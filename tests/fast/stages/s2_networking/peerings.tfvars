automation = {
  outputs_bucket = "test"
}
billing_account = {
  id = "000000-111111-222222"
}
factories_config = {
  defaults              = "hub-and-spokes-peerings/defaults.yaml"
  dns                   = "hub-and-spokes-peerings/dns/zones"
  dns-response-policies = "hub-and-spokes-peerings/dns/response-policies"
  firewall-policies     = "hub-and-spokes-peerings/firewall-policies"
  folders               = "hub-and-spokes-peerings/folders"
  interconnect          = "hub-and-spokes-peerings/interconnect"
  ncc-hubs              = "hub-and-spokes-peerings/ncc-hubs"
  nvas                  = "hub-and-spokes-peerings/nvas"
  projects              = "hub-and-spokes-peerings/projects"
  vpcs                  = "hub-and-spokes-peerings/vpcs"
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
