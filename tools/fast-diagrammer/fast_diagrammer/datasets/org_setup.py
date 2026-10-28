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

"""Loader for FAST 0-org-setup YAML datasets."""

from dataclasses import dataclass, field
import pathlib
import posixpath
from typing import Any, Dict, List, Optional, Tuple

from .. import tokens, yamlio

_IAM_KEYS = (
    "iam",
    "iam_bindings",
    "iam_bindings_additive",
    "iam_by_principals",
    "iam_by_principals_additive",
    "iam_by_principals_conditional",
    "iam_deny_policies",
)


def _parse_token(val: Any) -> Optional[Tuple[str, str]]:
  if not isinstance(val, str):
    return None
  return tokens.parse(val.strip())


def _load_yaml_file(path: pathlib.Path) -> Any:
  return yamlio.load_or_empty(path)


def _sorted_yaml_files(directory: pathlib.Path) -> List[pathlib.Path]:
  return yamlio.yaml_files(directory)


def _sorted_rglob_yaml(directory: pathlib.Path) -> List[pathlib.Path]:
  return yamlio.rglob_yaml(directory)


@dataclass
class OrgSink:
  name: str
  destination: str
  sink_type: str = ""
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
  key: str
  name: str
  parent: Optional[str] = None
  parent_folder_key: Optional[str] = None
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
  key: str
  name: str
  descriptive_name: str = ""
  source_path: str = ""
  parent: Optional[str] = None
  parent_folder_key: Optional[str] = None
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


def _normalize_folder_parent(raw_parent: Optional[str]) -> Tuple[Optional[str], Optional[str]]:
  """Returns (canonical_parent_token_or_None, folder_key_or_None)."""
  if not raw_parent:
    return (None, None)
  s = str(raw_parent).strip()
  if not s or s == "$folder_ids:default" or s.startswith("organizations/"):
    return (None, None)
  tok = _parse_token(s)
  if tok and tok[0] == "folder_ids":
    fk = tok[1].strip("/")
    if not fk or fk == "default":
      return (None, None)
    return (f"$folder_ids:{fk}", fk)
  return (s, s.strip("/"))


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
    if k in ("iam_by_principals", "iam_by_principals_additive", "iam_by_principals_conditional") and isinstance(val, dict):
      principals.update(str(p) for p in val.keys())
    elif k == "iam" and isinstance(val, dict):
      for members in val.values():
        if isinstance(members, list):
          principals.update(str(m) for m in members)
    elif k in ("iam_bindings", "iam_bindings_additive") and isinstance(val, dict):
      for b in val.values():
        if isinstance(b, dict):
          if "member" in b:
            principals.add(str(b["member"]))
          for m in b.get("members") or []:
            principals.add(str(m))
  return has_any, len(principals)


def _count_observability_dir(obs_dir: pathlib.Path) -> Tuple[int, int]:
  alerts = 0
  metrics = 0
  for yf in _sorted_rglob_yaml(obs_dir):
    doc = _load_yaml_file(yf)
    if not isinstance(doc, dict):
      continue
    a = doc.get("alerts")
    if isinstance(a, dict):
      alerts += len(a)
    m = doc.get("logging_metrics")
    if isinstance(m, dict):
      metrics += len(m)
  return alerts, metrics


