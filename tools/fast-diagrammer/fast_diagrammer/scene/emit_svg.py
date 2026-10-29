# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""SVG writer (`.drawio.svg`: SVG with the mxfile embedded in `content=`).

Badges, dashed cards, zone dash patterns, open/no arrow heads, edge dash
styles and the legend only emit bytes when the corresponding fields are set.
Each distinct icon is emitted once as a `<symbol>` in `<defs>` and drawn with
`<use>`.

The text helpers below (`clean_text`, `xml_text`, `color_key`) are shared
with the draw.io emitter: every dataset-derived string goes through them, so
no label, colour or id can break the XML or inject markup.
"""

import hashlib
from html import escape
import math
import re
from typing import Dict, List, Optional, Set, Tuple

from .layout import (BADGE_FONT, BADGE_GAP, BADGE_H, BADGE_ROW_PITCH,
                     card_badge_rows, card_badge_top, zone_badge_strip_width,
                     badge_width)
from .model import (BADGE_TONES, DASH_PATTERNS, CardNode, LegendEntry,
                    STYLE_PRESETS, SceneGraph, ZoneNode)

LegendBox = Tuple[float, float, float, float]

LEGEND_HEADER = 26.0
LEGEND_ROW = 20.0
LEGEND_PAD = 10.0

# XML 1.0 forbids C0 controls other than tab/LF/CR, U+FFFE/U+FFFF and lone
# surrogates; any of them in a label would make both outputs unparseable.
_XML_INVALID = re.compile(
    "[\x00-\x08\x0b\x0c\x0e-\x1f\ufffe\uffff\ud800-\udfff]")
_HEX_COLOR = re.compile(r"#[0-9A-Fa-f]{3,8}")
_SYMBOL_UNSAFE = re.compile(r"[^A-Za-z0-9_-]")


def clean_text(value) -> str:
  """`value` as a string with XML-invalid characters removed."""
  if value is None:
    return ""
  return _XML_INVALID.sub("", str(value))


def xml_text(value) -> str:
  """`value` cleaned and escaped for XML text or a double-quoted attribute."""
  return escape(clean_text(value), quote=True)


def color_key(color: str) -> str:
  """An id-safe key for `color` (hex digits, or a short digest otherwise)."""
  color = clean_text(color)
  if _HEX_COLOR.fullmatch(color):
    return color[1:]
  return "c" + hashlib.sha256(color.encode("utf-8")).hexdigest()[:10]


def resolve_icon(icons_map: Dict[str, Dict[str, str]],
                 name: Optional[str]) -> Optional[str]:
  """Name of the icon drawn for `name` (falls back to `CloudGeneric`)."""
  if name and name in icons_map:
    return name
  if "CloudGeneric" in icons_map:
    return "CloudGeneric"
  return None


def icon_markup(icon: Dict[str, str]) -> List[str]:
  """Non-blank, stripped lines of an icon's inner markup."""
  return [ln.strip() for ln in icon["inner"].splitlines() if ln.strip()]


def legend_size(scene: SceneGraph) -> Tuple[float, float]:
  """(w, h) of the legend box for `scene.legend` (single column)."""
  if not scene.legend:
    return 0.0, 0.0
  longest = max(len(e.label) for e in scene.legend)
  w = max(180.0, LEGEND_PAD * 2 + 44.0 + longest * 6.4)
  h = LEGEND_HEADER + LEGEND_ROW * len(scene.legend) + LEGEND_PAD
  return w, h


def legend_rows(scene: SceneGraph,
                box: LegendBox) -> List[Tuple[LegendEntry, float, float]]:
  """Absolute (entry, sample_x, row_center_y) for each legend row."""
  lx, ly, _, _ = box
  out = []
  for i, entry in enumerate(scene.legend):
    out.append((entry, lx + LEGEND_PAD,
                ly + LEGEND_HEADER + LEGEND_ROW * i + LEGEND_ROW / 2.0))
  return out


