Let's build a new module `resource-factory` module (i.e. under fast/stages) that allows users to specify all the resource-level components for an application or service via a YAML interface. Use the `project-factory` and `vpc-factory` modules as inpiration, and pay particular attention to how context interpolation is implemented (see also ../../adrs/20251013-context-locals.md).

The new module should not use Terraform resources directly, but leverage the existing low level modules in this repository. Modules already specify the right interface for the underlying resources via variable types, this should be the format for each resource schema and the corresponding YAML in the new module. This will also need to be abstracted in a tool, so as to keep the resource factory aligned with future lower level changes to the underlying modules.

Like the project factory, the new module should take care to not break the lower level interfaces, by using locals and try statements appropriately so as to pass valid data.

Interview me until everything is completely defined and clear to start implementation, then draft a high level plan and the inner tasks to complete it.

---

Got it — so this is a module at modules/resource-factory/ (or similar name), in the same family as modules/project-factory and modules/net-vpc-factory. The FAST stage wrapper comes later.

That clarifies the placement. The remaining questions still stand — let me re-frame them for the module context:

1. Which lower-level modules should it support initially? All ~80, or a curated subset to start?

Let's start by supporting the most common resources we need to deploy an application to GCP:

- compute-vm
- net-lb-int
- net-lb-app-int
- gcs
- cloudsql
- artifact-registry
- pubsub
- bigquery dataset
- filestore
- secret manager
- service account

1. YAML structure — per-application (one YAML with all resource types for an app) or per-resource-type (separate directories/files per resource type, like the project-factory does for projects, folders, budgets)?

Important detail: this module is single application. The future stage will leverage terraform workspaces. So the answer is: one folder/file per type.

1. The "tool" — a code generator that reads lower-level module variables.tf files and auto-generates the factory plumbing (locals, module calls, YAML schema)?

Here we slightly changed our mind: we will develop the tool as a separate project, we will ask you to convert the schemas directly at this stage.

1. Cross-resource references — should resources created within the same factory run be referenceable by each other via context (e.g., a Cloud Run service referencing a Secret Manager secret created in the same run)?

Yes, and also accept external static references via var.contexts like in the other modules.

1. Module name — resource-factory, application-factory, or something else? I notice the modules/application-factory/ directory already exists (with just the PROMPT.md file).

Ignore PROMPT.md we're using to track our prompts, reuse the folder.
