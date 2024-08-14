#!/usr/bin/env python3

# Copyright 2024 Google LLC
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
'''Generate tables for Terraform root module files, outputs and variables.

This tool generates nicely formatted Markdown tables from Terraform source
code, that can be used in root modules README files. It makes a few assumptions
on the code structure:

- that outputs are only in `outputs.tf`
- that variables are only in `variables.tf`
- that code has been formatted via `terraform fmt`

The tool supports annotations using the `tfdoc:scope:key value` syntax.
Annotations are rendered in the optional file table by default, and in the
outputs and variables tables if the `--extra-fields` flag is used. Currently
supported annotations are:

- `tfdoc:file:description`
- `tfdoc:output:consumers`
- `tfdoc:variable:source`

Tables can optionally be directly injected/replaced in README files by using
the tags in the `MARK_BEGIN` and `MARK_END` constants, and setting the
`--replace` flag.
'''

import collections
import enum
import glob
import os
import re
import string
import sys
import urllib.parse
from pathlib import Path

import click
import marko

try:
  from examples.utils import get_tftest_directive
except ImportError:
  BASEDIR = Path(__file__).parents[1]
  sys.path.append(str(BASEDIR / 'tests'))
  from examples.utils import get_tftest_directive

__version__ = '2.1.0'

# TODO(ludomagno): decide if we want to support variables*.tf and outputs*.tf
FILE_DESC_DEFAULTS = {
    'main.tf': 'Module-level locals and resources.',
    'outputs.tf': 'Module outputs.',
    'providers.tf': 'Provider configurations.',
    'variables.tf': 'Module variables.',
    'versions.tf': 'Version pins.',
}
FILE_RE_MODULES = re.compile(
    r'(?sm)module\s*"[^"]+"\s*\{[^\}]*?source\s*=\s*"([^"]+)"')
FILE_RE_RESOURCES = re.compile(r'(?sm)resource\s+"([^"]+)"')
HEREDOC_RE = re.compile(r'(?sm)^<<\-?END(\s*.*?)\s*END$')
MARK_BEGIN = '<!-- BEGIN TFDOC -->'
MARK_END = '<!-- END TFDOC -->'
MARK_OPTS_RE = re.compile(r'(?sm)<!-- TFDOC OPTS ((?:[a-z_]+:[0-1]\s*?)+) -->')
OUT_ENUM = enum.Enum('O', 'OPEN ATTR ATTR_DATA CLOSE COMMENT TXT SKIP')
OUT_RE = re.compile(r'''(?smx)
    # output open
    (?:^\s*output\s*"([^"]+)"\s*\{\s*$) |
    # attribute
    (?:^\n?\s{2}([a-z]+)\s*=\s*"?(.*?)"?\s*$) |
    # output close
    (?:^\s?(\})\s*$) |
    # comment
    (?:^\s*\#\s*(.*?)\s*$) |
    # anything else
    (?:^(.*?)$)
''')
OUT_TEMPLATE = ('description', 'value', 'sensitive')
RECIPE_RE = re.compile(r'(?sm)^#\s*(.*?)$')
REPO_ROOT = os.path.dirname(os.path.dirname(__file__))
REPO_URL = 'https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/blob/master'
TAG_RE = re.compile(r'(?sm)^\s*#\stfdoc:([^:]+:\S+)\s+(.*?)\s*$')
TOC_BEGIN = '<!-- BEGIN TOC -->'
TOC_END = '<!-- END TOC -->'
UNESCAPED = string.digits + string.ascii_letters + ' .,;:_-'
VAR_ENUM = enum.Enum('V', 'OPEN ATTR ATTR_DATA SKIP CLOSE COMMENT TXT')
VAR_RE = re.compile(r'''(?smx)
    # variable open
    (?:^\s*variable\s*"([^"]+)"\s*\{\s*$) |
    # attribute
    (?:^\s{2}([a-z]+)\s*=\s*"?(.*?)"?\s*$) |
    # validation
    (?:^\s+validation\s*(\{)\s*$) |
    # variable close
    (?:^\s?(\})\s*$) |
    # comment
    (?:^\s*\#\s*(.*?)\s*$) |
    # anything else
    (?:^(.*?)$)
''')
VAR_RE_TYPE = re.compile(r'([\(\{\}\)])')
VAR_TEMPLATE = ('default', 'description', 'type', 'nullable')

