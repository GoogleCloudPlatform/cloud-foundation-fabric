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
"""FAST 1-vpcsc -> SceneGraph builder (`perimeters` view).

The view flows top to bottom: sources outside the perimeters (access levels,
identities, source resources), the perimeters themselves, then egress
targets. Every ingress/egress policy is an intermediate card inside its
perimeter block, so the chain reads `source -> [Ingress: key] -> target`.

Inside a perimeter block, "Protected resources" holds only the block's own
`resources`; resources that appear only in policy `to`/`from` clauses are
drawn in a separate "Policy targets" group. A policy reference that does not
resolve is drawn as a dashed card with an `unresolved` badge and no edges.

`spec` is labelled dry-run only when `use_explicit_dry_run_spec` is true;
otherwise the API ignores it and the block is badged `spec (not applied)`.
"""

import pathlib
from typing import Any, Dict, List, Optional, Tuple, Union

from .. import tokens, yamlio
from ..datasets.org_setup import OrgSetupDataset, load_org_setup_dataset
from ..datasets.vpcsc import (
    EgressPolicySpec,
    IngressPolicySpec,
    PerimeterBlockSpec,
    PerimeterSpec,
    SetRef,
    VpcscDataset,
    load_vpcsc_dataset,
)
from ..scene.model import (
    Badge,
    SceneGraph,
    ZoneNode,
    make_card,
    make_edge,
    make_zone,
)
from ._common import (
    MAX_CARD_BADGES_DEFAULT,
    MAX_ZONE_BADGES_DEFAULT,
    SCC_AGENT_NAMES,
    cap_badges,
    cid,
    ellipsize,
    join_limited,
    legend_card,
    legend_edge,
    warn,
)

__all__ = [
    "BADGE_DRY_RUN",
    "BADGE_ENFORCED",
    "BADGE_SPEC_NOT_APPLIED",
    "VIEWS",
    "build",
    "build_perimeters",
    "load_dataset",
    "validate_org_dataset",
]

VIEWS = ("perimeters",)

BADGE_ENFORCED = "ENFORCED (status)"
BADGE_DRY_RUN = "DRY-RUN (spec)"
BADGE_SPEC_NOT_APPLIED = "spec (not applied)"

# Edge styles; the legend reuses the same tokens.
_INGRESS_COLOR = "$GcpBlue"
_EGRESS_COLOR = "$VermilionStroke"
_ACCESS_LEVEL_COLOR = "$TealStroke"

_ORG_AGENT_PREFIX = "$iam_principals:service_agents/org/"

# Display titles for `from.identity_type`.
_IDENTITY_TYPE_TITLES = {
    "ANY_IDENTITY": "Any identity",
    "ANY_USER_ACCOUNT": "Any user account",
    "ANY_SERVICE_ACCOUNT": "Any service account",
}

_DESCRIPTION_LIMIT = 80


def _spec_badge(perim: PerimeterSpec) -> Badge:
  if perim.use_explicit_dry_run_spec:
    return Badge(text=BADGE_DRY_RUN, tone="warn")
  return Badge(text=BADGE_SPEC_NOT_APPLIED, tone="neutral")


def _spec_title_suffix(perim: PerimeterSpec) -> str:
  return "spec (dry-run)" if perim.use_explicit_dry_run_spec else (
      BADGE_SPEC_NOT_APPLIED)


def _ref_badges(ref: SetRef, is_set: bool = True,
                verbose: bool = False) -> List[Badge]:
  out: List[Badge] = []
  if is_set and ref.provenance != "literal":
    out.append(Badge(text="set", tone="neutral"))
  if ref.provenance == "org-dataset":
    out.append(Badge(text="org-dataset", tone="info"))
  elif ref.provenance == "defaults-context":
    out.append(Badge(text="context", tone="info"))
  if ref.unresolved:
    out.append(Badge(text="unresolved", tone="warn"))
  return cap_badges(out, MAX_CARD_BADGES_DEFAULT, verbose)


