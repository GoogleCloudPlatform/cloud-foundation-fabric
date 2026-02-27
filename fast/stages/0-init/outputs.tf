output "existing_org_policies" {
  description = "Variable containing existing organization policies to be added to the terraform.tfvars of the 0-org-setup stage."
  value       = <<-EOF
    x = [
    %{for val in local.active_org_policies~}
      "${val}",
    %{endfor~}
    ]
  EOF
}

output "project_id" {
  description = "ID of the project to be used as billing project."
  value       = <<-EOF
    x = [
    %{for val in local.active_org_policies~}
      "${val}",
    %{endfor~}
    ]
  EOF
}
