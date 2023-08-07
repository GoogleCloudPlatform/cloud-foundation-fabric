import logging
from google.cloud import orgpolicy_v2

logger = logging.getLogger("default")


def delete(cai_client, organization_id, dry_run):
  """
    Delete organization policies.

    Parameters:
        cai_client (google.cloud.asset_v1.AssetServiceClient): The Cloud Asset Inventory client.
        organization_id (str): The ID of the organization.
        dry_run (bool, optional): If True, only simulate the deletions without actually performing them. Default is False.
    """

  logger.info(f"Starting processing org policies")

  org_policy_list = _list_org_policies(cai_client, organization_id)

  org_policy_client = orgpolicy_v2.OrgPolicyClient()

  logger.info(f"Retrieved {len(org_policy_list)} organization policies.")

  for policy in org_policy_list:
    policy = policy.replace("//orgpolicy.googleapis.com/", "")

    log_message = "%sDeleting organization policy %s." % (
        "(Simulated) " if dry_run else "", policy)
    logger.info(log_message)

    request = orgpolicy_v2.DeletePolicyRequest(name=policy,)

    if not dry_run:
      org_policy_client.delete_policy(request=request)

  logger.info(f"Done processing org policies")


def _list_org_policies(cai_client, organization_id):
  """
    List organization policies for the specified organization.

    Parameters:
        cai_client (google.cloud.asset_v1.AssetServiceClient): The Cloud Asset Inventory client.
        organization_id (str): The ID of the organization.

    Returns:
        list: A list of organization policy names.
    """
  ret = []

  results_iterator = cai_client.search_all_resources(
      request={
          "scope": f"organizations/{organization_id}",
          "asset_types": ["orgpolicy.googleapis.com/Policy"],
          "page_size": 500,
      })
  list(results_iterator)

  for resource in results_iterator:
    ret.append(resource.name)

  return ret
