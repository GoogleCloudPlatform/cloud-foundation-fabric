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
"""FAST 0-org-setup -> SceneGraph builder (`hierarchy` view).

A top-to-bottom tree: the organization card, folder cards, and one
`@ProjectZone` per project holding cards for the resources the project YAML
declares (embedded VPCs, log buckets, BigQuery datasets, GCS buckets,
automation service accounts, CI/CD workload identity, KMS keyrings,
observability alerts/metrics, Shared VPC attachment). Folders and projects
whose parent lives outside the dataset hang under a dashed "external parent"
placeholder instead of the organization. An "Organization controls" column
docked on the left summarises org policies, custom roles and tags, org log
sinks (with one edge per destination resource) and the billing account (with
billing export edges).
"""

import pathlib
from typing import Dict, List, Optional, Union

from ..datasets.org_setup import (
    FolderSpec,
    OrgSetupDataset,
    OrgSink,
    ProjectSpec,
    load_org_setup_dataset,
)
from ..scene.model import (
    Badge,
    SceneGraph,
    ZoneNode,
    make_card,
    make_edge,
    make_zone,
    resolve_color,
)
from ._common import (
    BILLING_EXPORT_DATASET,
    MAX_CARD_BADGES_DEFAULT,
    MAX_ZONE_BADGES_DEFAULT,
    cap_badges,
    card_width_for,
    cid,
    join_limited,
    legend_card,
    legend_edge,
)

__all__ = [
    "MAX_CARD_BADGES_DEFAULT",
    "MAX_ZONE_BADGES_DEFAULT",
    "UNIFORM_BOX_WIDTH",
    "VIEWS",
    "build",
    "build_hierarchy",
]

VIEWS = ("hierarchy",)

# Folder cards and project zones share one outer width so sibling boxes line
# up; a box grows only when an identifier would not fit. A project zone has
# 18 px padding per side (inner cards 204 px); an embedded VPC zone adds 28 px
# per side (inner cards 148 px).
UNIFORM_BOX_WIDTH = 240.0
PROJECT_INNER_CARD_WIDTH = 204.0
VPC_INNER_CARD_WIDTH = 148.0

# Character budget for lists in 204 px card subtitles (whole items only).
_LIST_BUDGET = 24

# Fabric sink type -> project resource card the sink edge lands on. Sinks of
# type `project` (and destinations the project YAML does not declare) land
# on the project zone.
SINK_KIND_BY_TYPE = {
    "logging": "logging",
    "bigquery": "bigquery",
    "storage": "storage",
    "pubsub": "pubsub",
}

# Edge styles; within the view no two share a (dash, head) pair. The tree
# edges are plain lines (the layout already reads top to bottom).
_HIERARCHY_EDGE = ("$SlateStroke", "solid", "none")
_SINK_EDGE = ("$TealStroke", "dashdot", "filled")
_BILLING_EDGE = ("$BillingGreen", "dotted", "open")
_SVPC_EDGE = ("$GcpBlue", "solid", "filled")


def _plural(n: int, word: str) -> str:
  return f"{n} {word if n == 1 else word + 's'}"


def _sink_kind(sink: OrgSink) -> Optional[str]:
  return SINK_KIND_BY_TYPE.get(str(sink.sink_type or "").strip())


def _build_org_card_badges(ds: OrgSetupDataset,
                           verbose: bool = False) -> List[Badge]:
  """Org card badges: facts not already shown by the controls column first."""
  org = ds.organization
  cand: List[Badge] = []
  if org.data_access_logs:
    cand.append(
        Badge(text=f"DAL: {join_limited(org.data_access_logs, 24)}",
              tone="info"))
  if org.scc_sha_modules_count > 0:
    cand.append(Badge(text=f"{org.scc_sha_modules_count} SHA", tone="warn"))
  if org.contacts_count > 0:
    cand.append(
        Badge(text=_plural(org.contacts_count, "contact"), tone="neutral"))
  if verbose:
    # The counts below are also in the Organization controls cards.
    if org.org_policies_count > 0:
      cand.append(Badge(text=f"{org.org_policies_count} policies", tone="info"))
    if org.custom_constraints_count > 0:
      cand.append(
          Badge(text=f"{org.custom_constraints_count} custom", tone="warn"))
    if org.custom_roles_count > 0:
      cand.append(Badge(text=f"{org.custom_roles_count} roles", tone="neutral"))
    if org.tag_keys_count > 0:
      cand.append(
          Badge(
              text=(f"{_plural(org.tag_keys_count, 'tag')} "
                    f"({org.tag_values_count})"), tone="neutral"))
  return cap_badges(cand, MAX_CARD_BADGES_DEFAULT, verbose)


