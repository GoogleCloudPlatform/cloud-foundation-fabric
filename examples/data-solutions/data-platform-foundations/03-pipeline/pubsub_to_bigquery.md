# Manual pipeline Example: PubSub to Bigquery

In this example we will publish person message in the following format:

```txt
name: Name
surname: Surname
timestamp: 1617898199
```

a Dataflow pipeline will read those messages and import them into a Bigquery table in the DWH project.

An autorized view will be created in the datamart project to expose the table.

[TODO] Further automation is expected in future.

## Set up the env vars
```bash
export DWH_PROJECT_ID=**dwh_project_id** 
export LANDING_PROJECT_ID=**landing_project_id** 
export TRANSFORMATION_PROJECT_ID=*transformation_project_id*
```

## Create BQ table
Those steps should be done as DWH Service Account.

You can run the command to create a table:

```bash
gcloud --impersonate-service-account=sa-datawh@$DWH_PROJECT_ID.iam.gserviceaccount.com \
alpha bq tables create person \
--project=$DWH_PROJECT_ID --dataset=bq_raw_dataset \
--description "This is a Test Person table" \
--schema name=STRING,surname=STRING,timestamp=TIMESTAMP
```

## Produce PubSub messages

Those steps should be done as landing Service Account:

Let's now create a series of messages we can use to import:

```bash
for i in {0..10} 
do 
  gcloud --impersonate-service-account=sa-landing@$LANDING_PROJECT_ID.iam.gserviceaccount.com pubsub topics publish projects/$LANDING_PROJECT_ID/topics/landing-1 --message="{\"name\": \"Lorenzo\", \"surname\": \"Caggioni\", \"timestamp\": \"$(date +%s)\"}"
done
```

if you want to check messages published, you can use the Transformation service account and read a message (message won't be acked and will stay in the subscription):

```bash
gcloud --impersonate-service-account=sa-transformation@$TRANSFORMATION_PROJECT_ID.iam.gserviceaccount.com pubsub subscriptions pull projects/$LANDING_PROJECT_ID/subscriptions/sub1
```

## Dataflow

Those steps should be done as transformation Service Account:

Let's than start a Dataflow streaming pipeline using a Google provided template using internal only IPs, the created network and subnetwork, the appropriate service account and requested parameters:

```bash
gcloud dataflow jobs run test_streaming01 \
    --gcs-location gs://dataflow-templates/latest/PubSub_Subscription_to_BigQuery \
    --project $TRANSFORMATION_PROJECT_ID \
    --region europe-west3 \
    --disable-public-ips \
    --network transformation-vpc \
    --subnetwork regions/europe-west3/subnetworks/transformation-subnet \
    --staging-location gs://$TRANSFORMATION_PROJECT_ID-eu-temp \
    --service-account-email sa-transformation@$TRANSFORMATION_PROJECT_ID.iam.gserviceaccount.com \
    --parameters \
inputSubscription=projects/$LANDING_PROJECT_ID/subscriptions/sub1,\
outputTableSpec=$DWH_PROJECT_ID:bq_raw_dataset.person
```
