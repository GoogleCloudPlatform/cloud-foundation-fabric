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
"""Scene engine tests: router robustness, overlap gate, builder validation.

Every gate assertion is paired with a negative control proving the gate (or
the fix under test) is what makes it pass.
"""

import inspect
import itertools
import math

import pytest

from conftest import GOLDEN_KEYS, golden_scene
from fast_diagrammer.scene import router
from fast_diagrammer.scene.layout import (_zone_header_height, _zone_padding,
                                          layout_scene)
from fast_diagrammer.scene.model import (STYLE_PRESETS, Badge, CardNode,
                                         SceneGraph, ZoneNode, make_card,
                                         make_edge, make_zone, resolve_color)
from fast_diagrammer.scene.router import (PORT_PITCH, route_all_edges,
                                          verify_no_arrow_overlaps)

MULTI = "0-org-setup"
NET = "2-networking"

# --------------------------------------------------------------------------
# helpers
# --------------------------------------------------------------------------


def _route(sc):
  layout_scene(sc)
  return route_all_edges(sc)


def _segments(pts):
  return [(pts[i], pts[i + 1]) for i in range(len(pts) - 1)]


def _proper_crossings(polylines):
  """Pairs of edges whose horizontal and vertical segments strictly cross."""
  out = set()
  for (i, a), (j, b) in itertools.combinations(sorted(polylines.items()), 2):
    for p, q in itertools.product(_segments(a), _segments(b)):
      for h, v in ((p, q), (q, p)):
        (hx1, hy1), (hx2, hy2) = h
        (vx1, vy1), (vx2, vy2) = v
        if abs(hy1 - hy2) > 0.5 or abs(vx1 - vx2) > 0.5:
          continue
        if (min(hx1, hx2) + 0.5 < vx1 < max(hx1, hx2) - 0.5 and
            min(vy1, vy2) + 0.5 < hy1 < max(vy1, vy2) - 0.5):
          out.add((i, j))
  return out


def _fan_scene(n, stage=MULTI):
  """Organization over one row of `n` folders, `bottom -> top` edges."""
  sc = SceneGraph("t", "hierarchy", stage=stage)
  col = sc.add_zone(make_zone("col", "@Ghost", gap=70))
  top = sc.add_zone(make_zone("top", "@Ghost", layout="row"), col)
  sc.add_card(make_card("org", "Organization", "id: 1"), top)
  mid = sc.add_zone(
      make_zone("mid", "@Ghost", layout="row", align="start", gap=40), col)
  for i in range(n):
    sc.add_card(make_card(f"f{i}", f"Folder: {i}", "x"), mid)
    sc.add_edge(
        make_edge("org", f"f{i}", source_anchor="bottom", target_anchor="top"))
  return sc


def _two_tier_scene(folders=4, projects=3):
  """Organization -> folders -> projects, every tier a row."""
  sc = SceneGraph("t", "hierarchy", stage=MULTI)
  col = sc.add_zone(make_zone("col", "@Ghost", gap=70))
  top = sc.add_zone(make_zone("top", "@Ghost", layout="row"), col)
  sc.add_card(make_card("org", "Organization", "id: 1"), top)
  mid = sc.add_zone(
      make_zone("mid", "@Ghost", layout="row", align="start", gap=40), col)
  bot = sc.add_zone(
      make_zone("bot", "@Ghost", layout="row", align="start", gap=40), col)
  for i in range(folders):
    sc.add_card(make_card(f"f{i}", f"Folder: {i}", "x"), mid)
    sc.add_edge(
        make_edge("org", f"f{i}", source_anchor="bottom", target_anchor="top"))
    for j in range(projects):
      sc.add_card(make_card(f"p{i}{j}", f"Project {i}{j}", "x"), bot)
      sc.add_edge(
          make_edge(f"f{i}", f"p{i}{j}", source_anchor="bottom",
                    target_anchor="top"))
  return sc


def _parallel_scene(n, layout, stage):
  sc = SceneGraph("p", "topology", stage=stage)
  z = sc.add_zone(make_zone("z", "@ProjectZone", "P", layout=layout))
  sc.add_card(make_card("a", "A"), z)
  sc.add_card(make_card("b", "B"), z)
  for i in range(n):
    sc.add_edge(make_edge("a", "b", label=f"e{i}"))
  return sc


