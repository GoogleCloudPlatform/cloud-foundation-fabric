# GCP Organization Cleaner

GCP Organization Cleaner is a command-line tool designed to help you purge all
resources within a GCP organization. Its ultimate goal is to support the
cleanup of E2E test deployments.

## Features (WIP)

- Delete organization policies: Remove organization-level IAM policies.
- Delete firewall policies: Clean up firewall policies.
- Delete log sinks: Remove log sinks.
- Delete secure tags: Delete secure tag keys and values.

## Missing features

See [TODO.md](TODO.md)

## Prerequisites

Before using this tool, ensure that you have the required privileges to execute the file.

TODO: document the list of required permissions

## Usage

To use GCP Organization Cleaner run:

```bash
python org_cleaner.py <organization_id> [options]
```

Replace `<organization_id>` with the ID of the target GCP organization.

Available options:

- `--dry-run`: Perform a dry-run without actual deletions.
- `--exclude-log-sinks`: Exclude specific log sinks in '{organizations,folders}/{id}/sinks/{sink_name}' format, comma-separated.
- `--only-fwpolicies`: Only delete firewall policies.
- `--only-logsinks`: Only delete log sinks.
- `--only-orgpolicies`: Only delete organization policies.
- `--only-securetags`: Only delete secure tag keys and values.

## Examples

- Delete all types of resources within the organization:

```sh
python gcp_organization_cleaner.py <organization_id>
  ```

- Delete only organization policies and log sinks (dry-run):

```sh
python gcp_organization_cleaner.py <organization_id> --dry-run --only-orgpolicies --only-logsinks
```

- Delete specific log sinks and firewall policies:

```sh
python gcp_organization_cleaner.py <organization_id> --exclude-log-sinks=<sink1,sink2> --only-logsinks --only-fwpolicies
```

## Note

Use this tool with caution, as it performs resource deletions within your GCP organization. Always review the options and confirm the actions before executing deletions.
