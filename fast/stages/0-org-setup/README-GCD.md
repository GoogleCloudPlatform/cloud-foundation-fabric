# FAST Installation on Cloud de Confiance (GCD)

This document serves as an extension to the main **[FAST Organization Setup README](../README.md)**, detailing the specific configurations and steps required to deploy the Fabric FAST landing zone on **Cloud de Confiance (GCD)**.

It assumes familiarity with the standard FAST bootstrap flow but highlights the critical divergences required for the Trusted Private Cloud (TPC) environment. For a detailed overview of the differences between Google Cloud and Cloud de Confiance, please refer to the [official S3NS documentation](https://documentation.s3ns.fr/docs/overview/tpc-key-differences).

## 1. Design Overview

The FAST framework uses the concept of **stages**, which perform precise tasks individually but taken together build a functional, ready-to-use organization. These stages are modeled around security boundaries typically found in mature organizations, allowing ownership delegation to specific teams (e.g., Networking, Security).

The core stages included in the toolkit are:

- **Organization Setup:** Bootstraps the organization, configures high-level IAM, Organization Policies, and the resource hierarchy.
- **VPC-SC:** Implements VPC Service Controls and resource auto-discovery.
- **Security:** Manages centralized security configurations (e.g., KMS).
- **Networking:** Manages centralized network resources (Hub-and-spoke, VPNs, etc.).

## 2. Prerequisites

This section extends the [Prerequisites](../README.md#prerequisites) in the main README. Before beginning the standard setup, ensure the following additional requirements are met.

### Identity Provider

An IdP is configured for your organization, and you can sign in with your administrator ID.

### Repository

Clone the latest version of the repository (currently v50.0.0) or download it from the Releases page:

```bash
git clone https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git
```

### Google Cloud CLI

Configure the `gcloud` CLI for use with Cloud de Confiance. The following is a simple example that worked for us.

First, create a WIF configuration file for `gcloud` via the following commands

```bash
AUDIENCE=locations/global/workforcePools/mypool/providers/myprovider
UNIVERSE_WEB_DOMAIN="cloud.s3nscloud.fr"
UNIVERSE_API_DOMAIN="s3nsapis.fr"
UNIVERSE_NAME="s3nsapis"
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

For the initial bootstrap on GCD, you cannot rely on automatic quota tracking for Organization Policies. You must manually create a temporary project first.

1. **Create a project:** Create a temporary project via the Cloud Console. **Note:** This project does not require a billing account.
2. **Enable Service:** Enable the `orgpolicy.googleapis.com` service in this project.
3. **Configure CLI:** Set this project as your default:

    ```bash
    gcloud config set project <TEMP_PROJECT_ID>
    ```

4. *Post-Setup:* Once the first Terraform apply is complete, you can switch to the newly created `iac-0` project and delete this temporary one.

## 4. Terraform Configuration Updates

*This section details specific modifications to the [Configure defaults](../README.md#configure-defaults) step.*

### Provider Configuration

Create a temporary `providers.tf` file to configure the specific universe domain for GCD. This ensures Terraform targets the correct API endpoints.

```hcl
provider "google" {
  # Replace with your specific universe domain (e.g., s3nsapis.fr)
  universe_domain = "s3nsapis.fr"
}

provider "google-beta" {
  universe_domain = "s3nsapis.fr"
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
      storage: u-france-east1
  overrides:
    universe:
      domain: s3nsapis.fr
      prefix: s3ns
      forced_jit_service_identities:
        - compute.googleapis.com
      unavailable_service_identities:
        - dns.googleapis.com
        - monitoring.googleapis.com
        - networksecurity.googleapis.com
```

## 5. Managing Organization Policies

*This section extends the [Importing org policies](../README.md#importing-org-policies) instructions.*

Organization policies must be tailored to the universe constraints. The recommended approach is to **bypass them during the first apply** and add them iteratively.

### Step A: Bypass for First Apply

1. **Rename** the `organization/org-policies` folder (e.g., to `organization/org-policies.unused`).
2. **Comment out** the `org-policies` block in the `projects/iac-0.yaml` file.
3. Run `terraform apply` as described in the [First apply cycle](../README.md#first-apply-cycle) section.

### Step B: Iterative Import

Once the stage is applied and you have switched credentials to the IaC service account:

1. Create an empty `organization/org-policies` folder.
2. Move policy YAML files back one by one, uncommenting relevant policies.
3. **Adjust constraints** for GCD-specific values. For example, `compute.trustedImageProjects` must reference the universe-specific project IDs (e.g., `eu0-system`):

```yaml
compute.trustedImageProjects:
  rules:
  - allow:
      values:
        - "is:projects/s3ns-system:cos-cloud"
        - "is:projects/s3ns-system:debian-cloud"
        - "is:projects/s3ns-system:rocky-linux-cloud"
        - "is:projects/s3ns-system:ubuntu-os-cloud"
```

To import pre-existing default policies without modifying them, define the constraint in your `terraform.tfvars` using the `org_policies_imports` variable:

```hcl
org_policies_imports = [
  "compute.trustedImageProjects",
]
```

## 6. Next Steps: Applying Other Stages

Once the **Organization Setup** stage is complete, you can configure and apply any subsequent stages (VPC-SC, Security, Networking, Project Factory). The universe configuration defined here will be carried over implicitly by the FAST cross-stage output files.
