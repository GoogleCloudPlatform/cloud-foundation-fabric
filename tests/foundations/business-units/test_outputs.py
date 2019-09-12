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

"Test root module outputs."


def test_project_ids(plan):
  "Project ids should use prefix and match expected values."
  prefix = plan.variables['prefix']
  assert plan.outputs['audit_logs_project'] == '%s-audit' % prefix
  assert plan.outputs['shared_resources_project'] == '%s-shared' % prefix
  assert plan.outputs['terraform_project'] == '%s-terraform' % prefix


def test_bucket_names(plan):
  "GCS bucket names should use prefix and location and match expected values."
  location = plan.variables['gcs_location'].lower()
  prefix = plan.variables['prefix']
  bootstrap_bucket = plan.outputs['bootstrap_tf_gcs_bucket']
  assert bootstrap_bucket.startswith(prefix)
  assert bootstrap_bucket.endswith('tf-bootstrap')
  assert '-%s-' % location in bootstrap_bucket


def test_environment_buckets(plan):
  "One GCS bucket should be created for each environment."
  buckets = plan.outputs['environment_tf_gcs_buckets']
  for environment in plan.variables['environments']:
    assert environment in buckets
    assert buckets[environment].endswith(environment)


def test_bq_dataset(plan):
  "Bigquery dataset name should be based on root node type and id."
  node_type, node_id = plan.variables['root_node'].split('/')
  assert plan.outputs['audit_logs_bq_dataset'] == 'logs_audit_%s_%s' % (
      node_type[:-1], node_id)
