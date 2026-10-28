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
"""FAST `2-networking` dataset directory -> plain-Python topology model.

Stdlib + PyYAML port of the fast-net-designer importer. The resulting `IR`
has the same structure and, critically, the same ordering as the original:

- files are read in sorted order, YAML keys keep document order;
- `links` are appended in import order: site VPNs and VLANs while reading
  each VPC (with NCC spokes from VPC / VPN / VLAN configs interleaved as they
  are met), then NCC spokes from NVAs, then paired peerings, then paired
  GCP-to-GCP VPNs;
- `opaque` captures every YAML file outside the modelled set (e.g. `dns/**`).

Documents are normalised the way the original round-trip loader did
(YAML 1.2 booleans, JSON-compatible keys and scalars) so downstream builders
see identical values. Never fails on unknown structure.
"""

import dataclasses
from dataclasses import dataclass, field
import datetime
import json
import pathlib
import re

import yaml

from .. import tokens

__all__ = [
    "IR",
    "Link",
    "NccHub",
    "Nic",
    "Nva",
    "Site",
    "Subnet",
    "Vpc",
    "VlanAttachment",
    "VpnGateway",
    "load_dataset",
]

# Keys of each file type that the model owns; everything else lands in `extra`.
VPC_OWNED = frozenset({
    "project_id", "name", "description", "mtu", "routing_mode",
    "delete_default_routes_on_create", "routers", "nat_config", "routes",
    "peering_config", "ncc_config",
})
SUBNET_OWNED = frozenset({
    "name", "region", "ip_cidr_range", "description", "proxy_only", "psc",
    "enable_private_access",
})
VPN_OWNED = frozenset({
    "name", "region", "peer_gateways", "router_config", "tunnels",
    "ncc_spoke_config",
})
VLAN_OWNED = frozenset(
    {"name", "region", "router_config", "peer_asn", "ncc_spoke_config"})
NCC_HUB_OWNED = frozenset({
    "name", "project_id", "description", "preset_topology", "export_psc",
    "groups",
})
NVA_OWNED = frozenset({
    "project_id", "name", "region", "auto_instance_config", "ilb_config",
    "ncc_ra_config",
})
DEFAULTS_OWNED = frozenset({"context", "vpcs"})


@dataclass
class Subnet:
  name: str
  region: str
  ip_cidr_range: str | None = None
  description: str | None = None
  proxy_only: bool | None = None
  psc: bool | None = None
  enable_private_access: bool | None = None
  extra: dict = field(default_factory=dict)


@dataclass
class VpnGateway:
  """One `vpcs/<vpc>/vpns/<name>.yaml`; the peer is on the `vpn` link."""
  name: str
  region: str | None = None
  router_config: dict | None = None
  tunnels: dict = field(default_factory=dict)
  peer_external: dict | None = None
  peer_key: str = "default"
  extra: dict = field(default_factory=dict)


@dataclass
class VlanAttachment:
  """One `vpcs/<vpc>/vlan-attachments/<name>.yaml`."""
  name: str
  region: str | None = None
  router_config: dict | None = None
  peer_asn: str | int | None = None
  extra: dict = field(default_factory=dict)


@dataclass
class Vpc:
  key: str
  project: str | None = None
  name: str | None = None
  description: str | None = None
  mtu: int | None = None
  routing_mode: str | None = None
  delete_default_routes_on_create: bool | None = None
  subnets: list[Subnet] = field(default_factory=list)
  routers: dict = field(default_factory=dict)
  nat: dict = field(default_factory=dict)
  routes: dict = field(default_factory=dict)
  vpns: list[VpnGateway] = field(default_factory=list)
  vlan_attachments: list[VlanAttachment] = field(default_factory=list)
  extra: dict = field(default_factory=dict)


@dataclass
class NccHub:
  key: str
  project: str | None = None
  name: str | None = None
  description: str | None = None
  preset_topology: str | None = None
  export_psc: bool | None = None
  groups: dict = field(default_factory=dict)
  extra: dict = field(default_factory=dict)


@dataclass
class Nic:
  vpc: str
  subnet: str
  region: str
  routes: list[str] = field(default_factory=list)
  masquerade: bool | None = None
  ilb: bool = False
  extra: dict = field(default_factory=dict)


