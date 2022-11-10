access_levels = {
  a1 = {
    combining_function = null
    conditions = [
      {
        device_policy          = null
        ip_subnetworks         = null
        members                = ["user:ludomagno@google.com"]
        negate                 = null
        regions                = null
        required_access_levels = null
      }
    ]
  }
  a2 = {
    combining_function = "OR"
    conditions = [
      {
        device_policy          = null
        ip_subnetworks         = null
        members                = null
        negate                 = null
        regions                = ["IT", "FR"]
        required_access_levels = null
      },
      {
        device_policy          = null
        ip_subnetworks         = null
        members                = null
        negate                 = null
        regions                = ["US"]
        required_access_levels = null
      }
    ]
  }
}
egress_policies = {
  foo = {
    from = {
      identities = ["user:foo@example.com"]
    }
    to = {
      resources = ["projects/333330"]
    }
  }
}
ingress_policies = {
  foo = {
    from = {
      source_access_levels = ["a2"]
      source_resources     = ["projects/333330"]
    }
    to = {
      operations = [{
        service_name = "compute.googleapis.com"
      }]
      resources = ["projects/222220"]
    }
  }
}
service_perimeters_bridge = {
  b1 = {
    status_resources = ["projects/111110", "projects/111111"]
  }
  b2 = {
    status_resources          = ["projects/111110", "projects/222220"]
    spec_resources            = ["projects/111110", "projects/222220"]
    use_explicit_dry_run_spec = true
  }
}
service_perimeters_regular = {
  r1 = {
    status = {
      access_levels       = ["a1"]
      resources           = ["projects/11111", "projects/111111"]
      restricted_services = ["storage.googleapis.com"]
      vpc_accessible_services = {
        allowed_services   = ["compute.googleapis.com"]
        enable_restriction = true
      }
    }
  }
  r2 = {
    status = {
      access_levels       = ["a1", "a2"]
      resources           = ["projects/222220", "projects/222221"]
      restricted_services = ["storage.googleapis.com"]
      egress_policies     = ["foo"]
      ingress_policies    = ["foo"]
      vpc_accessible_services = {
        allowed_services   = ["compute.googleapis.com"]
        enable_restriction = true
      }
    }
  }
}
