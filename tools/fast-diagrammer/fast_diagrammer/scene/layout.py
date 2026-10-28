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
"""Pure-Python flexbox layout + closest-side anchor solving.

Ported verbatim from the scratch `engine_1_pyflex_drawio.py` (golden parity);
additions (card/zone badges, `grid` zones, `@OrganizationZone` header) only
take effect when the corresponding model fields are set.
"""

from typing import Dict, List, Tuple, Union

from .model import Badge, CardNode, EdgeSpec, STYLE_PRESETS, SceneGraph, ZoneNode
from .router import _segment_hits_any_card, edge_obstacles

# Minimum vertical gap (in px) required between two vertically stacked cards
# to allow a straight `bottom -> top` arrow (2 arrowheads + 17px label pill + stems).
MIN_VERTICAL_ARROW_GAP = 48.0

# Badge pill geometry (shared with emit_svg).
BADGE_H = 16.0
BADGE_ROW_PITCH = 18.0
BADGE_GAP = 4.0
BADGE_FONT = 9.5
BADGE_MAX_ROWS = 2
CARD_TEXT_X = 48.0  # icon x (12) + icon size (26) + 10


def badge_width(text: str) -> float:
  # ~5.4 px/char at 9.5 px semi-bold + 6 px padding each side. Rows wrap at
  # card.width - 56 and start at card.x + 48, so pills end >= 8 px inside.
  return max(24.0, len(text) * 5.4 + 12.0)


def layout_badges(badges: List[Badge],
                  max_w: float,
                  max_rows: int = BADGE_MAX_ROWS
                 ) -> List[List[Tuple[Badge, float]]]:
  """Greedy-wraps badges into at most `max_rows` rows of width `max_w`.

  Overflowing badges collapse into a trailing `+N` neutral pill.
  """
  rows: List[List[Tuple[Badge, float]]] = [[]]
  cur_w = 0.0
  for i, b in enumerate(badges):
    bw = badge_width(b.text)
    need = bw if not rows[-1] else cur_w + BADGE_GAP + bw
    if rows[-1] and need > max_w:
      if len(rows) >= max_rows:
        remaining = len(badges) - i
        _append_overflow(rows, remaining, max_w)
        return rows
      rows.append([])
      cur_w = 0.0
      need = bw
    rows[-1].append((b, bw))
    cur_w = need
  return [r for r in rows if r]


def _append_overflow(rows: List[List[Tuple[Badge, float]]], remaining: int,
                     max_w: float) -> None:
  last = rows[-1]
  while True:
    more = Badge(text=f"+{remaining}", tone="neutral")
    mw = badge_width(more.text)
    used = sum(w for _, w in last) + BADGE_GAP * len(last)
    if not last or used + mw <= max_w:
      last.append((more, mw))
      return
    last.pop()
    remaining += 1


def card_badge_top(c: CardNode) -> float:
  """Offset from the card top where the first badge row starts."""
  if not c.subtitle:
    return 36.0
  if len(c.subtitle) > 38 and " · " in c.subtitle:
    return 60.0
  return 50.0


def card_badge_rows(c: CardNode) -> List[List[Tuple[Badge, float]]]:
  return layout_badges(c.badges, c.width - CARD_TEXT_X - 8.0)


def zone_badge_strip_width(z: ZoneNode) -> float:
  if not z.badges:
    return 0.0
  return sum(badge_width(b.text) for b in z.badges) + BADGE_GAP * (
      len(z.badges) - 1)


def _zone_header_height(z: ZoneNode) -> float:
  if z.style_name == "@Ghost" or (not z.title and not z.subtitle):
    return 0.0
  if z.style_name in ("@ArchitectureRoot", "@OrganizationZone"):
    return 66.0 if z.subtitle else 42.0
  if z.subtitle:
    return 48.0
  return 32.0


def _zone_padding(z: ZoneNode) -> float:
  if z.style_name == "@Ghost":
    return 0.0
  if z.style_name == "@VpcZone":
    return 28.0
  preset = STYLE_PRESETS.get(z.style_name, {})
  return float(preset.get("padding", 16.0))


def _child_w(ch: Union[ZoneNode, CardNode]) -> float:
  return ch.w if isinstance(ch, ZoneNode) else ch.width


def _child_h(ch: Union[ZoneNode, CardNode]) -> float:
  return ch.h if isinstance(ch, ZoneNode) else ch.height


