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
"""Standalone draw.io (`mxGraphModel`) XML emitter.

Card dashes and badges, zone badges and dash patterns, edge dash/head styles
and the legend group only emit bytes when the corresponding fields are set.
Card and zone icons are child image cells (`icon_<owner cell id>`, a prefix
no element cell uses) carrying the icon as a
`data:image/svg+xml,<base64>` URI (draw.io's form: a `;` would end the style
value), so the `.drawio` matches the `.drawio.svg` drawing.

Escaping: every label is rendered with `html=1`, so dataset text is first
HTML-escaped into a fragment whose only markup (`<b>`, `<br>`, `<font>`) is
produced here, and the fragment is then escaped again for the XML attribute.
Style values coming from the scene drop `;`, and element ids must match
`[A-Za-z0-9_]+`.
"""

import base64
from html import escape
import re
from typing import Dict, List, Optional, Set, Tuple
import urllib.parse
import zlib

from .emit_svg import (clean_text, icon_markup, legend_rows, resolve_icon,
                       xml_text)
from .model import (DASH_PATTERNS, STYLE_PRESETS, CardNode, SceneGraph,
                    ZoneNode)

# Legend geometry, computed by render.py: (x, y, w, h) plus per-row layout.
LegendBox = Tuple[float, float, float, float]
IconsMap = Dict[str, Dict[str, str]]

_HEAD_DRAWIO = {
    "filled": "endArrow=block;endFill=1;",
    "open": "endArrow=open;endFill=0;",
    "none": "endArrow=none;",
}
_SAFE_ID = re.compile(r"[A-Za-z0-9_]+")
# encodeURIComponent() leaves these unescaped (plus letters, digits, `-_.~`).
_URI_SAFE = "!*'()"

CARD_ICON = 26.0
CARD_ICON_X = 12.0


def _safe_id(eid) -> str:
  """`eid` checked against `[A-Za-z0-9_]+` (raises ValueError otherwise)."""
  if not isinstance(eid, str) or not _SAFE_ID.fullmatch(eid):
    raise ValueError(f"element id {eid!r} is not a valid diagram id: ids "
                     "must match [A-Za-z0-9_]+")
  return eid


def _h(text) -> str:
  """Dataset text as an HTML fragment (no markup can survive)."""
  return escape(clean_text(text), quote=False)


def _sv(value) -> str:
  """A scene value made safe for a draw.io `key=value;` style entry."""
  return clean_text(value).replace(";", "")


def _cell_id(scene: SceneGraph, eid: str) -> str:
  """drawio cell id of an edge endpoint (cards win over zones, as in routing)."""
  _safe_id(eid)
  if eid in scene.cards or eid not in scene.zones:
    return f"card_{eid}"
  return f"zone_{eid}"


def _badges_html(badges) -> str:
  return "  ".join(f"[{_h(b.text)}]" for b in badges)


def icon_data_uri(icon: Dict[str, str], size: float) -> str:
  """`data:image/svg+xml,<base64>` for one icons.json entry."""
  svg = (
      f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{xml_text(icon["viewBox"])}" '
      f'width="{size:.0f}" height="{size:.0f}">{"".join(icon_markup(icon))}</svg>'
  )
  return "data:image/svg+xml," + base64.b64encode(
      svg.encode("utf-8")).decode("ascii")


def compress_diagram(model_xml: str) -> str:
  """draw.io's compressed `<diagram>` payload: base64(deflateRaw(uri(xml)))."""
  data = urllib.parse.quote(model_xml, safe=_URI_SAFE).encode("ascii")
  co = zlib.compressobj(9, zlib.DEFLATED, -15)
  return base64.b64encode(co.compress(data) + co.flush()).decode("ascii")


def decompress_diagram(payload: str) -> str:
  """Inverse of `compress_diagram`."""
  raw = zlib.decompress(base64.b64decode(payload), -15)
  return urllib.parse.unquote(raw.decode("ascii"))


