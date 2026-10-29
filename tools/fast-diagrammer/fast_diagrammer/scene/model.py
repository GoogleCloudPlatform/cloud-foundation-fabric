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
"""Stage-agnostic scene model: zones, cards, edges, badges, presets, icons.

The 2-networking subset (PALETTE / STYLE_PRESETS entries up to `@HubCard`,
the original dataclass fields and their defaults) is byte-parity locked
against `tests/golden/2-networking/`. Everything added for the other stages
defaults to "off" so a networking scene renders exactly as before.
"""

from dataclasses import dataclass, field
import math
import re
from typing import Dict, List, Optional, Union

PALETTE = {
    "$GcpBlue": "#1a73e8",
    "$GcpGreen": "#1e8e3e",
    "$AmberStroke": "#d97706",
    "$CoralRed": "#d93025",
    "$PurpleStroke": "#9334e6",
    "$TealStroke": "#007b83",
    "$DarkSlate": "#202124",
    "$SubText": "#5f6368",
    "$CardBorder": "#dadce0",
    "$SurfaceWhite": "#ffffff",
    # Multi-stage additions. Every semantic colour also has a dash / head /
    # shape cue so colour is never the only signal.
    "$VermilionStroke": "#d55e00",
    "$SlateStroke": "#5f6368",
    "$FolderGrey": "#9aa0a6",
    "$FolderFill": "#f1f3f4",
    "$PerimeterRed": "#d93025",
    "$PerimeterFill": "#fef2f2",
    "$DryRunAmber": "#b05a00",
    "$DryRunFill": "#fef7e0",
    "$BillingGreen": "#1e8e3e",
    "$BillingFill": "#e6f4ea",
}

