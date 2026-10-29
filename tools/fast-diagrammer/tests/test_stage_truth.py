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
"""Truth gates: every diagram element and edge traces back to the YAML.

For every real dataset of the three stages, the expected picture is derived
from the dataset files with plain `yaml.safe_load` (independently of the
tool's loaders) and compared with the builder's SceneGraph:

- presence: every project, folder, VPC, NCC hub, NVA, DNS zone and VPC-SC
  perimeter appears exactly once as its card or zone, and no project/VPC/
  perimeter container exists that the dataset does not define;
- factories set to a missing path (`"none"`) leave no card and no edge;
- edges: the set of edges equals the set of relationships in the YAML (log
  sinks, billing export, Shared VPC, resource hierarchy, VPC peering, HA VPN,
  BGP, NCC spokes, NVA NICs, DNS bindings/peering/forwarding, VPC-SC access
  levels, ingress and egress policies);
- perimeter mode badges (ENFORCED / DRY-RUN / spec not applied) match the
  perimeter's `status`, `spec` and `use_explicit_dry_run_spec`.

Negative controls feed each gate a scene that violates exactly one property
(a dropped project, an invented edge, a VLAN card under a disabled factory, a
wrong mode badge, ...) and require the gate to report it.
"""

import collections
import copy
import re
import warnings

import pytest
import yaml

from conftest import stage_datasets_root  # pylint: disable=import-error
from fast_diagrammer.scene.model import Badge, make_card, make_edge
from fast_diagrammer.stages import networking, org_setup, vpcsc
from fast_diagrammer.stages._common import cid

# --- dataset discovery and raw YAML helpers -----------------------------------


def _real_datasets(stage):
  root = stage_datasets_root(stage)
  if root is None:
    return [
        pytest.param(
            None, marks=pytest.mark.skip(
                reason=f"no FAST {stage} datasets found; run inside "
                "a cloud-foundation-fabric checkout or set "
                "FD_FABRIC_ROOT"))
    ]
  return [
      p.name
      for p in sorted(root.iterdir())
      if p.is_dir() and not p.is_symlink() and not p.name.startswith(".")
  ]


def _dataset(stage, name):
  return stage_datasets_root(stage) / name


def _load(path):
  doc = yaml.safe_load(path.read_text(encoding="utf-8"))
  return doc if doc is not None else {}


def _yaml_files(directory):
  if not directory.is_dir():
    return []
  return sorted(p for p in directory.rglob("*.yaml") if p.is_file())


def _tok(value, namespace):
  """`$namespace:key` -> key, else None."""
  if isinstance(value, str):
    m = re.fullmatch(r"\$([a-z_]+):(.+)", value.strip())
    if m and m.group(1) == namespace:
      return m.group(2)
  return None


def _quiet(fn, *args, **kwargs):
  with warnings.catch_warnings():
    warnings.simplefilter("ignore")
    return fn(*args, **kwargs)


def _ancestors(scene, zone_id):
  out = []
  while zone_id:
    out.append(zone_id)
    zone = scene.zones.get(zone_id)
    zone_id = zone.parent_zone_id if zone else None
  return out


def _owner_zones(scene, element_id):
  """Zone ids enclosing a card or zone (itself included for zones)."""
  if element_id in scene.cards:
    return _ancestors(scene, scene.cards[element_id].parent_zone_id)
  return _ancestors(scene, element_id)


def _id_counts(scene):
  return collections.Counter(list(scene.cards) + list(scene.zones))


def _exactly_once(scene, ids, what, errors):
  counts = _id_counts(scene)
  for i in ids:
    if counts[i] != 1:
      errors.append(f"{what} {i}: drawn {counts[i]} times, expected once")


def _compare_edges(actual, expected, errors, what):
  """Multiset comparison of (src, dst, label-class) tuples."""
  a = collections.Counter(actual)
  e = collections.Counter(expected)
  for k in sorted(a - e):
    errors.append(f"{what}: edge {k} has no relationship in the YAML")
  for k in sorted(e - a):
    errors.append(f"{what}: relationship {k} from the YAML is not drawn")


# --- 2-networking -------------------------------------------------------------

_VPC_FACTORY_DIRS = {"vpns": "vpns", "vlan_attachments": "vlan-attachments"}

_NET_UNDIRECTED = {"vpn_vpc", "peering"}


def _net_label_class(label):
  if label == "BGP":
    return "bgp"
  if label == "HA VPN":
    return "vpn"
  if label == "Interconnect":
    return "interconnect"
  if label == "VPC Peering":
    return "peering"
  if label.startswith("VPC Spoke"):
    return "ncc_vpc"
  if label == "Hybrid Spoke":
    return "ncc_hybrid"
  if label.startswith("RA Spoke"):
    return "ncc_ra"
  if label == "eBGP":
    return "ebgp"
  if re.fullmatch(r"nic\d+ ILB", label):
    return "ilb"
  if re.fullmatch(r"nic\d+", label):
    return "nic"
  if label == "Bind":
    return "bind"
  if label == "Bind (RPZ)":
    return "rpz_bind"
  if label.startswith("Peer ("):
    return "dns_peer"
  if label.startswith("Forward"):
    return "dns_forward"
  return f"unknown:{label}"


