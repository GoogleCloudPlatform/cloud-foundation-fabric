# Networking and infrastructure examples

The examples in this folder implement **typical network topologies** like hub and spoke, or **end-to-end scenarios** that allow testing specific features like on-premises DNS policies and Private Google Access.

They are meant to be used as minimal but complete strting points to create actual infrastructure, and as playgrounds to experiment with specific Google Cloud features.

## Examples

### Hub and Spoke via Peering

<a href="./hub-and-spoke-peering/" title="Hub and spoke via peering example"><img src="./hub-and-spoke-peering/diagram.png" align="left" width="280px"></a> This [example](./hub-and-spoke-peering/)implements a hub and spoke topology via VPC peering, and highlights some peering limitations: non transitivity between spokes, the need to serialize peering creation/destruction for a single VPC, and limited cnnectivity to managed services like GKE which use private service access via an additional peering.
