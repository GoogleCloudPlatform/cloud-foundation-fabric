# Phase 2: Admin Principal & Baseline Info

### Step 3: Admin Principal Definition

1. Explain the concept of the **Admin Principal**. This is the identity (or group of identities) that will be granted the necessary FAST roles to deploy the foundation and manage critical organization-level configurations and policies thereafter.
2. Determine the Admin Principal approach by asking the user to choose between two options:
   - **Approach A (Preferred): Use a pre-created Group.**
     - *Action:* Explain that using a group (e.g., `group:gcp-organization-admins@example.com`) is the standard and preferred way. **Crucially, clarify that the group provided MUST be a group that the user's current authenticated identity belongs to**, otherwise they will lock themselves out.
     - *Action:* Ask the user to provide the group email address.
     - *Action:* Explicitly ask the user to confirm that their current identity (the one they just authenticated with) is already a member of this group.
     - *Action:* If the user answers "No" to the membership confirmation, **DO NOT PROCEED**. Inform the user that proceeding will lock them out. Ask them to either authenticate with an identity that *is* a member of the group (and restart the authentication step), or provide a different group that their current identity belongs to.
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
     - *Action:* Ask a follow-up question: "Is your billing account managed by the same organization where we are installing FAST, or outside of it? (You can check this in the Google Cloud Console by going to Billing -> using the organization picker on top -> checking if the account is listed under this organization)."
     - *If Inside the Org:* Note that `roles/billing.admin` WILL be assigned at the Organization level in Step 6. Instruct the user that we will deactivate the billing factories path for now, but if account-level IAM also needs to be managed via FAST later, they can reactivate the path and use the billing YAML to do it.
     - *If Outside the Org:* Note that `roles/billing.admin` WILL NOT be assigned at the Organization level in Step 6.
   - **Scenario 2 (Billing User):** The Admin Principal has `roles/billing.user` but NOT admin rights.
     - *Action:* Note that `roles/billing.admin` WILL NOT be assigned at the Organization level in Step 6. Either disable the billing YAML via the `factories_config` variable or comment it out, since the Admin Principal cannot control IAM on the account.
     - *Action:* **Explain to the user:** The service accounts for IaC (and therefore the provider switch and subsequent stages, except for VPC-SC) will not be operative until the correct billing permissions have been assigned to them outside of FAST.
   - **Scenario 3 (No Access):** The Admin Principal has absolutely no rights on the billing account.
     - *Action:* **Clearly state:** This scenario is mostly used for development purposes, is strongly discouraged, and requires advanced Terraform skills and FAST knowledge to proceed.
