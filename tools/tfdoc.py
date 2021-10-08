#! /usr/bin/env python3

# Copyright 2021 Google LLC
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

import collections
import enum
import glob
import os
import re
import string

import click


MARK_BEGIN = '<!-- BEGIN TFDOC -->'
MARK_END = '<!-- END TFDOC -->'
RE_OUTPUTS = re.compile(r'''(?smx)
    (?:^\s*output\s*"([^"]+)"\s*\{$) |
    (?:^\s*description\s*=\s*"((?:[^"\\]|\\")+)"\s*$) |
    (?:^\s*sensitive\s*=\s*(\S+)\s*$)
''')
RE_TYPE = re.compile(r'([\(\{\}\)])')
RE_VARIABLES = re.compile(r'''(?smx)
    # empty lines
    (^\s*$) |
    # block comment
    (^\s*/\*.*?\*/$) |
    # line comment
    (^\s*\#.*?$) |
    # variable declaration start
    (?:^\s*variable\s*"([^"]+)"\s*\{$) |
    # variable description start
    (?:^\s*description\s*=\s*"((?:[^"\\]|\\")+)"\s*$) |
    # variable type start
    (?:^\s*type\s*=\s*(.*?)$) |
    # variable default start
    (?:^\s*default\s*=\s*"?(.*?)"?\s*$) |
    # variable body
    (?:^\s*(\S.*?)$)
''')
REPL_VALID = string.digits + string.ascii_letters + ' .,;:_-'


OutputData = collections.namedtuple('Output', 'name description sensitive')
OutputToken = enum.Enum('OutputToken', 'NAME DESCRIPTION SENSITIVE')
VariableData = collections.namedtuple(
    'Variable', 'name description type default required')
VariableToken = enum.Enum(
    'VariableToken',
    'EMPTY BLOCK_COMMENT LINE_COMMENT NAME DESCRIPTION TYPE DEFAULT REST')


class ItemParsed(Exception):
  pass


class Output(object):
  "Output parsing helper class."

  def __init__(self):
    self.in_progress = False
    self.name = self.description = self.sensitive = None

  def parse_token(self, token_type, token_data):
    if token_type == 'NAME':
      if self.in_progress:
        raise ItemParsed(self.close())
      self.in_progress = True
      self.name = token_data
    else:
      setattr(self, token_type.lower(), token_data)

  def close(self):
    return OutputData(self.name, self.description, self.sensitive)


class Variable(object):
  "Variable parsing helper class."

  def __init__(self):
    self.in_progress = False
    self.name = self.description = self.type = self.default = None
    self._data = []
    self._data_context = None

  def parse_token(self, token_type, token_data):
    if token_type == 'NAME':
      if self.in_progress:
        raise ItemParsed(self.close())
      self.in_progress = True
      self.name = token_data
    elif token_type == 'DESCRIPTION':
      setattr(self, token_type.lower(), token_data)
    elif token_type in ('DEFAULT', 'TYPE'):
      self._start(token_type.lower(), token_data)
    elif token_type == 'REST':
      self._data.append(token_data)

  def _close(self, strip=False):
    if self._data_context:
      data = self._data
      if strip and '}' in data[-1]:
        data = data[:-1]
      setattr(self, self._data_context, ('\n'.join(data)).strip())

  def _start(self, context, data):
    if context == self._data_context or getattr(self, context):
      self._data.append("%s = %s" % (context, data))
      return
    self._close()
    self._data = [data]
    self._data_context = context

  def close(self):
    self._close(strip=True)
    return VariableData(self.name, self.description, self.type, self.default,
                        self.default is None)


def _escape(s):
  "Basic, minimal HTML escaping"
  return ''.join(c if c in REPL_VALID else ('&#%s;' % ord(c)) for c in s)


def format_outputs(outputs):
  "Format outputs."
  if not outputs:
    return
  outputs.sort(key=lambda v: v.name)
  yield '| name | description | sensitive |'
  yield '|---|---|:---:|'
  for o in outputs:
    yield '| {name} | {description} | {sensitive} |'.format(
        name=o.name, description=o.description,
        sensitive='✓' if o.sensitive else '')