def _legacy_port_fracs(n, length):
  del length
  return [0.5] if n == 1 else [0.20 + 0.60 * (r / (n - 1)) for r in range(n)]


# --------------------------------------------------------------------------
# H7: org-tree fan-out
# --------------------------------------------------------------------------


@pytest.mark.parametrize("n", [3, 6, 10, 16])
def test_org_fanout_row_passes_gate_without_crossings(n):
  sc = _fan_scene(n)
  _, polylines, _ = _route(sc)
  assert all(
      (e.source_anchor, e.target_anchor) == ("bottom", "top") for e in sc.edges)
  assert verify_no_arrow_overlaps(polylines, sc) == []
  assert _proper_crossings(polylines) == set()


def test_org_two_tier_tree_passes_gate():
  sc = _two_tier_scene()
  _, polylines, _ = _route(sc)
  assert verify_no_arrow_overlaps(polylines, sc) == []
  # Folder 1 sits right above project 12: the fan's middle drop shares x
  # with that project's rise, and the lanes keep them from running together.
  f1, p12 = sc.cards["f1"], sc.cards["p12"]
  assert f1.x == p12.x


def test_tree_lanes_negative_control(monkeypatch):
  """Without lane assignment the legacy de-overlap trips the gate."""
  monkeypatch.setattr(router, "_assign_tree_lanes", lambda ctx, pl: set())
  sc = _fan_scene(16)
  _, polylines, _ = _route(sc)
  assert verify_no_arrow_overlaps(polylines, sc)
  sc = _two_tier_scene()
  _, polylines, _ = _route(sc)
  assert any(
      "Vertical overlap" in e for e in verify_no_arrow_overlaps(polylines, sc))


def test_tree_route_single_lane_keeps_bar_20px_before_target():
  sc = _fan_scene(1)
  _, polylines, _ = _route(sc)
  pts = polylines[0]
  assert abs(pts[1][1] - (sc.cards["f0"].y - 20.0)) < 0.01


def test_tree_lanes_are_deterministic():
  a = _route(_two_tier_scene())[1]
  b = _route(_two_tier_scene())[1]
  assert a == b


# --------------------------------------------------------------------------
# H8: parallel edges between one pair
# --------------------------------------------------------------------------


@pytest.mark.parametrize("stage", [MULTI, NET, ""])
@pytest.mark.parametrize("layout", ["row", "column"])
@pytest.mark.parametrize("n", [5, 8, 25])
def test_parallel_edges_pass_gate(n, layout, stage):
  sc = _parallel_scene(n, layout, stage)
  ports, polylines, _ = _route(sc)
  assert len(polylines) == n
  assert verify_no_arrow_overlaps(polylines, sc) == []
  for card in ("a", "b"):
    side = {}
    for i, e in enumerate(sc.edges):
      role, cid, anchor = (("src", e.src, e.source_anchor) if e.src == card else
                           ("dst", e.dst, e.target_anchor))
      side.setdefault(anchor, []).append(ports[(i, role)])
    for anchor, pts in side.items():
      axis = 1 if anchor in ("left", "right") else 0
      coords = sorted(p[axis] for p in pts)
      assert min(b - a for a, b in zip(coords, coords[1:])) >= PORT_PITCH - 1e-6


def test_cards_grow_to_fit_their_ports():
  sc = _parallel_scene(25, "row", MULTI)
  layout_scene(sc)
  assert sc.cards["a"].height >= 2 * router.PORT_MARGIN + PORT_PITCH * 24
  sc = _parallel_scene(3, "row", MULTI)
  layout_scene(sc)
  assert sc.cards["a"].height == 58.0  # no growth when the ports fit


def test_port_fracs_widen_only_when_needed():
  assert router._port_fracs(3, 58.0) == _legacy_port_fracs(3, 58.0)
  fr = router._port_fracs(5, 58.0)
  pitch = min(b - a for a, b in zip(fr, fr[1:])) * 58.0
  assert pitch >= PORT_PITCH - 1e-9
  assert fr[0] * 58.0 >= router.PORT_MARGIN - 1e-9
  assert router._port_fracs(3, 0.0) == [0.5, 0.5, 0.5]


