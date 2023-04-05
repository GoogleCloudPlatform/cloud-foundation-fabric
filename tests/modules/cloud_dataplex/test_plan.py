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


def test_dataplex_instance(plan_runner):
    "Test dataplex instance."

    _, resources = plan_runner()
    assert len(resources) == 1
    r = resources[0]
    assert r['values']['project'] == 'myproject'
    assert r['values']['name'] == 'test'
    assert r['values']['region'] == 'europe-west2'


def test_prefix(plan_runner):
    "Test dataplex prefix."

    _, resources = plan_runner(prefix="prefix")
    assert len(resources) == 1
    r = resources[0]
    assert r['values']['name'] == 'prefix-test'

    _, resources = plan_runner(prefix="prefix")
    assert len(resources) == 1
    r = resources[0]
    assert r['values']['name'] == 'prefix-db'