def _format_resource_card_spec(
    raw_res: str, ds: VpcscDataset,
    verbose: bool = False) -> Tuple[str, str, str, str, List[Badge]]:
  """Returns (title, subtitle, style, icon, badges) for a resource ref."""
  ref = ds.resolve_token(raw_res)
  if ref.namespace == "resource_sets":
    return (f"Resource set: {ref.key}", ref.subtitle, "@ResourceSetCard",
            "ResourceSet", _ref_badges(ref, is_set=True, verbose=verbose))
  if ref.namespace == "project_numbers":
    return (f"Project: {ref.key}", ref.subtitle, "@ProjectCard", "Project",
            _ref_badges(ref, is_set=False, verbose=verbose))
  if ref.namespace == "folder_ids":
    return (f"Folder: {ref.key}", ref.subtitle, "@ProductCard", "Folder",
            _ref_badges(ref, is_set=False, verbose=verbose))
  if ref.namespace == "literal":
    if raw_res.startswith("projects/"):
      return (f"Project {raw_res.split('/', 1)[1]}", raw_res, "@ProjectCard",
              "Project", [])
    if raw_res.startswith("folders/"):
      return (f"Folder {raw_res.split('/', 1)[1]}", raw_res, "@ProductCard",
              "Folder", [])
    return (raw_res, "resource", "@ProjectCard", "Project", [])
  return (f"{ref.namespace}: {ref.key}", ref.subtitle, "@ResourceSetCard",
          "ResourceSet", _ref_badges(ref, is_set=True, verbose=verbose))


def _org_agents(identities: List[str]) -> Tuple[List[str], List[str]]:
  """Splits identities into (org service agent names, other identities)."""
  agents = [
      i.removeprefix(_ORG_AGENT_PREFIX)
      for i in identities
      if i.startswith(_ORG_AGENT_PREFIX)
  ]
  others = [i for i in identities if not i.startswith(_ORG_AGENT_PREFIX)]
  return agents, others


def _agents_label(agents: List[str]) -> str:
  if agents and all(a in SCC_AGENT_NAMES for a in agents):
    return "SCC"
  return "org"


def _identity_summary(identities: List[str], identity_type: Optional[str],
                      ds: VpcscDataset) -> str:
  """One-line summary of a policy's `from` identities for a policy card."""
  if not identities:
    if identity_type:
      return _IDENTITY_TYPE_TITLES.get(identity_type, identity_type).lower()
    return "no identities"
  agents, others = _org_agents(identities)
  parts: List[str] = []
  if agents:
    kind = _agents_label(agents)
    if len(agents) > 1:
      parts.append(f"{len(agents)} {kind} agents")
    else:
      parts.append(f"agent {agents[0]}")
  for o in others:
    parts.append(ds.resolve_token(o).key)
  return join_limited(parts, 40)


def _defaults_doc(root: Optional[pathlib.Path]) -> Dict[str, Any]:
  if root is None:
    return {}
  path = pathlib.Path(root) / "defaults.yaml"
  if not path.is_file():
    return {}
  doc = yamlio.load_or_empty(path)
  return doc if isinstance(doc, dict) else {}


def validate_org_dataset(vpcsc_root: Union[str, pathlib.Path],
                         org_ds: OrgSetupDataset) -> List[str]:
  """Returns reasons why `org_ds` does not belong to the 1-vpcsc dataset.

  The 1-vpcsc datasets do not carry an organization id or prefix of their
  own, so the check compares what both sides declare: an organization id in
  `context.organization_ids`, `output_files.local_path`, and the project and
  bucket of the `output_files.storage_bucket` reference.
  """
  problems: List[str] = []
  vdoc = _defaults_doc(pathlib.Path(vpcsc_root))
  odoc = _defaults_doc(org_ds.root_dir)

  ctx = vdoc.get("context") if isinstance(vdoc.get("context"), dict) else {}
  org_ids = ctx.get("organization_ids")
  if isinstance(org_ids, dict) and org_ds.organization.id:
    for key, val in sorted(org_ids.items(), key=lambda kv: str(kv[0])):
      if str(val).removeprefix("organizations/") != str(org_ds.organization.id):
        problems.append(f"context.organization_ids.{key} is {val}, org dataset "
                        f"organization id is {org_ds.organization.id}")

  v_out = vdoc.get("output_files")
  o_out = odoc.get("output_files")
  v_out = v_out if isinstance(v_out, dict) else {}
  o_out = o_out if isinstance(o_out, dict) else {}
  v_path = v_out.get("local_path")
  o_path = o_out.get("local_path")
  if v_path and o_path and str(v_path) != str(o_path):
    problems.append(f"output_files.local_path differs ({v_path} vs {o_path})")

  bucket_ref = v_out.get("storage_bucket")
  bucket_key = tokens.key_of(bucket_ref, "storage_buckets") if isinstance(
      bucket_ref, str) else None
  if bucket_key and "/" in bucket_key:
    proj_key, bucket = bucket_key.split("/", 1)
    proj = org_ds.projects.get(proj_key)
    if proj is None:
      problems.append(f"output_files.storage_bucket project {proj_key!r} is "
                      "not defined in the org dataset")
    elif bucket not in proj.buckets:
      problems.append(f"output_files.storage_bucket {bucket!r} is not a "
                      f"bucket of org dataset project {proj_key!r}")
  return problems


