# Copyright 2023 Google LLC
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
'Utility functions to create monitoring API requests.'

import collections
import datetime
import json
import logging
import time

from . import HTTPRequest

DESCRIPTOR_TYPE_BASE = 'custom.googleapis.com/{}'
DESCRIPTOR_URL = ('https://content-monitoring.googleapis.com/v3'
                  '/projects/{}/metricDescriptors?alt=json')
HEADERS = {'content-type': 'application/json'}
LOGGER = logging.getLogger('net-dash.plugins.monitoring')
TIMESERIES_URL = ('https://content-monitoring.googleapis.com/v3'
                  '/projects/{}/timeSeries?alt=json')


def descriptor_requests(project_id, root, existing, computed):
  'Returns create requests for missing descriptors.'
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
        'monitoredResourceTypes': ['global'],
        'labels': [{
            'key': l,
            'valueType': 'STRING'
        } for l in descriptor.labels]
    })
    yield HTTPRequest(url, HEADERS, data)


def timeseries_requests(project_id, root, timeseries, descriptors):
  'Returns create requests for timeseries.'
  descriptor_valuetypes = {d.type: d.is_ratio for d in descriptors}
  end_time = ''.join((datetime.datetime.utcnow().isoformat('T'), 'Z'))
  type_base = DESCRIPTOR_TYPE_BASE.format(root)
  url = TIMESERIES_URL.format(project_id)
  # group timeseries in buckets by their type so that multiple timeseries
  # can be grouped in a single API request without grouping duplicates types
  ts_buckets = {}
  for ts in timeseries:
    bucket = ts_buckets.setdefault(ts.metric, collections.deque())
    bucket.append(ts)
  LOGGER.info(f'metric types {list(ts_buckets.keys())}')
  ts_buckets = list(ts_buckets.values())
  api_calls, t = 0, time.time()
  while ts_buckets:
    data = {'timeSeries': []}
    for bucket in ts_buckets:
      ts = bucket.popleft()
      if descriptor_valuetypes[ts.metric]:
        pv = 'doubleValue'
      else:
        pv = 'int64Value'
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
    req_num = len(data['timeSeries'])
    tot_num = sum(len(b) for b in ts_buckets)
    LOGGER.info(f'sending {req_num} remaining: {tot_num}')
    yield HTTPRequest(url, HEADERS, json.dumps(data))
    api_calls += 1
    # Default quota is 180 request per minute per user
    if api_calls >= 170:
      td = time.time() - t
      if td < 60:
        LOGGER.info(
            f'Pausing for {round(60 - td)}s to avoid monitoring quota issues')
        time.sleep(60 - td)
      api_calls, t = 0, time.time()
    ts_buckets = [b for b in ts_buckets if b]
