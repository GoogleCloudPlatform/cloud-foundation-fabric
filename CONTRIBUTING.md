# Contributing

Contributors are the engine that keeps Fabric alive so if you were or are planning to be active in this repo, a huge thanks from all of us for dedicating your time!!! If you have free time and are looking for suggestions on what to work on, our issue tracker generally has a few pending feature requests: you are welcome to send a PR for any of them.

## Table of Contents
<!-- BEGIN TOC -->
- [I just found a bug / have a feature request](#i-just-found-a-bug--have-a-feature-request)
- [Quick developer workflow](#quick-developer-workflow)
- [Developer's handbook](#developers-handbook)
  - [The Zen of Fabric](#the-zen-of-fabric)
  - [Design principles in action](#design-principles-in-action)
  - [FAST stage design](#fast-stage-design)
  - [Style guide reference](#style-guide-reference)
  - [Interacting with checks and tools](#interacting-with-checks-and-tools)
- [Using and writing tests](#using-and-writing-tests)
  - [Testing via README.md example blocks.](#testing-via-readmemd-example-blocks)
    - [Testing examples against an inventory YAML](#testing-examples-against-an-inventory-yaml)
    - [Using external files](#using-external-files)
    - [Running tests for specific examples](#running-tests-for-specific-examples)
    - [Generating the inventory automatically](#generating-the-inventory-automatically)
    - [Building tests for blueprints](#building-tests-for-blueprints)
  - [Testing via `tfvars` and `yaml` (aka `tftest`-based tests)](#testing-via-tfvars-and-yaml-aka-tftest-based-tests)
    - [Generating the inventory for `tftest`-based tests](#generating-the-inventory-for-tftest-based-tests)
  - [Running end-to-end tests](#running-end-to-end-tests)
  - [Writing tests in Python (legacy approach)](#writing-tests-in-python-legacy-approach)
  - [Running tests from a temporary directory](#running-tests-from-a-temporary-directory)
- [Fabric tools](#fabric-tools)
- [Cutting a new release](#cutting-a-new-release)
<!-- END TOC -->

## I just found a bug / have a feature request

Feel free to open a new issue if you find something that does not work, need clarifications on usage (a good incentive for us to improve docs!), or have a feature request.

If you feel like tackling it directly via a PR check out the quick developer workflow below, we always welcome new contributors!

## Quick developer workflow

For small or first time issues the simplest way is to fork our repo, but if you are a regular contributor or are developing a large addition, ask us to be added directly to the repo so you can work on local branches, it makes life easier for both of us!

Fork or clone and go through the usual edit/add/commit cycle until your code is ready.

```bash
git checkout master
git pull
git checkout -b username/my-feature
git add -A
git commit -m "changed ham so that spam and eggs"
```

Once you are satisfied with your changes, make sure Terraform linting is ok. If you changed Python code you need to conform to our standard linting, see the last section for details on how to configure it.

```bash
terraform fmt -recursive
```

If you changed variables or outputs you need to regenerate the relevant tables in the documentation via our `tfdoc` tool. For help installing Python requirements and setting up virtualenv see the last section.

```bash
# point tfdoc to the folder containing your changed variables and outputs
./tools/tfdoc.py modules/my-changed-module
```

If the folder contains files which won't be pushed to the repository, for example provider files used in FAST stages, you need to change the command above to specifically exclude them from `tfdoc` generated output.

```bash
# exclude a local provider file from the generated documentation
./tools/tfdoc.py -x 00-bootstrap-providers.tf fast/stages/00-bootstrap
```

Run tests to make sure your changes work and you didn't accidentally break their consumers. Again, if you need help setting up the Python virtualenv and requirements or want to run specific test subsets see the last section.

```bash
pytest tests
```

Keep in mind we also test documentation examples so even if your PR only changes README files, you need to run a subset of tests.

```bash
# use if you only changed README examples, ignore if you ran all tests
pytest tests/examples
```

Once everything looks good, add/commit any pending changes then push and open a PR on GitHub. We typically enforce a set of design and style conventions, so please make sure you have familiarized yourself with the following sections and implemented them in your code, to avoid lengthy review cycles.

HINT: if you work on high-latency or low-bandwidth network use `TF_PLUGIN_CACHE_DIR` environment variable to dramatically speed up the tests, for example:

```bash
TF_PLUGIN_CACHE_DIR=/tmp/tfcache pytest tests
```

Or just add into your [terraformrc](https://developer.hashicorp.com/terraform/cli/config/config-file):

```
plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
```

## Developer's handbook

Over the years we have assembled a specific set of design principles and style conventions that allow for better readability and make understanding and changing code more predictable.

We expect your code to conform to those principles in both design and style, so that it integrates well with the rest of Fabric/FAST without having to go through long and painful PR cycles before it can be merged.

The sections below describe our design approach and style conventions, with specific mentions of FAST stages where their larger scope requires additional rules.

### The Zen of Fabric

While our approach to Terraform is constantly evolving as we meet new requirements or language features are released, there's a small set of core principles which influences all our code, and that you are expected to make yours before sending a PR.

Borrowing the format from the [Zen of Python](https://peps.python.org/pep-0020/) here is our fundamental design philosophy:

- always **design for composition** as our objective is to support whole infrastructures
- **encapsulate logical entities** that match single functional units in modules or stages to improve readability and composition (don't design by product or feature)
- **adopt common interfaces** across modules and **design small variable spaces** to decrease cognitive overload
- **write flat and concise code** which is easy to clone, evolve and troubleshoot independently
- **don't aim at covering all use cases** but make default ones simple and complex ones possible, to support rapid prototyping and specific production requirements
- when in doubt always **prefer code readability** for simplified maintenance and to achieve IaC as documentation
- **don't be too opinionated** in resource configurations as this makes it harder for users to implement their exact requirements
- **avoid side effects** and never rely on external tools to eliminate friction and reduce fragility

The following sections describe how these principles are applied in practice, with actual code examples from modules and FAST stages.

### Design principles in action

This section illustrates how our design principles translate into actual code. We consider this a living document that can be updated at any time.

#### Design by logical entity instead of product/feature

> “The most fundamental problem in computer science is problem decomposition: how to take a complex problem and divide it up into pieces that can be solved independently.”
>
> — John Ousterhout in "A Philosophy of Software Design"

This is probably our oldest and most important design principle. When designing a module or a FAST stage we look at its domain from a functional point of view: **what is the subset of resources (or modules for FAST) that fully describes one entity and allows encapsulating its full configuration?**

It's a radically different approach from designing by product or feature, where boundaries are drawn around a single GCP functionality.

Our modules -- and in a much broader sense our FAST stages -- are all designed to encapsulate a set of functionally related resources and their configurations. This achieves two main goals: to dramatically improve readability by using a single block of code -- a module declaration -- for a logical component; and to allow consumers to rely on outputs without having to worry about the dependency chain, as all related resources and configurations are managed internally in the module or stage.

Taking IAM as an example, we do not offer a single module to centrally manage role bindings (the product/feature based approach) but implement it instead in each module (the logical component approach) since:

- users understand IAM as an integral part of each resource, having bindings in the same context improves readability and speeds up changes
- resources are not fully usable before their relevant IAM bindings have been applied, encapsulating those allows referencing fully configured resources from the outside
- managing resources and their bindings in a single module makes code more portable with fewer dependencies

The most extensive examples of this approach are our resource management modules. For instance, the `project` module encapsulates resources for project, project services, logging sinks, project-level IAM bindings, Shared VPC enablement and attachment, metrics scope, budget alerts, organization policies, and several other functionalities in a single place.

A typical project module code block is easy to read as it centralizes all the information in one place, and allows consumers referencing it to trust that it will behave as a fully configured unit.

```hcl
module "project" {
  source          = "./modules/project"
  parent          = "folders/1234567890"
  name            = "project-example"
  billing_account = local.billing_account
  services        = [
    "container.googleapis.com",
    "stackdriver.googleapis.com",
    "storage.googleapis.com",
  ]
  iam = {
    "roles/viewer" = ["user1:one@example.org"]
  }
  policy_boolean = {
    "constraints/compute.disableGuestAttributesAccess" = true
    "constraints/compute.skipDefaultNetworkCreation" = true
  }
  service_encryption_key_ids = {
    "compute.googleapis.com" = [local.kms.europe-west1.compute]
    "storage.googleapis.com" = [local.kms.europe.gcs]
  }
  shared_vpc_service_config = {
    attach       = true
    host_project = "project-host"
  }
}
```

#### Define and reuse stable interfaces

Our second oldest and most important principle also stems from the need to design for composition: **whenever the same functionality is implemented in different modules, a stable variables interface should be designed and reused identically across them**.

Adopting the same interface across different modules reduces cognitive overload on users, improves readability by turning configurations into repeated patterns, and makes code more robust by using the same implementation everywhere.

Taking IAM again as an example, every module that allows management of IAM bindings conforms to the same interface.

```hcl
module "project" {
  source          = "./modules/project"
  name            = "project-example"
  iam = {
    "roles/viewer" = ["user1:one@example.org"]
  }
}

module "pubsub" {
  source     = "./modules/pubsub"
  project_id = module.project.project_id
  name       = "my-topic"
  iam = {
    "roles/pubsub.viewer"     = ["group:foo@example.com"]
    "roles/pubsub.subscriber" = ["user:user1@example.com"]
  }
}
```

We have several such interfaces defined for IAM, log sinks, organizational policies, etc. and always reuse them across modules.

#### Design interfaces to support actual usage

> “When developing a module, look for opportunities to take a little bit of extra suffering upon yourself in order to reduce the suffering of your users.”
>
> “Providing choice is good, but interfaces should be designed to make the common case as simple as possible”
>
> — John Ousterhout in "A Philosophy of Software Design"

Variables should not simply map to the underlying resource attributes, but their **interfaces should be designed to match common use cases** to reduce friction and offer the highest possible degree of legibility.

This translates into different practical approaches:

- multiple sets of interfaces that support the same feature which are then internally combined into the same resources (e.g. IAM groups below)
- functional interfaces that don't map 1:1 to resources (e.g. project service identities below)
- crossing the project boundary to configure resources which support key logical functionality (e.g shared VPC below)

The most pervasive example of the first practical approach above is IAM: given its importance we implement both a role-based interface and a group-based interface, which is less verbose and makes it easy to understand at a glance the roles assigned to a specific group. Both interfaces provide data that is then internally combined to drive the same IAM binding resource, and are available for authoritative and additive roles.

```hcl
module "project" {
  source          = "./modules/project"
  name            = "project-example"
  group_iam = {
    "roles/editor" = [
      "group:foo@example.com"
    ]
  }
  iam = {
    "roles/editor" = [
      "serviceAccount:${module.project.service_accounts.cloud_services}"
    ]
  }
}
```

Another practical consequence of this design principle is supporting common use cases via interfaces that don't directly map to a resource. The example below shows support for enabling service identities access to KMS keys used for CMEK encryption in the `project` module: there's no specific resource for service identities, but it's such a frequent use case that we support them directly in the module.

```hcl
module "project" {
  source          = "./modules/project"
  name            = "project-example"
  service_encryption_key_ids = {
    compute = [local.kms.europe-west1.compute]
    storage = [local.kms.europe.gcs]
  }
}
```

The principle also applies to output interfaces: it's often useful to assemble specific pieces of information in the module itself, as this improves overall code legibility. For example, we also support service identities in the `project` module's outputs (used here self-referentially).

```hcl
module "project" {
  source          = "./modules/project"
  name            = "project-example"
  iam = {
    "roles/editor" = [
      "serviceAccount:${module.project.service_accounts.cloud_services}"
    ]
  }
}
```

And the last practical application of the principle which we show here is crossing project boundaries to support specific functionality, as in the two examples below that support Shared VPC in the `project` module.

Host-based management, typically used where absolute control over service project attachment is required:

```hcl
module "project" {
  source          = "./modules/project"
  name            = "project-host"
  shared_vpc_host_config = {
    enabled          = true
    service_projects = [
      "prj-1", "prj-2"
    ]
  }
}
```

Service-based attachment, more common and typically used to delegate service project attachment at project creation, possibly from a project factory.

```hcl
module "project" {
  source          = "./modules/project"
  name            = "prj-1"
  shared_vpc_service_config = {
    attach       = true
    host_project = "project-host"
  }
}
```

#### Design compact variable spaces

> "The best modules are those whose interfaces are much simpler than their implementations"
>
> — John Ousterhout in "A Philosophy of Software Design"

Designing variable spaces is one of the most complex aspects to get right, as they are the main entry point through which users consume modules, examples and FAST stages. We always strive to **design small variable spaces by leveraging objects and implementing defaults** so that users can quickly produce highly readable code.

One of many examples of this approach comes from disk support in the `compute-vm` module, where preset defaults allow quick VM management with very few lines of code, and optional variables allow progressively expanding the code when more control is needed.

This brings up an instance with a 10GB PD balanced boot disk using a Debian 11 image, and is generally a good default when a quick VM is needed for experimentation.

```hcl
module "simple-vm-example" {
  source     = "./modules/compute-vm"
  project_id = var.project_id
  zone     = "europe-west1-b"
  name       = "test"
}
```

Changing boot disks defaults is of course possible, and adds some verbosity to the simple example above as you need to specify all of them.

```hcl
module "simple-vm-example" {
  source     = "./modules/compute-vm"
  project_id = var.project_id
  zone       = "europe-west1-b"
  name       = "test"
  boot_disk  = {
    initialize_params = {
      image = "projects/debian-cloud/global/images/family/cos-97-lts"
      type = "pd-balanced"
      size = 10
    }
  }
}
```

Where this results in objects with too many attributes, we usually split attributes between required and optional by adding a second level, as in this example where VM `attached_disks[].options` contains less used attributes and can be set to null if not needed.

```hcl
module "simple-vm-example" {
  source     = "./modules/compute-vm"
  project_id = var.project_id
  zone       = "europe-west1-b"
  name       = "test"
  attached_disks = [
    { name="data", size=10, source=null, source_type=null, options=null }
  ]
}
```

Whenever options are not passed like in the example above, we typically infer their values from a defaults variable which can be customized when using defaults across several items. In the following example instead of specifying regional PD options for both disks, we set their options to `null` and change the defaults used for all disks.

```hcl
module "simple-vm-example" {
  source     = "./modules/compute-vm"
  project_id = var.project_id
  zone       = "europe-west1-b"
  name       = "test"
  attached_disk_defaults = {
    auto_delete = false
    mode = "READ_WRITE"
    replica_zone = "europe-west1-c"
    type = "pd-balanced"
  }
  attached_disks = [
    { name="data1", size=10, source=null, source_type=null, options=null },
    { name="data2", size=10, source=null, source_type=null, options=null }
  ]
}
```

#### Depend outputs on internal resources

We mentioned this principle when discussing encapsulation above but it's worth repeating it explicitly: **set explicit dependencies in outputs so consumers will wait for full resource configuration**.

As an example, users can safely reference the project module's `project_id` output from other modules, knowing that the dependency tree for project configurations (service activation, IAM, etc.) has already been defined inside the module itself. In this particular example the output is also interpolated instead of derived from the resource, so as to avoid issues when used in `for_each` keys.

```hcl
output "project_id" {
  description = "Project id."
  value       = "${local.prefix}${var.name}"
  depends_on = [
    google_project.project,
    data.google_project.project,
    google_project_organization_policy.boolean,
    google_project_organization_policy.list,
    google_project_service.project_services,
    google_compute_shared_vpc_service_project.service_projects,
    google_project_iam_member.shared_vpc_host_robots,
    google_kms_crypto_key_iam_member.service_identity_cmek,
    google_project_service_identity.servicenetworking,
    google_project_iam_member.servicenetworking
  ]
}
```

#### Why we don't use random strings in names

This is more a convention than a design principle, but it's still important enough to be mentioned here: we **never use random strings for resource naming** and instead rely on an optional `prefix` variable which is implemented in most modules.

This matches actual use where naming is a key requirement that needs to integrate with company-wide CMDBs and naming schemes used on-prem or in other clouds, and usually is formed by concatenating progressively more specific tokens (something like `myco-gcp-dev-net-hub-0`).

Our approach supports easy implementation of company-specific policies and good readability, while still allowing a fairly compact way of ensuring unique resources have unique names.

```hcl
# prefix = "foo-gcp-dev"

module "project" {
  source = "./modules/project"
  name   = "net-host-0"
  prefix = var.prefix
}

module "project" {
  source = "./modules/project"
  name   = "net-svc-0"
  prefix = var.prefix
}
```

### FAST stage design

Due to their increased complexity and larger scope, FAST stages have some additional design considerations. Please refer to the [FAST documentation](./fast/) for additional context.

#### Standalone usage

Each FAST stage should be designed so that it can optionally be used in isolation, with no dependencies on anything other than its variables.

#### Stage interfaces

> “The best modules are those that provide powerful functionality yet have simple interfaces.”
>
> — John Ousterhout in "A Philosophy of Software Design"

Stages are designed based on the concept of ["contracts" or interfaces](./fast/README.md#contracts-and-stages), which define what information is produced by one stage via outputs, which is then consumed by subsequent stages via variables.

Interfaces are compact in size (few variables) but broad in scope (variables typically leverage maps), so that consumers can declare in variable types only the bits of information they are interested in.

For example, resource management stages only export three map variables: `folder_ids`, `service_accounts`, `tag_names`. Those variables contain values for all the relevant resources created, but consumers are only interested in some of them and only need to declare those: networking stages for example only declare the folder and service account names they need.

```hcl
variable "folder_ids" {
  # tfdoc:variable:source 01-resman
  description = "Folders to be used for the networking resources in folders/nnnnnnnnnnn format. If null, folder will be created."
  type = object({
    networking      = string
    networking-dev  = string
    networking-prod = string
  })
}
```

When creating a new stage or adding a feature to an existing one, always try to leverage the existing interfaces when some of the information you produce needs to cross the stage boundary, so as to minimize impact on producers and consumers logically dependent on your stage.

#### Output files

FAST stages rely on generated provider and tfvars files, as an easy convenience that allows automated setup and passing of contract values between stages.

Files are written to a special GCS bucket in order to be leveraged by both humans and CI/CD workflows, and optionally also written to local storage if needed.

When editing or adding a stage, you are expected to maintain the output files system so any new contact output is also present in files.

### Style guide reference

Similarly to our design principles above, we evolved a set of style conventions that we try to standardize on to make code more legible and uniform. This reduces friction when coding, and ideally moves us closer to the goal of using IaC as live documentation.

#### Group logical resources or modules in separate files

Over time and as our codebase got larger, we switched away from the canonical `main.tf`/`outputs.tf`/`variables.tf` triplet of file names and now tend to prefer descriptive file names that refer to the logical entities (resources or modules) they contain.

We still use traditional names for variables and outputs, but tend to use main only for top-level locals or resources (e.g. the project resource in the `project` module), or for those resources that would end up in very small files.

While some older modules and examples are still using three files, we are slowly bringing all code up to date and any new development should use descriptive file names.

Our `tfdoc` tool has a way of generating a documentation table that maps file names with descriptions and the actual resources and modules they contain, refer to the last section for details on how to activate the mode in your code.

#### Enforce line lengths

We enforce line length for legibility, and adopted the 79 characters convention from other languages for simplicity.

This convention is relaxed for long resource attribute names (even though in some cases you might want to alias them to short local names), and for variable and output descriptions.

In most other cases you should break long lines, especially in `for` and `for_each` loops. Some of the conventions we adopted:

- break after opening and before closing braces/parenthesis
- break after a colon in `for` loops
- add extra parenthesis and breaks to split long ternary operators
- break right before the `:` and `?` in long ternary operators

This is one of many examples.

```hcl
locals {
  sink_bindings = {
    for type in ["bigquery", "pubsub", "logging", "storage"] :
    type => {
      for name, sink in var.logging_sinks :
      name => sink if sink.iam && sink.type == type
    }
  }
}
```

#### Use alphabetical order for outputs and variables

We enforce alphabetical ordering for outputs and variables and have a check that prevents PRs using the wrong order to be merged. We also tend to prefer alphabetical ordering in locals when there's no implied logical grouping (e.g. for successive data transformations).

Additionally, we adopt a convention similar to the one used in Python for private class members, so that locals only referenced from inside the same locals block are prefixed by `_`, as in the example shown in the next section.

```hcl
locals {
  # compute the host project IAM bindings for this project's service identities
  _svpc_service_iam = flatten([
    for role, services in local._svpc_service_identity_iam : [
      for service in services : { role = role, service = service }
    ]
  ])
  _svpc_service_identity_iam = coalesce(
    local.svpc_service_config.service_identity_iam, {}
  )
  svpc_host_config = {
    enabled = coalesce(
      try(var.shared_vpc_host_config.enabled, null), false
    )
    service_projects = coalesce(
      try(var.shared_vpc_host_config.service_projects, null), []
    )
  }
  svpc_service_config = coalesce(var.shared_vpc_service_config, {
    host_project = null, service_identity_iam = {}
  })
  svpc_service_iam = {
    for b in local._svpc_service_iam : "${b.role}:${b.service}" => b
  }
}
```

#### Move complex transformations to locals

When data needs to be transformed in a `for` or `for_each` loop, we prefer moving the relevant code to `locals` so that module or resource attribute values have as little line noise as possible. This is especially relevant for complex transformations, which should be split in multiple smaller stages with descriptive names.

This is an example from the `project` module. Notice how we're breaking two of the rules above: line length in the last local so as to use the same formatting as the previous one, and alphabetical ordering so the order follows the transformation steps. Our rules are meant to improve legibility, so when they don't feel free to ignore them (and sometimes we'll push back anyway).

```hcl
locals {
  _group_iam_roles = distinct(flatten(values(var.group_iam)))
  _group_iam = {
    for r in local._group_iam_roles : r => [
      for k, v in var.group_iam : "group:${k}" if try(index(v, r), null) != null
    ]
  }
  _iam_additive_pairs = flatten([
    for role, members in var.iam_additive : [
      for member in members : { role = role, member = member }
    ]
  ])
  _iam_additive_member_pairs = flatten([
    for member, roles in var.iam_additive_members : [
      for role in roles : { role = role, member = member }
    ]
  ])
  iam = {
    for role in distinct(concat(keys(var.iam), keys(local._group_iam))) :
    role => concat(
      try(var.iam[role], []),
      try(local._group_iam[role], [])
    )
  }
  iam_additive = {
    for pair in concat(local._iam_additive_pairs, local._iam_additive_member_pairs) :
    "${pair.role}-${pair.member}" => pair
  }
}
```

#### The `prefix` variable

If you would like to use a "prefix" variable for resource names, please keep its definition consistent across all modules:

```hcl
# variables.tf
variable "prefix" {
  description = "Optional prefix used for resource names."
  type        = string
  default     = null
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty, please use null instead."
  }
}

# main.tf
locals {
  prefix = var.prefix == null ? "" : "${var.prefix}-"
}
```

For blueprints the prefix is mandatory:

```hcl
variable "prefix" {
  description = "Prefix used for resource names."
  type        = string
  validation {
    condition     = var.prefix != ""
    error_message = "Prefix cannot be empty."
  }
}
```

### Interacting with checks and tools

Our modules are designed for composition and live in a monorepo together with several end-to-end blueprints, so it was inevitable that over time we found ways of ensuring that a change does not break consumers.

Our tests exercise most of the code in the repo including documentation examples, and leverages the [tftest Python library](https://pypi.org/project/tftest/) we developed and independently published on PyPi.

Automated workflows run checks on PRs to ensure all tests pass, together with a few other controls that ensure code is linted, documentation reflects variables and outputs files, etc.

The following sections describe how interact with the above, and how to leverage some of the small utilities contained in this repo.

#### Python environment setup

All our tests and tools use Python, this section shows you how to bring up an environment with the correct dependencies installed.

First, follow the [official guide](https://packaging.python.org/en/latest/guides/installing-using-pip-and-virtual-environments/) so that you have a working virtual environment and `pip` installed.

Once you have created and activated a virtual environment, install the dependencies we use for testing and tools.

```bash
pip install -r tests/requirements.txt
pip install -r tools/requirements.txt
```

#### Automated checks on PRs

We run two GitHub workflows on PRs:

- `.github/workflows/linting.yml`
- `.github/workflows/tests.yml`

The linting workflow tests:

- that the correct copyright boilerplate is present in all files, using `tools/check_boilerplate.py`
- that all Terraform code is linted via `terraform fmt`
- that Terraform variables and outputs are sorted alphabetically
- that all README files have up to date outputs, variables, and files (where relevant) tables, via `tools/check_documentation.py`
- that all links in README files are syntactically correct and valid if internal, via `tools/check_links.py`
- that resource names used in FAST stages stay within a length limit, via `tools/check_names.py`
- that all Python code has been formatted with the correct `yapf` style

You can run those checks individually on your code to address any error before sending a PR, all you need to do is run the same command used in the workflow file from within your virtual environment. To run documentation tests for example if you changed the `project` module:

```bash
./tools/check_documentation.py modules/project
```

Our tools generally support a `--help` switch, so you can also use them for other purposes:

```bash
/tools/check_documentation.py --help
Usage: check_documentation.py [OPTIONS] [DIRS]...

  Cycle through modules and ensure READMEs are up-to-date.

Options:
  -x, --exclude-file TEXT
  --files / --no-files
  --show-diffs / --no-show-diffs
  --show-extra / --no-show-extra
  --help                          Show this message and exit.
```

As a convenience, we provide a script that runs the same set of checks as our GitHub workflow. Before submitting a PR, run `tools/lint.sh` and fix any errors. You can use the tools described above to find out more about the failures.

The test workflow runs test suites in parallel. Refer to the next section for more details on running and writing tests.

## Using and writing tests

Our testing approach follows a simple philosophy: we mainly test to ensure code works, and that it does not break due to changes to dependencies (modules) or provider resources.

This makes testing very simple, as a successful `terraform plan` run in a test case is often enough. We only write more specialized tests when we need to check the output of complex transformations in `for` loops.

As our testing needs are very simple, we also wanted to reduce the friction required to write new tests as much as possible: our tests are written in Python and use `pytest` which is the standard for the language, leveraging our [`tftest`](https://pypi.org/project/tftest/) library, which wraps the Terraform executable and returns familiar data structures for most commands.

Writing `pytest` unit tests to check plan results is really easy, but since wrapping modules and examples in dedicated fixtures and hand-coding checks gets annoying after a while, we developed additional ways that allow us to simplify the overall process.

In the following sections we describe the three testing approaches we currently have:

- [Example-based tests](#testing-via-readmemd-example-blocks): this is perhaps the easiest and most common way to test either a module or a blueprint. You simply have to provide an example call to your module and a few metadata values in the module's README.md.
- [tfvars-based tests](#testing-via-tfvars-and-yaml-aka-tftest-based-tests): allows you to test a module or blueprint by providing variables via tfvar files and an expected plan result in form of an inventory. This type of test is useful, for example, for FAST stages that don't have any examples within their READMEs.
- [Python-based (legacy) tests](#writing-tests-in-python-legacy-approach): in some situations you might still want to interact directly with `tftest` via Python, if that's the case, use this method to write custom Python logic to test your module in any way you see fit.

### Testing via README.md example blocks

This is the preferred method to write tests for modules and blueprints. Example-based tests are triggered from [HCL Markdown fenced code blocks](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-and-highlighting-code-blocks#syntax-highlighting) in any file named README.md, hence there's no need to create any additional files or revert to Python to write a test. Most of our documentation examples are using this method.

To enable an example for testing just use the special `tftest` comment as the last line in the example, listing the number of modules and resources expected.

A [few preset variables](./tests/examples/variables.tf) are available for use, as shown in this example from the `dns` module documentation.

```hcl
module "private-dns" {
  source          = "./modules/dns"
  project_id      = "myproject"
  type            = "private"
  name            = "test-example"
  domain          = "test.example."
  client_networks = [var.vpc.self_link]
  recordsets = {
    "A localhost" = { ttl = 300, records = ["127.0.0.1"] }
  }
}
# tftest modules=1 resources=2
```

This is enough to tell our test suite to run this example and assert that the resulting plan has one module (`modules=1`) and two resources (`resources=2`)

Note that all HCL code examples in READMEs are automatically tested. To prevent this behavior, include `tftest skip` somewhere in the code.

#### Testing examples against an inventory YAML

If you want to go further, you can define a `yaml` "inventory" with the plan and output results you want to test.

Continuing with the example above, imagine you want to ensure the plan also includes the creation of the A record specified in the `recordsets` variable. To do this we add the `inventory` parameter to the `tftest` directive, as shown below.

```hcl
module "private-dns" {
  source          = "./modules/dns"
  project_id      = "myproject"
  type            = "private"
  name            = "test-example"
  domain          = "test.example."
  client_networks = [var.vpc.self_link]
  recordsets = {
    "A localhost" = { ttl = 300, records = ["127.0.0.1"] }
  }
}
# tftest modules=1 resources=2 inventory=recordsets.yaml
```

Next define the corresponding "inventory" `yaml` file which will be used to assert values from the plan. The inventory is loaded from `tests/[module path]/examples/[inventory_name]`. In our example we have to create `tests/modules/dns/examples/recordsets.yaml`.

In the inventory file you have three sections available, and all of them are optional:

- `values` is a map of resource indexes (the same ones used by Terraform state) and their attribute name and values; you can define just the attributes you are interested in and the rest will be ignored
- `counts` is a map of resource types (eg `google_compute_engine`) and the number of times each type occurs in the plan; here too only define the ones that need checking
- `outputs` is a map of outputs and their values; where a value is unknown at plan time use the special `__missing__` token

Going back to our example, we create the inventory with values for the recordset and we also include the zone for good measure.

```yaml
# file: tests/modules/dns/examples/recordsets.yaml
values:
  module.private-dns.google_dns_managed_zone.non-public[0]:
    dns_name: test.example.
    forwarding_config: []
    name: test-example
    peering_config: []
    project: myproject
    reverse_lookup: false
    service_directory_config: []
    visibility: private
  module.private-dns.google_dns_record_set.cloud-static-records["A localhost"]:
    managed_zone: test-example
    name: localhost.test.example.
    project: myproject
    routing_policy: []
    rrdatas:
    - 127.0.0.1
    ttl: 300
    type: A

counts:
  google_dns_managed_zone: 1
  google_dns_record_set: 1
```

#### Using external files

In some situations your module might require additional files to properly test it. This is a common situation with modules that implement [factories](blueprints/factories/README.md) that drive the creation of resources from YAML files. If you're in this situation, you can still use example-based tests as described below:

- create your regular `hcl` code block example and add the `tftest` directive as described above.
- create a new code block with the contents of the additional file and use the `tftest-file` directive. You have to specify a label for the file and a relative path where the file will live.
- update your hcl code block to use the `files` parameters and pass a comma separated list of file ids that you want to make available to the module.

Continuing with the DNS example, imagine you want to load the recordsets from a YAML file

```hcl
module "private-dns" {
  source          = "./modules/dns"
  project_id      = "myproject"
  type            = "private"
  name            = "test-example"
  domain          = "test.example."
  client_networks = [var.vpc.self_link]
  recordsets      = yamldecode(file("records/example.yaml"))
}
# tftest modules=1 resources=2 files=records
```

```yaml
# tftest-file id=records path=records/example.yaml
A localhost:
 ttl: 300
 records: ["127.0.0.1"]
A myhost:
 ttl: 600
 records: ["10.10.0.1"]
```

Note that you can use the `files` parameters together with `inventory` to allow more fine-grained assertions. Please review the [subnet factory](modules/net-vpc#subnet-factory) in the `net-vpc` module for an example of this.

#### Running tests for specific examples

As mentioned before, we use `pytest` as our test runner, so you can use any of the standard [test selection options](https://docs.pytest.org/en/latest/how-to/usage.html) available in `pytest`.

Example-based test are named based on the section within the README.md that contains them. You can use this name to select specific tests.

Here we show a few commonly used selection commands:

- Run all examples:
  - `pytest tests/examples`
- Run all examples for blueprints only:
  - `pytest -k blueprints tests/examples`
- Run all examples for modules only:
  - `pytest -k modules tests/examples`
- Run all examples for the `net-vpc` module:
  - `pytest -k 'modules and net-vpc:' tests/examples`
- Run a specific example (identified by a substring match on its name) from the `net-vpc` module:
  - `pytest -k 'modules and net-vpc: and ipv6' tests/examples`
- Run a specific example (identified by its full name) from the `net-vpc` module:
  - `pytest -v 'tests/examples/test_plan.py::test_example[modules/net-vpc:IPv6:1]'`
- Run tests for all blueprints except those under the gke directory:
  - `pytest -k 'blueprints and not gke' tests/examples`

> [!NOTE]
> The colon symbol (`:`) in `pytest` keyword expression `'modules and net-vpc:'` makes sure that `net-vpc` is matched but `net-vpc-firewall` or `net-vpc-peering` are not.

Tip: to list all tests matched by your keyword expression (`-k ...`) without actually running them, you can use the `--collect-only` flag.

The following command executes a dry run that *lists* all example-based tests for the `gke-cluster-autopilot` module:

```bash
pytest -k 'modules and gke-cluster-autopilot:' tests/examples --collect-only
```

Once you find the expression matching your desired test(s), remove the `--collect-only` flag.

The next command executes an example-based test found in the *Monitoring Configuration* section of the README file for the `gke-cluster-autopilot` module. That section actually has two tests, so the `:2` part selects the second test only:

```bash
pytest -k 'modules and gke-cluster-autopilot: and monitoring and :2' tests/examples
```

#### Generating the inventory automatically

Building an inventory file by hand is difficult. To simplify this task, the default test runner for examples prints the inventory for the full plan if it succeeds. Therefore, you can start without an inventory and then run a test to get the full plan and extract the pieces you want to build the inventory file.

Suppose you want to generate the inventory for the last DNS example above (the one creating the recordsets from a YAML file). Assuming that example is the first code block under the "Private Zone" section in the README for the `dns` module, you can run the following command to build the inventory:

```bash
pytest -s 'tests/examples/test_plan.py::test_example[modules/dns:Private Zone:1]'
```

which will generate a output similar to this:

```
==================================== test session starts ====================================
platform ... -- Python 3.11.2, pytest-7.2.1, pluggy-1.0.0
rootdir: ...
plugins: xdist-3.1.0
collected 1 item

tests/examples/test_plan.py

values:
  module.private-dns.google_dns_managed_zone.non-public[0]:
    description: Terraform managed.
    dns_name: test.example.
    dnssec_config: []
    force_destroy: false
    forwarding_config: []
    labels: null
    name: test-example
    peering_config: []
    private_visibility_config:
    - gke_clusters: []
      networks:
      - network_url: projects/xxx/global/networks/aaa
    project: myproject
    reverse_lookup: false
    service_directory_config: []
    timeouts: null
    visibility: private
  module.private-dns.google_dns_record_set.cloud-static-records["A localhost"]:
    managed_zone: test-example
    name: localhost.test.example.
    project: myproject
    routing_policy: []
    rrdatas:
    - 127.0.0.1
    ttl: 300
    type: A
  module.private-dns.google_dns_record_set.cloud-static-records["A myhost"]:
    managed_zone: test-example
    name: myhost.test.example.
    project: myproject
    routing_policy: []
    rrdatas:
    - 10.10.0.1
    ttl: 600
    type: A

counts:
  google_dns_managed_zone: 1
  google_dns_record_set: 2
  modules: 1
  resources: 3

outputs: {}

.

===================================== 1 passed in 3.46s =====================================
```

You can use that output to build the inventory file.

Note that for complex modules, the output can be very large and includes a lot of details about the resources. Extract only those resources and fields that are relevant to your test. There is a fine balance between asserting the critical bits related to your test scenario and including too many details that end up making the test too specific.

#### Building tests for blueprints

Generally blueprints are used as top-level modules which means that usually their READMEs include sample values for their variables but there are no examples showing how to use them as modules.

If you want to test a blueprint using an example, we suggest adding a "Test" section at the end of the README and include the example there. See any existing blueprint for a [concrete example](blueprints/cloud-operations/asset-inventory-feed-remediation#test).

### Testing via `tfvars` and `yaml` (aka `tftest`-based tests)

The second approach to testing requires you to:

- create a folder in the right `tests` hierarchy where specific test files will be hosted
- define `tfvars` files each with a specific variable configuration to test
- define `yaml` "inventory" files with the plan and output results you want to test
- declare which of these files need to be run as tests in a `tftest.yaml` file

Let's go through each step in succession, assuming you are testing the new `net-lb-app-ext` module.

First create a new folder under `tests/modules` replacing any dash in the module name with underscores. Note that if you were testing a blueprint the folder would go in `tests/blueprints`.

```bash
mkdir tests/modules/net_glb
```

Then define a `tfvars` file with one of the module configurations you want to test. If you have a lot of variables which are shared across different tests, you can group all the common variables in a single `tfvars` file and associate it with each test's specific `tfvars` file (check the [organization module test](./tests/modules/organization/tftest.yaml) for an example).

```hcl
# file: tests/modules/net_glb/test-simple.tfvars
name       = "glb-test-0"
project_id = "my-project"
backend_buckets_config = {
  default = {
    bucket_name = "my-bucket"
  }
}
```

Next define the corresponding "inventory" `yaml` file which will be used to assert values from the plan that uses the `tfvars` file above. In the inventory file you have three sections available:

- `values` is a map of resource indexes (the same ones used by Terraform state) and their attribute name and values; you can define just the attributes you are interested in and the other will be ignored
- `counts` is a map of resource types (eg `google_compute_engine`) and the number of times each type occurs in the plan; here too just define the ones the that need checking
- `outputs` is a map of outputs and their values; where a value is unknown at plan time use the special `__missing__` token

```yaml
# file: tests/modules/net_glb/test-simple.yaml
values:
  google_compute_global_forwarding_rule.default:
    description: Terraform managed.
    load_balancing_scheme: EXTERNAL
  google_compute_target_http_proxy.default[0]:
    name: glb-test-1
counts:
  google_compute_backend_bucket: 1
  google_compute_global_forwarding_rule: 1
  google_compute_health_check: 1
  google_compute_target_http_proxy: 1
  google_compute_url_map: 1
outputs:
  address: __missing__
  backend_service_ids: __missing__
  forwarding_rule: __missing__
  group_ids: __missing__
  health_check_ids: __missing__
  neg_ids: __missing__
```

Create as many pairs of `tfvars`/`yaml` files as you need to test every scenario and feature, then create the file that triggers our fixture and converts them into `pytest` tests.

```yaml
# file: tests/modules/net_glb/tftest.yaml
module: modules/net-lb-app-ext
# if there are variables shared among all tests you can define a common file
# common_tfvars:
#   - defaults.tfvars
tests:
  # run a test named `test-plan`, load the specified tfvars files
  # use the default inventory file of `test-plan.yaml`
  test-plan:
    tfvars: # test-plan.tfvars is always loaded
      - test-plan-extra.tfvars
    inventory:
      - test-plan.yaml
  # You can use `extra_files` to include additional tf files outside 
  # the module's path before running the test.
  # extra_files:  
  #   - ../plugin-x/*.tf

  # You can omit the tfvars and inventory sections and they will
  # default to the name of the test. The following two examples are equivalent:
  #
  # test-plan2:
  #   tfvars:
  #     - test-plan2.tfvars
  #   inventory:
  #     - test-plan2.yaml
  # test-plan2:
```

A good example of tests showing different ways of leveraging our framework is in the [`tests/modules/organization`](./tests/modules/organization) folder.

#### Generating the inventory for `tftest`-based tests

Just as you can generate an initial inventory for example-based tests, you can do the same for `tftest`-based tests. Currently the process relies on an additional tool (`tools/plan_summary.py`) but but we have plans to unify both cases in the future.

As an example, if you want to generate the inventory for the `organization` module using the `common.tfvars` and `audit_config.tfvars` found in `tests/modules/organization/`, simply run `plan_summary.py` as follows:

```bash
$ python tools/plan_summary.py modules/organization \
   tests/modules/organization/common.tfvars \
   tests/modules/organization/audit_config.tfvars

values:
  google_organization_iam_audit_config.config["allServices"]:
    audit_log_config:
    - exempted_members:
      - user:me@example.org
      log_type: DATA_WRITE
    - exempted_members: []
      log_type: DATA_READ
    org_id: '1234567890'
    service: allServices

counts:
  google_organization_iam_audit_config: 1
  modules: 0
  resources: 1

outputs:
  custom_role_id: {}
  custom_roles: {}
  firewall_policies: {}
  firewall_policy_id: {}
  network_tag_keys: {}
  network_tag_values: {}
  organization_id: organizations/1234567890
  sink_writer_identities: {}
  tag_keys: {}
  tag_values: {}

```

You can now use this output to create the inventory file for your test. As mentioned before, please only use those values relevant to your test scenario.

You can optionally pass to the command additional files that your plan might need to properly execute.

In this example we pass in two extra files from the organization folder.

```bash
$ python tools/plan_summary.py modules/organization \
   tests/modules/organization/common.tfvars \
   tests/modules/organization/audit_config.tfvars \
   --extra-files ../my-file-1.tf \
   --extra-files ../my-file-2.yaml
```

### Running end-to-end tests

You can use end-to-end tests to verify your code against GCP API. These tests verify that `terraform apply` succeeds, `terraform plan` is empty afterwards and that `terraform destroy` raises no error.

#### Prerequisites

Prepare following information:

- billing account id
- organization id
- parent folder under which resources will be created
  - (you may want to disable / restore to default some organization policies under this folder)
- decide in which region you want to deploy (choose one, that has wide service coverage)
- (optional) prepare service account that has necessary permissions (able to assign billing account to project, resource creation etc)
- prepare a prefix (this is to provide project and other global resources name uniqueness)

#### How does it work

Each test case is provided by additional environment defined in [variables.tf](tests/examples/variables.tf). This simplifies writing the examples as this follows the same structure as for non-end-to-end tests, and allows multiple, independent and concurrent runs of tests.

The test environment can be provisioned automatically during the test run (which takes ~2 minutes) and destroyed at the end, when all tests finish (option 1 below), which is targeting automated runs in CI/CD pipeline, or it can be provisioned manually (option 2 below) to reduce test time, which might be typical use case for tests run locally.

For development, to keep the feedback loop short, consider using [local sandbox](#creating-sandbox-environment-for-examples) and paste specific example in `main.tf` file.

#### Option 1 - automatically provision and de-provision testing infrastructure

Set variables in environment:

```bash
export TFTEST_E2E_billing_account="123456-123456-123456"  # billing account id to associate projects
export TFTEST_E2E_group_email="group@example.org" # existing group within organization
export TFTEST_E2E_organization_id="1234567890" # your organization id
export TFTEST_E2E_parent="folders/1234567890"  # folder under which test resources will be created
export TFTEST_E2E_prefix="your-unique-prefix"  # unique prefix for projects, no longer than 7 characters
export TFTEST_E2E_region="europe-west4"  # region to use
export TFTEST_E2E_region_secondary="europe-west5" # secondary region to use
```

To use Service Account Impersonation, use provider environment variable

```bash
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=<username>@<project-id>.iam.gserviceaccount.com
```

You can keep the prefix the same for all the tests run, the tests will add necessary suffix for subsequent runs, and in case tests are run in parallel, use separate suffix for the workers.

# Run the tests

```bash
pytest tests/examples_e2e
```

#### Option 2 - Provision manually test environment and use it for tests

##### Provision manually test environment

In `tests/examples_e2e/setup_module` create `terraform.tfvars` with following values:

```tfvars
billing_account = "123456-123456-123456"  # billing account id to associate projects
group_email     = "group@example.org"  # existing group within organization
organization_id = "1234567890"  # your organization id
parent          = "folders/1234567890"  # folder under which test resources will be created
prefix          = "your-unique-prefix"  # unique prefix for projects
region          = "europe-west4"  # region to use
region_secondary = "europe-west5" # secondary region to use
timestamp       = "1696444185" # generate your own timestamp - will be used as a part of prefix for globally unique resources
```

If you use service account impersonation, set `GOOGLE_IMPERSONATE_SERVICE_ACCOUNT`

```bash
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=<username>@<project-id>.iam.gserviceaccount.com
```

Provision the environment using terraform

```bash
(cd tests/examples_e2e/setup_module/ && terraform init && terraform apply)
```

This will generate also `tests/examples_e2e/setup_module/e2e_tests.tfvars` for you, which can be used by tests.

##### Setup your environment

```bash
export TFTEST_E2E_TFVARS_PATH=`pwd`/tests/examples_e2e/setup_module/e2e_tests.tfvars  # generated above
export TFTEST_E2E_prefix="your-unique-prefix"  # unique prefix for projects, no longer than 7 characters
```

##### De-provision the environment

Once you are done with the tests, run:

```bash
(cd tests/examples_e2e/setup_module/ && terraform apply -destroy)
```

To remove all resources created for testing and `tests/examples_e2e/setup_module/e2e_tests.tfvars` file.

#### Run tests

Run tests using:

```bash
pytest tests/examples_e2e
```

#### Creating sandbox environment for examples

When developing it is convenient to have a module that represents chosen example, so you can inspect the environment after running apply and quickly verify fixes. Shell script [create_e2e_sandbox.sh](tools/create_e2e_sandbox.sh) will create such environment for you.

Prepare the environment variables as defined in Option 1 above and run:

```bash
tools/create_e2e_sandbox.sh <directory>
```

The script will create in `<directory>` following structure:

```
<directory>
├── default-versions.tf
├── e2e_tests.auto.tfvars -> infra/e2e_tests.tfvars
├── fabric -> <cloud-foundation-fabric root>
├── infra
│   ├── e2e_tests.tfvars
│   ├── e2e_tests.tfvars.tftpl
│   ├── main.tf
│   ├── randomizer.auto.tfvars
│   ├── terraform.tfvars
│   └── variables.tf
├── main.tf
└── variables.tf
```

The `infra` directory contains the sandbox infrastructure as well as all environment variables dumped into `terraform.tfvars` file. The script runs `terraform init` and `terraform apply -auto-approve` in this folder.

The `<directory>` has empty `main.tf` where you can paste any example, and it will get all necessary variables from `e2e_tests.auto.tfvars` file.

If there are any changes to the test sandbox, you can rerun the script and only changes will be applied to the project.

#### Cleaning up interrupted E2E tests / failed destroys

Tests take the effort to clean after themselves but in following situations some resources may be left in GCP:

- you interrupt the test run
- `terraform destroy` failed (for example, because of some bug in the example of module code)

To clean up the old dangling resources you may run this commands, to remove folders and projects older than 1 week

```bash

for folder_id in $(
  gcloud resource-manager folders list --folder "${TFTEST_E2E_parent}" --filter="createTime<-P1W" --format='value(name)'
  ) ; do
  for project_id in $(
  gcloud alpha projects list --folder "${folder_id}" --format='value(project_id)'
  ) ; do
    echo $project_id
    gcloud projects delete --quiet "${project_id}"
  done
  gcloud resource-manager folders delete --quiet "${folder_id}"
done
```

Take care, as this may also attempt to remove folders/projects created for Option 2 or sandbox.

### Writing tests in Python (legacy approach)

Where possible, we recommend using the testing methods described in the previous sections. However, if you need it, you can still write tests using Python directly.

In general, you should try to use the `plan_summary` fixture, which runs a a terraform plan and returns a `PlanSummary` object. The most important arguments to `plan_summary` are:

- the path of the Terraform module you want to test, relative to the root of the repository
- a list of paths representing the tfvars file to pass in to terraform. These paths are relative to the python file defining the test.

If successful, `plan_summary` will return a `PlanSummary` object with the `values`, `counts` and `outputs` attributes following the same semantics described in the previous section. You can use this fields to write your custom tests.

Like before let's imagine we're writing a (python) test for `net-lb-app-ext` module. First create a new folder under `tests/modules` replacing any dash in the module name with underscores. You also need to create an empty `__init__.py` file in it, to ensure `pytest` discovers you new tests automatically.

```bash
mkdir tests/modules/net_glb
touch tests/modules/net_glb/__init__.py
```

Now create a file containing your tests, e.g. `test_plan.py`:

```python
def test_name(plan_summary, tfvars_to_yaml, tmp_path):
  s = plan_summary('modules/net-lb-app-ext', tf_var_files=['test-plan.tfvars'])
  address = 'google_compute_url_map.default'
  assert s.values[address]['project'] == 'my-project'
```

For more examples on how to write python tests, check the tests for the [`organization`](./tests/modules/organization/test_plan_org_policies.py) module.

### Running tests from a temporary directory

Most of the time you can run tests using the `pytest` command as described in previous. However, the `plan_summary` fixture allows copying the root module and running the test from a temporary directory.

To enable this option, just define the environment variable `TFTEST_COPY` and any tests using the `plan_summary` fixture will automatically run from a temporary directory.

Running tests from temporary directories is useful if:

- you're running tests in parallel using `pytest-xdist`. In this case, just run you tests as follows:

  ```bash
  TFTEST_COPY=1 pytest -n 4
  ```

- you're running tests for the `fast/` directory which contain tfvars and auto.tfvars files (which are read by terraform automatically) making your tests fail. In this case, you can run

  ```
  TFTEST_COPY=1 pytest fast/
  ```

## Fabric tools

The main tool you will interact with in development is `tfdoc`, used to generate file, output and variable tables in README documents.

By default, `tfdoc` expects the path to a folder as its argument, and will parse variables and outputs files contained in it and embed generated tables in its README file.

You decide where the generated tables will be placed (or replaced if they already exist) via two special HTML comment tags, that mark the beginning and end of the space that will be managed by `tfdoc`.

```html
<!-- BEGIN TFDOC -->
<!-- everything between these two tags will be managed by tfdoc -->
<!-- END TFDOC -->
```

You can also set `tfdoc` options directly in a README file, so that a) you don't need to remember to pass the right options when running the tool, and b)  our automated workflow checks will know how to generate the right output.

```html
<!-- the following comment configures tfdoc options -->
<!-- TFDOC OPTS files:1 show_extra:1 -->
```

When generating the files table, a special annotation can be used to fill in the file description in Terraform files:

```hcl
# tfdoc:file:description Networking stage resources.
```

The tool can also be run so that it prints the generated output on standard output instead of replacing in files. Run `tfdoc --help` to see all available options.

## Cutting a new release

Cutting a new release is mostly about updating `CHANGELOG.md` - luckily the [changelog tool](./tools/changelog.py) will do the heavy lifting for you.

In order to use it, you will need to generate a [Github Token](https://github.com/settings/tokens/). The token does not require any scope, so if you're purposely generating one, make sure to avoid adding any. Store the token in your favourite secret manager for future usage.

Also make sure to work in a `venv` where all the [requirements for the fabric tools](./tools/requirements.txt) are installed.

```bash
cd cloud-foundation-fabric
git checkout master
git pull
./tools/changelog.py --write --token $YOURGITHUBTOKEN
```

After ~1 minute, the [CHANGELOG.md](./CHANGELOG.md) file will be updated by the tool - review any change by running `git diff` and make sure no unlabeled PR is listed. If you find unlabeled PRs, visit their link and add the relevant labels (e.g. on:FAST, on:blueprints, on:module, ...), and finally run again

```bash
./tools/changelog.py --write --token $YOURGITHUBTOKEN
```

Now open the up-to-date CHANGELOG.md in your favorite editor, and append the new release H2 after the `## [Unreleased]` header you see at the top - e.g. if the latest version is `29.0.0`, add an header for `30.0.0` and mark todays date as follows:

```md
[...]
## [Unreleased]
<!-- None < 2024-03-20 13:57:56+00:00 -->

## [30.0.0] - 2024-03-20

## [29.0.0] - 2024-01-24

### BLUEPRINTS
[...]
```

Now scroll to the bottom section of the document, and update the release links by adding `30.0.0` and updating `Unreleased` as follows:

```md
[Unreleased]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v30.0.0...HEAD
[30.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v29.0.0...v30.0.0
[29.0.0]: https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/compare/v28.0.0...v29.0.0
```

Once done, add, commit and push changes to master.

As CHANGELOG.md is now ready, [create a new release from the Github UI](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/releases/new), and use `vXX.Y.Z` as the release tag and title (don't forget the `v` in front!).

As a description, copy the whole content added to [CHANGELOG.md](./CHANGELOG.md) for the current release, and then click the 'Publish release' button.

As a last cleanup for the CHANGELOG.md file, run

```bash
git pull
./tools/changelog.py --write --token $TOKEN --release Unreleased --release vXX.Y.Z
git diff
```

And add / commit / push any change in case of a diff.
