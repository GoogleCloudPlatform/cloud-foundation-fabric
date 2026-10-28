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

"""Tests and negative-control gates for 1-vpcsc loader and perimeters builder."""

import copy
import pathlib
from typing import List
import pytest

from fast_diagrammer.datasets.vpcsc import (
    VpcscDataset,
    load_vpcsc_dataset,
)
from fast_diagrammer.scene.layout import layout_scene
from fast_diagrammer.scene.model import SceneGraph, ZoneNode
from fast_diagrammer.scene.render import render_scene
from fast_diagrammer.stages.org_setup import (
    MAX_CARD_BADGES_DEFAULT,
    MAX_ZONE_BADGES_DEFAULT,
)
from fast_diagrammer.stages.vpcsc import build

VPCSC_DATASETS = ("classic", "hardened")


def _clean_id(val: str) -> str:
  return "".join(ch if ch.isalnum() else "_" for ch in val)


def _ancestor_zone_ids(scene: SceneGraph, start_zone_id: str | None) -> List[str]:
  chain: List[str] = []
  cur = start_zone_id
  while cur and cur in scene.zones:
    chain.append(cur)
    cur = scene.zones[cur].parent_zone_id
  return chain


def check_vpcsc_containment_and_budget(scene: SceneGraph) -> List[str]:
  """Gate: every perimeter resource card and intermediate policy card sits inside its perimeter zone, and badge budgets hold."""
  errors: List[str] = []
  for cid, card in scene.cards.items():
    if len(card.badges) > MAX_CARD_BADGES_DEFAULT:
      errors.append(f"Card {cid} exceeds badge budget ({len(card.badges)})")
    if cid.startswith("res_"):
      ancestors = _ancestor_zone_ids(scene, card.parent_zone_id)
      if not any(a.startswith("perim_") for a in ancestors):
        errors.append(f"Resource card {cid} is not inside a perimeter zone (ancestors={ancestors})")
      if not any(a.startswith("prot_res_") for a in ancestors):
        errors.append(
            f"Resource card {cid} is not inside Protected resources subgroup (ancestors={ancestors})"
        )
    if cid.startswith(("ing_pol_", "egr_pol_")):
      ancestors = _ancestor_zone_ids(scene, card.parent_zone_id)
      if not any(a.startswith("perim_") for a in ancestors):
        errors.append(
            f"Intermediate policy card {cid} is not inside a perimeter zone (ancestors={ancestors})"
        )

  for zid, zone in scene.zones.items():
    if len(zone.badges) > MAX_ZONE_BADGES_DEFAULT:
      errors.append(f"Zone {zid} exceeds badge budget ({len(zone.badges)})")
    if zone.w <= 0 or zone.h <= 0:
      continue
    for ch in zone.children:
      cw = ch.w if isinstance(ch, ZoneNode) else ch.width
      ch_h = ch.h if isinstance(ch, ZoneNode) else ch.height
      if (
          ch.x < zone.x - 0.5
          or ch.y < zone.y - 0.5
          or ch.x + cw > zone.x + zone.w + 0.5
          or ch.y + ch_h > zone.y + zone.h + 0.5
      ):
        errors.append(f"Child {ch.id} bbox overflows parent zone {zone.id}")
  return errors