def _grid_rows(node: ZoneNode) -> List[List[Union[ZoneNode, CardNode]]]:
  cols = max(1, int(node.max_cols))
  return [node.children[i:i + cols] for i in range(0, len(node.children), cols)]


def measure_node(node: Union[ZoneNode, CardNode]) -> Tuple[float, float]:
  if isinstance(node, CardNode):
    if len(node.subtitle) > 40:
      node.height = max(node.height, 66.0)
    if node.badges:
      rows = card_badge_rows(node)
      need = card_badge_top(node) + len(rows) * BADGE_ROW_PITCH + 4.0
      node.height = max(node.height, need)
    return node.width, node.height

  pad = _zone_padding(node)
  hdr = _zone_header_height(node)
  if not node.children:
    node.w = max(200.0, pad * 2)
    if node.badges and node.title:
      node.w = max(node.w, _badge_title_min_w(node))
    node.h = hdr + pad * 2
    return node.w, node.h

  child_sizes = [measure_node(ch) for ch in node.children]
  gap = node.gap

  if node.layout == "row":
    content_w = sum(w for w, _ in child_sizes) + gap * max(0, len(child_sizes) - 1)
    content_h = max(h for _, h in child_sizes)
  elif node.layout == "grid":
    rows = _grid_rows(node)
    row_ws = [
        sum(_child_w(c) for c in r) + gap * max(0, len(r) - 1) for r in rows
    ]
    row_hs = [max(_child_h(c) for c in r) for r in rows]
    content_w = max(row_ws)
    content_h = sum(row_hs) + gap * max(0, len(rows) - 1)
  else:
    content_w = max(w for w, _ in child_sizes)
    content_h = sum(h for _, h in child_sizes) + gap * max(0, len(child_sizes) - 1)

  min_title_w = (
      max(len(node.title) * 9.0 + 70.0, len(node.subtitle) * 7.2 + 70.0)
      if node.title
      else 0.0
  )
  if node.badges and node.title:
    min_title_w = max(min_title_w, _badge_title_min_w(node))
  node.w = max(content_w + pad * 2, min_title_w)
  node.h = hdr + content_h + pad * 2
  return node.w, node.h


def _badge_title_min_w(node: ZoneNode) -> float:
  preset = STYLE_PRESETS.get(node.style_name, {})
  fsize = float(preset.get("fontSize", 15) or 15)
  icon_w = 0.0
  if node.icon:
    icon_w = (26.0 if node.style_name in ("@ArchitectureRoot",
                                         "@OrganizationZone") else 20.0) + 10.0
  title_w = len(node.title) * fsize * 0.6
  return 18.0 + icon_w + title_w + 24.0 + zone_badge_strip_width(node) + 16.0


def place_node(node: Union[ZoneNode, CardNode], x: float, y: float) -> None:
  node.x = x
  node.y = y
  if isinstance(node, CardNode):
    return

  pad = _zone_padding(node)
  hdr = _zone_header_height(node)
  inner_x = x + pad
  inner_y = y + hdr + pad
  inner_w = node.w - pad * 2
  inner_h = node.h - hdr - pad * 2

  if not node.children:
    return

  if node.layout == "row":
    total_w = sum(
        (ch.w if isinstance(ch, ZoneNode) else ch.width) for ch in node.children
    ) + node.gap * max(0, len(node.children) - 1)
    cur_x = inner_x + max(0.0, (inner_w - total_w) / 2.0)
    for ch in node.children:
      cw = ch.w if isinstance(ch, ZoneNode) else ch.width
      ch_h = ch.h if isinstance(ch, ZoneNode) else ch.height
      cy = inner_y + (inner_h - ch_h) / 2.0 if node.align == "center" else inner_y
      place_node(ch, cur_x, cy)
      cur_x += cw + node.gap
  elif node.layout == "grid":
    cur_y = inner_y
    for row in _grid_rows(node):
      row_w = sum(_child_w(c) for c in row) + node.gap * max(0, len(row) - 1)
      row_h = max(_child_h(c) for c in row)
      cur_x = inner_x + (max(0.0, (inner_w - row_w) / 2.0)
                         if node.align == "center" else 0.0)
      for ch in row:
        ch_h = _child_h(ch)
        cy = cur_y + (row_h - ch_h) / 2.0 if node.align == "center" else cur_y
        place_node(ch, cur_x, cy)
        cur_x += _child_w(ch) + node.gap
      cur_y += row_h + node.gap
  else:
    total_h = sum(
        (ch.h if isinstance(ch, ZoneNode) else ch.height) for ch in node.children
    ) + node.gap * max(0, len(node.children) - 1)
    cur_y = inner_y + max(0.0, (inner_h - total_h) / 2.0)
    for ch in node.children:
      cw = ch.w if isinstance(ch, ZoneNode) else ch.width
      ch_h = ch.h if isinstance(ch, ZoneNode) else ch.height
      cx = inner_x + (inner_w - cw) / 2.0 if node.align == "center" else inner_x
      place_node(ch, cx, cur_y)
      cur_y += ch_h + node.gap


