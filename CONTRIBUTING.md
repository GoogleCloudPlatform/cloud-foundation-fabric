# Contributing

Contributors are the engine that keeps Fabric alive so if you were or are planning to be active in this repo, a huge thanks from all of us for dedicating your time!!!

## Table of Contents

[I just found a bug / have a feature request!](#i-just-found-a-bug--have-a-feature-request)

[Quick developer workflow](#quick-developer-workflow)

[Developer's Handbook](#developers-handbook)

- [The Zen of Fabric](#the-zen-of-fabric)
- [Design principles in action](#design-principles-in-action)
- [FAST stage design](#fast-stage-design)
- [Style guide reference](#style-guide-reference)
- [Checks, tests and tools](#checks-tests-and-tools)

## I just found a bug / have a feature request

Feel free to open a new issue if you find something that does not work, need clarifications on usage (a good incentive for us to improve docs!), or have a feature request.

If you feel like tackling it directly via a PR check out the quick developer workflow below, we always welcome new contributors!

## Quick developer workflow

For small or first time issues the simplest way is to fork our repo, but if you are a regular contributor or are developing a large addition, ask us to be added directly to repo so you can work on local branches, it makes life easier for both of us!

Fork or clone and go through the usual edit/add/commit cycle until your code is ready.

```bash
git checkout master
git pull
git checkout -b username/my-feature
git add -A
git commit -m "changed ham so that spam and eggs"
```

Once you are satisfied, make sure Terraform linting is ok. If you changed Python code you need to conform to our standard linting, see the last section for details on how to configure it.

```bash
terraform fmt -recursive
```

If you changed variables or outputs you need to regenerate the relevant tables in the documentation via our `tfdoc` tool. For help installing Python requirements and setting up virtualenv see the last section.

```bash
# point tfdoc to the folder containing your changed variables and outputs
./tools/tfdoc.py modules/my-changed-module
```

If the folder contains files which won't be pushed to the repository, for example provider files used in FAST stages, you need to change the command above to specifically exclude them from `tfdoc` geerated output.

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
pytest tests/doc_examples
```

Once everything looks good, add/commit any pending changes then push and open a PR on GitHub. We typically enforce a set of design and style conventions, so please make sure you have familiarized yourself with the following sections and implemented them in your code, to avoid lengthy review cycles.

## Developer's handbook

Over the years we have assembled a specific set of design principles and style conventions that allow for better readability and make understanding and changing code more predictable.

We expect your code to conform to those princinples in both design and style, so that it integrates well with the rest of Fabric/FAST without having to go through long and painful PR cycles before it can be merged.

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

Our modules -- and in a much broader sense our FAST stages -- are all designed to encapsulate a set of functionally related resources and their configurations, so that from the outside (when using the module) they can be read as a single block, and referenced as a single unit trusting that they will be fully operational.

Taking IAM as an example, we do not offer a single module to centrally manage role bindings (product/feature based approach) but implement it instead in each module since:

- users understand IAM as an integral part of each resource, having bindings in the same context improves readability and speeds up changes
- resources are not fully usable before their relevant IAM bindings have been applied, encapsulating those allows referencing fully configured resources from the outside
- managing resources and their bindings in a single module makes code more portable with less dependencies

The most extensive examples of this approach are our resource management modules. The `project` modules for example encapsulates resources for project, project services, logging sinks, project-level IAM bindings, Shared VPC enablement and attachment, metrics scope, budget alerts, organization policies, and several other functionality in a single place.

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
    attach               = true
    host_project         = "project-host"
    service_identity_iam = {}
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

One other practical consequence of this design principle is supporting common use cases via interfaces that don't directly map to a resource. The example below shows support for enabling service identities access to KMS keys used for CMEK encryption in the `project` module: there's no specific resource for service identities, but it's such a frequent use case that we support them directly in the module.

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
    attach               = true
    host_project         = "project-host"
    service_identity_iam = {}
  }
}
```

#### Design compact variable spaces

Designing variable spaces is one of the most complex operations to get right, as they are the main entrypoint through which users consume modules, examples and FAST stages. We always strive to **design small variable spaces by leveraging objects and implementing defaults** so that users can quickly produce highly legible code.

One of many examples of this approach comes from disk support in the `compute-vm` module, where preset defaults allow quick VM management with very few lines of code, and optional variables allow progressively complicating code when more control is needed.

This brings up an instance with a 10GB PD baanced boot disk using a Debian 11 image, and is generally a good default when a quick VM is needed for experimantation.

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
  zone     = "europe-west1-b"
  name       = "test"
  boot_disk = {
    image = "projects/debian-cloud/global/images/family/cos-97-lts"
    type = "pd-balanced"
    size = 10
  }
}
```

Where this results in objets with too many attributes, we usually split in required and optional by adding a second level, as in this example adding extra disks to the VM where `attached_disks[].options` is an object type and can be set to null if not needed.

```hcl
module "simple-vm-example" {
  source     = "./modules/compute-vm"
  project_id = var.project_id
  zone     = "europe-west1-b"
  name       = "test"
  attached_disks = [
    { name="data", size =10, source=null, source_type=null, options = null }
  ]
}
```

Whenever options are not passed like in the example above, we typically infer their values from a defaults variable which can be customized when using defaults across several items. In the following example instead of specifying regional PD options for both disks, we set their options to `null` and change the defaults used for all disks.

```hcl
module "simple-vm-example" {
  source     = "./modules/compute-vm"
  project_id = var.project_id
  zone     = "europe-west1-b"
  name       = "test"
  attached_disk_defaults = {
    auto_delete = false
    mode = "READ_WRITE"
    replica_zone = "europe-west1-c"
    type = "pd-balanced"
  }
  attached_disks = [
    { name="data1", size =10, source=null, source_type=null, options = null },
    { name="data2", size =10, source=null, source_type=null, options = null }
  ]
}
```

#### Depend outputs on internal resources

We mentioned this principle when discussing encapsulation above but it's worth repating it explicitly: **set explicit dependencies in outputs so consumers will wait for full resource configuration**.

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

This is more a convention than a design principle, but it's still important enough to be mentioned here: we **never use random resources for naming** and instead rely on an optional `prefix` variable which is implemented in most modules.

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

### Style guide reference

Similarly to our design principles above, we evolved a set of style conventions that we try to standardize on to make code more legible and uniform. This reduces friction when coding, and ideally moves us closer to the goal of using IaC as live documentation.

#### Group logical resources or modules in separate files

#### Enforce line lengths

#### Use alphabetical order for locals, outputs, variables

#### Move complex transformations to locals

### Interacting with checks, tests and tools

#### Python environment setup

#### Automated checks on PRs

#### Using and writing tests