STYLE_PRESETS = {
    # ---- 2-networking presets: byte-parity locked, do not edit. ----
    # Zone presets may carry layout-only keys that are never emitted:
    # `padding` (inner padding) and `headerHeight` / `headerHeightSubtitle`
    # (title band height without / with a subtitle; default 32 / 48).
    "@Ghost": {
        "fill": "transparent",
        "strokeColor": "none",
        "strokeWidth": 0,
        "borderRadius": 0,
        "padding": 0,
        "gap": 14,
        "fontColor": "transparent",
        "fontSize": 0,
        "dashed": False,
    },
    "@ArchitectureRoot": {
        "fill": "#f8fafd",
        "strokeColor": "#c2d7f5",
        "strokeWidth": 1.5,
        "borderRadius": 16,
        "padding": 24,
        "gap": 28,
        "fontColor": "#3c4043",
        "fontSize": 20,
        "icon": "GoogleCloud",
        "iconSize": 28,
        "dashed": False,
        "headerHeight": 42,
        "headerHeightSubtitle": 66,
    },
    "@ProjectZone": {
        "fill": "#e8f0fe",
        "strokeColor": "#8ab4f8",
        "strokeWidth": 1.5,
        "borderRadius": 12,
        "padding": 18,
        "gap": 18,
        "fontColor": "#202124",
        "fontSize": 15,
        "dashed": False,
    },
    "@VpcZone": {
        "fill": "#fef7e0",
        "strokeColor": "#fbbc04",
        "strokeWidth": 1.5,
        "borderRadius": 10,
        "padding": 28,
        "gap": 12,
        "fontColor": "#202124",
        "fontSize": 14,
        "dashed": False,
    },
    "@ExternalZone": {
        "fill": "#fce8e6",
        "strokeColor": "#f6aea9",
        "strokeWidth": 1.5,
        "borderRadius": 12,
        "padding": 16,
        "gap": 12,
        "fontColor": "#202124",
        "fontSize": 15,
        "dashed": False,
    },
    "@SubGroupWhite": {
        "fill": "#ffffff",
        "strokeColor": "#cbd5e1",
        "strokeWidth": 1.0,
        "borderRadius": 10,
        "padding": 12,
        "gap": 10,
        "fontColor": "#202124",
        "fontSize": 13,
        "dashed": True,
    },
    "@ProductCard": {
        "width": 248,
        "height": 58,
        "fill": "#ffffff",
        "strokeColor": "#dadce0",
        "strokeWidth": 1.0,
        "borderRadius": 8,
        "fontColor": "#202124",
        "subFontColor": "#5f6368",
        "fontSize": 12.5,
        "subFontSize": 10.5,
        "iconSize": 26,
        "padding": 10,
    },
    "@HubCard": {
        "width": 248,
        "height": 60,
        "fill": "#ffffff",
        "strokeColor": "#1a73e8",
        "strokeWidth": 2.0,
        "borderRadius": 8,
        "fontColor": "#202124",
        "subFontColor": "#5f6368",
        "fontSize": 12.5,
        "subFontSize": 10.5,
        "iconSize": 26,
        "padding": 10,
    },
    # ---- Multi-stage zone presets. ----
    "@OrganizationZone": {
        "fill": "#f8fafd",
        "strokeColor": "#5f6368",
        "strokeWidth": 1.5,
        "borderRadius": 16,
        "padding": 24,
        "gap": 28,
        "fontColor": "#202124",
        "fontSize": 20,
        "icon": "Organization",
        "iconSize": 26,
        "dashed": False,
        "headerHeight": 42,
        "headerHeightSubtitle": 66,
    },
    "@FolderZone": {
        "fill": "#f1f3f4",
        "strokeColor": "#9aa0a6",
        "strokeWidth": 1.5,
        "borderRadius": 12,
        "padding": 16,
        "gap": 16,
        "fontColor": "#202124",
        "fontSize": 14,
        "icon": "Folder",
        "dashed": False,
    },
    "@BillingZone": {
        "fill": "#e6f4ea",
        "strokeColor": "#81c995",
        "strokeWidth": 1.5,
        "borderRadius": 12,
        "padding": 16,
        "gap": 12,
        "fontColor": "#202124",
        "fontSize": 15,
        "icon": "BillingAccount",
        "dashed": False,
    },
    "@PerimeterZone": {
        "fill": "#fef2f2",
        "strokeColor": "#d93025",
        "strokeWidth": 2.0,
        "borderRadius": 14,
        "padding": 22,
        "gap": 20,
        "fontColor": "#202124",
        "fontSize": 16,
        "icon": "VPCServiceControls",
        "dashed": True,
        "dashPattern": "10 6",
    },
    "@PerimeterDryRunZone": {
        "fill": "#fffbf0",
        "strokeColor": "#b05a00",
        "strokeWidth": 2.0,
        "borderRadius": 14,
        "padding": 22,
        "gap": 20,
        "fontColor": "#202124",
        "fontSize": 16,
        "icon": "VPCServiceControls",
        "dashed": True,
        "dashPattern": "10 6",
    },
    "@SourcesZone": {
        "fill": "#ffffff",
        "strokeColor": "#cbd5e1",
        "strokeWidth": 1.0,
        "borderRadius": 10,
        "padding": 12,
        "gap": 10,
        "fontColor": "#202124",
        "fontSize": 13,
        "dashed": True,
    },
    "@LegendZone": {
        "fill": "#ffffff",
        "strokeColor": "#e0e0e0",
        "strokeWidth": 1.0,
        "borderRadius": 8,
        "padding": 10,
        "gap": 6,
        "fontColor": "#202124",
        "fontSize": 11,
        "dashed": False,
    },
    # ---- Multi-stage card presets. ----
    "@ProjectCard": {
        "width": 236,
        "height": 58,
        "fill": "#ffffff",
        "strokeColor": "#8ab4f8",
        "strokeWidth": 1.5,
        "borderRadius": 8,
        "icon": "Project",
    },
    "@OrgControlCard": {
        "width": 220,
        "height": 52,
        "fill": "#ffffff",
        "strokeColor": "#dadce0",
        "strokeWidth": 1.0,
        "borderRadius": 8,
    },
    "@AccessLevelCard": {
        "width": 236,
        "height": 58,
        "fill": "#ffffff",
        "strokeColor": "#007b83",
        "strokeWidth": 1.8,
        "borderRadius": 8,
        "icon": "AccessLevel",
    },
    "@IdentityCard": {
        "width": 236,
        "height": 58,
        "fill": "#ffffff",
        "strokeColor": "#5f6368",
        "strokeWidth": 1.5,
        "borderRadius": 8,
        "icon": "IAM",
        "dashed": True,
    },
    "@ResourceSetCard": {
        "width": 248,
        "height": 58,
        "fill": "#ffffff",
        "strokeColor": "#5f6368",
        "strokeWidth": 1.5,
        "borderRadius": 8,
        "icon": "ResourceSet",
        "dashed": True,
    },
    "@ExternalCard": {
        "width": 220,
        "height": 58,
        "fill": "#ffffff",
        "strokeColor": "#d55e00",
        "strokeWidth": 1.8,
        "borderRadius": 8,
        "icon": "Internet",
    },
}

