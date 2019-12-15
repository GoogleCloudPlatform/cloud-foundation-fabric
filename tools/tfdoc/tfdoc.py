#! /usr/bin/env python3

# Copyright 2019 Google LLC
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
import os
import re

import click


RE_TYPE_FORMAT = re.compile(r'(?s)^\s*([a-z]+).*?$')
RE_OUTPUTS = re.compile(r'''(?smx)
    (?:^\s*output\s*"([^"]+)"\s*\{$) |
    (?:^\s*description\s*=\s*"([^"]+)"\s*$)
''')
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
    (?:^\s*description\s*=\s*"([^"]+)"\s*$) |
    # variable type start
    (?:^\s*type\s*=\s*(.*?)$) |
    # variable default start
    (?:^\s*default\s*=\s*"?(.*?)"?\s*$) |
    # variable body
    (?:^\s*(\S.*?)$)
''')

OutputData = collections.namedtuple('Output', 'name description')
OutputToken = enum.Enum('OutputToken', 'NAME DESCRIPTION')
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
    self.name = self.description = None

  def parse_token(self, token_type, token_data):
    if token_type == 'NAME':
      if self.in_progress:
        raise ItemParsed(self.close())
      self.in_progress = True
      self.name = token_data
    elif token_type == 'DESCRIPTION':
      setattr(self, token_type.lower(), token_data)

  def close(self):
    return OutputData(self.name, self.description)


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
    self._close()
    self._data = [data]
    self._data_context = context

  def close(self):
    self._close(strip=True)
    return VariableData(self.name, self.description, self.type, self.default,
                        self.default is None)


def format_output(output):
  "Format output."
  return


def format_outputs(outputs):
  "Format variables."
  if not outputs:
    return
  outputs.sort(key=lambda v: v.name)
  yield '| name | description |'
  yield '|---|---|'
  for o in outputs:
    yield '| {name} | {description} |'.format(
        name=o.name, description=o.description)


def format_type(type_spec):
  "Format variable type."
  if type_spec.startswith('map(object'):
    return 'object map'
  return RE_TYPE_FORMAT.sub(r'\1', type_spec)


def format_variables(variables, required_first=True):
  "Format variables."
  if not variables:
    return
  variables.sort(key=lambda v: v.name)
  variables.sort(key=lambda v: v.required, reverse=True)
  yield '| name | description | type | required |'
  yield '|---|---|:---: |:---:|'
  for v in variables:
    yield '| {name} | {description} | {type} | {required}'.format(
        name=v.name if v.required else '*%s*' % v.name,
        description=v.description, type=format_type(v.type),
        required='✓' if v.required else ''
    )


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


@click.command()
@click.argument('module', type=click.Path(exists=True))
def main(module=None):
  "Program entry point."
  try:
    with open(os.path.join(module, 'variables.tf')) as file:
      variables = [v for v in parse_items(
          file.read(), RE_VARIABLES, VariableToken, Variable, VariableData)]
    with open(os.path.join(module, 'outputs.tf')) as file:
      outputs = [o for o in parse_items(
          file.read(), RE_OUTPUTS, OutputToken, Output, OutputData)]
  except (IOError, OSError) as e:
    raise SystemExit(e)
  print('## Variables\n')
  for line in format_variables(variables):
    print(line)
  print()
  print('## Outputs\n')
  for line in format_outputs(outputs):
    print(line)


if __name__ == '__main__':
  main()
