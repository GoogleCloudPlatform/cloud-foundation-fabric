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
"""Loader for FAST 1-vpcsc YAML datasets with symbolic set resolution.

Access levels, ingress / egress policies and perimeters are read from
`<dir>/**/*.yaml` and keyed by their relative path without extension
(`perimeters/prod/landing.yaml` -> `prod/landing`), like
`modules/vpc-sc/factory.tf`. Defaults follow that file too, e.g.
`vpc_accessible_services.allow_all_restricted_services` defaults to `true`.
"""

from dataclasses import dataclass, field
import pathlib
from typing import Any, Dict, List, Optional, Tuple

from .. import tokens, yamlio
from ..yamlio import DatasetError
from .base import _display_name
from .org_setup import OrgSetupDataset, load_org_setup_dataset


def _parse_token(val: Any) -> Optional[Tuple[str, str]]:
  if not isinstance(val, str):
    return None
  return tokens.parse(val.strip())


def _load_yaml_file(path: pathlib.Path) -> Any:
  return yamlio.load_or_empty(path)


def _factory_docs(root: pathlib.Path, name: str) -> List[Tuple[str, Any]]:
  """`(key, doc)` for `<root>/<name>/**/*.yaml`, key = relative path."""
  directory = root / name
  return [(yamlio.relative_key(p, directory), yamlio.load(p))
          for p in yamlio.rglob_yaml(directory, within=root)]


def _m(value: Any, path: Any, key: str) -> dict:
  return yamlio.mapping(value, path, key)


def _strs(value: Any) -> List[str]:
  if value is None:
    return []
  if isinstance(value, list):
    return [str(x) for x in value]
  return [str(value)]


@dataclass
class SetRef:
  raw: str
  namespace: str
  key: str
  members: Optional[List[str]] = None
  provenance: str = "literal"
  subtitle: str = ""
  unresolved: bool = False


@dataclass
class AccessLevelSpec:
  key: str
  combining_function: str = "AND"
  regions: List[str] = field(default_factory=list)
  ip_subnetworks: List[str] = field(default_factory=list)
  members: List[str] = field(default_factory=list)
  required_access_levels: List[str] = field(default_factory=list)
  has_device_policy: bool = False
  vpc_subnets_count: int = 0
  negate: bool = False
  summary: str = ""


@dataclass
class OperationSpec:
  service_name: str
  method_selectors: List[str] = field(default_factory=list)
  permission_selectors: List[str] = field(default_factory=list)


@dataclass
class IngressPolicySpec:
  """One ingress policy.

  `from_identity_type` is `from.identity_type` (`ANY_IDENTITY`,
  `ANY_USER_ACCOUNT`, `ANY_SERVICE_ACCOUNT`) or `None`;
  `from_psc_endpoints` is `from.psc_endpoints`.
  """
  key: str
  from_access_levels: List[str] = field(default_factory=list)
  from_identities: List[str] = field(default_factory=list)
  from_identity_type: Optional[str] = None
  from_psc_endpoints: List[str] = field(default_factory=list)
  from_resources: List[str] = field(default_factory=list)
  to_resources: List[str] = field(default_factory=list)
  to_operations: List[OperationSpec] = field(default_factory=list)
  to_roles: List[str] = field(default_factory=list)
  ops_summary: str = ""


@dataclass
class EgressPolicySpec:
  """One egress policy; `from_*` fields as on `IngressPolicySpec`."""
  key: str
  from_access_levels: List[str] = field(default_factory=list)
  from_identities: List[str] = field(default_factory=list)
  from_identity_type: Optional[str] = None
  from_psc_endpoints: List[str] = field(default_factory=list)
  from_resources: List[str] = field(default_factory=list)
  to_resources: List[str] = field(default_factory=list)
  to_external_resources: List[str] = field(default_factory=list)
  to_operations: List[OperationSpec] = field(default_factory=list)
  to_roles: List[str] = field(default_factory=list)
  ops_summary: str = ""


@dataclass
class VpcAccessibleServicesSpec:
  """`vpc_accessible_services` with `modules/vpc-sc/factory.tf` defaults."""
  enable_restriction: bool = True
  allow_all_restricted_services: bool = True
  allowed_services: List[str] = field(default_factory=list)


