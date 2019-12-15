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

"Apply fixture."

import os

import pytest


# path of this folder relative to root
_PATH = os.path.sep.join(os.path.abspath(__file__).split(os.path.sep)[-4:-1])


@pytest.fixture(scope='module')
def fix_path():
  "Returns a function that prepends the test module path."
  return lambda p: os.path.join(_PATH, p)
