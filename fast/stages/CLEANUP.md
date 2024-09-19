# FAST deployment clean up

If you want to destroy a previous FAST deployment in your organization, follow these steps.

Destruction must be done in reverse order, from stage 3 to stage 0

## Stage 3 (GKE)

Terraform refuses to delete non-empty GCS buckets and BigQuery datasets, so they need to be removed manually from the state.

```bash
cd $FAST_PWD/3-gke-multitenant/dev/

# remove BQ dataset manually
for x in $(terraform state list | grep google_bigquery_dataset); do
  terraform state rm "$x";
done

terraform destroy
```

## Stage 3 (Data Platform)

Terraform refuses to delete non-empty GCS buckets and BigQuery datasets, so they need to be removed manually from the state.

```bash
cd $FAST_PWD/3-data-platform/dev/

# remove GCS buckets and BQ dataset manually. Projects will be destroyed anyway
for x in $(terraform state list | grep google_storage_bucket.bucket); do
  terraform state rm "$x";
done

for x in $(terraform state list | grep google_bigquery_dataset); do
  terraform state rm "$x";
done

terraform destroy
```

## Stage 2 (Project Factory)

```bash
cd $FAST_PWD/2-project-factory/
terraform destroy
```

## Stage 2 (Security)

```bash
cd $FAST_PWD/2-security/
terraform destroy
```

## Stage 2 (Networking)

```bash
cd $FAST_PWD/2-networking-XXX/
terraform destroy
```

A minor glitch can surface running `terraform destroy`, where the service project attachments to the Shared VPCs will not get destroyed even with the relevant API call succeeding. We are investigating the issue but in the meantime, manually remove the attachment in the Cloud console or via the ```gcloud beta compute shared-vpc associated-projects remove``` [command](https://cloud.google.com/sdk/gcloud/reference/beta/compute/shared-vpc/associated-projects/remove) when destroy fails, and then relaunch the command.

## Stage 1 (Resource Management)

Stage 1 is a little more complicated because of the GCS buckets containing your terraform statefiles. By default, Terraform refuses to delete non-empty buckets, which is good to protect your terraform state, but it makes destruction a bit harder. Use the commands below to remove the GCS buckets from the state and then execute `terraform destroy`

```bash
cd $FAST_PWD/1-resman/

# remove buckets from state since terraform refuses to delete them
for x in $(terraform state list | grep google_storage_bucket.bucket); do
  terraform state rm "$x"
done

terraform destroy
```

## Stage 0 (Bootstrap)

**Warning: you should follow these steps carefully as we will modify our own permissions. Ensure you can grant yourself the Organization Admin role again. Otherwise, you will not be able to finish the destruction process and will, most likely, get locked out of your organization.**

Just like before, we manually remove several resources (GCS buckets and BQ datasets). Note that `terrafom destroy` will fail. This is expected; just continue with the rest of the steps.

```bash
cd $FAST_PWD/0-bootstrap/
export FAST_BU=$(gcloud config list --format 'value(core.account)')

terraform apply -var bootstrap_user=$FAST_BU

# remove GCS buckets and BQ dataset manually. Projects will be destroyed anyway
for x in $(terraform state list | grep google_storage_bucket.bucket); do
  terraform state rm "$x";
done

for x in $(terraform state list | grep google_bigquery_dataset); do
  terraform state rm "$x";
done

## remove the providers file and migrate state
rm 0-bootstrap-providers.tf

# migrate to local state
terraform init -migrate-state
terraform destroy

```

When the destroy fails, continue with the steps below. Again, make sure your user (the one you are using to execute this step) has the Organization Administrator role, as we will remove the permissions for the organization-admins group

```bash
# Add the Organization Admin role to $BU_USER in the GCP Console
# then execute the command below to grant yourself the permissions needed
# to finish the destruction
export FAST_DESTROY_ROLES="roles/resourcemanager.projectDeleter \
  roles/owner roles/resourcemanager.organizationAdmin"

# set your org id
export FAST_ORG_ID=XXXX

for role in $FAST_DESTROY_ROLES; do
  gcloud organizations add-iam-policy-binding $FAST_ORG_ID \
    --member user:$FAST_BU --role $role --condition None
done

terraform destroy
rm -i terraform.tfstate*
```

In case you want to deploy FAST stages again, the make sure to:

* Modify the [prefix](0-bootstrap/variables.tf) variable to allow the deployment of resources that need unique names (eg, projects).
* Modify the [custom_roles](0-bootstrap/variables.tf) variable to allow recently deleted custom roles to be created again.
