import logging
from google.cloud import logging_v2

logger = logging.getLogger("default")


def delete(cai_client, organization_id, exclude_log_sinks, dry_run):
  """
    Delete log sinks created at folder and organization level

    Parameters:
        cai_client (google.cloud.asset_v1.AssetServiceClient): The Cloud Asset Inventory client.
        organization_id (str): The ID of the organization.
        exclude_log_sinks (str): Comma-separated list of log sink names to exclude from deletion.
        dry_run (bool, optional): If True, only simulate the deletions without actually performing them. Default is False.
    """

  logger.info(f"Starting processing log sinks")

  exclude_log_sinks = exclude_log_sinks.split(",") if exclude_log_sinks else []
  log_sinks_list = [
      x.replace("//logging.googleapis.com/", "")
      for x in _list_log_sinks(cai_client, organization_id)
  ]

  logger.info(f"Retrieved {len(log_sinks_list)} log sinks")

  log_sinks_client = logging_v2.Client()

  for sink in log_sinks_list:
    if not sink in exclude_log_sinks:
      log_message = "%sDeleting sink %s." % ("(Simulated) " if dry_run else "",
                                             sink)
      logger.info(log_message)
      if not dry_run:
        log_sinks_client.sinks_api.sink_delete(sink)
    else:
      logger.info(f"Skipping sink '{sink}'")

  logger.info(f"Done processing log sinks")


def _list_log_sinks(cai_client, organization_id):
  """
    List log sinks created at Folder or Organization level for the specified organization.
    Filters _Default and _Required out.

    Parameters:
        cai_client (google.cloud.asset_v1.AssetServiceClient): The Cloud Asset Inventory client.
        organization_id (str): The ID of the organization.

    Returns:
        list: A list of log sinks.
    """
  ret = []

  results_iterator = cai_client.search_all_resources(
      request={
          "scope": f"organizations/{organization_id}",
          "asset_types": ["logging.googleapis.com/LogSink"],
          "page_size": 500,
      })
  list(results_iterator)

  for resource in results_iterator:
    if resource.parent_asset_type in [
        "cloudresourcemanager.googleapis.com/Folder",
        "cloudresourcemanager.googleapis.com/Organization"
    ] and not (resource.name.endswith("_Default") or
               resource.name.endswith("_Required")):
      ret.append(resource.name)

  return ret
