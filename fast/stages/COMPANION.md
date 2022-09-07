# FAST deployment companion guide
In order to successfully deploy your GCP Landing Zone using FAST in your organization, a series of prerequisites are required before starting. Then, FAST deployment is splitted in different stages that are required to be executed in order as some of them depend on previous stages output.

Detailed explanation of each stage execution, configuration or possible modifications and adaptations are included in each stage section. The target of this companion guide is to serve as a cheat sheet, including the list of commands to be executed during FAST deployment. 

**Warning! Executing FAST sets organization policies and authoritative role bindings in your GCP Organization. We recommend using FAST on a clean organization, or to fork and adapt FAST to support your existing Organization needs.**

## Prerequisites
1. First of all, go to Workspace / Cloud Identity and create (or validate they already exist) all the required groups closely mirroring the [GCP Enterprise Setup checklist](https://cloud.google.com/docs/enterprise/setup-checklist):
- gcp-billing-admins@
- gcp-devops@
- gcp-network-admins@
- gcp-organization-admins@
- gcp-security-admins@
- gcp-support@
2. Grant your user “Organization Administrator” role in your Organization and add it to the gcp-organization-admins@ group
3. If you already executed FAST in your Organization, [clean it up](CLEANUP.md) before executing it again
4. Login
```bash
gcloud auth list
gcloud auth login
gcloud auth application-default login
```
5. Clone Fabric
```bash
git clone https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git
```
6. Grant required roles to your user
```bash
# set a variable to the fast folder
export FAST_PWD="$(pwd)/fast/stages"

# set the initial user variable via gcloud
export FAST_BU=$(gcloud config list --format 'value(core.account)')

# find your org id
gcloud organizations list --filter display_name:[part of your domain]

# set your org id
export FAST_ORG_ID=123456

# set needed roles (do not change this)
export FAST_ROLES="roles/billing.admin roles/logging.admin \
roles/iam.organizationRoleAdmin roles/resourcemanager.projectCreator"

for role in $FAST_ROLES; do
gcloud organizations add-iam-policy-binding $FAST_ORG_ID \
--member user:$FAST_BU --role $role
done
```
7. Configure Billing Account permissions. 
If you are using a standalone billing account, the identity applying this stage for the first time needs to be a Billing Administrator
```bash
# find your billing account id with gcloud beta billing accounts list
# replace with your billing id!
export FAST_BA_ID=0186A4-36005F-9ADEDE
# set needed roles (do not change this)
gcloud beta billing accounts add-iam-policy-binding $FAST_BA_ID \
--member user:$FAST_BU --role roles/billing.admin
```
If you are using a billing account in a different organization, please follow [these steps](00-bootstrap#billing-account-in-a-different-organization) instead

## Stage 0 (Bootstrap)
This initial stage will create common projects for IaC, Logging & Billing, and bootstrap IAM policies.

```bash
# move to the 00-bootstrap directory
cd $FAST_PWD/00-bootstrap

# copy the template terraform tfvars file and save as `terraform.tfvars`
# then edit to match your environment!
edit terraform.tfvars.sample
```

```hcl
# fetch the required id by running `gcloud beta billing accounts list`
billing_account={
    id="012345-67890A-BCDEF0"
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

# link the generated provider file
ln -s ~/fast-config/providers/00-bootstrap* .

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
cd $FAST_PWD/01-resman

# Link providers and variables from previous stages
ln -s ~/fast-config/providers/01-resman-providers.tf .
ln -s ~/fast-config/tfvars/00-bootstrap.auto.tfvars.json .
ln -s ~/fast-config/tfvars/globals.auto.tfvars.json .

# Edit your terraform.tfvars to append Teams configuration (optional)
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
     "team-1-users@example.com" = ["roles/viewer"]
   }
   impersonation_groups = [
      "team-1-admins@example.com"
   ]
 }
}
```
```bash
# Showtime!
terraform init
terraform apply
```

## Stage 2 (Networking)
In this stage, we will deploy one of the 3 available Hub&Spoke networking topologies:
1. VPC Peering
2. HA VPN
3. Multi-NIC appliances (NVA)
```bash
# move to the 02-networking-vpn directory
cd $FAST_PWD/02-networking-XXX

# setup providers and variables from previous stages
ln -s ~/fast-config/providers/02-networking-providers.tf .
ln -s ~/fast-config/tfvars/00-bootstrap.auto.tfvars.json .
ln -s ~/fast-config/tfvars/01-resman.auto.tfvars.json .
ln -s ~/fast-config/tfvars/globals.auto.tfvars.json .

# Copy and edit terraform.tfvars. output_location variable is required to generate networking stage output
cp ../00-bootstrap/terraform.tfvars .
edit terraform.tfvars
```
```hcl
# path for automatic generation of configs
outputs_location = "~/fast-config"
```
```bash
# Showtime!
terraform init
terraform apply
```

## Stage 2 (Security)
This stage sets up security resources (KMS and VPC-SC) and configurations which impact the whole organization, or are shared across the hierarchy to other projects and teams.
```bash
# move to the 02-security directory
cd $FAST_PWD/02-security

# link providers and variables from previous stages
ln -s ~/fast-config/providers/02-security-providers.tf .
ln -s ~/fast-config/tfvars/00-bootstrap.auto.tfvars.json .
ln -s ~/fast-config/tfvars/01-resman.auto.tfvars.json .
ln -s ~/fast-config/tfvars/globals.auto.tfvars.json .

# Copy and edit terraform.tfvars to include KMS and/or VPC-SC configuration
cp ../00-bootstrap/terraform.tfvars .
edit terraform.tfvars
```
Some examples of terraform.tfvars configurations for KMS and VPC-SC can be found [here](02-security#customizations)
```bash
terraform init
terraform apply
```

## Stage 3 (Project Factory)
The Project Factory stage builds on top of your foundations to create and set up projects (and related resources) to be used for your workloads. It is organized in folders representing environments (e.g. "dev", "prod"), each implemented by a stand-alone terraform resource factory.
```bash
# Variable `outputs_location` is set to `~/fast-config`
cd $FAST_PWD/03-project-factory/ENVIRONMENT
ln -s ~/fast-config/providers/03-project-factory-ENVIRONMENT-providers.tf .

ln -s ~/fast-config/tfvars/00-bootstrap.auto.tfvars.json .
ln -s ~/fast-config/tfvars/01-resman.auto.tfvars.json . 
ln -s ~/fast-config/tfvars/02-networking.auto.tfvars.json .

# Define your environment default values (eg for billing alerts and labels)
edit data/defaults.yaml

# Create one yaml file per project to be created. Yaml file will include project configuration. Projects will be named after the filename
cp data/projects/project.yaml.sample data/projects/YOUR_PROJECT_NAME.yaml
edit data/projects/YOUR_PROJECT_NAME.yaml

terraform init
terraform apply
```
