automation = {
  outputs_bucket = "fast2-prod-iac-core-outputs"
}
billing_account = {
  id = "000000-111111-222222"
}
environments = {
  dev = {
    is_default = false
    name       = "Development"
    short_name = "dev"
    tag_name   = "development"
  }
}
factories_config = {
  context = {
    iam_principals = {
      data-consumer-bi = "group:gcp-consumer-bi@example.com"
      dp-product-a-0   = "group:gcp-data-product-a-0@example.com"
      dp-domain-a      = "group:gcp-data-domain-a@example.com"
      dp-platform      = "group:dp-platform-0@example.com"
    }
  }
}
folder_ids = {
  data-platform-dev = "folders/00000000000000"
}
host_project_ids = {
  dev-spoke-0 = "fast2-dev-net-spoke-0"
}
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
prefix = "fast2"
subnet_self_links = {
  dev-spoke-0 = {
    "europe-west8/dev-dataplatform" = "projects/fast2-dev-net-spoke-0/regions/europe-west8/subnetworks/dev-dataplatform"
  }
}
vpc_self_links = {
  dev-spoke-0 = "projects/fast2-dev-net-spoke-0/global/networks/dev-spoke-0"
}


