# GKE hub module

This module allows simplified creation and management of GKE Hub object and its features for a given set of clusters.
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
# tftest modules=1 resources=7
```

### Module defaults
The attributes config_sync and policy_controller are implemented with an overrides logic. 

If null is specified, the default values are:
```
config_sync = {
  repository_url           = null
  repository_branch        = "main"
  repository_source_format = "hierarchy"
  repository_policy_dir    = "configsync"
  repository_secret_type   = "gcpserviceaccount"
  workload_identity_sa     = null
  secret_type              = "gcpserviceaccount"
}
```
The config_sync default settings will let the module create a new dedicated service account and a google source repository. 
The SA will be used trough Workload Identity, in the GKE cluster/s, to download configurations from the repository.

```
policy_controller = {
  enabled                 = true
  enable_template_library = true
  enable_log_denies       = true
  exemptable_namespaces   = ["config-management-monitoring", "config-management-system"]
}
```
The policy_controller default settings will let the module to enable the policy_controller with the default template_library and log_denies enabled, 
config-management-monitoring and config-management-system namespaces will be excluded from the policies enforcement.

### Internally managed service account
To have the module auto-create a service account for config_sync, set the `workload_identity_sa` variable to `null`. 
When a service account is created by the module, the service account resource and email (in both plain and IAM formats) are then available in outputs to assign IAM roles from your own code.

To have the module auto-create a source repository for config_sync, set the `repository_url` variable to `null`. 
When a Google Source Repository is created by the module, the sourcerepo resource and uurl are then available in outputs.


### TODO
MultiClusterServices feature is not yet implemented within the module.

<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default | producer |
|---|---|:---:|:---:|:---:|:---:|
| [hub_config](variables.tf#L55) |  | <code title="object&#40;&#123;&#10;  clusters &#61; list&#40;map&#40;string&#41;&#41;&#10;  config_sync &#61; object&#40;&#123;&#10;    repository_branch        &#61; string&#10;    repository_url           &#61; string&#10;    repository_source_format &#61; string&#10;    repository_secret_type   &#61; string&#10;    repository_policy_dir    &#61; string&#10;    workload_identity_sa     &#61; string&#10;  &#125;&#41;&#10;  policy_controller &#61; object&#40;&#123;&#10;    enabled                 &#61; bool&#10;    enable_template_library &#61; bool&#10;    enable_log_denies       &#61; bool&#10;    exemptable_namespaces   &#61; list&#40;string&#41;&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |  |
| [project_id](variables.tf#L75) | Cluster project ID. | <code>string</code> | ✓ |  |  |
| [config_sync_defaults](variables.tf#L17) | Default values for optional config_sync configurations. | <code title="object&#40;&#123;&#10;  repository_url           &#61; string&#10;  repository_branch        &#61; string&#10;  repository_source_format &#61; string&#10;  repository_policy_dir    &#61; string&#10;  repository_secret_type   &#61; string&#10;  workload_identity_sa     &#61; string&#10;  secret_type              &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  repository_url           &#61; null&#10;  repository_branch        &#61; &#34;main&#34;&#10;  repository_source_format &#61; &#34;hierarchy&#34;&#10;  repository_policy_dir    &#61; &#34;configsync&#34;&#10;  repository_secret_type   &#61; &#34;gcpserviceaccount&#34;&#10;  workload_identity_sa     &#61; null&#10;  secret_type              &#61; &#34;gcpserviceaccount&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |  |
| [policy_controller_defaults](variables.tf#L39) | Default values for optional config_sync configurations. | <code title="object&#40;&#123;&#10;  enabled                 &#61; bool&#10;  enable_template_library &#61; bool&#10;  enable_log_denies       &#61; bool&#10;  exemptable_namespaces   &#61; list&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  enabled                 &#61; true&#10;  enable_template_library &#61; true&#10;  enable_log_denies       &#61; true&#10;  exemptable_namespaces   &#61; &#91;&#34;config-management-monitoring&#34;, &#34;config-management-system&#34;&#93;&#10;&#125;">&#123;&#8230;&#125;</code> |  |

## Outputs

| name | description | sensitive | consumers |
|---|---|:---:|---|
| [google_sourcerepo_repository](outputs.tf#L44) | Service account resource. |  |  |
| [service_account](outputs.tf#L17) | Service account resource. |  |  |
| [service_account_email](outputs.tf#L26) | Service account email. |  |  |
| [service_account_iam_email](outputs.tf#L35) | Service account email. |  |  |
| [sourcerepo_repository_url](outputs.tf#L53) | Source repository url. |  |  |

<!-- END TFDOC -->