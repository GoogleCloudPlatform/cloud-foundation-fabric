# Network filtering with Squid with isolated VPCs using Private Service Connect

This blueprint shows how to deploy a filtering HTTP proxy to restrict Internet access. Here we show one way to do this using isolated VPCs and Private Service Connect:

- The `app` subnets hosts the consumer VMs that will have their Internet access tightly controlled by a non-caching filtering forward proxy.
- The `proxy` subnet hosts a Cloud NAT instance and a [Squid](http://www.squid-cache.org/) server.
- The `psc` subnet is reserved for the Private Service Connect.

All consumer VPCs and all the service projects will be located under a folder called `apps`, enforcing the `compute.vmExternalIpAccess` [organization policy](https://cloud.google.com/resource-manager/docs/organization-policy/org-policy-constraints). This prevents the service projects from having external IPs, thus forcing all outbound Internet connections through the proxy.

To allow Internet connectivity to the proxy subnet, a Cloud NAT instance is configured to allow usage from [that subnet only](https://cloud.google.com/nat/docs/using-nat#specify_subnet_ranges_for_nat). All other subnets are not allowed to use the Cloud NAT instance.

To simplify the usage of the proxy, a Cloud DNS private zone is created in each consumer VPC and the IP address of the proxy is exposed with the FQDN `proxy.internal`. In addition, system-wide `http_proxy` and `https_proxy` environment variables and an APT configuration are rolled out via a [startup script](proxy-consumer/startup.sh).

<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [billing_account](variables.tf#L28) | Billing account id used as default for new projects. | <code>string</code> | ✓ |  |
| [prefix](variables.tf#L49) | Prefix used for resources that need unique names. | <code>string</code> | ✓ |  |
| [root_node](variables.tf#L60) | Root node for the new hierarchy, either 'organizations/org_id' or 'folders/folder_id'. | <code>string</code> | ✓ |  |
| [allowed_domains](variables.tf#L17) | List of domains allowed by the squid proxy. | <code>list&#40;string&#41;</code> |  | <code title="&#91;&#10;  &#34;.google.com&#34;,&#10;  &#34;.github.com&#34;,&#10;  &#34;.fastlydns.net&#34;,&#10;  &#34;.debian.org&#34;&#10;&#93;">&#91;&#8230;&#93;</code> |
| [cidrs](variables.tf#L33) | CIDR ranges for subnets. | <code>map&#40;string&#41;</code> |  | <code title="&#123;&#10;  apps  &#61; &#34;10.0.0.0&#47;24&#34;&#10;  proxy &#61; &#34;10.0.1.0&#47;28&#34;&#10;  psc   &#61; &#34;10.0.2.0&#47;28&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [nat_logging](variables.tf#L43) | Enables Cloud NAT logging if not null, value is one of 'ERRORS_ONLY', 'TRANSLATIONS_ONLY', 'ALL'. | <code>string</code> |  | <code>&#34;ERRORS_ONLY&#34;</code> |
| [region](variables.tf#L54) | Default region for resources. | <code>string</code> |  | <code>&#34;europe-west1&#34;</code> |

<!-- END TFDOC -->
