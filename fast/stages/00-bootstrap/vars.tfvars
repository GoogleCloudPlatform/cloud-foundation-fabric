

# use `gcloud beta billing accounts list`
# if you have too many accounts, check the Cloud Console :)
billing_account = {
 id              = "01E654-CF45ED-8F2561"
 organization_id = 737340371464
}

# use `gcloud organizations list`
organization = {
 domain      = "rickompany.joonix.com"
 id          = 737340371464
 customer_id = "C03cjy5j3"
}

outputs_location = "~/fast-config"

# use something unique and short
prefix           = "my-gcp-rgr"

# variables for CI/CD
federated_identity_providers = {
  github-fip = {
    attribute_condition = "attribute.repository_owner==\"rgonzalezr22\""
    issuer              = "github"
    custom_settings     = null
  }
}

cicd_repositories = {
  bootstrap = {
    branch            = null
    identity_provider = "github-fip"
    name              = "rgonzalezr22/fast-bootstrap"
    type              = "github"
  }
  cicd = null
  resman = {
    branch            = null
    identity_provider = "github-fip"
    name              = "rgonzalezr22/fast-resman"
    type              = "github"
  }
}

