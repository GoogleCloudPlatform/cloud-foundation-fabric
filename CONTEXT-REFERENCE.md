# FAST context reference

**Status:** reference, not a proposal. It describes the context mechanism as implemented in this tree, so that the next reader does not have to rediscover it from the code the way the stage-outputs work did.

**Pin:** branch `ludo/fast-interfaces`, commit `7d957ca5f`. Line numbers are from that commit. The proposal that changes how stages hand each other context is a separate document: [`stage-outputs-context.md`](./stage-outputs-context.md), with its implementation plan in [`stage-outputs-context-plan.md`](./stage-outputs-context-plan.md). This file describes what exists today and points at that ADR where the shapes are about to change.

## 1. What context is

Context is Fast's plan-time indirection for values that are not known when a file is written: a project id, a folder id, a VPC self-link, an IAM principal, a tag value. Instead of pasting the literal, a caller writes a symbolic reference, `"$project_ids:iac-0"`, and passes a map of namespaces alongside it:

```hcl
module "project" {
  source  = "./modules/project"
  context = { project_ids = { iac-0 = "my-iac-project" } }
  parent  = "$folder_ids:teams/team-a"
}
```

The module resolves the reference at plan time, or keeps it as a literal if it finds nothing. Three properties follow, and everything else in this document is a consequence of them:

- references stay short and readable, and a whole deployment can be pointed at a different organization by changing the maps rather than the references;
- resolution happens inside the consumer, so a consumer never reaches into a producer's state;
- a name that is not in the maps is passed through unchanged, which is what lets the same file work both with and without FAST.

## 2. Namespaces

A **namespace** is a named map carried by `var.context`. The name is the part before the colon in a reference. `project_ids`, `folder_ids`, `iam_principals`, `locations`, `networks`, `subnets`, `custom_roles`, `kms_keys`, `storage_buckets`, `tag_keys`, `tag_values` are the common ones.

As of the pin: **45 modules declare `variable "context"`, and between them they use 40 distinct namespaces** (`grep -l '^variable "context"' modules/*/variables.tf`, and a parse of the declared types). Their shapes are not uniform:

| shape | count | namespaces |
| --- | --- | --- |
| `map(string)` | 31 | the bulk, e.g. `project_ids`, `folder_ids`, `networks`, `locations` |
| `map(list(string))` | 6 | `cidr_ranges_sets`, `folder_sets`, `identity_sets`, `project_sets`, `resource_sets`, `service_sets` |
| `map(map(string))` | 1 | `condition_vars` |
| object | 1 | `tag_vars` |
| `map(number)` | 1 | `project_numbers`, in `modules/vpc-sc/variables.tf:139` |

Each declaration is `optional(<shape>, {})`, so an unset namespace is an empty map rather than an absent attribute, and each module declares only the namespaces it can resolve.

**Where the vocabulary is declared: nowhere central.** A namespace's type is written at each point of consumption, so two modules can legitimately disagree — and one pair does: `project_numbers` is `map(number)` in `fast/stages/1-vpcsc/variables.tf:78` and `modules/vpc-sc/variables.tf:139`, and `map(string)` in `modules/billing-account/variables.tf:150`, `modules/folder/variables.tf:184` and `modules/project-factory/variables.tf:31`. Nothing states what a producer may publish under a name. That gap is rule 10's first question in the plan.

## 3. The symbolic form

A reference is `$` + namespace + `:` + key: `"$project_ids:iac-0"`, `"$folder_ids:teams/team-a"`, `"$networks:dmz"`, `"$subnets:dmz/europe-west1/dmz-default"`.

It can appear anywhere a string reaches a module or is written in a factory's YAML, and it is resolved by two idioms that both depend on the flattened context described in §4:

