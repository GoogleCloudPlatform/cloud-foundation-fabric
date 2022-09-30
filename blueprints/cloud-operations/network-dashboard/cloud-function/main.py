#
# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

from code import interact
from distutils.command.config import config
import os
from pickletools import int4
import time
from google.cloud import monitoring_v3, asset_v1
from google.protobuf import field_mask_pb2
from googleapiclient import discovery
from metrics import ilb_fwrules, instances, networks, metrics, limits, peerings, routes, vpc_firewalls


def monitoring_interval():
  '''
  Creates the monitoring interval of 24 hours

    Returns:
      monitoring_v3.TimeInterval: Moinitoring time interval of 24h
  '''
  now = time.time()
  seconds = int(now)
  nanos = int((now - seconds) * 10**9)
  return monitoring_v3.TimeInterval({
      "end_time": {
          "seconds": seconds,
          "nanos": nanos
      },
      "start_time": {
          "seconds": (seconds - 24 * 60 * 60),
          "nanos": nanos
      },
  })


config = {
    # Organization ID containing the projects to be monitored
    "organization":  #os.environ.get("ORGANIZATION_ID"),
        '34855741773',
    # list of projects from which function will get quotas information
    "monitored_projects":  #os.environ.get("MONITORED_PROJECTS_LIST").split(","),
        [
            "mnoseda-prod-net-landing-0", "mnoseda-prod-net-spoke-0",
            "mnoseda-dev-net-spoke-0"
        ],
    "monitoring_project":  #os.environ.get('MONITORING_PROJECT_ID'),
        "monitoring-tlc",
    "monitoring_project_link":  #f"projects/{os.environ.get('MONITORING_PROJECT_ID')}",
        f"projects/monitoring-tlc",
    "monitoring_interval":
        monitoring_interval(),
    "limit_names": {
        "GCE_INSTANCES":
            "compute.googleapis.com/quota/instances_per_vpc_network/limit",
        "L4":
            "compute.googleapis.com/quota/internal_lb_forwarding_rules_per_vpc_network/limit",
        "L7":
            "compute.googleapis.com/quota/internal_managed_forwarding_rules_per_vpc_network/limit",
        "SUBNET_RANGES":
            "compute.googleapis.com/quota/subnet_ranges_per_vpc_network/limit"
    },
    "lb_scheme": {
        "L7": "INTERNAL_MANAGED",
        "L4": "INTERNAL"
    },
    "clients": {
        "discovery_client": discovery.build('compute', 'v1'),
        "asset_client": asset_v1.AssetServiceClient(),
        "monitoring_client": monitoring_v3.MetricServiceClient()
    }
}


def main(event, context):
  '''
    Cloud Function Entry point, called by the scheduler.

      Parameters:
        event: Not used for now (Pubsub trigger)
        context: Not used for now (Pubsub trigger)
      Returns:
        'Function executed successfully'
  '''

  # Keep the monitoring interval up2date during each run
  config["monitoring_interval"] = monitoring_interval()

  metrics_dict, limits_dict = metrics.create_metrics(
      config["monitoring_project_link"])
  project_quotas_dict = limits.get_quota_project_limit(config)

  firewalls_dict = vpc_firewalls.get_firewalls_dict(config)

  # Asset inventory queries
  gce_instance_dict = instances.get_gce_instance_dict(config)
  l4_forwarding_rules_dict = ilb_fwrules.get_forwarding_rules_dict(config, "L4")
  l7_forwarding_rules_dict = ilb_fwrules.get_forwarding_rules_dict(config, "L7")
  subnet_range_dict = networks.get_subnet_ranges_dict(config)

  # Per Project metrics
  vpc_firewalls.get_firewalls_data(config, metrics_dict, project_quotas_dict,
                                   firewalls_dict)

  # Per Network metrics
  instances.get_gce_instances_data(config, metrics_dict, gce_instance_dict,
                                   limits_dict['number_of_instances_limit'])
  ilb_fwrules.get_forwarding_rules_data(
      config, metrics_dict, l4_forwarding_rules_dict,
      limits_dict['internal_forwarding_rules_l4_limit'], "L4")
  ilb_fwrules.get_forwarding_rules_data(
      config, metrics_dict, l7_forwarding_rules_dict,
      limits_dict['internal_forwarding_rules_l7_limit'], "L7")
  peerings.get_vpc_peering_data(config, metrics_dict,
                                limits_dict['number_of_vpc_peerings_limit'])
  dynamic_routes_dict = routes.get_dynamic_routes(
      config, metrics_dict, limits_dict['dynamic_routes_per_network_limit'])

  # Per VPC peering group metrics
  metrics.get_pgg_data(
      config,
      metrics_dict["metrics_per_peering_group"]["instance_per_peering_group"],
      gce_instance_dict, config["limit_names"]["GCE_INSTANCES"],
      limits_dict['number_of_instances_ppg_limit'])
  metrics.get_pgg_data(
      config, metrics_dict["metrics_per_peering_group"]
      ["l4_forwarding_rules_per_peering_group"], l4_forwarding_rules_dict,
      config["limit_names"]["L4"],
      limits_dict['internal_forwarding_rules_l4_ppg_limit'])
  metrics.get_pgg_data(
      config, metrics_dict["metrics_per_peering_group"]
      ["l7_forwarding_rules_per_peering_group"], l7_forwarding_rules_dict,
      config["limit_names"]["L7"],
      limits_dict['internal_forwarding_rules_l7_ppg_limit'])
  metrics.get_pgg_data(
      config, metrics_dict["metrics_per_peering_group"]
      ["subnet_ranges_per_peering_group"], subnet_range_dict,
      config["limit_names"]["SUBNET_RANGES"],
      limits_dict['number_of_subnet_IP_ranges_ppg_limit'])
  routes.get_dynamic_routes_ppg(
      config, metrics_dict["metrics_per_peering_group"]
      ["dynamic_routes_per_peering_group"], dynamic_routes_dict,
      limits_dict['number_of_subnet_IP_ranges_ppg_limit'])

  return 'Function executed successfully'


if __name__ == "__main__":
  main(None, None)
