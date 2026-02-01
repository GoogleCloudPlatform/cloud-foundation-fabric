# PRD: Refactoring FAST Data Platform Stage (Stage 3)

## 1. Objective

Refactor the FAST Data Platform stage (`fast/stages/3-data-platform-dev`) to align with the modern FAST architecture principles (exemplified by stages 0, 1, and 2). The goal is to standardize configuration management, leverage the `project-factory` module for resource creation, and improve maintainability and scalability.

## 2. Goals

1.  **Configuration via YAML and Schema**: Move from custom Terraform logic iterating over locals to a file-based configuration approach (`defaults.yaml` + `data/` directory) validated by JSON schemas.
2.  **Embed Project Factory**: Replace discrete `module "project"` and `module "folder"` calls with a single embedded usage of the `project-factory` module (`modules/project-factory`).
3.  **Context Replacements**: Utilize context variables (IAM principals, KMS keys, etc.) to share values effectively between modules, adhering to the standard `local.ctx` pattern found in other stages.
4.  **Preserve Semantics**: Maintain the existing logical hierarchy (Domains, Shared Projects, Data Products) while adapting to the `project-factory` data model.

## 3. Basic Principles

*   **Module-Driven Schemas**: Schemas for high-level objects (Data Domains, Data Products, etc.) must be grounded in the schemas of the underlying modules (e.g., `project-factory`, `dataplex-aspect-types`). Start with the module schema and extend/adapt only as necessary for the stage's specific abstractions.
*   **FAST Standard Derivation**: Implementation patterns (code structure, context handling, variable naming, YAML consumption) must be directly derived from the existing FAST stages 0, 1, and 2. Consistency with the "modern" FAST approach is paramount.
*   **Context Definition & Alignment**: `defaults.yaml` serves as the authoritative source for static environment context (IAM principals, KMS keys) and baseline project configuration (common services, locations). Keys defined here (e.g., `dp-admin`) are the canonical references used across all Domain and Product YAMLs.
*   **Iterative & Parallel**: Development occurs in a parallel `2-data-platform` directory to avoid breaking the existing stage. We iterate through layers: Schemas -> Defaults -> Central Project -> Domains -> Products.
*   **Context-First**: Leverage `local.ctx` and `var.context` for all cross-module dependency management, replacing ad-hoc variable passing.
*   **Explicit Context Keys**: Use explicit prefixes (e.g., `$iam_principals:group-name`) in YAML configurations to trigger context replacement. This enables schema validation and clear intent.
*   **YAML Style**: Avoid using double quotes for strings in YAML unless necessary (e.g., for reserved characters or special formatting).
*   **Configuration-Driven**: All logic should be driven by the YAML configuration files in `data/`, minimized hard-coded logic in Terraform files.

## 4. Current Architecture vs. Target Architecture

### Current State
- **Configuration**: Defined in `locals` within `data-domains.tf` and `data-products.tf` (or implicitly via complex variable objects).
- **Resource Creation**:
    - `module "dd-folders"` (Domain Folders)
    - `module "dd-dp-folders"` (Data Product Sub-folders)
    - `module "dd-projects"` (Domain Shared Projects)
    - `module "dp-projects"` (Data Product Projects)
    - Separate modules for Service Accounts and IAM.
- **Complexity**: High custom logic to manage the specific hierarchy and inter-dependencies.

### Target State
- **Configuration**:
    - `data/defaults.yaml`: Stage-wide defaults (IAM, locations, etc.), validated by `defaults.schema.json`.
    - `data/domains/*.yaml`: Definitions for Data Domains (custom schema or adapted project schema).
    - `data/products/*.yaml`: Definitions for Data Products (custom schema or adapted project schema).
- **Resource Creation**:
    - **One** `module "project-factory"` call in `factory-projects.tf` (or similar).
    - The module receives constructed `folders` and `projects` maps derived from the YAML configuration.
- **Hierarchy Management**:
    - The specific "Domain -> Shared Project + DP Folder -> DP Projects" hierarchy will be generated programmatically in `main.tf` locals before being passed to the project factory.

## 5. Detailed Design

### 5.1 Configuration Structure & Schemas

We will adopt the standard `schemas/` directory structure.