- **lookup the symbolic string as-is**: `lookup(local.ctx.project_ids, var.project_id, var.project_id)` (`modules/artifact-registry/main.tf:31`; the same block's `locations` lookup is at `:29`). The third argument is the fallback, and it is what makes a literal work unchanged.
- **strip the prefix to recover the plain key**: `replace(k, "$folder_ids:", "")` (`modules/project-factory/projects.tf:137`), used when the module needs the unqualified name — for an API call or for a map key of its own.

The prefix can also be compared rather than stripped: `startswith(service, "${local.ctx_p}service_agents:")` (`modules/project/shared-vpc.tf:37`).

Two limits worth knowing before designing around it:

- **resolution is one level deep.** The key is a plain string. A namespace whose value is a map or an object cannot be indexed by `$ns:key:subkey`; the module either reads the attribute directly (`local.ctx.tag_vars.organization`) or the value arrives as a whole map under one key.
- **resolution is per consumer.** Two modules declaring the same namespace with different types will each resolve the same string differently, or not at all.

## 4. The implementation

### 4.1 The module side: flattening

43 of the 45 modules that declare `context` flatten it in a `locals` block, with the same four lines (`modules/folder/main.tf:17-23`, `modules/artifact-registry/main.tf:17-23`, and 41 others):

```hcl
locals {
  ctx = {
    for k, v in var.context : k => {
      for kk, vv in v : "${local.ctx_p}${k}:${kk}" => vv
    }
    if !endswith(k, "_vars")
  }
  ctx_p = "$"
}
```

The inner loop rewrites every entry of every namespace to the symbolic string a caller would write, so `local.ctx.project_ids` is keyed by `"$project_ids:iac-0"`. That is why the lookup idiom above works with the symbolic form as the key, and it is why `local.ctx` is a map of namespaces whose inner keys are prefixed strings rather than the raw ones.

Three details:

- **`if !endswith(k, "_vars")`** excludes the namespaces whose names end in `_vars` from the flattening. 20 modules do this (`grep -l 'endswith(k, "_vars")' modules/*/*.tf`); they read `condition_vars` and `tag_vars` from `var.context` directly instead, as whole maps or objects. The other 23 flatten them too, which produces keys like `"$tag_vars:organization"` and `"$condition_vars:<key>"` — see §6.
- **Two modules do not flatten at all**: `modules/project-factory/main.tf:20` and `modules/net-vpc-factory/main.tf:18` both read `ctx = var.context`, so their `local.ctx.<namespace>` is the raw map. They are the modules that consume `tag_vars` as an object and `condition_vars` as a map of maps.
- **Local additions are merged on top.** A module that creates something resolvable, or that needs a namespace it did not receive, merges it into `local.ctx` after the loop; `modules/project/shared-vpc.tf` and `modules/project-factory/main.tf:21-30` are examples.

### 4.2 The factory side

A factory YAML file writes references exactly as a caller would, and the module resolves them when it consumes the value:

```yaml
parent: $folder_ids:teams/team-a
```

Stage-level factories — `fast/stages/2-networking/factory-*.tf` — do their own resolution, because they are locals rather than module calls: `factory-peering.tf:50-56` strips the `$networks:` prefix from a YAML value and looks the rest up in a map built from the stage's own VPC factory outputs, falling back to the literal.

### 4.3 The stage side

A stage receives context from three places and merges them in `main.tf`:

1. **`var.context`** — the user's own namespaces, typically written in a `terraform.tfvars` or an override file.
2. **the defaults file's `context:` block** — the dataset's `defaults.yaml`, which carries deployment-wide namespaces. `fast/stages/0-org-setup/datasets/classic/defaults.yaml:37-45` is the smallest example (`email_addresses`, `iam_principals`, `locations`).
3. **values published by upstream stages** — today these arrive as ordinary variables from a tfvars file and are merged into the context by hand, which is the mechanism the ADR changes.

The merge is the same shape in every stage: build `_ctx` from `var.context` with the defaults file on top, then merge the upstream values underneath so the user's entries win (`fast/stages/2-networking/main.tf:17-59`, `2-security/main.tf:18-53`, `2-project-factory/main.tf:19-26` with `:83-120`, `1-vpcsc/main.tf:18-77`, `3-secops-dev/main.tf:53-59`).

## 5. Precedence

From lowest to highest:

1. a value published by an upstream stage;
2. the user's `var.context`;
3. the dataset's `defaults.yaml` `context:` block;
4. a literal supplied where the reference is consumed (the fallback argument to `lookup`).

The first three are visible in one line of `2-networking`: `merge(v, try(local._defaults.context[k], {}))` puts the defaults file above the user (`main.tf:18-21`), and `merge(var.custom_roles, local._ctx.custom_roles)` puts both above the upstream value (`:35`). The fourth is not a level of the merge at all: it is what happens when the lookup misses.

Independently of context, tfvars files replace each other rather than merging: two files assigning the same variable means the later one wins, in lexical filename order. That is why one variable can have exactly one writer, and it is the constraint the ADR's role variables are built around.

## 6. Special entries

- **`condition_vars`** (`map(map(string))`, 19 modules). Not resolved by `$ns:key` lookups; it is handed whole to `templatestring` to expand `${...}` placeholders inside IAM condition expressions and organization policy values: `templatestring(each.value.condition.expression, var.context.condition_vars)` (`modules/project/iam.tf:184`, `modules/artifact-registry/iam.tf:48-49`). This is why the 20 modules that use it exclude it from the flattening.
- **`tag_vars`** (object with `projects` and `organization`). Also consumed whole, and merged per attribute where a module composes its own: `projects = merge(try(local.ctx.tag_vars.projects, {}), local.tag_vars_projects)` (`modules/project-factory/automation.tf:157-161`, and the same four times in `folders.tf`). A shallow merge at namespace level would replace the whole object, which is the defect recorded in §2.1 of the plan.
- **`locations`, and `regions` as its legacy alias.** `modules/net-vpc` declares both, merges them with `locations` winning, and its validation refuses to have both set: `Only one of locations, regions can be used.` (`modules/net-vpc/main.tf:22-24` and the `validation` block in `variables.tf`). New code should use `locations`.
- **`project_numbers`.** The only numeric namespace, and the only one typed two ways (§2).
- **`$service_agents:` is a prefix, not a namespace.** Project YAML writes `$service_agents:compute` in shared-VPC service-agent grants (`fast/project-templates/gce-workstation-cluster/project.yaml:68`), and `modules/project/shared-vpc.tf:32-45` handles it by testing for the prefix and stripping it itself — no `variable "context"` anywhere declares `service_agents`, so this form resolves only on that code path. It is worth knowing because it looks exactly like a namespace and is not one.
- **`vpc_host_projects`, `email_addresses`, `notification_channels`, `cidr_ranges_sets`** and the rest: ordinary map namespaces that happen to have no stage publishing them today; they are supplied by the user or by the defaults file. A list of namespaces a stage declares but nothing publishes is in §1.11 of the plan.

## 7. Where to start reading

- `AGENTS.md:148` — "Adding Context Support to a Module": the pattern for adding `context` to a module, which is also the best existing description of the mechanism.
- `modules/folder/main.tf:17-23` — the flattening idiom in its shortest form.
- `modules/artifact-registry/main.tf:17-29` — the same, plus the lookup idiom and a `_vars` filter.
- `modules/project/iam.tf:184` — `condition_vars` and `templatestring`.
- `modules/project-factory/main.tf:20-30` — a module that does not flatten, and how it merges local additions.
- `fast/stages/2-networking/main.tf:17-59` — the stage-side merge in full, including upstream values.
- `fast/stages/0-org-setup/datasets/classic/defaults.yaml:37-45` — the defaults-file `context:` block.
- `fast/stages/2-networking/datasets/hub-and-spokes-nva/nvas/main.yaml` — `$networks:` and `$subnets:` references in a real dataset.

## 8. What is not written down anywhere else

Four things this document records because they are not stated in one place in the tree, and each has cost someone time:

1. **There is no context specification.** The vocabulary lives in 45 `variable "context"` declarations written by hand, so the namespaces and their types can disagree, and `project_numbers` does. Any move to publish namespaces as a documented interface — the plan's rule 10 question — starts from this gap.
2. **The `$ns:key` form is one level deep, and the flattening is what makes it work.** A namespace that is a map or an object gets a key per top-level attribute: `$tag_vars:projects` and `$tag_vars:organization` exist in the 23 modules that do not filter `_vars`, and `$condition_vars:<key>` likewise. Nothing uses either form: `grep -rF '$tag_vars:'` and `grep -rF '$condition_vars:'` over `fast/`, `modules/` and `tests/` both return zero, because the modules that consume those namespaces read them as whole objects or pass them to `templatestring`. *Unsourced:* whether the flattening of `_vars` namespaces is intentional or an artefact nobody has needed.
3. **`subnets` and `subnetworks`** are the same idea under two spellings: 14 modules declare the first, `modules/workstation-cluster` the second (`variables.tf:32`).
4. **Which namespaces are produced by a stage and which by the user** is not visible from a module. `locations` and `cidr_ranges_sets`, for instance, arrive from a defaults file; `project_ids` and `folder_ids` arrive from stage 0. §1.11 of the plan lists the names that are declared with a source and published by nobody.
