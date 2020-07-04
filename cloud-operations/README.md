# Operations examples

The examples in this folder show how to wire together different Google Cloud services to simplify operations, and are meant for testing, or as minimal but sufficiently complete starting points for actual use.

## Examples

### Resource tracking and remediation via Cloud Asset feeds

<a href="./asset-inventory-feed-remediation" title="Resource tracking and remediation via Cloud Asset feeds"><img src="./asset-inventory-feed-remediation/diagram.png" align="left" width="280px"></a> This [example](./asset-inventory-feed-remediation) shows how to leverage Cloud Asset Inventory feeds to stream resource changes in real time, and how to programmatically react to changes by wiring a Cloud Function to the feed outputs.

The tracked resources in the example are compute instances, and the Cloud Function is used to enforce policy compliance on their tags, and can esaily be adapted to suit different use cases.

### Granular Cloud DNS IAM via Service Directory

TODO(ludoo): publish the working example