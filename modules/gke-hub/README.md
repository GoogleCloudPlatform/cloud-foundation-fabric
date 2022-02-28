# GKE hub module

This module allows simplified creation and management of a GKE Hub object and its features for a given set of clusters. The given list of clusters will be registered inside the Hub and all the configured features will be activated.

To use this module you must ensure the following APIs are enabled in the target project:
```
"gkehub.googleapis.com"
"gkeconnect.googleapis.com"
"anthosconfigmanagement.googleapis.com"
"multiclusteringress.googleapis.com"
"multiclusterservicediscovery.googleapis.com"
```

## GKE Hub configuration

```hcl
module "gke-hub-configuration" {
  source     = "./modules/gke-hub"
  project_id = "myproject"
  features        = {
    configmanagement    = true
    mc_ingress          = false
    mc_servicediscovery = false
  }
  member_clusters = [
    "projects/myproject/locations/europe-west1/clusters/cluster-1"
  ]
  member_features = {
    mc-ingress          = false
    mc-servicediscovery = false
    configmanagement = {
      version = "1.10.0"
      config_sync = {
        https_proxy               = ""
        sync_repo                 = "https://github.com/danielmarzini/configsync-platform-example"
        sync_branch               = "main"
        sync_rev                  = ""
        secret_type               = "none"
        gcp_service_account_email = ""
        policy_dir                = "configsync"
        source_format             = "hierarchy"
      }
      policy_controller = {
        template_library_installed = true
        log_denies_enabled         = false
        referential_rules_enabled  = false
        exemptable_namespaces      = ["config-management-monitoring", "config-management-system"]
      }
      binauthz             = null
      hierarchy_controller = null
    }
  }
}
# tftest modules=1 resources=4
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L71) | GKE hub project ID. | <code>string</code> | ✓ |  |
| [features](variables.tf#L17) | GKE hub features to enable. | <code title="object&#40;&#123;&#10;  configmanagement    &#61; bool&#10;  mc_ingress          &#61; bool&#10;  mc_servicediscovery &#61; bool&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  configmanagement    &#61; true&#10;  mc_ingress          &#61; false&#10;  mc_servicediscovery &#61; false&#10;&#125;">&#123;&#8230;&#125;</code> |
| [member_clusters](variables.tf#L31) | List for member cluster self links. | <code>list&#40;string&#41;</code> |  | <code>&#91;&#93;</code> |
| [member_features](variables.tf#L38) | Member features for each cluster | <code title="object&#40;&#123;&#10;  configmanagement &#61; object&#40;&#123;&#10;    binauthz &#61; bool&#10;    config_sync &#61; object&#40;&#123;&#10;      gcp_service_account_email &#61; string&#10;      https_proxy               &#61; string&#10;      policy_dir                &#61; string&#10;      secret_type               &#61; string&#10;      source_format             &#61; string&#10;      sync_branch               &#61; string&#10;      sync_repo                 &#61; string&#10;      sync_rev                  &#61; string&#10;    &#125;&#41;&#10;    hierarchy_controller &#61; object&#40;&#123;&#10;      enable_hierarchical_resource_quota &#61; bool&#10;      enable_pod_tree_labels             &#61; bool&#10;    &#125;&#41;&#10;    policy_controller &#61; object&#40;&#123;&#10;      exemptable_namespaces      &#61; list&#40;string&#41;&#10;      log_denies_enabled         &#61; bool&#10;      referential_rules_enabled  &#61; bool&#10;      template_library_installed &#61; bool&#10;    &#125;&#41;&#10;    version &#61; string&#10;  &#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

<!-- END TFDOC -->
