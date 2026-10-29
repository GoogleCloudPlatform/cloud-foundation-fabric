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
"""Tests for skills/fast/networking/scripts/validate_dataset.py."""

from __future__ import annotations

import importlib.util
import pathlib
import shutil
import sys

import pytest
import yaml

SKILL_DIR = pathlib.Path(__file__).resolve().parents[1]
SCRIPT_PATH = SKILL_DIR / "scripts" / "validate_dataset.py"
STAGE_DIR = SKILL_DIR.parents[2] / "fast" / "stages" / "2-networking"
DATASETS_DIR = STAGE_DIR / "datasets"

spec = importlib.util.spec_from_file_location("validate_dataset", SCRIPT_PATH)
assert spec is not None and spec.loader is not None
validate_dataset = importlib.util.module_from_spec(spec)
sys.modules["validate_dataset"] = validate_dataset
spec.loader.exec_module(validate_dataset)

REFERENCE_DATASETS = (
    "hub-and-spokes-ncc",
    "hub-and-spokes-nva",
    "hub-and-spokes-nva-ncc",
    "hub-and-spokes-peerings",
    "hub-and-spokes-vpns",
)


@pytest.mark.parametrize("dataset_name", REFERENCE_DATASETS)
def test_reference_datasets_pass_schema_and_semantic_checks(
    dataset_name: str) -> None:
  ds_path = DATASETS_DIR / dataset_name
  issues, _ = validate_dataset.validate_dataset_files(ds_path, STAGE_DIR)
  errors = [i for i in issues if i.level == "error"]
  warnings = [i for i in issues if i.level == "warn"]
  assert not errors, f"Unexpected errors in {dataset_name}: {errors}"
  assert not warnings, f"Unexpected warnings in {dataset_name}: {warnings}"


def test_negative_controls_detect_errors(tmp_path: pathlib.Path) -> None:
  ds_copy = tmp_path / "broken-dataset"
  shutil.copytree(DATASETS_DIR / "hub-and-spokes-peerings", ds_copy)

  # 1. Unknown file location outside factory paths
  (ds_copy / "random.yaml").write_text("foo: bar\n", encoding="utf-8")

  # 2. Unresolved token + broken reciprocal peering in dev VPC
  dev_cfg_path = ds_copy / "vpcs" / "dev" / ".config.yaml"
  dev_cfg = yaml.safe_load(dev_cfg_path.read_text(encoding="utf-8"))
  dev_cfg["project_id"] = "$project_ids:nonexistent-proj"
  dev_cfg.pop("peering_config", None)
  dev_cfg_path.write_text(yaml.safe_dump(dev_cfg), encoding="utf-8")

  # 3. Overlapping subnet CIDR in prod VPC
  overlap_sub = ds_copy / "vpcs" / "prod" / "subnets" / "overlap.yaml"
  overlap_sub.write_text(
      yaml.safe_dump({
          "name": "prod-overlap",
          "region": "$locations:primary",
          "ip_cidr_range": "10.72.0.0/24",
      }),
      encoding="utf-8",
  )

  issues, _ = validate_dataset.validate_dataset_files(ds_copy, STAGE_DIR)
  messages = "\n".join(i.message for i in issues if i.level == "error")

  assert "does not match any FAST 2-networking factory directory" in messages
  assert "unresolved token '$project_ids:nonexistent-proj'" in messages
  assert "has no reciprocal peering back to '$networks:hub'" in messages
  assert "overlaps with" in messages


def test_negative_control_nva_advertise_without_covering_route(
    tmp_path: pathlib.Path) -> None:
  ds_copy = tmp_path / "broken-nva-ncc"
  shutil.copytree(DATASETS_DIR / "hub-and-spokes-nva-ncc", ds_copy)

  nva_path = ds_copy / "nvas" / "primary.yaml"
  nva_doc = yaml.safe_load(nva_path.read_text(encoding="utf-8"))
  # Remove kernel routes from nic1 while keeping `advertise`
  nva_doc["auto_instance_config"]["nics"][1]["routes"] = []
  nva_path.write_text(yaml.safe_dump(nva_doc), encoding="utf-8")

  issues, _ = validate_dataset.validate_dataset_files(ds_copy, STAGE_DIR)
  messages = "\n".join(i.message for i in issues if i.level == "error")
  assert "without a covering kernel route in 'routes'" in messages
