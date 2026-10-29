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
"""FAST `2-networking` -> SceneGraph builders (`topology` and `dns` views).

Topology: one `@ProjectZone` per project of the dataset (projects without
network resources included), core projects (hybrid/transit VPCs, NCC hubs,
NVAs) on the left, spoke projects in a column on the right, on-premises sites
docked to the left of the first core project. Each VPC is a `@VpcZone` with
cards for HA VPN gateways, VLAN attachments, Cloud Routers, router appliance
NICs, NVA load balancers, peering and NCC spoke attachments, ILB next-hop
routes and Cloud NAT. Edges are drawn only for relationships present in the
dataset (BGP sessions, HA VPN tunnels, VLAN attachments, peerings, NCC
spokes, NVA NICs).

DNS: the same projects with their Cloud DNS zones, response policies and
VPCs; edges show zone bindings, DNS peering and forwarding.

Factories disabled with `factories_config.<name>: "none"` contribute nothing
to either view: no card, no edge, no on-premises site that only they use.
Both views carry a legend built from the edge kinds actually drawn.
"""

import pathlib
from typing import Dict, List

from .. import tokens
from ..datasets.networking import load_dataset
from ..scene.model import SceneGraph, make_card, make_edge, make_zone
from ._common import (
    SECONDARY_NAME_HINTS,
    VPC_ROLE_BY_NAME,
    cid,
    join_limited,
    legend_edge,
)

__all__ = ["VIEWS", "build", "build_dns", "build_topology"]

VIEWS = ("topology", "dns")

# Short region labels used in card subtitles; other regions print in full.
SHORT_REGIONS = {
    "europe-west1": "ew1",
    "europe-west4": "ew4",
    "europe-west8": "ew8",
    "us-central1": "usc1",
    "us-east1": "use1",
}

# Fabric defaults applied when the dataset leaves a field unset
# (`modules/net-vpc` routing_mode, `fast/stages/2-networking/factory-ncc.tf`).
DEFAULT_ROUTING_MODE = "GLOBAL"
DEFAULT_NCC_TOPOLOGY = "MESH"

# Left-to-right VPC ordering inside a core project and the secondary router
# appliance path are derived from the data (`_Net.vpc_role_rank`,
# `_Net.is_secondary`); `_common.VPC_ROLE_BY_NAME` and
# `_common.SECONDARY_NAME_HINTS` are the documented name fallbacks.

# Placeholder project key for resources that carry no `project_id`.
UNSPECIFIED_PROJECT = "(no project_id)"

# Factories whose content this builder draws, keyed by `factories_config` name.
FACTORY_VPNS = "vpns"
FACTORY_VLAN_ATTACHMENTS = "vlan_attachments"

# Edge kinds: legend label, colour token, dash style, arrow head. Within a
# view no two kinds share a (dash, head) pair, so link types never differ by
# colour alone; a `none` head draws a plain line (symmetric relationships).
# The legend lists exactly the kinds drawn, in first-use order, with the
# style of the edges. VLAN attachments reuse the BGP and hybrid spoke kinds
# (their card says what they are) and ILB legs reuse the NVA NIC kind.
EDGE_KINDS = {
    "bgp": ("Cloud Router BGP session", "$GcpBlue", "solid", "filled"),
    "vpn_site": ("HA VPN to on-premises", "$CoralRed", "solid", "open"),
    "vpn_vpc": ("HA VPN between VPCs", "$PurpleStroke", "solid", "none"),
    "interconnect":
        ("Interconnect VLAN attachment", "$CoralRed", "dashed", "filled"),
    "peering": ("VPC peering", "$GcpGreen", "dashed", "none"),
    "ncc_vpc": ("NCC VPC spoke", "$GcpGreen", "dashed", "open"),
    "ncc_hybrid": ("NCC hybrid spoke", "$GcpBlue", "dashdot", "none"),
    "ncc_ra": ("NCC router appliance spoke", "$PurpleStroke", "dotted", "none"),
    "ebgp": ("Router appliance eBGP", "$GcpBlue", "dashdot", "filled"),
    "ebgp_secondary": ("Router appliance eBGP (secondary region)",
                       "$AmberStroke", "dashdot", "open"),
    "nic":
        ("NVA NIC (router appliance or ILB)", "$GcpGreen", "dotted", "filled"),
    "nic_secondary":
        ("NVA NIC (secondary region)", "$AmberStroke", "dotted", "open"),
    "dns_bind": ("Zone bound to VPC", "$GcpBlue", "dashed", "filled"),
    "dns_forward":
        ("DNS forwarding to on-premises", "$CoralRed", "solid", "filled"),
    "dns_peer": ("DNS peering", "$PurpleStroke", "solid", "open"),
    "dns_rpz_bind":
        ("Response policy bound to VPC", "$TealStroke", "dotted", "filled"),
}

# Google API VIPs recognised in response policy CNAME rules.
_GOOGLE_VIPS = ("private.googleapis.com", "restricted.googleapis.com")