Document = collections.namedtuple('Document',
                                  'content files variables outputs recipes',
                                  defaults=[None])
File = collections.namedtuple('File', 'name description modules resources')
Output = collections.namedtuple(
    'Output', 'name description sensitive consumers file line')
Recipe = collections.namedtuple('Recipe', 'path title')
Variable = collections.namedtuple(
    'Variable',
    'name description type default required nullable source file line')


def _escape(s):
  'Basic, minimal HTML escaping'
  return ''.join(c if c in UNESCAPED else ('&#%s;' % ord(c)) for c in s)


def _extract_tags(body):
  'Extract and return tfdocs tags from content.'
  return {k: v for k, v in TAG_RE.findall(body)}


def _parse(body, enum=VAR_ENUM, re=VAR_RE, template=VAR_TEMPLATE):
  'Low-level parsing function for outputs and variables.'
  item = context = None
  for m in re.finditer(body):
    token = enum(m.lastindex)
    data = m.group(m.lastindex)
    if token == enum.OPEN:
      match = m.group(0)
      leading_lines = len(match) - len(match.lstrip("\n"))
      start = m.span()[0]
      line = body[:start].count('\n') + leading_lines + 1
      item = {'name': data, 'tags': {}, 'line': line}
      item.update({k: [] for k in template})
      context = None
    elif token == enum.CLOSE:
      if item:
        yield item
      item = context = None
    elif token == enum.ATTR_DATA:
      if not item:
        continue
      context = m.group(m.lastindex - 1)
      item[context].append(data)
    elif token == enum.SKIP:
      context = token
    elif token == enum.COMMENT:
      if item and data.startswith('tfdoc:'):
        k, v = data.split(' ', 1)
        item['tags'][k[6:]] = v
    elif token == enum.TXT:
      if context and context != enum.SKIP:
        item[context].append(data)


def create_toc(readme):
  'Create a Markdown table of contents a for README.'
  doc = marko.parse(readme)
  lines = []
  headings = [x for x in doc.children if x.get_type() == 'Heading']
  for h in headings[1:]:
    title = h.children[0].children
    slug = title.lower().strip()
    slug = re.sub(r'[^\w\s-]', '', slug)
    slug = re.sub(r'[-\s]+', '-', slug)
    link = f'- [{title}](#{slug})'
    indent = '  ' * (h.level - 2)
    lines.append(f'{indent}{link}')
  return "\n".join(lines)


def create_tfref(module_path, files=False, show_extra=False, exclude_files=None,
                 readme=None):
  'Return tfdoc mark and generated content.'
  if readme:
    # check for overrides in doc
    opts = get_tfref_opts(readme)
    files = opts.get('files', files)
    show_extra = opts.get('show_extra', show_extra)
  abspath = os.path.abspath(module_path)
  try:
    if os.path.dirname(abspath).endswith('/modules'):
      mod_recipes = list(
          parse_recipes(module_path,
                        f'{REPO_URL}/modules/{os.path.basename(abspath)}'))
    else:
      mod_recipes = None
    mod_files = list(parse_files(module_path, exclude_files)) if files else []
    mod_variables = list(parse_variables(module_path, exclude_files))
    mod_outputs = list(parse_outputs(module_path, exclude_files))
    mod_fixtures = list(parse_fixtures(module_path, readme))
  except (IOError, OSError) as e:
    raise SystemExit(e)
  doc = format_tfref(mod_outputs, mod_variables, mod_files, mod_fixtures,
                     mod_recipes, show_extra)
  return Document(doc, mod_files, mod_variables, mod_outputs, mod_recipes)


