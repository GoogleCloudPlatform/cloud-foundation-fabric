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
"""Loader for FAST 0-org-setup YAML datasets.

Factory locations follow `var.factories_config.paths` of the stage
(`fast/stages/0-org-setup/variables.tf`). A dataset cannot declare them (they
come from tfvars), so callers pass overrides with `paths=`; the defaults are
`DEFAULT_PATHS`. As in the stage, a value starting with `/` or `.` is used
as-is and anything else is relative to the dataset; unlike the stage, a path
that resolves outside the dataset directory is never read (a
`DatasetWarning` is emitted instead). `cicd_workflows` has no default, so
`cicd.yaml` is read only when `paths["cicd_workflows"]` is set.

Projects come from `folders/**/*.yaml` (minus `.config.yaml`; the folder is
the implicit parent) and `projects/**/*.yaml` (minus `*.config.yaml`), keyed
by basename (`modules/project-factory/projects.tf`). Terraform fails on a
duplicate basename; the loader keeps the last file in sorted order and emits
a `DatasetWarning`. All non-fatal problems use `warnings.warn` with
`DatasetWarning`; structural errors raise `DatasetError`.
"""

from dataclasses import dataclass, field
import pathlib
import posixpath
from typing import Any, Dict, List, Mapping, Optional, Tuple

from .. import tokens, yamlio
from ..yamlio import DatasetError
from .base import _display_name, resolve_dataset_path

_IAM_KEYS = (
    "iam",
    "iam_bindings",
    "iam_bindings_additive",
    "iam_by_principals",
    "iam_by_principals_additive",
    "iam_by_principals_conditional",
    "iam_deny_policies",
)

# `var.factories_config.paths` defaults of the 0-org-setup stage.
DEFAULT_PATHS: Dict[str, Optional[str]] = {
    "billing_accounts": "billing-accounts",
    "cicd_workflows": None,
    "defaults": "defaults.yaml",
    "folders": "folders",
    "observability": "observability",
    "organization": "organization",
    "project_templates": "templates",
    "projects": "projects",
    "vpcs": "vpcs",
}

# `modules/organization/variables-logging.tf` sink types.
SINK_TYPES = ("bigquery", "logging", "project", "pubsub", "storage")


def _parse_token(val: Any) -> Optional[Tuple[str, str]]:
  if not isinstance(val, str):
    return None
  return tokens.parse(val.strip())


@dataclass
class OrgSink:
  """One `organization/.config.yaml` `logging.sinks.<name>` entry.

  `sink_type` is the Fabric sink type, one of `SINK_TYPES`: the explicit
  `type` key, defaulting to `"logging"` (a log bucket) exactly like
  `modules/organization`. It decides how the destination is resolved, so it
  is the reliable field for picking the destination kind.
  `destination_kind` is the namespace of a `$<ns>:<key>` destination token
  (e.g. `log_buckets`, `project_ids`) or `""` for a literal destination.
  `target_project` / `target_resource` split the token key at the first `/`.
  """
  name: str
  destination: str
  sink_type: str = "logging"
  destination_kind: str = ""
  target_project: Optional[str] = None
  target_resource: Optional[str] = None
  filter: str = ""


@dataclass
class TagSpec:
  key: str
  description: str = ""
  values: List[str] = field(default_factory=list)


@dataclass
class BillingAccountSpec:
  key: str
  id: str
  iam_bindings_additive_count: int = 0
  iam_principals_count: int = 0
  logging_sinks: Dict[str, str] = field(default_factory=dict)


@dataclass
class CicdWorkflowSpec:
  name: str
  repo_name: str = ""
  repo_type: str = ""
  pool_project: Optional[str] = None
  pool_name: str = ""
  provider_name: str = ""
  apply_sa: str = ""
  plan_sa: str = ""


@dataclass
class EmbeddedSubnetSpec:
  name: str
  region: str
  ip_cidr_range: str
  description: str = ""


@dataclass
class EmbeddedVpcSpec:
  key: str
  name: str
  project_key: str
  subnets: List[EmbeddedSubnetSpec] = field(default_factory=list)
  ingress_rule_count: int = 0
  egress_rule_count: int = 0


