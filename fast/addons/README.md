# FAST add-ons

Each of the folders contained here is a separate "add-on" that can be used to add extra functionality to a specific stage.

Add-ons can be thought of as additional thin layers on top of a stage, that reuse its IaC resources and leverage the same IAM configuration: the same service accounts are used to run the add-on, and state configuration is stored in the same bucket as their "parent stage" under a different prefix.

## Add-on configuration

To configure an add-on, once you have identified its "parent stage" (networking, security, etc.) you have to configure the org setup stage so that its providers file, and associated GCS resources to host the state file, are created. The following example configures resources for the NGFW Networking add-on.

First, the new provider file is declared in the `defaults.yaml` file.

```yaml
# defaults.yaml (snippet)

output_files:
  # ...
  providers:
    # ...
    2-networking-ngfw:
      bucket: $storage_buckets:iac-0/iac-stage-state
      prefix: 2-networking-ngfw
      service_account: $iam_principals:service_accounts/iac-0/iac-networking-rw

```

Then, the GCS folder (shown here) or bucket for the Terraform state is defined in the IaC project.

```yaml
# projects/iac-0.yaml
buckets:
  # ...
  iac-stage-state:
    description: Terraform state for stage automation.
    managed_folders:
      # ...
      2-networking-ngfw:
        iam:
          roles/storage.admin:
            - $iam_principals:service_accounts/iac-0/iac-networking-rw
          $custom_roles:storage_viewer:
            - $iam_principals:service_accounts/iac-0/iac-networking-ro
```

Once the org setup stage is ready and applied, the add-on can be run using the generated provider files. The `fast-links.sh` can be used to link or copy the relevant files to the add-on, in the same way it's used for regular stages.