class NetTruth:
  """What a 2-networking dataset defines, read straight from its YAML."""

  def __init__(self, root):
    self.root = root
    self.projects = sorted({
        p.stem
        for d in ("projects", "folders")
        for p in _yaml_files(root / d)
        if not p.name.endswith(".config.yaml")
    })
    self.vpcs = {}
    for cfg in _yaml_files(root / "vpcs"):
      if cfg.name == ".config.yaml":
        key = cfg.parent.relative_to(root / "vpcs").as_posix()
        self.vpcs[key] = _load(cfg)
    self.hubs = {
        p.relative_to(root / "ncc-hubs").with_suffix("").as_posix(): _load(p)
        for p in _yaml_files(root / "ncc-hubs")
    }
    self.nvas = {
        p.relative_to(root / "nvas").with_suffix("").as_posix(): _load(p)
        for p in _yaml_files(root / "nvas")
    }
    self.dns_zones = [
        (p.stem, _load(p)) for p in _yaml_files(root / "dns" / "zones")
    ]
    self.rpzs = [(p.stem, _load(p))
                 for p in _yaml_files(root / "dns" / "response-policies")]

  def vpc_project(self, vkey):
    pid = self.vpcs[vkey].get("project_id")
    return _tok(pid, "project_ids") or (str(pid) if pid else
                                        networking.UNSPECIFIED_PROJECT)

  def factory_files(self, vkey, factory):
    """Files of a per-VPC factory, empty when its path does not exist."""
    cfg = self.vpcs[vkey].get("factories_config") or {}
    rel = cfg.get(factory, _VPC_FACTORY_DIRS[factory])
    base = self.root / "vpcs" / vkey
    path = (self.root / str(rel).lstrip("/")) if str(rel).startswith(
        ("/", ".")) else base / str(rel)
    return [(p.stem, _load(p)) for p in _yaml_files(path)]

  def disabled(self, vkey, factory):
    return not self.factory_files(vkey, factory) and bool(
        (self.vpcs[vkey].get("factories_config") or {}).get(factory))

  def vpns(self, vkey):
    return [((doc.get("name") or stem), doc)
            for stem, doc in self.factory_files(vkey, "vpns")]

  def nva_nics(self, nkey):
    doc = self.nvas[nkey]
    nics = ((doc.get("auto_instance_config") or {}).get("nics") or
            doc.get("nics") or [])
    frs = {
        (fr.get("network"), fr.get("subnet"))
        for fr in ((doc.get("ilb_config") or {}).get("forwarding_rules") or [])
    }
    out = []
    for idx, nic in enumerate(nics):
      vkey = _tok(nic.get("network"), "networks")
      out.append((idx, vkey, (nic.get("network"), nic.get("subnet")) in frs))
    return out

  # -- expected topology edges --

  def topology_edges(self):
    edges = []
    vpn_card = {}
    for vkey in self.vpcs:
      for name, _ in self.vpns(vkey):
        vpn_card[(vkey, name)] = cid("vpn", vkey, name)
    hybrid_vlan = set()
    for vkey, vdoc in self.vpcs.items():
      routers = vdoc.get("routers") or {}
      for name, doc in self.vpns(vkey):
        gcid = vpn_card[(vkey, name)]
        rref = _tok((doc.get("router_config") or {}).get("name"), "routers")
        if rref and rref.split("/", 1)[-1] in routers:
          edges.append((gcid, cid("rtr", vkey, rref.split("/", 1)[-1]), "bgp"))
        for pg in (doc.get("peer_gateways") or {}).values():
          pg = pg or {}
          if "external" in pg:
            edges.append(("site:*", gcid, "vpn"))
          peer = _tok(pg.get("gcp"), "vpn_gateways")
          if peer and "/" in peer:
            pv, pn = peer.split("/", 1)
            if (pv, pn) in vpn_card:
              edges.append((gcid, vpn_card[(pv, pn)], "vpn_vpc"))
        hub = _tok((doc.get("ncc_spoke_config") or {}).get("hub"), "ncc_hubs")
        if hub in self.hubs:
          edges.append((gcid, cid("ncc_hub", hub), "ncc_hybrid"))
      vlans = self.factory_files(vkey, "vlan_attachments")
      if vlans:
        vcid = cid("vlan", vkey)
        rref = _tok((vlans[0][1].get("router_config") or {}).get("name"),
                    "routers")
        if rref and rref.split("/", 1)[-1] in routers:
          edges.append((vcid, cid("rtr", vkey, rref.split("/", 1)[-1]), "bgp"))
        edges.append(("site:*", vcid, "interconnect"))
        for _, doc in vlans:
          hub = _tok((doc.get("ncc_spoke_config") or {}).get("hub"), "ncc_hubs")
          if hub in self.hubs and (vkey, hub) not in hybrid_vlan:
            hybrid_vlan.add((vkey, hub))
            edges.append((vcid, cid("ncc_hub", hub), "ncc_hybrid"))
      for pcfg in (vdoc.get("peering_config") or {}).values():
        peer = _tok((pcfg or {}).get("peer_network"), "networks")
        if peer in self.vpcs:
          edges.append((cid("peering_attachment",
                            vkey), cid("peering_attachment", peer), "peering"))
      hub = _tok((vdoc.get("ncc_config") or {}).get("hub"), "ncc_hubs")
      if hub in self.hubs:
        edges.append((cid("ncc_hub", hub), cid("ncc_spoke_attachment",
                                               vkey), "ncc_vpc"))
    ra_vpcs = set()
    ra_spokes = set()
    for nkey, doc in self.nvas.items():
      for _, vkey, is_ilb in self.nva_nics(nkey):
        if vkey not in self.vpcs:
          continue
        if is_ilb:
          edges.append((cid("ilb", vkey, nkey), cid("nva", nkey), "ilb"))
        else:
          ra_vpcs.add(vkey)
          edges.append((cid("nic_ra", vkey), cid("nva", nkey), "nic"))
      for spoke in ((doc.get("ncc_ra_config") or {}).get("spokes") or []):
        vkey = _tok(spoke.get("network"), "networks")
        hub = _tok(spoke.get("hub"), "ncc_hubs")
        if vkey in self.vpcs and hub in self.hubs and (vkey,
                                                       hub) not in ra_spokes:
          ra_spokes.add((vkey, hub))
          edges.append((cid("nic_ra", vkey), cid("ncc_hub", hub), "ncc_ra"))
    for vkey in sorted(ra_vpcs):
      for rname, rcfg in (self.vpcs[vkey].get("routers") or {}).items():
        rcfg = rcfg or {}
        if rcfg.get("peers") or rcfg.get("interfaces"):
          edges.append((cid("rtr", vkey, rname), cid("nic_ra", vkey), "ebgp"))
    return edges

  # -- expected dns edges --

  def dns_edges(self, rpz_bind_lines=False):
    edges = []
    for stem, doc in self.dns_zones:
      proj = _tok(doc.get("project_id"), "project_ids") or str(
          doc.get("project_id") or networking.UNSPECIFIED_PROJECT)
      zcid = cid("zone", proj, stem)
      for kind in ("forwarding", "peering", "private"):
        if kind not in doc:
          continue
        body = doc[kind] or {}
        if kind == "forwarding":
          edges.append((zcid, "onprem_dns", "dns_forward"))
        if kind == "peering":
          peer = _tok(body.get("peer_network"), "networks")
          if peer in self.vpcs:
            edges.append((zcid, cid("dns_vpc", peer), "dns_peer"))
        for c in body.get("client_networks") or []:
          net = _tok(c, "networks") or c
          if net in self.vpcs:
            edges.append((zcid, cid("dns_vpc", net), "bind"))
        break
    if rpz_bind_lines:
      for stem, doc in self.rpzs:
        proj = _tok(doc.get("project_id"), "project_ids") or str(
            doc.get("project_id") or networking.UNSPECIFIED_PROJECT)
        for n in doc.get("networks") or []:
          net = _tok(n, "networks") or n
          if net in self.vpcs:
            edges.append((cid("rpz", proj, stem), cid("dns_vpc",
                                                      net), "rpz_bind"))
    return edges


