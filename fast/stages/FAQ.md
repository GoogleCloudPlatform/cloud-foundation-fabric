# FAST Mini FAQ

- **How can the automation, logging and/or billing export projects be placed under specific folders instead of the org?**
  - Run the bootstrap stage and let automation, logging and/or billing projects be created under the organization.
  - Add the needed folders to the resource manager stage, or create them outside the stage in the console/gcloud or from a custom Terraform setup.
  - Once folders have been created go back to the bootstrap stage, and edit your tfvars file by adding their ids to the `project_parent_ids` variable.
  - Run the bootstrap stage again, the projects will be moved under the desired folders.
- **Why do we need two separate service accounts when configuring CI/CD pipelines (CI/CD SA and IaC SA)?**
  - To have the pipeline workflow follow the same impersonation flow ([CI/CD SA impersonates IaC SA](IaC_SA.png)) used when applying Terraform manually (user impersonates IaC SA), which allows the pipeline to consume the same auto-generated provider files.
  - To allow disabling pipeline credentials in case of issues with a single operation, by removing the ability of the CI/CD SA to impersonate the IaC SA.
- **How can I fix permission issues when running Terraform apply?**
  - Make sure your account is part of the organization admin group defined in variables.
  - Make sure you have configured [application default credentials](https://cloud.google.com/docs/authentication/application-default-credentials), rerun `gcloud auth login --update-adc` to fix them.
- **My GCP Org is not empty, what is the best way to save existing work and still install Fast?**
  - Background: Fast needs to be installed on the org level - because of many things that one can do only on that level, like the org policy role, secure tags, org policies
  - Create a folder, you can call it "Legacy"
  - Move all the existing projects and folders into this folder (you can do it by selecting all of them at once on the [resource management page](https://console.cloud.google.com/cloud-resource-manager) of the GCP console)
  - Collect the existing defined org policies and save them:
    ```
    gcloud organizations list
    export FAST_ORG_ID=123456
    for c in $(gcloud org-policies list --organization $FAST_ORG_ID --format='get(constraint)'); do gcloud org-policies describe --organization $FAST_ORG_ID $c ; echo '---' ; done > previous_policies.yaml
    ```
  - Analyze the policies together with [the ones Fast applies](1-resman/data/org-policies) and apply the ones that still make sense on that "Legacy" folder level
  - Proceed with installing Fast normally