*   **Defaults**: Reuse `fast/stages/2-project-factory/schemas/defaults.schema.json`.
*   **Data Domains**: Create `schemas/data-domain.schema.json`. This schema will compose folder and project attributes, defining the configuration for the Domain Folder and the Shared Project.
*   **Data Products**: Create `schemas/data-product.schema.json`. This schema will extend the project schema, adding specific attributes like `domain` (link to parent) and `dataset` configurations.
*   **Auxiliary Resources**:
    *   `schemas/aspect-types.schema.json`: For `data/aspect-types/*.yaml`.
    *   `schemas/tags.schema.json`: For `data/tags/*.yaml` (if needed, or reuse project factory's tags schema).

**`data/defaults.yaml`**
```yaml
# Global defaults for projects
projects:
  defaults:
    locations:
      storage: EU
      logging: EU
      bigquery: EU
    billing_account: "012345-678901-ABCDEF"
```

**`data/domains/marketing.yaml`** (Example)
```yaml
name: "Marketing Domain"
folder_config:
  iam:
    roles/viewer:
      - group:marketing-viewers@example.com
project_config:
  services:
    - bigquery.googleapis.com
service_accounts:
  automation: # definition for domain automation SA
    iam_self_roles: []
```

**`data/products/marketing-leads.yaml`** (Example)
```yaml
domain: "marketing" # Link to parent domain
services:
  - bigquery.googleapis.com
iam:
  roles/bigquery.dataEditor:
    - group:product-devs@example.com
```

### 5.2 Transformation Logic (Terraform Locals)

In `main.tf`, we will implement the standard loading pattern seen in stages 2.

**`main.tf`**
```hcl
locals {
  # ... paths ...
  _defaults = yamldecode(file(local.paths.defaults))
  
  # Standard context merging logic
  _ctx = { ... }
  ctx = merge(local._ctx, { ... })

  # Project Defaults Logic
  project_defaults = {
    defaults = merge(
      {
        billing_account = var.billing_account.id
        prefix          = var.prefix
        # Migrate other key variables here
      },
      try(local._defaults.projects.defaults, {})
    )
    overrides = try(local._defaults.projects.overrides, {})
  }
}
```

**Logic for Domain/Product Transformation:**
We will need to read `data/domains/*.yaml` and `data/products/*.yaml` and transform them into the `folders` and `projects` structures expected by `project-factory`.

1.  **Domains**:
    *   Map `data/domains/{name}.yaml` -> Folder `{name}`.
    *   Map `data/domains/{name}.yaml` -> Folder `{name}/products`.
    *   Map `data/domains/{name}.yaml` -> Project `{name}-shared`.
2.  **Products**:
    *   Map `data/products/{name}.yaml` -> Project `{name}` (parented under `{domain}/products` folder).

### 5.3 Integration with Project Factory

**`factory.tf`**
```hcl
module "project-factory" {
  source = "../../../modules/project-factory"
  
  # Context for replacements (IAM, etc.)
  context = local.ctx
  
  # Generated inputs
  folders  = local.generated_folders
  projects = local.generated_projects
  
  # Default configurations
  data_defaults  = local.project_defaults.defaults
  data_overrides = local.project_defaults.overrides

  # Factories Config (passing through)
  factories_config = var.factories_config
}
```

## 6. Migration Strategy

Refactoring will change the Terraform addresses of resources.
*   **Old**: `module.dd-folders["marketing"]`
*   **New**: `module.project-factory.module.folders["marketing"]`

**Action**: `moved` blocks will be critical. The logic should aim to produce predictable keys to minimize state friction.

## 7. Constructs Mapping

### 7.1 Current High-Level Constructs

*   **Central Project**: Manually defined via `module "central-project"`. Holds Aspect Types, Policy Tags.
*   **Data Domains**: Defined via `local.data_domains` (merging files/variables).
    *   **Domain Folder**: `module "dd-folders"`.
    *   **Products Sub-folder**: `module "dd-dp-folders"`.
    *   **Shared Project**: `module "dd-projects"`.
    *   **Service Accounts**: `module "dd-service-accounts"`.
*   **Data Products**: Defined via `local.data_products`.
    *   **Product Project**: `module "dp-projects"`.
    *   **Service Accounts**: `module "dp-service-accounts"`.
*   **Aspect Types**: Defined via `module "central-aspect-types"`.
*   **Policy Tags**: Defined via `module "central-policy-tags"`.

### 7.2 Target High-Level Constructs

*   **Central Project**: Defined in `data/projects/central.yaml` (or similar). Managed by `module "project-factory"`.
*   **Data Domains**: Defined in `data/domains/*.yaml`.
    *   **Folders**: Generated programmatically and passed to `project-factory`.
    *   **Shared Project**: Generated programmatically and passed to `project-factory`.
    *   **Service Accounts**: Defined within the domain YAML, passed to `project-factory` (project-level SAs).
*   **Data Products**: Defined in `data/products/*.yaml`.
    *   **Product Project**: Generated programmatically and passed to `project-factory`.
    *   **Service Accounts**: Defined within the product YAML, passed to `project-factory`.
*   **Aspect Types**: Defined in `data/aspect-types/*.yaml`. Managed by `module "dataplex-aspect-types"` (driven by YAML).
*   **Policy Tags**: Defined in `data/tags/*.yaml` (future). Managed by `module "data-catalog-policy-tag"` (driven by YAML).

## 8. Development Strategy

We will adopt a "clean slate" parallel development approach to ensure stability and incremental verification.

### 8.1 Workspace Setup
1.  Create a new directory `fast/stages/2-data-platform` (parallel to the existing `3-data-platform-dev`).
2.  This isolated environment allows us to reference the existing code while building the new architecture from scratch.

### 8.2 Step-by-Step Implementation Plan

**Phase 1: Foundation & Schemas**
1.  **Schema Generation**:
    *   **Defaults**: `schemas/defaults.schema.json` (reuse project-factory).
    *   **Data Domains**: `schemas/data-domain.schema.json` (compose folder/project attributes).
    *   **Data Products**: `schemas/data-product.schema.json` (extend project schema).
    *   **Aspects/Tags**: `schemas/aspect-types.schema.json`, `schemas/tags.schema.json`.
    *   Store all in `fast/stages/2-data-platform/schemas/`.
2.  **Dataset "Classic" Setup**:
    *   Create a `data/` directory structure.
    *   Create `data/defaults.yaml` based on `defaults.schema.json`.
3.  **Defaults Implementation**:
    *   Write `main.tf` code to read, decode, and validate `defaults.yaml`.
    *   Implement the `local.project_defaults` logic following standard FAST patterns.

**Phase 2: Central Project & Factories**
1.  **Central Project Config**:
    *   Create a YAML definition for the central project (e.g., `data/projects/central.yaml` or within `defaults.yaml` structure).
    *   Ensure all associated resources (Aspect Types, Policy Tags, etc.) currently defined in `main.tf` are representable in YAML.
2.  **Resource Implementation**:
    *   Write Terraform code to consume the central project configuration.
    *   Instantiate `module "project-factory"`.
    *   Instantiate necessary factory modules (e.g., `dataplex-aspect-types`) driven by the YAML data.
    *   **Strictly** adhere to FAST context conventions (`local.ctx`) for dependency injection.

**Phase 3: Data Domains**
1.  **Domain Config**: Create YAML files for Data Domains in `data/domains/`.
2.  **Transformation Logic**: Implement locals in `main.tf` to transform Domain YAMLs into `project-factory` inputs (Folders, Shared Projects, Service Accounts).
3.  **Verification**: Plan and verify that Domain resources are generated correctly.

**Phase 4: Data Products**

1.  **Product Config**: Create YAML files for Data Products in `data/products/`.

2.  **Transformation Logic**: Extend logic to parse Product YAMLs and link them to their parent Domains.

3.  **Verification**: Plan and verify that Product projects and IAM bindings are generated correctly.



## 9. Current Status







### Completed



*   **Workspace**: Initialized `fast/stages/2-data-platform`.



*   **Documentation**: Established `GEMINI.md` as the project plan and context.



*   **Schemas**:



    *   `schemas/defaults.schema.json` imported from `project-factory`.



    *   `schemas/project.schema.json` and `schemas/folder.schema.json` imported from `project-factory`.



*   **Data**:



    *   Created `datasets/classic/defaults.yaml`.



    *   Populated `defaults.yaml` with baseline services and IAM contexts.



    *   Created `datasets/classic/projects/central.yaml` for the Central Project.



*   **Code Structure**:



    *   Created `variables.tf` and `variables-fast.tf`.



    *   Implemented `main.tf` with defaults loading and context logic.



    *   Implemented `factory-projects.tf` integrating `module "project-factory"`.







### Next Steps



1.  **Verification**: Initialize and plan (using mock inputs) to verify Central Project generation.



2.  **Data Domains**:



    *   Create `schemas/data-domain.schema.json`.



    *   Create `datasets/classic/domains/` sample data.



    *   Implement domain transformation logic in `main.tf`.



3.  **Data Products**:



    *   Create `schemas/data-product.schema.json`.



    *   Create `datasets/classic/products/` sample data.



    *   Implement product transformation logic.








