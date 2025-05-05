# Organization Policies

<!-- markdownlint-disable MD036 -->

## Properties

*no additional properties allowed*

- **`^[a-z-]+[a-zA-Z0-9\.]+$`**: *object*
  <br>*no additional properties allowed*
  - **inherit_from_parent**: *boolean*
  - **reset**: *boolean*
  - **rules**: *array*
    - items: *object*
      <br>*no additional properties allowed*
      - **allow**: *reference([allow-deny](#refs-allow-deny))*
      - **deny**: *reference([allow-deny](#refs-allow-deny))*
      - **enforce**: *boolean*
      - **condition**: *object*
        <br>*no additional properties allowed*
        - **description**: *string*
        - **expression**: *string*
        - **location**: *string*
        - **title**: *string*
      - **parameters**: *string*

## Definitions

- **allow-deny**<a name="refs-allow-deny"></a>: *object*
  <br>*no additional properties allowed*
  - **all**: *boolean*
  - **values**: *array*
    - items: *string*