# Card presets: names that `make_card` treats as cards (have width/height).
CARD_PRESETS = tuple(k for k, v in STYLE_PRESETS.items() if "width" in v)
# Zone presets: everything else.
ZONE_PRESETS = tuple(k for k, v in STYLE_PRESETS.items() if "width" not in v)

# Badge pill tones: tone -> (fill, text colour).
BADGE_TONES = {
    "neutral": ("#f1f3f4", "#3c4043"),
    "info": ("#e8f0fe", "#1967d2"),
    "warn": ("#fef7e0", "#b05a00"),
    "danger": ("#fce8e6", "#c5221f"),
    "ok": ("#e6f4ea", "#137333"),
}

# Edge dash vocabulary. "dashed" keeps the legacy `6 4` pattern.
DASH_PATTERNS = {
    "solid": None,
    "dashed": "6 4",
    "dotted": "2 3",
    "dashdot": "8 3 2 3",
}
EDGE_HEADS = ("filled", "open", "none")
EDGE_ARROWS = ("-->", "<-->", "-.->")

# Accepted enum values for the builder API and `validate_scene`.
ANCHORS = ("left", "right", "top", "bottom")
ZONE_LAYOUTS = ("row", "column", "grid")
ZONE_ALIGNS = ("center", "start")
DOCK_SIDES = ("left", "right")
DOCK_ALIGNS = ("start", "center")

_HEX_COLOR = re.compile(r"#[0-9a-fA-F]{6}")
_KEYWORD_COLORS = ("transparent", "none")


def _check_color(val: str, what: str) -> str:
  """Returns `val` when it is `#rrggbb`, `transparent` or `none`."""
  if isinstance(val, str) and (val in _KEYWORD_COLORS or
                               _HEX_COLOR.fullmatch(val)):
    return val
  raise ValueError(
      f"{what}: invalid colour {val!r} (expected #rrggbb, transparent, none "
      f"or a palette token such as $GcpBlue)")


def _check_choice(val, choices, what: str):
  if val not in choices:
    raise ValueError(f"{what}: {val!r} is not one of {', '.join(choices)}")
  return val


def _check_number(val, what: str, *, positive: bool = False) -> float:
  """Returns `val` as a float; it must be finite and >= 0 (> 0 if positive)."""
  if isinstance(val, bool) or not isinstance(val, (int, float)):
    raise ValueError(f"{what}: expected a number, got {val!r}")
  num = float(val)
  if not math.isfinite(num) or num < 0 or (positive and num == 0):
    bound = "> 0" if positive else ">= 0"
    raise ValueError(f"{what}: must be finite and {bound}, got {val!r}")
  return num


def resolve_color(val: Optional[str]) -> str:
  """Resolves a `$Token` through PALETTE and validates the result.

  Empty values resolve to `#202124`. Literal colours must be `#rrggbb`,
  `transparent` or `none`; anything else (including an unknown `$Token`)
  raises ValueError, so no unchecked text reaches a style attribute.
  """
  if not val:
    return "#202124"
  if not isinstance(val, str):
    raise ValueError(f"invalid colour {val!r}")
  val = val.strip().strip('"')
  if val.startswith("$"):
    if val not in PALETTE:
      raise ValueError(f"unknown palette token {val!r}")
    return PALETTE[val]
  return _check_color(val, "colour")


