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