def _build_folder_badges(fspec: FolderSpec,
                         verbose: bool = False) -> List[Badge]:
  cand: List[Badge] = []
  for pill in fspec.tag_pills:
    short_pill = pill.replace("environment=",
                              "env=").replace("project-factory", "pf")
    cand.append(Badge(text=short_pill, tone="info"))
  if fspec.has_iam:
    cand.append(Badge(text="IAM", tone="neutral"))
  if fspec.org_policies_count > 0:
    cand.append(Badge(text=f"{fspec.org_policies_count} policies", tone="warn"))
  if fspec.has_scc_sha:
    cand.append(Badge(text="SCC SHA", tone="warn"))
  return cap_badges(cand, 2 if not verbose else MAX_CARD_BADGES_DEFAULT,
                    verbose)


def _build_project_zone_badges(proj: ProjectSpec,
                               verbose: bool = False) -> List[Badge]:
  """@ProjectZone header badges; none by default so boxes keep their width."""
  if not verbose:
    return []
  cand: List[Badge] = []
  if proj.shared_vpc_host:
    cand.append(Badge(text="Shared VPC host", tone="info"))
  if proj.shared_vpc_service_of:
    cand.append(
        Badge(text=f"service of {proj.shared_vpc_service_of}", tone="info"))
  if proj.is_observability_project:
    cand.append(Badge(text="Observability project", tone="info"))
  if proj.iam_principals_count > 0:
    cand.append(Badge(text=f"IAM: {proj.iam_principals_count}", tone="neutral"))
  if proj.services:
    cand.append(Badge(text=f"{len(proj.services)} APIs", tone="neutral"))
  return cap_badges(cand, MAX_ZONE_BADGES_DEFAULT, verbose)


def _edge(src: str, dst: str, style, label: str = "", **kw):
  color, dash, head = style
  return make_edge(src, dst, arrow="-.->" if dash != "solid" else "-->",
                   label=label, color=color,
                   stroke_width=kw.pop("stroke_width", 1.8), dashed=dash
                   != "solid", dash=dash, head=head, **kw)


def _tree_edge(src: str, dst: str):
  return _edge(src, dst, _HIERARCHY_EDGE, source_anchor="bottom",
               target_anchor="top")


