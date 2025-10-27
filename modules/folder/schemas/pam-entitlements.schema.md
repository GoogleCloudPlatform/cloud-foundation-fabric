# None

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **`^[a-z][a-z0-9-]{0,61}[a-z0-9]$`**: *object*
  <br>*additional properties: false*
  - ⁺**max_request_duration**: *string*
  - ⁺**eligible_users**: *array*
    - items: *string*
  - ⁺**privileged_access**: *array*
    - items: *object*
      <br>*additional properties: false*
      - ⁺**role**: *string*
      - **condition**: *string*
  - **requester_justification_config**: *object*
    <br>*additional properties: false*
    - **not_mandatory**: *boolean*
    - **unstructured**: *boolean*
  - **manual_approvals**: *object*
    <br>*additional properties: false*
    - ⁺**require_approver_justification**: *boolean*
    - ⁺**steps**: *array*
      - items: *object*
        <br>*additional properties: false*
        - ⁺**approvers**: *array*
          - items: *string*
        - **approvals_needed**: *number*
        - **approver_email_recipients**: *array*
          - items: *string*
  - **additional_notification_targets**: *object*
    <br>*additional properties: false*
    - **admin_email_recipients**: *array*
      - items: *string*
    - **requester_email_recipients**: *array*
      - items: *string*

## Definitions