def format_tfref(outputs, variables, files, fixtures, recipes=None,
                 show_extra=False):
  'Return formatted document.'
  buffer = []
  if recipes:
    buffer += ['', '## Recipes', '']
    buffer += list(format_tfref_recipes(recipes))
  if files:
    buffer += ['', '## Files', '']
    buffer += list(format_tfref_files(files))
  if variables:
    buffer += ['', '## Variables', '']
    buffer += list(format_tfref_variables(variables, show_extra))
  if outputs:
    buffer += ['', '## Outputs', '']
    buffer += list(format_tfref_outputs(outputs, show_extra))
  if fixtures:
    buffer += ['', '## Fixtures', '']
    buffer += list(format_tfref_fixtures(fixtures))
  return '\n'.join(buffer).strip()


def format_tfref_files(items):
  'Format files table.'
  items = sorted(items, key=lambda i: i.name)
  num_modules = sum(len(i.modules) for i in items)
  num_resources = sum(len(i.resources) for i in items)
  yield '| name | description |{}{}'.format(
      ' modules |' if num_modules else '',
      ' resources |' if num_resources else '')
  yield '|---|---|{}{}'.format('---|' if num_modules else '',
                               '---|' if num_resources else '')
  for i in items:
    modules = resources = ''
    if i.modules:
      modules = '<code>%s</code>' % '</code> · <code>'.join(sorted(i.modules))
    if i.resources:
      resources = '<code>%s</code>' % '</code> · <code>'.join(
          sorted(i.resources))
    yield '| [{}](./{}) | {} |{}{}'.format(
        i.name, i.name, i.description, f' {modules} |' if num_modules else '',
        f' {resources} |' if num_resources else '')


def format_tfref_fixtures(items):
  'Format fixtures table.'
  for x in items:
    yield f"- [{os.path.basename(x)}]({x})"


def format_tfref_outputs(items, show_extra=True):
  'Format outputs table.'
  if not items:
    return
  items = sorted(items, key=lambda i: i.name)
  yield '| name | description | sensitive |' + (' consumers |'
                                                if show_extra else '')
  yield '|---|---|:---:|' + ('---|' if show_extra else '')
  for i in items:
    consumers = i.consumers or ''
    if consumers:
      consumers = '<code>%s</code>' % '</code> · <code>'.join(consumers.split())
    sensitive = '✓' if i.sensitive else ''
    format = f'| [{i.name}]({i.file}#L{i.line}) | {i.description or ""} | {sensitive} |'
    format += f' {consumers} |' if show_extra else ''
    yield format


def format_tfref_recipes(recipes):
  'Format recipes list.'
  if not recipes:
    return
  for r in recipes:
    yield f'- [{r.title}]({r.path})'


def format_tfref_variables(items, show_extra=True):
  'Format variables table.'
  if not items:
    return
  items = sorted(items, key=lambda i: (not i.required, i.name))
  yield '| name | description | type | required | default |' + (
      ' producer |' if show_extra else '')
  yield '|---|---|:---:|:---:|:---:|' + (':---:|' if show_extra else '')
  for i in items:
    vars = {
        'default': f'<code>{_escape(i.default)}</code>' if i.default else '',
        'required': '✓' if i.required else '',
        'source': f'<code>{i.source}</code>' if i.source else '',
        'type': f'<code>{_escape(i.type)}</code>'
    }
    for k in ('default', 'type'):
      title = getattr(i, k)
      if '\n' in title:
        value = title.split('\n')
        # remove indent
        title = '\n'.join([value[0]] + [l[2:] for l in value[1:]])
        if len(value[0]) >= 18 or len(value[-1]) >= 18:
          value = '…'
        else:
          value = f'{value[0]}…{value[-1].strip()}'
        vars[k] = f'<code title="{_escape(title)}">{_escape(value)}</code>'
    format = (
        f'| [{i.name}]({i.file}#L{i.line}) | {i.description or ""} | {vars["type"]} '
        f'| {vars["required"]} | {vars["default"]} |')
    format += f' {vars["source"]} |' if show_extra else ''
    yield format


