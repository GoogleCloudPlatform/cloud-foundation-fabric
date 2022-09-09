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

def test_org_policy_simple(plan_runner):
  "Test vpc with no extra options."
  org_policies = (
   '{'
   '"folders/1234567890" = {'
   '  "constraints/iam.disableServiceAccountKeyUpload" = {'
   '    rules = ['
   '       {'
   '         enforce = true,'
   '       }'
   '     ]'
   '   }'
   ' },'
   ' "organizations/1234567890" = {'
   '   "run.allowedIngress" = {'
   '     rules = ['
   '       {'
   '         allow = ["internal"],'
   '         condition = {'
   '           description= "allow ingress",'
   '           expression = "resource.matchTag(\'123456789/environment\', \'prod\')",'
   '           title = "allow-for-prod-org"'
   '         }'
   '       }'
   '     ]'
   '   }'
   ' }'
   '}'
  )
  _, resources = plan_runner(
    policies = org_policies
  )
  assert len(resources) == 2

  org_policy = [r for r in resources if r["values"]
                  ["name"].endswith('iam.disableServiceAccountKeyUpload')][0]["values"]
  assert org_policy["parent"] == "folders/1234567890"
  assert org_policy["spec"][0]["rules"][0]["enforce"] == "TRUE"


def test_org_policy_factory(plan_runner):
  "Test yaml based configuration"
  _, resources = plan_runner(
    config_directory="./policies",
  )
  assert len(resources) == 5

  org_policy = [r for r in resources if r["values"]
                  ["name"].endswith('run.allowedIngress')][0]["values"]["spec"][0]
  assert org_policy["inherit_from_parent"] == True
  assert org_policy["rules"][0]["condition"][0]["title"] == "allow-for-prod"
  assert set(org_policy["rules"][0]["values"][0]["allowed_values"]) == set(["internal"])


def test_combined_org_policy_config(plan_runner):
  "Test combined (yaml, hcl) policy configuration"
  org_policies = (
   '{'
   '"folders/3456789012" = {'
   '     "constraints/iam.disableServiceAccountKeyUpload" = {'
   '       rules = ['
   '         {'
   '             enforce = true'
   '         }'
   '       ]'
   '     }'
   '  }'
   '}'
  )
  _, resources = plan_runner(
    config_directory="./policies",
    policies = org_policies
  )

  assert len(resources) == 6
