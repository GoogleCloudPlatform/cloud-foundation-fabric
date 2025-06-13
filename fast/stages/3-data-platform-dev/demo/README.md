# Data Product Reference example

This folder is intended to create a simple reference Data Product example. The example is intended to be used to understand and test a Data Product life cycle.

This stage is intended to be deployed using the automation Service Account created by the previous stage for the Data Product.

The Data Product example will cover a Batch Cloud Storage to Bigquery data product:

<p align="center">
  <img src="diagram.png" alt="High level diagram.">
</p>

The data product example comes with:

- Terraform file to deploy GCP resources in the Data Product Project
- Simple CSV files to import, tranform and expose
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
