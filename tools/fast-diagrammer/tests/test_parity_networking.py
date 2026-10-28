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
"""2-networking golden parity gate (spec §2.2).

Level 1 (structural): `stages.networking.build(dataset, view)` must equal the
frozen pre-layout snapshot `golden/2-networking/inputs/<key>.scene.json`,
compared as a canonical dump (zones, children, cards and edges in order,
anchors included).

Level 2 (bytes): rendering the builder scene, and rendering the snapshot,
must both reproduce `golden/2-networking/expected/<key>.drawio` and
`<key>.drawio.svg` exactly. The expected files were frozen from the original
prototype engine before the port, so Level 2 proves the port end to end.

Negative controls (run every time, must be caught): a flipped edge colour and
a swapped card fail Level 1; a one-byte SVG change fails Level 2.
"""

import copy
import dataclasses
import difflib
import json
import os
import pathlib
import sys

import pytest

TESTS_DIR = pathlib.Path(__file__).resolve().parent
APP_DIR = TESTS_DIR.parent
if str(APP_DIR) not in sys.path:
  sys.path.insert(0, str(APP_DIR))
if str(TESTS_DIR) not in sys.path:
  sys.path.insert(0, str(TESTS_DIR))

from fast_diagrammer.scene import render as scene_render  # noqa: E402
from fast_diagrammer.scene.model import CardNode, ZoneNode  # noqa: E402
from fast_diagrammer.scene.serialize import load_scene  # noqa: E402
from fast_diagrammer.stages import networking  # noqa: E402

GOLDEN = TESTS_DIR / "golden" / "2-networking"
INPUTS = GOLDEN / "inputs"
EXPECTED = GOLDEN / "expected"
FIXTURE_DATASETS = TESTS_DIR / "fixtures" / "datasets" / "2-networking"

DATASETS = (
    "classic",
    "hub-and-spokes-ncc",
    "hub-and-spokes-nva",
    "hub-and-spokes-nva-ncc",
    "hub-and-spokes-peerings",
    "hub-and-spokes-vpns",
)
KEYS = tuple(f"{ds}-{view}" for ds in DATASETS for view in networking.VIEWS)

# Canonical pre-layout fields (geometry x/y/w/h is layout output, excluded).
ZONE_FIELDS = ("id", "title", "subtitle", "style_name", "icon", "layout", "gap",
               "align", "dock_to", "dock_side", "dock_align", "dock_gap",
               "parent_zone_id", "badges", "max_cols")
CARD_FIELDS = ("id", "title", "subtitle", "style_name", "icon", "width",
               "height", "stroke_color", "stroke_width", "fill",
               "parent_zone_id", "badges", "dashed")
EDGE_FIELDS = ("src", "dst", "arrow", "label", "color", "stroke_width",
               "dashed", "dash", "head", "source_anchor", "target_anchor")


# --- helpers ----------------------------------------------------------------


def _dataset_roots():
  roots = [FIXTURE_DATASETS]
  env = os.environ.get("FD_FABRIC_ROOT")
  if env:
    roots.append(pathlib.Path(env) / "fast" / "stages" / "2-networking" /
                 "datasets")
  # Fabric layout: tools/fast-diagrammer/ -> ../../fast/stages/...
  roots.append(APP_DIR.parent.parent / "fast" / "stages" / "2-networking" /
               "datasets")
  roots.append(pathlib.Path.home() / "git" / "cloud-foundation-fabric" /
               "fast" / "stages" / "2-networking" / "datasets")
  return roots


def dataset_dir(name):
  for root in _dataset_roots():
    candidate = root / name
    if (candidate / "vpcs").is_dir():
      return candidate
  pytest.fail(f"2-networking dataset {name!r} not found; set FD_FABRIC_ROOT "
              f"(searched: {[str(r) for r in _dataset_roots()]})")


def split_key(key):
  ds, view = key.rsplit("-", 1)
  return ds, view


