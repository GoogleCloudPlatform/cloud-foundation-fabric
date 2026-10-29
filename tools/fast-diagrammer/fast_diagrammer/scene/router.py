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
"""Obstacle-aware zero-overlap orthogonal edge router.

Ports are slotted on the anchored card side; same-side edges become nested
3-segment C-brackets; long spans that would cross cards become 5-segment
bridges over or under them; multi-stage tree edges (`bottom -> top`) get one
fork-bar lane each in the corridor between tiers. Remaining inner segments are
then de-overlapped horizontally and vertically, and label pills are placed.
The router is a pure function of the laid-out `SceneGraph`; it never moves
cards. `verify_no_arrow_overlaps` is the mechanical gate run on the result.
"""

from dataclasses import dataclass, field
import math
from typing import Dict, FrozenSet, List, Optional, Set, Tuple, Union

from .model import CardNode, SceneGraph, ZoneNode

Point = Tuple[float, float]
Polylines = Dict[int, List[Point]]
PortCoords = Dict[Tuple[int, str], Tuple[float, float, float, float]]
# (card ancestors, zone ancestors): id -> ids of every enclosing zone.
AncestorIndex = Tuple[Dict[str, FrozenSet[str]], Dict[str, FrozenSet[str]]]

# Zone styles that act as routing obstacles in multi-stage scenes (see
# `is_multistage`). 2-networking keeps card-only obstacles and `@VpcZone` /
# `@SubGroupWhite` bridge spans.
OBSTACLE_ZONE_STYLES = (
    "@ProjectZone",
    "@VpcZone",
    "@SubGroupWhite",
    "@FolderZone",
    "@BillingZone",
    "@PerimeterZone",
    "@PerimeterDryRunZone",
    "@SourcesZone",
    "@ExternalZone",
    "@OrganizationZone",
)

# Multi-stage parallel-bar spacing (the overlap gate flags < 5 px).
H_SEP = 9.0
# Tightest spacing between tree fork-bar lanes when a corridor is crowded.
MIN_LANE_SEP = 6.0
# Minimum distance between two ports on one side (the stub separation test
# below treats < 9 px as a collision) and the margin kept from the corners.
# `layout_scene` grows cards whose sides cannot hold their ports at this pitch.
PORT_PITCH = 10.0
PORT_MARGIN = 6.0
# Horizontal stubs closer than this (with overlapping x ranges) collide.
STUB_SEP = 9.0
# Overlap gate thresholds: parallel segments closer than GATE_SEP that share
# more than GATE_MIN_RUN px of length overlap.
GATE_SEP = 5.0
GATE_MIN_RUN = 4.0

_INF = float("inf")


def is_multistage(scene: SceneGraph) -> bool:
  """True for non-networking scenes (stage set and not `2-networking`)."""
  return bool(scene.stage) and scene.stage != "2-networking"


def endpoint(scene: SceneGraph,
             eid: str) -> Optional[Union[CardNode, ZoneNode]]:
  """Resolves an edge endpoint: a card id, else a zone id (else None)."""
  return scene.cards.get(eid) or scene.zones.get(eid)


def ancestor_index(scene: SceneGraph) -> AncestorIndex:
  """Ancestor zone ids of every card and every zone, computed once."""
  zone_anc: Dict[str, FrozenSet[str]] = {}
  for zid in sorted(scene.zones):
    chain: List[str] = []
    cur: Optional[str] = zid
    while cur is not None and cur not in zone_anc and cur not in chain:
      chain.append(cur)
      parent = scene.zones[cur].parent_zone_id
      cur = parent if parent in scene.zones else None
    acc: Set[str] = set()
    if cur is not None and cur in zone_anc:
      acc = set(zone_anc[cur]) | {cur}
    for z in reversed(chain):
      zone_anc[z] = frozenset(acc)
      acc.add(z)
  card_anc: Dict[str, FrozenSet[str]] = {}
  for cid, c in scene.cards.items():
    pz = c.parent_zone_id
    card_anc[cid] = (zone_anc[pz] | {pz}) if pz in scene.zones else frozenset()
  return card_anc, zone_anc


def _ancestors_of(index: AncestorIndex, scene: SceneGraph,
                  eid: str) -> FrozenSet[str]:
  card_anc, zone_anc = index
  if eid in scene.cards:
    return card_anc[eid]
  return zone_anc.get(eid, frozenset())


def edge_obstacles(
    scene: SceneGraph, src_id: str, dst_id: str,
    ancestors: Optional[AncestorIndex] = None) -> Dict[str, object]:
  """Boxes an edge between `src_id` and `dst_id` must avoid.

  2-networking: exactly `scene.cards`. Multi-stage: cards plus
  `OBSTACLE_ZONE_STYLES` zones, minus the endpoint zones, their descendants
  and every ancestor of either endpoint (an edge may enter the containers it
  starts or ends in, and must route around the others). Pass a prebuilt
  `ancestor_index(scene)` when calling this for many edges.
  """
  if not is_multistage(scene):
    return scene.cards
  index = ancestors if ancestors is not None else ancestor_index(scene)
  card_anc, zone_anc = index
  open_zones = (_ancestors_of(index, scene, src_id) |
                _ancestors_of(index, scene, dst_id))
  endpoint_zones = {
      i for i in (src_id, dst_id) if i in scene.zones and i not in scene.cards
  }
  obstacles: Dict[str, object] = {}
  for cid, c in scene.cards.items():
    if not card_anc[cid] & endpoint_zones:
      obstacles[cid] = c
  for zid, z in scene.zones.items():
    if (z.style_name in OBSTACLE_ZONE_STYLES and zid not in open_zones and
        zid not in endpoint_zones and not zone_anc[zid] & endpoint_zones):
      obstacles[zid] = z
  return obstacles


def _segment_hits_any_card(
    x1: float,
    y1: float,
    x2: float,
    y2: float,
    cards: Dict[str, CardNode],
    ignore_ids: Tuple[str, str],
    pad: float = 6.0,
) -> bool:
  xmin, xmax = min(x1, x2), max(x1, x2)
  ymin, ymax = min(y1, y2), max(y1, y2)
  for cid, c in cards.items():
    if cid in ignore_ids:
      continue
    cx1, cy1 = c.x - pad, c.y - pad
    cx2, cy2 = c.x + c.width + pad, c.y + c.height + pad
    if xmax > cx1 and xmin < cx2 and ymax > cy1 and ymin < cy2:
      return True
  return False


