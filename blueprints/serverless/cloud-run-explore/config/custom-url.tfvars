###
### Purpose of this configuration file.
###
### Create a Cloud Run service with a custom domain using an HTTPS LB.
### Block requests not coming from the LB.
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