def _scene_net_edges(scene):
  out = []
  for e in scene.edges:
    cls = _net_label_class(e.label)
    src, dst = e.src, e.dst
    if src.startswith("site_"):
      src = "site:*"
    if cls == "vpn" and not e.src.startswith("site_"):
      cls = "vpn_vpc"
    out.append((src, dst, cls))
  return out


def _normalise(edges, dedup_undirected=False):
  """Orders undirected pairs; both sides of a peering/VPN are one relation."""
  out = []
  for src, dst, cls in edges:
    if cls in _NET_UNDIRECTED:
      src, dst = sorted((src, dst))
      if dedup_undirected and (src, dst, cls) in out:
        continue
    out.append((src, dst, cls))
  return out


def check_networking_topology(truth, scene):
  errors = []
  referenced = {truth.vpc_project(v) for v in truth.vpcs}
  referenced |= {
      _tok(d.get("project_id"), "project_ids") or networking.UNSPECIFIED_PROJECT
      for d in list(truth.hubs.values()) + list(truth.nvas.values())
  }
  _exactly_once(scene, [cid("Proj", p) for p in truth.projects], "project",
                errors)
  allowed = {cid("Proj", p) for p in set(truth.projects) | referenced}
  for z in scene.zones.values():
    if z.style_name == "@ProjectZone" and z.id not in allowed:
      errors.append(f"project zone {z.id} is not defined by the dataset")
  _exactly_once(scene, [cid("Vpc", v) for v in truth.vpcs], "VPC", errors)
  vpc_ids = {cid("Vpc", v) for v in truth.vpcs}
  for z in scene.zones.values():
    if z.style_name == "@VpcZone" and z.id not in vpc_ids:
      errors.append(f"VPC zone {z.id} is not defined by the dataset")
  _exactly_once(scene, [cid("ncc_hub", h) for h in truth.hubs], "NCC hub",
                errors)
  _exactly_once(scene, [cid("nva", n) for n in truth.nvas], "NVA", errors)
  for vkey in truth.vpcs:
    vzone = cid("Vpc", vkey)
    in_vpc = [
        c for c in scene.cards.values()
        if vzone in _ancestors(scene, c.parent_zone_id)
    ]
    if truth.disabled(vkey, "vlan_attachments"):
      bad = sorted({c.id for c in in_vpc if c.icon == "CloudInterconnect"} |
                   ({cid("vlan", vkey)} & set(scene.cards)))
      if bad:
        errors.append(f"VPC {vkey}: vlan_attachments factory is disabled but "
                      f"{bad} are drawn")
    if truth.disabled(vkey, "vpns"):
      bad = [c.id for c in in_vpc if c.icon == "CloudVPN"]
      if bad:
        errors.append(f"VPC {vkey}: vpns factory is disabled but {bad} are "
                      "drawn")
  for e in scene.edges:
    if e.label == "Interconnect" and not any(
        truth.factory_files(v, "vlan_attachments") for v in truth.vpcs):
      errors.append(f"Interconnect edge {e.src}->{e.dst} without any enabled "
                    "VLAN attachment")
  _compare_edges(_normalise(_scene_net_edges(scene)),
                 _normalise(truth.topology_edges(), dedup_undirected=True),
                 errors, "topology")
  return errors


def check_networking_dns(truth, scene, rpz_bind_lines=False):
  errors = []
  _exactly_once(scene, [cid("DnsProj", p) for p in truth.projects], "project",
                errors)
  _exactly_once(scene, [cid("DnsVpcZone", v) for v in truth.vpcs], "VPC",
                errors)
  _exactly_once(scene, [cid("dns_vpc", v) for v in truth.vpcs], "VPC card",
                errors)
  zone_ids = []
  for stem, doc in truth.dns_zones:
    proj = _tok(doc.get("project_id"), "project_ids") or str(
        doc.get("project_id") or networking.UNSPECIFIED_PROJECT)
    zone_ids.append(cid("zone", proj, stem))
  _exactly_once(scene, zone_ids, "DNS zone", errors)
  vpc_ids = {cid("DnsVpcZone", v) for v in truth.vpcs}
  for z in scene.zones.values():
    if z.style_name == "@VpcZone" and z.id not in vpc_ids:
      errors.append(f"VPC zone {z.id} is not defined by the dataset")
  _compare_edges(_scene_net_edges(scene), truth.dns_edges(rpz_bind_lines),
                 errors, "dns")
  return errors


@pytest.mark.parametrize("name", _real_datasets("2-networking"))
def test_networking_topology_truth(name):
  root = _dataset("2-networking", name)
  truth = NetTruth(root)
  scene = _quiet(networking.build, root, "topology")
  assert check_networking_topology(truth, scene) == []


@pytest.mark.parametrize("name", _real_datasets("2-networking"))
@pytest.mark.parametrize("rpz_bind_lines", [False, True])
def test_networking_dns_truth(name, rpz_bind_lines):
  root = _dataset("2-networking", name)
  truth = NetTruth(root)
  scene = _quiet(networking.build, root, "dns", rpz_bind_lines=rpz_bind_lines)
  assert check_networking_dns(truth, scene, rpz_bind_lines) == []


# --- 0-org-setup --------------------------------------------------------------


