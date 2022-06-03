# FAST deployment clean up
In case you require destroying FAST deployment in your organization, follow these steps. 

Destruction goes in reverse order, from stage 3 to stage 0:

## Stage 3 (Project Factory)

```bash
cd $FAST_PWD/03-project-factory/prod/
terraform destroy
```

## Stage 3 (GKE)
Terraform refuses to delete empty GCS buckets and/or BigQuery datasets, so they need to be removed manually from tf state

```bash
cd $FAST_PWD/03-project-factory/prod/

# remove BQ dataset manually
for x in $(terraform state list | grep google_bigquery_dataset); do  
  terraform state rm "$x"; 
done

terraform destroy
```


## Stage 2 (Security)
```bash
cd $FAST_PWD/02-security/
terraform destroy
```

## Stage 2 (Networking)
```bash
cd $FAST_PWD/02-networking-XXX/
terraform destroy
```

There's a minor glitch that can surface running terraform destroy, where the service project attachments to the Shared VPC will not get destroyed even with the relevant API call succeeding. We are investigating the issue, in the meantime just manually remove the attachment in the Cloud console or via the gcloud beta compute shared-vpc associated-projects remove command when terraform destroy fails, and then relaunch the command.

## Stage 1 (Resource Management)
Stage 1 is a little more complicated because of the GCS Buckets. By default terraform refuses to delete non-empty buckets, which is a good thing for your terraform state. However, it makes destruction a bit harder


```bash
cd $FAST_PWD/01-resman/

# remove buckets from state since terraform refuses to delete them
for x in $(terraform state list | grep google_storage_bucket.bucket); do  
  terraform state rm "$x"
done

terraform destroy
```

## Stage 0 (Bootstrap)
**You should follow these steps carefully because we can end up destroying our own permissions. As we will be removing gcp-admins group roles, where your user belongs, you will be required to grant organization admin role again**

We also have to remove several resources (GCS buckets and BQ datasets) manually.

```bash
cd $FAST_PWD/00-bootstrap/

# remove provider config to execute without SA impersonation
rm 00-bootstrap-providers.tf

# migrate to local state
terraform init -migrate-state

# remove GCS buckets and BQ dataset manually
for x in $(terraform state list | grep google_storage_bucket.bucket); do  
  terraform state rm "$x"; 
done

for x in $(terraform state list | grep google_bigquery_dataset); do  
  terraform state rm "$x"; 
done

terraform destroy

# when this fails continue with the steps below
# make your user (the one you are using to execute this step) org admin again, as we will remove organization-admins group roles

# Add the Organization Admin role to $BU_USER in the GCP Console

# grant yourself this permission so you can finish the destruction
export FAST_DESTROY_ROLES="roles/billing.admin roles/logging.admin \
  roles/iam.organizationRoleAdmin roles/resourcemanager.projectDeleter \
  roles/resourcemanager.folderAdmin roles/owner"

export FAST_BU=$(gcloud config list --format 'value(core.account)')

# find your org id
gcloud organizations list --filter display_name:[part of your domain]

# set your org id
export FAST_ORG_ID=XXXX

for role in $FAST_DESTROY_ROLES; do
  gcloud organizations add-iam-policy-binding $FAST_ORG_ID \
    --member user:$FAST_BU --role $role
done

terraform destroy
rm -i terraform.tfstate*

```
