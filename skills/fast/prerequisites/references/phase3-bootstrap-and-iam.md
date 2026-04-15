# Phase 3: Bootstrap Project & IAM

### Step 5: Bootstrap Project Setup

1. Explain that a temporary bootstrap project is required to track API quota before organization policies are fully established.
2. Ask the user if they already have a suitable project they can use for this purpose.
   - *If yes:* Ask if this project is already configured as the active project in `gcloud`. If the user does not know, run `gcloud config list project --format="value(core.project)"` to check for them.
     - If it is already configured, fetch the Project ID using `gcloud config list project --format="value(core.project)"`. Explicitly ask the user to confirm if this fetched Project ID is the one they want to use. **Only if they answer "No" to this confirmation**, ask them to provide the correct Project ID.
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

1. Grant the following roles to the chosen Admin Principal at the Organization level. **CRITICAL:** Only include `roles/billing.admin` in this list if the user selected Scenario 1 (Billing Administrator) AND confirmed the billing account is managed Inside the Organization in Step 4.
   ```bash
   # Roles to assign:
   # [roles/billing.admin] <-- CONDITIONAL (See above)
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
