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
"""Negative-control tests for FAST 2-networking VPN schema and preconditions."""

import json
from pathlib import Path
import shutil

import jsonschema
import pytest
import tftest
import yaml

_REPO_ROOT = Path(__file__).parents[4]
_STAGE_DIR = _REPO_ROOT / 'fast' / 'stages' / '2-networking'


@pytest.mark.parametrize(
    'tunnel_patch',
    [
        {
            'shared_secret': 'legacy-string'
        },
        {
            'shared_secret': {}
        },
        {
            'shared_secret': {
                'wo_version': 1
            }
        },
        {
            'shared_secret': {
                'value': 'a',
                'path': 'b'
            }
        },
        {
            'shared_secret': {
                'value': 'a',
                'write_only_version': 1
            },
        },
        {
            'deletion_policy': 'INVALID'
        },
    ],
)
def test_vpn_schema_rejects_invalid_shapes(tunnel_patch):
  schema = json.loads((_STAGE_DIR / 'schemas' / 'vpn.schema.json').read_text())
  sample = yaml.safe_load((_STAGE_DIR / 'datasets' / 'hub-and-spokes-ncc' /
                           'vpcs' / 'hub' / 'vpns' / 'onprem.yaml').read_text())
  sample['tunnels']['remote-0'].update(tunnel_patch)
  with pytest.raises(jsonschema.ValidationError):
    jsonschema.validate(instance=sample, schema=schema)


@pytest.mark.parametrize(
    'shared_secret_yaml,expected_error',
    [
        (
            'mySecret',
            'omit wo_version to avoid destroying and recreating live IPsec tunnels',
        ),
        (
            {
                'value': 'mySecret',
                'write_only_version': 1,
            },
            'contains unsupported keys; allowed keys are value, path, and wo_version',
        ),
    ],
)
def test_factory_vpns_preconditions(plan_summary, tmp_path, shared_secret_yaml,
                                    expected_error):
  ds_dir = tmp_path / 'data'
  shutil.copytree(_STAGE_DIR / 'datasets' / 'hub-and-spokes-ncc', ds_dir)
  vpn_file = ds_dir / 'vpcs' / 'hub' / 'vpns' / 'onprem.yaml'
  vpn_doc = yaml.safe_load(vpn_file.read_text())
  vpn_doc['tunnels']['remote-0']['shared_secret'] = shared_secret_yaml
  vpn_file.write_text(yaml.safe_dump(vpn_doc))

  tfvars_dir = Path(__file__).parent
  override_tfvars = tmp_path / 'override.tfvars.json'
  override_tfvars.write_text(
      json.dumps({'factories_config': {
          'dataset': str(ds_dir)
      }}))
  with pytest.raises(tftest.TerraformTestError) as exc_info:
    plan_summary(
        'fast/stages/2-networking',
        basedir=tfvars_dir,
        tf_var_files=['ncc.tfvars', str(override_tfvars)],
    )
  err_text = ' '.join(' '.join(str(a) for a in exc_info.value.args).split())
  assert expected_error in err_text