def _clear_z_channel(sx: float, sy: float, tx: float, ty: float, src_side: str,
                     obstacles, ignore) -> Optional[float]:
  """Multi-stage: first clear vertical channel x for a 3-segment Z route."""
  step = 1.0 if src_side == "right" else -1.0
  cands = [(sx + tx) / 2.0, sx + 28.0 * step, sx + 44.0 * step,
           tx - 28.0 * step, tx - 44.0 * step]
  lo, hi = min(sx, tx), max(sx, tx)
  for cx in cands:
    if not lo + 12.0 <= cx <= hi - 12.0:
      continue
    if not (_segment_hits_any_card(sx, sy, cx, sy, obstacles, ignore) or
            _segment_hits_any_card(cx, sy, cx, ty, obstacles, ignore) or
            _segment_hits_any_card(cx, ty, tx, ty, obstacles, ignore)):
      return cx
  return None


def _inner_range(pts: List[Point], si: int, axis: int) -> Tuple[float, float]:
  """Allowed coordinate range for moving inner segment `si` along `axis`.

  When the segment currently lies between its neighbouring points (a Z or
  fork bar), it must stay there (8 px margin) or the route would fold back
  on itself; otherwise (bridges, brackets) it is unconstrained.
  """
  a, b = pts[si - 1][axis], pts[si + 2][axis]
  cur = pts[si][axis]
  lo, hi = min(a, b), max(a, b)
  if lo + 8.0 <= cur <= hi - 8.0:
    return lo + 8.0, hi - 8.0
  return -_INF, _INF


def _free_h_offset(pts: List[Point], si: int, hy: float, hxmin: float,
                   hxmax: float, placed_h: List[Tuple[float, float, float]],
                   obstacles) -> float:
  """Multi-stage horizontal de-overlap: nearest free y, both directions.

  Free = no placed segment within `H_SEP` px over the same x range, no obstacle
  box hit, and inside `_inner_range`. Falls back to `hy` (the overlap gate
  then reports it) rather than pushing the bar into a card.
  """
  lo, hi = _inner_range(pts, si, axis=1)
  e_ids = ("", "")

  def free(y: float) -> bool:
    if not lo <= y <= hi:
      return False
    if any(
        abs(y - py) < H_SEP and hxmax > pxmin - 8.0 and hxmin < pxmax + 8.0
        for py, pxmin, pxmax in placed_h):
      return False
    return y == hy or not _segment_hits_any_card(hxmin, y, hxmax, y, obstacles,
                                                 e_ids, pad=3.0)

  if free(hy):
    return hy
  for k in range(1, 60):
    for cand in (hy - H_SEP * k, hy + H_SEP * k):
      if free(cand):
        return cand
  return hy


def _vertical_clear(x: float, ya: float, yb: float, obstacles, ignore) -> bool:
  return not _segment_hits_any_card(x, ya, x, yb, obstacles, ignore, pad=5.0)


def _tree_route(x1: float, y1: float, x2: float, y2: float, obstacles,
                ignore: Tuple[str, str], trunk: bool = False) -> List[Point]:
  """Multi-stage vertical route (`bottom -> top` / `top -> bottom`).

  The horizontal fork bar sits 20 px before the target row (not halfway, so
  it never runs through an intermediate tier); when the straight drop from
  the source port is blocked, a clear spine near `x1` carries it instead.
  `_assign_tree_lanes` later spreads the bars of one corridor into lanes.
  With `trunk`, the spine is searched around `x1` instead of the midpoint,
  so the siblings of one trunk pick the same spine.
  """
  down = y2 > y1
  if abs(y2 - y1) <= 40.0:
    mid_y = (y1 + y2) / 2.0
  else:
    mid_y = y2 - 20.0 if down else y2 + 20.0

  def h_clear(xa: float, xb: float, y: float) -> bool:
    return not _segment_hits_any_card(xa, y, xb, y, obstacles, ignore, pad=3.0)

  tail_clear = _vertical_clear(x2, mid_y, y2, obstacles, ignore)
  if (_vertical_clear(x1, y1, mid_y, obstacles, ignore) and
      h_clear(x1, x2, mid_y) and tail_clear):
    return [(x1, y1), (x1, mid_y), (x2, mid_y), (x2, y2)]
  exit_y = y1 + 16.0 if down else y1 - 16.0
  centre = x1 if trunk else (x1 + x2) / 2.0
  cands = sorted({round(centre + 12.0 * k, 1) for k in range(-80, 81)},
                 key=lambda c: (abs(c - centre), c))
  for spine_x in cands:
    if (h_clear(x1, spine_x, exit_y) and
        _vertical_clear(spine_x, exit_y, mid_y, obstacles, ignore) and
        h_clear(spine_x, x2, mid_y)):
      return [(x1, y1), (x1, exit_y), (spine_x, exit_y), (spine_x, mid_y),
              (x2, mid_y), (x2, y2)]
  return [(x1, y1), (x1, mid_y), (x2, mid_y), (x2, y2)]


def _bridge_leg_hits(s_out: float, sy: float, t_in: float, ty: float,
                     direction: str, obstacles, ignore) -> int:
  xmin, xmax = min(s_out, t_in), max(s_out, t_in)
  ys_min, ys_max = [], []
  for oid, o in obstacles.items():
    if oid not in ignore and (o.x +
                              o.width) > xmin + 10.0 and o.x < xmax - 10.0:
      ys_min.append(o.y)
      ys_max.append(o.y + o.height)
  if direction == "top":
    yb = min(ys_min, default=min(sy, ty)) - 16.0
  else:
    yb = max(ys_max, default=max(sy, ty)) + 16.0
  return (
      int(
          _segment_hits_any_card(s_out, sy, s_out, yb, obstacles, ignore,
                                 pad=3.0)) +
      int(_segment_hits_any_card(t_in, yb, t_in, ty, obstacles, ignore,
                                 pad=3.0)))


def _pick_bridge_dir(default: str, s_out: float, sy: float, t_in: float,
                     ty: float, obstacles, ignore) -> str:
  """Multi-stage: prefer the bridge side whose vertical legs hit nothing."""
  other = "bottom" if default == "top" else "top"
  if (_bridge_leg_hits(s_out, sy, t_in, ty, other, obstacles, ignore)
      < _bridge_leg_hits(s_out, sy, t_in, ty, default, obstacles, ignore)):
    return other
  return default


def _stub_segments(polylines: Polylines,
                   horizontal: bool) -> List[Tuple[float, float, float]]:
  """(fixed_coord, min, max) of each polyline's first and last segment."""
  return [seg for _, seg in _owned_stub_segments(polylines, horizontal)]


def _owned_stub_segments(
    polylines: Polylines,
    horizontal: bool) -> List[Tuple[int, Tuple[float, float, float]]]:
  """`_stub_segments` with the owning edge index of every stub."""
  out = []
  for idx, pts in polylines.items():
    if len(pts) < 2:
      continue
    for si in sorted({0, len(pts) - 2}):
      (ax, ay), (bx, by) = pts[si], pts[si + 1]
      if horizontal and abs(ay - by) < 0.5 and abs(ax - bx) > 0.5:
        out.append((idx, (ay, min(ax, bx), max(ax, bx))))
      elif not horizontal and abs(ax - bx) < 0.5 and abs(ay - by) > 0.5:
        out.append((idx, (ax, min(ay, by), max(ay, by))))
  return out


