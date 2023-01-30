###
### Purpose of this configuration file.
###
### On top of custom-url configuration (wish list: 'include' directive),
### add security using Cloud Armor in the LB.
###

# Add an HTTPS Load Balancer in front of the Cloud Run service
glb_create = true

# Domain for the Load Balancer, replace with your own domain.
# A managed certificate is created, and you will need to point to the LB IP
# address with an A/AAAA DNS record at your registrar:
# https://cloud.google.com/load-balancing/docs/ssl-certificates/google-managed-certs#update-dns
custom_domain = "cloud-run-explore.example.org"

# Ingress sources. Allow internal traffic and requests from the LB.
# To allow access through the default URL set this value to "all"
ingress_settings = "internal-and-cloud-load-balancing"

# Security policy to enforce in the LB. The code and this configuration
# allow to block a list of IPs and a specific URL path. For example, you
# may want to block access to a login page to external users
security_policy = {
  enabled      = true
  ip_blacklist = ["79.149.0.0/16"]
  path_blocked = "/login.html"
}
