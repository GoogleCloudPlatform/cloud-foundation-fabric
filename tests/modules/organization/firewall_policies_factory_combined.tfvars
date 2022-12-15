firewall_policies = {
  policy1 = {
    allow-ingress = {
      description = ""
      direction   = "INGRESS"
      action      = "allow"
      priority    = 100
      ranges      = ["10.0.0.0/8"]
      ports = {
        tcp = ["22"]
      }
      target_service_accounts = null
      target_resources        = null
      logging                 = false
    }
    deny-egress = {
      description = ""
      direction   = "EGRESS"
      action      = "deny"
      priority    = 200
      ranges      = ["192.168.0.0/24"]
      ports = {
        tcp = ["443"]
      }
      target_service_accounts = null
      target_resources        = null
      logging                 = false
    }
  }
  policy2 = {
    allow-ingress = {
      description = ""
      direction   = "INGRESS"
      action      = "allow"
      priority    = 100
      ranges      = ["10.0.0.0/8"]
      ports = {
        tcp = ["22"]
      }
      target_service_accounts = null
      target_resources        = null
      logging                 = false
    }
  }
}

firewall_policy_factory = {
  cidr_file   = "../../tests/modules/organization/data/firewall-cidrs.yaml"
  policy_name = "factory-1"
  rules_file  = "../../tests/modules/organization/data/firewall-rules.yaml"
}
