# FAST Cleaner

A lightweight, fast Go CLI tool designed to sanitize a Google Cloud Platform (GCP) Organization or a specific Folder hierarchy prior to deploying Cloud Foundation Fabric (FAST).

It recursively discovers and safely deletes Projects, Folders, Tags, and their associated dependencies (Liens, Tag Bindings, Firewall Policy Associations) in the correct order to prevent API conflicts.

## Why this tool?

When tearing down a GCP environment, you cannot simply delete a Folder or an Organization. GCP enforces strict dependencies:
- **Projects** cannot be deleted if they have **Liens** (e.g., Shared VPC Host projects).
- **Folders** cannot be deleted if they contain active Projects or child Folders.
- **Folders** cannot be deleted if they have **Hierarchical Firewall Policies** attached.
- **Tag Values/Keys** cannot be deleted if they are still bound to resources (even if those resources are inside soft-deleted projects).

`fast-cleaner` automates this entire dependency graph. It discovers all resources, builds an execution plan, and deletes them in a safe, batch-oriented, bottom-up order.

## Prerequisites

- **Go 1.21+** installed on your system.
- Authenticated to GCP via Application Default Credentials (ADC) with sufficient permissions (e.g., Organization Administrator).
  ```bash
  gcloud auth application-default login
  ```

## Building the Tool

If you are not familiar with Go, you can compile the tool into a single executable binary with this one-liner:

```bash
cd tools/fast-cleaner
go build -o fast-cleaner .
```

This will create a `fast-cleaner` executable in the current directory.

## Usage

The tool requires a `--target` parameter, which can be either an Organization or a Folder ID.

**By default, the tool runs in `--dry-run=true` mode.** It will discover all resources, print the execution plan, and exit without making any destructive changes.

### Example: Dry Run (Safe)

```bash
./fast-cleaner --target=organizations/1234567890
```

### Example: Live Deletion (Destructive)

To actually execute the deletions, you must explicitly pass `--dry-run=false`. The tool will still pause and require you to type `yes` before proceeding.

```bash
./fast-cleaner --target=organizations/1234567890 --dry-run=false
```

### Example: Quiet Mode

By default, the tool prints verbose output during the discovery phase (e.g., `Fetching tags...`, `Fetching liens...`). You can suppress this output using the `-q` flag.

```bash
./fast-cleaner --target=folders/9876543210 -q
```

## Execution Order

When running in live mode, the tool executes deletions in the following batch order to ensure all GCP API constraints are satisfied:

1.  **Remove Firewall Policy Associations:** Detaches global firewall policies from all discovered folders.
2.  **Remove Log Sinks:** Deletes all custom log sinks from the target root and all discovered folders.
3.  **Remove Tag Bindings:** Detaches all tags from all discovered Projects and Folders.
4.  **Remove Liens:** Deletes all liens from all discovered Projects.
5.  **Remove Folder Org Policies:** Deletes any custom Organization Policies attached directly to Folders.
6.  **Delete Projects:** Issues the delete command for all Projects.
7.  **Delete Folders:** Deletes all Folders in a strict post-order (bottom-up) traversal.
8.  **Delete Tag Definitions:** Deletes all Tag Values, then Tag Keys defined at the target root.

## Corner Cases & Limitations

- **Deep Tag Bindings:** The tool explicitly removes Tag Bindings attached to *Projects* and *Folders*. If you have Tag Bindings attached to deeper resources (e.g., Compute Instances, Storage Buckets) within those projects, the tool will not discover them. When the tool attempts to delete the Org-level Tag Definition in Step 8, it will gracefully fail with a `[WARNING]` because the Tag Hold still exists on the soft-deleted child resource. This is expected behavior and does not break the rest of the cleanup process.
- **Root Level Org Policies & Roles:** The tool does not delete custom Organization Policies or Custom IAM Roles defined at the target root (e.g., Organization level). These are left intact so FAST can re-import them or overwrite them.
- **Root Level IAM:** The tool provides an interactive prompt to selectively clean up IAM bindings at the root level.
- **System Log Sinks:** Default system Log Sinks (`_Default`, `_Required`) and their respective Log Buckets are ignored as they are managed by GCP and cannot be deleted.
