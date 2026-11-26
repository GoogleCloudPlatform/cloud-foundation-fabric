parent = "$folder_ids:default"
name   = "Test Context"
context = {
  condition_vars = {
    organization = {
      id = 1234567890
    }
  }
  custom_roles = {
    myrole_one = "organizations/366118655033/roles/myRoleOne"
    myrole_two = "organizations/366118655033/roles/myRoleTwo"
  }
  email_addresses = {
    default = "foo@example.com"
  }
  folder_ids = {
    default = "organizations/1234567890"
  }
  kms_keys = {
    test = "projects/test-kms-0/locations/europe-west8/keyRings/test/cryptoKeys/test"
  }
  iam_principals = {
    mygroup = "group:test-group@example.com"
    mysa    = "serviceAccount:test@test-project.iam.gserviceaccount.com"
    myuser  = "user:test-user@example.com"
  }
  project_numbers = {
    test = "1234567890"
  }
  pubsub_topics = {
    test = "projects/test-prod-audit-logs-0/topics/audit-logs"
  }
  security_policies = {
    test = "locations/global/securityPolicies/1234567890"
  }
  tag_values = {
    "test/one" = "tagValues/1234567890"
  }
  tag_vars = {
    organization = {
      env = "1234567890/environment"
    }
    projects = {
      "test-00" = {
        test = "foo-test-0/dynamic_test"
      }
    }
  }
}
asset_feeds = {
  test = {
    billing_project = "test-project"
    feed_output_config = {
      pubsub_destination = {
        topic = "$pubsub_topics:test"
      }
    }
  }
}
cloud_armor_policy = {
  policy_id         = "$security_policies:test"
  excluded_projects = ["$project_numbers:test", "projects/3333333333"]
}
contacts = {
  "$email_addresses:default" = ["ALL"]
}
iam = {
  "$custom_roles:myrole_one" = [
    "$iam_principals:myuser"
  ]
  "roles/viewer" = [
    "$iam_principals:mysa"
  ]
}
iam_by_principals = {
  "$iam_principals:mygroup" = [
    "roles/owner",
    "$custom_roles:myrole_one"
  ]
}
iam_by_principals_conditional = {
  "$iam_principals:myuser" = {
    roles = [
      "roles/storage.admin",
      "$custom_roles:myrole_one",
      "$custom_roles:myrole_two",
    ]
    condition = {
      title       = "expires_after_2020_12_31"
      description = "Expiring at midnight of 2020-12-31"
      expression  = "request.time < timestamp(\"2021-01-01T00:00:00Z\")"
    }
  }
}
iam_bindings = {
  myrole_two = {
    role = "$custom_roles:myrole_two"
    members = [
      "$iam_principals:mysa"
    ]
    condition = {
      title      = "Test"
      expression = "resource.matchTag('$${organization.id}/environment', 'development')"
    }
  }
}
iam_bindings_additive = {
  myrole_two = {
    role   = "$custom_roles:myrole_two"
    member = "$iam_principals:myuser"
  }
}
logging_data_access = {
  allServices = {
    ADMIN_READ = {
      exempted_members = ["$iam_principals:mygroup"]
    }
    DATA_READ = {}
  }
}
logging_settings = {
  kms_key_name = "$kms_keys:test"
}
logging_sinks = {
  test-pubsub = {
    description = ""
    destination = "$pubsub_topics:test"
    filter      = "log_id('cloudaudit.googleapis.com/activity')"
    type        = "pubsub"
  }
}
pam_entitlements = {
  net-admins = {
    max_request_duration = "3600s"
    manual_approvals = {
      require_approver_justification = true
      steps = [{
        approvers = ["$iam_principals:mygroup"]
      }]
    }
    eligible_users = ["$iam_principals:mygroup"]
    privileged_access = [
      { role = "roles/compute.networkAdmin" },
      { role = "roles/compute.admin" },
      { role = "$custom_roles:myrole_two" }
    ]
  }
}
tag_bindings = {
  bar = "tagValues/1234567891"
  baz = "$tag_values:test/one"
  foo = "$${projects[\"test-00\"].test}/cc-123"
}

iam_deny_policies = {
  test-policy = {
    display_name = "Test Deny Policy"
    rules = [
      {
        description          = "Test Rule"
        denied_principals    = ["$iam_principals:myuser"]
        denied_permissions   = ["compute.googleapis.com/instances.create"]
        exception_principals = ["$iam_principals:mygroup", "$iam_principals:mysa"]
        denial_condition = {
          title      = "Test Condition"
          expression = "resource.matchTag('$${organization.id}/environment', 'development')"
        }
      }
    ]
  }
}

org_policies = {
  "iam.disableServiceAccountKeyUpload" = {
    rules = [{
      condition = {
        description = "Org $${organization.id} condition"
        expression  = "resource.matchTag('$${organization.id}/environment', 'development')"
        location    = "org-$${organization.id}"
        title       = "org-$${organization.id}"
      }
      enforce = true
    }]
  }
  "essentialcontacts.managed.allowedContactDomains" = {
    rules = [{
      enforce    = true
      parameters = "{\"allowedDomains\": [\"@$${organization.id}.example.com\"]}"
    }]
  }
  "compute.trustedImageProjects" = {
    rules = [{
      allow = {
        values = ["under:organizations/$${organization.id}"]
      }
    }]
  }
  "dry_run:compute.trustedImageProjects" = {
    rules = [{
      condition = {
        expression = "resource.matchTag('$${organization.id}/environment', 'development')"
        title      = "dry-run-$${organization.id}"
      }
      deny = {
        values = ["under:organizations/$${organization.id}"]
      }
    }]
  }
}
boundary_configs = {
  tag_key = "$${organization.env}"
  boundaries = {
    prod-agents = {
      display_name = "Production Agents"
      tag_value    = "prod"
    }
  }
}
capability_configs = {
  prod-agent-registry = {
    display_name       = "Prod Agent Registry"
    boundaries         = ["prod-agents"]
    management_project = "$project_numbers:test"
  }
}