@dataclass
class FolderSpec:
  """A folder (`folders/<key>/.config.yaml`) or an implicit folder.

  Parent fields (the same rules apply to `ProjectSpec`):

  - `parent_folder_key`: key of the parent folder in `folders`, `None` when
    the parent is the organization or outside the dataset;
  - `parent_external`: set when the parent is outside the dataset: a literal
    (`folders/123`, `organizations/<another org>`, any non-`$folder_ids`
    string) or a `$folder_ids:<key>` resolved through `context.folder_ids` in
    `defaults.yaml` (the context value, or the token when it is not a
    string). A builder should draw an external placeholder for it;
  - `parent`: the canonical raw parent (`$folder_ids:<key>` or the literal),
    `None` for the organization root.

  `implicit` folders are not defined by a `.config.yaml`: they are created
  for a `$folder_ids:<key>` parent (of a folder or project) that is neither a
  dataset folder nor in `context.folder_ids`, so the hierarchy keeps its
  depth; in Fabric such keys must come from the stage `context` variable.
  `level` is the directory depth of the key (Fabric's deployment level).
  """
  key: str
  name: str
  parent: Optional[str] = None
  parent_folder_key: Optional[str] = None
  parent_external: Optional[str] = None
  level: int = 1
  tag_bindings: Dict[str, str] = field(default_factory=dict)
  tag_pills: List[str] = field(default_factory=list)
  has_iam: bool = False
  iam_principals_count: int = 0
  org_policies_count: int = 0
  has_scc_sha: bool = False
  scc_sha_count: int = 0
  implicit: bool = False
  children_folders: List[str] = field(default_factory=list)
  children_projects: List[str] = field(default_factory=list)


@dataclass
class ProjectSpec:
  """One project file; parent fields as documented on `FolderSpec`.

  `shared_vpc_host` is true when `shared_vpc_host_config.enabled` is true;
  `shared_vpc_service_of` is `shared_vpc_service_config.host_project` (the
  project key for a `$project_ids:<key>` token, else the raw string).
  `observability_missing_path` is true when `factories_config.observability`
  is set but does not resolve to a directory inside the dataset.
  """
  key: str
  name: str
  descriptive_name: str = ""
  source_path: str = ""
  parent: Optional[str] = None
  parent_folder_key: Optional[str] = None
  parent_external: Optional[str] = None
  project_template: Optional[str] = None
  log_buckets: List[str] = field(default_factory=list)
  log_buckets_cmek: bool = False
  datasets: List[str] = field(default_factory=list)
  datasets_cmek: bool = False
  buckets: List[str] = field(default_factory=list)
  service_accounts: List[str] = field(default_factory=list)
  kms_keyrings: List[str] = field(default_factory=list)
  cmek_services: Dict[str, List[str]] = field(default_factory=dict)
  shared_vpc_host: bool = False
  shared_vpc_service_of: Optional[str] = None
  org_policies_count: int = 0
  has_observability_factory: bool = False
  observability_factory_path: Optional[str] = None
  observability_alerts_count: int = 0
  observability_metrics_count: int = 0
  observability_missing_path: bool = False
  is_observability_project: bool = False
  cicd_workflows: List[CicdWorkflowSpec] = field(default_factory=list)
  has_iam: bool = False
  iam_principals_count: int = 0
  services: List[str] = field(default_factory=list)
  vpcs: List[EmbeddedVpcSpec] = field(default_factory=list)


@dataclass
class OrganizationSpec:
  domain: str = ""
  id: str = ""
  customer_id: str = ""
  prefix: str = ""
  primary_location: str = ""
  billing_account_id: str = ""
  observability_project_key: Optional[str] = None
  org_policies_count: int = 0
  org_policy_files_count: int = 0
  custom_constraints_count: int = 0
  custom_constraint_keys: List[str] = field(default_factory=list)
  custom_roles_count: int = 0
  custom_role_names: List[str] = field(default_factory=list)
  scc_sha_modules_count: int = 0
  scc_sha_module_names: List[str] = field(default_factory=list)
  tags: List[TagSpec] = field(default_factory=list)
  tag_keys_count: int = 0
  tag_values_count: int = 0
  data_access_logs: List[str] = field(default_factory=list)
  contacts_count: int = 0
  sinks: List[OrgSink] = field(default_factory=list)


@dataclass
class OrgSetupDataset:
  dataset_name: str
  root_dir: pathlib.Path
  organization: OrganizationSpec
  folders: Dict[str, FolderSpec] = field(default_factory=dict)
  projects: Dict[str, ProjectSpec] = field(default_factory=dict)
  root_folder_keys: List[str] = field(default_factory=list)
  root_project_keys: List[str] = field(default_factory=list)
  billing_accounts: List[BillingAccountSpec] = field(default_factory=list)
  cicd_workflows: List[CicdWorkflowSpec] = field(default_factory=list)
  vpcs: Dict[str, EmbeddedVpcSpec] = field(default_factory=dict)
  locations: Dict[str, str] = field(default_factory=dict)

  def resolve_region(self, value: str) -> str:
    tok = _parse_token(value)
    if tok and tok[0] == "locations":
      return self.locations.get(tok[1], value)
    return value


# --- helpers ----------------------------------------------------------------


class _Loader:
  """Per-load state: dataset root, organization id and folder context."""

  def __init__(self, root: pathlib.Path):
    self.root = root
    self.org_id = ""
    self.ctx_folder_ids: Dict[str, Any] = {}

  def path(self, value: Optional[str], what: str) -> Optional[pathlib.Path]:
    """A dataset path (stage or factory rule), `None` when unusable."""
    resolved = resolve_dataset_path(self.root, value, self.root)
    if resolved is None and isinstance(value, str) and value.strip():
      yamlio.warn(f"{self.root}: {what} {value!r} resolves outside the "
                  f"dataset; not read")
    return resolved

  def rel(self, path: pathlib.Path) -> str:
    return path.relative_to(self.root).as_posix()