@dataclass
class Badge:
  """A small pill drawn on a card (below the subtitle) or a zone header."""
  text: str
  tone: str = "neutral"  # neutral | info | warn | danger | ok
  icon: Optional[str] = None


@dataclass
class LegendEntry:
  """One legend row. kind: "edge" (line sample), "card" or "zone" (swatch)."""
  label: str
  kind: str = "edge"
  color: str = "#1a73e8"
  dash: str = "solid"
  head: str = "filled"
  fill: str = "#ffffff"
  dashed: bool = False


@dataclass
class CardNode:
  id: str
  title: str
  subtitle: str
  style_name: str = "@ProductCard"
  icon: str = "CloudGeneric"
  width: float = 248.0
  height: float = 58.0
  stroke_color: str = "#dadce0"
  stroke_width: float = 1.0
  fill: str = "#ffffff"
  # Computed layout geometry
  x: float = 0.0
  y: float = 0.0
  parent_zone_id: Optional[str] = None
  # Multi-stage additions (default off => networking bytes unchanged).
  badges: List[Badge] = field(default_factory=list)
  dashed: bool = False


@dataclass
class ZoneNode:
  id: str
  title: str = ""
  subtitle: str = ""
  style_name: str = "@Ghost"
  icon: Optional[str] = None
  layout: str = "column"  # "row", "column" or "grid"
  gap: float = 16.0
  align: str = "center"
  dock_to: Optional[str] = None
  dock_side: Optional[str] = None
  dock_align: Optional[str] = None
  dock_gap: float = 56.0
  children: List[Union["ZoneNode", CardNode]] = field(default_factory=list)
  # Computed layout geometry
  x: float = 0.0
  y: float = 0.0
  w: float = 0.0
  h: float = 0.0
  parent_zone_id: Optional[str] = None
  # Multi-stage additions (default off => networking bytes unchanged).
  badges: List[Badge] = field(default_factory=list)
  max_cols: int = 4  # only used by layout == "grid"

  # Card-compatible geometry so a zone can be an edge endpoint.
  @property
  def width(self) -> float:
    return self.w

  @property
  def height(self) -> float:
    return self.h


@dataclass
class EdgeSpec:
  src: str
  dst: str
  arrow: str  # "-->", "<-->", "-.->"
  label: str
  color: str
  stroke_width: float = 2.0
  dashed: bool = False
  source_anchor: str = "right"
  target_anchor: str = "left"
  # Multi-stage additions. `dash=None` derives from `dashed` (True -> "dashed").
  dash: Optional[str] = None  # solid | dashed | dotted | dashdot
  head: str = "filled"  # filled | open | none
  # Trunk edges leaving the same card side share one port (the side centre
  # when nothing else uses that side) and one vertical trunk, like an org
  # chart. Their mutual overlaps are the shared trunk, not a routing defect.
  trunk: bool = False

  @property
  def dash_style(self) -> str:
    if self.dash:
      return self.dash
    return "dashed" if self.dashed else "solid"

  @property
  def dash_pattern(self) -> Optional[str]:
    return DASH_PATTERNS.get(self.dash_style)


@dataclass
class SceneGraph:
  dataset_name: str
  view_kind: str  # "topology", "dns", "hierarchy", "perimeters", ...
  root_zones: List[ZoneNode] = field(default_factory=list)
  cards: Dict[str, CardNode] = field(default_factory=dict)
  zones: Dict[str, ZoneNode] = field(default_factory=dict)
  edges: List[EdgeSpec] = field(default_factory=list)
  # Multi-stage additions.
  legend: List[LegendEntry] = field(default_factory=list)
  stage: str = ""  # metadata only

  # -- construction helpers (insertion order == document order) --

  def add_zone(self, zone: ZoneNode,
               parent: Optional[ZoneNode] = None) -> ZoneNode:
    """Registers `zone` under `parent` (or as a root) and returns it."""
    if zone.id in self.zones:
      raise ValueError(f"duplicate zone id: {zone.id}")
    if zone.id in self.cards:
      raise ValueError(f"zone id {zone.id!r} is already used by a card")
    zone.parent_zone_id = parent.id if parent else None
    self.zones[zone.id] = zone
    if parent is not None:
      parent.children.append(zone)
    else:
      self.root_zones.append(zone)
    return zone

  def add_card(self, card: CardNode, parent: ZoneNode) -> CardNode:
    """Registers `card` inside `parent` and returns it."""
    if card.id in self.cards:
      raise ValueError(f"duplicate card id: {card.id}")
    if card.id in self.zones:
      raise ValueError(f"card id {card.id!r} is already used by a zone")
    card.parent_zone_id = parent.id if parent else None
    self.cards[card.id] = card
    if parent is not None:
      parent.children.append(card)
    return card

  def add_edge(self, edge: EdgeSpec) -> EdgeSpec:
    self.edges.append(edge)
    return edge