def shift_subtree(node: Union[ZoneNode, CardNode], dx: float, dy: float) -> None:
  node.x += dx
  node.y += dy
  if isinstance(node, ZoneNode):
    for ch in node.children:
      shift_subtree(ch, dx, dy)


def _endpoint(scene: SceneGraph, eid: str):
  """Edge endpoint: a card, else a zone (zones expose width/height)."""
  return scene.cards.get(eid) or scene.zones.get(eid)


def _is_multistage(scene: SceneGraph) -> bool:
  return bool(scene.stage) and scene.stage != "2-networking"


def fit_card_width(c: CardNode) -> None:
  """Widens a card so its title and subtitle lines never overflow it.

  Multi-stage only (2-networking widths are parity locked). Estimates:
  12.5 px bold title ~7.4 px/char, 10.5 px subtitle ~6.0 px/char (the
  ` · ` split renders two 10.2 px lines), text starts 48 px in, 14 px right
  margin.
  """
  need = CARD_TEXT_X + len(c.title) * 7.4 + 14.0
  sub = c.subtitle
  if sub:
    if len(sub) > 38 and " · " in sub:
      p1, p2 = sub.split(" · ", 1)
      longest = max(len(p1), len(p2) + 2)
    else:
      longest = len(sub)
    need = max(need, CARD_TEXT_X + longest * 6.0 + 14.0)
  c.width = max(c.width, round(need))


def _keeps_vertical_anchors(e: EdgeSpec, sy1: float, sy2: float, ty1: float,
                            ty2: float) -> bool:
  """Multi-stage: builder-set `bottom -> top` (or reverse) with a real gap."""
  if (e.source_anchor, e.target_anchor) == ("bottom", "top"):
    return sy2 + 12.0 <= ty1
  if (e.source_anchor, e.target_anchor) == ("top", "bottom"):
    return ty2 + 12.0 <= sy1
  return False