def test_parallel_edges_negative_control(monkeypatch):
  """The legacy 60 % spread (8.7 px pitch for 5 ports) trips the gate."""
  monkeypatch.setattr(router, "_port_fracs", _legacy_port_fracs)
  sc = _parallel_scene(5, "column", MULTI)
  _, polylines, _ = _route(sc)
  assert verify_no_arrow_overlaps(polylines, sc)


# --------------------------------------------------------------------------
# H9: zone endpoints under networking semantics
# --------------------------------------------------------------------------


@pytest.mark.parametrize("stage", ["", NET])
def test_zone_endpoint_long_span_networking(stage):
  sc = SceneGraph("z", "topology", stage=stage)
  root = sc.add_zone(make_zone("root", "@ArchitectureRoot", "R", layout="row"))
  for zid, cid in (("zl", "a"), ("zm", "m"), ("zr", "b")):
    z = sc.add_zone(make_zone(zid, "@VpcZone", zid.upper()), root)
    sc.add_card(make_card(cid, cid.upper()), z)
  sc.add_edge(make_edge("zl", "b", label="zone to card over a card"))
  _, polylines, _ = _route(sc)
  assert verify_no_arrow_overlaps(polylines, sc) == []
  zl = sc.zones["zl"]
  x0, y0 = polylines[0][0]
  assert abs(x0 - (zl.x + zl.w)) < 0.01 and zl.y <= y0 <= zl.y + zl.h
  assert len(polylines[0]) == 6  # bridged over the middle card


# --------------------------------------------------------------------------
# M17: bracket ordering
# --------------------------------------------------------------------------


def _bracket_scene(n, stage):
  sc = SceneGraph("b", "topology", stage=stage)
  z = sc.add_zone(make_zone("z", "@ProjectZone", "P", layout="column"))
  sc.add_card(make_card("a", "A"), z)
  sc.add_card(make_card("b", "B"), z)
  for i in range(n):
    sc.add_edge(make_edge("a", "b", label=f"e{i}"))
  return sc


@pytest.mark.parametrize("stage", [MULTI, NET])
@pytest.mark.parametrize("n", [2, 3, 5])
def test_equal_span_brackets_nest_without_crossing(n, stage):
  sc = _bracket_scene(n, stage)
  _, polylines, _ = _route(sc)
  assert all(e.source_anchor == e.target_anchor for e in sc.edges)
  assert verify_no_arrow_overlaps(polylines, sc) == []
  assert _proper_crossings(polylines) == set()


def test_bracket_order_ignores_float_noise():
  sc = SceneGraph("b", "topology", stage=MULTI)
  sc.edges = [
      make_edge("a", "b", source_anchor="right", target_anchor="right"),
      make_edge("c", "d", source_anchor="right", target_anchor="right"),
  ]
  ports = {
      (0, "src"): (100.0, 0.0, 1.0, 0.5),
      (0, "dst"): (100.0, 76.0, 1.0, 0.5),
      (1, "src"): (100.0, 0.0, 1.0, 0.5),
      (1, "dst"): (100.0, 75.99999999999999, 1.0, 0.5),
  }
  ctx = router._Ctx(scene=sc, multi=True, canvas_mid_y=0.0, ancestors=None)
  assert router._bracket_offsets(ctx, ports) == {0: 20.0, 1: 35.0}


def test_bracket_crossing_negative_control():
  """The crossing detector fires on two shifted (not nested) brackets."""
  shifted = {
      0: [(100, 10), (120, 10), (120, 90), (100, 90)],
      1: [(100, 20), (135, 20), (135, 100), (100, 100)],
  }
  assert _proper_crossings(shifted) == {(0, 1)}


# --------------------------------------------------------------------------
# M18: degenerate geometry
# --------------------------------------------------------------------------


