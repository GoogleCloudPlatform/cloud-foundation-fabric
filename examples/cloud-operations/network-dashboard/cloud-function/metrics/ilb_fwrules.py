from code import interact
from collections import defaultdict
from google.protobuf import field_mask_pb2
from . import metrics, networks, limits
import main as main

def get_forwarding_rules_dict(config, layer: str):
  '''
    Calls the Asset Inventory API to get all L4 Forwarding Rules under the GCP organization.

    Parameters:
      client (asset_v1.AssetServiceClient): assets client
      organizationID (string): Organization ID

    Returns:
      forwarding_rules_dict (dictionary of string: int): Keys are the network links and values are the number of Forwarding Rules per network.
  '''

  read_mask = field_mask_pb2.FieldMask()
  read_mask.FromJsonString('name,versionedResources')

  forwarding_rules_dict = defaultdict(int)

  # TODO: Paging?
  response = config["clients"]["asset_client"].search_all_resources(
      request={
          "scope": f"organizations/{config['organization']}",
          "asset_types": ["compute.googleapis.com/ForwardingRule"],
          "read_mask": read_mask,
      })

  for resource in response:
    internal = False
    network_link = ""
    for versioned in resource.versioned_resources:
      for field_name, field_value in versioned.resource.items():
        if field_name == "loadBalancingScheme":
          internal = (field_value == config["lb_scheme"][layer])
        if field_name == "network":
          network_link = field_value
    if internal:
      if network_link in forwarding_rules_dict:
        forwarding_rules_dict[network_link] += 1
      else:
        forwarding_rules_dict[network_link] = 1

  return forwarding_rules_dict

def get_forwarding_rules_data(config, metrics_dict, forwarding_rules_dict,
                                 limit_dict, layer):
  '''
    Gets the data for L4 Internal Forwarding Rules per VPC Network and writes it to the metric defined in forwarding_rules_metric.

      Parameters:
        metrics_dict (dictionary of dictionary of string: string): metrics names and descriptions.
        forwarding_rules_dict (dictionary of string: int): Keys are the network links and values are the number of Forwarding Rules per network.
        limit_dict (dictionary of string:int): Dictionary with the network link as key and the limit as value.
      Returns:
        None
  '''
  for project in config["monitored_projects"]:
    network_dict = networks.get_networks(config, project)

    current_quota_limit = limits.get_quota_current_limit(
        config, f"projects/{project}", config["limit_names"][layer])

    if current_quota_limit is None:
      print(
          f"Could not write {layer} forwarding rules to metric for projects/{project} due to missing quotas"
      )
      continue

    #TODO Workaround
    current_quota_limit_view = main.customize_quota_view(current_quota_limit)

    for net in network_dict:
      limits.set_limits(net, current_quota_limit_view, limit_dict)

      usage = 0
      if net['self_link'] in forwarding_rules_dict:
        usage = forwarding_rules_dict[net['self_link']]
      metrics.write_data_to_metric(
          config, project, usage, metrics_dict["metrics_per_network"]
          [f"{layer.lower()}_forwarding_rules_per_network"]["usage"]["name"],
          net['network_name'])
      metrics.write_data_to_metric(
          config, project, net['limit'], metrics_dict["metrics_per_network"]
          [f"{layer.lower()}_forwarding_rules_per_network"]["limit"]["name"],
          net['network_name'])
      metrics.write_data_to_metric(
          config, project, usage / net['limit'], metrics_dict["metrics_per_network"]
          [f"{layer.lower()}_forwarding_rules_per_network"]["utilization"]["name"],
          net['network_name'])

    print(
        f"Wrote number of {layer} forwarding rules to metric for projects/{project}")
