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

Reference datasets are the ones shipped with Cloud Foundation Fabric under
`fast/stages/<stage>/datasets/<name>`. The stages directory is resolved once,
first match wins:
  1. repo-relative `../../fast/stages` (the tool lives in
     `tools/fast-diagrammer/` of a cloud-foundation-fabric checkout);
  2. `$FD_FABRIC_ROOT/fast/stages`, for a copy of the tool outside the repo.
Tests needing an unresolvable dataset are skipped with the searched paths as
the reason, never failed and never silently passed. `tools/update_goldens.py`
uses the same resolver.
"""

import html
import json
import os
import pathlib
import re
import sys
import zlib
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
REPO_STAGES_DIR = APP_ROOT.parent.parent / "fast" / "stages"
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


_CONTENT_RE = re.compile(rb'content="([^"]*)"')
_DIAGRAM_RE = re.compile(r"(<diagram [^>]*>)([A-Za-z0-9+/=]+)(</diagram>)")


def canonical_svg(data: bytes) -> bytes:
  """`.drawio.svg` bytes with the compressed `content=` diagram inflated.

  Raw deflate output can differ between zlib builds (zlib, zlib-ng) for the
  same input, so byte-level gates compare the inflated model instead of the
  compressed payload. A payload that does not decode is left untouched (and
  then simply compares unequal).
  """
  from fast_diagrammer.scene.emit_drawio import decompress_diagram  # pylint: disable=import-outside-toplevel
  m = _CONTENT_RE.search(data)
  if m is None:
    return data
  content = html.unescape(m.group(1).decode("utf-8", errors="replace"))

  def inflate(dm):
    try:
      return dm.group(1) + decompress_diagram(dm.group(2)) + dm.group(3)
    except (ValueError, zlib.error, UnicodeDecodeError):
      return dm.group(0)

  content = _DIAGRAM_RE.sub(inflate, content)
  return data[:m.start(1)] + content.encode("utf-8") + data[m.end(1):]


def fabric_stages_roots() -> List[pathlib.Path]:
  """Candidate FAST `stages/` directories, in priority order."""
  roots = [REPO_STAGES_DIR]
  env = os.environ.get("FD_FABRIC_ROOT")
  if env:
    roots.append(pathlib.Path(env).expanduser() / "fast" / "stages")
  return roots


def fabric_stages_dir() -> Optional[pathlib.Path]:
  """The first existing FAST `stages/` directory, or None."""
  return next((r for r in fabric_stages_roots() if r.is_dir()), None)


def stage_datasets_root(stage: str) -> Optional[pathlib.Path]:
  """`<stages>/<stage>/datasets`, or None when not found."""
  r = fabric_stages_dir()
  if r is None:
    return None
  d = r / stage / "datasets"
  return d if d.is_dir() else None


def dataset_dir(stage: str, name: str) -> Optional[pathlib.Path]:
  """`<stages>/<stage>/datasets/<name>` (symlinks kept as named), or None."""
  root = stage_datasets_root(stage)
  if root is not None and (root / name).is_dir():
    return root / name
  return None


def missing_dataset_reason(stage: str, name: str) -> str:
  searched = ", ".join(str(r) for r in fabric_stages_roots())
  return (f"FAST dataset {stage}/{name} not found (searched: {searched}); "
          "run inside a cloud-foundation-fabric checkout or set FD_FABRIC_ROOT")


def require_dataset(stage: str, name: str) -> pathlib.Path:
  """Returns the dataset dir or skips the calling test with a reason."""
  d = dataset_dir(stage, name)
  if d is None:
    pytest.skip(missing_dataset_reason(stage, name))
  return d


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
