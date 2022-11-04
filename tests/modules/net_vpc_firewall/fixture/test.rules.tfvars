egress_rules = {
  allow-egress-rfc1918 = {
    description        = "Allow egress to RFC 1918 ranges."
    is_egress          = true
    destination_ranges = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }
  deny-egress-all = {
    description = "Block egress."
    is_deny     = true
    is_egress   = true
  }
}
ingress_rules = {
  allow-ingress-ntp = {
    description = "Allow NTP service based on tag."
    targets     = ["ntp-svc"]
    rules       = [{ protocol = "udp", ports = [123] }]
  }
}
default_rules_config = {
  disabled = true
}
