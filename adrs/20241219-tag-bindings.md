# Using `map(string)` for `tag_bindings` variables

**authors:** [Julio](https://github.com/juliocc)
**date:** Dec 19, 2024

## Status

Accepted and implemented.

## Context

We need to define a variable to manage tag bindings in our Terraform modules. This variable will be used across various modules and within the FAST framework to attach tags to resources via the `google_tags_tag_binding` resource.  This variable needs to support both statically defined tags and tags that are dynamically generated during the apply phase of Terraform.

## Decision:

We will use the `map(string)` type for the `tag_bindings` variable across all modules where it's needed. 

## Consequences

Minimal. This is already an established practice across the repository.

Note that the keys of the map are ignored by our code and only used to bypass Terraform limitations with dynamic values in a `for_each` argument.  See [Using Expressions in for_each](https://developer.hashicorp.com/terraform/language/meta-arguments/for_each#using-expressions-in-for_each) in Terraform's documentation for more details.

## Reasoning

The primary reason for choosing `map(string)` is to enable the use of dynamic tags without encountering Terraform errors related to dynamic values.  By using a map, we avoid the limitations imposed by lists or sets and ensure that our modules and FAST can handle both static and dynamic tag values.

## Alternatives Considered:

- `list(string)`: Lists would enforce a fixed number of tags defined at plan time, limiting flexibility and hindering the management of dynamic tags.
- `set(string)`: Similar to lists, sets would require all tag values to be known at plan time, which is not suitable for scenarios with dynamic tag generation.

## Implementation:

At the time of writing this ADR, all modules and FAST stages already use `map(string)`. The purpose of this ADR is to document an existing practice.