def build_drawio_model(
    scene: SceneGraph,
    port_coords: Dict[Tuple[int, str], Tuple[float, float, float, float]],
    polylines: Dict[int, List[Tuple[float, float]]],
    legend_box: Optional[LegendBox] = None,
    icons_map: Optional[IconsMap] = None,
) -> str:
  """The `<mxGraphModel>` element (indented for nesting in `<diagram>`)."""
  icons_map = icons_map or {}
  uri_cache: Dict[Tuple[str, float], str] = {}
  cell_ids: Set[str] = set()

  def new_cell_id(cid: str) -> str:
    if cid in cell_ids:
      raise ValueError(f"duplicate diagram cell id {cid!r}")
    cell_ids.add(cid)
    return cid

  lines = [
      '    <mxGraphModel dx="1600" dy="900" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="3000" pageHeight="4000" math="0" shadow="1">',
      "      <root>",
      '        <mxCell id="0" />',
      '        <mxCell id="1" parent="0" />',
  ]

  def emit_icon(owner_id: str, name: Optional[str], x: float, y: float,
                size: float) -> None:
    resolved = resolve_icon(icons_map, name)
    if resolved is None:
      return
    key = (resolved, size)
    if key not in uri_cache:
      uri_cache[key] = icon_data_uri(icons_map[resolved], size)
    style = ("shape=image;html=1;aspect=fixed;imageAspect=0;connectable=0;"
             f"image={uri_cache[key]};")
    lines.append(
        f'        <mxCell id="{new_cell_id("icon_" + owner_id)}" value="" style="{xml_text(style)}" vertex="1" parent="{owner_id}">'
    )
    lines.append(
        f'          <mxGeometry x="{x:.1f}" y="{y:.1f}" width="{size:.1f}" height="{size:.1f}" as="geometry" />'
    )
    lines.append("        </mxCell>")

  def emit_card(ch: CardNode, parent_id: str, z: ZoneNode) -> None:
    cell_id = new_cell_id(f"card_{_safe_id(ch.id)}")
    crx = ch.x - z.x
    cry = ch.y - z.y
    html = (f"<b>{_h(ch.title)}</b><br><font color='#5f6368' "
            f"size='1'>{_h(ch.subtitle)}</font>")
    if ch.badges:
      html += f"<br><font size='1'>{_badges_html(ch.badges)}</font>"
    has_icon = resolve_icon(icons_map, ch.icon) is not None
    spacing = CARD_ICON_X + CARD_ICON + 10.0 if has_icon else CARD_ICON_X
    c_style = (
        f"rounded=1;arcSize=15;whiteSpace=wrap;html=1;fillColor={_sv(ch.fill)};"
        f"strokeColor={_sv(ch.stroke_color)};strokeWidth={_sv(ch.stroke_width)};"
        f"fontColor=#202124;fontSize=12;shadow=1;align=left;spacingLeft={spacing:.0f};"
    )
    if ch.dashed:
      c_style += "dashed=1;dashPattern=5 3;"
    lines.append(
        f'        <mxCell id="{cell_id}" value="{xml_text(html)}" style="{xml_text(c_style)}" vertex="1" parent="{parent_id}">'
    )
    lines.append(
        f'          <mxGeometry x="{crx:.1f}" y="{cry:.1f}" width="{ch.width:.1f}" height="{ch.height:.1f}" as="geometry" />'
    )
    lines.append("        </mxCell>")
    # Same placement as the SVG emitter.
    icon_y = ((ch.height - CARD_ICON) / 2.0) if not ch.badges else 16.0
    emit_icon(cell_id, ch.icon, CARD_ICON_X, icon_y, CARD_ICON)

  def emit_zone_cells(z: ZoneNode, parent_id: str, parent_abs_x: float,
                      parent_abs_y: float):
    rx = z.x - parent_abs_x
    ry = z.y - parent_abs_y
    cell_id = new_cell_id(f"zone_{_safe_id(z.id)}")
    icon_size = 0.0
    if z.style_name == "@Ghost":
      style = "group;html=1;pointerEvents=0;fillColor=none;strokeColor=none;"
      val = ""
    else:
      preset = STYLE_PRESETS.get(z.style_name, STYLE_PRESETS["@ProjectZone"])
      dashed = "dashed=1;" if preset.get("dashed") else ""
      if preset.get("dashed") and preset.get("dashPattern"):
        dashed += f"dashPattern={preset['dashPattern']};"
      spacing = 18.0
      if z.icon and resolve_icon(icons_map, z.icon) is not None:
        icon_size = 26.0 if z.style_name in ("@ArchitectureRoot",
                                             "@OrganizationZone") else 20.0
        spacing = 16.0 + icon_size + 10.0
      start = 48 if z.subtitle else 32
      style = (
          f"swimlane;html=1;fontStyle=1;horizontal=1;startSize={start};collapsible=1;rounded=1;"
          f"fillColor={preset['fill']};strokeColor={preset['strokeColor']};"
          f"strokeWidth={preset['strokeWidth']};fontColor={preset['fontColor']};"
          f"fontSize=14;shadow=1;{dashed}align=left;spacingLeft={spacing:.0f};")
      val = _h(z.title)
      if z.badges:
        val = f"{val}  {_badges_html(z.badges)}"
      if z.subtitle:
        val += f"<br><font color='#475569' size='1'>{_h(z.subtitle)}</font>"
    lines.append(
        f'        <mxCell id="{cell_id}" value="{xml_text(val)}" style="{xml_text(style)}" vertex="1" parent="{parent_id}">'
    )
    lines.append(
        f'          <mxGeometry x="{rx:.1f}" y="{ry:.1f}" width="{z.w:.1f}" height="{z.h:.1f}" as="geometry" />'
    )
    lines.append("        </mxCell>")
    if icon_size:
      emit_icon(cell_id, z.icon, 16.0, 12.0, icon_size)
    for ch in z.children:
      if isinstance(ch, ZoneNode):
        emit_zone_cells(ch, cell_id, z.x, z.y)
      else:
        emit_card(ch, cell_id, z)

  for rz in scene.root_zones:
    emit_zone_cells(rz, "1", 0.0, 0.0)

  for idx, e in enumerate(scene.edges):
    if (idx, "src") not in port_coords or (idx, "dst") not in port_coords:
      continue
    _, _, enx1, eny1 = port_coords[(idx, "src")]
    _, _, enx2, eny2 = port_coords[(idx, "dst")]
    pattern = e.dash_pattern
    dashed = f"dashed=1;dashPattern={pattern};" if pattern else ""
    start_arrow = "startArrow=block;startFill=1;" if e.arrow == "<-->" else "startArrow=none;"
    e_style = (
        f"edgeStyle=orthogonalEdgeStyle;rounded=1;orthogonalLoop=1;jettySize=auto;html=1;"
        f"exitX={enx1:.2f};exitY={eny1:.2f};exitDx=0;exitDy=0;"
        f"entryX={enx2:.2f};entryY={eny2:.2f};entryDx=0;entryDy=0;"
        f"strokeColor={_sv(e.color)};strokeWidth={_sv(e.stroke_width)};{dashed}"
        f"{start_arrow}{_HEAD_DRAWIO.get(e.head, _HEAD_DRAWIO['filled'])}"
        f"fontColor=#1e293b;fontSize=11;labelBackgroundColor=#ffffff;")
    lines.append(
        f'        <mxCell id="edge_{idx}" value="{xml_text(_h(e.label))}" style="{xml_text(e_style)}" edge="1" parent="1" source="{_cell_id(scene, e.src)}" target="{_cell_id(scene, e.dst)}">'
    )
    pts = polylines.get(idx, [])
    if len(pts) > 2:
      lines.append('          <mxGeometry relative="1" as="geometry">')
      lines.append('            <Array as="points">')
      for wx, wy in pts[1:-1]:
        lines.append(f'              <mxPoint x="{wx:.1f}" y="{wy:.1f}" />')
      lines.append("            </Array>")
      lines.append("          </mxGeometry>")
    else:
      lines.append('          <mxGeometry relative="1" as="geometry" />')
    lines.append("        </mxCell>")

  if scene.legend and legend_box is not None:
    _emit_legend_cells(scene, legend_box, lines)

  lines.extend([
      "      </root>",
      "    </mxGraphModel>",
  ])
  return "\n".join(lines)


