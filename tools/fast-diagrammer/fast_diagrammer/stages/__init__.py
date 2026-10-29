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
"""Stage builders: dataset model -> SceneGraph (one module per stage).

Builder contract (every `stages/<module>.py`):
  VIEWS: tuple[str, ...]            # first entry is the default view
  build(dataset_dir, view, dataset_name=None, *, <options>) -> SceneGraph
Each builder declares its keyword-only options explicitly, so an unknown
option raises `TypeError`. The CLI passes only the options a builder's
signature accepts out of: rpz_bind_lines, verbose_badges, legend,
org_dataset, strict. Helpers shared by the builders live in `_common.py`.
"""

import importlib
import inspect
from types import ModuleType
from typing import Any, Dict

STAGE_MODULES = {
    "0-org-setup": "org_setup",
    "1-vpcsc": "vpcsc",
    "2-networking": "networking",
}


def get_builder(stage: str) -> ModuleType:
  """Imports and returns the builder module for a FAST stage."""
  try:
    mod = STAGE_MODULES[stage]
  except KeyError as exc:
    raise ValueError(f"unknown stage {stage!r}") from exc
  return importlib.import_module(f"{__name__}.{mod}")


def accepted_options(build_fn: Any, options: Dict[str, Any]) -> Dict[str, Any]:
  """Filters `options` down to what `build_fn` accepts by name."""
  sig = inspect.signature(build_fn)
  if any(
      p.kind is inspect.Parameter.VAR_KEYWORD for p in sig.parameters.values()):
    return dict(options)
  return {k: v for k, v in options.items() if k in sig.parameters}