def get_readme(readme_path):
  'Open and return README.md in module.'
  try:
    return open(readme_path, "r", encoding="utf-8").read()
  except (IOError, OSError) as e:
    raise SystemExit(f'Error opening README {readme_path}: {e}')


def get_tfref_parts(readme):
  'Check if README file is marked, and return current doc.'
  m = re.search('(?sm)%s(.*)%s' % (MARK_BEGIN, MARK_END), readme)
  if not m:
    return
  return {'doc': m.group(1).strip(), 'start': m.start(), 'end': m.end()}


def get_tfref_opts(readme):
  'Check if README file is setting options via a mark, and return options.'
  m = MARK_OPTS_RE.search(readme)
  opts = {}
  if not m:
    return opts
  try:
    for o in m.group(1).split():
      k, v = o.split(':')
      opts[k] = bool(int(v))
  except (TypeError, ValueError) as e:
    raise SystemExit(f'incorrect option mark: {e}')
  return opts


def get_toc_parts(readme):
  'Check if README file is marked, and return current toc.'
  t = re.search('(?sm)%s(.*)%s' % (TOC_BEGIN, TOC_END), readme)
  if not t:
    return
  return {'toc': t.group(1).strip(), 'start': t.start(), 'end': t.end()}


def parse_files(basepath, exclude_files=None):
  'Return a list of File named tuples in root module at basepath.'
  exclude_files = exclude_files or []
  for name in glob.glob(os.path.join(basepath, '*tf')):
    if os.path.islink(name):
      continue
    shortname = os.path.basename(name)
    if shortname in exclude_files:
      continue
    try:
      with open(name, encoding='utf-8') as file:
        body = file.read()
    except (IOError, OSError) as e:
      raise SystemExit(f'Cannot read file {name}: {e}')
    tags = _extract_tags(body)
    description = tags.get('file:description',
                           FILE_DESC_DEFAULTS.get(shortname))
    modules = set(
        os.path.basename(urllib.parse.urlparse(m).path)
        for m in FILE_RE_MODULES.findall(body))
    resources = set(FILE_RE_RESOURCES.findall(body))
    yield File(shortname, description, modules, resources)


def parse_fixtures(basepath, readme):
  'Return a list of file paths of all the unique fixtures used in the module.'
  doc = marko.parse(readme)
  used_fixtures = set()
  for child in doc.children:
    if isinstance(child, marko.block.FencedCode):
      if child.lang == 'hcl':
        code = child.children[0].children
        if directive := get_tftest_directive(code):
          if fixtures := directive.kwargs.get('fixtures'):
            for fixture in fixtures.split(','):
              fixture_full = os.path.join(REPO_ROOT, 'tests', fixture)
              if not os.path.exists(fixture_full):
                raise SystemExit(f'Unknown fixture: {fixture}')
              fixture_relative = os.path.relpath(fixture_full, basepath)
              used_fixtures.add(fixture_relative)
  yield from sorted(used_fixtures)


def parse_outputs(basepath, exclude_files=None):
  'Return a list of Output named tuples for root module outputs*.tf.'
  exclude_files = exclude_files or []
  names = glob.glob(os.path.join(basepath, 'outputs*tf'))
  names += glob.glob(os.path.join(basepath, 'local-*outputs*tf'))
  for name in names:
    shortname = os.path.basename(name)
    if shortname in exclude_files:
      continue
    try:
      with open(name, encoding='utf-8') as file:
        body = file.read()
    except (IOError, OSError) as e:
      raise SystemExit(f'Cannot open outputs file {shortname}.')
    for item in _parse(body, enum=OUT_ENUM, re=OUT_RE, template=OUT_TEMPLATE):
      description = ''.join(item['description'])
      sensitive = item['sensitive'] != []
      consumers = item['tags'].get('output:consumers', '')
      yield Output(name=item['name'], description=description,
                   sensitive=sensitive, consumers=consumers, file=shortname,
                   line=item['line'])


