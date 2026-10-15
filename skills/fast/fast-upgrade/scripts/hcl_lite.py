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
# dependencies = []
# ///
"""Minimal, dependency-free HCL scanning for the fast-upgrade tools.

This is deliberately not an HCL parser. It masks comments, strings and
heredoc bodies so that braces or keywords inside them cannot confuse brace
matching, then finds top-level blocks (`module`, `variable`, ...) and the
top-level attributes of a block body. That is enough to read module
sources, variable declarations and tfvars keys from Fabric and FAST code,
which is all the upgrade analysis needs. Anything that requires evaluating
expressions belongs to `terraform` itself.

Masking preserves the length and line structure of the text, so offsets
found in the masked text are valid in the original text.
"""

import dataclasses
import json
import re
import urllib.parse

_TOKEN_RE = re.compile(r'#|//|/\*|<<-?|"')
_HEREDOC_RE = re.compile(r'<<(-?)([A-Za-z_][A-Za-z0-9_-]*)[ \t]*\n')
_BRACE_RE = re.compile(r'[{}]')
_BLOCK_RE = re.compile(
    r'^[ \t]*([A-Za-z_][A-Za-z0-9_-]*)'
    r'((?:[ \t]+(?:"[^"\n]*"|[A-Za-z_][A-Za-z0-9_-]*))*)[ \t]*\{', re.MULTILINE)
_LABEL_RE = re.compile(r'"([^"\n]*)"|([A-Za-z_][A-Za-z0-9_-]*)')
_ATTR_RE = re.compile(r'^[ \t]*([A-Za-z_][A-Za-z0-9_-]*)[ \t]*=(?![=>])',
                      re.MULTILINE)
_NON_NEWLINE_RE = re.compile(r'[^\n]')
_WS_RE = re.compile(r'\s+')

# Module block arguments that are Terraform meta-arguments, not variables.
META_ARGUMENTS = frozenset(
    ('source', 'version', 'count', 'for_each', 'providers', 'depends_on'))
_OPENERS = '{[('
_CLOSERS = '}])'


@dataclasses.dataclass
class Block:
  """A top-level HCL block. Offsets index the original text."""
  type: str
  labels: list
  body_start: int
  body_end: int
  line: int


@dataclasses.dataclass
class Attribute:
  """A top-level attribute of a block body."""
  name: str
  value: str
  value_start: int
  value_end: int
  line: int


@dataclasses.dataclass
class ModuleCall:
  """A `module` block with a literal `source`."""
  name: str
  source: str
  line: int
  source_start: int
  source_end: int
  args: frozenset


def _blank(text):
  return _NON_NEWLINE_RE.sub(' ', text)


def _scan_string(text, start):
  """Scans the string literal opening at `start`; returns (end, closed).

  `end` is the offset just past the literal. Template sequences
  (`${ ... }`, `%{ ... }`) may contain nested strings and braces, so they
  are scanned recursively: a `}` or `"` inside them cannot end the outer
  string early. `$${` and `%%{` are literal escapes. An unterminated
  string ends at the end of its line (`closed` is False), so one bad line
  cannot swallow the rest of the file.
  """
  n = len(text)
  j = start + 1
  while j < n:
    ch = text[j]
    if ch == '\\':
      j += 2
    elif ch == '"':
      return j + 1, True
    elif ch == '\n':
      return j, False
    elif text.startswith(('$${', '%%{'), j):
      j += 3
    elif text.startswith(('${', '%{'), j):
      j = _template_end(text, j + 2)
    else:
      j += 1
  return n, False


def _template_end(text, j):
  """Returns the offset just past the `}` closing a template sequence."""
  n = len(text)
  depth = 0
  while j < n:
    ch = text[j]
    if ch == '"':
      j = _scan_string(text, j)[0]
      continue
    if ch == '{':
      depth += 1
    elif ch == '}':
      if depth == 0:
        return j + 1
      depth -= 1
    j += 1
  return n