def load_dataset(dataset: Union[str, pathlib.Path, VpcscDataset],
                 org_dataset: Optional[Union[str, pathlib.Path,
                                             OrgSetupDataset]] = None,
                 strict: bool = False) -> VpcscDataset:
  """Loads the dataset, attaching `org_dataset` only when it matches.

  A mismatching or unloadable org dataset is reported through
  `_common.warn` (the dataset's `warnings` list when it has one) and the
  dataset is loaded without it.
  """
  if isinstance(dataset, VpcscDataset):
    if strict and dataset.unresolved_refs:
      names = ", ".join(u.raw for u in dataset.unresolved_refs)
      raise ValueError(
          f"Unresolved symbolic references in strict mode: {names}")
    if org_dataset is not None:
      warn(
          dataset, "org_dataset is ignored when a loaded 1-vpcsc dataset is "
          "passed; load it with org_dataset_dir instead")
    return dataset

  messages: List[str] = []
  org_ds: Optional[OrgSetupDataset] = None
  if org_dataset is not None:
    try:
      org_ds = (org_dataset if isinstance(org_dataset, OrgSetupDataset) else
                load_org_setup_dataset(org_dataset))
    except Exception as exc:  # pylint: disable=broad-except
      messages.append(f"--org-dataset {org_dataset}: cannot be loaded as a "
                      f"0-org-setup dataset ({exc}); ignoring it")
      org_ds = None
    if org_ds is not None:
      problems = validate_org_dataset(dataset, org_ds)
      if problems:
        messages.append(
            f"--org-dataset {org_ds.root_dir} does not match 1-vpcsc dataset "
            f"{pathlib.Path(dataset).name}: {'; '.join(problems)}; ignoring it")
        org_ds = None

  ds = load_vpcsc_dataset(dataset, org_dataset_dir=org_ds, strict=strict)
  for msg in messages:
    warn(ds, msg)
  return ds


