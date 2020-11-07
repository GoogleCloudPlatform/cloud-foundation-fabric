from pathlib import Path

import marko


MODULES_PATH = Path(__file__).parents[3] / 'modules/'


def pytest_generate_tests(metafunc):
  if 'example' in metafunc.fixturenames:
    modules = [
      x for x in MODULES_PATH.iterdir()
      if x.is_dir()
    ]
    modules.sort()
    examples = []
    ids = []
    for module in modules:
      readme = module / 'README.md'
      if not readme.exists(): continue
      doc = marko.parse(readme.read_text())
      index = 0
      for child in doc.children:
        if isinstance(child, marko.block.FencedCode) and child.lang == 'hcl':
          index += 1
          code = child.children[0].children
          if 'tftest:skip' in code:
            continue
          examples.append(code)
          ids.append(f'{module.stem}:example{index}')

    metafunc.parametrize('example', examples, ids=ids)
