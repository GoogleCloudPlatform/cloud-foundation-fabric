# Manual pipeline Example: PubSub to Bigquery

In this example we will publish person message in the following format:

```txt
name: Lorenzo
surname: Caggioni
timestamp: 1617898199
```

a Dataflow pipeline will read those messages and import them into a Bigquery table in the DWH project.

An autorized view will be created in the datamart project to expose the table.

[TODO] Remove hardcoded 'lcaggio' variables and made ENV variable for it.
[TODO] Further automation is expected in future.

Create and download keys for Service accounts you created, be sure to have `iam.serviceAccountKeys.create` permission on projects or at folder level.

```bash
gcloud iam service-accounts keys create sa-landing.json --iam-account=sa-landing@landing-lc01.iam.gserviceaccount.com
gcloud iam service-accounts keys create sa-transformation.json --iam-account=sa-transformation@transformation-lc01.iam.gserviceaccount.com
gcloud iam service-accounts keys create sa-dwh.json --iam-account=sa-dwh@dwh-lc01.iam.gserviceaccount.com
```

## Create BQ table

Those steps should be done as Transformation Service Account:

```bash
gcloud auth activate-service-account sa-dwh@dwh-lc01.iam.gserviceaccount.com --key-file=sa-dwh.json --project=dwh-lc01
```

and you can run the command to create a table:

```bash
bq mk \
-t \
--description "This is a Test Person table" \
dwh-lc01:bq_raw_dataset.person \
name:STRING,surname:STRING,timestamp:TIMESTAMP
```

## Produce PubSub messages

Those steps should be done as landing Service Account:

```bash
gcloud auth activate-service-account sa-landing@landing-lc01.iam.gserviceaccount.com --key-file=sa-landing.json --project=landing-lc01
```

and let's now create a series of messages we can use to import:

```bash
for i in {0..10} 
do 
  gcloud pubsub topics publish projects/landing-lc01/topics/landing-1 --message="{\"name\": \"Lorenzo\", \"surname\": \"Caggioni\", \"timestamp\": \"$(date +%s)\"}"
done
```

if you want to check messages published, you can use the Transformation service account:

```bash
gcloud auth activate-service-account sa-transformation@transformation-lc01.iam.gserviceaccount.com --key-file=sa-transformation.json --project=transformation-lc01
```

and read a message (message won't be acked and will stay in the subscription):

```bash
gcloud pubsub subscriptions pull projects/landing-lc01/subscriptions/sub1
```

## Dataflow

Those steps should be done as transformation Service Account:

```bash
gcloud auth activate-service-account sa-transformation@transformation-lc01.iam.gserviceaccount.com --key-file=sa-transformation.json --project=transformation-lc01
```

Let's than start a Dataflwo streaming pipeline using a Google provided template using internal only IPs, the created network and subnetwork, the appropriate service account and requested parameters:

```bash
gcloud dataflow jobs run test_lcaggio01 \
    --gcs-location gs://dataflow-templates/latest/PubSub_Subscription_to_BigQuery \
    --project transformation-lc01 \
    --region europe-west3 \
    --disable-public-ips \
    --network transformation-vpc \
    --subnetwork regions/europe-west3/subnetworks/transformation-subnet \
    --staging-location gs://transformation-lc01-eu-temp \
    --service-account-email sa-transformation@transformation-lc01.iam.gserviceaccount.com \
    --parameters \
inputSubscription=projects/landing-lc01/subscriptions/sub1,\
outputTableSpec=dwh-lc01:bq_raw_dataset.person
```
