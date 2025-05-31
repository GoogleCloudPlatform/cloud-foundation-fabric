#!/usr/bin/env python3

# Copyright 2025 Google LLC
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

import click
import collections
import logging
import json

from pathlib import Path

DOC = '\n\n'.join(
    ('# {title}', '<!-- markdownlint-disable MD036 -->', '## Properties',
     '{properties}', '## Definitions', '{definitions}'))

Array = collections.namedtuple('Array', 'name items default', defaults=[None])
Boolean = collections.namedtuple('Boolean', 'name default')
Integer = collections.namedtuple('Integer', 'name default enum')
AnyOf = collections.namedtuple('AnyOf', 'name default pattern types')
Number = collections.namedtuple('Number', 'name default enum')
Object = collections.namedtuple(
    'Object', 'name required additional pattern properties defs')
Reference = collections.namedtuple('Reference', 'name to')
String = collections.namedtuple('String', 'name default enum pattern')


def parse_node(node, name=None):
  logging.debug(f'parse {name} type {node.get("type")}')
  name = name or node.get('title')
  el_type = node.get('type')
  default = node.get('default')
  enum = node.get('enum')
  pattern = node.get('pattern')
  if isinstance(el_type, list):
    return AnyOf(name, default, pattern, el_type)
  match el_type:
    case 'array':
      items = node.get('items')
      items = parse_node(items, 'items') if items else None
      el = Array(name, items, default)
    case 'boolean':
      el = Boolean(name, default)
    case 'object':
      additional = node.get('additionalProperties')
      if isinstance(additional, dict):
        additional = parse_node(additional)
      el = Object(name, node.get('required', []), additional, [], [], [])
      properties = node.get('properties')
      if properties:
        for k in properties:
          el.properties.append(parse_node(properties[k], k))
      pattern = node.get('patternProperties')
      if pattern:
        for k, v in pattern.items():
          el.pattern.append(parse_node(v, k))
      defs = node.get('$defs')
      if defs:
        for k, v in defs.items():
          el.defs.append(parse_node(v, k))
    case 'integer':
      el = Integer(name, default, enum)
    case 'number':
      el = Number(name, default, enum)
    case 'string':
      el = String(name, default, enum, pattern)
    case _:
      ref = node.get('$ref')
      if ref:
        el = Reference(name, ref.split('/')[-1])
      else:
        raise ValueError(f'{name} {el_type}')
  # logging.debug(f'return {el}')
  return el


def render_node(el, level=0, required=False, f_name=lambda f: f'**{f}**'):
  buffer = []
  defs_buffer = []
  indent = ''
  t = el.__class__.__name__.lower()
  r = '⁺' if required else ''
  if level > 0:
    indent = '  ' * (level - 1)
    buffer.append(f'{indent}- {r}{f_name(el.name)}: *{t}*')
  match t:
    case 'object':
      if el.additional == False:
        if level == 0:
          buffer.append(f'*additional properties: false*\n')
        else:
          buffer.append(f'{indent}  <br>*additional properties: false*')
      elif el.additional:
        buffer.append(
            f'{indent}  *additional properties: {el.additional.__class__.__name__}*'
        )
      if el.properties:
        for p in el.properties:
          buffer.append(render_node(p, level + 1, p.name in el.required))
      if el.pattern:
        for p in el.pattern:
          buffer.append(render_node(p, level + 1,
                                    f_name=lambda n: f'**`{n}`**'))
      if level == 0 and el.defs:
        for p in el.defs:
          defs_buffer.append(
              render_node(p, 1,
                          f_name=lambda n: f'**{n}**<a name="refs-{n}"></a>'))
    case 'array':
      if el.items:
        buffer.append(render_node(el.items, level + 1, f_name=str))
    case 'reference':
      buffer[-1] = (
          f'{indent}- {f_name(el.name)}: *reference([{el.to}](#refs-{el.to}))*')
    case 'anyof':
      buffer[-1] = f'{indent}- {r}{f_name(el.name)}: *({"|".join(el.types)})*'
      if el.pattern:
        buffer.append(f'{indent}  <br>*pattern: `{el.pattern}`*')
    case 'integer' | 'number' | 'string':
      details = []
      if el.default:
        details.append(f'*default: {el.default}*')
      if el.enum:
        details.append(f'*enum: {el.enum}*')
      if getattr(el, 'pattern', None):
        details.append(f'*pattern: {el.pattern}*')
      if details:
        buffer.append(f'{indent}  <br>{", ".join(details)}')
  if level == 0:
    return '\n'.join(buffer), '\n'.join(defs_buffer)
  return '\n'.join(buffer)


@click.command()
@click.argument('paths', type=str, nargs=-1)
def main(paths=None):
  paths = paths or ['.']
  for p in paths:
    logging.debug(f'path {p}')
    p = Path(p)
    schemas = [p] if p.is_file() else list(p.glob('**/*.schema.json'))
    for f in schemas:
      logging.info(f'schema {f}')
      try:
        schema = json.load(f.open())
      except json.JSONDecodeError as e:
        raise SystemExit(f'error decoding file {f}: {e.args[0]}')
      tree = parse_node(schema)
      props, defs = render_node(tree)
      doc = DOC.format(title=schema.get('title'), properties=props,
                       definitions=defs or '')
      f_doc = f.with_suffix('.md')
      f_doc.write_text(f'{doc}\n')
      logging.info(f'doc {f}')


if __name__ == '__main__':
  logging.basicConfig(level=logging.DEBUG)
  main()