def _rounded_polyline_svg_path(pts: List[Tuple[float, float]],
                               radius: float = 8.0) -> str:
  if len(pts) < 2:
    return ""
  if len(pts) == 2:
    return f"M {pts[0][0]:.1f} {pts[0][1]:.1f} L {pts[1][0]:.1f} {pts[1][1]:.1f}"
  cmds = [f"M {pts[0][0]:.1f} {pts[0][1]:.1f}"]
  for i in range(1, len(pts) - 1):
    p0, p1, p2 = pts[i - 1], pts[i], pts[i + 1]
    dx1, dy1 = p1[0] - p0[0], p1[1] - p0[1]
    dx2, dy2 = p2[0] - p1[0], p2[1] - p1[1]
    len1 = math.hypot(dx1, dy1)
    len2 = math.hypot(dx2, dy2)
    if len1 < 1.0 or len2 < 1.0:
      cmds.append(f"L {p1[0]:.1f} {p1[1]:.1f}")
      continue
    r = min(radius, len1 / 2.0, len2 / 2.0)
    bx = p1[0] - (dx1 / len1) * r
    by = p1[1] - (dy1 / len1) * r
    ax = p1[0] + (dx2 / len2) * r
    ay = p1[1] + (dy2 / len2) * r
    cmds.append(
        f"L {bx:.1f} {by:.1f} Q {p1[0]:.1f} {p1[1]:.1f} {ax:.1f} {ay:.1f}")
  cmds.append(f"L {pts[-1][0]:.1f} {pts[-1][1]:.1f}")
  return " ".join(cmds)


def _filled_marker_defs(col: str, start: bool) -> List[str]:
  cid, fill = color_key(col), xml_text(col)
  out = [
      f'    <marker id="arrow-end-{cid}" viewBox="0 0 10 10" refX="8.5" refY="5" markerWidth="6.5" markerHeight="6.5" orient="auto">',
      f'      <path d="M 0 1.5 L 9 5 L 0 8.5 z" fill="{fill}" />',
      "    </marker>",
  ]
  if start:
    out.extend([
        f'    <marker id="arrow-start-{cid}" viewBox="0 0 10 10" refX="1.5" refY="5" markerWidth="6.5" markerHeight="6.5" orient="auto">',
        f'      <path d="M 10 1.5 L 1 5 L 10 8.5 z" fill="{fill}" />',
        "    </marker>",
    ])
  return out


def _marker_defs(col: str, kinds: Set[str]) -> List[str]:
  cid = color_key(col)
  out = []
  if "open" in kinds:
    out.extend([
        f'    <marker id="arrow-open-{cid}" viewBox="0 0 10 10" refX="8.5" refY="5" markerWidth="7" markerHeight="7" orient="auto">',
        f'      <path d="M 1 1.5 L 9 5 L 1 8.5" fill="none" stroke="{xml_text(col)}" stroke-width="1.6" />',
        "    </marker>",
    ])
  return out


def _symbol_id(name: str) -> str:
  return "icon-" + _SYMBOL_UNSAFE.sub("_", name)


