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


def invoke_skill_cli(user_input: str, is_first_step: bool,
                     workspace_dir: str) -> str:
  '''Invokes the Gemini CLI using a subprocess.

    Args:
      user_input: The simulated text input from the user.
      is_first_step: True if this is the first step in a playbook, False otherwise.
      workspace_dir: The isolated temporary directory to run the CLI within.

    Returns:
      The stdout of the CLI response, or a SYSTEM_ERROR string on failure.
    '''
  # Use -y to allow tool usage (like activate_skill) without prompt
  command = ['gemini', '-y']
  if not is_first_step:
    command.extend(['--resume', 'latest'])
  command.extend(['-p', user_input])
  try:
    # Run inside the isolated workspace_dir so it maps to a unique project ID in projects.json
    result = subprocess.run(command, capture_output=True, text=True, timeout=60,
                            cwd=workspace_dir)
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
    print('⚠️ [CLI TIMEOUT]', file=sys.stderr)
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


def dump_failed_log(log_dir: str, playbook_name: str, interaction_log: list):
  '''Dumps the full interaction log to a JSON file upon failure.

    Args:
      log_dir: The directory where the failed log should be saved.
      playbook_name: The name of the playbook.
      interaction_log: The list of step data dictionaries recorded so far.
    '''
  failed_json_path = os.path.join(
      log_dir, f'{playbook_name.replace(" ", "_")}_failed.json')
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


def run_hybrid_tuning_loop(playbook_path: str, log_dir: str,
                           skill_src: str = None):
  '''Executes the test playbook and evaluates the agent's responses.

    Args:
      playbook_path: The file path to the YAML playbook.
      log_dir: The directory where logs and failed JSON dumps should be written.
      skill_src: Optional path to a local unpacked skill to link before testing.

    Returns:
      True if the playbook passes completely, False if any step fails.
  '''
  os.makedirs(log_dir, exist_ok=True)
  with open(playbook_path, 'r') as f:
    playbook = yaml.safe_load(f)
  playbook_name = playbook.get('name', 'Unknown Playbook')
  playbook_steps = playbook.get('steps', [])

  env_context = parse_and_validate_env(playbook)

  skill_name = None
  if skill_src:
    skill_name = get_skill_name(skill_src)
    print(f'🔗 Linking local skill: {skill_name} from {skill_src}')
    subprocess.run(['gemini', 'skills', 'link', skill_src, '--consent'],
                   check=True, capture_output=True)

  # Create a completely isolated workspace to ensure fresh session tracking
  workspace_dir = tempfile.mkdtemp(prefix='gemini_harness_')
  print(f'--- Tuning: {playbook_name} | Workspace: {workspace_dir} ---')
  interaction_log = []
  # Initialize Markdown log
  md_log_path = os.path.join(log_dir,
                             f'{playbook_name.replace(" ", "_")}_log.md')
  init_markdown_log(md_log_path, playbook_name)
  try:
    for step_index, step_dict in enumerate(playbook_steps):
      # Perform strict string substitution for defined env variables
      raw_user_input = step_dict['user_input']
      raw_expected_outcome = step_dict['expected_outcome']

      subbed_user_input = string.Template(raw_user_input).safe_substitute(
          env_context)
      subbed_expected_outcome = string.Template(
          raw_expected_outcome).safe_substitute(env_context)

      step = StepData(step_index=step_index, user_input=subbed_user_input,
                      expected_outcome=subbed_expected_outcome)
      is_first_step = (step.step_index == 0)
      print(f'\n[Step {step.step_index + 1}] Input: {step.user_input}')
      step.skill_response = invoke_skill_cli(step.user_input, is_first_step,
                                             workspace_dir)
      print(f'[Step {step.step_index + 1}] Output: {step.skill_response}')
      if step.skill_response.startswith('SYSTEM_ERROR'):
        print(f'❌ [FAILURE Step {step.step_index + 1}]: System Error.')
        step.is_system_error = True
        log_step_to_markdown(md_log_path, **asdict(step))
        interaction_log.append(asdict(step))
        break
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
      # Append to Markdown log
      log_step_to_markdown(md_log_path, **asdict(step))
      if not step.parsed_eval['passed']:
        print(
            f'❌ [FAILURE Step {step.step_index + 1}]: {step.parsed_eval["reasoning"]}'
        )
        dump_failed_log(log_dir, playbook_name, interaction_log)
        return False
      else:
        print(
            f'✅ [PASS Step {step.step_index + 1}]: {step.parsed_eval["reasoning"]}'
        )
    print(f'\n✅ [SUCCESS] Playbook \'{playbook_name}\' completed successfully.')
    print(f'📄 Markdown log saved to: {md_log_path}')
    return True
  finally:
    # Cleanup the temporary workspace
    shutil.rmtree(workspace_dir)
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
def main(playbook, log_dir, skill_src, env_file):
  '''Hybrid Python/CLI Test Harness.

  Executes a YAML playbook against the Gemini CLI and evaluates the
  responses using the Gemini API.
  '''
  if env_file:
    load_env_file(env_file)

  run_hybrid_tuning_loop(playbook, log_dir, skill_src)


if __name__ == '__main__':
  main()
