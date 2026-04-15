# Test Harness TODOs & Analysis

## The Problem: Skill Environment Dependencies

During E2E testing of the `fast-0-org-setup-prereqs` skill, the autonomous agent hallucinated that it needed to `git clone` the `cloud-foundation-fabric` repository. 

This occurred because the test harness executes the Gemini CLI in a completely empty, isolated temporary workspace (`/tmp/gemini_harness_*`). However, the FAST skill *assumes* it is being executed from the root of the `cloud-foundation-fabric` repository because it needs to:
1. Read available datasets from `fast/stages/0-org-setup/datasets/*/defaults.yaml`.
2. Create a symbolic link from the generated `0-org-setup.auto.tfvars` file to `fast/stages/0-org-setup/0-org-setup.auto.tfvars`.

Because these directories did not exist in the isolated workspace, the agent failed to complete Phase 4 of the setup.

## Proposed Solutions for Next Session

We need a way to provide the agent with the expected repository structure during tests without compromising the safety and isolation of the test harness.

### Option 1: Add a `working_dir` Playbook Attribute
Allow the playbook to specify a `working_dir` (e.g., the actual path to the `cloud-foundation-fabric` repo) where the CLI should be executed, bypassing the temporary workspace creation.

**Risks & Impacts:**
*   **Chat History Pollution:** The test's conversation will be saved to the global `~/.gemini/tmp/cloud-foundation-fabric/chats/` directory, mixing test runs with the developer's actual day-to-day CLI usage.
*   **Session Retrieval:** The harness will need to be updated to find the *newest* `session-*.json` file in that directory, rather than assuming it's the only one.
*   **File Modification Risk:** If the agent hallucinates or a test is poorly written, it could modify or delete real files in the repository instead of sandboxed test files.
*   **Cleanup:** The harness cannot safely clean up the workspace after the test completes.

### Option 2: The "Symlink Sandbox" (Recommended)
Keep the isolated temporary workspace (`/tmp/gemini_harness_*`), but add a `symlink_paths` array to the playbook schema. 

Before the test starts, the harness would dynamically create symbolic links from the real repository (e.g., `fast/`, `modules/`) into the temporary workspace.

**Benefits:**
*   **Total Isolation:** The agent's chat history remains isolated in a temporary `.gemini/tmp/gemini_harness_*/` directory.
*   **Safe Execution:** The agent sees the directory structure it expects (and can read the `defaults.yaml` files), but any new files it creates (like the `custom-fast-config` directory or the `0-org-setup.auto.tfvars` symlink) are created safely inside the temporary workspace.
*   **Automatic Cleanup:** The entire workspace (including the symlinks and generated files) is safely deleted when the test finishes.

## Next Steps
1. Decide between Option 1 (`working_dir`) and Option 2 (`symlink_paths`).
2. Implement the chosen solution in `harness.py`.
3. Update `playbook.schema.json` and `README.md`.
4. Re-run the `gcp-dev-autonomous.yaml` E2E test to verify Phase 4 completes successfully.