def check_vpcsc_edge_semantics(ds: VpcscDataset, scene: SceneGraph) -> List[str]:
  """Gate `edge_semantics_vpcsc` (§6 & #26 intermediate policy cards):
  - ingress edges (both source->policy card and policy card->resource card) are solid/filled (#1a73e8)
  - egress edges (both resource card->policy card and policy card->external card) are dashed/open (#d55e00)
  - access-level edges are dotted (#007b83)
  - every policy in the dataset produces an intermediate policy card (`Ingress: <k>` / `Egress: <k>`) with incoming and outgoing edges
  - edge labels are concise (<= 16 chars; detailed descriptions live in the intermediate policy cards)
  - a `*` target produces exactly one `All perimeter resources (*)` card per perimeter block.
  """
  errors: List[str] = []
  for idx, e in enumerate(scene.edges):
    if (e.source_anchor, e.target_anchor) != ("bottom", "top"):
      errors.append(
          f"Edge {idx} ({e.src}->{e.dst}) must use bottom->top anchors, got {e.source_anchor}->{e.target_anchor}"
      )
    if len(e.label) > 16:
      errors.append(f"Edge {idx} label too verbose ({e.label!r}); details belong in policy cards")
    if e.src.startswith("ing_pol_") or e.dst.startswith("ing_pol_"):
      if e.dash_style != "solid" or e.head != "filled" or e.color != "#1a73e8":
        errors.append(
            f"Ingress edge {idx} ({e.src}->{e.dst}) has wrong style: dash={e.dash_style}, head={e.head}, color={e.color}"
        )
    elif e.src.startswith("egr_pol_") or e.dst.startswith("egr_pol_"):
      if e.dash_style != "dashed" or e.head != "open" or e.color != "#d55e00":
        errors.append(
            f"Egress edge {idx} ({e.src}->{e.dst}) has wrong style: dash={e.dash_style}, head={e.head}, color={e.color}"
        )
    elif e.label == "access level":
      if e.dash_style != "dotted" or e.color != "#007b83":
        errors.append(
            f"Access-level edge {idx} ({e.src}->{e.dst}) has wrong style: dash={e.dash_style}, color={e.color}"
        )

  for ip_key in ds.ingress_policies:
    suffix = f"_{_clean_id(ip_key)}"
    ip_cards = [
        cid for cid in scene.cards if cid.startswith("ing_pol_") and cid.endswith(suffix)
    ]
    if not ip_cards:
      errors.append(f"Ingress policy {ip_key!r} produced no intermediate policy card")
      continue
    for ip_cid in ip_cards:
      if not any(e.dst == ip_cid for e in scene.edges):
        errors.append(f"Ingress policy card {ip_cid} has 0 incoming edges from sources")
      if not any(e.src == ip_cid for e in scene.edges):
        errors.append(f"Ingress policy card {ip_cid} has 0 outgoing edges to resources")

  for ep_key in ds.egress_policies:
    suffix = f"_{_clean_id(ep_key)}"
    ep_cards = [
        cid for cid in scene.cards if cid.startswith("egr_pol_") and cid.endswith(suffix)
    ]
    if not ep_cards:
      errors.append(f"Egress policy {ep_key!r} produced no intermediate policy card")
      continue
    for ep_cid in ep_cards:
      if not any(e.dst == ep_cid for e in scene.edges):
        errors.append(f"Egress policy card {ep_cid} has 0 incoming edges from resources")
      if not any(e.src == ep_cid for e in scene.edges):
        errors.append(f"Egress policy card {ep_cid} has 0 outgoing edges to external targets")

  # Check wildcard card rule: a `*` target in any policy produces exactly one `All perimeter resources (*)` card
  needs_wildcard = any(
      "*" in ip.to_resources for ip in ds.ingress_policies.values()
  ) or any(
      (not ep.from_resources or "*" in ep.from_resources)
      for ep in ds.egress_policies.values()
  )
  wildcard_cards = [
      c for c in scene.cards.values() if c.title == "All perimeter resources (*)"
  ]
  if needs_wildcard and len(wildcard_cards) != 1:
    errors.append(
        f"Expected exactly 1 'All perimeter resources (*)' card when policy targets *, found {len(wildcard_cards)}"
    )
  if not needs_wildcard and len(wildcard_cards) != 0:
    errors.append(
        f"Expected 0 'All perimeter resources (*)' cards when no policy targets *, found {len(wildcard_cards)}"
    )

  return errors


