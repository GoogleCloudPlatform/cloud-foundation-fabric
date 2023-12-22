#!/usr/bin/env python3
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

from google.cloud import monitoring_v3
import time
import datetime
import socket
import click
import logging
import concurrent.futures
from monitoring.utility import batched
from monitoring.utility import write_timeseries

# Set the log level
logging.basicConfig(level=logging.INFO)
LOGGER = logging.getLogger(__name__)

client = monitoring_v3.MetricServiceClient()

ENDPOINT_UPTIME_METRIC = "endpoint_uptime_check_passed"
ENDPOINT_LATENCY = "endpoint_latency"


class UptimeCheckResult:
  """A class to represent the result of an uptime check."""

  def __init__(self, host: str, port: int, reachable: bool,
               tstamp: datetime = None, latency: int = -1):
    """Initializes a new UptimeCheckResult object.

        Args:
          host: The endpoint that was checked.
          port: The port that was checked.
          latency: The latency of the check in milliseconds.
          reachable: Whether or not the endpoint was reachable.
        """
    self.tstamp = tstamp
    self.host = host
    self.port = port
    self.latency = latency
    self.reachable = reachable

  def _api_format(self, project: str, agent_vm: str, name: str):
    d = {
        'metric': {
            'type': f'custom.googleapis.com/{name}',
            'labels': {
                'agent_vm': agent_vm,
                'endpoint': f'{self.host}:{self.port}'
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

    if name == ENDPOINT_UPTIME_METRIC:
      d['valueType'] = 'BOOL'
      d['points'][0]['value'] = {'boolValue': self.reachable}
    else:
      d['valueType'] = 'INT64'
      d['points'][0]['value'] = {'int64Value': self.latency}

    return d

  def timeseries(self, project: str, agent_vm: str):
    yield self._api_format(project=project, agent_vm=agent_vm,
                           name=ENDPOINT_UPTIME_METRIC)
    yield self._api_format(project=project, agent_vm=agent_vm,
                           name=ENDPOINT_LATENCY)


def check_host_connectivity(timeout: int, host: str,
                            port: int) -> UptimeCheckResult:
  """Checks the connectivity to a given host and port.

    Args:
      timeout: Seconds to wait for the connection to be established
      host: The hostname or IP address of the host to check.
      port: The port number to check.

    Returns:
      An UptimeCheckResult object representing the result of the check.
    """
  start_time = time.perf_counter_ns()
  result = UptimeCheckResult(host=host, port=port, reachable=True)
  try:
    socket.create_connection((host, port), timeout).close()
    latency = (time.perf_counter_ns() - start_time) // 1000000
    result.latency = latency
  except socket.error:
    result.reachable = False
  finally:
    result.tstamp = datetime.datetime.utcnow()
    return result


@click.command()
@click.option('--project', '-p', type=str, required=True,
              help='Target GCP project id for metrics.')
@click.option(
    '--endpoint', type=(str, int), multiple=True, help=
    'Endpoints to test as ip port whitespace separated, this is a repeatable arg.'
)
@click.option('--agent', type=str, required=True,
              help='Agent VM running the script')
@click.option('--debug', is_flag=True, default=False,
              help='Turn on debug logging.')
@click.option('--interval', type=int, default=10,
              help='Time interval between checks in seconds.')
@click.option('--timeout', type=int, default=10,
              help='Timeout waiting for connection to be established.')
def main(project: str, endpoint: list, agent: str, debug: bool, interval: int,
         timeout: int):
  logging.basicConfig(level=logging.INFO if not debug else logging.DEBUG)

  while True:
    # Create a list of futures to represent the concurrent tasks.
    with concurrent.futures.ThreadPoolExecutor() as executor:
      futures = {
          executor.submit(check_host_connectivity, timeout, host, port)
          for (host, port) in endpoint
      }

    # Wait for all the tasks to finish.
    try:
      timeseries = []
      for future in concurrent.futures.as_completed(futures):
        uptime_result = future.result()
        timeseries += uptime_result.timeseries(project=project, agent_vm=agent)
      i, l = 0, len(timeseries)
      for batch in batched(timeseries, 30):
        data = list(batch)
        logging.info(f'sending {len(batch)} timeseries out of {l - i}/{l} left')
        i += len(batch)
        write_timeseries(project, {'timeSeries': list(data)})
        if debug:
          print(data)
      logging.info(f'{l} timeseries done (debug {debug})')
    except Exception as e:
      LOGGER.error(f"Failed to write time series data: {e}")
    time.sleep(interval)


if __name__ == "__main__":
  main()