def _check_badges(badges: List[Badge], what: str) -> List[Badge]:
  for b in badges:
    _check_choice(b.tone, tuple(BADGE_TONES), f"{what}: badge tone")
  return badges


def _check_zone(z: ZoneNode) -> None:
  what = f"zone {z.id!r}"
  _check_choice(z.style_name, ZONE_PRESETS, f"{what}: style")
  _check_choice(z.layout, ZONE_LAYOUTS, f"{what}: layout")
  _check_choice(z.align, ZONE_ALIGNS, f"{what}: align")
  _check_number(z.gap, f"{what}: gap")
  _check_number(z.dock_gap, f"{what}: dock_gap")
  if isinstance(z.max_cols,
                bool) or not isinstance(z.max_cols, int) or z.max_cols < 1:
    raise ValueError(f"{what}: max_cols must be an integer >= 1, "
                     f"got {z.max_cols!r}")
  if (z.dock_to is None) != (z.dock_side is None):
    raise ValueError(f"{what}: dock_to and dock_side must be set together")
  if z.dock_side is not None:
    _check_choice(z.dock_side, DOCK_SIDES, f"{what}: dock_side")
  if z.dock_align is not None:
    _check_choice(z.dock_align, DOCK_ALIGNS, f"{what}: dock_align")
  _check_badges(z.badges, what)


def _check_card(c: CardNode) -> None:
  what = f"card {c.id!r}"
  _check_choice(c.style_name, CARD_PRESETS, f"{what}: style")
  _check_number(c.width, f"{what}: width", positive=True)
  _check_number(c.height, f"{what}: height", positive=True)
  _check_badges(c.badges, what)


def _check_card_style(c: CardNode) -> None:
  what = f"card {c.id!r}"
  _check_number(c.stroke_width, f"{what}: stroke_width")
  _check_color(c.stroke_color, f"{what}: stroke_color")
  _check_color(c.fill, f"{what}: fill")


def _check_edge(e: EdgeSpec, what: str) -> None:
  _check_choice(e.source_anchor, ANCHORS, f"{what}: source_anchor")
  _check_choice(e.target_anchor, ANCHORS, f"{what}: target_anchor")


def _check_edge_style(e: EdgeSpec, what: str) -> None:
  _check_choice(e.arrow, EDGE_ARROWS, f"{what}: arrow")
  _check_color(e.color, f"{what}: color")
  _check_number(e.stroke_width, f"{what}: stroke_width")
  if e.dash is not None:
    _check_choice(e.dash, tuple(DASH_PATTERNS), f"{what}: dash")
  _check_choice(e.head, EDGE_HEADS, f"{what}: head")