def build_hierarchy(
    dataset: Union[str, pathlib.Path, OrgSetupDataset],
    dataset_name: Optional[str] = None,
    *,
    verbose_badges: bool = False,
    legend: bool = True,
    cicd_workflows: Optional[str] = None,
) -> SceneGraph:
  """Builds the 0-org-setup hierarchy tree with its controls column.

  `cicd_workflows` is the stage `factories_config.paths.cicd_workflows` file
  (relative to the dataset); unset, like the stage default, means no CI/CD
  workflows are read.
  """
  if isinstance(dataset, OrgSetupDataset):
    if cicd_workflows is not None:
      raise ValueError("cicd_workflows applies when loading a dataset path, "
                       "not to an already loaded OrgSetupDataset")
    ds = dataset
  else:
    paths = {"cicd_workflows": cicd_workflows} if cicd_workflows else None
    ds = load_org_setup_dataset(dataset, paths=paths)

  name = dataset_name or ds.dataset_name
  scene = SceneGraph(dataset_name=name, view_kind="hierarchy",
                     stage="0-org-setup")

  org = ds.organization
  org_title = f"Organization: {org.domain}" if org.domain else "Organization"
  sub_parts: List[str] = []
  if org.id:
    sub_parts.append(f"id: {org.id}")
  if org.prefix:
    sub_parts.append(f"prefix: {org.prefix}")
  org_subtitle = " · ".join(sub_parts)

  # Sinks grouped by destination project and kind, needed while projects are
  # emitted so that every destination gets a card to land on.
  sinks_by_dest: Dict[str, Dict[str, List[OrgSink]]] = {}
  for sk in org.sinks:
    if sk.target_project and sk.target_project in ds.projects:
      sinks_by_dest.setdefault(sk.target_project,
                               {}).setdefault(_sink_kind(sk) or "",
                                              []).append(sk)

  # The tree is an invisible column: organization, folders, projects.
  main_tree = scene.add_zone(
      make_zone("main_tree", "@Ghost", layout="column", gap=52.0,
                align="center"))
  org_tier = scene.add_zone(
      make_zone("tier_org", "@Ghost", layout="column", gap=16.0,
                align="center"), parent=main_tree)
  org_card = scene.add_card(
      make_card(
          "org_root_card",
          org_title,
          org_subtitle,
          style="@HubCard",
          icon="Organization",
          width=card_width_for(org_title, org_subtitle, 280.0),
          stroke_color="$SlateStroke",
          stroke_width=2.0,
          badges=_build_org_card_badges(ds, verbose=verbose_badges),
      ), parent=org_tier)

  # Edge anchors per project, keyed by project key.
  project_zone_id: Dict[str, str] = {}
  project_dest_card: Dict[str, Dict[str, str]] = {}
  project_svpc_src_card: Dict[str, str] = {}
  project_vpc_zone_id: Dict[str, str] = {}

  def inner_card(card_id, title, subtitle, icon, parent, **kw):
    return scene.add_card(
        make_card(
            card_id, title, subtitle, style=kw.pop("style", "@ProductCard"),
            icon=icon, width=card_width_for(title, subtitle,
                                            PROJECT_INNER_CARD_WIDTH),
            height=52.0, **kw), parent=parent)

  def emit_project_zone(pkey: str, parent_zone: ZoneNode) -> ZoneNode:
    """Emits the @ProjectZone of `pkey` with its resource cards."""
    pspec = ds.projects[pkey]
    pzone = scene.add_zone(
        make_zone(
            cid("proj_zone", pspec.key),
            "@ProjectZone",
            title=pspec.key,
            subtitle=pspec.name if pspec.name != pspec.key else "",
            icon="Project",
            layout="column",
            gap=8.0,
            align="center",
            badges=_build_project_zone_badges(pspec, verbose=verbose_badges),
        ),
        parent=parent_zone,
    )
    project_zone_id[pkey] = pzone.id
    dest = project_dest_card.setdefault(pkey, {})
    sink_dest = sinks_by_dest.get(pkey, {})
    has_inner = False

    for vspec in pspec.vpcs:
      vzone = scene.add_zone(
          make_zone(
              cid("vpc_zone", pspec.key, vspec.key),
              "@VpcZone",
              title=vspec.name,
              icon="VirtualPrivateCloud",
              layout="column",
              gap=8.0,
              align="center",
          ),
          parent=pzone,
      )
      project_vpc_zone_id.setdefault(pkey, vzone.id)
      if vspec.subnets:
        v_sub = join_limited((s.ip_cidr_range or s.name for s in vspec.subnets),
                             16)
      else:
        v_sub = f"{vspec.ingress_rule_count} fw rules"
      scene.add_card(
          make_card(
              cid("vpc_card", pspec.key, vspec.key),
              "Subnets/FW",
              v_sub,
              style="@ProductCard",
              icon="Subnet",
              width=card_width_for("Subnets/FW", v_sub, VPC_INNER_CARD_WIDTH),
              height=50.0,
          ),
          parent=vzone,
      )
      has_inner = True

    # The `_Default` bucket entry only configures the built-in bucket.
    buckets = [b for b in pspec.log_buckets if b != "_Default"]
    if buckets:
      lb_badges = ([Badge(text="CMEK", tone="warn")]
                   if pspec.log_buckets_cmek else [])
      c_lb = inner_card(cid("proj_log_buckets",
                            pspec.key), f"Log Buckets ({len(buckets)})",
                        join_limited(buckets, _LIST_BUDGET), "CloudLogging",
                        pzone, badges=lb_badges)
      dest["logging"] = c_lb.id
      has_inner = True

    if pspec.datasets:
      bq_badges = ([Badge(text="CMEK", tone="warn")]
                   if pspec.datasets_cmek else [])
      title = ("BigQuery Dataset" if len(pspec.datasets) == 1 else
               f"BigQuery Datasets ({len(pspec.datasets)})")
      c_bq = inner_card(cid("proj_bq", pspec.key), title,
                        join_limited(pspec.datasets, _LIST_BUDGET), "BigQuery",
                        pzone, badges=bq_badges)
      dest["bigquery"] = c_bq.id
      has_inner = True

    if pspec.buckets:
      c_gcs = inner_card(cid("proj_gcs",
                             pspec.key), f"GCS Buckets ({len(pspec.buckets)})",
                         join_limited(pspec.buckets, _LIST_BUDGET),
                         "CloudStorage", pzone)
      dest["storage"] = c_gcs.id
      has_inner = True

    if sink_dest.get("pubsub"):
      topics = sorted(
          {sk.target_resource or sk.name for sk in sink_dest["pubsub"]})
      c_ps = inner_card(cid("proj_pubsub",
                            pspec.key), f"Pub/Sub Topics ({len(topics)})",
                        join_limited(topics, _LIST_BUDGET), "CloudGeneric",
                        pzone)
      dest["pubsub"] = c_ps.id
      has_inner = True

    if pspec.service_accounts:
      sa_cnt = len(pspec.service_accounts)
      inner_card(cid("proj_sas", pspec.key), f"Automation SAs ({sa_cnt})",
                 join_limited(pspec.service_accounts, _LIST_BUDGET),
                 "ServiceAccount", pzone)
      has_inner = True

    for wf in pspec.cicd_workflows:
      repo_desc = f"{wf.repo_type} {wf.repo_name}".strip() or wf.name
      inner_card(cid("proj_cicd", pspec.key, wf.name), "CI/CD WIF", repo_desc,
                 "WorkloadIdentity", pzone)
      has_inner = True

    if pspec.kms_keyrings or pspec.cmek_services:
      kms_items = pspec.kms_keyrings or list(pspec.cmek_services.keys())
      inner_card(cid("proj_kms", pspec.key), "KMS Keyring",
                 join_limited(kms_items, _LIST_BUDGET), "KeyManagementService",
                 pzone, badges=[Badge(text="CMEK", tone="warn")])
      has_inner = True

    obs_alerts = pspec.observability_alerts_count
    obs_metrics = pspec.observability_metrics_count
    if pspec.has_observability_factory and (obs_alerts or obs_metrics):
      inner_card(cid("proj_obs", pspec.key), "Observability",
                 f"{obs_alerts} alerts · {obs_metrics} metrics",
                 "CloudMonitoring", pzone)
      has_inner = True

    if pspec.shared_vpc_service_of:
      c_svpc = inner_card(cid("proj_svpc_svc", pspec.key), "Shared VPC Service",
                          f"host: {pspec.shared_vpc_service_of}",
                          "VirtualPrivateCloud", pzone)
      project_svpc_src_card[pkey] = c_svpc.id
      has_inner = True

    if not has_inner:
      svcs_sub = (f"{len(pspec.services)} enabled APIs"
                  if pspec.services else "no resources declared")
      inner_card(cid("proj", pspec.key), pspec.key, svcs_sub, "Project", pzone,
                 style="@ProjectCard")

    return pzone

  def emit_projects_row(row_id: str, pkeys: List[str], parent_zone: ZoneNode,
                        parent_card_id: str, gap: float) -> None:
    row = scene.add_zone(
        make_zone(row_id, "@Ghost", layout="row", gap=gap, align="start"),
        parent=parent_zone)
    for pk in pkeys:
      pzone = emit_project_zone(pk, row)
      scene.add_edge(_tree_edge(parent_card_id, pzone.id))

  def emit_folder_branch(fkey: str, parent_zone: ZoneNode,
                         parent_card_id: str) -> ZoneNode:
    """Emits folder `fkey` with sub-folders and projects in sibling rows."""
    fspec = ds.folders[fkey]
    branch_col = scene.add_zone(
        make_zone(
            cid("branch_folder", fspec.key),
            "@Ghost",
            layout="column",
            gap=44.0,
            align="center",
        ),
        parent=parent_zone,
    )
    f_sub = fspec.key if fspec.key.lower() != fspec.name.lower() else "folder"
    fcard = scene.add_card(
        make_card(
            cid("folder_card", fspec.key),
            fspec.name,
            f_sub,
            style="@ProjectCard",
            icon="Folder",
            width=card_width_for(fspec.name, f_sub, UNIFORM_BOX_WIDTH),
            height=50.0,
            stroke_color="$FolderGrey",
            stroke_width=1.5,
            fill=resolve_color("$FolderFill"),
            badges=_build_folder_badges(fspec, verbose=verbose_badges),
        ),
        parent=branch_col,
    )
    scene.add_edge(_tree_edge(parent_card_id, fcard.id))

    if fspec.children_folders:
      sub_row = scene.add_zone(
          make_zone(
              cid("subfolders_row", fspec.key),
              "@Ghost",
              layout="row",
              gap=20.0,
              align="start",
          ),
          parent=branch_col,
      )
      for cfk in fspec.children_folders:
        emit_folder_branch(cfk, sub_row, fcard.id)

    if fspec.children_projects:
      emit_projects_row(cid("folder_projects_row", fspec.key),
                        list(fspec.children_projects), branch_col, fcard.id,
                        44.0)
    return branch_col

  # Folders and projects whose parent is outside the dataset.
  external: Dict[str, Dict[str, List[str]]] = {}
  for fkey in ds.root_folder_keys:
    ext = ds.folders[fkey].parent_external
    if ext:
      external.setdefault(ext, {
          "folders": [],
          "projects": []
      })["folders"].append(fkey)
  for pkey in ds.root_project_keys:
    ext = ds.projects[pkey].parent_external
    if ext:
      external.setdefault(ext, {
          "folders": [],
          "projects": []
      })["projects"].append(pkey)
  ext_folders = {k for v in external.values() for k in v["folders"]}
  ext_projects = {k for v in external.values() for k in v["projects"]}
  org_folders = [k for k in ds.root_folder_keys if k not in ext_folders]
  org_projects = [k for k in ds.root_project_keys if k not in ext_projects]

  if org_folders or external:
    folders_row = scene.add_zone(
        make_zone(
            "tier_folders",
            "@Ghost",
            layout="row",
            gap=32.0,
            align="start",
        ),
        parent=main_tree,
    )
    for rfk in org_folders:
      emit_folder_branch(rfk, folders_row, org_card.id)
    for ext in sorted(external):
      ext_col = scene.add_zone(
          make_zone(cid("branch_external", ext), "@Ghost", layout="column",
                    gap=44.0, align="center"), parent=folders_row)
      ext_card = scene.add_card(
          make_card(
              cid("external_parent", ext),
              "External parent",
              ext,
              style="@ProjectCard",
              icon="Folder",
              width=card_width_for("External parent", ext, UNIFORM_BOX_WIDTH),
              height=50.0,
              stroke_color="$FolderGrey",
              stroke_width=1.5,
              dashed=True,
              badges=[Badge(text="outside dataset", tone="neutral")],
          ), parent=ext_col)
      members = external[ext]
      if members["folders"]:
        sub_row = scene.add_zone(
            make_zone(cid("external_folders_row", ext), "@Ghost", layout="row",
                      gap=20.0, align="start"), parent=ext_col)
        for fk in members["folders"]:
          emit_folder_branch(fk, sub_row, ext_card.id)
      if members["projects"]:
        emit_projects_row(cid("external_projects_row", ext),
                          members["projects"], ext_col, ext_card.id, 44.0)

  if org_projects:
    # Projects that hold sink or billing export destinations sit on the left,
    # closest to the Organization controls column.
    ordered = sorted(
        org_projects,
        key=lambda pk: (0 if ds.projects[pk].log_buckets else
                        (1 if ds.projects[pk].datasets else 2), pk),
    )
    emit_projects_row("org_root_projects", ordered, main_tree, org_card.id,
                      24.0)

  # Organization controls: implicit org-level settings, no edge to the org.
  controls_zone = scene.add_zone(
      make_zone(
          "org_controls",
          "@SubGroupWhite",
          title="Organization controls",
          layout="column",
          gap=10.0,
          align="center",
          dock_to="main_tree",
          dock_side="left",
          dock_align="start",
          dock_gap=44.0,
      ))

  def control_card(card_id, title, subtitle, icon):
    return scene.add_card(
        make_card(
            card_id, title, subtitle, style="@OrgControlCard", icon=icon,
            width=card_width_for(title, subtitle, PROJECT_INNER_CARD_WIDTH)),
        parent=controls_zone)

  pol_sub = f"{org.org_policies_count} policies"
  if org.custom_constraints_count > 0:
    pol_sub += f" · {org.custom_constraints_count} custom"
  control_card("ctrl_org_policies", "Org Policies", pol_sub,
               "OrganizationPolicy")
  control_card(
      "ctrl_custom_roles", "Custom Roles & Tags",
      f"{_plural(org.custom_roles_count, 'role')} · "
      f"{_plural(org.tag_keys_count, 'tag')} ({org.tag_values_count})", "IAM")

  c_sinks = control_card(
      "ctrl_log_sinks", f"Org Log Sinks ({len(org.sinks)})",
      join_limited((s.name for s in org.sinks), _LIST_BUDGET,
                   empty="no org sinks"), "CloudLogging")
  for t_proj in sorted(sinks_by_dest):
    for kind in sorted(sinks_by_dest[t_proj]):
      # A destination the project YAML does not declare lands on the zone.
      dst = (project_dest_card.get(t_proj, {}).get(kind) or
             project_zone_id[t_proj])
      n = len(sinks_by_dest[t_proj][kind])
      scene.add_edge(
          _edge(c_sinks.id, dst, _SINK_EDGE,
                "logsink" if n == 1 else f"logsink ({n})"))

  if ds.billing_accounts:
    bzone = scene.add_zone(
        make_zone(
            "billing_zone",
            "@BillingZone",
            title=("Billing Account" if len(ds.billing_accounts) == 1 else
                   f"Billing Accounts ({len(ds.billing_accounts)})"),
            icon="BillingAccount",
            layout="column",
            gap=8.0,
            align="center",
        ),
        parent=controls_zone,
    )
    billing_cards: Dict[str, str] = {}
    for ba in ds.billing_accounts:
      ba_sub = (
          f"{_plural(ba.iam_bindings_additive_count, 'additive IAM binding')}"
          if ba.iam_bindings_additive_count > 0 else
          ("Org billing account"
           if ba.id == org.billing_account_id else "Billing account"))
      bcard = scene.add_card(
          make_card(
              cid("billing_acct", ba.key),
              ba.id,
              ba_sub,
              style="@ProductCard",
              icon="BillingAccount",
              width=card_width_for(ba.id, ba_sub, 180.0),
              stroke_color="$BillingGreen",
              stroke_width=1.5,
          ),
          parent=bzone,
      )
      billing_cards[ba.id] = bcard.id
    # The export dataset receives the organization's billing account data.
    export_src = billing_cards.get(
        org.billing_account_id) or billing_cards[ds.billing_accounts[0].id]
    for pkey, pspec in ds.projects.items():
      if BILLING_EXPORT_DATASET in pspec.datasets:
        dst_bq = project_dest_card.get(pkey, {}).get("bigquery")
        if dst_bq:
          scene.add_edge(
              _edge(export_src, dst_bq, _BILLING_EDGE, "billing export"))

  for pkey, pspec in ds.projects.items():
    host_key = pspec.shared_vpc_service_of
    if not host_key:
      continue
    src_cid = project_svpc_src_card.get(pkey)
    dst_zid = project_vpc_zone_id.get(host_key) or project_zone_id.get(host_key)
    if src_cid and dst_zid:
      scene.add_edge(
          _edge(src_cid, dst_zid, _SVPC_EDGE, "Shared VPC service",
                stroke_width=2.0))

  if legend:
    labels = {e.label.split(" (")[0] for e in scene.edges}
    entries = [
        legend_edge("Resource hierarchy parent → child", *_HIERARCHY_EDGE)
    ]
    if "logsink" in labels:
      entries.append(legend_edge("Org log sink routing", *_SINK_EDGE))
    if "billing export" in labels:
      entries.append(legend_edge("BigQuery billing export", *_BILLING_EDGE))
    if "Shared VPC service" in labels:
      entries.append(legend_edge("Shared VPC service → host VPC", *_SVPC_EDGE))
    if external:
      entries.append(
          legend_card("Parent outside the dataset", "$FolderGrey", dashed=True))
    scene.legend = entries

  return scene


def build(
    dataset: Union[str, pathlib.Path, OrgSetupDataset],
    view: str = "hierarchy",
    dataset_name: Optional[str] = None,
    *,
    verbose_badges: bool = False,
    legend: bool = True,
    cicd_workflows: Optional[str] = None,
) -> SceneGraph:
  """Returns the SceneGraph for `view` of a 0-org-setup dataset."""
  if view != "hierarchy":
    raise ValueError(f"unknown 0-org-setup view: {view!r} (expected {VIEWS})")
  return build_hierarchy(
      dataset,
      dataset_name=dataset_name,
      verbose_badges=verbose_badges,
      legend=legend,
      cicd_workflows=cicd_workflows,
  )
