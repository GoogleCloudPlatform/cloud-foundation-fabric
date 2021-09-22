# Operations examples

The examples in this folder show how to wire together different Google Cloud services to simplify operations, and are meant for testing, or as minimal but sufficiently complete starting points for actual use.

## Resource tracking and remediation via Cloud Asset feeds

<a href="./asset-inventory-feed-remediation" title="Resource tracking and remediation via Cloud Asset feeds"><img src="./asset-inventory-feed-remediation/diagram.png" align="left" width="280px"></a> This [example](./asset-inventory-feed-remediation) shows how to leverage [Cloud Asset Inventory feeds](https://cloud.google.com/asset-inventory/docs/monitoring-asset-changes) to stream resource changes in real time, and how to programmatically use the feed change notifications for alerting or remediation, via a Cloud Function wired to the feed PubSub queue.

The example's feed tracks changes to Google Compute instances, and the Cloud Function enforces policy compliance on each change so that tags match a set of simple rules. The obious use case is when instance tags are used to scope firewall rules, but the example can easily be adapted to suit different use cases.

<br clear="left">

## Scheduled Cloud Asset Inventory Export to Bigquery

<a href="./scheduled-asset-inventory-export-bq" title="Scheduled Cloud Asset Inventory Export to Bigquery"><img src="./scheduled-asset-inventory-export-bq/diagram.png" align="left" width="280px"></a> This [example](./scheduled-asset-inventory-export-bq) shows how to leverage the [Cloud Asset Inventory Exporting to Bigquery](https://cloud.google.com/asset-inventory/docs/exporting-to-bigquery) feature, to keep track of your organization's assets over time storing information in Bigquery. Data stored in Bigquery can then be used for different purposes like dashboarding or analysis.

<br clear="left">

## Granular Cloud DNS IAM via Service Directory

<a href="./dns-fine-grained-iam" title="Fine-grained Cloud DNS IAM with Service Directory"><img src="./dns-fine-grained-iam/diagram.png" align="left" width="280px"></a> This [example](./dns-fine-grained-iam) shows how to leverage [Service Directory](https://cloud.google.com/blog/products/networking/introducing-service-directory) and Cloud DNS Service Directory private zones, to implement fine-grained IAM controls on DNS. The example creates a Service Directory namespace, a Cloud DNS private zone that uses it as its authoritative source, service accounts with different levels of permissions, and VMs to test them.

<br clear="left">

## Granular Cloud DNS IAM for Shared VPC

<a href="./dns-shared-vpc" title="Fine-grained Cloud DNS IAM via Shared VPC"><img src="./dns-shared-vpc/diagram.png" align="left" width="280px"></a> This [example](./dns-shared-vpc) shows how to create reusable and modular Cloud DNS architectures, by provisioning dedicated Cloud DNS instances for application teams that want to manage their own DNS records, and configuring DNS peering to ensure name resolution works in a common Shared VPC.

<br clear="left">

## Compute Engine quota monitoring

<a href="./quota-monitoring" title="Compute Engine quota monitoring"><img src="./quota-monitoring/diagram.png" align="left" width="280px"></a> This [example](./quota-monitoring) shows a practical way of collecting and monitoring [Compute Engine resource quotas](https://cloud.google.com/compute/quotas) via Cloud Monitoring metrics as an alternative to the recently released [built-in quota metrics](https://cloud.google.com/monitoring/alerts/using-quota-metrics). A simple alert on quota thresholds is also part of the example.

<br clear="left">

## Delegated Role Grants

<a href="./iam-delegated-role-grants" title="Delegated Role Grants"><img src="./iam-delegated-role-grants/diagram.png" align="left" width="280px"></a> This [example](./iam-delegated-role-grants) shows how to use delegated role grants to restrict service usage.

<br clear="left">
