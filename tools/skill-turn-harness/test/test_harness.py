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

import os
import json
import subprocess
import asyncio
from unittest.mock import patch, MagicMock, AsyncMock, PropertyMock
import pytest
from dataclasses import asdict

import harness

# --- Phase A: Data & Logging Unit Tests ---


def test_parse_and_validate_env(monkeypatch):
  playbook = {'env': ['TEST_KEY']}

  # Missing key raises error
  with pytest.raises(ValueError,
                     match='Missing required environment variables: TEST_KEY'):
    harness.parse_and_validate_env(playbook)

  # Present key succeeds
  monkeypatch.setenv('TEST_KEY', '123')
  result = harness.parse_and_validate_env(playbook)
  assert result['TEST_KEY'] == '123'


def test_step_data_serialization():
  step = harness.StepData(
      step_index=0,
      user_input='hello',
      expected_outcome='greet back',
      skill_response='hi',
      parsed_eval={
          'passed': True,
          'reasoning': 'ok'
      },
      is_system_error=False,
  )
  d = asdict(step)
  assert d['step_index'] == 0
  assert d['user_input'] == 'hello'
  assert d['expected_outcome'] == 'greet back'
  assert d['parsed_eval']['passed'] is True


def test_load_env_file(tmp_path):
  env_file = tmp_path / '.env'
  env_file.write_text('FOO=bar\n# comment\nBAZ=qux=123\n')

  harness.load_env_file(str(env_file))
  assert os.environ.get('FOO') == 'bar'
  assert os.environ.get('BAZ') == 'qux=123'


def test_markdown_logging(tmp_path):
  log_file = tmp_path / 'test_log.md'
  harness.init_markdown_log(str(log_file), 'Test Playbook')
  harness.log_step_to_markdown(
      md_log_path=str(log_file),
      step_index=0,
      user_input='input 1',
      expected_outcome='outcome 1',
      skill_response='response 1',
      parsed_eval={
          'passed': True,
          'reasoning': 'Good job'
      },
  )
  content = log_file.read_text()
  assert '# Interaction Log: Test Playbook' in content
  assert '## Step 1' in content
  assert '**User:**\n\ninput 1' in content
  assert '**Expected Outcome:**\n\noutcome 1' in content
  assert '**Agent:**\n\nresponse 1' in content
  assert '✅ PASS: Good job' in content


def test_dump_failed_log(tmp_path):
  interaction_log = [{'step': 1, 'error': 'test'}]
  harness.dump_failed_log(str(tmp_path), 'test-playbook-prefix',
                          interaction_log)
  failed_file = tmp_path / 'test-playbook-prefix_failed.json'
  assert failed_file.exists()
  data = json.loads(failed_file.read_text())
  assert len(data) == 1
  assert data[0]['error'] == 'test'


# --- Phase B: Execution Unit Tests (Mocked) ---


@patch('harness.genai.Client')
@patch('harness.Agent')
def test_run_hybrid_tuning_loop_mocked_success(mock_agent_class,
                                               mock_client_class, tmp_path):
  # Mock Conversation
  mock_conversation = MagicMock()
  mock_conversation.send = AsyncMock()

  async def mock_receive_steps():
    yield harness.agy_types.Step(type=harness.agy_types.StepType.TEXT_RESPONSE,
                                 source=harness.agy_types.StepSource.MODEL,
                                 target=harness.agy_types.StepTarget.USER,
                                 status=harness.agy_types.StepStatus.DONE,
                                 content="Mocked Agent Response")

  mock_conversation.receive_steps.return_value = mock_receive_steps()
  type(mock_conversation).last_response = PropertyMock(
      return_value="Mocked Agent Response")

  # Mock Agent
  mock_agent = MagicMock()
  mock_agent.conversation = mock_conversation
  mock_agent_class.return_value.__aenter__.return_value = mock_agent

  # Mock Evaluator
  mock_eval_client = MagicMock()
  mock_client_class.return_value = mock_eval_client
  mock_eval_response = MagicMock()
  mock_eval_response.text = '{"passed": true, "reasoning": "Mocked pass"}'
  mock_eval_client.models.generate_content.return_value = mock_eval_response

  # Playbook
  playbook_content = """
name: "Mocked Playbook"
steps:
  - user_input: "Hello"
    expected_outcome: "Greet"
"""
  playbook_file = tmp_path / "playbook.yaml"
  playbook_file.write_text(playbook_content)

  import asyncio
  result = asyncio.run(
      harness.run_hybrid_tuning_loop(str(playbook_file), log_dir=str(tmp_path)))

  assert result is True
  mock_conversation.send.assert_called_once_with("Hello")
  mock_eval_client.models.generate_content.assert_called_once()


@patch('harness.genai.Client')
@patch('harness.Agent')
def test_run_hybrid_tuning_loop_mocked_timeout(mock_agent_class,
                                               mock_client_class, tmp_path):
  # Mock genai.Client
  mock_client_class.return_value = MagicMock()
  import asyncio
  mock_conversation = MagicMock()
  mock_conversation.send = AsyncMock(side_effect=asyncio.TimeoutError())

  async def empty_gen():
    if False:
      yield

  mock_conversation.receive_steps.return_value = empty_gen()

  mock_agent = MagicMock()
  mock_agent.conversation = mock_conversation
  mock_agent_class.return_value.__aenter__.return_value = mock_agent

  # Playbook
  playbook_content = """
name: "Mocked Playbook"
steps:
  - user_input: "Hello"
    expected_outcome: "Greet"
"""
  playbook_file = tmp_path / "playbook.yaml"
  playbook_file.write_text(playbook_content)

  result = asyncio.run(
      harness.run_hybrid_tuning_loop(str(playbook_file), log_dir=str(tmp_path)))

  assert result is False
  mock_conversation.send.assert_called_once_with("Hello")

  log_files = list(tmp_path.glob('*_log.md'))
  assert len(log_files) == 1
  content = log_files[0].read_text()
  assert 'SYSTEM_ERROR: Timeout' in content