def _m(value: Any, path: Any, key: Optional[str]) -> dict:
  return yamlio.mapping(value, path, key)


def _load_mapping_or_empty(path: Optional[pathlib.Path]) -> dict:
  if path is None or not path.is_file():
    return {}
  return yamlio.load_mapping(path)


def _classify_parent(
    ld: _Loader, raw: Any, path: Any,
    key: str) -> Tuple[Optional[str], Optional[str], Optional[str]]:
  """`(canonical_parent, folder_key, external)` for a raw parent value.

  Folder keys are not yet checked against the dataset: see `_resolve_refs`.
  """
  if raw is None:
    return (None, None, None)
  if not isinstance(raw, str):
    raise DatasetError(path, key,
                       f"expected a string parent, got {type(raw).__name__}")
  s = raw.strip()
  if not s:
    return (None, None, None)
  tok = _parse_token(s)
  if tok and tok[0] == "folder_ids":
    fk = tok[1].strip("/")
    if not fk or fk == "default":
      return (None, None, None)
    return (f"$folder_ids:{fk}", fk, None)
  if tok and tok[0] == "organization_ids" and tok[1] == "default":
    return (None, None, None)
  if s.startswith("organizations/") and (not ld.org_id or
                                         s == f"organizations/{ld.org_id}"):
    return (None, None, None)
  return (s, None, s)


def _resolve_refs(ld: _Loader, folders: Dict[str, "FolderSpec"], spec) -> None:
  """Points a `$folder_ids:` parent at a folder, context or implicit folder."""
  fk = spec.parent_folder_key
  if not fk or fk in folders:
    return
  if fk in ld.ctx_folder_ids:
    value = ld.ctx_folder_ids[fk]
    spec.parent_external = value if isinstance(value, str) else spec.parent
    spec.parent_folder_key = None
    return
  parts = fk.split("/")
  for i in range(1, len(parts) + 1):
    sub_fk = "/".join(parts[:i])
    if sub_fk not in folders:
      sub_parent_dir = posixpath.dirname(sub_fk)
      folders[sub_fk] = FolderSpec(
          key=sub_fk,
          name=posixpath.basename(sub_fk).replace("-", " ").title(),
          parent=None if i == 1 else f"$folder_ids:{sub_parent_dir}",
          parent_folder_key=None if i == 1 else sub_parent_dir,
          level=i,
          implicit=True,
      )


def _format_tag_pill(tag_key: str, raw_val: str) -> str:
  tok = _parse_token(raw_val)
  if tok and tok[0] == "tag_values":
    val_part = tok[1]
    if "/" in val_part:
      val_part = val_part.split("/", 1)[1]
    return f"{tag_key}={val_part}"
  return f"{tag_key}={raw_val}"


def _count_iam_principals(doc: Dict[str, Any]) -> Tuple[bool, int]:
  has_any = False
  principals: set[str] = set()
  for k in _IAM_KEYS:
    val = doc.get(k)
    if not val:
      continue
    has_any = True
    if k in ("iam_by_principals", "iam_by_principals_additive",
             "iam_by_principals_conditional") and isinstance(val, dict):
      principals.update(str(p) for p in val.keys())
    elif k == "iam" and isinstance(val, dict):
      for members in val.values():
        if isinstance(members, list):
          principals.update(str(m) for m in members)
    elif k in ("iam_bindings", "iam_bindings_additive") and isinstance(
        val, dict):
      for b in val.values():
        if isinstance(b, dict):
          if "member" in b:
            principals.add(str(b["member"]))
          members = b.get("members")
          if isinstance(members, list):
            principals.update(str(m) for m in members)
  return has_any, len(principals)


def _count_observability_dir(ld: _Loader,
                             obs_dir: pathlib.Path) -> Tuple[int, int]:
  alerts = 0
  metrics = 0
  for yf in yamlio.rglob_yaml(obs_dir, within=ld.root):
    doc = yamlio.load(yf)
    if not isinstance(doc, dict):
      continue
    a = doc.get("alerts")
    if isinstance(a, dict):
      alerts += len(a)
    m = doc.get("logging_metrics")
    if isinstance(m, dict):
      metrics += len(m)
  return alerts, metrics


def _names(value: Any) -> List[str]:
  return [str(k) for k in value.keys()] if isinstance(value, dict) else []


# --- sections ---------------------------------------------------------------


