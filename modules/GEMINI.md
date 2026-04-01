# Module testing notes

## Generating test inventory files

1. Specify `inventory=filename.yaml` in the `tftest` annotation in `README.md`.
2. Create the empty inventory file in `tests/modules/<module_name>/examples/` (note the underscore in module name, e.g., `compute_vm`).
3. Place the standard copyright blurb at the top.
4. Add `counts: { foo: 1 }` to the inventory file.
5. Run the specific test using `pytest "tests/examples/test_plan.py::test_example[terraform:modules/<module-name>:Heading Name:Index]"`.
6. Use the test failure output to replace `counts` with the actual resource types and counts.
7. Add `values: { foo: 1 }` to the inventory file and run the test again.
8. Use the output to replace `values` with the actual mapped attributes. Remove unnecessary or overly verbose keys like large instance configurations, and use `{}` for resources where specific values don't need validation.