@dataclass
class PerimeterBlockSpec:
  mode: str  # "status" or "spec"
  access_levels: List[str] = field(default_factory=list)
  resources: List[str] = field(default_factory=list)
  restricted_services: List[str] = field(default_factory=list)
  ingress_policies: List[str] = field(default_factory=list)
  egress_policies: List[str] = field(default_factory=list)
  vpc_accessible_services: Optional[VpcAccessibleServicesSpec] = None


@dataclass
class PerimeterSpec:
  key: str
  title: str = ""
  description: str = ""
  use_explicit_dry_run_spec: bool = False
  ignore_resource_changes: bool = False
  status: Optional[PerimeterBlockSpec] = None
  spec: Optional[PerimeterBlockSpec] = None
  has_both_equal: bool = False
  has_both_different: bool = False


@dataclass
class VpcscDataset:
  dataset_name: str
  root_dir: pathlib.Path
  org_dataset: Optional[OrgSetupDataset] = None
  context: Dict[str, Dict[str, Any]] = field(default_factory=dict)
  restricted_services: List[str] = field(default_factory=list)
  access_levels: Dict[str, AccessLevelSpec] = field(default_factory=dict)
  ingress_policies: Dict[str, IngressPolicySpec] = field(default_factory=dict)
  egress_policies: Dict[str, EgressPolicySpec] = field(default_factory=dict)
  perimeters: Dict[str, PerimeterSpec] = field(default_factory=dict)
  resolved_sets: Dict[str, SetRef] = field(default_factory=dict)
  unresolved_refs: List[SetRef] = field(default_factory=list)

  def resolve_token(self, token_str: str) -> SetRef:
    if token_str in self.resolved_sets:
      return self.resolved_sets[token_str]
    ref = resolve_symbolic_ref(
        token_str,
        context=self.context,
        restricted_services=self.restricted_services,
        access_levels=self.access_levels,
        ingress_policies=self.ingress_policies,
        egress_policies=self.egress_policies,
        org_dataset=self.org_dataset,
    )
    self.resolved_sets[token_str] = ref
    if ref.unresolved and all(u.raw != ref.raw for u in self.unresolved_refs):
      self.unresolved_refs.append(ref)
    return ref


def _summarize_members(members: List[str], limit: int = 3) -> str:
  if not members:
    return "empty"
  if len(members) <= limit:
    return ", ".join(members)
  shown = ", ".join(members[:limit])
  return f"{shown}, +{len(members) - limit}"


