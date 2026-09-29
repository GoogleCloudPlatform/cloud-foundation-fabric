#!/usr/bin/env python3
# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# /// script
# requires-python = ">=3.10"
# dependencies = [
#    "jsonschema",
#    "pyyaml",
# ]
# ///
"""Factory YAML checks for the fast-upgrade tools.

FAST factories read YAML files whose first lines carry a modeline:

    # yaml-language-server: $schema=../../schemas/project.schema.json

Terraform never validates these files, so a key the schema no longer
accepts is silently ignored rather than rejected. This module resolves the
modeline (the same regex as `tools/check_yaml_schema.py`), validates every
document in the file and diffs schema versions. Remote schemas are never
fetched: resolution is local and deterministic.

PyYAML and jsonschema are optional at import time so that the rest of the
upgrade analysis still works without them; `available()` reports whether
data checks can run.
"""

import functools
import hashlib
import json
import os
import re

try:
  import yaml
except ImportError:  # pragma: no cover - exercised only without PyYAML
  yaml = None
try:
  import jsonschema
except ImportError:  # pragma: no cover - exercised only without jsonschema
  jsonschema = None

MODELINE_RE = re.compile(r'^\s*#\s*yaml-language-server:\s*\$schema=(.*)\s*$',
                         re.MULTILINE)
YAML_SUFFIXES = ('.yaml', '.yml')
SCHEMA_SUFFIXES = ('.schema.json', '.schema.yaml', '.schema.yml')
MAX_MESSAGE = 200
_NODE_BUDGET = 20000


def available():
  return yaml is not None and jsonschema is not None


def missing_dependencies():
  return [
      name for name, mod in (('pyyaml', yaml), ('jsonschema', jsonschema))
      if mod is None
  ]


def modeline(text):
  """Returns the schema reference of a YAML modeline, or None."""
  m = MODELINE_RE.search(text)
  return m.group(1).strip() if m else None


def is_schema_file(name):
  return name.endswith(SCHEMA_SUFFIXES)


def _digest(path):
  with open(path, 'rb') as f:
    return hashlib.sha256(f.read()).hexdigest()


class SchemaIndex:
  """Resolves modelines to schema files, with a by-name fallback.

  The fallback matters for forks and for data kept outside the repository
  (for example a `fast-config` folder): a relative modeline often points
  nowhere once files move, but the schema name is still unique.
  """

  def __init__(self, schema_paths=()):
    self.by_name = {}
    for path in schema_paths:
      self.by_name.setdefault(os.path.basename(path), []).append(path)

  def resolve(self, yaml_path, ref):
    """Returns (schema_path or None, how)."""
    if ref.startswith('http://') or ref.startswith('https://'):
      return None, 'remote schema (not fetched)'
    direct = os.path.normpath(os.path.join(os.path.dirname(yaml_path), ref))
    if os.path.isfile(direct):
      return direct, 'modeline'
    candidates = self.by_name.get(os.path.basename(ref), [])
    if len(candidates) == 1:
      return candidates[0], 'by-name'
    if len(candidates) > 1:
      digests = {_digest(c) for c in candidates}
      if len(digests) == 1:
        return sorted(candidates)[0], 'by-name'
      return None, 'ambiguous schema name'
    return None, 'schema not found'


@functools.lru_cache(maxsize=512)
def load_schema(path):
  """Returns (schema, error)."""
  try:
    with open(path, 'r', encoding='utf-8') as f:
      text = f.read()
  except OSError as e:
    return None, f'cannot read schema: {e.strerror}'
  try:
    return json.loads(text), None
  except ValueError:
    pass
  if yaml is not None:
    try:
      data = yaml.safe_load(text)
      if isinstance(data, dict):
        return data, None
    except yaml.YAMLError:
      pass
  return None, 'schema is not valid JSON or YAML'


def _short(message):
  message = ' '.join(str(message).split())
  if len(message) > MAX_MESSAGE:
    return message[:MAX_MESSAGE - 3] + '...'
  return message


def validate_text(text, schema):
  """Returns sorted 'path: message' errors for all documents in text."""
  try:
    docs = list(yaml.safe_load_all(text))
  except yaml.YAMLError as e:
    return [f'<yaml>: invalid YAML: {_short(e)}']
  try:
    validator = jsonschema.validators.validator_for(schema)(schema)
    errors = []
    for index, doc in enumerate(docs):
      if doc is None:
        continue
      prefix = f'doc {index}: ' if len(docs) > 1 else ''
      for error in validator.iter_errors(doc):
        path = '/'.join(str(p) for p in error.absolute_path) or '<root>'
        errors.append(f'{prefix}{path}: {_short(error.message)}')
  except Exception as e:  # jsonschema raises several unrelated types here
    return [f'<schema>: schema error: {_short(e)}']
  return sorted(errors)


def _pointer(root, ref):
  node = root
  for part in ref.lstrip('#').strip('/').split('/'):
    if not part:
      continue
    part = part.replace('~1', '/').replace('~0', '~')
    if not isinstance(node, dict) or part not in node:
      return None
    node = node[part]
  return node


