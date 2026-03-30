---
name: fast-0-org-setup-prereqs
description: Guides the user step-by-step through the prerequisites for the FAST 0-org-setup stage, supporting both Standard GCP and Google Cloud Dedicated (GCD) environments. Use when a user asks to prepare or run prerequisites for 0-org-setup or bootstrap the FAST landing zone.
---

# FAST 0-org-setup Prerequisites Guide

## Core Principles & Execution Rules

1. **Step-by-Step Execution:** Never implement a single "magical" flow. Go through each step one at a time. Explain the context of what is being done, prompt the user for needed inputs, and explicitly ask for confirmation before running any command or making any edit.
2. **Execution Choice:** Whenever a `gcloud` or `terraform` command needs to be executed, offer the user a choice:
   - You (Gemini CLI) can execute the command automatically using the `run_shell_command` tool.
   - You can output the command for the user to copy/paste and execute manually.
     Users can switch between these preferences at any time.
3. **File Modifications:** Always use the `replace` tool (or `write_file` for new files) to manipulate files instead of opaque shell commands (like `sed` or `echo`). Show proposed edits and ask for confirmation before applying them.
4. **YAML Validation:** Whenever generating or modifying YAML files, use YAML validation if the tool is available. The project has `yamllint` configured (`.yamllint`). You can run `yamllint -c .yamllint --no-warnings <file>`. If it's missing, offer to install it (`pip install yamllint`) or advise the user.

## Step-by-Step Workflow

When triggered, guide the user through the following sequence strictly in order. Do not skip steps unless explicitly instructed by the user.

### Step 1: Environment Assessment & Initialization

1. Ask the user to clarify their target environment: **Standard GCP** or **Google Cloud Dedicated (GCD)**.
2. Ask how they prefer to run commands: Should you (Gemini CLI) run them automatically, or should you output them for manual execution?
3. *If GCD is selected*, ask the user if they are working in one of the known universes: **S3NS (France)** or **Berlin (Germany)**.
   - *If S3NS:* Pre-fill the following values:
     - Universe Web Domain: `cloud.s3nscloud.fr`
     - Universe API Domain: `s3nsapis.fr`
     - Universe Name: `s3ns`
     - Universe Prefix: `s3ns`
     - Universe Region: `u-france-east1`
   - *If Berlin:* Pre-fill the following values:
     - Universe Web Domain: `cloud.berlin-build0.goog`
     - Universe API Domain: `apis-berlin-build0.goog`
     - Universe Name: `berlin`
     - Universe Prefix: `eu0`
     - Universe Region: `u-germany-northeast1`
   - *If neither (Custom):* Gather the 5 universe-specific details manually from the user.
   - *Action:* Present the final list of the 5 universe values to the user for review. Ask for explicit confirmation and offer them the opportunity to change any of the values before proceeding.

### Step 2: Authentication

1. Ask the user if they are already authenticated with Google Cloud using the correct principal.
   - *If yes:* Proceed directly to Step 3.
   - *If no:* Proceed with the authentication steps below.
