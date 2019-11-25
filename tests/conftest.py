# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"Shared fixtures."

import collections
import os

import pytest
import tftest


# top-level repository folder
_BASEDIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# fixture result
Result = collections.namedtuple(
    'Result', 'terraform plan output destroy')


@pytest.fixture(scope='session')
def plan():

  def run_plan(testdir):
    tfdir = testdir.replace('_', '-')
    tf = tftest.TerraformTest(tfdir, _BASEDIR,
                              os.environ.get('TERRAFORM', 'terraform'))
    tf.setup(extra_files=['tests/{}/terraform.tfvars'.format(testdir)])
    return tf.plan(output=True)

  return run_plan


@pytest.fixture(scope='session')
def run_fixture():
  "Returns a function to run Terraform on a fixture."

  def run(fixture_path, extra_files=None, run_plan=True, run_apply=True,
          run_destroy=not os.environ.get('TFTEST_INCREMENTAL')):
    """Runs Terraform on fixture and return result.

    Convenience method to wrap a tftest instance for a single fixture. Runs
    init on the tftest instance and optionally runs plan, aply and destroy,
    returning outputs.

    Args:
      fixture_path: the relative path from root to the fixture folder
      extra_files: extra files that are passed in to tftest for injection
      run_plan: run plan on the tftest instance
      run_apply: run apply on the tftest instance
      run_destroy: run destroy on the tftest instance, skips destroy by
        default if the TFTEST_INCREMENTAL environment variable is set

    Returns:
      A Result named tuple with the tftest instance and outputs for plan,
      output and destroy.
    """
    tf = tftest.TerraformTest(fixture_path, _BASEDIR,
                              os.environ.get('TERRAFORM', 'terraform'))
    tf.setup(extra_files=extra_files, cleanup_on_exit=run_destroy)
    plan = output = destroy = None
    if run_plan:
      plan = tf.plan(output=True)
    if run_apply:
      tf.apply()
      output = tf.output(json_format=True)
    if run_destroy:
      tf.destroy()
    return Result(tf, plan, output, destroy)

  return run


@pytest.fixture
def pretty_print():
  "Returns a fuction that pretty prints a data structure."

  def pretty_printer(data):
    import json
    print(json.dumps(data, indent=2))

  return pretty_printer
