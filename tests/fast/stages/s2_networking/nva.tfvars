automation = {
  outputs_bucket = "test"
}
billing_account = {
  id = "000000-111111-222222"
}
factories_config = {
  defaults              = "datasets/hub-and-spokes-nva/defaults.yaml"
  dns                   = "datasets/hub-and-spokes-nva/dns/zones"
  dns-response-policies = "datasets/hub-and-spokes-nva/dns/response-policies"
  firewall-policies     = "datasets/hub-and-spokes-nva/firewall-policies"
  folders               = "datasets/hub-and-spokes-nva/folders"
  interconnect          = "datasets/hub-and-spokes-nva/interconnect"
  ncc-hubs              = "datasets/hub-and-spokes-nva/ncc-hubs"
  nvas                  = "datasets/hub-and-spokes-nva/nvas"
  projects              = "datasets/hub-and-spokes-nva/projects"
  vpcs                  = "datasets/hub-and-spokes-nva/vpcs"
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
tag_values = {
  "environment/development" = "tagValues/12345"
  "environment/production"  = "tagValues/12346"
}
