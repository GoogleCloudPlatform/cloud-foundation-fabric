# FAST Installation on Google Cloud Dedicated (GCD)

This document serves as an extension to the main **[FAST Organization Setup README](../README.md)**, detailing the specific configurations and steps required to deploy the Fabric FAST landing zone on **Google Cloud Dedicated (GCD)**.

It assumes familiarity with the standard FAST bootstrap flow but highlights the critical divergences required for the Trusted Private Cloud (TPC) environment. For a detailed overview of the differences between Google Cloud and Google Cloud Dedicated, please refer to the [official S3NS documentation](https://documentation.s3ns.fr/docs/overview/tpc-key-differences).

## Configuration Reference

The following table lists the specific configuration values for different Google Cloud Dedicated (GCD) environments. Please replace the placeholders in the commands and configurations below with the values corresponding to your target universe.

| Variable | GCD In France | GCD In Berlin |
| :--- | :--- | :--- |
| `UNIVERSE_WEB_DOMAIN` | `cloud.s3nscloud.fr` | `cloud.berlin-build0.goog` |
| `UNIVERSE_API_DOMAIN` | `s3nsapis.fr` | `apis-berlin-build0.goog` |
| `UNIVERSE_NAME` | `s3ns` | `berlin` |
| `UNIVERSE_PREFIX` | `s3ns` | `eu0` |
| `UNIVERSE_REGION` | `u-france-east1` | `u-germany-northeast1` |


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

Clone the latest version of the repository (currently v50.0.0) or download it from the Releases page:

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
2. **Enable APIs:** Enable the `orgpolicy.googleapis.com` service within this project.
3. **Set default project:** Configure your CLI context:

    ```bash
    gcloud config set project <TEMP_PROJECT_ID>
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

## 5. Managing Organization Policies

*This section extends the [Importing org policies](../README.md#importing-org-policies) instructions.*

Organization policies must be adapted to account for universe-specific constraints and available services. The recommended approach is to **bypass organization policies** during the first apply and then enable them iteratively.

### Step A: Bypass for First Apply

1. **Rename** the `organization/org-policies` folder (e.g., to `organization/org-policies.unused`).
2. **Comment out** the `org-policies` block in the `projects/iac-0.yaml` file.
3. Run `terraform apply` as described in the [First apply cycle](../README.md#first-apply-cycle) section.

### Step B: Iterative Import

Once the stage is applied and you have switched credentials to the IaC service account:

1. Create an empty `organization/org-policies` folder.
2. Move policy YAML files back one by one, uncommenting relevant policies.
3. **Adjust constraints:** Update policy values for GCD. For example, the `compute.trustedImageProjects` constraint must reference your universe-specific system projects:

```yaml
compute.trustedImageProjects:
  rules:
  - allow:
      values:
        # Replace UNIVERS_PREFIX with the value from the Configuration Reference table
        - "is:projects/<UNIVERSE_PREFIX>-system:cos-cloud"
        - "is:projects/<UNIVERSE_PREFIX>-system:debian-cloud"
        - "is:projects/<UNIVERSE_PREFIX>-system:rocky-linux-cloud"
        - "is:projects/<UNIVERSE_PREFIX>-system:ubuntu-os-cloud"
```

To import pre-existing default policies without modifying them, define the constraint in your `terraform.tfvars` using the `org_policies_imports` variable:

```terraform
org_policies_imports = [
  "compute.trustedImageProjects",
]
```

## 6. Next Steps

Once the **Organization Setup** stage is fully deployed, you can proceed with subsequent stages (VPC-SC, Security, Networking, Project Factory). The universe configuration established here is automatically propagated to these stages via the FAST cross-stage output mechanism.
