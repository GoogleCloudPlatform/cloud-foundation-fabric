---
name: fast-0-org-setup-prereqs
description: Guides the user step-by-step through the prerequisites for the FAST 0-org-setup stage, supporting both Standard GCP and Google Cloud Dedicated (GCD) environments. Use when a user asks to prepare or run prerequisites for 0-org-setup or bootstrap the FAST landing zone.
---

# FAST 0-org-setup Prerequisites Guide

## Core Principles & Execution Rules

> [!CRITICAL]
> **MANDATORY PROGRESS BLOCK (HUMAN VISIBILITY):** 
> To ensure the human user always knows where they are in the workflow and can immediately spot if you skip steps or make false assumptions, **EVERY SINGLE response you output MUST start with this progress block**. Do not omit it, do not shorten it, and do not skip step sequences.
>
> Format to prepend to EVERY message:
> ```text
> FAST Prerequisites Progress:
> - Phase 1: Environment & Authentication
>   (Step 1/2: Target Environment Selection - IN PROGRESS)
> - Phase 2: Admin Principal & Baseline Info
>   (Not started)
> - Phase 3: Bootstrap Project & IAM
>   (Not started)
> - Phase 4: Configuration & Wrap-up
>   (Not started)
> ```
>
> As steps are completed, update the bracketed lines to show completed steps or current active step, e.g.:
> ```text
> FAST Prerequisites Progress:
> - Phase 1: Environment & Authentication
>   (2/2 steps completed)
> - Phase 2: Admin Principal & Baseline Info
>   (Step 1/2: Admin Principal Definition - IN PROGRESS)
> - Phase 3: Bootstrap Project & IAM
>   (Not started)
> - Phase 4: Configuration & Wrap-up
>   (Not started)
> ```

> [!CRITICAL]
> **Understanding Turn Boundaries:** You are running in a turn-based execution environment. 
> - You receive one user message, then you can think and run tools.
> - Once you decide you need input from the user (e.g. to choose an environment or confirm a principal), you MUST output your question in a text response and **STOP execution immediately (do not call more tools)**. 
> - You **CANNOT** receive the user's answer in the same turn. 
> - You **MUST NOT** simulate, guess, or assume the user's response in your subsequent thinking blocks during the same turn. You must wait for the next turn to receive the actual input.
>
> **Do NOT Skip Steps or Make Assumptions:** You MUST NOT skip any phases or steps, even if you think they are redundant or if you find information on the system (like active credentials) that suggests a step is already complete. You MUST execute every step sequentially, in order, and wait for explicit user input/confirmation at each step boundary.
>
> **MANDATORY START POINT (TURN 1):** You MUST explicitly ask the user to choose their target environment (Standard GCP or GCD) in your first turn. Do NOT check active credentials or run background commands to bypass this step. The environment selection is a fundamental gateway that dictates all downstream resources, variables, and configurations. Proceeding without explicitly getting this choice in Turn 1 is a critical failure.
>
> **Strictly One Question at a Time:** You MUST NOT bundle multiple questions or steps together in a single response. Ask exactly one question, wait for the user's answer, and only then proceed to the next question or action.
>
> **Sandbox Awareness:** You are running inside an isolated, sandboxed temporary workspace (e.g., `/tmp/gemini_harness_*`). Whenever creating local files, configuration directories (like `custom-fast-config` or `fast-config`), or checking defaults, you MUST do so strictly relative to your current workspace directory (CWD). NEVER try to directly read or write to `/home/ludomagno/` or other external folders, as your file tools are sandboxed and will fail with permission errors.
>
> **Step-by-Step Execution:** Never implement a single "magical" flow. Go through each step one at a time, explaining context and asking for confirmation.
3. **Execution Choice:** Respect the user's execution preference (automatic via `run_shell_command` vs. manual copy/paste) throughout the entire workflow unless the user explicitly instructs you to change it. This preference will be gathered during Phase 1.
4. **File Modifications:** Always use `replace` or `write_file`. **Never** use opaque shell commands (like `sed`, `echo >>`, or `cat <<EOF >>`). Show proposed edits and ask for confirmation before applying them so the user can see what we're doing.
5. **YAML Validation:** Validate generated YAML using `yamllint -c .yamllint --no-warnings <file>`. If the command is not available, ask the user if they prefer to a) install it, b) have you install it (`pip install yamllint`), or c) skip validation.
6. **Resuming Mid-Flow:** If the user is resuming a previously interrupted session, ask them which Phase or Step they left off at, or assess the current state by reading previously generated files (e.g., `defaults.yaml`, `0-org-setup.auto.tfvars`). Read the corresponding reference file for the identified phase and resume execution directly from that point.

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
*Description:* Assign the necessary organization-level IAM roles and set up a temporary project for API quota tracking.\
*Reference: [Bootstrap Project & IAM](references/phase3-bootstrap-and-iam.md)*
- **Step 5:** IAM Role Assignments
- **Step 6:** Bootstrap Project Setup (Creation and API enablement)

### Phase 4: Configuration & Wrap-up
*Description:* Generate the FAST dataset configuration, handle existing organization policies, and prepare for the final Terraform apply.\
*Reference: [Configuration & Wrap-up](references/phase4-config-and-wrapup.md)*
- **Step 7:** Configuration Generation (Datasets, defaults.yaml, local paths)
- **Step 8:** Organization Policy Import Check
- **Step 9:** Wrap-up & Apply
