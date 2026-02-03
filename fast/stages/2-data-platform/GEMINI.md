# PRD: Refactoring FAST Data Platform Stage (Stage 3)

## 1. Objective

Refactor the FAST Data Platform stage (`fast/stages/3-data-platform-dev`) to align with the modern FAST architecture principles (exemplified by stages 0, 1, and 2). The goal is to standardize configuration management, leverage the `project-factory` module for resource creation, and improve maintainability and scalability.

## 2. Goals

1. **Configuration via YAML and Schema**: Move from custom Terraform logic iterating over locals to a file-based configuration approach (`defaults.yaml` + `data/` directory) validated by JSON schemas.
2. **Embed Project Factory**: Replace discrete `module "project"` and `module "folder"` calls with a single embedded usage of the `project-factory` module (`modules/project-factory`).
3. **Context Replacements**: Utilize context variables (IAM principals, KMS keys, etc.) to share values effectively between modules, adhering to the standard `local.ctx` pattern found in other stages.
4. **Preserve Semantics**: Maintain the existing logical hierarchy (Domains, Shared Projects, Data Products) while adapting to the `project-factory` data model.

## 3. Basic Principles

- **Module-Driven Schemas**: Schemas for high-level objects (Data Domains, Data Products, etc.) must be grounded in the schemas of the underlying modules (e.g., `project-factory`, `dataplex-aspect-types`). Start with the module schema and extend/adapt only as necessary for the stage's specific abstractions.
- **FAST Standard Derivation**: Implementation patterns (code structure, context handling, variable naming, YAML consumption) must be directly derived from the existing FAST stages 0, 1, and 2. Consistency with the "modern" FAST approach is paramount.
- **Context Definition & Alignment**: `defaults.yaml` serves as the authoritative source for static environment context (IAM principals, KMS keys) and baseline project configuration (common services, locations). Keys defined here (e.g., `dp-admin`) are the canonical references used across all Domain and Product YAMLs.
- **Iterative & Parallel**: Development occurs in a parallel `2-data-platform` directory to avoid breaking the existing stage. We iterate through layers: Schemas -> Defaults -> Central Project -> Domains -> Products.
- **Context-First**: Leverage `local.ctx` and `var.context` for all cross-module dependency management, replacing ad-hoc variable passing.
*   **Explicit Context Keys**: Use explicit prefixes (e.g., `$iam_principals:group-name`) in YAML configurations to trigger context replacement. This enables schema validation and clear intent.
*   **Private Locals**: Locals prefixed with an underscore (e.g., `_defaults`) are considered private to the scope of the locals block where they are defined and should not be used elsewhere.
*   **Review Before Commit**: Always ask for a review of your plan of action before committing to it (modifying files).
*   **Project Factory Alignment**: Always attempt to map high-level constructs (Domains, Products) to atomic `project-factory` resources (Project, Folder) defined within the dataset structure, minimizing custom Terraform logic. Prefer being explicit by implementing logic in the dataset (YAML) as a working example users can edit and reuse.
- **YAML Style**: Avoid using double quotes for strings in YAML unless necessary (e.g., for reserved characters or special formatting).
- **Configuration-Driven**: All logic should be driven by the YAML configuration files in `data/`, minimized hard-coded logic in Terraform files.
- **Always Read First**: Always re-read a file before analyzing or modifying it to ensure you are working with the latest version and context.

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
  - `data/[domain]/products/*.yaml`: Definitions for Data Products (custom schema or adapted project schema).
- **Resource Creation**:
  - **One** `module "project-factory"` call in `factory-projects.tf` (or similar).
  - The module receives constructed `folders` and `projects` maps derived from the YAML configuration.
- **Hierarchy Management**:
  - The specific "Domain -> Shared Project + DP Folder -> DP Projects" hierarchy will be generated programmatically in `main.tf` locals before being passed to the project factory.

## 5. Detailed Design

### 5.1 Configuration Structure & Schemas

We will adopt the standard `schemas/` directory structure and leverage existing `project-factory` schemas.

- **Defaults**: Reuse `fast/stages/2-project-factory/schemas/defaults.schema.json`.
- **Data Domains**: Represented by a directory structure `data/domains/{domain}/`.
  - `.config.yaml`: Domain Folder configuration (uses `folder.schema.json`).
  - `shared.yaml`: Domain Shared Project configuration (uses `project.schema.json`).
