# Hybrid connectivity to on-premises thrugh PSC

The sample allows to connect to an on-prem service leveraging Private Service Connect (PSC).

It creates:

* A "producer": a VPC exposing a PSC Service Attachment (SA), connecting to an internal regional TCP proxy load balancer, using a hybrid NEG backend that connects to an on-premises service (IP address + port)

* [PSC Consumer](./psc-consumer/README.md)

<!-- TODO(lucaprete) - Diagram goes here after first reviews -->

## Sample modules

The blueprint makes use of the modules [psc-producer](psc-producer) and [psc-consumer](psc-consumer) contained in this folder. This is done so you can build on top of these building blocks, in order to support more complex scenarios.

## Prerequisites

Before applying this Terraform

* On-premises
	- Allow ingress from *35.191.0.0/16* and *130.211.0.0/22* CIDRs (for HCs)
	- Allow ingress from the proxy-only subnet CIDR
	
* GCP
	- Advertise from GCP to on-prem *35.191.0.0/16* and *130.211.0.0/22* CIDRs
	- Advertise from GCP to on-prem the proxy-only subnet CIDRs

## Relevant Links

* [Private Service Connect](https://cloud.google.com/vpc/docs/private-service-connect)

* [Hybrid connectivity Network Endpoint Groups](https://cloud.google.com/load-balancing/docs/negs/hybrid-neg-concepts)

* [Regional TCP Proxy with Hybrid NEGs](https://cloud.google.com/load-balancing/docs/tcp/set-up-int-tcp-proxy-hybrid)

* [PSC approval](https://cloud.google.com/vpc/docs/configure-private-service-connect-producer#publish-service-explicit)

<!-- BEGIN TFDOC -->
<!-- END TFDOC -->
