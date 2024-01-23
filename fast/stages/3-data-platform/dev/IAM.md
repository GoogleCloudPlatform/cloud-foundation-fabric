# IAM bindings reference

Legend: <code>+</code> additive, <code>•</code> conditional.

## Project <i>cmn</i>

| members | roles |
|---|---|
|<b>gcp-data-analysts</b><br><small><i>group</i></small>|[roles/datacatalog.viewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.viewer) |
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/dlp.estimatesAdmin](https://cloud.google.com/iam/docs/understanding-roles#dlp.estimatesAdmin) <br>[roles/dlp.reader](https://cloud.google.com/iam/docs/understanding-roles#dlp.reader) <br>[roles/dlp.user](https://cloud.google.com/iam/docs/understanding-roles#dlp.user) |
|<b>gcp-data-security</b><br><small><i>group</i></small>|[roles/datacatalog.admin](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.admin) <br>[roles/dlp.admin](https://cloud.google.com/iam/docs/understanding-roles#dlp.admin) |
|<b>load-df</b><br><small><i>serviceAccount</i></small>|[roles/datacatalog.viewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.viewer) <br>[roles/dlp.user](https://cloud.google.com/iam/docs/understanding-roles#dlp.user) |
|<b>trf-bq</b><br><small><i>serviceAccount</i></small>|[roles/datacatalog.categoryFineGrainedReader](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.categoryFineGrainedReader) <br>[roles/datacatalog.viewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.viewer) |
|<b>trf-df</b><br><small><i>serviceAccount</i></small>|[roles/datacatalog.categoryFineGrainedReader](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.categoryFineGrainedReader) <br>[roles/datacatalog.viewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.viewer) <br>[roles/dlp.user](https://cloud.google.com/iam/docs/understanding-roles#dlp.user) |

## Project <i>drp</i>

| members | roles |
|---|---|
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) <br>[roles/bigquery.user](https://cloud.google.com/iam/docs/understanding-roles#bigquery.user) |
|<b>drp-bq</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) |
|<b>drp-cs</b><br><small><i>serviceAccount</i></small>|[roles/storage.objectCreator](https://cloud.google.com/iam/docs/understanding-roles#storage.objectCreator) |
|<b>drp-ps</b><br><small><i>serviceAccount</i></small>|[roles/pubsub.publisher](https://cloud.google.com/iam/docs/understanding-roles#pubsub.publisher) |
|<b>load-df</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.user](https://cloud.google.com/iam/docs/understanding-roles#bigquery.user) <br>[roles/pubsub.subscriber](https://cloud.google.com/iam/docs/understanding-roles#pubsub.subscriber) <br>[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |
|<b>orc-cmp</b><br><small><i>serviceAccount</i></small>|[roles/pubsub.subscriber](https://cloud.google.com/iam/docs/understanding-roles#pubsub.subscriber) <br>[roles/storage.objectViewer](https://cloud.google.com/iam/docs/understanding-roles#storage.objectViewer) |

## Project <i>dwh-conf</i>

| members | roles |
|---|---|
|<b>gcp-data-analysts</b><br><small><i>group</i></small>|[roles/bigquery.dataViewer](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataViewer) <br>[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/datacatalog.tagTemplateViewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.tagTemplateViewer) <br>[roles/datacatalog.viewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.viewer) <br>[roles/storage.objectViewer](https://cloud.google.com/iam/docs/understanding-roles#storage.objectViewer) |
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/bigquery.dataViewer](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataViewer) <br>[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/datacatalog.tagTemplateViewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.tagTemplateViewer) <br>[roles/datacatalog.viewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.viewer) <br>[roles/storage.objectViewer](https://cloud.google.com/iam/docs/understanding-roles#storage.objectViewer) |
|<b>SERVICE_IDENTITY_service-networking</b><br><small><i>serviceAccount</i></small>|[roles/servicenetworking.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#servicenetworking.serviceAgent) <code>+</code>|
|<b>trf-bq</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataOwner](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataOwner) <br>[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) |
|<b>trf-df</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataOwner](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataOwner) <br>[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |

## Project <i>dwh-cur</i>

| members | roles |
|---|---|
|<b>gcp-data-analysts</b><br><small><i>group</i></small>|[roles/bigquery.dataViewer](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataViewer) <br>[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/datacatalog.tagTemplateViewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.tagTemplateViewer) <br>[roles/datacatalog.viewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.viewer) <br>[roles/storage.objectViewer](https://cloud.google.com/iam/docs/understanding-roles#storage.objectViewer) |
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/bigquery.dataViewer](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataViewer) <br>[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/datacatalog.tagTemplateViewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.tagTemplateViewer) <br>[roles/datacatalog.viewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.viewer) <br>[roles/storage.objectViewer](https://cloud.google.com/iam/docs/understanding-roles#storage.objectViewer) |
|<b>SERVICE_IDENTITY_service-networking</b><br><small><i>serviceAccount</i></small>|[roles/servicenetworking.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#servicenetworking.serviceAgent) <code>+</code>|
|<b>trf-bq</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataOwner](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataOwner) <br>[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) |
|<b>trf-df</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataOwner](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataOwner) <br>[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |

## Project <i>dwh-lnd</i>

| members | roles |
|---|---|
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/bigquery.dataViewer](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataViewer) <br>[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/datacatalog.tagTemplateViewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.tagTemplateViewer) <br>[roles/datacatalog.viewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.viewer) <br>[roles/storage.objectViewer](https://cloud.google.com/iam/docs/understanding-roles#storage.objectViewer) |
|<b>SERVICE_IDENTITY_service-networking</b><br><small><i>serviceAccount</i></small>|[roles/servicenetworking.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#servicenetworking.serviceAgent) <code>+</code>|
|<b>load-df</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataOwner](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataOwner) <br>[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/storage.objectCreator](https://cloud.google.com/iam/docs/understanding-roles#storage.objectCreator) |
|<b>trf-bq</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataViewer](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataViewer) <br>[roles/datacatalog.categoryAdmin](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.categoryAdmin) |
|<b>trf-df</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataViewer](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataViewer) |

## Project <i>lod</i>

| members | roles |
|---|---|
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/dataflow.admin](https://cloud.google.com/iam/docs/understanding-roles#dataflow.admin) <br>[roles/dataflow.developer](https://cloud.google.com/iam/docs/understanding-roles#dataflow.developer) |
|<b>SERVICE_IDENTITY_dataflow-service-producer-prod</b><br><small><i>serviceAccount</i></small>|[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |
|<b>SERVICE_IDENTITY_service-networking</b><br><small><i>serviceAccount</i></small>|[roles/servicenetworking.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#servicenetworking.serviceAgent) <code>+</code>|
|<b>load-df</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/dataflow.admin](https://cloud.google.com/iam/docs/understanding-roles#dataflow.admin) <br>[roles/dataflow.worker](https://cloud.google.com/iam/docs/understanding-roles#dataflow.worker) <br>[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |
|<b>orc-cmp</b><br><small><i>serviceAccount</i></small>|[roles/dataflow.admin](https://cloud.google.com/iam/docs/understanding-roles#dataflow.admin) |

## Project <i>orc</i>

| members | roles |
|---|---|
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/artifactregistry.admin](https://cloud.google.com/iam/docs/understanding-roles#artifactregistry.admin) <br>[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) <br>[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/cloudbuild.builds.editor](https://cloud.google.com/iam/docs/understanding-roles#cloudbuild.builds.editor) <br>[roles/composer.admin](https://cloud.google.com/iam/docs/understanding-roles#composer.admin) <br>[roles/composer.environmentAndStorageObjectAdmin](https://cloud.google.com/iam/docs/understanding-roles#composer.environmentAndStorageObjectAdmin) <br>[roles/composer.user](https://cloud.google.com/iam/docs/understanding-roles#composer.user) <br>[roles/iam.serviceAccountUser](https://cloud.google.com/iam/docs/understanding-roles#iam.serviceAccountUser) <br>[roles/iap.httpsResourceAccessor](https://cloud.google.com/iam/docs/understanding-roles#iap.httpsResourceAccessor) <br>[roles/serviceusage.serviceUsageConsumer](https://cloud.google.com/iam/docs/understanding-roles#serviceusage.serviceUsageConsumer) <br>[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |
|<b>SERVICE_IDENTITY_cloudcomposer-accounts</b><br><small><i>serviceAccount</i></small>|[roles/composer.ServiceAgentV2Ext](https://cloud.google.com/iam/docs/understanding-roles#composer.ServiceAgentV2Ext) <br>[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |
|<b>SERVICE_IDENTITY_gcp-sa-cloudbuild</b><br><small><i>serviceAccount</i></small>|[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |
|<b>SERVICE_IDENTITY_service-networking</b><br><small><i>serviceAccount</i></small>|[roles/servicenetworking.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#servicenetworking.serviceAgent) <code>+</code>|
|<b>load-df</b><br><small><i>serviceAccount</i></small>|[roles/artifactregistry.reader](https://cloud.google.com/iam/docs/understanding-roles#artifactregistry.reader) <br>[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) <br>[roles/storage.objectViewer](https://cloud.google.com/iam/docs/understanding-roles#storage.objectViewer) |
|<b>orc-cmp</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/composer.worker](https://cloud.google.com/iam/docs/understanding-roles#composer.worker) <br>[roles/iam.serviceAccountUser](https://cloud.google.com/iam/docs/understanding-roles#iam.serviceAccountUser) <br>[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |
|<b>orc-sa-df-build</b><br><small><i>serviceAccount</i></small>|[roles/cloudbuild.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#cloudbuild.serviceAgent) <br>[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |
|<b>trf-df</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) |

## Project <i>trf</i>

| members | roles |
|---|---|
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/dataflow.admin](https://cloud.google.com/iam/docs/understanding-roles#dataflow.admin) |
|<b>SERVICE_IDENTITY_dataflow-service-producer-prod</b><br><small><i>serviceAccount</i></small>|[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |
|<b>SERVICE_IDENTITY_service-networking</b><br><small><i>serviceAccount</i></small>|[roles/servicenetworking.serviceAgent](https://cloud.google.com/iam/docs/understanding-roles#servicenetworking.serviceAgent) <code>+</code>|
|<b>orc-cmp</b><br><small><i>serviceAccount</i></small>|[roles/dataflow.admin](https://cloud.google.com/iam/docs/understanding-roles#dataflow.admin) |
|<b>trf-bq</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) |
|<b>trf-df</b><br><small><i>serviceAccount</i></small>|[roles/dataflow.worker](https://cloud.google.com/iam/docs/understanding-roles#dataflow.worker) <br>[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |
