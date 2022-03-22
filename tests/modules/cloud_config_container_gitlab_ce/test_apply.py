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

import re
import yaml


def test_defaults(apply_runner):
  "Test defalt configuration."
  _, output = apply_runner()
  cloud_config = output['cloud_config']
  assert cloud_config.startswith('#cloud-config')
  data = yaml.safe_load(cloud_config)
  files = {f['path']: f['content'] for f in data['write_files']}
  assert list(files.keys()) == [
      '/var/lib/docker/daemon.json', '/etc/systemd/system/gitlab.service'
  ]
  gitlab_unit = files['/etc/systemd/system/gitlab.service']
  assert len(re.findall('ExecStartPre', gitlab_unit)) == 3


def test_mounts(apply_runner):
  "Test defalt configuration."
  mounts = '''{
    config = { device_name = "config", fs_path = "config"}
    data = { device_name = "data", fs_path = "data"}
    logs = { device_name = null, fs_path = "logz"}
  }'''
  _, output = apply_runner(mounts=mounts)
  cloud_config = output['cloud_config']
  assert cloud_config.startswith('#cloud-config')
  data = yaml.safe_load(cloud_config)
  files = {f['path']: f['content'] for f in data['write_files']}
  assert list(files.keys()) == [
      '/var/lib/docker/daemon.json',
      '/etc/systemd/system/gitlab-disk-config.service',
      '/etc/systemd/system/gitlab-disk-data.service',
      '/etc/systemd/system/gitlab.service'
  ]
  gitlab_unit = files['/etc/systemd/system/gitlab.service']
  assert len(re.findall('ExecStartPre', gitlab_unit)) == 1
