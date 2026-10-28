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

Ported verbatim from the scratch `engine_1_pyflex_drawio.py` (golden parity):
closest-side port slotting, 3-segment C-bracket routes for same-side edges,
5-segment obstacle bridges for long spans that would cross cards, horizontal
then vertical de-overlapping, and label pill placement. Pure function of the
laid-out `SceneGraph`; it never moves cards.
"""

import math
from typing import Dict, List, Optional, Set, Tuple, Union

from .model import CardNode, SceneGraph, ZoneNode

# Zone styles that act as routing obstacles in multi-stage scenes (see
# `is_multistage`). 2-networking keeps the original card-only obstacles and
# `@VpcZone` / `@SubGroupWhite` bridge spans, so its bytes never change.
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


def is_multistage(scene: SceneGraph) -> bool:
  """True for non-networking scenes (stage set and not `2-networking`)."""
  return bool(scene.stage) and scene.stage != "2-networking"


def endpoint(scene: SceneGraph, eid: str) -> Optional[Union[CardNode, ZoneNode]]:
  """Resolves an edge endpoint: a card id, else a zone id (else None)."""
  return scene.cards.get(eid) or scene.zones.get(eid)


def _ancestor_ids(scene: SceneGraph, node) -> Set[str]:
  out: Set[str] = set()
  zid = node.parent_zone_id if node is not None else None
  while zid:
    out.add(zid)
    z = scene.zones.get(zid)
    zid = z.parent_zone_id if z is not None else None
  return out


def edge_obstacles(scene: SceneGraph, src_id: str, dst_id: str) -> Dict[str, object]:
  """Boxes an edge between `src_id` and `dst_id` must avoid.

  2-networking: exactly `scene.cards` (original behaviour). Multi-stage:
  cards plus `OBSTACLE_ZONE_STYLES` zones, minus the endpoint zones, their
  descendants and every ancestor of either endpoint (an edge may enter the
  containers it starts or ends in, and must route around the others).
  """
  if not is_multistage(scene):
    return scene.cards
  src, dst = endpoint(scene, src_id), endpoint(scene, dst_id)
  open_zones = _ancestor_ids(scene, src) | _ancestor_ids(scene, dst)
  endpoint_zones = {i for i in (src_id, dst_id) if i in scene.zones and i not in scene.cards}
  obstacles: Dict[str, object] = {}
  for cid, c in scene.cards.items():
    if not (_ancestor_ids(scene, c) & endpoint_zones):
      obstacles[cid] = c
  for zid, z in scene.zones.items():
    if (z.style_name in OBSTACLE_ZONE_STYLES and zid not in open_zones
        and zid not in endpoint_zones
        and not (_ancestor_ids(scene, z) & endpoint_zones)):
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
    if not (_segment_hits_any_card(sx, sy, cx, sy, obstacles, ignore)
            or _segment_hits_any_card(cx, sy, cx, ty, obstacles, ignore)
            or _segment_hits_any_card(cx, ty, tx, ty, obstacles, ignore)):
      return cx
  return None


def _inner_range(pts: List[Tuple[float, float]], si: int, axis: int) -> Tuple[float, float]:
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
  return float("-inf"), float("inf")


def _free_h_offset(scene: SceneGraph, pts: List[Tuple[float, float]], si: int,
                   hy: float, hxmin: float, hxmax: float,
                   placed_h: List[Tuple[float, float, float]], obstacles) -> float:
  """Multi-stage horizontal de-overlap: nearest free y, both directions.

  Free = no placed segment within `H_SEP` px over the same x range, no obstacle
  box hit, and inside `_inner_range`. Falls back to `hy` (the overlap gate
  then reports it) rather than pushing the bar into a card.
  """
  del scene  # reserved for future zone-aware heuristics
  lo, hi = _inner_range(pts, si, axis=1)
  e_ids = ("", "")

  def free(y: float) -> bool:
    if not lo <= y <= hi:
      return False
    if any(abs(y - py) < H_SEP and hxmax > pxmin - 8.0 and hxmin < pxmax + 8.0
           for py, pxmin, pxmax in placed_h):
      return False
    return y == hy or not _segment_hits_any_card(hxmin, y, hxmax, y, obstacles, e_ids, pad=3.0)

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
                ignore: Tuple[str, str]) -> List[Tuple[float, float]]:
  """Multi-stage vertical route (`bottom -> top` / `top -> bottom`).

  The horizontal fork bar sits 20 px before the target row (not halfway, so
  it never runs through an intermediate tier); when the straight drop from
  the source port is blocked, a clear spine near `x1` carries it instead.
  """
  down = y2 > y1
  if abs(y2 - y1) <= 40.0:
    mid_y = (y1 + y2) / 2.0
  else:
    mid_y = y2 - 20.0 if down else y2 + 20.0
  def h_clear(xa: float, xb: float, y: float) -> bool:
    return not _segment_hits_any_card(xa, y, xb, y, obstacles, ignore, pad=3.0)

  tail_clear = _vertical_clear(x2, mid_y, y2, obstacles, ignore)
  if (_vertical_clear(x1, y1, mid_y, obstacles, ignore) and h_clear(x1, x2, mid_y)
      and tail_clear):
    return [(x1, y1), (x1, mid_y), (x2, mid_y), (x2, y2)]
  exit_y = y1 + 16.0 if down else y1 - 16.0
  centre = (x1 + x2) / 2.0
  cands = sorted({round(centre + 12.0 * k, 1) for k in range(-80, 81)},
                 key=lambda c: (abs(c - centre), c))
  for spine_x in cands:
    if (h_clear(x1, spine_x, exit_y)
        and _vertical_clear(spine_x, exit_y, mid_y, obstacles, ignore)
        and h_clear(spine_x, x2, mid_y)):
      return [(x1, y1), (x1, exit_y), (spine_x, exit_y), (spine_x, mid_y),
              (x2, mid_y), (x2, y2)]
  return [(x1, y1), (x1, mid_y), (x2, mid_y), (x2, y2)]


def _bridge_leg_hits(s_out: float, sy: float, t_in: float, ty: float,
                     direction: str, obstacles, ignore) -> int:
  xmin, xmax = min(s_out, t_in), max(s_out, t_in)
  ys_min, ys_max = [], []
  for oid, o in obstacles.items():
    if oid not in ignore and (o.x + o.width) > xmin + 10.0 and o.x < xmax - 10.0:
      ys_min.append(o.y)
      ys_max.append(o.y + o.height)
  if direction == "top":
    yb = min(ys_min, default=min(sy, ty)) - 16.0
  else:
    yb = max(ys_max, default=max(sy, ty)) + 16.0
  return (int(_segment_hits_any_card(s_out, sy, s_out, yb, obstacles, ignore, pad=3.0))
          + int(_segment_hits_any_card(t_in, yb, t_in, ty, obstacles, ignore, pad=3.0)))


def _pick_bridge_dir(default: str, s_out: float, sy: float, t_in: float,
                     ty: float, obstacles, ignore) -> str:
  """Multi-stage: prefer the bridge side whose vertical legs hit nothing."""
  other = "bottom" if default == "top" else "top"
  if (_bridge_leg_hits(s_out, sy, t_in, ty, other, obstacles, ignore)
      < _bridge_leg_hits(s_out, sy, t_in, ty, default, obstacles, ignore)):
    return other
  return default


def _stub_segments(polylines: Dict[int, List[Tuple[float, float]]],
                   horizontal: bool) -> List[Tuple[float, float, float]]:
  """(fixed_coord, min, max) of each polyline's first and last segment."""
  out = []
  for pts in polylines.values():
    if len(pts) < 2:
      continue
    for si in sorted({0, len(pts) - 2}):
      (ax, ay), (bx, by) = pts[si], pts[si + 1]
      if horizontal and abs(ay - by) < 0.5 and abs(ax - bx) > 0.5:
        out.append((ay, min(ax, bx), max(ax, bx)))
      elif not horizontal and abs(ax - bx) < 0.5 and abs(ay - by) > 0.5:
        out.append((ax, min(ay, by), max(ay, by)))
  return out