class OrgTruth:
  """What a 0-org-setup dataset defines, read straight from its YAML."""

  def __init__(self, root):
    self.root = root
    folders = set()
    for cfg in _yaml_files(root / "folders"):
      if cfg.name == ".config.yaml":
        rel = cfg.parent.relative_to(root / "folders")
        while rel.parts:
          folders.add(rel.as_posix())
          rel = rel.parent
    self.folders = sorted(folders)
    self.projects = {}
    for d in ("projects", "folders"):
      for p in _yaml_files(root / d):
        if not p.name.endswith(".config.yaml"):
          self.projects[p.stem] = _load(p)
    self.vpcs = []
    for cfg in _yaml_files(root / "vpcs"):
      if cfg.name == ".config.yaml":
        doc = _load(cfg)
        proj = _tok(doc.get("project_id"), "project_ids")
        self.vpcs.append(
            (proj, cfg.parent.relative_to(root / "vpcs").as_posix()))
    org = _load(root / "organization" /
                ".config.yaml") if (root / "organization" /
                                    ".config.yaml").is_file() else {}
    sinks = ((org.get("logging") or {}).get("sinks") or {})
    self.sinks = []
    for sname, sdata in sinks.items():
      dest = str((sdata or {}).get("destination") or "")
      m = re.fullmatch(r"\$[a-z_]+:([^/]+)(/.*)?", dest)
      self.sinks.append((sname, m.group(1) if m else None))
    defaults = _load(root /
                     "defaults.yaml") if (root /
                                          "defaults.yaml").is_file() else {}
    org_billing = str(((defaults.get("global") or {}).get("billing_account") or
                       ""))
    self.billing_accounts = {}
    for p in _yaml_files(root / "billing-accounts"):
      raw = str(_load(p).get("id") or "")
      self.billing_accounts[p.stem] = (org_billing if raw in (
          "", "$defaults:billing_account") else raw)
    if not self.billing_accounts and org_billing:
      self.billing_accounts["default"] = org_billing
    self.export_account = next(
        (k for k, v in self.billing_accounts.items() if v == org_billing),
        next(iter(self.billing_accounts), None))
    self.billing_export = sorted(
        k for k, d in self.projects.items()
        if "billing_export" in (d.get("datasets") or {}))
    self.svpc = {}
    for k, d in self.projects.items():
      host = (d.get("shared_vpc_service_config") or {}).get("host_project")
      if host:
        self.svpc[k] = _tok(host, "project_ids") or host


def _org_label_class(label):
  if label == "":
    return "hierarchy"
  if label.startswith("logsink"):
    return "logsink"
  return label


def check_org_setup(truth, ds, scene):
  errors = []
  _exactly_once(scene, [cid("folder_card", f) for f in truth.folders], "folder",
                errors)
  folder_ids = {cid("folder_card", f) for f in truth.folders}
  for c in scene.cards.values():
    if c.id.startswith("folder_card_") and c.id not in folder_ids:
      errors.append(f"folder card {c.id} is not defined by the dataset")
  _exactly_once(scene, [cid("proj_zone", p) for p in truth.projects], "project",
                errors)
  proj_ids = {cid("proj_zone", p) for p in truth.projects}
  for z in scene.zones.values():
    if z.style_name == "@ProjectZone" and z.id not in proj_ids:
      errors.append(f"project zone {z.id} is not defined by the dataset")
  _exactly_once(scene, [cid("vpc_zone", p, v) for p, v in truth.vpcs], "VPC",
                errors)
  _exactly_once(scene, [cid("billing_acct", k) for k in truth.billing_accounts],
                "billing account", errors)
  billing_ids = {cid("billing_acct", k) for k in truth.billing_accounts}
  for c in scene.cards:
    if c.startswith("billing_acct_") and c not in billing_ids:
      errors.append(f"billing account card {c} is not defined by the dataset")

  def parent_card(spec):
    if spec.parent_folder_key:
      return cid("folder_card", spec.parent_folder_key)
    if spec.parent_external:
      return cid("external_parent", spec.parent_external)
    return "org_root_card"

  expected = []
  for fkey, fspec in ds.folders.items():
    expected.append((parent_card(fspec), cid("folder_card", fkey), "hierarchy"))
  for pkey, pspec in ds.projects.items():
    expected.append((parent_card(pspec), cid("proj_zone", pkey), "hierarchy"))
  sink_projects = collections.Counter(
      p for _, p in truth.sinks if p in truth.projects)
  for p in sink_projects:
    expected.append(("ctrl_log_sinks", cid("proj_zone", p), "logsink"))
  for p in truth.billing_export:
    expected.append((cid("billing_acct",
                         truth.export_account), cid("proj_bq",
                                                    p), "billing export"))
  for svc, host in truth.svpc.items():
    expected.append((cid("proj_svpc_svc",
                         svc), cid("proj_zone", host), "Shared VPC service"))

  actual = []
  sink_counts = collections.Counter()
  for e in scene.edges:
    cls = _org_label_class(e.label)
    dst = e.dst
    if cls in ("logsink", "Shared VPC service"):
      # Sinks land on a resource card inside the destination project, Shared
      # VPC edges on a VPC zone of the host project: compare by project.
      owners = [z for z in _owner_zones(scene, dst) if z in proj_ids]
      dst = owners[0] if owners else dst
    if cls == "logsink":
      m = re.fullmatch(r"logsink(?: \((\d+)\))?", e.label)
      sink_counts[dst] += int(m.group(1)) if m and m.group(1) else 1
      if (e.src, dst, cls) in actual:
        continue  # one edge per destination resource of the same project
    actual.append((e.src, dst, cls))
  _compare_edges(actual, expected, errors, "hierarchy")
  for p, n in sink_projects.items():
    if sink_counts[cid("proj_zone", p)] != n:
      errors.append(f"log sinks into {p}: YAML has {n}, edges carry "
                    f"{sink_counts[cid('proj_zone', p)]}")
  return errors


@pytest.mark.parametrize("name", _real_datasets("0-org-setup"))
def test_org_setup_truth(name):
  root = _dataset("0-org-setup", name)
  ds = _quiet(org_setup.load_org_setup_dataset, root)
  scene = _quiet(org_setup.build, ds, "hierarchy")
  assert check_org_setup(OrgTruth(root), ds, scene) == []


# --- 1-vpcsc ------------------------------------------------------------------


