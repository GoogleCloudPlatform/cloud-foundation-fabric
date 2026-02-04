output "org_policies_to_import_command" {
  description = "Command to add org policies to import to terraform.tfvars in 0-org-setup stage."
  value       = <<-EOF
    x = [
    %{for val in local.active_org_policies~}
      "${val}",
    %{endfor~}
    ]
  EOF
}