def mask(text, strings=True):
  """Returns text with comments (and string contents) replaced by spaces.

  Heredoc bodies are always masked. With `strings=False` quoted strings are
  kept verbatim, which is useful to compare type expressions without
  comments. The outer quote characters of a string are always preserved.
  """
  out = []
  i = 0
  n = len(text)
  while i < n:
    m = _TOKEN_RE.search(text, i)
    if not m:
      out.append(text[i:])
      break
    start = m.start()
    out.append(text[i:start])
    tok = m.group()
    if tok in ('#', '//'):
      end = text.find('\n', start)
      end = n if end == -1 else end
      out.append(_blank(text[start:end]))
      i = end
    elif tok == '/*':
      end = text.find('*/', start + 2)
      end = n if end == -1 else end + 2
      out.append(_blank(text[start:end]))
      i = end
    elif tok.startswith('<<'):
      hm = _HEREDOC_RE.match(text, start)
      if not hm:
        out.append(tok)
        i = start + len(tok)
        continue
      body_start = hm.end()
      close_re = re.compile(r'^[ \t]*' + re.escape(hm.group(2)) + r'[ \t]*$',
                            re.MULTILINE)
      cm = close_re.search(text, body_start)
      end = n if not cm else cm.end()
      out.append(text[start:body_start])
      out.append(_blank(text[body_start:end]))
      i = end
    else:
      end, closed = _scan_string(text, start)
      end = min(end, n)
      inner = text[start + 1:end - 1 if closed else end]
      out.append('"' + (_blank(inner) if strings else inner) +
                 ('"' if closed else ''))
      i = end
  return ''.join(out)


def match_brace(masked, open_pos):
  """Returns the index of the brace closing the one at `open_pos`, or -1."""
  depth = 0
  for m in _BRACE_RE.finditer(masked, open_pos):
    depth += 1 if m.group() == '{' else -1
    if depth == 0:
      return m.start()
  return -1


def _depth_delta(segment):
  return (sum(segment.count(c) for c in _OPENERS) -
          sum(segment.count(c) for c in _CLOSERS))


def iter_blocks(text, masked=None, types=None):
  """Yields top-level `Block`s, optionally filtered by block type."""
  masked = mask(text) if masked is None else masked
  pos = 0
  depth = 0
  for m in _BLOCK_RE.finditer(masked):
    if m.start() < pos:
      continue
    segment = masked[pos:m.start()]
    depth += segment.count('{') - segment.count('}')
    pos = m.start()
    if depth != 0:
      continue
    open_pos = m.end() - 1
    close = match_brace(masked, open_pos)
    if close < 0:
      return
    labels = [a or b for a, b in _LABEL_RE.findall(text[m.start(2):m.end(2)])]
    if types is None or m.group(1) in types:
      yield Block(m.group(1), labels, open_pos + 1, close,
                  text.count('\n', 0, m.start()) + 1)
    pos = close + 1


def _expression_end(masked, start, end):
  """Returns the end offset of the expression starting at `start`."""
  depth = 0
  i = start
  while i < end:
    ch = masked[i]
    if ch in _OPENERS:
      depth += 1
    elif ch in _CLOSERS:
      depth -= 1
      if depth < 0:
        return i
    elif ch == '\n' and depth == 0:
      return i
    i += 1
  return end


def attributes(text, masked, start, end):
  """Returns {name: Attribute} for attributes at depth 0 of text[start:end]."""
  result = {}
  depth = 0
  pos = start
  for m in _ATTR_RE.finditer(masked, start, end):
    if m.start() < pos:
      continue
    depth += _depth_delta(masked[pos:m.start()])
    pos = m.start()
    if depth != 0:
      continue
    value_end = _expression_end(masked, m.end(), end)
    # Trim with the masked text: a trailing comment is blank there.
    seg = masked[m.end():value_end]
    value_start = m.end() + len(seg) - len(seg.lstrip())
    value_stop = m.end() + len(seg.rstrip())
    value_stop = max(value_stop, value_start)
    result[m.group(1)] = Attribute(m.group(1), text[value_start:value_stop],
                                   value_start, value_stop,
                                   text.count('\n', 0, m.start()) + 1)
    depth += _depth_delta(masked[m.end():value_end])
    pos = value_end
  return result


