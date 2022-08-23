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

import pytest


@pytest.fixture
def resources(plan_runner):
  _, resources = plan_runner()
  return resources


def test_resource_count(resources):
  "Test number of resources created."
  assert len(resources) == 5


def test_iam(resources):
  "Test IAM binding resources."
  bindings = [
      r['values']
      for r in resources
      if r['type'] == 'google_cloud_run_service_iam_binding'
  ]
  assert len(bindings) == 1
  assert bindings[0]['role'] == 'roles/run.invoker'


def test_audit_log_triggers(resources):
  "Test audit logs Eventarc trigger resources."
  audit_log_triggers = [
      r['values']
      for r in resources
      if r['type'] == 'google_eventarc_trigger' and
      r['name'] == 'audit_log_triggers'
  ]
  assert len(audit_log_triggers) == 1


def test_pubsub_triggers(resources):
  "Test Pub/Sub Eventarc trigger resources."
  pubsub_triggers = [
      r['values'] for r in resources if
      r['type'] == 'google_eventarc_trigger' and r['name'] == 'pubsub_triggers'
  ]
  assert len(pubsub_triggers) == 2


def test_revision_annotations(plan_runner):
  revision_annotations = '''{
    autoscaling = null
    cloudsql_instances = ["a", "b"]
    vpcaccess_connector = "foo"
    vpcaccess_egress = "all-traffic"
  }'''
  _, resources = plan_runner(revision_annotations=revision_annotations)
  r = [
      r['values'] for r in resources if r['type'] == 'google_cloud_run_service'
  ][0]
  assert r['template'][0]['metadata'][0]['annotations'] == {
      'run.googleapis.com/cloudsql-instances': 'a,b',
      'run.googleapis.com/vpc-access-connector': 'foo',
      'run.googleapis.com/vpc-access-egress': 'all-traffic'
  }


def test_revision_annotations_autoscaling(plan_runner):
  revision_annotations = '''{
    autoscaling = {max_scale = 5, min_scale = 1}
    cloudsql_instances = null
    vpcaccess_connector = null
    vpcaccess_egress = null
  }'''
  _, resources = plan_runner(revision_annotations=revision_annotations)
  r = [
      r['values'] for r in resources if r['type'] == 'google_cloud_run_service'
  ][0]
  assert r['template'][0]['metadata'][0]['annotations'] == {
      'autoscaling.knative.dev/maxScale': '5',
      'autoscaling.knative.dev/minScale': '1'
  }


def test_revision_annotations_none(resources):
  r = [
      r['values'] for r in resources if r['type'] == 'google_cloud_run_service'
  ][0]
  assert r['template'][0]['metadata'][0].get('annotations') is None


def test_vpc_connector_create(plan_runner):
  vpc_connector_create = '''{
    ip_cidr_range = "10.10.10.0/24", name = "foo", vpc_self_link = "foo-vpc"
  }'''
  _, resources = plan_runner(vpc_connector_create=vpc_connector_create)
  assert any(r['type'] == 'google_vpc_access_connector' for r in resources)
