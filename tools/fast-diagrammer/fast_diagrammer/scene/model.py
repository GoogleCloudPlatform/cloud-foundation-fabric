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
    # Multi-stage additions (spec §5.1). Every semantic colour also has a
    # dash / head / shape cue so colour is never the only signal.
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
        "padding": 14,
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
    # ---- Multi-stage zone presets (spec §5.2). ----
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
    # ---- Multi-stage card presets (spec §5.3). ----
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

# Badge pill tones (spec §5.3 `@BadgePill`): tone -> (fill, text colour).
BADGE_TONES = {
    "neutral": ("#f1f3f4", "#3c4043"),
    "info": ("#e8f0fe", "#1967d2"),
    "warn": ("#fef7e0", "#b05a00"),
    "danger": ("#fce8e6", "#c5221f"),
    "ok": ("#e6f4ea", "#137333"),
}

# Edge dash vocabulary (spec §5.1). "dashed" keeps the legacy `6 4` bytes.
DASH_PATTERNS = {
    "solid": None,
    "dashed": "6 4",
    "dotted": "2 3",
    "dashdot": "8 3 2 3",
}
EDGE_HEADS = ("filled", "open", "none")


def resolve_color(val: Optional[str]) -> str:
  """Resolves a `$Token` through PALETTE; literal colours pass through."""
  if not val:
    return "#202124"
  val = val.strip().strip('"')
  return PALETTE.get(val, val)


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

  def add_zone(self,
               zone: ZoneNode,
               parent: Optional[ZoneNode] = None) -> ZoneNode:
    """Registers `zone` under `parent` (or as a root) and returns it."""
    if zone.id in self.zones:
      raise ValueError(f"duplicate zone id: {zone.id}")
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
    card.parent_zone_id = parent.id if parent else None
    self.cards[card.id] = card
    if parent is not None:
      parent.children.append(card)
    return card

  def add_edge(self, edge: EdgeSpec) -> EdgeSpec:
    self.edges.append(edge)
    return edge


def make_zone(zid: str,
              style: str = "@Ghost",
              title: str = "",
              subtitle: str = "",
              *,
              icon: Optional[str] = None,
              layout: str = "column",
              gap: Optional[float] = None,
              align: str = "center",
              dock_to: Optional[str] = None,
              dock_side: Optional[str] = None,
              dock_align: Optional[str] = None,
              dock_gap: float = 56.0,
              badges: Optional[List[Badge]] = None,
              max_cols: int = 4) -> ZoneNode:
  """Builds a ZoneNode the way the legacy scene-text parser would.

  Parity rules mirrored: the preset `gap` applies unless `gap` is given
  explicitly (an explicit `gap:` after `style:` wins); the preset `icon`
  (only `@ArchitectureRoot` among the networking presets) applies unless
  `icon` is given; `style=None`-like unknown presets keep gap 16.
  """
  preset = STYLE_PRESETS.get(style, {})
  z_gap = 16.0
  if "gap" in preset:
    z_gap = float(preset["gap"])
  if gap is not None:
    z_gap = float(gap)
  z_icon = icon if icon is not None else preset.get("icon") or None
  return ZoneNode(
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
      dock_gap=float(dock_gap),
      badges=list(badges or []),
      max_cols=max_cols,
  )


def make_card(cid: str,
              title: str,
              subtitle: str = "",
              style: str = "@ProductCard",
              *,
              icon: Optional[str] = None,
              width: Optional[float] = None,
              height: Optional[float] = None,
              stroke_color: Optional[str] = None,
              stroke_width: Optional[float] = None,
              fill: Optional[str] = None,
              badges: Optional[List[Badge]] = None,
              dashed: Optional[bool] = None) -> CardNode:
  """Builds a CardNode the way the legacy scene-text parser would.

  Unknown styles fall back to `@ProductCard` geometry (parser behaviour).
  `stroke_color` accepts `$Palette` tokens. `icon` defaults to the preset
  icon, else `CloudGeneric`.
  """
  preset = STYLE_PRESETS.get(style)
  if preset is None or "width" not in preset:
    preset = STYLE_PRESETS["@ProductCard"]
  return CardNode(
      id=cid,
      title=title,
      subtitle=subtitle,
      style_name=style,
      icon=icon if icon is not None else preset.get("icon", "CloudGeneric"),
      width=float(width if width is not None else preset["width"]),
      height=float(height if height is not None else preset["height"]),
      stroke_color=(resolve_color(stroke_color)
                    if stroke_color is not None else preset["strokeColor"]),
      stroke_width=float(stroke_width
                         if stroke_width is not None else preset["strokeWidth"]),
      fill=fill if fill is not None else preset.get("fill", "#ffffff"),
      badges=list(badges or []),
      dashed=bool(dashed if dashed is not None else preset.get("dashed", False)),
  )


def make_edge(src: str,
              dst: str,
              arrow: str = "-->",
              label: str = "",
              color: Optional[str] = None,
              *,
              stroke_width: float = 2.0,
              dashed: Optional[bool] = None,
              dash: Optional[str] = None,
              head: str = "filled",
              source_anchor: str = "right",
              target_anchor: str = "left") -> EdgeSpec:
  """Builds an EdgeSpec with parser semantics.

  `color` accepts `$Palette` tokens (default `#1a73e8`); `dashed` defaults to
  `arrow == "-.->"` exactly like the legacy parser.
  """
  if dash is not None and dash not in DASH_PATTERNS:
    raise ValueError(f"unknown dash style: {dash}")
  if head not in EDGE_HEADS:
    raise ValueError(f"unknown edge head: {head}")
  is_dashed = (arrow == "-.->") if dashed is None else (bool(dashed) or
                                                        arrow == "-.->")
  return EdgeSpec(
      src=src,
      dst=dst,
      arrow=arrow,
      label=label,
      color=resolve_color(color) if color else "#1a73e8",
      stroke_width=float(stroke_width),
      dashed=is_dashed,
      source_anchor=source_anchor,
      target_anchor=target_anchor,
      dash=dash,
      head=head,
  )


@dataclass(frozen=True)
class IconSpec:
  """Registry entry: `file` is the vendored SVG under `fast_diagrammer/icons/`."""
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
    # 0-org-setup / 1-vpcsc additions (spec §5.4).
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
