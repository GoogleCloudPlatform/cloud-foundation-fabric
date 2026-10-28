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

"""Tests and negative-control gates for 0-org-setup loader and hierarchy tree builder."""

import copy
import pathlib
from typing import List
import pytest

from fast_diagrammer.datasets.org_setup import (
    OrgSetupDataset,
    load_org_setup_dataset,
)
from fast_diagrammer.scene.layout import layout_scene
from fast_diagrammer.scene.model import Badge, SceneGraph, ZoneNode
from fast_diagrammer.scene.render import render_scene
from fast_diagrammer.stages.org_setup import (
    MAX_CARD_BADGES_DEFAULT,
    MAX_ZONE_BADGES_DEFAULT,
    UNIFORM_BOX_WIDTH,
    build,
)

ORG_DATASETS = ("classic", "classic-gcd", "hardened", "starter-gcd")


def _clean_id(val: str) -> str:
  return "".join(ch if ch.isalnum() else "_" for ch in val)


def _ancestor_zone_ids(scene: SceneGraph, start_zone_id: str | None) -> List[str]:
  chain: List[str] = []
  cur = start_zone_id
  while cur and cur in scene.zones:
    chain.append(cur)
    cur = scene.zones[cur].parent_zone_id
  return chain


def check_org_setup_containment(ds: OrgSetupDataset, scene: SceneGraph) -> List[str]:
  """Gate:
  1. Top-to-bottom tree: Organization card + Folder cards + @ProjectZone containers
     connected by parent->child edges targeting outer @ProjectZone (never inner cards).
  2. Uniform 240.0 px width on every Folder card and every @ProjectZone container.
  3. Sibling folders and sibling projects under the same parent share the exact same Y coordinate.
  4. Lateral `org_controls` has NO edges to `org_root_card`, uses `"logsink"` and `"billing export"` labels.
  """
  errors: List[str] = []

  if "org_root_card" not in scene.cards:
    errors.append("Missing Organization root card 'org_root_card'")

  ctrl_zone = scene.zones.get("org_controls")
  if not ctrl_zone or ctrl_zone.layout != "column" or ctrl_zone.dock_to != "main_tree":
    errors.append("org_controls must be a vertical column docked to main_tree")

  edge_pairs = {(e.src, e.dst) for e in scene.edges}

  # No edges allowed between org_controls cards and org_root_card
  ctrl_card_ids = {
      c.id
      for c in scene.cards.values()
      if "org_controls" in _ancestor_zone_ids(scene, c.parent_zone_id)
  }
  for e in scene.edges:
    if (e.src in ctrl_card_ids and e.dst == "org_root_card") or (
        e.dst in ctrl_card_ids and e.src == "org_root_card"
    ):
      errors.append(f"Forbidden edge between org_controls and org_root_card: {e.src}->{e.dst}")

  # Check every folder is a 240px tree card connected from its parent card, and siblings share Y
  for fkey, fspec in ds.folders.items():
    f_cid = f"folder_card_{_clean_id(fkey)}"
    if f_cid not in scene.cards:
      errors.append(f"Missing folder tree card {f_cid}")
      continue
    fcard = scene.cards[f_cid]
    if fcard.width > 0 and abs(fcard.width - UNIFORM_BOX_WIDTH) > 0.5:
      errors.append(f"Folder card {f_cid} width is {fcard.width}, expected {UNIFORM_BOX_WIDTH}")

    expected_parent_cid = (
        f"folder_card_{_clean_id(fspec.parent_folder_key)}"
        if fspec.parent_folder_key
        else "org_root_card"
    )
    if (expected_parent_cid, f_cid) not in edge_pairs:
      errors.append(f"Missing parent->child tree edge {expected_parent_cid} -> {f_cid}")

    if len(fspec.children_folders) > 1:
      child_ys = {
          round(scene.cards[f"folder_card_{_clean_id(cfk)}"].y, 1)
          for cfk in fspec.children_folders
          if f"folder_card_{_clean_id(cfk)}" in scene.cards
      }
      if len(child_ys) > 1:
        errors.append(f"Sibling sub-folders under {fkey} do not share same Y: {child_ys}")

    if len(fspec.children_projects) > 1:
      proj_ys = {
          round(scene.zones[f"proj_zone_{_clean_id(cpk)}"].y, 1)
          for cpk in fspec.children_projects
          if f"proj_zone_{_clean_id(cpk)}" in scene.zones
      }
      if len(proj_ys) > 1:
        errors.append(f"Sibling projects under {fkey} do not share same Y: {proj_ys}")

  if len(ds.root_folder_keys) > 1:
    root_f_ys = {
        round(scene.cards[f"folder_card_{_clean_id(rfk)}"].y, 1)
        for rfk in ds.root_folder_keys
        if f"folder_card_{_clean_id(rfk)}" in scene.cards
    }
    if len(root_f_ys) > 1:
      errors.append(f"Root folders do not share same Y: {root_f_ys}")

  if len(ds.root_project_keys) > 1:
    root_p_ys = {
        round(scene.zones[f"proj_zone_{_clean_id(rpk)}"].y, 1)
        for rpk in ds.root_project_keys
        if f"proj_zone_{_clean_id(rpk)}" in scene.zones
    }
    if len(root_p_ys) > 1:
      errors.append(f"Root projects do not share same Y: {root_p_ys}")

  # Check every project is a 240px @ProjectZone targeted on its outer border
  for pkey, pspec in ds.projects.items():
    p_zid = f"proj_zone_{_clean_id(pkey)}"
    if p_zid not in scene.zones:
      errors.append(f"Missing @ProjectZone {p_zid} for project {pkey}")
      continue
    pzone = scene.zones[p_zid]
    if pzone.style_name != "@ProjectZone":
      errors.append(f"Zone {p_zid} must have style @ProjectZone, got {pzone.style_name}")
    if pzone.w > 0 and abs(pzone.w - UNIFORM_BOX_WIDTH) > 0.5:
      errors.append(f"ProjectZone {p_zid} width is {pzone.w}, expected {UNIFORM_BOX_WIDTH}")

    expected_branch_zid = (
        f"branch_folder_{_clean_id(pspec.parent_folder_key)}"
        if pspec.parent_folder_key
        else "org_root_projects"
    )
    ancestors = _ancestor_zone_ids(scene, pzone.parent_zone_id)
    if expected_branch_zid not in ancestors:
      errors.append(
          f"ProjectZone {p_zid} not inside {expected_branch_zid} (ancestors={ancestors})"
      )

    expected_parent_cid = (
        f"folder_card_{_clean_id(pspec.parent_folder_key)}"
        if pspec.parent_folder_key
        else "org_root_card"
    )
    if (expected_parent_cid, p_zid) not in edge_pairs:
      errors.append(
          f"Missing parent->child tree edge {expected_parent_cid} -> outer ProjectZone {p_zid}"
      )

    for vspec in pspec.vpcs:
      v_zid = f"vpc_zone_{_clean_id(pkey)}_{_clean_id(vspec.key)}"
      if v_zid not in scene.zones:
        errors.append(f"Missing @VpcZone {v_zid} for VPC {vspec.key}")
        continue
      if scene.zones[v_zid].parent_zone_id != p_zid:
        errors.append(
            f"VpcZone {v_zid} parent is {scene.zones[v_zid].parent_zone_id}, expected {p_zid}"
        )

  # Check hierarchy edges use bottom->top anchors and logsink uses left target anchor
  for e in scene.edges:
    if e.src == "org_root_card" or e.src.startswith("folder_card_"):
      if (e.source_anchor, e.target_anchor) != ("bottom", "top"):
        errors.append(
            f"Hierarchy tree edge {e.src}->{e.dst} must use bottom->top anchors, got {e.source_anchor}->{e.target_anchor}"
        )
    if e.label == "logsink":
      if e.target_anchor != "left":
        errors.append(
            f"logsink edge {e.src}->{e.dst} must enter target from outer left, got {e.target_anchor}"
        )

  # Geometric bounding-box containment check when laid out
  for z in scene.zones.values():
    if z.w <= 0 or z.h <= 0:
      continue
    for ch in z.children:
      cw = ch.w if isinstance(ch, ZoneNode) else ch.width
      ch_h = ch.h if isinstance(ch, ZoneNode) else ch.height
      if (
          ch.x < z.x - 0.5
          or ch.y < z.y - 0.5
          or ch.x + cw > z.x + z.w + 0.5
          or ch.y + ch_h > z.y + z.h + 0.5
      ):
        errors.append(f"Child {ch.id} bbox overflows parent zone {z.id}")
  return errors


