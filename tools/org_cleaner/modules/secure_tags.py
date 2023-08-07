import logging
from google.cloud import resourcemanager_v3

logger = logging.getLogger("default")


def delete(cai_client, organization_id, dry_run):
  """
    Delete secure tag values and their associated tag bindings.

    :param cai_client: The Google Cloud Asset Inventory (CAI) client.
    :param organization_id: The ID of the organization.
    :param exclude_log_sinks: Not used in this function.
    :param dry_run: If True, performs a dry run without actually deleting anything.
    """

  logger.info(f"Starting processing secure tags")

  # Retrieve the secure tag values for the organization
  tag_values = [
      x.name.replace("//cloudresourcemanager.googleapis.com/", "")
      for x in _list_securetagvalues(cai_client, organization_id)
  ]

  logger.info("Retrieved %s secure tag values.", len(tag_values))

  # Delete the tag values and their associated tag bindings
  for tag_value in tag_values:
    _delete_tag_value(cai_client, organization_id, tag_value, dry_run)

  tag_keys = [
      x.name.replace("//cloudresourcemanager.googleapis.com/", "")
      for x in _list_securetagkeys(cai_client, organization_id)
  ]

  logger.info("Retrieved %s secure tag keys.", len(tag_keys))

  for tag_key in tag_keys:
    _delete_tag_key(tag_key, dry_run)

  logger.info(f"Done processing secure tags")


def _list_securetagkeys(cai_client, organization_id):
  """
    List all secure tag keys for the given organization.

    :param cai_client: The Google Cloud Asset Inventory (CAI) client.
    :param organization_id: The ID of the organization.
    :return: A generator that provides the secure tag keys.
    """

  # Use the CAI client to search for all resources of type "TagValue" within the organization
  results_iterator = cai_client.search_all_resources(
      request={
          "scope": f"organizations/{organization_id}",
          "asset_types": ["cloudresourcemanager.googleapis.com/TagKey"],
          "read_mask": "name",
          "page_size": 500
      })

  # Consume the generator and return the results
  list(results_iterator)
  return results_iterator


def _list_securetagvalues(cai_client, organization_id):
  """
    List all secure tag values for the given organization.

    :param cai_client: The Google Cloud Asset Inventory (CAI) client.
    :param organization_id: The ID of the organization.
    :return: A generator that provides the secure tag values.
    """

  # Use the CAI client to search for all resources of type "TagValue" within the organization
  results_iterator = cai_client.search_all_resources(
      request={
          "scope": f"organizations/{organization_id}",
          "asset_types": ["cloudresourcemanager.googleapis.com/TagValue"],
          "read_mask": "name",
          "page_size": 500
      })

  # Consume the generator and return the results
  list(results_iterator)
  return results_iterator


def _delete_tag_value(cai_client, organization_id, tag_value, dry_run):
  """
    Delete a specific secure tag value and its associated tag bindings.

    :param cai_client: The Google Cloud Asset Inventory (CAI) client.
    :param organization_id: The ID of the organization.
    :param tag_value: The name of the secure tag value.
    :param dry_run: If True, performs a dry run without actually deleting anything.
    """

  logger.info("Fetching tag value %s.", tag_value)
  request = resourcemanager_v3.GetTagValueRequest(name=tag_value,)

  try:
    # Fetch the details of the secure tag value
    tagvalue_client = resourcemanager_v3.TagValuesClient()
    tagvalue_response = tagvalue_client.get_tag_value(request=request)
  except:
    logger.warning(
        "Fetching %s failed. Either you lack permission or the resource has been recently deleted.",
        tag_value)
    return

  logger.info("Fetching resources having %s attached.",
              tagvalue_response.namespaced_name)
  tagvalname = tagvalue_response.namespaced_name.split("/")[2]

  request = {
      "scope": f"organizations/{organization_id}",
      "read_mask": "name,tagKeys,tagValues,tagValueIds,parentAssetType",
      "query": f"tagValues:{tagvalname}",
      "page_size": 500
  }

  # Fetch all resources associated with the given secure tag value
  cai_bindings_response = cai_client.search_all_resources(request=request)
  list(cai_bindings_response)

  # Delete tag bindings for the given secure tag value
  for binding in cai_bindings_response:
    _delete_bindings_for_value(cai_client, binding.name, dry_run)

  log_message = "%sDeleting secure tag value %s." % ("(Simulated) " if dry_run
                                                     else "", tag_value)
  logger.info(log_message)
  if not dry_run:
    try:
      tagvalue_client.delete_tag_value(name=tag_value)
    except:
      logger.warning(
          "Deleting %s failed. Either you lack permission or the resource has been recently deleted.",
          tag_value)


def _delete_tag_key(tag_key, dry_run):
  """
    Delete a specific secure tag key
    :param tag_key: The name of the secure tag key.
    :param dry_run: If True, performs a dry run without actually deleting anything.
    """
  log_message = "%sDeleting tag key %s." % ("(Simulated) " if dry_run else "",
                                            tag_key)
  logger.info(log_message)
  tagkey_client = resourcemanager_v3.TagKeysClient()
  if not dry_run:
    tagkey_client.delete_tag_key(name=tag_key)


def _delete_bindings_for_value(cai_client, resource_name, dry_run):
  """
    Delete tag bindings associated with a specific resource.

    :param cai_client: The Google Cloud Asset Inventory (CAI) client.
    :param resource_name: The name of the resource to delete bindings for.
    :param dry_run: If True, performs a dry run without actually deleting anything.
    """

  tagbinding_client = resourcemanager_v3.TagBindingsClient()

  logger.info("Fetching bindings for %s.", resource_name)
  # List all tag bindings for the resource
  bindings_response = tagbinding_client.list_tag_bindings(parent=resource_name)
  list(bindings_response)

  for binding in bindings_response:
    log_message = "%sDeleting binding %s." % ("(Simulated) " if dry_run else "",
                                              binding.name)
    logger.info(log_message)
    if not dry_run:
      # Perform the actual deletion of the tag binding
      tagbinding_client.delete_tag_binding(name=binding.name)
