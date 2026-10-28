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
"""Dataset identity and FAST stage auto-detection (spec §1.1).

Directory fingerprint, first match wins:
  1. `perimeters/` or `restricted-services.yaml`  -> `1-vpcsc`
  2. `organization/` or `folders/`                -> `0-org-setup`
     (`starter-gcd` also has `vpcs/`: still org-setup, VPCs embedded)
  3. `vpcs/`                                      -> `2-networking`
Anything else is an error that lists what was found.
"""

from dataclasses import dataclass
import pathlib
from typing import List, Tuple, Union

STAGE_ORG_SETUP = "0-org-setup"
STAGE_VPCSC = "1-vpcsc"
STAGE_NETWORKING = "2-networking"
STAGES = (STAGE_ORG_SETUP, STAGE_VPCSC, STAGE_NETWORKING)

PathLike = Union[str, pathlib.Path]


class StageDetectionError(ValueError):
  """The directory does not look like any supported FAST stage dataset."""


def _entries(root: pathlib.Path) -> List[str]:
  return sorted(p.name + ("/" if p.is_dir() else "") for p in root.iterdir())


def detect_stage(dataset_dir: PathLike) -> str:
  """Returns the FAST stage of a dataset directory by fingerprint."""
  root = pathlib.Path(dataset_dir)
  if not root.is_dir():
    raise StageDetectionError(f"not a directory: {root}")
  if (root / "perimeters").is_dir() or (root / "restricted-services.yaml").is_file():
    return STAGE_VPCSC
  if (root / "organization").is_dir() or (root / "folders").is_dir():
    return STAGE_ORG_SETUP
  if (root / "vpcs").is_dir():
    return STAGE_NETWORKING
  found = ", ".join(_entries(root)) or "(empty)"
  raise StageDetectionError(
      f"cannot detect FAST stage for {root}: expected perimeters/ or "
      f"restricted-services.yaml (1-vpcsc), organization/ or folders/ "
      f"(0-org-setup), or vpcs/ (2-networking); found: {found}")


@dataclass(frozen=True)
class Dataset:
  """A dataset directory with its resolved stage and display name."""
  root: pathlib.Path
  stage: str
  name: str

  @classmethod
  def from_path(cls, path: PathLike, stage: str = "auto") -> "Dataset":
    root = pathlib.Path(path).resolve()
    if stage in (None, "", "auto"):
      stage = detect_stage(root)
    elif stage not in STAGES:
      raise ValueError(f"unknown stage {stage!r} (expected one of {STAGES})")
    return cls(root=root, stage=stage, name=root.name)


def discover_datasets(datasets_root: PathLike) -> List[pathlib.Path]:
  """Sorted dataset sub-directories (non-hidden, non-symlink) of a root."""
  root = pathlib.Path(datasets_root)
  if not root.is_dir():
    return []
  return sorted(p for p in root.iterdir()
                if p.is_dir() and not p.is_symlink() and not p.name.startswith("."))


def discover_fast_root(stages_dir: PathLike) -> List[Tuple[str, pathlib.Path]]:
  """`(stage_dir_name, dataset_dir)` for every `<stages_dir>/*/datasets/*`.

  The stage directory name (e.g. `2-project-factory`) is returned so callers
  render only supported stages instead of trusting the fingerprint, which
  would misread a project-factory dataset (`folders/`) as 0-org-setup.
  """
  root = pathlib.Path(stages_dir)
  out: List[Tuple[str, pathlib.Path]] = []
  if not root.is_dir():
    return out
  for stage_dir in sorted(p for p in root.iterdir() if p.is_dir()):
    out.extend((stage_dir.name, d)
               for d in discover_datasets(stage_dir / "datasets"))
  return out