def check_badge_budget(scene: SceneGraph) -> List[str]:
  """Gate: <= 4 badges per card and <= 6 badges per zone header without --verbose-badges."""
  errors: List[str] = []
  for cid, card in scene.cards.items():
    if len(card.badges) > MAX_CARD_BADGES_DEFAULT:
      errors.append(
          f"Card {cid} has {len(card.badges)} badges (> {MAX_CARD_BADGES_DEFAULT})"
      )
  for zid, zone in scene.zones.items():
    if len(zone.badges) > MAX_ZONE_BADGES_DEFAULT:
      errors.append(
          f"Zone {zid} has {len(zone.badges)} badges (> {MAX_ZONE_BADGES_DEFAULT})"
      )
  return errors


def test_load_all_reference_org_setup_datasets(stage_dataset):
  classic = load_org_setup_dataset(stage_dataset("0-org-setup", "classic"))
  assert classic.organization.domain == "fast-test-00.example.com"
  assert classic.organization.org_policies_count == 36
  assert classic.organization.custom_constraints_count == 2
  assert classic.organization.custom_roles_count == 9
  assert classic.organization.tag_keys_count == 3
  assert classic.organization.tag_values_count == 5
  assert [s.name for s in classic.organization.sinks] == ["audit-logs", "iam", "vpc-sc"]
  assert classic.root_folder_keys == ["networking", "security", "teams"]
  assert classic.root_project_keys == ["billing-0", "iac-0", "log-0"]
  # F3: projects under projects/core/*.yaml sit at org root, NOT in a "core" folder
  for pk in ("billing-0", "iac-0", "log-0"):
    assert classic.projects[pk].parent is None
    assert classic.projects[pk].parent_folder_key is None
  assert len(classic.projects["iac-0"].cicd_workflows) == 1

  classic_gcd = load_org_setup_dataset(stage_dataset("0-org-setup", "classic-gcd"))
  assert classic_gcd.organization.org_policies_count == 27
  assert classic_gcd.organization.custom_constraints_count == 0
  assert classic_gcd.organization.custom_roles_count == 9

  hardened = load_org_setup_dataset(stage_dataset("0-org-setup", "hardened"))
  assert hardened.organization.org_policies_count == 202
  assert hardened.organization.custom_constraints_count == 136
  assert hardened.organization.custom_roles_count == 14
  assert hardened.organization.scc_sha_modules_count == 18
  # F5: hardened log-0 observability path missing -> tolerated without error, counts = 0
  log0 = hardened.projects["log-0"]
  assert log0.has_observability_factory is True
  assert log0.observability_missing_path is True
  assert log0.observability_alerts_count == 0
  assert log0.observability_metrics_count == 0

  starter = load_org_setup_dataset(stage_dataset("0-org-setup", "starter-gcd"))
  assert starter.root_folder_keys == ["dev", "prod"]
  assert starter.root_project_keys == ["iac-0"]
  assert starter.projects["dev-app-0"].parent_folder_key == "dev"
  assert starter.projects["dev-app-0"].shared_vpc_service_of == "dev-net-0"
  assert starter.projects["dev-net-0"].shared_vpc_host is True
  assert [v.name for v in starter.projects["dev-net-0"].vpcs] == ["dev-shared-0"]
  assert [v.name for v in starter.projects["prod-net-0"].vpcs] == ["prod-shared-0"]


