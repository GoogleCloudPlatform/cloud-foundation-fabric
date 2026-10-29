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

The resulting `IR` keeps a stable ordering:

- files are read in sorted relative-path order, YAML keys keep document
  order;
- `links` are appended in import order: site VPNs and VLANs while reading
  each VPC (with NCC spokes from VPC / VPN / VLAN configs interleaved as they
  are met), then NCC spokes from NVAs, then paired peerings, then paired
  GCP-to-GCP VPNs;
- `opaque` captures every YAML file outside the modelled set (e.g. `dns/**`).

File discovery follows the stage Terraform:

- projects: `projects/**/*.yaml` (minus `*.config.yaml`) and
  `folders/**/*.yaml` (minus `.config.yaml`), keyed by file basename
  (`modules/project-factory/projects.tf`); a duplicate basename is a
  Terraform error and is reported with a `DatasetWarning` (last file wins);
- VPCs: every directory below `vpcs/` that contains a `.config.yaml`, keyed
  by its relative path (`factory-vpcs.tf`); directories without one and
  symlinked directories are ignored;
- per-VPC factories (`subnets`, `firewall_rules`, `vpns`,
  `vlan_attachments`, `attachment_groups`) read `**/*.yaml` from the path in
  the VPC's `factories_config` (default: the kebab-case directory in the VPC
  directory); subnets are keyed by file basename (`modules/net-vpc/
  subnets.tf`);
- `ncc-hubs/**/*.yaml` and `nvas/**/*.yaml`, keyed by relative path without
  extension.

