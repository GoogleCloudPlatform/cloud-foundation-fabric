# **Architecture Document: Hybrid Python/CLI Test Harness**

This document outlines the architecture for testing the Fabric FAST configuration skill. It uses a hybrid approach, executing the skill in its native CLI environment while maintaining deterministic control via a Python orchestration loop.

## **1\. The Approach: Hybrid Isolation**

To accurately test the skill in its target environment while ensuring the reliability of the test harness, the execution and evaluation layers are strictly separated:

* **Orchestrator (Python):** A Python script acts as the absolute authority. It maintains the state machine, reads the playbook, injects inputs, captures outputs, and triggers evaluations.  
* **Execution Target (Gemini CLI):** The skill is run via the gemini CLI using Python's subprocess module. This ensures the test reflects the actual user environment. State is maintained across steps using the CLI's session management flags (e.g., \--resume).  
* **Evaluator (Gemini API):** The semantic evaluation of the CLI's output is performed via direct API calls to Gemini 1.5 Flash. This bypasses the string-parsing unreliability of a CLI and guarantees structured JSON output via Pydantic schemas.

## **2\. The Execution Loop**

The Python orchestrator executes the following rigid sequence for each step in a defined playbook:

1. **Injection:** Read the mocked user input and expected outcome from the playbook step.  
2. **Subprocess Execution:** Invoke the Gemini CLI with the user input and the designated session\_id. Capture stdout and trap stderr to handle hangs or crashes.  
3. **Prompt Assembly:** Construct a strict evaluation prompt combining the exact playbook expectation with the raw string response captured from the CLI.  
4. **Stateless Evaluation:** Call the Gemini API with the evaluation prompt, enforcing a structured output schema (Boolean Pass/Fail and Reasoning).  
5. **Verdict Enforcement:** If the evaluator returns True, proceed to the next step. If False, immediately halt the loop, dump the interaction trace to a JSON file, and alert the developer.

## **3\. Implementation Code**

The following Python script implements the hybrid harness:

import subprocess  
import json  
import sys  
from pydantic import BaseModel  
from google import genai  
from google.genai import types

\# 1\. Define Strict Evaluator Schema  
class EvaluationResult(BaseModel):  
    passed: bool  
    reasoning: str

evaluator\_client \= genai.Client()

def invoke\_skill\_cli(user\_input: str, session\_id: str) \-\> str:  
    \# Requires the CLI to support a session resume flag for state  
    command \= \["gemini", "--resume", session\_id, "-p", user\_input\]  
    try:  
        result \= subprocess.run(command, capture\_output=True, text=True, timeout=30)  
        if result.returncode \!= 0:  
            print(f"⚠️ \[CLI ERROR\]: {result.stderr}", file=sys.stderr)  
            return f"SYSTEM\_ERROR: {result.stderr}"  
        return result.stdout.strip()  
    except subprocess.TimeoutExpired:  
        print("⚠️ \[CLI TIMEOUT\]", file=sys.stderr)  
        return "SYSTEM\_ERROR: Timeout"

def run\_hybrid\_tuning\_loop(playbook\_name: str, playbook\_steps: list, session\_id: str):  
    print(f"--- Tuning: {playbook\_name} | Session: {session\_id} \---")  
    interaction\_log \= \[\]

    for step\_index, step in enumerate(playbook\_steps):  
        user\_input, expected\_outcome \= step\['user\_input'\], step\['expected\_outcome'\]  
          
        skill\_response \= invoke\_skill\_cli(user\_input, session\_id)  
        if skill\_response.startswith("SYSTEM\_ERROR"): break  
              
        eval\_prompt \= f"""  
        OBJECTIVE: {expected\_outcome}  
        ACTUAL RESPONSE: {skill\_response}  
        Evaluate if the agent fulfilled the objective.  
        """

        eval\_response \= evaluator\_client.models.generate\_content(  
            model="gemini-1.5-flash", contents=eval\_prompt,  
            config=types.GenerateContentConfig(  
                response\_mime\_type="application/json",  
                response\_schema=EvaluationResult, temperature=0.0  
            )  
        )  
          
        parsed\_eval \= json.loads(eval\_response.text)  
        interaction\_log.append({"step": step\_index \+ 1, "input": user\_input, "evaluation": parsed\_eval})

        if not parsed\_eval\['passed'\]:  
            print(f"❌ \[FAILURE Step {step\_index \+ 1}\]: {parsed\_eval\['reasoning'\]}")  
            with open(f"{playbook\_name}\_failed.json", "w") as f: json.dump(interaction\_log, f)  
            return False 

    print(f"✅ \[SUCCESS\]")  
    return True

## **4\. Critical Implementation Warnings**

* **Session Data Persistence:** The CLI likely persists session states to disk (e.g., in a local database or JSON file). If you reuse the same session\_id for consecutive test runs without manually deleting the cache file, the skill will inherit the context of the previous run, causing immediate test failures. You must either generate a UUID for every run or build a cache-clearing mechanism into the Python script.  
* **Context Window Discipline:** The evaluation prompt is strictly limited to the current playbook objective and the immediate CLI response. Do not feed the entire CLI conversation history to the Evaluator API, as this significantly increases the risk of hallucinated grading.