def _load_organization(ld: _Loader, org_dir: Optional[pathlib.Path],
                       org_spec: OrganizationSpec) -> None:
  if org_dir is None:
    return
  cfg_path = org_dir / ".config.yaml"
  org_cfg = _load_mapping_or_empty(cfg_path)

  dal = org_cfg.get("data_access_logs")
  if isinstance(dal, dict):
    org_spec.data_access_logs = list(dal.keys())
  contacts = org_cfg.get("contacts")
  if isinstance(contacts, dict):
    org_spec.contacts_count = len(contacts)

  logging_cfg = _m(org_cfg.get("logging"), cfg_path, "logging")
  sinks_cfg = _m(logging_cfg.get("sinks"), cfg_path, "logging.sinks")
  for sname, sdata in sinks_cfg.items():
    sdata = _m(sdata, cfg_path, f"logging.sinks.{sname}")
    dest = str(sdata.get("destination") or "")
    sink_type = str(sdata.get("type") or "logging")
    if sink_type not in SINK_TYPES:
      raise DatasetError(
          cfg_path, f"logging.sinks.{sname}.type",
          f"{sink_type!r} is not one of {', '.join(SINK_TYPES)}")
    tok = _parse_token(dest)
    t_proj: Optional[str] = None
    t_res: Optional[str] = None
    if tok:
      rest = tok[1]
      if "/" in rest:
        t_proj, t_res = rest.split("/", 1)
      else:
        t_proj = rest
    org_spec.sinks.append(
        OrgSink(
            name=str(sname),
            destination=dest,
            sink_type=sink_type,
            destination_kind=tok[0] if tok else "",
            target_project=t_proj,
            target_resource=t_res,
            filter=str(sdata.get("filter") or "").strip(),
        ))

  w = ld.root
  # Org policies: sum of constraints across files
  op_files = yamlio.yaml_files(org_dir / "org-policies", within=w)
  org_spec.org_policy_files_count = len(op_files)
  for opf in op_files:
    doc = yamlio.load(opf)
    if isinstance(doc, dict):
      org_spec.org_policies_count += len(doc)

  # Custom constraints: file count + keys
  cc_files = yamlio.yaml_files(org_dir / "custom-constraints", within=w)
  org_spec.custom_constraints_count = len(cc_files)
  for ccf in cc_files:
    doc = yamlio.load(ccf)
    if isinstance(doc, dict):
      org_spec.custom_constraint_keys.extend(str(k) for k in doc.keys())

  # Custom roles: file count + stem names
  cr_files = yamlio.yaml_files(org_dir / "custom-roles", within=w)
  org_spec.custom_roles_count = len(cr_files)
  org_spec.custom_role_names = [f.stem for f in cr_files]

  # SCC SHA custom modules: file count + stem names
  sha_files = yamlio.yaml_files(org_dir / "scc-sha-custom-modules", within=w)
  org_spec.scc_sha_modules_count = len(sha_files)
  org_spec.scc_sha_module_names = [f.stem for f in sha_files]

  # Tags: keys & values
  for tf in yamlio.yaml_files(org_dir / "tags", within=w):
    doc = yamlio.load(tf)
    if not isinstance(doc, dict):
      doc = {}
    org_spec.tags.append(
        TagSpec(
            key=tf.stem,
            description=str(doc.get("description") or ""),
            values=_names(doc.get("values")),
        ))
  org_spec.tag_keys_count = len(org_spec.tags)
  org_spec.tag_values_count = sum(len(t.values) for t in org_spec.tags)


def _load_cicd(path: Optional[pathlib.Path]) -> List[CicdWorkflowSpec]:
  out: List[CicdWorkflowSpec] = []
  if path is None or not path.is_file():
    return out
  for wname, wdata in yamlio.load_mapping(path).items():
    wdata = _m(wdata, path, str(wname))
    repo = _m(wdata.get("repository"), path, f"{wname}.repository")
    wif = _m(wdata.get("workload_identity"), path, f"{wname}.workload_identity")
    sas = _m(wdata.get("service_accounts"), path, f"{wname}.service_accounts")
    pool_tok = _parse_token(wif.get("pool"))
    pool_proj: Optional[str] = None
    pool_name = ""
    if pool_tok and pool_tok[0] == "workload_identity_pools":
      if "/" in pool_tok[1]:
        pool_proj, pool_name = pool_tok[1].split("/", 1)
      else:
        pool_proj = pool_tok[1]
    out.append(
        CicdWorkflowSpec(
            name=str(wname),
            repo_name=str(repo.get("name") or ""),
            repo_type=str(repo.get("type") or ""),
            pool_project=pool_proj,
            pool_name=pool_name,
            provider_name=str(wif.get("provider") or ""),
            apply_sa=str(sas.get("apply") or ""),
            plan_sa=str(sas.get("plan") or ""),
        ))
  return out


