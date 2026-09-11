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
'Pytest configuration.'

import hashlib
import itertools
import pytest

pytest_plugins = (
    'tests.fixtures',
    'tests.collectors',
)


def pytest_addoption(parser):
  group = parser.getgroup('sharding')
  group.addoption('--shard-id', type=int, default=0, metavar='N',
                  help='Zero-based index of this shard.')
  group.addoption('--shard-count', type=int, default=1, metavar='N',
                  help='Total number of shards (1 disables sharding).')


def pytest_collection_modifyitems(config, items):
  """Keep only the tests belonging to the current shard.

  Tests are assigned to shards by hashing their node id, so every shard
  computes the same partition without talking to the others. hashlib is
  used instead of hash() because Python randomizes string hashing per
  process, which would make shards disagree and silently drop tests.
  """
  count = config.getoption('shard_count')
  if count <= 1:
    return
  shard_id = config.getoption('shard_id')
  if not 0 <= shard_id < count:
    raise pytest.UsageError(f'--shard-id must be in [0, {count}), '
                            f'got {shard_id}')
  selected, deselected = [], []
  for item in items:
    digest = hashlib.sha256(item.nodeid.encode()).digest()
    bucket = int.from_bytes(digest[:8], 'big') % count
    (selected if bucket == shard_id else deselected).append(item)
  if deselected:
    config.hook.pytest_deselected(items=deselected)
  items[:] = selected


def pytest_terminal_summary(terminalreporter, exitstatus, config):
  failed_reports = terminalreporter.stats.get('failed', [])
  commands = []
  for rep in failed_reports:
    capstdout = getattr(rep, 'capstdout', '')
    lines = capstdout.splitlines()
    for line, next_line in itertools.pairwise(lines):
      if line.strip() == 'To regenerate inventory run:':
        commands.append(next_line.strip())

  if commands:
    terminalreporter.ensure_newline()
    terminalreporter.section(
        'Commands to regenerate inventories for failed tests', sep='=',
        bold=True)
    for cmd in sorted(set(commands)):
      terminalreporter.write_line(cmd)
