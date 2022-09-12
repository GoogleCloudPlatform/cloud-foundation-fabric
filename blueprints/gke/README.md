# GKE and Serverless blueprints

The blueprints in this folder show implement **end-to-end scenarios** for GKE or Serveless topologies that show how to automate common configurations or leverage specific products.

They are meant to be used as minimal but complete starting points to create actual infrastructure, and as playgrounds to experiment with Google Cloud features.

## Blueprints

### Multitenant GKE fleet

<a href="./multitenant-fleet/" title="GKE multitenant fleet"><img src="./multitenant-fleet/diagram.png" align="left" width="280px"></a> This [blueprint](./multitenant-fleet/) allows simple centralized management of similar sets of GKE clusters and their nodepools in a single project, and optional fleet management via GKE Hub templated configurations.
<br clear="left">

### Shared VPC with GKE and per-subnet support

<a href="../networking/shared-vpc-gke/" title="Shared VPC with GKE"><img src="../networking/shared-vpc-gke/diagram.png" align="left" width="280px"></a> This [blueprint](../networking/shared-vpc-gke/) shows how to configure a Shared VPC, including the specific IAM configurations needed for GKE, and to give different level of access to the VPC subnets to different identities.

It is meant to be used as a starting point for most Shared VPC configurations, and to be integrated to the above blueprints where Shared VPC is needed in more complex network topologies.
<br clear="left">