def _load_folders(ld: _Loader,
                  folders_dir: Optional[pathlib.Path]) -> Dict[str, FolderSpec]:
  folders: Dict[str, FolderSpec] = {}
  if folders_dir is None:
    return folders
  for rel_dir, cf in yamlio.config_dirs(folders_dir, within=ld.root):
    level = len(rel_dir.split("/"))
    if level > 4:
      raise DatasetError(cf, None,
                         f"Folder hierarchy exceeds max depth 4: {rel_dir}")
    doc = yamlio.load_mapping(cf)
    raw_parent = doc.get("parent")
    if raw_parent is None and level > 1:
      raw_parent = f"$folder_ids:{posixpath.dirname(rel_dir)}"
    canon_parent, parent_fk, external = _classify_parent(
        ld, raw_parent, cf, "parent")

    tb_raw = doc.get("tag_bindings")
    tag_bindings = ({
        str(k): str(v) for k, v in tb_raw.items()
    } if isinstance(tb_raw, dict) else {})
    tag_pills = [_format_tag_pill(k, v) for k, v in tag_bindings.items()]
    has_iam, iam_cnt = _count_iam_principals(doc)
    org_policies = doc.get("org_policies")
    op_cnt = len(org_policies) if isinstance(org_policies, dict) else 0
    fc = _m(doc.get("factories_config"), cf, "factories_config")
    sha_value = fc.get("scc_sha_custom_modules")
    has_sha = bool(sha_value)
    sha_cnt = 0
    if has_sha:
      sha_dir = ld.path(
          sha_value, f"{ld.rel(cf)} factories_config.scc_sha_custom_modules")
      if sha_dir is not None:
        sha_cnt = len(yamlio.yaml_files(sha_dir, within=ld.root))

    fname = str(
        doc.get("name") or
        posixpath.basename(rel_dir).replace("-", " ").title())
    folders[rel_dir] = FolderSpec(
        key=rel_dir,
        name=fname,
        parent=canon_parent,
        parent_folder_key=parent_fk,
        parent_external=external,
        level=level,
        tag_bindings=tag_bindings,
        tag_pills=tag_pills,
        has_iam=has_iam,
        iam_principals_count=iam_cnt,
        org_policies_count=op_cnt,
        has_scc_sha=has_sha,
        scc_sha_count=sha_cnt,
        implicit=False,
    )
  for fkey in sorted(folders):
    if not folders[fkey].implicit:
      _resolve_refs(ld, folders, folders[fkey])
  return folders


def _load_templates(ld: _Loader,
                    templates_dir: Optional[pathlib.Path]) -> Dict[str, dict]:
  templates: Dict[str, dict] = {}
  if templates_dir is None:
    return templates
  for tf in yamlio.rglob_yaml(templates_dir, within=ld.root):
    templates[yamlio.relative_key(tf, templates_dir)] = yamlio.load_mapping(tf)
  return templates


def _raw_projects(
    ld: _Loader, folders_dir: Optional[pathlib.Path],
    projects_dir: Optional[pathlib.Path]
) -> List[Tuple[str, pathlib.Path, str, Dict[str, Any]]]:
  """`(key, file, source_path, doc)` in Fabric order, one per key.

  On a duplicate basename only the last file is returned (and a warning is
  emitted), so a losing file leaves no trace (no implicit parent folder).
  """
  merged: Dict[str, Tuple[pathlib.Path, str, Dict[str, Any]]] = {}
  if folders_dir is not None:
    for pf in yamlio.rglob_yaml(folders_dir, within=ld.root):
      rel = yamlio.relative_key(pf, folders_dir)
      pdir = posixpath.dirname(rel)
      inferred = None if pdir in ("", ".") else f"$folder_ids:{pdir}"
      doc = {"parent": inferred, **yamlio.load_mapping(pf)}
      merged[rel] = (pf, f"folders/{rel}.yaml", doc)
  if projects_dir is not None:
    for pf in yamlio.rglob_yaml(projects_dir, within=ld.root):
      if pf.name.endswith(".config.yaml"):
        continue
      rel = yamlio.relative_key(pf, projects_dir)
      merged[rel] = (pf, f"projects/{rel}.yaml", yamlio.load_mapping(pf))
  by_key: Dict[str, List[str]] = {}
  winner: Dict[str, str] = {}
  for rel in merged:  # folders/ first, then projects/, each sorted
    key = posixpath.basename(rel)
    by_key.setdefault(key, []).append(merged[rel][1])
    winner[key] = rel
  out = [(posixpath.basename(rel), *merged[rel])
         for rel in merged
         if winner[posixpath.basename(rel)] == rel]
  for key, sources in sorted(by_key.items()):
    if len(sources) > 1:
      yamlio.warn(f"{ld.root}: project key {key!r} is defined by "
                  f"{', '.join(sources)}; Terraform fails on duplicate "
                  f"project keys, the diagram keeps {sources[-1]}")
  return out


