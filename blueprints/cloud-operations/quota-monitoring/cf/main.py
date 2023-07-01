#! /usr/bin/env python3
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
"""Sync GCE quota usage to Stackdriver for multiple projects.

This tool fetches global and/or regional quotas from the GCE API for
multiple projects, and sends them to Stackdriver as custom metrics, where they
can be used to set alert policies or create charts.
"""

import base64
import collections
import datetime
import itertools
import json
import logging
import warnings

import click
import google.auth

from google.auth.transport.requests import AuthorizedSession

BASE = 'custom.googleapis.com/quota'
BATCH_SIZE = 5
HTTP = AuthorizedSession(google.auth.default()[0])
HTTP_HEADERS = {'content-type': 'application/json; charset=UTF-8'}
URL_PROJECT = 'https://compute.googleapis.com/compute/v1/projects/{}'
URL_REGION = 'https://compute.googleapis.com/compute/v1/projects/{}/regions/{}'
URL_TS = 'https://monitoring.googleapis.com/v3/projects/{}/timeSeries'

_Quota = collections.namedtuple('_Quota',
                                'project region tstamp metric limit usage')
HTTPRequest = collections.namedtuple(
    'HTTPRequest', 'url data headers', defaults=[{}, {
        'content-type': 'application/json; charset=UTF-8'
    }])


class Quota(_Quota):
  'Compute quota.'

  def _api_format(self, name, value):
    'Return a specific timeseries for this quota in API format.'
    d = {
        'metric': {
            'type': f'{BASE}/{self.metric.lower()}/{name}',
            'labels': {
                'location': self.region
            }
        },
        'resource': {
            'type': 'global',
            'labels': {
                'project_id': self.project,
            }
        },
        'metricKind':
            'GAUGE',
        'points': [{
            'interval': {
                'endTime': f'{self.tstamp.isoformat("T")}Z'
            },
            'value': {}
        }]
    }
    if name == 'ratio':
      d['valueType'] = 'DOUBLE'
      d['points'][0]['value'] = {'doubleValue': value}
    else:
      d['valueType'] = 'INT64'
      d['points'][0]['value'] = {'int64Value': value}
    return d

  @property
  def timeseries(self):
    try:
      ratio = self.usage / float(self.limit)
    except ZeroDivisionError:
      ratio = 0
    yield self._api_format('ratio', ratio)
    yield self._api_format('usage', self.usage)
    yield self._api_format('limit', self.limit)


def batched(iterable, n):
  'Batches data into lists of length n. The last batch may be shorter.'
  # batched('ABCDEFG', 3) --> ABC DEF G
  if n < 1:
    raise ValueError('n must be at least one')
  it = iter(iterable)
  while (batch := list(itertools.islice(it, n))):
    yield batch


def configure_logging(verbose=True):
  'Basic logging configuration.'
  level = logging.DEBUG if verbose else logging.INFO
  logging.basicConfig(level=level)
  warnings.filterwarnings('ignore', r'.*end user credentials.*', UserWarning)


def fetch(request, delete=False):
  'Minimal HTTP client interface for API calls.'
  logging.debug(f'fetch {"POST" if request.data else "GET"} {request.url}')
  try:
    if delete:
      response = HTTP.delete(request.url, headers=request.headers)
    elif not request.data:
      response = HTTP.get(request.url, headers=request.headers)
    else:
      response = HTTP.post(request.url, headers=request.headers,
                           data=json.dumps(request.data))
  except google.auth.exceptions.RefreshError as e:
    raise SystemExit(e.args[0])
  if response.status_code != 200:
    logging.critical(
        f'response code {response.status_code} for URL {request.url}')
    logging.critical(response.content)
    logging.debug(request.data)
    raise SystemExit(1)
  return json.loads(response.content)


def write_timeseries(project, data):
  'Sends timeseries to the API.'
  # try
  logging.debug(f'write {len(data["timeSeries"])} timeseries')
  try:
    response = HTTP.post(URL_TS.format(project), headers=HTTP_HEADERS,
                         data=json.dumps(data))
  except google.auth.exceptions.RefreshError as e:
    raise SystemExit(e.args[0])
  if response.status_code != 200:
    logging.critical(
        f'response code {response.status_code} for URL {response.request.url}')
    logging.critical(response.content.decode('utf8'))
    logging.debug(data)
    raise SystemExit(1)
  return json.loads(response.content)


def get_quotas(project, region='global'):
  'Fetch GCE per - project or per - region quotas from the API.'
  if region == 'global':
    request = HTTPRequest(URL_PROJECT.format(project))
  else:
    request = HTTPRequest(URL_REGION.format(project, region))
  resp = fetch(request)
  for quota in resp.get('quotas'):
    yield Quota(project, region, datetime.datetime.utcnow(), **quota)


@click.command()
@click.argument('project-id', required=True)
@click.option(
    '--project-ids', multiple=True, help=
    'Project ids to monitor (multiple). Defaults to monitoring project if not set.'
)
@click.option('--regions', multiple=True,
              help='Regions (multiple). Defaults to "global" if not set.')
@click.option('--filters', multiple=True,
              help='Filter by quota name (multiple).')
@click.option('--dry-run', is_flag=True, help='Do not write metrics.')
@click.option('--verbose', is_flag=True, help='Verbose output.')
def main_cli(project_id=None, project_ids=None, regions=None, filters=None,
             dry_run=False, verbose=False):
  'Fetch GCE quotas and writes them as custom metrics to Stackdriver.'
  try:
    _main(project_id, project_ids, regions, filters, dry_run, verbose)
  except RuntimeError as e:
    logging.exception(f'exception raised: {e.args[0]}')


def main(event, context):
  """Cloud Function entry point."""
  try:
    data = json.loads(base64.b64decode(event['data']).decode('utf-8'))
    _main(**data)
  except RuntimeError:
    raise


def _main(monitoring_project, gce_projects=None, gce_regions=None,
          keywords=None, dry_run=False, verbose=False):
  """Module entry point used by cli and cloud function wrappers."""
  configure_logging(verbose=verbose)
  gce_projects = gce_projects or [monitoring_project]
  gce_regions = gce_regions or ['global']
  keywords = set(keywords or [])
  logging.debug(f'monitoring project {monitoring_project}')
  logging.debug(f'projects {gce_projects}, regions {gce_regions}')
  logging.debug(f'keywords {keywords}')
  timeseries = []
  logging.info(
      f'get quotas ({len(gce_projects)} project {len(gce_regions)} regions)')
  for project in gce_projects:
    for region in gce_regions:
      logging.info(f'get quota for {project} in {region}')
      for quota in get_quotas(project, region):
        if keywords and not any(k in quota.metric for k in keywords):
          continue
        logging.debug(f'quota {quota}')
        timeseries += list(quota.timeseries)
  logging.info(f'{len(timeseries)} timeseries')
  if dry_run:
    from icecream import ic
  for batch in batched(timeseries, 30):
    data = list(batch)
    logging.info(f'sending {len(batch)} timeseries')
    if not dry_run:
      write_timeseries(project, {'timeSeries': list(data)})
    else:
      ic(data)
  logging.info(f'{len(timeseries)} timeseries done (dry run {dry_run})')


if __name__ == '__main__':
  main_cli()
