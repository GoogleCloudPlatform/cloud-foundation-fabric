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
"""Read-only YAML helpers (PyYAML `safe_load`, insertion order preserved).

`load()` uses a YAML 1.2-core flavoured SafeLoader so plain data matches
what a round-trip (1.2) loader yields: `yes/no/on/off` stay strings (an
access-level region `NO` is Norway, not False), `1:20` is not sexagesimal,
and dates stay strings instead of becoming `datetime.date`. `None` documents
become `{}`. The tool never writes into a dataset directory.
"""

import pathlib
import re
from typing import Any, Iterator, List, Union

import yaml

PathLike = Union[str, pathlib.Path]


class Yaml12SafeLoader(yaml.SafeLoader):  # pylint: disable=too-many-ancestors
  """SafeLoader with YAML 1.2 core-schema bool/int/float resolution."""


# Drop the YAML 1.1 implicit resolvers for bool / int / float / timestamp...
Yaml12SafeLoader.yaml_implicit_resolvers = {
    first: [(tag, rx)
            for tag, rx in resolvers
            if tag not in ("tag:yaml.org,2002:bool", "tag:yaml.org,2002:int",
                           "tag:yaml.org,2002:float",
                           "tag:yaml.org,2002:timestamp")]
    for first, resolvers in yaml.SafeLoader.yaml_implicit_resolvers.items()
}
# ...and add the YAML 1.2 core-schema ones.
Yaml12SafeLoader.add_implicit_resolver(
    "tag:yaml.org,2002:bool",
    re.compile(r"^(?:true|True|TRUE|false|False|FALSE)$"),
    list("tTfF"))
Yaml12SafeLoader.add_implicit_resolver(
    "tag:yaml.org,2002:int",
    re.compile(r"^(?:[-+]?[0-9]+|0o[0-7]+|0x[0-9a-fA-F]+)$"),
    list("-+0123456789"))
Yaml12SafeLoader.add_implicit_resolver(
    "tag:yaml.org,2002:float",
    re.compile(r"^(?:[-+]?(?:\.[0-9]+|[0-9]+(?:\.[0-9]*)?)(?:[eE][-+]?[0-9]+)?"
               r"|[-+]?\.(?:inf|Inf|INF)|\.(?:nan|NaN|NAN))$"),
    list("-+0123456789."))


def _construct_yaml12_int(loader, node):
  value = loader.construct_scalar(node)
  text = value.replace("_", "")
  if text.startswith("0o"):
    return int(text[2:], 8)
  if text.startswith("0x"):
    return int(text[2:], 16)
  return int(text, 10)


Yaml12SafeLoader.add_constructor("tag:yaml.org,2002:int",
                                 _construct_yaml12_int)


def loads(text: str) -> Any:
  """Parses YAML text; an empty document becomes `{}`."""
  doc = yaml.load(text, Loader=Yaml12SafeLoader)  # nosec: safe loader subclass
  return {} if doc is None else doc


def load(path: PathLike) -> Any:
  """Loads one YAML file; an empty document becomes `{}`."""
  return loads(pathlib.Path(path).read_text(encoding="utf-8"))


def load_or_empty(path: PathLike) -> Any:
  """Like `load`, but a missing file is `{}` (never fatal)."""
  p = pathlib.Path(path)
  return load(p) if p.is_file() else {}


def _is_yaml(p: pathlib.Path) -> bool:
  return p.is_file() and p.suffix in (".yaml", ".yml")


def yaml_files(directory: PathLike, *, include_hidden: bool = False
              ) -> List[pathlib.Path]:
  """Sorted `*.yaml` / `*.yml` files directly inside `directory`.

  Hidden files (`.config.yaml`) are skipped unless `include_hidden`. A
  missing directory yields `[]`.
  """
  d = pathlib.Path(directory)
  if not d.is_dir():
    return []
  return sorted(p for p in d.iterdir()
                if _is_yaml(p) and (include_hidden or not p.name.startswith(".")))


def rglob_yaml(directory: PathLike, *, include_hidden: bool = False
              ) -> List[pathlib.Path]:
  """Sorted recursive `*.yaml` / `*.yml` under `directory` (POSIX path order).

  Files under hidden directories are skipped; hidden files are skipped unless
  `include_hidden`.
  """
  d = pathlib.Path(directory)
  if not d.is_dir():
    return []
  out = []
  for p in d.rglob("*"):
    if not _is_yaml(p):
      continue
    rel = p.relative_to(d)
    if any(part.startswith(".") for part in rel.parts[:-1]):
      continue
    if not include_hidden and p.name.startswith("."):
      continue
    out.append(p)
  return sorted(out, key=lambda p: p.relative_to(d).as_posix())


def subdirs(directory: PathLike) -> List[pathlib.Path]:
  """Sorted non-hidden, non-symlink sub-directories of `directory`."""
  d = pathlib.Path(directory)
  if not d.is_dir():
    return []
  return sorted(p for p in d.iterdir()
                if p.is_dir() and not p.is_symlink() and not p.name.startswith("."))


def iter_docs(directory: PathLike) -> Iterator[tuple]:
  """Yields `(stem, doc)` for `yaml_files(directory)` in sorted order."""
  for p in yaml_files(directory):
    yield p.stem, load(p)
