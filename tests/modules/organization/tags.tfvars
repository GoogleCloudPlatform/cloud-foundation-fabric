network_tags = {
  net_environment = {
    network = "foobar"
  }
}
tags = {
  foo = {}
  bar = {
    description = null
    iam         = null
    values      = null
  }
  baz = {
    id = "tagKeys/1234567890"
    values = {
      one = null
      two = null
    }
  }
  foobar = {
    description = "Foobar tag."
    iam = {
      "roles/resourcemanager.tagAdmin" = [
        "user:user1@example.com", "user:user2@example.com"
      ]
    }
    values = {
      one = null
      two = {
        description = "Foobar 2."
        iam = {
          "roles/resourcemanager.tagViewer" = [
            "user:user3@example.com"
          ]
        }
      }
      three = {
        description = "Foobar 3."
        iam = {
          "roles/resourcemanager.tagViewer" = [
            "user:user3@example.com"
          ]
          "roles/resourcemanager.tagAdmin" = [
            "user:user4@example.com"
          ]
        }
      }
      four = {
        description = "Foobar 4."
        id          = "tagValues/1234567890"
        iam = {
          "roles/resourcemanager.tagViewer" = [
            "user:user4@example.com"
          ]
        }
      }
    }
  }
}
