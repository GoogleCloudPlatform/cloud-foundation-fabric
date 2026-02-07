# Developer Workflow Project Template

This template provides a "paved path" for application development teams, establishing a secure and governed multi-environment setup (`dev`, `qa`, `prod`) ready for CI/CD integration.

It automates the creation of the necessary projects and IAM structures to support a typical developer workflow: developers build and test in non-production environments, while a separate group of approvers is required to promote changes to production. This process is commonly managed with tools like Cloud Build and Cloud Deploy, targeting services such as GKE, Cloud Run, or Firebase.

## Features

-   **Multi-Environment Setup**: Automatically provisions `dev`, `qa`, and `prod` projects.
-   **IAM & Key Groups**:
    -   Leverages `gcp-developers` and `gcp-approvers` Cloud Identity groups.
    -   Assigns appropriate IAM roles to these groups per environment, following the principle of least privilege (e.g., Developers have extensive permissions in `dev` but only `viewer` access in `prod`).
    -   The `gcp-approvers` group is essential for enabling secure release management workflows. In a CI/CD pipeline using Cloud Deploy, members of this group can be designated as the required approvers before a new build is promoted and deployed to the production environment.
-   **Service Enablement**: Optional toggles to enable common service stacks like Cloud Run, GKE, and Firebase.

## Usage

This template is typically used with the Project Factory stage. The following instructions assume you are running this template from within a project factory context.

1.  **Prerequisites**: This template requires a `gcp-approvers` group as the required approvers before a new build is promoted and deployed to the production environment.
    1.  Manually create a new group named `gcp-approvers` and `gcp-developers` in your Google Workspace (formerly G Suite) or Cloud Identity domain via the Google Groups interface or the Admin SDK.
    2.  In your `0-org-setup` stage, define these groups in your `organization.tf` file so that it's available for other stages.
     

2.  **Link FAST outputs**: Before running Terraform, you need to link the provider and variable files from your previous FAST stages. If you are using a GCS bucket for outputs, you can use a command similar to this:

    ```bash
    ../fast-links.sh gs://xxx-prod-iac-core-outputs-0
    ```

    This will generate commands to copy the necessary files. For example:

    ```bash
    # File linking commands for project factory (org level) stage
    
    # provider file
    gcloud storage cp gs://xxx-prod-iac-core-outputs-0/providers/2-project-factory-providers.tf ./
    
    # input files from other stages
    gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-globals.auto.tfvars.json ./
    gcloud storage cp gs://xxx-prod-iac-core-outputs-0/tfvars/0-org-setup.auto.tfvars.json ./
    ```

3.  **Run Terraform**: Once the configuration and provider files are in place, apply the template:

    ```bash
    terraform init
    terraform apply
    ```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [billing_account](variables.tf#L23) | Billing account id. | <code title="object&#40;&#123;&#10;  id &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [prefix](variables.tf#L79) | Prefix used for project ids. | <code>string</code> | ✓ |  |
| [automation](variables.tf#L17) | Automation options. | <code>any</code> |  | <code>&#123;&#125;</code> |
| [data_file](variables.tf#L30) | Path to the YAML data file. | <code>string</code> |  | <code>&#34;data&#47;values.yaml&#34;</code> |
| [iam_principals](variables.tf#L36) | Org-level IAM principals. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [locations](variables.tf#L42) | GCP locations. | <code title="object&#40;&#123;&#10;  bigquery &#61; string&#10;  logging  &#61; string&#10;  pubsub   &#61; list&#40;string&#41;&#10;  storage  &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  bigquery &#61; &#34;&#34;, logging &#61; &#34;&#34;, pubsub &#61; &#91;&#93;, storage &#61; &#34;&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [logging](variables.tf#L55) | Log writer identities for organization / folders. | <code title="object&#40;&#123;&#10;  writer_identities &#61; map&#40;string&#41;&#10;  project_number    &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [organization](variables.tf#L64) | Organization details. | <code title="object&#40;&#123;&#10;  domain      &#61; string&#10;  id          &#61; string&#10;  customer_id &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  domain &#61; &#34;&#34;&#10;  id          &#61; &#34;0&#34;&#10;  customer_id &#61; &#34;&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
| [project_numbers](variables.tf#L84) | Project numbers. | <code>map&#40;number&#41;</code> |  | <code>&#123;&#125;</code> |
| [root_node](variables.tf#L90) | Root node for the hierarchy, if running in tenant mode. | <code>string</code> |  | <code>null</code> |
| [service_accounts](variables.tf#L96) | Org-level service accounts. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [storage_buckets](variables.tf#L102) | Storage buckets created in the bootstrap stage. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [tag_values](variables.tf#L108) | Tag values. | <code>map&#40;string&#41;</code> |  | <code>&#123;&#125;</code> |
| [universe](variables.tf#L114) | GCP universe where to deploy the project. The prefix will be prepended to the project id. | <code title="object&#40;&#123;&#10;  prefix                         &#61; string&#10;  forced_jit_service_identities  &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  unavailable_services           &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;  unavailable_service_identities &#61; optional&#40;list&#40;string&#41;, &#91;&#93;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [group_emails](outputs.tf#L17) | Emails of the created groups. |  |
| [project_ids](outputs.tf#L25) | Project IDs of the created projects. |  |
<!-- END TFDOC -->
## Requirements

The service account used by the Project Factory stage requires the following permissions:

-   `roles/resourcemanager.projectCreator` on the parent folder.
-   `roles/billing.user` on the billing account.
-   `roles/cloudidentity.groupMember` on the `gcp-approvers` group to manage memberships.