def resolve_symbolic_ref(
    raw: str,
    context: Dict[str, Dict[str, Any]],
    restricted_services: List[str],
    access_levels: Dict[str, AccessLevelSpec],
    ingress_policies: Dict[str, IngressPolicySpec],
    egress_policies: Dict[str, EgressPolicySpec],
    org_dataset: Optional[OrgSetupDataset] = None,
) -> SetRef:
  """Resolves a symbolic `$ns:key` reference to a `SetRef`.

  Order: `defaults.yaml` context entries (except the always stage-generated
  `identity_sets.logging_identities`), then the sets the 1-vpcsc stage
  generates (optionally enriched by an org-setup dataset), then the
  dataset's own access levels and policies; anything else is unresolved.
  """
  s = str(raw).strip()
  tok = _parse_token(s)
  if not tok:
    return SetRef(
        raw=s,
        namespace="literal",
        key=s,
        members=[s],
        provenance="literal",
        subtitle=s,
        unresolved=False,
    )

  ns, key = tok

  # 1. Check defaults.yaml context.<ns>.<key> first if explicitly defined.
  # Exception: the stage always generates identity_sets.logging_identities
  # and merges it over the context (fast/stages/1-vpcsc/main.tf).
  ctx_ns = context.get(ns) or {}
  stage_wins = ns == "identity_sets" and key == "logging_identities"
  if key in ctx_ns and not stage_wins:
    val = ctx_ns[key]
    members = [str(x) for x in val] if isinstance(val, list) else [str(val)]
    return SetRef(
        raw=s,
        namespace=ns,
        key=key,
        members=members,
        provenance="defaults-context",
        subtitle=f"context.{ns}: {_summarize_members(members)}",
        unresolved=False,
    )

  # 2. Built-in stage-generated sets & optional --org-dataset enrichment
  if ns == "resource_sets" and key == "discovered_projects":
    return SetRef(
        raw=s,
        namespace=ns,
        key=key,
        members=None,
        provenance="stage-generated",
        subtitle="asset-inventory discovery · state:ACTIVE · org-wide",
        unresolved=False,
    )

  if ns == "resource_sets" and key == "logging_project":
    if org_dataset is not None:
      sink_projs: List[str] = []
      for sk in org_dataset.organization.sinks:
        if sk.target_project and sk.target_project not in sink_projs:
          sink_projs.append(sk.target_project)
      if not sink_projs and org_dataset.organization.observability_project_key:
        sink_projs.append(org_dataset.organization.observability_project_key)
      if sink_projs:
        sub = f"{', '.join(sink_projs)} (via --org-dataset)"
        return SetRef(
            raw=s,
            namespace=ns,
            key=key,
            members=sink_projs,
            provenance="org-dataset",
            subtitle=sub,
            unresolved=False,
        )
    return SetRef(
        raw=s,
        namespace=ns,
        key=key,
        members=None,
        provenance="stage-generated",
        subtitle="project hosting 0-org-setup sink destinations",
        unresolved=False,
    )

  if ns == "resource_sets" and key == "org_setup_projects":
    if org_dataset is not None and org_dataset.projects:
      pkeys = list(org_dataset.projects.keys())
      return SetRef(
          raw=s,
          namespace=ns,
          key=key,
          members=pkeys,
          provenance="org-dataset",
          subtitle=f"{_summarize_members(pkeys)} (via --org-dataset)",
          unresolved=False,
      )
    return SetRef(
        raw=s,
        namespace=ns,
        key=key,
        members=None,
        provenance="stage-generated",
        subtitle="all projects created by 0-org-setup",
        unresolved=False,
    )

  if ns == "identity_sets" and key == "logging_identities":
    if org_dataset is not None and org_dataset.organization.sinks:
      snames = [sk.name for sk in org_dataset.organization.sinks]
      return SetRef(
          raw=s,
          namespace=ns,
          key=key,
          members=snames,
          provenance="org-dataset",
          subtitle=f"writers of {len(snames)} sinks: {', '.join(snames)}",
          unresolved=False,
      )
    return SetRef(
        raw=s,
        namespace=ns,
        key=key,
        members=None,
        provenance="stage-generated",
        subtitle="writer identities of org log sinks",
        unresolved=False,
    )

  if ns == "service_sets" and key == "restricted_services":
    short_names = [
        svc.removesuffix(".googleapis.com") for svc in restricted_services
    ]
    return SetRef(
        raw=s,
        namespace=ns,
        key=key,
        members=list(restricted_services),
        provenance="stage-generated",
        subtitle=_summarize_members(short_names, limit=3),
        unresolved=False,
    )

  if ns == "iam_principals" and key.startswith("service_agents/org/"):
    agent_name = key.removeprefix("service_agents/org/")
    return SetRef(
        raw=s,
        namespace=ns,
        key=key,
        members=[agent_name],
        provenance="stage-generated",
        subtitle=f"org service agent {agent_name}",
        unresolved=False,
    )

  if ns == "iam_principals" and key.startswith("service_accounts/"):
    sa_path = key.removeprefix("service_accounts/")
    return SetRef(
        raw=s,
        namespace=ns,
        key=key,
        members=[sa_path],
        provenance="stage-generated",
        subtitle=f"service account {sa_path}",
        unresolved=False,
    )

  if ns == "access_levels" and key in access_levels:
    al = access_levels[key]
    return SetRef(
        raw=s,
        namespace=ns,
        key=key,
        members=[key],
        provenance="stage-generated",
        subtitle=al.summary,
        unresolved=False,
    )

  if ns == "ingress_policies" and key in ingress_policies:
    return SetRef(
        raw=s,
        namespace=ns,
        key=key,
        members=[key],
        provenance="stage-generated",
        subtitle=ingress_policies[key].ops_summary,
        unresolved=False,
    )

  if ns == "egress_policies" and key in egress_policies:
    return SetRef(
        raw=s,
        namespace=ns,
        key=key,
        members=[key],
        provenance="stage-generated",
        subtitle=egress_policies[key].ops_summary,
        unresolved=False,
    )

  if (ns == "project_numbers" and org_dataset is not None and
      key in org_dataset.projects):
    proj = org_dataset.projects[key]
    return SetRef(
        raw=s,
        namespace=ns,
        key=key,
        members=[key],
        provenance="org-dataset",
        subtitle=f"{proj.name} (via --org-dataset)",
        unresolved=False,
    )

  if (ns == "folder_ids" and org_dataset is not None and
      key in org_dataset.folders):
    fld = org_dataset.folders[key]
    return SetRef(
        raw=s,
        namespace=ns,
        key=key,
        members=[key],
        provenance="org-dataset",
        subtitle=f"folder {fld.name} (via --org-dataset)",
        unresolved=False,
    )

  if ns == "organization_ids" and key == "default":
    org_id = org_dataset.organization.id if org_dataset else "default"
    return SetRef(
        raw=s,
        namespace=ns,
        key=key,
        members=[org_id],
        provenance="org-dataset" if org_dataset else "stage-generated",
        subtitle=f"organizations/{org_id}",
        unresolved=False,
    )

  # Unknown $ns:key -> unresolved
  return SetRef(
      raw=s,
      namespace=ns,
      key=key,
      members=None,
      provenance="unresolved",
      subtitle=f"{ns}: {key} (unresolved)",
      unresolved=True,
  )


