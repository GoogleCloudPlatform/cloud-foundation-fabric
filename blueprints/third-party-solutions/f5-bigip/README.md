# Third Party Solutions

The blueprints in this folder show how to deploy both private and public active/active F5 BigIP-VE load balancers in GCP.

## Blueprints

### F5 BigIP

<a href="./f5-bigip-ha-active/" title="F5 BigIP HA active-active"><img src="./f5-bigip-ha-active/diagram.png" align="left" width="320px"></a> <p style="margin-left: 340px">This blueprint shows how to deploy both private and public active/active F5 BigIP-VE load balancers in GCP. It deploys external and/or internal GCP network passthrough load balancers in front of the F5 VMs in order to load balance the ingress traffic and it supports both IPv4 and IPv6.</p>

<br clear="left">

### F5 BigIP-HA deployment

<a href="./f5-bigip-ha-active-deployment/" title="F5 BigIP HA active-active deployment"><img src="./f5-bigip-ha-active-deployment/diagram.png" align="left" width="320px"></a> <p style="margin-left: 340px">The blueprint demonstrates how to deploy active-active F5 BigIP load balancers in a VPC, leveraging the [f5-big-ha-active blueprint](./f5-bigip-ha-active/README.md). In this example, the load balancer is exposed to internal sample clients only and it can handle both IPv4 and an IPv6 traffic.</p>

<br clear="left">
