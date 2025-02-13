# Looker Core module

This module manages the creation of a [Looker Core instance](https://cloud.google.com/looker/docs/looker-core).

This module accepts Oauth client ID and secret in the input variable `oauth_config` in case you have
already [set up an oauth client and credentials](https://cloud.google.com/looker/docs/looker-core-create-oauth).
If that is not the case it is possible to specify support_email in the same variable `oauth_config` for a default oauth
client id and secret setup within the terraform script, be aware that **such an oauth client id is not suitable for
authenticating end users**, and it is only used to provision the looker core instance.
You'll still be forced to create a new oauth and update the looker core instance from the console (or gcloud) as there
is no terraform support for these resources.


> [!WARNING]
> Please be aware that, at the time of this writing, deleting the looker core instance via terraform is not possible due
> to https://github.com/hashicorp/terraform-provider-google/issues/19467. The work-around is to delete the instance from the
> console (or gcloud with force option) and remove the corresponding resource from the terraform state.

<!-- TOC -->

* [Looker Core module](#looker-core-module)
    * [Examples](#examples)
        * [Simple example](#simple-example)
        * [Looker Core private instance with PSA](#looker-core-private-instance-with-psa)
        * [Looker Core full example](#looker-core-full-example)
    * [Variables](#variables)
    * [Outputs](#outputs)

<!-- TOC -->

## Examples

### Simple example

This example shows how to set up a public Looker Core instance.

```hcl
module "looker" {
  source     = "./fabric/modules/looker-core"
  project_id = var.project_id
  region     = var.region
  name       = "looker"
  network_config = {
    public = true
  }
  oauth_config = {
    support_email = "support@google.com"
  }
}
# tftest modules=1 resources=3 inventory=simple.yaml
```

### Looker Core private instance with PSA

```hcl
module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  parent          = var.folder_id
  name            = "looker"
  prefix          = var.prefix
  services = [
    "servicenetworking.googleapis.com",
    "looker.googleapis.com",
  ]
}

module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = module.project.project_id
  name       = "my-network"
  psa_configs = [
    {
      ranges = { looker = "10.60.0.0/16" }
    }
  ]
}

module "looker" {
  source     = "./fabric/modules/looker-core"
  project_id = module.project.project_id
  region     = var.region
  name       = "looker"
  network_config = {
    psa_config = {
      network = module.vpc.id
    }
  }
  oauth_config = {
    support_email = "support@google.com"
  }
  platform_edition = "LOOKER_CORE_ENTERPRISE_ANNUAL"
}
# tftest modules=3 resources=16 inventory=psa.yaml
```

### Looker Core full example

```hcl
module "project" {
  source          = "./fabric/modules/project"
  billing_account = var.billing_account_id
  parent          = var.folder_id
  name            = "looker"
  prefix          = var.prefix
  services = [
    "cloudkms.googleapis.com",
    "iap.googleapis.com",
    "looker.googleapis.com",
    "servicenetworking.googleapis.com"
  ]
}

module "vpc" {
  source     = "./fabric/modules/net-vpc"
  project_id = module.project.project_id
  name       = "my-network"
  psa_configs = [
    {
      ranges = { looker = "10.60.0.0/16" }
    }
  ]
}

module "kms" {
  source     = "./fabric/modules/kms"
  project_id = module.project.project_id
  keyring = {
    location = var.region
    name     = "keyring"
  }
  keys = {
    "key-regional" = {
    }
  }
  iam = {
    "roles/cloudkms.cryptoKeyEncrypterDecrypter" = [
      module.project.service_agents.looker.iam_email
    ]
  }
}

module "looker" {
  source     = "./fabric/modules/looker-core"
  project_id = module.project.project_id
  region     = var.region
  name       = "looker"
  admin_settings = {
    allowed_email_domains = ["google.com"]
  }
  encryption_config = {
    kms_key_name = module.kms.keys.key-regional.id
  }
  network_config = {
    psa_config = {
      network = module.vpc.id
    }
  }
  oauth_config = {
    client_id     = "xxxxxxxxx"
    client_secret = "xxxxxxxx"
  }
  platform_edition = "LOOKER_CORE_ENTERPRISE_ANNUAL"
}
# tftest modules=4 resources=22 inventory=full.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [name](variables.tf#L91) | Name of the looker core instance. | <code>string</code> | ✓ |  |
| [network_config](variables.tf#L96) | Network configuration for cluster and instance. Only one between psa_config and psc_config can be used. | <code title="object&#40;&#123;&#10;  psa_config &#61; optional&#40;object&#40;&#123;&#10;    network            &#61; string&#10;    allocated_ip_range &#61; optional&#40;string&#41;&#10;    enable_public_ip   &#61; optional&#40;bool, false&#41;&#10;    enable_private_ip  &#61; optional&#40;bool, true&#41;&#10;  &#125;&#41;&#41;&#10;  public &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [oauth_config](variables.tf#L114) | Looker Core Oauth config. Either client ID and secret (existing oauth client) or support email (temporary internal oauth client setup) must be specified. | <code title="object&#40;&#123;&#10;  client_id     &#61; optional&#40;string, null&#41;&#10;  client_secret &#61; optional&#40;string, null&#41;&#10;  support_email &#61; optional&#40;string, null&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [project_id](variables.tf#L147) | The ID of the project where this instances will be created. | <code>string</code> | ✓ |  |
| [region](variables.tf#L152) | Region for the Looker core instance. | <code>string</code> | ✓ |  |
| [admin_settings](variables.tf#L17) | Looker Core admins settings. | <code title="object&#40;&#123;&#10;  allowed_email_domains &#61; list&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [custom_domain](variables.tf#L26) | Looker core instance custom domain. | <code>string</code> |  | <code>null</code> |
| [encryption_config](variables.tf#L32) | Set encryption configuration. KMS name format: 'projects/[PROJECT]/locations/[REGION]/keyRings/[RING]/cryptoKeys/[KEY_NAME]'. | <code title="object&#40;&#123;&#10;  kms_key_name &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [maintenance_config](variables.tf#L41) | Set maintenance window configuration and maintenance deny period (up to 90 days). Date format: 'yyyy-mm-dd'. | <code title="object&#40;&#123;&#10;  maintenance_window &#61; optional&#40;object&#40;&#123;&#10;    day &#61; optional&#40;string, &#34;SUNDAY&#34;&#41;&#10;    start_time &#61; optional&#40;object&#40;&#123;&#10;      hours   &#61; optional&#40;number, 23&#41;&#10;      minutes &#61; optional&#40;number, 0&#41;&#10;      seconds &#61; optional&#40;number, 0&#41;&#10;      nanos   &#61; optional&#40;number, 0&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;, null&#41;&#10;  deny_maintenance_period &#61; optional&#40;object&#40;&#123;&#10;    start_date &#61; object&#40;&#123;&#10;      year  &#61; number&#10;      month &#61; number&#10;      day   &#61; number&#10;    &#125;&#41;&#10;    end_date &#61; object&#40;&#123;&#10;      year  &#61; number&#10;      month &#61; number&#10;      day   &#61; number&#10;    &#125;&#41;&#10;    start_time &#61; optional&#40;object&#40;&#123;&#10;      hours   &#61; optional&#40;number, 23&#41;&#10;      minutes &#61; optional&#40;number, 0&#41;&#10;      seconds &#61; optional&#40;number, 0&#41;&#10;      nanos   &#61; optional&#40;number, 0&#41;&#10;    &#125;&#41;, &#123;&#125;&#41;&#10;  &#125;&#41;, null&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |
| [platform_edition](variables.tf#L127) | Platform editions for a Looker instance. Each edition maps to a set of instance features, like its size. | <code>string</code> |  | <code>&#34;LOOKER_CORE_TRIAL&#34;</code> |
| [prefix](variables.tf#L137) | Optional prefix used to generate instance names. | <code>string</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [egress_public_ip](outputs.tf#L17) | Public IP address of Looker instance for egress. |  |
| [id](outputs.tf#L22) | Fully qualified primary instance id. |  |
| [ingress_private_ip](outputs.tf#L27) | Private IP address of Looker instance for ingress. |  |
| [ingress_public_ip](outputs.tf#L32) | Public IP address of Looker instance for ingress. |  |
| [instance](outputs.tf#L37) | Looker Core instance resource. | ✓ |
| [instance_name](outputs.tf#L43) | Name of the looker instance. |  |
| [looker_uri](outputs.tf#L48) | Looker core URI. |  |
| [looker_version](outputs.tf#L53) | Looker core version. |  |
<!-- END TFDOC -->