class VpcscTruth:
  """What a 1-vpcsc dataset defines, read straight from its YAML."""

  def __init__(self, root):

    def factory(name):
      d = root / name
      return {
          p.relative_to(d).with_suffix("").as_posix(): _load(p)
          for p in _yaml_files(d)
      }

    self.perimeters = factory("perimeters")
    self.ingress = factory("ingress-policies")
    self.egress = factory("egress-policies")
    self.access_levels = factory("access-levels")


def _perimeter_zone_ids(key):
  return {
      cid("perim_outer", key),
      cid("perim", key, "status"),
      cid("perim", key, "spec"),
      cid("perim", key, "both")
  }


def _ingress_sources(pol):
  frm = pol.get("from") or {}
  ids = list(frm.get("identities") or [])
  agents = [
      i for i in ids if i.startswith("$iam_principals:service_agents/org/")
  ]
  n = len([a for a in (frm.get("access_levels") or []) if a != "*"])
  n += 1 if agents else 0
  n += len(ids) - len(agents)
  n += len(frm.get("resources") or [])
  n += len(frm.get("psc_endpoints") or [])
  if frm.get("identity_type") and not ids:
    n += 1
  return n


def check_vpcsc(truth, scene):
  errors = []
  top = scene.zones.get("perimeters_col")
  top_ids = [z.id for z in (top.children if top else [])]
  for key, doc in truth.perimeters.items():
    mine = [z for z in top_ids if z in _perimeter_zone_ids(key)]
    if len(mine) != 1:
      errors.append(f"perimeter {key}: {len(mine)} top-level zones, expected 1")
      continue
    zones = [
        z for z in scene.zones.values() if z.id in _perimeter_zone_ids(key) and
        mine[0] in _ancestors(scene, z.id)
    ]
    badges = {b.text for z in zones for b in z.badges}
    has_status = doc.get("status") is not None
    has_spec = doc.get("spec") is not None
    explicit = bool(doc.get("use_explicit_dry_run_spec", False))
    want = {
        vpcsc.BADGE_ENFORCED: has_status,
        vpcsc.BADGE_DRY_RUN: has_spec and explicit,
        vpcsc.BADGE_SPEC_NOT_APPLIED: has_spec and not explicit,
    }
    for text, present in want.items():
      if present != (text in badges):
        errors.append(f"perimeter {key}: badge {text!r} "
                      f"{'missing' if present else 'not backed by the data'}")
  known = set()
  for key in truth.perimeters:
    known |= _perimeter_zone_ids(key)
  for z in top_ids:
    if z not in known:
      errors.append(f"perimeter zone {z} is not defined by the dataset")

  edges_in = collections.defaultdict(list)
  edges_out = collections.defaultdict(list)
  for e in scene.edges:
    edges_in[e.dst].append(e)
    edges_out[e.src].append(e)

  for key, doc in truth.perimeters.items():
    blocks = []
    if doc.get("status") is not None and doc.get("spec") is not None and (
        doc["status"] == doc["spec"]):
      blocks.append(("both", doc["status"]))
    else:
      for mode in ("status", "spec"):
        if doc.get(mode) is not None:
          blocks.append((mode, doc[mode]))
    for suffix, blk in blocks:
      blk = blk or {}
      bzone = cid("perim", key, suffix)
      members = scene.zones.get(cid("prot_res", key, suffix))
      got = sorted(c.id for c in (members.children if members else []))
      want = sorted(
          {cid("res", key, suffix, r) for r in blk.get("resources") or []})
      if got != want:
        errors.append(f"perimeter {key}/{suffix}: protected resources {got} "
                      f"!= perimeter resources {want}")
      al_edges = [e for e in edges_in[bzone] if e.label == "access level"]
      want_als = sorted(
          cid("src_al",
              _tok(a, "access_levels") or a)
          for a in blk.get("access_levels") or [])
      if sorted(e.src for e in al_edges) != want_als:
        errors.append(f"perimeter {key}/{suffix}: access level edges "
                      f"{sorted(e.src for e in al_edges)} != YAML {want_als}")
      for ref in blk.get("ingress_policies") or []:
        pkey = _tok(ref, "ingress_policies") or ref
        card = cid("ing_pol", key, suffix, pkey)
        ins = [e for e in edges_in[card]]
        outs = [e for e in edges_out[card]]
        pol = truth.ingress.get(pkey)
        if pol is None:
          if ins or outs:
            errors.append(f"unresolved ingress policy {pkey} in {key}/{suffix} "
                          f"has edges {[(e.src, e.dst) for e in ins + outs]}")
          continue
        if len(ins) != _ingress_sources(pol) or any(
            e.label != "ingress" for e in ins):
          errors.append(f"ingress {pkey} in {key}/{suffix}: {len(ins)} source "
                        f"edges, YAML defines {_ingress_sources(pol)} sources")
        n_to = len((pol.get("to") or {}).get("resources") or [])
        if len(outs) != n_to:
          errors.append(f"ingress {pkey} in {key}/{suffix}: {len(outs)} target "
                        f"edges, YAML defines {n_to} to.resources")
      for ref in blk.get("egress_policies") or []:
        pkey = _tok(ref, "egress_policies") or ref
        card = cid("egr_pol", key, suffix, pkey)
        ins = [e for e in edges_in[card]]
        outs = [e for e in edges_out[card]]
        pol = truth.egress.get(pkey)
        if pol is None:
          if ins or outs:
            errors.append(f"unresolved egress policy {pkey} in {key}/{suffix} "
                          f"has edges {[(e.src, e.dst) for e in ins + outs]}")
          continue
        n_from = len((pol.get("from") or {}).get("resources") or []) or 1
        if len(ins) != n_from or any(e.label != "egress" for e in ins):
          errors.append(f"egress {pkey} in {key}/{suffix}: {len(ins)} source "
                        f"edges, YAML defines {n_from}")
        to = pol.get("to") or {}
        n_to = len(to.get("resources") or []) + len(
            to.get("external_resources") or [])
        if len(outs) != n_to:
          errors.append(f"egress {pkey} in {key}/{suffix}: {len(outs)} target "
                        f"edges, YAML defines {n_to}")
  policy_cards = {
      e.dst for e in scene.edges if e.label in ("ingress", "egress")
  } | {e.src for e in scene.edges if e.label in ("ingress", "egress")}
  for e in scene.edges:
    if e.label not in ("access level", "ingress", "egress", ""):
      errors.append(f"edge {e.src}->{e.dst} has unexpected label {e.label!r}")
    if e.label == "" and not (e.src.startswith(
        ("ing_pol_", "egr_pol_")) or e.src in policy_cards):
      errors.append(f"edge {e.src}->{e.dst} does not leave a policy card")
  return errors


