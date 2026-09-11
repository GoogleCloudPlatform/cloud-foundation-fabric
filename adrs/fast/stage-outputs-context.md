# Stage outputs and context

**authors:** [Ludo](https://github.com/ludoo) (with Opus 5 help)\
**date:** 10 September 2026

## Status

Proposed.

## Context

FAST stages hand values to each other through tfvars files. A stage writes one file to the outputs bucket and to a local directory, later stages read it, and every value in it arrives as an ordinary Terraform variable. Stage 0 publishes `project_ids`, `folder_ids`, `service_accounts` and a dozen more. The networking stage publishes `host_project_ids` and the subnet and VPC maps. The security stage publishes `ca_pools` and `kms_keys`.

### Where the current mechanism came from

The first design had consumers read a producing stage's remote state. That coupled a consumer to the internal structure of everything upstream of it. References grew long and nested, a reader could not tell what a name pointed at, and a change inside a producer broke consumers that never mentioned it.

Flat tfvars files replaced remote state and fixed all of that. The flatness is the reason the current mechanism reads well, and it is worth keeping. It also allows stages to be used independently from FAST, with the variables becoming prerequisites the user deals with and specifies statically, like for any regular Terraform root module (first point below).

### What the current mechanism gets right

Four properties which any replacement needs to keep:

- a consumer declares what it needs as ordinary variables, so anyone can run a stage on its own with hand-written tfvars, the same way they would run any Terraform root module
- overriding one value costs nothing. Terraform loads `.auto.tfvars` files in lexical order, so a file named `9-custom.auto.tfvars.json` replaces a value with no code change anywhere, allowing simple overrides such as the billing account or the prefix
- references stay short and readable, because the values are flat maps
- a consumer never reaches inside a producer

### Two problems

FAST variables and a stage's own variables share one namespace. Names such as `organization`, `prefix`, `locations` and `groups` are names a stage author might reasonably want, and FAST has taken them. At some point in the past we grouped them into `fast-variables.tf` files to visually separate them, but this is just a cosmetic fix.

The second problem is sharper. Terraform replaces a variable when two tfvars files set it, and never merges the two values. A namespace therefore belongs to whichever stage claims it first. Stage 0 claims `project_ids`.

The networking stage also creates projects, but cannot publish them under that name, and publishes `host_project_ids` instead.

The project factory now merges the two by hand at `fast/stages/2-project-factory/main.tf:107`, in an order that lives nowhere except that line, and using this as a workaround without a clear pattern or principle defined for this at the FAST level.

The security stage publishes no project ids at all. So a project factory YAML file cannot refer to `dev-sec-core`, and a grant on that project has to carry a literal project id in the stage defaults context. We hit this while granting `roles/privateca.certificateRequester` on the dev security project to a Secure Source Manager service agent. The grant is ordinary. The only reason it needs a static value is that one variable name was already taken three stages earlier.

### Context is now how FAST expresses a reference

Modules and factories resolve symbolic references such as `$project_ids:dev-sec-core` at plan time, against a `context` variable holding one map per namespace. This started in the project factory and has spread across most modules, and become an implicit principle we built on everywhere.

Stage outputs and context have converged without anyone deciding that they should. Stage 0 builds almost all of its output from a local named `of_ctx` at `fast/stages/0-org-setup/output-files.tf:109`, and splits its output into a `globals` file and a stage file. The values the networking and security stages publish are all context. The project factory turns `perimeters` into the `vpc_sc_perimeters` namespace on arrival.

Counting what every stage in the tree writes, the values that cannot be used via context are `automation`, `stage_configs`, and two outputs from the network security add-on. Everything else is a context namespace already, or becomes one inside the consumer.

So context is a first-class FAST principle, and the output mechanism predates it. This proposal surfaces the contradiction and proposes a way for the output mechanism to work with context.

## Hard requirements

Four requirements, which between them discard most of the design space.

Terraform replaces a variable whenever two tfvars files set it. Nothing merges. The unit a stage writes therefore has to have exactly one writer. This rules out a single `fast` variable holding one attribute per stage, which was the first shape we considered: every stage would write the same variable, and the last file loaded would erase the rest.

A consumer has to state what it requires, so that a stage can run outside a FAST chain. This rules out handing a consumer an untyped bag of everything and letting it search (which is mostly what happens in the current system).

Running a stage on its own has to stay as easy as it is today. This rules out any shape where a standalone user has to know which stage produces a value before they can supply it, or reach deep inside nested attributes to define its external prerequisites.

Composition has to happen once per stage, in one place, under one rule. Today each consumer merges by hand, and the merge order is folklore and defined by ad hoc workarounds as the need arises.

## Proposal

Give each FAST role its own variable, and let it carry only context.

A role names what a stage produces rather than which stage produced it: `fast_org`, `fast_security`, `fast_networking`, `fast_vpcsc`. One role has one writer, which satisfies the first requirement. Two roles can both publish `project_ids`, because they write different variables, which is what the current design cannot do. Roles rather than stage names, because a stage name is arbitrary and settable per deployment: the project factory takes one in `var.stage_name`, and the security stage reads one from `defaults.global.stage_name`, each falling back to a hardcoded string.

Add a `context.tf` file, identical in every stage. It reads the namespaces that the stage's own `context` variable already declares, collects the matching attribute from every role variable, and merges them into one context. It then merges the stage's `context` variable and the context from the defaults file on top, which is what the project factory already does at `fast/stages/2-project-factory/main.tf:20`.

**The type of `var.context` becomes the statement of what a stage requires.** It says so in namespaces, which is the vocabulary a user thinks in, and it says so in one place.

**Leave everything that is not context as a first-class variable.** That is the user input in `globals` — organization, billing account, prefix, universe — and the short remainder such as `automation` which can also probably go away, since output files buckets etc are now all defined in YAML and use context. These have one producer each and have never had the second problem, so the new mechanism would buy them nothing. They are also what a user running a single stage needs to worry about as prerequisites.

Running a stage on its own then works exactly as it does today. The role variables default to empty, contribute nothing, and never appear. A user fills `var.context` or the `defaults.yaml` file with the references the stage needs and the plain variables with the rest. A standalone user never meets a role variable.

Deciding which channel a new output belongs to has one test, and stage 0 has been applying it by hand for years: a value referenced symbolically as `$namespace:key` is context, and a value that HCL reads directly is a variable.

## Decision

Vote on the proposal. Keep the first-class variables for user input and for the small non-context remainder, move everything else into role variables carrying context, and aggregate in a shared `context.tf`.

## Consequences

Five accepted compromises.

The interface has two channels instead of one. The test above decides between them, so the cost is one judgement per new output.

Two roles publishing the same key in the same namespace resolve by merge, silently. Two stages claiming the same project id means something has gone wrong further upstream, and we would rather fix that than build a check for it here.

Every existing deployment has to migrate its tfvars directory. Stages can write the old and the new files together for one release, which keeps the migration survivable.

Roles with more than one stage stay unsolved for now. The project factory and custom stages are the cases, and the project factory already bundles dedicated tfvars for each of its consumers, so a boundary exists to hold the problem behind. We open it once the canonical stages work.

One shape question stays open, and it is smaller than it looks at first. `ca_pools` is a map of objects carrying `ca_ids`, `id` and `location`, where `project_ids` and most other namespaces are flat maps of strings. Context already carries shapes beyond a string map, so this asks for no new capability. `modules/vpc-sc/variables.tf:132` declares `identity_sets`, `resource_sets` and `service_sets` as maps of string lists, `project_numbers` as a map of numbers and `condition_vars` as a map of string maps. `modules/net-vpc-factory/variables.tf:18` declares `cidr_ranges_sets` as a map of string lists. The project factory defaults schema types `tag_vars` as an object. Every namespace therefore declares its own type where it is consumed, and nothing states what a producer may publish under a given name. Settle two things before anyone writes code: where a namespace's type is declared once for every stage that publishes it, and whether the security stage publishes `ca_pools` whole or splits it into flat namespaces on the way out.

We also gain two things worth recording. Overriding a value gets simpler. A user adds one entry to `var.context` and it wins, whichever stage produced the original. Today the same override means restating a whole map that an upstream stage owns. And the merge order stops being folklore, because one file does the merging for every stage.