def test_parent_resolution_f3_synthetic_and_negative_control(tmp_path: pathlib.Path):
  """Gate `parent_resolution` (F3): projects/core/x.yaml -> org root; folders/a/b/y.yaml -> $folder_ids:a/b; defaults honoured."""
  (tmp_path / "defaults.yaml").write_text(
      "global:\n"
      "  organization:\n"
      "    domain: example.com\n"
      "    id: 111\n"
      "projects:\n"
      "  defaults:\n"
      "    prefix: test\n",
      encoding="utf-8",
  )
  (tmp_path / "projects" / "core").mkdir(parents=True)
  (tmp_path / "projects" / "core" / "x.yaml").write_text("name: proj-x\n", encoding="utf-8")

  (tmp_path / "folders" / "a" / "b").mkdir(parents=True)
  (tmp_path / "folders" / "a" / ".config.yaml").write_text("name: Folder A\n", encoding="utf-8")
  (tmp_path / "folders" / "a" / "b" / ".config.yaml").write_text("name: Folder B\n", encoding="utf-8")
  (tmp_path / "folders" / "a" / "b" / "y.yaml").write_text("name: proj-y\n", encoding="utf-8")

  ds = load_org_setup_dataset(tmp_path)
  assert ds.projects["x"].parent is None
  assert ds.projects["x"].parent_folder_key is None
  assert "core" not in ds.folders
  assert ds.projects["y"].parent == "$folder_ids:a/b"
  assert ds.projects["y"].parent_folder_key == "a/b"
  assert "y" in ds.folders["a/b"].children_projects

  # Now test defaults.projects.defaults.parent honoured when project has no parent:
  (tmp_path / "defaults.yaml").write_text(
      "global:\n"
      "  organization:\n"
      "    domain: example.com\n"
      "    id: 111\n"
      "projects:\n"
      "  defaults:\n"
      "    prefix: test\n"
      "    parent: $folder_ids:a\n",
      encoding="utf-8",
  )
  ds_def = load_org_setup_dataset(tmp_path)
  assert ds_def.projects["x"].parent == "$folder_ids:a"
  assert ds_def.projects["x"].parent_folder_key == "a"
  # y inside folders/a/b/ still keeps its inferred parent $folder_ids:a/b
  assert ds_def.projects["y"].parent == "$folder_ids:a/b"

  # Negative control: folder depth > 4 must fail
  deep_dir = tmp_path / "folders" / "l1" / "l2" / "l3" / "l4" / "l5"
  deep_dir.mkdir(parents=True)
  (deep_dir / ".config.yaml").write_text("name: Too Deep\n", encoding="utf-8")
  with pytest.raises(ValueError, match="exceeds max depth 4"):
    load_org_setup_dataset(tmp_path)


