#! /usr/bin/env python3
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
import requests.exceptions

from google.auth.transport.requests import AuthorizedSession

BASE = 'custom.googleapis.com/quota'
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
                'location': self.region,
                'project': self.project
            }
        },
        'resource': {
            'type': 'global',
            'labels': {}
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
    # remove this label if cardinality gets too high
    d['metric']['labels']['quota'] = f'{self.usage}/{self.limit}'
    return d

  @property
  def timeseries(self):
    try:
      ratio = self.usage / float(self.limit)
    except ZeroDivisionError:
      ratio = 0
    yield self._api_format('ratio', ratio)
    yield self._api_format('usage', self.usage)
    # yield self._api_format('limit', self.limit)


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
  logging.debug(request.data)
  try:
    if delete:
      response = HTTP.delete(request.url, headers=request.headers)
    elif not request.data:
      response = HTTP.get(request.url, headers=request.headers)
    else:
      response = HTTP.post(request.url, headers=request.headers,
                           data=json.dumps(request.data))
  except (google.auth.exceptions.RefreshError,
          requests.exceptions.ReadTimeout) as e:
    raise SystemExit(e.args[0])
  try:
    rdata = json.loads(response.content)
  except json.JSONDecodeError as e:
    logging.critical(e)
    raise SystemExit(f'Error decoding response: {response.content}')
  if response.status_code != 200:
    logging.critical(rdata)
    error = rdata.get('error', {})
    raise SystemExit('API error: {} (HTTP {})'.format(
        error.get('message', 'error message cannot be decoded'),
        error.get('code', 'no code found')))
  return json.loads(response.content)


def write_timeseries(project, data):
  'Sends timeseries to the API.'
  # try
  logging.debug(f'write {len(data["timeSeries"])} timeseries')
  request = HTTPRequest(URL_TS.format(project), data)
  return fetch(request)


def get_quotas(project, region='global'):
  'Fetch GCE per-project or per-region quotas from the API.'
  if region == 'global':
    request = HTTPRequest(URL_PROJECT.format(project))
  else:
    request = HTTPRequest(URL_REGION.format(project, region))
  resp = fetch(request)
  ts = datetime.datetime.utcnow()
  for quota in resp.get('quotas'):
    yield Quota(project, region, ts, **quota)


@click.command()
@click.argument('project-id', required=True)
@click.option(
    '--project-ids', multiple=True, help=
    'Project ids to monitor (multiple). Defaults to monitoring project if not set.'
)
@click.option('--regions', multiple=True,
              help='Regions (multiple). Defaults to "global" if not set.')
@click.option('--include', multiple=True,
              help='Only include quotas starting with keyword (multiple).')
@click.option('--exclude', multiple=True,
              help='Exclude quotas starting with keyword (multiple).')
@click.option('--dry-run', is_flag=True, help='Do not write metrics.')
@click.option('--verbose', is_flag=True, help='Verbose output.')
def main_cli(project_id=None, project_ids=None, regions=None, include=None,
             exclude=None, dry_run=False, verbose=False):
  'Fetch GCE quotas and writes them as custom metrics to Stackdriver.'
  try:
    _main(project_id, project_ids, regions, include, exclude, dry_run, verbose)
  except RuntimeError as e:
    logging.exception(f'exception raised: {e.args[0]}')


def main(event, context):
  """Cloud Function entry point."""
  try:
    data = json.loads(base64.b64decode(event['data']).decode('utf-8'))
    _main(**data)
  except RuntimeError:
    raise


def _main(monitoring_project, projects=None, regions=None, include=None,
          exclude=None, dry_run=False, verbose=False):
  """Module entry point used by cli and cloud function wrappers."""
  configure_logging(verbose=verbose)
  projects = projects or [monitoring_project]
  regions = regions or ['global']
  include = set(include or [])
  exclude = set(exclude or [])
  for k in ('monitoring_project', 'projects', 'regions', 'include', 'exclude'):
    logging.debug(f'{k} {locals().get(k)}')
  timeseries = []
  logging.info(f'get quotas ({len(projects)} projects {len(regions)} regions)')
  for project in projects:
    for region in regions:
      logging.info(f'get quota for {project} in {region}')
      for quota in get_quotas(project, region):
        metric = quota.metric.lower()
        if include and not any(metric.startswith(k) for k in include):
          logging.debug(f'skipping {project}:{region}:{metric} not included')
          continue
        if exclude and any(metric.startswith(k) for k in exclude):
          logging.debug(f'skipping {project}:{region}:{metric} excluded')
          continue
        logging.debug(f'quota {project}:{region}:{metric}')
        timeseries += list(quota.timeseries)
  logging.info(f'{len(timeseries)} timeseries')
  i, l = 0, len(timeseries)
  for batch in batched(timeseries, 30):
    data = list(batch)
    logging.info(f'sending {len(batch)} timeseries out of {l - i}/{l} left')
    i += len(batch)
    if not dry_run:
      write_timeseries(monitoring_project, {'timeSeries': list(data)})
    elif verbose:
      print(data)
  logging.info(f'{l} timeseries done (dry run {dry_run})')


if __name__ == '__main__':
  main_cli()
