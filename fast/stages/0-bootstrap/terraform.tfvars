# use `gcloud beta billing accounts list`
# if you have too many accounts, check the Cloud Console :)
billing_account = {
  id = "0189FA-E139FD-136A58"
  no_iam = true
}

# use `gcloud organizations list`
organization = {
  domain      = "chaos.joonix.net"
  id          = 97682669835
  customer_id = "C00hcluio"
}

outputs_location = "~/fast-config"

# use something unique and no longer than 9 characters
prefix = "fastdemo0"

iam = {
 "roles/browser" = [
   "group:cloud-gong-hierarchy_management-hm_tool-latchkey-presubmits@twosync-src.google.com",
   "serviceAccount:latchkey-multiorg-ephemeral-organization-automation@system.gserviceaccount.com"
 ]
 "roles/resourcemanager.organizationAdmin" = [
   "serviceAccount:latchkey-multiorg-ephemeral-iam-automation@system.gserviceaccount.com"
 ]
}
iam_additive = {
 "roles/iam.organizationRoleAdmin" = [
   "serviceAccount:latchkey-multiorg-ephemeral-custom-automation@system.gserviceaccount.com"
 ]
}