def _box_crosses_zone_border(scene: SceneGraph, bx1: float, by1: float,
                             bx2: float, by2: float, pad: float = 3.0) -> bool:
  """True when a label box straddles a visible zone border (multi-stage)."""
  for z in scene.zones.values():
    if z.style_name == "@Ghost":
      continue
    zx1, zy1, zx2, zy2 = z.x, z.y, z.x + z.w, z.y + z.h
    overlaps = bx2 > zx1 - pad and bx1 < zx2 + pad and by2 > zy1 - pad and by1 < zy2 + pad
    inside = bx1 >= zx1 + pad and bx2 <= zx2 - pad and by1 >= zy1 + pad and by2 <= zy2 - pad
    if overlaps and not inside:
      return True
  return False


def _route_all_edges_non_overlapping(
  scene: SceneGraph,
) -> Tuple[
  Dict[Tuple[int, str], Tuple[float, float, float, float]],
  Dict[int, List[Tuple[float, float]]],
  Dict[int, Tuple[float, float]],
]:
  """Routes all edges with obstacle avoidance, concentric same-side brackets, and zero-overlap de-collision."""
  is_long_span: Dict[int, bool] = {}
  bridge_dir: Dict[int, str] = {}
  all_cards = list(scene.cards.values())
  canvas_mid_y = (
    (min(c.y for c in all_cards) + max(c.y + c.height for c in all_cards)) / 2.0
    if all_cards
    else 400.0
  )

  multi = is_multistage(scene)
  _obs_cache: Dict[int, Dict[str, object]] = {}
  z_mid: Dict[int, float] = {}  # multi-stage: chosen clear Z channel x

  def obstacles_of(edge_idx: int) -> Dict[str, object]:
    if edge_idx not in _obs_cache:
      ed = scene.edges[edge_idx]
      _obs_cache[edge_idx] = edge_obstacles(scene, ed.src, ed.dst)
    return _obs_cache[edge_idx]

  for idx, e in enumerate(scene.edges):
    s = endpoint(scene, e.src)
    t = endpoint(scene, e.dst)
    if not s or not t:
      continue
    if (
      e.source_anchor in ("left", "right")
      and e.target_anchor in ("left", "right")
      and e.source_anchor != e.target_anchor
    ):
      sx = s.x + s.width if e.source_anchor == "right" else s.x
      tx = t.x if e.target_anchor == "left" else t.x + t.width
      sy = s.y + s.height / 2.0
      ty = t.y + t.height / 2.0
      mid_x = (sx + tx) / 2.0
      hits = (
        _segment_hits_any_card(sx, sy, mid_x, sy, obstacles_of(idx), (e.src, e.dst))
        or _segment_hits_any_card(mid_x, sy, mid_x, ty, obstacles_of(idx), (e.src, e.dst))
        or _segment_hits_any_card(mid_x, ty, tx, ty, obstacles_of(idx), (e.src, e.dst))
      )
      if hits and multi:
        cand = _clear_z_channel(sx, sy, tx, ty, e.source_anchor, obstacles_of(idx),
                                (e.src, e.dst))
        if cand is not None:
          z_mid[idx] = cand
          hits = False
      is_long_span[idx] = hits
      if hits:
        bridge_dir[idx] = "top" if (sy + ty) / 2.0 <= canvas_mid_y else "bottom"
        if multi:
          bridge_dir[idx] = _pick_bridge_dir(
              bridge_dir[idx], sx + (18.0 if e.source_anchor == "right" else -18.0),
              sy, tx + (-18.0 if e.target_anchor == "left" else 18.0), ty,
              obstacles_of(idx), (e.src, e.dst))
    else:
      is_long_span[idx] = False

  # Assign staggered port slots on each card side.
  # For same-side C-brackets (`left -> left` or `right -> right`), order ports so shorter vertical spans
  # sit closer to the partner card (inner bracket) and longer spans sit further out (outer bracket),
  # producing strictly concentric C-brackets that never cross each other!
  side_slots: Dict[Tuple[str, str], List[Tuple[int, str, float]]] = {}
  for idx, e in enumerate(scene.edges):
    s = endpoint(scene, e.src)
    t = endpoint(scene, e.dst)
    if not s or not t:
      continue
    tcx, tcy = t.x + t.width / 2.0, t.y + t.height / 2.0
    scx, scy = s.x + s.width / 2.0, s.y + s.height / 2.0

    if e.source_anchor == e.target_anchor and e.source_anchor in ("left", "right"):
      # Concentric C-bracket port ordering:
      # - Upward brackets (partner above card) sit at the TOP of the card side (-2000 + dist),
      #   with shorter spans above longer spans so outer brackets wrap cleanly around inner brackets.
      # - Downward brackets (partner below card) sit at the BOTTOM of the card side (+2000 - dist),
      #   with shorter spans below longer spans, keeping middle ports for cross-column edges.
      dist = abs(scy - tcy)
      s_sort = (-2000.0 + dist) if tcy < scy else (2000.0 - dist)
      t_sort = (-2000.0 + dist) if scy < tcy else (2000.0 - dist)
    elif is_long_span.get(idx):
      b_bias = -1000.0 if bridge_dir.get(idx) == "top" else 1000.0
      s_sort = b_bias + tcy * 0.1
      t_sort = b_bias + scy * 0.1
    else:
      s_sort = tcy if e.source_anchor in ("left", "right") else tcx
      t_sort = scy if e.target_anchor in ("left", "right") else scx
    side_slots.setdefault((e.src, e.source_anchor), []).append((idx, "src", s_sort))
    side_slots.setdefault((e.dst, e.target_anchor), []).append((idx, "dst", t_sort))

  port_coords: Dict[Tuple[int, str], Tuple[float, float, float, float]] = {}
  for (cid, side), items in side_slots.items():
    card = endpoint(scene, cid)
    items.sort(key=lambda it: (it[2], it[0]))
    n = len(items)
    for rank, (e_idx, role, _) in enumerate(items):
      frac = 0.5 if n == 1 else 0.20 + 0.60 * (rank / (n - 1))
      if side == "left":
        px, py, nx, ny = card.x, card.y + card.height * frac, 0.0, frac
      elif side == "right":
        px, py, nx, ny = card.x + card.width, card.y + card.height * frac, 1.0, frac
      elif side == "top":
        px, py, nx, ny = card.x + card.width * frac, card.y, frac, 0.0
      else:
        px, py, nx, ny = card.x + card.width * frac, card.y + card.height, frac, 1.0
      port_coords[(e_idx, role)] = (px, py, nx, ny)

  used_y_for_h_stubs: List[Tuple[float, float, float]] = []
  for idx, e in enumerate(scene.edges):
    if (idx, "src") not in port_coords or (idx, "dst") not in port_coords:
      continue
    if e.source_anchor in ("left", "right") and e.target_anchor in ("left", "right"):
      x1, y1, nx1, ny1 = port_coords[(idx, "src")]
      x2, y2, nx2, ny2 = port_coords[(idx, "dst")]
      xmin, xmax = min(x1, x2), max(x1, x2)
      for uy, uxmin, uxmax in used_y_for_h_stubs:
        if xmax > uxmin - 20.0 and xmin < uxmax + 20.0:
          if abs(y1 - uy) < 9.0:
            s_card = endpoint(scene, e.src)
            y1 = min(s_card.y + s_card.height - 6.0, y1 + 10.0)
            ny1 = (y1 - s_card.y) / s_card.height
            port_coords[(idx, "src")] = (x1, y1, nx1, ny1)
          if abs(y2 - uy) < 9.0:
            t_card = endpoint(scene, e.dst)
            y2 = max(t_card.y + 6.0, y2 - 10.0)
            ny2 = (y2 - t_card.y) / t_card.height
            port_coords[(idx, "dst")] = (x2, y2, nx2, ny2)
      used_y_for_h_stubs.append((y1, xmin, xmax))
      used_y_for_h_stubs.append((y2, xmin, xmax))

  # Pre-rank same-side C-brackets per column side by vertical span |y1 - y2| so shorter spans
  # take the inner track (`18px`) and longer spans take outer tracks (`32px`, `46px`, ...).
  bracket_groups: Dict[Tuple[int, str], List[Tuple[float, int]]] = {}
  for idx, e in enumerate(scene.edges):
    if (idx, "src") not in port_coords or (idx, "dst") not in port_coords:
      continue
    if e.source_anchor == e.target_anchor and e.source_anchor in ("left", "right"):
      x1, y1, _, _ = port_coords[(idx, "src")]
      _, y2, _, _ = port_coords[(idx, "dst")]
      col_bucket = int(round(x1 / 80.0))
      bracket_groups.setdefault((col_bucket, e.source_anchor), []).append((abs(y2 - y1), idx))

  bracket_offset: Dict[int, float] = {}
  for (_, side), grp in bracket_groups.items():
    grp.sort(key=lambda it: (it[0], it[1]))
    for rank, (_, e_idx) in enumerate(grp):
      bracket_offset[e_idx] = 20.0 + rank * 15.0

  polylines: Dict[int, List[Tuple[float, float]]] = {}
  top_bridge_tracks = 0
  bot_bridge_tracks = 0
  inner_zones = [
    z
    for z in scene.zones.values()
    if z.style_name in ("@VpcZone", "@SubGroupWhite")
  ]

  for idx, e in enumerate(scene.edges):
    if (idx, "src") not in port_coords or (idx, "dst") not in port_coords:
      continue
    x1, y1, _, _ = port_coords[(idx, "src")]
    x2, y2, _, _ = port_coords[(idx, "dst")]
    sa, ta = e.source_anchor, e.target_anchor

    if is_long_span.get(idx):
      s_out = x1 + 18.0 if sa == "right" else x1 - 18.0
      t_in = x2 - 18.0 if ta == "left" else x2 + 18.0
      xmin, xmax = min(s_out, t_in), max(s_out, t_in)
      span_ymins: List[float] = []
      span_ymaxs: List[float] = []
      if multi:
        # Multi-stage: every obstacle box (cards + obstacle zones) in range.
        for oid, o in obstacles_of(idx).items():
          if oid not in (e.src, e.dst) and (o.x + o.width) > xmin + 10.0 and o.x < xmax - 10.0:
            span_ymins.append(o.y)
            span_ymaxs.append(o.y + o.height)
      else:
        for cid, c in scene.cards.items():
          if cid not in (e.src, e.dst) and (c.x + c.width) > xmin + 10.0 and c.x < xmax - 10.0:
            span_ymins.append(c.y)
            span_ymaxs.append(c.y + c.height)
        for z in inner_zones:
          s_card, t_card = scene.cards[e.src], scene.cards[e.dst]
          if z.id in (s_card.parent_zone_id, t_card.parent_zone_id):
            continue
          if (z.x + z.w) > xmin + 10.0 and z.x < xmax - 10.0:
            span_ymins.append(z.y)
            span_ymaxs.append(z.y + z.h)

      if bridge_dir.get(idx) == "top":
        base_top = min(span_ymins, default=min(y1, y2)) - 16.0
        y_bridge = base_top - top_bridge_tracks * 14.0
        top_bridge_tracks += 1
      else:
        base_bot = max(span_ymaxs, default=max(y1, y2)) + 16.0
        y_bridge = base_bot + bot_bridge_tracks * 14.0
        bot_bridge_tracks += 1
      polylines[idx] = [
        (x1, y1),
        (s_out, y1),
        (s_out, y_bridge),
        (t_in, y_bridge),
        (t_in, y2),
        (x2, y2),
      ]
    elif sa in ("left", "right") and ta in ("left", "right") and sa != ta:
      mid_x = z_mid.get(idx, (x1 + x2) / 2.0)
      polylines[idx] = [(x1, y1), (mid_x, y1), (mid_x, y2), (x2, y2)]
    elif sa == "left" and ta == "left":
      off = bracket_offset.get(idx, 22.0)
      out_x = min(x1, x2) - off
      polylines[idx] = [(x1, y1), (out_x, y1), (out_x, y2), (x2, y2)]
    elif sa == "right" and ta == "right":
      off = bracket_offset.get(idx, 22.0)
      out_x = max(x1, x2) + off
      polylines[idx] = [(x1, y1), (out_x, y1), (out_x, y2), (x2, y2)]
    else:
      mid_y = (y1 + y2) / 2.0
      polylines[idx] = [(x1, y1), (x1, mid_y), (x2, mid_y), (x2, y2)]
      if multi and sa in ("top", "bottom") and ta in ("top", "bottom"):
        polylines[idx] = _tree_route(x1, y1, x2, y2, obstacles_of(idx), (e.src, e.dst))

  # 4a. Strict Horizontal Bridge De-Overlapper FIRST:
  h_segs: List[Tuple[int, int, float, float, float]] = []
  for idx, pts in polylines.items():
    for si in range(1, len(pts) - 2):
      p_a, p_b = pts[si], pts[si + 1]
      if abs(p_a[1] - p_b[1]) < 0.5 and abs(p_a[0] - p_b[0]) > 0.5:
        h_segs.append((idx, si, p_a[1], min(p_a[0], p_b[0]), max(p_a[0], p_b[0])))

  h_segs.sort(key=lambda it: (it[2], it[3], it[0]))
  placed_h: List[Tuple[float, float, float]] = []
  if multi:
    # Multi-stage: the fixed first/last stubs are obstacles for movable
    # inner segments too (the original pass only de-collides inner ones).
    placed_h.extend(_stub_segments(polylines, horizontal=True))
  for idx, si, hy, hxmin, hxmax in h_segs:
    new_y = hy
    step_idx = 0
    if multi:
      new_y = _free_h_offset(scene, polylines[idx], si, hy, hxmin, hxmax, placed_h,
                             obstacles_of(idx))
    while not multi and any(
      abs(new_y - py) < 12.0 and hxmax > pxmin - 8.0 and hxmin < pxmax + 8.0
      for py, pxmin, pxmax in placed_h
    ):
      step_idx += 1
      direction = -1.0 if hy < canvas_mid_y else 1.0
      new_y = hy + step_idx * 14.0 * direction
    placed_h.append((new_y, hxmin, hxmax))
    if abs(new_y - hy) > 0.1:
      pts = list(polylines[idx])
      pts[si] = (pts[si][0], new_y)
      pts[si + 1] = (pts[si + 1][0], new_y)
      polylines[idx] = pts

  # 4b. Strict Vertical Corridor De-Overlapper SECOND:
  v_segs: List[Tuple[int, int, float, float, float]] = []
  for idx, pts in polylines.items():
    for si in range(1, len(pts) - 2):
      p_a, p_b = pts[si], pts[si + 1]
      if abs(p_a[0] - p_b[0]) < 0.5 and abs(p_a[1] - p_b[1]) > 0.5:
        v_segs.append((idx, si, p_a[0], min(p_a[1], p_b[1]), max(p_a[1], p_b[1])))

  v_segs.sort(key=lambda it: (it[2], (it[3] + it[4]) / 2.0, it[0]))
  placed_v: List[Tuple[float, float, float]] = []
  if multi:
    placed_v.extend(_stub_segments(polylines, horizontal=False))
  for idx, si, vx, vymin, vymax in v_segs:
    e = scene.edges[idx]
    new_x = vx
    step_idx = 0
    x_lo, x_hi = (_inner_range(polylines[idx], si, axis=0) if multi
                  else (float("-inf"), float("inf")))
    while (
      any(
        abs(new_x - px) < 10.0
        and (vymax > pymin - 24.0 and vymin < pymax + 24.0)
        for px, pymin, pymax in placed_v
      )
      or _segment_hits_any_card(new_x, vymin, new_x, vymax, obstacles_of(idx), (e.src, e.dst), pad=5.0)
    ):
      step_idx += 1
      offset = ((step_idx + 1) // 2) * 11.0 * (1 if step_idx % 2 == 1 else -1)
      new_x = vx + offset
      if multi and not x_lo <= new_x <= x_hi:
        if step_idx > 24:
          new_x = vx
          break
        continue
      if step_idx > 24:
        if multi:
          new_x = vx  # never keep a failed far offset (it can land in a card)
        break
    placed_v.append((new_x, vymin, vymax))
    if abs(new_x - vx) > 0.1:
      pts = list(polylines[idx])
      pts[si] = (new_x, pts[si][1])
      pts[si + 1] = (new_x, pts[si + 1][1])
      polylines[idx] = pts

  # 5. Compute optimal label position on the longest clear segment of each polyline:
  label_pos: Dict[int, Tuple[float, float]] = {}
  placed_pills: List[Tuple[float, float, float, float]] = []

  def _pill_hits_other_edge(
    edge_idx: int, bx1: float, by1: float, bx2: float, by2: float
  ) -> bool:
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
      candidates.append((10.0, (p_a[0] + p_b[0]) / 2.0, (p_a[1] + p_b[1]) / 2.0))
    candidates.sort(key=lambda c: -c[0])

    best_cand = (999999.0, candidates[0][1], candidates[0][2])
    for prio, cx, cy in candidates:
      bx1, by1, bx2, by2 = cx - pw / 2.0, cy - ph / 2.0, cx + pw / 2.0, cy + ph / 2.0
      hit_pill = sum(
        1
        for px1, py1, px2, py2 in placed_pills
        if bx2 > px1 - 8.0 and bx1 < px2 + 8.0 and by2 > py1 - 6.0 and by1 < py2 + 6.0
      )
      hit_card = 1 if _segment_hits_any_card(bx1, by1, bx2, by2, scene.cards, ("", ""), pad=3.0) else 0
      if multi and not hit_card and _box_crosses_zone_border(scene, bx1, by1, bx2, by2):
        hit_card = 1
      hit_other = 1 if _pill_hits_other_edge(idx, bx1, by1, bx2, by2) else 0
      penalty = hit_pill * 10000.0 + hit_card * 5000.0 + hit_other * 200.0 - prio
      if penalty < best_cand[0]:
        best_cand = (penalty, cx, cy)
    chosen_x, chosen_y = best_cand[1], best_cand[2]
    placed_pills.append(
      (chosen_x - pw / 2.0, chosen_y - ph / 2.0, chosen_x + pw / 2.0, chosen_y + ph / 2.0)
    )
    label_pos[idx] = (chosen_x, chosen_y)

  return port_coords, polylines, label_pos


def verify_no_arrow_overlaps(polylines: Dict[int, List[Tuple[float, float]]]) -> List[str]:
  """Mechanical gate verifying that no two edges have overlapping parallel segments."""
  v_all: List[Tuple[int, float, float, float]] = []
  h_all: List[Tuple[int, float, float, float]] = []
  for idx, pts in polylines.items():
    for si in range(len(pts) - 1):
      x1, y1 = pts[si]
      x2, y2 = pts[si + 1]
      if abs(x1 - x2) < 0.5 and abs(y1 - y2) > 2.0:
        v_all.append((idx, x1, min(y1, y2), max(y1, y2)))
      elif abs(y1 - y2) < 0.5 and abs(x1 - x2) > 2.0:
        h_all.append((idx, y1, min(x1, x2), max(x1, x2)))

  errors: List[str] = []
  for i in range(len(v_all)):
    e1, x1, ymin1, ymax1 = v_all[i]
    for j in range(i + 1, len(v_all)):
      e2, x2, ymin2, ymax2 = v_all[j]
      if e1 != e2 and abs(x1 - x2) < 5.0 and min(ymax1, ymax2) - max(ymin1, ymin2) > 4.0:
        errors.append(
          f"Vertical overlap between edge {e1} and edge {e2} at x≈{x1:.1f}, y=[{max(ymin1,ymin2):.1f}..{min(ymax1,ymax2):.1f}]"
        )
  for i in range(len(h_all)):
    e1, y1, xmin1, xmax1 = h_all[i]
    for j in range(i + 1, len(h_all)):
      e2, y2, xmin2, xmax2 = h_all[j]
      # Fixed vs. the scratch engine, which compared against max(xmin1, xmax2)
      # and therefore never reported a horizontal overlap. The 12 networking
      # goldens are clean under the corrected predicate (render bytes unchanged).
      if e1 != e2 and abs(y1 - y2) < 5.0 and min(xmax1, xmax2) - max(xmin1, xmin2) > 4.0:
        errors.append(
          f"Horizontal overlap between edge {e1} and edge {e2} at y≈{y1:.1f}, x=[{max(xmin1,xmin2):.1f}..{min(xmax1,xmax2):.1f}]"
        )
  return errors


# Public name for the router entry point.
route_all_edges = _route_all_edges_non_overlapping
