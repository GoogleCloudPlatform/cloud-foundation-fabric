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

Builds `ZoneNode` / `CardNode` / `EdgeSpec` objects directly. The output is
parity-locked against `tests/golden/2-networking/`: for every dataset the
scene must equal, field for field and in the same order, the scene the
legacy text generator + DSL parser produced. Rules that keep it that way:

- zones and cards are registered in document order, and a repeated id
  replaces the earlier entry in `scene.zones` / `scene.cards` while keeping
  its slot (dict assignment, exactly like the legacy parser);
- edges are collected while zones are built and appended in that order;
- zone `gap` is the explicit value when the generator gave one, else the
  preset gap; zone `icon` is explicit except `@ArchitectureRoot`;
- endpoint ids are formatted with `str()` so a missing anchor card yields the
  literal id `None` (kept in `scene.edges`, never routed).
"""

import pathlib

from .. import tokens
from ..datasets.networking import load_dataset
from ..scene.model import SceneGraph, make_card, make_edge, make_zone

__all__ = ["VIEWS", "build", "build_dns", "build_topology"]

VIEWS = ("topology", "dns")

_SHORT_REGIONS = {
    "europe-west1": "ew1",
    "europe-west8": "ew8",
    "europe-west4": "ew4",
    "us-central1": "usc1",
    "us-east1": "use1",
}


def build(dataset, view, dataset_name=None, rpz_bind_lines=False):
  """Returns the SceneGraph for `view` of a dataset directory or loaded IR."""
  if isinstance(dataset, (str, pathlib.Path)):
    dataset_name = dataset_name or pathlib.Path(dataset).name
    ir = load_dataset(dataset)
  else:
    ir = dataset
  if not dataset_name:
    raise ValueError("dataset_name is required when passing a loaded IR")
  if view == "topology":
    return build_topology(ir, dataset_name)
  if view == "dns":
    return build_dns(ir, dataset_name, rpz_bind_lines=rpz_bind_lines)
  raise ValueError(f"unknown 2-networking view: {view!r} (expected {VIEWS})")


# --- helpers ----------------------------------------------------------------


def _cid(prefix, *parts):
  raw = "_".join([prefix] + [str(p) for p in parts if p is not None])
  return "".join(ch if ch.isalnum() else "_" for ch in raw)


def _short_region(ir, reg_tok):
  reg = ir.resolve_region(reg_tok) if reg_tok else ""
  return _SHORT_REGIONS.get(reg, reg or "regional")


def _router_name_from_ref(ref):
  if not ref:
    return None
  key = tokens.key_of(ref, "routers")
  if key and "/" in key:
    return key.split("/", 1)[1]
  return key or ref


def _vpc_role_rank(ir, vpc_key):
  """Orders VPCs left-to-right: hybrid/egress (0) -> transit/hub (1) -> spoke (2)."""
  has_ext_vpn = any(
      l.type in ("vpn", "vlan") and l.a.get("vpc") == vpc_key and "site" in l.b
      for l in ir.links)
  has_masq_nic = any(
      nic.vpc == vpc_key and nic.masquerade
      for nva in ir.nvas.values()
      for nic in nva.nics)
  if has_ext_vpn or has_masq_nic or vpc_key in ("routing", "dmz"):
    return (0, vpc_key)
  if vpc_key in ("transit", "hub"):
    return (1, vpc_key)
  return (2, vpc_key)


def _net_key(value):
  return tokens.key_of(value, "networks") or value


class _Builder:
  """Zone stack + registries with legacy-parser insertion semantics."""

  def __init__(self, dataset_name, view_kind):
    self.scene = SceneGraph(
        dataset_name=dataset_name, view_kind=view_kind, stage="2-networking")
    self._stack = []
    self._edges = []

  def open(self, zid, style, title="", subtitle="", **kw):
    zone = make_zone(zid, style, title, subtitle, **kw)
    parent = self._stack[-1] if self._stack else None
    zone.parent_zone_id = parent.id if parent else None
    self.scene.zones[zid] = zone
    if parent is not None:
      parent.children.append(zone)
    else:
      self.scene.root_zones.append(zone)
    self._stack.append(zone)
    return zone

  def close(self):
    self._stack.pop()

  def card(self, cid, title, subtitle, style="@ProductCard", **kw):
    card = make_card(cid, title, subtitle, style, **kw)
    parent = self._stack[-1] if self._stack else None
    card.parent_zone_id = parent.id if parent else None
    self.scene.cards[cid] = card
    if parent is not None:
      parent.children.append(card)
    return cid

  def edge(self, src, dst, arrow, label, color, dashed, sa, ta, width):
    self._edges.append(
        make_edge(str(src), str(dst), arrow, label, color, stroke_width=width,
                  dashed=dashed, source_anchor=sa, target_anchor=ta))

  def finish(self):
    assert not self._stack, "unbalanced zones"
    self.scene.edges.extend(self._edges)
    return self.scene


# --- topology view ----------------------------------------------------------


def build_topology(ir, dataset_name):
  b = _Builder(dataset_name, "topology")

  def edge(src, dst, arrow, label, color, dashed, sa, ta):
    b.edge(src, dst, arrow, label, color, dashed, sa, ta, 2.0)

  proj_vpcs = {p: [] for p in ir.projects}
  for vkey, vpc in ir.vpcs.items():
    proj_vpcs.setdefault(vpc.project or "default", []).append(vkey)
  for p in proj_vpcs:
    proj_vpcs[p].sort(key=lambda k: _vpc_role_rank(ir, k))

  proj_hubs = {p: [] for p in proj_vpcs}
  for hkey, hub in ir.ncc_hubs.items():
    proj_hubs.setdefault(hub.project or "default", []).append(hkey)

  proj_nvas = {p: [] for p in proj_vpcs}
  for nkey, nva in ir.nvas.items():
    proj_nvas.setdefault(nva.project or "default", []).append(nkey)

  active_projects = [
      p for p in proj_vpcs
      if proj_vpcs.get(p) or proj_hubs.get(p) or proj_nvas.get(p)
  ]
  core_projects = [
      p for p in active_projects
      if proj_hubs.get(p) or proj_nvas.get(p) or any(
          _vpc_role_rank(ir, v)[0] < 2 for v in proj_vpcs.get(p, []))
  ]
  spoke_projects = [p for p in active_projects if p not in core_projects]

  vpc_peerings = {v: [] for v in ir.vpcs}
  vpc_ncc_spokes = {v: [] for v in ir.vpcs}
  for l in ir.links:
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

  def router_card(vpc_key, rname, rcfg):
    rcid = _cid("rtr", vpc_key, rname)
    asn = rcfg.get("asn", "")
    reg = _short_region(ir, rcfg.get("region"))
    b.card(rcid, f"Router: {rname}", f"ASN {asn} ({reg})", icon="CloudRouter")
    return rcid

  def vpc_zone(vpc_key):
    vpc = ir.vpcs[vpc_key]
    mode_str = f"{vpc.routing_mode or 'GLOBAL'} routing"
    b.open(_cid("Vpc", vpc_key), "@VpcZone", f"VPC: {vpc_key}", mode_str,
           icon="VirtualPrivateCloud", layout="column", gap=12, align="center")

    emitted_routers = set()
    any_card = False

    router_to_vpns = {}
    for gw in vpc.vpns:
      rtr_name = _router_name_from_ref((gw.router_config or {}).get("name"))
      router_to_vpns.setdefault(rtr_name, []).append(gw)

    vlan_rtr_name = None
    if vpc.vlan_attachments:
      vlan_rtr_name = _router_name_from_ref(
          (vpc.vlan_attachments[0].router_config or {}).get("name"))

    for rtr_name, gws in router_to_vpns.items():
      for gw in gws:
        cid = _cid("vpn", vpc_key, gw.name)
        any_card = True
        sub = (f"Router: {rtr_name}"
               if rtr_name else f"{len(gw.tunnels)} tunnel(s)")
        b.card(cid, f"HA VPN: {gw.name}", sub, icon="CloudVPN")
        if rtr_name and rtr_name in vpc.routers:
          rcid = _cid("rtr", vpc_key, rtr_name)
          edge(cid, rcid, "<-->", "BGP", "$GcpBlue", False, "bottom", "top")
      if vpc.vlan_attachments and vlan_rtr_name == rtr_name:
        vcid = _cid("vlan", vpc_key)
        any_card = True
        names = ", ".join(a.name for a in vpc.vlan_attachments)
        b.card(vcid, "VLAN Attachments", names, icon="CloudInterconnect")
        if rtr_name and rtr_name in vpc.routers:
          rcid = _cid("rtr", vpc_key, rtr_name)
          edge(vcid, rcid, "<-->", "BGP", "$GcpBlue", True, "bottom", "top")
        vlan_rtr_name = None
      if rtr_name and rtr_name in vpc.routers and rtr_name not in emitted_routers:
        router_card(vpc_key, rtr_name, vpc.routers[rtr_name])
        emitted_routers.add(rtr_name)

    if vpc.vlan_attachments and vlan_rtr_name is not None:
      vcid = _cid("vlan", vpc_key)
      any_card = True
      names = ", ".join(a.name for a in vpc.vlan_attachments)
      b.card(vcid, "VLAN Attachments", names, icon="CloudInterconnect")
      if vlan_rtr_name in vpc.routers and vlan_rtr_name not in emitted_routers:
        rcid = router_card(vpc_key, vlan_rtr_name, vpc.routers[vlan_rtr_name])
        emitted_routers.add(vlan_rtr_name)
        edge(vcid, rcid, "<-->", "BGP", "$GcpBlue", True, "bottom", "top")

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
      nic_idx = ra_nics[0][1]
      ncid = _cid("nic_ra", vpc_key)
      any_card = True
      flags = []
      if any(n.routes for _, _, n in ra_nics):
        flags.append(f"routes: {','.join(ra_nics[0][2].routes)}")
      if any(n.extra.get("advertise") for _, _, n in ra_nics):
        flags.append("BGP advertise")
      sub = " · ".join(flags) if flags else "Router Appliance NICs"
      b.card(ncid, f"NVA nic{nic_idx} Interfaces", sub, icon="Networking")
      for rname, rcfg in vpc.routers.items():
        if rcfg.get("peers") or rcfg.get("interfaces"):
          rcid = _cid("rtr", vpc_key, rname)
          is_sec = "secondary" in rname
          edge(rcid, ncid, "<-->", "eBGP",
               "$AmberStroke" if is_sec else "$GcpBlue", is_sec, "bottom",
               "top")
      for i, (nkey, idx, _) in enumerate(ra_nics):
        nva_cid = _cid("nva", nkey)
        is_sec = i > 0 or "secondary" in nkey
        edge(ncid, nva_cid, "<-->", f"nic{idx}",
             "$AmberStroke" if is_sec else "$GcpGreen", is_sec, "right", "left")

    for nkey, idx, nic in ilb_nics:
      ilb_cid = _cid("ilb", vpc_key, nkey)
      any_card = True
      flags = [f"NVA nic{idx}"]
      if nic.routes:
        flags.append(f"routes: {','.join(nic.routes)}")
      b.card(ilb_cid, f"ILB & NVA nic{idx} ({nkey})", " · ".join(flags),
             icon="CloudLoadBalancing")
      edge(ilb_cid, _cid("nva", nkey), "<-->", f"nic{idx} ILB", "$GcpGreen",
           False, "right", "left")

    if vpc_peerings.get(vpc_key):
      pcid = _cid("peering_attachment", vpc_key)
      any_card = True
      peers_csv = ", ".join(sorted(vpc_peerings[vpc_key]))
      b.card(pcid, "VPC Peering", f"Peers: {peers_csv}",
             icon="VirtualPrivateCloud")
      vpc_peering_anchor[vpc_key] = pcid

    if vpc_ncc_spokes.get(vpc_key):
      scid = _cid("ncc_spoke_attachment", vpc_key)
      any_card = True
      hkey, grp = vpc_ncc_spokes[vpc_key][0]
      grp_str = f"group: {grp}" if grp else "default group"
      b.card(scid, f"NCC VPC Spoke: {vpc_key}", f"Hub: {hkey} ({grp_str})",
             icon="NetworkConnectivityCenter")
      vpc_spoke_anchor[vpc_key] = scid

    ilb_routes = [(rk, rv)
                  for rk, rv in vpc.routes.items()
                  if (rv or {}).get("next_hop_type") == "ilb"]
    if ilb_routes and not vpc.routers:
      rk, rv = ilb_routes[0]
      any_card = True
      b.card(_cid("route", vpc_key, rk), f"Route: {rk} ({rv.get('dest_range')})",
             f"next-hop: ILB ({vpc_key})", icon="Routes")

    if vpc.nat:
      any_card = True
      nat_summary = ", ".join(
          f"{k} ({_short_region(ir, (v or {}).get('region'))})"
          for k, v in vpc.nat.items())
      b.card(_cid("nat", vpc_key), "Cloud NAT", nat_summary, icon="CloudNAT")

    if not any_card:
      b.card(_cid("vpc_attachment", vpc_key), "VPC Routing Table",
             f"{vpc_key} ({mode_str})", icon="VirtualPrivateCloud")

    b.close()

  def hub_title(hkey):
    hub = ir.ncc_hubs[hkey]
    topo = hub.preset_topology or "MESH"
    grps = ", ".join(hub.groups.keys()) if hub.groups else "default"
    return f"NCC Hub: {hkey}", f"{topo} (groups: {grps})"

  for pkey in core_projects:
    p_vpcs = proj_vpcs.get(pkey, [])
    p_hubs = proj_hubs.get(pkey, [])
    p_nvas = proj_nvas.get(pkey, [])
    b.open(_cid("Proj", pkey), "@ProjectZone", f"Project: {pkey}",
           "Shared VPC Host (Core Networking)", icon="CloudGeneric",
           layout="row", gap=36, align="center")

    if len(p_vpcs) > 1 and (p_nvas or len(p_hubs) > 1):
      left_vpcs = [v for v in p_vpcs if _vpc_role_rank(ir, v)[0] == 0]
      right_vpcs = [v for v in p_vpcs if v not in left_vpcs]
    else:
      left_vpcs = p_vpcs
      right_vpcs = []

    if left_vpcs:
      b.open("CoreLeftVpcs", "@Ghost", layout="column", gap=16, align="center")
      for v in left_vpcs:
        vpc_zone(v)
      b.close()

    mid_hubs = p_hubs[:1] if len(p_hubs) > 1 else (
        p_hubs if not right_vpcs else [])
    right_hubs = p_hubs[1:] if len(p_hubs) > 1 else (
        p_hubs if right_vpcs else [])

    if mid_hubs or p_nvas:
      b.open("CoreProjectMid", "@Ghost", layout="column", gap=18,
             align="center")
      for hkey in mid_hubs:
        title, sub = hub_title(hkey)
        b.card(_cid("ncc_hub", hkey), title, sub, "@HubCard",
               icon="NetworkConnectivityCenter")
      if p_nvas:
        b.open("NvaCluster", "@SubGroupWhite", "NVA VM Instances",
               layout="column", gap=12, align="center")
        for idx, nkey in enumerate(p_nvas):
          nva = ir.nvas[nkey]
          reg = _short_region(ir, nva.region)
          bgp = nva.extra.get("bgp_config") or {}
          asn_str = (f" · BGP ASN {bgp.get('asn')}"
                     if bgp.get("asn") else " · Static/ILB")
          ig = (nva.extra.get("instance_groups") or
                nva.ilb_config.get("instance_groups") or {})
          zones = "/".join(sorted(ig.keys())) if ig else "b/c"
          b.card(_cid("nva", nkey), f"nva-{nkey} ({reg} {zones})",
                 f"{len(nva.nics)} NICs{asn_str}", icon="ComputeEngine",
                 stroke_color="$AmberStroke" if idx > 0 else "$GcpGreen",
                 stroke_width=1.8)
        b.close()
      b.close()

    if right_vpcs:
      b.open("CoreRightVpcs", "@Ghost", layout="column", gap=16,
             align="center")
      for v in right_vpcs:
        vpc_zone(v)
      b.close()

    for hkey in right_hubs:
      title, sub = hub_title(hkey)
      b.card(_cid("ncc_hub", hkey), title, sub, "@HubCard",
             icon="NetworkConnectivityCenter", stroke_color="$PurpleStroke")

    b.close()

  if spoke_projects:
    b.open("SpokeProjectsCol", "@Ghost", layout="column", gap=18,
           align="center")
    for pkey in spoke_projects:
      b.open(_cid("Proj", pkey), "@ProjectZone", f"Project: {pkey}",
             "Shared VPC Host (Spoke)", icon="CloudGeneric", layout="column",
             gap=12, align="center")
      for v in proj_vpcs.get(pkey, []):
        vpc_zone(v)
      b.close()
    b.close()

  b.close()  # GoogleCloudRoot

  if ir.sites and core_projects:
    b.open("ExternalHybrid", "@Ghost", layout="column", gap=16,
           align="center", dock_to=_cid("Proj", core_projects[0]),
           dock_side="left", dock_align="start", dock_gap=56)
    for skey, site in ir.sites.items():
      asn_sub = f"ASN {site.asn}" if site.asn else "External Network"
      b.open(_cid("SiteZone", skey), "@ExternalZone",
             f"On-Premises ({skey})", asn_sub, icon="Server")
      b.card(_cid("site", skey), "On-Premises Router", asn_sub, width=190,
             icon="Server")
      b.close()
    b.close()

  vlan_linked_sites = set()
  vlan_linked_hubs = set()
  ra_linked_hubs = set()

  for link in ir.links:
    if link.type == "vpn":
      a_cid = _cid("vpn", link.a["vpc"], link.a["name"])
      if "site" in link.b:
        edge(_cid("site", link.b["site"]), a_cid, "<-->", "HA VPN",
             "$CoralRed", False, "right", "left")
      else:
        edge(a_cid, _cid("vpn", link.b["vpc"], link.b["name"]), "<-->",
             "HA VPN", "$PurpleStroke", False, "right", "left")
    elif link.type == "vlan":
      vpc_key = link.a["vpc"]
      skey = link.b["site"]
      if (vpc_key, skey) not in vlan_linked_sites:
        vlan_linked_sites.add((vpc_key, skey))
        edge(_cid("site", skey), _cid("vlan", vpc_key), "<-->", "Interconnect",
             "$CoralRed", True, "right", "left")
    elif link.type == "peering":
      a_cid = vpc_peering_anchor.get(link.a["vpc"])
      b_cid = vpc_peering_anchor.get(link.b["vpc"])
      if a_cid and b_cid:
        edge(a_cid, b_cid, "<-->", "VPC Peering", "$GcpGreen", False, "right",
             "left")
    elif link.type == "ncc_spoke":
      hkey = link.a["hub"]
      grp = link.a.get("group")
      hcid = _cid("ncc_hub", hkey)
      target = link.b
      if "vpc" in target and "nva" not in target:
        vcid = vpc_spoke_anchor.get(target["vpc"])
        lbl = f"VPC Spoke ({grp})" if grp else "VPC Spoke"
        edge(hcid, vcid, "<-->", lbl, "$GcpGreen", False, "right", "left")
      elif "vpn" in target:
        vpc_key, gw_name = target["vpn"]
        edge(_cid("vpn", vpc_key, gw_name), hcid, "-->", "Hybrid Spoke",
             "$GcpBlue", False, "right", "left")
      elif "vlan" in target:
        vpc_key, _ = target["vlan"]
        if (vpc_key, hkey) not in vlan_linked_hubs:
          vlan_linked_hubs.add((vpc_key, hkey))
          edge(_cid("vlan", vpc_key), hcid, "-->", "Hybrid Spoke", "$GcpBlue",
               True, "right", "left")
      elif "nva" in target:
        vpc_key = target["vpc"]
        if (vpc_key, hkey) not in ra_linked_hubs:
          ra_linked_hubs.add((vpc_key, hkey))
          lbl = f"RA Spoke ({grp})" if grp else "RA Spokes"
          edge(_cid("nic_ra", vpc_key), hcid, "-->", lbl, "$PurpleStroke",
               True, "right", "left")

  return b.finish()


# --- dns view ---------------------------------------------------------------


def build_dns(ir, dataset_name, rpz_bind_lines=False):
  b = _Builder(dataset_name, "dns")

  def edge(src, dst, arrow, label, color, dashed, sa, ta):
    b.edge(src, dst, arrow, label, color, dashed, sa, ta,
           1.6 if dashed else 2.2)

  zones_by_proj = {}
  rpz_by_proj = {}
  has_forwarding = False
  forwarder_ips = []
  dns_hub_vpc = None

  for rel, doc in sorted(ir.opaque.items()):
    if not isinstance(doc, dict):
      continue
    if rel.startswith("dns/zones/"):
      zname = pathlib.Path(rel).stem
      proj = tokens.key_of(doc.get("project_id"), "project_ids") or "net-core-0"
      zones_by_proj.setdefault(proj, []).append((zname, doc))
      if "forwarding" in doc:
        has_forwarding = True
        for ip in (doc["forwarding"].get("forwarders") or {}).keys():
          if ip not in forwarder_ips:
            forwarder_ips.append(ip)
      elif "peering" in doc and not dns_hub_vpc:
        dns_hub_vpc = tokens.key_of(doc["peering"].get("peer_network"),
                                    "networks")
    elif rel.startswith("dns/response-policies/"):
      rname = pathlib.Path(rel).stem
      proj = tokens.key_of(doc.get("project_id"), "project_ids") or "net-core-0"
      rpz_by_proj.setdefault(proj, []).append((rname, doc))

  proj_vpcs = {p: [] for p in ir.projects}
  for vkey, vpc in ir.vpcs.items():
    proj_vpcs.setdefault(vpc.project or "default", []).append(vkey)
  for p in proj_vpcs:
    proj_vpcs[p].sort(key=lambda k: _vpc_role_rank(ir, k))

  if not dns_hub_vpc:
    for p in proj_vpcs.values():
      if p:
        dns_hub_vpc = p[0]
        break

  active_projects = [
      p for p in proj_vpcs
      if proj_vpcs.get(p) or zones_by_proj.get(p) or rpz_by_proj.get(p)
  ]
  core_projects = [
      p for p in active_projects if p == "net-core-0" or rpz_by_proj.get(p)
  ]
  spoke_projects = [p for p in active_projects if p not in core_projects]

  b.open("GoogleCloudRoot", "@ArchitectureRoot", "Google Cloud",
         f"FAST 2-networking — {dataset_name} (Cloud DNS Overlay: Dashed = "
         "Bind · Solid = Peer / Forward)", layout="row", gap=36, align="center")

  def dns_vpc(vkey):
    role = "Central Resolver Hub" if vkey == dns_hub_vpc else "Client VPC"
    b.open(_cid("DnsVpcZone", vkey), "@VpcZone", f"VPC: {vkey}",
           icon="VirtualPrivateCloud", layout="column", gap=10, align="center")
    b.card(_cid("dns_vpc", vkey), f"VPC: {vkey}", role,
           icon="VirtualPrivateCloud")
    b.close()

  def bind_edges(zcid, clients):
    for c in clients:
      edge(zcid, _cid("dns_vpc", c), "-.->", "Bind", "$GcpBlue", True, "right",
           "left")

  def zone_card(pkey, zname, doc):
    zcid = _cid("zone", pkey, zname)
    dom = doc.get("domain", "")
    if "forwarding" in doc:
      fwds = ", ".join((doc["forwarding"].get("forwarders") or {}).keys())
      clients = [
          _net_key(c) for c in (doc["forwarding"].get("client_networks") or [])
      ]
      b.card(zcid, f"FWD Zone: {dom}", f"Target IPs: {fwds}", icon="CloudDNS",
             stroke_color="$CoralRed", stroke_width=1.8)
      if has_forwarding:
        edge(zcid, "onprem_dns", "-->", f"Forward({fwds})", "$CoralRed", False,
             "left", "right")
      bind_edges(zcid, clients)
    elif "peering" in doc:
      peer_vpc = tokens.key_of(doc["peering"].get("peer_network"), "networks")
      clients = [
          _net_key(c) for c in (doc["peering"].get("client_networks") or [])
      ]
      clients_csv = ", ".join(clients)
      b.card(zcid, f"Peering Zone: '{dom}'",
             f"Target: {peer_vpc} · Bound: {clients_csv}", icon="CloudDNS",
             stroke_color="$PurpleStroke", stroke_width=1.8)
      if peer_vpc:
        edge(zcid, _cid("dns_vpc", peer_vpc), "-->", f"Peer ({peer_vpc})",
             "$PurpleStroke", False, "left", "right")
      bind_edges(zcid, clients)
    elif "private" in doc:
      clients = [
          _net_key(c) for c in (doc["private"].get("client_networks") or [])
      ]
      clients_csv = ", ".join(clients)
      b.card(zcid, f"PVT Zone: {dom}", f"Bound VPCs: {clients_csv}",
             icon="CloudDNS", stroke_color="$GcpGreen", stroke_width=1.8)
      bind_edges(zcid, clients)

  def rpz_cards(pkey):
    for rname, doc in rpz_by_proj.get(pkey, []):
      rcid = _cid("rpz", pkey, rname)
      nets = [_net_key(n) for n in (doc.get("networks") or [])]
      n_rules = len(doc.get("rules") or {})
      b.card(rcid, f"RPZ: {rname} ({n_rules} PGA rules)",
             f"Bound VPCs: {', '.join(nets)}", icon="CloudDNS",
             stroke_color="$TealStroke", stroke_width=1.8)
      if rpz_bind_lines:
        for n in nets:
          edge(rcid, _cid("dns_vpc", n), "-.->", "Bind (RPZ)", "$TealStroke",
               True, "right", "left")

  for pkey in core_projects:
    p_vpcs = proj_vpcs.get(pkey, [])
    p_zones = zones_by_proj.get(pkey, [])
    b.open(_cid("DnsProj", pkey), "@ProjectZone", f"Project: {pkey}",
           "Centralized Cloud DNS & Core VPCs", icon="CloudGeneric",
           layout="row", gap=36, align="center")

    left_zones = []
    mid_zones = []
    for zname, doc in p_zones:
      if "forwarding" in doc:
        left_zones.append((zname, doc))
      elif "private" in doc:
        clients = [
            _net_key(c) for c in (doc["private"].get("client_networks") or [])
        ]
        if clients == [dns_hub_vpc]:
          left_zones.append((zname, doc))
        else:
          mid_zones.append((zname, doc))
      else:
        mid_zones.append((zname, doc))

    hub_vpcs = [v for v in p_vpcs if v == dns_hub_vpc]
    other_core_vpcs = [v for v in p_vpcs if v != dns_hub_vpc]

    if left_zones or rpz_by_proj.get(pkey):
      b.open("CoreUpstreamDns", "@SubGroupWhite", "Hub DNS Zones & RPZ",
             layout="column", gap=12, align="center")
      for zname, doc in left_zones:
        zone_card(pkey, zname, doc)
      rpz_cards(pkey)
      b.close()

    if hub_vpcs:
      b.open("CoreHubVpcCol", "@Ghost", layout="column", gap=14,
             align="center")
      for v in hub_vpcs:
        dns_vpc(v)
      b.close()

    if mid_zones:
      b.open("CorePeeringDns", "@SubGroupWhite", "Cross-VPC DNS Zones",
             layout="column", gap=12, align="center")
      for zname, doc in mid_zones:
        zone_card(pkey, zname, doc)
      b.close()

    if other_core_vpcs:
      b.open("CoreClientVpcsCol", "@Ghost", layout="column", gap=14,
             align="center")
      for v in other_core_vpcs:
        dns_vpc(v)
      b.close()

    b.close()

  if spoke_projects:
    b.open("SpokeDnsProjectsCol", "@Ghost", layout="column", gap=18,
           align="center")
    for pkey in spoke_projects:
      b.open(_cid("DnsProj", pkey), "@ProjectZone", f"Project: {pkey}",
             "Spoke VPC & Subdomain Zone", icon="CloudGeneric", layout="row",
             gap=28, align="center")
      if zones_by_proj.get(pkey) or rpz_by_proj.get(pkey):
        b.open(_cid("SpokeDnsZones", pkey), "@Ghost", layout="column", gap=10,
               align="center")
        for zname, doc in zones_by_proj.get(pkey, []):
          zone_card(pkey, zname, doc)
        rpz_cards(pkey)
        b.close()
      for v in proj_vpcs.get(pkey, []):
        dns_vpc(v)
      b.close()
    b.close()

  b.close()  # GoogleCloudRoot

  if has_forwarding and core_projects:
    fwds_str = ", ".join(forwarder_ips) if forwarder_ips else "8.8.8.8, 1.1.1.1"
    b.open("ExternalDns", "@Ghost", layout="column", gap=16, align="center",
           dock_to=_cid("DnsProj", core_projects[0]), dock_side="left",
           dock_align="start", dock_gap=56)
    b.open("OnPremDnsZone", "@ExternalZone", "On-Premises",
           "External DNS Target", icon="Server")
    b.card("onprem_dns", "Target DNS IPs", fwds_str, width=196, icon="Server")
    b.close()
    b.close()

  return b.finish()
