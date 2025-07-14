# Work Log

## Issues

### Two-stage IAM

Project creation and a bunch of other stuff needs permissions on our IaC service accounts, so we can't refer to these service accounts in IAM.

## Design Notes

### Push factory/context support to modules?

Should the project and folder modules support receiving raw data from YAML and expanding context? This would make each module owner of their own parsing/interpolation/schema, and remove a lot of complexity from the project factory.

(ludo) in favour of this approach

### Interpolation Approach

(ludo)

We can not build a single interpolation namespace, as we must be careful about which values are used where: certain values in specific places will trigger a cycle. What we should do is provide different "flat" interpolation namespaces depending on context (principals, roles, tags, etc.).

Instead of this

```yaml
iam_by_principals:
  ${context.iam_principals.billing_admins}:
    - roles/billing.admin
    - ${context.iam_roles.my_custom_role}:
```

users should assume that all principals (manually passed in + derived at runtime) are available as values in `iam`, keys in `iam_principals`, etc. An initial table of which contexts are available where is at the bottom of this doc, and we will need to document it well and provide examples.

```yaml
iam_by_principals:
  $billing_admins:
    - roles/billing.admin
    - $my_custom_role
```

Not using `templatestring` has the added benefit of preventig users from using dynamic code in templates, which would eventually break in all kinds of interesting ways. This would for example be possible in our original plan:

```yaml
contacts:
  foo:
    - ${replace(context.emails.org_admins, "@example.com", "@example.org")}
```

### Interpolation Table

| object.attribute          | examples                                   | manual context    | dynamic context                     |
| :------------------------ | :----------------------------------------- | :---------------- | :---------------------------------- |
| organization.id           | `$organization_id`                         | `organization.id` |                                     |
| organization.contacts.foo | `$org_admins`                              | `email_addresses` |                                     |
| \*.iam\* (role)           | `$my_role`                                 | `custom_roles`    | `organization.custom_roles`         |
| \*.iam\* (principals)     | `$principals.org_admins`                   | `principals`      |                                     |
|                           | `$projects.foo.service_accounts.bar`       |                   | project service accounts            |
|                           | `$service_accounts.bar` (short form)       |                   | project service accounts            |
|                           | `$projects.foo.service_accounts.iac.rw`    |                   | project automation service accounts |
|                           | `$service_accounts.iac.rw` (short form)    |                   | project automation service accounts |
|                           | `$projects.foo.service_agents.compute`     |                   | project service agents              |
|                           | `$service_agents.foo.compute` (short form) |                   | project service agents              |
| [any project id]          | `$project_ids.foo`                         | `project_ids`     | project ids                         |
| [any location or region]  | `$locations.bigquery`                      | `locations`       |                                     |
