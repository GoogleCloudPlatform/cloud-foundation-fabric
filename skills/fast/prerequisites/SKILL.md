---
name: fast-0-org-setup-prereqs
description: Guides the user step-by-step through the prerequisites for the FAST 0-org-setup stage, supporting both Standard GCP and Google Cloud Dedicated (GCD) environments. Use when a user asks to prepare or run prerequisites for 0-org-setup or bootstrap the FAST landing zone.
---

# FAST 0-org-setup Prerequisites Guide

## Core Principles & Execution Rules

1. **Strictly One Question at a Time:** You MUST NOT bundle multiple questions or steps together in a single response. Ask exactly one question, wait for the user's answer, and only then proceed to the next question or action.
2. **Step-by-Step:** Never implement a single "magical" flow. Go through each step one at a time, explaining context and asking for confirmation.
2. **Execution Choice:** At the beginning of the workflow, ask the user for their execution preference (automatic via `run_shell_command` vs. manual copy/paste). Respect this choice throughout the entire workflow unless the user explicitly instructs you to change it.
3. **File Modifications:** Always use `replace` or `write_file`. **Never** use opaque shell commands (like `sed`, `echo >>`, or `cat <<EOF >>`). Show proposed edits and ask for confirmation before applying them so the user can see what we're doing.
4. **YAML Validation:** Validate generated YAML using `yamllint -c .yamllint --no-warnings <file>`. If the command is not available, ask the user if they prefer to a) install it, b) have you install it (`pip install yamllint`), or c) skip validation.
5. **Resuming Mid-Flow:** If the user is resuming a previously interrupted session, ask them which Phase or Step they left off at, or assess the current state by reading previously generated files (e.g., `defaults.yaml`, `0-org-setup.auto.tfvars`). Read the corresponding reference file for the identified phase and resume execution directly from that point.

## Workflow Map

Guide the user through the following sequence strictly in order. **Before starting a phase, read its corresponding reference document to get the exact instructions, commands, and logic.**

### Phase 1: Environment & Authentication
*Description:* Determine the target environment (Standard GCP or GCD) and ensure the user is properly authenticated.\
*Reference: [Environment & Authentication](references/phase1-env-and-auth.md)*
- **Step 1:** Environment Assessment & Initialization (Standard vs GCD)
- **Step 2:** Authentication

### Phase 2: Admin Principal & Baseline Info
*Description:* Define the core administrative identity and gather essential baseline data like Organization and Billing IDs.\
*Reference: [Admin Principal & Baseline Info](references/phase2-admin-and-baseline.md)*
- **Step 3:** Admin Principal Definition (Group vs Single User)
- **Step 4:** Baseline Information Gathering (Org ID, Billing ID, Billing Access Scenarios)

### Phase 3: Bootstrap Project & IAM
*Description:* Set up a temporary project for API quota tracking and assign the necessary organization-level IAM roles.\
*Reference: [Bootstrap Project & IAM](references/phase3-bootstrap-and-iam.md)*
- **Step 5:** Bootstrap Project Setup (Creation and API enablement)
- **Step 6:** IAM Role Assignments

### Phase 4: Configuration & Wrap-up
*Description:* Generate the FAST dataset configuration, handle existing organization policies, and prepare for the final Terraform apply.\
*Reference: [Configuration & Wrap-up](references/phase4-config-and-wrapup.md)*
- **Step 7:** Configuration Generation (Datasets, defaults.yaml, local paths)
- **Step 8:** Organization Policy Import Check
- **Step 9:** Wrap-up & Apply
