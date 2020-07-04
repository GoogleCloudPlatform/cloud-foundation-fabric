# Cloud Asset Inventory feeds for resource change tracking and remediation

This example shows how to leverage [Cloud Asset Inventory feeds](https://cloud.google.com/asset-inventory/docs/monitoring-asset-changes) to stream resource changes in real time, and how to programmatically react to changes by wiring a Cloud Function to the feed outputs.

The Cloud Function can then be used for different purposes:

- updating remote data (eg a CMDB) to reflect the changed resources
- triggering alerts to surface critical changes
- adapting the configuration of separate related resources
- implementing remediation steps that enforce policy compliance by tweaking or reverting the changes.

This example shows a simple remediation use case: how to enforce policies on instance tags and revert non-compliant changes in near-real time, thus adding an additional measure of control when using tags for firewall rule scoping.

With simple changes to the [monitored asset](https://cloud.google.com/asset-inventory/docs/supported-asset-types) and the remediation logic, the example can be adapted to fit other common use cases: enforcing a centrally defined Cloud Armor policy in backend services, creating custom DNS records for instances or forwarding rules, etc.

The resources created in this example are shown in the high level diagram below:

<img src="diagram.png" width="640px">

## Running the example

Clone this repository or [open it in cloud shell](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2Fterraform-google-modules%2Fcloud-foundation-fabric&cloudshell_git_branch=ludo-asset-feeds&cloudshell_print=cloud-shell-readme.txt&cloudshell_working_dir=cloud-operations%2Fasset-inventory-feed-remediation), then go through the following steps to create resources:

- `terraform init`
- `terraform apply -var project_id=my-project-id`
- copy and paste the `command_feed_create` output to create the feed

Once done testing, you can clean up resources by running `terraform destroy`. To persist state, check out the `backend.tf.sample` file.

## Testing remediation

TODO

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| project_id | Project id that references existing project. | <code title="">string</code> | ✓ |  |
| *bundle_path* | Path used to write the intermediate Cloud Function code bundle. | <code title="">string</code> |  | <code title="">./bundle.zip</code> |
| *name* | Arbitrary string used to name created resources. | <code title="">string</code> |  | <code title="">asset-feed</code> |
| *region* | Compute region used in the example. | <code title="">string</code> |  | <code title="">europe-west1</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| command_cf_logs | Cloud Function logs read command. |  |
| command_feed_create | Feed gcloud command. |  |
| command_instance_add_tag | Instance add tag command. |  |
| command_subscription_pull | Subscription pull command. |  |
<!-- END TFDOC -->