Every file is read through `yamlio.load` (YAML 1.2 scalars, string keys).
Documents Terraform merges into objects must be mappings; anything else
raises `DatasetError`. Dataset strings never cause reads outside the
dataset directory.
"""

import dataclasses
from dataclasses import dataclass, field
import pathlib

from .. import tokens, yamlio
from .base import resolve_dataset_path

__all__ = [
    "IR",
    "Link",
    "NccHub",
    "Nic",
    "Nva",
    "Project",
    "Site",
    "Subnet",
    "VPC_FACTORIES",
    "Vpc",
    "VlanAttachment",
    "VpnGateway",
    "load_dataset",
]

# Keys of each file type that the model owns; everything else lands in `extra`.
VPC_OWNED = frozenset({
    "project_id", "name", "description", "mtu", "routing_mode",
    "delete_default_routes_on_create", "routers", "nat_config", "routes",
    "peering_config", "ncc_config", "factories_config"
})
SUBNET_OWNED = frozenset({
    "name", "region", "ip_cidr_range", "description", "proxy_only", "psc",
    "enable_private_access"
})
VPN_OWNED = frozenset({
    "name", "region", "peer_gateways", "router_config", "tunnels",
    "ncc_spoke_config"
})
VLAN_OWNED = frozenset(
    {"name", "region", "router_config", "peer_asn", "ncc_spoke_config"})
NCC_HUB_OWNED = frozenset({
    "name", "project_id", "description", "preset_topology", "export_psc",
    "groups"
})
NVA_OWNED = frozenset({
    "project_id", "name", "region", "auto_instance_config", "ilb_config",
    "ncc_ra_config"
})
DEFAULTS_OWNED = frozenset({"context", "vpcs"})

# Per-VPC factories: `factories_config` key -> default directory name.
VPC_FACTORIES = {
    "subnets": "subnets",
    "firewall_rules": "firewall-rules",
    "vpns": "vpns",
    "vlan_attachments": "vlan-attachments",
    "attachment_groups": "attachment-groups",
}


@dataclass
class Project:
  """One project-factory project file.

  `source_path` is the dataset-relative POSIX path of the file;
  `shared_vpc_host` is true when `shared_vpc_host_config.enabled` is true;
  `shared_vpc_service_of` is `shared_vpc_service_config.host_project`
  (the project key for a `$project_ids:<key>` token, else the raw string,
  `None` when absent); `extra` is the full raw document.
  """
  key: str
  source_path: str = ""
  name: str | None = None
  shared_vpc_host: bool = False
  shared_vpc_service_of: str | None = None
  reuse_id: str | None = None
  extra: dict = field(default_factory=dict)


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
  """One `vpcs/<vpc>/vpns/**/<name>.yaml`; the peer is on the `vpn` link."""
  name: str
  region: str | None = None
  router_config: dict | None = None
  tunnels: dict = field(default_factory=dict)
  peer_external: dict | None = None
  peer_key: str = "default"
  extra: dict = field(default_factory=dict)


@dataclass
class VlanAttachment:
  """One `vpcs/<vpc>/vlan-attachments/**/<name>.yaml`."""
  name: str
  region: str | None = None
  router_config: dict | None = None
  peer_asn: str | int | None = None
  extra: dict = field(default_factory=dict)


@dataclass
class Vpc:
  """One `vpcs/**/.config.yaml`; `key` is its directory relative to `vpcs/`.

  `factories_config` is the raw `factories_config` mapping of the VPC file.
  `disabled_factories` names the per-VPC factories (keys of
  `VPC_FACTORIES`) that are explicitly configured in `factories_config` but
  whose path does not resolve to an existing directory inside the dataset.
  In Fabric the configured value is a path (relative to the VPC directory
  unless it starts with `/` or `.`) handed to `fileset()`; a missing
  directory yields no files, so the factory creates nothing. `"none"` is the
  conventional value (`vlan_attachments: "none"`), but any missing path has
  the same effect. Files of a disabled factory are not loaded: they are not
  in `subnets` / `vpns` / `vlan_attachments` and produce no links or sites.
  """
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
  factories_config: dict = field(default_factory=dict)
  disabled_factories: frozenset[str] = frozenset()
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


# --- helpers ----------------------------------------------------------------


class _Ctx:
  """Per-load state: dataset root and the set of files modelled so far."""

  def __init__(self, root):
    self.root = root
    self.modelled = set()

  def rel(self, path):
    return path.relative_to(self.root).as_posix()

  def load(self, path):
    """Loads a document that must be a mapping and marks it modelled."""
    self.modelled.add(self.rel(path))
    return yamlio.load_mapping(path)


def _m(value, path, key):
  return yamlio.mapping(value, path, key)


def _basename_key(path):
  return path.name[:-len(".yaml")]


def _strip_keys(plain, keys):
  return {k: v for k, v in plain.items() if k not in keys}


def _project_key(value):
  return tokens.key_of(value, "project_ids") or value


def _split_last(key, parts):
  """`a/b/c/d` with parts=3 -> ['a/b', 'c', 'd'] (VPC keys may nest)."""
  pieces = key.rsplit("/", parts - 1)
  return pieces if len(pieces) == parts and all(pieces) else None


# --- import -----------------------------------------------------------------


def load_dataset(dataset_dir):
  """Reads a `2-networking` dataset directory into an `IR`."""
  root = pathlib.Path(dataset_dir).resolve()
  if not root.is_dir():
    raise FileNotFoundError(f"Dataset directory not found: {root}")
  ctx = _Ctx(root)
  ir = IR()
  _import_defaults(ir, ctx)
  _import_projects(ir, ctx)
  for key, cfg in yamlio.config_dirs(root / "vpcs", within=root):
    _import_vpc(ir, ctx, key, cfg)
  for path in yamlio.rglob_yaml(root / "ncc-hubs", within=root):
    _import_ncc_hub(ir, ctx, path)
  for path in yamlio.rglob_yaml(root / "nvas", within=root):
    _import_nva(ir, ctx, path)
  _derive_peerings(ir)
  _derive_sites(ir)
  _import_opaque(ir, ctx)
  ir.mode = "fast" if ir.projects else "standalone"
  return ir


def _import_defaults(ir, ctx):
  path = ctx.root / "defaults.yaml"
  if not path.is_file():
    return
  plain = ctx.load(path)
  context = _m(plain.get("context"), path, "context")
  vpcs = _m(plain.get("vpcs"), path, "vpcs")
  ir.defaults = {
      "locations": _m(context.get("locations"), path, "context.locations"),
      "cidr_ranges_sets": context.get("cidr_ranges_sets", {}) or {},
      "context_extra": _strip_keys(context, {"locations", "cidr_ranges_sets"}),
      "vpc_defaults": _m(vpcs.get("defaults"), path, "vpcs.defaults"),
      "vpcs_extra": _strip_keys(vpcs, {"defaults"}),
      "extra": _strip_keys(plain, DEFAULTS_OWNED),
  }


def _project_files(root):
  """`(path, source_path)` per project file, Fabric merge order."""
  out = []
  folders = root / "folders"
  for path in yamlio.rglob_yaml(folders, within=root):
    out.append((path, "folders/" + path.relative_to(folders).as_posix()))
  projects = root / "projects"
  for path in yamlio.rglob_yaml(projects, within=root):
    if not path.name.endswith(".config.yaml"):
      out.append((path, "projects/" + path.relative_to(projects).as_posix()))
  return out


def _import_projects(ir, ctx):
  seen = {}
  for path, src in _project_files(ctx.root):
    doc = ctx.load(path)
    key = _basename_key(path)
    if key in seen:
      yamlio.warn(f"{ctx.root}: project key {key!r} is defined by both "
                  f"{seen[key]} and {src}; Terraform fails on duplicate "
                  f"project keys, the diagram keeps {src}")
    seen[key] = src
    host_cfg = doc.get("shared_vpc_host_config")
    svc_cfg = doc.get("shared_vpc_service_config")
    host_project = svc_cfg.get("host_project") if isinstance(svc_cfg,
                                                             dict) else None
    ir.projects[key] = Project(
        key=key,
        source_path=src,
        name=doc.get("name"),
        shared_vpc_host=bool(
            isinstance(host_cfg, dict) and host_cfg.get("enabled") is True),
        shared_vpc_service_of=(None if host_project is None else str(
            _project_key(host_project))),
        extra=doc,
    )
  # Keep a deterministic key order independent of folders/projects order.
  ir.projects = {k: ir.projects[k] for k in sorted(ir.projects)}


def _factory_dirs(ctx, vpc_dir, cfg_path, fc):
  """`({factory: dir_or_None}, disabled)` for one VPC's factories_config."""
  dirs = {}
  disabled = set()
  for name, default in VPC_FACTORIES.items():
    value = fc.get(name)
    if not isinstance(value, str):  # Fabric: try(...) falls back to default
      dirs[name] = vpc_dir / default
      continue
    resolved = resolve_dataset_path(ctx.root, value, vpc_dir)
    if resolved is None:
      if value.strip() and value.strip().lower() != "none":
        yamlio.warn(f"{cfg_path}: factories_config.{name} {value!r} "
                    f"resolves outside the dataset; not read")
      dirs[name] = None
      disabled.add(name)
    elif not resolved.is_dir():
      dirs[name] = None
      disabled.add(name)
    else:
      dirs[name] = resolved
  return dirs, frozenset(disabled)


