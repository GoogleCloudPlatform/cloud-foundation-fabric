# IAP Demo

[This demo](https://source.cloud.google.com/drebes-play-org-repos-88ed/iap-demo) aims to show the use of Enterprise BeyondCorp features to expose HTTP(S) services running on-prem via Cloud IAP using the [IAP connector](https://github.com/GoogleCloudPlatform/iap-connector) and Cloud VPN HA for connectivity.

## Requirements

### Services

The following services need to be enabled for the project:

* `cloudresourcemanager.googleapis.com` - For granting the GKE service account and the web app users the appropriate IAM permissions at the project level
* `compute.googleapis.com` - For the VPC, Cloud VPN, Cloud Router, Cloud NAT
* `container.googleapis.com` - For creating and managing the GKE cluster
* `dns.googleapis.com` - For setting up Cloud DNS outbound forwarding to on-prem
* `iam.googleapis.com` - For creating the service account the GKE nodes run as
* `iap.googleapis.com` - For setting up Cloud IAP
* `logging.googleapis.com` - For GKE nodes logging
* `monitoring.googleapis.com` - For GKE nodes monitoring

## Resource Management

Resources will be deployed to a newly created project specified by the `project_id` variable.

### IAM bindings

Resources

The user or service account deploying the demo should have the role `Project Creator` (`roles/resourcemanager.projectCreator`) is required. If an optional `policy_name` is specified to create an Access Level (see parameters below), the role Access Context Manager Editor (`roles/accesscontextmanager.policyEditor`) should also be granted at the root level of the Organization.

### Group permissions

To create the IAP OAuth Brand page, a support email needs to be specified. This email needs to be a G Suite/Cloud Identity group, and the user or service account running the demo needs to be an Owner of such group.

### Billing account

A billing account is required for the project creation

### On-prem

* A DNS zone for the on-prem services
* A DNS server on-prem that resolves these service names with their respective private IPs
* A VPN configured with properly [supported ciphers](https://cloud.google.com/network-connectivity/docs/vpn/concepts/supported-ike-ciphers), preshared key, Cloud VPN IP as peer.
* A BGP server configured to exchange routes through the VPN tunnels.
* At least one HTTP(s) server that accepts incoming requests from GCP.
* You can't use a Google Cloud VM to test, since the VPN that is created uses an external gateway and cannot connect to Google Cloud.
* 
### Public internet

Services will be access from the public internet via specific domains.

* The domains have to have public DNS records pointing to the Load Balancer of the IAP connector.
* With the above DNS entries, the certificate can be emitted and after that, the Load Balancer can start accepting external requests with the help of IAP.
* Those same domains have to be used in the `mapping` variable as `source` to ensure the Load Balancer can receive external requests.
* Given authentification will be required by IAP, public domains will have to be accessed by https, the on-prem services might be accessed through http or https.
* The Load Balancer IP will be shown in the `terraform apply` output since its part of the output. This is the IP that needs to be configured for external services.
* Use the web_user_principals variable to allow external use of the services through IAP. This consistently gives access to all services to the same principals.
* If you want to do give fine grained control per service, manually grant the role `IAP-user web app` to each backend service to each principal.

### Terraform

Terraform is not configured to use remote state, so `GOOGLE_APPLICATION_CREDENTIALS` is not required. If it is not set, `gcloud config get-value account` must return an account that has the necessary IAM permissions. For more information on how to manage GCP projects with terraform, please refer to [this guide](https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform).

## Installation

The steps are as follows:

1. Copy the defaults.auto.tfvars.example to defaults.auto.tfvars replacing the sample values with the real values.
2. Make sure that the service account or user used with gcloud has the right IAM bindings.
3. Execute `terraform apply` inside of the project.
4. Configure the public DNS entries after the Load Balancer IP is available so that the certificate can finalize its setup.
5. Configure on-prem by:
    * Connecting via VPN
    * Setting up BGP
    * Providing at least one DNS server to resolve on-prem
    * Providing at least one http(s) server to provide services to the IAP connector.

## Environment Description

The created environment contains the following resources

### Compute Engine

* `module.cert.google_compute_global_address.address`
* `module.cert.google_compute_managed_ssl_certificate.cert`
* `module.vpc.google_compute_network.network`
* `module.vpc.google_compute_subnetwork.subnetwork`
* `module.vpn_ha.google_compute_external_vpn_gateway.external_gateway`
* `module.vpn_ha.google_compute_ha_vpn_gateway.ha_gateway`
* `module.vpn_ha.google_compute_router.router`
* `module.vpn_ha.google_compute_router_interface.router_interface`
* `module.vpn_ha.google_compute_router_peer.bgp_peer`
* `module.vpn_ha.google_compute_vpn_tunnel.tunnels`
* `module.nat.google_compute_router_nat.nat`

### Cloud DNS

* `module.dns.google_dns_managed_zone.non-public`

### Container Engine

* `module.cluster.google_container_cluster.cluster`
* `module.cluster.google_container_node_pool.primary`

### Cloud IAM/Resource Manager

* `module.cluster.google_project_iam_member.sa_logging`
* `module.cluster.google_project_iam_member.sa_metrics`
* `module.cluster.google_service_account.gke_nodes`
* `module.connector.google_project_iam_member.web_users`

### Cloud IAP

* `module.iap-brand.google_iap_brand.brand`
* `module.iap-brand.google_iap_client.client`
* `module.connector.helm_release.iap_connector`

### Parameters

The following list of parameters can be defined.

#### Required

* `asn_local` - ASN for the GCP side of the BGP session
* `asn_peer` - ASN for the remote (on-prem) side of the BGP session
* `cert_domains` - List of FQDNs to issue a Google-managed certificate for. Public DNS needs to be updated to point these FQDNs to the IP address returned by the module.
* `cert_name` - Name to use to the Google-managed certificate.
* `dns_zone` - Remote (on-prem) DNS zone, for DNS outbound forwarding.
* `dns_resolvers` - List of remote (on-prem) DNS resolvers to forward requests to.
* `mappings` - List of mappings between frontend and backend URLs.
* `master_authorized_ranges` - IP ranges authorized to contact the GKE master.
* `name` - Unique name within the project to be used for created resources.
* `peer_vpn_ip` - IP address of the remote (on-prem) VPN gateway.
* `project_id` - Project ID to be created where resources are going to be deployed.
* `billing_account_id` - Billing account id to be associated with the project.
* `range_master` - RFC1918 IP range to be used for the GKE master.
* `range_nodes` - RFC1918 IP range to be used for the GKE nodes.
* `range_pods` - RFC1918 IP range to be used for the GKE pods.
* `range_services` - RFC1918 IP range to be used for the GKE services.
* `region` - GCP region to deploy resources into.
* `shared_secret` - Shared Secret used for IPsec Cloud VPN authentication.
* `support_email` - Email address of the support group for the IAP OAuth page. *NOTE: The user or service account running the demo needs to be an Owner of such group.*

#### Optional

* `name` - Unique name within the project to be used for created resources.
* `policy_name` - Name of an Access Context Manager policy for the organization, in the form `accessPolicies/{policy_id}`. If specified, an access level called `${var.name}` will be created, under this policy, specifiying only access only from corp. owned devices. *NOTE: In order to use this, explicit IAM permissions need to be granted manually to the service referencing this created access level.*
* `tunnel_0_link_range` - IP range (/30) to be used for link of VPN tunnel 0. First IP will be used on-prem, second on GCP.
* `tunnel_1_link_range` - IP range (/30) to be used for link of VPN tunnel 1. First IP will be used on-prem, second on GCP.
* `web_user_principals` - List of IAM principals authorized to access IAP web resources in the project. If these are specified, they will be granted access via IAP to all services within the project. No access level will be required in this case.

## On-prem demo

* Follow the following tutorial https://cloud.google.com/community/tutorials/using-cloud-vpn-with-strongswan
* At least in Ubuntu:
    * The following packages are required: `strongswan` `libstrongswan-standard-plugins` `bird`
    * The following files should be configured:
        * /etc/ipsec.conf
        * /etc/ipsec.d/gcp.conf
        * /etc/ipsec.secrets
        * /etc/sysctl.d/99-forwarding.conf
        * /etc/bird/bird.conf
        * /var/lib/strongswan/ipsec-vti.sh
* If you have a single server with no on-prem network, it suffices to [add an IP alias](https://www.cyberciti.biz/faq/linux-creating-or-adding-new-network-alias-to-a-network-card-nic/)
* It suffices to have an nginx service. https is optional.

## Troubleshooting

* The following Terraform dependency is not properly detected, which can lead to issues when updating/destroying projects/<project-id>/global/targetHttpsProxies/k8s-tps-default-iap-connector-ingress--46ad5a296bf9a1b7 -> projects/<project-id>/global/sslCertificates/iap-demo.
* Terraform can't keep track of the google_iap_brand resource. This has a consequence that in case of a destroy, a recreation will fail because the resource will have been destroyed locally, but it will keep existing in GCP (https://www.terraform.io/docs/providers/google/r/iap_brand.html). Terraform-importing the brand doesn't work out of the box, so recreating the project is the best option.
* The IAP connector can take longer than 5 minutes to create, which can lead to terraform failing on creation. Reapplying fixes this problem.
* Destroying and recreating the module.connector.helm_release.iap_connector might require a manual pause in-between because kubectl will return before the resources are actually fully destroyed.
* Please keep in mind that Cloud DNS [doesn't support routes for 35.199.192.0/19](https://cloud.google.com/vpc/docs/routes#cloud-dns). For this reason, the name servers can only be located in the *same* VPC network or the on-premises network.
* If your on-prem server does some magic to route traffic to the internet, you might have some trouble properly routing to GCP. In that case, source routing might come in handy. For example, you could issue the following commands:
<pre>
# Create a new routing table
echo 200 custom >> /etc/iproute2/rt_tables
# Add a new source rule. This will route only packets that come from the 192.168.0.0/16 on-prem network destined to talk to GCP.
ip rule add from 192.168.0.0/16 lookup custom
# In the defaults.auto.tfvars.example this is the subnet of nodes. In this example, only for packets coming from the on-prem VM 192.168.1.7.
ip route add 10.248.0.0/14 via 169.254.3.2 dev vti0 proto bird src 192.168.1.7 table custom
# In the defaults.auto.tfvars.example this is the subnet of pods. In this example, only for packets coming from the on-prem VM 192.168.1.7.
ip route add 10.252.0.0/18 via 169.254.3.2 dev vti0 proto bird src 192.168.1.7 table custom
# This is the IP address range of Cloud DNS for the case where a DNS server has the IP 192.168.1.7
ip route add 35.199.192.0/19 via 169.254.3.2 dev vti0 proto bird src 192.168.1.7 table custom
</pre>
* If the above situation arises and you indeed need source routing, keep in mind that there might be demons resetting the routing tables. These routes will need to be added on a regular basis.