def build(dataset, view="topology", dataset_name=None, *, rpz_bind_lines=False,
          legend=True):
  """Returns the SceneGraph for `view` of a dataset directory or loaded IR."""
  if isinstance(dataset, (str, pathlib.Path)):
    dataset_name = dataset_name or pathlib.Path(dataset).name
    ir = load_dataset(dataset)
  else:
    ir = dataset
  if not dataset_name:
    raise ValueError("dataset_name is required when passing a loaded IR")
  if view == "topology":
    return build_topology(ir, dataset_name, legend=legend)
  if view == "dns":
    return build_dns(ir, dataset_name, rpz_bind_lines=rpz_bind_lines,
                     legend=legend)
  raise ValueError(f"unknown 2-networking view: {view!r} (expected {VIEWS})")


# --- dataset helpers ----------------------------------------------------------


def _short_region(ir, reg_tok):
  reg = ir.resolve_region(reg_tok) if reg_tok else ""
  return SHORT_REGIONS.get(reg, reg)


def _router_name_from_ref(ref):
  if not ref:
    return None
  key = tokens.key_of(ref, "routers")
  if key and "/" in key:
    return key.split("/", 1)[1]
  return key or ref


def _net_key(value):
  return tokens.key_of(value, "networks") or value


def _project_key(value):
  """Project key of a `project_id` value (token, literal or missing)."""
  if not value:
    return UNSPECIFIED_PROJECT
  return tokens.key_of(value, "project_ids") or str(value)


def _project_kind(ir, pkey):
  proj = ir.projects.get(pkey)
  return "Shared VPC host" if proj is not None and proj.shared_vpc_host else (
      "Project")


def _vpc_project(vpc):
  return vpc.project or UNSPECIFIED_PROJECT


class _Net:
  """Dataset view with disabled factories removed."""

  def __init__(self, ir):
    self.ir = ir
    # The loader already skips the files of disabled factories; filtering
    # here as well keeps the rule in one visible place for the builder.
    self.disabled = {k: v.disabled_factories for k, v in ir.vpcs.items()}
    self.links = [l for l in ir.links if self._link_enabled(l)]
    self.site_keys = []
    for l in self.links:
      skey = l.b.get("site") if l.type in ("vpn", "vlan") else None
      if skey and skey not in self.site_keys and skey in ir.sites:
        self.site_keys.append(skey)
    self.locations = ((ir.defaults or {}).get("context") or
                      {}).get("locations") or {}

  def enabled(self, vpc_key, factory):
    return factory not in self.disabled.get(vpc_key, frozenset())

  def vpns(self, vpc_key):
    vpc = self.ir.vpcs[vpc_key]
    return vpc.vpns if self.enabled(vpc_key, FACTORY_VPNS) else []

  def vlans(self, vpc_key):
    vpc = self.ir.vpcs[vpc_key]
    return (vpc.vlan_attachments
            if self.enabled(vpc_key, FACTORY_VLAN_ATTACHMENTS) else [])

  def _link_enabled(self, link):
    if link.type == "vpn":
      ends = [link.a] + ([link.b] if "vpc" in link.b else [])
      return all(self.enabled(e["vpc"], FACTORY_VPNS) for e in ends)
    if link.type == "vlan":
      return self.enabled(link.a["vpc"], FACTORY_VLAN_ATTACHMENTS)
    if link.type == "ncc_spoke":
      if "vpn" in link.b:
        return self.enabled(link.b["vpn"][0], FACTORY_VPNS)
      if "vlan" in link.b:
        return self.enabled(link.b["vlan"][0], FACTORY_VLAN_ATTACHMENTS)
    return True

  def is_secondary(self, key, region_tok):
    primary = self.locations.get("primary")
    if primary and region_tok:
      return self.ir.resolve_region(region_tok) != primary
    return any(h in key for h in SECONDARY_NAME_HINTS)

  def vpc_role_rank(self, vpc_key):
    """Left-to-right rank: hybrid/egress (0), transit (1), spoke (2)."""
    hybrid = any(
        l.type in ("vpn",
                   "vlan") and l.a.get("vpc") == vpc_key and "site" in l.b
        for l in self.links)
    masq = any(nic.vpc == vpc_key and nic.masquerade
               for nva in self.ir.nvas.values()
               for nic in nva.nics)
    if hybrid or masq:
      return (0, vpc_key)
    neighbours = set()
    for l in self.links:
      if l.type not in ("peering", "vpn") or "vpc" not in l.b:
        continue
      if l.a.get("vpc") == vpc_key:
        neighbours.add(l.b["vpc"])
      elif l.b.get("vpc") == vpc_key:
        neighbours.add(l.a.get("vpc"))
    if len(neighbours) >= 2:
      return (1, vpc_key)
    return (VPC_ROLE_BY_NAME.get(vpc_key, 2), vpc_key)


