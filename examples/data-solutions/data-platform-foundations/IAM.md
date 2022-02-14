# IAM bindings reference

Legend: <code>+</code> additive, <code>•</code> conditional.

## Project <i>cmn</i>

| members | roles |
|---|---|
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/dlp.estimatesAdmin](https://cloud.google.com/iam/docs/understanding-roles#dlp.estimatesAdmin) <br>[roles/dlp.reader](https://cloud.google.com/iam/docs/understanding-roles#dlp.reader) <br>[roles/dlp.user](https://cloud.google.com/iam/docs/understanding-roles#dlp.user) |
|<b>gcp-data-security</b><br><small><i>group</i></small>|[roles/dlp.admin](https://cloud.google.com/iam/docs/understanding-roles#dlp.admin) |
|<b>load-df-0</b><br><small><i>serviceAccount</i></small>|[roles/dlp.user](https://cloud.google.com/iam/docs/understanding-roles#dlp.user) |
|<b>trf-df-0</b><br><small><i>serviceAccount</i></small>|[roles/dlp.user](https://cloud.google.com/iam/docs/understanding-roles#dlp.user) |

## Project <i>dtl-0</i>

| members | roles |
|---|---|
|<b>gcp-data-analysts</b><br><small><i>group</i></small>|[roles/bigquery.dataViewer](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataViewer) <br>[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/bigquery.user](https://cloud.google.com/iam/docs/understanding-roles#bigquery.user) <br>[roles/datacatalog.tagTemplateViewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.tagTemplateViewer) <br>[roles/datacatalog.viewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.viewer) <br>[roles/storage.objectViewer](https://cloud.google.com/iam/docs/understanding-roles#storage.objectViewer) |
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) <br>[roles/storage.admin](https://cloud.google.com/iam/docs/understanding-roles#storage.admin) |
|<b>load-df-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/storage.objectCreator](https://cloud.google.com/iam/docs/understanding-roles#storage.objectCreator) |
|<b>trf-bq-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) |
|<b>trf-df-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) |

## Project <i>dtl-1</i>

| members | roles |
|---|---|
|<b>gcp-data-analysts</b><br><small><i>group</i></small>|[roles/bigquery.dataViewer](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataViewer) <br>[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/bigquery.user](https://cloud.google.com/iam/docs/understanding-roles#bigquery.user) <br>[roles/datacatalog.tagTemplateViewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.tagTemplateViewer) <br>[roles/datacatalog.viewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.viewer) <br>[roles/storage.objectViewer](https://cloud.google.com/iam/docs/understanding-roles#storage.objectViewer) |
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) <br>[roles/storage.admin](https://cloud.google.com/iam/docs/understanding-roles#storage.admin) |
|<b>trf-bq-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) <br>[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) |
|<b>trf-df-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) <br>[roles/storage.objectCreator](https://cloud.google.com/iam/docs/understanding-roles#storage.objectCreator) <br>[roles/storage.objectViewer](https://cloud.google.com/iam/docs/understanding-roles#storage.objectViewer) |

## Project <i>dtl-2</i>

| members | roles |
|---|---|
|<b>gcp-data-analysts</b><br><small><i>group</i></small>|[roles/bigquery.dataViewer](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataViewer) <br>[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/bigquery.user](https://cloud.google.com/iam/docs/understanding-roles#bigquery.user) <br>[roles/datacatalog.tagTemplateViewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.tagTemplateViewer) <br>[roles/datacatalog.viewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.viewer) <br>[roles/storage.objectViewer](https://cloud.google.com/iam/docs/understanding-roles#storage.objectViewer) |
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) <br>[roles/storage.admin](https://cloud.google.com/iam/docs/understanding-roles#storage.admin) |
|<b>trf-bq-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) <br>[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) |
|<b>trf-df-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) <br>[roles/storage.objectCreator](https://cloud.google.com/iam/docs/understanding-roles#storage.objectCreator) <br>[roles/storage.objectViewer](https://cloud.google.com/iam/docs/understanding-roles#storage.objectViewer) |

## Project <i>dtl-plg</i>

| members | roles |
|---|---|
|<b>gcp-data-analysts</b><br><small><i>group</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) <br>[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/bigquery.user](https://cloud.google.com/iam/docs/understanding-roles#bigquery.user) <br>[roles/datacatalog.tagTemplateViewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.tagTemplateViewer) <br>[roles/datacatalog.viewer](https://cloud.google.com/iam/docs/understanding-roles#datacatalog.viewer) <br>[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) <br>[roles/storage.admin](https://cloud.google.com/iam/docs/understanding-roles#storage.admin) |

## Project <i>lnd</i>

| members | roles |
|---|---|
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) <br>[roles/pubsub.editor](https://cloud.google.com/iam/docs/understanding-roles#pubsub.editor) <br>[roles/storage.admin](https://cloud.google.com/iam/docs/understanding-roles#storage.admin) |
|<b>lnd-bq-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) |
|<b>lnd-cs-0</b><br><small><i>serviceAccount</i></small>|[roles/storage.objectCreator](https://cloud.google.com/iam/docs/understanding-roles#storage.objectCreator) |
|<b>lnd-ps-0</b><br><small><i>serviceAccount</i></small>|[roles/pubsub.publisher](https://cloud.google.com/iam/docs/understanding-roles#pubsub.publisher) |
|<b>load-df-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.user](https://cloud.google.com/iam/docs/understanding-roles#bigquery.user) <br>[roles/pubsub.subscriber](https://cloud.google.com/iam/docs/understanding-roles#pubsub.subscriber) <br>[roles/storage.admin](https://cloud.google.com/iam/docs/understanding-roles#storage.admin) <br>[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |
|<b>orc-cmp-0</b><br><small><i>serviceAccount</i></small>|[roles/pubsub.subscriber](https://cloud.google.com/iam/docs/understanding-roles#pubsub.subscriber) <br>[roles/storage.objectViewer](https://cloud.google.com/iam/docs/understanding-roles#storage.objectViewer) |

## Project <i>lod</i>

| members | roles |
|---|---|
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/compute.viewer](https://cloud.google.com/iam/docs/understanding-roles#compute.viewer) <br>[roles/dataflow.admin](https://cloud.google.com/iam/docs/understanding-roles#dataflow.admin) <br>[roles/dataflow.developer](https://cloud.google.com/iam/docs/understanding-roles#dataflow.developer) <br>[roles/viewer](https://cloud.google.com/iam/docs/understanding-roles#viewer) |
|<b>load-df-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/dataflow.admin](https://cloud.google.com/iam/docs/understanding-roles#dataflow.admin) <br>[roles/dataflow.worker](https://cloud.google.com/iam/docs/understanding-roles#dataflow.worker) <br>[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |
|<b>orc-cmp-0</b><br><small><i>serviceAccount</i></small>|[roles/dataflow.admin](https://cloud.google.com/iam/docs/understanding-roles#dataflow.admin) |

## Project <i>orc</i>

| members | roles |
|---|---|
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) <br>[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/cloudbuild.builds.editor](https://cloud.google.com/iam/docs/understanding-roles#cloudbuild.builds.editor) <br>[roles/composer.admin](https://cloud.google.com/iam/docs/understanding-roles#composer.admin) <br>[roles/composer.environmentAndStorageObjectAdmin](https://cloud.google.com/iam/docs/understanding-roles#composer.environmentAndStorageObjectAdmin) <br>[roles/compute.networkUser](https://cloud.google.com/iam/docs/understanding-roles#compute.networkUser) <br>[roles/iam.serviceAccountUser](https://cloud.google.com/iam/docs/understanding-roles#iam.serviceAccountUser) <br>[roles/iap.httpsResourceAccessor](https://cloud.google.com/iam/docs/understanding-roles#iap.httpsResourceAccessor) <br>[roles/storage.admin](https://cloud.google.com/iam/docs/understanding-roles#storage.admin) <br>[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |
|<b>load-df-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) <br>[roles/storage.objectViewer](https://cloud.google.com/iam/docs/understanding-roles#storage.objectViewer) |
|<b>orc-cmp-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/composer.worker](https://cloud.google.com/iam/docs/understanding-roles#composer.worker) <br>[roles/iam.serviceAccountUser](https://cloud.google.com/iam/docs/understanding-roles#iam.serviceAccountUser) <br>[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |
|<b>trf-df-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.dataEditor](https://cloud.google.com/iam/docs/understanding-roles#bigquery.dataEditor) |

## Project <i>trf</i>

| members | roles |
|---|---|
|<b>gcp-data-engineers</b><br><small><i>group</i></small>|[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) <br>[roles/dataflow.admin](https://cloud.google.com/iam/docs/understanding-roles#dataflow.admin) |
|<b>orc-cmp-0</b><br><small><i>serviceAccount</i></small>|[roles/dataflow.admin](https://cloud.google.com/iam/docs/understanding-roles#dataflow.admin) |
|<b>trf-bq-0</b><br><small><i>serviceAccount</i></small>|[roles/bigquery.jobUser](https://cloud.google.com/iam/docs/understanding-roles#bigquery.jobUser) |
|<b>trf-df-0</b><br><small><i>serviceAccount</i></small>|[roles/dataflow.worker](https://cloud.google.com/iam/docs/understanding-roles#dataflow.worker) <br>[roles/storage.objectAdmin](https://cloud.google.com/iam/docs/understanding-roles#storage.objectAdmin) |