def _plain(value):
  if dataclasses.is_dataclass(value):
    return dataclasses.asdict(value)
  if isinstance(value, list):
    return [_plain(v) for v in value]
  return value


def canonical(scene):
  """Pre-layout dump: insertion order of zones/cards/edges is significant."""
  return {
      "dataset_name": scene.dataset_name,
      "view_kind": scene.view_kind,
      "root_zones": [z.id for z in scene.root_zones],
      "zones": [{
          **{f: _plain(getattr(z, f)) for f in ZONE_FIELDS},
          "children": [[type(c).__name__, c.id] for c in z.children],
      } for z in scene.zones.values()],
      "cards": [{f: _plain(getattr(c, f)) for f in CARD_FIELDS}
                for c in scene.cards.values()],
      "edges": [{f: _plain(getattr(e, f)) for f in EDGE_FIELDS}
                for e in scene.edges],
  }


def l1_diff(expected_scene, actual_scene):
  """Unified diff of the canonical dumps; empty string means equal."""
  a = json.dumps(canonical(expected_scene), indent=1, sort_keys=False)
  b = json.dumps(canonical(actual_scene), indent=1, sort_keys=False)
  if a == b:
    return ""
  return "".join(
      difflib.unified_diff(a.splitlines(True), b.splitlines(True),
                           "inputs/<key>.scene.json", "stages.networking"))


def bytes_equal(actual, expected):
  return actual == expected


def first_byte_mismatch(actual, expected):
  for i, (x, y) in enumerate(zip(actual, expected)):
    if x != y:
      return i
  return min(len(actual), len(expected))


def oracle_scene(key):
  """Frozen pre-layout snapshot of the scene for `key`."""
  return load_scene(INPUTS / f"{key}.scene.json")


def builder_scene(key):
  ds, view = split_key(key)
  return networking.build(dataset_dir(ds), view, dataset_name=ds)


_ICONS = None


def render_bytes(scene, out_dir, key):
  global _ICONS
  if _ICONS is None:
    _ICONS = scene_render.load_icons()
  out_svg = out_dir / f"{key}.drawio.svg"
  out_drawio = out_dir / f"{key}.drawio"
  scene_render.render(scene, _ICONS, out_svg, out_drawio)
  return out_svg.read_bytes(), out_drawio.read_bytes()


# --- gate preconditions -----------------------------------------------------


def test_golden_set_is_complete():
  assert len(KEYS) == 12
  for key in KEYS:
    assert (INPUTS / f"{key}.scene.json").is_file(), key
    assert (EXPECTED / f"{key}.drawio").is_file(), key
    assert (EXPECTED / f"{key}.drawio.svg").is_file(), key


# --- Level 1: structural ----------------------------------------------------


@pytest.mark.parametrize("key", KEYS)
def test_l1_structural_parity(key):
  diff = l1_diff(oracle_scene(key), builder_scene(key))
  assert not diff, f"L1 SceneGraph mismatch for {key}:\n{diff}"


@pytest.mark.parametrize("key", KEYS)
def test_l2_snapshot_byte_parity(key, tmp_path):
  svg, drawio = render_bytes(oracle_scene(key), tmp_path, key)
  assert bytes_equal(drawio, (EXPECTED / f"{key}.drawio").read_bytes()), key
  assert bytes_equal(svg, (EXPECTED / f"{key}.drawio.svg").read_bytes()), key


@pytest.mark.parametrize("key", KEYS)
def test_builder_is_deterministic(key):
  assert not l1_diff(builder_scene(key), builder_scene(key))


# --- Level 2: bytes ---------------------------------------------------------


@pytest.mark.parametrize("key", KEYS)
def test_l2_byte_parity(key, tmp_path):
  svg, drawio = render_bytes(builder_scene(key), tmp_path, key)
  exp_svg = (EXPECTED / f"{key}.drawio.svg").read_bytes()
  exp_drawio = (EXPECTED / f"{key}.drawio").read_bytes()
  assert bytes_equal(drawio, exp_drawio), (
      f"{key}.drawio differs at byte {first_byte_mismatch(drawio, exp_drawio)}")
  assert bytes_equal(svg, exp_svg), (
      f"{key}.drawio.svg differs at byte {first_byte_mismatch(svg, exp_svg)}")


# --- negative controls (must be caught) -------------------------------------


@pytest.mark.parametrize("key", KEYS)
def test_negative_control_flipped_edge_colour_fails_l1(key):
  oracle = oracle_scene(key)
  bad = copy.deepcopy(builder_scene(key))
  assert bad.edges, f"{key}: no edges to corrupt; control would not execute"
  edge = bad.edges[len(bad.edges) // 2]
  edge.color = "#d93025" if edge.color != "#d93025" else "#1a73e8"
  assert l1_diff(oracle, bad), f"{key}: flipped edge colour was not detected"


@pytest.mark.parametrize("key", KEYS)
def test_negative_control_swapped_card_fails_l1(key):
  oracle = oracle_scene(key)
  bad = copy.deepcopy(builder_scene(key))
  zone = next((z for z in bad.zones.values()
               if sum(isinstance(c, CardNode) for c in z.children) >= 2), None)
  if zone is None:
    # No zone holds two cards: swap the first card into another zone instead.
    zones = [z for z in bad.zones.values() if any(
        isinstance(c, CardNode) for c in z.children)]
    assert len(zones) >= 2, f"{key}: cannot build a swapped-card control"
    card = next(c for c in zones[0].children if isinstance(c, CardNode))
    zones[0].children.remove(card)
    zones[1].children.append(card)
    card.parent_zone_id = zones[1].id
  else:
    idx = [i for i, c in enumerate(zone.children) if isinstance(c, CardNode)]
    i, j = idx[0], idx[1]
    zone.children[i], zone.children[j] = zone.children[j], zone.children[i]
  assert l1_diff(oracle, bad), f"{key}: swapped card was not detected"


@pytest.mark.parametrize("key", KEYS)
def test_negative_control_one_byte_svg_change_fails_l2(key, tmp_path):
  svg, _ = render_bytes(builder_scene(key), tmp_path, key)
  exp_svg = (EXPECTED / f"{key}.drawio.svg").read_bytes()
  pos = len(svg) // 2
  bad = bytearray(svg)
  bad[pos] = (bad[pos] + 1) % 256
  bad = bytes(bad)
  assert bad != svg, "mutation did not change the bytes; control is dead"
  assert not bytes_equal(bad, exp_svg), f"{key}: 1-byte SVG change not detected"


# --- builder hygiene --------------------------------------------------------


_BANNED_EVERYWHERE = ("den" "drite", "fast_net_designer", "ruamel")
_BANNED_IN_BUILDER = ("import re\n", "Zone @", "style: @", "] {")


def hygiene_violations(src, builder=False):
  """Returns the banned markers found in a module's source text."""
  found = [b for b in _BANNED_EVERYWHERE if b in src.lower()]
  if builder:
    found += [b for b in _BANNED_IN_BUILDER if b in src]
  return found


def test_builder_emits_no_dsl_and_parses_nothing():
  """The direct builder constructs objects: no DSL text, no regex parsing."""
  stage = APP_DIR / "fast_diagrammer" / "stages" / "networking.py"
  loader = APP_DIR / "fast_diagrammer" / "datasets" / "networking.py"
  assert not hygiene_violations(stage.read_text(), builder=True)
  assert not hygiene_violations(loader.read_text())


def test_negative_control_hygiene_detector_catches_dsl():
  bad = ('import re\nfrom fast_net_designer import tokens\n'
         'lines.append(\'Zone @Foo {\')\nlines.append(\'  style: @Ghost\')\n')
  found = hygiene_violations(bad, builder=True)
  assert set(found) >= {"fast_net_designer", "import re\n", "Zone @",
                        "style: @"}, found
