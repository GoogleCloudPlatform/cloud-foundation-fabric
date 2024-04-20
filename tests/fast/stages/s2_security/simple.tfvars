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
  project-factory-dev  = "foobar@iam.gserviceaccount.com"
  project-factory-prod = "foobar@iam.gserviceaccount.com"
}
factories_config = {
  vpc-sc = {
    access_levels    = "../../../../tests/fast/stages/s2_security/data/vpc-sc/access-levels"
    egress_policies  = "../../../../tests/fast/stages/s2_security/data/vpc-sc/egress-policies"
    ingress_policies = "../../../../tests/fast/stages/s2_security/data/vpc-sc/ingress-policies"
  }
}
vpc_sc = {
  perimeter_default = {
    access_levels    = ["geo_it", "identity_me"]
    egress_policies  = ["test"]
    ingress_policies = ["test"]
    dry_run          = true
    resources = [
      "projects/1234567890"
    ]
  }
  resource_discovery = {
    enabled = false
  }
}
