output "org_policies_to_import_command" {
    description = "Command to add org policies to import to terraform.tfvars in 0-org-setup stage."
    value = <<EOT
ORG_ID="${local.organization_id}"
P=$(gcloud org-policies list --organization="$ORG_ID" --format="value(constraint)") && [ -n "$P" ] && {
  printf "\norg_policies_imports = [\n"
  printf "%s\n" "$P" | sed 's/.*/  "&",/'
  echo "]"
} >> ../0-org-setup/terraform.tfvars                           
EOT
}