def _box_crosses_zone_border(scene: SceneGraph, bx1: float, by1: float,
                             bx2: float, by2: float, pad: float = 3.0) -> bool:
  """True when a label box straddles a visible zone border (multi-stage)."""
  for z in scene.zones.values():
    if z.style_name == "@Ghost":
      continue
    zx1, zy1, zx2, zy2 = z.x, z.y, z.x + z.w, z.y + z.h
    overlaps = (bx2 > zx1 - pad and bx1 < zx2 + pad and by2 > zy1 - pad and
                by1 < zy2 + pad)
    inside = (bx1 >= zx1 + pad and bx2 <= zx2 - pad and by1 >= zy1 + pad and
              by2 <= zy2 - pad)
    if overlaps and not inside:
      return True
  return False


def _port_fracs(n: int, length: float) -> List[float]:
  """Fractions along a side of length `length` for `n` ports, in rank order.

  Ports spread over the middle 60 % of the side; when that leaves less than
  `PORT_PITCH` between neighbours the spread widens up to `PORT_MARGIN` from
  the corners (`layout_scene` grows cards so the pitch always fits).
  """
  if n == 1:
    return [0.5]
  if length <= 0.0:
    return [0.5] * n
  want = PORT_PITCH * (n - 1)
  if 0.60 * length >= want:
    return [0.20 + 0.60 * (r / (n - 1)) for r in range(n)]
  span = min(want, max(0.0, length - 2.0 * PORT_MARGIN))
  lo = 0.5 - span / (2.0 * length)
  return [lo + (span / length) * (r / (n - 1)) for r in range(n)]


# --------------------------------------------------------------------------
# Routing passes
# --------------------------------------------------------------------------


@dataclass
class _Ctx:
  """Per-call routing state shared by the passes."""
  scene: SceneGraph
  multi: bool
  canvas_mid_y: float
  ancestors: Optional[AncestorIndex]
  is_long_span: Dict[int, bool] = field(default_factory=dict)
  bridge_dir: Dict[int, str] = field(default_factory=dict)
  z_mid: Dict[int, float] = field(default_factory=dict)
  _obs: Dict[int, Dict[str, object]] = field(default_factory=dict)

  def obstacles(self, idx: int) -> Dict[str, object]:
    if idx not in self._obs:
      e = self.scene.edges[idx]
      self._obs[idx] = edge_obstacles(self.scene, e.src, e.dst, self.ancestors)
    return self._obs[idx]


def _classify_spans(ctx: _Ctx) -> None:
  """Marks cross-column edges whose Z route would cross a box as bridges."""
  scene = ctx.scene
  for idx, e in enumerate(scene.edges):
    s = endpoint(scene, e.src)
    t = endpoint(scene, e.dst)
    if not s or not t:
      continue
    if (e.source_anchor in ("left", "right") and
        e.target_anchor in ("left", "right") and
        e.source_anchor != e.target_anchor):
      sx = s.x + s.width if e.source_anchor == "right" else s.x
      tx = t.x if e.target_anchor == "left" else t.x + t.width
      sy = s.y + s.height / 2.0
      ty = t.y + t.height / 2.0
      mid_x = (sx + tx) / 2.0
      obs, ign = ctx.obstacles(idx), (e.src, e.dst)
      hits = (_segment_hits_any_card(sx, sy, mid_x, sy, obs, ign) or
              _segment_hits_any_card(mid_x, sy, mid_x, ty, obs, ign) or
              _segment_hits_any_card(mid_x, ty, tx, ty, obs, ign))
      if hits and ctx.multi:
        cand = _clear_z_channel(sx, sy, tx, ty, e.source_anchor, obs, ign)
        if cand is not None:
          ctx.z_mid[idx] = cand
          hits = False
      ctx.is_long_span[idx] = hits
      if hits:
        ctx.bridge_dir[idx] = ("top" if (sy + ty) /
                               2.0 <= ctx.canvas_mid_y else "bottom")
        if ctx.multi:
          ctx.bridge_dir[idx] = _pick_bridge_dir(
              ctx.bridge_dir[idx],
              sx + (18.0 if e.source_anchor == "right" else -18.0), sy,
              tx + (-18.0 if e.target_anchor == "left" else 18.0), ty, obs, ign)
    else:
      ctx.is_long_span[idx] = False


def _assign_ports(ctx: _Ctx) -> PortCoords:
  """Slots every edge end on its card side, ordered to avoid crossings.

  Same-side C-brackets (`left -> left`, `right -> right`) sit at the end of
  the side facing their partner, shorter spans nearer the partner, so the
  brackets nest. Parallel brackets between one pair (equal spans) nest too:
  the lower edge index takes the outer slot on both cards.
  """
  scene = ctx.scene
  side_slots: Dict[Tuple[str, str], List[Tuple[int, str, float, int]]] = {}
  for idx, e in enumerate(scene.edges):
    s = endpoint(scene, e.src)
    t = endpoint(scene, e.dst)
    if not s or not t:
      continue
    tcx, tcy = t.x + t.width / 2.0, t.y + t.height / 2.0
    scx, scy = s.x + s.width / 2.0, s.y + s.height / 2.0
    s_tie = t_tie = idx

    if e.source_anchor == e.target_anchor and e.source_anchor in ("left",
                                                                  "right"):
      # Upward brackets (partner above) take the top of the side, shorter
      # spans above longer ones; downward brackets take the bottom, shorter
      # spans below longer ones; middle slots stay free for cross-column
      # edges. On the card whose partner is above, the outer (lower index)
      # bracket must sit lowest, so the index tie-break is reversed there.
      dist = round(abs(scy - tcy), 6)
      s_sort = (-2000.0 + dist) if tcy < scy else (2000.0 - dist)
      t_sort = (-2000.0 + dist) if scy < tcy else (2000.0 - dist)
      s_tie = -idx if tcy < scy else idx
      t_tie = -idx if scy < tcy else idx
    elif ctx.is_long_span.get(idx):
      b_bias = -1000.0 if ctx.bridge_dir.get(idx) == "top" else 1000.0
      s_sort = b_bias + tcy * 0.1
      t_sort = b_bias + scy * 0.1
    else:
      s_sort = tcy if e.source_anchor in ("left", "right") else tcx
      t_sort = scy if e.target_anchor in ("left", "right") else scx
    side_slots.setdefault((e.src, e.source_anchor), []).append(
        (idx, "src", s_sort, s_tie))
    side_slots.setdefault((e.dst, e.target_anchor), []).append(
        (idx, "dst", t_sort, t_tie))

  port_coords: PortCoords = {}
  for (cid, side), items in side_slots.items():
    card = endpoint(scene, cid)
    items = _merge_trunk_slots(scene, items)
    items.sort(key=lambda it: (it[1], it[2], it[3]))
    length = card.height if side in ("left", "right") else card.width
    fracs = _port_fracs(len(items), length)
    for (members, _, _, _), frac in zip(items, fracs):
      along_x = card.x + card.width * frac
      along_y = card.y + card.height * frac
      for e_idx, role in members:
        if side == "left":
          port_coords[(e_idx, role)] = (card.x, along_y, 0.0, frac)
        elif side == "right":
          port_coords[(e_idx, role)] = (card.x + card.width, along_y, 1.0, frac)
        elif side == "top":
          port_coords[(e_idx, role)] = (along_x, card.y, frac, 0.0)
        else:
          port_coords[(e_idx, role)] = (along_x, card.y + card.height, frac,
                                        1.0)
  return port_coords


