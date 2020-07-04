# Cloud Asset Inventory feeds for resource change tracking and remediation

This example shows how to leverage [Cloud Asset Inventory feeds](https://cloud.google.com/asset-inventory/docs/monitoring-asset-changes) to stream resource changes in real time, and how to programmatically react to changes by wiring a Cloud Function to the feed outputs.

The Cloud Function can then be used for different purposes:

- updating remote data (eg a CMDB) to reflect the changed resources
- triggering alerts to surface critical changes
- adapting the configuration of separate related resources
- implementing remediation steps that enforce policy compliance by tweaking or reverting the changes.

This example shows a simple remediation use case: how to enforce policies on instance tags and revert non-compliant changes in near-real time, thus adding an additional measure of control when using tags for firewall rule scoping.

With simple changes to the [monitored asset](https://cloud.google.com/asset-inventory/docs/supported-asset-types) and the remediation logic, the example can be adapted to fit other common use cases: enforcing a centrally defined Cloud Armor policy in backend services, creating custom DNS records in private zones for instances or forwarding rules, etc.

The resources created in this example are shown in the high level diagram below:

![Asset Inventory Feed diagram](diagram.png "Asset Inventory Feed diagram")

## Testing the example