def _load_project(ld: _Loader, key: str, pf: pathlib.Path, src: str,
                  raw: Dict[str, Any], templates: Dict[str, dict],
                  proj_defaults: dict, proj_overrides: dict) -> ProjectSpec:
  tmpl_name = raw.get("project_template")
  if tmpl_name is not None and not isinstance(tmpl_name, str):
    raise DatasetError(pf, "project_template", "expected a string")
  if tmpl_name and tmpl_name not in templates:
    yamlio.warn(f"{pf}: project_template {tmpl_name!r} not found in the "
                f"project templates directory; ignored")
  pdoc = {**templates.get(tmpl_name or "", {}), **raw}

  # Parent precedence (projects-defaults.tf): overrides.parent -> explicit or
  # inferred project parent -> defaults.parent -> org root.
  if proj_overrides.get("parent") is not None:
    eff_parent, where = proj_overrides["parent"], "projects.overrides.parent"
  elif pdoc.get("parent") is not None:
    eff_parent, where = pdoc["parent"], "parent"
  else:
    eff_parent, where = proj_defaults.get("parent"), "projects.defaults.parent"
  canon_parent, parent_fk, external = _classify_parent(ld, eff_parent, pf,
                                                       where)

  lb_raw = pdoc.get("log_buckets")
  log_buckets = _names(lb_raw)
  lb_cmek = isinstance(lb_raw, dict) and any(
      isinstance(c, dict) and c.get("kms_key_name") for c in lb_raw.values())
  ds_raw = pdoc.get("datasets")
  ds_cmek = isinstance(ds_raw, dict) and any(
      isinstance(c, dict) and c.get("encryption_key") for c in ds_raw.values())

  kms_raw = pdoc.get("kms")
  keyrings_raw = kms_raw.get("keyrings") if isinstance(kms_raw, dict) else None
  kms_keyrings: List[str] = []
  if isinstance(keyrings_raw, dict):
    for kr_name, kr_cfg in keyrings_raw.items():
      keys_dict = kr_cfg.get("keys") if isinstance(kr_cfg, dict) else None
      if isinstance(keys_dict, dict) and keys_dict:
        kms_keyrings.extend(f"{kr_name}/{k_name}" for k_name in keys_dict)
      else:
        kms_keyrings.append(str(kr_name))

  sek_raw = pdoc.get("service_encryption_key_ids")
  cmek_services: Dict[str, List[str]] = {}
  if isinstance(sek_raw, dict):
    for svc_name, klist in sek_raw.items():
      if isinstance(klist, list):
        cmek_services[str(svc_name)] = [str(x) for x in klist]

  host_cfg = pdoc.get("shared_vpc_host_config")
  svc_cfg = pdoc.get("shared_vpc_service_config")
  svpc_service_of: Optional[str] = None
  if isinstance(svc_cfg, dict) and svc_cfg.get("host_project"):
    hp_raw = str(svc_cfg["host_project"])
    hp_tok = _parse_token(hp_raw)
    svpc_service_of = hp_tok[1] if (hp_tok and
                                    hp_tok[0] == "project_ids") else hp_raw

  pop_raw = pdoc.get("org_policies")

  # factories_config.observability: relative to the dataset, never outside.
  fc = _m(pdoc.get("factories_config"), pf, "factories_config")
  obs_value = fc.get("observability")
  obs_fc_path: Optional[str] = None
  obs_alerts = obs_metrics = 0
  obs_missing = False
  if obs_value:
    obs_fc_path = str(obs_value)
    obs_dir = ld.path(obs_value, f"{src} factories_config.observability")
    if obs_dir is not None and obs_dir.is_dir():
      obs_alerts, obs_metrics = _count_observability_dir(ld, obs_dir)
    else:
      obs_missing = True

  has_iam, iam_cnt = _count_iam_principals(pdoc)
  svcs_raw = pdoc.get("services")
  return ProjectSpec(
      key=key,
      name=str(pdoc.get("name") or key),
      descriptive_name=str(pdoc.get("descriptive_name") or ""),
      source_path=src,
      parent=canon_parent,
      parent_folder_key=parent_fk,
      parent_external=external,
      project_template=tmpl_name or None,
      log_buckets=log_buckets,
      log_buckets_cmek=bool(lb_cmek),
      datasets=_names(ds_raw),
      datasets_cmek=bool(ds_cmek),
      buckets=_names(pdoc.get("buckets")),
      service_accounts=_names(pdoc.get("service_accounts")),
      kms_keyrings=kms_keyrings,
      cmek_services=cmek_services,
      shared_vpc_host=bool(
          isinstance(host_cfg, dict) and host_cfg.get("enabled") is True),
      shared_vpc_service_of=svpc_service_of,
      org_policies_count=len(pop_raw) if isinstance(pop_raw, dict) else 0,
      has_observability_factory=bool(obs_value),
      observability_factory_path=obs_fc_path,
      observability_alerts_count=obs_alerts,
      observability_metrics_count=obs_metrics,
      observability_missing_path=obs_missing,
      has_iam=has_iam,
      iam_principals_count=iam_cnt,
      services=([str(s) for s in svcs_raw]
                if isinstance(svcs_raw, list) else []),
  )


