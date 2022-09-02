# FAST deployment companion guide
In order to successfully deploy your GCP Landing Zone using FAST in your organization, a series of prerequisites are required to be followed before starting. Then, FAST deployment is splitted in different stages that are required to be executed in order as some of them depend on previous stages output.

Detailed explanation of each stage execution, configuration or possible modifications and adaptations are included in each stage section. The target of this companion guide is to serve as a cheat sheet with the list of commands to be executed during FAST deployment. 

**Warning**
Executing FAST sets organization policies and authoritative role bindings in your GCP Organization. We recommend using FAST on a clean organization, or to fork and adapt FAST to support your existing Organization.

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
# find your billing account id
# replace with your billing id!
export FAST_BA_ID=0186A4-36005F-9ADEDE
# set needed roles (do not change this)
gcloud beta billing accounts add-iam-policy-binding $FAST_BA_ID \
--member user:$FAST_BU --role roles/billing.admin
```
If you are using a billing account in a different organization, please follow [these steps](00-bootstrap#billing-account-in-a-different-organization) instead

## Stage 0 (Bootstrap)

## Stage 1 (Resource Management)

## Stage 2 (Networking)

## Stage 2 (Security)

## Stage 3 (GKE)

## Stage 3 (Project Factory)
