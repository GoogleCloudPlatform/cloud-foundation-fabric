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
import pathlib
import pkgutil
import types

__all__ = [
    'HTTPRequest', 'Level', 'PluginError', 'Resource', 'get_discovery_plugins',
    'get_init_plugins', 'register_discovery', 'register_init'
]

_PLUGINS_SERIES = []
_PLUGINS_DISCOVERY = []
_PLUGINS_INIT = []
_PLUGINS_SERIES = []

HTTPRequest = collections.namedtuple('HTTPRequest', 'url headers data')
Level = enum.IntEnum('Level', 'CORE PRIMARY DERIVED')
Plugin = collections.namedtuple('Plugin', 'func name level priority handler',
                                defaults=[None, None, None])
Resource = collections.namedtuple('Resource', 'id data')


class PluginError(Exception):
  pass


def get_discovery_plugins():
  'Return discovery plugins.'
  for p in _PLUGINS_DISCOVERY:
    yield p


def get_init_plugins():
  'Return init plugins.'
  for p in _PLUGINS_INIT:
    yield p


def get_series_plugins():
  'Return metrics plugins.'
  for p in _PLUGINS_SERIES:
    yield p


def _register(collection, func, *args):
  'Derive plugin name from function and add to its collection.'
  name = f'{func.__module__}.{func.__name__}'
  collection.append(Plugin(func, name, *args))


def register_discovery(handler_func, level=Level.PRIMARY, priority=99):
  'Register plugins that discover data.'

  def outer(func):
    _register(_PLUGINS_DISCOVERY, func, level, priority, handler_func)
    return func

  return outer


def register_init(*args):
  'Register plugins that prepare the shared data structure.'
  if args and type(args[0]) == types.FunctionType:
    _register(_PLUGINS_INIT, args[0])
    return

  def outer(func):
    _register(_PLUGINS_INIT, func)
    return func

  return outer


def register_series(*args):
  'Register plugins that derive metrics series from data.'
  if args and type(args[0]) == types.FunctionType:
    _register(_PLUGINS_SERIES, args[0])
    return

  def outer(func):
    _register(_PLUGINS_SERIES, func)
    return func

  return outer


_plugins_path = str(pathlib.Path(__file__).parent)

for mod_info in pkgutil.iter_modules([_plugins_path], 'plugins.'):
  importlib.import_module(mod_info.name)

_PLUGINS_DISCOVERY.sort(key=lambda i: i[2:-1])