def test_zero_height_zone_endpoint_with_colliding_stubs():
  sc = SceneGraph("g", "topology", stage=MULTI)
  row = sc.add_zone(make_zone("row", "@Ghost", layout="row", gap=80))
  sc.add_card(make_card("a", "A"), row)
  sc.add_zone(make_zone("empty", "@Ghost"), row)
  sc.add_card(make_card("b", "B"), row)
  for src in ("a", "b", "a", "b"):
    sc.add_edge(make_edge(src, "empty"))
  layout_scene(sc)
  assert sc.zones["empty"].h == 0.0
  ports, polylines, _ = route_all_edges(sc)
  assert len(polylines) == 4
  assert all(math.isfinite(v) for p in ports.values() for v in p)
  assert router._rel(5.0, 0.0, 0.0) == 0.5


@pytest.mark.parametrize("field", ["width", "height"])
@pytest.mark.parametrize("value", [float("nan"), float("inf"), 0.0, -1.0])
def test_non_finite_or_empty_card_size_is_rejected(field, value):
  with pytest.raises(ValueError, match=field):
    make_card("c", "C", **{field: value})
  sc = SceneGraph("n", "topology", stage=MULTI)
  z = sc.add_zone(make_zone("z", "@ProjectZone", "P"))
  sc.add_card(make_card("c", "C"), z)
  setattr(sc.cards["c"], field, value)  # bypasses the builder
  with pytest.raises(ValueError, match=field):
    layout_scene(sc)


# --------------------------------------------------------------------------
# M19: builder API validation
# --------------------------------------------------------------------------


@pytest.mark.parametrize("kwargs", [
    {
        "style": "@NoSuchZone"
    },
    {
        "style": "@ProductCard"
    },
    {
        "layout": "diagonal"
    },
    {
        "align": "middle"
    },
    {
        "gap": -1
    },
    {
        "gap": float("nan")
    },
    {
        "dock_to": "x"
    },
    {
        "dock_side": "left"
    },
    {
        "dock_to": "x",
        "dock_side": "top"
    },
    {
        "dock_to": "x",
        "dock_side": "left",
        "dock_align": "end"
    },
    {
        "dock_gap": -5
    },
    {
        "max_cols": 0
    },
    {
        "badges": [Badge("b", "loud")]
    },
])
def test_make_zone_rejects_invalid_input(kwargs):
  args = {"style": "@ProjectZone", **kwargs}
  style = args.pop("style")
  with pytest.raises(ValueError):
    make_zone("z", style, "Z", **args)


@pytest.mark.parametrize("kwargs", [
    {
        "style": "@NoSuchCard"
    },
    {
        "style": "@ProjectZone"
    },
    {
        "stroke_color": "not-a-colour\" onload=\"x"
    },
    {
        "stroke_color": "$Nope"
    },
    {
        "stroke_color": "#12345"
    },
    {
        "stroke_color": "red"
    },
    {
        "fill": "url(#x)"
    },
    {
        "stroke_width": -1
    },
    {
        "badges": [Badge("b", "loud")]
    },
])
def test_make_card_rejects_invalid_input(kwargs):
  args = dict(kwargs)
  style = args.pop("style", "@ProductCard")
  with pytest.raises(ValueError):
    make_card("c", "C", "", style, **args)


@pytest.mark.parametrize("kwargs", [
    {
        "source_anchor": "diagonal"
    },
    {
        "target_anchor": "centre"
    },
    {
        "color": "$Nope"
    },
    {
        "color": "blue"
    },
    {
        "arrow": "==>"
    },
    {
        "stroke_width": float("inf")
    },
])
def test_make_edge_rejects_invalid_input(kwargs):
  with pytest.raises(ValueError):
    make_edge("a", "b", **kwargs)


def test_valid_colours_are_accepted():
  assert resolve_color("$GcpBlue") == "#1a73e8"
  assert resolve_color("#AbCdEf") == "#AbCdEf"
  assert resolve_color("transparent") == "transparent"
  assert resolve_color("none") == "none"
  assert resolve_color(None) == "#202124"
  assert make_card("c", "C", fill="$FolderFill").fill == "#f1f3f4"
  assert make_edge("a", "b", color="$TealStroke").color == "#007b83"


