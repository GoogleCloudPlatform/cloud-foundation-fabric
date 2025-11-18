# InternalRange

<!-- markdownlint-disable MD036 -->

## Properties

*additional properties: false*

- **name**: *string*
- **description**: *string*
- **labels**: *object*
  <br>*additional properties: string*
- **ip_cidr_range**: *string*
- ⁺**usage**: *string*
  <br>*enum: ['FOR_VPC', 'EXTERNAL_TO_VPC', 'FOR_MIGRATION']*
- ⁺**peering**: *string*
  <br>*enum: ['FOR_SELF', 'FOR_PEER', 'NOT_SHARED']*
- **prefix_length**: *integer*
- **target_cidr_range**: *array*
  - items: *string*
- **exclude_cidr_ranges**: *array*
  - items: *string*
- **allocation_options**: *object*
  <br>*additional properties: false*
  - **allocation_strategy**: *string*
    <br>*enum: ['RANDOM', 'FIRST_AVAILABLE', 'RANDOM_FIRST_N_AVAILABLE', 'FIRST_SMALLEST_FITTING']*
  - **first_available_ranges_lookup_size**: *integer*
- **overlaps**: *array*
  - items: *string*
    <br>*enum: ['OVERLAP_ROUTE_RANGE', 'OVERLAP_EXISTING_SUBNET_RANGE']*
- **migration**: *object*
  <br>*additional properties: false*
  - ⁺**source**: *string*
  - ⁺**target**: *string*
- **immutable**: *boolean*

## Definitions


