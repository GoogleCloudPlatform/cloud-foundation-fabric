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
REPO_ROOT = SKILL_DIR.parents[2]
SCRIPT_PATH = SKILL_DIR / "scripts" / "validate_dataset.py"
STAGE_DIR = REPO_ROOT / "fast" / "stages" / "2-networking"
DATASETS_DIR = STAGE_DIR / "datasets"
STAGE_TEST_DIR = REPO_ROOT / "tests" / "fast" / "stages" / "s2_networking"

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

SELF_CONTAINED_STAGE_TEST_FIXTURES = (
    "data-testaddresses",
    "data-testdns-delegation",
    "data-testnva-ra",
    "data-teststatic-ips-nat",
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


@pytest.mark.parametrize("fixture_name", SELF_CONTAINED_STAGE_TEST_FIXTURES)
def test_stage_test_fixtures_pass_when_defaults_normalized(
    fixture_name: str, tmp_path: pathlib.Path) -> None:
  ds_copy = tmp_path / fixture_name
  shutil.copytree(STAGE_TEST_DIR / fixture_name, ds_copy)
  # Stage test fixtures predate defaults.schema.json's `vpcs.defaults` wrapper
  def_path = ds_copy / "defaults.yaml"
  def_doc = yaml.safe_load(def_path.read_text(encoding="utf-8"))
  if isinstance(def_doc.get("vpcs"),
                dict) and "defaults" not in def_doc["vpcs"]:
    vpc_def = dict(def_doc["vpcs"])
    if "delete_default_route_on_create" in vpc_def:
      vpc_def["delete_default_routes_on_create"] = vpc_def.pop(
          "delete_default_route_on_create")
    def_doc["vpcs"] = {"defaults": vpc_def}
    def_path.write_text(yaml.safe_dump(def_doc), encoding="utf-8")

  issues, _ = validate_dataset.validate_dataset_files(ds_copy, STAGE_DIR)
  errors = [i for i in issues if i.level == "error"]
  assert not errors, f"Unexpected errors in {fixture_name}: {errors}"


def test_negative_controls_detect_errors(tmp_path: pathlib.Path) -> None:
  ds_copy = tmp_path / "broken-dataset"
  shutil.copytree(DATASETS_DIR / "hub-and-spokes-peerings", ds_copy)

  # 1. Unknown file location outside factory paths + ghost vpcs/<vpc>/firewall-policy.yaml (H1)
  (ds_copy / "random.yaml").write_text("foo: bar\n", encoding="utf-8")
  (ds_copy / "vpcs" / "hub" / "firewall-policy.yaml").write_text(
      "name: ghost\n", encoding="utf-8")

  # 2. Unresolved token + broken reciprocal peering + network_attachments in dev VPC (H3)
  dev_cfg_path = ds_copy / "vpcs" / "dev" / ".config.yaml"
  dev_cfg = yaml.safe_load(dev_cfg_path.read_text(encoding="utf-8"))
  dev_cfg["project_id"] = "$project_ids:nonexistent-proj"
  dev_cfg.pop("peering_config", None)
  dev_cfg["network_attachments"] = {
      "bad-na": {
          "subnet": "nonexistent-subnet",
          "producer_accept_lists": ["$project_ids:net-core-0"],
      }
  }
  dev_cfg_path.write_text(yaml.safe_dump(dev_cfg), encoding="utf-8")

  # 3. Overlapping subnet CIDR in prod VPC + host bits set + duplicate subnet filename across subdirs (H8)
  overlap_sub = ds_copy / "vpcs" / "prod" / "subnets" / "overlap.yaml"
  overlap_sub.write_text(
      yaml.safe_dump({
          "name": "prod-overlap",
          "region": "$locations:primary",
          "ip_cidr_range": "10.72.0.0/24",
      }),
      encoding="utf-8",
  )
  hostbits_sub = ds_copy / "vpcs" / "prod" / "subnets" / "hostbits.yaml"
  hostbits_sub.write_text(
      yaml.safe_dump({
          "name": "prod-hostbits",
          "region": "$locations:primary",
          "ip_cidr_range": "10.72.99.5/24",
      }),
      encoding="utf-8",
  )
  dup_dir = ds_copy / "vpcs" / "prod" / "subnets" / "secondary"
  dup_dir.mkdir(parents=True, exist_ok=True)
  (dup_dir / "overlap.yaml").write_text(
      yaml.safe_dump({
          "name": "prod-secondary-sub",
          "region": "$locations:secondary",
          "ip_cidr_range": "10.72.100.0/24",
      }),
      encoding="utf-8",
  )

  issues, _ = validate_dataset.validate_dataset_files(ds_copy, STAGE_DIR)
  messages = "\n".join(i.message for i in issues if i.level == "error")

  assert "does not match any FAST 2-networking factory directory" in messages
  assert "unresolved token '$project_ids:nonexistent-proj'" in messages
  assert "has no reciprocal peering back to '$networks:hub'" in messages
  assert "overlaps with" in messages
  assert "has host bits set" in messages
  assert "duplicate subnet filename stem 'overlap.yaml'" in messages
  assert "must be '<resolved-region>/<subnet-name>' matching a subnet in VPC 'dev'" in messages
  assert "does not interpolate '$project_ids:net-core-0'" in messages


def test_negative_control_cross_vpc_cidr_overlap(
    tmp_path: pathlib.Path) -> None:
  ds_copy = tmp_path / "cross-vpc-overlap"
  shutil.copytree(DATASETS_DIR / "hub-and-spokes-peerings", ds_copy)

  # Add a subnet in prod that overlaps with dev's 10.73.0.0/24 across peered VPCs (M6)
  (ds_copy / "vpcs" / "prod" / "subnets" / "collide-dev.yaml").write_text(
      yaml.safe_dump({
          "name": "prod-collide-dev",
          "region": "$locations:primary",
          "ip_cidr_range": "10.73.0.0/25",
      }),
      encoding="utf-8",
  )

  issues, _ = validate_dataset.validate_dataset_files(ds_copy, STAGE_DIR)
  messages = "\n".join(i.message for i in issues if i.level == "error")
  assert "cross-VPC CIDR overlap over peering-via:hub: VPC 'dev'" in messages


def test_addresses_and_vpn_gateway_tokens(tmp_path: pathlib.Path) -> None:
  ds_copy = tmp_path / "tokens-check"
  shutil.copytree(DATASETS_DIR / "hub-and-spokes-vpns", ds_copy)

  # Rename VPN name inside YAML so it differs from filename stem (H5)
  vpn_path = ds_copy / "vpcs" / "hub" / "vpns" / "onprem.yaml"
  vpn_doc = yaml.safe_load(vpn_path.read_text(encoding="utf-8"))
  vpn_doc["name"] = "custom-vpn-gw-name"
  vpn_path.write_text(yaml.safe_dump(vpn_doc), encoding="utf-8")

  # Add internal address in hub (H4)
  (ds_copy / "vpcs" / "hub" / "addresses.yaml").write_text(
      yaml.safe_dump({
          "internal": {
              "my-ilb-vip": {
                  "region": "$locations:primary",
                  "subnetwork": "$subnet_self_links:hub/hub-default",
                  "address": "10.64.0.99",
              }
          }
      }),
      encoding="utf-8",
  )

  # Reference both valid ($addresses:hub/my-ilb-vip) and invalid ($addresses:hub/internal/my-ilb-vip)
  # plus invalid $vpn_gateways:hub/onprem (stem instead of vpn.name) in hub/.config.yaml routes
  hub_cfg_path = ds_copy / "vpcs" / "hub" / ".config.yaml"
  hub_cfg = yaml.safe_load(hub_cfg_path.read_text(encoding="utf-8"))
  hub_cfg["routes"] = {
      "valid-addr": {
          "dest_range": "192.168.100.0/24",
          "next_hop_type": "ilb",
          "next_hop": "$addresses:hub/my-ilb-vip",
      },
      "invalid-addr": {
          "dest_range": "192.168.101.0/24",
          "next_hop_type": "ilb",
          "next_hop": "$addresses:hub/internal/my-ilb-vip",
      },
      "invalid-vpn-stem": {
          "dest_range": "192.168.102.0/24",
          "next_hop_type": "gateway",
          "next_hop": "$vpn_gateways:hub/onprem",
      },
      "valid-vpn-name": {
          "dest_range": "192.168.103.0/24",
          "next_hop_type": "gateway",
          "next_hop": "$vpn_gateways:hub/custom-vpn-gw-name",
      },
  }
  hub_cfg_path.write_text(yaml.safe_dump(hub_cfg), encoding="utf-8")

  issues, _ = validate_dataset.validate_dataset_files(ds_copy, STAGE_DIR)
  messages = "\n".join(i.message for i in issues if i.level == "error")
  assert "unresolved token '$addresses:hub/internal/my-ilb-vip'" in messages
  assert "unresolved token '$vpn_gateways:hub/onprem'" in messages
  assert "unresolved token '$addresses:hub/my-ilb-vip'" not in messages
  assert "unresolved token '$vpn_gateways:hub/custom-vpn-gw-name'" not in messages


def test_negative_control_nva_advertise_and_same_vpc_ilb_ncc_collision(
    tmp_path: pathlib.Path) -> None:
  ds_copy = tmp_path / "broken-nva-ncc"
  shutil.copytree(DATASETS_DIR / "hub-and-spokes-nva-ncc", ds_copy)

  nva_path = ds_copy / "nvas" / "primary.yaml"
  nva_doc = yaml.safe_load(nva_path.read_text(encoding="utf-8"))
  # 1. Remove kernel routes from nic1 while keeping `advertise`
  nva_doc["auto_instance_config"]["nics"][1]["routes"] = []
  # 2. Add track_per_session: true on ilb_config.connection_tracking (M4)
  # 3. Point ILB forwarding rule at the same VPC ('routing') as ncc_ra_config ('routing') (H7)
  nva_doc["ilb_config"] = {
      "connection_tracking": {
          "idle_timeout_sec": 600,
          "track_per_session": True,
      },
      "forwarding_rules": [{
          "network": "$networks:routing",
          "subnet": "$subnets:routing/europe-west1/routing-primary",
      }],
  }
  nva_path.write_text(yaml.safe_dump(nva_doc), encoding="utf-8")

  issues, _ = validate_dataset.validate_dataset_files(ds_copy, STAGE_DIR)
  messages = "\n".join(i.message for i in issues if i.level == "error")
  assert "without a covering kernel route in 'routes'" in messages
  assert "track_per_session: true" in messages
  assert "VPC 'routing' cannot have both an ILB forwarding rule and an NCC Router Appliance spoke for the same NVA 'primary'" in messages


def test_single_shared_vpc_dataset_passes(tmp_path: pathlib.Path) -> None:
  ds_single = tmp_path / "single-vpc"
  shutil.copytree(DATASETS_DIR / "hub-and-spokes-peerings", ds_single)

  # Remove dev/prod spoke projects, VPCs, and DNS zones to form a Single Shared VPC dataset
  for proj in ("net-dev-0.yaml", "net-prod-0.yaml"):
    (ds_single / "projects" / proj).unlink()
  for vpc in ("dev", "prod"):
    shutil.rmtree(ds_single / "vpcs" / vpc)
  for dns_dir in ("net-dev-0", "net-prod-0"):
    shutil.rmtree(ds_single / "dns" / "zones" / dns_dir)
  (ds_single / "dns" / "zones" / "net-core-0" / "peer-root.yaml").unlink()

  # Strip peering_config from the single VPC (hub) and narrow RPZ networks to [hub]
  hub_cfg_path = ds_single / "vpcs" / "hub" / ".config.yaml"
  hub_cfg = yaml.safe_load(hub_cfg_path.read_text(encoding="utf-8"))
  hub_cfg.pop("peering_config", None)
  hub_cfg_path.write_text(yaml.safe_dump(hub_cfg), encoding="utf-8")

  rpz_path = ds_single / "dns" / "response-policies" / "net-core-0.yaml"
  rpz_cfg = yaml.safe_load(rpz_path.read_text(encoding="utf-8"))
  rpz_cfg["networks"] = ["$networks:hub"]
  rpz_path.write_text(yaml.safe_dump(rpz_cfg), encoding="utf-8")

  issues, _ = validate_dataset.validate_dataset_files(ds_single, STAGE_DIR)
  errors = [i for i in issues if i.level == "error"]
  warnings = [i for i in issues if i.level == "warn"]
  assert not errors, f"Unexpected errors in single-vpc: {errors}"
  assert not warnings, f"Unexpected warnings in single-vpc: {warnings}"
