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

from distutils.command.config import config
import os
import time
from google.cloud import monitoring_v3, asset_v1
from google.protobuf import field_mask_pb2
from googleapiclient import discovery
from metrics import ilb_fwrules, instances, networks, metrics, limits, peerings, routes, subnets


def get_monitored_projects_list(config):
  '''
    Gets the projects to be monitored from the MONITORED_FOLDERS_LIST environment variable.

      Parameters:
        config (dict): The dict containing config like clients and limits
      Returns:
        monitored_projects (List of strings): Full list of projects to be monitored
    '''
  monitored_projects = config["monitored_projects"]
  monitored_folders = os.environ.get("MONITORED_FOLDERS_LIST").split(",")

  # Handling empty monitored folders list
  if monitored_folders == ['']:
    monitored_folders = []

  # Gets all projects under each monitored folder (and even in sub folders)
  for folder in monitored_folders:
    read_mask = field_mask_pb2.FieldMask()
    read_mask.FromJsonString('name,versionedResources')

    response = config["clients"]["asset_client"].search_all_resources(
        request={
            "scope": f"folders/{folder}",
            "asset_types": ["cloudresourcemanager.googleapis.com/Project"],
            "read_mask": read_mask
        })

    for resource in response:
      for versioned in resource.versioned_resources:
        for field_name, field_value in versioned.resource.items():
          if field_name == "projectId":
            project_id = field_value
            # Avoid duplicate
            if project_id not in monitored_projects:
              monitored_projects.append(project_id)

  print("List of projects to be monitored:")
  print(monitored_projects)

  return monitored_projects


def monitoring_interval():
  '''
  Creates the monitoring interval of 24 hours
    Returns:
      monitoring_v3.TimeInterval: Monitoring time interval of 24h
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
    "organization":
        os.environ.get("ORGANIZATION_ID"),
    # list of projects from which function will get quotas information
    "monitored_projects":
        os.environ.get("MONITORED_PROJECTS_LIST").split(","),
    "monitoring_project_link":
        os.environ.get('MONITORING_PROJECT_ID'),
    "monitoring_project_link":
        f"projects/{os.environ.get('MONITORING_PROJECT_ID')}",
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
    },
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
  # Handling empty monitored projects list
  if config["monitored_projects"] == ['']:
    config["monitored_projects"] = []

  # Gets projects and folders to be monitored
  config["monitored_projects"] = get_monitored_projects_list(config)

  # Keep the monitoring interval up2date during each run
  config["monitoring_interval"] = monitoring_interval()

  metrics_dict, limits_dict = metrics.create_metrics(
      config["monitoring_project_link"])

  # IP utilization subnet level metrics
  subnets.get_subnets(config, metrics_dict)

  # Asset inventory queries
  gce_instance_dict = instances.get_gce_instance_dict(config)
  l4_forwarding_rules_dict = ilb_fwrules.get_forwarding_rules_dict(config, "L4")
  l7_forwarding_rules_dict = ilb_fwrules.get_forwarding_rules_dict(config, "L7")
  subnet_range_dict = networks.get_subnet_ranges_dict(config)

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
      limits_dict['dynamic_routes_per_peering_group_limit'])

  return 'Function executed successfully'


if __name__ == "__main__":
  main(None, None)