def _parse_operations(ops_raw: Any) -> Tuple[List[OperationSpec], str]:
  if not isinstance(ops_raw, list):
    return [], "no operations"
  ops: List[OperationSpec] = []
  has_wildcard = False
  has_methods = False
  services: List[str] = []
  for item in ops_raw:
    if not isinstance(item, dict):
      continue
    sname = str(item.get("service_name") or "")
    m_sel = [str(x) for x in (item.get("method_selectors") or [])]
    p_sel = [str(x) for x in (item.get("permission_selectors") or [])]
    if sname == "*":
      has_wildcard = True
    elif sname:
      services.append(sname.removesuffix(".googleapis.com"))
    if m_sel or p_sel:
      has_methods = True
    ops.append(
        OperationSpec(
            service_name=sname,
            method_selectors=m_sel,
            permission_selectors=p_sel,
        ))
  if has_wildcard:
    summary = "all services"
  elif len(services) == 1:
    summary = services[0]
  elif services:
    summary = f"{len(services)} services"
  else:
    summary = "no services"
  if has_methods:
    summary += " (method selectors)"
  return ops, summary


def _default_true(value: Any) -> bool:
  return True if value is None else bool(value)


def _parse_perimeter_block(mode: str, raw: Any) -> Optional[PerimeterBlockSpec]:
  if not isinstance(raw, dict):
    return None
  vas_raw = raw.get("vpc_accessible_services")
  vas: Optional[VpcAccessibleServicesSpec] = None
  if isinstance(vas_raw, dict):
    vas = VpcAccessibleServicesSpec(
        enable_restriction=_default_true(vas_raw.get("enable_restriction")),
        allow_all_restricted_services=_default_true(
            vas_raw.get("allow_all_restricted_services")),
        allowed_services=_strs(vas_raw.get("allowed_services")),
    )
  return PerimeterBlockSpec(
      mode=mode,
      access_levels=_strs(raw.get("access_levels")),
      resources=_strs(raw.get("resources")),
      restricted_services=_strs(raw.get("restricted_services")),
      ingress_policies=_strs(raw.get("ingress_policies")),
      egress_policies=_strs(raw.get("egress_policies")),
      vpc_accessible_services=vas,
  )


def _conditions(value: Any) -> List[Any]:
  """`for c in try(v.conditions, [])`: a list, or the values of a map."""
  if isinstance(value, dict):
    return list(value.values())
  return value if isinstance(value, list) else []