@pytest.mark.parametrize("name", _real_datasets("1-vpcsc"))
@pytest.mark.parametrize("with_org", [False, True])
def test_vpcsc_truth(name, with_org):
  root = _dataset("1-vpcsc", name)
  kwargs = {}
  if with_org:
    org_root = stage_datasets_root("0-org-setup")
    if org_root is None or not (org_root / name).is_dir():
      pytest.skip(f"no 0-org-setup dataset named {name}")
    kwargs["org_dataset"] = org_root / name
  scene = _quiet(vpcsc.build, root, "perimeters", **kwargs)
  assert check_vpcsc(VpcscTruth(root), scene) == []


# --- crafted datasets ---------------------------------------------------------


def _write(root, rel, text):
  path = root / rel
  path.parent.mkdir(parents=True, exist_ok=True)
  path.write_text(text, encoding="utf-8")


def _crafted_networking(tmp_path):
  """VPC-less host project, disabled VPN and VLAN factories, ILB routes."""
  root = tmp_path / "net"
  _write(root, "defaults.yaml",
         "context:\n  locations:\n    primary: europe-west1\n")
  for p in ("core", "spoke-a", "empty"):
    _write(root, f"projects/{p}.yaml",
           f"name: {p}-0\nshared_vpc_host_config:\n  enabled: true\n")
  _write(
      root, "vpcs/hub/.config.yaml", "project_id: $project_ids:core\n"
      "routers:\n  r1:\n    region: europe-west1\n    asn: 64514\n"
      "routes:\n"
      "  a: {dest_range: 10.0.0.0/8, next_hop_type: ilb, next_hop: x}\n"
      "  b: {dest_range: 172.16.0.0/12, next_hop_type: ilb, next_hop: x}\n"
      "factories_config:\n  vlan_attachments: none\n  vpns: none\n")
  _write(
      root, "vpcs/hub/vpns/onprem.yaml", "name: onprem\n"
      "peer_gateways:\n  default:\n    external:\n"
      "      redundancy_type: SINGLE_IP_INTERNALLY_REDUNDANT\n"
      "      interfaces: [8.8.8.8]\n"
      "router_config:\n  name: $routers:hub/r1\n")
  _write(root, "vpcs/hub/vlan-attachments/a.yaml", "name: a\n"
         "router_config:\n  name: $routers:hub/r1\n")
  _write(
      root, "vpcs/spoke/.config.yaml", "project_id: $project_ids:spoke-a\n"
      "peering_config:\n  to-hub:\n    peer_network: $networks:hub\n")
  return root


def test_crafted_networking_truth(tmp_path):
  root = _crafted_networking(tmp_path)
  truth = NetTruth(root)
  scene = _quiet(networking.build, root, "topology")
  assert check_networking_topology(truth, scene) == []
  assert cid("Proj", "empty") in scene.zones
  assert not any(
      c.icon in ("CloudVPN", "CloudInterconnect") for c in scene.cards.values())
  assert not any(e.label in ("HA VPN", "Interconnect", "Hybrid Spoke")
                 for e in scene.edges)
  assert "site_onprem" not in scene.cards
  # Both ILB routes are summarised although the VPC has a Cloud Router.
  assert scene.cards[cid("routes_ilb", "hub")].title == "Routes via ILB (2)"
  dns = _quiet(networking.build, root, "dns")
  assert check_networking_dns(truth, dns) == []
  assert not any("8.8.8.8" in c.subtitle for c in dns.cards.values())


def test_crafted_org_setup_truth(tmp_path):
  root = tmp_path / "org"
  _write(
      root, "defaults.yaml",
      "global:\n  organization:\n    domain: example.com\n    id: 1\n"
      "projects:\n  defaults:\n    prefix: t\n")
  _write(
      root, "organization/.config.yaml", "logging:\n  sinks:\n"
      "    audit:\n      destination: $log_buckets:log-0/audit\n"
      "    bq:\n      type: bigquery\n"
      "      destination: $bigquery_datasets:log-0/logs\n"
      "    ps:\n      type: pubsub\n"
      "      destination: $pubsub_topics:log-0/events\n")
  _write(
      root, "projects/log-0.yaml", "name: log-0\nlog_buckets:\n"
      "  _Default: {retention: 30}\n  audit: {}\n"
      "datasets:\n  logs: {}\n")
  _write(root, "projects/ext-0.yaml", "name: ext-0\nparent: folders/12345\n")
  _write(root, "folders/team/.config.yaml",
         "name: Team\nparent: folders/12345\n")
  _write(root, "billing-accounts/main.yaml", "id: AAAAAA-BBBBBB-CCCCCC\n")
  _write(root, "billing-accounts/second.yaml", "id: 012345-6789AB-CDEF01\n")
  ds = _quiet(org_setup.load_org_setup_dataset, root)
  scene = _quiet(org_setup.build, ds, "hierarchy")
  assert check_org_setup(OrgTruth(root), ds, scene) == []
  assert {cid("billing_acct", "main"),
          cid("billing_acct", "second")} <= set(scene.cards)
  ext = cid("external_parent", "folders/12345")
  assert ext in scene.cards and scene.cards[ext].dashed
  assert ("org_root_card", cid("proj_zone", "ext-0")) not in {
      (e.src, e.dst) for e in scene.edges
  }
  sink_dst = sorted(e.dst for e in scene.edges if e.label == "logsink")
  assert sink_dst == sorted([
      cid("proj_log_buckets", "log-0"),
      cid("proj_bq", "log-0"),
      cid("proj_pubsub", "log-0")
  ])
  # `_Default` alone is a configuration of the built-in bucket, not a bucket.
  assert scene.cards[cid("proj_log_buckets",
                         "log-0")].title == ("Log Buckets (1)")


# --- negative controls --------------------------------------------------------


def _first(stage, prefer):
  root = stage_datasets_root(stage)
  if root is None or not (root / prefer).is_dir():
    pytest.skip(f"FAST dataset {stage}/{prefer} not found")
  return root / prefer