@pytest.mark.asyncio
@patch('harness.Agent')
async def test_run_turn_generator(mock_agent_class):
  # Mock steps returned by the SDK
  async def mock_receive_steps():
    yield harness.agy_types.Step(type=harness.agy_types.StepType.UNKNOWN,
                                 status=harness.agy_types.StepStatus.DONE,
                                 thinking_delta="Thinking about it")
    yield harness.agy_types.Step(
        type=harness.agy_types.StepType.TOOL_CALL,
        status=harness.agy_types.StepStatus.DONE, tool_calls=[
            harness.agy_types.ToolCall(id="tc-1", name="list_directory",
                                       args={"path": "/tmp"})
        ])
    yield harness.agy_types.Step(type=harness.agy_types.StepType.TEXT_RESPONSE,
                                 status=harness.agy_types.StepStatus.ERROR,
                                 error="Something went wrong")

  mock_conversation = MagicMock()
  mock_conversation.send = AsyncMock()
  mock_conversation.receive_steps.return_value = mock_receive_steps()

  mock_agent = MagicMock()
  mock_agent.conversation = mock_conversation

  # Consume our new run_turn async generator
  events = []
  async for event in harness.run_turn(mock_agent, "Hi"):
    events.append(event)

  # Verify correct types and data are yielded
  assert len(events) == 3
  assert isinstance(events[0], harness.ThinkingDeltaEvent)
  assert events[0].text == "Thinking about it"

  assert isinstance(events[1], harness.ToolCallEvent)
  assert events[1].name == "list_directory"
  assert events[1].args == {"path": "/tmp"}

  assert isinstance(events[2], harness.ErrorEvent)
  assert events[2].message == "Something went wrong"


# --- Phase C: E2E Test ---


@pytest.mark.e2e
def test_e2e_hybrid_tuning_loop(tmp_path):
  '''
    Runs the actual evaluation loop against the basic FAST Setup PoC skill.
    Uses tmp_path for log_dir so we don't pollute the actual workspace logs.
    '''
  fixtures_dir = os.path.join(os.path.dirname(__file__), 'fixtures')
  skill_dir = os.path.join(fixtures_dir, 'mock-conversation-skill')
  playbook_path = os.path.join(fixtures_dir,
                               'playbook_scripted_env_substitution.yaml')
  env_file_path = os.path.join(fixtures_dir, '.env.test')

  # Load env to prime the os.environ
  harness.load_env_file(env_file_path)

  result = asyncio.run(
      harness.run_hybrid_tuning_loop(playbook_path, log_dir=str(tmp_path),
                                     skill_src=skill_dir))
  assert result is True
  # Verify the log file was created in the temporary directory
  log_files = list(tmp_path.glob('*_log.md'))
  assert len(log_files) == 1
  log_file = log_files[0]
  assert log_file.exists()
  content = log_file.read_text()
  assert '✅ PASS' in content
  # Verify substitution happened securely
  assert 'dummy-secret-12345' in content
  assert '${MY_SECRET_ID}' not in content


@pytest.mark.e2e
def test_e2e_autonomous_tuning_loop(tmp_path):
  '''
  Runs the autonomous evaluation loop against the basic FAST Setup PoC skill.
  '''
  fixtures_dir = os.path.join(os.path.dirname(__file__), 'fixtures')
  skill_dir = os.path.join(fixtures_dir, 'mock-conversation-skill')
  playbook_path = os.path.join(fixtures_dir,
                               'playbook_autonomous_conversation.yaml')
  env_file_path = os.path.join(fixtures_dir, '.env.test')

  harness.load_env_file(env_file_path)

  result = asyncio.run(
      harness.run_hybrid_tuning_loop(playbook_path, log_dir=str(tmp_path),
                                     skill_src=skill_dir))
  assert result is True
  log_files = list(tmp_path.glob('*_log.md'))
  assert len(log_files) == 1
  content = log_files[0].read_text()

  # Check that the autonomous turns were logged
  assert '## Autonomous Turn 1' in content
  assert 'dummy-secret-12345' in content


@pytest.mark.e2e
def test_e2e_tool_calls_contain(tmp_path):
  '''
  Runs an autonomous evaluation loop to verify tool_calls_contain deterministic checks.
  '''
  fixtures_dir = os.path.join(os.path.dirname(__file__), 'fixtures')
  skill_dir = os.path.join(fixtures_dir, 'mock-tool-use-skill')
  playbook_path = os.path.join(fixtures_dir,
                               'playbook_autonomous_tool_use.yaml')

  result = asyncio.run(
      harness.run_hybrid_tuning_loop(playbook_path, log_dir=str(tmp_path),
                                     skill_src=skill_dir))

  assert result is True
  # Verify that the session JSON was saved
  session_files = list(tmp_path.glob('*_session.json'))
  assert len(session_files) == 1
  assert session_files[0].exists()