def wrap_mxfile(scene: SceneGraph, model_xml: str,
                compressed: bool = False) -> str:
  """The `<mxfile>` document around `model_xml` (optionally compressed)."""
  name = f"{clean_text(scene.dataset_name)}_{clean_text(scene.view_kind)}"
  label = f"{clean_text(scene.dataset_name)} ({clean_text(scene.view_kind)})"
  lines = [
      '<?xml version="1.0" encoding="UTF-8"?>',
      '<mxfile host="app.diagrams.net" modified="2026-10-28T12:00:00.000Z" agent="fast-diagrammer" version="24.0.0" type="device">',
  ]
  diagram = f'  <diagram id="{xml_text(name)}" name="{xml_text(label)}">'
  if compressed:
    lines.append(f"{diagram}{compress_diagram(model_xml)}</diagram>")
  else:
    lines.extend([diagram, model_xml, "  </diagram>"])
  lines.append("</mxfile>")
  return "\n".join(lines) + "\n"


def build_drawio_xml(
    scene: SceneGraph,
    port_coords: Dict[Tuple[int, str], Tuple[float, float, float, float]],
    polylines: Dict[int, List[Tuple[float, float]]],
    legend_box: Optional[LegendBox] = None,
    icons_map: Optional[IconsMap] = None,
    *,
    compressed: bool = False,
) -> str:
  """The `.drawio` document (plain XML unless `compressed`)."""
  return wrap_mxfile(
      scene,
      build_drawio_model(scene, port_coords, polylines, legend_box, icons_map),
      compressed)


