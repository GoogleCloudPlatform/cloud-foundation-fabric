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
"""Read-only YAML helpers for FAST datasets (PyYAML `SafeLoader` subclass).

Scalar resolution follows the YAML 1.2 core schema: only `true`/`false`
(and their `True`/`TRUE` variants) are booleans, `1:20` is not sexagesimal
and dates stay strings instead of becoming `datetime.date`.

This intentionally diverges from Terraform. `yamldecode` (go-cty-yaml, a
YAML 1.1 resolver) reads the plain scalars `y/n/yes/no/on/off` (any case
variant) as booleans, so an access-level region `NO` (Norway) is `false` for
Terraform. The loader keeps such scalars as strings and emits a
`DatasetWarning` naming the file and line, so the dataset author can quote
the value. Quoted scalars are never reported.

Other rules, matching Terraform where it matters for the diagrams:

- mapping keys are converted to strings (Terraform object keys are strings;
  `true`/`false` keys become `"true"`/`"false"`);
- an empty document becomes `{}`; more than one document is an error;
- parse errors and undecodable files raise `DatasetError` carrying the path.

File discovery mirrors Terraform `fileset(dir, "*.yaml")` and
`fileset(dir, "**/*.yaml")`: only the `.yaml` extension is read (`.yml` is
ignored), results are sorted by relative POSIX path, symlinked directories
are never descended into, and a symlinked file is read only when its target
stays inside the `within` directory (default: the directory being listed).
Hidden files and hidden directories are skipped (a deliberate divergence:
`fileset` would match them); `.config.yaml` is reachable through
`include_hidden` or `config_dirs`.

Non-fatal problems are reported with `warnings.warn(DatasetWarning(...))`;
callers collect them with `warnings.catch_warnings(record=True)`. The tool
never writes into a dataset directory.
"""

import os
import pathlib
import re
from typing import Any, Iterator, List, Optional, Tuple, Union
import warnings

import yaml

PathLike = Union[str, pathlib.Path]


class DatasetError(ValueError):
  """A dataset file is unreadable or structurally invalid.

  `path` is the offending file (or directory), `key` the dotted key inside
  it (or `None` for the whole document), `message` the human explanation.
  """

  def __init__(self, path: Optional[PathLike], key: Optional[str],
               message: str):
    self.path = None if path is None else str(path)
    self.key = key
    self.message = message
    where = self.path or "<dataset>"
    if key:
      where = f"{where}: {key}"
    super().__init__(f"{where}: {message}")


class DatasetWarning(UserWarning):
  """A non-fatal dataset problem (divergence from Terraform, ignored data)."""


def warn(message: str) -> None:
  """Emits a `DatasetWarning` (the single loader warning mechanism)."""
  warnings.warn(DatasetWarning(message), stacklevel=2)


class Yaml12SafeLoader(yaml.SafeLoader):  # pylint: disable=too-many-ancestors
  """SafeLoader with YAML 1.2 core-schema scalars and string mapping keys."""

  def construct_mapping(self, node, deep=False):
    """Like SafeConstructor's, but keys become strings while building, so
    `1` and `true` stay distinct keys (`"1"`, `"true"`) as in Terraform."""
    if isinstance(node, yaml.MappingNode):
      self.flatten_mapping(node)
    else:
      raise yaml.constructor.ConstructorError(
          None, None, f"expected a mapping node, but found {node.id}",
          node.start_mark)
    mapping = {}
    for key_node, value_node in node.value:
      key = self.construct_object(key_node, deep=deep)
      if isinstance(key, (list, dict, set)):
        raise yaml.constructor.ConstructorError("while constructing a mapping",
                                                node.start_mark,
                                                "found an unhashable key",
                                                key_node.start_mark)
      mapping[key if isinstance(key, str) else _key(key)] = (
          self.construct_object(value_node, deep=deep))
    return mapping


_YAML11_BOOL_TAG = "tag:fast-diagrammer,2026:yaml11-bool"

