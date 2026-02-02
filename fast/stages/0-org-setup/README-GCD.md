# FAST Installation on Google Cloud Dedicated (GCD)

This document serves as an extension to the main **[FAST Organization Setup README](../README.md)**, detailing the specific configurations and steps required to deploy the Fabric FAST landing zone on **Google Cloud Dedicated (GCD)**.

It assumes familiarity with the standard FAST bootstrap flow but highlights the critical divergences required for the Google Cloud Dedicated (GCD) environment.

## Configuration Reference

The following table lists the specific configuration values for different Google Cloud Dedicated (GCD) environments. Please replace the placeholders in the commands and configurations below with the values corresponding to your target universe.

| Variable | GCD In France (GA) | GCD In Germany (Preview)[^1] |
| :--- | :--- | :--- |
| `UNIVERSE_WEB_DOMAIN` | `cloud.s3nscloud.fr` | `cloud.berlin-build0.goog` |
| `UNIVERSE_API_DOMAIN` | `s3nsapis.fr` | `apis-berlin-build0.goog` |
| `UNIVERSE_NAME` | `s3ns` | `berlin` |
| `UNIVERSE_PREFIX` | `s3ns` | `eu0` |
| `UNIVERSE_REGION` | `u-france-east1` | `u-germany-northeast1` |

[^1]: Note that these APIs are subject to change before GA (General Availability).

## 1. Design Overview

The landing zone is built using a series of modular **stages**, each performing specific tasks to create a functional, production-ready organization. These stages align with typical enterprise security boundaries, enabling clear ownership delegation (e.g., to Networking or Security teams).

The core stages are:

- **Organization Setup:** Bootstraps the organization, configures high-level IAM, Organization Policies, and the resource hierarchy.
- **VPC-SC:** Implements VPC Service Controls and resource auto-discovery.
- **Security:** Manages centralized security configurations (e.g., KMS).
- **Networking:** Manages centralized network resources (Hub-and-spoke, VPNs, etc.).

## 2. Prerequisites

