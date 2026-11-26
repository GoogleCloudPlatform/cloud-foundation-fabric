context = {
  condition_vars = {
    names = {
      my-id = "myid"
    }
  }
  custom_roles = {
    myrole = "organizations/366118655033/roles/myRoleOne"
  }
  iam_principals = {
    myuser  = "user:test-user@example.com"
    myuser2 = "user:test-user2@example.com"
    kmssa   = "kms-sa@dev-test-0.iam.gserviceaccount.com"
  }
  kms_keys = {
    my-key = "projects/dev-test-0/locations/europe-west8/keyRings/my-kr/cryptoKeys/my-key"
  }
  locations = {
    ew8 = "europe-west8"
  }
  networks = {
    "dev-spoke-0" : "projects/foo-dev-net-spoke-0/global/networks/dev-spoke-0"
  }
  subnetworks = {
    "default" : "projects/foo-dev-net-spoke-0/regions/europe-west8/subnetworks/default"
  }
  project_ids = {
    test = "dev-test-0"
  }
}

project_id = "$project_ids:test"
id         = "test-0"
location   = "$locations:ew8"
network_config = {
  network    = "$networks:dev-spoke-0"
  subnetwork = "$subnetworks:default"
}
private_cluster_config = {
  enable_private_endpoint = true
  allowed_projects        = ["$project_ids:test"]
}
workstation_configs = {
  my-workstation-config = {
    encryption_key = {
      kms_key                 = "$kms_keys:my-key"
      kms_key_service_account = "$iam_principals:kmssa"
    }
    workstations = {
      my-workstation = {
        labels = {
          team = "my-team"
        }
        iam = {
          "roles/workstations.user" = ["$iam_principals:myuser"]
        }
        iam_bindings = {
          workstation-user-cond = {
            role    = "$custom_roles:myrole"
            members = ["$iam_principals:myuser"]
            condition = {
              title      = "ws-limited-access"
              expression = "resource.name.startsWith('$${names.my-id}-')"
            }
          }
        }
        iam_bindings_additive = {
          workstation-editor-cond = {
            role   = "roles/editor"
            member = "$iam_principals:myuser2"
            condition = {
              title       = "ws-editor-access"
              description = "Conditional workstation editor"
              expression  = "resource.name.startsWith('my-')"
            }
          }
        }
      }
    }
    iam = {
      "roles/viewer" = ["$iam_principals:myuser2"]
    }
    iam_bindings = {
      workstations-config-viewer = {
        role    = "$custom_roles:myrole"
        members = ["$iam_principals:myuser"]
        condition = {
          title      = "limited-access"
          expression = "resource.name.startsWith('my-')"
        }
      }
    }
    iam_bindings_additive = {
      workstations-config-editor = {
        role   = "roles/editor"
        member = "group:group3@my-org.com"
        condition = {
          title      = "limited-access"
          expression = "resource.name.startsWith('$${names.my-id}-')"
        }
      }
    }
  }
}
