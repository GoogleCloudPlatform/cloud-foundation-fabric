# use `gcloud beta billing accounts list`
# if you have too many accounts, check the Cloud Console :)
billing_account = {
  id = "01FF8F-4431B6-5A9F44"
}

# use `gcloud organizations list`
organization = {
  domain      = "ozoneproject.com"
  id          = 674021023397
  customer_id = "C02ba2um1"
}

outputs_location = "~/fast-config"

# use something unique and no longer than 9 characters
prefix = "ozpr"

# cicd_repositories = {
#   bootstrap = {
#     branch            = "main"
#     identity_provider = "github-sample"
#     name              = "my-gh-org/fast-bootstrap"
#     type              = "github"
#   }
#   resman = {
#     branch            = "main"
#     identity_provider = "github-sample"
#     name              = "my-gh-org/fast-resman"
#     type              = "github"
#   }
# }

federated_identity_providers = {
  # Use the public GitHub and specify an attribute condition
  github = {
    attribute_condition = "attribute.repository_owner==\"ozone-project\""
    issuer              = "github"
  }
}