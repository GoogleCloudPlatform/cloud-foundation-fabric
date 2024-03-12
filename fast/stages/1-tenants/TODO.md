# Multitenant stages todo list

## Tenant management via an additional organization-level stage 1

An additional stage 1 manages tenants, basically emulating a lightweight bootstrap for each teanant to decouple it from the org.

The distinction between light and hard tenant does not exist anymore: every tenant has the basics that allow bolting on FAST from stage 1. If tenants don't need support for FAST stages, a simple tenant-level configuration allows defining split management where the tenant context has minimal tenant-level resources managed by the core team.

The `tenant_configs` variable sets tenant configuration:

- tenant short and descriptive names
- optional tenant-level billing account and billing-related settings
- optional tenant-level Cloud Identity
- tenant administrative principal and optional extra IAM roles
- optional federated identity provider and CI/CD configuration
- global-level settings that can differ from the organization ones

This is the type of the `tenant_configs` variable:

```hcl
variable "tenant_configs" {
  description = "Tenant configurations, keyed by tenant short name."
  type = map(object({
    admin_principal  = string
    descriptive_name = string
    fast_support     = optional(bool, false)
    billing  = optional(object({
      account_id = string
      no_iam     = optional(bool, false)
    }))
    cicd_repository = optional({
      name              = string
      type              = string
      branch            = optional(string)
      identity_provider = optional(string)
    })
    cloud_identity = optional(object({
      customer_id = string
      domain      = string
    }))
    locations = optional({
      bq      = optional(string, "EU")
      gcs     = optional(string, "EU")
      logging = optional(string, "global")
      pubsub  = optional(list(string), [])
    })
    workforce_identity_provider = optional(object({
      attribute_condition = optional(string)
      issuer              = string
      display_name        = string
      description         = string
      disabled            = optional(bool, false)
      saml = optional(object({
        idp_metadata_xml = string
      }), null)
    }))
    workload_identity_provider = optional(object({
      attribute_condition = optional(string)
      issuer              = string
      custom_settings = optional(object({
        issuer_uri = optional(string)
        audiences  = optional(list(string), [])
        jwks_json  = optional(string)
      }), {})
    }))
  }))
  nullable = false
  default  = {}
}
```

- spit out a single tfvars file to bootstrap multitenants from org-level resman
- billing account is tenant-level configuration
- cloud identity could be different
- tenants have their own tag hierarchy

merge lightweight and hard tenants, so

- stage 1 creates the tenant top-level folder and main SA
- tenant bootstrap works on stage 1 created tenants and is optional if FAST compatibility is desired

stage 2/3 SAs for the tenant can happen later, as the assumption is there's
billing admin on the billing account for tenant-level resman SA

ideally, the only required tenant-level stage is stage 0 to decouple from the org

which means org-level stage 1 should accept an arbitrary node instead of depending on the org

## teams vs tenants

Teams use

- the org Cloud Identity
- the org billing account
- the org tag system

Teams don't

- control org policies unless via tags they can associate