@dataclass
class Nva:
  key: str
  project: str | None = None
  name: str | None = None
  region: str | None = None
  nics: list[Nic] = field(default_factory=list)
  instance_config: dict = field(default_factory=dict)
  ilb_config: dict = field(default_factory=dict)
  ncc_ra_extra: dict = field(default_factory=dict)
  extra: dict = field(default_factory=dict)


@dataclass
class Site:
  """A non-GCP endpoint (on-prem), derived from VPN / VLAN names."""
  key: str
  asn: str | int | None = None
  extra: dict = field(default_factory=dict)


@dataclass
class Link:
  """Graph edge. `type` in {peering, vpn, vlan, ncc_spoke}.

  peering:   a={vpc, key, ...flags}  b={vpc, key, ...flags} (key None = half)
  vpn:       a={vpc, name}           b={vpc, name} | {site}
  vlan:      a={vpc, name}           b={site}
  ncc_spoke: a={hub, group}          b={vpc} | {vpn: [vpc, name]} |
                                       {vlan: [vpc, name]} | {nva, vpc}
  """
  id: str
  type: str
  a: dict
  b: dict
  attrs: dict = field(default_factory=dict)


@dataclass
class IR:
  defaults: dict = field(default_factory=dict)
  projects: dict = field(default_factory=dict)
  vpcs: dict = field(default_factory=dict)
  ncc_hubs: dict = field(default_factory=dict)
  nvas: dict = field(default_factory=dict)
  sites: dict = field(default_factory=dict)
  links: list = field(default_factory=list)
  opaque: dict = field(default_factory=dict)
  mode: str = "fast"

  def to_dict(self):
    return dataclasses.asdict(self)

  def locations(self):
    return self.defaults.get("locations", {}) or {}

  def resolve_region(self, region):
    """Resolves `$locations:<key>` through defaults; literals pass through."""
    if isinstance(region, str) and region.startswith("$locations:"):
      return self.locations().get(region.split(":", 1)[1], region)
    return region


# --- YAML loading -----------------------------------------------------------


class _Yaml12Loader(yaml.SafeLoader):
  """SafeLoader with YAML 1.2 booleans (no `yes`/`no`/`on`/`off`).

  Matches the round-trip loader the original importer used, so a value like
  `enable: on` stays the string "on" instead of turning into True.
  """


_Yaml12Loader.yaml_implicit_resolvers = {
    ch: [(tag, rx) for tag, rx in resolvers if tag != "tag:yaml.org,2002:bool"]
    for ch, resolvers in yaml.SafeLoader.yaml_implicit_resolvers.items()
}
_Yaml12Loader.add_implicit_resolver(
    "tag:yaml.org,2002:bool",
    re.compile(r"^(?:true|True|TRUE|false|False|FALSE)$"),
    list("tTfF"),
)


def _json_default(obj):
  if isinstance(obj, (datetime.date, datetime.datetime)):
    return obj.isoformat()
  return str(obj)


def _load(path):
  """Plain JSON-compatible document; empty files load as `{}`."""
  doc = yaml.load(pathlib.Path(path).read_text(), Loader=_Yaml12Loader)
  if doc is None:
    doc = {}
  return json.loads(json.dumps(doc, default=_json_default))


def _yaml_files(directory):
  directory = pathlib.Path(directory)
  if not directory.is_dir():
    return []
  return sorted(
      p for p in directory.iterdir() if p.suffix == ".yaml" and p.is_file())


def _stem(path):
  return path.name[:-len(".yaml")]


def _strip_keys(plain, keys):
  return {k: v for k, v in plain.items() if k not in keys}


def _project_key(value):
  return tokens.key_of(value, "project_ids") or value


# --- import -----------------------------------------------------------------


def load_dataset(dataset_dir):
  """Reads a `2-networking` dataset directory into an `IR`."""
  root = pathlib.Path(dataset_dir)
  ir = IR()
  _import_defaults(ir, root)
  _import_projects(ir, root)
  vpcs_dir = root / "vpcs"
  if vpcs_dir.is_dir():
    for vpc_dir in sorted(p for p in vpcs_dir.iterdir() if p.is_dir()):
      _import_vpc(ir, vpc_dir)
  for path in _yaml_files(root / "ncc-hubs"):
    _import_ncc_hub(ir, path)
  for path in _yaml_files(root / "nvas"):
    _import_nva(ir, path)
  _derive_peerings(ir)
  _derive_sites(ir)
  _import_opaque(ir, root)
  ir.mode = "fast" if ir.projects else "standalone"
  return ir


