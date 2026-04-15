#!/usr/bin/env python3
'''Hybrid Python/CLI Test Harness for Gemini Skills.

This module provides a testing framework that executes Gemini CLI skills in an
isolated subprocess and evaluates the interactions using the Gemini API and
structured Pydantic schemas.
'''

import subprocess
import json
import sys
import yaml
import tempfile
import os
import shutil
import click
import re
import jsonschema
import glob
import json
from datetime import datetime
from pydantic import BaseModel
from dataclasses import dataclass, asdict
import string
from typing import Optional, Dict
from google import genai
from google.genai import types


def load_env_file(env_file_path: str):
  '''Loads a .env file and injects its key-value pairs into os.environ.

  Args:
    env_file_path: The path to the .env file.
  '''
  if not os.path.exists(env_file_path):
    raise FileNotFoundError(f'Environment file not found: {env_file_path}')
  with open(env_file_path, 'r') as f:
    for line in f:
      line = line.strip()
      if not line or line.startswith('#'):
        continue
      if '=' in line:
        key, value = line.split('=', 1)
        os.environ[key.strip()] = value.strip()


def validate_playbook(playbook: dict):
  '''Validates a playbook dictionary against the JSON schema.

  Args:
    playbook: The loaded playbook dictionary.
  '''
  schema_path = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                             'playbooks', 'playbook.schema.json')
  if os.path.exists(schema_path):
    with open(schema_path, 'r') as f:
      schema = json.load(f)
    try:
      jsonschema.validate(instance=playbook, schema=schema)
    except jsonschema.exceptions.ValidationError as e:
      print(f"❌ [VALIDATION ERROR] Playbook is invalid: {e.message}",
            file=sys.stderr)
      sys.exit(1)
  else:
    print(
        f"⚠️ [WARNING] Schema file not found at {schema_path}. Skipping validation."
    )


@dataclass
class StepData:
  step_index: int
  user_input: str
  expected_outcome: str
  skill_response: str = ''
  parsed_eval: Optional[dict] = None
  is_system_error: bool = False


# 1. Define Strict Evaluator Schema
class EvaluationResult(BaseModel):
  passed: bool
  reasoning: str


class AutonomousTurnResult(BaseModel):
  agent_followed_skill_rules: bool
  reasoning: str
  test_completed_successfully: bool
  next_user_input: str


# Ensure GEMINI_API_KEY is available. If not, try to load from ~/.gemini/key.env
if 'GEMINI_API_KEY' not in os.environ:
  key_file = os.path.expanduser('~/.gemini/key.env')
  if os.path.exists(key_file):
    with open(key_file, 'r') as f:
      for line in f:
        if line.startswith('GEMINI_API_KEY='):
          os.environ['GEMINI_API_KEY'] = line.strip().split('=', 1)[1]
          break

evaluator_client = genai.Client()


def invoke_skill_cli(user_input: str, is_first_step: bool, workspace_dir: str,
                     gemini_cmd_list: list, timeout: int) -> str:
  '''Invokes the Gemini CLI using a subprocess.

    Args:
      user_input: The simulated text input from the user.
      is_first_step: True if this is the first step in a playbook, False otherwise.
      workspace_dir: The isolated temporary directory to run the CLI within.
      gemini_cmd_list: The base command list (e.g. ['gemini', '-y']).
      timeout: The subprocess timeout in seconds.

    Returns:
      The stdout of the CLI response, or a SYSTEM_ERROR string on failure.
    '''
  command = gemini_cmd_list.copy()
  if not is_first_step:
    command.extend(['--resume', 'latest'])
  command.extend(['-p', user_input])
  try:
    # Run inside the isolated workspace_dir so it maps to a unique project ID in projects.json
    result = subprocess.run(command, capture_output=True, text=True,
                            timeout=timeout, cwd=workspace_dir)
    if result.returncode != 0:
      print(f'⚠️ [CLI ERROR]: {result.stderr}', file=sys.stderr)
      return f'SYSTEM_ERROR: {result.stderr}'
    # Clean up output (remove YOLO warnings etc)
    stdout_lines = result.stdout.strip().split('\n')
    clean_lines = [
        line for line in stdout_lines if not line.startswith('Warning:') and
        not line.startswith('YOLO mode is enabled') and
        not line.startswith('Loading extension:')
    ]
    return '\n'.join(clean_lines).strip()
  except subprocess.TimeoutExpired:
    print(f'⚠️ [CLI TIMEOUT] ({timeout}s)', file=sys.stderr)
    return 'SYSTEM_ERROR: Timeout'


