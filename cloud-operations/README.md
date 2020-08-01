# Operations examples

The examples in this folder show how to wire together different Google Cloud services to simplify operations, and are meant for testing, or as minimal but sufficiently complete starting points for actual use.

## Resource tracking and remediation via Cloud Asset feeds

<a href="./asset-inventory-feed-remediation" title="Resource tracking and remediation via Cloud Asset feeds"><img src="./asset-inventory-feed-remediation/diagram.png" align="left" width="280px"></a> This [example](./asset-inventory-feed-remediation) shows how to leverage [Cloud Asset Inventory feeds](https://cloud.google.com/asset-inventory/docs/monitoring-asset-changes) to stream resource changes in real time, and how to programmatically use the feed change notifications for alerting or remediation, via a Cloud Function wired to the feed PubSub queue.

The example's feed tracks changes to Google Compute instances, and the Cloud Function enforces policy compliance on each change so that tags match a set of simple rules. The obious use case is when instance tags are used to scope firewall rules, bu the example can easily be adapted to suit different use cases.

<br clear="left">

## Granular Cloud DNS IAM via Service Directory

<a href="./dns-fine-grained-iam" title="Fine-grained Cloud DNS IAM with Service Directory"><img src="./dns-fine-grained-iam/diagram.png" align="left" width="280px"></a> This [example](./dns-fine-grained-iam) shows how to leverage Service Directory](https://cloud.google.com/blog/products/networking/introducing-service-directory) and Cloud DNS Service Directory private zones, to implement fine-grained IAM controls on DNS. The example creates a Service Directory namespace, a Cloud DNS private zone that uses it as its authoritative source, service accounts with different levels of permissions, and VMs to test them.

<br clear="left">

