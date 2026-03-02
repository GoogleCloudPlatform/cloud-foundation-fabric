---
trigger: always_on
---

# Modules as containers of resources and sub-resources

Modules are designed to be containers for all aspects related to uage of a resource type. The pattern is a module is focused on a specific resource (e.g. folder, project, vpc, etc.) and implements all the functionality needed to create/manage that resources so that it is ready for user consumption. This includes: IAM, sub resources (eg subnets and routes for a network), org policies where applicable, etc.

Unrelated resources like a dataset for a project should never be part of the same module, except in the two "aggregation modules" (project and vpc factory) where that makes sense to allow consumers to create baseline infrastructure ready to receive application-level resources.

Never, ever break this boundary as a first approach, and always, always check in with the user if this looks like the only plan of action, as the criteria and constraints that led to the plan might need to be revised instead.