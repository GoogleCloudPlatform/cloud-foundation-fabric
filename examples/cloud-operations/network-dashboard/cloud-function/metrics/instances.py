from code import interact
from collections import defaultdict
from google.protobuf import field_mask_pb2
from google.cloud import asset_v1
#TODO: Workaround
import main as main
from . import metrics, networks

def get_gce_instance_dict(config: dict):
  '''
  Calls the Asset Inventory API to get all GCE instances under the GCP organization.

    Parameters:
      config (dict): The config containing clients and limits

    Returns:
      gce_instance_dict (dictionary of string: int): Keys are the network links and values are the number of GCE Instances per network.
  '''

  gce_instance_dict = defaultdict(int)

  response = config["clients"]["asset_client"].search_all_resources(
      request={
          "scope": f"organizations/{config['organization']}",
          "asset_types": ["compute.googleapis.com/Instance"],
      })
  for resource in response:
    for field_name, field_value in resource.additional_attributes.items():
      if field_name == "networkInterfaceNetworks":
        for network in field_value:
          if network in gce_instance_dict:
            gce_instance_dict[network] += 1
          else:
            gce_instance_dict[network] = 1

  return gce_instance_dict


def get_gce_instances_data(config, metrics_dict, gce_instance_dict, limit_dict):
  '''
    Gets the data for GCE instances per VPC Network and writes it to the metric defined in instance_metric.

      Parameters:
        metrics_dict (dictionary of dictionary of string: string): metrics names and descriptions
        gce_instance_dict (dictionary of string: int): Keys are the network links and values are the number of GCE Instances per network.
        limit_dict (dictionary of string:int): Dictionary with the network link as key and the limit as value
      Returns:
        gce_instance_dict
  '''
  # TODO: move out
  # Existing GCP Monitoring metrics for GCE instances
  metric_instances_limit = "compute.googleapis.com/quota/instances_per_vpc_network/limit"

  for project in config["monitored_projects"]:
    network_dict = networks.get_networks(config, project)

    #TODO
    current_quota_limit = main.get_quota_current_limit(f"projects/{project}",
                                                  metric_instances_limit)
    if current_quota_limit is None:
      print(
          f"Could not write number of instances for projects/{project} due to missing quotas"
      )

    # TODO: workaround
    current_quota_limit_view = main.customize_quota_view(current_quota_limit)

    for net in network_dict:
      # TODO: workaround
      main.set_limits(net, current_quota_limit_view, limit_dict)

      usage = 0
      if net['self_link'] in gce_instance_dict:
        usage = gce_instance_dict[net['self_link']]

      metrics.write_data_to_metric(
          config,project, usage, metrics_dict["metrics_per_network"]
          ["instance_per_network"]["usage"]["name"], net['network_name'])
      metrics.write_data_to_metric(
          config, project, net['limit'], metrics_dict["metrics_per_network"]
          ["instance_per_network"]["limit"]["name"], net['network_name'])
      metrics.write_data_to_metric(
          config, project, usage / net['limit'], metrics_dict["metrics_per_network"]
          ["instance_per_network"]["utilization"]["name"], net['network_name'])

    print(f"Wrote number of instances to metric for projects/{project}")
