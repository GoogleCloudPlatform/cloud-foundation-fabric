automation = {
  outputs_bucket = "test"
}
billing_account = {
  id = "000000-111111-222222"
}
essential_contacts = "gcp-security-admins@fast.example.com"
folder_ids = {
  security = null
}
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
prefix = "fast"
kms_keys = {
  compute = {
    iam = {
      "roles/cloudkms.admin" = ["user:user1@example.com"]
    }
    labels          = { service = "compute" }
    locations       = null
    rotation_period = null
  }
}
service_accounts = {
  security             = "foobar@iam.gserviceaccount.com"
  data-platform-dev    = "foobar@iam.gserviceaccount.com"
  data-platform-prod   = "foobar@iam.gserviceaccount.com"
  nsec                 = "foobar@iam.gserviceaccount.com"
  nsec-r               = "foobar@iam.gserviceaccount.com"
  project-factory      = "foobar@iam.gserviceaccount.com"
  project-factory-dev  = "foobar@iam.gserviceaccount.com"
  project-factory-prod = "foobar@iam.gserviceaccount.com"
}