def _import_defaults(ir, root):
  path = root / "defaults.yaml"
  if not path.exists():
    return
  plain = _load(path)
  context = plain.get("context", {}) or {}
  ir.defaults = {
      "locations": context.get("locations", {}) or {},
      "cidr_ranges_sets": context.get("cidr_ranges_sets", {}) or {},
      "context_extra": _strip_keys(context, {"locations", "cidr_ranges_sets"}),
      "vpc_defaults": (plain.get("vpcs", {}) or {}).get("defaults", {}) or {},
      "vpcs_extra": _strip_keys(plain.get("vpcs", {}) or {}, {"defaults"}),
      "extra": _strip_keys(plain, DEFAULTS_OWNED),
  }


def _import_projects(ir, root):
  for path in _yaml_files(root / "projects"):
    ir.projects[_stem(path)] = {"reuse_id": None, "extra": _load(path)}


def _import_vpc(ir, vpc_dir):
  key = vpc_dir.name
  config_path = vpc_dir / ".config.yaml"
  plain = _load(config_path) if config_path.exists() else {}
  vpc = Vpc(
      key=key,
      project=_project_key(plain.get("project_id")),
      name=plain.get("name"),
      description=plain.get("description"),
      mtu=plain.get("mtu"),
      routing_mode=plain.get("routing_mode"),
      delete_default_routes_on_create=plain.get(
          "delete_default_routes_on_create"),
      routers=plain.get("routers", {}) or {},
      nat=plain.get("nat_config", {}) or {},
      routes=plain.get("routes", {}) or {},
      extra=_strip_keys(plain, VPC_OWNED),
  )
  # peering_config and ncc_config are turned into links
  vpc.extra["_peering_config"] = plain.get("peering_config", {}) or {}
  if plain.get("ncc_config"):
    _add_spoke(ir, plain["ncc_config"], {"vpc": key})
  for path in _yaml_files(vpc_dir / "subnets"):
    s = _load(path)
    name = s.get("name", _stem(path))
    extra = _strip_keys(s, SUBNET_OWNED)
    if name != _stem(path):
      extra = extra | {"_file": _stem(path)}
    vpc.subnets.append(
        Subnet(
            name=name,
            region=s.get("region"),
            ip_cidr_range=s.get("ip_cidr_range"),
            description=s.get("description"),
            proxy_only=s.get("proxy_only"),
            psc=s.get("psc"),
            enable_private_access=s.get("enable_private_access"),
            extra=extra,
        ))
  for path in _yaml_files(vpc_dir / "vpns"):
    _import_vpn(ir, vpc, path)
  for path in _yaml_files(vpc_dir / "vlan-attachments"):
    _import_vlan(ir, vpc, path)
  ir.vpcs[key] = vpc


def _import_vpn(ir, vpc, path):
  v = _load(path)
  name = v.get("name", _stem(path))
  gw = VpnGateway(
      name=name,
      region=v.get("region"),
      router_config=v.get("router_config"),
      tunnels=v.get("tunnels", {}) or {},
      extra=_strip_keys(v, VPN_OWNED),
  )
  if name != _stem(path):
    gw.extra["_file"] = _stem(path)
  peer_gateways = v.get("peer_gateways", {}) or {}
  peer_vpc = None
  for pk, pg in peer_gateways.items():
    gw.peer_key = pk
    if isinstance(pg, dict) and tokens.key_of(pg.get("gcp"), "vpn_gateways"):
      peer_vpc = tokens.split_path(tokens.key_of(pg["gcp"], "vpn_gateways"), 2)
      rest = _strip_keys(pg, {"gcp"})
      if rest:
        gw.extra["_peer_gateway_extra"] = rest
    elif isinstance(pg, dict) and "external" in pg:
      gw.peer_external = pg["external"]
      rest = _strip_keys(pg, {"external"})
      if rest:
        gw.extra["_peer_gateway_extra"] = rest
    else:
      gw.extra.setdefault("_peer_gateways_raw", {})[pk] = pg
    break  # the stage uses a single peer gateway per VPN
  if len(peer_gateways) > 1:
    gw.extra["_peer_gateways_raw"] = peer_gateways
  vpc.vpns.append(gw)
  if v.get("ncc_spoke_config"):
    _add_spoke(ir, v["ncc_spoke_config"], {"vpn": [vpc.key, name]})
  # GCP-to-GCP links are paired after all VPCs are read; stash the intent.
  if peer_vpc:
    gw.extra["_peer_vpn"] = peer_vpc
  else:
    ir.links.append(
        Link(id=f"vpn:{vpc.key}/{name}", type="vpn",
             a={"vpc": vpc.key, "name": name}, b={"site": _site_key(name)}))


