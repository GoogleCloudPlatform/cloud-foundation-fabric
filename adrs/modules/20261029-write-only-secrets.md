# Secret Values in Module Interfaces

**authors:** [ludomagno](https://github.com/ludomagno)
**date:** Oct 29, 2026

## Status

Implemented in [#4329](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/4329). Supersedes the interfaces in `modules/secret-manager` (`data` + `data_config`) and `fast/project-templates/data-mongodb` (`password` + `password_wo` + `password_wo_version`), which are migrated in the same PR as this document together with the `organization` module change proposed in [#4327](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/4327). Applies to any future interface carrying a secret.

## Context

The Google provider has been adding write-only variants to arguments that carry secrets: `secret_data_wo` on secret versions, `plain_text_wo` on the three `client_secret` blocks of `google_iam_workforce_pool_provider`, and so on. Each comes paired with a `*_wo_version` number that triggers an update, since the provider cannot otherwise detect that a value it never stores has changed. The provider rule is that one of the plain or write-only attribute may be set, not both.

Fabric exposes this in two places today, with two different shapes.

`modules/secret-manager` takes a single `data` string and a `data_config` bag whose `write_only_version` selects between `secret_data` and `secret_data_wo`, with `is_file` deciding whether `data` is the secret or a path to it:

```hcl
versions = optional(map(object({
  data            = string
  deletion_policy = optional(string)
  enabled         = optional(bool)
  data_config = optional(object({
    is_base64          = optional(bool, false)
    is_file            = optional(bool, false)
    write_only_version = optional(number)
  }))
})), {})
```

`fast/project-templates/data-mongodb` mirrors the provider attribute names one to one, with a validation that exactly one of the two values is set and that the version accompanies the write-only one:

```hcl
password            = optional(string)
password_wo         = optional(string)
password_wo_version = optional(number)
```

Both work. Neither is documented as the way to do it, and the cost showed up in the `organization` module: [#4166](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/4166) proposed reading the workforce pool client secret from a file and was closed in favour of write-only attributes; its successor [#4327](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/pull/4327) adopted secret-manager's semantics with the config bag flattened and the version renamed, landing on a third shape that matched neither precedent and that the review had no document to point at.

Three concerns are tangled in these interfaces and are worth separating:

- **where the secret comes from**: a literal in configuration, or a file on disk. The file case matters for FAST, where factories are YAML and have no `file()` to call; it is the only way for a YAML-driven stage to keep a secret out of the data files.
- **how it reaches the provider**: the plain attribute, which stores the value in state, or the write-only one, which does not.
- **module-specific flags** that travel with the secret but are not about it, such as `is_base64` in secret-manager.

The secret-manager shape expresses the first concern with a boolean that changes the meaning of `data` from secret to path, which is the part of the design that reads badly and that #4327 reproduced.

## Decision

Secrets are passed through a single object, embedded under whatever attribute name the module uses for that secret (`client_secret`, `data`, `password`):

```hcl
object({
  value      = optional(string)
  path       = optional(string)
  wo_version = optional(number)
})
```

Each field is one thing. `value` is the secret. `path` is a path to a file containing it, read with `file(pathexpand(path))` so that `~` is honoured; a relative path resolves against the root module's working directory like every other path in our modules, an absolute path is used as is, and the file has to exist at every plan, destroys included. `wo_version` set means the secret goes to the provider's write-only attribute with that version; null means it goes to the plain attribute and is stored in state.

A variable validation requires at most one of `value` and `path`; nothing else needs validating, since the provider's own constraint that a write-only value needs a version is built into the shape. Both null is allowed on purpose: with `wo_version` set it means "nothing to send", and the provider leaves the existing write-only value in place as long as the version does not change. This is what lets a caller write `value = try(file("token.txt"), null)` and delete the file after the first apply, which `fast/project-templates/devops-azure-wif` relies on. The module itself never does that for `path`, a missing file there is an error, so that a typo in a path does not turn into an empty secret. Without `wo_version` a null source reaches the plain attribute as null and the provider rejects it, so nothing is created empty by accident. For a map variable holding the object under `data`:

```hcl
validation {
  condition = alltrue([
    for k, v in var.secrets :
    v.data.value == null || v.data.path == null
  ])
  error_message = "Only one of data.value and data.path can be set."
}
```

The two source fields and the one transport switch map onto the provider like this:

| `value` | `path` | `wo_version` | provider arguments |
|---|---|---|---|
| set | null | null | `plain = value` |
| null | set | null | `plain = file(pathexpand(path))` |
| set | null | set | `plain_wo = value`, `plain_wo_version = wo_version` |
| null | set | set | `plain_wo = file(pathexpand(path))`, `plain_wo_version = wo_version` |
| null | null | set | `plain_wo = null`, `plain_wo_version = wo_version`, existing value untouched |

Module-specific flags stay outside the object, as siblings of the attribute that holds it, so that the object is identical wherever it appears. In secret-manager `is_base64` moves next to `data` rather than inside it.

The plain path is kept on purpose. Some resources have no write-only attribute yet, some callers accept the value in state, and a module that only offered the write-only form would push those callers to work around it. READMEs state which form is the safe one and show it in the examples, as secret-manager already does.

### README section

Every module or template using the object carries a section explaining it, so that the semantics above are read where the attribute is used and not only here. The text below is the template; replace `<attribute>` with the attribute name, adjust the relative link to this document, and keep the rest, adding module-specific notes after it.

```markdown
## Secret values

`<attribute>` is an object that follows the [shape used for secrets across modules](../../adrs/modules/20261029-write-only-secrets.md):

- `value` is the secret itself
- `path` is the path to a file containing the secret, read via `file(pathexpand(path))` and relative to the root module; the file must exist at every plan
- `wo_version` switches to the provider's write-only attribute, so that the secret is never stored in state; bump the number whenever the secret changes and needs to be sent again

Only one of `value` and `path` can be set. Without `wo_version` the secret is stored in state, and that form should only be used when this is acceptable. With `wo_version` set, both `value` and `path` can be null once the secret has been applied, since the provider leaves the existing write-only value untouched until the version changes: this allows passing `value = try(file("secret.txt"), null)` and removing the file after the first apply.
```

Two shapes were considered and set aside. Mirroring the provider with `value`, `wo_value` and `wo_version` makes the transport choice visible in the field name, but needs two validations instead of one and, once `path` is added for FAST, grows to four source fields for one secret. Keeping secret-manager's `data` + `data_config` bag has the overloaded `data` field described above, and the bag only pays for itself when there are several flags to carry, which here there are not.

## Consequences

- **`modules/secret-manager`**: `versions.*.data` becomes the object, `data_config.is_base64` becomes `versions.*.is_base64`, `data_config` goes away. Breaking for every caller setting versions, with an upgrade note in the PR. `google_secret_manager_regional_secret_version` has gained `secret_data_wo` upstream since the module was written, so the "regional secrets still store data in state" caveat is lifted at the same time. The `skip-tofu` markers on its tests predate write-only support in OpenTofu, which arrived in 1.11 and is what CI pins; they are removed with the migration and tests run on both flavours.
- **`fast/project-templates/data-mongodb`**: `database_users.*.password` becomes the object and `password_wo` / `password_wo_version` are removed, with the two validations collapsing into one.
- **`modules/organization`**: the three `client_secret` fields under `workforce_identity_pools` (`identity_provider.oidc`, `oauth2_client_config.extra_attributes`, `oauth2_client_config.extended_attributes`) become the object, mapped to `plain_text` / `plain_text_wo` / `plain_text_wo_version`. This is the change #4327 set out to make, done here in its place. The FAST `0-org-setup` organization schema follows the module.
- **Callers inside the repository** are updated in the same PR: `fast/stages/3-secops-dev/secrets.tf`, `fast/project-templates/devops-azure-wif/self-hosted-agents/main.tf`, the `tests/fixtures/secret-credentials.tf` fixture, and the `secret-manager` examples in the `cloud-build-v2-connection`, `cloud-function-v1`, `cloud-function-v2`, `cloud-run-v2` and `dataform-repository` READMEs.
- **FAST schemas** that expose a secret declare the object with `additionalProperties: false` and the same three properties, and describe `path` as relative to the stage directory.
- **New interfaces** carrying a secret adopt the object as is, and the README section above; a PR introducing a different shape is asked to cite this document or amend it.
