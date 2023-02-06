# FAST multitenant stages

The stages in this folder set up separate resource hierarchies inside the same organization that are fully FAST-compliant, and allow each tenant to run and manage their own networking, security, or application-level stages. They are designed to be used where a high degree of autonomy is needed for each tenant, for example individual subsidiaries of a large corporation all sharing the same GCP organization.

The multitenant stages have the following characteristics:

- they support one tenant at a time, so one copy of both stages is needed for each tenant
- they have the organization-level bootstrap and resource management stages as prerequisite
- they are logically equivalent to the respective organization-level stages but behave slightly differently, as they actively minimize access and changes to organization or shared resources

Once both tenant-level stages are run, a hierarchy and a set of resources is available for the new tenant, including a separate automation project, service accounts for subsequent stages, etc.

The tenant-level stages require that organization-level stage 0 (bootstrap) and 1 (resource management) have been applied. Their position and role in the FAST stage flow is shown in the following diagram:

<p align="center">
  <img src="stages.svg" alt="Stages diagram">
</p>

## Tenant bootstrap (0)

This stage creates the top-level root folder and tag for the tenant, and the tenant-level automation project and automation service accounts. It also sets up billing and organization-level roles for the tenant administrators group and the automation service accounts. As in the organizational-level stages, it can optionally set up CI/CD for itself and the tenant resource management stage.

This stage is run with the organization-level resource management service account as it leverages its permissions, and is the bridge between the organization-level stages and the tenant stages which are effectively decoupled from the rest of the organization.

## Tenant resource management (1)

This stage populates the resource hierarchy rooted in the top-level tenant folder, assigns roles to the tenant automation service accounts, and optionally sets up CI/CD for the following stages. It is functionally equivalent to the organization-level resource management stage, but runs with a tenant-specific service account and has no control over resources outside of the tenant context.
