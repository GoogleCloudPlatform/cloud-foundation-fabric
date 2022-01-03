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


import os
import pytest


FIXTURES_DIR = os.path.join(os.path.dirname(__file__), 'fixture')


def test_types(plan_runner):
  _disks = '''[{
    name = "data1"
    size = "10"
    source_type = "image"
    source = "image-1"
    options = null
  }, {
    name = "data2"
    size = "20"
    source_type = "snapshot"
    source = "snapshot-2"
    options = null
  }, {
    name = "data3"
    size = null
    source_type = "attach"
    source = "disk-3"
    options = null
  }]
  '''
  _, resources = plan_runner(FIXTURES_DIR, attached_disks=_disks)
  assert len(resources) == 3
  disks = {r['values']['name']: r['values']
           for r in resources if r['type'] == 'google_compute_disk'}
  assert disks['test-data1']['size'] == 10
  assert disks['test-data2']['size'] == 20
  assert disks['test-data1']['image'] == 'image-1'
  assert disks['test-data1']['snapshot'] is None
  assert disks['test-data2']['snapshot'] == 'snapshot-2'
  assert disks['test-data2']['image'] is None
  instance = [r['values']
              for r in resources if r['type'] == 'google_compute_instance'][0]
  instance_disks = {d['source']: d['device_name']
                    for d in instance['attached_disk']}
  assert instance_disks == {'test-data1': 'data1',
                            'test-data2': 'data2', 'disk-3': 'data3'}


def test_options(plan_runner):
  _disks = '''[{
    name = "data1"
    size = "10"
    source_type = "image"
    source = "image-1"
    options = {
      mode = null, replica_zone = null, type = "pd-standard"
    }
  }, {
    name = "data2"
    size = "20"
    source_type = null
    source = null
    options = {
      mode = null, replica_zone = "europe-west1-c", type = "pd-ssd"
    }
  }]
  '''
  _, resources = plan_runner(FIXTURES_DIR, attached_disks=_disks)
  assert len(resources) == 3
  disks_z = [r['values']
             for r in resources if r['type'] == 'google_compute_disk']
  disks_r = [r['values']
             for r in resources if r['type'] == 'google_compute_region_disk']
  assert len(disks_z) == len(disks_r) == 1
  instance = [r['values']
              for r in resources if r['type'] == 'google_compute_instance'][0]
  instance_disks = [d['device_name'] for d in instance['attached_disk']]
  assert instance_disks == ['data1', 'data2']


def test_template(plan_runner):
  _disks = '''[{
    name = "data1"
    size = "10"
    source_type = "image"
    source = "image-1"
    options = {
      mode = null, replica_zone = null, type = "pd-standard"
    }
  }, {
    name = "data2"
    size = "20"
    source_type = null
    source = null
    options = {
      mode = null, replica_zone = "europe-west1-c", type = "pd-ssd"
    }
  }]
  '''
  _, resources = plan_runner(
      FIXTURES_DIR, attached_disks=_disks, create_template="true")
  assert len(resources) == 1
  template = [r['values'] for r in resources if r['type']
              == 'google_compute_instance_template'][0]
  assert len(template['disk']) == 3
