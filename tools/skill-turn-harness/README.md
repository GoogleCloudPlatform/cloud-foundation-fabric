# Hybrid Python/CLI Test Harness for Gemini Skills

## Overview

This project provides a robust, hybrid test harness for developing and evaluating Gemini CLI skills. It solves the "inner dev loop" problem by allowing you to test local, unpacked skills directly against the real Gemini CLI, while using an LLM to deterministically grade the agent's behavior.

## Table of Contents

- [Prerequisites](#prerequisites)
- [How to Use](#how-to-use)
  - [Basic Usage](#basic-usage)
  - [Command Line Options](#command-line-options)
  - [Expected Output](#expected-output)
- [Testing Local Skills (Inner Dev Loop)](#testing-local-skills-inner-dev-loop)
- [Writing Playbooks](#writing-playbooks)
- [Running the Pytest Suite](#running-the-pytest-suite)

The architecture relies on three main components:

- **Orchestrator (Python):** Drives the execution loop, reads YAML playbooks, and manages isolated workspaces for each test run to prevent session caching issues.
- **Execution Target (Gemini CLI):** The skill is executed via the native `gemini` CLI using Python's `subprocess` module. This guarantees the tests accurately reflect the actual user experience.
- **Evaluator (Gemini API):** The semantic evaluation of the CLI's output is performed via direct API calls to `gemini-2.5-flash`. This bypasses brittle string-parsing and guarantees structured JSON output (Pass/Fail + Reasoning).

## Prerequisites

Ensure you have a Python virtual environment set up with the required dependencies:

```bash
pip install google-genai pydantic pyyaml click pytest
```

You also need your Gemini API key available in your environment, or stored in `~/.gemini/key.env`:

```bash
export GEMINI_API_KEY="your_api_key_here"
```

## How to Use

The main entry point is the `harness.py` CLI tool.

### Basic Usage

To run a test, provide a YAML playbook:

```bash
python3 harness.py playbooks/my-playbook.yaml
```

### Command Line Options

- `playbook` (Required): The path to the YAML playbook defining the test steps.
- `--log-dir <path>` (Optional): The directory where the harness will write detailed Markdown logs and JSON failure dumps. Defaults to `./logs`.
- `--skill-src <path>` (Optional): The path to a local, unpacked skill directory. If omitted, the harness will test against the skills currently installed in your global `~/.gemini` environment. See the "Testing Local Skills" section below for details.
- `--env-file <path>` (Optional): The path to a standard `.env` file containing key-value pairs (e.g. `MY_SECRET=123`). This is used for secure string substitution within your playbook steps.

⚠️ **Security Warning regarding Logs:**
If your playbooks require secrets (like API keys or passwords) via the `env` array, the harness will substitute them before executing the CLI. Because the harness traces all inputs and outputs for debugging, **these substituted secrets will be written in plain text** to your `logs/` directory.
A default `.gitignore` is provided in the `logs/` directory to prevent committing these files, but care should still be taken to avoid leaking secrets into your repository.

### Expected Output

The harness executes the CLI steps, evaluates the responses, and streams the results to the console:

```text
--- Tuning: FAST Setup PoC | Workspace: /tmp/gemini_harness_abc123 ---

[Step 1] Input: Hi, please activate the fast-setup-poc skill and let's configure FAST.
[Step 1] Output: Hi, let's configure FAST. Please provide your Google Cloud Project ID.
✅ [PASS Step 1]: The agent greeted the user ('Hi'), confirmed it was configuring FAST, and asked for the Project ID. All parts of the objective were fulfilled.

...

✅ [SUCCESS] Playbook 'FAST Setup PoC' completed successfully.
📄 Markdown log saved to: logs/FAST_Setup_PoC_log.md
```

If a step fails, the harness halts immediately and dumps the full interaction trace to a JSON file (e.g., `logs/FAST_Setup_PoC_failed.json`) for debugging.

## Testing Local Skills (Inner Dev Loop)

When developing a complex skill (with multiple markdown files, prompt templates, or tools), you don't want to package and globally install it just to run a test.

The harness supports dynamic, ephemeral linking of local skills using the `--skill-src` flag:

```bash
python3 harness.py playbooks/my-playbook.yaml --skill-src ./my-local-skill/
```

**How it works under the hood:**

1. **Parsing:** The harness reads `./my-local-skill/SKILL.md` to extract the exact name of your skill from the YAML frontmatter.
2. **Linking:** It dynamically executes `gemini skills link ./my-local-skill/ --consent`. The `--consent` flag is crucial as it bypasses the CLI's interactive security prompt, preventing the test from hanging.
3. **Execution:** The playbook runs normally. The Gemini CLI will now naturally resolve and utilize your local folder (including relative references like `[supporting doc](./references/doc.md)`).
4. **Cleanup:** Regardless of whether the test passes, fails, or crashes, a `finally` block executes `gemini skills uninstall <skill_name>` to remove the symlink, ensuring your global `~/.gemini` environment is kept clean.

## Writing Playbooks

Playbooks are written in YAML. For autocompletion and validation in VS Code, add the schema annotation to the top of your playbook.

If your playbook requires environment variables (e.g., secrets), declare them in the `env` array. You can then reference them in your `steps` using `${VAR_NAME}`. If a variable is declared but not found in the environment (or passed via `--env-file`), the harness will safely halt before execution.

```yaml
# yaml-language-server: $schema=../playbooks/playbook.schema.json
name: "My Test Playbook"
env:
  - MY_API_KEY
steps:
  - user_input: "Hi, activate my-skill and use this key: ${MY_API_KEY}"
    expected_outcome: "The agent should greet the user and acknowledge the key."
```

## Running the Pytest Suite

This repository includes a `pytest` suite in the `test/` directory to test the harness itself.

To run the fast unit tests (which mock the CLI execution):

```bash
python3 -m pytest test/test_harness.py -m "not e2e" -v
```

To run the full End-to-End (E2E) test (which dynamically links the fixture skill and hits the real Gemini API):

```bash
python3 -m pytest test/test_harness.py -m "e2e" -v
```

## Future Enhancements: Autonomous "Pond" Testing (Simulated User)

**TODO:** Implement an autonomous testing mode to complement the deterministic script-based approach.

While the current strict `steps` based playbook is excellent for **Unit/Regression Testing** (ensuring the exact state machine of a skill hasn't broken), an autonomous approach provides robust **E2E / Fuzz Testing** by handling the messy reality of natural language and conversational drift.

### Concept: The "Pond" Architecture

Instead of providing a rigid list of sequential steps, the playbook acts as a declarative **Persona** with a "Pond" of knowledge:

```yaml
name: "FAST Setup PoC - Autonomous"
goal: "Successfully configure FAST."
knowledge_base:
  project_id: "my-super-project-123"
  region: "europe-west1"
rules_for_simulated_user:
  - "Do not provide information until the agent explicitly asks for it."
  - "If the agent asks for something not in your knowledge base, say you don't know."
```

### How it will work:
1. **Primary Agent (CLI)** asks a question.
2. **Secondary Agent (Evaluator / Simulated User)** receives the CLI output, the conversation history, and the "Pond" (knowledge base).
3. The Secondary Agent makes a single LLM call to evaluate the state *and* generate the next input dynamically (fishing the right data from the pond).
4. The generated input is fed back into the CLI.

### Implementation Plan
- Add a `--mode autonomous` flag to `harness.py` to switch between deterministic script execution and the autonomous persona mode.
- Update the Pydantic evaluation schema to return both an evaluation of the previous turn and the `next_user_input`.
- Update the playbook schema to support `goal`, `knowledge_base`, and `rules_for_simulated_user` as an alternative to `steps`.
