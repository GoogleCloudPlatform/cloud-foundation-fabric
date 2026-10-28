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
"""Pre-layout SceneGraph snapshots (JSON) — lossless for rendering.

`scene_to_dict` / `scene_from_dict` round-trip every model field that layout,
routing and the emitters read, preserving the order of zones, children,
cards and edges. Rebuilding replays the original registration order with
plain dict assignment, so even a duplicated id keeps its first slot and last
value exactly as when the scene was built. Geometry (x, y, w, h) is layout
output and is not stored.
"""

import dataclasses
import json
import pathlib
from typing import Any, Dict, Union

from .model import Badge, CardNode, EdgeSpec, LegendEntry, SceneGraph, ZoneNode

FORMAT = "fast-diagrammer/scene@1"

_ZONE_FIELDS = ("id", "title", "subtitle", "style_name", "icon", "layout", "gap",
                "align", "dock_to", "dock_side", "dock_align", "dock_gap",
                "max_cols")
_CARD_FIELDS = ("id", "title", "subtitle", "style_name", "icon", "width",
                "height", "stroke_color", "stroke_width", "fill", "dashed")
_EDGE_FIELDS = tuple(f.name for f in dataclasses.fields(EdgeSpec))


def _node_to_dict(node: Union[ZoneNode, CardNode]) -> Dict[str, Any]:
  if isinstance(node, CardNode):
    out = {"kind": "card", **{f: getattr(node, f) for f in _CARD_FIELDS}}
    out["badges"] = [dataclasses.asdict(b) for b in node.badges]
    return out
  out = {"kind": "zone", **{f: getattr(node, f) for f in _ZONE_FIELDS}}
  out["badges"] = [dataclasses.asdict(b) for b in node.badges]
  out["children"] = [_node_to_dict(c) for c in node.children]
  return out


def scene_to_dict(scene: SceneGraph) -> Dict[str, Any]:
  """Pre-layout snapshot as plain JSON-compatible data."""
  return {
      "format": FORMAT,
      "dataset_name": scene.dataset_name,
      "view_kind": scene.view_kind,
      "stage": scene.stage,
      "root_zones": [_node_to_dict(z) for z in scene.root_zones],
      "edges": [{f: getattr(e, f) for f in _EDGE_FIELDS} for e in scene.edges],
      "legend": [dataclasses.asdict(l) for l in scene.legend],
  }


def scene_from_dict(data: Dict[str, Any]) -> SceneGraph:
  """Rebuilds a SceneGraph from `scene_to_dict` output."""
  if data.get("format") != FORMAT:
    raise ValueError(f"not a {FORMAT} snapshot: {data.get('format')!r}")
  scene = SceneGraph(data["dataset_name"], data["view_kind"],
                     stage=data.get("stage", ""))

  def build(d: Dict[str, Any], parent: Union[ZoneNode, None]):
    badges = [Badge(**b) for b in d.get("badges", [])]
    if d["kind"] == "card":
      node = CardNode(**{f: d[f] for f in _CARD_FIELDS}, badges=badges,
                      parent_zone_id=parent.id if parent else None)
      scene.cards[node.id] = node
      return node
    node = ZoneNode(**{f: d[f] for f in _ZONE_FIELDS}, badges=badges,
                    parent_zone_id=parent.id if parent else None)
    scene.zones[node.id] = node
    node.children = [build(c, node) for c in d["children"]]
    return node

  scene.root_zones = [build(z, None) for z in data["root_zones"]]
  scene.edges = [EdgeSpec(**e) for e in data["edges"]]
  scene.legend = [LegendEntry(**l) for l in data.get("legend", [])]
  return scene


def dumps_scene(scene: SceneGraph) -> str:
  return json.dumps(scene_to_dict(scene), indent=1, ensure_ascii=False) + "\n"


def loads_scene(text: str) -> SceneGraph:
  return scene_from_dict(json.loads(text))


def dump_scene(scene: SceneGraph, path: Union[str, pathlib.Path]) -> None:
  pathlib.Path(path).write_text(dumps_scene(scene), encoding="utf-8")


def load_scene(path: Union[str, pathlib.Path]) -> SceneGraph:
  return loads_scene(pathlib.Path(path).read_text(encoding="utf-8"))
