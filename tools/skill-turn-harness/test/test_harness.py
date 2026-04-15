import os
import json
import subprocess
from unittest.mock import patch, MagicMock
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
  harness.dump_failed_log(str(tmp_path), 'Test Playbook', interaction_log)
  failed_file = tmp_path / 'Test_Playbook_failed.json'
  assert failed_file.exists()
  data = json.loads(failed_file.read_text())
  assert len(data) == 1
  assert data[0]['error'] == 'test'


# --- Phase B: Execution Unit Tests (Mocked) ---


@patch('harness.subprocess.run')
def test_invoke_skill_cli_success(mock_run):
  mock_result = MagicMock()
  mock_result.returncode = 0
  mock_result.stdout = (
      'Warning: YOLO mode is enabled\nLoading extension: foo\nActual response')
  mock_run.return_value = mock_result
  response = harness.invoke_skill_cli('hello', is_first_step=True,
                                      workspace_dir='/tmp')
  # Check command construction
  mock_run.assert_called_once()
  args = mock_run.call_args[0][0]
  assert args == ['gemini', '-y', '-p', 'hello']
  # Check output cleaning
  assert response == 'Actual response'


@patch('harness.subprocess.run')
def test_invoke_skill_cli_timeout(mock_run):
  mock_run.side_effect = subprocess.TimeoutExpired(cmd='gemini', timeout=60)
  response = harness.invoke_skill_cli('hello', is_first_step=False,
                                      workspace_dir='/tmp')
  assert response == 'SYSTEM_ERROR: Timeout'


# --- Phase C: E2E Test ---


@pytest.mark.e2e
def test_e2e_hybrid_tuning_loop(tmp_path):
  '''
    Runs the actual evaluation loop against the basic FAST Setup PoC skill.
    Uses tmp_path for log_dir so we don't pollute the actual workspace logs.
    '''
  fixtures_dir = os.path.join(os.path.dirname(__file__), 'fixtures')
  skill_dir = os.path.join(fixtures_dir, 'my-test-skill')
  playbook_path = os.path.join(fixtures_dir, 'playbook_env.yaml')
  env_file_path = os.path.join(fixtures_dir, '.env.test')

  # Load env to prime the os.environ
  harness.load_env_file(env_file_path)

  result = harness.run_hybrid_tuning_loop(playbook_path, log_dir=str(tmp_path),
                                          skill_src=skill_dir)
  assert result is True
  # Verify the log file was created in the temporary directory
  log_file = tmp_path / 'FAST_Setup_PoC_with_Env_log.md'
  assert log_file.exists()
  content = log_file.read_text()
  assert '✅ PASS' in content
  # Verify substitution happened securely
  assert 'dummy-secret-12345' in content
  assert '${MY_SECRET_ID}' not in content
