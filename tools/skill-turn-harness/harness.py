#!/usr/bin/env python3

# /// script
# dependencies = [
#   "google-antigravity",
#   "google-genai",
#   "pydantic",
#   "pyyaml",
#   "click",
#   "jsonschema",
# ]
# ///

# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
'''Hybrid Python/CLI Test Harness for Gemini Skills.

This module provides a testing framework that executes Gemini CLI skills in an
isolated subprocess and evaluates the interactions using the Gemini API and
structured Pydantic schemas.
'''

# Standard library imports
import glob
import json
import logging
import os
import re
import shutil
import string
import subprocess
import sys
import tempfile

from dataclasses import dataclass, asdict
from datetime import datetime
from typing import Optional, Dict, Union, AsyncIterator


@dataclass
class ThinkingDeltaEvent:
  text: str


@dataclass
class ToolCallEvent:
  name: str
  args: dict


@dataclass
class ErrorEvent:
  message: str


# Third-party imports
import click
import jsonschema
import yaml

from google import genai
from google.genai import types
from pydantic import BaseModel
from google.antigravity import Agent, LocalAgentConfig
from google.antigravity import types as agy_types
from google.antigravity.hooks import policy
import asyncio


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

C_GRAY = '\033[90m'
C_BLUE = '\033[94m'
C_PINK = '\033[95m'
C_GREEN = '\033[92m'
C_RED = '\033[91m'
C_YELLOW = '\033[93m'
C_LIGHT_GRAY = '\033[37m'
C_BOLD_WHITE = '\033[1;37m'


def format_color(text: str, color: str) -> str:
  """Formats text with ANSI color if stdout is a TTY."""
  if sys.stdout.isatty():
    return f"{color}{text}\033[0m"
  return text


class StreamingTrimmer:
  """Buffers streaming deltas to strip leading/trailing whitespace dynamically."""

  def __init__(self):
    self.started = False
    self.whitespace_buffer = ""

  def process_delta(self, delta: str) -> str:
    if not delta:
      return ""

    out = ""
    if not self.started:
      stripped = delta.lstrip()
      if not stripped:
        return ""
      self.started = True
      delta = stripped

    rstripped = delta.rstrip()
    trailing_ws = delta[len(rstripped):]

    if rstripped:
      out = self.whitespace_buffer + rstripped
      self.whitespace_buffer = trailing_ws
    else:
      self.whitespace_buffer += trailing_ws

    if out:
      out = re.sub(r'\n{3,}', '\n\n', out)
    return out

  def flush_remaining(self) -> None:
    self.started = False
    self.whitespace_buffer = ""


class ConsoleRenderer:
  """Handles console formatting and streaming output for interaction turns."""

  def __init__(self):
    self.trimmer = StreamingTrimmer()
    self.need_newline = False
    self.at_start_of_line = True

  def render_thinking(self, text: str):
    to_print = self.trimmer.process_delta(text)
    if to_print:
      if not self.need_newline:
        print(f"  {format_color('🧠 Thinking:', C_GRAY)}", flush=True)
        self.need_newline = True
        self.at_start_of_line = True

      parts = to_print.split('\n')
      for i, part in enumerate(parts):
        if i > 0:
          print('\n', end='')
          self.at_start_of_line = True
        if part:
          if self.at_start_of_line:
            print('  ', end='')
            self.at_start_of_line = False
          print(format_color(part, C_GRAY), end='', flush=True)

  def render_tool_call(self, name: str, args: dict):
    if self.need_newline:
      self.trimmer.flush_remaining()
      print()
      self.need_newline = False
    cleaned_args = {
        k: v for k, v in args.items() if k not in {
            "output",
            "results",
            "num_results",
            "diff_block",
            "exit_code",
            "combined_output",
            "image_name",
        }
    }
    args_str = ", ".join(f"{k}={v}" for k, v in cleaned_args.items())
    print(f"  🛠️ {format_color(f'[Tool Call]: {name}({args_str})', C_GRAY)}")

  def render_error(self, message: str):
    if self.need_newline:
      self.trimmer.flush_remaining()
      print()
      self.need_newline = False
    print(f"  ❌ [Error]: {message}")

  def finalize(self):
    if self.need_newline:
      self.trimmer.flush_remaining()
      print()


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
      files_contain: A dictionary mapping relative file paths to a list of expected strings.
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
        for expected in expected_content:
          if expected not in content:
            print(
                f"❌ [CHECK FAILED]: Expected content '{expected}' not found in '{file_path}'."
            )
            passed = False
  return passed


