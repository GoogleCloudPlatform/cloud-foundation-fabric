# Networking and infrastructure examples

The examples in this folder implement **typical network topologies** like hub and spoke, or **end-to-end scenarios** that allow testing specific features like on-premises DNS policies and Private Google Access.

They are meant to be used as minimal but complete strting points to create actual infrastructure, and as playgrounds to experiment with specific Google Cloud features.

## Examples

### Hub and Spoke via Peering

<a href="./hub-and-spoke-peering/" title="Hub and spoke via peering example"><img src="./hub-and-spoke-peering/diagram.png" align="left" width="280px"></a> This [example](./hub-and-spoke-peering/) implements a hub and spoke topology via VPC peering, a common design where a landing zone VPC (hub) is conncted to on-premises, and then peered with satellite VPCs (spokes) to partition the infrastructure in environments, business units, etc.

The sample highlights a few issues around the lack of transitivity in peering: the lack of connectivity between spokes, and the need to work around private service access to managed services that add a peering to a tenant VPC managed by the service provider. One solution for private GKE is shown, allowing access from hub and spoke to GKE masters via a dedicated VPN.

<br clear="left">
