import tftest
import re
import tempfile
from pathlib import Path

import marko

MODULES_PATH = Path(__file__, '../../../../modules/').resolve()
VARIABLES_PATH = Path(__file__, '../variables.tf').resolve()
EXPECTED_RESOURCES_RE = re.compile(r'# tftest:modules=(\d+):resources=(\d+)')


def test_example(example_plan_runner, tmp_path, example):
  (tmp_path / 'modules').symlink_to(MODULES_PATH)
  (tmp_path / 'variables.tf').symlink_to(VARIABLES_PATH)
  (tmp_path / 'main.tf').write_text(example)

  match = EXPECTED_RESOURCES_RE.search(example)
  expected_modules = int(match.group(1)) if match is not None else 1
  expected_resources = int(match.group(2)) if match is not None else 1

  plan, modules, resources = example_plan_runner(str(tmp_path))
  assert expected_modules == len(modules)
  assert expected_resources == len(resources)
