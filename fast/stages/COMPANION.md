# FAST deployment companion guide

To deploy a GCP Landing Zone using FAST, your organization needs to meet a few prerequisites before starting. This guide serves as quick guide to prepare your GCP organization and also as cheat sheet with the commands and minimal configuration required to deploy FAST.

The detailed explanation of each stage, their configuration, possible modifications and adaptations are included in the README of stage. This document only outlines the minimal configuration to get from an empty organization to a working FAST deployment.

**Warning! Executing FAST sets organization policies and authoritative role bindings in your GCP Organization. We recommend using FAST on a clean organization, or to fork and adapt FAST to support your existing Organization needs.**

## Prerequisites

1. FAST uses the recommended groups from the [GCP Enterprise Setup checklist](https://cloud.google.com/docs/enterprise/setup-checklist). Go to [Workspace / Cloud Identity](https://admin.google.com) and ensure all the following groups exist:

- `gcp-billing-admins@`
- `gcp-devops@`
- `gcp-network-admins@`
- `gcp-organization-admins@`
- `gcp-security-admins@`
- `gcp-support@`

2. If you already executed FAST in your organization, make you [clean it up](CLEANUP.md) before continuing with the rest of this guide.

3. Grant your user “Organization Administrator” role in your organization and add it to the `gcp-organization-admins@` group.

4. Login with your user using gcloud.

```bash
gcloud auth login
gcloud auth application-default login
```

5. Clone the Fabric repository.

```bash
git clone https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git
cd cloud-foundation-fabric
```

6. Grant required roles to your user.

```bash
# set a variable to the fast folder
export FAST_PWD="$(pwd)/fast/stages"

# set the initial user variable via gcloud
export FAST_BU=$(gcloud config list --format 'value(core.account)')

# find your org id. change "fast.example.com" with your own org domain
gcloud organizations list --filter display_name:fast.example.com

# set your org id
export FAST_ORG_ID=1234567890

# set needed roles (do not change this)
export FAST_ROLES="roles/billing.admin roles/logging.admin \
roles/iam.organizationRoleAdmin roles/resourcemanager.projectCreator"

for role in $FAST_ROLES; do
gcloud organizations add-iam-policy-binding $FAST_ORG_ID \
--member user:$FAST_BU --role $role
done
```

7. Configure Billing Account permissions.

If you are using a standalone billing account, the user applying this stage for the first time needs to be a Billing Administrator.

```bash
# find your billing account id with gcloud beta billing accounts list
# replace with your billing id!
export FAST_BA_ID=XXXXXX-YYYYYY-ZZZZZZ
# set needed roles (do not change this)
gcloud beta billing accounts add-iam-policy-binding $FAST_BA_ID \
--member user:$FAST_BU --role roles/billing.admin
```

If you are using a billing account in a different organization, please follow [these steps](0-bootstrap#billing-account-in-a-different-organization) instead.

## Stage 0 (Bootstrap)

This initial stage will create common projects for IaC, Logging & Billing, and bootstrap IAM policies.

```bash
# move to the 0-bootstrap directory
cd $FAST_PWD/0-bootstrap

# copy the template terraform tfvars file and save as `terraform.tfvars`
# then edit to match your environment!
edit terraform.tfvars.sample
```

Here you have a terraform.tfvars example:

```hcl
# fetch the required id by running `gcloud beta billing accounts list`
billing_account={
    id="XXXXXX-YYYYYY-ZZZZZZ"
    organization_id="01234567890"
}
# get the required info by running `gcloud organizations list`
organization={
    id="01234567890"
    domain="fast.example.com"
    customer_id="Cxxxxxxx"
}
# create your own 4-letters prefix
prefix="abcd"

# path for automatic generation of configs
outputs_location = "~/fast-config"
```

```bash
# run init and apply
terraform init
terraform apply -var bootstrap_user=$FAST_BU

# link providers file
ln -s ~/fast-config/providers/0-bootstrap-providers.tf ./

# re-run init and apply to remove user-level IAM
terraform init -migrate-state

# answer 'yes' to terraform's question
terraform apply
```

## Stage 1 (Resource Management)

This stage performs two important tasks:

- Create the top-level hierarchy of folders, and the associated resources used later on to automate each part of the hierarchy (eg. Networking).
- Set organization policies on the organization, and any exception required on specific folders.

```bash
# move to the 01-resman directory
cd $FAST_PWD/1-resman

# link providers and variables from previous stages
ln -s ~/fast-config/providers/1-resman-providers.tf .
ln -s ~/fast-config/tfvars/0-bootstrap.auto.tfvars.json .
ln -s ~/fast-config/tfvars/0-globals.auto.tfvars.json .

# edit your terraform.tfvars to append Teams configuration (optional)
edit terraform.tfvars
```

In the following terraform.tfvars it is shown an example of configuration for teams provisioning:

```hcl
outputs_location = "~/fast-config"

# optional
team_folders = {
 team-1 = {
   descriptive_name = "Team 1"
   group_iam = {
     "team-1-users@fast.example.com" = ["roles/viewer"]
   }
   impersonation_groups = [
      "team-1-admins@fast.example.com"
   ]
 }
}
```

```bash
# run init and apply
terraform init
terraform apply
```

## Stage 2 (Networking)

In this stage, we will deploy one of the 3 available Hub&Spoke networking topologies:

1. VPC Peering
2. HA VPN
3. Multi-NIC appliances (NVA)
4. Multi-NIC appliances (NVA) with NCC / BGP support

```bash
# move to the 02-networking-XXX directory (where XXX should be one of a-peering|b-vpn|c-nva|d-separate-envs|e-nva-bgp)
cd $FAST_PWD/2-networking-XXX

# setup providers and variables from previous stages
ln -s ~/fast-config/providers/2-networking-providers.tf .
ln -s ~/fast-config/tfvars/0-bootstrap.auto.tfvars.json .
ln -s ~/fast-config/tfvars/1-resman.auto.tfvars.json .
ln -s ~/fast-config/tfvars/0-globals.auto.tfvars.json .

# create terraform.tfvars. output_location variable is required to generate networking stage output file
edit terraform.tfvars
```

In the following terraform.tfvars we configure output_location variable to generate networking stage output file:

```hcl
# path for automatic generation of configs
outputs_location = "~/fast-config"
```

```bash
# run init and apply
terraform init
terraform apply
```

## Stage 2 (Security)

This stage sets up security resources (KMS and VPC-SC) and configurations which impact the whole organization, or are shared across the hierarchy to other projects and teams.

```bash
# move to the 02-security directory
cd $FAST_PWD/02-security

# link providers and variables from previous stages
ln -s ~/fast-config/providers/2-security-providers.tf .
ln -s ~/fast-config/tfvars/0-bootstrap.auto.tfvars.json .
ln -s ~/fast-config/tfvars/1-resman.auto.tfvars.json .
ln -s ~/fast-config/tfvars/0-globals.auto.tfvars.json .

# edit terraform.tfvars to include KMS and/or VPC-SC configuration
edit terraform.tfvars
```

Some examples of terraform.tfvars configurations for KMS and VPC-SC can be found [here](2-security#customizations)

```bash
# run init and apply
terraform init
terraform apply
```

## Stage 3 (Project Factory)

The Project Factory stage builds on top of your foundations to create and set up projects (and related resources) to be used for your workloads. It is organized in folders representing environments (e.g. "dev", "prod"), each implemented by a stand-alone terraform resource factory.

```bash
# variable `outputs_location` is set to `~/fast-config`
cd $FAST_PWD/3-project-factory/ENVIRONMENT
ln -s ~/fast-config/providers/3-project-factory-ENVIRONMENT-providers.tf .

ln -s ~/fast-config/tfvars/0-bootstrap.auto.tfvars.json .
ln -s ~/fast-config/tfvars/1-resman.auto.tfvars.json . 
ln -s ~/fast-config/tfvars/2-networking.auto.tfvars.json .
ln -s ~/fast-config/tfvars/0-globals.auto.tfvars.json .

# define your environment default values (eg for billing alerts and labels)
edit data/defaults.yaml

# create one YAML file per project to be created with project configuration
# filenames will be used for project ids
cp data/projects/project.yaml.sample data/projects/YOUR_PROJECT_NAME.yaml
edit data/projects/YOUR_PROJECT_NAME.yaml

# run init and apply
terraform init
terraform apply
```
