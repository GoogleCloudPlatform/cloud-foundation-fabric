# Phase 4: Configuration & Wrap-up

### Step 7: Configuration Generation

1. **Explain Datasets:** Briefly explain to the user that FAST uses "datasets" (collections of YAML files) that fully describe the design, architecture, resources, and policies applied.
2. **Select the Dataset:** Ask the user to select the dataset they want to use for their landing zone design.
   - *If GCD:* Explicitly state that the `classic-gcd` dataset must be used for GCD installations.
   - *If Standard GCP:* Offer the available datasets and ask them to choose one. **Crucially, only search for available datasets within the `fast/stages/0-org-setup/datasets/` directory.** Do not search across the entire repository or other FAST stages. Provide a one-line description below each dataset when presenting the options (e.g., "classic: The standard FAST landing zone architecture", "hardened: A more restrictive, hardened landing zone architecture").
3. **Explain Defaults Configuration:** Explain to the user that we are starting the configuration of the `defaults.yaml` file, which drives the static configuration of the dataset by providing the Org ID, Billing ID, user-specified locations, and any static values they need to bring in from the outside (like additional IAM principals used in the YAML files to assign IAM roles).
4. **Determine Locations:** FAST uses a set of locations for different services.
   - *If GCD:* The region is fixed based on the universe selected in Phase 1. Set the `logging` location to `global` and all other required locations to the Universe Region. Do not ask the user to choose; simply show them the configured locations.
   - *If Standard GCP:* Check the `fast/stages/0-org-setup/schemas/defaults.schema.json` to identify the required location keys (e.g., `bq`, `gcs`, `logging`, `pubsub`). First, ask the user to provide a "base location" (e.g., `europe-west1`), explaining that submitting without answering will confirm the default value. Even if the user confirms the base location, you must then ask if they need to override the location for any individual services.
5. **Determine Local Path:** Explain to the user that FAST generates provider configurations and other files that need to be stored outside the repository. This is defined by the `output_files.local_path` setting. Propose a default path based on the chosen prefix (e.g., `~/fast-config/<prefix>`) and ask the user to confirm or provide a different path. **Crucially, if the user provides a relative path (e.g., `custom-fast-config` or `./custom-fast-config`), use it exactly as provided relative to the current working directory. Do not automatically prepend `~/` to their input.** Once confirmed, create this directory using `mkdir -p <LOCAL_PATH>`.
6. **Ask for Additional Context:** Ask the user if there are any other static values they want to bring in from outside to be referenced in the YAML files. Show them the available context keys (excluding `condition_vars`). Provide examples showing that prefixes are mandatory for IAM principals (e.g., `user:foo@example.com`, `group:bar@example.com`). For GCD, also show a `principalSet:` example. **Do not use shell commands like `echo` or `cat` to show this list; output it directly in your chat message or the `ask_user` prompt.**
7. **Create Local Directories and Copy Defaults:**
   - Create the `data/0-org-setup/` directory inside the confirmed `local_path` (`mkdir -p <LOCAL_PATH>/data/0-org-setup/`).
   - **Copy** (do not move) the `defaults.yaml` from the chosen dataset folder to `<LOCAL_PATH>/data/0-org-setup/defaults.yaml` using `cp`.
8. **Edit the Copied Defaults File:** Use the `replace` tool to edit the *copied* `<LOCAL_PATH>/data/0-org-setup/defaults.yaml` file.
   - Populate `global.billing_account`, `global.organization.id`, `global.organization.domain`, and `global.organization.customer_id` (using the values gathered in Phase 2). Note that `customer_id` may not be present for GCD.
   - Populate `context.iam_principals.gcp-organization-admins` (using the Admin Principal determined in Phase 2).
   - Populate the service-specific locations gathered in the previous step into the `context.locations` block and map them appropriately in `projects.defaults.locations`.
   - Populate `output_files.local_path` with the confirmed path.
   - If additional context was provided, add it to the `context` block.
   - *If GCD*, ensure the `overrides.universe` block is present with `domain`, `prefix`, and specific identity overrides.
9. Run YAML validation: `yamllint -c .yamllint --no-warnings <LOCAL_PATH>/data/0-org-setup/defaults.yaml`. Handle missing tool errors as described in the Core Principles.
10. **Create and Link Configuration Files:**
    - Use `write_file` to create `0-org-setup.auto.tfvars` inside the `local_path` (`<LOCAL_PATH>/0-org-setup.auto.tfvars`).
    - In `0-org-setup.auto.tfvars`, set the `factories_config` variable. The `dataset` should point to the original dataset folder (e.g., `"datasets/classic"`), but the `paths.defaults` must point to the absolute path of the copied defaults file.
    - Create a symbolic link from the stage folder to the tfvars file: `ln -s <LOCAL_PATH>/0-org-setup.auto.tfvars fast/stages/0-org-setup/0-org-setup.auto.tfvars`.
11. *If GCD*, also:
    - Create a temporary `providers.tf` file containing the specific `universe_domain` configuration using `write_file`.

### Step 8: Organization Policy Import Check

1. Explain that pre-existing organization policies can cause `409 Conflict` errors during the first apply if not imported.
2. Execute (or provide) the command to list current policies.
   ```bash
   gcloud org-policies list --organization="<ORG_ID>" --format="value(constraint)"
   ```
3. **Update `0-org-setup.auto.tfvars`:** If any policies are returned, capture the output, format it as an HCL list in memory, and use the `replace` tool to append the `org_policies_imports` variable to the `0-org-setup.auto.tfvars` file. **ABSOLUTELY NEVER use shell redirection like `echo >>`, `awk >>`, or `cat <<EOF >>` to edit files.** Explain to the user that this tells Terraform to import these existing policies rather than attempting to recreate them.

### Step 9: Wrap-up & Apply

1. Remind the user that the prerequisite phase is complete.
2. Instruct them to run `terraform init` and `terraform apply`.
3. Remind them to delete the temporary project and reset their gcloud default project to `iac-0` after a successful apply. Provide the exact commands for them to copy and use later:
   ```bash
   gcloud projects delete <TEMP_PROJECT_ID>
   gcloud config set project <IAC_PROJECT_ID>
   ```
