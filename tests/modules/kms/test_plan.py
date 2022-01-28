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

def test_resources(plan_runner):
  "Test module resources."
  _, resources = plan_runner()
  assert sorted(r['type'] for r in resources) == [
      'google_kms_crypto_key',
      'google_kms_crypto_key',
      'google_kms_crypto_key',
      'google_kms_crypto_key_iam_binding',
      'google_kms_key_ring',
      'google_kms_key_ring_iam_binding'
  ]
