# Copyright 2023 Google LLC
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
'''Plugin interface objects and registration functions.

This module export the objects passed to and returned from plugin functions,
and the function used to register plugins for each stage, and get all plugins
for individual stages.
'''

import collections
import enum
import functools
import importlib
import pathlib
import pkgutil
import types

__all__ = [
    'HTTPRequest', 'Level', 'PluginError', 'Resource', 'get_discovery_plugins',
    'get_init_plugins', 'register_discovery', 'register_init'
]

_PLUGINS_DISCOVERY = []
_PLUGINS_INIT = []
_PLUGINS_TIMESERIES = []

HTTPRequest = collections.namedtuple('HTTPRequest', 'url headers data json',
                                     defaults=[True])
Level = enum.IntEnum('Level', 'CORE PRIMARY DERIVED')
MetricDescriptor = collections.namedtuple('MetricDescriptor',
                                          'type name labels is_ratio',
                                          defaults=[False])
Plugin = collections.namedtuple('Plugin', 'func name level priority',
                                defaults=[Level.PRIMARY, 99])
Resource = collections.namedtuple('Resource', 'type id data key',
                                  defaults=[None])
TimeSeries = collections.namedtuple('TimeSeries', 'metric value labels')


class PluginError(Exception):
  pass


def _register_plugin(collection, *args):
  'Derive plugin name from function and add to its collection.'
  if args and type(args[0]) == types.FunctionType:
    collection.append(
        Plugin(args[0], f'{args[0].__module__}.{args[0].__name__}'))
    return

  def outer(func):
    collection.append(Plugin(func, f'{func.__module__}.{func.__name__}', *args))
    return func

  return outer


get_discovery_plugins = functools.partial(iter, _PLUGINS_DISCOVERY)
get_init_plugins = functools.partial(iter, _PLUGINS_INIT)
get_timeseries_plugins = functools.partial(iter, _PLUGINS_TIMESERIES)
register_discovery = functools.partial(_register_plugin, _PLUGINS_DISCOVERY)
register_init = functools.partial(_register_plugin, _PLUGINS_INIT)
register_timeseries = functools.partial(_register_plugin, _PLUGINS_TIMESERIES)

_plugins_path = str(pathlib.Path(__file__).parent)

for mod_info in pkgutil.iter_modules([_plugins_path], 'plugins.'):
  importlib.import_module(mod_info.name)

_PLUGINS_DISCOVERY.sort(key=lambda i: i.level)