def test_negative_controls_networking():
  root = _first("2-networking", "hub-and-spokes-nva")
  truth = NetTruth(root)
  scene = _quiet(networking.build, root, "topology")
  assert check_networking_topology(truth, scene) == []

  dropped = copy.deepcopy(scene)
  zid = cid("Proj", "net-dev-0")
  parent = dropped.zones[dropped.zones[zid].parent_zone_id]
  parent.children = [c for c in parent.children if c.id != zid]
  del dropped.zones[zid]
  assert any(zid in e for e in check_networking_topology(truth, dropped))

  vlan = copy.deepcopy(scene)
  vlan.add_card(
      make_card(cid("vlan", "dmz"), "VLAN Attachments", "x",
                icon="CloudInterconnect"), vlan.zones[cid("Vpc", "dmz")])
  vlan.add_edge(
      make_edge("site_onprem", cid("vlan", "dmz"), "<-->", "Interconnect"))
  errs = check_networking_topology(truth, vlan)
  assert any("vlan_attachments factory is disabled" in e for e in errs)
  assert any("Interconnect" in e for e in errs)

  invented = copy.deepcopy(scene)
  invented.add_edge(
      make_edge(cid("ilb", "hub", "main"), cid("ilb", "dev", "main"), "<-->",
                "VPC Peering"))
  assert any("no relationship" in e
             for e in check_networking_topology(truth, invented))

  missing = copy.deepcopy(scene)
  missing.edges = [e for e in missing.edges if e.label != "HA VPN"]
  assert any(
      "not drawn" in e for e in check_networking_topology(truth, missing))

  dns = _quiet(networking.build, root, "dns")
  assert check_networking_dns(truth, dns) == []
  bad_dns = copy.deepcopy(dns)
  bad_dns.edges = [e for e in bad_dns.edges if not e.label.startswith("Peer")]
  assert check_networking_dns(truth, bad_dns)
  dup = copy.deepcopy(dns)
  zone = dup.zones[cid("DnsVpcZone", "hub")]
  zone.id = "DnsVpcZone_hub_copy"
  dup.zones[zone.id] = zone
  assert any("not defined" in e for e in check_networking_dns(truth, dup))


def test_negative_controls_org_setup():
  root = _first("0-org-setup", "starter-gcd")
  ds = _quiet(org_setup.load_org_setup_dataset, root)
  truth = OrgTruth(root)
  scene = _quiet(org_setup.build, ds, "hierarchy")
  assert check_org_setup(truth, ds, scene) == []

  no_sink = copy.deepcopy(scene)
  no_sink.edges = [e for e in no_sink.edges if e.label != "logsink"]
  assert any("not drawn" in e for e in check_org_setup(truth, ds, no_sink))

  wrong_billing = copy.deepcopy(scene)
  for e in wrong_billing.edges:
    if e.label == "billing export":
      e.dst = cid("proj_zone", "dev-app-0")
  assert check_org_setup(truth, ds, wrong_billing)

  twice = copy.deepcopy(scene)
  card = copy.deepcopy(twice.cards[cid("folder_card", "dev")])
  card.id = cid("folder_card", "dev_copy")
  twice.cards[card.id] = card
  assert any("not defined" in e for e in check_org_setup(truth, ds, twice))

  no_billing = copy.deepcopy(scene)
  del no_billing.cards["billing_acct_default"]
  assert any(
      "billing account" in e for e in check_org_setup(truth, ds, no_billing))

  reparented = copy.deepcopy(scene)
  for e in reparented.edges:
    if e.dst == cid("proj_zone", "dev-app-0"):
      e.src = "org_root_card"
  assert check_org_setup(truth, ds, reparented)


def test_negative_controls_vpcsc():
  root = _first("1-vpcsc", "classic")
  truth = VpcscTruth(root)
  scene = _quiet(vpcsc.build, root, "perimeters")
  assert check_vpcsc(truth, scene) == []

  wrong_mode = copy.deepcopy(scene)
  for z in wrong_mode.zones.values():
    if z.id.startswith("perim_"):
      z.badges = [Badge(text=vpcsc.BADGE_ENFORCED, tone="danger")]
  errs = check_vpcsc(truth, wrong_mode)
  assert any("not backed by the data" in e for e in errs)
  assert any("missing" in e for e in errs)

  no_ingress = copy.deepcopy(scene)
  no_ingress.edges = [e for e in no_ingress.edges if e.label != "ingress"]
  assert any("source edges" in e for e in check_vpcsc(truth, no_ingress))

  intruder = copy.deepcopy(scene)
  prot = next(
      z for z in intruder.zones.values() if z.id.startswith("prot_res_"))
  intruder.add_card(make_card("res_policy_target", "Project: x", ""), prot)
  assert any("protected resources" in e for e in check_vpcsc(truth, intruder))

  no_al = copy.deepcopy(scene)
  no_al.edges = [e for e in no_al.edges if e.label != "access level"]
  assert any("access level" in e for e in check_vpcsc(truth, no_al))


def test_negative_controls_vpcsc_unresolved_policy(tmp_path):
  root = tmp_path / "vpcsc"
  _write(root, "defaults.yaml", "output_files: {}\n")
  _write(
      root, "perimeters/p1.yaml", "use_explicit_dry_run_spec: false\n"
      "status:\n  resources: [projects/123]\n"
      "  ingress_policies: [$ingress_policies:missing]\n"
      "  egress_policies: [$egress_policies:gone]\n"
      "spec:\n  resources: [projects/456]\n")
  truth = VpcscTruth(root)
  scene = _quiet(vpcsc.build, root, "perimeters")
  assert check_vpcsc(truth, scene) == []
  invented = copy.deepcopy(scene)
  invented.add_edge(
      make_edge(cid("ing_pol", "p1", "status", "missing"),
                cid("res", "p1", "status", "projects/123"), "-->", ""))
  assert any(
      "unresolved ingress policy" in e for e in check_vpcsc(truth, invented))


# --- builder behaviour --------------------------------------------------------


