# Contributing

Contributors are the engine that keeps Fabric alive so if you were or are planning to be active in this repo, a huge thanks from all of us for dedicating your time!!!

## Table of Contents

[I just found a bug / have a feature request!](#aaa)

[Quick developer workflow](#aaa)

[Developer's Handbook](#a)

- [The Zen of Fabric](#aaa)
- [Design principles in action](#aaa)
- [FAST stage design](#aaa)
- [Style guide reference](#aaa)
- [Interacting with checks, tests and tools](#testing)

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

Taking IAM as an example, we do not offer a single module to centrally manage role bindings but implement it instead in each module since:

- users typically understand IAM as an integral part of each resource, having bindings in the same context improves readability and speeds up changes
- resources are typically not fully usable before their relevant IAM bindings have been applied, encapsulating those allows referencing fully configured resources from the outside
- managing resources and their bindings in a single module makes code more portable with less dependencies

Our modules -- and in a much broader sense our FAST stages -- are all designed encapsulate a set of functionally related resources and their configurations, so that from the outside (when using the module) they can be read as a single block, and referenced as a single unit trusting that they will be fully operational.

The most extensive examples of this approach are our resource management modules. The `project` modules for example encapsulates resources for project, project services, logging sinks, project-level IAM bindings, Shared VPC enablement and attachment, metrics scope, budget alerts, organization policies, and several other functionality in a single place.

```hcl
module "project" {
  source          = "./modules/project"
  billing_account = "123456-123456-123456"
  name            = "project-example"
  parent          = "folders/1234567890"
  prefix          = "foo"
  services        = [
    "container.googleapis.com",
    "stackdriver.googleapis.com"
  ]
  policy_boolean = {
    "constraints/compute.disableGuestAttributesAccess" = true
    "constraints/compute.skipDefaultNetworkCreation" = true
  }
  service_encryption_key_ids = {
    compute = [
      local.kms.europe-west1.compute,
      local.kms.europe-west3.compute,
    ]
    storage = [
      local.kms.europe.gcs,
    ]
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

#### Model interfaces on actual use

One other important way in which we try to reduce cognitive fatigue and increase legibility is by implementing the same functionality via different interfaces.

The best example of this approach is IAM: given its importance we implement both a role-based interface and a group-based interface, which is less verbose and makes it easy to understand at a glance the roles assigned to a specific group. Both interfaces provide data that is then internally combined to drive the same IAM binding resource, and are available for authoritative and additive roles.

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

Host-based management, typically used where absolute control over service project attachment is needed:

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

Service-based attachment, more common and typically used to delegate service project attachment at project creation, possibly from a project factory (we use this in FAST).

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

Mention outputs and use project service accounts as an example

#### Design compact variable spaces

Aaa

#### Depend outputs on internal resources

One important consequence of this approach is a much reduced need for explicit dependency declarations when combining modules, as modules' outputs already have dependencies in place on relevant internal resources.

As an example, users can safely reference the project module's `project_id` output from other modules, knowing that the dependency tree for project configurations (service activation, IAM, etc.) has already been defined inside the module itself.

#### Why we don't use random strings in names

Mention prefix

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
