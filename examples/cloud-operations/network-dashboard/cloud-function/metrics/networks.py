from code import interact
from collections import defaultdict
from google.protobuf import field_mask_pb2
from google.cloud import asset_v1

def get_subnet_ranges_dict(config: dict):
  '''
    Calls the Asset Inventory API to get all Subnet ranges under the GCP organization.

      Parameters:
        client (asset_v1.AssetServiceClient): assets client
        organizationID (_type_): Organization ID
      Returns:
        subnet_range_dict (dictionary of string: int): Keys are the network links and values are the number of subnet ranges per network.
  '''

  subnet_range_dict = defaultdict(int)
  read_mask = field_mask_pb2.FieldMask()
  read_mask.FromJsonString('name,versionedResources')

  response = config["clients"]["asset_client"].search_all_resources(
      request={
          "scope": f"organizations/{config['organization']}",
          "asset_types": ["compute.googleapis.com/Subnetwork"],
          "read_mask": read_mask,
      })
  for resource in response:
    ranges = 0
    network_link = None

    for versioned in resource.versioned_resources:
      for field_name, field_value in versioned.resource.items():
        if field_name == "network":
          network_link = field_value
          ranges += 1
        if field_name == "secondaryIpRanges":
          for range in field_value:
            ranges += 1

    if network_link in subnet_range_dict:
      subnet_range_dict[network_link] += ranges
    else:
      subnet_range_dict[network_link] = ranges

  return subnet_range_dict
