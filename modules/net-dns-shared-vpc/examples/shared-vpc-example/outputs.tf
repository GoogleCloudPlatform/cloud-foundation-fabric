output "host_project_id" {
  description = "Shared VPC Host project id"
  value       = module.project-host.project_id
}

output "shared_vpc_self_link" {
  description = "Shared VPC Self link"
  value       = module.vpc.self_link
}