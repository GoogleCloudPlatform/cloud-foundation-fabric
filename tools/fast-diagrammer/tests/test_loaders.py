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
"""Dataset loader fidelity against the FAST stage Terraform.

Every test builds a crafted dataset in a temp directory, except the stage
detection negatives and the "real datasets load cleanly" sweep, which use
the FAST datasets of the checkout (skipped when it is not available).
"""

import os
import pathlib
import warnings

import pytest

from conftest import fabric_stages_dir
from fast_diagrammer import yamlio
from fast_diagrammer.datasets import networking, org_setup, vpcsc
from fast_diagrammer.datasets.base import (Dataset, DatasetError,
                                           DatasetWarning, StageDetectionError,
                                           detect_stage, discover_datasets,
                                           symlinked_datasets)


def _w(root: pathlib.Path, rel: str, text: str = "") -> pathlib.Path:
  p = root / rel
  p.parent.mkdir(parents=True, exist_ok=True)
  p.write_text(text, encoding="utf-8")
  return p


def _no_warnings(fn, *args, **kwargs):
  with warnings.catch_warnings():
    warnings.simplefilter("error", DatasetWarning)
    return fn(*args, **kwargs)


def _fabric_datasets(stage: str):
  stages = fabric_stages_dir()
  if stages is None:
    pytest.skip("Fabric checkout not found (set FD_FABRIC_ROOT)")
  root = stages / stage / "datasets"
  dirs = sorted(p for p in root.iterdir() if p.is_dir())
  assert dirs, f"no datasets under {root}"
  return dirs


# --------------------------------------------------------------------------
# yamlio
# --------------------------------------------------------------------------


def test_yaml_parse_error_carries_path(tmp_path):
  bad = _w(tmp_path, "organization/.config.yaml", "logging:\n\tsinks: {}\n")
  with pytest.raises(DatasetError) as exc:
    yamlio.load(bad)
  assert exc.value.path == str(bad)
  assert str(bad) in str(exc.value)
  assert "line 2" in str(exc.value)
  # Through a loader too, and DatasetError stays a ValueError.
  with pytest.raises(ValueError, match="organization/.config.yaml"):
    org_setup.load(tmp_path)


def test_yaml_multi_document_and_non_utf8_are_errors(tmp_path):
  with pytest.raises(DatasetError, match="multi.yaml"):
    yamlio.load(_w(tmp_path, "multi.yaml", "a: 1\n---\na: 2\n"))
  p = tmp_path / "latin1.yaml"
  p.write_bytes("a: \xe9\n".encode("latin-1"))
  with pytest.raises(DatasetError, match="UTF-8"):
    yamlio.load(p)


def test_yaml11_booleans_stay_strings_and_warn(tmp_path):
  p = _w(tmp_path, "al.yaml", "regions: [NO, IT]\nq: 'no'\nflag: on\nt: true\n")
  with pytest.warns(DatasetWarning) as rec:
    doc = yamlio.load(p)
  assert doc == {"regions": ["NO", "IT"], "q": "no", "flag": "on", "t": True}
  messages = sorted(str(r.message) for r in rec)
  assert len(messages) == 2  # the quoted 'no' is not reported
  assert messages[0].startswith(f"{p}:1: plain scalar 'NO'")
  assert messages[1].startswith(f"{p}:3: plain scalar 'on'")


def test_yaml_scalars_and_keys(tmp_path):
  doc = yamlio.loads("1: a\ntrue: b\n2024-01-01: c\nnum: 1_000\nm: 0o17\n"
                     "x: 0x1F\nd: 2024-01-01\n")
  assert doc == {
      "1": "a",
      "true": "b",
      "2024-01-01": "c",
      "num": "1_000",
      "m": 15,
      "x": 31,
      "d": "2024-01-01"
  }
  assert all(isinstance(k, str) for k in doc)
  with pytest.raises(DatasetError):
    yamlio.loads("a: !!python/object/apply:os.system ['true']\n")