def _import_vlan(ir, vpc, path):
  v = _load(path)
  name = v.get("name", _stem(path))
  att = VlanAttachment(
      name=name,
      region=v.get("region"),
      router_config=v.get("router_config"),
      peer_asn=v.get("peer_asn"),
      extra=_strip_keys(v, VLAN_OWNED),
  )
  if name != _stem(path):
    att.extra["_file"] = _stem(path)
  vpc.vlan_attachments.append(att)
  if v.get("ncc_spoke_config"):
    _add_spoke(ir, v["ncc_spoke_config"], {"vlan": [vpc.key, name]})
  ir.links.append(
      Link(id=f"vlan:{vpc.key}/{name}", type="vlan",
           a={"vpc": vpc.key, "name": name}, b={"site": _site_key(name)}))


def _site_key(name):
  """'to-onprem-vlan-0' -> 'onprem'; 'onprem' -> 'onprem'."""
  key = name
  if key.startswith("to-"):
    key = key[3:]
  for marker in ("-vlan-", "-attachment-", "-vpn-"):
    if marker in key:
      key = key.split(marker)[0]
  return key or name


def _import_ncc_hub(ir, path):
  h = _load(path)
  key = _stem(path)
  groups = {}
  for gname, g in (h.get("groups", {}) or {}).items():
    g = dict(g or {})
    g["auto_accept"] = [_project_key(p) for p in g.get("auto_accept", []) or []]
    if not g["auto_accept"]:
      del g["auto_accept"]
    groups[gname] = g
  ir.ncc_hubs[key] = NccHub(
      key=key,
      project=_project_key(h.get("project_id")),
      name=h.get("name"),
      description=h.get("description"),
      preset_topology=h.get("preset_topology"),
      export_psc=h.get("export_psc"),
      groups=groups,
      extra=_strip_keys(h, NCC_HUB_OWNED),
  )


def _import_nva(ir, path):
  n = _load(path)
  key = _stem(path)
  aic = dict(n.get("auto_instance_config", {}) or {})
  ilb = dict(n.get("ilb_config", {}) or {})
  fr = ilb.pop("forwarding_rules", []) or []
  fr_set = {(f.get("network"), f.get("subnet")) for f in fr}
  nics = []
  for nic in aic.pop("nics", []) or []:
    vpc_key = tokens.key_of(nic.get("network"), "networks") or nic.get("network")
    sub = tokens.key_of(nic.get("subnet"), "subnets")
    parts = tokens.split_path(sub, 3) if sub else None
    nics.append(
        Nic(
            vpc=vpc_key,
            subnet=parts[2] if parts else nic.get("subnet"),
            region=parts[1] if parts else None,
            routes=nic.get("routes", []) or [],
            masquerade=nic.get("masquerade"),
            ilb=(nic.get("network"), nic.get("subnet")) in fr_set,
            extra=_strip_keys(nic, {"network", "subnet", "routes", "masquerade"}),
        ))
  ra = dict(n.get("ncc_ra_config", {}) or {})
  for spoke in ra.pop("spokes", []) or []:
    spoke = dict(spoke)
    vpc_key = tokens.key_of(spoke.pop("network", None), "networks")
    _add_spoke(ir, spoke, {"nva": key, "vpc": vpc_key})
  ir.nvas[key] = Nva(
      key=key,
      project=_project_key(n.get("project_id")),
      name=n.get("name"),
      region=n.get("region"),
      nics=nics,
      instance_config=aic,
      ilb_config=ilb,
      ncc_ra_extra=ra,
      extra=_strip_keys(n, NVA_OWNED),
  )