class _Builder:
  """Zone stack over `SceneGraph.add_*` with edge kinds and legend rows."""

  def __init__(self, dataset_name, view_kind):
    self.scene = SceneGraph(dataset_name=dataset_name, view_kind=view_kind,
                            stage="2-networking")
    self._stack = []
    self._kinds = []

  def open(self, zid, style, title="", subtitle="", **kw):
    parent = self._stack[-1] if self._stack else None
    zone = self.scene.add_zone(make_zone(zid, style, title, subtitle, **kw),
                               parent)
    self._stack.append(zone)
    return zone

  def close(self):
    self._stack.pop()

  def card(self, card_id, title, subtitle, style="@ProductCard", **kw):
    self.scene.add_card(make_card(card_id, title, subtitle, style, **kw),
                        self._stack[-1])
    return card_id

  def edge(self, kind, src, dst, arrow, label, sa, ta, width):
    """Adds an edge of `kind`; a missing endpoint means no relationship."""
    if not src or not dst:
      return
    _, color, dash, head = EDGE_KINDS[kind]
    self.scene.add_edge(
        make_edge(src, dst, "-->" if head == "none" else arrow, label, color,
                  stroke_width=width, dashed=dash != "solid", dash=dash,
                  head=head, source_anchor=sa, target_anchor=ta))
    if kind not in self._kinds:
      self._kinds.append(kind)

  def finish(self, legend):
    assert not self._stack, "unbalanced zones"
    known = set(self.scene.cards) | set(self.scene.zones)
    dangling = [(e.src, e.dst)
                for e in self.scene.edges
                if e.src not in known or e.dst not in known]
    if dangling:
      raise ValueError(f"edges with unknown endpoints: {dangling}")
    if legend:
      self.scene.legend = [legend_edge(*EDGE_KINDS[k]) for k in self._kinds]
    return self.scene


def _projects_in_order(ir, *groups):
  """Project keys: dataset projects first, then any only referenced."""
  keys = list(ir.projects)
  for group in groups:
    for k in group:
      if k not in keys:
        keys.append(k)
  return keys


# --- topology view ------------------------------------------------------------


