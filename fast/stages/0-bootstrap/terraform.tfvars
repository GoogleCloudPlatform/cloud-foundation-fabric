# use `gcloud beta billing accounts list`
# if you have too many accounts, check the Cloud Console :)
billing_account = {
  id = "01D5CE-A97DDF-E2952F"
}

# use `gcloud organizations list`
organization = {
  domain      = "sandbox.timeout.com"
  id          = 1032553045476
  customer_id = "C0179cs6k"
}

outputs_location = "../fast-config"

# use something unique and no longer than 9 characters
prefix = "tosbx"

fast_features = {
  data_platform = true
}