def test_yaml_file_discovery(tmp_path):
  _w(tmp_path, "d/a.yaml", "x: 1\n")
  _w(tmp_path, "d/b.yml", "x: 2\n")
  _w(tmp_path, "d/.config.yaml")
  _w(tmp_path, "d/sub/c.yaml")
  _w(tmp_path, "d/.hidden/e.yaml")
  _w(tmp_path, "outside/f.yaml")
  os.symlink(tmp_path / "outside", tmp_path / "d" / "linked-dir")
  os.symlink(tmp_path / "outside" / "f.yaml", tmp_path / "d" / "g.yaml")
  os.symlink(tmp_path / "d" / "a.yaml", tmp_path / "d" / "sub" / "h.yaml")
  d = tmp_path / "d"
  assert [p.name for p in yamlio.yaml_files(d)] == ["a.yaml"]
  assert [yamlio.relative_key(p, d) for p in yamlio.rglob_yaml(d)
         ] == ["a", "sub/c", "sub/h"]
  assert yamlio.config_dirs(d) == []  # the directory itself is excluded
  _w(tmp_path, "d/sub/.config.yaml")
  assert [k for k, _ in yamlio.config_dirs(d)] == ["sub"]


def test_yaml_structure_helpers():
  assert yamlio.mapping(None, "f", "k") == {}
  assert yamlio.sequence(None, "f", "k") == []
  with pytest.raises(DatasetError, match="f: k: expected a mapping, got int"):
    yamlio.mapping(5, "f", "k")
  with pytest.raises(DatasetError, match="expected a list, got dict"):
    yamlio.sequence({}, "f", "k")


# --------------------------------------------------------------------------
# Stage detection, naming, symlinks
# --------------------------------------------------------------------------


@pytest.mark.parametrize("stage", ["2-project-factory", "2-security"])
def test_detect_stage_refuses_unsupported_fabric_stages(stage):
  for d in _fabric_datasets(stage):
    with pytest.raises(StageDetectionError):
      detect_stage(d)


@pytest.mark.parametrize("stage", ["0-org-setup", "1-vpcsc", "2-networking"])
def test_detect_stage_supported_fabric_stages(stage):
  for d in _fabric_datasets(stage):
    assert detect_stage(d) == stage, d.name


def test_detect_stage_networking_with_folders(tmp_path):
  _w(tmp_path, "folders/team/.config.yaml")
  _w(tmp_path, "projects/net-0.yaml")
  _w(tmp_path, "vpcs/hub/.config.yaml")
  with pytest.raises(StageDetectionError, match="found: folders/"):
    detect_stage(tmp_path)  # no networking marker yet
  _w(tmp_path, "defaults.yaml", "vpcs:\n  defaults: {}\n")
  assert detect_stage(tmp_path) == "2-networking"
  (tmp_path / "defaults.yaml").unlink()
  (tmp_path / "nvas").mkdir()
  assert detect_stage(tmp_path) == "2-networking"
  (tmp_path / "organization").mkdir()
  assert detect_stage(tmp_path) == "0-org-setup"


def test_detect_stage_probe_does_not_warn(tmp_path):
  _w(tmp_path, "vpcs/hub/.config.yaml")
  _w(tmp_path, "defaults.yaml", "vpcs: {defaults: {}}\nflag: no\n")
  assert _no_warnings(detect_stage, tmp_path) == "2-networking"
  with pytest.warns(DatasetWarning, match="defaults.yaml:2: plain scalar"):
    networking.load_dataset(tmp_path)  # the real load still reports it


def test_dataset_name_keeps_symlink_name(tmp_path):
  target = tmp_path / "datasets" / "hub-and-spokes-peerings"
  _w(target, "vpcs/hub/.config.yaml")
  _w(target, "defaults.yaml", "vpcs: {}\n")
  link = tmp_path / "datasets" / "classic"
  os.symlink(target, link, target_is_directory=True)
  os.symlink(tmp_path / "nowhere", tmp_path / "datasets" / "dangling")
  ds = Dataset.from_path(link)
  assert ds.name == "classic"
  assert ds.root == target.resolve()
  assert ds.stage == "2-networking"
  assert Dataset.from_path(str(link) + "/").name == "classic"
  assert discover_datasets(tmp_path / "datasets") == [target]
  assert symlinked_datasets(tmp_path / "datasets") == [
      (link, target.resolve()),
      (tmp_path / "datasets" / "dangling", (tmp_path / "nowhere").resolve()),
  ]