def _parse_access_level(key: str, adoc: Any) -> AccessLevelSpec:
  if not isinstance(adoc, dict):
    adoc = {}
  comb = str(adoc.get("combining_function") or "AND")
  regions: List[str] = []
  ips: List[str] = []
  members: List[str] = []
  req_als: List[str] = []
  has_dev = False
  vpc_sub_cnt = 0
  negate = False
  for cond in _conditions(adoc.get("conditions")):
    if not isinstance(cond, dict):
      continue
    regions.extend(_strs(cond.get("regions")))
    ips.extend(_strs(cond.get("ip_subnetworks")))
    members.extend(_strs(cond.get("members")))
    req_als.extend(_strs(cond.get("required_access_levels")))
    if cond.get("device_policy"):
      has_dev = True
    if isinstance(cond.get("vpc_subnets"), dict):
      vpc_sub_cnt += len(cond["vpc_subnets"])
    if cond.get("negate"):
      negate = True

  parts: List[str] = []
  if regions:
    parts.append(f"regions: {', '.join(regions)}")
  if ips:
    parts.append(f"ip: {len(ips)} ranges" if len(ips) > 1 else f"ip: {ips[0]}")
  if members:
    parts.append(f"members: {len(members)}")
  if has_dev:
    parts.append("device policy")
  if req_als:
    clean_reqs = [r.removeprefix("$access_levels:") for r in req_als]
    parts.append(f"required: {', '.join(clean_reqs)}")
  if vpc_sub_cnt:
    parts.append(f"vpc subnets: {vpc_sub_cnt}")
  if negate:
    parts.append("negated")
  if comb != "AND":
    parts.append(f"combining: {comb}")
  return AccessLevelSpec(
      key=key,
      combining_function=comb,
      regions=regions,
      ip_subnetworks=ips,
      members=members,
      required_access_levels=req_als,
      has_device_policy=has_dev,
      vpc_subnets_count=vpc_sub_cnt,
      negate=negate,
      summary=" · ".join(parts) if parts else "custom condition",
  )


def _policy_parts(root: pathlib.Path, kind: str, key: str, doc: Any):
  """`(from, to, identity_type)` mappings of a policy document."""
  path = root / kind / f"{key}.yaml"
  if not isinstance(doc, dict):
    doc = {}
  frm = _m(doc.get("from"), path, "from")
  to = _m(doc.get("to"), path, "to")
  identity_type = frm.get("identity_type")
  if identity_type is not None and not isinstance(identity_type, str):
    raise DatasetError(path, "from.identity_type", "expected a string")
  return frm, to, identity_type


def _blocks_equal(a: Optional[PerimeterBlockSpec],
                  b: Optional[PerimeterBlockSpec]) -> bool:
  if a is None or b is None:
    return False
  return (a.access_levels == b.access_levels and a.resources == b.resources and
          a.restricted_services == b.restricted_services and
          a.ingress_policies == b.ingress_policies and
          a.egress_policies == b.egress_policies and
          a.vpc_accessible_services == b.vpc_accessible_services)


