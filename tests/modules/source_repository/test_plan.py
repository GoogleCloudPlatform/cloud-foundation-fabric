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


def test_resource_count(plan_runner):
  'Test number of resources created.'
  _, resources = plan_runner()
  assert len(resources) == 1


def test_iam(plan_runner):
  'Test IAM binding resources.'
  group_iam = '{"fooers@example.org"=["roles/owner"]}'
  iam = '''{
    "roles/editor" = ["user:a@example.org", "user:b@example.org"]
    "roles/owner" = ["user:c@example.org"]
  }'''
  _, resources = plan_runner(group_iam=group_iam, iam=iam)
  bindings = {
      r['values']['role']: r['values']['members']
      for r in resources
      if r['type'] == 'google_sourcerepo_repository_iam_binding'
  }
  assert bindings == {
      'roles/editor': ['user:a@example.org', 'user:b@example.org'],
      'roles/owner': ['group:fooers@example.org', 'user:c@example.org']
  }


def test_triggers(plan_runner):
  'Test trigger resources.'
  triggers = '''{
    foo = {
      filename = "ci/foo.yaml"
      included_files = ["**/*yaml"]
      service_account = null
      substitutions = null
      template = {
        branch_name = null
        project_id = null
        tag_name = "foo"
      }
    }
  }'''
  _, resources = plan_runner(triggers=triggers)
  triggers = [
      r['index'] for r in resources if r['type'] == 'google_cloudbuild_trigger'
  ]
  assert triggers == ['foo']