def check_tool_calls_contain(tool_calls_criteria: dict,
                             executed_tool_calls: list) -> bool:
  '''Checks if the agent's tool calls contain expected literal strings in their arguments.

    Args:
      tool_calls_criteria: A dictionary mapping tool names to lists of expected strings.
      executed_tool_calls: A list of recorded tool calls, each being a dict with 'name' and 'args'.

    Returns:
      True if all tool calls contain their expected strings, False otherwise.
    '''
  if not tool_calls_criteria:
    return True

  passed = True
  try:
    extracted_calls: Dict[str, str] = {}
    for tc in executed_tool_calls:
      name = tc['name']
      args_str = json.dumps(tc['args'])
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
    print(f"❌ [CHECK FAILED]: Failed to process tool calls: {e}")
    passed = False

  return passed


def perform_deterministic_checks(success_criteria: dict, workspace_dir: str,
                                 executed_tool_calls: list,
                                 full_stdout: str) -> bool:
  '''Evaluates the deterministic checks defined in the persona success_criteria.

  Args:
    success_criteria: The success_criteria dictionary from the playbook.
    workspace_dir: The temporary workspace directory path.
    executed_tool_calls: A list of recorded tool calls.
    full_stdout: The combined stdout of all CLI invocations.

  Returns:
    True if all checks pass, False otherwise.
  '''
  passed = True

  if not check_flow_contains(success_criteria.get('flow_contains', []),
                             full_stdout):
    passed = False

  if not check_tool_calls_contain(
      success_criteria.get('tool_calls_contain', {}), executed_tool_calls):
    passed = False

  if not check_files_exist(success_criteria.get('files_exist', []),
                           workspace_dir):
    passed = False

  if not check_files_contain(success_criteria.get('files_contain', {}),
                             workspace_dir):
    passed = False

  return passed


def _view_file_directory_check(args: dict) -> bool:
  """Predicate to check if the target of view_file is actually a directory."""
  path = args.get('AbsolutePath') or args.get('file_path') or args.get('path')
  if path:
    return os.path.isdir(path)
  return False


async def run_turn(
    agent: Agent, user_input: str
) -> AsyncIterator[Union[ThinkingDeltaEvent, ToolCallEvent, ErrorEvent]]:
  """Sends user input and yields interaction events in real-time."""
  await agent.conversation.send(user_input)
  printed_calls = set()
  async for step_obj in agent.conversation.receive_steps():
    if step_obj.thinking_delta:
      yield ThinkingDeltaEvent(text=step_obj.thinking_delta)

    if step_obj.type == agy_types.StepType.TOOL_CALL:
      for tc in step_obj.tool_calls:
        if tc.id not in printed_calls:
          printed_calls.add(tc.id)
          yield ToolCallEvent(name=tc.name, args=dict(tc.args))

    if step_obj.status == agy_types.StepStatus.ERROR:
      yield ErrorEvent(message=step_obj.error or "Unknown step error")


def _get_usage_str(agent: Agent) -> str:
  """Safely retrieves the active context size from the agent's conversation."""
  try:
    usage = agent.conversation.last_turn_usage
    if usage and usage.prompt_token_count is not None:
      return f" [Context: {usage.prompt_token_count:,}]"
  except Exception:
    pass
  return ""