def test_loader_dataset_name_keeps_symlink_name(tmp_path):
  target = tmp_path / "real"
  _w(target, "organization/.config.yaml")
  _w(target, "perimeters/p.yaml")
  os.symlink(target, tmp_path / "alias", target_is_directory=True)
  assert org_setup.load(tmp_path / "alias").dataset_name == "alias"
  assert vpcsc.load(tmp_path / "alias").dataset_name == "alias"


# --------------------------------------------------------------------------
# 0-org-setup
# --------------------------------------------------------------------------

_ORG_DEFAULTS = ("global:\n  organization: {id: 111}\n"
                 "projects:\n  defaults: {prefix: t}\n")


def _org(tmp_path, defaults=_ORG_DEFAULTS):
  _w(tmp_path, "defaults.yaml", defaults)
  _w(tmp_path, "organization/.config.yaml")
  return tmp_path


def test_org_templates_dir_default_and_override(tmp_path):
  _org(tmp_path)
  _w(tmp_path, "folders/team/.config.yaml")
  _w(tmp_path, "projects/p.yaml", "project_template: base\n")
  _w(tmp_path, "templates/base.yaml",
     "parent: $folder_ids:team\nservices: [x.googleapis.com]\n")
  _w(tmp_path, "project_templates/base.yaml", "services: [wrong]\n")
  ds = _no_warnings(org_setup.load, tmp_path)
  p = ds.projects["p"]
  assert (p.parent_folder_key, p.services) == ("team", ["x.googleapis.com"])
  assert p.project_template == "base"
  assert ds.folders["team"].children_projects == ["p"]
  ds = org_setup.load(tmp_path,
                      paths={"project_templates": "project_templates"})
  assert ds.projects["p"].services == ["wrong"]
  assert ds.projects["p"].parent_folder_key is None
  with pytest.warns(DatasetWarning, match="project_template 'base' not found"):
    org_setup.load(tmp_path, paths={"project_templates": "missing"})
  with pytest.raises(ValueError, match="unknown 0-org-setup paths: bogus"):
    org_setup.load(tmp_path, paths={"bogus": "x"})


def test_org_recursive_projects_and_file_filters(tmp_path):
  _org(tmp_path)
  _w(tmp_path, "folders/a/.config.yaml")
  _w(tmp_path, "folders/a/b/.config.yaml")
  _w(tmp_path, "folders/a/b/deep/.config.yaml")
  _w(tmp_path, "folders/a/b/deep/fp.yaml", "name: folder-project\n")
  _w(tmp_path, "projects/core/sub/p1.yaml")
  _w(tmp_path, "projects/p2.yml")
  _w(tmp_path, "projects/sub.config.yaml")
  _w(tmp_path, "projects/.hidden.yaml")
  ds = _no_warnings(org_setup.load, tmp_path)
  assert sorted(ds.projects) == ["fp", "p1"]
  assert ds.projects["fp"].parent_folder_key == "a/b/deep"
  assert ds.projects["fp"].source_path == "folders/a/b/deep/fp.yaml"
  assert ds.projects["p1"].parent_folder_key is None
  assert ds.folders["a/b/deep"].level == 3
  assert ds.root_folder_keys == ["a"]


def test_org_duplicate_project_basename_warns(tmp_path):
  _org(tmp_path)
  _w(tmp_path, "folders/team/.config.yaml")
  _w(tmp_path, "folders/team/x.yaml", "name: from-folder\n")
  _w(tmp_path, "projects/a/x.yaml", "name: from-a\n")
  _w(tmp_path, "projects/b/x.yaml", "name: from-b\n")
  with pytest.warns(
      DatasetWarning,
      match=r"project key 'x' is defined by folders/team/x\.yaml, "
      r"projects/a/x\.yaml, projects/b/x\.yaml"):
    ds = org_setup.load(tmp_path)
  assert ds.projects["x"].name == "from-b"