def test_card_and_zone_ids_must_differ():
  sc = SceneGraph("i", "topology")
  z = sc.add_zone(make_zone("x", "@ProjectZone", "P"))
  with pytest.raises(ValueError, match="already used by a zone"):
    sc.add_card(make_card("x", "A"), z)
  sc.add_card(make_card("c", "C"), z)
  with pytest.raises(ValueError, match="already used by a card"):
    sc.add_zone(make_zone("c", "@ProjectZone", "Q"))
  # A builder writing the dicts directly is caught at layout time.
  sc.cards["x"] = make_card("x", "dup")
  with pytest.raises(ValueError, match="both a card and a zone"):
    layout_scene(sc)


def test_cards_outside_the_zone_tree_are_rejected():
  sc = SceneGraph("o", "topology")
  sc.add_card(make_card("a", "A"), None)
  with pytest.raises(ValueError, match="never laid out"):
    layout_scene(sc)
  sc = SceneGraph("d", "topology")
  z = sc.add_zone(make_zone("z", "@ProjectZone", "P"))
  z.children.append(sc.add_card(make_card("a", "A"), z))
  with pytest.raises(ValueError, match="more than once"):
    layout_scene(sc)


# --------------------------------------------------------------------------
# M20: overlap gate false negatives
# --------------------------------------------------------------------------


def test_gate_flags_same_edge_retrace():
  errs = verify_no_arrow_overlaps({0: [(0, 0), (0, 80), (0, 30)]})
  assert errs and "retrace on edge 0" in errs[0]
  errs = verify_no_arrow_overlaps({0: [(0, 0), (60, 0), (20, 0), (20, 40)]})
  assert errs and "Horizontal retrace" in errs[0]
  # A straight run split by a zero-length segment is not a retrace.
  assert verify_no_arrow_overlaps({0: [(0, 0), (0, 40), (0, 40),
                                       (0, 90)]}) == []


def _crossing_scene():
  sc = SceneGraph("x", "topology", stage=MULTI)
  root = sc.add_zone(make_zone("root", "@Ghost", layout="row", gap=60))
  sc.add_card(make_card("a", "A"), root)
  sc.add_card(make_card("mid", "M"), root)
  p = sc.add_zone(make_zone("P", "@ProjectZone", "P"), root)
  sc.add_card(make_card("inner", "I"), p)
  sc.add_edge(make_edge("a", "P"))
  layout_scene(sc)
  return sc


def test_gate_flags_route_through_a_card():
  sc = _crossing_scene()
  a, mid, inner = sc.cards["a"], sc.cards["mid"], sc.cards["inner"]
  y = mid.y + mid.height / 2.0
  straight = {0: [(a.x + a.width, y), (inner.x + inner.width / 2.0, y)]}
  errs = verify_no_arrow_overlaps(straight, sc)
  assert any("crosses card mid" in e for e in errs)
  # The card inside the endpoint zone and the endpoint itself are exempt.
  assert not any("inner" in e or "card a " in e for e in errs)
  # Without the scene the sweep does not run (legacy call signature).
  assert verify_no_arrow_overlaps(straight) == []


def test_gate_accepts_routes_that_touch_a_card_border():
  sc = _crossing_scene()
  mid = sc.cards["mid"]
  along = {0: [(mid.x - 10, mid.y), (mid.x + mid.width + 10, mid.y)]}
  assert verify_no_arrow_overlaps(along, sc) == []


@pytest.mark.parametrize("key", GOLDEN_KEYS)
def test_goldens_pass_the_full_gate(key):
  sc = golden_scene(key)
  _, polylines, _ = _route(sc)
  assert verify_no_arrow_overlaps(polylines, sc) == []


def test_side_by_side_touching_cards_do_not_fold_back():
  sc = SceneGraph("g", "topology", stage=MULTI)
  z = sc.add_zone(make_zone("z", "@Ghost", layout="row", gap=0))
  sc.add_card(make_card("a", "A"), z)
  sc.add_card(make_card("b", "B"), z)
  sc.add_edge(make_edge("a", "b"))
  _, polylines, _ = _route(sc)
  assert (sc.edges[0].source_anchor, sc.edges[0].target_anchor) == ("right",
                                                                    "left")
  assert verify_no_arrow_overlaps(polylines, sc) == []


