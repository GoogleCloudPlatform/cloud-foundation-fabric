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
"""Render entry point: layout -> route -> overlap gate -> .drawio + .drawio.svg."""

from dataclasses import dataclass, field
import json
import pathlib
from typing import Dict, List, Optional, Tuple, Union

from .emit_drawio import build_drawio_xml
from .emit_svg import build_svg, legend_size
from .layout import layout_scene
from .model import CardNode, SceneGraph, ZoneNode
from .router import route_all_edges, verify_no_arrow_overlaps

ICONS_JSON = pathlib.Path(__file__).resolve().parent.parent / "icons" / "icons.json"

PathLike = Union[str, pathlib.Path]


class OverlapError(RuntimeError):
  """Raised when `verify_no_arrow_overlaps` reports overlapping edges."""


@dataclass
class RenderResult:
  svg: str
  drawio: str
  width: float
  height: float
  polylines: Dict[int, List[Tuple[float, float]]] = field(default_factory=dict)
  overlap_errors: List[str] = field(default_factory=list)
  unknown_icons: List[str] = field(default_factory=list)


def load_icons(path: Optional[PathLike] = None) -> Dict[str, Dict[str, str]]:
  """Loads `{name: {viewBox, inner}}` (default: the packaged icons.json)."""
  return json.loads(pathlib.Path(path or ICONS_JSON).read_text(encoding="utf-8"))


def unknown_icons(scene: SceneGraph, icons_map: Dict[str, Dict[str, str]]
                 ) -> List[str]:
  """Icon names referenced by the scene but absent from `icons_map` (sorted).

  The renderer falls back to `CloudGeneric` for these; networking keeps
  `CloudLoadBalancing` / `Routes` on purpose (they land in drawio labels).
  """
  names = set()

  def walk(node: Union[ZoneNode, CardNode]) -> None:
    if isinstance(node, CardNode):
      if node.icon:
        names.add(node.icon)
      return
    if node.style_name != "@Ghost" and node.icon:
      names.add(node.icon)
    for ch in node.children:
      walk(ch)

  for rz in scene.root_zones:
    walk(rz)
  return sorted(n for n in names if n not in icons_map)


def _legend_box(scene: SceneGraph, canvas_w: float, canvas_h: float,
                polylines: Dict[int, List[Tuple[float, float]]]
               ) -> Tuple[Optional[Tuple[float, float, float, float]], float,
                          float]:
  if not scene.legend:
    return None, canvas_w, canvas_h
  lw, lh = legend_size(scene)
  bottom = canvas_h - 32.0
  for pts in polylines.values():
    for _, y in pts:
      bottom = max(bottom, y + 8.0)
  ly = bottom + 24.0
  box = (32.0, ly, lw, lh)
  return box, max(canvas_w, 32.0 + lw + 32.0), max(canvas_h, ly + lh + 32.0)


def render_scene(scene: SceneGraph,
                 icons_map: Optional[Dict[str, Dict[str, str]]] = None,
                 *,
                 check_overlaps: bool = True) -> RenderResult:
  """Lays out, routes and serialises `scene` in memory (mutates geometry).

  Raises OverlapError when `check_overlaps` and the overlap gate fails.
  """
  if icons_map is None:
    icons_map = load_icons()
  canvas_w, canvas_h = layout_scene(scene)
  port_coords, polylines, label_pos = route_all_edges(scene)
  errs = verify_no_arrow_overlaps(polylines)
  if errs and check_overlaps:
    raise OverlapError(
        f"Arrow overlap gate failed on {scene.dataset_name}-{scene.view_kind}: {errs}"
    )
  legend_box, canvas_w, canvas_h = _legend_box(scene, canvas_w, canvas_h,
                                               polylines)
  drawio_xml = build_drawio_xml(scene, port_coords, polylines, legend_box)
  svg = build_svg(scene, icons_map, canvas_w, canvas_h, drawio_xml, polylines,
                  label_pos, legend_box)
  return RenderResult(
      svg=svg,
      drawio=drawio_xml,
      width=canvas_w,
      height=canvas_h,
      polylines=polylines,
      overlap_errors=errs,
      unknown_icons=unknown_icons(scene, icons_map),
  )


def render(scene: SceneGraph,
           icons_map: Optional[Dict[str, Dict[str, str]]],
           out_svg: PathLike,
           out_drawio: PathLike,
           *,
           check_overlaps: bool = True) -> RenderResult:
  """Renders `scene` and writes `<x>.drawio.svg` and `<x>.drawio` (UTF-8)."""
  result = render_scene(scene, icons_map, check_overlaps=check_overlaps)
  pathlib.Path(out_drawio).write_text(result.drawio, encoding="utf-8")
  pathlib.Path(out_svg).write_text(result.svg, encoding="utf-8")
  return result
