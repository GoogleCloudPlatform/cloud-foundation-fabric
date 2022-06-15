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

# _RESOURCE_COUNT = {
#     'module.organization': 28,
#     'module.automation-project': 23,
#     'module.automation-tf-bootstrap-gcs': 1,
#     'module.automation-tf-bootstrap-sa': 1,
#     'module.automation-tf-resman-gcs': 2,
#     'module.automation-tf-resman-sa': 1,
#     'module.billing-export-dataset': 1,
#     'module.billing-export-project': 7,
#     'module.log-export-dataset': 1,
#     'module.log-export-project': 7,
# }


def test_counts(fast_e2e_plan_runner):
    "Test stage."
    # TODO: to re-enable per-module resource count check print _, then test
    num_modules, num_resources, _ = fast_e2e_plan_runner()
    assert num_modules > 0 and num_resources > 0
