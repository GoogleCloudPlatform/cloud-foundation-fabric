# Data Product Reference example

This folder is intended to create a simple reference Data Product example. The example is intended to be used to understand and test a Data Product life cycle.

This stage is intended to be deployed using the automation Service Account created by the previous stage for the Data Product.

The Data Product example will cover a Batch Cloud Storage to Bigquery data product:

<p align="center">
  <img src="diagram.png" alt="High level diagram.">
</p>

The data product example comes with:

- Terraform file to deploy GCP resources in the Data Product Project
- Simple CSV files to import, transform and expose
- Cloud Composer DAGs to create needed tables and perform the ELT pipeline on sample data

## Running the demo

Run the terraform script using the automation service account created for the data product by the previous stage:

```bash
terraform init
terraform apply
```

Copy sample data in the landing folder just created:

```bash
gsutil cp -r data/* gs://LANDING_BUCKET/
```

Copy sample Airflow DAGs in the composer DAG GCS bucket:

```bash
gsutil cp -r composer/DAG-dp0/* gs://COMPOSER_DAG_BUCKET/dag/DAG-dp0/
```

Customize as needed the `composer/variables` file and import into Airflow from the UI.

From the composer UI run the DAG to create

<!-- TFDOC OPTS files:1 show_extra:1 exclude:providers.tf -->
<!-- BEGIN TFDOC -->
## Files

| name | description | modules |
|---|---|---|
| [main.tf](./main.tf) | Module-level locals and resources. | <code>bigquery-dataset</code> · <code>gcs</code> |
| [variables.tf](./variables.tf) | Module variables. |  |

## Variables

| name | description | type | required | default | producer |
|---|---|:---:|:---:|:---:|:---:|
| [authorized_dataset_on_curated](variables.tf#L16) | Authorized Dataset. | <code>string</code> | ✓ |  |  |
| [impersonate_service_account](variables.tf#L32) | Service account to impersonate for Google Cloud providers. | <code>string</code> | ✓ |  |  |
| [prefix](variables.tf#L45) | Prefix used for resources that need unique names. Use a maximum of 9 chars for organizations, and 11 chars for tenants. | <code>string</code> | ✓ |  |  |
| [project_id](variables.tf#L54) | Project ID to deploy resources. | <code>string</code> | ✓ |  |  |
| [encryption_keys](variables.tf#L21) | Default encryption keys for services, in service => { region => key id } format. Overridable on a per-object basis. | <code title="object&#40;&#123;&#10;  bigquery &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  composer &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;  storage  &#61; optional&#40;map&#40;string&#41;, &#123;&#125;&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>&#123;&#125;</code> |  |
| [location](variables.tf#L38) | Default location used when no location is specified. | <code>string</code> |  | <code>&#34;europe-west8&#34;</code> |  |
<!-- END TFDOC -->