def _add_spoke(ir, cfg, target):
  cfg = dict(cfg)
  hub = tokens.key_of(cfg.pop("hub", None), "ncc_hubs")
  group_tok = tokens.key_of(cfg.pop("group", None), "ncc_groups")
  group = None
  if group_tok:
    parts = tokens.split_path(group_tok, 2)
    group = parts[1] if parts else group_tok
  tkey = "/".join(
      str(v) if not isinstance(v, list) else "/".join(v)
      for v in target.values())
  ir.links.append(
      Link(id=f"ncc_spoke:{hub}:{tkey}", type="ncc_spoke",
           a={"hub": hub, "group": group}, b=target, attrs=cfg))


def _derive_peerings(ir):
  """Pairs peering_config entries into links; unpaired ones become half links."""
  entries = []  # [vpc, key, peer_vpc, flags, consumed]
  for vpc in ir.vpcs.values():
    for pkey, cfg in vpc.extra.pop("_peering_config", {}).items():
      cfg = dict(cfg or {})
      peer = tokens.key_of(cfg.pop("peer_network", None), "networks")
      if peer is None:
        peer = tokens.key_of(cfg.pop("peer_vpc_self_link", None), "networks")
      entries.append([vpc.key, pkey, peer, cfg, False])
  for i, e in enumerate(entries):
    if e[4]:
      continue
    partner = None
    for f in entries[i + 1:]:
      if not f[4] and f[0] == e[2] and f[2] == e[0]:
        partner = f
        break
    e[4] = True
    a = {"vpc": e[0], "key": e[1], **e[3]}
    if partner:
      partner[4] = True
      b = {"vpc": partner[0], "key": partner[1], **partner[3]}
    else:
      b = {"vpc": e[2], "key": None}
    ir.links.append(Link(id=f"peering:{e[0]}/{e[1]}", type="peering", a=a, b=b))
  # pair GCP-to-GCP VPNs
  seen = set()
  for vpc in ir.vpcs.values():
    for gw in vpc.vpns:
      peer = gw.extra.pop("_peer_vpn", None)
      if not peer:
        continue
      me = (vpc.key, gw.name)
      other = (peer[0], peer[1])
      if other in seen:
        continue
      seen.add(me)
      ir.links.append(
          Link(id=f"vpn:{vpc.key}/{gw.name}", type="vpn",
               a={"vpc": vpc.key, "name": gw.name},
               b={"vpc": peer[0], "name": peer[1]}))


def _derive_sites(ir):
  for link in ir.links:
    if link.type in ("vpn", "vlan") and "site" in link.b:
      site = ir.sites.setdefault(link.b["site"], Site(key=link.b["site"]))
      vpc = ir.vpcs.get(link.a["vpc"])
      if not vpc:
        continue
      if link.type == "vlan":
        att = next(
            (x for x in vpc.vlan_attachments if x.name == link.a["name"]), None)
        if att and att.peer_asn is not None and site.asn is None:
          site.asn = att.peer_asn
      else:
        gw = next((x for x in vpc.vpns if x.name == link.a["name"]), None)
        if gw:
          for t in gw.tunnels.values():
            asn = ((t or {}).get("bgp_peer") or {}).get("asn")
            if asn is not None and site.asn is None:
              site.asn = asn


def _import_opaque(ir, root):
  """Every YAML file outside the modelled set, as plain data."""
  modelled = {"defaults.yaml"}
  for sub in ("projects", "ncc-hubs", "nvas"):
    for p in _yaml_files(root / sub):
      modelled.add(str(p.relative_to(root)))
  vpcs = root / "vpcs"
  if vpcs.is_dir():
    for vpc_dir in vpcs.iterdir():
      if not vpc_dir.is_dir():
        continue
      modelled.add(str((vpc_dir / ".config.yaml").relative_to(root)))
      for sub in ("subnets", "vpns", "vlan-attachments"):
        for p in _yaml_files(vpc_dir / sub):
          modelled.add(str(p.relative_to(root)))
  for p in sorted(root.rglob("*.yaml")):
    rel = str(p.relative_to(root))
    if rel in modelled:
      continue
    ir.opaque[rel] = _load(p)
