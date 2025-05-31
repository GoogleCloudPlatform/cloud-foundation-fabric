# Organization Policies

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **`^[a-z-]+[a-zA-Z0-9\.]+$`**: *object*
  <br>*additional properties: false*
  - **inherit_from_parent**: *boolean*
  - **reset**: *boolean*
  - **rules**: *array*
    - items: *object*
      <br>*additional properties: false*
      - **allow**: *reference([allow-deny](#refs-allow-deny))*
      - **deny**: *reference([allow-deny](#refs-allow-deny))*
      - **enforce**: *boolean*
      - **condition**: *object*
        <br>*additional properties: false*
        - **description**: *string*
          <br>*pattern: None*
        - **expression**: *string*
          <br>*pattern: None*
        - **location**: *string*
          <br>*pattern: None*
        - **title**: *string*
          <br>*pattern: None*
      - **parameters**: *string*
        <br>*pattern: None*

## Definitions

- **allow-deny**<a name="refs-allow-deny"></a>: *object*
  <br>*additional properties: false*
  - **all**: *boolean*
  - **values**: *array*
    - items: *string*
      <br>*pattern: None*
