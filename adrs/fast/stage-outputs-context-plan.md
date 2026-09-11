# Stage outputs and context — implementation plan

**Status:** draft for review. \
**Companion to:** [`stage-outputs-context.md`](./stage-outputs-context.md), which this plan takes as the proposal to implement rather than to argue.

**Reference:** branch `ludo/fast-interfaces`, commit `7d957ca5f`. The checkout's HEAD is `e20170d34` and `git diff --stat 7d957ca5f HEAD` is `adrs/fast/stage-outputs-context-prompt.md` only, so every path under `fast/` is byte-identical at both commits. All line numbers below are at `7d957ca5f`.

**Evidence rules used here.** Every claim about code carries a path, usually with a line number. The few that do not are marked *unsourced* in those words. Namespace hit counts are `grep -rF '$name:'` over the repo (`--include=*.tf --include=*.yaml --include=*.json --include=*.md`); they are a presence test, not a measure of importance. Nothing in this plan has been run: no `terraform init`, `plan` or `apply`. Suspicions that need a run are collected in §5 as named probes.

---

## 0. The change in code, in one page

For a reader who knows the tree and wants the shape before the inventory. Today four stages write flat tfvars files and later stages read them through declarations in `variables-fast.tf`:

```hcl
tfvars/0-org-setup.auto.tfvars.json    project_ids = {"iac-0" = "prj-…"}, folder_ids = {...}, iam_principals = {...}, …
tfvars/2-networking.auto.tfvars.json   host_project_ids = {"net-spoke-0" = "prj-…"}, vpc_self_links = {...}, subnet_self_links = {...}
tfvars/2-security.auto.tfvars.json     ca_pools = {...}, kms_keys = {...}
tfvars/1-vpcsc.auto.tfvars.json        perimeters = {"default" = "accessPolicies/…/perimeters/…"}
```

Each consumer declares those as its own variables and merges them into `local.ctx` by hand — `2-networking/main.tf:34-59`, `2-security/main.tf:30-53`, `2-project-factory/main.tf:83-120`, `1-vpcsc/main.tf:40-77`, `3-secops-dev/main.tf:53-59`. The line that shows why the mechanism needs a rule is `2-project-factory/main.tf:107-109`:

```hcl
project_ids = merge(var.project_ids, var.host_project_ids, local.context.project_ids)
```

After the change, one variable per FAST role carries the namespaces, and one shared file merges them:

```hcl
# tfvars/0-org-setup.auto.tfvars.json
fast_org        = { project_ids = {...}, folder_ids = {...}, iam_principals = {...}, … }
# tfvars/2-networking.auto.tfvars.json
fast_networking = { networks = {...}, subnets = {...}, project_ids = {...}, … }
# tfvars/2-security.auto.tfvars.json
fast_security   = { ca_pools = {...}, kms_keys = {...} }
# tfvars/1-vpcsc.auto.tfvars.json
fast_vpcsc      = { vpc_sc_perimeters = {...} }
```

`context.tf` — identical in every stage and add-on, registered in `tools/duplicate-diff.py` — declares those four variables and merges them per namespace in the order today's code already uses (role value, then `var.context`, then the defaults file):

```hcl
locals {
  _fast_ctx = {
    for k, v in var.context : k => merge(
      try(var.fast_org[k], {}), try(var.fast_vpcsc[k], {}),
      try(var.fast_networking[k], {}), try(var.fast_security[k], {}),
      v, try(local.context_defaults[k], {})
    )
  }
  fast_ctx = merge(local._fast_ctx, { tag_vars = { … the one object-valued namespace, merged two levels deep … } })
}
```

In the stage, the merge block shrinks to whatever is not role data. For 2-networking, `main.tf:34-59` loses its ten `merge(var.X, …)` lines, keeps the `iam_principals` entries built from `service_accounts`, and gains two lines:

```hcl
context_defaults = try(local._defaults.context, {})   # new: where the defaults file's context lives now
_ctx             = local.fast_ctx                      # was: {for k, v in var.context : k => merge(v, defaults[k])}
```

The full justification, the per-stage change lists, the migration and the probes are §2 onward. This section exists so that a reviewer can see the shape before the evidence, and it is the persisted form of the walk-through the human asked to keep for future readers.

---

## 1. Inventory (rule 9)

### 1.1 The test as applied, and the two places it needs a second leg

The ADR's test is "a value referenced symbolically as `$namespace:key` somewhere is context, and a value that HCL reads directly is a variable". Applied literally it classifies the flat maps of strings and misses two cases:

- **`tag_vars`** has no `$tag_vars:key` form because it is consumed whole, as an object, never resolved key by key: `modules/project-factory/automation.tf:159-160`, `modules/project-factory/folders.tf:113-114`, `:196-197`, `:279-280`, `:362-363`; type at `fast/stages/2-project-factory/variables.tf:31-34`.
- **A renamed namespace** has a `$ns:key` form under a name the producer does not use. `1-vpcsc` publishes the flat key `perimeters` (`fast/stages/1-vpcsc/outputs.tf:19-22`) and every consumer renames it into `vpc_sc_perimeters` by hand: `2-networking/main.tf:58`, `2-security/main.tf:53`, `2-project-factory/main.tf:25` and `:119`. `$vpc_sc_perimeters:` is used 8 times.

So this plan states the test as: **a namespace declared in the stage's `context` type**, with `$ns:key` as the evidence for the flat ones, and `tag_vars` plus any renamed value called out explicitly. The alternative reading — "is it merged into a local named `ctx`" — gives the same answer on every row below and is easier to check, because the merge is visible in six files (§1.7).

One more consequence worth stating before the tables: the incoming leg is already dual-channel. `iam_principals` is used symbolically 754 times and also read directly as a variable in all five consumer stages (`2-networking/main.tf:37-44`, `1-vpcsc/main.tf:41-48`, `2-project-factory/main.tf:96-103`, `2-security/main.tf:35-40`, `3-secops-dev/main.tf:56`). The same is true of `custom_roles`, `folder_ids`, `project_ids`, `project_numbers`, `storage_buckets`, `tag_keys`, `tag_values`, `kms_keys`. Under either channel the value is a namespace; the difference is only how it arrives. That is the ADR's proposal in one sentence, and the inventory below records both legs.

### 1.2 0-org-setup

Writer: `fast/stages/0-org-setup/output-files.tf`. Two files, `0-globals.auto.tfvars.json` and `0-org-setup.auto.tfvars.json`, written by `local_file.tfvars` `:177-182` and `google_storage_bucket_object.tfvars` `:184-189`, from `local.of_tfvars` `:109-154`. (`of_ctx` is at `:22-64`; the ADR cites line 109 for `of_ctx`, which is `of_tfvars` — worth correcting on the way past.)

`0-globals` (`of_tfvars.globals`, `:110-126`), all first-class:

| value | written | consumers (`variables-fast.tf`) | class |
| --- | --- | --- | --- |
| `billing_account` | `:111-113` | 2-networking:17, 2-project-factory:26, 2-security:17, 3-secops-dev:26 | variable (0 hits) |
| `groups` | `:114` | none | variable (0 hits) |
| `organization` | `:115-119` | 1-vpcsc:48, 2-networking:58, 2-project-factory:74, ngfw:57 | variable (0 hits) |
| `prefix` | `:120` | 2-networking:75, 2-project-factory:92, 2-security:57, 3-secops-dev:67 | variable (0 hits) |
| `universe` | `:121-125` | 2-networking:136, 2-project-factory:145, 2-security:118 | variable (0 hits) |

`0-org-setup` (`of_tfvars.org-setup`, `:127-153`):

| value | written | consumers | class |
| --- | --- | --- | --- |
| `automation` | `:128-130` | 2-project-factory:17, 3-secops-dev:17, ngfw:29, swp:29 | variable (0 hits) |
| `custom_roles` | `:131` | 2-networking:25, 2-project-factory:34, 2-security:25, 3-secops-dev:35 | context (469) |
| `folder_ids` | `:132` | 2-networking:33, 2-project-factory:42, 2-security:33, 3-secops-dev:43 | context (113) |
| `iam_principals` | `:133` | 1-vpcsc:17, 2-networking:41, 2-project-factory:50, 2-security:41, 3-secops-dev:51 | context (754), also read directly in all five |
| `logging_sinks` | `:134` | 1-vpcsc:25 | variable (0 hits) |
| `project_ids` | `:135` | 1-vpcsc:59, 2-networking:85, 2-project-factory:102, 2-security:67, 3-secops-dev:74 | context (216), also read directly |
| `project_numbers` | `:136` | 1-vpcsc:67 | context (25) |
| `service_accounts` | `:137` | 1-vpcsc:89, 2-networking:93, 2-project-factory:110, 2-security:75 | variable (0 hits) |
| `storage_buckets` | `:138` | 1-vpcsc:97, 2-networking:101, 2-security:83 | context (92) |
| `subnet_ips` | `:139-141` | none | variable; second publisher of a name 2-networking also writes (§1.4) |
| `subnet_self_links` | `:142-144` | the same name is declared by 2-project-factory:118, swp:53, test:35 | variable; second publisher, shadowed by load order (*inference*) |
| `tag_keys` | `:145` | 2-networking:109, 2-security:91 | context (7) |
| `tag_values` | `:146` | 2-networking:117, 2-project-factory:126, 2-security:99 | context (54) |
| `tag_vars` | `:147` | 2-networking:125, 2-project-factory:134, 2-security:107 | context by type only (§1.1) |
| `vpc_self_links` | `:148-150` | the same name is declared by ngfw:67, swp:61, test:43 | variable; second publisher, shadowed by load order (*inference*) |
| `workload_identity_providers` | `:151` | none | context (8), dead in chain |
| `workforce_identity_providers` | `:152` | none | variable (0 hits), dead |

Root outputs, `fast/stages/0-org-setup/outputs.tf`: `iam_principals` `:17`, `projects` `:22`, `subnet_ips` `:27`, `subnet_self_links` `:34`, `tfvars` `:41`, `vpc_self_links` `:47`. The `tfvars` output is asserted as `__missing__` (sensitive) in the stage inventories, so its shape change costs no inventory churn.

