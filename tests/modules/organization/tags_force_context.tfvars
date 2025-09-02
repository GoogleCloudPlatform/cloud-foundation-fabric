context = {
  tag_keys = {
    foo             = "tagKeys/111111"
    bar             = "tagKeys/222222"
    foobar          = "tagKeys/333333"
    net_environment = "tagKeys/444444"
  }
  tag_values = {
    "baz/one"      = "tagValues/111111"
    "baz/two"      = "tagValues/222222"
    "foobar/one"   = "tagValues/333333"
    "foobar/two"   = "tagValues/444444"
    "foobar/three" = "tagValues/555555"
  }
}
network_tags = {
  net_environment = {
    network = "foobar"
  }
}
tags_config = {
  force_context_ids = true
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
      one = {}
      two = {}
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
      one = {}
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
