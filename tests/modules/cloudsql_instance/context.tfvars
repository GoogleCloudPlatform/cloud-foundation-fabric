context = {
  kms_keys    = { mykey = "projects/myprj/locations/europe-west8/keyRings/mykr/cryptoKeys/mykey" }
  locations   = { ew8 = "europe-west8" }
  networks    = { myvpc = "projects/myprj/global/networks/myvpc" }
  project_ids = { myprj = "my-project" }
}
project_id       = "$project_ids:myprj"
region           = "$locations:ew8"
name             = "db-test"
database_version = "POSTGRES_13"
tier             = "db-g1-small"
network_config = {
  connectivity = {
    psc_allowed_consumer_projects = ["$project_ids:myprj"]
    psa_config = {
      private_network = "$networks:myvpc"
    }
  }
}
encryption_key_name           = "$kms_keys:mykey"
gcp_deletion_protection       = false
terraform_deletion_protection = false
insights_config = {
  query_string_length             = 2048
  record_application_tags         = true
  record_client_address           = true
  query_plans_per_minute          = 10
  enhanced_query_insights_enabled = true
}