Two things this stage does that the table's "class" column hides. It publishes three names that 2-networking also publishes — `subnet_ips` (`:139-141`), `subnet_self_links` (`:142-144`) and `vpc_self_links` (`:148-150`), plus the same three as root outputs — so the ADR's second problem already has **three live instances**, not one. *Inference:* since Terraform loads `*.auto.tfvars.json` in lexical order and replaces rather than merges, `0-org-setup` sorts before `2-networking`, so in any deployment that loads both files the stage-0 copies are shadowed for every consumer that declares the name (the mechanism is the ADR's, the ordering is the filename's; no run was made). And `local.of_ctx` contains `pubsub_topics` (`:42`), which never reaches `of_tfvars` — internal to the stage, not published. Muse found both (room #56); the collision is confirmed against my own read of `:127-153`.

### 1.3 1-vpcsc

Writer: `fast/stages/1-vpcsc/outputs.tf`, `local.tfvars` `:18-23`, file `<stage_name>.auto.tfvars.json` (`:37-42`, `:44-49`; `stage_name` defaults to `1-vpcsc` at `main.tf:80`).

| value | written | consumers | class |
| --- | --- | --- | --- |
| `perimeters` | `:19-22` (`k => v.id`) | 2-networking:67, 2-project-factory:84, 2-security:49 | variable, renamed to `vpc_sc_perimeters` by every consumer (§1.1) |
| `vpc_sc_perimeter_default` | `outputs.tf:58-62` | none | output only |
| `tfvars` | `outputs.tf:52-56` | none | output only, sensitive |

### 1.4 2-networking

Writer: `fast/stages/2-networking/outputs.tf`, `local.tfvars` `:18-40`, file `<stage_name>.auto.tfvars.json` `:56-61`, `:63-69` (`stage_name` default at `main.tf:63`).

| value | written | consumers | class |
| --- | --- | --- | --- |
| `host_project_ids` | `:19` | 2-project-factory:58, ngfw:49, swp:37, test:19 | variable (0 hits) |
| `host_project_numbers` | `:20` | none | variable, dead |
| `subnet_ips` | `:21-23` | none | variable, dead |
| `subnet_self_links` | `:24-26` | 2-project-factory:118, swp:53, test:35 | variable (0 hits) |
| `subnet_proxy_only_self_links` | `:27-31` | none | variable, dead |
| `subnet_psc_self_links` | `:32-36` | none | variable, dead |
| `vpc_self_links` | `:37-40` | ngfw:67, swp:61, test:43 | variable (0 hits) |

Two of them are re-cast into context inside a consumer: `2-project-factory/main.tf:107-109` merges `host_project_ids` into the `project_ids` namespace, and `:71-78` with `:85-87` flattens `subnet_self_links` into `condition_vars.subnet_self_links`. All seven are also root outputs `:73-106`, which is how the stage tests read them. Three of the seven — `subnet_ips`, `subnet_self_links`, `vpc_self_links` — are names 0-org-setup publishes as well (§1.2), so they are the ADR's second problem in duplicate rather than new values.

### 1.5 2-project-factory

Writers: `fast/stages/2-project-factory/output-files.tf`. One tfvars file per project, `<project>.auto.tfvars.json`, content `module.factory.projects[each.value]` (`local_file.tfvars` `:143-152`, bucket object `:162-169`), plus provider files `:134-141`, `:154-160`.

| value | written | consumers | class |
| --- | --- | --- | --- |
| per-project tfvars | `:143-152` | none in-repo; the readers are team roots outside FAST (project templates). *Unsourced:* no in-repo consumer was found | variable, concrete project attributes |
| `projects` | `outputs.tf:17-19` | none | output only |
| `vpcs` | `outputs.tf:22-24` | none (`variable "vpcs"` is declared nowhere under `fast/`) | output only |

The ADR's two citations for this stage check out: the hand merge is `main.tf:107-109` and the context/defaults merge is `main.tf:20-26`.

### 1.6 2-security

Writer: `fast/stages/2-security/outputs.tf`, `local.tfvars` `:26-37`, file `<stage_name>.auto.tfvars.json` `:51-56`, `:58-63` (`stage_name` default `2-security` at `main.tf:58`).

| value | written | consumers | class |
| --- | --- | --- | --- |
| `ca_pools` | `:27-33` | none | variable (0 hits); shape is `{ca_ids, id, location}` per pool |
| `kms_keys` | `:34-36` | 2-networking:50, 2-project-factory:66, 3-secops-dev:59 | context (23) |
| `kms_keys_ids` | `outputs.tf:71-74` | none | output only, alias of `kms_keys` |
| `tfvars` | `outputs.tf:76-80` | none | output only, sensitive |

`ca_pools` has no consumer anywhere: repo-wide hits are its own producer (`outputs.tf:27`, `:66`), its factory (`factory-cas.tf:18-28`, `:92`), the ADR, and two test inventories (`tests/fast/stages/s2_security/simple.yaml:464`, `service_agent.yaml:120`). The nearest thing to a consumer is the ngfw add-on's `certificate_authority_pools` (`fast/addons/2-networking-ngfw/variables-fast.tf:37`, read at `tls-inspection.tf:21`), same shape, different name, never written by any stage. The ADR's "the security stage publishes no project ids" is confirmed: `local.tfvars` `:26-37` holds `ca_pools` and `kms_keys` only, although `factory-projects.tf` exists.

### 1.7 3-secops-dev

| value | written | consumers | class |
|---|---|---|---|
| `project_id` | `outputs.tf:15-18` | none (the only repo hit outside the file is its own input declaration) | output only |

No tfvars writer at all; the stage only writes `versions/3-<name>-version.txt` (`outputs.tf:20-26`). It reads five role-carried variables plus three first-class ones (`variables-fast.tf`: `custom_roles`:35, `folder_ids`:43, `iam_principals`:51, `kms_keys`:59, `project_ids`:74, `automation`:17, `billing_account`:26, `prefix`:67).

### 1.8 Add-ons

**2-networking-ngfw.** Writer `outputs.tf`, `local.tfvars` `:22-33`, file `tfvars/2-networking-ngfw.auto.tfvars.json` (`:36-41`, `:43-47`; prefix default at `variables.tf:107`). `ngfw` (associations, endpoints; `:23-31`) and `security_profile_groups` (`:32`): no consumer, no `$ngfw:` or `$security_profile_groups:` anywhere. Variable, and the ADR's remainder naming these two is right.

**2-networking-swp.** Writer `outputs.tf`, `local.tfvars` `:18-31`, file `tfvars/2-networking-<name>.auto.tfvars.json` (`:59-70`). `swp_cas_pool_ids` `:19`, `swp_gateway_ids` `:22`, `swp_gateway_security_policy_ids` `:25`, `swp_service_attachment_ids` `:28`: no consumer, no symbolic refs. Variable. Root outputs `cas_pool_ids` `:34`, `gateway_security_policies` `:39`, `gateways` `:44`, `ids` `:49`, `service_attachments` `:54`. The ADR's remainder names "two outputs from the network security add-on"; these four are also outside context and outside that count.

**2-networking-test.** Root outputs only (`outputs.tf:17-39`): `instance_addresses`, `instance_ssh`, `service_account_emails`. No tfvars writer, so it publishes nothing into the chain. Its `context.tf` (`:17-59`) is an add-on-local locals file, not the shared file this plan proposes — see §3.2.

### 1.9 Extras

`fast/extras/0-cicd-github` and `fast/extras/0-cicd-gitlab`: one root output each, both named `clone` (`outputs.tf:17-23` in each), referenced by no `.tf` file outside `fast/extras`. They publish nothing into the chain and are left out of the table.

They are not consumers of the globals file either — but they are the ADR's first problem in the wild. `0-cicd-github/variables.tf:51-54` declares `organization` as a `string`; `0-cicd-gitlab/variables.tf:45-52` declares `groups` as a `map(object({name, path, description}))`. The globals file publishes `organization` as an object (`:115-119`) and `groups` as a map of IAM principals (`:114`). Same two names the ADR uses as its example, different types, in the same tree. Nothing reads either from the bucket today, so this is a collision waiting for the first user who points an extra at the outputs directory rather than a live failure. It is the cheapest existing argument for role variables: `fast_org` cannot collide with anything a stage author wants to call their own.

### 1.10 The remainder, and where I agree with the ADR

The ADR lists `automation`, `stage_configs` and "two outputs from the network security add-on" as the values that cannot be used via context. Findings:

- `automation`: agree. Written at `0-org-setup/output-files.tf:128-130`, read as `var.automation.outputs_bucket` in four roots (`2-project-factory/outputs.tf:29`, `3-secops-dev/outputs.tf:22`, `ngfw/outputs.tf:44`, `swp/outputs.tf:67`).
- `stage_configs`: **not found, and it is a leftover rather than a typo.** `grep -rn stage_configs fast/ modules/` is empty today. It was a real output once: `ade7fb32b` renamed `stage_config` → `stage_configs` (PR #3042, `CHANGELOG.md:1822`, 2025-04-16) across `1-resman` and `2-security`, and `git log -S stage_configs -- fast` then shows the stages that carried it being removed (`9b862c383`, `4a41a4237`, `118b70d45`). Provenance from qwen (room #72), re-checked at those two anchors. The nearest live thing is `3-secops-dev/variables.tf:127` `stage_config`, a root variable nothing publishes. The list needs the item dropped, not renamed.
- The two add-on outputs: agree for ngfw (`ngfw`, `security_profile_groups`), and the list is short by swp's four keys (§1.8).
- **The remainder is not short from stage 0.** `logging_sinks`, `service_accounts`, `subnet_ips`, `subnet_self_links`, `vpc_self_links`, `workforce_identity_providers`, plus the whole globals file, each have one producer, no second writer, and no context form. They stay first-class for exactly the reason the ADR gives for `automation`, so the plan lists them as first-class rather than pretending they are context.
- Two values are dead in a way the list does not cover: `subnet_ips`, `subnet_self_links`, `vpc_self_links` and `workload_identity_providers` are published by stage 0 and 2-networking under names nothing consumes (four more from 2-networking in §1.4). Killing them is a decision (§6.4), not part of this proposal.

### 1.11 Declared sources that nothing publishes

- **`regions`.** `fast/addons/2-networking-swp/variables-fast.tf:45-51` and `2-networking-test/variables-fast.tf:27-33` declare it with `# tfdoc:variable:source 2-networking`. 2-networking's tfvars local (`outputs.tf:18-40`) has no `regions` key, and no dataset under `fast/stages/2-networking/datasets/` defines one. The value is hand-written in the add-on tests (`tests/fast/addons/a2_networking_test/simple.tfvars:4`). Either the annotation is wrong or a producer is missing; on the current code a user driving an add-on from the networking stage's file must set `regions` by hand. The namespace itself is not invented: `modules/net-vpc/variables.tf:58` declares `regions = optional(map(string), {})` next to `locations`, `modules/net-vpc/main.tf:22-24` merges the two with `locations` winning, and the module forbids setting both (`Only one of locations, regions can be used.`, in that variable's `validation`). So `regions` is the module-side legacy name for `locations`, and the add-ons are declaring the older of the two — settled in §6.4 in favour of `locations`.
- **`certificate_authority_pools`.** `fast/addons/2-networking-ngfw/variables-fast.tf:37-47`, source `2-security`; 2-security publishes `ca_pools` (§1.6). Different key, same shape, so the value never arrives — with a sharper consequence than a missing map. `2-networking-ngfw/.fast-stage.env` lists `2-security` in `FAST_STAGE_OPTIONAL`, so `fast-links.sh` links `2-security.auto.tfvars.json` whenever it is present, and that file sets `ca_pools` *and* `kms_keys`, neither of which any ngfw root declares (`grep -rn ca_pools fast/addons/2-networking-ngfw/` is empty). *Inference, no run made:* on the rule §4.3 rests on — an auto-loaded file that assigns an undeclared variable is a hard error — the documented workflow fails before the mismatch ever matters. This is the only place in the tree where the two names meet, and it is the same failure mode the migration is designed around.
- **`root_node`.** `fast/stages/1-vpcsc/variables-fast.tf:75-88` declares it, source `0-org-setup`; stage 0 publishes no such key; the only read is inside 1-vpcsc itself (`main.tf:102`).
- **`_fast_debug`.** Declared in the FAST channel by two add-ons (`addons/2-networking-ngfw/variables-fast.tf:20`, `addons/2-networking-swp/variables-fast.tf:20`) and read at `ngfw/main.tf:26`, `ngfw/tls-inspection.tf:47`, `swp/main.tf:40`, `swp/tls-inspection.tf:39`. No stage publishes it. The only files in the tree that set it are the two add-on tests (`tests/fast/addons/a2_networking_ngfw/simple.tfvars:1`, `a2_networking-swp`'s equivalent at `:1`), and its own description says "Internal FAST variable used for testing and debugging. Do not use." It is a consumer-side switch sitting in a file otherwise made of stage outputs, which is why it belongs on this list — and it is the one name here that no role could ever carry.

### 1.12 The merge already exists in six files

Every consumer stage already merges role data into context by hand, with the same shape:

| file | merge local | role-variable merges |
| --- | --- | --- |
| `0-org-setup/main.tf` | `_ctx` `:18-23`, `ctx` `:26-28` | `iam_principals` (from `local.org_iam_principals`, `:43-47`) |
| `1-vpcsc/main.tf` | `_ctx` `:18-22`, `ctx` `:40-77` | `iam_principals` `:41-48`, `storage_buckets` `:76`, plus computed `identity_sets`, `project_numbers`, `resource_sets`, `service_sets` |
| `2-networking/main.tf` | `_ctx` `:17-21`, `ctx` `:34-59` | ten namespaces: `custom_roles` `:35`, `folder_ids` `:36`, `iam_principals` `:37-44`, `kms_keys` `:45`, `project_ids` `:46`, `storage_buckets` `:47`, `tag_keys` `:48`, `tag_values` `:49`, `tag_vars` `:50-57`, `vpc_sc_perimeters` `:58` |
| `2-security/main.tf` | `_ctx` `:18-22`, `ctx` `:30-53` | `custom_roles` `:31`, `folder_ids` `:32`, `iam_principals` `:35-40`, `project_ids` `:41`, `storage_buckets` `:42`, `tag_keys` `:43`, `tag_values` `:44`, `tag_vars` `:45-52`, `vpc_sc_perimeters` `:53` |
| `3-secops-dev/main.tf` | `local.context` `:53-59` | `custom_roles` `:54`, `folder_ids` `:55`, `iam_principals` `:56`, `kms_keys` `:57`, `project_ids` `:58`; no defaults-file merge |
| `2-project-factory/main.tf` | `_context` `:20-23`, `context` `:24-26`; module merge `:83-120` | twelve namespaces plus the second writer at `:107-109` |

**This is what `context.tf` replaces.** It is not a new merge; it is the sixth copy of one, deduplicated.

### 1.13 The consumer side, once

Every consumer column above was checked twice at `7d957ca5f`, by two reads of the same eight `variables-fast.tf` files — mine by grep, qwen's by an independent walk (room #72) — and the list was then re-derived a third time with a declaration parser after qwen left the room, which returns the same 25 names with the same per-stage sets. The first two reads share an instrument class, so their agreement is one check rather than two; the third is a different instrument and is corroboration of the name list, not of the line numbers. It is worth printing once because it is also the deletion list per stage. The 25 names any stage declares: `_fast_debug`, `automation`, `billing_account`, `certificate_authority_pools`, `custom_roles`, `folder_ids`, `host_project_ids`, `iam_principals`, `kms_keys`, `logging_sinks`, `organization`, `perimeters`, `prefix`, `project_ids`, `project_numbers`, `regions`, `root_node`, `service_accounts`, `storage_buckets`, `subnet_self_links`, `tag_keys`, `tag_values`, `tag_vars`, `universe`, `vpc_self_links`. Of those, ten are already module `context` namespaces (`custom_roles`, `folder_ids`, `iam_principals`, `kms_keys`, `project_ids`, `project_numbers`, `regions`, `storage_buckets`, `tag_keys`, `tag_values`), four are converted by hand inside a consumer (`host_project_ids`→`project_ids`, `perimeters`→`vpc_sc_perimeters`, `subnet_self_links`→`condition_vars`, `service_accounts`→`iam_principals`), and the rest are what §1 calls first-class. `0-org-setup` is the only root with no `variables-fast.tf`, having nothing upstream to read.

---

## 2. The shared `context.tf`

### 2.1 What the file holds

The file holds the four role variables **and** the aggregation, so that a stage opts out by deleting one file. Content, identical in every stage and add-on:

```hcl
/**
 * Copyright 2026 Google LLC
 * ... (standard boilerplate) ...
 */

# tfdoc:file:description FAST role variables and context aggregation.

variable "fast_networking" {
  description = "Context published by the networking role."
  type        = object({ ... })   # see §2.5
  default     = {}
  nullable    = false
}

variable "fast_org" {
  description = "Context published by the organization setup role."
  type        = object({ ... })
  default     = {}
  nullable    = false
}

variable "fast_security" {
  description = "Context published by the security role."
  type        = object({ ... })
  default     = {}
  nullable    = false
}

variable "fast_vpcsc" {
  description = "Context published by the VPC-SC role."
  type        = object({ ... })
  default     = {}
  nullable    = false
}

locals {
  _fast_ctx = {
    for k, v in var.context : k => merge(
      try(var.fast_org[k], {}),
      try(var.fast_vpcsc[k], {}),
      try(var.fast_networking[k], {}),
      try(var.fast_security[k], {}),
      v,
      try(local.context_defaults[k], {})
    )
  }
  # the one object-valued namespace: merge is shallow, so the loop above would
  # replace the producer's sub-maps with the empty ones var.context materialises
  fast_ctx = merge(local._fast_ctx, {
    tag_vars = {
      organization = merge(
        try(var.fast_org.tag_vars.organization, {}),
        try(var.fast_vpcsc.tag_vars.organization, {}),
        try(var.fast_networking.tag_vars.organization, {}),
        try(var.fast_security.tag_vars.organization, {}),
        var.context.tag_vars.organization,
        try(local.context_defaults.tag_vars.organization, {})
      )
      projects = merge(
        try(var.fast_org.tag_vars.projects, {}),
        try(var.fast_vpcsc.tag_vars.projects, {}),
        try(var.fast_networking.tag_vars.projects, {}),
        try(var.fast_security.tag_vars.projects, {}),
        var.context.tag_vars.projects,
        try(local.context_defaults.tag_vars.projects, {})
      )
    }
  })
}
```

**Why that second block exists — a defect in the loop, found by qwen (room #85).** `merge` is shallow: it replaces a top-level key rather than recursing. For a namespace whose value is a map that is exactly right, and `merge(role_value, {})` with an unset user value is the identity, which is the case for every `optional(map(...), {})` namespace in the tree, `condition_vars` included. It is wrong for the one namespace typed as an *object*, because an unset object is not `{}` — `optional(object({ projects = optional(map(map(string)), {}), organization = optional(map(string), {}) }), {})` converts to `{ projects = {}, organization = {} }` (`fast/stages/2-networking/variables.tf:30-33`, and identically in `2-security`, `2-project-factory`, `0-org-setup` and `modules/project-factory`). The loop merges that materialised empty object over the producer's, and the producer's tag maps are gone in every stage with no error.

Today's code does not have the bug because it merges one level down, per sub-key: `organization = merge(var.tag_vars.organization, local._ctx.tag_vars.organization)` at `2-networking/main.tf:50-57`, `2-security/main.tf:45-52`, `2-project-factory/main.tf:111-118`. The second block above reproduces exactly that, in the same order (role, then `var.context`, then the defaults file). What it protects is not a placeholder: stage 0 derives `organization` from deployed tag keys (`0-org-setup/output-files.tf:58-63`) and `projects` from the factory (`:53-57`), and while `modules/project-factory/automation.tf:157-161` rebuilds `projects` from its own data, `organization = try(local.ctx.tag_vars.organization, {})` there takes whatever arrives — an empty map if this is left to the loop.

**The exception reads all four roles, in the order of §2.2, and that is deliberate.** Reading `fast_org` alone would be correct today — stage 0 is `tag_vars`' only publisher — and would be silently wrong the day a second role publishes it, because under the canonical-union shape of §2.5, `var.fast_networking.tag_vars` exists and defaults to `{ projects = {}, organization = {} }`, which the block would then ignore. With all four roles written out, the exception is the loop with the depth fixed: absent attributes are absorbed by `try()` under narrow role types, and an empty object merges as the identity under union ones. It is six repetitive lines, and they are the price of the block's correctness not depending on §6.1's unresolved choice (qwen, room #99).

Two properties do the work. The loop is over `var.context`, so the stage's `context` type stays the statement of what the stage requires — a namespace the stage does not declare is invisible to it, whatever the roles publish. And `try(var.fast_x[k], {})` tolerates a role that publishes nothing in a namespace, which is the normal case.

The `try(local.context_defaults[k], {})` line is the one per-stage coupling. Three options, and the plan now takes **(a)** — this is muse's catch in room #89, and the reason is the `tag_vars` exception directly above:

- **(a)** — **recommended** — `context.tf` merges the roles, `var.context` and the defaults context, all in the one file; every stage declares `local.context_defaults` (one line, taken from the defaults object it already decodes, or `{}` where it decodes none) and its `_ctx` local becomes an alias, `_ctx = local.fast_ctx`, so every downstream `local.ctx` reference keeps working untouched. Cost: one extra line per stage, and `context.tf` breaks loudly wherever the line is missing.
- **(b)** — the smaller diff, and it does not survive `tag_vars`. With the defaults merge left in the stage's loop, that loop runs `merge(v, defaults[k])` one level up over a `fast_ctx` whose `tag_vars` is already the correctly merged object, and `v` for a defaults file that says nothing about tags is again `{ projects = {}, organization = {} }` — the same wipe, one level down, in every stage instead of in one file. Keeping (b) would mean repeating the two-level exception in every stage's `main.tf`. It was the first draft's choice, and the exception is what showed it was wrong.
- **(c)** pass the defaults context in as a fifth role-like variable. Consistent, but it makes the file merge something no role publishes and hides a user-facing input behind a role-shaped name.

What (a) costs per stage is two lines: `context_defaults = try(local._defaults.context, {})` (or the stage's own local name — `2-project-factory` decodes to `local.defaults`, `main.tf:22`, `:27`) and `_ctx = local.fast_ctx`. Two stages still need a hand:

- **0-org-setup** reads `var.context` a second time outside its loop, at `main.tf:45` inside `local.iam_principals = merge(local.org_iam_principals, var.context.iam_principals, try(local._defaults.context.iam_principals, {}))` (`:43-47`); that local feeds `of_ctx.iam_principals` (`output-files.tf:31-37`) and the whole stage, so it becomes `local.fast_ctx.iam_principals`, and its third argument is then redundant — the defaults are already inside `fast_ctx` — though harmless to leave.
- **3-secops-dev** decodes no defaults file at all (`grep -n 'yamldecode\|_defaults' fast/stages/3-secops-dev/main.tf` is empty), so its `context_defaults` is `{}` and its five-line `local.context` block (`main.tf:53-59`) collapses to `context = local.fast_ctx`.

### 2.2 Merge order

`fast_org` → `fast_vpcsc` → `fast_networking` → `fast_security` → `var.context` → `defaults.context`. Last writer wins, per namespace, inside one `merge`.

The evidence for the user and defaults positions is existing behaviour: `merge(var.custom_roles, local._ctx.custom_roles)` at `2-networking/main.tf:35` puts user context above the stage's own input, and `merge(v, try(local._defaults.context[k], {}))` at `:18-21` puts the defaults file above both. The user-contract statement in the ADR — "a user adds one entry to `var.context` and it wins, whichever stage produced the original" — is what that order already does.

The order *between roles* matters for exactly one namespace today: `project_ids`, published by `fast_org` and `fast_networking`, with networking winning at `2-project-factory/main.tf:107-109` (`merge(var.project_ids, var.host_project_ids, local.context.project_ids)`). Ordering the roles as the chain runs reproduces that and gives a rule for the next collision. Every other namespace has one publisher:

| namespace | publishing role(s) |
| --- | --- |
| `custom_roles`, `folder_ids`, `iam_principals`, `project_ids`, `project_numbers`, `storage_buckets`, `tag_keys`, `tag_values`, `tag_vars`, `workload_identity_providers` | `fast_org` (`project_ids` also `fast_networking`) |
| `vpc_sc_perimeters` | `fast_vpcsc` |
| `project_ids`, `subnet_ips`, `subnet_self_links`, `subnet_proxy_only_self_links`, `subnet_psc_self_links`, `vpc_self_links` | `fast_networking` |
| `ca_pools`, `kms_keys` | `fast_security` |

### 2.3 What stays in each stage after the change

Only the additions that are not role data. In 2-networking that is the `iam_principals` entries built from `var.service_accounts` (`main.tf:37-44`); the other ten lines of the block at `:34-59` become role merges. In 1-vpcsc the computed sets stay (`identity_sets` `:49-53`, `project_numbers` `:54`, `resource_sets` `:55-69`, `service_sets` `:70-75`). In 0-org-setup the `iam_principals` merge with `local.org_iam_principals` stays (`:26-28`, `:43-47`). Under §2.1's choice (a) the loop itself is gone from every stage — `_ctx = local.fast_ctx` — so the per-namespace `merge(var.X, ...)` lines disappear while the stage's own computed additions stay inside the `ctx = merge(local._ctx, {...})` block.

**The renamed namespaces, and where the rename lives.** The generic loop only merges namespaces that already have the same name on both sides, so the two renames need a home, and putting it in the producer is what makes the consumer lines disappear:

- `perimeters` → `vpc_sc_perimeters`. 1-vpcsc writes `fast_vpcsc = { vpc_sc_perimeters = { ... } }` — the attribute in the role variable is already the namespace name — so the four consumer lines (`2-networking/main.tf:58`, `2-security/main.tf:53`, `2-project-factory/main.tf:25` and `:119`) are deleted, not rewritten. The alternative, keeping `fast_vpcsc.perimeters` and renaming in each consumer, costs four copies of one line and is the state the ADR is trying to end.
- `host_project_ids` → `project_ids`. 2-networking writes `fast_networking = { project_ids = { ... } }`, so `2-project-factory/main.tf:107-109` collapses to the role order in §2.2. In the add-ons the same value arrives as `local.fast_ctx.project_ids` and keeps its lookup shape (`addons/2-networking-test/context.tf:41` becomes `lookup(local.fast_ctx.project_ids, v.project_id, v.project_id)`) — the lookup does not disappear, only its source.
- `service_accounts` → `iam_principals[...]` is **not** a rename and stays in the consumer: `service_accounts` is a first-class value (§1.10) and the derivation runs where the value is used (`1-vpcsc/main.tf:41-48`, `2-networking/main.tf:37-44`, `2-project-factory/main.tf:96-103`). Anyone trimming the `ctx` blocks should keep these three sites. Folding the derivation into the producer instead would delete all three; it changes what stage 0 publishes, so it is a decision (§6.4), not part of this plan.

Everything else in the six `ctx` blocks of §1.12 is either a same-name role merge, which the loop does, or a value the stage computes itself.

### 2.4 The `var.context` type each stage ends up declaring

Unchanged for every stage, because the type is the requirement statement and role-carried namespaces are still required. Ranges are the `type` expression, from `type = object({` to its closing `})`; the `variable` block starts one line earlier and ends three lines later (for 1-vpcsc, the block is `variables.tf:73-86` and the type expression `:75-82`) — muse checked the ranges against `grep -n '^variable'` in room #62, and this note is why the two answers differ rather than disagree:

| stage | namespaces declared in `var.context` | source |
| --- | --- | --- |
| 0-org-setup | access_levels, cidr_ranges_sets, custom_roles, email_addresses, folder_ids, iam_principals, locations, kms_keys, notification_channels, project_ids, service_account_ids, tag_keys, tag_values, tag_vars, vpc_host_projects, vpc_sc_perimeters, workload_identity_pools, workload_identity_providers | `variables.tf:19-41` |
| 1-vpcsc | iam_principals, identity_sets, project_numbers, resource_sets, service_sets, storage_buckets | `variables.tf:75-82` |
| 2-networking | cidr_ranges_sets, custom_roles, email_addresses, folder_ids, kms_keys, iam_principals, locations, project_ids, storage_buckets, tag_keys, tag_values, tag_vars, vpc_sc_perimeters | `variables.tf:19-36` |
| 2-project-factory | cidr_ranges_sets, condition_vars, custom_roles, email_addresses, folder_ids, iam_principals, kms_keys, locations, notification_channels, project_ids, tag_values, tag_vars, vpc_host_projects, vpc_sc_perimeters | `variables.tf:19-37` |
| 2-security | condition_vars, email_addresses, custom_roles, folder_ids, iam_principals, locations, project_ids, storage_buckets, tag_keys, tag_values, tag_vars, vpc_sc_perimeters | `variables.tf:19-35` |
| 3-secops-dev | custom_roles, folder_ids, iam_principals, kms_keys, project_ids | `variables.tf:19-25` |

Add-ons and extras declare no `context` today. The add-ons need one if their reference-shaped inputs move (§3.2); the extras need nothing, since they are outside the chain.

### 2.5 The role variable types — the shape question

The set of namespaces a union would cover is the namespaces with **at least one publisher** — §3.1's map — not every key a stage declares. `access_levels`, `cidr_ranges_sets`, `condition_vars`, `email_addresses`, `locations`, `notification_channels`, `service_account_ids`, `vpc_host_projects` and `workload_identity_pools` are declared in stage `context` types and written by nobody; they stay valid there for a standalone user filling in their own values, and they get no role slot until a producer exists. Without that rule a union pulls eight unpublished namespaces into every role object in every stage.

HCL has no type aliases, so a namespace's type can be written once per variable but never once per repository. Both shapes below keep `context.tf` byte-identical from stage to stage, because a role's type is fixed either way — identity of the file is not an argument for the union, even though it is tempting to make it one. Two shapes:

- **Narrow roles.** `fast_org` declares only what stage 0 publishes, `fast_networking` only what 2-networking publishes, and so on. `project_ids` is then typed twice, in two role variables in the same file, and the two declarations have to agree by hand. Cheapest to read, no role carries dead namespaces.
- **Canonical union.** Every role variable declares the same namespace set, all `optional(..., {})`. One union type, copied four times inside one file, and it becomes the vocabulary: a producer writing a namespace outside it should fail on the consumer side. *Unsourced:* whether an object-typed variable rejects unknown attributes for tfvars input is assumed here, not verified — probe §5.3. Cost if it does not reject: the union becomes documentation, not enforcement. Second cost: every stage carries four objects with ~20 optional attributes each, in generated docs and `terraform` plan files.

Either way, the four role variables live in `context.tf`, which is the file registered as a duplicate in `tools/duplicate-diff.py` so CI keeps the copies identical (§6.1).

---

## 3. Change list

### 3.1 Producer → namespace map

| published today | published after | published by | note |
| --- | --- | --- | --- |
| `custom_roles`, `folder_ids`, `iam_principals`, `project_ids`, `project_numbers`, `storage_buckets`, `tag_keys`, `tag_values`, `tag_vars`, `workload_identity_providers` | `fast_org.<same name>` | 0-org-setup | flat renames |
| `perimeters` | `fast_vpcsc.vpc_sc_perimeters` | 1-vpcsc | rename (§1.1) |
| `host_project_ids` | `fast_networking.project_ids` | 2-networking | the ADR's example; the merge at `2-project-factory/main.tf:107-109` becomes the role order |
| `subnet_ips`, `subnet_proxy_only_self_links`, `subnet_psc_self_links` | `fast_networking.<same name>` | 2-networking | names unchanged (§6.4) |
| `vpc_self_links` | `fast_networking.networks` | 2-networking | renamed to the name the modules and the stage's own factories already use (§6.4) |
| `subnet_self_links` | `fast_networking.subnets` | 2-networking | renamed; the reshape from nested to flat and the key convention are left for development (§6.4) |
| `ca_pools`, `kms_keys` | `fast_security.<same name>` | 2-security | |
| `automation`, `logging_sinks`, `service_accounts`, `billing_account`, `groups`, `organization`, `prefix`, `universe` | unchanged, first-class | 0-org-setup | |
| `ngfw`, `security_profile_groups`, swp's four keys, extras' `clone` | unchanged, first-class, no consumer | add-ons, extras | |

`host_project_numbers` deliberately has no row here. Mapping it to `fast_networking.project_numbers` would create a second order-dependent namespace the day stage 0 also has a `project_numbers` to publish, with no consumer merge to say which wins (§2.2's "exactly one" would stop being true by construction, and the only thing keeping it true would be that the two key sets happen to be disjoint). Nothing consumes the value. Keep it flat or delete it (§6.4); muse raised this in room #62 and the row was struck.

### 3.2 Per stage

| stage | files touched | variables added | variables removed | outputs moved |
|---|---|---|---|---|

Every row's `main.tf` change includes the same two lines from §2.1's choice (a) — `context_defaults = ...` and `_ctx = local.fast_ctx` — and the cells below name the block each stage currently has so the diff is checkable; they do not repeat those two lines.
| **0-org-setup** | `context.tf` (new), `main.tf` (the direct `var.context` read at `:45` plus the standard two lines, §2.1a), `output-files.tf` (`of_tfvars.org-setup` at `:127-153` gains `fast_org`), `README.md` (tfdoc) | `fast_org`, `fast_vpcsc`, `fast_networking`, `fast_security` (via `context.tf`) | none | `output "tfvars"` `outputs.tf:41` shape changes; inventories assert it as `__missing__`, so no churn |
| **1-vpcsc** | `context.tf` (new), `main.tf` (`_ctx` `:18-22` loop source, `ctx` `:41-48`, `:76`), `variables-fast.tf` (delete 4), `outputs.tf` (`local.tfvars` `:18-23` gains `fast_vpcsc`), `README.md` | as above | `iam_principals` `variables-fast.tf:17`, `project_ids` `:59`, `project_numbers` `:67`, `storage_buckets` `:97` | `output "tfvars"` `:52` shape changes |
| **2-networking** | `context.tf` (new), `main.tf` (`_ctx` `:17-21`, `ctx` `:34-59`), `variables-fast.tf` (delete 10), `outputs.tf` (`local.tfvars` `:18-40` gains `fast_networking`), `README.md` | as above | `custom_roles` `:25`, `folder_ids` `:33`, `iam_principals` `:41`, `kms_keys` `:50`, `perimeters` `:67`, `project_ids` `:85`, `storage_buckets` `:101`, `tag_keys` `:109`, `tag_values` `:117`, `tag_vars` `:125` | none — **but `main.tf:36` needs an explicit decision, not a deletion** |
| **2-project-factory** | `context.tf` (new), `main.tf` (`_context` `:20-23`, module `context` `:83-120` — `:107-109` collapses), `variables-fast.tf` (delete 10), `README.md` | as above | `custom_roles` `:34`, `folder_ids` `:42`, `host_project_ids` `:58`, `iam_principals` `:50`, `kms_keys` `:66`, `perimeters` `:84`, `project_ids` `:102`, `subnet_self_links` `:118`, `tag_values` `:126`, `tag_vars` `:134` | none |
| **2-security** | `context.tf` (new), `main.tf` (`_ctx` `:18-22`, `ctx` `:30-53`), `variables-fast.tf` (delete 9), `outputs.tf` (`local.tfvars` `:26-37` gains `fast_security`), `README.md` | as above | `custom_roles` `:25`, `folder_ids` `:33`, `iam_principals` `:41`, `perimeters` `:49`, `project_ids` `:67`, `storage_buckets` `:83`, `tag_keys` `:91`, `tag_values` `:99`, `tag_vars` `:107` | `output "tfvars"` `:76` shape changes |
| **3-secops-dev** | `context.tf` (new), `main.tf` (`local.context` `:53-59` collapses to `context = local.fast_ctx`; `context_defaults = {}`, §2.1a), `variables-fast.tf` (delete 5), `README.md` | as above | `custom_roles` `:35`, `folder_ids` `:43`, `iam_principals` `:51`, `kms_keys` `:59`, `project_ids` `:74` | none |

One line in 2-networking is inconsistent today, and the migration would change what it does. `main.tf:36` reads `folder_ids = merge(var.folder_ids, var.context.folder_ids)` while the line above it reads `local._ctx.custom_roles` and the parallel line in 2-security (`main.tf:32`) reads `local._ctx.folder_ids`. `local._ctx` is `var.context` merged with the defaults file (`:18-21`), so a `folder_ids` entry supplied in networking's `defaults.yaml` is dropped from the merged namespace today — while the VPC parent lookup two lines later reads the first-class `var.folder_ids` directly (`:86-87`). Found by qwen (room #72), who marks the "unintended" judgement as unsourced; the file difference is sourced.

**The implementer instruction is not "delete the line".** The shape of the inconsistency: `:36` reads `var.context.folder_ids` where the line above reads `local._ctx.custom_roles`, so a `folder_ids` entry in networking's `defaults.yaml` is dropped from `local.ctx.folder_ids` today, while the VPC parent lookup two lines later reads the first-class `var.folder_ids` directly (`:86-87`). If the current behaviour is the intended one, the only faithful rewrite is `folder_ids = merge(var.fast_org.folder_ids, var.context.folder_ids)`; if it is not, the line goes and the loop merges the defaults file. Per room #139 the verdict waits for development — what the plan owes is the shape and the two rewrites, and probe §5.8 to measure which one is in force. Muse flagged this as the one item in the change list that is load-bearing for whoever implements it (room #73).

What every stage keeps in `variables-fast.tf`: `automation`, `billing_account`, `logging_sinks`, `organization`, `prefix`, `root_node`, `service_accounts`, `universe` — whichever of them that stage declares.

**2-project-factory is the only stage where a namespace merge order changes**: `host_project_ids` disappears as a consumer-side variable and `fast_networking.project_ids` is merged by `context.tf` in role order, which reproduces `:107-109` if the order is `fast_org` before `fast_networking`.

### 3.3 Per add-on

- **2-networking-ngfw**: `context.tf` (new; the name collides, see below), `variables.tf` (new `context` variable: `project_ids`, `vpc_self_links`, `ca_pools` — whatever §6.2 decides), `variables-fast.tf` (delete `host_project_ids` `:49`, `vpc_self_links` `:67`, `certificate_authority_pools` `:37`), `tls-inspection.tf:19-23` (`var.certificate_authority_pools` → context), `ngfw.tf:25` and elsewhere (`var.vpc_self_links` → context), `README.md`. `automation` and `organization` stay first-class. This also resolves §1.11's name mismatch, because both sides then say `ca_pools`.
- **2-networking-swp**: `context.tf` (new), `context` variable added (`project_ids`, `networks`, `subnets`, `locations` — the names §6.4 settles on), `variables-fast.tf` delete `host_project_ids` `:37`, `subnet_self_links` `:53`, `vpc_self_links` `:61`, `regions` `:45`, `main.tf:19`, `:60` and `:60`'s neighbours, `README.md`.
- **2-networking-test**: rename the existing `context.tf` first. That file (`:17-59`) holds locals that derive instances, subnets and service-account emails from `var.host_project_ids`, `var.vpc_self_links` and `var.subnet_self_links`. Either the shared file takes a different name (`fast-context.tf` is the obvious one) or the add-on's locals move (to `locals.tf` — the repo already prefers descriptive names, and `context.tf` would then mean one thing everywhere). Then: `context` variable added, three `variables-fast.tf` declarations deleted, `main.tf:20` and `context.tf:41-59` changed to read the merged context, `README.md`.
- **Adopt or not:** nothing in the ADR requires add-ons to move. An add-on can keep its first-class variables forever and still work, because both are written by the same tfvars directory. The reason to move them is §1.11: today two of the three add-ons declare a source that nothing publishes.

### 3.4 Extras

No change. They are outside the chain, publish `clone` only, and gain nothing from role variables. Their `organization` and `groups` variables remain name collisions with the globals file (§1.9) — invisible until someone loads both into one root.

### 3.5 Tests and docs

- **Test tfvars**: 20 of the 25 files under `tests/fast/{stages,addons}/*/*.tfvars` set a role-published variable at line start (`grep -l '^\(project_ids\|folder_ids\|...\)'`), a lower bound because indented and `context`-block uses are not counted. Each needs the same edit the stage's own examples get: the value moves under `fast_org` / `fast_networking` / `fast_security` / `fast_vpcsc`. The five that do not are the `s0_org_setup` ones, which have no upstream.
- **Test inventories**: only four mention moved names — `host_project_ids` in `tests/fast/stages/s2_networking/fw_policies.yaml` and `vlan_attachments.yaml`, `subnet_self_links` in those two plus the five `s0_org_setup` inventories, `ca_pools` in `tests/fast/stages/s2_security/simple.yaml:464` and `service_agent.yaml:120`. Regenerate rather than hand-edit (`pytest -s '<test id>'` writes the inventory).
- **READMEs**: `python3 tools/tfdoc.py --replace fast/stages/<stage>` for every touched stage and add-on, then `python3 tools/check_documentation.py`. The variables tables will show four new `fast_*` variables and the deleted ones.
- **`tools/duplicate-diff.py`**: add a group listing every `context.tf` copy (§6.1). Without it the copies drift, which is the failure mode the file's identity depends on.
- **`adrs/fast/stage-outputs-context.md`**: status `Proposed` → `Accepted` is the human's edit, not ours.

---

## 4. Migration sequence

The constraint that shapes everything: Terraform fails with "Value for undeclared variable" when a tfvars file assigns a variable the root module does not declare, and silently replaces a variable when two files assign it. So a new file may only be written once every root that loads it declares the new variable, and a declaration may only be deleted once every producer has stopped writing the old key.

### 4.1 One release, one clean cut

**Decided, room #139: no backward compatibility.** The ADR's "stages can write the old and the new files together for one release" is not taken. Every deployment migrates its tfvars directory in one release, which is the cost the ADR's consequences section already accepts; the dual-write apparatus, the second output object and the half-upgraded-tree analysis that went with them are dropped from this plan. What survives is §4.5, because the file lists are how a stage receives its inputs at all.

1. **Declare.** `context.tf` in every stage and add-on: the four role variables and the merge. Two probes gate this rather than ride along: §5.1 (does the dynamic index typecheck) and §5.6 (does the loop empty `tag_vars`).
2. **Producers replace, they do not add.** `0-org-setup.auto.tfvars.json` carries `fast_org = {...}` where it carried the flat `project_ids`, `folder_ids`, `iam_principals`, …; `2-networking.auto.tfvars.json` carries `fast_networking = {...}` where it carried `host_project_ids`, `vpc_self_links`, …; `2-security.auto.tfvars.json` carries `fast_security` for `ca_pools`/`kms_keys`; `1-vpcsc.auto.tfvars.json` carries `fast_vpcsc.vpc_sc_perimeters` for `perimeters`. One writer per variable, and because the file names do not change no `.fast-stage.env` entry moves for a producer. `0-globals.auto.tfvars.json` is untouched.
3. **Consumers switch in the same release.** The `ctx` block reads `local.fast_ctx` instead of `merge(var.X, ...)`, the legacy declarations leave `variables-fast.tf`, and a consumer whose link list does not already name a producer it reads gets that entry — `3-secops-dev` is the known case (§4.5: its `.fast-stage.env` omits `2-security` while it declares `kms_keys` from it).
4. **Tests and docs in the same commit** as the stage they describe (§3.5), README tables regenerated.
5. **The ADR follows**: status Proposed → Accepted, and the consequences line about a survivable migration is replaced by the one-release cut.

### 4.2 What a partial upgrade does now

Two directions, and they are not symmetrical:

- **Producer moved, consumer not.** The consumer links a file that assigns `fast_org`, which it does not declare: a hard "Value for undeclared variable", at plan time, naming the variable.
- **Consumer moved, producer not.** `fast_ctx` merges an absent role as `{}` and the legacy keys are no longer read, so the stage plans with empty maps and no error at all.

So the release is taken as a whole — that is what a clean cut means in practice — and the release note says upgrade the tree, not the stage. The silent direction is the one worth writing down, because every variable in the deletion lists carries `default = {}` (an awk pass over the five `variables-fast.tf` files; only `automation`, `billing_account`, `organization` and `prefix` lack one, and none of those is deleted), so nothing complains about an empty upstream.

### 4.3 What was considered and dropped

Kept in one paragraph because the analysis is reusable if backward compatibility is ever wanted, and because it is the reason the decision is cheap rather than assumed. A dual-write release would put the role variables in their own `<stage>-ctx.auto.tfvars.json` rather than in the existing file, which is safe in one direction only: `fast-links.sh` links what `.fast-stage.env` names and nothing else (`:69-72`, `:81-84`), so an unupgraded consumer never loads the new object, but a consumer naming an object its producer has not written gets a dangling symlink or a failed copy. That makes the order producers-first and adds one object per producer plus one line per consumer in `.fast-stage.env`; keeping the new variable in the existing file instead makes the opposite direction fail loudly. Neither is needed here, and the ADR's own consequences section already prices the alternative — that every existing deployment migrates its tfvars directory.

### 4.4 Rollback

The release is atomic, so rollback is the same operation reversed: restore the producers' flat keys and the consumers' declarations and `ctx` block together, one commit per stage. There is no intermediate state to unwind because there is no intermediate state.

### 4.5 How the files reach a stage

The files a stage loads are listed in its own `.fast-stage.env`, and under a clean cut (§4.1) this mechanism matters more than it did under a dual write, because the link list is the only thing that decides what a stage sees.

`fast/stages/fast-links.sh` sources a per-stage `.fast-stage.env` (`:51` requires it, `:56` sources it) and prints one download command per entry of `FAST_STAGE_DEPS` (`:68-77`, the loop at `:70-76`) and of `FAST_STAGE_OPTIONAL` (`:82-86`); the entries are stage file names. There are eight such files: `.fast-stage.env` in each of the six stages, in `2-networking-ngfw`, and in `2-networking-test`. `2-networking/.fast-stage.env` reads `FAST_STAGE_DEPS="0-globals 0-org-setup"` and `FAST_STAGE_OPTIONAL="1-vpcsc 2-networking-ngfw"`; `2-networking-ngfw` adds `2-security` as optional.

Consequences, of which the second is now an implementation step rather than a migration option:

- **`FAST_STAGE_OPTIONAL` is not "load it if it is there".** The two lists are emitted by the same command: the body of the DEPS loop (`:70`) and of the OPTIONAL loop (`:82`) is the same `echo "$CMD/tfvars/$f.auto.tfvars.json ./", and both go through the same`ln -s` or `gcloud storage cp` chosen at `:39` and `:44`. A name in either list is linked whether or not the producer has written the object, and a link to a missing object is a dangling`*.auto.tfvars.json` symlink that Terraform then fails to read (a bucket source fails one step earlier, at the copy). Muse suggests the new objects belong in `FAST_STAGE_OPTIONAL` (room #79) in the expectation that it means "load if present"; mechanically it does not, so producer-first holds for either list — which is why §4.3 states the order rather than relying on which list a user picks.
- **The link lists already drift, and under a clean cut that is a defect to fix in the same release.** `3-secops-dev/.fast-stage.env` carries only `FAST_STAGE_DEPS="0-globals 0-org-setup"` and no OPTIONAL entry, yet that stage declares `kms_keys` with source `2-security` (`variables-fast.tf:59`) and reads it (`main.tf:57`) — after the cut it declares `fast_security` and must name `2-security`, or it plans with an empty `kms_keys` and no error at all (§4.2). A user following the generated script for secops-dev gets nothing from the bucket today and has to copy the file by hand (muse, room #79).
- **The dual-write shapes are moot.** (A) role data in the file a consumer already links, and (B) its own `<stage>-ctx` object, existed to let an unupgraded consumer keep working; §4.1 drops both, so the only thing the link list has to get right is that a consumer names every producer it reads.
- **`fast/addons/2-networking-swp` has no `.fast-stage.env` at all**, so `fast-links.sh` cannot link it and its inputs are fetched by hand — which means a `context.tf` there (§3.3) changes nothing about how its inputs arrive, and nobody should assume the script covers it. *Unsourced:* whether the omission is deliberate is stated nowhere I found.
- **`fast/addons/2-networking-test` has one** (`FAST_STAGE_DEPS="2-networking"`) but writes no tfvars file (§1.8), so it appears in the link output as a consumer that publishes nothing.

---

## 5. Probes

Nothing here was run. Each probe names the command and the result that would change the plan.

1. **The role merge typechecks — gate, run before code.** `terraform validate` (or `plan`) in `fast/stages/2-networking` after step 1 of §4.1. This is the plan's one language-level assumption: that `try(var.fast_org[k], {})` with `k` a dynamic string over an object-typed variable is valid and returns `{}` for an attribute the role does not declare, and that `merge` of the four results plus `var.context`'s value keeps its type. The state of the evidence, after qwen's pass and a second one of mine (room #92 and below):
   - **The loop half is proven in-tree.** `2-networking/main.tf:17-21` is a `for k, v in var.context` over the declared heterogeneous object at `variables.tf:19-36`. What it indexes inside the body is `local._defaults.context[k]`, a `yamldecode` result, which the checker treats structurally — so the precedent proves the loop and not the dynamic index into a *declared* object. qwen is right about that, and it is the reason this stays a probe.
   - **The dynamic index into a declared object has one live site**, which qwen's zero-hit grep missed and both my run and muse's re-run found with the same pattern (`grep -rnE 'var\.[a-z_.]+\[[a-z_]*(key|k|kk|v|vv)\]' modules fast` returns three lines, not none): `modules/vpc-sc/factory.tf:26` and `:28` index `var.factories_config[k]` where `k` ranges over a literal four-string list and `factories_config` is `object({ access_levels = optional(string), egress_policies = ..., ingress_policies = ..., perimeters = ... })` at `modules/vpc-sc/variables.tf:190-200`. That is the same syntax in a tested module, so the **syntactic half is proven**: validate accepts `var.obj[k]` with a non-literal key. What it does not cover is the other half — `k` iterates a literal list rather than another variable's keys, every attribute exists (as `null`), and there is no `try()`, so a missing attribute would error there and never does. The unrun surface is therefore narrower than "the idiom": `try()` on an attribute the object does not declare, which is standard `try` runtime semantics plus whatever validate statically does with a key it cannot prove present. Muse's framing (room #93) and the right one for this probe.
   - **Every dynamic key lookup in the tree otherwise goes through a map**, in numbers that are larger than the first pass reported: `grep -rnE 'lookup\(var\.' modules fast --include='*.tf'` returns 28 sites, and `try(var.iam[role], [])` alone appears in eighteen `iam.tf` files, alongside `lookup(var.configmanagement_templates, ...)` at `modules/gke-hub/main.tf:21` over `map(object({...}))` and `lookup(var.service_iam, ...)` at `modules/service-directory/main.tf:66` over `map(map(list(string)))`. Those prove the map path, which is not the shape proposed — but they make the map alternative (§6.1) the one with a large body of working precedent behind it.

   Fallbacks, and they differ in the thing §6.1 asks about: (i) a per-namespace `try(var.fast_org.project_ids, {})` chain written out in full — keeps the type statement, loses the one-line loop; (ii) type the role variables `map(any)` — keeps the loop and the twelve in-tree precedents for map indexing, and gives up the type statement entirely. §6.1 and this probe are one decision wearing two hats.
2. **The two-writer case resolves to networking.** `pytest 'tests/fast/stages/s2_project_factory/tftest.yaml::simple'` after §4.1. Result that changes the plan: if a `$project_ids:` reference in the dataset resolves to stage 0's value instead of networking's, the role order in §2.2 is wrong.
3. **Unknown-attribute rejection.** A one-off stage with an object-typed variable fed a tfvars file containing an extra attribute, then `terraform plan`. If Terraform accepts and drops it, the canonical-union shape in §2.5 is documentation rather than enforcement, and the vocabulary needs a different guard.
4. **`ca_pools` through the merge.** `pytest 'tests/fast/addons/a2_networking_ngfw/tftest.yaml::simple'` after the add-on moves to context, with a `certificate_authority_pools` value supplied (the current test leaves it empty, `tests/fast/addons/a2_networking_ngfw/simple.tfvars`). Result that changes the plan: if the map-of-objects namespace fails to survive `merge`, §6.2's "whole" option is not available.
5. **`regions` really has no producer.** `grep -rn '^regions' fast/ tests/ --include=*.tf --include=*.yaml --include=*.tfvars`. If a producer exists that this plan missed, §1.11 and §6.4 change.
6. **The merge is shallow, so object-valued namespaces need a line of their own — gate, run before code.** `terraform console` in any stage after an `init`: `merge({tag_vars={projects={p={k="v"}},organization={o="x"}}}, var.context.tag_vars)` with nothing set in `var.context`. Result that changes the plan: if both sub-maps come back empty, §2.1's second block is required and the loop cannot be the whole answer; if they come back as the producer's values, the exception is unnecessary and should be deleted rather than left as folklore. Reasoned but not run (rule 3) — the emptiness follows from Terraform's documented `optional(..., {})` materialisation and the documented shallowness of `merge`.
7. **Duplicate copies stay identical.** `python3 tools/duplicate-diff.py --all-files` after the `context.tf` copies are registered.
8. **`folder_ids` and the defaults file.** `pytest 'tests/fast/stages/s2_networking/tftest.yaml::simple'` after adding one `folder_ids` entry to the networking dataset's `defaults.yaml`, run once before and once after §4.2's switch. Result that changes the plan: if the entry is dropped before and honoured after, the migration carries a behaviour change that needs its own line in the release notes and a decision (§3.2, §6.4).

---

## 6. Decisions

**All but two are now decided (room #139), and each section below carries the decision at the top with the options kept underneath as the record of what was rejected and why.** The two still open are recorded in their sections as "at development time": the exact split of `ca_pools` (§6.2) and the `tag_vars` corner cases beyond the one this plan proved (§6.5). The first three sections are the rule 10 questions; the rest surfaced while building the change list.

### 6.1 Where a namespace's type is declared once for every publisher (rule 10)

**Decided (room #139): narrow role types, one per role, declaring only what that role publishes.** `fast_org` carries stage 0's namespaces, `fast_networking` 2-networking's, and the consumer's `var.context` continues to declare what that consumer requires, which is what it already does. The canonical-union option below is rejected because a consumer would then declare namespaces it never uses, which does not match what its `context` means; `map(any)` is rejected because this repository does not use it and because merging complex types through it is where it bites. `duplicate-diff.py` registration still applies — it is what keeps the several copies of the narrow declarations identical. Probe §5.1 stays a gate, because narrow types are exactly what makes the dynamic index necessary.

**This question is also §5.1's question, and the plan says so here because a reader choosing a shape is also choosing a language risk.** If the role variables are declared as objects that state what the role may publish, the merge needs `var.fast_role[k]` with a dynamic `k`, and the design rests on probe §5.1. If they are typed `map(any)`, the mechanics are the ones the tree already uses in the same idiom many times over (eighteen `try(var.iam[role], [])` sites, plus `lookup(var.…)` sites such as `modules/gke-hub/main.tf:21`), `try()` becomes `lookup(var.fast_role, k, {})` — the third argument doing the work — and §5.1 stops being load-bearing. The cost is exact: `map(any)` states nothing about what a producer may publish, which is the defect this section exists to fix, so it converts "declare the namespace type once for every publisher" into "declare it nowhere, as today". The one thing it does not lose entirely is enforcement at the point of use, since a module receiving `local.fast_ctx` still checks it against its own `context` type — but only for values a module actually consumes, and not for whatever stays in locals and templates. The union option's one other side effect is already neutralised: §2.1's `tag_vars` exception reads all four roles, so a second publisher of that namespace is not silently dropped, and the choice no longer has to answer for it.

Today nothing states what a producer may publish under a name: each namespace's type is declared wherever it is *consumed* (`modules/*/variables.tf`, and each stage's `context` type), and `project_ids` — published by stage 0 and, after the change, by networking — would be typed in two role variables.

A census of every stage's `context` type plus the module side gives one disagreement and two gaps. qwen ran the module side with a brace-matching parser over `modules/*/variables.tf` (room #72), a different instrument from my grep, so this is a check rather than a repetition: **45 modules declare `variable "context"`, holding 40 distinct namespace keys** — 31 `map(string)`, six `map(list(string))` (`cidr_ranges_sets`, `folder_sets`, `identity_sets`, `project_sets`, `resource_sets`, `service_sets`), one `map(map(string))` (`condition_vars`), one object (`tag_vars`), one `map(number)` (`project_numbers`) — and exactly one namespace is declared two ways across modules:

- **`project_numbers` is declared two ways, in five files.** `map(number)` at `fast/stages/1-vpcsc/variables.tf:78` and `modules/vpc-sc/variables.tf:139`; `map(string)` at `modules/project-factory/variables.tf:31`, `modules/folder/variables.tf:184` and `modules/billing-account/variables.tf:150`. The producer publishes numbers (`modules/project-factory/outputs.tf:160-164` maps `v.number`) and `0-org-setup/output-files.tf:136` publishes it unchanged. Terraform is assumed to convert number to string where the consumer's type demands it (*unsourced* — no run), which would make the disagreement harmless in practice; it is still the live instance of this question, in the tree, today. *(Corrected: an earlier version of this paragraph listed `modules/project/variables.tf:147` as a third string witness. That line is `project_ids` in the same `context` block, and `grep -rn '^    project_numbers *= ' modules/*/variables.tf fast/stages/*/variables.tf` returns five lines, none of them in `modules/project`. Muse caught it; `modules/billing-account/variables.tf:150` is the witness the first count had missed.)*
- **Four namespaces are declared nowhere**: `subnet_ips`, `subnet_self_links`, `vpc_self_links` and `ca_pools` appear in no stage's `context` type and no module's. They exist only as first-class variables. That is why §3.3 has the add-ons declare them: whichever channel they take, someone has to write their type down for the first time.
- **The same gap from the producer side**: `0-org-setup/factory.tf:39` reads `try(local.ctx.condition_vars.custom_roles, {})`, and `condition_vars` is not in stage 0's `context` type (`variables.tf:19-41`). The access sits inside `try()`, so it resolves to the fallback and nothing breaks — but it is a reader asking for a key nothing states it may carry, found by qwen (room #72). With the `project_numbers` disagreement above it is the same fact twice.
- Everything else agrees: `custom_roles`, `folder_ids`, `iam_principals`, `project_ids`, `storage_buckets`, `tag_keys`, `tag_values`, `kms_keys`, `vpc_sc_perimeters` are `map(string)` wherever declared; `tag_vars` is the same two-level object in all five places it appears (`0-org-setup/variables.tf:33-36`, `2-networking:31-34`, `2-project-factory:31-34`, `2-security:30-33`, `modules/project-factory/variables.tf:36-39`); `workload_identity_providers` is declared once, in `0-org-setup/variables.tf:40`, and no module consumes it.

qwen's table form of the same census (room #111) lists all forty namespaces with their module counts and declared types; the two findings it adds that decide anything are options in §6.4 (the `vpc_self_links`/`networks` mismatch and the `subnets`/`subnetworks` duplicate), and the table itself is not reproduced here because the plan is one file and the counts are the part that matters.

**The carrier for "declared once, copied, enforced" already exists, and it is used for `.tf` files.** `tools/duplicate-diff.py` holds an explicit list of path groups that must be byte-identical, and five of the groups are Terraform files rather than schemas: `bundle.tf`, `serviceaccount.tf`, `variables-serviceaccount.tf`, `variables-vpcconnector.tf` and `vpcconnector.tf`, each across `modules/cloud-function-v1`, `-v2` and `cloud-run-v2` (`tools/duplicate-diff.py:129-152`). The `variables-*.tf` ones carry a typed `variable` block with `optional()` defaults — `modules/cloud-run-v2/variables-serviceaccount.tf` is one `variable "service_account_config"` of that shape, three copies, byte-equal — so the mechanism is not limited to data files. It is enforced twice: `.pre-commit-config.yaml:135-137` and `.github/workflows/linting.yml:126` (`duplicate-diff --all-files`), failing with `[DIFF] Files are different: <a> <b>`. So the answer to this question is not "does a carrier exist" but "is `context.tf` registered in the list that already exists" — §2.5's subordinate clause, promoted here to the mechanism it is (qwen, room #104).

**Two limits, which narrow what is being chosen.** It reaches the stages and add-ons, not the modules: `modules/*/variables.tf` are legitimately narrower, so the live `project_numbers` disagreement stays live under every option in this section unless it is ruled on separately, which needs no new mechanism — a decision applied to five files by hand. And it buys identity, not derivation: a change to a namespace type means editing the canonical file and letting CI name the copies that lag, six to nine files per edit, every edit. That fixed tax is the real cost of every option below and it is worth pricing before the choice rather than after. One further consequence: a `schemas/context.schema.json` carrier would be documentation with CI-enforced copies and nothing more, because no Terraform code reads it — the same "documentation, not enforcement" failure §2.5 warns the union about, arrived at from the other side.

- **Option A — narrow role types, duplication accepted.** Each role declares only its own namespaces. Cost: `project_ids` typed twice in the same file, kept in step by review and by the plan tests; nothing else duplicated.
- **Option B — canonical union in `context.tf`.** Every role declares the full namespace set, all optional. Cost: the union is copied four times *within one file* (HCL has no type aliases), and whether an unknown attribute is rejected is unverified (§5.3). Benefit: the file becomes the vocabulary, and a new namespace is one edit in one file in every stage.
- **Option C — loose types plus validation.** Role variables typed `any` or `map(any)`, shape checked by a `validation` block or by `try` at the point of use. Cost: the consumer's `context` type stops being able to promise anything about upstream shapes, and type errors turn into plan-time surprises deeper in the code.
- **Option D — register the copies in `duplicate-diff.py`.** Not a third shape but the enforcement layer for either of the first two; the carrier paragraph above is this option. Cost: the list entry, and the per-edit tax of editing the canonical file and following CI to the copies that lag.

### 6.2 Whether the security stage publishes `ca_pools` whole or split (rule 10)

**Direction set (room #139): it becomes additional context namespaces, and like every other namespace it must be flat.** The map-of-objects shape is the part that goes; whether that lands as `ca_pool_ids` plus `ca_pool_locations` plus a `ca_ids` namespace, or as some other split, is decided against the code at development time. Touching consumers or modules to accommodate the new shape is acceptable if that is what it takes. So the option list below is the design space, not a choice to take now.

The shape today is `map(object({ca_ids = map(string), id = string, location = string}))` (`2-security/outputs.tf:27-33`), declared on the consumer side by ngfw as `certificate_authority_pools` (`variables-fast.tf:40-44`).

- **Option A — whole, under the name `ca_pools`.** Keeps the current shape, makes §1.11's mismatch vanish, costs a map-of-objects namespace in the type. `$ca_pools:key` resolves to the object, not to `id`, so a dataset that wants the pool id writes `$ca_pools:x` and a consumer that wants `.id` still does the extraction in HCL (`ngfw/tls-inspection.tf:21`).
- **Option B — split into flat namespaces** (`ca_pool_ids = map(string)`, `ca_pool_locations = map(string)`, and `ca_ids` as a map of maps). Cost: three namespaces where there is one today, and `ca_ids` does not become a flat map of strings at all, so the split only half-achieves flatness. Benefit: the id map, which is the only field ngfw reads, becomes `$ca_pool_ids:key`.
- **Option C — both.** Publish `ca_pools` for shape fidelity and `ca_pool_ids` for key resolution. Cost: two namespaces holding the same information, and the first divergence between them is silent.
- **What the code supports:** no in-chain consumer constrains this today — `ca_pools` has none (§1.6), and ngfw's `ca_ids` field is never read (`tls-inspection.tf:19-23` uses only `.id`, and the test leaves the value empty). So the cost of choosing wrong is one namespace rename later, not a broken tree.

### 6.3 Roles with more than one stage (rule 10)

**Decided (room #139): one writer per role, and the ADR should say so.** The only stages that overlap a role are the project factories and custom stages that create tenants — app projects, tenant sub-landing-zones — and those already generate their own unified context file, one per tenant, which is the boundary the problem stays behind. The options below are kept as the record of what was considered and why they are not needed.

The cases are the project factory (its `stage_name` is a root variable, `variables.tf:65`) and custom stages; the ADR defers both.

- **Option A — one writer per role variable, by convention.** Two stages publishing `fast_org` means the second file silently replaces the first, which is the current problem under a new name. Cost: nothing to build, and the failure is silent.
- **Option B — a role variable per stage, declared by the consumer.** `fast_org_<name>` and so on. Cost: the consumer must know which stages produce for it, which is the "reach into the producer" property the ADR is trying to remove; and the ADR's role naming was chosen precisely to avoid stage names.
- **Option C — keep the boundary the ADR names.** The project factory already ships per-consumer tfvars (`output-files.tf:143-152`), so its multi-stage case stays behind that boundary, and custom stages keep the legacy flat variables until a rule exists. Cost: a second mechanism that lives as long as custom stages do.
- **Option D — make the role a list of writers.** `fast_org` as a `list(object)` merged in order, one element per stage. Cost: it changes the merge from "last writer wins" to a defined order across files (still not expressible in HCL — two tfvars files still cannot append to one list, so this does not actually work). *Unsourced:* listed for completeness; the variable-replacement semantics in the ADR's hard requirements are why it fails.

### 6.4 The rest

- **`_fast_debug`** stays where it is and needs no decision: a harness switch in a FAST-channel file, no producer, no role, no migration (§1.11). It is listed here only so that a reader who notices it in the delete lists knows it was seen.
- **Dead published values — decided (room #139): keep them.** They are meaningful as contexts in the project factory when projects need them, so the question is not whether they are dead but which of them the project factory's `context` type should gain and under what name; that is settled during development. The nine: `subnet_ips` from both publishers, `host_project_numbers`, `subnet_proxy_only_self_links`, `subnet_psc_self_links` from networking, `groups`, `workload_identity_providers`, `workforce_identity_providers` from stage 0, and the stage-0 copies of `subnet_self_links` and `vpc_self_links`. For the record, the option that was not taken: **drop** — smallest surface, breaking for any out-of-tree reader, and *unsourced*, since no in-repo evidence either way exists; muse's disposition list (room #57) proposed it.
- **Which name the networking namespaces publish under — decided (room #139): the context names already in the code are the rule, consumers adapt.** So `vpc_self_links` publishes as `networks` and `subnet_self_links` as `subnets` — with the reshape caveat below left for development — `perimeters` publishes as `vpc_sc_perimeters` (§3.1), and `regions` gives way to `locations`. §3.1's producer-side rename covers `host_project_ids` → `project_ids`; five more of 2-networking's seven values have the same problem, and here the tree is unusually clear about which name should win. The stage's own factories already call them `networks` and `subnets` — `factory-addresses.tf:34-36` and `factory-cloudnat.tf:77-79` build `{ networks = local.ctx_vpcs.self_links, subnets = local.ctx_vpcs.subnets_by_vpc }` for its own YAML — 25 modules declare `networks` and 14 declare `subnets` (qwen's census, §6.1), and the YAML that goes with those names (`$networks:dmz`, `$subnets:hub/europe-west1/hub-default`) is resolved by a hand-written `replace()` against the same map (`factory-peering.tf:52-56`, `factory-nva.tf:98`). The published names are the odd ones out: no module declares `vpc_self_links` or `subnet_self_links`, and neither is addressable symbolically anywhere (`$vpc_self_links:` and `$subnet_self_links:` are both zero-hit). Options: **publish under the module vocabulary** (`networks`, `subnets`), which is the only version where the role variable and the module types agree and which lets the hand-written replaces go; or **keep the present names**, which costs nothing today and leaves a consumer declaring one spelling while every module resolves another. Cost of aligning: two names change for anyone reading the bucket, and the add-ons' `vpc_self_links`/`subnet_self_links` variables move with them — the values are identical, so it is a rename and not a migration. **How far each of the three aligns differs, and one of them is not a rename.** `host_project_ids`→`project_ids` and `vpc_self_links`→`networks` are pure: both sides are flat `map(string)` keyed by project or VPC name. `subnet_self_links`→`subnets` is a reshape: networking publishes a nested `map(map(string))` keyed network → `region/name` (`2-networking/outputs.tf:24-26`), read nested by both add-ons (`2-networking-swp/main.tf:65,82`, `2-networking-test/context.tf:53`), while modules take a flat `map(string)` keyed by subnet name alone (`modules/cloud-function-v1/vpcconnector.tf:20-35`, `modules/cloud-run-v2/job-managed.tf:60`). Aligning that one needs a key convention as well as a name, and a bare subnet name is not unique across VPCs. So of the seven values 2-networking publishes: two are renames, one is a rename plus a shape decision, and four have no module-side namespace at all — which is muse's sharpening (room #113) with the shape correction from this pass. The last four are the ones §6.4's keep-or-delete covers; putting them in a role object would manufacture namespaces no module requires. One unrelated duplicate the census turned up: `subnets` (14 modules) and `subnetworks` (1, `modules/workstation-cluster/variables.tf:32`) are the same idea one character apart, cheaper to settle before role variables carry both than after (qwen, room #111).
- **`regions` and `root_node` — naming settled by the bullet above; the annotation fix stands.** `locations` is the surviving name for region aliases here, because `net-vpc` merges the two and its validation rejects setting both (`modules/net-vpc/main.tf:22-24`, `variables.tf:58`). What remains is the one-line source fix: both are declared with a source that publishes nothing (§1.11). Options: fix the annotation to "user-supplied" (one line each, no behaviour change); make 2-networking publish region aliases, which needs a decision on the name — publishing under `locations` is the namespace members already understand (`$locations:` 92 hits) and the one `net-vpc` prefers, but requires the add-ons to stop calling it `regions` (`modules/net-vpc/main.tf:22-24` merges the two with `locations` winning and its validation rejects both at once), while publishing under `regions` leaves the add-ons untouched and propagates a deprecated name; or move them into the add-ons' `context` type with the same "user-supplied" annotation. The third is the smallest and follows §3.3; the second is the only one that makes the annotation true, and either of its two names is defensible. Note also that 2-networking would have to get the alias map from somewhere it does not read today: no `regions` key exists in its datasets.
- **`service_accounts` derivation — revisited later (room #139).** Folding `iam_principals["service_accounts/<k>"]` into the producer would delete three hand-written copies (§2.3); the human's note is that this class of case gets revisited and streamlined, so it stays as it is for now. Cost: it changes what stage 0 publishes, and any user reading `service_accounts` from the bucket keeps working either way if the flat key stays.
- **`2-networking-test/context.tf`.** The shared file needs a name that is free: rename the add-on's locals file to `locals.tf`, or name the shared file `fast-context.tf`. The first is better — one meaning per filename — and it only touches one add-on.
- **Migration shape — decided (room #139): one clean cut, no backward compatibility (§4.1).** The dual-write options that were listed here are now §4.3, the record of what was dropped.
- **Whether the globals file keeps its name and contents.** `0-globals.auto.tfvars.json` is the only file whose shape this plan leaves alone, and it is the file the extras nearly collide with (§1.9). No change is needed; saying so explicitly is what stops the next person from folding it into `fast_org`.

---

### 6.5 The one object-valued namespace

**Direction set (room #139): the context implementation already in the code drives how the new variables are shaped.** `tag_vars` and, in a simpler form, `condition_vars` are special context entries consumed in replacements through `templatestring`, and there is no context specification document — which is why §1.1 had to rediscover the classification from the code, and it is a gap worth fixing in prose at some point. A future reader should start at `AGENTS.md:148` (Adding Context Support to a Module, the module-side pattern), `modules/folder/main.tf:19-23` (the `ctx_p` flattening that produces the `$ns:key` strings `templatestring` resolves), and `fast/stages/2-project-factory/main.tf:20-26` (the stage-side merge with the defaults file). Merges here will be painful and the plan does not need to settle every corner case; they will be met in development against real code. The one implication this plan did prove is kept in §2.1 — the shallow merge against materialised empty sub-maps — because it is proven, it bites `tag_vars` specifically, and the fix is six lines. Everything else in this section waits for the code.

Not one of the three above, but the same kind of thing: a shape question the code does not answer. `tag_vars` is the only namespace in the tree typed as an object rather than a map, and the loop in §2.1 replaces its sub-maps with the empty ones `var.context` always materialises.

- **Option 1 — one stated exception in `context.tf`.** The loop handles every map-typed namespace; `tag_vars` gets the explicit two-level merge shown in §2.1, which is what the three consumer sites do today. Cost: "composition happens once, under one rule" gains a named exception, and "one rule" becomes "one rule and one name". Smallest diff, changes no types, and the exception is provably the only one until a second object-typed namespace is added.
- **Option 2 — split it into two flat namespaces** (`tag_vars_projects`, `tag_vars_organization`). Everything is a map, the exception disappears, and nothing has to branch on shape. Cost: `modules/project-factory` stops reading `local.ctx.tag_vars` as an object — `automation.tf:157-161` and the four `folders.tf` sites (`:112-114`, `:195-197`, `:278-280`, `:361-363`) — plus five type declarations and whatever the project YAML feeds. Largest diff, cleanest end state, and the only option that makes the vocabulary uniform.
- **Option 3 — teach the loop to merge two levels** by branching on shape or hard-coding depth. Cost: the loop stops being an expression and becomes magic, which `fast/README.md`'s implementation section explicitly argues against. Listed for completeness; not recommended.
- **Option 4 — strip the inner `{}` defaults** so that user silence leaves the attribute absent and `merge` behaves as it does for maps. Considered and rejected (muse, room #87): the module-side `context` types fill those defaults straight back (`modules/project-factory/variables.tf:36-39`, and the same shape in the stages), so it trades one exception in one file for synchronised type changes across five declarations and every module that reads them. It would also break a standalone user relying on the documented defaults.

qwen's ordering judgement — option 1 now, option 2 if `modules/project-factory` is being touched anyway — is a reasonable default and is not taken here, because it is the same kind of call as the three above. Note that option 1's exception is narrow by measurement, not by hope: qwen's census found exactly one object-typed namespace among 40, and `condition_vars` (`map(map(string))`, 19 modules) is safe — its unset value is `{}`, and `merge(x, {})` is `x`.

## 7. Disagreements, unsourced claims, and what is still owed

- **The decision round (room #139), and what it changed here:** role variables are narrow, one per role, declaring only what that role publishes (§6.1) — which is why probe §5.1 stays a gate; `ca_pools` becomes flat context namespaces with the exact split left to development (§6.2); one writer per role goes into the ADR, with tenant-creating stages behind their own per-tenant context file (§6.3); the context names already in the code win over the published ones (§6.4, so `vpc_self_links`→`networks`, `subnet_self_links`→`subnets`, `regions`→`locations`); the nine unconsumed values are kept because the project factory uses them as contexts when projects need them; `service_accounts` and the `folder_ids` inconsistency are left for development; and the migration is one clean cut with no backward compatibility (§4.1), which deleted the dual-write design, the second output object and the half-upgraded-tree analysis, leaving §4.3 as the record. §0 was added at the human's request as the one-page orientation for future reviewers.
- **Unsourced:** whether an object-typed variable rejects unknown attributes (§5.3); whether anything outside the repo consumes the per-project tfvars (§1.5); whether dead outputs have out-of-tree consumers (§6.4); the durability of option D in §6.3.
- **Convergent, and settled:** muse agrees the classification test needs the amendment in §1.1 (`tag_vars` by type, renamed namespaces, plus `project_numbers` promoted from "first-class feeding context" to context outright). Two independent reads, so §1.1 stands as written.
- **Corrected, mine (room #69):** §6.1's `project_numbers` paragraph wrongly listed `modules/project/variables.tf:147` as a witness; that line is `project_ids`, in the same `context` block. The corrected witnesses are `1-vpcsc/variables.tf:78` and `modules/vpc-sc/variables.tf:139` (`map(number)`) against `modules/project-factory/variables.tf:31`, `modules/folder/variables.tf:184` and `modules/billing-account/variables.tf:150` (`map(string)`) — three against two, and billing-account is a witness neither of us had in the first count. §2.2's publisher table also carried a `project_numbers` row for `fast_networking` that §3.1 no longer has; it is struck too, so the two sections agree.
- **Reviewed and amended (room #62):** muse approved §2.2's role order, §2.1's choice (b) — since flipped to (a), next bullet — and the §1.1 rewrite, with four changes that are now in the file — the `host_project_numbers` row struck from §3.1 to keep "order matters for exactly one namespace" true by construction, the 0-org-setup row corrected from one line to two token swaps, (b2) added for 3-secops-dev's five-line block, and the union restricted to namespaces that have a publisher. One correction back: muse placed the second 0-org-setup read at `main.tf:46`; `grep -n 'var\.context' fast/stages/0-org-setup/*.tf` returns `:19` and `:45`, and `:46` is the `try(local._defaults.context...)` line. Muse also read §2.4's `1-vpcsc:75-82` as wrong against the `variable` block's `:73-86`; both are right for their object, and §2.4 now says which one it quotes.
- **Convergent, and now in the plan:** the second-publisher collision on `subnet_ips`, `subnet_self_links` and `vpc_self_links` between 0-org-setup and 2-networking (§1.2). Found independently on both sides; it is worth more than a row, since it is the ADR's second problem already happening inside the tree.
- **Open disagreement:** the ADR's §1.10 sentence "the values the networking and security stages publish are all context". By the ADR's own test, all seven of 2-networking's published values are first-class, and only the merge at `2-project-factory/main.tf:107-109` makes two of them context anywhere. The plan records them as variables today and moves them because the merge is the argument, not the test. If the intent was that the test *should* classify them as context, the test needs rewriting as "reference-shaped", which changes §1.1 and no other row.
- **Corrected, and it flipped §2.1 (muse, room #89):** the `tag_vars` exception referenced `local.context_defaults`, which only choice (a) provides. Under the first draft's choice (b) the stage loop would have shallow-merged `tag_vars` a second time and wiped it one level down, in every stage. The plan now takes (a): `context.tf` does the whole merge, each stage declares `context_defaults` and sets `_ctx = local.fast_ctx`, and (b) is recorded as the option the exception killed. Two sections that could not both be true now can.
- **Qwen's self-correction (room #109), recorded because the plan rests on negative results too:** their zero-hit grep was a regex bug — the pattern consumed the single-character key before the alternation — and it reproduces: `grep -rnE 'var\.[a-z_.]+\[[a-z_]([a-z_]*key[a-z_]*|k|kk|v|vv)\]' modules/vpc-sc/factory.tf` returns nothing on a file that contains two such lines. Their "ten live sites" was the length of a `head -10` listing, not a count; the real figure is 28. Neither was invented, which is the part worth keeping: a hand-written pattern that cannot match its own example prints exactly what a real absence prints. Every `zero hits` and empty-grep claim in this plan carries the same exposure, and the pattern that would have found the thing is the cheap check — for the §5.1 negative it was `grep -n 'var.factories_config\[k\]' modules/vpc-sc/factory.tf`, two tokens.
- **The carrier for rule 10's first question, named (qwen, room #104):** `tools/duplicate-diff.py` already enforces byte-identity for five `.tf` groups — `bundle.tf`, `serviceaccount.tf`, `variables-serviceaccount.tf`, `variables-vpcconnector.tf`, `vpcconnector.tf` across three `cloud-function`/`cloud-run` modules (`:129-152`), with `.pre-commit-config.yaml:135-137` and `.github/workflows/linting.yml:126` running it. Re-verified here. §6.1 now leads with that instead of a subordinate clause, states the two limits (it reaches stages and add-ons, not `modules/*`, so the `project_numbers` disagreement survives every option unless ruled on separately; and it buys identity, not derivation, at a per-edit cost of six to nine files), and demotes the schema-file carrier to what it is — documentation no Terraform code reads.
- **Both fallbacks are recorded in §5.1 and the shape choice now carries a second consequence (qwen, room #99):** the `tag_vars` exception reads all four roles, so it no longer breaks under either type shape. Before that edit, the union option would have made the exception silently drop a second publisher's `tag_vars` — the same species of defect as muse's §2.2 point at #62, a property holding only because of who happens to publish what. Two findings, from §5.1 and from the exception, both said the narrow/union choice was doing more work than §6.1 credited; the file now says that in one place.
- **Qwen's coupling of §5.1 and §6.1 (room #92), accepted**, and one of their claims is falsified: their zero-hit grep for dynamic indexing into a variable was run again with the same pattern and returns three lines, one of which — `modules/vpc-sc/factory.tf:26,28`, indexing the declared object `var.factories_config[k]` — is a live precedent for the shape §5.1 tests. It proves the hit path, not the miss path that `try()` is for, so the probe stands but its risk is lower than "unproven everywhere". Their confidence figure (~85%) is recorded in place of my ~70%, with their reason — role values come from tfvars, so they are known at plan time — and muse's stronger version of the same number (room #93): the syntactic half is settled by `modules/vpc-sc/factory.tf:26-28`, so only the `try()`-on-a-declared-attribute-absent case is unrun. §5.1 now carries all of this, and §6.1 states that the type-shape choice and the probe are one decision.
- **Qwen's defect report (room #85), accepted and endorsed by muse (room #87):** the loop's shallow `merge` destroys `tag_vars`, the one object-typed namespace, because an unset `optional(object(...), {})` materialises to empty sub-maps. §2.1 now carries the explicit two-level merge as an exception, §5.6 is the gate probe, and §6.5 lists three live options plus one rejected (stripping the inner defaults, which the module types refill). Qwen's closing sentence about `condition_vars` is right in mechanism and narrower in scope than stated: `condition_vars` is a map, so its unset value is `{}` and the loop is the identity on it — the discriminator is map versus object, and only an object has filled inner defaults to wipe with. Both seats converged on that after the report, so the exception is one name, not a class.
- **Two probes now gate §4.1's first step** rather than riding with the rest: §5.1 (dynamic index into an object-typed role variable) and §5.6 (the `tag_vars` wipe). Muse's point in room #87, and the right one — either answer changes the shape of the file every stage would otherwise copy.
- **Owed:** qwen's module-side context census over all of `modules/*`. It arrived in room #72 and is now in §6.1, run with a brace-matching parser rather than a grep — 45 modules, 40 namespaces, the shape classes, and the one cross-module disagreement that confirms `project_numbers` from a second instrument. Nothing in this plan still waits on it. It was re-run independently after qwen left the room: a fresh parse over `modules/*/variables.tf` returns 45 modules and 40 namespaces, every count checked against the table (`networks` 25, `subnets` 14, `project_ids` 43, `locations` 36, `tag_vars` 14, `project_numbers` 3× `map(string)` + 1× `map(number)`, `regions` 1, `subnetworks` 1), and the same single cross-module disagreement. The first version of that re-run returned 42 namespaces; the two extras were `projects` and `organization`, the inner attributes of the `tag_vars` object leaking into my parser — an artefact of the instrument, not a claim in the table, and the reason the count is stated with the artefact next to it.
- **Qwen's three fold-ins (room #72):** `stage_configs` given a provenance in §1.10 (a real output renamed in `ade7fb32b`, since removed with its stage); `_fast_debug` added to §1.11 (a consumer-side switch in the FAST channel, set only by the two add-on tests); and the `folder_ids`/defaults-file inconsistency at `2-networking/main.tf:36` added to §3.2 and §5.8. Qwen also supplied the consumer matrix — 25 names across the eight `variables-fast.tf` files, `0-org-setup` the only root with none — which agrees with muse's and my rows wherever they overlap.
- **Qwen's correction to §4.3 (room #78), accepted and now the plan's shape:** the opt-in for a separate file already exists and is not a `-var-file` — `fast-links.sh` links only what `.fast-stage.env` names (`:69-72` for `FAST_STAGE_DEPS`, `:81-84` for `FAST_STAGE_OPTIONAL`, with `:39` and `:44` choosing `gcloud storage cp` or `ln -s`), so an unlinked file is never loaded. §4.1's step 2 now writes the role variables to `<stage>-ctx.auto.tfvars.json` rather than into the existing file, which turns "old consumer, new producer" from fatal into stale and moves the loud failure to "new consumer, old producer". I had written option (iii) as the only safe shape with the cheap shape as its trade-off; that was wrong, and §4.3 now says so. Qwen's two smaller notes are in §3.3 and §4.5; the open question about `2-networking-swp` having no `.fast-stage.env` stays open, marked unsourced.
- **Left alone deliberately:** qwen counts 757 `$iam_principals:` hits to my 754, the difference being include sets and the `tests/` tree. §1.1 already calls these counts a presence test; the digit is not load-bearing and the plan does not change it.
