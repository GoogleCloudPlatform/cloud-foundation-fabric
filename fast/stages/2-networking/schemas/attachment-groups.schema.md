# Attachment Groups schema

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **name**: *string*
- **project_id**: *string*
- **description**: *string*
- **intent**: *object*
  <br>*additional properties: false*
  - **availability_sla**: *string*
    <br>*default: NO_SLA*, *enum: ['NO_SLA', 'PRODUCTION_NON_CRITICAL', 'PRODUCTION_CRITICAL', 'AVAILABILITY_SLA_UNSPECIFIED']*
- **attachments**: *object*
  <br>*additional properties: false*
  - **`^[a-zA-Z0-9-_]+$`**: *object*
    <br>*additional properties: false*
    - ⁺**name**: *string*
    - **attachment**: *string*

## Definitions


