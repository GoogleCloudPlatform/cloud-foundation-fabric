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

"Plan fixture."

import os

import pytest
import tftest


_ABSPATH = os.path.dirname(os.path.abspath(__file__)).split(os.path.sep)
_TFDIR = os.path.sep.join(_ABSPATH[-2:])


@pytest.fixture(scope='session')
def plan():
  import logging
  logging.basicConfig(level=logging.DEBUG)
  tf = tftest.TerraformTest(_TFDIR, os.path.sep.join(_ABSPATH[:-3]),
                            os.environ.get('TERRAFORM', 'terraform'))
  tf.setup(extra_files=['tests/{}/terraform.tfvars'.format(_TFDIR)])
  return tf.plan_out(parsed=True)
