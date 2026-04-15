# Design Decisions: Test Harness Architecture

## Context

This document captures architectural decisions and considerations for the `harness.py` test harness.

## LangChain Integration Analysis

*Date: April 15, 2026*

We evaluated whether to integrate LangChain into the `harness.py` script. The script currently acts as a lightweight testing harness that uses `subprocess` to interact with the Gemini CLI and the native `google.genai` SDK for evaluation using structured outputs (Pydantic).

### Potential Benefits of LangChain

1. **Model-Agnostic Evaluators (Avoiding Self-Bias):**
   Currently, the harness uses Gemini 2.5 Flash to evaluate the Gemini CLI. To avoid "self-preference bias", it is often best practice to use a different model family for evaluation. LangChain's `ChatModel` abstractions would allow swapping the evaluator model easily without rewriting API call logic.
2. **Built-in Evaluation Frameworks:**
   LangChain provides a dedicated evaluation module (`langchain.evaluation`). Instead of custom prompts, we could leverage pre-built evaluators (like `CriteriaEvalChain`) that are prompt-engineered to reduce hallucinations and false positives.
3. **Observability and Tracing (LangSmith):**
   Integration provides seamless access to LangSmith for logging evaluation runs, inspecting prompts, latency, token usage, and tracking pass/fail rates over time.
4. **Prompt Management:**
   LangChain's `PromptTemplate` system offers robust handling for complex evaluation criteria (e.g., few-shot examples, dynamic context).

### Drawbacks and Limitations

1. **Overkill for Current Scope:**
   The current script is lightweight and readable. LangChain is a heavy dependency that introduces complex abstractions (like LCEL/Runnables), adding bloat and a steeper learning curve.
2. **Native Structured Outputs are Sufficient:**
   The native `google.genai` SDK already handles structured JSON outputs via `response_schema=EvaluationResult` efficiently and reliably. LangChain's structured output would merely wrap this existing capability.
3. **External Agent Execution:**
   LangChain excels at managing agent memory, tools, and reasoning loops. Since our harness tests an external CLI tool via `subprocess.run`, LangChain cannot orchestrate the agent and is relegated strictly to the role of a grader.

### Conclusion & Recommendation

**Recommendation: Hold off on LangChain for now.**

The current architecture is elegant, dependency-light, and perfectly suited for its job. The native `google.genai` SDK handles the structured Pydantic evaluation flawlessly.

**When to reconsider LangChain:**

- We need to evaluate the CLI using non-Google models (e.g., Claude, GPT-4) to ensure unbiased grading.
- We require visual tracking of test runs, prompt versions, and token costs using LangSmith.
