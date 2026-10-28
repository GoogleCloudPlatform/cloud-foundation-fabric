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

"""FAST 0-org-setup -> SceneGraph builder (top-to-bottom hierarchy tree + lateral controls)."""

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
    CardNode,
    LegendEntry,
    SceneGraph,
    ZoneNode,
    make_card,
    make_edge,
    make_zone,
)

__all__ = ["VIEWS", "build", "build_hierarchy"]

VIEWS = ("hierarchy",)

MAX_CARD_BADGES_DEFAULT = 4
MAX_ZONE_BADGES_DEFAULT = 6

# Fixed outer width for every Folder card and every @ProjectZone container (§24 item 3):
# - @ProjectZone has padding = 18.0 (left 18 + right 18 = 36.0), so inner cards have width 204.0 -> 204.0 + 36.0 = 240.0.
# - @VpcZone inside @ProjectZone has padding = 28.0 (left 28 + right 28 = 56.0), so its inner card has width 148.0 -> 148.0 + 56.0 + 36.0 = 240.0.
UNIFORM_BOX_WIDTH = 240.0
PROJECT_INNER_CARD_WIDTH = 204.0
VPC_INNER_CARD_WIDTH = 148.0


def _cid(prefix: str, *parts: Optional[str]) -> str:
  raw = "_".join([prefix] + [str(p) for p in parts if p is not None and str(p) != ""])
  return "".join(ch if ch.isalnum() else "_" for ch in raw)


def _cap_badges(badges: List[Badge], limit: int, verbose: bool) -> List[Badge]:
  if verbose or len(badges) <= limit:
    return list(badges)
  if limit <= 1:
    return [Badge(text=f"+{len(badges)}", tone="neutral")]
  kept = list(badges[: limit - 1])
  kept.append(Badge(text=f"+{len(badges) - (limit - 1)}", tone="neutral"))
  return kept


def _clean_region(reg: str) -> str:
  if not reg or "<" in reg or ">" in reg:
    return "regional"
  return reg


def _build_org_card_badges(ds: OrgSetupDataset, verbose: bool = False) -> List[Badge]:
  org = ds.organization
  cand: List[Badge] = []
  if org.org_policies_count > 0:
    cand.append(Badge(text=f"{org.org_policies_count} policies", tone="info"))
  if org.custom_constraints_count > 0:
    cand.append(Badge(text=f"{org.custom_constraints_count} custom", tone="warn"))
  if org.custom_roles_count > 0:
    cand.append(Badge(text=f"{org.custom_roles_count} roles", tone="neutral"))
  if org.tag_keys_count > 0:
    cand.append(
        Badge(
            text=f"{org.tag_keys_count} tags ({org.tag_values_count})",
            tone="neutral",
        )
    )
  if org.data_access_logs:
    dal_str = ", ".join(org.data_access_logs[:1])
    cand.append(Badge(text=f"DAL: {dal_str}", tone="info"))
  if org.scc_sha_modules_count > 0:
    cand.append(Badge(text=f"{org.scc_sha_modules_count} SHA", tone="warn"))
  if verbose and org.contacts_count > 0:
    cand.append(Badge(text=f"{org.contacts_count} contacts", tone="neutral"))
  return _cap_badges(cand, MAX_CARD_BADGES_DEFAULT, verbose)


def _build_folder_badges(fspec: FolderSpec, verbose: bool = False) -> List[Badge]:
  cand: List[Badge] = []
  for pill in fspec.tag_pills:
    short_pill = pill.replace("environment=", "env=").replace("project-factory", "pf")
    cand.append(Badge(text=short_pill, tone="info"))
  if fspec.has_iam:
    cand.append(Badge(text="IAM", tone="neutral"))
  if fspec.org_policies_count > 0:
    cand.append(Badge(text=f"{fspec.org_policies_count} policies", tone="warn"))
  if fspec.has_scc_sha:
    cand.append(Badge(text="SCC SHA", tone="warn"))
  return _cap_badges(cand, 2 if not verbose else MAX_CARD_BADGES_DEFAULT, verbose)