def _emit_legend_cells(scene: SceneGraph, box: LegendBox,
                       lines: List[str]) -> None:
  lx, ly, lw, lh = box
  preset = STYLE_PRESETS["@LegendZone"]
  lines.append(
      f'        <mxCell id="legend" value="Legend" style="swimlane;fontStyle=1;'
      f'horizontal=1;startSize=24;collapsible=1;rounded=1;fillColor={preset["fill"]};'
      f'strokeColor={preset["strokeColor"]};strokeWidth={preset["strokeWidth"]};'
      f'fontColor={preset["fontColor"]};fontSize=11;" vertex="1" parent="1">')
  lines.append(
      f'          <mxGeometry x="{lx:.1f}" y="{ly:.1f}" width="{lw:.1f}" '
      f'height="{lh:.1f}" as="geometry" />')
  lines.append("        </mxCell>")
  for i, (entry, sx, sy) in enumerate(legend_rows(scene, box)):
    rel_x, rel_y = sx - lx, sy - ly
    if entry.kind == "edge":
      pattern = DASH_PATTERNS.get(entry.dash)
      dashed = f"dashed=1;dashPattern={pattern};" if pattern else ""
      style = (
          f"endArrow={'none' if entry.head == 'none' else ('open' if entry.head == 'open' else 'block')};"
          f"endFill={1 if entry.head == 'filled' else 0};html=1;"
          f"strokeColor={_sv(entry.color)};strokeWidth=2;{dashed}")
      lines.append(
          f'        <mxCell id="legend_{i}_line" value="" style="{xml_text(style)}" '
          f'edge="1" parent="legend">')
      lines.append('          <mxGeometry relative="1" as="geometry">')
      lines.append(
          f'            <mxPoint x="{rel_x:.1f}" y="{rel_y:.1f}" as="sourcePoint" />'
      )
      lines.append(
          f'            <mxPoint x="{rel_x + 36.0:.1f}" y="{rel_y:.1f}" as="targetPoint" />'
      )
      lines.append("          </mxGeometry>")
      lines.append("        </mxCell>")
    else:
      dashed = "dashed=1;dashPattern=5 3;" if entry.dashed else ""
      style = (f"rounded=1;fillColor={_sv(entry.fill)};"
               f"strokeColor={_sv(entry.color)};strokeWidth=1.5;{dashed}")
      lines.append(
          f'        <mxCell id="legend_{i}_swatch" value="" style="{xml_text(style)}" '
          f'vertex="1" parent="legend">')
      lines.append(
          f'          <mxGeometry x="{rel_x + 6.0:.1f}" y="{rel_y - 7.0:.1f}" '
          f'width="24.0" height="14.0" as="geometry" />')
      lines.append("        </mxCell>")
    lines.append(
        f'        <mxCell id="legend_{i}_label" value="{xml_text(_h(entry.label))}" '
        f'style="text;html=1;align=left;verticalAlign=middle;fontSize=11;'
        f'fontColor=#3c4043;" vertex="1" parent="legend">')
    lines.append(
        f'          <mxGeometry x="{rel_x + 44.0:.1f}" y="{rel_y - 9.0:.1f}" '
        f'width="{lw - (rel_x + 44.0) - 6.0:.1f}" height="18.0" as="geometry" />'
    )
    lines.append("        </mxCell>")