# Drop the YAML 1.1 implicit resolvers for bool / int / float / timestamp...
Yaml12SafeLoader.yaml_implicit_resolvers = {
    first: [
        (tag, rx)
        for tag, rx in resolvers
        if tag not in ("tag:yaml.org,2002:bool", "tag:yaml.org,2002:int",
                       "tag:yaml.org,2002:float", "tag:yaml.org,2002:timestamp")
    ] for first, resolvers in yaml.SafeLoader.yaml_implicit_resolvers.items()
}
# ...and add the YAML 1.2 core-schema ones.
Yaml12SafeLoader.add_implicit_resolver(
    "tag:yaml.org,2002:bool",
    re.compile(r"^(?:true|True|TRUE|false|False|FALSE)$"), list("tTfF"))
Yaml12SafeLoader.add_implicit_resolver(
    "tag:yaml.org,2002:int",
    re.compile(r"^(?:[-+]?[0-9]+|0o[0-7]+|0x[0-9a-fA-F]+)$"),
    list("-+0123456789"))
Yaml12SafeLoader.add_implicit_resolver(
    "tag:yaml.org,2002:float",
    re.compile(r"^(?:[-+]?(?:\.[0-9]+|[0-9]+(?:\.[0-9]*)?)(?:[eE][-+]?[0-9]+)?"
               r"|[-+]?\.(?:inf|Inf|INF)|\.(?:nan|NaN|NAN))$"),
    list("-+0123456789."))
# Plain scalars that go-cty-yaml (YAML 1.1) resolves as booleans: kept as
# strings here, but reported.
Yaml12SafeLoader.add_implicit_resolver(
    _YAML11_BOOL_TAG,
    re.compile(r"^(?:y|Y|yes|Yes|YES|n|N|no|No|NO"
               r"|on|On|ON|off|Off|OFF)$"), list("yYnNoO"))


def _construct_yaml12_int(loader, node):
  text = loader.construct_scalar(node)
  if text.startswith("0o"):
    return int(text[2:], 8)
  if text.startswith("0x"):
    return int(text[2:], 16)
  return int(text, 10)


def _construct_yaml11_bool(loader, node):
  value = loader.construct_scalar(node)
  mark = node.start_mark
  warnings.warn(
      DatasetWarning(
          f"{mark.name}:{mark.line + 1}: plain scalar {value!r} is read as the "
          f"string {value!r}, but Terraform yamldecode (YAML 1.1) reads it "
          f"as a boolean; quote it to make the intent explicit"), stacklevel=2)
  return value


Yaml12SafeLoader.add_constructor("tag:yaml.org,2002:int", _construct_yaml12_int)
Yaml12SafeLoader.add_constructor(_YAML11_BOOL_TAG, _construct_yaml11_bool)


def _key(k: Any) -> str:
  if isinstance(k, bool):
    return "true" if k else "false"
  if k is None:
    return "null"
  return str(k)


def _parse(stream, path: Optional[PathLike]) -> Any:
  try:
    doc = yaml.load(stream, Loader=Yaml12SafeLoader)  # nosec: safe subclass
  except yaml.YAMLError as e:
    raise DatasetError(path, None, f"invalid YAML: {e}") from e
  return {} if doc is None else doc


def loads(text: str) -> Any:
  """Parses YAML text; an empty document becomes `{}`."""
  return _parse(text, None)


def load(path: PathLike) -> Any:
  """Loads one YAML file; an empty document becomes `{}`.

  The file is parsed from a stream so that every parser error and warning
  names the file; errors are raised as `DatasetError`.
  """
  p = pathlib.Path(path)
  try:
    with p.open(encoding="utf-8") as stream:
      return _parse(stream, p)
  except UnicodeDecodeError as e:
    raise DatasetError(p, None, f"not valid UTF-8: {e}") from e
  except OSError as e:
    raise DatasetError(p, None, f"cannot read: {e.strerror or e}") from e


def load_or_empty(path: PathLike) -> Any:
  """Like `load`, but a missing file is `{}` (never fatal)."""
  p = pathlib.Path(path)
  return load(p) if p.is_file() else {}


def _inside(path: pathlib.Path, within: pathlib.Path) -> bool:
  try:
    return path.resolve().is_relative_to(within.resolve())
  except (OSError, RuntimeError):  # symlink loops
    return False


def _yaml_file_ok(p: pathlib.Path, within: pathlib.Path,
                  include_hidden: bool) -> bool:
  if not p.name.endswith(".yaml"):
    return False
  if p.name.startswith(".") and not include_hidden:
    return False
  if p.is_symlink() and not _inside(p, within):
    return False
  return p.is_file()