@pytest.mark.parametrize("ds_name", ORG_DATASETS)
def test_containment_and_badge_budget_org_setup(stage_dataset, ds_name: str):
  ds_path = stage_dataset("0-org-setup", ds_name)
  ds = load_org_setup_dataset(ds_path)
  scene = build(ds, "hierarchy")
  layout_scene(scene)

  assert check_org_setup_containment(ds, scene) == []
  assert check_badge_budget(scene) == []


def test_org_setup_negative_controls(stage_dataset):
  """Known-bad fixtures for tree containment, uniform width, and badge_budget gates must fail."""
  ds = load_org_setup_dataset(stage_dataset("0-org-setup", "starter-gcd"))
  scene = build(ds, "hierarchy")
  layout_scene(scene)

  # Negative control 1: move dev-app-0 ProjectZone into prod folder branch -> containment fails
  bad_scene_1 = copy.deepcopy(scene)
  bad_scene_1.zones["proj_zone_dev_app_0"].parent_zone_id = "branch_folder_prod"
  errs_1 = check_org_setup_containment(ds, bad_scene_1)
  assert errs_1, "Expected containment gate to fail when ProjectZone is in wrong folder branch"

  # Negative control 2: detach VPC zone from its owning ProjectZone -> containment fails
  bad_scene_2 = copy.deepcopy(scene)
  bad_scene_2.zones["vpc_zone_dev_net_0_dev"].parent_zone_id = "branch_folder_dev"
  errs_2 = check_org_setup_containment(ds, bad_scene_2)
  assert errs_2, "Expected containment gate to fail when VPC zone is outside its ProjectZone"

  # Negative control 3: alter ProjectZone width away from 240.0 -> containment fails
  bad_scene_w = copy.deepcopy(scene)
  bad_scene_w.zones["proj_zone_dev_app_0"].w = 260.0
  assert check_org_setup_containment(ds, bad_scene_w), "Expected non-240px ProjectZone to fail"

  # Negative control 4: exceed card badge budget (> 4 badges) -> badge_budget fails
  bad_scene_3 = copy.deepcopy(scene)
  bad_scene_3.cards["org_root_card"].badges = [
      Badge(text=f"b{i}", tone="neutral") for i in range(MAX_CARD_BADGES_DEFAULT + 1)
  ]
  errs_3 = check_badge_budget(bad_scene_3)
  assert errs_3, "Expected badge_budget gate to fail when card has > 4 badges"

  # Negative control 5: exceed zone header badge budget (> 6 badges) -> badge_budget fails
  bad_scene_4 = copy.deepcopy(scene)
  bad_scene_4.zones["proj_zone_iac_0"].badges = [
      Badge(text=f"zb{i}", tone="info") for i in range(MAX_ZONE_BADGES_DEFAULT + 1)
  ]
  errs_4 = check_badge_budget(bad_scene_4)
  assert errs_4, "Expected badge_budget gate to fail when zone header has > 6 badges"


@pytest.mark.parametrize("ds_name", ORG_DATASETS)
def test_org_setup_render_determinism_and_no_overlap(stage_dataset, ds_name: str):
  ds_path = stage_dataset("0-org-setup", ds_name)
  sc1 = build(ds_path, "hierarchy")
  sc2 = build(ds_path, "hierarchy")

  res1 = render_scene(sc1)
  res2 = render_scene(sc2)

  assert res1.overlap_errors == []
  assert res1.svg == res2.svg
  assert res1.drawio == res2.drawio
  assert res1.unknown_icons == []
