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
import json
import logging
import time
import warnings

import click
import google.auth

from google.auth.transport.requests import AuthorizedSession

BASE = 'custom.googleapis.com/quota/'
BATCH_SIZE = 5
HTTP = AuthorizedSession(google.auth.default()[0])
HTTP_HEADERS = {'content-type': 'application/json; charset=UTF-8'}
URL_PROJECT = 'https://compute.googleapis.com/compute/v1/projects/{}'
URL_REGION = 'https://compute.googleapis.com/compute/v1/projects/{}/regions/{}'

HTTPRequest = collections.namedtuple(
    'HTTPRequest', 'url data headers', defaults=[{}, {
        'content-type': 'application/json; charset=UTF-8'
    }])
Quota = collections.namedtuple('Quota', 'project region metric limit usage')


def add_series(project_id, series):
  """Write metrics series to Stackdriver.

  Args:
    project_id: series will be written to this project id's account
    series: the time series to be written, as a list of
        monitoring_v3.types.TimeSeries instances
    client: optional monitoring_v3.MetricServiceClient will be used
        instead of obtaining a new one
  """
  logging.info(f'add_series {project_id}')
  # client = client or monitoring_v3.MetricServiceClient()
  # project_name = client.common_project_path(project_id)
  # if isinstance(series, monitoring_v3.types.TimeSeries):
  #   series = [series]
  # try:
  #   client.create_time_series(name=project_name, time_series=series)
  # except GoogleAPIError as e:
  #   raise RuntimeError(f'Error from monitoring API: {e.args[0]}')


def configure_logging(verbose=True):
  """Basic logging configuration.

  Args:
    verbose: enable verbose logging
  """
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


def get_quotas(project, region='global'):
  """Fetch GCE per - project or per - region quotas from the API.

  Args:
    project: fetch global or regional quotas for this project id
    region: which quotas to fetch, 'global' or region name
    compute: optional instance of googleapiclient.discovery.build will be used
        instead of obtaining a new one
  """
  logging.info(f'fetch_quotas {project} {region}')
  if region == 'global':
    request = HTTPRequest(URL_PROJECT.format(project))
  else:
    request = HTTPRequest(URL_REGION.format(project, region))
  resp = fetch(request)
  for quota in resp.get('quotas'):
    yield Quota(project, region, **quota)


def get_series(metric_labels, value, metric_type, timestamp):
  """Create a Stackdriver monitoring time series from value and labels.

  Args:
    metric_labels: dict with labels that will be used in the time series
    value: time series value
    metric_type: which metric is this series for
    dt: datetime.datetime instance used for the series end time
  """
  logging.info(f'get_series')
  # series = monitoring_v3.types.TimeSeries()
  # series.metric.type = metric_type
  # series.resource.type = 'global'
  # for label in metric_labels:
  #   series.metric.labels[label] = metric_labels[label]
  # point = monitoring_v3.types.Point()
  # point.value.double_value = value

  # seconds = int(timestamp)
  # nanos = int((timestamp - seconds) * 10**9)
  # interval = monitoring_v3.TimeInterval(
  #     {"end_time": {
  #         "seconds": seconds,
  #         "nanos": nanos
  #     }})
  # point.interval = interval

  # series.points.append(point)
  # return series


def quota_to_series_triplet(project, region, quota):
  """Convert API quota objects to three Stackdriver monitoring time series: usage, limit and utilization

  Args:
    project: set in converted time series labels
    region: set in converted time series labels
    quota: quota object received from the GCE API
  """
  logging.info(f'quota_to_series_triplets {project} {region} {quota}')
  # labels = dict()
  # labels['project'] = project
  # labels['region'] = region

  # try:
  #   utilization = quota['usage'] / float(quota['limit'])
  # except ZeroDivisionError:
  #   utilization = 0
  # now = time.time()
  # metric_type_prefix = _METRIC_TYPE_STEM + quota['metric'].lower() + '_'
  # return [
  #     _get_series(labels, quota['usage'], metric_type_prefix + _USAGE, now),
  #     _get_series(labels, quota['limit'], metric_type_prefix + _LIMIT, now),
  #     _get_series(labels, utilization, metric_type_prefix + _UTILIZATION, now),
  # ]


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
@click.option('--verbose', is_flag=True, help='Verbose output.')
def main_cli(project_id=None, project_ids=None, regions=None, filters=None,
             verbose=False):
  """Fetch GCE quotas and writes them as custom metrics to Stackdriver.

  If filters are specified as arguments, only quotas matching one of the
  filters will be stored in Stackdriver.
  """
  try:
    _main(project_id, project_ids, regions, filters, verbose)
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
          keywords=None, verbose=False):
  """Module entry point used by cli and cloud function wrappers."""
  configure_logging(verbose=verbose)
  gce_projects = gce_projects or [monitoring_project]
  gce_regions = gce_regions or ['global']
  keywords = set(keywords or [])
  logging.debug(f'monitoring project {monitoring_project}')
  logging.debug(f'projects {gce_projects}, regions {gce_regions}')
  logging.debug(f'keywords {keywords}')
  quotas = []
  for project in gce_projects:
    for region in gce_regions:
      for quota in get_quotas(project, region):
        if keywords and not any(k in quota['metric'] for k in keywords):
          continue
        logging.debug(f'quota {quota}')
        quotas.append((project, region, quota))


if __name__ == '__main__':
  main_cli()