def build_topology(ir, dataset_name, legend=True):
  net = _Net(ir)
  b = _Builder(dataset_name, "topology")

  def edge(kind, src, dst, arrow, label, sa="right", ta="left"):
    b.edge(kind, src, dst, arrow, label, sa, ta, 2.0)

  proj_vpcs: Dict[str, List[str]] = {}
  for vkey, vpc in ir.vpcs.items():
    proj_vpcs.setdefault(_vpc_project(vpc), []).append(vkey)
  for vkeys in proj_vpcs.values():
    vkeys.sort(key=net.vpc_role_rank)
  proj_hubs: Dict[str, List[str]] = {}
  for hkey, hub in ir.ncc_hubs.items():
    proj_hubs.setdefault(hub.project or UNSPECIFIED_PROJECT, []).append(hkey)
  proj_nvas: Dict[str, List[str]] = {}
  for nkey, nva in ir.nvas.items():
    proj_nvas.setdefault(nva.project or UNSPECIFIED_PROJECT, []).append(nkey)

  all_projects = _projects_in_order(ir, proj_vpcs, proj_hubs, proj_nvas)
  core_projects = [
      p for p in all_projects if proj_hubs.get(p) or proj_nvas.get(p) or any(
          net.vpc_role_rank(v)[0] < 2 for v in proj_vpcs.get(p, []))
  ]
  spoke_projects = [
      p for p in all_projects if p not in core_projects and proj_vpcs.get(p)
  ]
  empty_projects = [
      p for p in all_projects
      if p not in core_projects and p not in spoke_projects
  ]

  vpc_peerings = {v: [] for v in ir.vpcs}
  vpc_ncc_spokes = {v: [] for v in ir.vpcs}
  for l in net.links:
    if l.type == "peering":
      vpc_peerings[l.a["vpc"]].append(l.b["vpc"])
      vpc_peerings[l.b["vpc"]].append(l.a["vpc"])
    elif l.type == "ncc_spoke" and "vpc" in l.b and "nva" not in l.b:
      vpc_ncc_spokes[l.b["vpc"]].append((l.a["hub"], l.a.get("group")))

  b.open("GoogleCloudRoot", "@ArchitectureRoot", "Google Cloud",
         f"FAST 2-networking — {dataset_name} (Network & Routing Topology)",
         layout="row", gap=34, align="center")

  vpc_peering_anchor = {}
  vpc_spoke_anchor = {}
  vlan_anchor = {}
  vpn_anchor = {}
  nic_ra_anchor = {}

  def router_card(vpc_key, rname, rcfg):
    rcid = cid("rtr", vpc_key, rname)
    reg = _short_region(ir, rcfg.get("region"))
    asn = rcfg.get("asn")
    sub = " ".join(p for p in (f"ASN {asn}" if asn else "",
                               f"({reg})" if reg else "") if p)
    b.card(rcid, f"Router: {rname}", sub, icon="CloudRouter")
    return rcid

  def vlan_card(vpc_key, vlans):
    vcid = cid("vlan", vpc_key)
    b.card(vcid, "VLAN Attachments", join_limited((a.name for a in vlans), 38),
           icon="CloudInterconnect")
    vlan_anchor[vpc_key] = vcid
    return vcid

  def vpc_zone(vpc_key):
    vpc = ir.vpcs[vpc_key]
    mode_str = f"{vpc.routing_mode or DEFAULT_ROUTING_MODE} routing"
    b.open(cid("Vpc", vpc_key), "@VpcZone", f"VPC: {vpc_key}", mode_str,
           icon="VirtualPrivateCloud", layout="column", gap=12, align="center")

    emitted_routers = set()
    any_card = False
    vpns = net.vpns(vpc_key)
    vlans = net.vlans(vpc_key)

    router_to_vpns = {}
    for gw in vpns:
      rtr_name = _router_name_from_ref((gw.router_config or {}).get("name"))
      router_to_vpns.setdefault(rtr_name, []).append(gw)

    vlan_rtr_name = None
    if vlans:
      vlan_rtr_name = _router_name_from_ref((vlans[0].router_config or
                                             {}).get("name"))
    vlan_pending = bool(vlans)

    for rtr_name, gws in router_to_vpns.items():
      has_router = bool(rtr_name) and rtr_name in vpc.routers
      for gw in gws:
        gcid = cid("vpn", vpc_key, gw.name)
        any_card = True
        sub = (f"Router: {rtr_name}"
               if rtr_name else f"{len(gw.tunnels)} tunnel(s)")
        b.card(gcid, f"HA VPN: {gw.name}", sub, icon="CloudVPN")
        vpn_anchor[(vpc_key, gw.name)] = gcid
        if has_router:
          edge("bgp", gcid, cid("rtr", vpc_key, rtr_name), "<-->", "BGP",
               "bottom", "top")
      if vlan_pending and vlan_rtr_name == rtr_name:
        vcid = vlan_card(vpc_key, vlans)
        any_card = True
        if has_router:
          edge("bgp", vcid, cid("rtr", vpc_key, rtr_name), "<-->", "BGP",
               "bottom", "top")
        vlan_pending = False
      if has_router and rtr_name not in emitted_routers:
        router_card(vpc_key, rtr_name, vpc.routers[rtr_name])
        emitted_routers.add(rtr_name)

    if vlan_pending:
      vcid = vlan_card(vpc_key, vlans)
      any_card = True
      if vlan_rtr_name in vpc.routers:
        if vlan_rtr_name not in emitted_routers:
          router_card(vpc_key, vlan_rtr_name, vpc.routers[vlan_rtr_name])
          emitted_routers.add(vlan_rtr_name)
        edge("bgp", vcid, cid("rtr", vpc_key, vlan_rtr_name), "<-->", "BGP",
             "bottom", "top")

    for rname, rcfg in vpc.routers.items():
      if rname not in emitted_routers:
        any_card = True
        router_card(vpc_key, rname, rcfg)
        emitted_routers.add(rname)

    ra_nics = [(nkey, idx, nic)
               for nkey, nva in ir.nvas.items()
               for idx, nic in enumerate(nva.nics)
               if nic.vpc == vpc_key and not nic.ilb]
    ilb_nics = [(nkey, idx, nic)
                for nkey, nva in ir.nvas.items()
                for idx, nic in enumerate(nva.nics)
                if nic.vpc == vpc_key and nic.ilb]

    if ra_nics:
      ncid = cid("nic_ra", vpc_key)
      any_card = True
      routes = []
      for _, _, n in ra_nics:
        for r in n.routes:
          if r not in routes:
            routes.append(r)
      flags = []
      if routes:
        flags.append(f"routes: {join_limited(routes, 34, sep=',')}")
      if any(n.extra.get("advertise") for _, _, n in ra_nics):
        flags.append("BGP advertise")
      sub = " · ".join(flags) if flags else "Router Appliance NICs"
      idxs = []
      for _, idx, _ in ra_nics:
        if f"nic{idx}" not in idxs:
          idxs.append(f"nic{idx}")
      b.card(ncid, f"NVA {'/'.join(idxs)} Interfaces", sub, icon="Networking")
      nic_ra_anchor[vpc_key] = ncid
      for rname, rcfg in vpc.routers.items():
        if rcfg.get("peers") or rcfg.get("interfaces"):
          sec = net.is_secondary(rname, rcfg.get("region"))
          edge("ebgp_secondary" if sec else "ebgp", cid("rtr", vpc_key, rname),
               ncid, "<-->", "eBGP", "bottom", "top")
      for nkey, idx, _ in ra_nics:
        sec = net.is_secondary(nkey, ir.nvas[nkey].region)
        edge("nic_secondary" if sec else "nic", ncid, cid("nva", nkey), "<-->",
             f"nic{idx}")

    for nkey, idx, nic in ilb_nics:
      ilb_cid = cid("ilb", vpc_key, nkey)
      any_card = True
      flags = [f"NVA nic{idx}"]
      if nic.routes:
        flags.append(f"routes: {join_limited(nic.routes, 34, sep=',')}")
      b.card(ilb_cid, f"ILB & NVA nic{idx} ({nkey})", " · ".join(flags),
             icon="LoadBalancing")
      edge("nic", ilb_cid, cid("nva", nkey), "<-->", f"nic{idx} ILB")

    if vpc_peerings.get(vpc_key):
      pcid = cid("peering_attachment", vpc_key)
      any_card = True
      peers = sorted(set(vpc_peerings[vpc_key]))
      b.card(pcid, "VPC Peering", f"Peers: {join_limited(peers, 30)}",
             icon="VirtualPrivateCloud")
      vpc_peering_anchor[vpc_key] = pcid

    if vpc_ncc_spokes.get(vpc_key):
      scid = cid("ncc_spoke_attachment", vpc_key)
      any_card = True
      hubs = []
      for hkey, grp in vpc_ncc_spokes[vpc_key]:
        label = f"{hkey} ({f'group: {grp}' if grp else 'default group'})"
        if label not in hubs:
          hubs.append(label)
      b.card(scid, f"NCC VPC Spoke: {vpc_key}",
             f"Hub: {join_limited(hubs, 36)}", icon="NetworkConnectivityCenter")
      vpc_spoke_anchor[vpc_key] = scid

    ilb_routes = [(rk, rv)
                  for rk, rv in vpc.routes.items()
                  if (rv or {}).get("next_hop_type") == "ilb"]
    if len(ilb_routes) == 1:
      rk, rv = ilb_routes[0]
      any_card = True
      hop = tokens.key_of(rv.get("next_hop"),
                          "addresses") or rv.get("next_hop") or vpc_key
      b.card(cid("route", vpc_key, rk), f"Route: {rk} ({rv.get('dest_range')})",
             f"next-hop: ILB ({hop})", icon="Networking")
    elif ilb_routes:
      any_card = True
      ranges = [str((rv or {}).get("dest_range")) for _, rv in ilb_routes]
      b.card(cid("routes_ilb", vpc_key), f"Routes via ILB ({len(ilb_routes)})",
             join_limited(ranges, 38), icon="Networking")

    if vpc.nat:
      any_card = True
      nat_parts = []
      for k, v in vpc.nat.items():
        reg = _short_region(ir, (v or {}).get("region"))
        nat_parts.append(f"{k} ({reg})" if reg else k)
      b.card(cid("nat", vpc_key), "Cloud NAT", join_limited(nat_parts, 40),
             icon="CloudNAT")

    if not any_card:
      b.card(cid("vpc_attachment", vpc_key), "VPC Routing Table",
             f"{vpc_key} ({mode_str})", icon="VirtualPrivateCloud")

    b.close()

  def hub_card(hkey, **kw):
    hub = ir.ncc_hubs[hkey]
    topo = hub.preset_topology or DEFAULT_NCC_TOPOLOGY
    grps = ", ".join(hub.groups.keys()) if hub.groups else "default"
    b.card(cid("ncc_hub", hkey), f"NCC Hub: {hkey}", f"{topo} (groups: {grps})",
           "@HubCard", icon="NetworkConnectivityCenter", **kw)

  def project_zone(pkey, role, **kw):
    sub = " · ".join(p for p in (_project_kind(ir, pkey), role) if p)
    return b.open(cid("Proj", pkey), "@ProjectZone", f"Project: {pkey}", sub,
                  icon="CloudGeneric", align="center", **kw)

  for pkey in core_projects:
    p_vpcs = proj_vpcs.get(pkey, [])
    p_hubs = proj_hubs.get(pkey, [])
    p_nvas = proj_nvas.get(pkey, [])
    project_zone(pkey, "core networking", layout="row", gap=36)

    if len(p_vpcs) > 1 and (p_nvas or len(p_hubs) > 1):
      left_vpcs = [v for v in p_vpcs if net.vpc_role_rank(v)[0] == 0]
      right_vpcs = [v for v in p_vpcs if v not in left_vpcs]
    else:
      left_vpcs = p_vpcs
      right_vpcs = []

    if left_vpcs:
      b.open(cid("CoreLeftVpcs", pkey), "@Ghost", layout="column", gap=16,
             align="center")
      for v in left_vpcs:
        vpc_zone(v)
      b.close()

    mid_hubs = p_hubs[:1] if len(p_hubs) > 1 else (
        p_hubs if not right_vpcs else [])
    right_hubs = p_hubs[1:] if len(p_hubs) > 1 else (
        p_hubs if right_vpcs else [])

    if mid_hubs or p_nvas:
      b.open(cid("CoreProjectMid", pkey), "@Ghost", layout="column", gap=18,
             align="center")
      for hkey in mid_hubs:
        hub_card(hkey)
      if p_nvas:
        b.open(cid("NvaCluster", pkey), "@SubGroupWhite", "NVA VM Instances",
               layout="column", gap=12, align="center")
        for nkey in p_nvas:
          nva = ir.nvas[nkey]
          reg = _short_region(ir, nva.region)
          bgp = nva.extra.get("bgp_config") or {}
          asn_str = (f" · BGP ASN {bgp.get('asn')}"
                     if bgp.get("asn") else " · Static/ILB")
          ig = (nva.extra.get("instance_groups") or
                nva.ilb_config.get("instance_groups") or {})
          where = " ".join(p for p in (reg, "/".join(sorted(ig))) if p)
          title = f"NVA: {nva.name or nkey}" + (f" ({where})" if where else "")
          sec = net.is_secondary(nkey, nva.region)
          b.card(cid("nva", nkey), title, f"{len(nva.nics)} NICs{asn_str}",
                 icon="ComputeEngine",
                 stroke_color="$AmberStroke" if sec else "$GcpGreen",
                 stroke_width=1.8)
        b.close()
      b.close()

    if right_vpcs:
      b.open(cid("CoreRightVpcs", pkey), "@Ghost", layout="column", gap=16,
             align="center")
      for v in right_vpcs:
        vpc_zone(v)
      b.close()

    for hkey in right_hubs:
      hub_card(hkey, stroke_color="$PurpleStroke")

    b.close()

  if spoke_projects or empty_projects:
    b.open("SpokeProjectsCol", "@Ghost", layout="column", gap=18,
           align="center")
    for pkey in spoke_projects:
      project_zone(pkey, "spoke", layout="column", gap=12)
      for v in proj_vpcs.get(pkey, []):
        vpc_zone(v)
      b.close()
    for pkey in empty_projects:
      project_zone(pkey, "", layout="column", gap=12)
      proj = ir.projects.get(pkey)
      name = proj.name if proj is not None else None
      b.card(cid("proj_empty", pkey), "No network resources",
             f"name: {name}" if name else "no VPCs, hubs or NVAs",
             icon="CloudGeneric")
      b.close()
    b.close()

  b.close()  # GoogleCloudRoot

  dock_project = (core_projects + spoke_projects + empty_projects)[:1]
  if net.site_keys and dock_project:
    b.open("ExternalHybrid", "@Ghost", layout="column", gap=16, align="center",
           dock_to=cid("Proj", dock_project[0]), dock_side="left",
           dock_align="start", dock_gap=56)
    for skey in net.site_keys:
      site = ir.sites[skey]
      asn_sub = f"ASN {site.asn}" if site.asn else "External Network"
      b.open(cid("SiteZone", skey), "@ExternalZone", f"On-Premises ({skey})",
             asn_sub, icon="Server")
      b.card(cid("site", skey), "On-Premises Router", asn_sub, width=190,
             icon="Server")
      b.close()
    b.close()

  vlan_linked_sites = set()
  vlan_linked_hubs = set()
  ra_linked_hubs = set()

  for link in net.links:
    if link.type == "vpn":
      a_cid = vpn_anchor.get((link.a["vpc"], link.a["name"]))
      if "site" in link.b:
        edge("vpn_site", cid("site", link.b["site"]), a_cid, "<-->", "HA VPN")
      else:
        edge("vpn_vpc", a_cid, vpn_anchor.get((link.b["vpc"], link.b["name"])),
             "<-->", "HA VPN")
    elif link.type == "vlan":
      vpc_key = link.a["vpc"]
      skey = link.b["site"]
      if (vpc_key, skey) not in vlan_linked_sites:
        vlan_linked_sites.add((vpc_key, skey))
        edge("interconnect", cid("site", skey), vlan_anchor.get(vpc_key),
             "<-->", "Interconnect")
    elif link.type == "peering":
      edge("peering", vpc_peering_anchor.get(link.a["vpc"]),
           vpc_peering_anchor.get(link.b["vpc"]), "<-->", "VPC Peering")
    elif link.type == "ncc_spoke":
      hkey = link.a["hub"]
      grp = link.a.get("group")
      hcid = cid("ncc_hub", hkey) if hkey in ir.ncc_hubs else None
      target = link.b
      if "vpc" in target and "nva" not in target:
        lbl = f"VPC Spoke ({grp})" if grp else "VPC Spoke"
        edge("ncc_vpc", hcid, vpc_spoke_anchor.get(target["vpc"]), "<-->", lbl)
      elif "vpn" in target:
        vpc_key, gw_name = target["vpn"]
        edge("ncc_hybrid", vpn_anchor.get((vpc_key, gw_name)), hcid, "-->",
             "Hybrid Spoke")
      elif "vlan" in target:
        vpc_key, _ = target["vlan"]
        if (vpc_key, hkey) not in vlan_linked_hubs:
          vlan_linked_hubs.add((vpc_key, hkey))
          edge("ncc_hybrid", vlan_anchor.get(vpc_key), hcid, "-->",
               "Hybrid Spoke")
      elif "nva" in target:
        vpc_key = target["vpc"]
        if (vpc_key, hkey) not in ra_linked_hubs:
          ra_linked_hubs.add((vpc_key, hkey))
          lbl = f"RA Spoke ({grp})" if grp else "RA Spokes"
          edge("ncc_ra", nic_ra_anchor.get(vpc_key), hcid, "-->", lbl)

  return b.finish(legend)