def _merge_trunk_slots(scene: SceneGraph, items):
  """Groups the slots of one card side; trunk sources share a single slot.

  Returns `(members, sort_key, tie, first_idx)` tuples where `members` lists
  the `(edge index, role)` pairs drawn from that slot. The shared trunk slot
  sorts by the mean of its members' keys, so it lands at the side centre
  when the trunk edges are the only ones on that side.
  """
  out = []
  trunk = [it for it in items if it[1] == "src" and scene.edges[it[0]].trunk]
  for it in items:
    if it in trunk:
      continue
    out.append(([(it[0], it[1])], it[2], it[3], it[0]))
  if trunk:
    key = sum(it[2] for it in trunk) / len(trunk)
    first = min(it[0] for it in trunk)
    out.append(([(it[0], it[1]) for it in trunk], key, first, first))
  return out


def trunk_key(scene: SceneGraph, idx: int) -> Optional[Tuple[str, str]]:
  """`(source id, source side)` for a trunk edge, None for any other edge."""
  if not 0 <= idx < len(scene.edges):
    return None
  e = scene.edges[idx]
  return (e.src, e.source_anchor) if e.trunk else None


def _same_trunk(scene: SceneGraph, a: int, b: int) -> bool:
  ka = trunk_key(scene, a)
  return ka is not None and ka == trunk_key(scene, b)


def _rel(v: float, origin: float, size: float) -> float:
  """Relative position of `v` on a side; 0.5 for a zero-size side."""
  return (v - origin) / size if size > 0.0 else 0.5


def _separate_h_stubs(ctx: _Ctx, port_coords: PortCoords) -> None:
  """Moves horizontal port stubs that collide with an earlier edge's stubs.

  A stub collides when it is within `STUB_SEP` px of an already placed stub
  whose x range overlaps (20 px margin). The port first takes the classic
  10 px nudge (down for sources, up for targets, clamped 6 px inside the
  card); if that spot is taken too, it moves to the nearest free 10 px step
  along its side, and stays put when the side has none.
  """
  scene = ctx.scene
  used: List[Tuple[float, float, float]] = []

  def near(y: float, xmin: float, xmax: float):
    return [
        uy for uy, uxmin, uxmax in used if xmax > uxmin -
        20.0 and xmin < uxmax + 20.0 and abs(y - uy) < STUB_SEP
    ]

  def move(card, y: float, xmin: float, xmax: float, first: float) -> float:
    lo, hi = card.y + 6.0, card.y + card.height - 6.0
    nudged = y
    for uy, uxmin, uxmax in used:
      if (xmax > uxmin - 20.0 and xmin < uxmax + 20.0 and
          abs(nudged - uy) < STUB_SEP):
        nudged = (min(hi, nudged +
                      10.0) if first > 0 else max(lo, nudged - 10.0))
    if not near(nudged, xmin, xmax):
      return nudged
    for k in range(1, 200):
      inside = False
      for sgn in (first, -first):
        cand = y + sgn * 10.0 * k
        if lo <= cand <= hi:
          inside = True
          if not near(cand, xmin, xmax):
            return cand
      if not inside:
        break
    return nudged

  for idx, e in enumerate(scene.edges):
    if (idx, "src") not in port_coords or (idx, "dst") not in port_coords:
      continue
    if e.source_anchor in ("left", "right") and e.target_anchor in ("left",
                                                                    "right"):
      x1, y1, nx1, _ = port_coords[(idx, "src")]
      x2, y2, nx2, _ = port_coords[(idx, "dst")]
      xmin, xmax = min(x1, x2), max(x1, x2)
      if near(y1, xmin, xmax):
        s_card = endpoint(scene, e.src)
        y1 = move(s_card, y1, xmin, xmax, 1.0)
        port_coords[(idx, "src")] = (x1, y1, nx1,
                                     _rel(y1, s_card.y, s_card.height))
      if near(y2, xmin, xmax):
        t_card = endpoint(scene, e.dst)
        y2 = move(t_card, y2, xmin, xmax, -1.0)
        port_coords[(idx, "dst")] = (x2, y2, nx2,
                                     _rel(y2, t_card.y, t_card.height))
      used.append((y1, xmin, xmax))
      used.append((y2, xmin, xmax))


def _bracket_offsets(ctx: _Ctx, port_coords: PortCoords) -> Dict[int, float]:
  """Track offset per same-side C-bracket: shorter spans take inner tracks.

  Brackets are grouped per column side and ranked by vertical span (rounded
  to 1/1000 px so float noise never decides the order, ties by edge index):
  the shortest takes the 20 px track, longer ones 35, 50, ... px.
  """
  groups: Dict[Tuple[int, str], List[Tuple[float, int]]] = {}
  for idx, e in enumerate(ctx.scene.edges):
    if (idx, "src") not in port_coords or (idx, "dst") not in port_coords:
      continue
    if e.source_anchor == e.target_anchor and e.source_anchor in ("left",
                                                                  "right"):
      x1, y1, _, _ = port_coords[(idx, "src")]
      _, y2, _, _ = port_coords[(idx, "dst")]
      col_bucket = int(round(x1 / 80.0))
      groups.setdefault((col_bucket, e.source_anchor), []).append(
          (round(abs(y2 - y1), 3), idx))
  offsets: Dict[int, float] = {}
  for _, grp in sorted(groups.items()):
    grp.sort()
    for rank, (_, e_idx) in enumerate(grp):
      offsets[e_idx] = 20.0 + rank * 15.0
  return offsets


