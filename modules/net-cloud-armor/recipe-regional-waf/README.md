# Regional Application Load Balancers with a shared Cloud Armor policy

This recipe deploys a Cloud Run application exposed through both a regional external Application Load Balancer and a regional internal Application Load Balancer, and protects both with a single **regional backend security policy** managed via the [`net-cloud-armor`](../) module.

Regional policies are the only Cloud Armor policy type supported by regional Application Load Balancers, and can be shared by any number of backend services in the same region regardless of the load balancer being external or internal: this is useful when the same application is reachable from the Internet and from the corporate network, and the same WAF baseline has to apply on both paths.

The policy evaluates preconfigured OWASP WAF rule sets (in preview mode by default), optionally bypassing inspection for trusted source ranges. Global-only features such as redirects, header actions or Adaptive Protection are not available for regional policies, and are rejected at plan time by the module.

The policy is wired to both load balancers by passing the module `id` output to the `security_policy` attribute of their backend configurations.
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L42) | Project ID. | <code>string</code> | ✓ |  |
| [region](variables.tf#L47) | Region where all resources are deployed. | <code>string</code> | ✓ |  |
| [_testing](variables.tf#L18) | Populate this variable to avoid triggering the data source. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [invoker_members](variables.tf#L28) | Identities allowed to invoke the Cloud Run service. Override when the organization restricts allUsers via domain restricted sharing. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#34;allUsers&#34;&#93;</code> |
| [name](variables.tf#L35) | Prefix used for resource names. | <code>string</code> |  | <code>&#34;armor-ralb&#34;</code> |
| [trusted_ranges](variables.tf#L52) | IP ranges exempted from WAF inspection, e.g. corporate egress ranges. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [vpc_config](variables.tf#L59) | VPC configuration. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [waf_config](variables.tf#L69) | Preconfigured WAF rule sets evaluated on the backend services, and whether they run in preview mode. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [addresses](outputs.tf#L17) | Load balancer addresses. |  |
| [commands](outputs.tf#L25) | Commands to exercise the security policy. |  |
| [security_policy](outputs.tf#L34) | Security policy id. |  |
<!-- END TFDOC -->
## Test

```hcl
module "test" {
  source     = "./fabric/modules/net-cloud-armor/recipe-regional-waf"
  project_id = "project-1"
  _testing = {
    name   = "project-1"
    number = 1234567890
  }
  region         = "europe-west1"
  trusted_ranges = ["192.0.2.0/24"]
}
# tftest modules=7 resources=31
```
