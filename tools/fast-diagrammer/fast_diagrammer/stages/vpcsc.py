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

"""FAST 1-vpcsc -> SceneGraph builder (perimeters view with intermediate policy cards)."""

import pathlib
from typing import Dict, List, Optional, Tuple, Union

from ..datasets.org_setup import OrgSetupDataset
from ..datasets.vpcsc import (
    PerimeterBlockSpec,
    PerimeterSpec,
    SetRef,
    VpcscDataset,
    load_vpcsc_dataset,
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

__all__ = ["VIEWS", "build", "build_perimeters"]

VIEWS = ("perimeters",)

MAX_CARD_BADGES_DEFAULT = 4
MAX_ZONE_BADGES_DEFAULT = 6


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


def _ref_badges(ref: SetRef, is_set: bool = True, verbose: bool = False) -> List[Badge]:
  out: List[Badge] = []
  if is_set and ref.provenance != "literal":
    out.append(Badge(text="set", tone="neutral"))
  if ref.provenance == "org-dataset":
    out.append(Badge(text="org-dataset", tone="info"))
  elif ref.provenance == "defaults-context":
    out.append(Badge(text="context", tone="info"))
  if ref.unresolved:
    out.append(Badge(text="unresolved", tone="warn"))
  return _cap_badges(out, MAX_CARD_BADGES_DEFAULT, verbose)


def _format_resource_card_spec(
    raw_res: str, ds: VpcscDataset, verbose: bool = False
) -> Tuple[str, str, str, str, List[Badge]]:
  """Returns (title, subtitle, style, icon, badges) for a perimeter resource ref."""
  ref = ds.resolve_token(raw_res)
  if ref.namespace == "resource_sets":
    return (
        f"Resource set: {ref.key}",
        ref.subtitle,
        "@ResourceSetCard",
        "ResourceSet",
        _ref_badges(ref, is_set=True, verbose=verbose),
    )
  if ref.namespace == "project_numbers":
    return (
        f"Project: {ref.key}",
        ref.subtitle,
        "@ProjectCard",
        "Project",
        _ref_badges(ref, is_set=False, verbose=verbose),
    )
  if ref.namespace == "folder_ids":
    return (
        f"Folder: {ref.key}",
        ref.subtitle,
        "@ProductCard",
        "Folder",
        _ref_badges(ref, is_set=False, verbose=verbose),
    )
  if ref.namespace == "literal":
    if raw_res.startswith("projects/"):
      return (
          f"Project {raw_res.split('/', 1)[1]}",
          raw_res,
          "@ProjectCard",
          "Project",
          [],
      )
    if raw_res.startswith("folders/"):
      return (
          f"Folder {raw_res.split('/', 1)[1]}",
          raw_res,
          "@ProductCard",
          "Folder",
          [],
      )
    return (raw_res, "protected resource", "@ProjectCard", "Project", [])
  return (
      f"{ref.namespace}: {ref.key}",
      ref.subtitle,
      "@ResourceSetCard",
      "ResourceSet",
      _ref_badges(ref, is_set=True, verbose=verbose),
  )


def _summarize_identities_for_label(identities: List[str], ds: VpcscDataset) -> str:
  if not identities:
    return "any identity"
  org_agents = [
      i.removeprefix("$iam_principals:service_agents/org/")
      for i in identities
      if i.startswith("$iam_principals:service_agents/org/")
  ]
  others = [
      i for i in identities if not i.startswith("$iam_principals:service_agents/org/")
  ]
  parts: List[str] = []
  if org_agents:
    if len(org_agents) > 1:
      parts.append(f"{len(org_agents)} SCC agents")
    else:
      parts.append(f"agent {org_agents[0]}")
  for o in others:
    ref = ds.resolve_token(o)
    parts.append(ref.key)
  return ", ".join(parts)


def build_perimeters(
    dataset: Union[str, pathlib.Path, VpcscDataset],
    dataset_name: Optional[str] = None,
    *,
    org_dataset: Optional[Union[str, pathlib.Path, OrgSetupDataset]] = None,
    verbose_badges: bool = False,
    legend: bool = True,
    strict: bool = False,
) -> SceneGraph:
  """Builds the 1-vpcsc `perimeters` SceneGraph with intermediate policy cards."""
  if isinstance(dataset, VpcscDataset):
    ds = dataset
    if strict and ds.unresolved_refs:
      names = ", ".join(u.raw for u in ds.unresolved_refs)
      raise ValueError(f"Unresolved symbolic references in strict mode: {names}")
  else:
    ds = load_vpcsc_dataset(dataset, org_dataset_dir=org_dataset, strict=strict)

  name = dataset_name or ds.dataset_name
  scene = SceneGraph(dataset_name=name, view_kind="perimeters", stage="1-vpcsc")

  # Outer top-to-bottom vertical flow: Sources (outside) -> Perimeters -> Egress targets
  root_col = scene.add_zone(
      make_zone(
          "vpcsc_root",
          "@ArchitectureRoot",
          title=f"VPC Service Controls · {name}",
          subtitle=(
              f"{len(ds.perimeters)} perimeter(s) · "
              f"{len(ds.access_levels)} access level(s) · "
              f"{len(ds.ingress_policies)} ingress / {len(ds.egress_policies)} egress policies"
          ),
          icon="VPCServiceControls",
          layout="column",
          gap=48.0,
          align="center",
      )
  )

  # Top tier: Sources (outside) row
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

  # Middle tier: Perimeters stack
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

  # Track created cards in Sources and Egress tiers to avoid duplicates
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

  def ensure_access_level_card(raw_al: str) -> str:
    ref = ds.resolve_token(raw_al)
    al_key = ref.key if ref.namespace == "access_levels" else raw_al
    if al_key in al_cards:
      return al_cards[al_key]
    al_spec = ds.access_levels.get(al_key)
    sub = al_spec.summary if al_spec else ref.subtitle
    badges = _ref_badges(ref, is_set=False, verbose=verbose_badges)
    c = scene.add_card(
        make_card(
            _cid("src_al", al_key),
            f"Access level: {al_key}",
            sub,
            style="@AccessLevelCard",
            icon="AccessLevel",
            badges=badges,
        ),
        parent=sources_col,
    )
    al_cards[al_key] = c.id
    return c.id

  # Pre-populate defined access levels in deterministic order
  for al_key in ds.access_levels:
    ensure_access_level_card(f"$access_levels:{al_key}")

  def ensure_identity_source_cards(ipol_key: str) -> List[str]:
    """Creates or returns source CardNode IDs for an ingress policy."""
    ipol = ds.ingress_policies.get(ipol_key)
    if not ipol:
      ref = ds.resolve_token(f"$ingress_policies:{ipol_key}")
      cid = _cid("src_unresolved_ipol", ipol_key)
      if cid not in source_cards:
        c = scene.add_card(
            make_card(
                cid,
                f"Source: {ipol_key}",
                ref.subtitle,
                style="@IdentityCard",
                icon="IAM",
                badges=_ref_badges(ref, is_set=True, verbose=verbose_badges),
            ),
            parent=sources_col,
        )
        source_cards[cid] = c.id
      return [source_cards[cid]]

    # Check if named access levels are specified in from.access_levels (§4.2)
    named_als = [al for al in ipol.from_access_levels if al != "*"]
    if named_als:
      return [ensure_access_level_card(al) for al in named_als]

    out_ids: List[str] = []
    # Group $iam_principals:service_agents/org/* into one card per policy (§4.2)
    org_agents: List[str] = []
    other_idents: List[str] = []
    for ident in ipol.from_identities:
      if ident.startswith("$iam_principals:service_agents/org/"):
        org_agents.append(ident.removeprefix("$iam_principals:service_agents/org/"))
      else:
        other_idents.append(ident)

    if org_agents:
      grp_key = f"org_agents_{ipol_key}"
      if grp_key not in source_cards:
        is_scc = "scc" in ipol_key.lower() or any(
            "csc" in a or "ktd" in a or "security-center" in a for a in org_agents
        )
        prefix_lbl = "SCC service agents" if is_scc else "Org service agents"
        title = f"{prefix_lbl} ({len(org_agents)})"
        sub = ", ".join(org_agents[:3])
        if len(org_agents) > 3:
          sub += f", +{len(org_agents) - 3}"
        c = scene.add_card(
            make_card(
                _cid("src_agents", ipol_key),
                title,
                sub,
                style="@IdentityCard",
                icon="ServiceAgent",
                badges=[Badge(text="service agents", tone="info")],
            ),
            parent=sources_col,
        )
        source_cards[grp_key] = c.id
      out_ids.append(source_cards[grp_key])

    for ident in other_idents:
      if ident not in source_cards:
        ref = ds.resolve_token(ident)
        if ident == "$identity_sets:logging_identities":
          title = "Log sink writers"
        elif ref.namespace == "identity_sets":
          title = f"Identity set: {ref.key}"
        else:
          title = f"Identity: {ref.key}"
        c = scene.add_card(
            make_card(
                _cid("src_id", ref.namespace, ref.key),
                title,
                ref.subtitle,
                style="@IdentityCard",
                icon="IAM",
                badges=_ref_badges(ref, is_set=(ref.namespace == "identity_sets"), verbose=verbose_badges),
            ),
            parent=sources_col,
        )
        source_cards[ident] = c.id
      out_ids.append(source_cards[ident])

    for fres in ipol.from_resources:
      rkey = f"from_res_{fres}"
      if rkey not in source_cards:
        ref = ds.resolve_token(fres)
        c = scene.add_card(
            make_card(
                _cid("src_res", ref.namespace, ref.key),
                f"Source resource: {ref.key}",
                ref.subtitle,
                style="@ProjectCard",
                icon="Project",
                badges=_ref_badges(ref, is_set=(ref.namespace == "resource_sets"), verbose=verbose_badges),
            ),
            parent=sources_col,
        )
        source_cards[rkey] = c.id
      out_ids.append(source_cards[rkey])

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
    title = (
        f"External: {ref.key}"
        if ref.namespace == "literal"
        else f"Target {ref.namespace}: {ref.key}"
    )
    c = scene.add_card(
        make_card(
            _cid("egress_target", ref.namespace, ref.key),
            title,
            ref.subtitle,
            style="@ExternalCard",
            icon="Internet",
            badges=_ref_badges(ref, is_set=(ref.namespace != "literal"), verbose=verbose_badges),
        ),
        parent=ecol,
    )
    egress_cards[raw_target] = c.id
    return c.id

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
    p_badges = _cap_badges(p_badges, MAX_ZONE_BADGES_DEFAULT, verbose_badges)

    p_sub = perim.description or perim.title or ""
    pzone = scene.add_zone(
        make_zone(
            _cid("perim", perim.key, zone_id_suffix),
            zone_style,
            title=zone_title,
            subtitle=p_sub,
            icon="VPCServiceControls",
            layout="column",
            gap=36.0,
            align="center",
            badges=p_badges,
        ),
        parent=parent_zone,
    )

    # Row 1 inside perimeter: Ingress policies row (when ingress policies exist)
    ingress_col: Optional[ZoneNode] = None
    if blk.ingress_policies:
      ingress_col = scene.add_zone(
          make_zone(
              _cid("ing_pol_col", perim.key, zone_id_suffix),
              "@SubGroupWhite",
              title="Ingress policies",
              layout="row",
              gap=20.0,
              align="start",
          ),
          parent=pzone,
      )

    # Row 2 inside perimeter: Protected resources row + Restricted services
    center_col = scene.add_zone(
        make_zone(
            _cid("perim_center", perim.key, zone_id_suffix),
            "@Ghost",
            layout="row",
            gap=20.0,
            align="center",
        ),
        parent=pzone,
    )

    # Protected resources subgroup (@SubGroupWhite)
    prot_zone = scene.add_zone(
        make_zone(
            _cid("prot_res", perim.key, zone_id_suffix),
            "@SubGroupWhite",
            title="Protected resources",
            layout="row",
            gap=20.0,
            align="start",
        ),
        parent=center_col,
    )

    # Row 3 inside perimeter: Egress policies row (when egress policies exist)
    egress_pol_col: Optional[ZoneNode] = None
    if blk.egress_policies:
      egress_pol_col = scene.add_zone(
          make_zone(
              _cid("egr_pol_col", perim.key, zone_id_suffix),
              "@SubGroupWhite",
              title="Egress policies",
              layout="row",
              gap=20.0,
              align="start",
          ),
          parent=pzone,
      )

    res_card_by_token: Dict[str, str] = {}
    first_res_card_id: Optional[str] = None

    def ensure_protected_resource_card(raw_res: str) -> str:
      nonlocal first_res_card_id
      if raw_res in res_card_by_token:
        return res_card_by_token[raw_res]
      if raw_res == "*":
        c = scene.add_card(
            make_card(
                _cid("res_wildcard", perim.key, zone_id_suffix),
                "All perimeter resources (*)",
                "wildcard policy target (*)",
                style="@ResourceSetCard",
                icon="ResourceSet",
                badges=[Badge(text="wildcard", tone="info")],
            ),
            parent=prot_zone,
        )
        res_card_by_token["*"] = c.id
        if first_res_card_id is None:
          first_res_card_id = c.id
        return c.id

      title, sub, style, icon, badges = _format_resource_card_spec(
          raw_res, ds, verbose=verbose_badges
      )
      c = scene.add_card(
          make_card(
              _cid("res", perim.key, zone_id_suffix, raw_res),
              title,
              sub,
              style=style,
              icon=icon,
              badges=badges,
          ),
          parent=prot_zone,
      )
      res_card_by_token[raw_res] = c.id
      if first_res_card_id is None:
        first_res_card_id = c.id
      return c.id

    # 1. Explicit perimeter resources
    for r in blk.resources:
      ensure_protected_resource_card(r)

    # 2. Check ingress/egress policies for referenced perimeter resources (e.g. $resource_sets:logging_project or *)
    for ip_ref in blk.ingress_policies:
      ip_tok = ds.resolve_token(ip_ref)
      ipol = ds.ingress_policies.get(ip_tok.key)
      if ipol:
        for tr in ipol.to_resources:
          ensure_protected_resource_card(tr)

    for ep_ref in blk.egress_policies:
      ep_tok = ds.resolve_token(ep_ref)
      epol = ds.egress_policies.get(ep_tok.key)
      if epol:
        if epol.from_resources:
          for fr in epol.from_resources:
            ensure_protected_resource_card(fr)
        else:
          ensure_protected_resource_card("*")

    # 3. Restricted services summary card
    if blk.restricted_services:
      total_svcs = 0
      sample_svcs: List[str] = []
      rs_badges: List[Badge] = []
      for rs_entry in blk.restricted_services:
        ref = ds.resolve_token(rs_entry)
        if ref.members:
          total_svcs += len(ref.members)
          for m in ref.members:
            short_m = m.removesuffix(".googleapis.com")
            if short_m not in sample_svcs:
              sample_svcs.append(short_m)
        elif not ref.unresolved:
          total_svcs += 1
          sample_svcs.append(ref.key.removesuffix(".googleapis.com"))
        if ref.unresolved:
          rs_badges.append(Badge(text="unresolved", tone="warn"))

      priority = ("storage", "bigquery", "compute")
      ordered_samples = [p for p in priority if p in sample_svcs] + [
          s for s in sample_svcs if s not in priority
      ]
      shown = ", ".join(ordered_samples[:3])
      if total_svcs > 3:
        shown += f", +{total_svcs - 3}"
      scene.add_card(
          make_card(
              _cid("restricted_svcs", perim.key, zone_id_suffix),
              f"Restricted services: {total_svcs}",
              shown or "none",
              style="@ProductCard",
              icon="ApiService",
              badges=_cap_badges(rs_badges, MAX_CARD_BADGES_DEFAULT, verbose_badges),
          ),
          parent=center_col,
      )

    # 4. VPC accessible services card (when present)
    if blk.vpc_accessible_services is not None:
      vas = blk.vpc_accessible_services
      vas_sub = (
          f"enable_restriction: {vas.enable_restriction} · "
          f"{len(vas.allowed_services)} allowed services"
      )
      scene.add_card(
          make_card(
              _cid("vpc_acc_svcs", perim.key, zone_id_suffix),
              "VPC accessible services",
              vas_sub,
              style="@ProductCard",
              icon="VirtualPrivateCloud",
          ),
          parent=center_col,
      )

    # 5. Edges & Intermediate Policy Cards (§26 & §36 item 2: top-to-bottom bottom->top flow)
    # 5a. Perimeter-level Access Levels -> @PerimeterZone (dotted teal, concise label)
    for al_ref in blk.access_levels:
      src_al_cid = ensure_access_level_card(al_ref)
      scene.add_edge(
          make_edge(
              src_al_cid,
              pzone.id,
              arrow="-.->",
              label="access level",
              color="$TealStroke",
              stroke_width=1.8,
              dashed=True,
              dash="dotted",
              head="filled",
              source_anchor="bottom",
              target_anchor="top",
          )
      )

    # 5b. Ingress policy chain:
    # [Source Identity / Access Level] --(solid blue "ingress")--> [Ingress: <policy_key>] --(solid blue "")--> [Target Resource Set]
    for ip_ref in blk.ingress_policies:
      ip_tok = ds.resolve_token(ip_ref)
      ip_key = ip_tok.key
      ipol = ds.ingress_policies.get(ip_key)
      src_cids = ensure_identity_source_cards(ip_key)

      if ipol:
        named_als = [al for al in ipol.from_access_levels if al != "*"]
        sub_parts_ip = [ipol.ops_summary]
        if named_als:
          sub_parts_ip.append(_summarize_identities_for_label(ipol.from_identities, ds))
        elif "*" in ipol.from_access_levels:
          sub_parts_ip.append("any access level")
        ip_sub = " · ".join(sub_parts_ip)
        ip_badges: List[Badge] = []
      else:
        ip_sub = ip_tok.subtitle
        ip_badges = _ref_badges(ip_tok, is_set=False, verbose=verbose_badges)

      ip_card = scene.add_card(
          make_card(
              _cid("ing_pol", perim.key, zone_id_suffix, ip_key),
              f"Ingress: {ip_key}",
              ip_sub,
              style="@ProductCard",
              icon="VPCServiceControls",
              stroke_color="$GcpBlue",
              stroke_width=1.8,
              badges=ip_badges,
          ),
          parent=ingress_col or center_col,
      )

      for scid in src_cids:
        scene.add_edge(
            make_edge(
                scid,
                ip_card.id,
                arrow="-->",
                label="ingress",
                color="$GcpBlue",
                stroke_width=2.0,
                dashed=False,
                dash="solid",
                head="filled",
                source_anchor="bottom",
                target_anchor="top",
            )
        )

      target_tokens = (ipol.to_resources if ipol else None) or ["*"]
      for t_tok in target_tokens:
        dst_cid = (
            ensure_protected_resource_card(t_tok)
            if ipol
            else (first_res_card_id or ensure_protected_resource_card("*"))
        )
        scene.add_edge(
            make_edge(
                ip_card.id,
                dst_cid,
                arrow="-->",
                label="",
                color="$GcpBlue",
                stroke_width=2.0,
                dashed=False,
                dash="solid",
                head="filled",
                source_anchor="bottom",
                target_anchor="top",
            )
        )

    # 5c. Egress policy chain:
    # [Source Resource Set / All perimeter resources (*)] --(dashed vermilion "egress")--> [Egress: <policy_key>] --(dashed vermilion "")--> [External Target]
    for ep_ref in blk.egress_policies:
      ep_tok = ds.resolve_token(ep_ref)
      ep_key = ep_tok.key
      epol = ds.egress_policies.get(ep_key)

      if epol:
        id_summary = _summarize_identities_for_label(epol.from_identities, ds)
        ep_sub = f"{epol.ops_summary} · {id_summary}"
        ep_badges: List[Badge] = []
      else:
        ep_sub = ep_tok.subtitle
        ep_badges = _ref_badges(ep_tok, is_set=False, verbose=verbose_badges)

      ep_card = scene.add_card(
          make_card(
              _cid("egr_pol", perim.key, zone_id_suffix, ep_key),
              f"Egress: {ep_key}",
              ep_sub,
              style="@ProductCard",
              icon="VPCServiceControls",
              stroke_color="$VermilionStroke",
              stroke_width=1.8,
              badges=ep_badges,
          ),
          parent=egress_pol_col or center_col,
      )

      from_res_tokens = (epol.from_resources if epol else None) or ["*"]
      to_res_tokens = (
          (epol.to_resources + epol.to_external_resources) if epol else None
      ) or ["*"]

      for fr_tok in from_res_tokens:
        src_cid = (
            ensure_protected_resource_card(fr_tok)
            if epol
            else (first_res_card_id or ensure_protected_resource_card("*"))
        )
        scene.add_edge(
            make_edge(
                src_cid,
                ep_card.id,
                arrow="-.->",
                label="egress",
                color="$VermilionStroke",
                stroke_width=2.0,
                dashed=True,
                dash="dashed",
                head="open",
                source_anchor="bottom",
                target_anchor="top",
            )
        )

      for tr_tok in to_res_tokens:
        dst_cid = ensure_egress_target_card(tr_tok)
        scene.add_edge(
            make_edge(
                ep_card.id,
                dst_cid,
                arrow="-.->",
                label="",
                color="$VermilionStroke",
                stroke_width=2.0,
                dashed=True,
                dash="dashed",
                head="open",
                source_anchor="bottom",
                target_anchor="top",
            )
        )

  # Emit all perimeters in deterministic order
  for pkey, perim in ds.perimeters.items():
    if perim.has_both_equal and perim.status is not None:
      emit_perimeter_block(
          perim,
          perim.status,
          perimeters_col,
          "both",
          [
              Badge(text="ENFORCED (status)", tone="danger"),
              Badge(text="DRY-RUN (spec)", tone="warn"),
          ],
          "@PerimeterZone",
          f"Perimeter: {pkey}",
      )
    elif perim.has_both_different and perim.status is not None and perim.spec is not None:
      outer_pzone = scene.add_zone(
          make_zone(
              _cid("perim_outer", pkey),
              "@PerimeterZone",
              title=f"Perimeter: {pkey}",
              subtitle=perim.description or perim.title or "status + explicit dry-run spec",
              icon="VPCServiceControls",
              layout="column",
              gap=20.0,
              align="center",
              badges=[
                  Badge(text="ENFORCED (status)", tone="danger"),
                  Badge(text="DRY-RUN (spec)", tone="warn"),
              ],
          ),
          parent=perimeters_col,
      )
      emit_perimeter_block(
          perim,
          perim.status,
          outer_pzone,
          "status",
          [Badge(text="ENFORCED (status)", tone="danger")],
          "@PerimeterZone",
          f"{pkey} · status (enforced)",
      )
      emit_perimeter_block(
          perim,
          perim.spec,
          outer_pzone,
          "spec",
          [Badge(text="DRY-RUN (spec)", tone="warn")],
          "@PerimeterDryRunZone",
          f"{pkey} · spec (dry-run)",
      )
    elif perim.status is not None:
      emit_perimeter_block(
          perim,
          perim.status,
          perimeters_col,
          "status",
          [Badge(text="ENFORCED (status)", tone="danger")],
          "@PerimeterZone",
          f"Perimeter: {pkey}",
      )
    elif perim.spec is not None:
      emit_perimeter_block(
          perim,
          perim.spec,
          perimeters_col,
          "spec",
          [Badge(text="DRY-RUN (spec)", tone="warn")],
          "@PerimeterDryRunZone",
          f"Perimeter: {pkey}",
      )

  if legend:
    scene.legend = [
        LegendEntry(
            label="Ingress policy flow (solid blue, filled head)",
            kind="edge",
            color="#1a73e8",
            dash="solid",
            head="filled",
        ),
        LegendEntry(
            label="Egress policy flow (dashed vermilion, open head)",
            kind="edge",
            color="#d55e00",
            dash="dashed",
            head="open",
        ),
        LegendEntry(
            label="Access level binding (dotted teal)",
            kind="edge",
            color="#007b83",
            dash="dotted",
            head="filled",
        ),
        LegendEntry(
            label="Symbolic / discovered set (dashed card border)",
            kind="card",
            color="#5f6368",
            fill="#ffffff",
            dashed=True,
        ),
    ]

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
    **_kwargs: object,
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
