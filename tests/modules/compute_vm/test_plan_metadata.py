# Copyright 2021 Google LLC
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


import os
import pytest


FIXTURES_DIR = os.path.join(os.path.dirname(__file__), 'fixture')


def test_default(plan_runner):
  _, resources = plan_runner(FIXTURES_DIR, metadata='{a=1, b=2}')
  assert resources[0]['values']['metadata'] == {'a': '1', 'b': '2'}


def test_multi(plan_runner):
  _, resources = plan_runner(FIXTURES_DIR, instance_count=3,
                             metadata='{a=1, b=2}',
                             metadata_list='[{c=3}, {c=4}]')
  assert resources[0]['values']['metadata'] == {'a': '1', 'b': '2', 'c': '3'}
  assert resources[1]['values']['metadata'] == {'a': '1', 'b': '2', 'c': '4'}
  assert resources[2]['values']['metadata'] == {'a': '1', 'b': '2', 'c': '3'}
