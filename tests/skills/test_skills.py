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
"""Repository-level contract tests for skills/ and agents-cli-extension.yaml."""

from __future__ import annotations

import pathlib

import yaml

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]
SKILLS_ROOT = REPO_ROOT / "skills"

BUCKET_PREFIXES = {
    "fabric": "fabric-",
    "fast": "fast-",
    "contributor": "cff-",
    "maintainer": "cff-",
}

CONSUMER_BUCKETS = {"fabric", "fast"}

EXPECTED_MANIFEST_SKILLS = {
    "fabric-builder",
    "fast-networking",
    "fast-prerequisites",
}


def _parse_frontmatter(skill_md: pathlib.Path) -> dict:
  raw = skill_md.read_text(encoding="utf-8")
  assert raw.startswith("---\n"), f"{skill_md} must start with YAML frontmatter"
  parts = raw.split("---", 2)
  assert len(parts) == 3, f"{skill_md} has malformed YAML frontmatter"
  data = yaml.safe_load(parts[1])
  assert isinstance(data, dict), f"{skill_md} frontmatter must be a mapping"
  return data


def test_agents_cli_extension_manifest_is_valid() -> None:
  manifest_path = REPO_ROOT / "agents-cli-extension.yaml"
  doc = yaml.safe_load(manifest_path.read_text(encoding="utf-8"))
  assert doc["schema"] == "agents-cli-extension/v1alpha1"
  assert doc["name"] == "cloud-foundation-fabric"
  skills = doc["skills"]
  assert set(skills.keys()) == EXPECTED_MANIFEST_SKILLS
  for skill_name, entry in skills.items():
    rel_path = pathlib.Path(entry["path"])
    assert rel_path.parts[0] == "skills", (
        f"Manifest path for {skill_name} must live under skills/: {rel_path}")
    assert rel_path.parts[1] in CONSUMER_BUCKETS, (
        f"Manifest skill {skill_name} must live in a consumer bucket "
        f"{sorted(CONSUMER_BUCKETS)}, got: {rel_path}")
    assert rel_path.name == skill_name, (
        f"Manifest leaf directory for {skill_name} must match key: {rel_path}")
    skill_md = REPO_ROOT / rel_path / "SKILL.md"
    assert skill_md.is_file(), f"Missing SKILL.md for {skill_name}"
    frontmatter = _parse_frontmatter(skill_md)
    assert frontmatter["name"] == skill_name


def test_skills_hierarchy_and_flat_install_naming() -> None:
  top_dirs = sorted(p.name
                    for p in SKILLS_ROOT.iterdir()
                    if p.is_dir() and not p.name.startswith("."))
  assert set(top_dirs) == set(BUCKET_PREFIXES.keys()), (
      f"Unexpected top-level directories under skills/: {top_dirs}")

  readme_text = (SKILLS_ROOT / "README.md").read_text(encoding="utf-8")
  seen_names: set[str] = set()

  for bucket, prefix in BUCKET_PREFIXES.items():
    bucket_dir = SKILLS_ROOT / bucket
    skill_dirs = sorted(p for p in bucket_dir.iterdir()
                        if p.is_dir() and not p.name.startswith("."))
    assert skill_dirs, f"Bucket skills/{bucket}/ must contain at least one skill"
    for skill_dir in skill_dirs:
      leaf = skill_dir.name
      assert leaf.startswith(prefix), (
          f"Skill {skill_dir.relative_to(REPO_ROOT)} must start with '{prefix}'"
      )
      skill_md = skill_dir / "SKILL.md"
      assert skill_md.is_file(), (
          f"Missing SKILL.md in {skill_dir.relative_to(REPO_ROOT)}")
      frontmatter = _parse_frontmatter(skill_md)
      assert frontmatter.get("name") == leaf, (
          f"{skill_md.relative_to(REPO_ROOT)} frontmatter name "
          f"{frontmatter.get('name')!r} != leaf directory {leaf!r}")
      desc = frontmatter.get("description")
      assert isinstance(desc, str) and desc.strip(), (
          f"{skill_md.relative_to(REPO_ROOT)} must declare a non-empty description"
      )
      assert leaf not in seen_names, f"Duplicate skill name: {leaf}"
      seen_names.add(leaf)
      expected_link = f"(./{bucket}/{leaf})"
      assert expected_link in readme_text, (
          f"skills/README.md is missing link {expected_link}")