def build_perimeters(
    dataset: Union[str, pathlib.Path, VpcscDataset],
    dataset_name: Optional[str] = None,
    *,
    org_dataset: Optional[Union[str, pathlib.Path, OrgSetupDataset]] = None,
    verbose_badges: bool = False,
    legend: bool = True,
    strict: bool = False,
) -> SceneGraph:
  """Builds the 1-vpcsc `perimeters` SceneGraph with policy cards."""
  ds = load_dataset(dataset, org_dataset, strict)

  name = dataset_name or ds.dataset_name
  scene = SceneGraph(dataset_name=name, view_kind="perimeters", stage="1-vpcsc")

  root_col = scene.add_zone(
      make_zone(
          "vpcsc_root",
          "@ArchitectureRoot",
          title=f"VPC Service Controls · {name}",
          subtitle=(f"{len(ds.perimeters)} perimeter(s) · "
                    f"{len(ds.access_levels)} access level(s) · "
                    f"{len(ds.ingress_policies)} ingress / "
                    f"{len(ds.egress_policies)} egress policies"),
          icon="VPCServiceControls",
          layout="column",
          gap=48.0,
          align="center",
      ))

  sources_col = scene.add_zone(
      make_zone(
          "sources_col",
          "@SourcesZone",
          title="Sources (outside)",
          layout="row",
          gap=20.0,
          align="start",
      ),
      parent=root_col,
  )

  perimeters_col = scene.add_zone(
      make_zone(
          "perimeters_col",
          "@Ghost",
          layout="column",
          gap=28.0,
          align="center",
      ),
      parent=root_col,
  )

  al_cards: Dict[str, str] = {}
  source_cards: Dict[str, str] = {}
  egress_cards: Dict[str, str] = {}
  egress_col: Optional[ZoneNode] = None

  def ensure_egress_col() -> ZoneNode:
    nonlocal egress_col
    if egress_col is None:
      egress_col = scene.add_zone(
          make_zone(
              "egress_col",
              "@SourcesZone",
              title="Egress targets",
              layout="row",
              gap=20.0,
              align="start",
          ),
          parent=root_col,
      )
    return egress_col

  def source_card(key: str, card_id: str, title: str, subtitle: str, style: str,
                  icon: str, badges: List[Badge]) -> str:
    if key not in source_cards:
      c = scene.add_card(
          make_card(card_id, title, subtitle, style=style, icon=icon,
                    badges=badges),
          parent=sources_col,
      )
      source_cards[key] = c.id
    return source_cards[key]

  def ensure_access_level_card(raw_al: str) -> str:
    ref = ds.resolve_token(raw_al)
    al_key = ref.key if ref.namespace == "access_levels" else raw_al
    if al_key in al_cards:
      return al_cards[al_key]
    al_spec = ds.access_levels.get(al_key)
    sub = al_spec.summary if al_spec else ref.subtitle
    c = scene.add_card(
        make_card(
            cid("src_al", al_key),
            f"Access level: {al_key}",
            sub,
            style="@AccessLevelCard",
            icon="AccessLevel",
            badges=_ref_badges(ref, is_set=False, verbose=verbose_badges),
        ),
        parent=sources_col,
    )
    al_cards[al_key] = c.id
    return c.id

  # Defined access levels first, in dataset order.
  for al_key in ds.access_levels:
    ensure_access_level_card(f"$access_levels:{al_key}")

  def identity_source_cards(ipol_key: str,
                            ipol: IngressPolicySpec) -> List[str]:
    """Source card ids for every `from` clause of an ingress policy."""
    out_ids: List[str] = []
    for al in ipol.from_access_levels:
      if al != "*":
        out_ids.append(ensure_access_level_card(al))

    agents, other_idents = _org_agents(ipol.from_identities)
    if agents:
      kind = _agents_label(agents)
      title = f"{'SCC' if kind == 'SCC' else 'Org'} service agents"
      out_ids.append(
          source_card(
              f"org_agents_{ipol_key}",
              cid("src_agents", ipol_key),
              f"{title} ({len(agents)})",
              join_limited(agents, 44),
              "@IdentityCard",
              "ServiceAgent",
              [Badge(text="service agents", tone="info")],
          ))

    for ident in other_idents:
      ref = ds.resolve_token(ident)
      if ref.namespace == "identity_sets" and ref.key == "logging_identities":
        title = "Log sink writers"
      elif ref.namespace == "identity_sets":
        title = f"Identity set: {ref.key}"
      else:
        title = f"Identity: {ref.key}"
      out_ids.append(
          source_card(
              ident,
              cid("src_id", ref.namespace, ref.key),
              title,
              ref.subtitle,
              "@IdentityCard",
              "IAM",
              _ref_badges(ref, is_set=(ref.namespace == "identity_sets"),
                          verbose=verbose_badges),
          ))

    identity_type = ipol.from_identity_type
    if identity_type and not ipol.from_identities:
      out_ids.append(
          source_card(
              f"identity_type_{identity_type}",
              cid("src_idtype", identity_type),
              _IDENTITY_TYPE_TITLES.get(identity_type, str(identity_type)),
              f"identity_type: {identity_type}",
              "@IdentityCard",
              "IAM",
              [],
          ))

    for fres in ipol.from_resources:
      ref = ds.resolve_token(fres)
      out_ids.append(
          source_card(
              f"from_res_{fres}",
              cid("src_res", ref.namespace, ref.key),
              f"Source resource: {ref.key}",
              ref.subtitle,
              "@ProjectCard",
              "Project",
              _ref_badges(ref, is_set=(ref.namespace == "resource_sets"),
                          verbose=verbose_badges),
          ))

    for psc in ipol.from_psc_endpoints:
      ref = ds.resolve_token(str(psc))
      out_ids.append(
          source_card(
              f"psc_{psc}",
              cid("src_psc", ref.namespace, ref.key),
              f"PSC endpoint: {ref.key}",
              ref.subtitle,
              "@ProductCard",
              "Networking",
              _ref_badges(ref, is_set=False, verbose=verbose_badges),
          ))
    return out_ids

  def ensure_egress_target_card(raw_target: str) -> str:
    if raw_target in egress_cards:
      return egress_cards[raw_target]
    ecol = ensure_egress_col()
    if raw_target == "*":
      c = scene.add_card(
          make_card(
              "egress_target_all",
              "Any external resource (*)",
              "unrestricted target resource (*)",
              style="@ExternalCard",
              icon="Internet",
          ),
          parent=ecol,
      )
      egress_cards[raw_target] = c.id
      return c.id

    ref = ds.resolve_token(raw_target)
    title = (f"External: {ref.key}"
             if ref.namespace == "literal" else f"Target {ref.namespace}: "
             f"{ref.key}")
    c = scene.add_card(
        make_card(
            cid("egress_target", ref.namespace, ref.key),
            title,
            ref.subtitle,
            style="@ExternalCard",
            icon="Internet",
            badges=_ref_badges(ref, is_set=(ref.namespace != "literal"),
                               verbose=verbose_badges),
        ),
        parent=ecol,
    )
    egress_cards[raw_target] = c.id
    return c.id

  def flow_edge(src: str, dst: str, ingress: bool, label: str = "") -> None:
    if ingress:
      scene.add_edge(
          make_edge(src, dst, arrow="-->", label=label, color=_INGRESS_COLOR,
                    stroke_width=2.0, dashed=False, dash="solid", head="filled",
                    source_anchor="bottom", target_anchor="top"))
    else:
      scene.add_edge(
          make_edge(src, dst, arrow="-.->", label=label, color=_EGRESS_COLOR,
                    stroke_width=2.0, dashed=True, dash="dashed", head="open",
                    source_anchor="bottom", target_anchor="top"))

  def emit_perimeter_block(
      perim: PerimeterSpec,
      blk: PerimeterBlockSpec,
      parent_zone: ZoneNode,
      zone_id_suffix: str,
      mode_badges: List[Badge],
      zone_style: str,
      zone_title: str,
  ) -> None:
    p_badges = list(mode_badges)
    if perim.ignore_resource_changes:
      p_badges.append(Badge(text="ignore changes", tone="neutral"))
    p_badges = cap_badges(p_badges, MAX_ZONE_BADGES_DEFAULT, verbose_badges)

    pzone = scene.add_zone(
        make_zone(
            cid("perim", perim.key, zone_id_suffix),
            zone_style,
            title=zone_title,
            subtitle=ellipsize(perim.description or perim.title or "",
                               _DESCRIPTION_LIMIT),
            icon="VPCServiceControls",
            layout="column",
            gap=36.0,
            align="center",
            badges=p_badges,
        ),
        parent=parent_zone,
    )

    ingress_col: Optional[ZoneNode] = None
    if blk.ingress_policies:
      ingress_col = scene.add_zone(
          make_zone(
              cid("ing_pol_col", perim.key, zone_id_suffix),
              "@SubGroupWhite",
              title="Ingress policies",
              layout="row",
              gap=20.0,
              align="start",
          ),
          parent=pzone,
      )

    center_col = scene.add_zone(
        make_zone(
            cid("perim_center", perim.key, zone_id_suffix),
            "@Ghost",
            layout="row",
            gap=20.0,
            align="center",
        ),
        parent=pzone,
    )

    egress_pol_col: Optional[ZoneNode] = None
    if blk.egress_policies:
      egress_pol_col = scene.add_zone(
          make_zone(
              cid("egr_pol_col", perim.key, zone_id_suffix),
              "@SubGroupWhite",
              title="Egress policies",
              layout="row",
              gap=20.0,
              align="start",
          ),
          parent=pzone,
      )

    prot_zone: Optional[ZoneNode] = None
    targets_zone: Optional[ZoneNode] = None
    card_by_token: Dict[str, str] = {}

    def resource_card(raw_res: str, zone: ZoneNode, prefix: str) -> str:
      if raw_res == "*":
        c = scene.add_card(
            make_card(
                cid(f"{prefix}_wildcard", perim.key, zone_id_suffix),
                "All perimeter resources (*)",
                "wildcard policy target (*)",
                style="@ResourceSetCard",
                icon="ResourceSet",
                badges=[Badge(text="wildcard", tone="info")],
            ),
            parent=zone,
        )
        return c.id
      title, sub, style, icon, badges = _format_resource_card_spec(
          raw_res, ds, verbose=verbose_badges)
      c = scene.add_card(
          make_card(
              cid(prefix, perim.key, zone_id_suffix, raw_res),
              title,
              sub,
              style=style,
              icon=icon,
              badges=badges,
          ),
          parent=zone,
      )
      return c.id

    def ensure_protected_card(raw_res: str) -> str:
      nonlocal prot_zone
      if raw_res in card_by_token:
        return card_by_token[raw_res]
      if prot_zone is None:
        prot_zone = scene.add_zone(
            make_zone(
                cid("prot_res", perim.key, zone_id_suffix),
                "@SubGroupWhite",
                title="Protected resources",
                layout="row",
                gap=20.0,
                align="start",
            ),
            parent=center_col,
        )
      card_by_token[raw_res] = resource_card(raw_res, prot_zone, "res")
      return card_by_token[raw_res]

    def ensure_target_card(raw_res: str) -> str:
      """Card for a policy target; perimeter members reuse their card."""
      nonlocal targets_zone
      if raw_res in card_by_token:
        return card_by_token[raw_res]
      if targets_zone is None:
        targets_zone = scene.add_zone(
            make_zone(
                cid("pol_targets", perim.key, zone_id_suffix),
                "@SubGroupWhite",
                title="Policy targets",
                layout="row",
                gap=20.0,
                align="start",
            ),
            parent=center_col,
        )
      card_by_token[raw_res] = resource_card(raw_res, targets_zone, "tgt")
      return card_by_token[raw_res]

    def resolved_ingress(
        ip_ref: str) -> Tuple[str, Optional[IngressPolicySpec]]:
      tok = ds.resolve_token(ip_ref)
      return tok.key, ds.ingress_policies.get(tok.key)

    def resolved_egress(ep_ref: str) -> Tuple[str, Optional[EgressPolicySpec]]:
      tok = ds.resolve_token(ep_ref)
      return tok.key, ds.egress_policies.get(tok.key)

    # 1. The block's own resources.
    for r in blk.resources:
      ensure_protected_card(r)

    # 2. Policy targets, created up front so the groups keep a stable order.
    for ip_ref in blk.ingress_policies:
      _, ipol = resolved_ingress(ip_ref)
      if ipol:
        for tr in ipol.to_resources:
          ensure_target_card(tr)
    for ep_ref in blk.egress_policies:
      _, epol = resolved_egress(ep_ref)
      if epol:
        for fr in epol.from_resources or ["*"]:
          ensure_target_card(fr)

    # 3. Restricted services summary card.
    if blk.restricted_services:
      total_svcs = 0
      sample_svcs: List[str] = []
      rs_badges: List[Badge] = []
      for rs_entry in blk.restricted_services:
        ref = ds.resolve_token(rs_entry)
        if ref.unresolved:
          rs_badges.append(Badge(text="unresolved", tone="warn"))
          continue
        members = ref.members if ref.members is not None else [ref.key]
        total_svcs += len(members)
        for m in members:
          short_m = m.removesuffix(".googleapis.com")
          if short_m not in sample_svcs:
            sample_svcs.append(short_m)

      priority = ("storage", "bigquery", "compute")
      ordered = [p for p in priority if p in sample_svcs
                ] + [s for s in sample_svcs if s not in priority]
      shown = ", ".join(ordered[:3])
      if len(ordered) > 3:
        shown += f", +{len(ordered) - 3}"
      scene.add_card(
          make_card(
              cid("restricted_svcs", perim.key, zone_id_suffix),
              f"Restricted services: {total_svcs}",
              shown or "none",
              style="@ProductCard",
              icon="ApiService",
              badges=cap_badges(rs_badges, MAX_CARD_BADGES_DEFAULT,
                                verbose_badges),
          ),
          parent=center_col,
      )

    # 4. VPC accessible services card.
    if blk.vpc_accessible_services is not None:
      vas = blk.vpc_accessible_services
      vas_sub = (f"enable_restriction: {vas.enable_restriction} · "
                 f"{len(vas.allowed_services)} allowed services")
      scene.add_card(
          make_card(
              cid("vpc_acc_svcs", perim.key, zone_id_suffix),
              "VPC accessible services",
              vas_sub,
              style="@ProductCard",
              icon="VirtualPrivateCloud",
          ),
          parent=center_col,
      )

    # 5a. Perimeter-level access levels -> perimeter zone.
    for al_ref in blk.access_levels:
      scene.add_edge(
          make_edge(
              ensure_access_level_card(al_ref),
              pzone.id,
              arrow="-.->",
              label="access level",
              color=_ACCESS_LEVEL_COLOR,
              stroke_width=1.8,
              dashed=True,
              dash="dotted",
              head="filled",
              source_anchor="bottom",
              target_anchor="top",
          ))

    # 5b. Ingress chain: sources -> [Ingress: key] -> targets.
    for ip_ref in blk.ingress_policies:
      ip_key, ipol = resolved_ingress(ip_ref)
      if ipol is None:
        tok = ds.resolve_token(ip_ref)
        scene.add_card(
            make_card(
                cid("ing_pol", perim.key, zone_id_suffix, ip_key),
                f"Ingress: {ip_key}",
                tok.subtitle or "policy not found",
                style="@ProductCard",
                icon="VPCServiceControls",
                stroke_color=_INGRESS_COLOR,
                stroke_width=1.8,
                dashed=True,
                badges=_ref_badges(tok, is_set=False, verbose=verbose_badges),
            ),
            parent=ingress_col or center_col,
        )
        continue

      sub_parts = [ipol.ops_summary]
      if "*" in ipol.from_access_levels:
        sub_parts.append("any access level")
      ip_card = scene.add_card(
          make_card(
              cid("ing_pol", perim.key, zone_id_suffix, ip_key),
              f"Ingress: {ip_key}",
              " · ".join(p for p in sub_parts if p),
              style="@ProductCard",
              icon="VPCServiceControls",
              stroke_color=_INGRESS_COLOR,
              stroke_width=1.8,
          ),
          parent=ingress_col or center_col,
      )
      for scid in identity_source_cards(ip_key, ipol):
        flow_edge(scid, ip_card.id, ingress=True, label="ingress")
      for t_tok in ipol.to_resources:
        flow_edge(ip_card.id, ensure_target_card(t_tok), ingress=True)

    # 5c. Egress chain: perimeter resources -> [Egress: key] -> targets.
    for ep_ref in blk.egress_policies:
      ep_key, epol = resolved_egress(ep_ref)
      if epol is None:
        tok = ds.resolve_token(ep_ref)
        scene.add_card(
            make_card(
                cid("egr_pol", perim.key, zone_id_suffix, ep_key),
                f"Egress: {ep_key}",
                tok.subtitle or "policy not found",
                style="@ProductCard",
                icon="VPCServiceControls",
                stroke_color=_EGRESS_COLOR,
                stroke_width=1.8,
                dashed=True,
                badges=_ref_badges(tok, is_set=False, verbose=verbose_badges),
            ),
            parent=egress_pol_col or center_col,
        )
        continue

      id_summary = _identity_summary(epol.from_identities,
                                     epol.from_identity_type, ds)
      ep_card = scene.add_card(
          make_card(
              cid("egr_pol", perim.key, zone_id_suffix, ep_key),
              f"Egress: {ep_key}",
              " · ".join(p for p in (epol.ops_summary, id_summary) if p),
              style="@ProductCard",
              icon="VPCServiceControls",
              stroke_color=_EGRESS_COLOR,
              stroke_width=1.8,
          ),
          parent=egress_pol_col or center_col,
      )
      # An egress policy without `from.resources` applies to every resource
      # in the perimeter, hence the wildcard source.
      for fr_tok in epol.from_resources or ["*"]:
        flow_edge(ensure_target_card(fr_tok), ep_card.id, ingress=False,
                  label="egress")
      for tr_tok in epol.to_resources + epol.to_external_resources:
        flow_edge(ep_card.id, ensure_egress_target_card(tr_tok), ingress=False)

  for pkey, perim in ds.perimeters.items():
    if perim.has_both_equal and perim.status is not None:
      emit_perimeter_block(
          perim,
          perim.status,
          perimeters_col,
          "both",
          [Badge(text=BADGE_ENFORCED, tone="danger"),
           _spec_badge(perim)],
          "@PerimeterZone",
          f"Perimeter: {pkey}",
      )
    elif (perim.has_both_different and perim.status is not None and
          perim.spec is not None):
      outer = scene.add_zone(
          make_zone(
              cid("perim_outer", pkey),
              "@PerimeterZone",
              title=f"Perimeter: {pkey}",
              subtitle=ellipsize(
                  perim.description or perim.title or "status and spec",
                  _DESCRIPTION_LIMIT),
              icon="VPCServiceControls",
              layout="column",
              gap=20.0,
              align="center",
              badges=[
                  Badge(text=BADGE_ENFORCED, tone="danger"),
                  _spec_badge(perim)
              ],
          ),
          parent=perimeters_col,
      )
      emit_perimeter_block(
          perim,
          perim.status,
          outer,
          "status",
          [Badge(text=BADGE_ENFORCED, tone="danger")],
          "@PerimeterZone",
          f"{pkey} · status (enforced)",
      )
      emit_perimeter_block(
          perim,
          perim.spec,
          outer,
          "spec",
          [_spec_badge(perim)],
          "@PerimeterDryRunZone",
          f"{pkey} · {_spec_title_suffix(perim)}",
      )
    elif perim.status is not None:
      emit_perimeter_block(
          perim,
          perim.status,
          perimeters_col,
          "status",
          [Badge(text=BADGE_ENFORCED, tone="danger")],
          "@PerimeterZone",
          f"Perimeter: {pkey}",
      )
    elif perim.spec is not None:
      title = f"Perimeter: {pkey}"
      if not perim.use_explicit_dry_run_spec:
        title = f"{title} · {BADGE_SPEC_NOT_APPLIED}"
      emit_perimeter_block(
          perim,
          perim.spec,
          perimeters_col,
          "spec",
          [_spec_badge(perim)],
          "@PerimeterDryRunZone",
          title,
      )

  if legend:
    labels = {e.label for e in scene.edges}
    entries = []
    if "ingress" in labels:
      entries.append(
          legend_edge("Ingress policy flow (solid blue, filled head)",
                      _INGRESS_COLOR, "solid", "filled"))
    if "egress" in labels:
      entries.append(
          legend_edge("Egress policy flow (dashed vermilion, open head)",
                      _EGRESS_COLOR, "dashed", "open"))
    if "access level" in labels:
      entries.append(
          legend_edge("Access level binding (dotted teal)", _ACCESS_LEVEL_COLOR,
                      "dotted", "filled"))
    if any(c.dashed for c in scene.cards.values()):
      entries.append(
          legend_card("Symbolic set or unresolved reference (dashed border)",
                      "$SlateStroke", "$SurfaceWhite", dashed=True))
    scene.legend = entries

  return scene


def build(
    dataset: Union[str, pathlib.Path, VpcscDataset],
    view: str = "perimeters",
    dataset_name: Optional[str] = None,
    *,
    org_dataset: Optional[Union[str, pathlib.Path, OrgSetupDataset]] = None,
    verbose_badges: bool = False,
    legend: bool = True,
    strict: bool = False,
) -> SceneGraph:
  """Returns the SceneGraph for `view` of a 1-vpcsc dataset."""
  if view != "perimeters":
    raise ValueError(f"unknown 1-vpcsc view: {view!r} (expected {VIEWS})")
  return build_perimeters(
      dataset,
      dataset_name=dataset_name,
      org_dataset=org_dataset,
      verbose_badges=verbose_badges,
      legend=legend,
      strict=strict,
  )
