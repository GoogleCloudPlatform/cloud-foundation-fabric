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
"""Tests and negative-control gates for the 1-vpcsc perimeters builder."""

import copy
import pathlib
import shutil
import warnings
from typing import Dict, List, Optional

import pytest

from fast_diagrammer.datasets.vpcsc import (
    VpcscDataset,
    load_vpcsc_dataset,
)
from fast_diagrammer.scene.layout import layout_scene
from fast_diagrammer.scene.model import SceneGraph, ZoneNode, resolve_color
from fast_diagrammer.scene.render import render_scene
from fast_diagrammer.stages._common import (
    MAX_CARD_BADGES_DEFAULT,
    MAX_ZONE_BADGES_DEFAULT,
    cid,
)
from fast_diagrammer.stages.vpcsc import (
    BADGE_DRY_RUN,
    BADGE_ENFORCED,
    BADGE_SPEC_NOT_APPLIED,
    build,
    load_dataset,
)

VPCSC_DATASETS = ("classic", "hardened")
CRAFTED_REVIEW_DATASET = pathlib.Path("/tmp/fd-review-stages/crafted/vpcsc")

INGRESS_COLOR = resolve_color("$GcpBlue")
EGRESS_COLOR = resolve_color("$VermilionStroke")
ACCESS_LEVEL_COLOR = resolve_color("$TealStroke")


def _ancestor_zone_ids(scene: SceneGraph,
                       start_zone_id: Optional[str]) -> List[str]:
  chain: List[str] = []
  cur = start_zone_id
  while cur and cur in scene.zones:
    chain.append(cur)
    cur = scene.zones[cur].parent_zone_id
  return chain


def _write_dataset(root: pathlib.Path, files: Dict[str, str]) -> pathlib.Path:
  for rel, text in files.items():
    path = root / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")
  return root


def _edges_touching(scene: SceneGraph, node_id: str):
  return [e for e in scene.edges if node_id in (e.src, e.dst)]


def check_vpcsc_containment_and_budget(scene: SceneGraph) -> List[str]:
  """Gate: perimeter members sit in "Protected resources", policy targets in
  "Policy targets", policy cards inside their perimeter; badge budgets hold.
  """
  errors: List[str] = []
  for card_id, card in scene.cards.items():
    if len(card.badges) > MAX_CARD_BADGES_DEFAULT:
      errors.append(f"Card {card_id} exceeds badge budget ({len(card.badges)})")
    ancestors = _ancestor_zone_ids(scene, card.parent_zone_id)
    if card_id.startswith(("res_", "tgt_", "ing_pol_", "egr_pol_")):
      if not any(a.startswith("perim_") for a in ancestors):
        errors.append(f"Card {card_id} is not inside a perimeter zone "
                      f"(ancestors={ancestors})")
    if card_id.startswith("res_"):
      if not any(a.startswith("prot_res_") for a in ancestors):
        errors.append(f"Resource card {card_id} is not inside Protected "
                      f"resources (ancestors={ancestors})")
    if card_id.startswith("tgt_"):
      if not any(a.startswith("pol_targets_") for a in ancestors):
        errors.append(f"Policy target {card_id} is not inside Policy targets "
                      f"(ancestors={ancestors})")
      if any(a.startswith("prot_res_") for a in ancestors):
        errors.append(f"Policy target {card_id} is inside Protected resources")

  for zid, zone in scene.zones.items():
    if len(zone.badges) > MAX_ZONE_BADGES_DEFAULT:
      errors.append(f"Zone {zid} exceeds badge budget ({len(zone.badges)})")
    if zone.w <= 0 or zone.h <= 0:
      continue
    for ch in zone.children:
      cw = ch.w if isinstance(ch, ZoneNode) else ch.width
      ch_h = ch.h if isinstance(ch, ZoneNode) else ch.height
      if (ch.x < zone.x - 0.5 or ch.y < zone.y - 0.5 or
          ch.x + cw > zone.x + zone.w + 0.5 or
          ch.y + ch_h > zone.y + zone.h + 0.5):
        errors.append(f"Child {ch.id} bbox overflows parent zone {zone.id}")
  return errors


