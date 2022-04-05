# IAM bindings reference

Legend: <code>+</code> additive, <code>•</code> conditional.

## Project <i>dev-data-cmn-0</i>

| members | roles |
|---|---|
|<b>gcp-data-analysts</b><br><small><i>group</i></small>|[roles/datacatalog.viewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.viewer) |
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/dlp.estimatesAdmin](https://cloud.google.com/iam/docs/understanding-roles#dlp.estimatesAdmin) <br>[roles/dlp.reader](https://cloud.google.com/iam/docs/understanding-roles#dlp.reader) <br>[roles/dlp.user](https://cloud.google.com/iam/docs/understanding-roles#dlp.user) |
|<b>gcp-data-security</b><br><small><i>group</i></small>|[roles/datacatalog.admin](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.admin) <br>[roles/dlp.admin](https://cloud.google.com/iam/docs/understanding-roles#dlp.admin) |
|<b>dev-data-load-df-0</b><br><small><i>serviceAccount</i></small>|[roles/datacatalog.viewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.viewer) <br>[roles/dlp.user](https://cloud.google.com/iam/docs/understanding-roles#dlp.user) |
|<b>dev-data-trf-bq-0</b><br><small><i>serviceAccount</i></small>|[roles/datacatalog.categoryFineGrainedReader](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.categoryFineGrainedReader) <br>[roles/datacatalog.viewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.viewer) |
|<b>dev-data-trf-df-0</b><br><small><i>serviceAccount</i></small>|[roles/datacatalog.categoryFineGrainedReader](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.categoryFineGrainedReader) <br>[roles/datacatalog.viewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.viewer) <br>[roles/dlp.user](https://cloud.google.com/iam/docs/understanding-roles#dlp.user) |

## Project <i>dev-data-dtl-0-0</i>

| members | roles |
|---|---|
|<b>gcp-data-analysts</b><br><small><i>group</i></small>|[roles/bigquery.dataViewer](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataViewer) <br>[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/bigquery.metadataViewer](https://cloud.google.com/iam/docs/understanding-roles#bigquery.metadataViewer) <br>[roles/bigquery.user](https://cloud.google.com/iam/docs/understanding-roles#bigquery.user) <br>[roles/datacatalog.tagTemplateViewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.tagTemplateViewer) <br>[roles/datacatalog.viewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.viewer) <br>[roles/storage.objectViewer](https://cloud.google.com/iam/docs/understanding-roles#storage.objectViewer) |
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) <br>[roles/storage.admin](https://cloud.google.com/iam/docs/understanding-roles#storage.admin) |
|<b>SERVICE_IDENTITY_service-networking</b><br><small><i>serviceAccount</i></small>|[roles/servicenetworking.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#servicenetworking.serviceAgent) <code>+</code>|
|<b>dev-data-load-df-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataOwner](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataOwner) <br>[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/storage.objectCreator](https://cloud.google.com/iam/docs/understanding-roles#storage.objectCreator) |
|<b>dev-data-trf-bq-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataOwner](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataOwner) <br>[roles/datacatalog.categoryAdmin](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.categoryAdmin) |
|<b>dev-data-trf-df-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataOwner](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataOwner) |

## Project <i>dev-data-dtl-1-0</i>

| members | roles |
|---|---|
|<b>gcp-data-analysts</b><br><small><i>group</i></small>|[roles/bigquery.dataViewer](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataViewer) <br>[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/bigquery.metadataViewer](https://cloud.google.com/iam/docs/understanding-roles#bigquery.metadataViewer) <br>[roles/bigquery.user](https://cloud.google.com/iam/docs/understanding-roles#bigquery.user) <br>[roles/datacatalog.tagTemplateViewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.tagTemplateViewer) <br>[roles/datacatalog.viewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.viewer) <br>[roles/storage.objectViewer](https://cloud.google.com/iam/docs/understanding-roles#storage.objectViewer) |
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) <br>[roles/storage.admin](https://cloud.google.com/iam/docs/understanding-roles#storage.admin) |
|<b>SERVICE_IDENTITY_service-networking</b><br><small><i>serviceAccount</i></small>|[roles/servicenetworking.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#servicenetworking.serviceAgent) <code>+</code>|
|<b>dev-data-load-df-0</b><br><small><i>serviceAccount</i></small>|[roles/datacatalog.categoryAdmin](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.categoryAdmin) |
|<b>dev-data-trf-bq-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataOwner](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataOwner) <br>[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) |
|<b>dev-data-trf-df-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataOwner](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataOwner) <br>[roles/storage.objectCreator](https://cloud.google.com/iam/docs/understanding-roles#storage.objectCreator) <br>[roles/storage.objectViewer](https://cloud.google.com/iam/docs/understanding-roles#storage.objectViewer) |

## Project <i>dev-data-dtl-2-0</i>

| members | roles |
|---|---|
|<b>gcp-data-analysts</b><br><small><i>group</i></small>|[roles/bigquery.dataViewer](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataViewer) <br>[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/bigquery.metadataViewer](https://cloud.google.com/iam/docs/understanding-roles#bigquery.metadataViewer) <br>[roles/bigquery.user](https://cloud.google.com/iam/docs/understanding-roles#bigquery.user) <br>[roles/datacatalog.tagTemplateViewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.tagTemplateViewer) <br>[roles/datacatalog.viewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.viewer) <br>[roles/storage.objectViewer](https://cloud.google.com/iam/docs/understanding-roles#storage.objectViewer) |
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) <br>[roles/storage.admin](https://cloud.google.com/iam/docs/understanding-roles#storage.admin) |
|<b>SERVICE_IDENTITY_service-networking</b><br><small><i>serviceAccount</i></small>|[roles/servicenetworking.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#servicenetworking.serviceAgent) <code>+</code>|
|<b>dev-data-load-df-0</b><br><small><i>serviceAccount</i></small>|[roles/datacatalog.categoryAdmin](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.categoryAdmin) |
|<b>dev-data-trf-bq-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataOwner](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataOwner) <br>[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) |
|<b>dev-data-trf-df-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataOwner](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataOwner) <br>[roles/storage.objectCreator](https://cloud.google.com/iam/docs/understanding-roles#storage.objectCreator) <br>[roles/storage.objectViewer](https://cloud.google.com/iam/docs/understanding-roles#storage.objectViewer) |

## Project <i>dev-data-dtl-plg-0</i>

| members | roles |
|---|---|
|<b>gcp-data-analysts</b><br><small><i>group</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) <br>[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/bigquery.metadataViewer](https://cloud.google.com/iam/docs/understanding-roles#bigquery.metadataViewer) <br>[roles/bigquery.user](https://cloud.google.com/iam/docs/understanding-roles#bigquery.user) <br>[roles/datacatalog.tagTemplateViewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.tagTemplateViewer) <br>[roles/datacatalog.viewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.viewer) <br>[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) <br>[roles/storage.admin](https://cloud.google.com/iam/docs/understanding-roles#storage.admin) |
|<b>SERVICE_IDENTITY_service-networking</b><br><small><i>serviceAccount</i></small>|[roles/servicenetworking.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#servicenetworking.serviceAgent) <code>+</code>|

## Project <i>dev-data-lnd-0</i>

| members | roles |
|---|---|
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) <br>[roles/pubsub.editor](https://cloud.google.com/iam/docs/understanding-roles#pubsub.editor) <br>[roles/storage.admin](https://cloud.google.com/iam/docs/understanding-roles#storage.admin) |
|<b>dev-data-lnd-bq-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) |
|<b>dev-data-lnd-cs-0</b><br><small><i>serviceAccount</i></small>|[roles/storage.objectCreator](https://cloud.google.com/iam/docs/understanding-roles#storage.objectCreator) |
|<b>dev-data-lnd-ps-0</b><br><small><i>serviceAccount</i></small>|[roles/pubsub.publisher](https://cloud.google.com/iam/docs/understanding-roles#pubsub.publisher) |
|<b>dev-data-load-df-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.user](https://cloud.google.com/iam/docs/understanding-roles#bigquery.user) <br>[roles/pubsub.subscriber](https://cloud.google.com/iam/docs/understanding-roles#pubsub.subscriber) <br>[roles/storage.admin](https://cloud.google.com/iam/docs/understanding-roles#storage.admin) <br>[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |
|<b>dev-data-orc-cmp-0</b><br><small><i>serviceAccount</i></small>|[roles/pubsub.subscriber](https://cloud.google.com/iam/docs/understanding-roles#pubsub.subscriber) <br>[roles/storage.objectViewer](https://cloud.google.com/iam/docs/understanding-roles#storage.objectViewer) |

## Project <i>dev-data-lod-0</i>

| members | roles |
|---|---|
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/compute.viewer](https://cloud.google.com/iam/docs/understanding-roles#compute.viewer) <br>[roles/dataflow.admin](https://cloud.google.com/iam/docs/understanding-roles#dataflow.admin) <br>[roles/dataflow.developer](https://cloud.google.com/iam/docs/understanding-roles#dataflow.developer) <br>[roles/viewer](https://cloud.google.com/iam/docs/understanding-roles#viewer) |
|<b>SERVICE_IDENTITY_dataflow-service-producer-prod</b><br><small><i>serviceAccount</i></small>|[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |
|<b>SERVICE_IDENTITY_service-networking</b><br><small><i>serviceAccount</i></small>|[roles/servicenetworking.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#servicenetworking.serviceAgent) <code>+</code>|
|<b>dev-data-load-df-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/dataflow.admin](https://cloud.google.com/iam/docs/understanding-roles#dataflow.admin) <br>[roles/dataflow.worker](https://cloud.google.com/iam/docs/understanding-roles#dataflow.worker) <br>[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |
|<b>dev-data-orc-cmp-0</b><br><small><i>serviceAccount</i></small>|[roles/dataflow.admin](https://cloud.google.com/iam/docs/understanding-roles#dataflow.admin) |

## Project <i>dev-data-orc-0</i>

| members | roles |
|---|---|
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) <br>[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/cloudbuild.builds.editor](https://cloud.google.com/iam/docs/understanding-roles#cloudbuild.builds.editor) <br>[roles/composer.admin](https://cloud.google.com/iam/docs/understanding-roles#composer.admin) <br>[roles/composer.environmentAndStorageObjectAdmin](https://cloud.google.com/iam/docs/understanding-roles#composer.environmentAndStorageObjectAdmin) <br>[roles/iam.serviceAccountUser](https://cloud.google.com/iam/docs/understanding-roles#iam.serviceAccountUser) <br>[roles/iap.httpsResourceAccessor](https://cloud.google.com/iam/docs/understanding-roles#iap.httpsResourceAccessor) <br>[roles/storage.admin](https://cloud.google.com/iam/docs/understanding-roles#storage.admin) <br>[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |
|<b>SERVICE_IDENTITY_cloudcomposer-accounts</b><br><small><i>serviceAccount</i></small>|[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |
|<b>SERVICE_IDENTITY_service-networking</b><br><small><i>serviceAccount</i></small>|[roles/servicenetworking.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#servicenetworking.serviceAgent) <code>+</code>|
|<b>dev-data-load-df-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) <br>[roles/storage.objectViewer](https://cloud.google.com/iam/docs/understanding-roles#storage.objectViewer) |
|<b>dev-data-orc-cmp-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/composer.worker](https://cloud.google.com/iam/docs/understanding-roles#composer.worker) <br>[roles/iam.serviceAccountUser](https://cloud.google.com/iam/docs/understanding-roles#iam.serviceAccountUser) <br>[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |
|<b>dev-data-trf-df-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) |

## Project <i>dev-data-trf-0</i>

| members | roles |
|---|---|
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/dataflow.admin](https://cloud.google.com/iam/docs/understanding-roles#dataflow.admin) |
|<b>SERVICE_IDENTITY_dataflow-service-producer-prod</b><br><small><i>serviceAccount</i></small>|[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |
|<b>SERVICE_IDENTITY_service-networking</b><br><small><i>serviceAccount</i></small>|[roles/servicenetworking.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#servicenetworking.serviceAgent) <code>+</code>|
|<b>dev-data-orc-cmp-0</b><br><small><i>serviceAccount</i></small>|[roles/dataflow.admin](https://cloud.google.com/iam/docs/understanding-roles#dataflow.admin) |
|<b>dev-data-trf-bq-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) |
|<b>dev-data-trf-df-0</b><br><small><i>serviceAccount</i></small>|[roles/dataflow.worker](https://cloud.google.com/iam/docs/understanding-roles#dataflow.worker) <br>[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |

## Project <i>dev-net-spoke-0</i>

| members | roles |
|---|---|
|<b>PROJECT_CLOUD_SERVICES</b><br><small><i>serviceAccount</i></small>|[roles/compute.networkUser](https://cloud.google.com/iam/docs/understanding-roles#compute.networkUser) <code>+</code>|
|<b>SERVICE_IDENTITY_cloudcomposer-accounts</b><br><small><i>serviceAccount</i></small>|[roles/composer.sharedVpcAgent](https://cloud.google.com/iam/docs/understanding-roles#composer.sharedVpcAgent) <code>+</code>|
|<b>SERVICE_IDENTITY_container-engine-robot</b><br><small><i>serviceAccount</i></small>|[roles/compute.networkUser](https://cloud.google.com/iam/docs/understanding-roles#compute.networkUser) <code>+</code><br>[roles/container.hostServiceAgentUser](https://cloud.google.com/iam/docs/understanding-roles#container.hostServiceAgentUser) <code>+</code>|
|<b>SERVICE_IDENTITY_dataflow-service-producer-prod</b><br><small><i>serviceAccount</i></small>|[roles/compute.networkUser](https://cloud.google.com/iam/docs/understanding-roles#compute.networkUser) <code>+</code><br>[roles/compute.networkUser](https://cloud.google.com/iam/docs/understanding-roles#compute.networkUser) <code>+</code><br>[roles/compute.networkUser](https://cloud.google.com/iam/docs/understanding-roles#compute.networkUser) <code>+</code><br>[roles/container.hostServiceAgentUser](https://cloud.google.com/iam/docs/understanding-roles#container.hostServiceAgentUser) <code>+</code>|
|<b>dev-data-load-df-0</b><br><small><i>serviceAccount</i></small>|[roles/compute.networkUser](https://cloud.google.com/iam/docs/understanding-roles#compute.networkUser) <code>+</code>|
|<b>dev-data-trf-df-0</b><br><small><i>serviceAccount</i></small>|[roles/compute.networkUser](https://cloud.google.com/iam/docs/understanding-roles#compute.networkUser) <code>+</code>|