def test_load_and_build_reference_vpcsc_datasets(stage_dataset):
  # 1. classic: spec only (dry-run)
  classic_dir = stage_dataset("1-vpcsc", "classic")
  classic_ds = load_vpcsc_dataset(classic_dir)
  assert len(classic_ds.restricted_services) == 96
  p_def = classic_ds.perimeters["default"]
  assert p_def.spec is not None and p_def.status is None
  assert p_def.use_explicit_dry_run_spec is True

  sc_classic = build(classic_ds, "perimeters")
  layout_scene(sc_classic)
  assert sc_classic.zones["perim_default_spec"].style_name == "@PerimeterDryRunZone"
  assert any(b.text == "DRY-RUN (spec)" for b in sc_classic.zones["perim_default_spec"].badges)
  assert check_vpcsc_containment_and_budget(sc_classic) == []
  assert check_vpcsc_edge_semantics(classic_ds, sc_classic) == []

  # 2. hardened: status only (enforced), SCC ingress + egress policies
  hardened_dir = stage_dataset("1-vpcsc", "hardened")
  hardened_ds = load_vpcsc_dataset(hardened_dir)
  p_hard = hardened_ds.perimeters["default"]
  assert p_hard.status is not None and p_hard.spec is None

  sc_hardened = build(hardened_ds, "perimeters")
  layout_scene(sc_hardened)
  assert sc_hardened.zones["perim_default_status"].style_name == "@PerimeterZone"
  assert any(b.text == "ENFORCED (status)" for b in sc_hardened.zones["perim_default_status"].badges)
  # Grouped SCC service agents card in Sources column
  assert "src_agents_fast_org_scc" in sc_hardened.cards
  assert sc_hardened.cards["src_agents_fast_org_scc"].title == "SCC service agents (3)"
  # Intermediate ingress and egress policy cards present
  assert "ing_pol_default_status_fast_org_log_sinks" in sc_hardened.cards
  assert "ing_pol_default_status_fast_org_scc" in sc_hardened.cards
  assert "egr_pol_default_status_fast_org_scc" in sc_hardened.cards
  assert check_vpcsc_containment_and_budget(sc_hardened) == []
  assert check_vpcsc_edge_semantics(hardened_ds, sc_hardened) == []


def test_org_dataset_enrichment(stage_dataset):
  """Verifies --org-dataset enrichment resolves logging_project and logging_identities."""
  vpcsc_dir = stage_dataset("1-vpcsc", "classic")
  org_classic = stage_dataset("0-org-setup", "classic")
  org_starter = stage_dataset("0-org-setup", "starter-gcd")

  ds_with_classic = load_vpcsc_dataset(vpcsc_dir, org_dataset_dir=org_classic)
  log_proj_ref = ds_with_classic.resolve_token("$resource_sets:logging_project")
  assert log_proj_ref.provenance == "org-dataset"
  assert log_proj_ref.members == ["log-0"]
  assert "log-0 (via --org-dataset)" in log_proj_ref.subtitle

  log_id_ref = ds_with_classic.resolve_token("$identity_sets:logging_identities")
  assert log_id_ref.provenance == "org-dataset"
  assert "writers of 3 sinks: audit-logs, iam, vpc-sc" == log_id_ref.subtitle

  org_projs_ref = ds_with_classic.resolve_token("$resource_sets:org_setup_projects")
  assert org_projs_ref.provenance == "org-dataset"
  assert org_projs_ref.members == ["billing-0", "iac-0", "log-0"]

  # With starter-gcd, logging sink points to iac-0!
  ds_with_starter = load_vpcsc_dataset(vpcsc_dir, org_dataset_dir=org_starter)
  starter_log_ref = ds_with_starter.resolve_token("$resource_sets:logging_project")
  assert starter_log_ref.provenance == "org-dataset"
  assert starter_log_ref.members == ["iac-0"]
  assert "iac-0 (via --org-dataset)" in starter_log_ref.subtitle


