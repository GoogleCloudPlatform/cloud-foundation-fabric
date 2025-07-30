context = {
  bigquery_datasets = {
    test = "projects/test-prod-audit-logs-0/datasets/logs"
  }
  custom_roles = {
    myrole_one = "organizations/366118655033/roles/myRoleOne"
    myrole_two = "organizations/366118655033/roles/myRoleTwo"
  }
  iam_principals = {
    mygroup = "group:test-group@example.com"
    mysa    = "serviceAccount:test@test-project.iam.gserviceaccount.com"
    myuser  = "user:test-user@example.com"
  }
  locations = {
    default = "europe-west8"
  }
  log_buckets = {
    test = "projects/test-prod-audit-logs-0/locations/europe-west8/buckets/audit-logs"
  }
  project_ids = {
    test = "test-prod-audit-logs-0"
  }
  pubsub_topics = {
    test = "projects/test-prod-audit-logs-0/topics/audit-logs"
  }
  storage_buckets = {
    test = "test-prod-logs-audit-0"
  }
  tag_keys = {
    test = "tagKeys/1234567890"
  }
  tag_values = {
    "test/one" = "tagValues/1234567890"
  }
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
iam_bindings = {
  myrole_two = {
    role = "$custom_roles:myrole_two"
    members = [
      "$iam_principals:mysa"
    ]
  }
}
iam_bindings_additive = {
  myrole_two = {
    role   = "$custom_roles:myrole_two"
    member = "$iam_principals:myuser"
  }
}
logging_sinks = {
  test-bq = {
    destination = "$bigquery_datasets:test"
    filter      = "log_id('cloudaudit.googleapis.com/activity')"
    type        = "bigquery"
  }
  test-logging = {
    destination = "$log_buckets:test"
    filter      = "log_id('cloudaudit.googleapis.com/activity')"
    type        = "logging"
  }
  test-project = {
    destination = "$project_ids:test"
    filter      = "log_id('cloudaudit.googleapis.com/activity')"
    type        = "project"
  }
  test-pubsub = {
    destination = "$pubsub_topics:test"
    filter      = "log_id('cloudaudit.googleapis.com/activity')"
    type        = "pubsub"
  }
  test-storage = {
    destination = "$storage_buckets:test"
    filter      = "log_id('cloudaudit.googleapis.com/activity')"
    type        = "storage"
  }
}
logging_settings = {
  storage_location = "$locations:default"
}
tag_bindings = {
  foo = "$tag_values:test/one"
}
tags = {
  test = {
    id = "$tag_keys:test"
    iam = {
      "roles/tagAdmin" = ["$iam_principals:mygroup"]
    }
    iam_bindings = {
      tag_user = {
        role    = "roles/tagUser"
        members = ["$iam_principals:myuser"]
      }
    }
    iam_bindings_additive = {
      tag_viewer = {
        role   = "roles/tagViewer"
        member = "$iam_principals:mysa"
      }
    }
    values = {
      one = {
        id = "$tag_values:test/one"
        iam = {
          "roles/tagAdmin" = ["$iam_principals:mygroup"]
        }
        iam_bindings = {
          tag_user = {
            role    = "roles/tagUser"
            members = ["$iam_principals:myuser"]
          }
        }
        iam_bindings_additive = {
          tag_viewer = {
            role   = "roles/tagViewer"
            member = "$iam_principals:mysa"
          }
        }
      }
    }
  }
}
