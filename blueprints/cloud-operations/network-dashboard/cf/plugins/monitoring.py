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

import datetime
import json
import logging

from . import HTTPRequest
from .utils import batched

DESCRIPTOR_TYPE_BASE = 'custom.googleapis.com/{}'
DESCRIPTOR_URL = ('https://content-monitoring.googleapis.com/v3'
                  '/projects/{}/metricDescriptors?alt=json')
HEADERS = {'content-type': 'application/json'}
LOGGER = logging.getLogger('net-dash.plugins.monitoring')
TIMESERIES_URL = ('https://content-monitoring.googleapis.com/v3'
                  '/projects/{}/timeSeries?alt=json')


def descriptor_requests(project_id, root, existing, computed):
  type_base = DESCRIPTOR_TYPE_BASE.format(root)
  url = DESCRIPTOR_URL.format(project_id)
  for descriptor in computed:
    d_type = f'{type_base}{descriptor.type}'
    if d_type in existing:
      continue
    LOGGER.info(f'creating descriptor {d_type}')
    if descriptor.is_ratio:
      unit = '10^2.%'
      value_type = 'DOUBLE'
    else:
      unit = '1'
      value_type = 'INT64'
    data = json.dumps({
        'type': d_type,
        'displayName': descriptor.name,
        'metricKind': 'GAUGE',
        'valueType': value_type,
        'unit': unit,
        'labels': [{
            'key': l,
            'valueType': 'STRING'
        } for l in descriptor.labels]
    })
    yield HTTPRequest(url, HEADERS, data)


def timeseries_requests(project_id, root, timeseries):
  end_time = ''.join((datetime.datetime.utcnow().isoformat('T'), 'Z'))
  type_base = DESCRIPTOR_TYPE_BASE.format(root)
  url = TIMESERIES_URL.format(project_id)
  # TODO: bucketize per metric type
  for batch in batched(timeseries, 190):
    data = {'timeSeries': []}
    for ts in batch:
      pv = 'int64Value' if isinstance(ts.value, int) else 'doubleValue'
      data['timeSeries'].append({
          'metric': {
              'type': f'{type_base}{ts.metric}',
              'labels': ts.labels
          },
          'resource': {
              'type': 'global'
          },
          'points': [{
              'interval': {
                  'endTime': end_time
              },
              'value': {
                  pv: ts.value
              }
          }]
      })
    yield HTTPRequest(url, HEADERS, json.dumps(data))
