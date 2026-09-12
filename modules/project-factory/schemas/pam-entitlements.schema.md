# PAM Entitlements

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **`^[a-z0-9-]+$`**: *object*
  <br>*additional properties: false*
  - ⁺**max_request_duration**: *string*
  - ⁺**eligible_users**: *array*
    - items: *string*
      <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|\$iam_principals:[a-z0-9_-]+)*
  - ⁺**privileged_access**: *array*
    - items: *object*
      <br>*additional properties: false*
      - ⁺**role**: *string*
        <br>*pattern: ^(?:roles/|\$custom_roles:|organizations/[0-9]+/roles/|([a-z0-9.]+:)?projects/[a-z0-9-]+/roles/)*
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
            <br>*pattern: ^(?:domain:|group:|serviceAccount:|user:|principal:|principalSet:|\$iam_principals:[a-z0-9_-]+)*
        - **approvals_needed**: *number*
          <br>*default: 1*
        - **approver_email_recipients**: *array*
          - items: *string*
            <br>*pattern: ^\S+@\S+\.\S+$*
  - **additional_notification_targets**: *object*
    <br>*additional properties: false*
    - **admin_email_recipients**: *array*
      - items: *string*
        <br>*pattern: ^\S+@\S+\.\S+$*
    - **requester_email_recipients**: *array*
      - items: *string*
        <br>*pattern: ^\S+@\S+\.\S+$*

## Definitions