def test_org_duplicate_loser_leaves_no_implicit_folder(tmp_path):
  _org(tmp_path)
  _w(tmp_path, "projects/a/x.yaml", "parent: $folder_ids:ghost\n")
  _w(tmp_path, "projects/b/x.yaml", "name: x\n")
  with pytest.warns(DatasetWarning, match="project key 'x'"):
    ds = org_setup.load(tmp_path)
  assert ds.folders == {} and ds.root_folder_keys == []
  assert ds.projects["x"].parent_folder_key is None


def test_org_dataset_paths_cannot_escape(tmp_path):
  root = tmp_path / "stage" / "datasets" / "ds"
  _org(root)
  _w(tmp_path, "stage/outside/x.yaml", "alerts: {a: 1}\n")
  _w(root, "observability/inside/x.yaml",
     "alerts: {a: 1, b: 2}\nlogging_metrics: {m: 1}\n")
  _w(root, "projects/up.yaml",
     "factories_config: {observability: ../../outside}\n")
  _w(root, "projects/abs.yaml",
     "factories_config: {observability: /usr/share}\n")
  _w(root, "projects/dot.yaml",
     "factories_config: {observability: ./outside}\n")  # stage-relative
  _w(root, "projects/dot-in.yaml",
     "factories_config: {observability: ./datasets/ds/observability/inside}\n")
  _w(root, "projects/rel.yaml",
     "factories_config: {observability: observability/inside}\n")
  _w(root, "projects/gone.yaml", "factories_config: {observability: nope}\n")
  _w(root, "folders/f/.config.yaml",
     "factories_config: {scc_sha_custom_modules: /etc}\n")
  with pytest.warns(DatasetWarning) as rec:
    ds = org_setup.load(root)
  outside = sorted(str(r.message) for r in rec)
  assert len(outside) == 4 and all("outside the dataset" in m for m in outside)
  for key in ("up", "abs", "dot", "gone"):
    p = ds.projects[key]
    assert p.has_observability_factory and p.observability_missing_path, key
    assert p.observability_alerts_count == 0, key
  for key in ("rel", "dot-in"):
    p = ds.projects[key]
    assert not p.observability_missing_path, key
    assert (p.observability_alerts_count, p.observability_metrics_count) == (2,
                                                                             1)
  assert ds.folders["f"].has_scc_sha and ds.folders["f"].scc_sha_count == 0


def test_org_external_and_implicit_parents(tmp_path):
  _org(tmp_path, _ORG_DEFAULTS + "context:\n  folder_ids: {ext: folders/555}\n")
  _w(tmp_path, "folders/team/.config.yaml")
  _w(tmp_path, "folders/team/sub/.config.yaml",
     "parent: $folder_ids:other/deep\n")
  _w(tmp_path, "folders/lit/.config.yaml", "parent: folders/1234567\n")
  _w(tmp_path, "folders/ctx/.config.yaml", "parent: $folder_ids:ext\n")
  _w(tmp_path, "folders/orphan/child/.config.yaml")
  _w(tmp_path, "projects/p-lit.yaml", "parent: folders/999\n")
  _w(tmp_path, "projects/p-org.yaml", "parent: organizations/111\n")
  _w(tmp_path, "projects/p-other-org.yaml", "parent: organizations/222\n")
  _w(tmp_path, "projects/p-default.yaml", "parent: $folder_ids:default\n")
  _w(tmp_path, "projects/p-trail.yaml", "parent: $folder_ids:team/\n")
  ds = _no_warnings(org_setup.load, tmp_path)
  f = ds.folders
  assert (f["lit"].parent_folder_key,
          f["lit"].parent_external) == (None, "folders/1234567")
  assert (f["ctx"].parent_folder_key,
          f["ctx"].parent_external) == (None, "folders/555")
  assert f["team/sub"].parent_folder_key == "other/deep"
  assert f["other"].implicit and f["other/deep"].implicit
  assert f["other/deep"].children_folders == ["team/sub"]
  assert f["orphan"].implicit and f["orphan"].children_folders == [
      "orphan/child"
  ]
  p = ds.projects
  assert (p["p-lit"].parent_folder_key,
          p["p-lit"].parent_external) == (None, "folders/999")
  assert (p["p-org"].parent, p["p-org"].parent_external) == (None, None)
  assert p["p-other-org"].parent_external == "organizations/222"
  assert p["p-default"].parent is None
  assert p["p-trail"].parent_folder_key == "team"
  assert ds.root_folder_keys == ["ctx", "lit", "orphan", "other", "team"]
  assert "p-lit" in ds.root_project_keys


