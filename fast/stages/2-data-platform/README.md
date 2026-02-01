# FAST Data Platform (Stage 2)

This stage sets up the Data Platform environment, including the central project, data domains, and data products.

## Design

### Cloud KMS Encryption Keys (CMEK)

This stage supports three approaches for managing Customer-Managed Encryption Keys (CMEK):

1.  **Inherited Keys (Recommended)**: Keys are managed centrally in the Security Stage (Stage 2) and their resource IDs are passed to this stage via the `kms_keys` variable.
    *   **Configuration**: Keys are referenced in `defaults.yaml` context (e.g., `kms_keys.storage-dev-primary`) and used in project YAMLs via substitution (e.g., `$kms_keys:storage-dev-primary`).
    *   **Setup**: Ensure the Security stage has created the keys and they are correctly passed in `terraform.tfvars`.

2.  **Local Keys (Central Project)**: Keys are created and managed directly within the Central Project of this stage.
    *   **Configuration**: Uncomment and configure the `kms` block in `data/projects/central.yaml` to define keyrings and keys.
    *   **Context**: Update `defaults.yaml` context to point to these new local key IDs (e.g., `projects/${project_ids.central}/locations/...`).

3.  **Autokey**: Use Cloud KMS Autokey for automated key provisioning.
    *   **Configuration**: Uncomment and configure the `kms.autokeys` block in `data/projects/central.yaml`.
    *   **Prerequisites**: Cloud KMS Autokey must be enabled in the folder/organization.