def validate_scene(scene: SceneGraph) -> None:
  """Raises ValueError when the scene holds values layout cannot honour.

  Covers scenes built without the `make_*` helpers (direct dataclass use,
  `scene_from_dict`): unknown presets, layouts, alignments, dock settings,
  badge tones and anchors; non-finite or non-positive card sizes; negative
  gaps; card ids that collide with zone ids; cards or zones that are not in
  the zone tree exactly once (they would never be laid out); and docked
  zones whose `dock_to` is not a zone inside a primary (undocked) root.
  Colours and other purely visual fields are checked by the `make_*`
  helpers; the emitters sanitise whatever reaches them.
  """
  clash = sorted(set(scene.cards) & set(scene.zones))
  if clash:
    raise ValueError(f"ids used by both a card and a zone: {clash}")
  seen: Dict[str, int] = {}
  stack: List[Union[ZoneNode, CardNode]] = list(reversed(scene.root_zones))
  while stack:
    node = stack.pop()
    seen[node.id] = seen.get(node.id, 0) + 1
    if seen[node.id] > 1:
      raise ValueError(f"{node.id!r} appears more than once in the zone tree")
    if isinstance(node, ZoneNode):
      stack.extend(reversed(node.children))
  missing = sorted(
      i for i in list(scene.zones) + list(scene.cards) if i not in seen)
  if missing:
    raise ValueError(f"not inside any root zone (never laid out): {missing}")
  for z in scene.zones.values():
    _check_zone(z)
  for c in scene.cards.values():
    _check_card(c)
  for i, e in enumerate(scene.edges):
    _check_edge(e, f"edge {i} ({e.src} -> {e.dst})")
  for z in scene.root_zones:
    if z.dock_to is None:
      continue
    target = scene.zones.get(z.dock_to)
    if target is None:
      raise ValueError(f"zone {z.id!r}: dock_to {z.dock_to!r} is not a zone")
    root = target
    while root.parent_zone_id:
      root = scene.zones[root.parent_zone_id]
    if root.dock_to is not None:
      raise ValueError(
          f"zone {z.id!r}: dock_to {z.dock_to!r} must sit inside an undocked "
          "root zone")
  for z in scene.zones.values():
    if z.dock_to is not None and z.parent_zone_id is not None:
      raise ValueError(f"zone {z.id!r}: only root zones can be docked")


def make_zone(zid: str, style: str = "@Ghost", title: str = "",
              subtitle: str = "", *, icon: Optional[str] = None,
              layout: str = "column", gap: Optional[float] = None,
              align: str = "center", dock_to: Optional[str] = None,
              dock_side: Optional[str] = None, dock_align: Optional[str] = None,
              dock_gap: float = 56.0, badges: Optional[List[Badge]] = None,
              max_cols: int = 4) -> ZoneNode:
  """Builds a ZoneNode the way the legacy scene-text parser would.

  The preset `gap` applies unless `gap` is given explicitly; the preset
  `icon` (only `@ArchitectureRoot` among the networking presets) applies
  unless `icon` is given. Raises ValueError for an unknown or card preset,
  an unknown `layout` / `align` / `dock_side` / `dock_align`, a negative or
  non-finite gap, `max_cols < 1`, or `dock_to` without `dock_side`.
  """
  if style not in ZONE_PRESETS:
    raise ValueError(f"zone {zid!r}: unknown zone style {style!r}")
  preset = STYLE_PRESETS[style]
  z_gap = 16.0
  if "gap" in preset:
    z_gap = float(preset["gap"])
  if gap is not None:
    z_gap = _check_number(gap, f"zone {zid!r}: gap")
  z_icon = icon if icon is not None else preset.get("icon") or None
  zone = ZoneNode(
      id=zid,
      title=title,
      subtitle=subtitle,
      style_name=style,
      icon=z_icon,
      layout=layout,
      gap=z_gap,
      align=align,
      dock_to=dock_to,
      dock_side=dock_side,
      dock_align=dock_align,
      dock_gap=_check_number(dock_gap, f"zone {zid!r}: dock_gap"),
      badges=list(badges or []),
      max_cols=max_cols,
  )
  _check_zone(zone)
  return zone