def test_org_structural_errors_raise_dataset_error(tmp_path):
  _org(tmp_path)
  _w(tmp_path, "projects/p.yaml", "parent: [a, b]\n")
  with pytest.raises(DatasetError) as exc:
    org_setup.load(tmp_path)
  assert exc.value.path.endswith("projects/p.yaml")
  assert exc.value.key == "parent"
  _w(tmp_path, "projects/p.yaml", "- not a mapping\n")
  with pytest.raises(DatasetError, match="projects/p.yaml: expected a mapping"):
    org_setup.load(tmp_path)
  (tmp_path / "projects" / "p.yaml").unlink()
  _w(tmp_path, "organization/.config.yaml", "logging: 5\n")
  with pytest.raises(DatasetError, match=r"\.config\.yaml: logging: expected"):
    org_setup.load(tmp_path)
  _w(tmp_path, "organization/.config.yaml",
     "logging:\n  sinks:\n    s: {destination: x, type: kafka}\n")
  with pytest.raises(DatasetError, match="logging.sinks.s.type"):
    org_setup.load(tmp_path)


def test_org_sink_type(tmp_path):
  _org(tmp_path)
  _w(
      tmp_path, "organization/.config.yaml", "logging:\n  sinks:\n"
      "    a: {destination: $log_buckets:log-0/audit}\n"
      "    b: {destination: $project_ids:log-0, type: project}\n"
      "    c: {destination: projects/x/datasets/y, type: bigquery}\n")
  sinks = {s.name: s for s in org_setup.load(tmp_path).organization.sinks}
  assert (sinks["a"].sink_type, sinks["a"].destination_kind) == ("logging",
                                                                 "log_buckets")
  assert (sinks["a"].target_project, sinks["a"].target_resource) == ("log-0",
                                                                     "audit")
  assert (sinks["b"].sink_type, sinks["b"].destination_kind) == ("project",
                                                                 "project_ids")
  assert (sinks["c"].sink_type, sinks["c"].destination_kind) == ("bigquery", "")


def test_org_cicd_read_only_when_path_set(tmp_path):
  _org(tmp_path)
  _w(tmp_path, "projects/iac-0.yaml")
  _w(
      tmp_path, "cicd.yaml",
      "org-setup:\n  workload_identity: {pool: $workload_identity_pools:iac-0/"
      "default}\n")
  assert org_setup.load(tmp_path).cicd_workflows == []
  ds = org_setup.load(tmp_path, paths={"cicd_workflows": "cicd.yaml"})
  assert [w.name for w in ds.projects["iac-0"].cicd_workflows] == ["org-setup"]


def test_org_embedded_vpcs_recursive(tmp_path):
  _org(tmp_path)
  _w(tmp_path, "projects/net-0.yaml",
     "shared_vpc_host_config: {enabled: true}\n")
  _w(tmp_path, "vpcs/prod/a/.config.yaml", "project_id: $project_ids:net-0\n")
  _w(tmp_path, "vpcs/prod/a/subnets/ew1/s.yaml",
     "region: europe-west1\nip_cidr_range: 10.0.0.0/24\n")
  _w(tmp_path, "vpcs/nocfg/subnets/s.yaml")
  ds = _no_warnings(org_setup.load, tmp_path)
  assert list(ds.vpcs) == ["prod/a"]
  assert [s.name for s in ds.vpcs["prod/a"].subnets] == ["s"]
  assert ds.projects["net-0"].shared_vpc_host
  assert [v.key for v in ds.projects["net-0"].vpcs] == ["prod/a"]


