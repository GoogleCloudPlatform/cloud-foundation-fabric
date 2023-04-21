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
"""Legacy pytest fixtures.

The fixtures contained in this file will eventually go away. Consider
using one of the fixtures in fixtures.py
"""

import inspect
import os
import shutil
import tempfile

import pytest
import tftest

BASEDIR = os.path.dirname(os.path.dirname(__file__))


@pytest.fixture(scope='session')
def apply_runner():
  'Return a function to run Terraform apply on a fixture.'

  def run_apply(fixture_path=None, **tf_vars):
    'Run Terraform plan and returns parsed output.'
    if fixture_path is None:
      # find out the fixture directory from the caller's directory
      caller = inspect.stack()[1]
      fixture_path = os.path.join(os.path.dirname(caller.filename), 'fixture')

    fixture_parent = os.path.dirname(fixture_path)
    fixture_prefix = os.path.basename(fixture_path) + '_'

    with tempfile.TemporaryDirectory(prefix=fixture_prefix,
                                     dir=fixture_parent) as tmp_path:
      # copy fixture to a temporary directory so we can execute
      # multiple tests in parallel
      shutil.copytree(fixture_path, tmp_path, dirs_exist_ok=True)
      tf = tftest.TerraformTest(tmp_path, BASEDIR,
                                os.environ.get('TERRAFORM', 'terraform'))
      tf.setup(upgrade=True)
      apply = tf.apply(tf_vars=tf_vars)
      output = tf.output(json_format=True)
      return apply, output

  return run_apply