def load_vpcsc_dataset(
    dataset_dir: pathlib.Path | str,
    org_dataset_dir: Optional[pathlib.Path | str | OrgSetupDataset] = None,
    strict: bool = False,
) -> VpcscDataset:
  """Loads a FAST 1-vpcsc dataset directory into a VpcscDataset model."""
  root = pathlib.Path(dataset_dir).resolve()
  if not root.is_dir():
    raise FileNotFoundError(f"Dataset directory not found: {root}")

  org_ds: Optional[OrgSetupDataset] = None
  if isinstance(org_dataset_dir, OrgSetupDataset):
    org_ds = org_dataset_dir
  elif org_dataset_dir is not None:
    org_ds = load_org_setup_dataset(org_dataset_dir)

  defaults_path = root / "defaults.yaml"
  defaults_doc = _load_yaml_file(defaults_path)
  if not isinstance(defaults_doc, dict):
    defaults_doc = {}
  raw_ctx = _m(defaults_doc.get("context"), defaults_path, "context")
  context: Dict[str, Dict[str, Any]] = {}
  for ns, mapping in raw_ctx.items():
    if isinstance(mapping, dict):
      context[ns] = dict(mapping)

  # Restricted services list (an empty file is an empty list)
  rs_path = root / "restricted-services.yaml"
  rs_raw = _load_yaml_file(rs_path)
  if rs_raw == {}:
    rs_raw = []
  restricted_services = [str(s) for s in yamlio.sequence(rs_raw, rs_path, None)]

  access_levels: Dict[str, AccessLevelSpec] = {
      key: _parse_access_level(key, adoc)
      for key, adoc in _factory_docs(root, "access-levels")
  }

  ingress_policies: Dict[str, IngressPolicySpec] = {}
  for key, idoc in _factory_docs(root, "ingress-policies"):
    frm, to, identity_type = _policy_parts(root, "ingress-policies", key, idoc)
    ops, ops_sum = _parse_operations(to.get("operations"))
    ingress_policies[key] = IngressPolicySpec(
        key=key,
        from_access_levels=_strs(frm.get("access_levels")),
        from_identities=_strs(frm.get("identities")),
        from_identity_type=identity_type,
        from_psc_endpoints=_strs(frm.get("psc_endpoints")),
        from_resources=_strs(frm.get("resources")),
        to_resources=_strs(to.get("resources")),
        to_operations=ops,
        to_roles=_strs(to.get("roles")),
        ops_summary=ops_sum,
    )

  egress_policies: Dict[str, EgressPolicySpec] = {}
  for key, edoc in _factory_docs(root, "egress-policies"):
    frm, to, identity_type = _policy_parts(root, "egress-policies", key, edoc)
    ops, ops_sum = _parse_operations(to.get("operations"))
    egress_policies[key] = EgressPolicySpec(
        key=key,
        from_access_levels=_strs(frm.get("access_levels")),
        from_identities=_strs(frm.get("identities")),
        from_identity_type=identity_type,
        from_psc_endpoints=_strs(frm.get("psc_endpoints")),
        from_resources=_strs(frm.get("resources")),
        to_resources=_strs(to.get("resources")),
        to_external_resources=_strs(to.get("external_resources")),
        to_operations=ops,
        to_roles=_strs(to.get("roles")),
        ops_summary=ops_sum,
    )

  perimeters: Dict[str, PerimeterSpec] = {}
  for key, pdoc in _factory_docs(root, "perimeters"):
    if not isinstance(pdoc, dict):
      pdoc = {}
    status_blk = _parse_perimeter_block("status", pdoc.get("status"))
    spec_blk = _parse_perimeter_block("spec", pdoc.get("spec"))
    both_eq = _blocks_equal(status_blk, spec_blk)
    both_diff = (status_blk is not None and spec_blk is not None and
                 not both_eq)
    perimeters[key] = PerimeterSpec(
        key=key,
        title=str(pdoc.get("title") or ""),
        description=str(pdoc.get("description") or ""),
        use_explicit_dry_run_spec=bool(
            pdoc.get("use_explicit_dry_run_spec", False)),
        ignore_resource_changes=bool(pdoc.get("ignore_resource_changes",
                                              False)),
        status=status_blk,
        spec=spec_blk,
        has_both_equal=both_eq,
        has_both_different=both_diff,
    )

  ds = VpcscDataset(
      dataset_name=_display_name(dataset_dir, root),
      root_dir=root,
      org_dataset=org_ds,
      context=context,
      restricted_services=restricted_services,
      access_levels=access_levels,
      ingress_policies=ingress_policies,
      egress_policies=egress_policies,
      perimeters=perimeters,
  )

  # Pre-resolve all symbolic tokens referenced across perimeters and policies
  for perim in perimeters.values():
    for blk in (perim.status, perim.spec):
      if not blk:
        continue
      for r in blk.resources:
        ds.resolve_token(r)
      for al in blk.access_levels:
        ds.resolve_token(al)
      for rs in blk.restricted_services:
        ds.resolve_token(rs)
      for ip in blk.ingress_policies:
        ds.resolve_token(ip)
      for ep in blk.egress_policies:
        ds.resolve_token(ep)

  for ipol in ingress_policies.values():
    for al in ipol.from_access_levels:
      if al != "*":
        ds.resolve_token(al)
    for ident in ipol.from_identities:
      ds.resolve_token(ident)
    for res in ipol.from_resources:
      ds.resolve_token(res)
    for res in ipol.to_resources:
      if res != "*":
        ds.resolve_token(res)

  for epol in egress_policies.values():
    for al in epol.from_access_levels:
      if al != "*":
        ds.resolve_token(al)
    for ident in epol.from_identities:
      ds.resolve_token(ident)
    for res in epol.from_resources:
      ds.resolve_token(res)
    for res in epol.to_resources:
      if res != "*":
        ds.resolve_token(res)
    for eres in epol.to_external_resources:
      ds.resolve_token(eres)

  if strict and ds.unresolved_refs:
    names = ", ".join(u.raw for u in ds.unresolved_refs)
    raise ValueError(f"Unresolved symbolic references in strict mode: {names}")

  return ds


# Aliases for generic stage loader conventions
import_dataset = load_vpcsc_dataset
load = load_vpcsc_dataset
