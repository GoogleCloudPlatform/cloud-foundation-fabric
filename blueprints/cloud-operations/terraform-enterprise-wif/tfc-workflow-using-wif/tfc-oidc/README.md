# Terraform Enterprise OIDC Credential for GCP Workload Identity Federation

This is a helper module to prepare GCP Credentials from Terraform Enterprise workload identity token. For more information see [Terraform Enterprise Workload Identity Federation](../) blueprint.

## Example
```hcl
module "tfe_oidc" {
  source = "./tfc-oidc"

  impersonate_service_account_email = "tfe-test@tfe-test-wif.iam.gserviceaccount.com"
}

provider "google" {
  credentials = module.tfe_oidc.credentials
}

provider "google-beta" {
  credentials = module.tfe_oidc.credentials
}

# tftest skip
```
<!-- BEGIN TFDOC -->

## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [impersonate_service_account_email](variables.tf#L17) | Service account to be impersonated by workload identity federation. | <code>string</code> | ✓ |  |
| [tmp_oidc_token_path](variables.tf#L22) | Name of the temporary file where TFC OIDC token will be stored to authentificate terraform provider google. | <code>string</code> |  | <code>&#34;.oidc_token&#34;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [credentials](outputs.tf#L17) | Credentials in format to pass the to gcp provider. |  |

<!-- END TFDOC -->
