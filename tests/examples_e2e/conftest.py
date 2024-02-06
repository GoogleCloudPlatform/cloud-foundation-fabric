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
"""Pytest configuration for testing code examples."""

from ..examples.conftest import pytest_generate_tests as _examples_generate_test


def pytest_generate_tests(metafunc):
  """Find all README.md files and collect code examples tagged for testing."""
  _examples_generate_test(metafunc, "examples_e2e", lambda x: 'e2e' in x)