def _bridge_span(ctx: _Ctx, idx: int, xmin: float,
                 xmax: float) -> Tuple[List[float], List[float]]:
  """Top / bottom y of every box a bridge between xmin..xmax must clear."""
  scene = ctx.scene
  e = scene.edges[idx]
  ymins: List[float] = []
  ymaxs: List[float] = []
  if ctx.multi:
    # Multi-stage: every obstacle box (cards + obstacle zones) in range.
    for oid, o in ctx.obstacles(idx).items():
      if oid not in (e.src, e.dst) and (o.x + o.width) > xmin + 10.0 and \
          o.x < xmax - 10.0:
        ymins.append(o.y)
        ymaxs.append(o.y + o.height)
    return ymins, ymaxs
  for cid, c in scene.cards.items():
    if cid not in (e.src, e.dst) and (c.x + c.width) > xmin + 10.0 and \
        c.x < xmax - 10.0:
      ymins.append(c.y)
      ymaxs.append(c.y + c.height)
  # Networking: VPC / sub-group zones count too, except the zones that hold
  # (or are) either endpoint.
  s, t = endpoint(scene, e.src), endpoint(scene, e.dst)
  skip = {e.src, e.dst, s.parent_zone_id, t.parent_zone_id}
  for z in scene.zones.values():
    if z.style_name not in ("@VpcZone", "@SubGroupWhite") or z.id in skip:
      continue
    if (z.x + z.w) > xmin + 10.0 and z.x < xmax - 10.0:
      ymins.append(z.y)
      ymaxs.append(z.y + z.h)
  return ymins, ymaxs


def _initial_polylines(ctx: _Ctx, port_coords: PortCoords,
                       bracket_offset: Dict[int, float]) -> Polylines:
  """First-cut route per edge: bridge, Z, C-bracket or tree route."""
  scene = ctx.scene
  polylines: Polylines = {}
  top_bridge_tracks = 0
  bot_bridge_tracks = 0
  for idx, e in enumerate(scene.edges):
    if (idx, "src") not in port_coords or (idx, "dst") not in port_coords:
      continue
    x1, y1, _, _ = port_coords[(idx, "src")]
    x2, y2, _, _ = port_coords[(idx, "dst")]
    sa, ta = e.source_anchor, e.target_anchor

    if ctx.is_long_span.get(idx):
      s_out = x1 + 18.0 if sa == "right" else x1 - 18.0
      t_in = x2 - 18.0 if ta == "left" else x2 + 18.0
      span_ymins, span_ymaxs = _bridge_span(ctx, idx, min(s_out, t_in),
                                            max(s_out, t_in))
      if ctx.bridge_dir.get(idx) == "top":
        base_top = min(span_ymins, default=min(y1, y2)) - 16.0
        y_bridge = base_top - top_bridge_tracks * 14.0
        top_bridge_tracks += 1
      else:
        base_bot = max(span_ymaxs, default=max(y1, y2)) + 16.0
        y_bridge = base_bot + bot_bridge_tracks * 14.0
        bot_bridge_tracks += 1
      polylines[idx] = [(x1, y1), (s_out, y1), (s_out, y_bridge),
                        (t_in, y_bridge), (t_in, y2), (x2, y2)]
    elif sa in ("left", "right") and ta in ("left", "right") and sa != ta:
      mid_x = ctx.z_mid.get(idx, (x1 + x2) / 2.0)
      polylines[idx] = [(x1, y1), (mid_x, y1), (mid_x, y2), (x2, y2)]
    elif sa == "left" and ta == "left":
      out_x = min(x1, x2) - bracket_offset.get(idx, 22.0)
      polylines[idx] = [(x1, y1), (out_x, y1), (out_x, y2), (x2, y2)]
    elif sa == "right" and ta == "right":
      out_x = max(x1, x2) + bracket_offset.get(idx, 22.0)
      polylines[idx] = [(x1, y1), (out_x, y1), (out_x, y2), (x2, y2)]
    elif ctx.multi and sa in ("top", "bottom") and ta in ("top", "bottom"):
      polylines[idx] = _tree_route(x1, y1, x2, y2, ctx.obstacles(idx),
                                   (e.src, e.dst), trunk=e.trunk)
    else:
      mid_y = (y1 + y2) / 2.0
      polylines[idx] = [(x1, y1), (x1, mid_y), (x2, mid_y), (x2, y2)]
  return polylines


@dataclass
class _Bar:
  """A multi-stage tree route's fork bar, its stubs and feasible y window."""
  idx: int
  xu: float  # x of the stub that meets the upper card, at y = yu
  yu: float
  xl: float  # x of the stub that meets the lower card, at y = yl
  yl: float
  pref: float  # y chosen by `_tree_route`
  lo: float
  hi: float
  trunk: Optional[Tuple[str, str]] = None  # `trunk_key` of the edge

  @property
  def xmin(self) -> float:
    return min(self.xu, self.xl)

  @property
  def xmax(self) -> float:
    return max(self.xu, self.xl)


def _bar_window(
    pts: List[Point], obstacles, ignore: Tuple[str, str],
    fixed_h: List[Tuple[float, float, float]]) -> Optional[Tuple[float, float]]:
  """Feasible y interval around the current bar y of a 4-point tree route.

  A y is feasible when it stays 8 px inside the gap between the two cards,
  the bar and both vertical stubs stay clear of obstacles (the same paddings
  `_tree_route` checks) and the bar keeps `H_SEP` px from every fixed
  horizontal stub over its x range. Returns None when the current y is not
  feasible.
  """
  (x1, y1), (_, pref), (x2, _), (_, y2) = pts
  if y1 <= y2:
    xu, yu, xl, yl = x1, y1, x2, y2
  else:
    xu, yu, xl, yl = x2, y2, x1, y1
  lo, hi = yu + 8.0, yl - 8.0
  if not lo <= pref <= hi:
    return None
  xmin, xmax = min(x1, x2), max(x1, x2)
  bands: List[Tuple[float, float]] = []  # open intervals of forbidden y
  for oid, o in obstacles.items():
    if oid in ignore:
      continue
    ox1, oy1, ox2, oy2 = o.x, o.y, o.x + o.width, o.y + o.height
    if xmax > ox1 - 3.0 and xmin < ox2 + 3.0:
      bands.append((oy1 - 3.0, oy2 + 3.0))
    if ox1 - 5.0 < xu < ox2 + 5.0 and yu < oy2 + 5.0:
      bands.append((oy1 - 5.0, _INF))
    if ox1 - 5.0 < xl < ox2 + 5.0 and yl > oy1 - 5.0:
      bands.append((-_INF, oy2 + 5.0))
  for sy, sxmin, sxmax in fixed_h:
    if xmax > sxmin - 8.0 and xmin < sxmax + 8.0:
      bands.append((sy - H_SEP, sy + H_SEP))
  for a, b in bands:
    if a < pref < b:
      return None
    if b <= pref:
      lo = max(lo, b)
    else:
      hi = min(hi, a)
  return lo, hi


def _x_overlap(a: _Bar, b: _Bar) -> bool:
  return a.xmax > b.xmin - 8.0 and a.xmin < b.xmax + 8.0


