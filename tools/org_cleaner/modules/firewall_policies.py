import logging
from google.cloud import compute_v1

logger = logging.getLogger("default")


def delete(cai_client, organization_id, dry_run):
  """
    Delete firewall policies and their associations.

    Parameters:
        cai_client (google.cloud.asset_v1.AssetServiceClient): The Cloud Asset Inventory client.
        organization_id (str): The ID of the organization.
        dry_run (bool, optional): If True, only simulate the deletions without actually performing them. Default is False.
    """
  logger.info(f"Starting processing firewall policies")

  fw_policy_list = _list_fw_policies(cai_client, organization_id)

  fw_policy_client = compute_v1.FirewallPoliciesClient()

  logger.info(f"Retrieved {len(fw_policy_list)} policy/ies")

  for policy in fw_policy_list:
    policy_id = policy['name'].replace(
        "//compute.googleapis.com/locations/global/firewallPolicies/", "")

    for association in policy.get('associations', []):
      _delete_policy_association(
          fw_policy_client, policy_id, association, dry_run=dry_run)
    log_message = "%sDeleting firewall policy key %s." % ("(Simulated) " if dry_run else "",
                                                          policy_id)
    logger.info(log_message)

    if not dry_run:
      fw_policy_client.delete(
          request=compute_v1.DeleteFirewallPolicyRequest(
              firewall_policy=policy_id,))

  if not dry_run:
    logger.info(f"{len(fw_policy_list)} policy/ies deleted.")

  logger.info(f"Done processing firewall policies")


def _list_fw_policies(cai_client, organization_id):
  """
    List firewall policies for the specified organization.

    Parameters:
        cai_client (google.cloud.asset_v1.AssetServiceClient): The Cloud Asset Inventory client.
        organization_id (str): The ID of the organization.

    Returns:
        list: A list of dictionaries containing firewall policy information.
              Each dictionary has the following keys: 'name' and 'associations'.
    """
  ret = []

  results_iterator = cai_client.search_all_resources(
      request={
          "scope": f"organizations/{organization_id}",
          "asset_types": ["compute.googleapis.com/FirewallPolicy"],
          "read_mask": "name,versionedResources",
          "page_size": 500
      })
  list(results_iterator)

  for resource in results_iterator:
    associations = resource.versioned_resources[0].resource.get(
        'associations', [])

    ret.append({
        "name": resource.name,
        "associations": [association['name'] for association in associations]
    })

  return ret


def _delete_policy_association(fw_policy_client, policy_id, association,
                               dry_run):
  """
    Delete the association of a firewall policy.

    Parameters:
        fw_policy_client (google.cloud.compute_v1.FirewallPoliciesClient): The Firewall Policies client.
        policy_id (str): The ID of the firewall policy.
        association (str): The name of the association to delete.
        dry_run (bool, optional): If True, only simulate the deletion without actually performing it. Default is False.
    """
  log_message = "%sDeleting firewall policy association %s for policy %s." % ("(Simulated) " if dry_run else "",
                                                                              association, policy_id)
  logger.info(log_message)

  request = compute_v1.RemoveAssociationFirewallPolicyRequest(
      firewall_policy=policy_id, name=association)
  if not dry_run:
    fw_policy_client.remove_association(
        request=request).result()  # Wait for the operation to complete.
