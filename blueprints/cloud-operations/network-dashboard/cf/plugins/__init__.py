# Copyright 2022 Google LLC
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

import collections
import enum
import importlib
import itertools
import pathlib
import pkgutil

_PLUGINS = []

Level = enum.IntEnum('Level', 'CORE PRIMARY DERIVED')
Phase = enum.IntEnum('Phase', 'INIT DISCOVER EXTEND AGGREGATE')
Plugin = collections.namedtuple('Plugin',
                                'phase step level priority resource func')
Resource = collections.namedtuple('Resource', 'id data')
Step = enum.IntEnum('Step', 'START END')


class PluginError(Exception):
  pass


def get_plugins(phase, step=None):
  pred = lambda p: not (p.phase == phase and (step is None or p.step == step))
  return itertools.filterfalse(pred, _PLUGINS)


def register(resource, phase, step, level=Level.PRIMARY, priority=99):

  def outer(fn):
    _PLUGINS.append(Plugin(phase, step, level, priority, resource, fn))
    return fn

  return outer


_plugins_path = str(pathlib.Path(__file__).parent)

for mod_info in pkgutil.iter_modules([_plugins_path], 'plugins.'):
  importlib.import_module(mod_info.name)

_PLUGINS.sort()

__all__ = [
    'Level', 'Phase', 'PluginError', 'Resource', 'Step', 'get_plugins',
    'register'
]