# --------------------------------------------------------------------------
# 1-vpcsc
# --------------------------------------------------------------------------


def test_vpcsc_recursive_factories_and_defaults(tmp_path):
  _w(tmp_path, "restricted-services.yaml", "- storage.googleapis.com\n")
  _w(
      tmp_path, "perimeters/prod/landing.yaml", "status:\n"
      "  ingress_policies: [$ingress_policies:team/i]\n"
      "  egress_policies: [$egress_policies:team/e]\n"
      "  access_levels: [$access_levels:geo/it]\n"
      "  vpc_accessible_services: {enable_restriction: true}\n"
      "spec:\n  vpc_accessible_services:\n"
      "    allow_all_restricted_services: false\n")
  _w(tmp_path, "access-levels/geo/it.yaml", "conditions:\n  - regions: [IT]\n")
  _w(
      tmp_path, "ingress-policies/team/i.yaml",
      "from:\n  identity_type: ANY_IDENTITY\n  psc_endpoints: [ep-1]\n"
      "to:\n  operations: [{service_name: '*'}]\n")
  _w(tmp_path, "egress-policies/team/e.yaml",
     "from:\n  identity_type: ANY_SERVICE_ACCOUNT\nto: {}\n")
  _w(tmp_path, "perimeters/x.yml", "status: {}\n")
  ds = _no_warnings(vpcsc.load, tmp_path, strict=True)
  assert list(ds.perimeters) == ["prod/landing"]
  assert list(ds.access_levels) == ["geo/it"]
  p = ds.perimeters["prod/landing"]
  assert p.status.vpc_accessible_services.allow_all_restricted_services is True
  assert p.spec.vpc_accessible_services.allow_all_restricted_services is False
  i = ds.ingress_policies["team/i"]
  assert (i.from_identity_type, i.from_psc_endpoints) == ("ANY_IDENTITY",
                                                          ["ep-1"])
  assert ds.egress_policies[
      "team/e"].from_identity_type == "ANY_SERVICE_ACCOUNT"
  assert ds.unresolved_refs == []


def test_vpcsc_logging_identities_precedence_and_keys(tmp_path):
  _w(
      tmp_path, "defaults.yaml", "context:\n"
      "  identity_sets: {logging_identities: [user:x], other: [user:y]}\n"
      "  resource_sets: {discovered_projects: [projects/1]}\n"
      "  1: {2: three}\n")
  _w(tmp_path, "perimeters/p.yaml", "status:\n"
     "  resources: [$resource_sets:discovered_projects]\n")
  _w(
      tmp_path, "ingress-policies/i.yaml", "from:\n  identities:\n"
      "    - $identity_sets:logging_identities\n"
      "    - $identity_sets:other\n")
  ds = vpcsc.load(tmp_path)
  refs = ds.resolved_sets
  assert refs["$identity_sets:logging_identities"].provenance == (
      "stage-generated")
  assert refs["$identity_sets:other"].members == ["user:y"]
  assert refs["$resource_sets:discovered_projects"].provenance == (
      "defaults-context")
  assert ds.context["1"] == {"2": "three"}


def test_vpcsc_structural_errors(tmp_path):
  _w(tmp_path, "perimeters/p.yaml")
  _w(tmp_path, "ingress-policies/i.yaml", "from: [x]\n")
  with pytest.raises(DatasetError, match="ingress-policies/i.yaml: from"):
    vpcsc.load(tmp_path)


# --------------------------------------------------------------------------
# 2-networking
# --------------------------------------------------------------------------

_NET_DEFAULTS = "context:\n  locations: {primary: europe-west1}\nvpcs: {}\n"


def _net(tmp_path):
  _w(tmp_path, "defaults.yaml", _NET_DEFAULTS)
  return tmp_path