def format_type(type_spec):
  "Format variable type."
  if not type_spec:
    return ''
  buffer = []
  stack = []
  for t in RE_TYPE.split(type_spec.split("\n")[0]):
    if not t:
      continue
    if t in '({':
      stack.append(t)
    elif t in '})':
      stack.pop()
    buffer.append(t)
  for t in reversed(stack):
    buffer.append(')' if t == '(' else '}')
  return ''.join(buffer).replace('object({})', 'object({...})')


def format_variables(variables, required_first=True):
  "Format variables."
  if not variables:
    return
  variables.sort(key=lambda v: v.name)
  variables.sort(key=lambda v: v.required, reverse=True)
  yield '| name | description | type | required | default |'
  yield '|---|---|:---: |:---:|:---:|'
  row = (
      '| {name} | {description} | <code title="{type_spec}">{type}</code> '
      '| {required} | {default} |'
  )
  for v in variables:
    default = type_spec = ''
    if not v.required:
      default = '<code title="{title}">{default}</code>'
      if '\n' in v.default:
        default = default.format(title=_escape(v.default), default='...')
      else:
        default = default.format(title='', default=v.default or '')
    if v.type and '(' in v.type:
      type_spec = _escape(v.type)
    yield row.format(
        name=v.name if v.required else '*%s*' % v.name,
        description=v.description, required='✓' if v.required else '',
        type=format_type(v.type), type_spec=type_spec,
        default=default
    )


def get_doc(variables, outputs):
  "Return formatted documentation."
  buffer = ['## Variables\n']
  for line in format_variables(variables):
    buffer.append(line)
  buffer.append('\n## Outputs\n')
  for line in format_outputs(outputs):
    buffer.append(line)
  return '\n'.join(buffer)


def parse_items(content, item_re, item_enum, item_class, item_data_class):
  "Parse variable or output items in data."
  item = item_class()
  for m in item_re.finditer(content):
    try:
      item.parse_token(item_enum(m.lastindex).name, m.group(m.lastindex))
    except ItemParsed as e:
      item = item_class()
      item.parse_token(item_enum(m.lastindex).name, m.group(m.lastindex))
      yield e.args[0]
  if item.in_progress:
    yield item.close()


def replace_doc(module, doc):
  "Replace document in module's README.md file."
  try:
    readme = open(os.path.join(module, 'README.md')).read()
    m = re.search('(?sm)%s.*%s' % (MARK_BEGIN, MARK_END), readme)
    if not m:
      raise SystemExit('Pattern not found in README file.')
    replacement = "{pre}{begin}\n{doc}\n{end}{post}".format(
        pre=readme[:m.start()], begin=MARK_BEGIN, doc=doc,
        end=MARK_END, post=readme[m.end():])
    open(os.path.join(module, 'README.md'), 'w').write(replacement)
  except (IOError, OSError) as e:
    raise SystemExit('Error replacing in README: %s' % e)


def get_variables(path):
  "Get variables for the module in a path"
  variables = []
  for path in glob.glob(os.path.join(path, 'variables*tf')):
    with open(path) as file:
      variables += [v for v in parse_items(
          file.read(), RE_VARIABLES, VariableToken, Variable, VariableData)]
  return variables


def get_outputs(path):
  "Get outputs for the module in a path"
  outputs = []
  for path in glob.glob(os.path.join(path, 'outputs*tf')):
    with open(path) as file:
      outputs += [o for o in parse_items(
          file.read(), RE_OUTPUTS, OutputToken, Output, OutputData)]
  return outputs


def check_state(path):
  """Determine if a module's README has all its variables and outputs
  documentation up-to-date."""
  try:
    variables = get_variables(path)
    outputs = get_outputs(path)
    readme = open(os.path.join(path, 'README.md')).read()
  except (IOError, OSError):
    return
  m = re.search('(?sm)%s.*%s' % (MARK_BEGIN, MARK_END), readme)
  if not m:
    return
  return get_doc(variables, outputs) in readme


@click.command()
@click.argument('module', type=click.Path(exists=True))
@click.option('--replace/--no-replace', default=True)
def main(module=None, replace=True):
  "Program entry point."
  try:
    variables = get_variables(module)
    outputs = get_outputs(module)
  except (IOError, OSError) as e:
    raise SystemExit(e)
  doc = get_doc(variables, outputs)
  if replace:
    replace_doc(module, doc)
  else:
    print(doc)


if __name__ == '__main__':
  main()
