# None

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- ⁺**name**: *string*
- **agent_model**: *string*
- **evaluator_model**: *string*
- **tmpdir**: *object*
  <br>*additional properties: false*
  - **link_paths**: *array*
    - items: *string*
- **timeout**: *integer*
  <br>*default: 60*
- **env**: *array*
  - items: *string*
- **steps**: *array*
  - items: *object*
    <br>*additional properties: false*
    - ⁺**user_input**: *string*
    - ⁺**expected_outcome**: *string*
- **persona**: *object*
  <br>*additional properties: false*
  - **initial_user_input**: *string*
  - ⁺**context**: *string*
  - **max_turns**: *integer*
    <br>*default: 10*
  - ⁺**success_criteria**: *object*
    <br>*additional properties: false*
    - **llm_checks**: *array*
      - items: *string*
    - **flow_contains**: *array*
      - items: *string*
    - **files_exist**: *array*
      - items: *string*
    - **files_contain**: *object*
      - **`.*`**: *array*
        - items: *string*
    - **tool_calls_contain**: *object*
      - **`.*`**: *array*
        - items: *string*

## Definitions
