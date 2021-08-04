# Cloud Asset Inventory feeds for resource change tracking and remediation

This example shows how to leverage [Cloud Asset Inventory feeds](https://cloud.google.com/asset-inventory/docs/monitoring-asset-changes) to stream resource changes in real time, and how to programmatically react to changes by wiring a Cloud Function to the feed outputs.

The Cloud Function can then be used for different purposes:

- updating remote data (eg a CMDB) to reflect the changed resources
- triggering alerts to surface critical changes
- adapting the configuration of separate related resources
- implementing remediation steps that enforce policy compliance by tweaking or reverting the changes.

A [companion Medium article](https://medium.com/google-cloud/using-cloud-asset-inventory-feeds-for-dynamic-configuration-and-policy-enforcement-c37b6a590c49) has been published for this example, refer to it for more details on the context and the specifics of running the example.

This example shows a simple remediation use case: how to enforce policies on instance tags and revert non-compliant changes in near-real time, thus adding an additional measure of control when using tags for firewall rule scoping. Changing the [monitored asset](https://cloud.google.com/asset-inventory/docs/supported-asset-types) and the function logic allows simple adaptation to other common use cases:

- enforcing a centrally defined Cloud Armor policy in backend services
- creating custom DNS records for instances or forwarding rules

The example uses a single project for ease of testing, in actual use a few changes are needed to operate at the resource hierarchy level:

- the feed should be set at the folder or organization level
- the custom role used to assign tag changing permissions should be defined at the organization level
- the role binding that grants the custom role to the Cloud Function service account should be set at the same level as the feed (folder or organization)

The resources created in this example are shown in the high level diagram below:

<img src="diagram.png" width="640px">


## Running the example

Clone this repository or [open it in cloud shell](https://ssh.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2Fterraform-google-modules%2Fcloud-foundation-fabric&cloudshell_print=cloud-shell-readme.txt&cloudshell_working_dir=cloud-operations%2Fasset-inventory-feed-remediation), then go through the following steps to create resources:

- `terraform init`
- `terraform apply -var project_id=my-project-id`

Once done testing, you can clean up resources by running `terraform destroy`. To persist state, check out the `backend.tf.sample` file.

## Testing the example

The terraform outputs generate preset `gcloud` commands that you can copy and run in the console, to complete configuration and test the example:

- `subscription_pull` shows messages in the PubSub queue, to check feed message format if the Cloud Function is disabled
- `cf_logs` shows Cloud Function logs to check that remediation works
- `tag_add` adds a non-compliant tag to the test instance, and triggers the Cloud Function remediation process
- `tag_show` displays the tags currently set on the test instance

Run the `subscription_pull` command until it returns nothing, then run the following commands in order to test remediation:

- the `tag_add` command
- the `cf_logs` command until the logs show that the change has been picked up, verified, and the compliant tags have been force-set on the instance
- the `tag_show` command to verify that the function output matches the resource state


<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| project_id | Project id that references existing project. | <code title="">string</code> | ✓ |  |
| *bundle_path* | Path used to write the intermediate Cloud Function code bundle. | <code title="">string</code> |  | <code title="">./bundle.zip</code> |
| *name* | Arbitrary string used to name created resources. | <code title="">string</code> |  | <code title="">asset-feed</code> |
| *project_create* | Create project instead of using an existing one. | <code title="">bool</code> |  | <code title="">false</code> |
| *region* | Compute region used in the example. | <code title="">string</code> |  | <code title="">europe-west1</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| cf_logs | Cloud Function logs read command. |  |
| subscription_pull | Subscription pull command. |  |
| tag_add | Instance add tag command. |  |
| tag_show | Instance add tag command. |  |
<!-- END TFDOC -->

