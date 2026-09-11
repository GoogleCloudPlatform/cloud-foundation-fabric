# Global external Application Load Balancer with Cloud Armor WAF and edge policies

This recipe deploys a Cloud Run application and a static assets bucket behind a global external Application Load Balancer, and protects them with two Cloud Armor security policies managed via the [`net-cloud-armor`](../) module:

- a **backend security policy** (`CLOUD_ARMOR`) attached to the Cloud Run backend service, with preconfigured OWASP WAF rule sets (in preview mode by default), per-client IP rate limiting, an optional geographic allowlist, JSON body parsing and Adaptive Protection L7 DDoS defense;
- an **edge security policy** (`CLOUD_ARMOR_EDGE`) attached to the CDN-enabled backend bucket serving `/static/*`, enforcing the same geographic allowlist upstream of the Cloud CDN cache.

The policies are wired to the load balancer by passing the module `id` outputs to the `security_policy` and `edge_security_policy` attributes of the `net-lb-app-ext` backend configurations.

Once deployed, the `commands` output provides `curl` invocations to verify the behaviour: a request with a SQL injection payload is logged (or denied, if `waf_config.preview` is `false`), and exceeding the configured rate limit returns `429` responses. Cloud Armor logs are available in the load balancer request logs under `jsonPayload.enforcedSecurityPolicy` and `jsonPayload.previewSecurityPolicy`.
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L49) | Project ID. | <code>string</code> | ✓ |  |
| [region](variables.tf#L65) | Region where the Cloud Run service and bucket are deployed. | <code>string</code> | ✓ |  |
| [_testing](variables.tf#L18) | Populate this variable to avoid triggering the data source. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [geo_allowlist](variables.tf#L28) | ISO 3166-1 alpha-2 region codes allowed to reach the application. Leave empty to allow all regions. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [invoker_members](variables.tf#L35) | Identities allowed to invoke the Cloud Run service. Override when the organization restricts allUsers via domain restricted sharing. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#34;allUsers&#34;&#93;</code> |
| [name](variables.tf#L42) | Prefix used for resource names. | <code>string</code> |  | <code>&#34;armor-glb&#34;</code> |
| [rate_limit](variables.tf#L54) | Per-client IP rate limit enforced on the application backend. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [waf_config](variables.tf#L70) | Preconfigured WAF rule sets evaluated on the application backend, and whether they run in preview mode. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [address](outputs.tf#L17) | Load balancer address. |  |
| [commands](outputs.tf#L22) | Commands to exercise the security policies. |  |
| [security_policies](outputs.tf#L32) | Security policy ids. |  |
<!-- END TFDOC -->
## Test

```hcl
module "test" {
  source     = "./fabric/modules/net-cloud-armor/recipe-glb-waf"
  project_id = "project-1"
  _testing = {
    name   = "project-1"
    number = 1234567890
  }
  region        = "europe-west1"
  geo_allowlist = ["IT", "CH"]
  waf_config = {
    preview   = false
    rule_sets = ["sqli-v33-stable", "xss-v33-stable"]
  }
}
# tftest modules=7 resources=27
```