In addition to the [standard FAST prerequisites](../README.md#prerequisites), ensure the following GCD-specific requirements are met.


### Identity Provider

An IdP is configured for your organization, and you can sign in with your administrator ID.

### Repository

Clone the latest version of the repository or download it from the Releases page:

```bash
git clone https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git
```

### Google Cloud CLI

Initialize the `gcloud` CLI for your GCD universe. Use the values from the [Configuration Reference](#configuration-reference) table to replace the `<PLACEHOLDERS>` in the commands below.

First, create a Workforce Identity Federation (WIF) login configuration:

```bash
AUDIENCE=locations/global/workforcePools/mypool/providers/myprovider
# Replace with values from the Configuration Reference table
UNIVERSE_WEB_DOMAIN="<UNIVERSE_WEB_DOMAIN>"
UNIVERSE_API_DOMAIN="<UNIVERSE_API_DOMAIN>"
UNIVERSE_NAME="<UNIVERSE_NAME>"
WF_POOL_FILE_PATH="/tmp"

gcloud config configurations create $UNIVERSE_NAME
gcloud config configurations activate $UNIVERSE_NAME
gcloud config set universe_domain $UNIVERSE_API_DOMAIN

gcloud iam workforce-pools create-login-config $AUDIENCE \
  --universe-cloud-web-domain="$UNIVERSE_WEB_DOMAIN" \
  --universe-domain="$UNIVERSE_API_DOMAIN" \
  --output-file="$WF_POOL_FILE_PATH/wif-login-config-$UNIVERSE_NAME.json" \
  --activate
```

Once the above file has been created and the gcloud profile configured, run the following command to login to the organization with `gcloud`. This will prompt a web browser that will allow login to the organization with the configured IdP.

```bash
gcloud auth login \
  --login-config=$WF_POOL_FILE_PATH/wif-login-config-$UNIVERSE_NAME.json \
  --no-launch-browser

gcloud auth application-default login \
  --login-config=$WF_POOL_FILE_PATH/wif-login-config-$UNIVERSE_NAME.json
```

## 3. Bootstrap: Manual Temporary Project

*This step replaces the standard [Default project](../README.md#default-project) creation flow.*

GCD requires a manual bootstrap project because organization policy services are not automatically available at the organization root during the initial setup.

1. **Create a project:** Use the Cloud Console to create a temporary project. A billing account is **not** required.

3. **Set default project:** Configure your CLI context:

    ```bash
    gcloud config set project <TEMP_PROJECT_ID>
    ```
2. **Enable APIs:** Enable the the following services within this project.

    ```bash
    gcloud services enable \
      bigquery.googleapis.com \
      cloudbilling.googleapis.com \
      cloudresourcemanager.googleapis.com \
      essentialcontacts.googleapis.com \
      iam.googleapis.com \
      logging.googleapis.com \
      orgpolicy.googleapis.com \
      serviceusage.googleapis.com
    ```

4. **Post-Setup Cleanup:** After the initial `0-org-setup` stage is successfully deployed, switch to the production `iac-0` project and delete this temporary bootstrap project.

## 4. Terraform Configuration Updates

*This section details specific modifications to the [Configure defaults](../README.md#configure-defaults) step.*

### Provider Configuration

Create a temporary `providers.tf` file to configure the specific universe domain for GCD. This ensures Terraform targets the correct API endpoints.

```terraform
provider "google" {
  # Replace with your specific universe domain (e.g., s3nsapis.fr)
  universe_domain = "<UNIVERSE_API_DOMAIN>"
}

provider "google-beta" {
  universe_domain = "<UNIVERSE_API_DOMAIN>"
}
```

### Defaults Configuration (`defaults.yaml`)

Update your `defaults.yaml` file to include a `universe` block within the `overrides` section. This configures the correct API domains and disables service identities that are not available in GCD.

```yaml
projects:
  defaults:
    # customize prefix as per usual FAST instructions
    prefix: ftpc00
    locations:
      logging: global
      # Replace with values from the Configuration Reference table
      storage: <UNIVERSE_REGION>
  overrides:
    universe:
      # Replace with values from the Configuration Reference table
      domain: <UNIVERSE_API_DOMAIN>
      prefix: <UNIVERSE_PREFIX>
      forced_jit_service_identities:
        - compute.googleapis.com
      unavailable_service_identities:
        - dns.googleapis.com
        - monitoring.googleapis.com
        - networksecurity.googleapis.com
```

### Switch to GCD Dataset

Create a `terraform.tfvars` file to configure the `classic-gcd` dataset. This overrides the default factory locations to use the GCD-specific configurations.

```terraform
factories_config = {
  billing_accounts = "datasets/classic-gcd/billing-accounts"
  cicd_workflows   = "datasets/classic-gcd/cicd.yaml"
  defaults         = "datasets/classic-gcd/defaults.yaml"
  folders          = "datasets/classic-gcd/folders"
  organization     = "datasets/classic-gcd/organization"
  projects         = "datasets/classic-gcd/projects"
}
```
## 5. Organization Policies

The `classic-gcd` dataset provides a baseline set of organization policies compatible with the GCD environment. While it works out-of-the-box, it includes fewer policies than the standard dataset. Notably, it disables domain restricted sharing (`iam.allowedPolicyMemberDomains`) as Cloud Identity is typically not present in GCD organizations. **We strongly encourage you to review the differences between the `classic` dataset and `classic-gcd`, customizing as needed.**

### Importing Default Policies

The first `terraform apply` **must** import the default set of organization policies that are already active in your organization environment. Failure to do so may result in apply errors or unintended policy overwrites.

To do this, you need to list the existing policies and add them to the `org_policies_imports` variable in your `terraform.tfvars`.

Use the following command to generate the configuration and append it directly to your `terraform.tfvars` file:

```bash
ORG_ID="your-org-id-here"

P=$(gcloud org-policies list --organization="$ORG_ID" --format="value(constraint)") && [ -n "$P" ] && {
  printf "\norg_policies_imports = [\n"
  printf "%s\n" "$P" | sed 's/.*/  "&",/'
  echo "]"
} >> terraform.tfvars
```

This will append a configuration block similar to:

```terraform
org_policies_imports = [
  "sql.restrictPublicIp",
  "compute.vmExternalIpAccess",
  "iam.disableServiceAccountKeyUpload",
  "compute.restrictXpnProjectLienRemoval",
]
```
## 6. Deploy

At this point you can proceed to grant the required permissions to the bootstrap identity and perform the first Terraform run.

### Granting Permissions

Use the following commands to grant the necessary IAM roles to the principal running the deployment:

```bash
export FAST_PRINCIPAL="group:gcp-organization-admins@example.com"

# find your organization and export its id in the FAST_ORG variable
gcloud organizations list
export FAST_ORG_ID=123456

# set needed roles (billing role only needed for organization-owned account)
export FAST_ROLES="\
  roles/billing.admin \
  roles/logging.admin \
  roles/iam.organizationRoleAdmin \
  roles/orgpolicy.policyAdmin \
  roles/resourcemanager.folderAdmin \
  roles/resourcemanager.organizationAdmin \
  roles/resourcemanager.projectCreator \
  roles/resourcemanager.tagAdmin \
  roles/owner"

for role in $FAST_ROLES; do
  gcloud organizations add-iam-policy-binding $FAST_ORG_ID \
    --member $FAST_PRINCIPAL --role $role --condition None
done
```

### First Apply

Initialize and apply the configuration:

```bash
terraform init
terraform apply
```

Once the apply completes successfully, continue with the [Provider setup and final apply cycle](../README.md#provider-setup-and-final-apply-cycle) instructions in the main README.


## 7. Next Steps

Once the **Organization Setup** stage is fully deployed:

1.  **Delete Temporary Project:** You can now safely delete the temporary bootstrap project created in Step 3. Also remember to set your default gcloud project to the IAC project.

    ```bash
    gcloud projects delete <TEMP_PROJECT_ID>
    gcloud config set project <IAC_PROJECT_ID>
    ```

2.  **Proceed to Next Stages:** Continue with the subsequent FAST stages (VPC-SC, Security, Networking, Project Factory). The universe configuration established here is automatically propagated to these stages via the FAST cross-stage output mechanism.

