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

import itertools
import pytest

pytest_plugins = (
    'tests.fixtures',
    'tests.collectors',
)


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