# --- dns view -----------------------------------------------------------------


def _rpz_rule_summary(rules):
  """Counts response policy rules by what they do, most frequent first."""
  counts: Dict[str, int] = {}
  for rule in (rules or {}).values():
    rule = rule or {}
    if rule.get("behavior"):
      what = str(rule["behavior"])
    else:
      what = "local data"
      for rtype, rdata in sorted((rule.get("local_data") or {}).items()):
        datas = (rdata or {}).get("rrdatas") or []
        target = str(datas[0]).rstrip(".") if datas else ""
        if rtype == "CNAME" and target in _GOOGLE_VIPS:
          what = f"→ {target}"
        else:
          what = f"{rtype} record"
        break
    counts[what] = counts.get(what, 0) + 1
  return [
      f"{n} {what}"
      for what, n in sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))
  ]


def _plural(n, word, plural=None):
  return f"{n} {word if n == 1 else (plural or word + 's')}"


def build_dns(ir, dataset_name, rpz_bind_lines=False, legend=True):
  b = _Builder(dataset_name, "dns")

  def edge(kind, src, dst, arrow, label, sa, ta):
    dashed = EDGE_KINDS[kind][2] != "solid"
    b.edge(kind, src, dst, arrow, label, sa, ta, 1.6 if dashed else 2.2)

  zones_by_proj: Dict[str, list] = {}
  rpz_by_proj: Dict[str, list] = {}
  forwarder_ips: List[str] = []
  has_forwarding = False
  peer_targets: List[str] = []
  fwd_clients: List[str] = []

  for rel, doc in sorted(ir.opaque.items()):
    if not isinstance(doc, dict):
      continue
    if rel.startswith("dns/zones/"):
      zname = pathlib.Path(rel).stem
      proj = _project_key(doc.get("project_id"))
      zones_by_proj.setdefault(proj, []).append((zname, doc))
      if "forwarding" in doc:
        has_forwarding = True
        fwd = doc["forwarding"] or {}
        for ip in (fwd.get("forwarders") or {}).keys():
          if ip not in forwarder_ips:
            forwarder_ips.append(ip)
        for c in fwd.get("client_networks") or []:
          if _net_key(c) not in fwd_clients:
            fwd_clients.append(_net_key(c))
      elif "peering" in doc:
        peer = tokens.key_of((doc["peering"] or {}).get("peer_network"),
                             "networks")
        if peer and peer not in peer_targets:
          peer_targets.append(peer)
    elif rel.startswith("dns/response-policies/"):
      rname = pathlib.Path(rel).stem
      proj = _project_key(doc.get("project_id"))
      rpz_by_proj.setdefault(proj, []).append((rname, doc))

  net = _Net(ir)
  proj_vpcs: Dict[str, List[str]] = {}
  for vkey, vpc in ir.vpcs.items():
    proj_vpcs.setdefault(_vpc_project(vpc), []).append(vkey)
  for vkeys in proj_vpcs.values():
    vkeys.sort(key=net.vpc_role_rank)

  # The resolver hub is the VPC other VPCs peer their DNS with; without
  # peering zones, the VPC bound to the forwarding zones.
  hub_candidates = peer_targets or fwd_clients
  dns_hub_vpc = next((v for v in hub_candidates if v in ir.vpcs), None)

  bound_count: Dict[str, int] = {}
  for zlist in zones_by_proj.values():
    for _, doc in zlist:
      for kind in ("forwarding", "peering", "private"):
        if kind in doc:
          for c in (doc[kind] or {}).get("client_networks") or []:
            bound_count[_net_key(c)] = bound_count.get(_net_key(c), 0) + 1

  all_projects = _projects_in_order(ir, proj_vpcs, zones_by_proj, rpz_by_proj)
  hub_project = (_vpc_project(ir.vpcs[dns_hub_vpc]) if dns_hub_vpc else None)
  core_projects = [
      p for p in all_projects if p == hub_project or rpz_by_proj.get(p) or any(
          "forwarding" in d for _, d in zones_by_proj.get(p, []))
  ]
  spoke_projects = [p for p in all_projects if p not in core_projects]

  b.open(
      "GoogleCloudRoot", "@ArchitectureRoot", "Google Cloud",
      f"FAST 2-networking — {dataset_name} (Cloud DNS Overlay: Dashed = "
      "Bind · Solid = Peer / Forward)", layout="row", gap=36, align="center")

  def dns_vpc(vkey):
    if vkey == dns_hub_vpc:
      role = "Central Resolver Hub"
    elif bound_count.get(vkey):
      role = f"Client VPC · {_plural(bound_count[vkey], 'bound zone')}"
    else:
      role = "No DNS zones bound"
    b.open(cid("DnsVpcZone", vkey), "@VpcZone", f"VPC: {vkey}",
           icon="VirtualPrivateCloud", layout="column", gap=10, align="center")
    b.card(cid("dns_vpc", vkey), f"VPC: {vkey}", role,
           icon="VirtualPrivateCloud")
    b.close()

  def vpc_cid(vkey):
    return cid("dns_vpc", vkey) if vkey in ir.vpcs else None

  def bind_edges(zcid, clients):
    for c in clients:
      edge("dns_bind", zcid, vpc_cid(c), "-.->", "Bind", "right", "left")

  def zone_card(pkey, zname, doc):
    zcid = cid("zone", pkey, zname)
    dom = doc.get("domain", "")
    if "forwarding" in doc:
      fwd = doc["forwarding"] or {}
      fwds = list((fwd.get("forwarders") or {}).keys())
      clients = [_net_key(c) for c in (fwd.get("client_networks") or [])]
      b.card(zcid, f"FWD Zone: {dom}", (f"Target IPs: {join_limited(fwds, 30)}"
                                        if fwds else "no forwarders defined"),
             icon="CloudDNS", stroke_color="$CoralRed", stroke_width=1.8)
      label = f"Forward({', '.join(fwds)})" if fwds else "Forward"
      edge("dns_forward", zcid, "onprem_dns", "-->", label, "left", "right")
      bind_edges(zcid, clients)
    elif "peering" in doc:
      peering = doc["peering"] or {}
      peer_vpc = tokens.key_of(peering.get("peer_network"), "networks")
      clients = [_net_key(c) for c in (peering.get("client_networks") or [])]
      b.card(zcid, f"Peering Zone: '{dom}'",
             f"Target: {peer_vpc} · Bound: {join_limited(clients, 28)}",
             icon="CloudDNS", stroke_color="$PurpleStroke", stroke_width=1.8)
      if peer_vpc:
        edge("dns_peer", zcid, vpc_cid(peer_vpc), "-->", f"Peer ({peer_vpc})",
             "left", "right")
      bind_edges(zcid, clients)
    elif "private" in doc:
      clients = [
          _net_key(c)
          for c in ((doc["private"] or {}).get("client_networks") or [])
      ]
      b.card(zcid, f"PVT Zone: {dom}",
             f"Bound VPCs: {join_limited(clients, 34)}", icon="CloudDNS",
             stroke_color="$GcpGreen", stroke_width=1.8)
      bind_edges(zcid, clients)
    else:
      b.card(zcid, f"Zone: {dom}", "no zone type configured", icon="CloudDNS",
             stroke_width=1.8)

  def rpz_cards(pkey):
    for rname, doc in rpz_by_proj.get(pkey, []):
      rcid = cid("rpz", pkey, rname)
      nets = [_net_key(n) for n in (doc.get("networks") or [])]
      rules = doc.get("rules") or {}
      parts = [f"Bound VPCs: {join_limited(nets, 30)}"]
      summary = _rpz_rule_summary(rules)
      if summary:
        parts.append(join_limited(summary, 36))
      b.card(rcid, f"RPZ: {rname} ({_plural(len(rules), 'rule')})",
             " · ".join(parts), icon="CloudDNS", stroke_color="$TealStroke",
             stroke_width=1.8)
      if rpz_bind_lines:
        for n in nets:
          edge("dns_rpz_bind", rcid, vpc_cid(n), "-.->", "Bind (RPZ)", "right",
               "left")

  def project_zone(pkey, layout, gap):
    zlist = zones_by_proj.get(pkey, [])
    rlist = rpz_by_proj.get(pkey, [])
    vlist = proj_vpcs.get(pkey, [])
    parts = [_project_kind(ir, pkey)]
    if zlist:
      parts.append(_plural(len(zlist), "zone"))
    if rlist:
      parts.append(_plural(len(rlist), "response policy", "response policies"))
    if vlist:
      parts.append(_plural(len(vlist), "VPC"))
    b.open(cid("DnsProj",
               pkey), "@ProjectZone", f"Project: {pkey}", " · ".join(parts),
           icon="CloudGeneric", layout=layout, gap=gap, align="center")

  for pkey in core_projects:
    p_vpcs = proj_vpcs.get(pkey, [])
    p_zones = zones_by_proj.get(pkey, [])
    project_zone(pkey, "row", 36)

    left_zones = []
    mid_zones = []
    for zname, doc in p_zones:
      if "forwarding" in doc:
        left_zones.append((zname, doc))
      elif "private" in doc:
        clients = [
            _net_key(c)
            for c in ((doc["private"] or {}).get("client_networks") or [])
        ]
        if dns_hub_vpc and clients == [dns_hub_vpc]:
          left_zones.append((zname, doc))
        else:
          mid_zones.append((zname, doc))
      else:
        mid_zones.append((zname, doc))

    hub_vpcs = [v for v in p_vpcs if v == dns_hub_vpc]
    other_core_vpcs = [v for v in p_vpcs if v != dns_hub_vpc]

    if left_zones or rpz_by_proj.get(pkey):
      b.open(cid("CoreUpstreamDns", pkey), "@SubGroupWhite",
             "Hub DNS Zones & RPZ", layout="column", gap=12, align="center")
      for zname, doc in left_zones:
        zone_card(pkey, zname, doc)
      rpz_cards(pkey)
      b.close()

    if hub_vpcs:
      b.open(cid("CoreHubVpcCol", pkey), "@Ghost", layout="column", gap=14,
             align="center")
      for v in hub_vpcs:
        dns_vpc(v)
      b.close()

    if mid_zones:
      b.open(cid("CorePeeringDns", pkey), "@SubGroupWhite",
             "Cross-VPC DNS Zones", layout="column", gap=12, align="center")
      for zname, doc in mid_zones:
        zone_card(pkey, zname, doc)
      b.close()

    if other_core_vpcs:
      b.open(cid("CoreClientVpcsCol", pkey), "@Ghost", layout="column", gap=14,
             align="center")
      for v in other_core_vpcs:
        dns_vpc(v)
      b.close()

    if not (p_vpcs or p_zones or rpz_by_proj.get(pkey)):
      b.card(cid("proj_empty", pkey), "No DNS resources",
             "no zones, policies or VPCs", icon="CloudGeneric")
    b.close()

  if spoke_projects:
    b.open("SpokeDnsProjectsCol", "@Ghost", layout="column", gap=18,
           align="center")
    for pkey in spoke_projects:
      project_zone(pkey, "row", 28)
      has_any = False
      if zones_by_proj.get(pkey) or rpz_by_proj.get(pkey):
        has_any = True
        b.open(cid("SpokeDnsZones", pkey), "@Ghost", layout="column", gap=10,
               align="center")
        for zname, doc in zones_by_proj.get(pkey, []):
          zone_card(pkey, zname, doc)
        rpz_cards(pkey)
        b.close()
      for v in proj_vpcs.get(pkey, []):
        has_any = True
        dns_vpc(v)
      if not has_any:
        b.card(cid("proj_empty", pkey), "No DNS resources",
               "no zones, policies or VPCs", icon="CloudGeneric")
      b.close()
    b.close()

  b.close()  # GoogleCloudRoot

  dock_project = (core_projects + spoke_projects)[:1]
  if has_forwarding and dock_project:
    b.open("ExternalDns", "@Ghost", layout="column", gap=16, align="center",
           dock_to=cid("DnsProj", dock_project[0]), dock_side="left",
           dock_align="start", dock_gap=56)
    b.open("OnPremDnsZone", "@ExternalZone", "On-Premises",
           "External DNS Target", icon="Server")
    b.card("onprem_dns", "Target DNS IPs", (join_limited(
        forwarder_ips, 30) if forwarder_ips else "no forwarders defined"),
           width=196, icon="Server")
    b.close()
    b.close()

  return b.finish(legend)
