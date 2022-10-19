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


def test_counts(recursive_e2e_plan_runner):
  "Test stage."
  num_modules, num_resources = recursive_e2e_plan_runner()
  # TODO: to re-enable per-module resource count check print _, then test
  assert num_modules > 0 and num_resources > 0