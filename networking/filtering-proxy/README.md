# Network filtering with Squid

This example shows how to deploy a filtering HTTP proxy to restrict Internet access. Here we show one way to do this using a VPC with two subnets:

- The first subnet (called "apps" in this example) hosts the VMs that will have their Internet access tightly controlled a non-caching filtering forward proxy.
- The second subnet (called "proxy" in this example) hosts a Cloud NAT instance and a Squid Server [Squid](http://www.squid-cache.org/).

The VPC is a Shared VPC and all the service projects will be located under a folder enforcing the `compute.vmExternalIpAccess` (organization policies)[https://cloud.google.com/resource-manager/docs/organization-policy/org-policy-constraints]. This prevents the service projects from having external IPs thus forcing all outbound Internet connections through the proxy.

To allow Internet connectivity to the proxy subnet, a Cloud NAT instance is configured to allow usage from (that subnet only)[https://cloud.google.com/nat/docs/using-nat#specify_subnet_ranges_for_nat]. All other subnets are not allowed to use the Cloud NAT instance.

To simplify the usage of the proxy, a Cloud DNS private zone is created and the IP address of the proxy is exposed with the FQDN `proxy.internal`.

You can optionally deploy the Squid server as (Managed Instance Group)[https://cloud.google.com/compute/docs/instance-groups] by setting the `mig` option to `true`. This option defaults to `false` which results in a standalone VM.

![High-level diagram](squid.png "High-level diagram")