- **Data Products**:
  - `products/.config.yaml` (optional): Products sub-folder configuration (uses `folder.schema.json`).
  - `products/{product}.yaml`: Product Project configuration (uses `project.schema.json`).
- **Auxiliary Resources**:
  - `schemas/aspect-types.schema.json`: For `data/aspect-types/*.yaml`.
  - `schemas/tags.schema.json`: For `data/tags/*.yaml` (if needed, or reuse project factory's tags schema).

#### 5.1.1 Resource Embedding Strategy

To balance configuration simplicity with modularity:

- **Embed in Project YAML (`central.yaml`, etc.)**:
  - **Secure Tags**: Use the `tags` attribute supported by `project-factory`.
  - **KMS Keys**: Use `service_encryption_key_ids` supported by `project-factory`.
  - **Service Accounts**: Use `service_accounts` supported by `project-factory`.
- **Separate Factories (YAML + Module)**:
  - **Aspect Types**: Too complex for embedding; use `data/aspect-types/*.yaml` and `module "dataplex-aspect-types"`.
  - **Policy Tags**: Too complex for embedding; use `data/tags/*.yaml` and `module "data-catalog-policy-tag"`.

**`data/defaults.yaml`**

```yaml
# Global defaults for projects
projects:
  defaults:
    locations:
      storage: EU
      logging: EU
      bigquery: EU
    billing_account: 012345-678901-ABCDEF
```

**`data/domains/marketing/.config.yaml`** (Domain Folder)

```yaml
name: Marketing Domain
iam:
  roles/viewer:
    - group:marketing-viewers@example.com
```

**`data/domains/marketing/shared.yaml`** (Shared Project)

```yaml
services:
  - bigquery.googleapis.com
service_accounts:
  automation: # Explicit definition replacing old auto-generation
    iam_self_roles: []
```

### 5.2 Transformation Logic (Terraform Locals)

In `main.tf`, we will implement logic to traverse the `data/domains` directory structure and flatten it into `project-factory` inputs.

**`main.tf`**

```hcl
locals {
  # ... defaults loading ...

  # Logic to traverse data/domains/ and generate:
  # 1. Folders (Domain root folders, Products sub-folders)
  # 2. Projects (Shared projects, Product projects)
  # 3. Stitching parents automatically based on directory structure
}
```

**Logic for Domain/Product Transformation:**

1. **Folders**:
    - `data/domains/{d}/.config.yaml` -> Folder `{d}` (Parent: Stage Folder).
    - `data/domains/{d}/products/.config.yaml` -> Folder `{d}-products` (Parent: Folder `{d}`).
2. **Projects**:
    - `data/domains/{d}/shared.yaml` -> Project `{d}-shared` (Parent: Folder `{d}`).
    - `data/domains/{d}/products/{p}.yaml` -> Project `{p}` (Parent: Folder `{d}-products`).

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

- **Old**: `module.dd-folders["marketing"]`
- **New**: `module.project-factory.module.folders["marketing"]`

**Action**: `moved` blocks will be critical. The logic should aim to produce predictable keys to minimize state friction.

## 7. Constructs Mapping & Implementation Analysis

### 7.1 Data Domains

#### Analysis of Old Construct

- **Definition**: `data/data-domains/{domain}/.config.yaml`.
- **Resources**: Creates a Folder, a "Data Products" sub-folder, and a Shared Project. Automatically creates `iac-ro` and `iac-rw` service accounts.
- **Logic**: Complex custom logic in `factory.tf` to iterate and build resource maps.

#### Implementation Plan (New)

- **Structure**: `datasets/classic/domains/{domain}/`.
- **Components**:
  - `.config.yaml`: Maps to `project-factory` **Folder** (Domain root).
  - `shared.yaml`: Maps to `project-factory` **Project** (Shared Project).
  - `products/.config.yaml`: Maps to `project-factory` **Folder** (Products sub-folder).
- **Automation**: Service accounts are defined explicitly in `shared.yaml` (via `service_accounts`), removing "magic" generation.

### 7.2 Data Products

#### Analysis of Old Construct

- **Definition**: `data/data-domains/{domain}/{product}.yaml`.
- **Resources**: Creates a Project under the "Data Products" sub-folder.
- **Logic**: Part of the same complex iteration in `factory.tf`.

#### Implementation Plan (New)

- **Structure**: `datasets/classic/domains/{domain}/products/{product}.yaml`.
- **Components**:
  - `{product}.yaml`: Maps to `project-factory` **Project**.
- **Parenting**: Logic in `main.tf` stitches this project to the `products` folder of the domain.

### 7.3 Central Project Resources

*   **Central Project**: Defined in `central.yaml`.
*   **Aspect Types**: Managed by `module "dataplex-aspect-types"` which has native factory support. **(Implementation Priority 1)**
*   **Policy Tags**: Managed by `module "data-catalog-policy-tag"`. Implementation strategy to be revisited. **(Implementation Priority 2)**
*   **Resource Manager Tags**: Strategy to be determined. **(Implementation Priority 3)**

## 8. Development Strategy

We will adopt a "clean slate" parallel development approach to ensure stability and incremental verification.

### 8.1 Workspace Setup

1. Create a new directory `fast/stages/2-data-platform` (parallel to the existing `3-data-platform-dev`).
2. This isolated environment allows us to reference the existing code while building the new architecture from scratch.

### 8.2 Step-by-Step Implementation Plan

**Phase 1: Foundation & Schemas**

1. **Schema Generation**:
    - **Defaults**: `schemas/defaults.schema.json` (reuse project-factory).
    - **Data Domains**: `schemas/data-domain.schema.json` (compose folder/project attributes).
    - **Data Products**: `schemas/data-product.schema.json` (extend project schema).
    - **Aspects/Tags**: `schemas/aspect-types.schema.json`, `schemas/tags.schema.json`.
    - Store all in `fast/stages/2-data-platform/schemas/`.
2. **Dataset "Classic" Setup**:
    - Create a `data/` directory structure.
    - Create `data/defaults.yaml` based on `defaults.schema.json`.
3. **Defaults Implementation**:
    - Write `main.tf` code to read, decode, and validate `defaults.yaml`.
    - Implement the `local.project_defaults` logic following standard FAST patterns.

**Phase 2: Central Project & Factories**

1. **Central Project Config**:
    - Create a YAML definition for the central project (e.g., `data/projects/central.yaml` or within `defaults.yaml` structure).
    - Ensure all associated resources (Aspect Types, Policy Tags, etc.) currently defined in `main.tf` are representable in YAML.
2. **Resource Implementation**:
    - Write Terraform code to consume the central project configuration.
    - Instantiate `module "project-factory"`.
    - Instantiate necessary factory modules (e.g., `dataplex-aspect-types`) driven by the YAML data.
    - **Strictly** adhere to FAST context conventions (`local.ctx`) for dependency injection.

**Phase 3: Data Domains**

1. **Domain Config**: Create YAML files for Data Domains in `data/domains/`.
2. **Transformation Logic**: Implement locals in `main.tf` to transform Domain YAMLs into `project-factory` inputs (Folders, Shared Projects, Service Accounts).
3. **Verification**: Plan and verify that Domain resources are generated correctly.

**Phase 4: Data Products**

1. **Product Config**: Create YAML files for Data Products in `data/products/`.

2. **Transformation Logic**: Extend logic to parse Product YAMLs and link them to their parent Domains.

3. **Verification**: Plan and verify that Product projects and IAM bindings are generated correctly.

## 9. Current Status

### Completed

- **Workspace**: Initialized `fast/stages/2-data-platform`.

- **Documentation**: Established `GEMINI.md` as the project plan and context.

- **Schemas**:

  - `schemas/defaults.schema.json` imported from `project-factory`.

  - `schemas/project.schema.json` and `schemas/folder.schema.json` imported from `project-factory`.

- **Data**:

  - Created `datasets/classic/defaults.yaml`.

  - Populated `defaults.yaml` with baseline services and IAM contexts.

  - Created `datasets/classic/projects/central.yaml` for the Central Project.

- **Code Structure**:

  - Created `variables.tf` and `variables-fast.tf`.

  - Implemented `main.tf` with defaults loading and context logic.

  - Implemented `factory-projects.tf` integrating `module "project-factory"`.

### Next Steps

1. **Verification**: Initialize and plan (using mock inputs) to verify Central Project generation.

2. **Data Domains**:

    - Create `schemas/data-domain.schema.json`.

    - Create `datasets/classic/domains/` sample data.

    - Implement domain transformation logic in `main.tf`.

3. **Data Products**:

    - Create `schemas/data-product.schema.json`.

    - Create `datasets/classic/products/` sample data.

    - Implement product transformation logic.