def build_svg(
    scene: SceneGraph,
    icons_map: Dict[str, Dict[str, str]],
    canvas_w: float,
    canvas_h: float,
    drawio_xml: str,
    polylines: Dict[int, List[Tuple[float, float]]],
    label_pos: Dict[int, Tuple[float, float]],
    legend_box: Optional[LegendBox] = None,
) -> str:
  """The `.drawio.svg` document; `drawio_xml` is embedded in `content=`."""
  title = f"{clean_text(scene.dataset_name)} ({clean_text(scene.view_kind)})"
  stage = clean_text(scene.stage)
  stage_note = f" (FAST {stage})" if stage else ""
  desc = (f"{clean_text(scene.view_kind)} diagram of the "
          f"{clean_text(scene.dataset_name)} dataset{stage_note}, generated "
          "by fast-diagrammer.")
  # Newlines are kept as character references so `content=` parses back
  # to exactly `drawio_xml`.
  content = escape(drawio_xml, quote=True).replace("\n", "&#10;")
  head = [
      '<?xml version="1.0" encoding="UTF-8"?>',
      f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" role="img" viewBox="0 0 {canvas_w:.0f} {canvas_h:.0f}" width="{canvas_w:.0f}" height="{canvas_h:.0f}" content="{content}" font-family="\'Google Sans\', \'Roboto\', \'Inter\', -apple-system, BlinkMacSystemFont, sans-serif">',
      f"  <title>{escape(title)}</title>",
      f"  <desc>{escape(desc)}</desc>",
      "  <defs>",
      '    <filter id="card-shadow" x="-8%" y="-8%" width="120%" height="125%">',
      '      <feDropShadow dx="0" dy="2" stdDeviation="2.5" flood-color="#0f172a" flood-opacity="0.08" />',
      "    </filter>",
  ]

  used_colors = sorted({e.color for e in scene.edges})
  for col in used_colors:
    head.extend(_filled_marker_defs(col, start=True))
  # Extra markers: open heads, and legend-only colours.
  extra: Dict[str, Set[str]] = {}
  for e in scene.edges:
    if e.head == "open":
      extra.setdefault(e.color, set()).add("open")
  if legend_box is not None:
    for entry in scene.legend:
      if entry.kind != "edge":
        continue
      if entry.head == "open":
        extra.setdefault(entry.color, set()).add("open")
      elif entry.head == "filled" and entry.color not in used_colors:
        extra.setdefault(entry.color, set()).add("filled")
  for col in sorted(extra):
    kinds = extra[col]
    if "filled" in kinds:
      head.extend(_filled_marker_defs(col, start=False))
    head.extend(_marker_defs(col, kinds))

  # The body is collected first so that <defs> only carries used icons.
  used_icons: Set[str] = set()
  svg_lines: List[str] = [
      f'  <rect x="0" y="0" width="{canvas_w:.0f}" height="{canvas_h:.0f}" fill="#ffffff" rx="12" ry="12" />'
  ]

  def render_icon(icon_name: Optional[str], ix: float, iy: float,
                  size: float) -> None:
    name = resolve_icon(icons_map, icon_name)
    if name is None:
      return
    used_icons.add(name)
    svg_lines.append(
        f'  <use xlink:href="#{_symbol_id(name)}" x="{ix:.1f}" y="{iy:.1f}" width="{size:.1f}" height="{size:.1f}" />'
    )

  def render_pill(text: str, tone: str, px: float, py: float,
                  pw: float) -> None:
    fill, fg = BADGE_TONES.get(tone, BADGE_TONES["neutral"])
    svg_lines.append(
        f'  <rect x="{px:.1f}" y="{py:.1f}" width="{pw:.1f}" height="{BADGE_H:.1f}" rx="8" ry="8" fill="{fill}" stroke="{fg}" stroke-width="0.6" stroke-opacity="0.45" />'
    )
    svg_lines.append(
        f'  <text x="{px + pw / 2.0:.1f}" y="{py + 11.5:.1f}" text-anchor="middle" font-size="{BADGE_FONT}" font-weight="600" fill="{fg}">{xml_text(text)}</text>'
    )

  def emit_zone_svg(z: ZoneNode) -> None:
    if z.style_name != "@Ghost":
      preset = STYLE_PRESETS.get(z.style_name, STYLE_PRESETS["@ProjectZone"])
      dash_attr = ""
      if preset.get("dashed"):
        dash_attr = f' stroke-dasharray="{preset.get("dashPattern", "6 3")}"'
      rx = preset.get("borderRadius", 12)
      svg_lines.append(
          f'  <rect x="{z.x:.1f}" y="{z.y:.1f}" width="{z.w:.1f}" height="{z.h:.1f}" rx="{rx}" ry="{rx}" fill="{preset["fill"]}" stroke="{preset["strokeColor"]}" stroke-width="{preset["strokeWidth"]}"{dash_attr} />'
      )
      tx = z.x + 18.0
      if z.icon:
        ic_sz = 26.0 if z.style_name in ("@ArchitectureRoot",
                                         "@OrganizationZone") else 20.0
        render_icon(z.icon, z.x + 16.0, z.y + 12.0, ic_sz)
        tx = z.x + 16.0 + ic_sz + 10.0
      fsize = preset.get("fontSize", 15)
      svg_lines.append(
          f'  <text x="{tx:.1f}" y="{z.y + 26.0:.1f}" font-size="{fsize}" font-weight="700" fill="{preset["fontColor"]}">{xml_text(z.title)}</text>'
      )
      if z.subtitle:
        sub_sz = fsize * 0.78
        svg_lines.append(
            f'  <text x="{tx:.1f}" y="{z.y + 44.0:.1f}" font-size="{sub_sz:.1f}" font-weight="600" fill="#475569">{xml_text(z.subtitle)}</text>'
        )
      if z.badges:
        bx = z.x + z.w - 16.0 - zone_badge_strip_width(z)
        for b in z.badges:
          bw = badge_width(b.text)
          render_pill(b.text, b.tone, bx, z.y + 13.0, bw)
          bx += bw + BADGE_GAP

    for ch in z.children:
      if isinstance(ch, ZoneNode):
        emit_zone_svg(ch)
      else:
        emit_card_svg(ch)

  def emit_card_svg(c: CardNode) -> None:
    card_dash = ' stroke-dasharray="5 3"' if c.dashed else ""
    svg_lines.append(
        f'  <rect x="{c.x:.1f}" y="{c.y:.1f}" width="{c.width:.1f}" height="{c.height:.1f}" rx="8" ry="8" fill="{xml_text(c.fill)}" stroke="{xml_text(c.stroke_color)}" stroke-width="{xml_text(c.stroke_width)}"{card_dash} filter="url(#card-shadow)" />'
    )
    ic_sz = 26.0
    ic_x = c.x + 12.0
    ic_y = c.y + (c.height - ic_sz) / 2.0 if not c.badges else c.y + 16.0
    render_icon(c.icon, ic_x, ic_y, ic_sz)
    tx = ic_x + ic_sz + 10.0
    svg_lines.append(
        f'  <text x="{tx:.1f}" y="{c.y + 24.0:.1f}" font-size="12.5" font-weight="700" fill="#202124">{xml_text(c.title)}</text>'
    )
    if c.subtitle:
      sub = c.subtitle
      if len(sub) > 38 and " · " in sub:
        p1, p2 = sub.split(" · ", 1)
        svg_lines.append(
            f'  <text x="{tx:.1f}" y="{c.y + 40.0:.1f}" font-size="10.2" font-weight="500" fill="#5f6368">{xml_text(p1)}</text>'
        )
        svg_lines.append(
            f'  <text x="{tx:.1f}" y="{c.y + 53.0:.1f}" font-size="10.2" font-weight="500" fill="#5f6368">· {xml_text(p2)}</text>'
        )
      else:
        svg_lines.append(
            f'  <text x="{tx:.1f}" y="{c.y + 42.0:.1f}" font-size="10.5" font-weight="500" fill="#5f6368">{xml_text(sub)}</text>'
        )
    if c.badges:
      by = c.y + card_badge_top(c)
      for row in card_badge_rows(c):
        bx = tx
        for b, bw in row:
          render_pill(b.text, b.tone, bx, by, bw)
          bx += bw + BADGE_GAP
        by += BADGE_ROW_PITCH

  for rz in scene.root_zones:
    emit_zone_svg(rz)

  for idx, e in enumerate(scene.edges):
    pts = polylines.get(idx)
    if not pts:
      continue
    d_path = _rounded_polyline_svg_path(pts, radius=8.0)
    cid = color_key(e.color)
    pattern = e.dash_pattern
    dash_attr = f' stroke-dasharray="{pattern}"' if pattern else ""
    m_start = f' marker-start="url(#arrow-start-{cid})"' if e.arrow == "<-->" else ""
    if e.head == "open":
      m_end = f' marker-end="url(#arrow-open-{cid})"'
    elif e.head == "none":
      m_end = ""
    else:
      m_end = f' marker-end="url(#arrow-end-{cid})"'
    svg_lines.append(
        f'  <path d="{d_path}" fill="none" stroke="{xml_text(e.color)}" stroke-width="{xml_text(e.stroke_width)}"{dash_attr}{m_start}{m_end} />'
    )

  for idx, (lx, ly) in label_pos.items():
    e = scene.edges[idx]
    pw = max(36.0, len(e.label) * 6.4 + 14.0)
    ph = 17.0
    svg_lines.append(
        f'  <rect x="{lx - pw / 2.0:.1f}" y="{ly - ph / 2.0:.1f}" width="{pw:.1f}" height="{ph:.1f}" rx="4" ry="4" fill="#ffffff" fill-opacity="0.95" stroke="{xml_text(e.color)}" stroke-width="0.9" />'
    )
    svg_lines.append(
        f'  <text x="{lx:.1f}" y="{ly + 3.8:.1f}" text-anchor="middle" font-size="10.2" font-weight="600" fill="#1e293b">{xml_text(e.label)}</text>'
    )

  if scene.legend and legend_box is not None:
    _emit_legend_svg(scene, legend_box, svg_lines)

  for name in sorted(used_icons):
    ic = icons_map[name]
    head.append(
        f'    <symbol id="{_symbol_id(name)}" viewBox="{xml_text(ic["viewBox"])}">'
    )
    head.extend("      " + ln for ln in icon_markup(ic))
    head.append("    </symbol>")
  head.append("  </defs>")
  svg_lines.append("</svg>")
  return "\n".join(head + svg_lines) + "\n"