def _vpc_factory_dir(ld: _Loader, vpc_dir: pathlib.Path, fc: dict, name: str,
                     default: str) -> Optional[pathlib.Path]:
  value = fc.get(name)
  if not isinstance(value, str):
    return vpc_dir / default
  resolved = resolve_dataset_path(ld.root, value, vpc_dir)
  if resolved is None and value.strip().lower() not in ("", "none"):
    yamlio.warn(f"{vpc_dir / '.config.yaml'}: factories_config.{name} "
                f"{value!r} resolves outside the dataset; not read")
  return resolved


def _load_vpcs(ld: _Loader, vpcs_dir: Optional[pathlib.Path],
               locations: Dict[str, str]) -> Dict[str, EmbeddedVpcSpec]:
  vpcs: Dict[str, EmbeddedVpcSpec] = {}
  if vpcs_dir is None:
    return vpcs
  for vkey, vcfg_file in yamlio.config_dirs(vpcs_dir, within=ld.root):
    vdoc = yamlio.load_mapping(vcfg_file)
    vpc_dir = vcfg_file.parent
    fc = _m(vdoc.get("factories_config"), vcfg_file, "factories_config")
    pid_raw = str(vdoc.get("project_id") or "")
    ptok = _parse_token(pid_raw)
    proj_key = ptok[1] if (ptok and ptok[0] == "project_ids") else pid_raw

    subnets: List[EmbeddedSubnetSpec] = []
    sub_dir = _vpc_factory_dir(ld, vpc_dir, fc, "subnets", "subnets")
    for sf in (yamlio.rglob_yaml(sub_dir, within=ld.root) if sub_dir else []):
      sdoc = yamlio.load(sf)
      if not isinstance(sdoc, dict):
        continue
      s_reg_raw = str(sdoc.get("region") or "")
      s_reg_tok = _parse_token(s_reg_raw)
      s_reg = (locations.get(s_reg_tok[1], s_reg_raw) if
               (s_reg_tok and s_reg_tok[0] == "locations") else s_reg_raw)
      subnets.append(
          EmbeddedSubnetSpec(
              name=str(sdoc.get("name") or sf.stem),
              region=s_reg,
              ip_cidr_range=str(sdoc.get("ip_cidr_range") or ""),
              description=str(sdoc.get("description") or ""),
          ))

    ing_cnt = 0
    eg_cnt = 0
    fw_dir = _vpc_factory_dir(ld, vpc_dir, fc, "firewall_rules",
                              "firewall-rules")
    for fwf in (yamlio.rglob_yaml(fw_dir, within=ld.root) if fw_dir else []):
      fwdoc = yamlio.load(fwf)
      if not isinstance(fwdoc, dict):
        continue
      if isinstance(fwdoc.get("ingress"), dict):
        ing_cnt += len(fwdoc["ingress"])
      if isinstance(fwdoc.get("egress"), dict):
        eg_cnt += len(fwdoc["egress"])

    vpcs[vkey] = EmbeddedVpcSpec(
        key=vkey,
        name=str(vdoc.get("name") or vkey),
        project_key=proj_key,
        subnets=subnets,
        ingress_rule_count=ing_cnt,
        egress_rule_count=eg_cnt,
    )
  return vpcs


def _load_billing_accounts(
    ld: _Loader, ba_dir: Optional[pathlib.Path],
    org_spec: OrganizationSpec) -> List[BillingAccountSpec]:
  billing_accounts: List[BillingAccountSpec] = []
  for baf in (yamlio.yaml_files(ba_dir, within=ld.root) if ba_dir else []):
    bdoc = yamlio.load_mapping(baf)
    raw_id = str(bdoc.get("id") or "")
    if raw_id == "$defaults:billing_account" and org_spec.billing_account_id:
      ba_id = org_spec.billing_account_id
    else:
      ba_id = raw_id or org_spec.billing_account_id or baf.stem
    add_bindings = bdoc.get("iam_bindings_additive")
    _, ba_iam_cnt = _count_iam_principals(bdoc)
    ba_sinks: Dict[str, str] = {}
    sinks = bdoc.get("logging_sinks")
    if isinstance(sinks, dict):
      for sk, sv in sinks.items():
        if isinstance(sv, dict) and sv.get("destination"):
          ba_sinks[str(sk)] = str(sv["destination"])
    billing_accounts.append(
        BillingAccountSpec(
            key=baf.stem,
            id=ba_id,
            iam_bindings_additive_count=(len(add_bindings) if isinstance(
                add_bindings, dict) else 0),
            iam_principals_count=ba_iam_cnt,
            logging_sinks=ba_sinks,
        ))
  if not billing_accounts and org_spec.billing_account_id:
    billing_accounts.append(
        BillingAccountSpec(key="default", id=org_spec.billing_account_id))
  return billing_accounts


# --- entry point ------------------------------------------------------------


