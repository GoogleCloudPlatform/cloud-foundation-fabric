# FAST multitenant stages

The stages in this folder set up separate resource hierarchies inside the same organization that are fully FAST-compliant, and allow each tenant to run and manage their own networking, security, or application-level stages. They are designed to be used where a high degree of autonomy is needed for each tenant, for example individual subsidiaries of a large corporation all sharing the same GCP organization.

The multitenant stages have the following characteristics:

- they support one tenant at a time, so one copy of both stages is needed for each tenant
- they have the organization-level bootstrap and resource management stages as prerequisite
- they are logically equivalent to the respective organization-level stages but behave slightly differently, as they actively minimize access and changes to organization or shared resources

Once both tenant-level stages are run, a hierarchy and a set of resources is available for the new tenant, including a separate automation project, service accounts for subsequent stages, etc.

## Tenant bootstrap (0)

This stage creates the top-level root folder, tag, automation project, automation service accounts, and optionally sets up CI/CD for itself and the tenant resource management stage. It also sets up billing and organization-level roles for the tenant administrators group and the automation service accounts. The organization-level resource management service account is used to run it.

## Tenant resource management (1)

This stage populates the resource hierarchy for the tenant rooted in the dedicated top-level folder, assigns roles to the tenant automation service accounts, and optionally sets up CI/CD for the following stages. It is functionally equivalent to the organization-level resource management stage, and runs with a tenant-specific service account.
