automation = {
  outputs_bucket = "test"
}
billing_account = {
  id = "000000-111111-222222"
}
factories_config = {
  defaults              = "datasets/hub-and-spokes-vpns/defaults.yaml"
  dns                   = "datasets/hub-and-spokes-vpns/dns/zones"
  dns-response-policies = "datasets/hub-and-spokes-vpns/dns/response-policies"
  firewall-policies     = "datasets/hub-and-spokes-vpns/firewall-policies"
  folders               = "datasets/hub-and-spokes-vpns/folders"
  interconnect          = "datasets/hub-and-spokes-vpns/interconnect"
  ncc-hubs              = "datasets/hub-and-spokes-vpns/ncc-hubs"
  nvas                  = "datasets/hub-and-spokes-vpns/nvas"
  projects              = "datasets/hub-and-spokes-vpns/projects"
  vpcs                  = "datasets/hub-and-spokes-vpns/vpcs"
}

folder_ids = {
  "networking"      = "folders/12345678"
  "networking/prod" = "folders/23456789"
  "networking/dev"  = "folders/34567890"
}
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
prefix = "fast"
service_accounts = {
  "iac-0/iac-pf-rw" = "iac-pf-rw@test.iam.gserviceaccount.com"
  "iac-0/iac-pf-ro" = "iac-pf-ro@test.iam.gserviceaccount.com"
}
storage_buckets = {
  "iac-0/iac-outputs" = "test"
}
tag_values = {
  "environment/development" = "tagValues/12345"
  "environment/production"  = "tagValues/12346"
}
