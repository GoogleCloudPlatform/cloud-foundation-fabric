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

Array = collections.namedtuple('Array', 'name items default', defaults=(None,))
Boolean = collections.namedtuple('Boolean', 'name default')
Number = collections.namedtuple('Number', 'name default')
Object = collections.namedtuple(
    'Object', 'name required additional pattern children defs',
    defaults=([], [], []))
Ref = collections.namedtuple('Ref', 'name to')
String = collections.namedtuple('String', 'name default')


def parse_node(node, name=None):
  logging.info(f'parse {name} {node}')
  name = name or node.get('title')
  el_type = node.get('type')
  match el_type:
    case 'array':
      items = node.get('items')
      items = parse_node(items) if items else None
      el = Array(name, items, node.get('default'))
    case 'boolean':
      el = Boolean(name, node.get('default'))
    case 'object':
      additional = node.get('additionalProperties')
      additional = parse_node(additional) if additional else None
      el = Object(name, node.get('required'), additional)
      logging.info(f'object keys {list(node.keys())}')
      pattern = node.get('patternProperties')
      if pattern:
        for k, v in pattern.items():
          el.pattern.append(parse_node(v, k))
      properties = node.get('properties')
      if properties:
        for k, v in properties.items():
          el.children.append(parse_node(v, k))
      defs = node.get('$defs')
      if defs:
        for k, v in defs.items():
          el.defs.append(parse_node(v, k))
    case 'number':
      el = Number(name, node.get('default'))
    case 'string':
      el = String(name, node.get('default'))
    case _:
      ref = node.get('$ref')
      if ref:
        el = Ref(name, ref)
      else:
        raise ValueError(f'{name} {el_type}')
  # logging.info(f'return {el}')
  return el


@click.command()
@click.argument('dirs', type=str, nargs=-1)
def main(dirs=None):
  dirs = dirs or ['.']
  for dir in dirs:
    logging.info(f'dir {dir}')
    for f in Path(dir).glob('**/*.schema.json'):
      logging.info(f'file {f}')
      try:
        schema = json.load(f.open())
      except json.JSONDecodeError as e:
        raise SystemExit(f'error decoding file {f}: {e.args[0]}')
      tree = parse_node(schema)
      from pprint import pprint
      pprint(tree)
      break


if __name__ == '__main__':
  logging.basicConfig(level=logging.INFO)
  main()
