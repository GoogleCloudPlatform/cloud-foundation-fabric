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

"Shared fixtures"

import os
import pytest
import tftest


BASEDIR = os.path.dirname(os.path.dirname(__file__))


@pytest.fixture(scope='session')
def plan_runner():
  "Returns a function to run Terraform plan on a fixture."

  def run_plan(fixture_path, **tf_vars):
    "Runs Terraform plan and returns parsed output"
    tf = tftest.TerraformTest(fixture_path, BASEDIR,
                              os.environ.get('TERRAFORM', 'terraform'))
    tf.setup()
    plan = tf.plan(output=True, tf_vars=tf_vars)
    return (
        plan,
        plan.planned_values['root_module']['child_modules'][0]['resources']
    )

  return run_plan
