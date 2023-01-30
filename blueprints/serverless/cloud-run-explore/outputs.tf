output "default_URL" {
  description = "Cloud Run service default URL"
  value       = module.cloud_run.service.status[0].url
}

output "load_balancer_ip" {
  description = "LB IP that forwards to Cloud Run service"
  value       = var.glb_create ? module.glb[0].address : "none"
}
