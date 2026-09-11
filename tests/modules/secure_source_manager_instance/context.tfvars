context = {
  ca_pools = {
    dev-ca-0 = "projects/dev-sec-core-0/locations/europe-west8/caPools/dev-ca-0"
  }
  custom_roles = {
    myrole = "organizations/366118655033/roles/myRoleOne"
  }
  iam_principals = {
    myuser  = "user:test-user@example.com"
    repo-sa = "serviceAccount:ssm-repo-0@dev-build-ssm-0.iam.gserviceaccount.com"
  }
  kms_keys = {
    ssm = "projects/dev-sec-core-0/locations/europe-west4/keyRings/ssm/cryptoKeys/ssm"
  }
  locations = {
    ew4 = "europe-west4"
  }
  project_ids = {
    ssm  = "dev-build-ssm-0"
    peer = "dev-build-pool-0"
  }
  project_numbers = {
    peer = "1234567890"
  }
  service_accounts = {
    repo-0 = "ssm-repo-0@dev-build-ssm-0.iam.gserviceaccount.com"
  }
}

project_id  = "$project_ids:ssm"
instance_id = "test-0"
location    = "$locations:ew4"
kms_key     = "$kms_keys:ssm"
private_configs = {
  is_private           = true
  ca_pool_id           = "$ca_pools:dev-ca-0"
  psc_allowed_projects = ["$project_ids:peer", "$project_numbers:peer"]
  custom_host_config = {
    api      = "api.ssm.example.com"
    git_http = "git.ssm.example.com"
    git_ssh  = "ssh.ssm.example.com"
    html     = "ssm.example.com"
  }
}
iam = {
  "roles/securesourcemanager.instanceAccessor" = ["$iam_principals:repo-sa"]
}
iam_bindings_additive = {
  custom = {
    role   = "$custom_roles:myrole"
    member = "$iam_principals:myuser"
  }
}
repositories = {
  repo-0 = {
    service_account = "$service_accounts:repo-0"
    iam = {
      "roles/securesourcemanager.repoReader" = ["$iam_principals:repo-sa"]
    }
  }
}
