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


def test_counts(plan_summary):
  "Test stage."
  summary = plan_summary("fast/stages/1-resman",
                         tf_var_files=["common.tfvars"])
  assert summary.counts["modules"] > 0
  assert summary.counts["resources"] > 0
