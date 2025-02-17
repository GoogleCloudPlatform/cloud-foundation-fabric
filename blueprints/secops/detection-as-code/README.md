# Detection as Code in Terraform for Google SecOps

This blueprint is a sample terraform repository to implementing a Detection as code pipeline for managing Google SecOps rules based on Terraform code.
For more information of the code available and how to use it to deploy rules in SecOps please refer to this [medium article](https://medium.com/p/646de8967278).

### GitLab CICD Pipeline design

![GitLab CICD Pipeline](./images/diagram.png)

A brief workflow description:

1. **Code Commit and Testing (Optional)**: A SOC engineer makes changes to the Terraform configuration (might be an update to the YARA-L rule or its configuration in the YAML file) in their local development environment. They may optionally test these changes locally with a local terraform plan command.

2. **Create Merge Request**: The engineer commits the changes and pushes them to a feature branch in the GitLab repository. Then creates a merge request (MR) in GitLab, which will trigger the CI/CD pipeline.

3. **GitLab Plan Pipeline**: The first pipeline executing when a new MR is open is responsible for setting up authentication, initializes Terraform (terraform init), validates the configuration files (terraform validate) to ensure they are syntactically correct and then generates an execution plan (terraform plan) outlining the changes that will be made to the SecOps rules. The plan is then attached as a report to the MR.


4. **Review and Approval**: Another SOC engineer (or a predefined set of reviewers) reviews the report generated from the Terraform plan and the proposed chages. If the plan is approved, the approver will approve and merge the MR, while if the changes need adjustments, the approver might request changes, requiring the original developer to update the code and push new commits to the feature branch, restarting the pipeline from step 3.

5. **GitLab Apply Pipeline**: Merging the MR triggers a new pipeline run on the main branch. The pipeline will still first initialize authentication and Terraform (terraform init). But then it will applly the proposed changes using terraform apply, deploying the updated or new YARA-L rules to Google SecOps.

6. **Report Results**: The pipeline might then optionally reports the results of the deployment (success or failure) to the SOC engineers team, where the SOC team might just have to do some operations in case of a failure.

### Deployment

#### Step 0: Cloning the repository

If you want to deploy from your Cloud Shell, click on the image below, sign in
if required and when the prompt appears, click on “confirm”.

[![Open Cloudshell](./images/cloud-shell-button.png)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2FGoogleCloudPlatform%2Fcloud-foundation-fabric&cloudshell_workspace=blueprints%2Fthird-party-solutions%2Fwordpress%2Fcloudrun)

Otherwise, in your console of choice:

```bash
git clone https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git
```

Before you deploy the architecture, you will need at least the following
information/configurations in place (for more precise configuration see the Variables section):

* A SecOps tenant deployed with BYOP
* The SecOps project ID
* Region and customer code for the SecOps tenant
* Chronicle API Admin or equivalent to access SecOps APIs

#### Step 2: Prepare the variables

Once you have the required information, head back to your cloned repository.
Make sure you’re in the directory of this tutorial (where this README is in).

Configure the Terraform variables in your `terraform.tfvars` file.
Rename the existing `terrafomr.tfvars.sample` as starting pointand then see the variables
documentation below.

#### Step 3: Deploy resources

Initialize your Terraform environment and deploy the resources:

```shell
terraform init
terraform apply
```

### GitLab CICD Configuration

Please first set up Workload Identity Federation and then replace the following in the .gitlab-ci.yml:

- SERVICE_ACCOUNT
- WIF_PROVIDER
- GITLAB_TOKEN audience

according to the WIF configuration. The service account the pipeline will impersonate must have Chronicle API Admin role or equivalent custom role for dealing with SecOps Rule Management APIs. It is important to setup a remote backend (possibly on GCS) before adopting the pipeline (of course).

### GitHub CICD Configuration

Please first set up Workload Identity Federation and then replace the following in the .github/workflows/secops.yaml:

- SERVICE_ACCOUNT
- WIF_PROVIDER

according to the WIF configuration. The service account the pipeline will impersonate must have Chronicle API Admin role or equivalent custom role for dealing with SecOps Rule Management APIs. It is important to setup a remote backend (possibly on GCS) before adopting the pipeline (of course).
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [secops_tenant_config](variables.tf#L29) | SecOps tenant configuration. | <code title="object&#40;&#123;&#10;  location &#61; optional&#40;string, &#34;eu&#34;&#41;&#10;  instance &#61; string&#10;  project  &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [secops_content_config](variables.tf#L17) | Path to SecOps rules and reference lists deployment YAML config files. | <code title="object&#40;&#123;&#10;  reference_lists &#61; string&#10;  rules &#61; string&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code title="&#123;&#10;  reference_lists &#61; &#34;secops_reference_lists.yaml&#34;&#10;  rules &#61; &#34;secops_rules.yaml&#34;&#10;&#125;">&#123;&#8230;&#125;</code> |
<!-- END TFDOC -->
## Test

```hcl
module "test" {
  source = "./fabric/blueprints/secops/detection-as-code"
  secops_config = {
    location = "eu"
    instance = "XXXXXX-XXX-XXXXXX"
    project  = "secops-project"
  }
}
# tftest modules=1 resources=2 files=rule,config
```

```
# tftest-file id=rule path=rules/network_traffic_to_specific_country.yaral
rule network_traffic_to_specific_country {

  meta:
    author = "Google Cloud Security"
    description = "Identify network traffic based on target country"
    type = "alert"
    tags = "geoip enrichment"
    data_source = "microsoft windows events"
    severity = "Low"
    priority = "Low"

  events:
    $network.metadata.event_type = "NETWORK_CONNECTION"
    //Specify a country of interest to monitor or add additional countries using an or statement
    $network.target.ip_geo_artifact.location.country_or_region = "France" nocase
    $network.target.ip = $ip

  match:
    $ip over 30m

  outcome:
    $risk_score = max(35)
    $event_count = count_distinct($network.metadata.id)

    // added to populate alert graph with additional context
    $principal_ip = array_distinct($network.principal.ip)

    // Commented out target.ip because it is already represented in graph as match variable. If match changes, can uncomment to add to results
    //$target_ip = array_distinct($network.target.ip)
    $principal_process_pid = array_distinct($network.principal.process.pid)
    $principal_process_command_line = array_distinct($network.principal.process.command_line)
    $principal_process_file_sha256 = array_distinct($network.principal.process.file.sha256)
    $principal_process_file_full_path = array_distinct($network.principal.process.file.full_path)
    $principal_process_product_specfic_process_id = array_distinct($network.principal.process.product_specific_process_id)
    $principal_process_parent_process_product_specfic_process_id = array_distinct($network.principal.process.parent_process.product_specific_process_id)
    $target_process_pid = array_distinct($network.target.process.pid)
    $target_process_command_line = array_distinct($network.target.process.command_line)
    $target_process_file_sha256 = array_distinct($network.target.process.file.sha256)
    $target_process_file_full_path = array_distinct($network.target.process.file.full_path)
    $target_process_product_specfic_process_id = array_distinct($network.target.process.product_specific_process_id)
    $target_process_parent_process_product_specfic_process_id = array_distinct($network.target.process.parent_process.product_specific_process_id)
    $principal_user_userid = array_distinct($network.principal.user.userid)
    $target_user_userid = array_distinct($network.target.user.userid)

  condition:
    $network
}
```

```
# tftest-file id=config path=secops_rules.yaml
network_traffic_to_specific_country:
  enabled: true
  alerting: true
  archived: false
  run_frequency: "DAILY"
```
