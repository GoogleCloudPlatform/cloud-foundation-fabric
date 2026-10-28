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

Ported verbatim from the scratch engine (golden parity). Additions — card
dashes and badges, zone badges and dash patterns, edge dash/head styles and
the legend group — only emit bytes when the corresponding fields are set.
"""

from html import escape
from typing import Dict, List, Optional, Tuple

from .model import DASH_PATTERNS, STYLE_PRESETS, SceneGraph, ZoneNode

# Legend geometry, computed by render.py: (x, y, w, h) plus per-row layout.
LegendBox = Tuple[float, float, float, float]

_HEAD_DRAWIO = {
    "filled": "endArrow=block;endFill=1;",
    "open": "endArrow=open;endFill=0;",
    "none": "endArrow=none;",
}


def _cell_id(scene: SceneGraph, eid: str) -> str:
  """drawio cell id of an edge endpoint (cards win over zones, as in routing)."""
  if eid in scene.cards or eid not in scene.zones:
    return f"card_{eid}"
  return f"zone_{eid}"


def _badge_suffix(badges) -> str:
  return "  ".join(f"[{b.text}]" for b in badges)


def build_drawio_xml(
    scene: SceneGraph,
    port_coords: Dict[Tuple[int, str], Tuple[float, float, float, float]],
    polylines: Dict[int, List[Tuple[float, float]]],
    legend_box: Optional[LegendBox] = None,
) -> str:
  lines = [
      '<?xml version="1.0" encoding="UTF-8"?>',
      '<mxfile host="app.diagrams.net" modified="2026-10-28T12:00:00.000Z" agent="fast-net-diagrammer-oss" version="24.0.0" type="device">',
      f'  <diagram id="{escape(scene.dataset_name)}_{escape(scene.view_kind)}" name="{escape(scene.dataset_name)} ({escape(scene.view_kind)})">',
      '    <mxGraphModel dx="1600" dy="900" grid="1" gridSize="10" guides="1" tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1" pageWidth="3000" pageHeight="4000" math="0" shadow="1">',
      "      <root>",
      '        <mxCell id="0" />',
      '        <mxCell id="1" parent="0" />',
  ]

  def emit_zone_cells(z: ZoneNode, parent_id: str, parent_abs_x: float,
                      parent_abs_y: float):
    rx = z.x - parent_abs_x
    ry = z.y - parent_abs_y
    cell_id = f"zone_{z.id}"
    if z.style_name == "@Ghost":
      style = "group;html=1;pointerEvents=0;fillColor=none;strokeColor=none;"
      val = ""
    else:
      preset = STYLE_PRESETS.get(z.style_name, STYLE_PRESETS["@ProjectZone"])
      dashed = "dashed=1;" if preset.get("dashed") else ""
      if preset.get("dashed") and preset.get("dashPattern"):
        dashed += f"dashPattern={preset['dashPattern']};"
      style = (
          f"swimlane;fontStyle=1;horizontal=1;startSize=32;collapsible=1;rounded=1;"
          f"fillColor={preset['fill']};strokeColor={preset['strokeColor']};"
          f"strokeWidth={preset['strokeWidth']};fontColor={preset['fontColor']};"
          f"fontSize=14;shadow=1;{dashed}"
      )
      title = z.title
      if z.badges:
        title = f"{title}  {_badge_suffix(z.badges)}"
      val = escape(title)
    lines.append(
        f'        <mxCell id="{cell_id}" value="{val}" style="{style}" vertex="1" parent="{parent_id}">'
    )
    lines.append(
        f'          <mxGeometry x="{rx:.1f}" y="{ry:.1f}" width="{z.w:.1f}" height="{z.h:.1f}" as="geometry" />'
    )
    lines.append("        </mxCell>")
    for ch in z.children:
      if isinstance(ch, ZoneNode):
        emit_zone_cells(ch, cell_id, z.x, z.y)
      else:
        crx = ch.x - z.x
        cry = ch.y - z.y
        html = (f"<b>[{ch.icon}] {ch.title}</b><br><font color='#5f6368' "
                f"size='1'>{ch.subtitle}</font>")
        if ch.badges:
          html += f"<br><font size='1'>{_badge_suffix(ch.badges)}</font>"
        c_val = escape(html)
        c_style = (
            f"rounded=1;arcSize=15;whiteSpace=wrap;html=1;fillColor={ch.fill};"
            f"strokeColor={ch.stroke_color};strokeWidth={ch.stroke_width};"
            f"fontColor=#202124;fontSize=12;shadow=1;align=left;spacingLeft=12;"
        )
        if ch.dashed:
          c_style += "dashed=1;dashPattern=5 3;"
        lines.append(
            f'        <mxCell id="card_{ch.id}" value="{c_val}" style="{c_style}" vertex="1" parent="{cell_id}">'
        )
        lines.append(
            f'          <mxGeometry x="{crx:.1f}" y="{cry:.1f}" width="{ch.width:.1f}" height="{ch.height:.1f}" as="geometry" />'
        )
        lines.append("        </mxCell>")

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
        f"strokeColor={e.color};strokeWidth={e.stroke_width};{dashed}"
        f"{start_arrow}{_HEAD_DRAWIO.get(e.head, _HEAD_DRAWIO['filled'])}"
        f"fontColor=#1e293b;fontSize=11;labelBackgroundColor=#ffffff;"
    )
    lines.append(
        f'        <mxCell id="edge_{idx}" value="{escape(e.label)}" style="{e_style}" edge="1" parent="1" source="{_cell_id(scene, e.src)}" target="{_cell_id(scene, e.dst)}">'
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
      "  </diagram>",
      "</mxfile>",
  ])
  return "\n".join(lines) + "\n"


def _emit_legend_cells(scene: SceneGraph, box: LegendBox,
                       lines: List[str]) -> None:
  # Imported lazily to avoid a cycle (legend geometry lives with the SVG side).
  from .emit_svg import legend_rows
  lx, ly, lw, lh = box
  preset = STYLE_PRESETS["@LegendZone"]
  lines.append(
      f'        <mxCell id="legend" value="Legend" style="swimlane;fontStyle=1;'
      f'horizontal=1;startSize=24;collapsible=1;rounded=1;fillColor={preset["fill"]};'
      f'strokeColor={preset["strokeColor"]};strokeWidth={preset["strokeWidth"]};'
      f'fontColor={preset["fontColor"]};fontSize=11;" vertex="1" parent="1">')
  lines.append(f'          <mxGeometry x="{lx:.1f}" y="{ly:.1f}" width="{lw:.1f}" '
               f'height="{lh:.1f}" as="geometry" />')
  lines.append("        </mxCell>")
  for i, (entry, sx, sy) in enumerate(legend_rows(scene, box)):
    rel_x, rel_y = sx - lx, sy - ly
    if entry.kind == "edge":
      pattern = DASH_PATTERNS.get(entry.dash)
      dashed = f"dashed=1;dashPattern={pattern};" if pattern else ""
      style = (f"endArrow={'none' if entry.head == 'none' else ('open' if entry.head == 'open' else 'block')};"
               f"endFill={1 if entry.head == 'filled' else 0};html=1;"
               f"strokeColor={entry.color};strokeWidth=2;{dashed}")
      lines.append(f'        <mxCell id="legend_{i}_line" value="" style="{style}" '
                   f'edge="1" parent="legend">')
      lines.append('          <mxGeometry relative="1" as="geometry">')
      lines.append(f'            <mxPoint x="{rel_x:.1f}" y="{rel_y:.1f}" as="sourcePoint" />')
      lines.append(f'            <mxPoint x="{rel_x + 36.0:.1f}" y="{rel_y:.1f}" as="targetPoint" />')
      lines.append("          </mxGeometry>")
      lines.append("        </mxCell>")
    else:
      dashed = "dashed=1;dashPattern=5 3;" if entry.dashed else ""
      lines.append(
          f'        <mxCell id="legend_{i}_swatch" value="" style="rounded=1;'
          f'fillColor={entry.fill};strokeColor={entry.color};strokeWidth=1.5;{dashed}" '
          f'vertex="1" parent="legend">')
      lines.append(f'          <mxGeometry x="{rel_x + 6.0:.1f}" y="{rel_y - 7.0:.1f}" '
                   f'width="24.0" height="14.0" as="geometry" />')
      lines.append("        </mxCell>")
    lines.append(
        f'        <mxCell id="legend_{i}_label" value="{escape(entry.label)}" '
        f'style="text;html=1;align=left;verticalAlign=middle;fontSize=11;'
        f'fontColor=#3c4043;" vertex="1" parent="legend">')
    lines.append(f'          <mxGeometry x="{rel_x + 44.0:.1f}" y="{rel_y - 9.0:.1f}" '
                 f'width="{lw - (rel_x + 44.0) - 6.0:.1f}" height="18.0" as="geometry" />')
    lines.append("        </mxCell>")