def _build_project_zone_badges(proj: ProjectSpec, verbose: bool = False) -> List[Badge]:
  """Builds @ProjectZone header badges (0 by default so outer width stays 240.0 px)."""
  if not verbose:
    return []
  cand: List[Badge] = []
  if proj.shared_vpc_host:
    cand.append(Badge(text="Shared VPC host", tone="info"))
  if proj.shared_vpc_service_of:
    cand.append(Badge(text=f"service of {proj.shared_vpc_service_of}", tone="info"))
  if proj.is_observability_project:
    cand.append(Badge(text="Observability project", tone="info"))
  if proj.iam_principals_count > 0:
    cand.append(Badge(text=f"IAM: {proj.iam_principals_count}", tone="neutral"))
  if proj.services:
    cand.append(Badge(text=f"{len(proj.services)} APIs", tone="neutral"))
  return _cap_badges(cand, MAX_ZONE_BADGES_DEFAULT, verbose)


def build_hierarchy(
    dataset: Union[str, pathlib.Path, OrgSetupDataset],
    dataset_name: Optional[str] = None,
    *,
    verbose_badges: bool = False,
    legend: bool = True,
) -> SceneGraph:
  """Builds the top-to-bottom tree + lateral controls 0-org-setup SceneGraph."""
  if isinstance(dataset, OrgSetupDataset):
    ds = dataset
  else:
    ds = load_org_setup_dataset(dataset)

  name = dataset_name or ds.dataset_name
  scene = SceneGraph(dataset_name=name, view_kind="hierarchy", stage="0-org-setup")

  org = ds.organization
  org_title = f"Organization: {org.domain}" if org.domain else "Organization"
  sub_parts: List[str] = []
  if org.id:
    sub_parts.append(f"id: {org.id}")
  if org.prefix:
    sub_parts.append(f"prefix: {org.prefix}")
  org_subtitle = " · ".join(sub_parts)

  # Main hierarchy tree zone (invisible @Ghost vertical tree so Organization,
  # Folders, and Projects are tree nodes connected by parent->child edges).
  main_tree = scene.add_zone(
      make_zone(
          "main_tree",
          "@Ghost",
          layout="column",
          gap=52.0,
          align="center",
      )
  )

  # Tier 0: Organization root card at the top of the tree
  org_tier = scene.add_zone(
      make_zone(
          "tier_org",
          "@Ghost",
          layout="column",
          gap=16.0,
          align="center",
      ),
      parent=main_tree,
  )
  org_card = scene.add_card(
      make_card(
          "org_root_card",
          org_title,
          org_subtitle,
          style="@HubCard",
          icon="Organization",
          width=280.0,
          stroke_color="$SlateStroke",
          stroke_width=2.0,
          badges=_build_org_card_badges(ds, verbose=verbose_badges),
      ),
      parent=org_tier,
  )

  # Track IDs for semantic edges:
  # - folder_card_id[fkey]: the tree card representing folder `fkey`
  # - project_zone_id[pkey]: the outer `@ProjectZone` ID for `Organization/Folder -> Project` edges
  # - project_log_card[pkey]: the `[Log Buckets]` card inside `@ProjectZone` for log sink edges
  # - project_bq_card[pkey]: the `[BigQuery Dataset]` card inside `@ProjectZone` for billing export edges
  # - project_svpc_src_card[pkey]: the `[Shared VPC Service]` card inside a service project
  # - project_vpc_zone_id[pkey]: the `@VpcZone` ID inside a host project for Shared VPC edges
  folder_card_id: Dict[str, str] = {}
  project_zone_id: Dict[str, str] = {}
  project_log_card: Dict[str, str] = {}
  project_bq_card: Dict[str, str] = {}
  project_svpc_src_card: Dict[str, str] = {}
  project_vpc_zone_id: Dict[str, str] = {}

  def emit_project_zone(pkey: str, parent_zone: ZoneNode) -> ZoneNode:
    """Emits a 240px-wide @ProjectZone container with its internal resource cards."""
    pspec = ds.projects[pkey]
    # Keep title <= 18 chars so layout_scene min_title_w (len*9 + 70) <= 240.0
    z_title = f"Project: {pspec.key}"
    if len(z_title) > 18:
      z_title = f"Project {pspec.key}"
    z_sub = pspec.name if len(pspec.name) <= 22 else pspec.name[:22]

    pzone = scene.add_zone(
        make_zone(
            _cid("proj_zone", pspec.key),
            "@ProjectZone",
            title=z_title,
            subtitle=z_sub,
            icon="Project",
            layout="column",
            gap=8.0,
            align="center",
            badges=_build_project_zone_badges(pspec, verbose=verbose_badges),
        ),
        parent=parent_zone,
    )
    project_zone_id[pkey] = pzone.id
    has_inner = False

    # 1. Embedded VPCs (e.g. starter-gcd dev-net-0 / prod-net-0)
    for vspec in pspec.vpcs:
      vzone = scene.add_zone(
          make_zone(
              _cid("vpc_zone", pspec.key, vspec.key),
              "@VpcZone",
              title=vspec.name[:13],
              icon="VirtualPrivateCloud",
              layout="column",
              gap=8.0,
              align="center",
          ),
          parent=pzone,
      )
      if pkey not in project_vpc_zone_id:
        project_vpc_zone_id[pkey] = vzone.id
      if vspec.subnets:
        s0 = vspec.subnets[0]
        v_sub = s0.ip_cidr_range or s0.name
      else:
        v_sub = f"{vspec.ingress_rule_count} fw rules"
      scene.add_card(
          make_card(
              _cid("vpc_card", pspec.key, vspec.key),
              "Subnets/FW",
              v_sub[:14],
              style="@ProductCard",
              icon="Subnet",
              width=VPC_INNER_CARD_WIDTH,
              height=50.0,
          ),
          parent=vzone,
      )
      has_inner = True

    # 2. Log buckets (e.g. log-0 in classic/hardened, iac-0 in starter-gcd)
    if pspec.log_buckets:
      non_def = [b for b in pspec.log_buckets if b != "_Default"]
      shown = non_def if non_def else pspec.log_buckets
      lb_sub = ", ".join(shown[:3])
      if len(lb_sub) > 22:
        lb_sub = f"{len(shown)} log buckets"
      lb_badges = [Badge(text="CMEK", tone="warn")] if pspec.log_buckets_cmek else []
      c_lb = scene.add_card(
          make_card(
              _cid("proj_log_buckets", pspec.key),
              f"Log Buckets ({len(shown)})",
              lb_sub,
              style="@ProductCard",
              icon="CloudLogging",
              width=PROJECT_INNER_CARD_WIDTH,
              height=52.0,
              badges=lb_badges,
          ),
          parent=pzone,
      )
      project_log_card[pkey] = c_lb.id
      has_inner = True

    # 3. BigQuery datasets (e.g. billing-0 in classic/hardened, iac-0 in starter-gcd)
    if pspec.datasets:
      bq_sub = ", ".join(pspec.datasets[:2])[:22]
      bq_badges = [Badge(text="CMEK", tone="warn")] if pspec.datasets_cmek else []
      c_bq = scene.add_card(
          make_card(
              _cid("proj_bq", pspec.key),
              "BigQuery Dataset",
              bq_sub,
              style="@ProductCard",
              icon="BigQuery",
              width=PROJECT_INNER_CARD_WIDTH,
              height=52.0,
              badges=bq_badges,
          ),
          parent=pzone,
      )
      project_bq_card[pkey] = c_bq.id
      has_inner = True

    # 4. GCS buckets (e.g. iac-0 state & outputs buckets)
    if pspec.buckets:
      b_sub = f"{len(pspec.buckets)} state/output buckets"
      scene.add_card(
          make_card(
              _cid("proj_gcs", pspec.key),
              f"GCS Buckets ({len(pspec.buckets)})",
              b_sub,
              style="@ProductCard",
              icon="CloudStorage",
              width=PROJECT_INNER_CARD_WIDTH,
              height=52.0,
          ),
          parent=pzone,
      )
      has_inner = True

    # 5. Service accounts (e.g. iac-0 stage automation SAs)
    if pspec.service_accounts:
      sa_cnt = len(pspec.service_accounts)
      sa_sub = f"{sa_cnt} stage SAs"
      scene.add_card(
          make_card(
              _cid("proj_sas", pspec.key),
              f"Automation SAs ({sa_cnt})",
              sa_sub,
              style="@ProductCard",
              icon="ServiceAccount",
              width=PROJECT_INNER_CARD_WIDTH,
              height=52.0,
          ),
          parent=pzone,
      )
      has_inner = True

    # 6. CI/CD Workload Identity Federation (when cicd.yaml points to this project)
    for wf in pspec.cicd_workflows:
      repo_desc = f"{wf.repo_type} {wf.repo_name}".strip()[:22] or wf.name[:22]
      scene.add_card(
          make_card(
              _cid("proj_cicd", pspec.key, wf.name),
              "CI/CD WIF",
              repo_desc,
              style="@ProductCard",
              icon="WorkloadIdentity",
              width=PROJECT_INNER_CARD_WIDTH,
              height=52.0,
          ),
          parent=pzone,
      )
      has_inner = True

    # 7. KMS keyring / CMEK keys (e.g. hardened log-0, billing-0, iac-0)
    if pspec.kms_keyrings or pspec.cmek_services:
      if pspec.kms_keyrings:
        kms_sub = ", ".join(pspec.kms_keyrings[:2])[:22]
      else:
        kms_sub = ", ".join(pspec.cmek_services.keys())[:22]
      scene.add_card(
          make_card(
              _cid("proj_kms", pspec.key),
              "KMS Keyring",
              kms_sub,
              style="@ProductCard",
              icon="KeyManagementService",
              width=PROJECT_INNER_CARD_WIDTH,
              height=52.0,
              badges=[Badge(text="CMEK", tone="warn")],
          ),
          parent=pzone,
      )
      has_inner = True

    # 8. Observability factory (alerts & logging metrics)
    if pspec.has_observability_factory:
      obs_sub = (
          f"{pspec.observability_alerts_count} alerts · "
          f"{pspec.observability_metrics_count} metrics"
      )
      scene.add_card(
          make_card(
              _cid("proj_obs", pspec.key),
              "Observability",
              obs_sub,
              style="@ProductCard",
              icon="CloudMonitoring",
              width=PROJECT_INNER_CARD_WIDTH,
              height=52.0,
          ),
          parent=pzone,
      )
      has_inner = True

    # 9. Shared VPC service attachment card (e.g. starter-gcd dev-app-0 / prod-app-0)
    if pspec.shared_vpc_service_of:
      svpc_sub = f"host: {pspec.shared_vpc_service_of}"[:22]
      c_svpc = scene.add_card(
          make_card(
              _cid("proj_svpc_svc", pspec.key),
              "Shared VPC Service",
              svpc_sub,
              style="@ProductCard",
              icon="VirtualPrivateCloud",
              width=PROJECT_INNER_CARD_WIDTH,
              height=52.0,
          ),
          parent=pzone,
      )
      project_svpc_src_card[pkey] = c_svpc.id
      has_inner = True

    # Fallback if a project has no specific internal resource cards (e.g. bare project fixture)
    if not has_inner:
      svcs_sub = (
          f"{len(pspec.services)} enabled APIs"
          if pspec.services
          else pspec.name[:22]
      )
      scene.add_card(
          make_card(
              _cid("proj", pspec.key),
              pspec.key[:18],
              svcs_sub,
              style="@ProjectCard",
              icon="Project",
              width=PROJECT_INNER_CARD_WIDTH,
              height=52.0,
          ),
          parent=pzone,
      )

    return pzone

  def emit_folder_branch(
      fkey: str, parent_zone: ZoneNode, parent_card_id: str
  ) -> ZoneNode:
    """Emits a tree branch for folder `fkey`, with sibling sub-folders and sibling projects in rows."""
    fspec = ds.folders[fkey]
    branch_col = scene.add_zone(
        make_zone(
            _cid("branch_folder", fspec.key),
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
            _cid("folder_card", fspec.key),
            f"Folder: {fspec.name}"[:19],
            f_sub[:22],
            style="@ProjectCard",
            icon="Folder",
            width=UNIFORM_BOX_WIDTH,
            height=50.0,
            stroke_color="$FolderGrey",
            stroke_width=1.5,
            fill="#f1f3f4",
            badges=_build_folder_badges(fspec, verbose=verbose_badges),
        ),
        parent=branch_col,
    )
    folder_card_id[fkey] = fcard.id

    # Tree edge: parent (Organization or parent Folder) -> this Folder card
    scene.add_edge(
        make_edge(
            parent_card_id,
            fcard.id,
            arrow="-->",
            label="",
            color="$SlateStroke",
            stroke_width=1.8,
            dashed=False,
            dash="solid",
            head="filled",
            source_anchor="bottom",
            target_anchor="top",
        )
    )

    # All sibling sub-folders MUST sit at the same Y height (layout="row", §24 item 2)
    if fspec.children_folders:
      sub_row = scene.add_zone(
          make_zone(
              _cid("subfolders_row", fspec.key),
              "@Ghost",
              layout="row",
              gap=20.0,
              align="start",
          ),
          parent=branch_col,
      )
      for cfk in fspec.children_folders:
        emit_folder_branch(cfk, sub_row, fcard.id)

    # All sibling projects under this folder MUST sit at the same Y height (layout="row", §25 item 2)
    # and Folder -> Project edges target the outer @ProjectZone box (§25 item 1).
    if fspec.children_projects:
      proj_row = scene.add_zone(
          make_zone(
              _cid("folder_projects_row", fspec.key),
              "@Ghost",
              layout="row",
              gap=44.0,
              align="start",
          ),
          parent=branch_col,
      )
      for cpk in fspec.children_projects:
        pzone = emit_project_zone(cpk, proj_row)
        scene.add_edge(
            make_edge(
                fcard.id,
                pzone.id,
                arrow="-->",
                label="",
                color="$SlateStroke",
                stroke_width=1.8,
                dashed=False,
                dash="solid",
                head="filled",
                source_anchor="bottom",
                target_anchor="top",
            )
        )

    return branch_col

  # Tier 1: Sibling root folders row (same Y height)
  if ds.root_folder_keys:
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
    for rfk in ds.root_folder_keys:
      emit_folder_branch(rfk, folders_row, org_card.id)

  # Tier 2: Sibling org-root projects row (same Y height, §24 item 5 & §25 item 2)
  # with Organization -> Project edges targeting the outer @ProjectZone box (§25 item 1).
  if ds.root_project_keys:
    org_proj_zone = scene.add_zone(
        make_zone(
            "org_root_projects",
            "@Ghost",
            layout="row",
            gap=24.0,
            align="start",
        ),
        parent=main_tree,
    )
    # Order org-root projects so log-0 and billing-0 sit on the left closest to Organization controls
    ordered_root_projs = sorted(
        ds.root_project_keys,
        key=lambda pk: (
            0 if ds.projects[pk].log_buckets else (1 if ds.projects[pk].datasets else 2),
            pk,
        ),
    )
    for rpk in ordered_root_projs:
      pzone = emit_project_zone(rpk, org_proj_zone)
      scene.add_edge(
          make_edge(
              org_card.id,
              pzone.id,
              arrow="-->",
              label="",
              color="$SlateStroke",
              stroke_width=1.8,
              dashed=False,
              dash="solid",
              head="filled",
              source_anchor="bottom",
              target_anchor="top",
          )
      )

  # Lateral "Organization controls" panel (vertical column docked to the left of main_tree)
  # NO edges from Organization controls to Organization (§24 item 1: implicit!).
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
      )
  )

  # 1. [Org Policies & Constraints] card (no edge to Organization)
  pol_sub = f"{org.org_policies_count} policies"
  if org.custom_constraints_count > 0:
    pol_sub += f" · {org.custom_constraints_count} custom"
  scene.add_card(
      make_card(
          "ctrl_org_policies",
          "Org Policies",
          pol_sub,
          style="@OrgControlCard",
          icon="OrganizationPolicy",
          width=PROJECT_INNER_CARD_WIDTH,
      ),
      parent=controls_zone,
  )

  # 2. [Custom Roles & Tags] card (no edge to Organization)
  roles_tags_sub = (
      f"{org.custom_roles_count} roles · "
      f"{org.tag_keys_count} tags ({org.tag_values_count})"
  )
  scene.add_card(
      make_card(
          "ctrl_custom_roles",
          "Custom Roles & Tags",
          roles_tags_sub,
          style="@OrgControlCard",
          icon="IAM",
          width=PROJECT_INNER_CARD_WIDTH,
      ),
      parent=controls_zone,
  )

  # 3. [Org Log Sinks] card -> routes ONLY to [Log Buckets] card with label "logsink" (§25 item 3)
  sink_names = [s.name for s in org.sinks]
  if sink_names:
    sink_sub = ", ".join(sink_names[:3])[:22]
  else:
    sink_sub = "no org sinks"
  c_sinks = scene.add_card(
      make_card(
          "ctrl_log_sinks",
          f"Org Log Sinks ({len(org.sinks)})",
          sink_sub,
          style="@OrgControlCard",
          icon="CloudLogging",
          width=PROJECT_INNER_CARD_WIDTH,
      ),
      parent=controls_zone,
  )

  sinks_by_proj: Dict[str, List[OrgSink]] = {}
  for sk in org.sinks:
    if sk.target_project and sk.target_project in ds.projects:
      sinks_by_proj.setdefault(sk.target_project, []).append(sk)

  for t_proj in sinks_by_proj:
    dst_cid = project_log_card.get(t_proj) or project_zone_id.get(t_proj)
    if dst_cid:
      scene.add_edge(
          make_edge(
              c_sinks.id,
              dst_cid,
              arrow="-.->",
              label="logsink",
              color="$TealStroke",
              stroke_width=1.8,
              dashed=True,
              dash="dashdot",
              head="filled",
          )
      )

  # 4. [Billing Account] inside lateral Organization controls panel -> [BigQuery Dataset]
  # with concise label "billing export" (§24 item 1)
  if ds.billing_accounts:
    ba = ds.billing_accounts[0]
    bzone = scene.add_zone(
        make_zone(
            "billing_zone",
            "@BillingZone",
            title="Billing Account",
            icon="BillingAccount",
            layout="column",
            gap=8.0,
            align="center",
        ),
        parent=controls_zone,
    )
    ba_sub = (
        f"{ba.iam_bindings_additive_count} additive IAM bindings"
        if ba.iam_bindings_additive_count > 0
        else "Org billing account"
    )
    bcard = scene.add_card(
        make_card(
            _cid("billing_acct", ba.key),
            ba.id[:18],
            ba_sub[:22],
            style="@ProductCard",
            icon="BillingAccount",
            width=180.0,
            stroke_color="$BillingGreen",
            stroke_width=1.5,
        ),
        parent=bzone,
    )
    for pkey, pspec in ds.projects.items():
      if "billing_export" in pspec.datasets:
        dst_bq = project_bq_card.get(pkey) or project_zone_id.get(pkey)
        if dst_bq:
          scene.add_edge(
              make_edge(
                  bcard.id,
                  dst_bq,
                  arrow="-.->",
                  label="billing export",
                  color="$BillingGreen",
                  stroke_width=1.8,
                  dashed=True,
                  dash="dotted",
                  head="open",
              )
          )

  # 5. Shared VPC service -> host @VpcZone edges (§23 item 2 & §25 item 2)
  for pkey, pspec in ds.projects.items():
    host_key = pspec.shared_vpc_service_of
    if not host_key:
      continue
    src_cid = project_svpc_src_card.get(pkey) or project_zone_id.get(pkey)
    dst_zid = project_vpc_zone_id.get(host_key) or project_zone_id.get(host_key)
    if src_cid and dst_zid:
      scene.add_edge(
          make_edge(
              src_cid,
              dst_zid,
              arrow="-->",
              label="Shared VPC service",
              color="$GcpBlue",
              stroke_width=2.0,
              dashed=False,
              dash="solid",
              head="filled",
          )
      )

  # 6. Legend
  if legend:
    scene.legend = [
        LegendEntry(
            label="Resource hierarchy parent → child (solid)",
            kind="edge",
            color="#5f6368",
            dash="solid",
            head="filled",
        ),
        LegendEntry(
            label="Org log sink routing (dash-dot, filled)",
            kind="edge",
            color="#007b83",
            dash="dashdot",
            head="filled",
        ),
        LegendEntry(
            label="BigQuery billing export (dotted, open)",
            kind="edge",
            color="#1e8e3e",
            dash="dotted",
            head="open",
        ),
        LegendEntry(
            label="Shared VPC service → host VPC (solid blue)",
            kind="edge",
            color="#1a73e8",
            dash="solid",
            head="filled",
        ),
    ]

  return scene


def build(
    dataset: Union[str, pathlib.Path, OrgSetupDataset],
    view: str = "hierarchy",
    dataset_name: Optional[str] = None,
    *,
    verbose_badges: bool = False,
    legend: bool = True,
    **_kwargs: object,
) -> SceneGraph:
  """Returns the SceneGraph for `view` of a 0-org-setup dataset."""
  if view != "hierarchy":
    raise ValueError(f"unknown 0-org-setup view: {view!r} (expected {VIEWS})")
  return build_hierarchy(
      dataset,
      dataset_name=dataset_name,
      verbose_badges=verbose_badges,
      legend=legend,
  )