2. *Standard GCP:* Provide or execute the command:
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```
3. *GCD:* Automate or guide the user through WIF login. Ask for the workforce pool audience string first, then generate the configuration:
   ```bash
   # (Use the gathered GCD variables to fill placeholders)
   gcloud config configurations create <UNIVERSE_NAME>
   gcloud config configurations activate <UNIVERSE_NAME>
   gcloud config set universe_domain <UNIVERSE_API_DOMAIN>

   gcloud iam workforce-pools create-login-config <AUDIENCE> \
     --universe-cloud-web-domain="<UNIVERSE_WEB_DOMAIN>" \
     --universe-domain="<UNIVERSE_API_DOMAIN>" \
     --output-file="/tmp/wif-login-config-<UNIVERSE_NAME>.json" \
     --activate

   gcloud auth login --login-config=/tmp/wif-login-config-<UNIVERSE_NAME>.json --no-launch-browser
   gcloud auth application-default login --login-config=/tmp/wif-login-config-<UNIVERSE_NAME>.json
   ```
4. Explicitly ask the user to confirm they have successfully authenticated before moving to the next step.

### Step 3: Admin Principal Definition

1. Explain the concept of the **Admin Principal**. This is the identity (or group of identities) that will be granted the necessary FAST roles to deploy the foundation and manage critical organization-level configurations and policies thereafter.
2. Determine the Admin Principal approach by asking the user to choose between two options:
   - **Approach A (Preferred): Use a pre-created Group.**
     - *Action:* Explain that using a group (e.g., `group:gcp-organization-admins@example.com`) is the standard and preferred way.
     - *Action:* Ask the user to provide the group email address.
     - *Action:* Explicitly ask the user to confirm that their current identity (the one they just authenticated with) is already a member of this group.
   - **Approach B (Fallback): Use a Single User.**
     - *Action:* Explain that this flow uses a single user as the sole GCP Org Admin, but more can be added later.
     - *Action:* Run (or ask the user to run) `gcloud config list account --format="value(core.account)"` to retrieve their current authenticated principal.
     - *Action:* Show the user their current principal and explicitly ask them to confirm this is the identity they want to use as the Admin Principal.

### Step 4: Baseline Information Gathering

1. Gather baseline information required for `0-org-setup`:
   - Organization ID
   - Billing Account ID (Mandatory for subsequent stages, even if not required for the GCD temporary project)
   *Action:* When prompting the user for the Organization ID and Billing Account ID, explicitly instruct them in the prompt/question that they can leave the field blank (or type "list") to have you automatically run the relevant `gcloud` command (`gcloud organizations list` or `gcloud beta billing accounts list`). Also, instruct them that they can type a keyword to filter the list.
   *Action:* If the user leaves the field blank or types "list", run the `gcloud` command without filters. If the user types a keyword that is not a valid Organization ID (numeric) or Billing Account ID (e.g., `012345-6789AB-CDEF01`), run the `gcloud` command and use that keyword to filter the results using a **case-insensitive** regex match. Ensure the regex pattern is enclosed in single quotes within the filter argument (e.g., `--filter="displayName~'(?i)KEYWORD'"`). Do NOT use `*` wildcards in the filter.
   *Action:* If the filtered `gcloud` command returns no results, inform the user and use the `ask_user` tool to ask if they want to provide a different keyword or fetch all items (run without a filter).
   *Action:* Once you have results (filtered or unfiltered), sort them alphabetically by the display name, and then output the sorted results as a clearly formatted numbered list in the chat. Then, use the `ask_user` tool (type: text) to ask the user to enter the number corresponding to their selection.
2. Determine the **Admin Principal's** access level to the provided Billing Account ID. Ask which of the following three scenarios applies to the Admin Principal (not necessarily the current user):
   - **Scenario 1 (Billing Administrator):** The Admin Principal has `roles/billing.admin`.
     - *Action:* Use the billing account for projects. Ask for confirmation to keep the billing admin roles in the billing account YAML. Ask for confirmation to keep the billing user roles in the billing account YAML.
     - *Action:* Ask the user if absolute control of the billing account should be implemented in FAST by switching the billing roles to authoritative. **Outline the risks:** Authoritative bindings will remove any existing IAM bindings on the billing account not defined in FAST, potentially locking out existing users or systems.
   - **Scenario 2 (Billing User):** The Admin Principal has `roles/billing.user` but NOT admin rights.
     - *Action:* Use the billing account for projects. Either disable the billing YAML via the `factories_config` variable or comment it out, since the Admin Principal cannot control IAM on the account.
     - *Action:* **Explain to the user:** The service accounts for IaC (and therefore the provider switch and subsequent stages, except for VPC-SC) will not be operative until the correct billing permissions have been assigned to them outside of FAST.
   - **Scenario 3 (No Access):** The Admin Principal has absolutely no rights on the billing account.
     - *Action:* **Clearly state:** This scenario is mostly used for development purposes, is strongly discouraged, and requires advanced Terraform skills and FAST knowledge to proceed.

### Step 5: Bootstrap Project Setup

1. Explain that a temporary bootstrap project is required to track API quota before organization policies are fully established.
2. Ask the user if they already have a suitable project they can use for this purpose.
   - *If yes:* Ask if this project is already configured as the active project in `gcloud`. If the user does not know, run `gcloud config list project --format="value(core.project)"` to check for them.
     - If it is already configured, fetch the Project ID using `gcloud config list project --format="value(core.project)"`.
     - If it is not configured, ask the user to provide the Project ID.
   - *If no:* Ask the user to use the Cloud Console to create a temporary project (must be linked to the billing account). Ask them to provide the new Project ID once created.
3. Once the Project ID is provided or fetched, ensure it is set as the default project. If it is not already set, run:
   ```bash
   gcloud config set project <TEMP_PROJECT_ID>
   ```
4. Enable the required baseline APIs on the project:
   - The required APIs are: `bigquery.googleapis.com`, `cloudbilling.googleapis.com`, `cloudresourcemanager.googleapis.com`, `essentialcontacts.googleapis.com`, `iam.googleapis.com`, `logging.googleapis.com`, `orgpolicy.googleapis.com`, `serviceusage.googleapis.com`.
   - *If the project was pre-existing:* Ask the user if they want you to check which services are already enabled.
     - *If yes:* Run `gcloud services list --enabled --format="value(config.name)"` to get the current list. Compute the delta between the enabled services and the required list. Only run `gcloud services enable <MISSING_APIS>` for the ones that are missing.
     - *If no:* Run the full `gcloud services enable` command for all required APIs.
   - *If the project is new:* Run the full `gcloud services enable` command for all required APIs.

### Step 6: IAM Role Assignments

1. Grant the following roles to the chosen Admin Principal at the Organization level:
   ```bash
   # Roles to assign:
   # roles/billing.admin
   # roles/logging.admin
   # roles/iam.organizationRoleAdmin
   # roles/orgpolicy.policyAdmin
   # roles/resourcemanager.folderAdmin
   # roles/resourcemanager.organizationAdmin
   # roles/resourcemanager.projectCreator
   # roles/resourcemanager.tagAdmin
   # roles/owner

   # Loop example for the user or tool execution:
   for role in [ROLES_LIST]; do
     gcloud organizations add-iam-policy-binding <ORG_ID> \
       --member="<ADMIN_PRINCIPAL>" --role="$role" --condition=None
   done
   ```

### Step 6: Configuration Generation

1. **Explain Datasets and Contexts:** Briefly explain to the user that FAST uses "datasets" (collections of YAML files that describe the actual landing zone design and configuration) to drive its deployment. The `defaults.yaml` file within a dataset acts as the central configuration hub for the stage. It defines global settings (like the Organization ID and Billing Account) and sets up "contexts" (static mappings of values like principals or locations) that can be referenced symbolically throughout the rest of the YAML files.
2. **Select the Dataset:** Ask the user to select the dataset they want to use for their landing zone design.
   - *If GCD:* Explicitly state that the `classic-gcd` dataset must be used for GCD installations.
   - *If Standard GCP:* Offer the available datasets (e.g., `classic`, `hardened`, or any custom datasets present in the `datasets/` folder) and ask them to choose one.
3. Scaffold or update the `defaults.yaml` file within the chosen dataset (e.g., `datasets/classic/defaults.yaml` or `datasets/classic-gcd/defaults.yaml`).
   - Populate `global.billing_account`, `global.organization.id`, `context.iam_principals.gcp-organization-admins` (using the Admin Principal determined in Step 4), and `locations`.
   - *If GCD*, ensure the `overrides.universe` block is present with `domain`, `prefix`, and specific identity overrides.
4. **Ask for Additional Context:** Ask the user if there are any other static values (like additional IAM principals, custom roles, or specific locations) they want to bring in from outside to be referenced in the YAML files. If yes, add them to the `context` block in `defaults.yaml`.
5. **Create `0-org-setup.auto.tfvars`:** Explain that Terraform variables for this stage are conventionally stored in `0-org-setup.auto.tfvars`. Create this file (or update it if it exists).
   - Set the `factories_config` variable to point to the dataset chosen in Step 5.2 (e.g., `factories_config = { dataset = "datasets/classic" }`).
6. Use the `replace` tool to edit the files.
7. Run YAML validation: `yamllint -c .yamllint --no-warnings <file>`.
8. *If GCD*, also:
   - Create a temporary `providers.tf` file containing the specific `universe_domain` configuration.

### Step 7: Organization Policy Import Check

1. Explain that pre-existing organization policies can cause `409 Conflict` errors during the first apply if not imported.
2. Execute (or provide) the command to list current policies.
   ```bash
   gcloud org-policies list --organization="<ORG_ID>" --format="value(constraint)"
   ```
3. **Update `0-org-setup.auto.tfvars`:** If any policies are returned, use the `replace` or `write_file` tool to append them to the `org_policies_imports` list variable in the `0-org-setup.auto.tfvars` file. Explain to the user that this tells Terraform to import these existing policies rather than attempting to recreate them.

### Step 8: Wrap-up & Apply

1. Remind the user that the prerequisite phase is complete.
2. Instruct them to run `terraform init` and `terraform apply`.
3. Remind them to delete the temporary project and reset their gcloud default project to `iac-0` after a successful apply. Provide the exact commands for them to copy and use later:
   ```bash
   gcloud projects delete <TEMP_PROJECT_ID>
   gcloud config set project <IAC_PROJECT_ID>
   ```