def _emit_legend_svg(scene: SceneGraph, box: LegendBox,
                     svg_lines: List[str]) -> None:
  lx, ly, lw, lh = box
  preset = STYLE_PRESETS["@LegendZone"]
  svg_lines.append(
      f'  <rect x="{lx:.1f}" y="{ly:.1f}" width="{lw:.1f}" height="{lh:.1f}" rx="{preset["borderRadius"]}" ry="{preset["borderRadius"]}" fill="{preset["fill"]}" stroke="{preset["strokeColor"]}" stroke-width="{preset["strokeWidth"]}" />'
  )
  svg_lines.append(
      f'  <text x="{lx + LEGEND_PAD:.1f}" y="{ly + 17.0:.1f}" font-size="{preset["fontSize"]}" font-weight="700" fill="{preset["fontColor"]}">Legend</text>'
  )
  for entry, sx, sy in legend_rows(scene, box):
    if entry.kind == "edge":
      pattern = DASH_PATTERNS.get(entry.dash)
      dash_attr = f' stroke-dasharray="{pattern}"' if pattern else ""
      cid = color_key(entry.color)
      if entry.head == "open":
        m_end = f' marker-end="url(#arrow-open-{cid})"'
      elif entry.head == "none":
        m_end = ""
      else:
        m_end = f' marker-end="url(#arrow-end-{cid})"'
      svg_lines.append(
          f'  <path d="M {sx:.1f} {sy:.1f} L {sx + 36.0:.1f} {sy:.1f}" fill="none" stroke="{xml_text(entry.color)}" stroke-width="2"{dash_attr}{m_end} />'
      )
    else:
      dash_attr = ' stroke-dasharray="5 3"' if entry.dashed else ""
      svg_lines.append(
          f'  <rect x="{sx + 6.0:.1f}" y="{sy - 7.0:.1f}" width="24.0" height="14.0" rx="3" ry="3" fill="{xml_text(entry.fill)}" stroke="{xml_text(entry.color)}" stroke-width="1.5"{dash_attr} />'
      )
    svg_lines.append(
        f'  <text x="{sx + 44.0:.1f}" y="{sy + 3.8:.1f}" font-size="11" font-weight="500" fill="#3c4043">{xml_text(entry.label)}</text>'
    )
