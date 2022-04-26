def get_ppg(network_link, limit_dict):
  '''
    Checks if this network has a specific limit for a metric, if so, returns that limit, if not, returns the default limit.

      Parameters:
        network_link (string): VPC network link.
        limit_list (list of string): Used to get the limit per VPC or the default limit.
      Returns:
        limit_dict (dictionary of string:int): Dictionary with the network link as key and the limit as value
  '''
  if network_link in limit_dict:
    return limit_dict[network_link]
  else:
    if 'default_value' in limit_dict:
      return limit_dict['default_value']
    else:
      print(f"Error: limit not found for {network_link}")
      return 0