def test_networking_recursive_vpcs_subnets_projects(tmp_path):
  _net(tmp_path)
  _w(tmp_path, "projects/core/net-0.yaml",
     "name: prod-net-0\nshared_vpc_host_config: {enabled: true}\n")
  _w(tmp_path, "folders/team/app-0.yaml",
     "shared_vpc_service_config: {host_project: $project_ids:net-0}\n")
  _w(tmp_path, "folders/team/.config.yaml")
  _w(tmp_path, "projects/x.config.yaml")
  _w(tmp_path, "vpcs/landing/prod/.config.yaml",
     "project_id: $project_ids:net-0\nname: prod\n")
  _w(tmp_path, "vpcs/dev/.config.yaml", "project_id: $project_ids:net-0\n")
  _w(tmp_path, "vpcs/dev/subnets/ew1/a.yaml", "region: europe-west1\n")
  _w(tmp_path, "vpcs/dev/subnets/b.yaml", "region: europe-west1\n")
  _w(tmp_path, "vpcs/dev/subnets/c.yml", "region: europe-west1\n")
  _w(tmp_path, "vpcs/empty-dir/subnets/s.yaml", "region: europe-west1\n")
  _w(tmp_path, "nvas/core/fw.yaml", "project_id: $project_ids:net-0\n")
  os.symlink(tmp_path, tmp_path / "vpcs" / "loop", target_is_directory=True)
  ir = _no_warnings(networking.load_dataset, tmp_path)
  assert list(ir.vpcs) == ["dev", "landing/prod"]
  assert sorted(s.name for s in ir.vpcs["dev"].subnets) == ["a", "b"]
  assert list(ir.nvas) == ["core/fw"]
  assert list(ir.projects) == ["app-0", "net-0"]
  assert ir.mode == "fast"
  net0, app0 = ir.projects["net-0"], ir.projects["app-0"]
  assert (net0.shared_vpc_host, net0.source_path,
          net0.name) == (True, "projects/core/net-0.yaml", "prod-net-0")
  assert (app0.shared_vpc_host, app0.shared_vpc_service_of) == (False, "net-0")
  assert "vpcs/empty-dir/subnets/s.yaml" in ir.opaque
  assert not any(k.startswith("vpcs/loop") for k in ir.opaque)


def test_networking_disabled_and_relocated_factories(tmp_path):
  _net(tmp_path)
  _w(
      tmp_path, "vpcs/hub/.config.yaml", "project_id: p\nfactories_config:\n"
      "  vlan_attachments: none\n  vpns: shared/vpns\n"
      "  subnets: /etc\n")
  _w(tmp_path, "vpcs/hub/vlan-attachments/onprem-0.yaml",
     "ncc_spoke_config: {hub: $ncc_hubs:h}\n")
  _w(tmp_path, "vpcs/hub/subnets/s.yaml", "region: x\n")
  _w(tmp_path, "vpcs/hub/vpns/ignored.yaml")
  _w(tmp_path, "vpcs/hub/shared/vpns/to-onprem.yaml",
     "peer_gateways:\n  default: {external: {redundancy_type: SINGLE}}\n")
  with pytest.warns(DatasetWarning,
                    match="factories_config.subnets '/etc' resolves outside"):
    ir = networking.load_dataset(tmp_path)
  hub = ir.vpcs["hub"]
  assert hub.factories_config["vlan_attachments"] == "none"
  assert hub.disabled_factories == frozenset({"vlan_attachments", "subnets"})
  assert hub.vlan_attachments == [] and hub.subnets == []
  assert [g.name for g in hub.vpns] == ["to-onprem"]
  assert [(l.type, l.id) for l in ir.links] == [("vpn", "vpn:hub/to-onprem")]
  assert list(ir.sites) == ["onprem"]
  assert "vpcs/hub/vlan-attachments/onprem-0.yaml" in ir.opaque
  assert "vpcs/hub/vpns/ignored.yaml" in ir.opaque  # default dir not read