def _blocked_bracket_scene(stage):
  """p0 | p1 in a grid row, `ext` below p0: a right bracket crosses p1."""
  sc = SceneGraph("b", "hierarchy", stage=stage)
  root = sc.add_zone(make_zone("root", "@Ghost", gap=0))
  grid = sc.add_zone(
      make_zone("g", "@FolderZone", "F", layout="grid", max_cols=2), root)
  sc.add_card(make_card("p0", "P0"), grid)
  sc.add_card(make_card("p1", "P1"), grid)
  low = sc.add_zone(make_zone("low", "@Ghost", align="start"), root)
  sc.add_card(make_card("ext", "Ext"), low)
  sc.add_edge(make_edge("p0", "ext"))
  return sc


def test_multistage_bracket_avoids_the_blocked_side():
  sc = _blocked_bracket_scene(MULTI)
  _, polylines, _ = _route(sc)
  assert sc.edges[0].source_anchor == "left"
  assert verify_no_arrow_overlaps(polylines, sc) == []


def test_blocked_bracket_negative_control():
  """Networking semantics keep the load-based side; the sweep catches it."""
  sc = _blocked_bracket_scene("")
  _, polylines, _ = _route(sc)
  assert sc.edges[0].source_anchor == "right"
  assert any(
      "crosses card p1" in e for e in verify_no_arrow_overlaps(polylines, sc))


# --------------------------------------------------------------------------
# L1: dock and enum values
# --------------------------------------------------------------------------


def _docked_scene(**dock):
  sc = SceneGraph("d", "topology", stage=NET)
  root = sc.add_zone(make_zone("root", "@ArchitectureRoot", "R"))
  proj = sc.add_zone(make_zone("proj", "@ProjectZone", "P"), root)
  sc.add_card(make_card("a", "A"), proj)
  d = sc.add_zone(make_zone("ext", "@ExternalZone", "E", **dock))
  sc.add_card(make_card("b", "B"), d)
  return sc


def test_dock_left_and_right():
  sc = _docked_scene(dock_to="proj", dock_side="left", dock_align="start")
  layout_scene(sc)
  ext, root, proj = sc.zones["ext"], sc.zones["root"], sc.zones["proj"]
  assert ext.x + ext.w + 56.0 == pytest.approx(root.x)
  assert ext.y == pytest.approx(proj.y)
  sc = _docked_scene(dock_to="proj", dock_side="right", dock_gap=30)
  layout_scene(sc)
  ext, root, proj = sc.zones["ext"], sc.zones["root"], sc.zones["proj"]
  assert ext.x == pytest.approx(root.x + root.w + 30.0)
  assert ext.y + ext.h / 2.0 == pytest.approx(proj.y + proj.h / 2.0)


@pytest.mark.parametrize("target", ["missing", "a", "ext"])
def test_dock_to_must_be_a_laid_out_zone(target):
  sc = _docked_scene(dock_to=target, dock_side="left")
  with pytest.raises(ValueError, match="dock_to"):
    layout_scene(sc)


@pytest.mark.parametrize("field,value", [("layout", "diagonal"),
                                         ("align", "middle"),
                                         ("dock_side", "top"), ("max_cols", 0)])
def test_unknown_zone_values_raise_at_layout(field, value):
  sc = SceneGraph("u", "topology", stage=MULTI)
  z = sc.add_zone(ZoneNode("z", "Z", style_name="@ProjectZone"))
  sc.add_card(CardNode("c", "C", ""), z)
  setattr(z, field, value)
  if field == "dock_side":
    z.dock_to = "z"
  with pytest.raises(ValueError):
    layout_scene(sc)


def test_unknown_anchor_raises_at_layout():
  sc = _parallel_scene(1, "row", MULTI)
  sc.edges[0].source_anchor = "diagonal"
  with pytest.raises(ValueError, match="source_anchor"):
    layout_scene(sc)


# --------------------------------------------------------------------------
# L3 / L4: preset-driven zone metrics, router structure
# --------------------------------------------------------------------------