def _factory_files(ctx, directory):
  if directory is None:
    return []
  return yamlio.rglob_yaml(directory, within=ctx.root)


def _import_vpc(ir, ctx, key, config_path):
  vpc_dir = config_path.parent
  plain = ctx.load(config_path)
  fc = _m(plain.get("factories_config"), config_path, "factories_config")
  dirs, disabled = _factory_dirs(ctx, vpc_dir, config_path, fc)
  vpc = Vpc(
      key=key,
      project=_project_key(plain.get("project_id")),
      name=plain.get("name"),
      description=plain.get("description"),
      mtu=plain.get("mtu"),
      routing_mode=plain.get("routing_mode"),
      delete_default_routes_on_create=plain.get(
          "delete_default_routes_on_create"),
      routers=_m(plain.get("routers"), config_path, "routers"),
      nat=_m(plain.get("nat_config"), config_path, "nat_config"),
      routes=_m(plain.get("routes"), config_path, "routes"),
      factories_config=dict(fc),
      disabled_factories=disabled,
      extra=_strip_keys(plain, VPC_OWNED),
  )
  # peering_config and ncc_config are turned into links
  vpc.extra["_peering_config"] = _m(plain.get("peering_config"), config_path,
                                    "peering_config")
  vpc.extra["_config_path"] = config_path
  if plain.get("ncc_config"):
    _add_spoke(ir, plain["ncc_config"], {"vpc": key}, config_path, "ncc_config")
  for path in _factory_files(ctx, dirs["subnets"]):
    s = ctx.load(path)
    stem = _basename_key(path)
    name = s.get("name", stem)
    extra = _strip_keys(s, SUBNET_OWNED)
    if name != stem:
      extra = extra | {"_file": stem}
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
  for path in _factory_files(ctx, dirs["vpns"]):
    _import_vpn(ir, ctx, vpc, path)
  for path in _factory_files(ctx, dirs["vlan_attachments"]):
    _import_vlan(ir, ctx, vpc, path)
  ir.vpcs[key] = vpc


