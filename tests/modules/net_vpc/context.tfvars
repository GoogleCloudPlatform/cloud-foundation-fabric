context = {
  addresses = {
    dns-external = "8.8.8.8"
    dns-internal = "10.10.10.10"
    test         = "10.20.20.20"
  }
  cidr_ranges = {
    rfc1918-10  = "10.0.0.0/8"
    rfc1918-172 = "172.16.10.0/12"
    rfc1918-192 = "192.168.0.0/16"
    test        = "8.8.8.8/32"
  }
  condition_vars = {
    organization = {
      id = 1234567890
    }
  }
  custom_roles = {
    myrole = "organizations/366118655033/roles/myRoleOne"
  }
  iam_principals = {
    test = "serviceAccount:test@test-project.iam.gserviceaccount.com"
  }
  locations = {
    ew8 = "europe-west8"
  }
  networks = {
    test = "projects/foo-dev-net-spoke-0/global/networks/dev-spoke-0"
  }
  project_ids = {
    test = "foo-test-0"
  }
}
dns_policy = {
  inbound = true
  outbound = {
    private_ns = ["$addresses:dns-internal"]
    public_ns  = ["$addresses:dns-external"]
  }
}
internal_ranges = [
  {
    name          = "pods-range"
    usage         = "FOR_VPC"
    peering       = "FOR_SELF"
    ip_cidr_range = "$cidr_ranges:rfc1918-172"
  }
]
project_id = "$project_ids:test"
routes = {
  next-hop = {
    description   = "Route to internal range."
    dest_range    = "$cidr_ranges:test"
    next_hop_type = "ip"
    next_hop      = "$addresses:test"
  }
}
subnets = [
  {
    name                    = "production"
    region                  = "$locations:ew8"
    reserved_internal_range = "pods-range"
    iam = {
      "$custom_roles:myrole" = [
        "iam_principals:test"
      ]
    }
    iam_bindings = {
      myrole_two = {
        role = "$custom_roles:myrole"
        members = [
          "$iam_principals:test"
        ]
        condition = {
          title      = "Test"
          expression = "resource.matchTag('$${organization.id}/environment', 'development')"
        }
      }
    }
    iam_bindings_additive = {
      myrole_two = {
        role   = "$custom_roles:myrole"
        member = "$iam_principals:test"
      }
    }
    secondary_ip_ranges = {
      pods = {
        reserved_internal_range = "pods-range"
      }
      # Mixed configuration: some ranges use internal ranges, others use CIDR
      traditional = {
        ip_cidr_range = "$cidr_ranges:rfc1918-192"
      }
    }
  }
]