def _bars_clash(a: _Bar, ya: float, b: _Bar, yb: float, sep: float) -> bool:
  """True when bars a (at ya) and b (at yb) would trip the overlap gate.

  The bars clash when their x ranges overlap (8 px margin) and they sit
  closer than `sep`, or when a vertical stub of one runs along a vertical
  stub of the other on a shared x. Bars of one trunk never clash: they
  share their fork and trunk on purpose.
  """
  if a.trunk is not None and a.trunk == b.trunk:
    return False
  if _x_overlap(a, b) and abs(ya - yb) < sep:
    return True
  for xa, a0, a1 in ((a.xu, a.yu, ya), (a.xl, ya, a.yl)):
    for xb, b0, b1 in ((b.xu, b.yu, yb), (b.xl, yb, b.yl)):
      if abs(xa - xb) < GATE_SEP and min(a1, b1) - max(a0, b0) > GATE_MIN_RUN:
        return True
  return False


_HARD = 1000


def _cost_above(a: _Bar, b: _Bar) -> int:
  """Crossings (or a forbidden overlap) created by putting bar a above b."""
  cost = 0
  if b.xmin < a.xl < b.xmax:
    cost += 1  # a's lower stub crosses b's bar
  if a.xmin < b.xu < a.xmax:
    cost += 1  # b's upper stub crosses a's bar
  if abs(a.xl - b.xu) < GATE_SEP:
    cost += _HARD  # a's lower stub would run along b's upper stub
  return cost


def _lane_order(bars: List[_Bar], conflicts: Dict[int, List[int]]) -> List[int]:
  """Top-to-bottom priority: fewest crossings, hard constraints honoured."""
  n = len(bars)
  score = [0] * n
  must_above: Dict[int, Set[int]] = {i: set() for i in range(n)}
  for i in range(n):
    for j in conflicts[i]:
      if j <= i:
        continue
      cij, cji = _cost_above(bars[i], bars[j]), _cost_above(bars[j], bars[i])
      if cij < cji:
        score[i] += 1
        score[j] -= 1
      elif cji < cij:
        score[j] += 1
        score[i] -= 1
      if cji >= _HARD > cij:
        must_above[j].add(i)
      elif cij >= _HARD > cji:
        must_above[i].add(j)
  rank = sorted(range(n), key=lambda i: (-score[i], bars[i].idx))
  # Stable topological order over the hard constraints, rank as priority;
  # a cycle (impossible geometry) falls back to rank order.
  order: List[int] = []
  done: Set[int] = set()
  while len(order) < n:
    todo = [i for i in rank if i not in done]
    ready = [i for i in todo if must_above[i] <= done]
    pick = ready[0] if ready else todo[0]
    order.append(pick)
    done.add(pick)
  return order


def _lanes(order: List[int], conflicts: Dict[int, List[int]],
           respect_order: bool) -> Dict[int, int]:
  """Lane index per bar (0 = top).

  Ordered mode puts every conflicting earlier bar above; first-fit mode only
  keeps conflicting bars in distinct lanes (fewer lanes, more crossings).
  """
  lane: Dict[int, int] = {}
  for i in order:
    taken = {lane[j] for j in conflicts[i] if j in lane}
    if respect_order:
      lane[i] = 1 + max(taken) if taken else 0
    else:
      k = 0
      while k in taken:
        k += 1
      lane[i] = k
  return lane


def _layout_group(bars: List[_Bar],
                  members: List[int]) -> Optional[Dict[int, float]]:
  """Lane y per bar of one group, or None when the lanes do not fit."""
  group = [bars[g] for g in members]
  n = len(group)
  conflicts = {
      k: [j for j in range(n) if j != k and _x_overlap(group[k], group[j])]
      for k in range(n)
  }
  lo = max(b.lo for b in group)
  hi = min(b.hi for b in group)
  if hi < lo:
    return None
  order = _lane_order(group, conflicts)
  pref = sum(b.pref for b in group) / n
  for respect in (True, False):
    lane = _lanes(order, conflicts, respect)
    count = max(lane.values()) + 1
    if count == 1:
      ys = {k: min(max(group[k].pref, lo), hi) for k in range(n)}
    else:
      sep = min(H_SEP, (hi - lo) / (count - 1))
      if sep < MIN_LANE_SEP:
        continue
      block = sep * (count - 1)
      start = min(max(pref - block / 2.0, lo), hi - block)
      ys = {k: start + lane[k] * sep for k in range(n)}
    if not any(
        _bars_clash(group[k], ys[k], group[j], ys[j], GATE_SEP)
        for k in range(n)
        for j in range(k + 1, n)):
      return {members[k]: y for k, y in ys.items()}
  return None


def _assign_tree_lanes(ctx: _Ctx, polylines: Polylines) -> Set[int]:
  """Spreads the fork bars of multi-stage tree routes into separate lanes.

  Bars that collide at their current y form a group. Within a group bars
  are ordered top to bottom to minimise crossings (the outer bars of a fan
  sit nearer the parent) without letting one edge's stub run along
  another's, then laid out `H_SEP` (down to `MIN_LANE_SEP`) px apart inside
  the window they all share, centred on their current y. Groups that end up
  colliding with each other are merged and laid out again. Returns the edge
  indices whose bars are final; groups that do not fit are left to
  `_deoverlap_horizontal`.
  """
  scene = ctx.scene
  fixed_h = _stub_segments(polylines, horizontal=True)
  bars: List[_Bar] = []
  for idx in sorted(polylines):
    e = scene.edges[idx]
    pts = polylines[idx]
    if (e.source_anchor not in ("top", "bottom") or
        e.target_anchor not in ("top", "bottom") or len(pts) != 4 or
        abs(pts[0][0] - pts[3][0]) <= 0.5):
      continue
    win = _bar_window(pts, ctx.obstacles(idx), (e.src, e.dst), fixed_h)
    if win is None:
      continue
    (xa, ya), (xb, yb) = pts[0], pts[3]
    if ya > yb:
      (xa, ya), (xb, yb) = (xb, yb), (xa, ya)
    bars.append(
        _Bar(idx, xa, ya, xb, yb, pts[1][1], win[0], win[1],
             trunk_key(scene, idx)))

  n = len(bars)
  parent = list(range(n))

  def find(i: int) -> int:
    while parent[i] != i:
      parent[i] = parent[parent[i]]
      i = parent[i]
    return i

  for i in range(n):
    for j in range(i + 1, n):
      if _bars_clash(bars[i], bars[i].pref, bars[j], bars[j].pref, H_SEP):
        parent[find(i)] = find(j)

  ys: Dict[int, float] = {}
  for _ in range(n + 1):
    groups: Dict[int, List[int]] = {}
    for i in range(n):
      groups.setdefault(find(i), []).append(i)
    ys = {}
    for members in groups.values():
      if len(members) == 1:
        ys[members[0]] = bars[members[0]].pref
        continue
      laid = _layout_group(bars, members)
      if laid is not None:
        ys.update(laid)
    merged = False
    placed = sorted(ys)
    for a, i in enumerate(placed):
      for j in placed[a + 1:]:
        if find(i) != find(j) and _bars_clash(bars[i], ys[i], bars[j], ys[j],
                                              MIN_LANE_SEP):
          parent[find(i)] = find(j)
          merged = True
    if not merged:
      break

  for i, y in sorted(ys.items()):
    b = bars[i]
    pts = list(polylines[b.idx])
    pts[1] = (pts[1][0], y)
    pts[2] = (pts[2][0], y)
    polylines[b.idx] = pts
  return {bars[i].idx for i in ys}


