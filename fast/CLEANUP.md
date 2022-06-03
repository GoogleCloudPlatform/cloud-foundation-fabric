# FAST deployment clean up
In case you require destroying FAST deployment in your organization, follow these steps. 

Destruction goes in reverse order, from stage 3 to stage 0:

## Stage 3 (Project Factory)

```bash
cd $FAST_PWD/03-project-factory/prod/
terraform destroy
```

## Stage 3 (GKE)

```bash
cd $FAST_PWD/03-project-factory/prod/

for x in $(terraform state list | grep google_bigquery_dataset); do  
  terraform state rm "$x"; 
done

terraform destroy
```


# Stage 2 (Security)
```bash
cd $FAST_PWD/02-security/
terraform destroy
```

# Networking
```bash
cd $FAST_PWD/02-networking-XXX/
terraform destroy
```bash

There's a minor glitch that can surface running terraform destroy, where the service project attachments to the Shared VPC will not get destroyed even with the relevant API call succeeding. We are investigating the issue, in the meantime just manually remove the attachment in the Cloud console or via the gcloud beta compute shared-vpc associated-projects remove command when terraform destroy fails, and then relaunch the command.
