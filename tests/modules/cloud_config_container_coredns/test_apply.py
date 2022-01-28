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
  yaml.safe_load(cloud_config)
  assert cloud_config.startswith('#cloud-config')
  assert re.findall(r'(?m)^\s+\-\s*path:\s*(\S+)', cloud_config) == [
      '/var/lib/docker/daemon.json', '/etc/systemd/resolved.conf',
      '/etc/coredns/Corefile', '/etc/systemd/system/coredns.service'
  ]