def _import_vpn(ir, ctx, vpc, path):
  v = ctx.load(path)
  stem = _basename_key(path)
  name = v.get("name", stem)
  gw = VpnGateway(
      name=name,
      region=v.get("region"),
      router_config=v.get("router_config"),
      tunnels=_m(v.get("tunnels"), path, "tunnels"),
      extra=_strip_keys(v, VPN_OWNED),
  )
  if name != stem:
    gw.extra["_file"] = stem
  peer_gateways = _m(v.get("peer_gateways"), path, "peer_gateways")
  peer_vpc = None
  peer_gcp = False
  for pk, pg in peer_gateways.items():
    gw.peer_key = pk
    gcp = pg.get("gcp") if isinstance(pg, dict) else None
    if isinstance(pg, dict) and gcp is not None:
      # A GCP peer is never an on-prem site, even if the token is malformed.
      peer_gcp = True
      gw_key = tokens.key_of(gcp, "vpn_gateways")
      peer_vpc = _split_last(gw_key, 2) if gw_key else None
      if peer_vpc is None:
        yamlio.warn(f"{path}: peer_gateways.{pk}.gcp {gcp!r} is not a "
                    f"$vpn_gateways:<vpc>/<name> token; no link drawn")
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
    _add_spoke(ir, v["ncc_spoke_config"], {"vpn": [vpc.key, name]}, path,
               "ncc_spoke_config")
  # GCP-to-GCP links are paired after all VPCs are read; stash the intent.
  if peer_vpc:
    gw.extra["_peer_vpn"] = peer_vpc
  elif not peer_gcp:
    ir.links.append(
        Link(id=f"vpn:{vpc.key}/{name}", type="vpn", a={
            "vpc": vpc.key,
            "name": name
        }, b={"site": _site_key(name)}))


def _import_vlan(ir, ctx, vpc, path):
  v = ctx.load(path)
  stem = _basename_key(path)
  name = v.get("name", stem)
  att = VlanAttachment(
      name=name,
      region=v.get("region"),
      router_config=v.get("router_config"),
      peer_asn=v.get("peer_asn"),
      extra=_strip_keys(v, VLAN_OWNED),
  )
  if name != stem:
    att.extra["_file"] = stem
  vpc.vlan_attachments.append(att)
  if v.get("ncc_spoke_config"):
    _add_spoke(ir, v["ncc_spoke_config"], {"vlan": [vpc.key, name]}, path,
               "ncc_spoke_config")
  ir.links.append(
      Link(id=f"vlan:{vpc.key}/{name}", type="vlan", a={
          "vpc": vpc.key,
          "name": name
      }, b={"site": _site_key(name)}))


def _site_key(name):
  """'to-onprem-vlan-0' -> 'onprem'; 'onprem' -> 'onprem'."""
  key = name
  if key.startswith("to-"):
    key = key[3:]
  for marker in ("-vlan-", "-attachment-", "-vpn-"):
    if marker in key:
      key = key.split(marker)[0]
  return key or name


def _import_ncc_hub(ir, ctx, path):
  h = ctx.load(path)
  key = yamlio.relative_key(path, ctx.root / "ncc-hubs")
  groups = {}
  for gname, g in _m(h.get("groups"), path, "groups").items():
    g = dict(_m(g, path, f"groups.{gname}"))
    g["auto_accept"] = [
        _project_key(p) for p in yamlio.sequence(g.get("auto_accept"), path,
                                                 f"groups.{gname}.auto_accept")
    ]
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