def load_org_setup_dataset(dataset_dir: pathlib.Path | str) -> OrgSetupDataset:
  """Loads a FAST 0-org-setup dataset directory into an OrgSetupDataset model."""
  root = pathlib.Path(dataset_dir).resolve()
  if not root.is_dir():
    raise FileNotFoundError(f"Dataset directory not found: {root}")

  defaults_doc = _load_yaml_file(root / "defaults.yaml")
  if not isinstance(defaults_doc, dict):
    defaults_doc = {}

  global_cfg = defaults_doc.get("global") or {}
  org_global = global_cfg.get("organization") or {}
  proj_cfg = defaults_doc.get("projects") or {}
  proj_defaults = proj_cfg.get("defaults") or {}
  proj_overrides = proj_cfg.get("overrides") or {}
  ctx_cfg = defaults_doc.get("context") or {}
  locations = {
      str(k): str(v) for k, v in (ctx_cfg.get("locations") or {}).items()
  }

  obs_cfg = defaults_doc.get("observability") or {}
  obs_proj_raw = obs_cfg.get("project_id")
  obs_proj_key: Optional[str] = None
  if obs_proj_raw:
    tok = _parse_token(obs_proj_raw)
    obs_proj_key = tok[1] if (tok and tok[0] == "project_ids") else str(obs_proj_raw)

  org_spec = OrganizationSpec(
      domain=str(org_global.get("domain") or ""),
      id=str(org_global.get("id") or ""),
      customer_id=str(org_global.get("customer_id") or ""),
      prefix=str(proj_defaults.get("prefix") or ""),
      primary_location=str(locations.get("primary") or ""),
      billing_account_id=str(global_cfg.get("billing_account") or ""),
      observability_project_key=obs_proj_key,
  )

  # 1. Organization directory
  org_dir = root / "organization"
  org_cfg = _load_yaml_file(org_dir / ".config.yaml")
  if not isinstance(org_cfg, dict):
    org_cfg = {}

  dal = org_cfg.get("data_access_logs")
  if isinstance(dal, dict):
    org_spec.data_access_logs = list(dal.keys())
  contacts = org_cfg.get("contacts")
  if isinstance(contacts, dict):
    org_spec.contacts_count = len(contacts)

  logging_cfg = org_cfg.get("logging") or {}
  sinks_cfg = logging_cfg.get("sinks") or {}
  if isinstance(sinks_cfg, dict):
    for sname, sdata in sinks_cfg.items():
      if not isinstance(sdata, dict):
        continue
      dest = str(sdata.get("destination") or "")
      tok = _parse_token(dest)
      sink_type = tok[0] if tok else str(sdata.get("type") or "")
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
              target_project=t_proj,
              target_resource=t_res,
              filter=str(sdata.get("filter") or "").strip(),
          )
      )

  # Org policies: sum of constraints across files
  op_files = _sorted_yaml_files(org_dir / "org-policies")
  org_spec.org_policy_files_count = len(op_files)
  for opf in op_files:
    doc = _load_yaml_file(opf)
    if isinstance(doc, dict):
      org_spec.org_policies_count += len(doc)

  # Custom constraints: file count + keys
  cc_files = _sorted_yaml_files(org_dir / "custom-constraints")
  org_spec.custom_constraints_count = len(cc_files)
  for ccf in cc_files:
    doc = _load_yaml_file(ccf)
    if isinstance(doc, dict):
      org_spec.custom_constraint_keys.extend(str(k) for k in doc.keys())

  # Custom roles: file count + stem names
  cr_files = _sorted_yaml_files(org_dir / "custom-roles")
  org_spec.custom_roles_count = len(cr_files)
  org_spec.custom_role_names = [f.stem for f in cr_files]

  # SCC SHA custom modules: file count + stem names
  sha_files = _sorted_yaml_files(org_dir / "scc-sha-custom-modules")
  org_spec.scc_sha_modules_count = len(sha_files)
  org_spec.scc_sha_module_names = [f.stem for f in sha_files]

  # Tags: keys & values
  tag_files = _sorted_yaml_files(org_dir / "tags")
  for tf in tag_files:
    doc = _load_yaml_file(tf)
    if not isinstance(doc, dict):
      doc = {}
    vals_dict = doc.get("values") or {}
    val_names = [str(k) for k in vals_dict.keys()] if isinstance(vals_dict, dict) else []
    org_spec.tags.append(
        TagSpec(
            key=tf.stem,
            description=str(doc.get("description") or ""),
            values=val_names,
        )
    )
  org_spec.tag_keys_count = len(org_spec.tags)
  org_spec.tag_values_count = sum(len(t.values) for t in org_spec.tags)

  # 2. CI/CD workflows (cicd.yaml)
  cicd_workflows: List[CicdWorkflowSpec] = []
  cicd_by_project: Dict[str, List[CicdWorkflowSpec]] = {}
  cicd_doc = _load_yaml_file(root / "cicd.yaml")
  if isinstance(cicd_doc, dict):
    for wname, wdata in cicd_doc.items():
      if not isinstance(wdata, dict):
        continue
      repo = wdata.get("repository") or {}
      wif = wdata.get("workload_identity") or {}
      sas = wdata.get("service_accounts") or {}
      pool_raw = str(wif.get("pool") or "")
      pool_tok = _parse_token(pool_raw)
      pool_proj: Optional[str] = None
      pool_name = ""
      if pool_tok and pool_tok[0] == "workload_identity_pools":
        if "/" in pool_tok[1]:
          pool_proj, pool_name = pool_tok[1].split("/", 1)
        else:
          pool_proj = pool_tok[1]
      wf_spec = CicdWorkflowSpec(
          name=str(wname),
          repo_name=str(repo.get("name") or ""),
          repo_type=str(repo.get("type") or ""),
          pool_project=pool_proj,
          pool_name=pool_name,
          provider_name=str(wif.get("provider") or ""),
          apply_sa=str(sas.get("apply") or ""),
          plan_sa=str(sas.get("plan") or ""),
      )
      cicd_workflows.append(wf_spec)
      if pool_proj:
        cicd_by_project.setdefault(pool_proj, []).append(wf_spec)

  # 3. Folders hierarchy (folders/**/.config.yaml, up to depth 4)
  folders: Dict[str, FolderSpec] = {}
  folders_dir = root / "folders"
  if folders_dir.is_dir():
    cfg_files = sorted(folders_dir.rglob(".config.yaml"))
    for cf in cfg_files:
      rel_dir = cf.parent.relative_to(folders_dir).as_posix()
      if rel_dir in ("", "."):
        continue
      level = len(rel_dir.split("/"))
      if level > 4:
        raise ValueError(f"Folder hierarchy exceeds max depth 4: {rel_dir}")
      doc = _load_yaml_file(cf)
      if not isinstance(doc, dict):
        doc = {}
      parent_dir = posixpath.dirname(rel_dir)
      raw_parent_val = doc.get("parent")
      if raw_parent_val is None:
        raw_parent_val = None if level == 1 else f"$folder_ids:{parent_dir}"
      canon_parent, parent_fk = _normalize_folder_parent(raw_parent_val)

      tb_raw = doc.get("tag_bindings") or {}
      tag_bindings = {str(k): str(v) for k, v in tb_raw.items()} if isinstance(tb_raw, dict) else {}
      tag_pills = [_format_tag_pill(k, v) for k, v in tag_bindings.items()]
      has_iam, iam_cnt = _count_iam_principals(doc)
      op_cnt = len(doc.get("org_policies") or {}) if isinstance(doc.get("org_policies"), dict) else 0
      fc = doc.get("factories_config") or {}
      has_sha = isinstance(fc, dict) and bool(fc.get("scc_sha_custom_modules"))
      sha_cnt = 0
      if has_sha:
        sha_dir = root / str(fc["scc_sha_custom_modules"]).strip("/")
        sha_cnt = len(_sorted_yaml_files(sha_dir))

      fname = str(doc.get("name") or posixpath.basename(rel_dir).replace("-", " ").title())
      folders[rel_dir] = FolderSpec(
          key=rel_dir,
          name=fname,
          parent=canon_parent,
          parent_folder_key=parent_fk,
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

  # 4. Projects (F3 parent semantics: folders/<path>/<name>.yaml + projects/**/<name>.yaml)
  templates_dir = root / "project_templates"
  templates_raw: Dict[str, Dict[str, Any]] = {}
  if templates_dir.is_dir():
    for tf in _sorted_rglob_yaml(templates_dir):
      rel_t = tf.relative_to(templates_dir).with_suffix("").as_posix()
      tdoc = _load_yaml_file(tf)
      if isinstance(tdoc, dict):
        templates_raw[rel_t] = tdoc

  raw_projects_merged: List[Tuple[str, str, Dict[str, Any]]] = []
  # 4a. _folder_projects_raw from folders/**/*.yaml (excluding .config.yaml)
  if folders_dir.is_dir():
    for pf in _sorted_rglob_yaml(folders_dir):
      if pf.name == ".config.yaml":
        continue
      rel_no_ext = pf.relative_to(folders_dir).with_suffix("").as_posix()
      pdir = posixpath.dirname(rel_no_ext)
      inferred_parent = None if pdir in ("", ".") else f"$folder_ids:{pdir}"
      pdoc = _load_yaml_file(pf)
      if not isinstance(pdoc, dict):
        pdoc = {}
      merged_doc = {"parent": inferred_parent, **pdoc}
      raw_projects_merged.append((rel_no_ext, f"folders/{rel_no_ext}.yaml", merged_doc))

  # 4b. _projects_raw from projects/**/*.yaml (excluding .config.yaml)
  # Subdirectories under projects/ are organisational only!
  projects_dir = root / "projects"
  if projects_dir.is_dir():
    for pf in _sorted_rglob_yaml(projects_dir):
      if pf.name == ".config.yaml":
        continue
      rel_no_ext = pf.relative_to(projects_dir).with_suffix("").as_posix()
      pdoc = _load_yaml_file(pf)
      if not isinstance(pdoc, dict):
        pdoc = {}
      raw_projects_merged.append((rel_no_ext, f"projects/{rel_no_ext}.yaml", pdoc))

  overrides_parent = proj_overrides.get("parent") if isinstance(proj_overrides, dict) else None
  defaults_parent = proj_defaults.get("parent") if isinstance(proj_defaults, dict) else None

  projects: Dict[str, ProjectSpec] = {}
  for rel_key, src_path, raw_pdoc in raw_projects_merged:
    pkey = posixpath.basename(rel_key)
    tmpl_name = raw_pdoc.get("project_template")
    if tmpl_name and tmpl_name in templates_raw:
      pdoc = {**templates_raw[tmpl_name], **raw_pdoc}
    else:
      pdoc = dict(raw_pdoc)

    # F3 parent resolution precedence:
    # overrides.parent -> explicit/inferred project parent -> defaults.parent -> org root (None)
    eff_parent_raw = (
        overrides_parent
        if overrides_parent is not None
        else (pdoc.get("parent") if pdoc.get("parent") is not None else defaults_parent)
    )
    canon_parent, parent_fk = _normalize_folder_parent(eff_parent_raw)

    # Ensure any referenced folder path (and its ancestors up to 4 levels) exists in folders
    if parent_fk and parent_fk not in folders and not parent_fk.startswith("folders/"):
      parts = parent_fk.split("/")
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

    pname = str(pdoc.get("name") or pkey)
    desc_name = str(pdoc.get("descriptive_name") or "")

    # Log buckets & CMEK
    lb_raw = pdoc.get("log_buckets") or {}
    log_buckets: List[str] = []
    lb_cmek = False
    if isinstance(lb_raw, dict):
      for bname, bcfg in lb_raw.items():
        log_buckets.append(str(bname))
        if isinstance(bcfg, dict) and bcfg.get("kms_key_name"):
          lb_cmek = True

    # BigQuery datasets
    ds_raw = pdoc.get("datasets") or {}
    bq_datasets: List[str] = []
    ds_cmek = False
    if isinstance(ds_raw, dict):
      for dname, dcfg in ds_raw.items():
        bq_datasets.append(str(dname))
        if isinstance(dcfg, dict) and dcfg.get("encryption_key"):
          ds_cmek = True

    # GCS buckets
    bkt_raw = pdoc.get("buckets") or {}
    gcs_buckets = [str(k) for k in bkt_raw.keys()] if isinstance(bkt_raw, dict) else []

    # Service accounts
    sa_raw = pdoc.get("service_accounts") or {}
    sas = [str(k) for k in sa_raw.keys()] if isinstance(sa_raw, dict) else []

    # KMS keyrings
    kms_raw = pdoc.get("kms") or {}
    keyrings_raw = (kms_raw.get("keyrings") or {}) if isinstance(kms_raw, dict) else {}
    kms_keyrings: List[str] = []
    if isinstance(keyrings_raw, dict):
      for kr_name, kr_cfg in keyrings_raw.items():
        keys_dict = (kr_cfg.get("keys") or {}) if isinstance(kr_cfg, dict) else {}
        if isinstance(keys_dict, dict) and keys_dict:
          for k_name in keys_dict.keys():
            kms_keyrings.append(f"{kr_name}/{k_name}")
        else:
          kms_keyrings.append(str(kr_name))

    # Service encryption key IDs (CMEK)
    sek_raw = pdoc.get("service_encryption_key_ids") or {}
    cmek_services: Dict[str, List[str]] = {}
    if isinstance(sek_raw, dict):
      for svc_name, klist in sek_raw.items():
        if isinstance(klist, list):
          cmek_services[str(svc_name)] = [str(x) for x in klist]

    # Shared VPC host / service
    svpc_host_cfg = pdoc.get("shared_vpc_host_config") or {}
    svpc_host = bool(isinstance(svpc_host_cfg, dict) and svpc_host_cfg.get("enabled"))

    svpc_svc_cfg = pdoc.get("shared_vpc_service_config") or {}
    svpc_service_of: Optional[str] = None
    if isinstance(svpc_svc_cfg, dict) and svpc_svc_cfg.get("host_project"):
      hp_raw = str(svpc_svc_cfg["host_project"])
      hp_tok = _parse_token(hp_raw)
      svpc_service_of = hp_tok[1] if (hp_tok and hp_tok[0] == "project_ids") else hp_raw

    # Project org policies
    pop_raw = pdoc.get("org_policies") or {}
    pop_cnt = len(pop_raw) if isinstance(pop_raw, dict) else 0

    # Factories config -> observability (F5: relative to dataset root; tolerate missing path)
    fc_raw = pdoc.get("factories_config") or {}
    has_obs_fc = False
    obs_fc_path: Optional[str] = None
    obs_alerts = 0
    obs_metrics = 0
    obs_missing = False
    if isinstance(fc_raw, dict) and fc_raw.get("observability"):
      has_obs_fc = True
      obs_fc_path = str(fc_raw["observability"])
      resolved_obs = root / obs_fc_path.strip("/")
      if resolved_obs.is_dir():
        obs_alerts, obs_metrics = _count_observability_dir(resolved_obs)
      else:
        obs_missing = True

    has_iam, iam_cnt = _count_iam_principals(pdoc)
    svcs_raw = pdoc.get("services") or []
    svcs = [str(s) for s in svcs_raw] if isinstance(svcs_raw, list) else []

    projects[pkey] = ProjectSpec(
        key=pkey,
        name=pname,
        descriptive_name=desc_name,
        source_path=src_path,
        parent=canon_parent,
        parent_folder_key=parent_fk,
        log_buckets=log_buckets,
        log_buckets_cmek=lb_cmek,
        datasets=bq_datasets,
        datasets_cmek=ds_cmek,
        buckets=gcs_buckets,
        service_accounts=sas,
        kms_keyrings=kms_keyrings,
        cmek_services=cmek_services,
        shared_vpc_host=svpc_host,
        shared_vpc_service_of=svpc_service_of,
        org_policies_count=pop_cnt,
        has_observability_factory=has_obs_fc,
        observability_factory_path=obs_fc_path,
        observability_alerts_count=obs_alerts,
        observability_metrics_count=obs_metrics,
        observability_missing_path=obs_missing,
        is_observability_project=(pkey == obs_proj_key),
        cicd_workflows=list(cicd_by_project.get(pkey, [])),
        has_iam=has_iam,
        iam_principals_count=iam_cnt,
        services=svcs,
    )

  # 5. Embedded VPCs (e.g. starter-gcd/vpcs/*/.config.yaml)
  vpcs: Dict[str, EmbeddedVpcSpec] = {}
  vpcs_dir = root / "vpcs"
  if vpcs_dir.is_dir():
    for vcfg_file in sorted(vpcs_dir.glob("*/.config.yaml")):
      vkey = vcfg_file.parent.name
      vdoc = _load_yaml_file(vcfg_file)
      if not isinstance(vdoc, dict):
        vdoc = {}
      vname = str(vdoc.get("name") or vkey)
      pid_raw = str(vdoc.get("project_id") or "")
      ptok = _parse_token(pid_raw)
      proj_key = ptok[1] if (ptok and ptok[0] == "project_ids") else pid_raw

      subnets: List[EmbeddedSubnetSpec] = []
      for sf in _sorted_rglob_yaml(vcfg_file.parent / "subnets"):
        sdoc = _load_yaml_file(sf)
        if not isinstance(sdoc, dict):
          continue
        s_reg_raw = str(sdoc.get("region") or "")
        s_reg_tok = _parse_token(s_reg_raw)
        s_reg = locations.get(s_reg_tok[1], s_reg_raw) if (s_reg_tok and s_reg_tok[0] == "locations") else s_reg_raw
        subnets.append(
            EmbeddedSubnetSpec(
                name=str(sdoc.get("name") or sf.stem),
                region=s_reg,
                ip_cidr_range=str(sdoc.get("ip_cidr_range") or ""),
                description=str(sdoc.get("description") or ""),
            )
        )

      ing_cnt = 0
      eg_cnt = 0
      for fwf in _sorted_rglob_yaml(vcfg_file.parent / "firewall-rules"):
        fwdoc = _load_yaml_file(fwf)
        if not isinstance(fwdoc, dict):
          continue
        if isinstance(fwdoc.get("ingress"), dict):
          ing_cnt += len(fwdoc["ingress"])
        if isinstance(fwdoc.get("egress"), dict):
          eg_cnt += len(fwdoc["egress"])

      vspec = EmbeddedVpcSpec(
          key=vkey,
          name=vname,
          project_key=proj_key,
          subnets=subnets,
          ingress_rule_count=ing_cnt,
          egress_rule_count=eg_cnt,
      )
      vpcs[vkey] = vspec
      if proj_key in projects:
        projects[proj_key].vpcs.append(vspec)

  # 6. Billing accounts (billing-accounts/*.yaml or defaults.yaml global.billing_account)
  billing_accounts: List[BillingAccountSpec] = []
  ba_dir = root / "billing-accounts"
  for baf in _sorted_yaml_files(ba_dir):
    bdoc = _load_yaml_file(baf)
    if not isinstance(bdoc, dict):
      bdoc = {}
    raw_id = str(bdoc.get("id") or "")
    if raw_id == "$defaults:billing_account" and org_spec.billing_account_id:
      ba_id = org_spec.billing_account_id
    else:
      ba_id = raw_id or org_spec.billing_account_id or baf.stem
    add_bindings = bdoc.get("iam_bindings_additive") or {}
    add_cnt = len(add_bindings) if isinstance(add_bindings, dict) else 0
    _, ba_iam_cnt = _count_iam_principals(bdoc)
    ba_sinks: Dict[str, str] = {}
    if isinstance(bdoc.get("logging_sinks"), dict):
      for sk, sv in bdoc["logging_sinks"].items():
        if isinstance(sv, dict) and sv.get("destination"):
          ba_sinks[str(sk)] = str(sv["destination"])
    billing_accounts.append(
        BillingAccountSpec(
            key=baf.stem,
            id=ba_id,
            iam_bindings_additive_count=add_cnt,
            iam_principals_count=ba_iam_cnt,
            logging_sinks=ba_sinks,
        )
    )
  if not billing_accounts and org_spec.billing_account_id:
    billing_accounts.append(
        BillingAccountSpec(
            key="default",
            id=org_spec.billing_account_id,
            iam_bindings_additive_count=0,
            iam_principals_count=0,
        )
    )

  # 7. Wire folder tree and root lists deterministically
  root_folder_keys: List[str] = []
  for fkey in sorted(folders.keys()):
    fspec = folders[fkey]
    pfk = fspec.parent_folder_key
    if pfk and pfk in folders:
      folders[pfk].children_folders.append(fkey)
    else:
      root_folder_keys.append(fkey)

  root_project_keys: List[str] = []
  for pkey in sorted(projects.keys()):
    pspec = projects[pkey]
    pfk = pspec.parent_folder_key
    if pfk and pfk in folders:
      folders[pfk].children_projects.append(pkey)
    else:
      root_project_keys.append(pkey)

  return OrgSetupDataset(
      dataset_name=root.name,
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
