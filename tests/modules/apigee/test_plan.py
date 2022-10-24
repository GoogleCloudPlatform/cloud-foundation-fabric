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

import collections

def test_all(plan_runner):
    "Test that creates all resources."
    _, resources = plan_runner(tf_var_file='test.all.tfvars')
    counts = collections.Counter(f'{r["type"]}.{r["name"]}' for r in resources)
    assert counts == {
        'google_apigee_organization.organization': 1,
        'google_apigee_envgroup.envgroups': 2,
        'google_apigee_environment.environments': 2,
        'google_apigee_envgroup_attachment.envgroup_attachments': 2,
        'google_apigee_instance.instances': 2,
        'google_apigee_instance_attachment.instance_attachments': 2,
        'google_apigee_environment_iam_binding.binding': 1
    }

def test_organization_only(plan_runner):
    "Test that creates only an organization."
    _, resources = plan_runner(tf_var_file='test.organization_only.tfvars')
    counts = collections.Counter(f'{r["type"]}.{r["name"]}' for r in resources)
    assert counts == {
        'google_apigee_organization.organization': 1
    }

def test_envgroup_only(plan_runner):
    "Test that creates only an environment group in an existing organization."
    _, resources = plan_runner(tf_var_file='test.envgroup_only.tfvars')
    counts = collections.Counter(f'{r["type"]}.{r["name"]}' for r in resources)
    assert counts == {
        'google_apigee_envgroup.envgroups': 1,
    }

def test_env_only(plan_runner):
    "Test that creates an environment in an existing environment group."
    _, resources = plan_runner(tf_var_file='test.env_only.tfvars')
    counts = collections.Counter(f'{r["type"]}.{r["name"]}' for r in resources)
    assert counts == {
        'google_apigee_environment.environments': 1,
        'google_apigee_envgroup_attachment.envgroup_attachments': 1,
    }

def test_instance_only(plan_runner):
    "Test that creates only an instance."
    _, resources = plan_runner(tf_var_file='test.instance_only.tfvars')
    counts = collections.Counter(f'{r["type"]}.{r["name"]}' for r in resources)
    assert counts == {
        'google_apigee_instance.instances': 1,
        'google_apigee_instance_attachment.instance_attachments': 1
    }

def test_no_instances(plan_runner):
    "Test that creates everything but the instances."
    _, resources = plan_runner(tf_var_file='test.no_instances.tfvars')
    counts = collections.Counter(f'{r["type"]}.{r["name"]}' for r in resources)
    assert counts == {
        'google_apigee_organization.organization': 1,
        'google_apigee_envgroup.envgroups': 2,
        'google_apigee_environment.environments': 2,
        'google_apigee_envgroup_attachment.envgroup_attachments': 2,
    }
