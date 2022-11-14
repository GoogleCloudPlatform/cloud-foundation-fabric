# Contributing

Contributors are the engine that keeps Fabric alive so if you were or are planning to be active in this repo, a huge thanks from all of us for dedicating your time!!! If you have free time and are looking for suggestions on what to work on, our issue tracker generally has a few pending feature requests: you are welcome to send a PR for any of them.

## Table of Contents

[I just found a bug / have a feature request!](#i-just-found-a-bug--have-a-feature-request)

[Quick developer workflow](#quick-developer-workflow)

[Developer's Handbook](#developers-handbook)

- [The Zen of Fabric](#the-zen-of-fabric)
- [Design principles in action](#design-principles-in-action)
- [FAST stage design](#fast-stage-design)
- [Style guide reference](#style-guide-reference)
- [Checks, tests and tools](#interacting-with-checks-tests-and-tools)

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
    compute = [local.kms.europe-west1.compute]
    storage = [local.kms.europe.gcs]
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
    image = "projects/debian-cloud/global/images/family/cos-97-lts"
    type = "pd-balanced"
    size = 10
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

If you would like to use a "prefix" variable for resource names, please keep its definition consistent across all code:
```hcl
# variables.tf
variable "prefix" {
  description = "Optional prefix used for resource names."
  type        = string
  default     = null
  validation {
    condition = var.prefix != ""
    error_message = "Prefix can not be empty, please use null instead."
  }
}

# main.tf
locals {
  prefix = var.prefix == null ? "" : "${var.prefix}-"
}
```

### Interacting with checks, tests and tools

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

The test workflow runs test suites in parallel. Refer to the next section for more details on running and writing tests.

#### Using and writing tests

Our testing approach follows a simple philosophy: we mainly test to ensure code works, and it does not break due to changes to dependencies (modules) or provider resources.

This makes testing very simple, as a successful `terraform plan` run in a test case is often enough. We only write more specialized tests when we need to check the output of complex transformations in `for` loops.

As our testing needs are very simple, we also wanted to reduce the friction required to write new tests as much as possible: our tests are written in Python, and use `pytest` which is the standard for the language. We adopted this approach instead of others (Inspec/Kitchen, Terratest) as it allows writing simple functions as test units using Python which is simple and widely known.

The last piece of our testing framework is our [`tftest`](https://pypi.org/project/tftest/) library, which wraps the Terraform executable and returns familiar data structures for most commands.

##### Testing end-to-end examples

Putting it all together, here is how an end-to-end blueprint test works.

Each example is a Python module in its own directory, and a Terraform fixture that calls the example as a module:

```bash
tests/blueprints/cloud_operations/iam_delegated_role_grants/
├── fixture
│   ├── main.tf
│   └── variables.tf
├── __init__.py
└── test_plan.py
```

One point of note is that the folder contains a Python module, so any dash needs to be replaced with underscores to make it importable. The actual test in the `test_plan.py` file looks like this:

```python
def test_resources(e2e_plan_runner):
  "Test that plan works and the numbers of resources is as expected."
  modules, resources = e2e_plan_runner()
  assert len(modules) == 6
  assert len(resources) == 18
```

It uses our pytest `e2e_plan_runner` fixture, which assumes a Terraform test setup is present in the `fixture` folder alongside the test file, runs `plan` on it, and returns the number of modules and resources.

The Terraform fixture is a single block that runs the whole example as a module, and a handful of variables that can be used to test different configurations (not used above so they could be replaced with static strings).

```hcl
module "test" {
  source         = "../../../../../blueprints/cloud-operations/asset-inventory-feed-remediation"
  project_create = var.project_create
  project_id     = var.project_id
}
```

You can run this test as part of or entire suite of tests, the blueprints suite, or individually:

```bash
# run all tests
pytest
# only run example tests
pytest tests/blueprints
# only run this example tests
pytest tests/blueprints/cloud_operations/iam_delegated_role_grants/
# only run a single unit
pytest tests/blueprints/cloud_operations/iam_delegated_role_grants/test_plan.py::test_resources
```

##### Testing modules

The same approach used above can also be used for testing modules when a simple plan is enough to validate code. When specific features need to be tested though, the `plan_runner` pytest fixture can be used so that plan resources are returned for inspection.

The following example from the `project` module leverages variables in the Terraform fixture to define which module resources are returned from plan.

```python
def test_iam(plan_runner):
  "Test IAM bindings."
  iam = (
      '{"roles/owner" = ["user:one@example.org"],'
      '"roles/viewer" = ["user:two@example.org", "user:three@example.org"]}'
  )
  _, resources = plan_runner(iam=iam)
  roles = dict((r['values']['role'], r['values']['members'])
               for r in resources if r['type'] == 'google_project_iam_binding')
  assert roles == {
      'roles/owner': ['user:one@example.org'],
      'roles/viewer': ['user:three@example.org', 'user:two@example.org']}
```

#### Testing documentation examples

Most of our documentation examples are also tested via the `examples` test suite. To enable an example for testing just use the special `tftest` comment as the last line in the example, listing the number of modules and resources tested.

A few preset variables are available for use, as shown in this example from the `dns` module documentation.

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

#### Fabric tools

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