def load_org_setup_dataset(
    dataset_dir: pathlib.Path | str,
    paths: Optional[Mapping[str, Optional[str]]] = None) -> OrgSetupDataset:
  """Loads a FAST 0-org-setup dataset directory into an OrgSetupDataset.

  `paths` overrides entries of `DEFAULT_PATHS` (the stage's
  `var.factories_config.paths`); e.g. `{"cicd_workflows": "cicd.yaml"}`
  enables the CI/CD workflows file.
  """
  root = pathlib.Path(dataset_dir).resolve()
  if not root.is_dir():
    raise FileNotFoundError(f"Dataset directory not found: {root}")
  unknown = sorted(set(paths or {}) - set(DEFAULT_PATHS))
  if unknown:
    raise ValueError(f"unknown 0-org-setup paths: {', '.join(unknown)}")
  eff_paths = {**DEFAULT_PATHS, **(paths or {})}
  ld = _Loader(root)

  def stage_path(name: str) -> Optional[pathlib.Path]:
    return ld.path(eff_paths[name], f"paths.{name}")

  defaults_path = stage_path("defaults")
  defaults_doc = _load_mapping_or_empty(defaults_path)
  global_cfg = _m(defaults_doc.get("global"), defaults_path, "global")
  org_global = _m(global_cfg.get("organization"), defaults_path,
                  "global.organization")
  proj_cfg = _m(defaults_doc.get("projects"), defaults_path, "projects")
  proj_defaults = _m(proj_cfg.get("defaults"), defaults_path,
                     "projects.defaults")
  proj_overrides = _m(proj_cfg.get("overrides"), defaults_path,
                      "projects.overrides")
  ctx_cfg = _m(defaults_doc.get("context"), defaults_path, "context")
  locations = {
      str(k): str(v) for k, v in _m(ctx_cfg.get("locations"), defaults_path,
                                   "context.locations").items()
  }
  ld.ctx_folder_ids = _m(ctx_cfg.get("folder_ids"), defaults_path,
                         "context.folder_ids")

  obs_cfg = _m(defaults_doc.get("observability"), defaults_path,
               "observability")
  obs_proj_raw = obs_cfg.get("project_id")
  obs_proj_key: Optional[str] = None
  if obs_proj_raw:
    tok = _parse_token(obs_proj_raw)
    obs_proj_key = tok[1] if (tok and
                              tok[0] == "project_ids") else str(obs_proj_raw)

  org_spec = OrganizationSpec(
      domain=str(org_global.get("domain") or ""),
      id=str(org_global.get("id") or ""),
      customer_id=str(org_global.get("customer_id") or ""),
      prefix=str(proj_defaults.get("prefix") or ""),
      primary_location=str(locations.get("primary") or ""),
      billing_account_id=str(global_cfg.get("billing_account") or ""),
      observability_project_key=obs_proj_key,
  )
  ld.org_id = org_spec.id

  _load_organization(ld, stage_path("organization"), org_spec)

  cicd_workflows = _load_cicd(stage_path("cicd_workflows"))
  cicd_by_project: Dict[str, List[CicdWorkflowSpec]] = {}
  for wf in cicd_workflows:
    if wf.pool_project:
      cicd_by_project.setdefault(wf.pool_project, []).append(wf)

  folders_dir = stage_path("folders")
  folders = _load_folders(ld, folders_dir)
  templates = _load_templates(ld, stage_path("project_templates"))

  projects: Dict[str, ProjectSpec] = {}
  for key, pf, src, raw in _raw_projects(ld, folders_dir,
                                         stage_path("projects")):
    pspec = _load_project(ld, key, pf, src, raw, templates, proj_defaults,
                          proj_overrides)
    pspec.is_observability_project = key == obs_proj_key
    pspec.cicd_workflows = list(cicd_by_project.get(key, []))
    _resolve_refs(ld, folders, pspec)
    projects[key] = pspec

  vpcs = _load_vpcs(ld, stage_path("vpcs"), locations)
  for vspec in vpcs.values():
    if vspec.project_key in projects:
      projects[vspec.project_key].vpcs.append(vspec)

  billing_accounts = _load_billing_accounts(ld, stage_path("billing_accounts"),
                                            org_spec)

  # Wire folder tree and root lists deterministically
  root_folder_keys: List[str] = []
  for fkey in sorted(folders.keys()):
    pfk = folders[fkey].parent_folder_key
    if pfk and pfk in folders:
      folders[pfk].children_folders.append(fkey)
    else:
      root_folder_keys.append(fkey)

  root_project_keys: List[str] = []
  for pkey in sorted(projects.keys()):
    pfk = projects[pkey].parent_folder_key
    if pfk and pfk in folders:
      folders[pfk].children_projects.append(pkey)
    else:
      root_project_keys.append(pkey)

  return OrgSetupDataset(
      dataset_name=_display_name(dataset_dir, root),
      root_dir=root,
      organization=org_spec,
      folders=folders,
      projects=projects,
      root_folder_keys=root_folder_keys,
      root_project_keys=root_project_keys,
      billing_accounts=billing_accounts,
      cicd_workflows=cicd_workflows,
      vpcs=vpcs,
      locations=locations,
  )


# Alias for generic stage loader conventions
import_dataset = load_org_setup_dataset
load = load_org_setup_dataset
