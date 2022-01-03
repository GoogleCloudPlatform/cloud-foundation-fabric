#!/usr/bin/env python3

# Copyright 2022 Google LLC
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
import urllib.parse

import click


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
    r'(?sm)module\s*"[^"]+"\s*\{[^\}]*?source\s*=\s*"([^"]+)"'
)
FILE_RE_RESOURCES = re.compile(
    r'(?sm)resource\s*"([^"]+)"'
)
HEREDOC_RE = re.compile(r'(?sm)^<<\-?END(\s*.*?)\s*END$')
MARK_BEGIN = '<!-- BEGIN TFDOC -->'
MARK_END = '<!-- END TFDOC -->'
OUT_ENUM = enum.Enum('O', 'OPEN ATTR ATTR_DATA CLOSE COMMENT TXT SKIP')
OUT_RE = re.compile(r'''(?smx)
    # output open
    (?:^\s*output\s*"([^"]+)"\s*\{\s*$) |
    # attribute
    (?:^\s{2}([a-z]+)\s*=\s*"?(.*?)"?\s*$) |
    # output close
    (?:^\s?(\})\s*$) |
    # comment
    (?:^\s*\#\s*(.*?)\s*$) |
    # anything else
    (?:^(.*?)$)
''')
OUT_TEMPLATE = ('description', 'value', 'sensitive')
TAG_RE = re.compile(r'(?sm)^\s*#\stfdoc:([^:]+:\S+)\s+(.*?)\s*$')
UNESCAPED = string.digits + string.ascii_letters + ' .,;:_-'
VAR_ENUM = enum.Enum(
    'V', 'OPEN ATTR ATTR_DATA SKIP CLOSE COMMENT TXT')
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
VAR_TEMPLATE = ('default', 'description', 'type')


File = collections.namedtuple('File', 'name description modules resources')
Output = collections.namedtuple('Output',
                                'name description sensitive consumers')
Variable = collections.namedtuple(
    'Variable', 'name description type default required source')


# parsing functions


def _extract_tags(body):
  'Extract and return tfdocs tags from content.'
  return {k: v for k, v in TAG_RE.findall(body)}


def _parse(body, enum=VAR_ENUM, re=VAR_RE, template=VAR_TEMPLATE):
  'Low-level parsing function for outputs and variables.'
  item = context = None
  for m in re.finditer(body):
    token = enum(m.lastindex)
    data = m.group(m.lastindex)
    # print(token, m.groups())
    if token == enum.OPEN:
      item = {'name': data, 'tags': {}}
      item.update({k: [] for k in template})
      context = None
    elif token == enum.CLOSE:
      if item:
        yield item
      item = context = None
    elif token == enum.ATTR_DATA:
      if not item:
        continue
      context = m.group(m.lastindex-1)
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


def parse_files(basepath, exclude_files=None):
  'Return a list of File named tuples in root module at basepath.'
  exclude_files = exclude_files or []
  for name in glob.glob(os.path.join(basepath, '*tf')):
    shortname = os.path.basename(name)
    if shortname in exclude_files:
      continue
    try:
      with open(name) as file:
        body = file.read()
    except (IOError, OSError) as e:
      raise SystemExit(f'Cannot read file {name}: {e}')
    tags = _extract_tags(body)
    description = tags.get(
        'file:description', FILE_DESC_DEFAULTS.get(shortname))
    modules = set(
        os.path.basename(urllib.parse.urlparse(m).path)
        for m in FILE_RE_MODULES.findall(body)
    )
    resources = set(FILE_RE_RESOURCES.findall(body))
    yield File(shortname, description, modules, resources)


def parse_outputs(basepath):
  'Return a list of Output named tuples for root module outputs.tf.'
  try:
    with open(os.path.join(basepath, 'outputs.tf')) as file:
      body = file.read()
  except (IOError, OSError) as e:
    raise SystemExit(f'No outputs file in {basepath}.')
  for item in _parse(body, enum=OUT_ENUM, re=OUT_RE, template=OUT_TEMPLATE):
    yield Output(name=item['name'], description=''.join(item['description']),
                 sensitive=item['sensitive'] != [],
                 consumers=item['tags'].get('output:consumers', ''))


def parse_variables(basepath):
  'Return a list of Output named tuples for root module variables.tf.'
  try:
    with open(os.path.join(basepath, 'variables.tf')) as file:
      body = file.read()
  except (IOError, OSError) as e:
    raise SystemExit(f'No variables file in {basepath}.')
  for item in _parse(body):
    # print(item)
    default = HEREDOC_RE.sub(r'\1', '\n'.join(item['default']))
    required = not item['default']
    vtype = '\n'.join(item['type'])
    if not required and default != 'null' and vtype == 'string':
      default = f'"{default}"'
    yield Variable(name=item['name'], description=''.join(item['description']),
                   type=vtype, default=default,
                   required=required,
                   source=item['tags'].get('variable:source', ''))


