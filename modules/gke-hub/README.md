# GKE hub module

This module allows simplified creation and management of GKE Hub object and its features for a given set of clusters.
The given list of clusters will be registered inside the Hub and all the configure features will be activated on all the clusters.

## GKE Hub configuration

```hcl
module "gke-hub-configuration" {
  source     = "./modules/gke-hub"
  project_id = "myproject"
  features        = {
    configmanagement             = true
    multiclusteringress          = false
    multiclusterservicediscovery = false
  }
  member_clusters = {
    "cluster-1" = "europe-west1"
  }
  member_features = {
    multiclusteringress          = false
    multiclusterservicediscovery = false
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
        enabled                    = true
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
# tftest modules=1 resources=5
```

### Module required APIs
The module does not enable the required APIs for the target cloud services.
The required APIs should be enabled on the parent project on a need basis and are:
```
# GKE Hub and Configmanagement
"gkehub.googleapis.com"
"gkeconnect.googleapis.com"
"anthosconfigmanagement.googleapis.com"
"multiclusteringress.googleapis.com"
"multiclusterservicediscovery.googleapis.com"
```

<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [project_id](variables.tf#L74) | GKE hub project ID. | <code>string</code> | ✓ |  |
| [features](variables.tf#L17) | GKE hub features to enable. | <code title="object&#40;&#123;&#10;  configmanagement             &#61; bool&#10;  multiclusteringress          &#61; bool&#10;  multiclusterservicediscovery &#61; bool&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  configmanagement             &#61; true&#10;  multiclusteringress          &#61; false&#10;  multiclusterservicediscovery &#61; false&#10;&#125;">&#123;&#8230;&#125;</code> |
| [member_clusters](variables.tf#L31) | List for member cluster self links. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [member_features](variables.tf#L37) | Member features for each cluster | <code title="object&#40;&#123;&#10;  configmanagement &#61; object&#40;&#123;&#10;    version &#61; string&#10;    config_sync &#61; object&#40;&#123;&#10;      https_proxy               &#61; string&#10;      sync_repo                 &#61; string&#10;      sync_branch               &#61; string&#10;      sync_rev                  &#61; string&#10;      secret_type               &#61; string&#10;      gcp_service_account_email &#61; string&#10;      policy_dir                &#61; string&#10;      source_format             &#61; string&#10;    &#125;&#41;&#10;    policy_controller &#61; object&#40;&#123;&#10;      enabled                    &#61; bool&#10;      log_denies_enabled         &#61; bool&#10;      referential_rules_enabled  &#61; bool&#10;      exemptable_namespaces      &#61; list&#40;string&#41;&#10;      template_library_installed &#61; bool&#10;    &#125;&#41;&#10;    binauthz &#61; object&#40;&#123;&#10;      enabled &#61; bool&#10;    &#125;&#41;&#10;    hierarchy_controller &#61; object&#40;&#123;&#10;      enabled                            &#61; bool&#10;      enable_pod_tree_labels             &#61; bool&#10;      enable_hierarchical_resource_quota &#61; bool&#10;    &#125;&#41;&#10;  &#125;&#41;&#10;  multiclusteringress          &#61; bool&#10;  multiclusterservicediscovery &#61; bool&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

<!-- END TFDOC -->