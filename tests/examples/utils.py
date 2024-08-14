# Copyright 2024 Google LLC
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

import collections
import re

Directive = collections.namedtuple('Directive', 'name args kwargs')
TerraformExample = collections.namedtuple(
    'TerraformExample', 'name code module files fixtures type directive')
YamlExample = collections.namedtuple('YamlExample', 'body module schema')
File = collections.namedtuple('File', 'path content')


def get_tftest_directive(s):
  """Scan a code block and return a Directive object if there are any
  tftest directives"""
  regexp = rf"^ *# *(tftest\S*)(.*)$"
  if match := re.search(regexp, s, re.M):
    name, body = match.groups()
    args = []
    kwargs = {}
    for arg in body.split():
      if '=' in arg:
        l, r = arg.split('=', 1)
        kwargs[l] = r
      else:
        args.append(arg)
    return Directive(name, args, kwargs)
  return None