def check_vpcsc_edge_semantics(ds: VpcscDataset,
                               scene: SceneGraph) -> List[str]:
  """Gate: edge styles, concise labels, and one policy card per policy.

  - ingress edges (source -> policy card -> target) are solid, filled, blue;
  - egress edges (resource -> policy card -> external) are dashed, open,
    vermilion;
  - access-level edges are dotted teal;
  - every resolved policy produces an `Ingress:`/`Egress:` card with incoming
    and outgoing edges; labels stay short (details live on the cards);
  - a `*` target produces exactly one `All perimeter resources (*)` card.
  """
  errors: List[str] = []
  for idx, e in enumerate(scene.edges):
    if (e.source_anchor, e.target_anchor) != ("bottom", "top"):
      errors.append(f"Edge {idx} ({e.src}->{e.dst}) must use bottom->top "
                    f"anchors, got {e.source_anchor}->{e.target_anchor}")
    if len(e.label) > 16:
      errors.append(f"Edge {idx} label too verbose ({e.label!r})")
    if e.src.startswith("ing_pol_") or e.dst.startswith("ing_pol_"):
      if (e.dash_style != "solid" or e.head != "filled" or
          e.color != INGRESS_COLOR):
        errors.append(f"Ingress edge {idx} ({e.src}->{e.dst}) has wrong "
                      f"style: {e.dash_style}/{e.head}/{e.color}")
    elif e.src.startswith("egr_pol_") or e.dst.startswith("egr_pol_"):
      if (e.dash_style != "dashed" or e.head != "open" or
          e.color != EGRESS_COLOR):
        errors.append(f"Egress edge {idx} ({e.src}->{e.dst}) has wrong "
                      f"style: {e.dash_style}/{e.head}/{e.color}")
    elif e.label == "access level":
      if e.dash_style != "dotted" or e.color != ACCESS_LEVEL_COLOR:
        errors.append(f"Access-level edge {idx} ({e.src}->{e.dst}) has wrong "
                      f"style: {e.dash_style}/{e.color}")

  for prefix, policies in (("ing_pol_", ds.ingress_policies),
                           ("egr_pol_", ds.egress_policies)):
    for key in policies:
      suffix = f"_{cid(key)}"
      cards = [
          c for c in scene.cards if c.startswith(prefix) and c.endswith(suffix)
      ]
      if not cards:
        errors.append(f"Policy {key!r} produced no {prefix} card")
      for card_id in cards:
        if not any(e.dst == card_id for e in scene.edges):
          errors.append(f"Policy card {card_id} has 0 incoming edges")
        if not any(e.src == card_id for e in scene.edges):
          errors.append(f"Policy card {card_id} has 0 outgoing edges")

  needs_wildcard = any(
      "*" in ip.to_resources for ip in ds.ingress_policies.values()) or any(
          (not ep.from_resources or "*" in ep.from_resources)
          for ep in ds.egress_policies.values())
  wildcard_cards = [
      c for c in scene.cards.values()
      if c.title == "All perimeter resources (*)"
  ]
  if needs_wildcard and len(wildcard_cards) != 1:
    errors.append("Expected exactly 1 'All perimeter resources (*)' card, "
                  f"found {len(wildcard_cards)}")
  if not needs_wildcard and wildcard_cards:
    errors.append("Expected no 'All perimeter resources (*)' card, found "
                  f"{len(wildcard_cards)}")
  return errors


def test_load_and_build_reference_vpcsc_datasets(stage_dataset):
  # classic: spec only, explicit dry-run.
  classic_ds = load_vpcsc_dataset(stage_dataset("1-vpcsc", "classic"))
  assert len(classic_ds.restricted_services) == 96
  p_def = classic_ds.perimeters["default"]
  assert p_def.spec is not None and p_def.status is None
  assert p_def.use_explicit_dry_run_spec is True

  sc_classic = build(classic_ds, "perimeters")
  layout_scene(sc_classic)
  zone = sc_classic.zones["perim_default_spec"]
  assert zone.style_name == "@PerimeterDryRunZone"
  assert [b.text for b in zone.badges] == [BADGE_DRY_RUN]
  assert check_vpcsc_containment_and_budget(sc_classic) == []
  assert check_vpcsc_edge_semantics(classic_ds, sc_classic) == []

  # hardened: status only (enforced), SCC ingress + egress policies.
  hardened_ds = load_vpcsc_dataset(stage_dataset("1-vpcsc", "hardened"))
  p_hard = hardened_ds.perimeters["default"]
  assert p_hard.status is not None and p_hard.spec is None

  sc_hardened = build(hardened_ds, "perimeters")
  layout_scene(sc_hardened)
  zone = sc_hardened.zones["perim_default_status"]
  assert zone.style_name == "@PerimeterZone"
  assert [b.text for b in zone.badges] == [BADGE_ENFORCED]
  assert sc_hardened.cards["src_agents_fast_org_scc"].title == (
      "SCC service agents (3)")
  for card_id in ("ing_pol_default_status_fast_org_log_sinks",
                  "ing_pol_default_status_fast_org_scc",
                  "egr_pol_default_status_fast_org_scc"):
    assert card_id in sc_hardened.cards
  # Policy-only resources are targets, not perimeter members.
  assert "tgt_default_status__resource_sets_logging_project" in (
      sc_hardened.cards)
  assert "res_default_status__resource_sets_logging_project" not in (
      sc_hardened.cards)
  assert check_vpcsc_containment_and_budget(sc_hardened) == []
  assert check_vpcsc_edge_semantics(hardened_ds, sc_hardened) == []