def yaml_files(directory: PathLike, *, include_hidden: bool = False,
               within: Optional[PathLike] = None) -> List[pathlib.Path]:
  """Sorted `*.yaml` files directly inside `directory`.

  Hidden files (`.config.yaml`) are skipped unless `include_hidden`. A
  missing directory (or a symlinked one) yields `[]`.
  """
  d = pathlib.Path(directory)
  if not d.is_dir() or d.is_symlink():
    return []
  w = pathlib.Path(within) if within is not None else d
  return sorted((p for p in d.iterdir() if _yaml_file_ok(p, w, include_hidden)),
                key=lambda p: p.name)


def _walk(d: pathlib.Path) -> Iterator[Tuple[pathlib.Path, List[str]]]:
  """`os.walk` that never follows symlinks and prunes hidden directories."""
  for dirpath, dirnames, filenames in os.walk(d, followlinks=False):
    base = pathlib.Path(dirpath)
    dirnames[:] = sorted(
        n for n in dirnames
        if not n.startswith(".") and not (base / n).is_symlink())
    yield base, sorted(filenames)


def rglob_yaml(directory: PathLike, *, include_hidden: bool = False,
               within: Optional[PathLike] = None) -> List[pathlib.Path]:
  """Sorted recursive `*.yaml` under `directory` (`fileset("**/*.yaml")`).

  Ordered by relative POSIX path. Hidden directories and symlinked
  directories are never entered; hidden files are skipped unless
  `include_hidden`.
  """
  d = pathlib.Path(directory)
  if not d.is_dir() or d.is_symlink():
    return []
  w = pathlib.Path(within) if within is not None else d
  out = []
  for base, filenames in _walk(d):
    out.extend(base / n
               for n in filenames
               if _yaml_file_ok(base / n, w, include_hidden))
  return sorted(out, key=lambda p: p.relative_to(d).as_posix())


def config_dirs(
    directory: PathLike, *,
    within: Optional[PathLike] = None) -> List[Tuple[str, pathlib.Path]]:
  """`(relative_dir, config_path)` for every `**/.config.yaml` below
  `directory` (the directory itself excluded), sorted by relative path.

  This is how Fabric keys folders and VPCs: `dirname()` of each match.
  Directories without a `.config.yaml` are not returned.
  """
  d = pathlib.Path(directory)
  if not d.is_dir() or d.is_symlink():
    return []
  w = pathlib.Path(within) if within is not None else d
  out = []
  for base, filenames in _walk(d):
    if base == d or ".config.yaml" not in filenames:
      continue
    cfg = base / ".config.yaml"
    if _yaml_file_ok(cfg, w, True):
      out.append((base.relative_to(d).as_posix(), cfg))
  return sorted(out)


def relative_key(path: pathlib.Path, directory: pathlib.Path) -> str:
  """`a/b/c.yaml` under `directory` -> `a/b/c` (Fabric `trimsuffix` key)."""
  rel = path.relative_to(directory).as_posix()
  return rel[:-len(".yaml")] if rel.endswith(".yaml") else rel


def subdirs(directory: PathLike) -> List[pathlib.Path]:
  """Sorted non-hidden, non-symlink sub-directories of `directory`."""
  d = pathlib.Path(directory)
  if not d.is_dir():
    return []
  return sorted(
      p for p in d.iterdir()
      if p.is_dir() and not p.is_symlink() and not p.name.startswith("."))


def iter_docs(directory: PathLike) -> Iterator[tuple]:
  """Yields `(stem, doc)` for `yaml_files(directory)` in sorted order."""
  for p in yaml_files(directory):
    yield p.stem, load(p)


def mapping(value: Any, path: Optional[PathLike], key: str) -> dict:
  """`value` as a mapping: `None` is `{}`, anything else non-dict raises."""
  if value is None:
    return {}
  if isinstance(value, dict):
    return value
  raise DatasetError(path, key,
                     f"expected a mapping, got {type(value).__name__}")


def sequence(value: Any, path: Optional[PathLike], key: str) -> list:
  """`value` as a list: `None` is `[]`, anything else non-list raises."""
  if value is None:
    return []
  if isinstance(value, list):
    return value
  raise DatasetError(path, key, f"expected a list, got {type(value).__name__}")


def load_mapping(path: PathLike) -> dict:
  """Loads a file whose document must be a mapping (or empty)."""
  return mapping(load(path), path, None)