def init_markdown_log(md_log_path: str, playbook_name: str):
  '''Initializes the markdown log file with a header.

    Args:
      md_log_path: The file path where the markdown log will be written.
      playbook_name: The name of the playbook being executed.
    '''
  with open(md_log_path, 'w') as md_file:
    md_file.write(f'# Interaction Log: {playbook_name}\n\n')


def log_step_to_markdown(
    md_log_path: str,
    step_index: int,
    user_input: str,
    expected_outcome: str,
    skill_response: str,
    parsed_eval: dict = None,
    is_system_error: bool = False,
):
  '''Appends a single interaction step to the markdown log.

    Args:
      md_log_path: The file path of the markdown log.
      step_index: The zero-based index of the current step.
      user_input: The simulated user input.
      expected_outcome: The expected outcome defined in the playbook.
      skill_response: The actual response from the agent.
      parsed_eval: The parsed JSON evaluation result from the LLM evaluator.
      is_system_error: True if the CLI execution failed with a system error.
    '''
  with open(md_log_path, 'a') as md_file:
    md_file.write(f'## Step {step_index + 1}\n\n')
    md_file.write(f'**User:**\n\n{user_input}\n\n')
    md_file.write(f'**Expected Outcome:**\n\n{expected_outcome}\n\n')
    md_file.write(f'**Agent:**\n\n{skill_response}\n\n')
    if is_system_error:
      md_file.write('*❌ FAIL: System Error*\n\n---\n\n')
    elif parsed_eval:
      status = '✅ PASS' if parsed_eval['passed'] else '❌ FAIL'
      md_file.write(f'*{status}: {parsed_eval["reasoning"]}*\n\n')
      md_file.write('---\n\n')


def generate_log_prefix(playbook_path: str) -> str:
  '''Generates a slugified prefix for log files using the parent directory and filename.

  Args:
    playbook_path: The file path to the YAML playbook.

  Returns:
    A slugified string with a timestamp.
  '''
  dir_name = os.path.basename(os.path.dirname(playbook_path))
  file_name = os.path.splitext(os.path.basename(playbook_path))[0]
  combined = f'{dir_name}_{file_name}' if dir_name else file_name
  slug = re.sub(r'[^a-zA-Z0-9]+', '-', combined).strip('-').lower()
  timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
  return f'{slug}-{timestamp}'


def dump_failed_log(log_dir: str, log_prefix: str, interaction_log: list):
  '''Dumps the full interaction log to a JSON file upon failure.

    Args:
      log_dir: The directory where the failed log should be saved.
      log_prefix: The prefix string generated for this playbook run.
      interaction_log: The list of step data dictionaries recorded so far.
    '''
  failed_json_path = os.path.join(log_dir, f'{log_prefix}_failed.json')
  with open(failed_json_path, 'w') as f:
    json.dump(interaction_log, f, indent=2)


def get_skill_name(skill_src: str) -> str:
  '''Extracts the skill name from the SKILL.md YAML frontmatter.

  Args:
    skill_src: The directory path containing the SKILL.md file.

  Returns:
    The name of the skill.
  '''
  skill_md_path = os.path.join(skill_src, 'SKILL.md')
  if not os.path.exists(skill_md_path):
    raise ValueError(f'SKILL.md not found in {skill_src}')
  with open(skill_md_path, 'r') as f:
    content = f.read()
  if content.startswith('---'):
    end_idx = content.find('---', 3)
    if end_idx != -1:
      frontmatter = content[3:end_idx]
      metadata = yaml.safe_load(frontmatter)
      if metadata and 'name' in metadata:
        return metadata['name']
  raise ValueError('Could not parse skill name from SKILL.md frontmatter')


def parse_and_validate_env(playbook: dict) -> Dict[str, str]:
  '''Validates required environment variables and returns a substitution dict.

  Args:
    playbook: The loaded playbook dictionary.

  Returns:
    A dictionary mapping the required environment keys to their values.

  Raises:
    ValueError: If a required environment variable is missing.
  '''
  required_envs = playbook.get('env', [])
  env_context = {}
  missing_keys = []

  for key in required_envs:
    if key in os.environ:
      env_context[key] = os.environ[key]
    else:
      missing_keys.append(key)

  if missing_keys:
    raise ValueError(
        f'Missing required environment variables: {", ".join(missing_keys)}')

  return env_context