def test_org_dataset_enrichment(stage_dataset):
  """--org-dataset resolves logging_project and logging_identities."""
  vpcsc_dir = stage_dataset("1-vpcsc", "classic")
  org_classic = stage_dataset("0-org-setup", "classic")

  ds = load_vpcsc_dataset(vpcsc_dir, org_dataset_dir=org_classic)
  log_proj_ref = ds.resolve_token("$resource_sets:logging_project")
  assert log_proj_ref.provenance == "org-dataset"
  assert log_proj_ref.members == ["log-0"]
  log_id_ref = ds.resolve_token("$identity_sets:logging_identities")
  assert log_id_ref.provenance == "org-dataset"
  assert log_id_ref.subtitle == "writers of 3 sinks: audit-logs, iam, vpc-sc"
  org_projs_ref = ds.resolve_token("$resource_sets:org_setup_projects")
  assert org_projs_ref.members == ["billing-0", "iac-0", "log-0"]


def _warnings_of(fn):
  """Runs `fn` and returns (result, warning messages from either channel)."""
  with warnings.catch_warnings(record=True) as caught:
    warnings.simplefilter("always")
    result = fn()
  msgs = [str(w.message) for w in caught]
  msgs += list(getattr(result, "warnings", None) or [])
  return result, msgs


def test_m6_org_dataset_validation(stage_dataset, tmp_path):
  """A matching --org-dataset is used; a mismatching one is warned and
  ignored (negative controls: changed local_path, missing bucket project,
  a directory that is not an org dataset)."""
  vpcsc_dir = stage_dataset("1-vpcsc", "hardened")
  org_dir = stage_dataset("0-org-setup", "hardened")

  ds, msgs = _warnings_of(lambda: load_dataset(vpcsc_dir, org_dir))
  assert ds.org_dataset is not None
  assert not [m for m in msgs if "org-dataset" in m]

  def mismatch(defaults_text: str, org=org_dir):
    crafted = tmp_path / f"v{len(list(tmp_path.iterdir()))}"
    shutil.copytree(vpcsc_dir, crafted)
    (crafted / "defaults.yaml").write_text(defaults_text, encoding="utf-8")
    return _warnings_of(lambda: load_dataset(crafted, org))

  ds, msgs = mismatch("output_files:\n  local_path: ~/fast-config/other\n")
  assert ds.org_dataset is None
  assert any("local_path" in m for m in msgs), msgs
  assert ds.resolve_token("$resource_sets:logging_project").provenance != (
      "org-dataset")

  ds, msgs = mismatch("output_files:\n"
                      "  storage_bucket: $storage_buckets:nope-0/outputs\n")
  assert ds.org_dataset is None
  assert any("nope-0" in m for m in msgs), msgs

  ds, msgs = mismatch("context:\n  organization_ids:\n    default: 42\n")
  assert ds.org_dataset is None
  assert any("organization_ids" in m for m in msgs), msgs

  not_org = tmp_path / "not-org"
  not_org.mkdir()
  ds, msgs = _warnings_of(lambda: load_dataset(vpcsc_dir, not_org))
  assert ds.org_dataset is None
  assert any("org-dataset" in m for m in msgs), msgs

  # The scene of a mismatched run never claims org-dataset provenance.
  scene, _ = _warnings_of(
      lambda: build(vpcsc_dir, "perimeters", org_dataset=not_org))
  assert not any("org-dataset" in c.subtitle for c in scene.cards.values())


