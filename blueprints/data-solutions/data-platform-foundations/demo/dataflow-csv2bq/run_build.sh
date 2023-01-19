#gcp-data-engineers

GCP_PROJECT="ff-orc"
TEMPLATE_IMAGE="europe-west1-docker.pkg.dev/ff-orc/ff-app-images/csv2bq:latest"
TEMPLATE_PATH="gs://ff-orc-cs-0/csv2bq.json"
STAGIN_PATH="gs://ff-orc-cs-build-staging/build"
LOG_PATH="gs://ff-orc-cs-build-staging/logs"

gcloud builds submit \
    --config=cloudbuild.yaml \
    --project=$GCP_PROJECT \
    --region="europe-west1" \
    --gcs-log-dir=$LOG_PATH \
    --gcs-source-staging-dir=$STAGIN_PATH \
    --substitutions=_TEMPLATE_IMAGE=$TEMPLATE_IMAGE,_TEMPLATE_PATH=$TEMPLATE_PATH,_DOCKER_DIR="."


#gcloud builds submit \
#        --config=./demo/dataflow-csv2bq/cloudbuild.yaml \
#        --project=ff-orc \
#        --region="europe-west1" \
#        --gcs-log-dir=gs://ff-orc-cs-build-staging/log \
#        --gcs-source-staging-dir=gs://ff-orc-cs-build-staging/staging \
#        --substitutions=_TEMPLATE_IMAGE="europe-west1-docker.pkg.dev/ff-orc/ff-app-images/csv2bq:latest",_TEMPLATE_PATH="gs://ff-orc-cs-df-template",_DOCKER_DIR="./demo/dataflow-csv2bq"
