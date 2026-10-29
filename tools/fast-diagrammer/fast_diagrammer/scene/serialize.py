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
import re
from typing import Any, Dict, List, Union

from .model import Badge, CardNode, EdgeSpec, LegendEntry, SceneGraph, ZoneNode

FORMAT = "fast-diagrammer/scene@1"

_ZONE_FIELDS = ("id", "title", "subtitle", "style_name", "icon", "layout",
                "gap", "align", "dock_to", "dock_side", "dock_align",
                "dock_gap", "max_cols")
_CARD_FIELDS = ("id", "title", "subtitle", "style_name", "icon", "width",
                "height", "stroke_color", "stroke_width", "fill", "dashed")
_EDGE_FIELDS = tuple(f.name for f in dataclasses.fields(EdgeSpec))
_SAFE_ID = re.compile(r"[A-Za-z0-9_]+")


class SceneFormatError(ValueError):
  """Raised when a snapshot is not a well-formed `FORMAT` document."""


def _node_to_dict(node: Union[ZoneNode, CardNode]) -> Dict[str, Any]:
  if isinstance(node, CardNode):
    out = {"kind": "card", **{f: getattr(node, f) for f in _CARD_FIELDS}}
    out["badges"] = [dataclasses.asdict(b) for b in node.badges]
    return out
  out = {"kind": "zone", **{f: getattr(node, f) for f in _ZONE_FIELDS}}
  out["badges"] = [dataclasses.asdict(b) for b in node.badges]
  out["children"] = [_node_to_dict(c) for c in node.children]
  return out


def _edge_to_dict(e: EdgeSpec) -> Dict[str, Any]:
  # `trunk` is written only when set, so snapshots of scenes that do not use
  # it stay byte-identical to the ones written before the field existed.
  return {f: getattr(e, f) for f in _EDGE_FIELDS if f != "trunk" or e.trunk}


def scene_to_dict(scene: SceneGraph) -> Dict[str, Any]:
  """Pre-layout snapshot as plain JSON-compatible data."""
  return {
      "format": FORMAT,
      "dataset_name": scene.dataset_name,
      "view_kind": scene.view_kind,
      "stage": scene.stage,
      "root_zones": [_node_to_dict(z) for z in scene.root_zones],
      "edges": [_edge_to_dict(e) for e in scene.edges],
      "legend": [dataclasses.asdict(l) for l in scene.legend],
  }


def _obj(value: Any, where: str) -> Dict[str, Any]:
  if not isinstance(value, dict):
    raise SceneFormatError(
        f"{where}: expected an object, got {type(value).__name__}")
  return value


def _list(value: Any, where: str) -> List[Any]:
  if not isinstance(value, list):
    raise SceneFormatError(
        f"{where}: expected a list, got {type(value).__name__}")
  return value


def _fields(d: Dict[str, Any], names, where: str) -> Dict[str, Any]:
  missing = [n for n in names if n not in d]
  if missing:
    raise SceneFormatError(f"{where}: missing field(s) {', '.join(missing)}")
  return {n: d[n] for n in names}


def _check_id(value: Any, where: str) -> None:
  if not isinstance(value, str) or not _SAFE_ID.fullmatch(value):
    raise SceneFormatError(
        f"{where}: id {value!r} must be a string matching [A-Za-z0-9_]+")


def _make(cls, kwargs: Dict[str, Any], where: str):
  try:
    return cls(**kwargs)
  except TypeError as e:
    raise SceneFormatError(f"{where}: {e}") from None


def scene_from_dict(data: Dict[str, Any]) -> SceneGraph:
  """Rebuilds a SceneGraph from `scene_to_dict` output.

  Raises SceneFormatError (a ValueError) naming the offending location when
  `data` is not a well-formed snapshot.
  """
  data = _obj(data, "snapshot")
  if data.get("format") != FORMAT:
    raise SceneFormatError(f"not a {FORMAT} snapshot: {data.get('format')!r}")
  head = _fields(data, ("dataset_name", "view_kind", "root_zones", "edges"),
                 "snapshot")
  scene = SceneGraph(head["dataset_name"], head["view_kind"],
                     stage=data.get("stage", ""))

  def build(d: Any, parent: Union[ZoneNode, None], where: str):
    d = _obj(d, where)
    badges = [
        _make(Badge, _obj(b, f"{where}.badges[{i}]"), f"{where}.badges[{i}]")
        for i, b in enumerate(_list(d.get("badges", []), f"{where}.badges"))
    ]
    kind = d.get("kind")
    if kind == "card":
      kwargs = _fields(d, _CARD_FIELDS, where)
      _check_id(kwargs["id"], where)
      node = _make(
          CardNode, {
              **kwargs, "badges": badges,
              "parent_zone_id": parent.id if parent else None
          }, where)
      scene.cards[node.id] = node
      return node
    if kind != "zone":
      raise SceneFormatError(f"{where}: kind must be 'zone' or 'card', got "
                             f"{kind!r}")
    kwargs = _fields(d, _ZONE_FIELDS, where)
    _check_id(kwargs["id"], where)
    node = _make(ZoneNode, {
        **kwargs, "badges": badges,
        "parent_zone_id": parent.id if parent else None
    }, where)
    scene.zones[node.id] = node
    children = _list(
        _fields(d, ("children",), where)["children"], f"{where}.children")
    node.children = [
        build(c, node, f"{where}.children[{i}]") for i, c in enumerate(children)
    ]
    return node

  scene.root_zones = [
      build(z, None, f"root_zones[{i}]")
      for i, z in enumerate(_list(head["root_zones"], "root_zones"))
  ]
  edges = []
  for i, e in enumerate(_list(head["edges"], "edges")):
    where = f"edges[{i}]"
    e = _obj(e, where)
    _check_id(e.get("src"), f"{where}.src")
    _check_id(e.get("dst"), f"{where}.dst")
    edges.append(_make(EdgeSpec, e, where))
  scene.edges = edges
  scene.legend = [
      _make(LegendEntry, _obj(l, f"legend[{i}]"), f"legend[{i}]")
      for i, l in enumerate(_list(data.get("legend", []), "legend"))
  ]
  return scene


def dumps_scene(scene: SceneGraph) -> str:
  return json.dumps(scene_to_dict(scene), indent=1, ensure_ascii=False) + "\n"


def loads_scene(text: str) -> SceneGraph:
  try:
    data = json.loads(text)
  except json.JSONDecodeError as e:
    raise SceneFormatError(f"invalid JSON: {e}") from None
  return scene_from_dict(data)


def dump_scene(scene: SceneGraph, path: Union[str, pathlib.Path]) -> None:
  pathlib.Path(path).write_text(dumps_scene(scene), encoding="utf-8")


def load_scene(path: Union[str, pathlib.Path]) -> SceneGraph:
  try:
    return loads_scene(pathlib.Path(path).read_text(encoding="utf-8"))
  except SceneFormatError as e:
    raise SceneFormatError(f"{path}: {e}") from None
