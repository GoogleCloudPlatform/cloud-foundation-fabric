# GKE hub module

This module allows simplified creation and management of GKE Hub object and its feature for a given set of clusters.
The given list of clusters will be registered inside the Hub and all the configure features will be activated on all the clusters.

## GKE Hub configuration

```hcl
module "gke-hub-configuration" {
  source     = "./modules/gke-hub"
  hub_config = {
    clusters = [
      { name = "cluster-1", location = "europe-west1" },
    ]
    config_sync = null
    policy_controller = {
      enabled                 = true
      enable_template_library = true
      enable_log_denies       = false
      exemptable_namespaces   = ["config-management-monitoring", "config-management-system"]
    }
  }
  project_id = "myproject"
}
# tftest modules=1 resources=3
```

### Module defaults

### Internally managed service account


<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default | producer |
|---|---|:---:|:---:|:---:|:---:|
| [hub_config](variables.tf#L55) |  | <code title="object&#40;&#123;&#10;  clusters &#61; list&#40;map&#40;string&#41;&#41;&#10;  config_sync &#61; object&#40;&#123;&#10;    repository_branch        &#61; string&#10;    repository_url           &#61; string&#10;    repository_source_format &#61; string&#10;    repository_secret_type   &#61; string&#10;    repository_policy_dir    &#61; string&#10;    workload_identity_sa     &#61; string&#10;  &#125;&#41;&#10;  policy_controller &#61; object&#40;&#123;&#10;    enabled                 &#61; bool&#10;    enable_template_library &#61; bool&#10;    enable_log_denies       &#61; bool&#10;    exemptable_namespaces   &#61; list&#40;string&#41;&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |  |
| [project_id](variables.tf#L75) | Cluster project ID. | <code>string</code> | ✓ |  |  |
| [config_sync_defaults](variables.tf#L17) | Default values for optional config_sync configurations. | <code title="object&#40;&#123;&#10;  repository_url           &#61; string&#10;  repository_branch        &#61; string&#10;  repository_source_format &#61; string&#10;  repository_policy_dir    &#61; string&#10;  repository_secret_type   &#61; string&#10;  workload_identity_sa     &#61; string&#10;  secret_type              &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  repository_url           &#61; null&#10;  repository_branch        &#61; &#34;main&#34;&#10;  repository_source_format &#61; &#34;hierarchy&#34;&#10;  repository_policy_dir    &#61; &#34;configsync&#34;&#10;  repository_secret_type   &#61; &#34;gcpserviceaccount&#34;&#10;  workload_identity_sa     &#61; null&#10;  secret_type              &#61; &#34;gcpserviceaccount&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [policy_controller_defaults](variables.tf#L39) | Default values for optional config_sync configurations. | <code title="object&#40;&#123;&#10;  enabled                 &#61; bool&#10;  enable_template_library &#61; bool&#10;  enable_log_denies       &#61; bool&#10;  exemptable_namespaces   &#61; list&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  enabled                 &#61; true&#10;  enable_template_library &#61; true&#10;  enable_log_denies       &#61; true&#10;  exemptable_namespaces   &#61; &#91;&#34;config-management-monitoring&#34;, &#34;config-management-system&#34;&#93;&#10;&#125;">&#123;&#8230;&#125;</code> |  |

<!-- END TFDOC -->
