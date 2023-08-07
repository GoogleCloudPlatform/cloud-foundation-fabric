import logging
import click
from google.cloud import asset
from modules import firewall_policies, log_sinks, org_policies, secure_tags

# Set up logging configuration
logger = logging.getLogger("default")
logging.basicConfig(format='[%(levelname)s] - %(asctime)s - %(message)s')
logging.root.setLevel(logging.INFO)


# Define the main function using Click
@click.command()
@click.argument("organization_id", type=str, required=True)
@click.option(
    "--dry-run",
    is_flag=True,
    help="Perform a dry-run without actual deletions.")
@click.option(
    '--exclude-log-sinks',
    help="Log sinks to exclude in '{organizations,folders}/{id}/sinks/{sink_name}' format, comma separated."
)
@click.option(
    "--only-fwpolicies", is_flag=True, help="Only delete firewall policies.")
@click.option("--only-logsinks", is_flag=True, help="Only delete log sinks.")
@click.option(
    "--only-orgpolicies",
    is_flag=True,
    help="Only delete organization policies")
@click.option(
    "--only-securetags",
    is_flag=True,
    help="Only delete secure tag keys and values")
def main(organization_id, dry_run, exclude_log_sinks, only_orgpolicies,
         only_fwpolicies, only_logsinks, only_securetags):
  logger.info("Starting")

  # Determine which actions to perform
  delete_all = not any(
      [only_orgpolicies, only_logsinks, only_fwpolicies, only_securetags])

  # Create the Cloud Asset Inventory client
  cai_client = asset.AssetServiceClient()

  # Delete organization policies
  if delete_all or only_orgpolicies:
    org_policies.delete(cai_client, organization_id, dry_run)

  # Delete firewall policies
  if delete_all or only_fwpolicies:
    firewall_policies.delete(cai_client, organization_id, dry_run)

  # Delete log sinks
  if delete_all or only_logsinks:
    log_sinks.delete(cai_client, organization_id, exclude_log_sinks, dry_run)

  # Delete secure tags
  if delete_all or only_securetags:
    secure_tags.delete(cai_client, organization_id, dry_run)


# Run the main function if the script is executed directly
if __name__ == "__main__":
  main()