async def run_hybrid_tuning_loop(playbook_path: str, log_dir: str,
                                 skill_src: str = None,
                                 keep_workspace: bool = False,
                                 cli_agent_model: str = None,
                                 cli_evaluator_model: str = None,
                                 max_deviations: int = 3):
  '''Executes the test playbook and evaluates the agent's responses.

  Args:
    playbook_path: The file path to the YAML playbook.
    log_dir: The directory where logs and failed JSON dumps should be written.
    skill_src: Optional path to a local unpacked skill to run.
    keep_workspace: Preserve the temporary workspace directory.
    cli_agent_model: Override for the agent model.
    cli_evaluator_model: Override for the evaluator model.

  Returns:
    True if the playbook passes completely, False if any step fails.
  '''
  # Initialize all finally-block dependencies at the very top to avoid NameErrors on early failure
  log_prefix = "unknown_playbook"
  conversation_history = []
  executed_tool_calls = []
  interaction_log = []
  is_tmpdir = False
  workspace_dir = os.getcwd()
  original_cwd = os.getcwd()

  evaluator_client = genai.Client()
  log_dir = os.path.abspath(log_dir)
  os.makedirs(log_dir, exist_ok=True)
  with open(playbook_path, 'r') as f:
    playbook = yaml.safe_load(f)

  validate_playbook(playbook)

  playbook_timeout = playbook.get('timeout', 60)

  # Determine models (CLI override > Playbook > Default)
  agent_model = cli_agent_model or playbook.get('agent_model')
  evaluator_model = cli_evaluator_model or playbook.get('evaluator_model',
                                                        'gemini-2.5-flash')

  playbook_name = playbook.get('name', 'Unknown Playbook')
  playbook_steps = playbook.get('steps', [])
  persona = playbook.get('persona')

  env_context = parse_and_validate_env(playbook)

  tmpdir_config = playbook.get('tmpdir')
  is_tmpdir = tmpdir_config is not None

  if is_tmpdir:
    workspace_dir = tempfile.mkdtemp(prefix='gemini_harness_')
    open(os.path.join(workspace_dir, '.project_root'), 'w').close()

    def _ignore_symlinks_and_patterns(directory, names):
      ignore_func = shutil.ignore_patterns('.terraform', '.git', '.venv',
                                           'venv', '__pycache__',
                                           '.pytest_cache',
                                           'skill-turn-harness')
      ignored = set(ignore_func(directory, names))
      for name in names:
        if os.path.islink(os.path.join(directory, name)):
          ignored.add(name)
      return list(ignored)

    link_paths = tmpdir_config.get('link_paths', [])
    for path in link_paths:
      src_abs = os.path.abspath(os.path.join(original_cwd, path))
      dst_abs = os.path.join(workspace_dir, path)
      os.makedirs(os.path.dirname(dst_abs), exist_ok=True)
      try:
        if os.path.islink(src_abs):
          print(f'🔗 Skipped symlink: {path}')
        elif os.path.isdir(src_abs):
          shutil.copytree(src_abs, dst_abs,
                          ignore=_ignore_symlinks_and_patterns)
          print(f'📁 Copied directory: {path} -> {dst_abs}')
        else:
          shutil.copy2(src_abs, dst_abs)
          print(f'📄 Copied file: {path} -> {dst_abs}')
      except Exception as e:
        print(f'❌ [SETUP ERROR]: Failed to copy {path}: {e}', file=sys.stderr)
        shutil.rmtree(workspace_dir)
        sys.exit(1)

    os.chdir(workspace_dir)
  else:
    workspace_dir = original_cwd
  print(f'--- Tuning: {playbook_name} | Workspace: {workspace_dir} ---')
  interaction_log = []
  log_prefix = generate_log_prefix(playbook_path)
  md_log_path = os.path.join(log_dir, f'{log_prefix}_log.md')
  init_markdown_log(md_log_path, playbook_name)

  full_stdout = ""
  conversation_history = []
  executed_tool_calls = []
  step_index = 0
  fallback_to_persona = False

  # Configure SDK Agent
  skills_paths = []
  if skill_src:
    if is_tmpdir:
      # If sandboxed in tmpdir, point to the copied skill path inside the sandbox
      skills_paths.append(
          os.path.abspath(os.path.join(workspace_dir, skill_src)))
    else:
      skills_paths.append(os.path.abspath(skill_src))

  # Allow all tools to emulate CLI -y/--dangerously-skip-permissions
  policies = [
      policy.deny(
          agy_types.BuiltinTools.VIEW_FILE.value,
          when=_view_file_directory_check, name=
          "Rejection: Path is a directory, not a file. Use list_directory to inspect it."
      ),
      policy.allow_all()
  ]

  standard_instructions = (
      "GUIDELINES:\n"
      "- Always check if a path is a directory before trying to view it. "
      "Use list_directory to inspect directories, never view_file.\n"
      "- You are running inside an isolated, sandboxed temporary workspace (e.g., /tmp/gemini_harness_*). "
      "Whenever creating local files, configuration directories (like custom-fast-config or fast-config), "
      "or checking defaults, you MUST do so strictly relative to your current workspace directory (CWD). "
      "NEVER try to directly read or write to /home/ludomagno/ or other external folders, as your file tools "
      "are sandboxed and will fail with permission/step errors.")

  config = LocalAgentConfig(
      model=agent_model,
      api_key=os.environ.get('GEMINI_API_KEY'),
      skills_paths=skills_paths,
      policies=policies,
      workspaces=[workspace_dir],
      save_dir=log_dir,  # Use log_dir for raw state too
      system_instructions=standard_instructions,
  )

  try:
    async with Agent(config) as agent:

      async def _execute_turn(user_input_str: str):
        renderer = ConsoleRenderer()
        async for event in run_turn(agent, user_input_str):
          if isinstance(event, ThinkingDeltaEvent):
            renderer.render_thinking(event.text)
          elif isinstance(event, ToolCallEvent):
            executed_tool_calls.append({'name': event.name, 'args': event.args})
            renderer.render_tool_call(event.name, event.args)
          elif isinstance(event, ErrorEvent):
            renderer.render_error(event.message)
        renderer.finalize()

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

        usage_str_start = _get_usage_str(agent) if step_index > 0 else ""
        turn_str = format_color(
            f'[Step {step.step_index + 1}]{usage_str_start}', C_BOLD_WHITE)
        print(
            f"\n{turn_str}\n{format_color('Tester:', C_BLUE)}\n{step.user_input.rstrip()}"
        )

        try:
          await asyncio.wait_for(_execute_turn(step.user_input),
                                 timeout=playbook_timeout)
          step.skill_response = agent.conversation.last_response
        except asyncio.TimeoutError:
          print(f'⚠️ [TIMEOUT] ({playbook_timeout}s)', file=sys.stderr)
          step.skill_response = 'SYSTEM_ERROR: Timeout'
        except Exception as e:
          print(f'⚠️ [ERROR]: {e}', file=sys.stderr)
          step.skill_response = f'SYSTEM_ERROR: {e}'

        full_stdout += step.skill_response + "\n"
        turn_str = format_color(f'[Step {step.step_index + 1}]', C_BOLD_WHITE)
        print(
            f"\n{turn_str}\n\n{format_color('Agent:', C_PINK)}\n{step.skill_response.rstrip()}"
        )

        conversation_history.append({
            "user": step.user_input,
            "agent": step.skill_response
        })

        if step.skill_response.startswith('SYSTEM_ERROR'):
          label = format_color(f'[FAILURE Step {step.step_index + 1}]', C_GRAY)
          msg = format_color('System Error.', C_RED)
          print(f'❌ {label}: {msg}')
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
            model=evaluator_model,
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
            label = format_color(f'[WARNING Step {step.step_index + 1}]',
                                 C_GRAY)
            msg = format_color(step.parsed_eval["reasoning"], C_YELLOW)
            print(f'⚠️ {label}: {msg}')
            print(
                '🔄 Scripted step failed. Falling back to autonomous persona...')
            fallback_to_persona = True
            break
          else:
            label = format_color(f'[FAILURE Step {step.step_index + 1}]',
                                 C_GRAY)
            msg = format_color(step.parsed_eval["reasoning"], C_RED)
            print(f'❌ {label}: {msg}')
            dump_failed_log(log_dir, log_prefix, interaction_log)
            return False
        else:
          label = format_color(f'[PASS Step {step.step_index + 1}]', C_GRAY)
          msg = format_color(step.parsed_eval["reasoning"], C_GREEN)
          print(f'✅ {label}: {msg}')

        step_index += 1

      # If steps succeeded completely and no persona exists, we're done.
      if not persona and not fallback_to_persona:
        label = format_color('[SUCCESS]', C_GRAY)
        msg = format_color(
            f"Scripted Playbook '{playbook_name}' completed successfully.",
            C_GREEN)
        print(f'\n✅ {label} {msg}')
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
                  string.Template(item).safe_substitute(env_context)
                  for item in v
              ] for k, v in success_criteria.get('tool_calls_contain',
                                                {}).items()
          },
          'files_contain': {
              string.Template(k).safe_substitute(env_context): [
                  string.Template(item).safe_substitute(env_context)
                  for item in v
              ] for k, v in success_criteria.get('files_contain', {}).items()
          }
      }

      # Determine next input
      next_input = None
      if len(conversation_history) == 0:
        # Pure autonomous start
        next_input = string.Template(
            persona['initial_user_input']).safe_substitute(env_context)

      max_turns = persona.get('max_turns', 10)

      if next_input:
        print(f"{format_color('Tester:', C_BLUE)}\n{next_input.rstrip()}")

      deviation_count = 0

      for turn in range(max_turns):
        if next_input:
          turn_display = len(conversation_history) + 1
          usage_str_start = _get_usage_str(agent)
          turn_str = format_color(
              f'[Autonomous Turn {turn_display}]{usage_str_start}',
              C_BOLD_WHITE)
          print(f"\n{turn_str}")

          try:
            await asyncio.wait_for(_execute_turn(next_input),
                                   timeout=playbook_timeout)
            agent_response = agent.conversation.last_response
          except asyncio.TimeoutError:
            print(f'⚠️ [TIMEOUT] ({playbook_timeout}s)', file=sys.stderr)
            agent_response = 'SYSTEM_ERROR: Timeout'
          except Exception as e:
            print(f'⚠️ [ERROR]: {e}', file=sys.stderr)
            agent_response = f'SYSTEM_ERROR: {e}'

          full_stdout += agent_response + "\n"
          print(
              f"\n{format_color('Agent:', C_PINK)}\n{agent_response.rstrip()}")

          if agent_response.startswith('SYSTEM_ERROR'):
            print(f'❌ [FAILURE Turn {turn_display}]: System Error.')
            dump_failed_log(log_dir, log_prefix, interaction_log)
            return False

          conversation_history.append({
              "user": next_input,
              "agent": agent_response
          })
          # Log to markdown for autonomous turns (reusing StepData for structure)
          step_log = StepData(step_index=turn_display - 1,
                              user_input=next_input,
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
            model=evaluator_model,
            contents=eval_prompt,
            config=types.GenerateContentConfig(
                response_mime_type='application/json',
                response_schema=AutonomousTurnResult,
                temperature=0.0,
            ),
        )
        parsed_eval = json.loads(eval_response.text)

        if not parsed_eval['agent_followed_skill_rules']:
          deviation_count += 1
          label = format_color('[AGENT DEVIATION]', C_YELLOW)
          msg = format_color(
              f"{parsed_eval['reasoning']} (Deviation {deviation_count}/{max_deviations})",
              C_YELLOW)
          print(f"⚠️ {label}: {msg}")
          if deviation_count > max_deviations:
            label_fail = format_color('[AUTONOMOUS FAIL]', C_GRAY)
            msg_fail = format_color(
                f"Exceeded max allowed deviations ({max_deviations}). Failing test.",
                C_RED)
            print(f"❌ {label_fail}: {msg_fail}")
            dump_failed_log(log_dir, log_prefix, interaction_log)
            return False
          fallback_to_persona = True  # Flag as passed with warning since we recovered from a deviation

        elif parsed_eval['test_completed_successfully']:
          label = format_color('[AUTONOMOUS SEMANTIC SUCCESS]', C_GRAY)
          msg = format_color(parsed_eval['reasoning'], C_GREEN)
          print(f"✅ {label}: {msg}")
          print("🔍 Performing deterministic checks...")

          if perform_deterministic_checks(interpolated_success_criteria,
                                          workspace_dir, executed_tool_calls,
                                          full_stdout):
            if fallback_to_persona:
              label = format_color('[PASS WITH WARNINGS]', C_GRAY)
              msg = format_color(
                  f"Playbook '{playbook_name}' completed via autonomous recovery.",
                  C_YELLOW)
              print(f"\n✅ {label} {msg}")
            else:
              label = format_color('[SUCCESS]', C_GRAY)
              msg = format_color(
                  f"Autonomous Playbook '{playbook_name}' completed successfully.",
                  C_GREEN)
              print(f"\n✅ {label} {msg}")
            print(f'📄 Markdown log saved to: {md_log_path}')
            return True
          else:
            label = format_color('[AUTONOMOUS FAIL]', C_GRAY)
            msg = format_color("Deterministic checks failed.", C_RED)
            print(f"❌ {label}: {msg}")
            dump_failed_log(log_dir, log_prefix, interaction_log)
            return False

        next_input = parsed_eval['next_user_input']
        if next_input:
          print(f"\n{format_color('Tester:', C_BLUE)}\n{next_input.rstrip()}")

      label = format_color('[AUTONOMOUS FAIL]', C_GRAY)
      msg = format_color(
          f"Reached max turns ({max_turns}) without completing the goal.",
          C_RED)
      print(f"❌ {label}: {msg}")
      dump_failed_log(log_dir, log_prefix, interaction_log)
      return False

  except Exception as e:
    print(format_color(f'\n💥 [CRASH] Unexpected error: {e}', C_RED),
          file=sys.stderr)
    import traceback
    traceback.print_exc()
    dump_failed_log(log_dir, log_prefix, interaction_log)
    return False
  except KeyboardInterrupt:
    print('\n🛑 [INTERRUPTED] Shutting down cleanly...')
    dump_failed_log(log_dir, log_prefix, interaction_log)
    return False
  finally:
    # Save the session trace json to the logs directory
    session_log_path = os.path.join(log_dir, f'{log_prefix}_session.json')
    session_data = {
        "messages": conversation_history,
        "toolCalls": executed_tool_calls
    }
    try:
      with open(session_log_path, 'w') as f:
        json.dump(session_data, f, indent=2)
      print(f'📄 Session JSON saved to: {session_log_path}')
    except Exception as e:
      print(f'⚠️ [WARNING] Failed to write session JSON: {e}', file=sys.stderr)

    if is_tmpdir:
      os.chdir(original_cwd)
      if not keep_workspace:
        shutil.rmtree(workspace_dir)
      else:
        print(f'📁 Workspace preserved at: {workspace_dir}')


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
    help='Path to a local unpacked skill directory to run.',
)
@click.option(
    '--env-file',
    type=click.Path(exists=True),
    default=None,
    help='Path to a .env file containing secrets to substitute in the playbook.',
)
@click.option(
    '--keep-workspace',
    is_flag=True,
    help='Preserve the temporary workspace directory after execution.',
)
@click.option(
    '--agent-model',
    type=str,
    default=None,
    help='Override the model the agent uses (e.g., gemini-2.5-pro).',
)
@click.option(
    '--evaluator-model',
    type=str,
    default=None,
    help=
    'Override the model the test harness uses to grade (e.g., gemini-2.5-flash).',
)
@click.option(
    '--max-deviations',
    type=int,
    default=3,
    help=
    'Number of deviations/mistakes the agent can make before failing (allows human recovery).',
)
@click.option(
    '--debug',
    is_flag=True,
    help='Enable debug logging for the SDK.',
)
def main(playbook, log_dir, skill_src, env_file, keep_workspace, agent_model,
         evaluator_model, max_deviations, debug):
  '''Hybrid Python SDK Test Harness.

  Executes a YAML playbook using the Antigravity SDK and evaluates the
  responses using the Gemini API.
  '''
  if env_file:
    load_env_file(env_file)

  if 'GEMINI_API_KEY' not in os.environ:
    print(
        '❌ [ERROR]: GEMINI_API_KEY environment variable is not set.',
        file=sys.stderr,
    )
    print(
        'Please set it in your environment, provide it in a .env file, or store it in ~/.gemini/key.env',
        file=sys.stderr,
    )
    sys.exit(1)

  if debug:
    logging.basicConfig(level=logging.DEBUG)

  asyncio.run(
      run_hybrid_tuning_loop(playbook, log_dir, skill_src, keep_workspace,
                             agent_model, evaluator_model, max_deviations))


if __name__ == '__main__':
  main()
