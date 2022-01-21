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

"Shared fixtures"

import inspect
import os
import types

import pytest
import tftest


BASEDIR = os.path.dirname(os.path.dirname(__file__))


@pytest.fixture(scope='session')
def fast_e2e_plan_runner(_plan_runner):
  "Plan runner for end-to-end root module, returns modules and resources."
  def run_plan(fixture_path=None, targets=None, refresh=True,
               include_bare_resources=False, compute_sums=True, **tf_vars):
    "Runs Terraform plan on a root module using defaults, returns data."
    plan = _plan_runner(fixture_path, targets=targets, refresh=refresh,
                        **tf_vars)
    root_module = plan.root_module['child_modules'][0]
    modules = {
        m['address'].removeprefix(root_module['address'])[1:]: m['resources']
        for m in root_module['child_modules']
    }
    resources = [r for m in modules.values() for r in m]
    if include_bare_resources:
      bare_resources = root_module['resources']
      resources.extend(bare_resources)
    if compute_sums:
      return len(modules), len(resources), {k: len(v) for k, v in modules.items()}
    return modules, resources
  return run_plan