def test_networking_gcp_vpn_peer_is_never_a_site(tmp_path):
  _net(tmp_path)
  _w(tmp_path, "vpcs/hub/.config.yaml", "project_id: p\n")
  _w(tmp_path, "vpcs/hub/vpns/v.yaml",
     "peer_gateways:\n  default: {gcp: $vpn_gateways:spoke/x/y}\n")
  _w(tmp_path, "vpcs/hub/vpns/w.yaml",
     "peer_gateways:\n  default: {gcp: not-a-token}\n")
  with pytest.warns(DatasetWarning) as rec:
    ir = networking.load_dataset(tmp_path)
  assert ir.links == [] and ir.sites == {}
  msgs = " ".join(str(r.message) for r in rec)
  assert "peer VPC 'spoke/x' is not in the dataset" in msgs
  assert "'not-a-token' is not a $vpn_gateways" in msgs
  # A nested peer VPC key pairs normally.
  _w(tmp_path, "vpcs/spoke/x/.config.yaml", "project_id: p\n")
  _w(tmp_path, "vpcs/spoke/x/vpns/y.yaml",
     "peer_gateways:\n  default: {gcp: $vpn_gateways:hub/v}\n")
  (tmp_path / "vpcs/hub/vpns/w.yaml").unlink()
  ir = _no_warnings(networking.load_dataset, tmp_path)
  assert [(l.a, l.b) for l in ir.links] == [({
      "vpc": "hub",
      "name": "v"
  }, {
      "vpc": "spoke/x",
      "name": "y"
  })]


def test_networking_nva_subnet_tokens(tmp_path):
  _net(tmp_path)
  _w(tmp_path, "vpcs/a/b/.config.yaml", "project_id: p\n")
  _w(
      tmp_path, "nvas/n.yaml", "auto_instance_config:\n  nics:\n"
      "    - {network: $networks:a/b, subnet: $subnets:a/b/europe-west1/s}\n"
      "    - {network: $networks:a/b, subnet: literal}\n")
  with pytest.warns(DatasetWarning, match=r"nics\[1\]\.subnet 'literal'"):
    ir = networking.load_dataset(tmp_path)
  nics = ir.nvas["n"].nics
  assert (nics[0].vpc, nics[0].region, nics[0].subnet) == ("a/b",
                                                           "europe-west1", "s")
  assert (nics[1].region, nics[1].subnet) == (None, "literal")


def test_networking_duplicate_projects_warn(tmp_path):
  _net(tmp_path)
  _w(tmp_path, "projects/a/net-0.yaml", "name: a\n")
  _w(tmp_path, "projects/b/net-0.yaml", "name: b\n")
  with pytest.warns(DatasetWarning, match="project key 'net-0'"):
    ir = networking.load_dataset(tmp_path)
  assert ir.projects["net-0"].name == "b"


def test_networking_structural_errors(tmp_path):
  _net(tmp_path)
  cfg = _w(tmp_path, "vpcs/x/.config.yaml", "peering_config: [a]\n")
  with pytest.raises(DatasetError) as exc:
    networking.load_dataset(tmp_path)
  assert (exc.value.path, exc.value.key) == (str(cfg), "peering_config")
  _w(tmp_path, "vpcs/x/.config.yaml", "- a list\n")
  with pytest.raises(DatasetError, match="expected a mapping, got list"):
    networking.load_dataset(tmp_path)
  _w(tmp_path, "vpcs/x/.config.yaml", "project_id: p\n")
  _w(tmp_path, "vpcs/x/subnets/2024-01-01.yaml", "2024-01-01: x\nregion: r\n")
  ir = networking.load_dataset(tmp_path)
  assert ir.vpcs["x"].subnets[0].extra == {"2024-01-01": "x"}


# --------------------------------------------------------------------------
# Real datasets: every loader, no crash, no spurious warning
# --------------------------------------------------------------------------


@pytest.mark.parametrize("stage,loader", [
    ("0-org-setup", org_setup.load),
    ("1-vpcsc", vpcsc.load),
    ("2-networking", networking.load_dataset),
])
def test_real_datasets_load_without_warnings(stage, loader):
  for d in _fabric_datasets(stage):
    _no_warnings(loader, d)
