from google.protobuf import field_mask_pb2

def get_routers(config):
  '''
    Returns a dictionary of all Cloud Routers in the GCP organization.

      Parameters:
        None
      Returns:
        routers_dict (dictionary of string: list of string): Key is the network link and value is a list of router links.
  '''

  read_mask = field_mask_pb2.FieldMask()
  read_mask.FromJsonString('name,versionedResources')

  routers_dict = {}

  response = config["clients"]["asset_client"].search_all_resources(
      request={
          "scope": f"organizations/{config['organization']}",
          "asset_types": ["compute.googleapis.com/Router"],
          "read_mask": read_mask,
      })
  for resource in response:
    network_link = None
    router_link = None
    for versioned in resource.versioned_resources:
      for field_name, field_value in versioned.resource.items():
        if field_name == "network":
          network_link = field_value
        if field_name == "selfLink":
          router_link = field_value

    if network_link in routers_dict:
      routers_dict[network_link].append(router_link)
    else:
      routers_dict[network_link] = [router_link]

  return routers_dict
