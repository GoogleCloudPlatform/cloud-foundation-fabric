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

from google.api import label_pb2 as ga_label
from google.api import metric_pb2 as ga_metric
from google.api.metric_pb2 import MetricDescriptor
from google.cloud import monitoring_v3
from monitoring.utility import create_custom_metric, get_custom_metric

import time
import socket
import click
import logging
import concurrent.futures

# Set the log level
logging.basicConfig(level=logging.INFO)
LOGGER = logging.getLogger(__name__)

client = monitoring_v3.MetricServiceClient()

ENDPOINT_UPTIME_METRIC = "endpoint_uptime_check_passed"
ENDPOINT_LATENCY = "endpoint_latency"


class UptimeCheckResult:
    """A class to represent the result of an uptime check."""

    def __init__(self, host: str, port: int, latency: int, reachable: bool):
        """Initializes a new UptimeCheckResult object.

        Args:
          host: The endpoint that was checked.
          port: The port that was checked.
          latency: The latency of the check in milliseconds.
          reachable: Whether or not the endpoint was reachable.
        """
        self.host = host
        self.port = port
        self.latency = latency
        self.reachable = reachable

    def __str__(self):
        """Returns a string representation of the UptimeCheckResult object."""
        return f"UptimeCheckResult(endpoint={self.endpoint}, port={self.port}, latency={self.latency}, reachable={self.reachable})"


def check_host_connectivity(timeout: int, host: str, port: int) -> UptimeCheckResult:
    """Checks the connectivity to a given host and port.

    Args:
      timeout: Seconds to wait for the connection to be established
      host: The hostname or IP address of the host to check.
      port: The port number to check.

    Returns:
      An UptimeCheckResult object representing the result of the check.
    """

    start_time = time.perf_counter_ns()
    try:
        socket.create_connection((host, port), timeout).close()
        latency = (time.perf_counter_ns() - start_time) // 1000000
        return UptimeCheckResult(host=host, port=port, latency=latency, reachable=True)
    except socket.error:
        return UptimeCheckResult(host=host, port=port, latency=-1, reachable=False)


def write_uptime_check_results_to_monitoring(
      project: str, agent_vm: str, uptime_check_result: UptimeCheckResult
) -> None:
    """Writes the results of an uptime check to Google Cloud Monitoring.

    Args:
      project: The Google Cloud project ID.
      agent_vm: The name of the VM that performed the uptime check.
      uptime_check_result: An UptimeCheckResult object representing the result of the check.
    """
    time_series = []

    now = time.time()
    seconds = int(now)
    nanos = int((now - seconds) * 10 ** 9)
    interval = monitoring_v3.TimeInterval(
          {"end_time": {"seconds": seconds, "nanos": nanos}}
    )

    uptime_check_series = monitoring_v3.TimeSeries()
    uptime_check_series.metric.type = f"custom.googleapis.com/{ENDPOINT_UPTIME_METRIC}"
    uptime_check_series.resource.type = "global"
    uptime_check_series.metric.labels[
        "endpoint"] = f"{uptime_check_result.host}:{uptime_check_result.port}"
    uptime_check_series.metric.labels["agent_vm"] = agent_vm
    uptime_point = monitoring_v3.Point(
          {"interval": interval, "value": {"bool_value": uptime_check_result.reachable}})
    uptime_check_series.points = [uptime_point]
    time_series.append(uptime_check_series)

    if uptime_check_result.reachable:
        latency_series = monitoring_v3.TimeSeries()
        latency_series.metric.type = f"custom.googleapis.com/{ENDPOINT_LATENCY}"
        latency_series.resource.type = "global"
        latency_series.metric.labels[
            "endpoint"] = f"{uptime_check_result.host}:{uptime_check_result.port}"
        latency_series.metric.labels["agent_vm"] = agent_vm
        latency_point = monitoring_v3.Point(
              {"interval": interval, "value": {"int64_value": uptime_check_result.latency}})
        latency_series.points = [latency_point]
        time_series.append(latency_series)

    try:
        client.create_time_series(name=f"projects/{project}", time_series=time_series)
    except Exception as e:
        LOGGER.error(f"Failed to write time series data: {e}")


@click.command()
@click.option('--project', '-p', type=str, required=True, help='Target GCP project id for metrics.')
@click.option('--endpoint', type=(str, int), multiple=True,
              help='Endpoints to test as ip port whitespace separated, this is a repeatable arg.')
@click.option('--agent', type=str, required=True, help='Agent VM running the script')
@click.option('--debug', is_flag=True, default=False,
              help='Turn on debug logging.')
@click.option('--interval', type=int, default=10, help='Time interval between checks in seconds.')
@click.option('--timeout', type=int, default=10,
              help='Timeout waiting for connection to be established.')
def main(project: str, endpoint: list, agent: str, debug: bool, interval: int, timeout: int):
    logging.basicConfig(level=logging.INFO if not debug else logging.DEBUG)

    while True:
        # Create a list of futures to represent the concurrent tasks.
        with concurrent.futures.ThreadPoolExecutor() as executor:
            futures = {executor.submit(check_host_connectivity, timeout, host, port) for
                       (host, port) in endpoint}

        # Wait for all the tasks to finish.
        try:
            for future in concurrent.futures.as_completed(futures):
                uptime_check_result = future.result()
                write_uptime_check_results_to_monitoring(project=project, agent_vm=agent,
                                                         uptime_check_result=uptime_check_result)
        except Exception as e:
            LOGGER.error(f"Failed to write time series data: {e}")
        time.sleep(interval)


if __name__ == "__main__":
    main()
