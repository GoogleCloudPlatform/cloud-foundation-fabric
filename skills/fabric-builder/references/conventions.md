# Cloud Foundation Fabric (CFF) Conventions for Module Consumers

When generating Terraform code that consumes Cloud Foundation Fabric modules, you MUST adhere to the following conventions:

## 1. Module Preference
- **Prefer Modules:** Always prefer CFF modules over raw `google_*` resources.
- **Flat Structure:** Avoid creating wrapper modules or nested module calls (modules calling other modules). Consume CFF modules directly in your root module.
- **Module Sources:** Ask the user whether they want to use relative local paths or absolute paths referencing the GitHub repository.
  - Relative local paths: `source = "./modules/project"`
  - GitHub repository paths: `source = "github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/project?ref={VERSION}&depth=1"` (include version ref and `depth=1`).
  - All modules used must specify the same version tag. By default, unless the user states otherwise, default to using the latest release tag (obtainable via `python3 scripts/fabric.py release`).

## 2. Naming Conventions
- **Use `prefix`:** For modules that support it (e.g., `project`, `gcs`), using a `prefix` variable is recommended but not mandatory.
- **Deterministic Naming:** Prefer using structured, deterministic tokens rather than random strings.

## 3. Dependency Management
- **Output-to-Input:** Pass outputs from one module directly as inputs to another (e.g., `network = module.vpc.name`).
- **Ordering:** CFF modules encapsulate dependencies (like API activation) in their outputs. Rely on these outputs to ensure correct creation order.
- **Service Agents:** Use the `service_agents` output from the `project` module when granting IAM roles to Google-managed service accounts.
- **Implicit Dependencies:** Avoid explicit `depends_on` unless absolutely necessary. Rely on implicit dependencies (passing outputs to inputs) for better readability and maintainability.

## 4. Factories
- **When to Use Factories:** Use factories when you need to manage a large number of similar resources (e.g., projects, VPCs, firewall rules) without duplicating module blocks. Factories separate configuration data (in YAML files) from Terraform logic.
- **Main Modules with Factory Support:**
  - `project-factory`: For bulk creation of projects, folders, and budgets.
  - `net-vpc-factory`: For bulk creation of VPCs and associated resources.
  - `net-vpc`: Supports loading subnets and internal ranges from folders via `subnets_folder` and `internal_ranges_folder` keys in `factories_config`.
  - `net-vpc-firewall`: Supports loading firewall rules from a folder via `rules_folder`.
  - `organization` and `folder`: Support loading organization policies and custom roles.
  - `vpc-sc`: Supports loading access levels and service perimeters.
- **Usage:** Pass the path to the directory containing YAML files to the `factories_config` variable of the respective module.

## 5. Style for Root Modules
- **File Structure:** Make file structure dependent on size. For small configurations, use a single `main.tf`. For larger configurations, split into multiple files grouped by resource type (e.g., `main.tf` for general elements, `networking.tf`, `compute.tf`, etc.).
- **Variables & Defaults:**
  - Define all variables in `variables.tf`, sorted alphabetically.
  - Set defaults directly in the `default` attribute if a reasonable default exists or if provided by the user.
  - Avoid creating a `terraform.tfvars` file unless explicitly requested by the user.
- **Value Handling & Providers:**
  - **No Hardcoded Values:** Never use hardcoded values for project IDs, folder IDs, or other specific identifiers unless provided by the user. If a value is required, ask the user for it or create a variable.
  - **Provider Attributes:** Do not configure provider-level attributes like `project`, `region`, or `zone` in provider blocks (`provider "google"`, `provider "google-beta"`). All attributes must be passed to the modules explicitly in the module calls.
- **Formatting:** Adhere to standard Terraform formatting and keep line lengths readable. Wrap complex ternaries in parentheses.
- **No Local Exec:** Never use `local-exec` or similar provisioners to run shell commands. Rely on native Terraform resources and data sources, preferably from official providers (i.e., no third-party providers).

## 5a. Version Constraints
- **Omit Root Version Constraints:** Do not include version constraints (for Terraform or providers in `required_providers` or `required_version`) in the root module.
- **Automatic Resolution:** Let Terraform automatically compute and resolve the required provider and Terraform versions based on the constraints defined within the consumed CFF modules.

## 6. Impersonation and Backend Management
- **Impersonation:** If the user requires service account impersonation, add the `impersonate_service_account` attribute to the `provider "google"` and `provider "google-beta"` blocks in `providers.tf`.
- **Remote Backend:** If the user wants to use a remote backend, prefer `gcs`. Put the backend configuration in the `terraform` block inside `providers.tf`. If impersonation is used, also set it for the backend.

**Template for `providers.tf`:**
```terraform
terraform {
  backend "gcs" {
    bucket                      = "${bucket}"
    impersonate_service_account = "${service_account}"
  }
}

provider "google" {
  impersonate_service_account = "${service_account}"
}

provider "google-beta" {
  impersonate_service_account = "${service_account}"
}
```