def layout_scene(scene: SceneGraph) -> Tuple[float, float]:
  if _is_multistage(scene):
    for c in scene.cards.values():
      fit_card_width(c)
  primary_roots = [z for z in scene.root_zones if not z.dock_to]
  docked_roots = [z for z in scene.root_zones if z.dock_to]

  # 2-networking row-gap floor (parity locked); multi-stage builders own their gaps.
  if not _is_multistage(scene):
    for z in scene.zones.values():
      if z.layout == "row":
        z.gap = max(z.gap, 68.0 if scene.view_kind == "dns" else 56.0)

  cur_x = 32.0
  cur_y = 32.0
  for rz in primary_roots:
    measure_node(rz)
    place_node(rz, cur_x, cur_y)
    cur_x += rz.w + 48.0

  for dz in docked_roots:
    measure_node(dz)
    target = scene.zones.get(dz.dock_to or "")
    if target and dz.dock_side == "left":
      gcp_root = primary_roots[0] if primary_roots else target
      dx_pos = gcp_root.x - dz.w - dz.dock_gap
      dy_pos = (
          target.y
          if dz.dock_align == "start"
          else (target.y + (target.h - dz.h) / 2.0)
      )
      place_node(dz, dx_pos, dy_pos)
    else:
      place_node(dz, cur_x, cur_y)
      cur_x += dz.w + 48.0

  all_zones = list(scene.zones.values())
  min_x = min((z.x for z in all_zones), default=32.0)
  min_y = min((z.y for z in all_zones), default=32.0)
  shift_x = 32.0 - min_x if min_x < 32.0 else 0.0
  shift_y = 32.0 - min_y if min_y < 32.0 else 0.0
  if shift_x or shift_y:
    for rz in scene.root_zones:
      shift_subtree(rz, shift_x, shift_y)

  max_x = max((z.x + z.w for z in all_zones), default=1200.0) + 32.0
  max_y = max((z.y + z.h for z in all_zones), default=800.0) + 32.0

  # Pass 1 of anchor solving: resolve cross-column edges (`right -> left` / `left -> right`)
  # and count how many cross-column edges use each card's `left` vs `right` side.
  cross_side_load: Dict[Tuple[str, str], int] = {}
  same_col_edges: List[EdgeSpec] = []
  multi = _is_multistage(scene)

  for e in scene.edges:
    s = _endpoint(scene, e.src)
    t = _endpoint(scene, e.dst)
    if not s or not t:
      continue
    sx1, sy1, sx2, sy2 = s.x, s.y, s.x + s.width, s.y + s.height
    tx1, ty1, tx2, ty2 = t.x, t.y, t.x + t.width, t.y + t.height

    if multi and _keeps_vertical_anchors(e, sy1, sy2, ty1, ty2):
      continue  # explicit tree edge (bottom -> top / top -> bottom) is kept
    if sx2 + 10.0 < tx1:
      e.source_anchor, e.target_anchor = "right", "left"
      cross_side_load[(e.src, "right")] = cross_side_load.get((e.src, "right"), 0) + 1
      cross_side_load[(e.dst, "left")] = cross_side_load.get((e.dst, "left"), 0) + 1
    elif tx2 + 10.0 < sx1:
      e.source_anchor, e.target_anchor = "left", "right"
      cross_side_load[(e.src, "left")] = cross_side_load.get((e.src, "left"), 0) + 1
      cross_side_load[(e.dst, "right")] = cross_side_load.get((e.dst, "right"), 0) + 1
    else:
      same_col_edges.append(e)

  # Pass 2 of anchor solving: resolve same-column edges using:
  #   (a) Minimum vertical clearance threshold (`dy_gap >= MIN_VERTICAL_ARROW_GAP` and unblocked)
  #   (b) Least-congested side selection (`left -> left` vs `right -> right`) when `dy_gap < MIN_VERTICAL_ARROW_GAP` or blocked!
  for e in same_col_edges:
    s = _endpoint(scene, e.src)
    t = _endpoint(scene, e.dst)
    sx1, sy1, sx2, sy2 = s.x, s.y, s.x + s.width, s.y + s.height
    tx1, ty1, tx2, ty2 = t.x, t.y, t.x + t.width, t.y + t.height
    scx, scy = (sx1 + sx2) / 2.0, (sy1 + sy2) / 2.0
    tcx, tcy = (tx1 + tx2) / 2.0, (ty1 + ty2) / 2.0

    ymin, ymax = min(scy, tcy), max(scy, tcy)
    if multi:
      # Only what sits in the vertical gap between the two boxes counts, and
      # never the contents of an endpoint zone or the zones holding either.
      g1, g2 = (sy2, ty1) if scy < tcy else (ty2, sy1)
      obs = edge_obstacles(scene, e.src, e.dst)
      blocked = g2 <= g1 or any(
          _segment_hits_any_card(x, g1, x, g2, obs, (e.src, e.dst), pad=2.0)
          for x in (scx, tcx))
    else:
      blocked = any(
          other_id not in (e.src, e.dst)
          and abs((oc.x + oc.width / 2.0) - scx) < 60.0
          and ymin < (oc.y + oc.height / 2.0) < ymax
          for other_id, oc in scene.cards.items()
      )
    dy_gap = (ty1 - sy2) if scy < tcy else (sy1 - ty2)

    if not blocked and dy_gap >= MIN_VERTICAL_ARROW_GAP:
      if scy < tcy:
        e.source_anchor, e.target_anchor = "bottom", "top"
      else:
        e.source_anchor, e.target_anchor = "top", "bottom"
    else:
      # Score `left` vs `right` on the pair (src, dst) and their column neighbors:
      # Prefer the side with fewer cross-column connections on src and dst.
      left_load = (
          cross_side_load.get((e.src, "left"), 0) * 10
          + cross_side_load.get((e.dst, "left"), 0) * 10
          + sum(
              cross_side_load.get((cid, "left"), 0)
              for cid, oc in scene.cards.items()
              if abs((oc.x + oc.width / 2.0) - scx) < 60.0
          )
      )
      right_load = (
          cross_side_load.get((e.src, "right"), 0) * 10
          + cross_side_load.get((e.dst, "right"), 0) * 10
          + sum(
              cross_side_load.get((cid, "right"), 0)
              for cid, oc in scene.cards.items()
              if abs((oc.x + oc.width / 2.0) - scx) < 60.0
          )
      )
      chosen_side = "right" if right_load <= left_load else "left"
      e.source_anchor, e.target_anchor = chosen_side, chosen_side

  return max_x, max_y
