billing_account = {
  id = "000000-111111-222222"
}
factories_config = {
  paths = {
    keyrings = "./service-agent-data/keyrings"
    defaults = "./service-agent-data/defaults.yaml"
    projects = "./service-agent-data/projects"
  }
}
organization = {
  domain      = "fast.example.com"
  id          = 123456789012
  customer_id = "C00000000"
}
prefix = "fast"
storage_buckets = {
  "iac-0/iac-outputs" = "test"
}