def test_m1_ingress_sources_with_access_level(tmp_path):
  """Identities and source resources are drawn even when named access
  levels are present; the access level stays a source too."""
  root = _write_dataset(
      tmp_path, {
          "defaults.yaml":
              "context: {}\n",
          "access-levels/geo.yaml":
              "conditions:\n  - regions: [IT]\n",
          "ingress-policies/mixed.yaml":
              ("from:\n"
               "  access_levels: [$access_levels:geo]\n"
               "  identities: ['user:a@example.com']\n"
               "  resources: ['projects/999']\n"
               "to:\n"
               "  operations: [{service_name: '*'}]\n"
               "  resources: ['projects/123']\n"),
          "perimeters/p.yaml":
              ("status:\n"
               "  resources: ['projects/123']\n"
               "  ingress_policies: [$ingress_policies:mixed]\n"),
      })
  scene = build(root, "perimeters")
  pol = "ing_pol_p_status_mixed"
  sources = {e.src for e in scene.edges if e.dst == pol}
  assert sources == {
      "src_al_geo",
      "src_id_literal_user_a_example_com",
      "src_res_literal_projects_999",
  }
  # The target is a perimeter member: the edge reuses its protected card.
  assert {e.dst for e in scene.edges if e.src == pol
         } == {"res_p_status_projects_123"}
  assert not any(c.startswith("tgt_") for c in scene.cards)


def test_identity_type_source_card(tmp_path):
  root = _write_dataset(
      tmp_path, {
          "ingress-policies/any.yaml":
              ("from:\n  identity_type: ANY_IDENTITY\n"
               "to:\n  operations: [{service_name: '*'}]\n"
               "  resources: ['*']\n"),
          "perimeters/p.yaml":
              "status:\n  ingress_policies: [$ingress_policies:any]\n",
      })
  ds = load_vpcsc_dataset(root)
  assert ds.ingress_policies["any"].from_identity_type == "ANY_IDENTITY"
  scene = build(ds, "perimeters")
  card = scene.cards["src_idtype_ANY_IDENTITY"]
  assert card.title == "Any identity"
  assert any(
      e.src == card.id and e.dst == "ing_pol_p_status_any" for e in scene.edges)


def test_psc_endpoint_source_card(tmp_path):
  root = _write_dataset(
      tmp_path, {
          "ingress-policies/psc.yaml":
              ("from:\n  identities: ['user:a@example.com']\n"
               "  psc_endpoints: ['projects/1/regions/r/forwardingRules/f']\n"
               "to:\n  operations: [{service_name: '*'}]\n"
               "  resources: ['*']\n"),
          "perimeters/p.yaml":
              "status:\n  ingress_policies: [$ingress_policies:psc]\n",
      })
  scene = build(root, "perimeters")
  psc = [c for c in scene.cards if c.startswith("src_psc_")]
  assert len(psc) == 1
  assert any(
      e.src == psc[0] and e.dst == "ing_pol_p_status_psc" for e in scene.edges)


def test_m2_unresolved_policies_have_no_invented_edges(tmp_path):
  root = _write_dataset(
      tmp_path, {
          "perimeters/p.yaml":
              ("status:\n"
               "  resources: ['projects/123']\n"
               "  ingress_policies: [$ingress_policies:missing_in]\n"
               "  egress_policies: [$egress_policies:missing_eg]\n"),
      })
  scene = build(root, "perimeters")
  for card_id in ("ing_pol_p_status_missing_in", "egr_pol_p_status_missing_eg"):
    card = scene.cards[card_id]
    assert card.dashed
    assert any(b.text == "unresolved" for b in card.badges)
    assert _edges_touching(scene, card_id) == []
  assert not any(c.startswith("src_") and "missing" in c for c in scene.cards)
  assert _edges_touching(scene, "res_p_status_projects_123") == []
  assert not any("wildcard" in c for c in scene.cards)