def check_flow_contains(flow_contains: list, full_stdout: str) -> bool:
  '''Checks if literal strings are present in the combined stdout.

    Args:
      flow_contains: A list of literal strings to search for.
      full_stdout: The combined stdout of all CLI invocations.

    Returns:
      True if all strings are found, False otherwise.
    '''
  passed = True
  for literal in flow_contains:
    if literal not in full_stdout:
      print(
          f"❌ [CHECK FAILED]: Expected literal '{literal}' not found in output flow."
      )
      passed = False
  return passed


def check_files_exist(files_exist: list, workspace_dir: str) -> bool:
  '''Checks if specified files exist within the workspace.

    Args:
      files_exist: A list of relative file paths.
      workspace_dir: The temporary workspace directory path.

    Returns:
      True if all files exist, False otherwise.
    '''
  passed = True
  for file_path in files_exist:
    full_path = os.path.join(workspace_dir, file_path)
    if not os.path.exists(full_path):
      print(f"❌ [CHECK FAILED]: Expected file '{file_path}' does not exist.")
      passed = False
  return passed


def check_files_contain(files_contain: dict, workspace_dir: str) -> bool:
  '''Checks if specified files contain expected literal strings.

    Args:
      files_contain: A dictionary mapping relative file paths to expected strings.
      workspace_dir: The temporary workspace directory path.

    Returns:
      True if all files contain their expected strings, False otherwise.
    '''
  passed = True
  for file_path, expected_content in files_contain.items():
    full_path = os.path.join(workspace_dir, file_path)
    if not os.path.exists(full_path):
      print(
          f"❌ [CHECK FAILED]: Expected file '{file_path}' does not exist for content check."
      )
      passed = False
    else:
      with open(full_path, 'r') as f:
        content = f.read()
        if expected_content not in content:
          print(
              f"❌ [CHECK FAILED]: Expected content '{expected_content}' not found in '{file_path}'."
          )
          passed = False
  return passed


def check_tool_calls_contain(tool_calls_criteria: dict,
                             workspace_dir: str) -> bool:
  '''Checks if the agent's tool calls contain expected literal strings in their arguments.

    Args:
      tool_calls_criteria: A dictionary mapping tool names to lists of expected strings.
      workspace_dir: The temporary workspace directory path.

    Returns:
      True if all tool calls contain their expected strings, False otherwise.
    '''
  if not tool_calls_criteria:
    return True

  passed = True
  workspace_name = os.path.basename(workspace_dir)
  slugified_name = re.sub(r'[^a-zA-Z0-9]+', '-',
                          workspace_name).strip('-').lower()

  session_files = glob.glob(
      os.path.expanduser(
          f'~/.gemini/tmp/{slugified_name}/chats/session-*.json'))
  if not session_files:
    print(
        "❌ [CHECK FAILED]: Expected session JSON file not found in workspace for tool validation."
    )
    return False

  try:
    with open(session_files[0], 'r') as f:
      session_data = json.load(f)

    extracted_calls: Dict[str, str] = {}
    for m in session_data.get('messages', []):
      for tc in m.get('toolCalls', []):
        name = tc.get('name')
        args_str = json.dumps(tc.get('args', {}))
        if name not in extracted_calls:
          extracted_calls[name] = ""
        extracted_calls[name] += args_str + "\n"

    for tool_name, expected_strings in tool_calls_criteria.items():
      if tool_name not in extracted_calls:
        print(
            f"❌ [CHECK FAILED]: Expected tool '{tool_name}' was never called.")
        passed = False
        continue

      tool_args_str = extracted_calls[tool_name]
      for expected_str in expected_strings:
        if expected_str not in tool_args_str:
          print(
              f"❌ [CHECK FAILED]: Expected string '{expected_str}' not found in arguments of tool '{tool_name}'."
          )
          passed = False

  except Exception as e:
    print(f"❌ [CHECK FAILED]: Failed to parse session JSON: {e}")
    passed = False

  return passed


def perform_deterministic_checks(success_criteria: dict, workspace_dir: str,
                                 full_stdout: str) -> bool:
  '''Evaluates the deterministic checks defined in the persona success_criteria.

  Args:
    success_criteria: The success_criteria dictionary from the playbook.
    workspace_dir: The temporary workspace directory path.
    full_stdout: The combined stdout of all CLI invocations.

  Returns:
    True if all checks pass, False otherwise.
  '''
  passed = True

  if not check_flow_contains(success_criteria.get('flow_contains', []),
                             full_stdout):
    passed = False

  if not check_tool_calls_contain(
      success_criteria.get('tool_calls_contain', {}), workspace_dir):
    passed = False

  if not check_files_exist(success_criteria.get('files_exist', []),
                           workspace_dir):
    passed = False

  if not check_files_contain(success_criteria.get('files_contain', {}),
                             workspace_dir):
    passed = False

  return passed