def parse_recipes(module_path, module_url):
  'Find and return module recipes.'
  for dirpath, dirnames, filenames in os.walk(module_path):
    name = os.path.basename(dirpath)
    if name.startswith('recipe-') and 'README.md' in filenames:
      try:
        with open(os.path.join(dirpath, 'README.md'), encoding='utf-8') as f:
          match = RECIPE_RE.search(f.read())
          if match:
            yield Recipe(f'{module_url}/{name}', match.group(1))
          else:
            raise SystemExit(f'No title for recipe {dirpath}')
      except (IOError, OSError) as e:
        raise SystemExit(f'Error opening recipe {dirpath}')


def parse_variables(basepath, exclude_files=None):
  'Return a list of Variable named tuples for root module variables*.tf.'
  exclude_files = exclude_files or []
  names = glob.glob(os.path.join(basepath, 'variables*tf'))
  names += glob.glob(os.path.join(basepath, 'local-*variables*tf'))
  for name in names:
    shortname = os.path.basename(name)
    if shortname in exclude_files:
      continue
    try:
      with open(name, encoding='utf-8') as file:
        body = file.read()
    except (IOError, OSError) as e:
      raise SystemExit(f'Cannot open variables file {shortname}.')
    for item in _parse(body):
      description = (''.join(item['description'])).replace('|', '\\|')
      vtype = '\n'.join(item['type'])
      default = HEREDOC_RE.sub(r'\1', '\n'.join(item['default']))
      required = not item['default']
      nullable = item.get('nullable') != ['false']
      source = item['tags'].get('variable:source', '')
      if not required and default != 'null' and vtype == 'string':
        default = f'"{default}"'

      yield Variable(name=item['name'], description=description, type=vtype,
                     default=default, required=required, source=source,
                     file=shortname, line=item['line'], nullable=nullable)


def render_tfref(readme, doc):
  'Replace document in module\'s README.md file.'
  result = get_tfref_parts(readme)
  if not result:
    raise SystemExit(f'Mark not found in README')
  if doc == result['doc']:
    return readme
  return '\n'.join([
      readme[:result['start']].rstrip(),
      MARK_BEGIN,
      doc,
      MARK_END,
      readme[result['end']:].lstrip(),
  ])


def render_toc(readme, toc):
  'Replace toc in module\'s README.md file.'
  result = get_toc_parts(readme)
  if not result or toc == result['toc']:
    return readme
  return '\n'.join([
      readme[:result['start']].rstrip(),
      '',
      TOC_BEGIN,
      toc,
      TOC_END,
      '',
      readme[result['end']:].lstrip(),
  ])


@click.command()
@click.argument('module_path', type=click.Path(exists=True))
@click.option('--exclude-file', '-x', multiple=True)
@click.option('--files/--no-files', default=False)
@click.option('--replace/--no-replace', default=True)
@click.option('--show-extra/--no-show-extra', default=False)
@click.option('--toc-only', is_flag=True, default=False)
def main(module_path=None, exclude_file=None, files=False, replace=True,
         show_extra=True, toc_only=False):
  'Program entry point.'
  readme_path = os.path.join(module_path, 'README.md')
  readme = get_readme(readme_path)
  if not toc_only:
    doc = create_tfref(module_path, files, show_extra, exclude_file, readme)
    readme = render_tfref(readme, doc.content)
  toc = create_toc(readme)
  readme = render_toc(readme, toc)
  if replace:
    try:
      with open(readme_path, 'w', encoding='utf-8') as f:
        f.write(readme)
    except (IOError, OSError) as e:
      raise SystemExit(f'Error replacing README {readme_path}: {e}')
  else:
    print(readme)


if __name__ == '__main__':
  main()
