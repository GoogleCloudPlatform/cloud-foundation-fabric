# Data Platform Stage Analysis

## 1. Logical Entities

The Data Platform stage (`3-data-platform`) is structured around two primary logical entities:

1.  **Data Domains**: High-level groupings representing business areas or teams.
2.  **Data Products**: Specific data projects or applications within a Data Domain.

## 2. Projects and Resources

### 2.1. Central Resources (Stage Level)
These resources are created at the top level of the stage, typically in a "Central" project.

*   **Project**: `central-project`
*   **Resources**:
    *   **Dataplex Aspect Types**: Centralized definitions for metadata templates (Aspects).
    *   **Data Catalog Policy Tags**: Taxonomy for column-level security.
    *   **Secure Tags**: Resource Manager tags for access control.
    *   **IAM**: Central IAM bindings.

### 2.2. Data Domain Resources
For each Data Domain, the following are created:

*   **Folder**: A dedicated folder for the domain.
*   **Shared Project**: A project (`<domain>-shared-0`) for shared domain resources.
*   **Service Accounts**:
    *   Automation SAs (`iac-ro`, `iac-rw`) for managing domain resources.
    *   Custom Service Accounts defined in config.
    *   Composer Service Account (if Composer is enabled).
*   **Storage**:
    *   Automation state bucket (`<domain>-state`) for Terraform state.
*   **Composer** (Optional): A Cloud Composer environment in the shared project.

### 2.3. Data Product Resources
For each Data Product, the following are created:

*   **Folder**: A "Data Products" folder within the Domain folder (shared for all products in the domain? No, it's a `dd-dp-folders` module, creating ONE "Data Products" folder per domain, to hold product projects). *Correction*: `dd-dp-folders` creates one folder named "Data Products" per Domain, to hold the product projects.
*   **Project**: A dedicated project (`<domain>-<product>-0`).
*   **Service Accounts**:
    *   Automation SAs (`iac-ro`, `iac-rw`) for managing product resources.
    *   Custom Service Accounts defined in config.
*   **Storage**:
    *   Automation state bucket (`<product>-state`).
    *   **Exposure Buckets**: GCS buckets for data exposure (`<product>-<name>-0`).
*   **BigQuery**:
    *   **Exposure Datasets**: BigQuery datasets for data exposure.
*   **Services**: Enabled APIs (BigQuery, GCS, etc.).

## 3. Integration Plan

To migrate this to the Project Factory (`2-project-factory`), we will implement a new **Dataset** strategy.

### 3.1. Project Factory Integration
The Project Factory module needs to be extended to support the specific resources required by the Data Platform that are currently "missing" from the generic factory:

1.  **Aspect Types**: Need a way to define and manage Dataplex Aspect Types, likely via a new factory logic or resource in the central project context.
2.  **Policy Tags**: Support for Data Catalog Policy Tags taxonomies.
3.  **Data Platform Resources (Exposure)**:
    *   BigQuery Datasets (with IAM and Encryption).
    *   GCS Buckets (with IAM and Encryption).
    *   *Note*: The Project Factory already supports some of this, but we need to ensure the *Data Platform* schema (YAML structure) can be mapped or supported.
4.  **Composer**: Support for deploying Composer environments via the factory.

### 3.2. Dataset Structure
The new `datasets/data-platform` will likely contain:
*   YAML files defining the Domains and Products as "Projects" (or groups of projects) for the factory.

## 4. Project Factory Integration Design

To support the Data Platform "Exposure" resources, we need to enhance the Project Factory's capabilities for BigQuery and Cloud Storage.

### 4.1. BigQuery Datasets
*   **Current Capabilities**: The `projects-bigquery.tf` file currently supports minimal configuration: `id`, `friendly_name`, `location`, `encryption_key`.
*   **Gaps**:
    *   **IAM**: No support for dataset-level IAM bindings (crucial for exposure).
    *   **Tag Bindings**: No support for attaching tags (used for "Exposure" tags).
    *   **Options**: No support for dataset options (e.g., default expiration).
*   **Proposed Changes**:
    1.  **Update `projects-bigquery.tf`**:
        *   Extract `iam`, `iam_bindings`, `iam_bindings_additive`, `iam_by_principals` from YAML and pass to `bigquery-datasets` module.
        *   Extract `tag_bindings` and pass to module.
        *   Extract `options` and pass to module.
    2.  **Update `schemas/project.schema.json`**:
        *   Expand the `properties` for `datasets` to include these new fields.

### 4.2. Cloud Storage Buckets
*   **Current Capabilities**: The `projects-buckets.tf` file is robust, supporting IAM, detailed configuration, and lifecycle rules.
*   **Gaps**:
    *   **Tag Bindings**: Missing support for `tag_bindings`.
*   **Proposed Changes**:
    1.  **Update `projects-buckets.tf`**:
        *   Extract `tag_bindings` from YAML and pass to `buckets` module.
    2.  **Update `schemas/project.schema.json`**:
        *   Add `tag_bindings` to the `bucket` definition.

*   Configuration for the extra resources (Aspects, Policy Tags) to be applied.
