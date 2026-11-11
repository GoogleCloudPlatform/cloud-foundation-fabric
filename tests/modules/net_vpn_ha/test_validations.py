# Copyright 2026 Google LLC
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
"""Negative-control tests for VPN tunnel variable validations."""

import json
import pytest
import tftest


@pytest.mark.parametrize(
    'tunnel_override,expected_error',
    [
        (
            {
                'shared_secret': {}
            },
            'either shared_secret.value or shared_secret.path must be non-null',
        ),
        (
            {
                'shared_secret': {
                    'wo_version': 1
                }
            },
            'either shared_secret.value or shared_secret.path must be non-null',
        ),
        (
            {
                'shared_secret': {
                    'value': 'foo',
                    'path': './secret.txt',
                }
            },
            'Only one of shared_secret.value and shared_secret.path can be set',
        ),
        (
            {
                'deletion_policy': 'INVALID'
            },
            'Tunnel deletion_policy must be one of ABANDON, DELETE, or PREVENT',
        ),
    ],
)
def test_tunnel_validations(plan_summary, tmp_path, tunnel_override,
                            expected_error):
  base_tunnel = {
      'bgp_peer': {
          'address': '169.254.1.2',
          'asn': 64514,
      },
      'bgp_session_range': '169.254.1.1/30',
      'shared_secret': {
          'value': 'mySecret'
      },
      'vpn_gateway_interface': 0,
  }
  base_tunnel.update(tunnel_override)
  override_tfvars = tmp_path / 'override.tfvars.json'
  override_tfvars.write_text(json.dumps({'tunnels': {'remote-0': base_tunnel}}))
  with pytest.raises(tftest.TerraformTestError) as exc_info:
    plan_summary(
        'modules/net-vpn-ha',
        tf_var_files=['context.tfvars', str(override_tfvars)],
    )
  err_text = ' '.join(' '.join(str(a) for a in exc_info.value.args).split())
  assert expected_error in err_text