def make_card(cid: str, title: str, subtitle: str = "",
              style: str = "@ProductCard", *, icon: Optional[str] = None,
              width: Optional[float] = None, height: Optional[float] = None,
              stroke_color: Optional[str] = None,
              stroke_width: Optional[float] = None, fill: Optional[str] = None,
              badges: Optional[List[Badge]] = None,
              dashed: Optional[bool] = None) -> CardNode:
  """Builds a CardNode the way the legacy scene-text parser would.

  `style` must be a card preset; `stroke_color` and `fill` accept
  `$Palette` tokens; `width` / `height` must be finite and > 0. `icon`
  defaults to the preset icon, else `CloudGeneric`. Raises ValueError on
  invalid input.
  """
  if style not in CARD_PRESETS:
    raise ValueError(f"card {cid!r}: unknown card style {style!r}")
  preset = STYLE_PRESETS[style]
  card = CardNode(
      id=cid,
      title=title,
      subtitle=subtitle,
      style_name=style,
      icon=icon if icon is not None else preset.get("icon", "CloudGeneric"),
      width=_check_number(width if width is not None else preset["width"],
                          f"card {cid!r}: width", positive=True),
      height=_check_number(height if height is not None else preset["height"],
                           f"card {cid!r}: height", positive=True),
      stroke_color=(resolve_color(stroke_color)
                    if stroke_color is not None else preset["strokeColor"]),
      stroke_width=_check_number(
          stroke_width if stroke_width is not None else preset["strokeWidth"],
          f"card {cid!r}: stroke_width"),
      fill=(resolve_color(fill) if fill is not None else preset.get(
          "fill", "#ffffff")),
      badges=list(badges or []),
      dashed=bool(
          dashed if dashed is not None else preset.get("dashed", False)),
  )
  _check_card(card)
  _check_card_style(card)
  return card


def make_edge(src: str, dst: str, arrow: str = "-->", label: str = "",
              color: Optional[str] = None, *, stroke_width: float = 2.0,
              dashed: Optional[bool] = None, dash: Optional[str] = None,
              head: str = "filled", source_anchor: str = "right",
              target_anchor: str = "left", trunk: bool = False) -> EdgeSpec:
  """Builds an EdgeSpec with parser semantics.

  `color` accepts `$Palette` tokens (default `#1a73e8`); `dashed` defaults to
  `arrow == "-.->"` exactly like the legacy parser. Anchors must be one of
  `left`, `right`, `top`, `bottom`. `trunk` makes the edge share its source
  port and trunk with the other trunk edges leaving the same card side.
  Raises ValueError on invalid input.
  """
  if dash is not None and dash not in DASH_PATTERNS:
    raise ValueError(f"unknown dash style: {dash}")
  if head not in EDGE_HEADS:
    raise ValueError(f"unknown edge head: {head}")
  is_dashed = (arrow == "-.->") if dashed is None else (bool(dashed) or
                                                        arrow == "-.->")
  edge = EdgeSpec(
      src=src,
      dst=dst,
      arrow=arrow,
      label=label,
      color=resolve_color(color) if color else "#1a73e8",
      stroke_width=_check_number(stroke_width, "edge stroke_width"),
      dashed=is_dashed,
      source_anchor=source_anchor,
      target_anchor=target_anchor,
      dash=dash,
      head=head,
      trunk=bool(trunk),
  )
  _check_edge(edge, f"edge {src} -> {dst}")
  _check_edge_style(edge, f"edge {src} -> {dst}")
  return edge


@dataclass(frozen=True)
class IconSpec:
  """Registry entry: `file` is the vendored SVG in `fast_diagrammer/icons/`."""
  file: str
  default_size: float = 26.0


_ICON_NAMES = (
    # Legacy 13 (byte-identical inner markup; networking parity).
    "GoogleCloud",
    "VirtualPrivateCloud",
    "NetworkConnectivityCenter",
    "CloudVPN",
    "CloudInterconnect",
    "CloudRouter",
    "CloudNAT",
    "CloudDNS",
    "LoadBalancing",
    "ComputeEngine",
    "CloudGeneric",
    "Networking",
    "Server",
    # 0-org-setup / 1-vpcsc additions.
    "Organization",
    "Folder",
    "Project",
    "BillingAccount",
    "CloudLogging",
    "CloudMonitoring",
    "BigQuery",
    "CloudStorage",
    "IAM",
    "ServiceAccount",
    "ServiceAgent",
    "KeyManagementService",
    "OrganizationPolicy",
    "Tags",
    "SecurityCommandCenter",
    "CloudBuild",
    "WorkloadIdentity",
    "VPCServiceControls",
    "AccessLevel",
    "ResourceSet",
    "ApiService",
    "CloudFirewall",
    "Subnet",
    "Internet",
)

GCP_ICONS: Dict[str, IconSpec] = {
    name: IconSpec(file=f"{name}.svg") for name in _ICON_NAMES
}