def _deoverlap_horizontal(ctx: _Ctx, polylines: Polylines,
                          fixed: Set[int]) -> None:
  """Moves inner horizontal segments off each other (and off fixed stubs).

  Edges in `fixed` keep their bars, which act as obstacles for the others.
  """
  h_segs: List[Tuple[int, int, float, float, float]] = []
  placed_h: List[Tuple[float, float, float]] = []
  owners: List[Optional[int]] = []  # edge index of each placed_h entry
  for idx, pts in polylines.items():
    for si in range(1, len(pts) - 2):
      p_a, p_b = pts[si], pts[si + 1]
      if abs(p_a[1] - p_b[1]) < 0.5 and abs(p_a[0] - p_b[0]) > 0.5:
        seg = (p_a[1], min(p_a[0], p_b[0]), max(p_a[0], p_b[0]))
        if idx in fixed:
          placed_h.append(seg)
          owners.append(idx)
        else:
          h_segs.append((idx, si) + seg)

  h_segs.sort(key=lambda it: (it[2], it[3], it[0]))
  if ctx.multi:
    # The fixed first/last stubs are obstacles for movable inner segments.
    stubs = _stub_segments(polylines, horizontal=True)
    placed_h.extend(stubs)
    owners.extend([None] * len(stubs))
  for idx, si, hy, hxmin, hxmax in h_segs:
    new_y = hy
    if ctx.multi:
      others = [
          seg for seg, own in zip(placed_h, owners)
          if own is None or not _same_trunk(ctx.scene, idx, own)
      ]
      new_y = _free_h_offset(polylines[idx], si, hy, hxmin, hxmax, others,
                             ctx.obstacles(idx))
    else:
      step_idx = 0
      while any(
          abs(new_y - py) < 12.0 and hxmax > pxmin - 8.0 and hxmin < pxmax + 8.0
          for py, pxmin, pxmax in placed_h):
        step_idx += 1
        direction = -1.0 if hy < ctx.canvas_mid_y else 1.0
        new_y = hy + step_idx * 14.0 * direction
    placed_h.append((new_y, hxmin, hxmax))
    owners.append(idx)
    if abs(new_y - hy) > 0.1:
      pts = list(polylines[idx])
      pts[si] = (pts[si][0], new_y)
      pts[si + 1] = (pts[si + 1][0], new_y)
      polylines[idx] = pts


