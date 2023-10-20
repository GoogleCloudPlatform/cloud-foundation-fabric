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

# def test_service_encryption_key_dependencies(plan_runner):
#   "Test service encryption keys with dependencies."
#   _, resources = plan_runner(service_encryption_key_ids=(
#       '{compute=["key1"], dataflow=["key1", "key2"]}'))
#   key_bindings = [
#       r['index']
#       for r in resources
#       if r['type'] == 'google_kms_crypto_key_iam_member'
#   ]
#   assert len(key_bindings), 3
#   # compute.key1 cannot repeat or we'll get a duplicate key error in for_each
#   assert key_bindings == [
#       'compute.key1', 'compute.key2', 'dataflow.key1', 'dataflow.key2'
#   ]