def _import_nva(ir, ctx, path):
  n = ctx.load(path)
  key = yamlio.relative_key(path, ctx.root / "nvas")
  aic = dict(_m(n.get("auto_instance_config"), path, "auto_instance_config"))
  ilb = dict(_m(n.get("ilb_config"), path, "ilb_config"))
  fr = yamlio.sequence(ilb.pop("forwarding_rules", None), path,
                       "ilb_config.forwarding_rules")
  fr_set = {
      (f.get("network"), f.get("subnet")) for f in fr if isinstance(f, dict)
  }
  nics = []
  raw_nics = yamlio.sequence(aic.pop("nics", None), path,
                             "auto_instance_config.nics")
  for i, nic in enumerate(raw_nics):
    nic = _m(nic, path, f"auto_instance_config.nics[{i}]")
    vpc_key = tokens.key_of(nic.get("network"),
                            "networks") or nic.get("network")
    sub = tokens.key_of(nic.get("subnet"), "subnets")
    parts = _split_last(sub, 3) if sub else None
    if parts is None and nic.get("subnet") is not None:
      yamlio.warn(f"{path}: auto_instance_config.nics[{i}].subnet "
                  f"{nic.get('subnet')!r} is not a "
                  f"$subnets:<vpc>/<region>/<name> token; region unknown")
    nics.append(
        Nic(
            vpc=vpc_key,
            subnet=parts[2] if parts else nic.get("subnet"),
            region=parts[1] if parts else None,
            routes=nic.get("routes", []) or [],
            masquerade=nic.get("masquerade"),
            ilb=(nic.get("network"), nic.get("subnet")) in fr_set,
            extra=_strip_keys(nic,
                              {"network", "subnet", "routes", "masquerade"}),
        ))
  ra = dict(_m(n.get("ncc_ra_config"), path, "ncc_ra_config"))
  spokes = yamlio.sequence(ra.pop("spokes", None), path, "ncc_ra_config.spokes")
  for i, spoke in enumerate(spokes):
    spoke = dict(_m(spoke, path, f"ncc_ra_config.spokes[{i}]"))
    vpc_key = tokens.key_of(spoke.pop("network", None), "networks")
    _add_spoke(ir, spoke, {
        "nva": key,
        "vpc": vpc_key
    }, path, f"ncc_ra_config.spokes[{i}]")
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


def _add_spoke(ir, cfg, target, path, key):
  cfg = dict(_m(cfg, path, key))
  hub = tokens.key_of(cfg.pop("hub", None), "ncc_hubs")
  group_tok = tokens.key_of(cfg.pop("group", None), "ncc_groups")
  group = None
  if group_tok:
    parts = _split_last(group_tok, 2)
    group = parts[1] if parts else group_tok
  tkey = "/".join(
      str(v) if not isinstance(v, list) else "/".join(v)
      for v in target.values())
  ir.links.append(
      Link(id=f"ncc_spoke:{hub}:{tkey}", type="ncc_spoke", a={
          "hub": hub,
          "group": group
      }, b=target, attrs=cfg))


def _derive_peerings(ir):
  """Pairs peering_config entries into links (unpaired: half links)."""
  entries = []  # [vpc, key, peer_vpc, flags, consumed]
  for vpc in ir.vpcs.values():
    path = vpc.extra.pop("_config_path", None)
    for pkey, cfg in vpc.extra.pop("_peering_config", {}).items():
      cfg = dict(_m(cfg, path, f"peering_config.{pkey}"))
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
      if peer[0] not in ir.vpcs:
        yamlio.warn(f"VPN {vpc.key}/{gw.name}: peer VPC {peer[0]!r} is not "
                    f"in the dataset; no link drawn")
        continue
      me = (vpc.key, gw.name)
      other = (peer[0], peer[1])
      if other in seen:
        continue
      seen.add(me)
      ir.links.append(
          Link(id=f"vpn:{vpc.key}/{gw.name}", type="vpn", a={
              "vpc": vpc.key,
              "name": gw.name
          }, b={
              "vpc": peer[0],
              "name": peer[1]
          }))


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
            bgp = t.get("bgp_peer") if isinstance(t, dict) else None
            asn = bgp.get("asn") if isinstance(bgp, dict) else None
            if asn is not None and site.asn is None:
              site.asn = asn


def _import_opaque(ir, ctx):
  """Every YAML file outside the modelled set, as plain data."""
  for p in yamlio.rglob_yaml(ctx.root, include_hidden=True, within=ctx.root):
    rel = ctx.rel(p)
    if rel in ctx.modelled:
      continue
    ir.opaque[rel] = yamlio.load(p)
