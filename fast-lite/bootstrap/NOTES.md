# Notes

## Interpolation

(ludo)

We should can not build a single interpolation namespace, as using certain values in specific places will trigger a cycle. What we should do is provide different "flat" interpolation namespaces depending on context (principals, roles, tags, etc.).

Instead of this

```yaml
iam_by_principals:
  ${context.iam_principals.billing_admins}:
    - roles/billing.admin
    - ${context.iam_roles.my_custom_role}:
```

users should assume that all principals (manually passed in + derived at runtime) are available at that place, and custom roles are available for roles.

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
