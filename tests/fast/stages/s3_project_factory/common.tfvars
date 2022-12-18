data_dir             = "../../../../tests/fast/stages/s03_project_factory/data/projects/"
defaults_file        = "../../../../tests/fast/stages/s03_project_factory/data/defaults.yaml"
prefix               = "test"
environment_dns_zone = "dev"
billing_account = {
  id              = "000000-111111-222222"
  organization_id = 123456789012
}
vpc_self_links = {
  dev-spoke-0 = "link"
}