def test_m3_policy_targets_are_not_perimeter_members(tmp_path):
  root = _write_dataset(
      tmp_path, {
          "ingress-policies/in.yaml":
              ("from:\n  identities: ['user:a@example.com']\n"
               "to:\n  operations: [{service_name: '*'}]\n"
               "  resources: ['projects/777']\n"),
          "egress-policies/eg.yaml":
              ("from:\n  identities: ['user:a@example.com']\n"
               "to:\n  operations: [{service_name: '*'}]\n"
               "  resources: ['projects/888']\n"),
          "perimeters/p.yaml": ("status:\n"
                                "  resources: ['projects/123']\n"
                                "  ingress_policies: [$ingress_policies:in]\n"
                                "  egress_policies: [$egress_policies:eg]\n"),
      })
  scene = build(root, "perimeters")
  prot = scene.zones["prot_res_p_status"]
  targets = scene.zones["pol_targets_p_status"]
  assert targets.title == "Policy targets"
  assert [c.id for c in prot.children] == ["res_p_status_projects_123"]
  assert sorted(c.id for c in targets.children) == [
      "tgt_p_status_projects_777",
      "tgt_wildcard_p_status",
  ]
  layout_scene(scene)
  assert check_vpcsc_containment_and_budget(scene) == []

  # Negative control: a target moved into Protected resources must fail.
  bad = copy.deepcopy(scene)
  bad.cards["tgt_p_status_projects_777"].parent_zone_id = "prot_res_p_status"
  assert check_vpcsc_containment_and_budget(bad)


@pytest.mark.parametrize(
    "doc, zone_id, badges, title",
    [
        ("use_explicit_dry_run_spec: true\nspec:\n  resources: [projects/1]\n",
         "perim_p_spec", [BADGE_DRY_RUN], "Perimeter: p"),
        ("spec:\n  resources: [projects/1]\n", "perim_p_spec",
         [BADGE_SPEC_NOT_APPLIED], f"Perimeter: p · {BADGE_SPEC_NOT_APPLIED}"),
        ("status:\n  resources: [projects/1]\n", "perim_p_status",
         [BADGE_ENFORCED], "Perimeter: p"),
        ("status:\n  resources: [projects/1]\n"
         "spec:\n  resources: [projects/1]\n", "perim_p_both",
         [BADGE_ENFORCED, BADGE_SPEC_NOT_APPLIED], "Perimeter: p"),
        ("use_explicit_dry_run_spec: true\n"
         "status:\n  resources: [projects/1]\n"
         "spec:\n  resources: [projects/2]\n", "perim_p_spec", [BADGE_DRY_RUN],
         "p · spec (dry-run)"),
        ("status:\n  resources: [projects/1]\n"
         "spec:\n  resources: [projects/2]\n", "perim_p_spec",
         [BADGE_SPEC_NOT_APPLIED], f"p · {BADGE_SPEC_NOT_APPLIED}"),
    ],
)
def test_m4_dry_run_labels_follow_explicit_flag(tmp_path, doc, zone_id, badges,
                                                title):
  root = _write_dataset(tmp_path, {"perimeters/p.yaml": doc})
  scene = build(root, "perimeters")
  zone = scene.zones[zone_id]
  assert [b.text for b in zone.badges] == badges
  assert zone.title == title
  all_badges = [b.text for z in scene.zones.values() for b in z.badges]
  if BADGE_DRY_RUN not in badges:
    assert BADGE_DRY_RUN not in all_badges


def test_l7_empty_resolved_service_set_counts_zero(tmp_path):
  root = _write_dataset(
      tmp_path, {
          "restricted-services.yaml":
              "[]\n",
          "perimeters/p.yaml":
              ("status:\n  resources: [projects/1]\n"
               "  restricted_services: [$service_sets:restricted_services]\n"),
      })
  scene = build(root, "perimeters")
  card = scene.cards["restricted_svcs_p_status"]
  assert card.title == "Restricted services: 0"
  assert card.subtitle == "none"


def test_l4_build_rejects_unknown_options(stage_dataset):
  with pytest.raises(TypeError):
    build(stage_dataset("1-vpcsc", "classic"), "perimeters", verbose_badge=True)


def test_legend_uses_edge_colours(stage_dataset):
  scene = build(stage_dataset("1-vpcsc", "hardened"), "perimeters")
  edge_colours = {e.color for e in scene.edges}
  legend_edge_colours = {l.color for l in scene.legend if l.kind == "edge"}
  assert legend_edge_colours <= edge_colours | {ACCESS_LEVEL_COLOR}
  assert {INGRESS_COLOR, EGRESS_COLOR,
          ACCESS_LEVEL_COLOR} == (legend_edge_colours)
  assert not build(stage_dataset("1-vpcsc", "hardened"), "perimeters",
                   legend=False).legend


@pytest.mark.skipif(not CRAFTED_REVIEW_DATASET.is_dir(),
                    reason="review repro dataset not present")