def _deoverlap_vertical(ctx: _Ctx, polylines: Polylines) -> None:
  """Moves inner vertical segments (Z channels, bridge legs, brackets)."""
  scene = ctx.scene
  v_segs: List[Tuple[int, int, float, float, float]] = []
  for idx, pts in polylines.items():
    for si in range(1, len(pts) - 2):
      p_a, p_b = pts[si], pts[si + 1]
      if abs(p_a[0] - p_b[0]) < 0.5 and abs(p_a[1] - p_b[1]) > 0.5:
        v_segs.append((idx, si, p_a[0], min(p_a[1],
                                            p_b[1]), max(p_a[1], p_b[1])))

  v_segs.sort(key=lambda it: (it[2], (it[3] + it[4]) / 2.0, it[0]))
  placed_v: List[Tuple[float, float, float]] = []
  owners: List[Optional[int]] = []  # edge index of each placed_v entry
  if ctx.multi:
    for sidx, seg in _owned_stub_segments(polylines, horizontal=False):
      placed_v.append(seg)
      owners.append(sidx)
  for idx, si, vx, vymin, vymax in v_segs:
    e = scene.edges[idx]
    others = [
        seg for seg, own in zip(placed_v, owners)
        if own is None or not _same_trunk(scene, idx, own)
    ]
    new_x = vx
    step_idx = 0
    x_lo, x_hi = (_inner_range(polylines[idx], si, axis=0) if ctx.multi else
                  (-_INF, _INF))
    while (any(
        abs(new_x - px) < 10.0 and
        (vymax > pymin - 24.0 and vymin < pymax + 24.0)
        for px, pymin, pymax in others) or _segment_hits_any_card(
            new_x, vymin, new_x, vymax, ctx.obstacles(idx),
            (e.src, e.dst), pad=5.0)):
      step_idx += 1
      offset = ((step_idx + 1) // 2) * 11.0 * (1 if step_idx % 2 == 1 else -1)
      new_x = vx + offset
      if ctx.multi and not x_lo <= new_x <= x_hi:
        if step_idx > 24:
          new_x = vx
          break
        continue
      if step_idx > 24:
        if ctx.multi:
          new_x = vx  # never keep a failed far offset (it can land in a card)
        break
    placed_v.append((new_x, vymin, vymax))
    owners.append(idx)
    if abs(new_x - vx) > 0.1:
      pts = list(polylines[idx])
      pts[si] = (new_x, pts[si][1])
      pts[si + 1] = (new_x, pts[si + 1][1])
      polylines[idx] = pts


def _place_labels(ctx: _Ctx, polylines: Polylines) -> Dict[int, Point]:
  """Label pill centre per labelled edge, on its longest clear segment."""
  scene = ctx.scene
  label_pos: Dict[int, Point] = {}
  placed_pills: List[Tuple[float, float, float, float]] = []

  def pill_hits_other_edge(edge_idx: int, bx1: float, by1: float, bx2: float,
                           by2: float) -> bool:
    for o_idx, o_pts in polylines.items():
      if o_idx == edge_idx:
        continue
      for si in range(len(o_pts) - 1):
        sx1, sy1 = o_pts[si]
        sx2, sy2 = o_pts[si + 1]
        sxmin, sxmax = min(sx1, sx2) - 2.0, max(sx1, sx2) + 2.0
        symin, symax = min(sy1, sy2) - 2.0, max(sy1, sy2) + 2.0
        if bx2 > sxmin and bx1 < sxmax and by2 > symin and by1 < symax:
          return True
    return False

  for idx, pts in polylines.items():
    e = scene.edges[idx]
    if not e.label or len(pts) < 2:
      continue
    pw = max(36.0, len(e.label) * 6.4 + 14.0)
    ph = 17.0
    candidates: List[Tuple[float, float, float]] = []
    for si in range(len(pts) - 1):
      p_a, p_b = pts[si], pts[si + 1]
      seg_len = math.hypot(p_b[0] - p_a[0], p_b[1] - p_a[1])
      if seg_len < 16.0:
        continue
      for frac in (0.5, 0.35, 0.65, 0.22, 0.78, 0.15, 0.85):
        cx = p_a[0] + (p_b[0] - p_a[0]) * frac
        cy = p_a[1] + (p_b[1] - p_a[1]) * frac
        bonus = 60.0 if 0 < si < len(pts) - 2 else 0.0
        candidates.append((seg_len + bonus, cx, cy))
    if not candidates:
      p_a, p_b = pts[0], pts[-1]
      candidates.append(
          (10.0, (p_a[0] + p_b[0]) / 2.0, (p_a[1] + p_b[1]) / 2.0))
    candidates.sort(key=lambda c: -c[0])

    best_cand = (999999.0, candidates[0][1], candidates[0][2])
    for prio, cx, cy in candidates:
      bx1, by1 = cx - pw / 2.0, cy - ph / 2.0
      bx2, by2 = cx + pw / 2.0, cy + ph / 2.0
      hit_pill = sum(1 for px1, py1, px2, py2 in placed_pills
                     if bx2 > px1 - 8.0 and bx1 < px2 + 8.0 and by2 > py1 -
                     6.0 and by1 < py2 + 6.0)
      hit_card = 1 if _segment_hits_any_card(bx1, by1, bx2, by2, scene.cards,
                                             ("", ""), pad=3.0) else 0
      if ctx.multi and not hit_card and _box_crosses_zone_border(
          scene, bx1, by1, bx2, by2):
        hit_card = 1
      hit_other = 1 if pill_hits_other_edge(idx, bx1, by1, bx2, by2) else 0
      penalty = (hit_pill * 10000.0 + hit_card * 5000.0 + hit_other * 200.0 -
                 prio)
      if penalty < best_cand[0]:
        best_cand = (penalty, cx, cy)
    chosen_x, chosen_y = best_cand[1], best_cand[2]
    placed_pills.append((chosen_x - pw / 2.0, chosen_y - ph / 2.0,
                         chosen_x + pw / 2.0, chosen_y + ph / 2.0))
    label_pos[idx] = (chosen_x, chosen_y)
  return label_pos


def route_all_edges(
    scene: SceneGraph) -> Tuple[PortCoords, Polylines, Dict[int, Point]]:
  """Routes every edge of a laid-out scene.

  Returns `(port_coords, polylines, label_pos)`: per `(edge index, "src" |
  "dst")` the port `(x, y, rel_x, rel_y)`, per edge index its orthogonal
  polyline, and per labelled edge its pill centre. Edges with an unknown
  endpoint are skipped.
  """
  all_cards = list(scene.cards.values())
  canvas_mid_y = (
      (min(c.y for c in all_cards) + max(c.y + c.height for c in all_cards)) /
      2.0 if all_cards else 400.0)
  multi = is_multistage(scene)
  ctx = _Ctx(scene=scene, multi=multi, canvas_mid_y=canvas_mid_y,
             ancestors=ancestor_index(scene) if multi else None)
  _classify_spans(ctx)
  port_coords = _assign_ports(ctx)
  _separate_h_stubs(ctx, port_coords)
  polylines = _initial_polylines(ctx, port_coords,
                                 _bracket_offsets(ctx, port_coords))
  fixed = _assign_tree_lanes(ctx, polylines) if multi else set()
  _deoverlap_horizontal(ctx, polylines, fixed)
  _deoverlap_vertical(ctx, polylines)
  return port_coords, polylines, _place_labels(ctx, polylines)


# --------------------------------------------------------------------------
# Overlap gate
# --------------------------------------------------------------------------


def verify_no_arrow_overlaps(polylines: Polylines,
                             scene: Optional[SceneGraph] = None) -> List[str]:
  """Mechanical gate over routed polylines; returns one message per issue.

  Flags parallel segments (of two edges, or of one edge that retraces
  itself) closer than `GATE_SEP` px that share more than `GATE_MIN_RUN` px.
  With `scene`, also flags any segment that runs through a card other than
  the edge's endpoints and the cards inside an endpoint zone, and accepts
  overlaps between trunk edges of one source side (their shared trunk).
  """
  v_all: List[Tuple[int, float, float, float]] = []
  h_all: List[Tuple[int, float, float, float]] = []
  for idx, pts in sorted(polylines.items()):
    for si in range(len(pts) - 1):
      x1, y1 = pts[si]
      x2, y2 = pts[si + 1]
      if abs(x1 - x2) < 0.5 and abs(y1 - y2) > 2.0:
        v_all.append((idx, x1, min(y1, y2), max(y1, y2)))
      elif abs(y1 - y2) < 0.5 and abs(x1 - x2) > 2.0:
        h_all.append((idx, y1, min(x1, x2), max(x1, x2)))

  errors: List[str] = []
  for kind, segs, axis, span in (("Vertical", v_all, "x", "y"),
                                 ("Horizontal", h_all, "y", "x")):
    for i in range(len(segs)):
      e1, c1, lo1, hi1 = segs[i]
      for j in range(i + 1, len(segs)):
        e2, c2, lo2, hi2 = segs[j]
        if (e1 != e2 and scene is not None and _same_trunk(scene, e1, e2)):
          continue
        if abs(c1 -
               c2) < GATE_SEP and min(hi1, hi2) - max(lo1, lo2) > GATE_MIN_RUN:
          what = (f"{kind} overlap between edge {e1} and edge {e2}"
                  if e1 != e2 else f"{kind} retrace on edge {e1}")
          errors.append(f"{what} at {axis}≈{c1:.1f}, {span}="
                        f"[{max(lo1, lo2):.1f}..{min(hi1, hi2):.1f}]")
  if scene is not None:
    errors.extend(_card_crossings(polylines, scene))
  return errors


def _card_crossings(polylines: Polylines, scene: SceneGraph) -> List[str]:
  """Segments that pass through a card (1 px inset, so touching is fine)."""
  card_anc, _ = ancestor_index(scene)
  errors: List[str] = []
  for idx, pts in sorted(polylines.items()):
    if not 0 <= idx < len(scene.edges):
      continue
    e = scene.edges[idx]
    ends = {e.src, e.dst}
    for cid, c in scene.cards.items():
      if cid in ends or card_anc[cid] & ends:
        continue
      bx1, by1 = c.x + 1.0, c.y + 1.0
      bx2, by2 = c.x + c.width - 1.0, c.y + c.height - 1.0
      for si in range(len(pts) - 1):
        (x1, y1), (x2, y2) = pts[si], pts[si + 1]
        if (max(x1, x2) > bx1 and min(x1, x2) < bx2 and max(y1, y2) > by1 and
            min(y1, y2) < by2):
          errors.append(f"Edge {idx} ({e.src} -> {e.dst}) crosses card {cid} "
                        f"on segment {si}")
          break
  return errors
