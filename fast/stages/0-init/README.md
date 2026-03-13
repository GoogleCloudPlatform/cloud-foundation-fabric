# Fast Init

<!-- BEGIN TOC -->
<!-- END TOC -->

This stage establishes all the prerequisites required to execute 0-org-setup stage.

## Prerequisites

To successfully execute this stage, ensure the following are available:

* An organization
* A billing account
* A user belonging to a group that has the Organization Administrator role granted

In addition to that, edit the `datasets/[FACTORY-NAME]/default.yaml` file inside the `0-org-setup` stage, where `FACTORY-NAME` should be the factory of your choice (classic, hardened, etc), and populate the following:

* The billing account ID (`global.billing_account`)
* The organization ID (`global.organization.id`)
* The prefix to use for projects in your organization (`global.projects.defaults.prefix`)
* The group representing your organization admins (`context.iam_principals.gcp-organization-admins`)

To be able to run the `0-org-setup` stage we need a project to pre-exist in the organization. Some of the APIs enabled in the `0-org-setup` stage require a billing project. By default, this stage will create a project for you and enable those APIs in it. If however, you prefer that the APIs are enabled in an already existing in your organization, just create a `terraform.tfvars` and enter the project ID as follows:

```hcl
default_project_config = {
    project_id = "YOUR_PROJECT_ID"
}
```

By the default this stage will use the config file in `0-org-setup/classic/default.yaml`. In case you would like to use a different one, just add this to your terraform.tfvars

```hcl
default_factory_config = "datasets/YOUR-PREFERRED-FACTORY/default.yaml"
```

## Deployment

Once you have set these values you can run the stage by executing the following in the 0-init folder:

```bash
terraform init 
terraform apply
```

## Post-deployment

When terraform completes, take the `project_id` output and set your default project using gcloud CLI

```bash
gcloud config set project $(terraform output project_id)
```

Finally take the value of the `existing_org_policies` and add it to the terraform.tfvars of the `0-org-setup` stage

```bash
terraform output existing_org_policies > terraform.tfvars
```

Now you are ready to go to the `0-org-setup` stage!
