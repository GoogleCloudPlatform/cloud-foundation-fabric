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
"""Dataset identity, FAST stage auto-detection and dataset path helpers.

Directory fingerprint, first match wins:
  1. `perimeters/` or `restricted-services.yaml`        -> `1-vpcsc`
  2. `organization/`                                    -> `0-org-setup`
     (`starter-gcd` also has `vpcs/`: still org-setup, VPCs embedded)
  3. `vpcs/` plus a networking marker: `ncc-hubs/`,
     `nvas/`, or a top-level `vpcs:` key in `defaults.yaml` -> `2-networking`
Anything else is an error that lists what was found. `folders/` alone is not
a fingerprint: 2-networking and 2-project-factory datasets have one too, and
2-project-factory / 2-security datasets must not be mistaken for a supported
stage.
"""

from dataclasses import dataclass
import pathlib
from typing import List, Optional, Tuple, Union
import warnings

from .. import yamlio
from ..yamlio import DatasetError, DatasetWarning  # re-exported

__all__ = [
    "STAGES", "STAGE_NETWORKING", "STAGE_ORG_SETUP", "STAGE_VPCSC", "Dataset",
    "DatasetError", "DatasetWarning", "StageDetectionError", "detect_stage",
    "discover_datasets", "discover_fast_root", "resolve_dataset_path",
    "symlinked_datasets"
]

STAGE_ORG_SETUP = "0-org-setup"
STAGE_VPCSC = "1-vpcsc"
STAGE_NETWORKING = "2-networking"
STAGES = (STAGE_ORG_SETUP, STAGE_VPCSC, STAGE_NETWORKING)

PathLike = Union[str, pathlib.Path]


class StageDetectionError(ValueError):
  """The directory does not look like any supported FAST stage dataset."""


def _entries(root: pathlib.Path) -> List[str]:
  return sorted(p.name + ("/" if p.is_dir() else "") for p in root.iterdir())


def _defaults_has_vpcs(root: pathlib.Path) -> bool:
  # A probe only: the loader parses the file again and reports its warnings.
  try:
    with warnings.catch_warnings():
      warnings.simplefilter("ignore", DatasetWarning)
      doc = yamlio.load_or_empty(root / "defaults.yaml")
  except DatasetError:
    return False
  return isinstance(doc, dict) and "vpcs" in doc


def detect_stage(dataset_dir: PathLike) -> str:
  """Returns the FAST stage of a dataset directory by fingerprint."""
  root = pathlib.Path(dataset_dir)
  if not root.is_dir():
    raise StageDetectionError(f"not a directory: {root}")
  if (root / "perimeters").is_dir() or (root /
                                        "restricted-services.yaml").is_file():
    return STAGE_VPCSC
  if (root / "organization").is_dir():
    return STAGE_ORG_SETUP
  if (root / "vpcs").is_dir() and ((root / "ncc-hubs").is_dir() or
                                   (root / "nvas").is_dir() or
                                   _defaults_has_vpcs(root)):
    return STAGE_NETWORKING
  found = ", ".join(_entries(root)) or "(empty)"
  raise StageDetectionError(
      f"cannot detect FAST stage for {root}: expected perimeters/ or "
      f"restricted-services.yaml (1-vpcsc), organization/ (0-org-setup), or "
      f"vpcs/ with ncc-hubs/, nvas/ or a `vpcs:` key in defaults.yaml "
      f"(2-networking); found: {found}")


def _display_name(path: PathLike, resolved: pathlib.Path) -> str:
  """The name the user typed (a symlink keeps its own name)."""
  name = pathlib.Path(path).name
  return resolved.name if name in ("", ".", "..") else name


@dataclass(frozen=True)
class Dataset:
  """A dataset directory with its resolved stage and display name.

  `root` is the resolved directory (symlinks followed); `name` is the name
  of the path as given, before resolving symlinks, so `datasets/classic ->
  hub-and-spokes-peerings` renders as `classic`.
  """
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
    return cls(root=root, stage=stage, name=_display_name(path, root))


def discover_datasets(datasets_root: PathLike) -> List[pathlib.Path]:
  """Sorted dataset sub-directories (non-hidden, non-symlink) of a root.

  Symlinked datasets are skipped (they duplicate their target); use
  `symlinked_datasets` to report them.
  """
  root = pathlib.Path(datasets_root)
  if not root.is_dir():
    return []
  return sorted(
      p for p in root.iterdir()
      if p.is_dir() and not p.is_symlink() and not p.name.startswith("."))


def symlinked_datasets(
    datasets_root: PathLike) -> List[Tuple[pathlib.Path, pathlib.Path]]:
  """`(link, resolved_target)` for every non-hidden symlink in a root.

  These are the entries `discover_datasets` skips, sorted by link name. A
  dangling link is included; its target simply does not exist.
  """
  root = pathlib.Path(datasets_root)
  if not root.is_dir():
    return []
  out = []
  for p in sorted(root.iterdir()):
    if p.is_symlink() and not p.name.startswith("."):
      try:
        target = p.resolve()
      except (OSError, RuntimeError):  # symlink loop
        target = pathlib.Path(p.readlink())
      out.append((p, target))
  return out


def discover_fast_root(stages_dir: PathLike) -> List[Tuple[str, pathlib.Path]]:
  """`(stage_dir_name, dataset_dir)` for every `<stages_dir>/*/datasets/*`.

  The stage directory name (e.g. `2-project-factory`) is returned so callers
  render only supported stages instead of trusting the fingerprint alone.
  """
  root = pathlib.Path(stages_dir)
  out: List[Tuple[str, pathlib.Path]] = []
  if not root.is_dir():
    return out
  for stage_dir in sorted(p for p in root.iterdir() if p.is_dir()):
    out.extend(
        (stage_dir.name, d) for d in discover_datasets(stage_dir / "datasets"))
  return out


def resolve_dataset_path(root: pathlib.Path, value,
                         base: pathlib.Path) -> Optional[pathlib.Path]:
  """Resolves a dataset-provided path string, refusing to leave `root`.

  Mirrors Fabric's factory path rule (`modules/project-factory/projects.tf`,
  `fast/stages/2-networking/factory-vpcs.tf`): a value starting with `/` or
  `.` is used as-is, anything else is relative to `base` (the dataset root
  or the VPC directory). `.`-prefixed values are relative to the Terraform
  working directory, taken to be the stage directory (`<stage>/datasets/
  <name>/../..`) when the dataset lives in a `datasets/` folder, else the
  dataset root.

  Returns the resolved path, or `None` when `value` is not a non-empty
  string or resolves outside `root` (symlinks included). The caller decides
  whether a `None` or a non-existent path is a "missing" factory.
  """
  if not isinstance(value, str) or not value.strip():
    return None
  root = root.resolve()
  v = value.strip()
  if v.startswith("/"):
    candidate = pathlib.Path(v)
  elif v.startswith("."):
    cwd = root.parent.parent if root.parent.name == "datasets" else root
    candidate = cwd / v
  else:
    candidate = base / v
  try:
    resolved = candidate.resolve()
  except (OSError, RuntimeError):  # symlink loop
    return None
  return resolved if resolved.is_relative_to(root) else None
