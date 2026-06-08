#!/bin/bash

AUDIENCE=locations/global/workforcePools/preview-pso-p/providers/preview-pso-pp
CONFIG_NAME=gcd-workshop-org
UNIVERSE_WEB_DOMAIN=cloud.berlin-build0.goog
UNIVERSE_API_DOMAIN=apis-berlin-build0.goog
WIF_FILE=wif-${CONFIG_NAME}-login-config.json

echo "https://console.cloud.berlin-build0.goog/"
echo $AUDIENCE

# gcloud config configurations create $CONFIG_NAME
gcloud config configurations activate $CONFIG_NAME
gcloud config set universe_domain $UNIVERSE_API_DOMAIN

gcloud iam workforce-pools create-login-config $AUDIENCE \
  --universe-cloud-web-domain="$UNIVERSE_WEB_DOMAIN" \
  --universe-domain="$UNIVERSE_API_DOMAIN" \
  --output-file="$WIF_FILE" \
  --activate

gcloud auth login --login-config=$WIF_FILE --no-launch-browser
gcloud auth application-default login --login-config=$WIF_FILE --no-launch-browser
