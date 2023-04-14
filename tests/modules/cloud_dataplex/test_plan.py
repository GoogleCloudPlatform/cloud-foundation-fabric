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


def test_dataplex_lake(plan_runner):
    "Test dataplex lake."

    _, resources = plan_runner()
    assert len(resources) == 3
    r = resources[0]
    assert r['values']['project'] == 'myproject'
    assert r['values']['name'] == 'test_gcs'
    assert r['values']['location'] == 'europe-west2'
    assert r['values']['lake'] == 'test-terraform-lake'