def run_hybrid_tuning_loop(playbook_path: str, log_dir: str,
                           skill_src: str = None, gemini_cmd: str = 'gemini -y',
                           keep_workspace: bool = False):
  '''Executes the test playbook and evaluates the agent's responses.

    Args:
      playbook_path: The file path to the YAML playbook.
      log_dir: The directory where logs and failed JSON dumps should be written.
      skill_src: Optional path to a local unpacked skill to link before testing.
      gemini_cmd: Command and arguments to invoke the CLI.
      keep_workspace: Preserve the temporary workspace directory.

    Returns:
      True if the playbook passes completely, False if any step fails.
  '''
  os.makedirs(log_dir, exist_ok=True)
  with open(playbook_path, 'r') as f:
    playbook = yaml.safe_load(f)

  validate_playbook(playbook)

  playbook_timeout = playbook.get('timeout', 60)
  gemini_cmd_list = gemini_cmd.split()

  playbook_name = playbook.get('name', 'Unknown Playbook')
  playbook_steps = playbook.get('steps', [])
  persona = playbook.get('persona')

  env_context = parse_and_validate_env(playbook)

  skill_name = None
  if skill_src:
    skill_name = get_skill_name(skill_src)
    print(f'🔗 Linking local skill: {skill_name} from {skill_src}')
    subprocess.run(['gemini', 'skills', 'link', skill_src, '--consent'],
                   check=True, capture_output=True)

  workspace_dir = tempfile.mkdtemp(prefix='gemini_harness_')
  open(os.path.join(workspace_dir, '.project_root'), 'w').close()
  print(f'--- Tuning: {playbook_name} | Workspace: {workspace_dir} ---')
  interaction_log = []
  log_prefix = generate_log_prefix(playbook_path)
  md_log_path = os.path.join(log_dir, f'{log_prefix}_log.md')
  init_markdown_log(md_log_path, playbook_name)

  full_stdout = ""
  conversation_history = []
  step_index = 0
  fallback_to_persona = False

  try:
    # --- PHASE 1: SCRIPTED STEPS ---
    for step_dict in playbook_steps:
      raw_user_input = step_dict['user_input']
      raw_expected_outcome = step_dict['expected_outcome']

      subbed_user_input = string.Template(raw_user_input).safe_substitute(
          env_context)
      subbed_expected_outcome = string.Template(
          raw_expected_outcome).safe_substitute(env_context)

      step = StepData(step_index=step_index, user_input=subbed_user_input,
                      expected_outcome=subbed_expected_outcome)

      print(f'\n[Step {step.step_index + 1}] Input: {step.user_input}')
      step.skill_response = invoke_skill_cli(step.user_input,
                                             len(conversation_history) == 0,
                                             workspace_dir, gemini_cmd_list,
                                             playbook_timeout)
      full_stdout += step.skill_response + "\n"
      print(f'[Step {step.step_index + 1}] Output: {step.skill_response}')

      conversation_history.append({
          "user": step.user_input,
          "agent": step.skill_response
      })

      if step.skill_response.startswith('SYSTEM_ERROR'):
        print(f'❌ [FAILURE Step {step.step_index + 1}]: System Error.')
        step.is_system_error = True
        log_step_to_markdown(md_log_path, **asdict(step))
        interaction_log.append(asdict(step))
        dump_failed_log(log_dir, log_prefix, interaction_log)
        return False

      eval_prompt = f'''
            OBJECTIVE: {step.expected_outcome}
            ACTUAL RESPONSE: {step.skill_response}
            Evaluate if the agent fulfilled the objective.
            '''
      eval_response = evaluator_client.models.generate_content(
          model='gemini-2.5-flash',
          contents=eval_prompt,
          config=types.GenerateContentConfig(
              response_mime_type='application/json',
              response_schema=EvaluationResult,
              temperature=0.0,
          ),
      )
      step.parsed_eval = json.loads(eval_response.text)
      interaction_log.append(asdict(step))
      log_step_to_markdown(md_log_path, **asdict(step))

      if not step.parsed_eval['passed']:
        if persona:
          print(
              f'⚠️ [WARNING Step {step.step_index + 1}]: {step.parsed_eval["reasoning"]}'
          )
          print('🔄 Scripted step failed. Falling back to autonomous persona...')
          fallback_to_persona = True
          break
        else:
          print(
              f'❌ [FAILURE Step {step.step_index + 1}]: {step.parsed_eval["reasoning"]}'
          )
          dump_failed_log(log_dir, log_prefix, interaction_log)
          return False
      else:
        print(
            f'✅ [PASS Step {step.step_index + 1}]: {step.parsed_eval["reasoning"]}'
        )

      step_index += 1

    # If steps succeeded completely and no persona exists, we're done.
    if not persona and not fallback_to_persona:
      print(
          f'\n✅ [SUCCESS] Scripted Playbook \'{playbook_name}\' completed successfully.'
      )
      print(f'📄 Markdown log saved to: {md_log_path}')
      return True

    # --- PHASE 2: AUTONOMOUS PERSONA ---
    print("\n--- Entering Autonomous Persona Mode ---")
    persona_context = string.Template(
        persona['context']).safe_substitute(env_context)

    # Interpolate success criteria string values
    success_criteria = persona.get('success_criteria', {})
    interpolated_success_criteria = {
        'llm_checks': [
            string.Template(c).safe_substitute(env_context)
            for c in success_criteria.get('llm_checks', [])
        ],
        'flow_contains': [
            string.Template(c).safe_substitute(env_context)
            for c in success_criteria.get('flow_contains', [])
        ],
        'files_exist': [
            string.Template(c).safe_substitute(env_context)
            for c in success_criteria.get('files_exist', [])
        ],
        'tool_calls_contain': {
            k: [
                string.Template(item).safe_substitute(env_context) for item in v
            ] for k, v in success_criteria.get('tool_calls_contain', {}).items()
        },
        'files_contain': {
            string.Template(k).safe_substitute(env_context):
                string.Template(v).safe_substitute(env_context)
            for k, v in success_criteria.get('files_contain', {}).items()
        }
    }

    # Determine next input
    next_input = None
    if len(conversation_history) == 0:
      # Pure autonomous start
      next_input = string.Template(
          persona['initial_user_input']).safe_substitute(env_context)

    max_turns = persona.get('max_turns', 10)

    for turn in range(max_turns):
      turn_display = turn + step_index + 1

      if next_input:
        print(f'\n[Autonomous Turn {turn_display}] Input: {next_input}')
        agent_response = invoke_skill_cli(next_input,
                                          len(conversation_history) == 0,
                                          workspace_dir, gemini_cmd_list,
                                          playbook_timeout)
        full_stdout += agent_response + "\n"
        print(f'[Autonomous Turn {turn_display}] Output: {agent_response}')

        if agent_response.startswith('SYSTEM_ERROR'):
          print(f'❌ [FAILURE Turn {turn_display}]: System Error.')
          dump_failed_log(log_dir, log_prefix, interaction_log)
          return False

        conversation_history.append({
            "user": next_input,
            "agent": agent_response
        })
        # Log to markdown for autonomous turns (reusing StepData for structure)
        step_log = StepData(step_index=turn_display - 1, user_input=next_input,
                            expected_outcome="Autonomous Persona Turn",
                            skill_response=agent_response)
        interaction_log.append(asdict(step_log))
        with open(md_log_path, 'a') as md_file:
          md_file.write(
              f'## Autonomous Turn {turn_display}\n\n**User:**\n\n{next_input}\n\n**Agent:**\n\n{agent_response}\n\n---\n\n'
          )

      # Evaluate state and generate next input
      llm_checks = "\n".join([
          f"- {check}"
          for check in interpolated_success_criteria.get('llm_checks', [])
      ])
      history_text = "\n".join([
          f"USER: {h['user']}\nAGENT: {h['agent']}\n"
          for h in conversation_history
      ])

      eval_prompt = f"""
      You are simulating a user interacting with an AI agent.
      
      YOUR PERSONA AND RULES:
      {persona_context}
      
      GOAL (SEMANTIC CHECKS TO VERIFY COMPLETION):
      {llm_checks}
      
      CONVERSATION HISTORY:
      {history_text}
      
      TASK:
      1. Evaluate if the agent's latest response was helpful, followed the rules, and is moving towards the goal. Set `agent_followed_skill_rules` to false if the agent hallucinated or broke rules.
      2. Check if the GOAL has been fully achieved based on the conversation so far. If yes, set `test_completed_successfully` to true.
      3. If the GOAL is not achieved, formulate the exact text you will reply with to advance the conversation, using only your persona knowledge. Put this in `next_user_input`.
      """

      eval_response = evaluator_client.models.generate_content(
          model='gemini-2.5-flash',
          contents=eval_prompt,
          config=types.GenerateContentConfig(
              response_mime_type='application/json',
              response_schema=AutonomousTurnResult,
              temperature=0.0,
          ),
      )
      parsed_eval = json.loads(eval_response.text)

      if not parsed_eval['agent_followed_skill_rules']:
        print(f"❌ [AUTONOMOUS FAIL]: {parsed_eval['reasoning']}")
        dump_failed_log(log_dir, log_prefix, interaction_log)
        return False

      if parsed_eval['test_completed_successfully']:
        print(f"✅ [AUTONOMOUS SEMANTIC SUCCESS]: {parsed_eval['reasoning']}")
        print("🔍 Performing deterministic checks...")

        if perform_deterministic_checks(interpolated_success_criteria,
                                        workspace_dir, full_stdout):
          if fallback_to_persona:
            print(
                f"\n✅ [PASS WITH WARNINGS] Playbook '{playbook_name}' completed via autonomous recovery."
            )
          else:
            print(
                f"\n✅ [SUCCESS] Autonomous Playbook '{playbook_name}' completed successfully."
            )
          print(f'📄 Markdown log saved to: {md_log_path}')
          return True
        else:
          print("❌ [AUTONOMOUS FAIL]: Deterministic checks failed.")
          dump_failed_log(log_dir, log_prefix, interaction_log)
          return False

      next_input = parsed_eval['next_user_input']

    print(
        f"❌ [AUTONOMOUS FAIL]: Reached max turns ({max_turns}) without completing the goal."
    )
    dump_failed_log(log_dir, log_prefix, interaction_log)
    return False

  except KeyboardInterrupt:
    print('\n🛑 [INTERRUPTED] Shutting down cleanly...')
    dump_failed_log(log_dir, log_prefix, interaction_log)
    return False
  finally:
    # Locate and copy the session json to the logs directory
    workspace_name = os.path.basename(workspace_dir)
    slugified_name = re.sub(r'[^a-zA-Z0-9]+', '-',
                            workspace_name).strip('-').lower()
    session_files = glob.glob(
        os.path.expanduser(
            f'~/.gemini/tmp/{slugified_name}/chats/session-*.json'))
    if session_files:
      session_log_path = os.path.join(log_dir, f'{log_prefix}_session.json')
      shutil.copy2(session_files[0], session_log_path)
      print(f'📄 Session JSON saved to: {session_log_path}')

    if not keep_workspace:
      # Cleanup the temporary workspace
      shutil.rmtree(workspace_dir)
    else:
      print(f'📁 Workspace preserved at: {workspace_dir}')

    if skill_name:
      print(f'🧹 Unlinking local skill: {skill_name}')
      subprocess.run(['gemini', 'skills', 'uninstall', skill_name], check=False,
                     capture_output=True)


@click.command()
@click.argument('playbook', type=click.Path(exists=True))
@click.option(
    '--log-dir',
    type=click.Path(),
    default='logs',
    help='Directory to store logs and json dumps.',
)
@click.option(
    '--skill-src',
    type=click.Path(exists=True),
    default=None,
    help='Path to a local unpacked skill directory to link before testing.',
)
@click.option(
    '--env-file',
    type=click.Path(exists=True),
    default=None,
    help='Path to a .env file containing secrets to substitute in the playbook.',
)
@click.option(
    '--gemini-cmd',
    type=str,
    default='gemini -y',
    help='Command and initial arguments to invoke the CLI.',
)
@click.option(
    '--keep-workspace',
    is_flag=True,
    help='Preserve the temporary workspace directory after execution.',
)
def main(playbook, log_dir, skill_src, env_file, gemini_cmd, keep_workspace):
  '''Hybrid Python/CLI Test Harness.

  Executes a YAML playbook against the Gemini CLI and evaluates the
  responses using the Gemini API.
  '''
  if env_file:
    load_env_file(env_file)

  run_hybrid_tuning_loop(playbook, log_dir, skill_src, gemini_cmd,
                         keep_workspace)


if __name__ == '__main__':
  main()