def normalize_ws(value):
  return _WS_RE.sub(' ', value).strip() if value else value


def unquote(value):
  """Returns the content of a plain string literal, or None."""
  if value and len(value) >= 2 and value[0] == '"' and value[-1] == '"':
    inner = value[1:-1]
    if '"' not in inner and '${' not in inner:
      return inner
  return None


def module_calls(text):
  """Returns `ModuleCall`s for module blocks with a literal source."""
  masked = mask(text)
  calls = []
  for block in iter_blocks(text, masked, types={'module'}):
    attrs = attributes(text, masked, block.body_start, block.body_end)
    source = attrs.get('source')
    value = unquote(source.value) if source else None
    if value is None:
      continue
    calls.append(
        ModuleCall(name=block.labels[0] if block.labels else '', source=value,
                   line=source.line, source_start=source.value_start + 1,
                   source_end=source.value_end - 1,
                   args=frozenset(set(attrs) - META_ARGUMENTS)))
  return calls


def variables(text):
  """Returns {name: {'type', 'has_default', 'line'}} for variable blocks."""
  masked = mask(text)
  comments_only = mask(text, strings=False)
  result = {}
  for block in iter_blocks(text, masked, types={'variable'}):
    if not block.labels:
      continue
    attrs = attributes(text, masked, block.body_start, block.body_end)
    type_attr = attrs.get('type')
    type_text = None
    if type_attr:
      type_text = normalize_ws(
          comments_only[type_attr.value_start:type_attr.value_end])
    result[block.labels[0]] = {
        'type': type_text,
        'has_default': 'default' in attrs,
        'line': block.line,
    }
  return result


def tfvars_keys(text, is_json=False):
  """Returns the top-level keys set in a tfvars (or tfvars.json) file."""
  if is_json:
    try:
      data = json.loads(text)
    except ValueError:
      return []
    return sorted(data) if isinstance(data, dict) else []
  masked = mask(text)
  return sorted(attributes(text, masked, 0, len(text)))


def classify_source(source):
  """Returns 'local', 'git', 'registry' or 'other' for a module source."""
  if source.startswith('./') or source.startswith('../'):
    return 'local'
  if (source.startswith('git::') or source.startswith('git@') or
      source.startswith('github.com/') or source.startswith('bitbucket.org/')):
    return 'git'
  if re.match(r'^[A-Za-z0-9._-]+/[A-Za-z0-9_-]+/[A-Za-z0-9_-]+(//.*)?$',
              source):
    return 'registry'
  if re.match(
      r'^[A-Za-z0-9.-]+\.[A-Za-z]+/[A-Za-z0-9_-]+/[A-Za-z0-9_-]+/'
      r'[A-Za-z0-9_-]+$', source):
    return 'registry'
  return 'other'


def parse_git_source(source):
  """Splits a git module source into (url, subdir, ref)."""
  value = source[5:] if source.startswith('git::') else source
  query = ''
  if '?' in value:
    value, query = value.split('?', 1)
  ref = urllib.parse.parse_qs(query).get('ref', [None])[0]
  m = re.search(r'(?<!:)//', value)
  if m:
    url, subdir = value[:m.start()], value[m.end():]
  else:
    url, subdir = value, ''
  return url, subdir.strip('/'), ref


def replace_spans(text, replacements):
  """Applies [(start, end, new_text)] replacements to text."""
  for start, end, new in sorted(replacements, reverse=True):
    text = text[:start] + new + text[end:]
  return text
