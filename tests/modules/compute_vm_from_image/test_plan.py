# Copyright 2021 Google LLC
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


def test_test_vm_from_image(plan_runner):
    "Test vm creation from image from images/images.yaml."
    _, resources = plan_runner(FIXTURES_DIR)
    assert len(resources) == 2
    assert set(r['type'] for r in resources) == set([
        'google_compute_instance_from_machine_image'
    ])
    vm = [r['values'] for r in resources if r['type']
          == 'google_compute_instance_from_machine_image']
    assert vm[0]['name'] == 'vm-1'
    assert vm[0]['source_machine_image'] == 'vm-image1'
    assert vm[0]['network_interface'][0]['network'] == 'vpc-region-2'
    assert vm[0]['metadata'] == {'server': 'webserver', 'team': 'dev'}
    assert vm[1]['name'] == 'vm-2'
    assert vm[1]['source_machine_image'] == 'vm-image2'
