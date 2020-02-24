# Copyright 2020 Google LLC
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


def test_vpc_simple(plan_runner):
  "Test vpc with no extra options."
  _, resources = plan_runner(FIXTURES_DIR)
  assert len(resources) == 1
  assert [r['type'] for r in resources] == ['google_compute_network']
  assert [r['values']['name'] for r in resources] == ['my-vpc']
  assert [r['values']['project'] for r in resources] == ['my-project']
