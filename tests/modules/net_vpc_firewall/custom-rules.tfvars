default_rules_config = {
  disabled = true
}
egress_rules = {
  allow-egress-rfc1918 = {
    deny        = false
    description = "Allow egress to RFC 1918 ranges."
    destination_ranges = [
      "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"
    ]
  }
  allow-egress-tag = {
    deny        = false
    description = "Allow egress from a specific tag to 0/0."
    targets     = ["target-tag"]
  }
  deny-egress-all = {
    description = "Block egress."
  }
}
ingress_rules = {
  allow-ingress-ntp = {
    description = "Allow NTP service based on tag."
    targets     = ["ntp-svc"]
    rules       = [{ protocol = "udp", ports = [123] }]
  }
  allow-ingress-tag = {
    description   = "Allow ingress from a specific tag."
    source_ranges = []
    sources       = ["client-tag"]
    targets       = ["target-tag"]
  }
}
