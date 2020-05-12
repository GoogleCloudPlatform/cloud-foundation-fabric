# Google Cloud Service Directory Module

This module allows managing a single [Service Directory](https://cloud.google.com/service-directory) namespace, including multiple services, endpoints and IAM bindings at the namespace and service levels.

It can be used in conjunction with the [DNS](../dns) module to create service-directory based DNS zones, offloading IAM control of `A` and `SRV` records at the namespace or service level to Service Directory. The last examples shows how to wire the two modules together.


## Examples

### Namespace with IAM

```hcl
module "service-directory" {
  source      = "./modules/service-directory"
  project_id  = "my-project"
  location    = "europe-west1"
  name        = "sd-1"
  iam_members = {
    "roles/servicedirectory.editor" = [
      "serviceAccount:namespace-editor@example.com"
    ]
  }
  iam_roles = [
    "roles/servicedirectory.editor"
  ]
}
```

### Services with IAM and endpoints

```hcl
module "service-directory" {
  source      = "./modules/service-directory"
  project_id  = "my-project"
  location    = "europe-west1"
  name        = "sd-1"
  services = {
    one = {
      endpoints = ["first", "second"]
      metadata  = null
    }
  }
  service_iam_members = {
    one = {
      "roles/servicedirectory.editor" = [
        "serviceAccount:service-editor.example.com"
      ]
    }
  }
  service_iam_roles = {
    one = ["roles/servicedirectory.editor"]
  }
  endpoint_config = {
    "one/first"  = { address = "127.0.0.1", port = 80, metadata = {} }
    "one/second" = { address = "127.0.0.2", port = 80, metadata = {} }
  }
}
```

### DNS based zone

Wiring a service directory namespace to a private DNS zone allows querying the namespace, and delegating control of DNS records at the namespace or service level. This effectively allows fine grained ACL control of Cloud DNS zones.

```hcl
module "service-directory" {
  source      = "./modules/service-directory"
  project_id  = "my-project"
  location    = "europe-west1"
  name       = "apps"
  services = {
    app1 = { endpoints = ["one"], metadata = null }
  }
  endpoint_config = {
    "app1/one" = { address = "127.0.0.1", port = 80, metadata = {} }
  }
}

module "dns-sd" {
  source                      = "./modules/dns"
  project_id                  = "my-project"
  type                        = "service-directory"
  name                        = "apps"
  domain                      = "apps.example.org."
  client_networks             = [local.vpc_self_link]
  service_directory_namespace = module.service-directory.id
}

```

<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---: |:---:|:---:|
| location | Namespace location. | <code title="">string</code> | ✓ |  |
| name | Namespace name. | <code title="">string</code> | ✓ |  |
| project_id | Project used for resources. | <code title="">string</code> | ✓ |  |
| *endpoint_config* | Map of endpoint attributes, keys are in service/endpoint format. | <code title="map&#40;object&#40;&#123;&#10;address  &#61; string&#10;port     &#61; number&#10;metadata &#61; map&#40;string&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |
| *iam_members* | IAM members for each namespace role. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *iam_roles* | IAM roles for the namespace. | <code title="list&#40;string&#41;">list(string)</code> |  | <code title="">[]</code> |
| *labels* | Labels. | <code title="map&#40;string&#41;">map(string)</code> |  | <code title="">{}</code> |
| *service_iam_members* | IAM members for each service and role. | <code title="map&#40;map&#40;list&#40;string&#41;&#41;&#41;">map(map(list(string)))</code> |  | <code title="">{}</code> |
| *service_iam_roles* | IAM roles for each service. | <code title="map&#40;list&#40;string&#41;&#41;">map(list(string))</code> |  | <code title="">{}</code> |
| *services* | Service configuration, using service names as keys. | <code title="map&#40;object&#40;&#123;&#10;endpoints &#61; list&#40;string&#41;&#10;metadata  &#61; map&#40;string&#41;&#10;&#125;&#41;&#41;">map(object({...}))</code> |  | <code title="">{}</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| endpoints | Endpoint resources. |  |
| id | Namespace id (short name). |  |
| name | Namespace name (long name). |  |
| namespace | Namespace resource. |  |
| service_id | Service ids (short names). |  |
| service_names | Service ids (long names). |  |
| services | Service resources. |  |
<!-- END TFDOC -->