def test_set_resolution_unknown_and_strict_gate(tmp_path: pathlib.Path):
  """Gate `set_resolution` (§6): unknown $ns:key -> `unresolved` badge; raises only with strict=True."""
  (tmp_path / "defaults.yaml").write_text(
      "context:\n"
      "  resource_sets:\n"
      "    static_set:\n"
      "      - projects/111\n"
      "      - projects/222\n",
      encoding="utf-8",
  )
  (tmp_path / "restricted-services.yaml").write_text(
      "- storage.googleapis.com\n- bigquery.googleapis.com\n",
      encoding="utf-8",
  )
  (tmp_path / "perimeters").mkdir()
  (tmp_path / "perimeters" / "default.yaml").write_text(
      "status:\n"
      "  resources:\n"
      "    - $resource_sets:static_set\n"
      "    - $resource_sets:mystery_unknown\n"
      "  restricted_services:\n"
      "    - $service_sets:restricted_services\n",
      encoding="utf-8",
  )

  # Non-strict mode: loads and builds without error, attaches `unresolved` badge
  ds = load_vpcsc_dataset(tmp_path, strict=False)
  assert ds.resolved_sets["$resource_sets:static_set"].provenance == "defaults-context"
  assert ds.resolved_sets["$resource_sets:mystery_unknown"].unresolved is True
  assert len(ds.unresolved_refs) == 1

  scene = build(ds, "perimeters", strict=False)
  unknown_card = scene.cards["res_default_status__resource_sets_mystery_unknown"]
  assert any(b.text == "unresolved" for b in unknown_card.badges)

  # Strict mode: must fail with ValueError (negative control for set_resolution)
  with pytest.raises(ValueError, match="Unresolved symbolic references"):
    load_vpcsc_dataset(tmp_path, strict=True)
  with pytest.raises(ValueError, match="Unresolved symbolic references"):
    build(tmp_path, "perimeters", strict=True)


def test_vpcsc_negative_controls(stage_dataset):
  """Known-bad mutations must fail `check_vpcsc_edge_semantics` and `check_vpcsc_containment_and_budget`."""
  ds = load_vpcsc_dataset(stage_dataset("1-vpcsc", "hardened"))
  scene = build(ds, "perimeters")
  layout_scene(scene)

  # Negative control 1: flip ingress edge to dashed -> fails edge_semantics_vpcsc
  bad_1 = copy.deepcopy(scene)
  for e in bad_1.edges:
    if e.dst.startswith("ing_pol_"):
      e.dash = "dashed"
      break
  assert check_vpcsc_edge_semantics(ds, bad_1), "Expected dashed ingress edge to fail gate"

  # Negative control 2: flip egress edge to filled head -> fails edge_semantics_vpcsc
  bad_2 = copy.deepcopy(scene)
  for e in bad_2.edges:
    if e.src.startswith("egr_pol_"):
      e.head = "filled"
      break
  assert check_vpcsc_edge_semantics(ds, bad_2), "Expected filled-head egress edge to fail gate"

  # Negative control 3: remove intermediate egress policy card -> fails edge_semantics_vpcsc
  bad_3 = copy.deepcopy(scene)
  del bad_3.cards["egr_pol_default_status_fast_org_scc"]
  assert check_vpcsc_edge_semantics(ds, bad_3), "Expected missing intermediate policy card to fail gate"

  # Negative control 4: duplicate `All perimeter resources (*)` card -> fails edge_semantics_vpcsc
  bad_4 = copy.deepcopy(scene)
  dup_card = copy.deepcopy(bad_4.cards["res_wildcard_default_status"])
  dup_card.id = "res_wildcard_dup"
  bad_4.cards["res_wildcard_dup"] = dup_card
  assert check_vpcsc_edge_semantics(ds, bad_4), "Expected duplicate wildcard card to fail gate"

  # Negative control 5: move protected resource card outside perimeter -> fails containment
  bad_5 = copy.deepcopy(scene)
  bad_5.cards["res_wildcard_default_status"].parent_zone_id = "sources_col"
  assert check_vpcsc_containment_and_budget(bad_5), "Expected resource card outside perimeter to fail"


@pytest.mark.parametrize("ds_name", VPCSC_DATASETS)
@pytest.mark.parametrize("with_org", (False, True))
def test_vpcsc_render_determinism_and_no_overlap(stage_dataset, ds_name: str, with_org: bool):
  vpcsc_dir = stage_dataset("1-vpcsc", ds_name)
  org_dir = stage_dataset("0-org-setup", ds_name) if with_org else None

  sc1 = build(vpcsc_dir, "perimeters", org_dataset=org_dir)
  sc2 = build(vpcsc_dir, "perimeters", org_dataset=org_dir)

  res1 = render_scene(sc1)
  res2 = render_scene(sc2)

  assert res1.overlap_errors == []
  assert res1.svg == res2.svg
  assert res1.drawio == res2.drawio
  assert res1.unknown_icons == []