def test_zone_metrics_come_from_presets(monkeypatch):
  for style, preset in STYLE_PRESETS.items():
    if "width" in preset:
      continue
    z = ZoneNode("z", "T", style_name=style)
    assert _zone_padding(z) == float(preset.get("padding", 16.0))
    if style != "@Ghost":
      assert _zone_header_height(z) == float(preset.get("headerHeight", 32.0))
  patched = dict(STYLE_PRESETS["@FolderZone"], padding=40, headerHeight=50)
  monkeypatch.setitem(STYLE_PRESETS, "@FolderZone", patched)
  z = ZoneNode("z", "T", style_name="@FolderZone")
  assert _zone_padding(z) == 40.0 and _zone_header_height(z) == 50.0
  assert _zone_header_height(ZoneNode("g", "T", style_name="@Ghost")) == 0.0


def test_router_passes_and_ancestor_index():
  assert "scene" not in inspect.signature(router._free_h_offset).parameters
  sc = SceneGraph("a", "topology", stage=MULTI)
  outer = sc.add_zone(make_zone("outer", "@FolderZone", "O"))
  mid = sc.add_zone(make_zone("mid", "@ProjectZone", "M"), outer)
  sc.add_card(make_card("c", "C"), mid)
  other = sc.add_zone(make_zone("other", "@ProjectZone", "X"))
  sc.add_card(make_card("d", "D"), other)
  card_anc, zone_anc = router.ancestor_index(sc)
  assert card_anc["c"] == {"outer", "mid"} and zone_anc["mid"] == {"outer"}
  assert zone_anc["outer"] == frozenset() and card_anc["d"] == {"other"}
  index = router.ancestor_index(sc)
  for src, dst in (("c", "d"), ("mid", "d"), ("c", "other")):
    assert (router.edge_obstacles(sc, src, dst,
                                  index) == router.edge_obstacles(sc, src, dst))
  assert set(router.edge_obstacles(sc, "c", "d")) == {"c", "d"}


# --------------------------------------------------------------------------
# Trunk edges: one shared source port and trunk per parent side
# --------------------------------------------------------------------------


def _trunk_scene(trunk=True):
  """`_two_tier_scene` with every hierarchy edge marked as a trunk edge."""
  sc = _two_tier_scene()
  for e in sc.edges:
    e.trunk = trunk
  return sc


def test_trunk_edges_share_the_centre_bottom_port():
  sc = _trunk_scene()
  ports, polylines, _ = _route(sc)
  by_src = {}
  for i, e in enumerate(sc.edges):
    by_src.setdefault(e.src, set()).add(ports[(i, "src")])
  for src, starts in by_src.items():
    assert len(starts) == 1, src
    (x, y, rel_x, rel_y), = starts
    card = sc.cards[src]
    assert (rel_x, rel_y) == (0.5, 1.0)
    assert x == card.x + card.width / 2.0 and y == card.y + card.height
  assert verify_no_arrow_overlaps(polylines, sc) == []


def test_trunk_overlaps_are_only_accepted_within_one_trunk():
  """Negative control: the same polylines fail the gate without `trunk`."""
  sc = _trunk_scene()
  _, polylines, _ = _route(sc)
  assert verify_no_arrow_overlaps(polylines, sc) == []
  assert verify_no_arrow_overlaps(polylines)  # no scene: no trunk exemption
  for e in sc.edges:
    e.trunk = False
  assert verify_no_arrow_overlaps(polylines, sc)


def test_trunk_slot_shares_a_side_with_other_edges():
  sc = _fan_scene(3)
  for e in sc.edges:
    e.trunk = True
  sc.add_card(make_card("x", "Extra", "x"), sc.zones["mid"])
  sc.add_edge(make_edge("org", "x", source_anchor="bottom",
                        target_anchor="top"))
  ports, polylines, _ = _route(sc)
  trunk_starts = {ports[(i, "src")] for i, e in enumerate(sc.edges) if e.trunk}
  other = ports[(len(sc.edges) - 1, "src")]
  assert len(trunk_starts) == 1 and other not in trunk_starts
  assert verify_no_arrow_overlaps(polylines, sc) == []


def test_trunk_is_serialized_only_when_set():
  from fast_diagrammer.scene.serialize import scene_from_dict, scene_to_dict
  plain = scene_to_dict(_two_tier_scene())
  assert all("trunk" not in e for e in plain["edges"])
  data = scene_to_dict(_trunk_scene())
  assert all(e["trunk"] is True for e in data["edges"])
  assert all(e.trunk for e in scene_from_dict(data).edges)
