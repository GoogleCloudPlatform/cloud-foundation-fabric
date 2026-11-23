# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Unit tests for skills/fabric/fabric-builder/scripts/fabric.py."""

import json
import pathlib
import sys
from unittest import mock

SCRIPTS_DIR = pathlib.Path(__file__).resolve().parent.parent / "scripts"
REPO_ROOT = pathlib.Path(__file__).resolve().parents[4]
if str(SCRIPTS_DIR) not in sys.path:
  sys.path.insert(0, str(SCRIPTS_DIR))

import fabric

SAMPLE_SCHEMA = {
    "$schema": "http://json-schema.org/draft-07/schema#",
    "type": "object",
    "additionalProperties": False,
    "required": ["name"],
    "properties": {
        "name": {
            "type": "string"
        },
        "region": {
            "type": "string"
        },
    },
}


def _write_schema(tmp_path, name="sample.schema.json", schema=None):
  schemas = tmp_path / "schemas"
  schemas.mkdir(exist_ok=True)
  path = schemas / name
  path.write_text(json.dumps(schema or SAMPLE_SCHEMA), encoding="utf-8")
  return path


def test_parse_repo_factories_md_covers_modules_stages_addons():
  md_text = (REPO_ROOT / "FACTORIES.md").read_text(encoding="utf-8")
  sections = fabric.parse_factories_md(md_text)
  mod_names = {r["Module"] for r in sections["modules"]}
  stage_names = {r["Stage"] for r in sections["stages"]}
  addon_names = {r["Component"] for r in sections["addons"]}

  assert {"project-factory", "net-vpc-factory", "vpc-sc",
          "net-vpc"} <= mod_names
  assert {"0-org-setup", "1-vpcsc", "2-networking",
          "2-project-factory"} <= stage_names
  assert "addons/2-networking-swp" in addon_names


def test_factories_cli_list_and_filter(capsys):
  md_text = (REPO_ROOT / "FACTORIES.md").read_text(encoding="utf-8")
  with mock.patch.object(fabric, "fetch_url", return_value=md_text):
    rc = fabric.main(["--no-cache", "factories"])
    assert rc == 0
    out = capsys.readouterr().out
    assert " - project-factory (pure)" in out
    assert " - net-vpc (in-module)" in out
    assert " - 2-networking" in out

    rc = fabric.main(["--no-cache", "factories", "project-factory"])
    assert rc == 0
    detail = capsys.readouterr().out
    assert "[project-factory] key: `paths.projects`" in detail
    assert "`**/*.yaml`" in detail
    assert "`**/**/.config.yaml`" in detail
    assert "modules/project-factory/schemas/project.schema.json" in detail
    assert "[net-vpc]" not in detail


def test_factories_cli_unknown_target_fails(capsys):
  md_text = (REPO_ROOT / "FACTORIES.md").read_text(encoding="utf-8")
  with mock.patch.object(fabric, "fetch_url", return_value=md_text):
    rc = fabric.main(["--no-cache", "factories", "does-not-exist"])
  assert rc == 1
  assert "No factory found" in capsys.readouterr().err


def test_validate_valid_modeline(tmp_path):
  _write_schema(tmp_path)
  data_dir = tmp_path / "data"
  data_dir.mkdir()
  yml = data_dir / "item.yaml"
  yml.write_text(
      "# yaml-language-server: $schema=../schemas/sample.schema.json\n"
      "name: demo-0\n"
      "region: $locations:ew1\n",
      encoding="utf-8",
  )

  checked, skipped, errors = fabric.validate_yaml_files([str(data_dir)],
                                                        require_modeline=True)
  assert checked == 1
  assert skipped == []
  assert errors == []


def test_validate_schema_violation_reports_field(tmp_path):
  _write_schema(tmp_path)
  yml = tmp_path / "bad.yaml"
  yml.write_text(
      "# yaml-language-server: $schema=schemas/sample.schema.json\n"
      "name: 123\n"
      "unexpected_key: true\n",
      encoding="utf-8",
  )

  checked, skipped, errors = fabric.validate_yaml_files([str(yml)])
  assert checked == 1
  assert skipped == []
  assert len(errors) == 2
  assert any("unexpected_key" in e for e in errors)
  assert any("(doc 0, name)" in e for e in errors)


def test_validate_missing_modeline_optional_vs_required(tmp_path):
  yml = tmp_path / "nomodeline.yaml"
  yml.write_text("name: demo-0\n", encoding="utf-8")

  checked, skipped, errors = fabric.validate_yaml_files([str(yml)],
                                                        require_modeline=False)
  assert checked == 0
  assert skipped == [yml]
  assert errors == []

  checked, skipped, errors = fabric.validate_yaml_files([str(yml)],
                                                        require_modeline=True)
  assert checked == 0
  assert len(errors) == 1
  assert "missing # yaml-language-server" in errors[0]


def test_validate_explicit_schema_override(tmp_path):
  schema_path = _write_schema(tmp_path)
  yml = tmp_path / "plain.yaml"
  yml.write_text("name: ok\n", encoding="utf-8")

  rc = fabric.main(["validate", str(yml), "--schema", str(schema_path)])
  assert rc == 0


def test_validate_remote_schema_url_is_cached(tmp_path):
  data_dir = tmp_path / "data"
  data_dir.mkdir()
  url = "https://example.test/sample.schema.json"
  for idx in range(2):
    (data_dir / f"item-{idx}.yaml").write_text(
        f"# yaml-language-server: $schema={url}\nname: item-{idx}\n",
        encoding="utf-8",
    )

  with mock.patch.object(fabric, "fetch",
                         return_value=json.dumps(SAMPLE_SCHEMA)) as fetch_mock:
    checked, skipped, errors = fabric.validate_yaml_files([str(data_dir)],
                                                          require_modeline=True)

  assert checked == 2
  assert skipped == []
  assert errors == []
  assert fetch_mock.call_count == 1


def test_validate_missing_path_fails_cleanly(tmp_path):
  rc = fabric.main(["validate", str(tmp_path / "does-not-exist.yaml")])
  assert rc == 1


def test_fetch_schemas_writes_stage_files(tmp_path):
  listing = [
      {
          "name": "project.schema.json",
          "type": "file"
      },
      {
          "name": "project.schema.md",
          "type": "file"
      },
      {
          "name": "folder.schema.json",
          "type": "file"
      },
  ]
  out_dir = tmp_path / "out"

  def fake_api_get(path, ref=None):
    assert path == "contents/fast/stages/2-project-factory/schemas"
    assert ref == "v54.0.0"
    return listing

  with mock.patch.object(fabric, "api_get", side_effect=fake_api_get), \
       mock.patch.object(fabric, "fetch_url",
                         return_value=json.dumps(SAMPLE_SCHEMA)):
    rc = fabric.main([
        "--no-cache",
        "fetch",
        "schemas",
        "2-project-factory",
        "--stage",
        "--ref",
        "v54.0.0",
        "--out",
        str(out_dir),
    ])

  assert rc == 0
  assert sorted(p.name for p in out_dir.iterdir()) == [
      "folder.schema.json",
      "project.schema.json",
  ]