def test_networking_ilb_routes_and_ra_routes():
  """All ILB next-hop routes are summarised even with a Cloud Router, and the
  router appliance NIC card lists the routes of every NVA."""
  root = _first("2-networking", "hub-and-spokes-nva")
  scene = _quiet(networking.build, root, "topology")
  card = scene.cards[cid("routes_ilb", "dmz")]
  assert card.title == "Routes via ILB (3)"
  assert scene.cards[cid("route", "dev",
                         "gateway")].subtitle == ("next-hop: ILB (dev/main)")
  root = _first("2-networking", "hub-and-spokes-nva-ncc")
  truth = NetTruth(root)
  scene = _quiet(networking.build, root, "topology")
  routes = set()
  for nkey in truth.nvas:
    nics = ((truth.nvas[nkey].get("auto_instance_config") or {}).get("nics") or
            [])
    for nic in nics:
      if _tok(nic.get("network"), "networks") == "transit":
        routes |= set(nic.get("routes") or [])
  sub = scene.cards[cid("nic_ra", "transit")].subtitle
  assert all(r in sub for r in routes), sub


def test_networking_no_invented_defaults(tmp_path):
  """No `b/c` zones, no public resolver IPs, no `PGA` label without data."""
  root = tmp_path / "net"
  _write(root, "projects/core.yaml", "name: core-0\n")
  _write(root, "vpcs/hub/.config.yaml", "project_id: $project_ids:core\n")
  _write(
      root, "nvas/main.yaml", "project_id: $project_ids:core\nname: main\n"
      "region: europe-west1\nauto_instance_config:\n  nics:\n"
      "    - network: $networks:hub\n      subnet: $subnets:hub/ew1/a\n")
  _write(
      root, "dns/zones/fwd.yaml", "project_id: $project_ids:core\n"
      "domain: onprem.\nforwarding:\n  client_networks: [$networks:hub]\n")
  _write(
      root, "dns/response-policies/rp.yaml", "project_id: $project_ids:core\n"
      "networks: [$networks:hub]\nrules:\n"
      "  a: {dns_name: a.example.com., local_data: {A: {rrdatas: [1.2.3.4]}}}\n"
  )
  topo = _quiet(networking.build, root, "topology")
  assert topo.cards[cid("nva", "main")].title == "NVA: main (ew1)"
  dns = _quiet(networking.build, root, "dns")
  texts = " ".join(f"{c.title} {c.subtitle}" for c in dns.cards.values())
  assert "8.8.8.8" not in texts and "1.1.1.1" not in texts
  assert "no forwarders defined" in texts
  assert "PGA" not in texts
  assert dns.cards[cid("rpz", "core", "rp")].title == "RPZ: rp (1 rule)"


def test_networking_legend_matches_edges():
  root = _first("2-networking", "hub-and-spokes-nva-ncc")
  scene = _quiet(networking.build, root, "topology")
  colours = {e.color for e in scene.edges}
  assert scene.legend, "legend is on by default"
  assert {entry.color for entry in scene.legend} == colours
  assert not _quiet(networking.build, root, "topology", legend=False).legend
  dns = _quiet(networking.build, root, "dns")
  assert {entry.color for entry in dns.legend} == {e.color for e in dns.edges}


@pytest.mark.parametrize("module,stage,view", [
    (networking, "2-networking", "topology"),
    (vpcsc, "1-vpcsc", "perimeters"),
    (org_setup, "0-org-setup", "hierarchy"),
])
def test_build_rejects_unknown_options(module, stage, view):
  root = stage_datasets_root(stage)
  if root is None:
    pytest.skip(f"no FAST {stage} datasets found")
  name = next(p.name for p in sorted(root.iterdir()) if p.is_dir())
  with pytest.raises(TypeError):
    module.build(root / name, view, verbose_bagdes=True)


def check_legend_styles(scene):
  """Legend rows are told apart without colour, and match the edges.

  Two edge rows may not share a (dash, head) pair, and every drawn edge's
  (colour, dash, head) must be one of the legend rows.
  """
  errors = []
  rows = [l for l in scene.legend if l.kind == "edge"]
  seen = {}
  for row in rows:
    key = (row.dash, row.head)
    if key in seen:
      errors.append(f"legend rows {seen[key]!r} and {row.label!r} share "
                    f"dash/head {key}; only colour tells them apart")
    seen.setdefault(key, row.label)
  styles = {(r.color, r.dash, r.head) for r in rows}
  for e in scene.edges:
    if (e.color, e.dash_style, e.head) not in styles:
      errors.append(f"edge {e.src}->{e.dst} style "
                    f"{(e.color, e.dash_style, e.head)} is not in the legend")
  return errors


def _all_views():
  out = []
  for stage, module in (("0-org-setup", org_setup), ("1-vpcsc", vpcsc),
                        ("2-networking", networking)):
    for name in _real_datasets(stage):
      if not isinstance(name, str):
        out.append(name)
        continue
      for view in module.VIEWS:
        out.append(pytest.param(stage, name, view, id=f"{stage}-{name}-{view}"))
  return out


@pytest.mark.parametrize("stage,name,view", _all_views())
def test_legend_styles_are_distinct(stage, name, view):
  module = {
      "0-org-setup": org_setup,
      "1-vpcsc": vpcsc,
      "2-networking": networking
  }[stage]
  scene = _quiet(module.build, _dataset(stage, name), view)
  assert scene.legend
  assert check_legend_styles(scene) == []


def test_networking_edge_kinds_are_distinct():
  """Every topology (and every DNS) kind has its own dash/head pair."""
  topo = [k for k in networking.EDGE_KINDS if not k.startswith("dns_")]
  dns = [k for k in networking.EDGE_KINDS if k.startswith("dns_")]
  for group in (topo, dns):
    pairs = [networking.EDGE_KINDS[k][2:] for k in group]
    assert len(pairs) == len(set(pairs)), group


def test_negative_control_legend_styles():
  root = _first("2-networking", "hub-and-spokes-nva-ncc")
  scene = _quiet(networking.build, root, "topology")
  assert check_legend_styles(scene) == []
  same = copy.deepcopy(scene)
  first, second = same.legend[0], same.legend[1]
  second.dash, second.head = first.dash, first.head
  assert any("only colour" in e for e in check_legend_styles(same))
  off = copy.deepcopy(scene)
  off.edges[0].head = "open" if off.edges[0].head != "open" else "filled"
  assert any("not in the legend" in e for e in check_legend_styles(off))