def schema_paths(schema):
  """Flattens a JSON schema into ({path: set(types)}, set(required paths)).

  Map-like levels (patternProperties, additionalProperties) are written as
  `*` and array items as `[]`, so `buckets.*.description` is the
  `description` of any bucket.
  """
  paths = {}
  required = set()
  budget = [_NODE_BUDGET]

  def join(path, key):
    return f'{path}.{key}' if path else key

  def walk(node, path, seen):
    if budget[0] <= 0:
      return
    budget[0] -= 1
    descend = True
    while isinstance(node, dict) and isinstance(node.get('$ref'), str):
      ref = node['$ref']
      if not ref.startswith('#'):
        break
      # A recursive definition is recorded once, then not descended again.
      descend = ref not in seen
      seen = seen | {ref}
      node = _pointer(schema, ref)
      if not descend:
        break
    types = paths.setdefault(path, set()) if path else set()
    if not isinstance(node, dict):
      return
    kind = node.get('type')
    if isinstance(kind, list):
      types.update(kind)
    elif isinstance(kind, str):
      types.add(kind)
    if not descend:
      return
    for key in ('allOf', 'anyOf', 'oneOf'):
      for sub in node.get(key) or []:
        walk(sub, path, seen)
    for name in node.get('required') or []:
      if isinstance(name, str):
        required.add(join(path, name))
    for name, sub in (node.get('properties') or {}).items():
      walk(sub, join(path, name), seen)
    for sub in (node.get('patternProperties') or {}).values():
      walk(sub, join(path, '*'), seen)
    extra = node.get('additionalProperties')
    if isinstance(extra, dict):
      walk(extra, join(path, '*'), seen)
    items = node.get('items')
    if isinstance(items, dict):
      walk(items, join(path, '[]'), seen)

  walk(schema, '', frozenset())
  return paths, required


def _parent(path):
  return path.rpartition('.')[0]


def diff_schemas(before, after):
  """Returns added, removed, newly required and retyped property paths.

  Added and removed paths are reported at the top of each subtree: a new
  optional `notification_config` object is one addition, not one per
  field. A newly required path only counts when its parent already
  existed, because fields required inside a new optional object cannot
  break existing data.
  """
  b_paths, b_required = schema_paths(before)
  a_paths, a_required = schema_paths(after)
  added = set(a_paths) - set(b_paths)
  removed = set(b_paths) - set(a_paths)
  retyped = sorted(p for p in set(b_paths) & set(a_paths)
                   if b_paths[p] and a_paths[p] and b_paths[p] != a_paths[p])
  return {
      'added':
          sorted(p for p in added if not _parent(p) or _parent(p) in b_paths),
      'removed':
          sorted(p for p in removed if not _parent(p) or _parent(p) in a_paths),
      'required_added':
          sorted(p for p in a_required - b_required
                 if not _parent(p) or _parent(p) in b_paths),
      'type_changed':
          retyped,
  }


def find_yaml_files(paths, ignored_dirs=()):
  """Returns sorted YAML files (not schemas) under files or directories."""
  found = set()
  for path in paths:
    if os.path.isfile(path):
      if path.endswith(YAML_SUFFIXES) and not is_schema_file(path):
        found.add(os.path.abspath(path))
      continue
    for dirpath, dirnames, filenames in os.walk(path):
      dirnames[:] = sorted(d for d in dirnames if d not in ignored_dirs)
      for name in filenames:
        if name.endswith(YAML_SUFFIXES) and not is_schema_file(name):
          found.add(os.path.abspath(os.path.join(dirpath, name)))
  return sorted(found)


def find_schema_files(paths, ignored_dirs=()):
  found = set()
  for path in paths:
    if os.path.isfile(path):
      if is_schema_file(path):
        found.add(os.path.abspath(path))
      continue
    for dirpath, dirnames, filenames in os.walk(path):
      dirnames[:] = sorted(d for d in dirnames if d not in ignored_dirs)
      for name in filenames:
        if is_schema_file(name):
          found.add(os.path.abspath(os.path.join(dirpath, name)))
  return sorted(found)


def check_file(path, index):
  """Validates one YAML file. Returns a result dict with a 'status'.

  Status is one of: ok, invalid, unresolved, no-modeline.
  """
  try:
    with open(path, 'r', encoding='utf-8') as f:
      text = f.read()
  except (OSError, UnicodeDecodeError) as e:
    return {'path': path, 'status': 'unresolved', 'reason': str(e)}
  ref = modeline(text)
  if not ref:
    return {'path': path, 'status': 'no-modeline'}
  schema_path, how = index.resolve(path, ref)
  if not schema_path:
    return {'path': path, 'status': 'unresolved', 'schema': ref, 'reason': how}
  schema, error = load_schema(schema_path)
  if error:
    return {
        'path': path,
        'status': 'unresolved',
        'schema': schema_path,
        'reason': error
    }
  errors = validate_text(text, schema)
  return {
      'path': path,
      'status': 'invalid' if errors else 'ok',
      'schema': schema_path,
      'resolved_by': how,
      'errors': errors,
  }
