# IP ranges for network stages

**authors:** [Ludo](https://github.com/ludoo), [Roberto](https://github.com/drebes), [Julio](https://github.com/jccb) \
**date:** Sept 20, 2023

## Status

Implemented

## Context

Adding or changing subnets to networking stages is a mistake-prone process because there is no clear IP plan. The problem was made worse when we began supporting GKE, which requires secondary ranges and a large number of IP addresses for pods and services.

This was not an issue when there were only a few networking stages, but as FAST expands, it becomes more difficult to keep track of IP ranges for different regions and environments.

## Decision

We adopted an IP plan based on regions and environments with the following key points:
- Large ranges for the 3 environments we have out of the box (landing, dev, prod)
- Support for 2 regions
- Leave enough space to easily grow either the number of environments or regions
- Allocate large blocks from the CG-NAT range to use as secondary ranges, primarily for GKE pods and services.

The following table summarizes the agreed IP plan:

|                            |     aggregate |                                                            landing |           dev |          prod |
|----------------------------|--------------:|-------------------------------------------------------------------:|--------------:|--------------:|
| Region 1, primary ranges   |  10.64.0.0/12 | 10.64.0.0/16<br>Trusted: 10.64.0.0/17<br>Untrusted: 10.64.128.0/17 |  10.68.0.0/16 |  10.72.0.0/16 |
| Region 2, primary ranges   |  10.80.0.0/12 | 10.80.0.0/16<br>Trusted: 10.80.0.0/17<br>Untrusted: 10.80.128.0/17 |  10.84.0.0/16 |  10.88.0.0/16 |
| Region 1, secondary ranges | 100.64.0.0/12 |                                                      100.64.0.0/14 | 100.68.0.0/14 | 100.72.0.0/14 |
| Region 2, secondary ranges | 100.80.0.0/12 |                                                      100.80.0.0/14 | 100.84.0.0/16 | 100.88.0.0/14 |

To allocate additional secondary ranges for GKE clusters:
- For the pods range, use the next available /16 in the secondary range of its region/environment pair.
- For the service range, use the next available /24 in the last /16 of its region/environment pair.

## Consequences

Default subnets for networking stages were updated to reflect to new ranges.
