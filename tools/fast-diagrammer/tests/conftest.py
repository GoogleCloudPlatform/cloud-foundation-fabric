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
"""Shared pytest wiring: import path, golden paths, FAST dataset discovery.

Dataset resolution order for `dataset_dir(stage, name)`:
  1. `tests/fixtures/datasets/<stage>/<name>` (vendored, e.g. nva-ncc);
  2. `$FD_FABRIC_ROOT/fast/stages/<stage>/datasets/<name>`;
  3. repo-relative `../../fast/stages/<stage>/datasets/<name>` (the tool's
     home inside cloud-foundation-fabric is `tools/fast-diagrammer/`);
  4. `~/git/cloud-foundation-fabric/fast/stages/...` (vault dev default).
Tests needing an unresolvable dataset are skipped, never silently passed.
"""

import json
import os
import pathlib
import sys
from typing import List, Optional

import pytest

TESTS_DIR = pathlib.Path(__file__).resolve().parent
APP_ROOT = TESTS_DIR.parent
for _p in (str(APP_ROOT), str(TESTS_DIR)):
  if _p not in sys.path:
    sys.path.insert(0, _p)

GOLDEN_DIR = TESTS_DIR / "golden" / "2-networking"
GOLDEN_INPUTS = GOLDEN_DIR / "inputs"
GOLDEN_EXPECTED = GOLDEN_DIR / "expected"
FIXTURES_DIR = TESTS_DIR / "fixtures"
ICONS_JSON = APP_ROOT / "fast_diagrammer" / "icons" / "icons.json"

STAGES = ("0-org-setup", "1-vpcsc", "2-networking")

GOLDEN_DATASETS = (
    "classic",
    "hub-and-spokes-ncc",
    "hub-and-spokes-nva",
    "hub-and-spokes-nva-ncc",
    "hub-and-spokes-peerings",
    "hub-and-spokes-vpns",
)
GOLDEN_VIEWS = ("topology", "dns")
GOLDEN_KEYS = tuple(f"{ds}-{v}" for ds in GOLDEN_DATASETS for v in GOLDEN_VIEWS)


def split_key(key: str):
  """'hub-and-spokes-ncc-dns' -> ('hub-and-spokes-ncc', 'dns')."""
  ds, view = key.rsplit("-", 1)
  return ds, view


def golden_scene(key: str):
  """Frozen pre-layout SceneGraph snapshot `inputs/<key>.scene.json`."""
  from fast_diagrammer.scene.serialize import load_scene  # pylint: disable=import-outside-toplevel
  return load_scene(GOLDEN_INPUTS / f"{key}.scene.json")


def fabric_roots() -> List[pathlib.Path]:
  """Candidate cloud-foundation-fabric checkouts, in priority order."""
  roots = []
  env = os.environ.get("FD_FABRIC_ROOT")
  if env:
    roots.append(pathlib.Path(env).expanduser())
  roots.append(APP_ROOT.parent.parent)  # tools/fast-diagrammer -> repo root
  roots.append(pathlib.Path.home() / "git" / "cloud-foundation-fabric")
  return roots


def fabric_root() -> Optional[pathlib.Path]:
  for r in fabric_roots():
    if (r / "fast" / "stages").is_dir():
      return r
  return None


def stage_datasets_root(stage: str) -> Optional[pathlib.Path]:
  """`<fabric>/fast/stages/<stage>/datasets`, or None when not found."""
  r = fabric_root()
  if r is None:
    return None
  d = r / "fast" / "stages" / stage / "datasets"
  return d if d.is_dir() else None


def dataset_dir(stage: str, name: str) -> Optional[pathlib.Path]:
  vendored = FIXTURES_DIR / "datasets" / stage / name
  if vendored.is_dir():
    return vendored
  root = stage_datasets_root(stage)
  if root is not None and (root / name).is_dir():
    return root / name
  return None


def require_dataset(stage: str, name: str) -> pathlib.Path:
  """Returns the dataset dir or skips the calling test with a reason."""
  d = dataset_dir(stage, name)
  if d is None:
    pytest.skip(f"dataset {stage}/{name} not found (set FD_FABRIC_ROOT)")
  return d


def list_datasets(stage: str) -> List[str]:
  """Dataset names for a stage (Fabric checkout + vendored fixtures), sorted."""
  names = set()
  root = stage_datasets_root(stage)
  if root is not None:
    names.update(p.name for p in root.iterdir()
                 if p.is_dir() and not p.is_symlink())
  vend = FIXTURES_DIR / "datasets" / stage
  if vend.is_dir():
    names.update(p.name for p in vend.iterdir() if p.is_dir())
  return sorted(names)


@pytest.fixture(scope="session")
def app_root() -> pathlib.Path:
  return APP_ROOT


@pytest.fixture(scope="session")
def golden_dir() -> pathlib.Path:
  return GOLDEN_DIR


@pytest.fixture(scope="session")
def icons_map():
  return json.loads(ICONS_JSON.read_text(encoding="utf-8"))


@pytest.fixture
def networking_dataset():
  """Callable fixture: `networking_dataset("hub-and-spokes-ncc")` -> Path."""
  return lambda name: require_dataset("2-networking", name)


@pytest.fixture
def stage_dataset():
  """Callable fixture: `stage_dataset("0-org-setup", "classic")` -> Path."""
  return require_dataset
