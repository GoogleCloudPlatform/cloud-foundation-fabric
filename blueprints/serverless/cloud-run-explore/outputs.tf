output "default_URL" {
  description = "Cloud Run service default URL"
  value       = module.cloud_run.service.status[0].url
}

output "load_balancer_ip" {
  description = "LB IP that forwards to Cloud Run service"
  value       = local.gclb_create ? module.glb[0].address : "none"
}

# Custom domain for the Load Balancer. I'd prefer getting the value from the
# SSL certificate but it is not exported as output
output "custom_domain" {
  description = "Custom domain for the Load Balancer"
  value       = local.gclb_create ? var.custom_domain : "none"
}