def test_review_crafted_dataset():
  scene = build(CRAFTED_REVIEW_DATASET, "perimeters")
  # The unresolved ingress policy has a card but no edges.
  assert _edges_touching(scene, "ing_pol_p1_status_missing") == []
  assert scene.cards["ing_pol_p1_status_missing"].dashed
  # Identities and the source resource sit next to the access level.
  sources = {e.src for e in scene.edges if e.dst == "ing_pol_p1_status_ok"}
  assert {
      "src_al_missing", "src_id_literal_user_a_b_com",
      "src_res_literal_projects_999", "src_agents_ok"
  } <= sources
  # use_explicit_dry_run_spec is false in both perimeters.
  assert [b.text for b in scene.zones["perim_p2_spec"].badges
         ] == [BADGE_SPEC_NOT_APPLIED]
  assert render_scene(scene).overlap_errors == []


def test_set_resolution_unknown_and_strict_gate(tmp_path: pathlib.Path):
  """Unknown $ns:key -> `unresolved` badge; raises only with strict=True."""
  _write_dataset(
      tmp_path, {
          "defaults.yaml": ("context:\n"
                            "  resource_sets:\n"
                            "    static_set:\n"
                            "      - projects/111\n"
                            "      - projects/222\n"),
          "restricted-services.yaml":
              "- storage.googleapis.com\n- bigquery.googleapis.com\n",
          "perimeters/default.yaml":
              ("status:\n"
               "  resources:\n"
               "    - $resource_sets:static_set\n"
               "    - $resource_sets:mystery_unknown\n"
               "  restricted_services:\n"
               "    - $service_sets:restricted_services\n"),
      })

  ds = load_vpcsc_dataset(tmp_path, strict=False)
  assert ds.resolved_sets["$resource_sets:static_set"].provenance == (
      "defaults-context")
  assert ds.resolved_sets["$resource_sets:mystery_unknown"].unresolved is True
  assert len(ds.unresolved_refs) == 1

  scene = build(ds, "perimeters", strict=False)
  unknown_card = scene.cards[
      "res_default_status__resource_sets_mystery_unknown"]
  assert any(b.text == "unresolved" for b in unknown_card.badges)
  assert scene.cards["restricted_svcs_default_status"].title == (
      "Restricted services: 2")

  with pytest.raises(ValueError, match="Unresolved symbolic references"):
    load_vpcsc_dataset(tmp_path, strict=True)
  with pytest.raises(ValueError, match="Unresolved symbolic references"):
    build(tmp_path, "perimeters", strict=True)


def test_vpcsc_negative_controls(stage_dataset):
  """Known-bad mutations must fail both gates."""
  ds = load_vpcsc_dataset(stage_dataset("1-vpcsc", "hardened"))
  scene = build(ds, "perimeters")
  layout_scene(scene)

  bad_1 = copy.deepcopy(scene)
  next(e for e in bad_1.edges if e.dst.startswith("ing_pol_")).dash = "dashed"
  assert check_vpcsc_edge_semantics(ds, bad_1), "dashed ingress edge"

  bad_2 = copy.deepcopy(scene)
  next(e for e in bad_2.edges if e.src.startswith("egr_pol_")).head = "filled"
  assert check_vpcsc_edge_semantics(ds, bad_2), "filled-head egress edge"

  bad_3 = copy.deepcopy(scene)
  del bad_3.cards["egr_pol_default_status_fast_org_scc"]
  assert check_vpcsc_edge_semantics(ds, bad_3), "missing policy card"

  bad_4 = copy.deepcopy(scene)
  dup_card = copy.deepcopy(bad_4.cards["tgt_wildcard_default_status"])
  dup_card.id = "tgt_wildcard_dup"
  bad_4.cards["tgt_wildcard_dup"] = dup_card
  assert check_vpcsc_edge_semantics(ds, bad_4), "duplicate wildcard card"

  bad_5 = copy.deepcopy(scene)
  bad_5.cards["tgt_wildcard_default_status"].parent_zone_id = "sources_col"
  assert check_vpcsc_containment_and_budget(bad_5), "target outside perimeter"


@pytest.mark.parametrize("ds_name", VPCSC_DATASETS)
@pytest.mark.parametrize("with_org", (False, True))
def test_vpcsc_render_determinism_and_no_overlap(stage_dataset, ds_name: str,
                                                 with_org: bool):
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