# formatting functions


def _escape(s):
  'Basic, minimal HTML escaping'
  return ''.join(c if c in UNESCAPED else ('&#%s;' % ord(c)) for c in s)


def format_doc(outputs, variables, files, show_extra=False):
  'Return formatted document.'
  buffer = []
  if files:
    buffer += ['', '## Files', '']
    buffer += list(format_files(files))
  if variables:
    buffer += ['', '## Variables', '']
    buffer += list(format_variables(variables, show_extra))
  if outputs:
    buffer += ['', '## Outputs', '']
    buffer += list(format_outputs(outputs, show_extra))
  if buffer:
    buffer.append('')
  return '\n'.join(buffer)


def format_files(items):
  'Format files table.'
  items.sort(key=lambda i: i.name)
  yield '| name | description | modules | resources |'
  yield '|---|---|---|---|'
  for i in items:
    modules = resources = ''
    if i.modules:
      modules = '<code>%s</code>' % '</code> · <code>'.join(
          sorted(i.modules))
    if i.resources:
      resources = '<code>%s</code>' % '</code> · <code>'.join(
          sorted(i.resources))
    yield f'| [{i.name}](./{i.name}) | {i.description} | {modules} | {resources} |'


def format_outputs(items, show_extra=True):
  'Format outputs table.'
  if not items:
    return
  items.sort(key=lambda i: i.name)
  yield '| name | description | sensitive |' + (
      ' consumers |' if show_extra else ''
  )
  yield '|---|---|:---:|' + (
      '---|' if show_extra else ''
  )
  for i in items:
    consumers = i.consumers or ''
    if consumers:
      consumers = '<code>%s</code>' % '</code> · <code>'.join(
          consumers.split())
    sensitive = '✓' if i.sensitive else ''
    format = f'| {i.name} | {i.description or ""} | {sensitive} |'
    format += f' {consumers} |' if show_extra else ''
    yield format


def format_variables(items, show_extra=True):
  'Format variables table.'
  if not items:
    return
  items.sort(key=lambda i: i.name)
  items.sort(key=lambda i: i.required, reverse=True)
  yield '| name | description | type | required | default |' + (
      ' producer |' if show_extra else ''
  )
  yield '|---|---|:---:|:---:|:---:|' + (
      ':---:|' if show_extra else ''
  )
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
        f'| {i.name} | {i.description or ""} | {vars["type"]} '
        f'| {vars["required"]} | {vars["default"]} |'
    )
    format += f' {vars["source"]} |' if show_extra else ''
    yield format


# replace functions


def get_doc(readme):
  'Check if README file is marked, and return current doc.'
  m = re.search('(?sm)%s\n(.*)\n%s' % (MARK_BEGIN, MARK_END), readme)
  if not m:
    return
  return {'doc': m.group(1), 'start': m.start(), 'end': m.end()}


def create_doc(module_path, files=False, show_extra=False, exclude_files=None):
  try:
    mod_files = list(parse_files(module_path, exclude_files)) if files else []
    mod_variables = list(parse_variables(module_path))
    mod_outputs = list(parse_outputs(module_path))
  except (IOError, OSError) as e:
    raise SystemExit(e)
  return format_doc(mod_outputs, mod_variables, mod_files, show_extra)


def replace_doc(module_path, doc):
  'Replace document in module\'s README.md file.'
  readme_path = os.path.join(module_path, 'README.md')
  try:
    readme = open(readme_path).read()
  except (IOError, OSError) as e:
    raise SystemExit(f'Error opening README {readme_path}: {e}')
  result = get_doc(readme)
  if not result:
    raise SystemExit(f'Mark not found in README {readme_path}')
  if doc == result['doc']:
    return
  try:
    open(readme_path, 'w').write('\n'.join([
        readme[:result['start']],
        MARK_BEGIN,
        doc,
        MARK_END,
        readme[result['end']:]
    ]))
  except (IOError, OSError) as e:
    raise SystemExit(f'Error replacing README {readme_path}: {e}')


@ click.command()
@ click.argument('module', type=click.Path(exists=True))
@click.option('--exclude-file', '-x', multiple=True)
@ click.option('--files/--no-files', default=False)
@ click.option('--replace/--no-replace', default=True)
@ click.option('--show-extra/--no-show-extra', default=False)
def main(module=None, annotate=False, exclude_file=None, files=False, replace=True,
         show_extra=True):
  'Program entry point.'
  doc = create_doc(module, files, show_extra, exclude_file)
  if replace:
    replace_doc(module, doc)
  else:
    print(doc)


if __name__ == '__main__':
  main()
