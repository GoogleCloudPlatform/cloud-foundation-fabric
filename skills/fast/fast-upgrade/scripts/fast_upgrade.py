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
"""FROZEN SCRIPT — plans and applies FAST upgrades with a three-way comparison.

  C  the customer repository: any layout, possibly edited or reorganized
  B  the upstream release C was built from (base)
  T  the upstream release to upgrade to (target)

Folders in C are mapped to upstream stages and modules by name, then by
content, so renamed or moved folders still line up. Every mapped file is
then classified by comparing C, B and T: changed upstream only (safe to
take), changed by the customer only (kept), changed on both sides
(3-way merge), and so on. Module sources in upstream code are rewritten to
the customer's layout before comparing, so a reorganized repository does
not turn every file into a conflict.

Subcommands:
  releases    list upstream release tags (git ls-remote)
  fetch       materialize an upstream release into a local cache
  detect      describe a FAST repository: stages, modules, sources, version
  changelog   breaking changes, FAST changes and upgrade notes in (B, T]
  analyze     the upgrade report (alias `plan`): file actions, conflicts,
              breaking changes, variables, module interfaces, schema and
              factory data impact
  migrate     update repository files on a clean git tree (alias `apply`):
              take upstream-only changes, 3-way merge conflicts; deletions,
              ref bumps and moved-block copies only when asked
  check-data  validate factory YAML files against their modeline schemas

Nothing here runs terraform, commits, or pushes.

Exit codes: 0 = success; 1 = error, or refused by a safety check (for
example a dirty working tree); 2 = attention needed (`migrate`/`apply`:
conflict markers or manual items remain; `check-data`: invalid files found).
"""

import argparse
import collections
import dataclasses
import difflib
import hashlib
import io
import itertools
import json
import os
import posixpath
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile

import factory_data
import hcl_lite
import provenance
import release_notes
import report

UPSTREAM_URL = 'https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git'
DEFAULT_FABRIC_SOURCE = 'cloud-foundation-fabric'
UPSTREAM_STAGE_PARENTS = ('fast/stages', 'fast/addons', 'fast/extras')
IGNORED_DIRS = frozenset(
    ('.git', '.terraform', '.fast-upgrade', 'node_modules', '.venv', 'venv',
     '__pycache__', '.pytest_cache', '.idea', '.vscode'))
IGNORED_FILE_RE = re.compile(
    r'(\.tfstate|\.tfstate\.backup|\.tfplan|\.terraform\.lock\.hcl|'
    r'\.DS_Store|\.pyc|~)$')
STAGE_NAME_RE = re.compile(r'^\d+-[a-z0-9][a-z0-9-]*$')
FAST_MARKER_RE = re.compile(r'#\s*FAST release:\s*(v\d+\.\d+\.\d+)')
FABRIC_MARKER_RE = re.compile(r'#\s*Fabric release:\s*(v\d+\.\d+\.\d+)')
MODULE_META_RE = re.compile(
    r'cloud-foundation-fabric/[^":\s]*:(v\d+\.\d+\.\d+)')
ANY_VERSION_RE = re.compile(r'\bv\d+\.\d+\.\d+\b')
SAFE_REF_RE = re.compile(r'^[A-Za-z0-9][A-Za-z0-9._/-]*$')
# Tar extraction filters (PEP 706): Python 3.12+, and security releases of
# 3.8 to 3.11. Without them, _extract checks archive members itself.
TAR_FILTERS = hasattr(tarfile, 'data_filter')
GENERIC_TF = frozenset(('main.tf', 'variables.tf', 'outputs.tf', 'versions.tf',
                        'providers.tf', 'backend.tf', 'locals.tf', 'data.tf'))
STAGE_MATCH_THRESHOLD = 0.5
PREFIX_MATCH_THRESHOLD = 0.3
# A stage-like folder below STAGE_MATCH_THRESHOLD but at least this similar
# to an upstream stage is a candidate: the user is asked which stage it is.
CANDIDATE_MIN_SCORE = 0.2
CANDIDATE_GUESSES = 3
# Variables of FAST's stage interface (variables-fast.tf): a folder that
# declares several of them is built like a stage.
FAST_INTERFACE_VARS = frozenset(
    ('automation', 'billing_account', 'custom_roles', 'folder_ids',
     'iam_principals', 'kms_keys', 'organization', 'perimeters', 'prefix',
     'project_ids', 'service_accounts', 'storage_buckets', 'tag_values',
     'universe'))
FAST_INTERFACE_MIN = 3
MODULE_MATCH_THRESHOLD = 0.6
RENAME_SIMILARITY = 0.75
FULL_VENDOR_RATIO = 0.9
DEFAULT_LIMIT = 25

CATEGORY_HELP = collections.OrderedDict((
    ('conflict', 'changed on both sides: apply runs a 3-way merge'),
    ('conflict-added', 'added on both sides with different content: manual'),
    ('conflict-deleted', 'removed upstream but changed by you: manual'),
    ('conflict-customer-deleted', 'removed by you but changed upstream: '
     'manual'),
    ('upstream-changed', 'changed upstream only: apply takes the target'),
    ('upstream-added', 'new upstream: apply adds it'),
    ('upstream-deleted', 'removed upstream: apply deletes only with '
     '--include-deletes'),
    ('customer-changed', 'changed by you only: kept'),
    ('customer-added', 'yours only: kept'),
    ('customer-deleted', 'removed by you, unchanged upstream: stays removed'),
    ('already-updated', 'already matches the target'),
    ('unchanged', 'identical in all three'),
))
MANUAL_CATEGORIES = ('conflict-added', 'conflict-deleted',
                     'conflict-customer-deleted')
UPSTREAM_CONTENT = ('upstream-changed', 'upstream-added', 'upstream-deleted',
                    'unchanged', 'already-updated')
# Categories whose content the customer owns after apply.
CUSTOMER_OWNED = ('customer-added', 'customer-changed', 'conflict',
                  'conflict-added')
DATA_ORDER = ('breaks', 'schema-removed', 'still-invalid', 'validator-error',
              'unresolved', 'fixed')
# Files written by fast/stages/fast-links.sh or the CI/CD setup: generated
# per environment, so committing them (or symlinks to them) is a smell.
GENERATED_RE = re.compile(r'(^|/)(\d+-[a-z0-9-]+-providers(-ro)?\.tf|'
                          r'\d+-[a-z0-9-]+\.auto\.tfvars\.json|'
                          r'([a-z0-9]+[-_])*wif([-_][a-z0-9]+)*\.json)$')
# Files at the top of an upstream release, next to fast/ and modules/.
RELEASE_ROOT_FILES = ('CHANGELOG.md', 'default-versions.tf')
# Top-level blocks that make a folder a Terraform configuration, as opposed
# to a file holding only a `terraform {}` block.
CONFIG_BLOCK_RE = re.compile(
    r'^[ \t]*(resource|data|module|variable|output|locals|provider|moved|'
    r'import|check|removed)\b', re.M)
PIN_RE = re.compile(r'^\s*(>=|<=|!=|~>|>|<|=)?\s*v?(\d+(?:\.\d+){0,2})\s*$')
ADDON_MATCH = 0.8
SEVERITIES = ('blocker', 'high', 'medium', 'low', 'info')


class UpgradeError(Exception):
  """Invalid input or environment; reported with exit code 1."""


class Refused(UpgradeError):
  """A safety check refused to modify the repository."""


# --------------------------------------------------------------------------
# Small helpers
# --------------------------------------------------------------------------


def _join(root, rel_path):
  return os.path.join(root, *rel_path.split('/')) if rel_path else root


def _rel(path, root):
  return os.path.relpath(path, root).replace(os.sep, '/')


def _inside(rel_path, parent):
  return parent == '' or rel_path == parent or rel_path.startswith(parent + '/')


def _read_bytes(path):
  with open(path, 'rb') as f:
    return f.read()


def _read_text(path):
  return _read_bytes(path).replace(b'\r\n',
                                   b'\n').decode('utf-8', errors='replace')


def _sha(data):
  return hashlib.sha256(data).hexdigest()


def _has_tf(path):
  try:
    return any(
        n.endswith('.tf') and os.path.isfile(os.path.join(path, n))
        for n in os.listdir(path))
  except OSError:
    return False


def _version(value):
  return release_notes.parse_version(value) if value else None


def _is_terraform(path):
  return path.endswith(('.tf', '.tofu'))


def _normalize_versions(text):
  return ANY_VERSION_RE.sub('vX', text)


def file_kind(path):
  name = posixpath.basename(path)
  if name == 'fast_version.txt':
    return 'marker'
  if _is_terraform(name):
    return 'terraform'
  if name.endswith(('.tfvars', '.tfvars.json')):
    return 'tfvars'
  if factory_data.is_schema_file(name):
    return 'schema'
  if name.endswith(factory_data.YAML_SUFFIXES):
    return 'data'
  if name.endswith(('.md', '.png', '.svg', '.gz', '.excalidraw', '.jpg')):
    return 'docs'
  if name.endswith(('.sh', '.py')):
    return 'script'
  return 'other'


def walk_tree(base, exclude=(), top_level_only=False):
  """Returns {posix rel path: abs path} for files under base.

  Symlinks (to files or directories) are returned as entries and never
  followed, so directory aliases cannot loop or escape the tree.
  """
  result = {}
  if not base or not os.path.isdir(base):
    return result
  for dirpath, dirnames, filenames in os.walk(base):
    reldir = '' if dirpath == base else _rel(dirpath, base)
    keep = []
    for name in sorted(dirnames):
      full = os.path.join(dirpath, name)
      rel_path = f'{reldir}/{name}' if reldir else name
      if name in IGNORED_DIRS or rel_path in exclude:
        continue
      if os.path.islink(full):
        result[rel_path] = full
        continue
      keep.append(name)
    dirnames[:] = [] if top_level_only else keep
    for name in sorted(filenames):
      if IGNORED_FILE_RE.search(name):
        continue
      rel_path = f'{reldir}/{name}' if reldir else name
      result[rel_path] = os.path.join(dirpath, name)
  return result


@dataclasses.dataclass
class Entry:
  kind: str
  digest: str
  binary: bool = False
  executable: bool = False
  link: str = None
  adjusted: bool = False


def read_entry(path, rewrite=None):
  """Reads one file for comparison. CRLF is normalized; links not followed.

  `rewrite(text) -> text` adjusts upstream Terraform before hashing.
  """
  if not path or not os.path.lexists(path):
    return None
  if os.path.islink(path):
    target = os.readlink(path)
    return Entry('link', 'link:' + provenance.link_target(path), link=target)
  if not os.path.isfile(path):
    return None
  data = _read_bytes(path)
  binary = b'\0' in data[:8192]
  adjusted = False
  if not binary:
    data = data.replace(b'\r\n', b'\n')
    if rewrite:
      text = data.decode('utf-8', errors='replace')
      new = rewrite(text)
      if new != text:
        data = new.encode('utf-8')
        adjusted = True
  return Entry('file', _sha(data), binary, os.access(path, os.X_OK),
               adjusted=adjusted)


def classify(c, b, t):
  """Returns the three-way category for digests (None = absent)."""
  if c == t:
    return 'unchanged' if b == c else 'already-updated'
  if b == t:
    if b is None:
      return 'customer-added'
    return 'customer-deleted' if c is None else 'customer-changed'
  if c == b:
    if b is None:
      return 'upstream-added'
    return 'upstream-deleted' if t is None else 'upstream-changed'
  if c is None:
    return 'conflict-customer-deleted'
  if t is None:
    return 'conflict-deleted'
  if b is None:
    return 'conflict-added'
  return 'conflict'


# --------------------------------------------------------------------------
# Git
# --------------------------------------------------------------------------


def _git_bin():
  path = shutil.which('git')
  if not path:
    raise UpgradeError('git is not installed or not on PATH')
  return path


def git(args, check=True, input_bytes=None):
  proc = subprocess.run([_git_bin()] + list(args), capture_output=True,
                        input=input_bytes)
  if check and proc.returncode != 0:
    detail = proc.stderr.decode('utf-8', errors='replace').strip()
    raise UpgradeError(f'git {" ".join(args)} failed: {detail}')
  return proc


def git_state(path):
  """Returns a summary of the git working tree containing path."""
  if not shutil.which('git'):
    return {'git': False, 'reason': 'git not installed'}
  top = git(['-C', path, 'rev-parse', '--show-toplevel'], check=False)
  if top.returncode != 0:
    return {'git': False, 'reason': 'not a git repository'}
  branch = git(['-C', path, 'rev-parse', '--abbrev-ref', 'HEAD'], check=False)
  head = git(['-C', path, 'rev-parse', '--short', 'HEAD'], check=False)
  status = git(['-C', path, 'status', '--porcelain', '--untracked-files=no'],
               check=False)
  dirty = [
      line[3:]
      for line in status.stdout.decode('utf-8', errors='replace').splitlines()
      if line.strip()
  ]
  return {
      'git': True,
      'toplevel': top.stdout.decode().strip(),
      'branch': branch.stdout.decode().strip() or None,
      'head': head.stdout.decode().strip() if head.returncode == 0 else None,
      'dirty': len(dirty),
      'dirty_files': dirty[:20],
  }


def upstream_history(path, version):
  """True if path is a git fork containing the upstream release tag."""
  if not version or not shutil.which('git'):
    return False
  tag = git(['-C', path, 'rev-parse', '-q', '--verify', f'refs/tags/{version}'],
            check=False)
  if tag.returncode != 0:
    return False
  ancestor = git([
      '-C', path, 'merge-base', '--is-ancestor', f'refs/tags/{version}', 'HEAD'
  ], check=False)
  return ancestor.returncode == 0


def _git_summary(state):
  if not state.get('git'):
    return state.get('reason', 'no git')
  dirty = f'{state["dirty"]} dirty' if state['dirty'] else 'clean'
  return f'git {state["branch"]} @ {state["head"]}, {dirty}'


# --------------------------------------------------------------------------
# Scanning a repository
# --------------------------------------------------------------------------


@dataclasses.dataclass
class Scan:
  root: str
  tf_dirs: set
  stage_dirs: dict
  calls: list
  markers: list
  schema_files: list
  yaml_files: list
  tfvars_files: list
  lock_files: list
  module_dirs: set
  links: list = dataclasses.field(default_factory=list)
  version_files: list = dataclasses.field(default_factory=list)
  # Folders below the root that are git repositories of their own.
  nested_repos: list = dataclasses.field(default_factory=list)


def _call_info(file_rel, call, root, fabric_re):
  kind = hcl_lite.classify_source(call.source)
  info = {
      'file': file_rel,
      'line': call.line,
      'name': call.name,
      'source': call.source,
      'kind': kind,
      'args': sorted(call.args),
  }
  if kind == 'local':
    target = posixpath.normpath(
        posixpath.join(posixpath.dirname(file_rel), call.source))
    if target == '..' or target.startswith('../'):
      info['resolved'] = None
      info['problem'] = 'outside repository'
    elif os.path.isdir(_join(root, target)):
      info['resolved'] = target
    else:
      info['resolved'] = None
      info['problem'] = 'missing'
  elif kind == 'git':
    url, subdir, ref = hcl_lite.parse_git_source(call.source)
    info.update(url=url, subdir=subdir, ref=ref,
                fabric=bool(fabric_re.search(url)))
  return info


def _link_info(full, rel_path, root):
  """Describes a symlink: where it points and whether that is a problem."""
  target = os.readlink(full)
  resolved = os.path.realpath(full)
  real_root = os.path.realpath(root)
  return {
      'path':
          rel_path,
      'target':
          target,
      'dir':
          os.path.isdir(full),
      'broken':
          not os.path.exists(full),
      'absolute':
          os.path.isabs(target),
      'outside':
          not (resolved == real_root or
               resolved.startswith(real_root + os.sep)),
      'generated':
          bool(GENERATED_RE.search(rel_path)),
  }


def version_pins(text):
  """Returns the Terraform and provider version constraints in text."""
  pins = {}
  masked = hcl_lite.mask(text)
  for key, pattern in (
      ('terraform', r'required_version\s*=\s*"([^"]+)"'),
      ('google', r'(?<![\w-])google\s*=\s*\{[^}]*?version\s*=\s*"([^"]+)"'),
      ('google-beta', r'google-beta\s*=\s*\{[^}]*?version\s*=\s*"([^"]+)"'),
  ):
    for m in re.finditer(pattern, text, re.S):
      # Skip matches inside comments: masking keeps offsets, so a match
      # whose first character is blanked out was commented.
      if masked[m.start()].isspace() and not text[m.start()].isspace():
        continue
      pins[key] = m.group(1)
      break
  return pins


def scan_repo(root, fabric_re):
  root = os.path.abspath(root)
  if not os.path.isdir(root):
    raise UpgradeError(f'not a directory: {root}')
  tf_dirs = set()
  stage_dirs = {}
  calls = []
  markers = []
  schemas = []
  yamls = []
  tfvars = []
  locks = []
  links = []
  version_files = []
  nested_repos = []
  for dirpath, dirnames, filenames in os.walk(root):
    if dirpath != root and ('.git' in dirnames or '.git' in filenames):
      nested_repos.append(_rel(dirpath, root))
    dirnames[:] = sorted(d for d in dirnames if d not in IGNORED_DIRS)
    reldir = '' if dirpath == root else _rel(dirpath, root)
    for name in dirnames:
      full = os.path.join(dirpath, name)
      if os.path.islink(full):
        links.append(
            _link_info(full, f'{reldir}/{name}' if reldir else name, root))
    for name in sorted(filenames):
      full = os.path.join(dirpath, name)
      rel_path = f'{reldir}/{name}' if reldir else name
      if os.path.islink(full):
        links.append(_link_info(full, rel_path, root))
      if name == '.terraform.lock.hcl':
        locks.append(rel_path)
        continue
      if name.endswith(('.tfvars', '.tfvars.json')):
        tfvars.append(rel_path)
        continue
      if IGNORED_FILE_RE.search(name) or os.path.islink(full):
        continue
      if _is_terraform(name):
        text = _read_text(full)
        pins = version_pins(text)
        m = FABRIC_MARKER_RE.search(text) or MODULE_META_RE.search(text)
        if pins:
          version_files.append({
              'path': rel_path,
              'pins': pins,
              'marker': m.group(1) if m else None,
          })
        if not name.endswith('.tf'):
          continue
        tf_dirs.add(reldir)
        for call in hcl_lite.module_calls(text):
          calls.append(_call_info(rel_path, call, root, fabric_re))
        if m and name in ('versions.tf', 'default-versions.tf'):
          markers.append((rel_path, 'module', m.group(1)))
        elif m and pins:
          # A copy of default-versions.tf under another name (for example
          # terraform.tf in each stage) still records the release it came
          # from, and pins providers to it.
          markers.append((rel_path, 'pin', m.group(1)))
      elif name == 'fast_version.txt':
        m = FAST_MARKER_RE.search(_read_text(full))
        markers.append((rel_path, 'stage', m.group(1) if m else None))
        stage_dirs[reldir] = {
            'marker': m.group(1) if m else None,
            'reason': 'marker'
        }
      elif factory_data.is_schema_file(name):
        schemas.append(rel_path)
      elif name.endswith(factory_data.YAML_SUFFIXES):
        yamls.append(rel_path)
  for d in tf_dirs:
    if d not in stage_dirs and STAGE_NAME_RE.match(posixpath.basename(d)):
      stage_dirs[d] = {'marker': None, 'reason': 'name'}
  # One stage per repository: the repository folder carries the stage name.
  if ('' in tf_dirs and not stage_dirs and
      STAGE_NAME_RE.match(os.path.basename(root))):
    stage_dirs[''] = {'marker': None, 'reason': 'repository name'}
  module_dirs = {c['resolved'] for c in calls if c.get('resolved')}
  for d in list(stage_dirs):
    nested = any(o != d and _inside(d, o) for o in stage_dirs)
    if d in module_dirs or nested:
      del stage_dirs[d]
  for call in calls:
    if call['kind'] == 'git' and call.get('fabric') and _version(call['ref']):
      markers.append((call['file'], 'git-ref', call['ref']))
  return Scan(root, tf_dirs, stage_dirs, calls, [m for m in markers if m[2]],
              schemas, yamls, tfvars, locks, module_dirs - set(stage_dirs),
              links, version_files, nested_repos)


def version_consensus(markers):
  """Returns (version, confidence, {kind: {version: count}})."""
  by_kind = collections.OrderedDict(
      (k, collections.Counter()) for k in ('stage', 'module', 'git-ref', 'pin'))
  for _, kind, version in markers:
    by_kind[kind][version] += 1
  breakdown = {k: dict(v) for k, v in by_kind.items() if v}
  for kind, counter in by_kind.items():
    if not counter:
      continue
    top = max(counter.values())
    # Ties resolve to the oldest release: a half-upgraded repository then
    # shows the other half as changes instead of silently hiding them.
    best = min(_version(v) for v, n in counter.items() if n == top)
    version = release_notes.format_version(best)
    all_versions = {v for c in by_kind.values() for v in c}
    confidence = 'high' if len(all_versions) == 1 else 'mixed'
    return version, confidence, breakdown
  return None, 'none', breakdown


# --------------------------------------------------------------------------
# Upstream catalogs and folder mapping
# --------------------------------------------------------------------------


def _is_fabric_tree(root):
  return (os.path.isdir(_join(root, 'modules')) and
          os.path.isdir(_join(root, 'fast/stages')))


def release_version(root):
  """Returns the release recorded in an upstream tree, or None."""
  path = _join(root, 'default-versions.tf')
  if os.path.isfile(path):
    m = FABRIC_MARKER_RE.search(_read_text(path))
    if m:
      return m.group(1)
  stages = _join(root, 'fast/stages')
  for name in sorted(os.listdir(stages)) if os.path.isdir(stages) else []:
    path = os.path.join(stages, name, 'fast_version.txt')
    if os.path.isfile(path):
      m = FAST_MARKER_RE.search(_read_text(path))
      if m:
        return m.group(1)
  return None


def _subdirs(path):
  """Returns sorted names of real (non-link, non-ignored) subfolders."""
  try:
    names = sorted(os.listdir(path))
  except OSError:
    return []
  return [
      n for n in names
      if n not in IGNORED_DIRS and os.path.isdir(os.path.join(path, n)) and
      not os.path.islink(os.path.join(path, n))
  ]


def _tf_subdirs(path):
  """Returns sorted names of real subfolders holding .tf files."""
  return [n for n in _subdirs(path) if _has_tf(os.path.join(path, n))]


def _module_leaves(path, depth=2):
  """Returns folders holding .tf files below a module group folder.

  Groups can nest: `modules/cloud-config-container/__need_fixing/onprem`
  is a module two levels below its group. The first folder with .tf files
  on each branch is the module; its own subfolders (recipes, examples)
  belong to it.
  """
  found = []
  for name in _subdirs(path):
    full = os.path.join(path, name)
    if _has_tf(full):
      found.append(name)
    elif depth > 1:
      found += [f'{name}/{sub}' for sub in _module_leaves(full, depth - 1)]
  return found


def catalog(root):
  root = os.path.abspath(root)
  if not _is_fabric_tree(root):
    raise UpgradeError(f'{root} is not a Cloud Foundation Fabric tree '
                       '(expected fast/stages and modules)')
  stages = {}
  for parent in UPSTREAM_STAGE_PARENTS:
    for name in _tf_subdirs(_join(root, parent)):
      stages.setdefault(name, f'{parent}/{name}')
  modules = {}
  modules_root = _join(root, 'modules')
  for name in sorted(os.listdir(modules_root)):
    full = os.path.join(modules_root, name)
    if not os.path.isdir(full) or os.path.islink(full):
      continue
    if _has_tf(full):
      modules[name] = f'modules/{name}'
      continue
    # A group of modules, e.g. modules/cloud-config-container/<name>, or
    # modules/cloud-config-container/__need_fixing/<name>.
    for sub in _module_leaves(full):
      modules[f'{name}/{sub}'] = f'modules/{name}/{sub}'
  return {
      'root': root,
      'stages': stages,
      'modules': modules,
      'version': release_version(root)
  }


def _tree_info(cat):
  """Path, release and content digest of an upstream tree, for reports."""
  return {
      'path':
          cat['root'],
      'version':
          cat['version'],
      'digest':
          provenance.tree_digest(cat['root'], ignored_dirs=IGNORED_DIRS,
                                 ignored_file_re=IGNORED_FILE_RE),
  }


def module_key(rel_dir, module_names):
  """Returns (upstream module name or None, module root) for a folder.

  `tf-modules/project` is `project` under root `tf-modules`, and
  `modules/cloud-config-container/coredns` is the grouped module
  `cloud-config-container/coredns` under root `modules`.
  """
  parts = rel_dir.split('/')
  for size in (3, 2):
    if len(parts) >= size and '/'.join(parts[-size:]) in module_names:
      return '/'.join(parts[-size:]), '/'.join(parts[:-size])
  name = parts[-1] if parts[-1] in module_names else None
  return name, '/'.join(parts[:-1])


def git_module_name(call):
  """Returns the Fabric module a git source points to, or None."""
  if call['kind'] != 'git' or not call.get('fabric'):
    return None
  parts = (call.get('subdir') or '').split('/')
  if len(parts) in (2, 3, 4) and parts[0] == 'modules' and all(parts):
    return '/'.join(parts[1:])
  return None


def dir_signature(path):
  """Returns {name: digest} for the top-level .tf files of a folder."""
  sig = {}
  try:
    names = sorted(os.listdir(path))
  except OSError:
    return sig
  for name in names:
    full = os.path.join(path, name)
    if name.endswith('.tf') and os.path.isfile(
        full) and not os.path.islink(full):
      sig[name] = _sha(_read_bytes(full).replace(b'\r\n', b'\n'))
  return sig


def match_score(candidate, upstream):
  """Scores how likely a folder is a copy of an upstream folder (0..1)."""
  if not upstream or len(candidate) < 2:
    return 0.0
  up_hashes = set(upstream.values())
  hash_overlap = len(up_hashes & set(candidate.values())) / len(up_hashes)
  distinctive = [n for n in upstream if n not in GENERIC_TF]
  name_overlap = 0.0
  if len(distinctive) >= 2:
    name_overlap = sum(
        1 for n in distinctive if n in candidate) / len(distinctive)
  return max(hash_overlap, 0.8 * name_overlap)


def _best_match(sig, signatures):
  best = (0.0, None)
  for name, upstream in sorted(signatures.items()):
    score = match_score(sig, upstream)
    if score > best[0]:
      best = (score, name)
  return best


@dataclasses.dataclass
class Mapping:
  kind: str
  name: str
  customer: str
  base: str
  target: str
  match: str
  recursive: bool = True
  # For non-recursive mappings: the only top-level file names compared
  # (None compares every top-level file upstream has).
  only: tuple = None


def _under(prefix, rel_path):
  """rel_path below prefix, where '' is the root of the tree."""
  return f'{prefix}/{rel_path}' if prefix else rel_path


def module_closure(root, start_dirs, modules):
  """Returns module names reachable from start_dirs via local sources."""
  by_path = {v: k for k, v in modules.items()}
  needed = set()
  queue = list(start_dirs)
  seen = set()
  while queue:
    d = queue.pop()
    if d in seen:
      continue
    seen.add(d)
    full = _join(root, d)
    for name in sorted(os.listdir(full)) if os.path.isdir(full) else []:
      if not name.endswith('.tf'):
        continue
      for call in hcl_lite.module_calls(_read_text(os.path.join(full, name))):
        if hcl_lite.classify_source(call.source) != 'local':
          continue
        target = posixpath.normpath(posixpath.join(d, call.source))
        if target in by_path and by_path[target] not in needed:
          needed.add(by_path[target])
          queue.append(target)
  return needed


def module_renames(base_cat, target_cat, declared):
  """Returns {old: new} for modules renamed between base and target."""
  base_mods, target_mods = base_cat['modules'], target_cat['modules']
  renames = {
      old: new
      for old, new in declared.items()
      if old in base_mods and old not in target_mods and new in target_mods
  }
  base_only = [
      n for n in base_mods if n not in target_mods and n not in renames
  ]
  target_only = {
      n: dir_signature(_join(target_cat['root'], target_mods[n]))
      for n in target_mods
      if n not in base_mods and n not in renames.values()
  }
  for old in base_only:
    sig = dir_signature(_join(base_cat['root'], base_mods[old]))
    score, new = _best_match(sig, target_only)
    if new and score >= MODULE_MATCH_THRESHOLD:
      renames[old] = new
  return renames


def _fast_folder_mappings(repo, mappings, base_cat, target_cat):
  """Maps upstream files that live around the stages, by path.

  Only when at least two stages sit, under their upstream names, in one
  customer folder: its top-level files are mapped to `fast/stages`, and
  when that folder is called `stages` its parent is the customer's copy of
  `fast/`, whose other upstream folders (project templates, ...) and
  top-level files are mapped too.
  """
  parents = collections.Counter(
      posixpath.dirname(m.customer) for m in mappings if m.kind == 'stage' and
      m.match == 'name' and m.base and m.base.startswith('fast/stages/'))
  claimed = {m.customer for m in mappings}
  stage_parents = {posixpath.basename(p) for p in UPSTREAM_STAGE_PARENTS}
  result = []

  def top_level_overlap(upstream_rel, customer_rel):
    upstream_files = set(
        walk_tree(_join(base_cat['root'], upstream_rel), top_level_only=True))
    return upstream_files & set(
        walk_tree(_join(repo, customer_rel), top_level_only=True))

  for parent, count in sorted(parents.items()):
    if count < 2:
      continue
    if top_level_overlap('fast/stages', parent):
      result.append(
          Mapping('files', 'fast/stages', parent, 'fast/stages', 'fast/stages',
                  'parent of mapped stages', recursive=False))
    if posixpath.basename(parent) != 'stages':
      continue
    fast_root = posixpath.dirname(parent)
    names = set(_subdirs(_join(base_cat['root'], 'fast'))) | set(
        _subdirs(_join(target_cat['root'], 'fast')))
    for name in sorted(names - stage_parents):
      d = f'{fast_root}/{name}' if fast_root else name
      full = _join(repo, d)
      if d in claimed or not os.path.isdir(full) or os.path.islink(full):
        continue
      upstream = f'fast/{name}'
      result.append(
          Mapping(
              'files', upstream, d, upstream if os.path.isdir(
                  _join(base_cat['root'], upstream)) else None, upstream
              if os.path.isdir(_join(target_cat['root'], upstream)) else None,
              'path'))
    # A repository root is never mapped to fast/: its README is the
    # customer's own.
    if fast_root and top_level_overlap('fast', fast_root):
      result.append(
          Mapping('files', 'fast', fast_root, 'fast', 'fast',
                  'parent of the stages folder', recursive=False))
  return result


def _same_content(path_a, path_b):
  try:
    return (_read_bytes(path_a).replace(b'\r\n',
                                        b'\n') == _read_bytes(path_b).replace(
                                            b'\r\n', b'\n'))
  except OSError:
    return False


def _release_root_mappings(repo, mappings, base_cat, target_cat, primary_root,
                           full_vendor):
  """Maps upstream files that belong to no stage or module, by path.

  A fork keeps upstream's top-level module files (modules/README.md) and,
  next to its copy of fast/, upstream's CHANGELOG.md and
  default-versions.tf, whose release stamp `detect` reads. Without a
  mapping apply leaves them at the base release. They are mapped only
  where the layout shows they are upstream's copies:

  - the module root, when it vendors (nearly) every upstream module: the
    top-level files upstream also has there;
  - the folder that holds the customer's copy of fast/ (the parent of a
    `stages` folder with two or more upstream stages): each release file
    it has that is still upstream's, identical to the base or the target,
    or a default-versions.tf with a Fabric release stamp. A CHANGELOG the
    customer rewrote is theirs and is left alone.
  """
  claimed = {m.customer for m in mappings}
  result = []
  if primary_root and full_vendor and primary_root not in claimed:
    upstream_files = set(
        walk_tree(_join(base_cat['root'], 'modules'),
                  top_level_only=True)) | set(
                      walk_tree(_join(target_cat['root'], 'modules'),
                                top_level_only=True))
    customer_files = set(
        walk_tree(_join(repo, primary_root), top_level_only=True))
    if upstream_files & customer_files:
      result.append(
          Mapping('files', 'modules', primary_root, 'modules', 'modules',
                  'parent of the vendored modules', recursive=False))
  parents = collections.Counter(
      posixpath.dirname(m.customer)
      for m in mappings
      if m.kind == 'stage' and m.match in (
          'name', 'prefix') and m.base and m.base.startswith('fast/stages/'))
  roots = sorted({
      posixpath.dirname(posixpath.dirname(p))
      for p, n in parents.items()
      if n >= 2 and posixpath.basename(p) == 'stages' and posixpath.dirname(p)
  })
  for root in roots:
    if root in claimed:
      continue
    only = []
    for name in RELEASE_ROOT_FILES:
      customer = _join(repo, _under(root, name))
      if not os.path.isfile(customer) or os.path.islink(customer):
        continue
      upstream = [
          _join(cat['root'], name)
          for cat in (base_cat, target_cat)
          if os.path.isfile(_join(cat['root'], name))
      ]
      stamped = name == 'default-versions.tf' and FABRIC_MARKER_RE.search(
          _read_text(customer))
      if stamped or any(_same_content(customer, u) for u in upstream):
        only.append(name)
    if only:
      result.append(
          Mapping('files', 'release files', root, '', '',
                  'release files next to fast/', recursive=False,
                  only=tuple(only)))
  return result


def _stage_from_name(name, stage_names, words=False):
  """Returns (upstream stage, how) for a folder name, or (None, None).

  `2-networking` matches by name, `2-networking-prod` by prefix. With
  `words`, used for a repository that is one stage, a name without the
  number matches when it contains the stage name as whole words
  (`gcp-networking`, `fast-org-setup-prod`).
  """
  name = name.lower().replace('_', '-')
  if name in stage_names:
    return name, 'name'
  prefixed = [n for n in stage_names if name.startswith(n + '-')]
  if prefixed:
    return max(prefixed, key=len), 'prefix'
  if words:
    padded = f'-{name}-'
    found = [
        n for n in stage_names
        if '-' in n and f'-{n.split("-", 1)[1]}-' in padded
    ]
    if found:
      return max(found, key=len), 'unnumbered name'
  return None, None


def parse_stage_map(values):
  """{folder: stage name, path or None} from `--map FOLDER=STAGE` values.

  FOLDER is relative to the repository ('.' is its root). STAGE is an
  upstream stage name (0-org-setup) or path (fast/stages/0-org-setup), or
  `none` for a folder that is the customer's own.
  """
  result = {}
  for value in values or ():
    folder, sep, stage = value.partition('=')
    folder, stage = folder.strip().replace('\\', '/'), stage.strip()
    if not sep or not folder or not stage:
      raise UpgradeError(f'--map {value!r}: use FOLDER=STAGE or FOLDER=none')
    folder = posixpath.normpath(folder)
    if folder.startswith('/') or folder == '..' or folder.startswith('../'):
      raise UpgradeError(f'--map {value!r}: the folder must be inside the '
                         'repository')
    folder = '' if folder == '.' else folder
    if folder in result:
      raise UpgradeError(f'--map: {folder or "."} is mapped more than once')
    result[folder] = None if stage.lower() == 'none' else stage.strip('/')
  return result


def _stage_like(repo, d, scan):
  """Why a folder looks like a FAST stage, or None."""
  if d in scan.stage_dirs:
    return {
        'marker': 'fast_version.txt',
        'name': 'stage-style name'
    }.get(scan.stage_dirs[d]['reason'], 'stage-style name')
  full = _join(repo, d)
  if os.path.isfile(os.path.join(full, 'variables-fast.tf')):
    return 'variables-fast.tf'
  found = FAST_INTERFACE_VARS & set(_collect_variables(full))
  if len(found) >= FAST_INTERFACE_MIN:
    return 'FAST stage variables (' + ', '.join(sorted(found)[:4]) + ')'
  return None


def _stage_similarity(repo, d, base_cat, cache):
  """{upstream stage: (files, variables)} similarity 0..1 for a folder.

  `files` is the comparison automatic matching uses; `variables` is the
  overlap of declared variables, since a stage rewritten file by file
  usually keeps its interface. Guesses rank by the higher of the two;
  merge risk depends on the files alone.
  """
  if 'sigs' not in cache:
    cache['sigs'] = {
        n: dir_signature(_join(base_cat['root'], p))
        for n, p in base_cat['stages'].items()
    }
    cache['vars'] = {
        n: set(_collect_variables(_join(base_cat['root'], p)))
        for n, p in base_cat['stages'].items()
    }
  full = _join(repo, d)
  sig, names = dir_signature(full), set(_collect_variables(full))
  scores = {}
  for name, upstream in cache['sigs'].items():
    up_vars = cache['vars'][name]
    by_vars = (len(names & up_vars) /
               len(names | up_vars) if names and up_vars else 0.0)
    scores[name] = (match_score(sig, upstream), by_vars)
  return scores


def _stage_guesses(repo, d, base_cat, cache):
  """The likeliest upstream stages for a folder, best first."""
  scores = {
      n: (max(s), s)
      for n, s in _stage_similarity(repo, d, base_cat, cache).items()
  }
  named, _ = _stage_from_name(
      posixpath.basename(d) or os.path.basename(repo),
      sorted(base_cat['stages']), words=True)
  ranked = sorted(scores, key=lambda n: (n != named, -scores[n][0], n))
  return [{
      'stage': n,
      'path': base_cat['stages'][n],
      'score': round(scores[n][0], 2),
      'files': round(scores[n][1][0], 2),
      'variables': round(scores[n][1][1], 2),
      'by_name': n == named,
  } for n in ranked if scores[n][0] > 0 or n == named][:CANDIDATE_GUESSES]


def _user_mappings(repo, stage_map, base_cat, target_cat):
  """Validates `--map` and returns (mappings, folders marked none, scores)."""
  by_path = {p: n for n, p in base_cat['stages'].items()}
  mappings, mine, scores, cache = [], [], {}, {}
  for folder, stage in sorted(stage_map.items()):
    if not os.path.isdir(_join(repo, folder)):
      raise UpgradeError(f'--map {folder or "."}: no such folder in the '
                         'repository')
    if stage is None:
      mine.append(folder)
      continue
    name = by_path.get(stage, stage)
    if name not in base_cat['stages']:
      raise UpgradeError(
          f'--map {folder or "."}={stage}: not a stage of the base release '
          f'{base_cat["version"]}; use one of: ' +
          ', '.join(sorted(base_cat['stages'])))
    if not dir_signature(_join(repo, folder)):
      raise UpgradeError(f'--map {folder or "."}: the folder has no .tf files')
    scores[folder] = round(
        _stage_similarity(repo, folder, base_cat, cache)[name][0], 2)
    mappings.append(
        Mapping('stage', name, folder, base_cat['stages'][name],
                target_cat['stages'].get(name), 'set by user'))
  return mappings, mine, scores


def map_repo(scan, base_cat, target_cat, renames, stage_map=None):
  """Maps customer folders to upstream stages and modules.

  `stage_map` ({folder: stage or None}, see parse_stage_map) is the user's
  answer for folders the automatic match cannot settle; it wins over it.
  Returns (mappings, customer stages, customer modules, module root,
  {'candidates', 'user'}).
  """
  repo = scan.root
  stage_names = sorted(set(base_cat['stages']) | set(target_cat['stages']))
  base_stage_sigs = {
      n: dir_signature(_join(base_cat['root'], p))
      for n, p in base_cat['stages'].items()
  }
  repo_name = os.path.basename(os.path.abspath(repo))

  def by_name(d):
    """Maps a folder by its name (the repository name for the root)."""
    name, how = _stage_from_name(
        posixpath.basename(d) if d else repo_name, stage_names, words=not d)
    if name and how != 'name' and name in base_stage_sigs:
      score = match_score(dir_signature(_join(repo, d)), base_stage_sigs[name])
      if score < PREFIX_MATCH_THRESHOLD:
        name = None
    if not name:
      return None
    return Mapping('stage', name, d, base_cat['stages'].get(name),
                   target_cat['stages'].get(name),
                   how if d else f'repository {how}')

  mappings, mine, user_scores = _user_mappings(repo, stage_map or {}, base_cat,
                                               target_cat)
  # Folders the user decided on, with everything below them.
  decided = [m.customer for m in mappings] + mine

  def is_decided(d):
    return any(_inside(d, x) for x in decided)

  unmatched = []
  for d in sorted(scan.stage_dirs):
    if is_decided(d):
      continue
    mapping = by_name(d)
    if mapping:
      mappings.append(mapping)
    else:
      unmatched.append(d)
  mappings += _fast_folder_mappings(repo, mappings, base_cat, target_cat)
  # Non-recursive mappings only own their top-level files, so they must not
  # hide the folders below them.
  mapped = {m.customer for m in mappings if m.recursive}
  candidates = list(unmatched)
  for d in sorted(scan.tf_dirs):
    if d in scan.stage_dirs or d in scan.module_dirs or is_decided(d):
      continue
    if any(_inside(d, x) for x in mapped | scan.module_dirs):
      continue
    candidates.append(d)
  customer_stages = [d for d in mine if dir_signature(_join(repo, d))]
  unmapped = []
  for d in candidates:
    # A repository that holds one stage at its root, named after it.
    if d == '' and d not in unmatched and not mapped:
      mapping = by_name(d)
      if mapping:
        mappings.append(mapping)
        continue
    score, name = _best_match(dir_signature(_join(repo, d)), base_stage_sigs)
    if name and score >= STAGE_MATCH_THRESHOLD:
      mappings.append(
          Mapping('stage', name, d, base_cat['stages'].get(name),
                  target_cat['stages'].get(name), f'content {score:.2f}'))
    else:
      unmapped.append(d)
      if d in unmatched:
        customer_stages.append(d)
  # Stage-like folders that came close: the user is asked which stage each
  # one is. The outermost folder of a branch speaks for the ones below it.
  stage_candidates, cache = [], {}
  for d in sorted(unmapped):
    if any(_inside(d, m.customer) for m in mappings if m.recursive):
      continue
    if any(_inside(d, c['folder']) for c in stage_candidates):
      continue
    reason = _stage_like(repo, d, scan)
    if not reason:
      continue
    guesses = _stage_guesses(repo, d, base_cat, cache)
    if guesses and (guesses[0]['by_name'] or
                    guesses[0]['score'] >= CANDIDATE_MIN_SCORE):
      stage_candidates.append({
          'folder': d,
          'reason': reason,
          'guesses': guesses
      })
  asked = {c['folder'] for c in stage_candidates}
  customer_stages = sorted(set(customer_stages) - asked)
  claimed = [m.customer for m in mappings if m.recursive]

  module_names = set(base_cat['modules']) | set(target_cat['modules'])
  customer_modules = {
      d for d in scan.module_dirs
      if d not in scan.stage_dirs and not any(_inside(d, s) for s in claimed)
  }
  # Every module call reveals a module root: list it to find the modules
  # vendored next to the called ones, including grouped modules.
  scan_roots = set()
  for d in customer_modules:
    name, root_rel = module_key(d, module_names)
    scan_roots.add(root_rel if name else posixpath.dirname(d))
  for root_rel in sorted(scan_roots):
    full = _join(repo, root_rel)
    for name in _subdirs(full):
      d = f'{root_rel}/{name}' if root_rel else name
      if d in scan.stage_dirs or any(_inside(d, s) for s in claimed):
        continue
      if _has_tf(os.path.join(full, name)):
        customer_modules.add(d)
      else:
        customer_modules.update(
            f'{d}/{sub}' for sub in _module_leaves(os.path.join(full, name)))
  base_module_sigs = None
  roots = collections.Counter()
  module_roots = {}
  customer_only_modules = []
  for d in sorted(customer_modules):
    name, root_rel = module_key(d, module_names)
    how = 'name'
    if name is None:
      if base_module_sigs is None:
        base_module_sigs = {
            n: dir_signature(_join(base_cat['root'], p))
            for n, p in base_cat['modules'].items()
        }
      score, name = _best_match(dir_signature(_join(repo, d)), base_module_sigs)
      if not name or score < MODULE_MATCH_THRESHOLD:
        customer_only_modules.append(d)
        continue
      how = f'content {score:.2f}'
      root_rel = posixpath.dirname(d)
    mappings.append(
        Mapping('module', name, d, base_cat['modules'].get(name),
                target_cat['modules'].get(name), how))
    roots[root_rel] += 1
    module_roots[d] = root_rel

  primary_root = roots.most_common(1)[0][0] if roots else None
  full_vendor = False
  if primary_root is not None:
    have = {m.name for m in mappings if m.kind == 'module'}
    in_root = {
        m.name
        for m in mappings
        if m.kind == 'module' and module_roots.get(m.customer) == primary_root
    }
    full_vendor = len(in_root & set(base_cat['modules'])) >= (
        FULL_VENDOR_RATIO * max(1, len(base_cat['modules'])))
    needed = module_closure(target_cat['root'],
                            [m.target for m in mappings if m.target],
                            target_cat['modules'])
    additions = {}
    for name in sorted(needed - have):
      additions[name] = 'new dependency'
    for old, new in sorted(renames.items()):
      if old in have and new not in have:
        additions.setdefault(new, f'renamed from {old}')
    if full_vendor:
      for name in sorted(set(target_cat['modules']) - have):
        additions.setdefault(name, 'new upstream module')
    for name, how in sorted(additions.items()):
      if name not in target_cat['modules']:
        continue
      d = f'{primary_root}/{name}' if primary_root else name
      mappings.append(
          Mapping('module', name, d, None, target_cat['modules'][name], how))
  mappings += _release_root_mappings(repo, mappings, base_cat, target_cat,
                                     primary_root, full_vendor)
  user = [{
      'folder': m.customer,
      'stage': m.name,
      'score': user_scores[m.customer],
      'low_similarity': user_scores[m.customer] < STAGE_MATCH_THRESHOLD,
  } for m in mappings if m.match == 'set by user']
  user += [{
      'folder': d,
      'stage': None,
      'score': None,
      'low_similarity': False
  } for d in mine]
  matching = {
      'candidates': stage_candidates,
      'user': sorted(user, key=lambda u: u['folder']),
  }
  return (mappings, customer_stages, customer_only_modules, primary_root,
          matching)


def git_template(calls, fabric_re):
  """Derives the customer's git source template for Fabric modules."""
  templates = collections.Counter()
  refs = collections.Counter()
  for call in calls:
    if (call['kind'] == 'git' and call.get('fabric') and call.get('ref') and
        call.get('subdir', '').startswith('modules/')):
      source = call['source']
      source = source.replace('//' + call['subdir'], '//{subdir}', 1)
      source = source.replace('ref=' + call['ref'], 'ref={ref}', 1)
      templates[source] += 1
      refs[call['ref']] += 1
  if not templates:
    return None, None
  return templates.most_common(1)[0][0], refs.most_common(1)[0][0]


class SourceRewriter:
  """Rewrites local module sources of upstream code to the customer layout.

  A source is only rewritten when it would not resolve to the right
  customer folder as written. Upstream spells some sources the long way
  (`../../../modules/x` from inside `modules/y/recipe`), and keeping the
  original spelling keeps unchanged files byte-identical.
  """

  def __init__(self, dir_map, template=None, ref=None):
    self.dir_map = dir_map
    self.template = template
    self.ref = ref

  def rewrite(self, text, upstream_file, customer_file):
    calls = hcl_lite.module_calls(text)
    if not calls:
      return text
    up_dir = posixpath.dirname(upstream_file)
    cu_dir = posixpath.dirname(customer_file)
    replacements = []
    for call in calls:
      if hcl_lite.classify_source(call.source) != 'local':
        continue
      target = posixpath.normpath(posixpath.join(up_dir, call.source))
      new = None
      if target in self.dir_map:
        wanted = self.dir_map[target]
        if posixpath.normpath(posixpath.join(cu_dir, call.source)) == wanted:
          continue
        new = posixpath.relpath(wanted, cu_dir or '.')
        if not new.startswith('.'):
          new = './' + new
      elif self.template and target.startswith('modules/'):
        new = self.template.replace('{subdir}',
                                    target).replace('{ref}', self.ref or '')
      if new and new != call.source:
        replacements.append((call.source_start, call.source_end, new))
    return hcl_lite.replace_spans(text, replacements)


# --------------------------------------------------------------------------
# The plan
# --------------------------------------------------------------------------


@dataclasses.dataclass
class FileResult:
  path: str
  category: str
  kind: str
  mapping: str
  base_path: str = None
  target_path: str = None
  marker_only: bool = False
  layout_adjusted: bool = False
  binary: bool = False
  link: bool = False
  renamed_to: str = None
  renamed_from: str = None
  blocked: str = None
  # The customer's copy keeps upstream's module sources although the rest
  # of the repository uses another module folder: compared and written
  # without the layout rewrite.
  upstream_sources: bool = False
  # A file of an upstream sample dataset (`datasets/<name>/`) that the
  # customer does not keep: their data lives in another dataset, folder or
  # repository. apply does not add or restore these.
  sample_data: bool = False


def _git_ignored(repo, rel_path):
  if not shutil.which('git'):
    return False
  proc = git(['-C', repo, 'check-ignore', '-q', rel_path], check=False)
  return proc.returncode == 0


def linked_repos(repo, mappings, scan=None):
  """Mapped folders that live in another git repository.

  A module folder can be a symlink to a separate checkout, or a nested,
  git-ignored clone. Either way `git status` of the main repository does
  not see changes there: apply must check that repository too, and the
  upgrade needs one commit per repository. The same holds for a folder
  inside a stage, typically `datasets/` kept in its own repository: a
  nested clone is written by apply like any other folder, a symlink is
  compared through the link but never written through (`writes` False).
  """
  real_repo = os.path.realpath(repo)
  found = {}

  def entry(prefix, kind, mapped, writes=True):
    full = _join(repo, prefix)
    target = os.path.realpath(full)
    return {
        'path':
            prefix,
        'kind':
            kind,
        'target':
            target,
        'outside':
            not target.startswith(real_repo + os.sep),
        'ignored':
            _git_ignored(repo, prefix),
        'git':
            git_state(target) if os.path.isdir(target) else {
                'git': False,
                'reason': 'missing'
            },
        'mappings':
            mapped,
        'writes':
            writes,
    }

  for m in mappings:
    if not m.customer:
      continue
    parts = m.customer.split('/')
    for i in range(1, len(parts) + 1):
      prefix = '/'.join(parts[:i])
      if prefix in found:
        found[prefix]['mappings'] += 1
        break
      full = _join(repo, prefix)
      kind = None
      if os.path.islink(full):
        kind = 'symlink'
      elif os.path.exists(os.path.join(full, '.git')):
        kind = 'nested repository'
      if kind:
        found[prefix] = entry(prefix, kind, 1)
        break
  if scan is not None:
    below = [(l['path'], 'symlink')
             for l in scan.links
             if l['dir'] and not l['broken']]
    below += [(p, 'nested repository') for p in scan.nested_repos]
    for path, kind in sorted(below):
      if any(_inside(path, p) for p in found):
        continue
      owners = [
          m for m in mappings if m.recursive and m.customer is not None and
          _inside(path, m.customer) and path != m.customer
      ]
      if not owners:
        continue
      linked = entry(path, kind, len(owners), writes=kind != 'symlink')
      # A link to another folder of the same repository is an alias, not
      # a separate repository.
      if kind == 'symlink' and not linked['outside']:
        continue
      found[path] = linked
  return sorted(found.values(), key=lambda r: r['path'])


class Context:
  """Everything `plan` and `apply` derive from their three inputs."""

  def __init__(self, repo, base, target, fabric_source=DEFAULT_FABRIC_SOURCE,
               data_paths=(), stage_map=None):
    self.repo = os.path.abspath(repo)
    self.fabric_re = re.compile(fabric_source)
    self.stage_map = dict(stage_map or {})
    self.data_paths = [os.path.abspath(p) for p in data_paths]
    for path in self.data_paths:
      if not os.path.exists(path):
        raise UpgradeError(f'data path not found: {path}')
    self.scan = scan_repo(self.repo, self.fabric_re)
    self.base_cat = catalog(base)
    self.target_cat = catalog(target)
    self.base_version = self.base_cat['version']
    self.target_version = self.target_cat['version']
    self.warnings = []
    self.notes = []
    if not self.base_version or not self.target_version:
      raise UpgradeError('cannot read the release of the base or target tree '
                         '(default-versions.tf or fast_version.txt)')
    base_v, target_v = _version(self.base_version), _version(
        self.target_version)
    if target_v < base_v:
      raise UpgradeError(f'target {self.target_version} is older than base '
                         f'{self.base_version}: downgrades are not supported')
    if target_v == base_v:
      self.warnings.append('base and target are the same release: nothing '
                           'upstream to take')
    self.detected, self.confidence, self.breakdown = version_consensus(
        self.scan.markers)
    if self.detected and self.detected != self.base_version:
      self.warnings.append(
          f'the repository looks like {self.detected} but the base is '
          f'{self.base_version}: a wrong base turns upstream changes into '
          'conflicts. Use the release the repository was built from.')
    if self.confidence == 'mixed':
      self.warnings.append('version markers disagree (mixed releases): ' +
                           _breakdown_text(self.breakdown))
    changelog_path = _join(self.target_cat['root'], 'CHANGELOG.md')
    self.releases = []
    if os.path.isfile(changelog_path):
      self.releases = release_notes.select_releases(
          release_notes.parse_changelog(_read_text(changelog_path)), base_v,
          target_v)
    else:
      self.warnings.append('target tree has no CHANGELOG.md: breaking changes '
                           'cannot be listed')
    self.renames = module_renames(
        self.base_cat, self.target_cat,
        release_notes.declared_module_renames(self.releases))
    (self.mappings, self.customer_stages, self.customer_modules,
     self.modules_root, self.matching) = map_repo(self.scan, self.base_cat,
                                                  self.target_cat, self.renames,
                                                  self.stage_map)
    self.template, template_ref = git_template(self.scan.calls, self.fabric_re)
    base_map = {
        m.base: m.customer
        for m in self.mappings
        if m.kind == 'module' and m.base
    }
    target_map = {
        m.target: m.customer
        for m in self.mappings
        if m.kind == 'module' and m.target
    }
    self.rewriters = {
        'base':
            SourceRewriter(base_map, self.template, template_ref or
                           self.base_version),
        'target':
            SourceRewriter(target_map, self.template, self.target_version),
    }
    self.roots = {
        'base': self.base_cat['root'],
        'target': self.target_cat['root']
    }
    self.raw_files = set()
    self.upstream_schemas = None
    self.linked_repos = linked_repos(self.repo, self.mappings, self.scan)

  def upstream_bytes(self, side, upstream_rel, customer_rel):
    """Returns upstream file content adjusted to the customer layout."""
    path = _join(self.roots[side], upstream_rel)
    data = _read_bytes(path)
    if b'\0' in data[:8192]:
      return data
    data = data.replace(b'\r\n', b'\n')
    if _is_terraform(upstream_rel) and customer_rel not in self.raw_files:
      text = data.decode('utf-8', errors='replace')
      new = self.rewriters[side].rewrite(text, upstream_rel, customer_rel)
      if new != text:
        return new.encode('utf-8')
    return data

  def upstream_entry(self, side, upstream_rel, customer_rel, raw=False):
    if upstream_rel is None:
      return None
    path = _join(self.roots[side], upstream_rel)
    rewrite = None
    if _is_terraform(upstream_rel) and not raw:
      rewrite = lambda text: self.rewriters[side].rewrite(
          text, upstream_rel, customer_rel)
    return read_entry(path, rewrite)


def _breakdown_text(breakdown):
  parts = []
  for kind, counts in breakdown.items():
    inner = ', '.join(f'{v} x{n}' for v, n in sorted(counts.items()))
    parts.append(f'{kind}: {inner}')
  return '; '.join(parts)


def _dir_names(path):
  """Names of the folders (or links to them) in path; empty if missing."""
  try:
    return {
        n for n in os.listdir(path) if os.path.isdir(os.path.join(path, n)) or
        os.path.islink(os.path.join(path, n))
    }
  except OSError:
    return set()


def diff_mapping(ctx, mapping, exclude):
  c_root = _join(ctx.repo, mapping.customer)
  b_root = (_join(ctx.base_cat['root'], mapping.base)
            if mapping.base is not None else None)
  t_root = (_join(ctx.target_cat['root'], mapping.target)
            if mapping.target is not None else None)
  top = not mapping.recursive
  c_files = walk_tree(c_root, exclude, top)
  b_files = walk_tree(b_root, (), top)
  t_files = walk_tree(t_root, (), top)
  if mapping.only is not None:
    keep = set(mapping.only)
    c_files, b_files, t_files = ({
        k: v for k, v in files.items() if k in keep
    } for files in (c_files, b_files, t_files))
  if top:
    c_files = {k: v for k, v in c_files.items() if k in b_files or k in t_files}
  links = {r for r, p in c_files.items() if os.path.islink(p)}
  # An upstream folder replaced by a link to another checkout (datasets/
  # kept in its own repository): compare the files through the link, so
  # they are not all reported as removed. They stay blocked below.
  real_root = os.path.realpath(c_root)
  for rel in sorted(links):
    full = c_files[rel]
    if top or not os.path.isdir(full):
      continue
    points_to = _rel(os.path.realpath(full), real_root)
    # Links inside the folder (upstream's own datasets/classic alias) are
    # compared as links, like upstream does.
    if not (points_to == '..' or points_to.startswith('../')):
      continue
    if not any(
        k.startswith(rel + '/') for k in itertools.chain(b_files, t_files)):
      continue
    for sub, path in walk_tree(full).items():
      c_files.setdefault(f'{rel}/{sub}', path)
  # Upstream sample datasets (`datasets/<name>/`) the customer does not
  # keep. A dataset new in the target counts only when the customer already
  # dropped some of the base datasets: a fork that keeps them all gets the
  # new one too.
  base_datasets = set()
  curated = False
  if mapping.kind == 'stage' and b_root:
    base_datasets = _dir_names(os.path.join(b_root, 'datasets'))
    curated = bool(base_datasets - _dir_names(os.path.join(c_root, 'datasets')))
  results = []
  for rel_path in sorted(set(c_files) | set(b_files) | set(t_files)):
    customer_rel = (f'{mapping.customer}/{rel_path}'
                    if mapping.customer else rel_path)
    b_rel = _under(mapping.base, rel_path) if rel_path in b_files else None
    t_rel = _under(mapping.target, rel_path) if rel_path in t_files else None
    c = read_entry(c_files.get(rel_path))
    b = ctx.upstream_entry('base', b_rel, customer_rel)
    t = ctx.upstream_entry('target', t_rel, customer_rel)
    upstream_sources = False
    if (b and b.adjusted and c and c.kind == 'file' and c.digest != b.digest):
      # The rest of the repository uses another module folder, but this
      # file still has upstream's sources: comparing it with the rewritten
      # base would report the untouched upstream paths as a customer edit.
      raw_b = ctx.upstream_entry('base', b_rel, customer_rel, raw=True)
      if raw_b and raw_b.digest == c.digest:
        b = raw_b
        t = ctx.upstream_entry('target', t_rel, customer_rel, raw=True)
        upstream_sources = True
        ctx.raw_files.add(customer_rel)
    category = classify(c and c.digest, b and b.digest, t and t.digest)
    entries = [e for e in (c, b, t) if e]
    parts = rel_path.split('/')
    sample = (mapping.kind == 'stage' and c is None and len(parts) >= 2 and
              parts[0] == 'datasets' and
              not os.path.lexists(_join(c_root, f'datasets/{parts[1]}')) and
              (parts[1] in base_datasets or curated))
    result = FileResult(
        path=customer_rel, category=category, kind=file_kind(rel_path),
        mapping=mapping.customer, base_path=b_rel, target_path=t_rel,
        layout_adjusted=bool(
            (b and b.adjusted) or
            (t and t.adjusted)), binary=any(e.binary for e in entries),
        link=any(e.kind == 'link' for e in entries),
        upstream_sources=upstream_sources, sample_data=sample)
    parents = rel_path.split('/')[:-1]
    for i in range(len(parents)):
      if '/'.join(parents[:i + 1]) in links:
        result.blocked = 'a parent folder is a symlink in your repository'
    if (b and t and b.digest != t.digest and b.kind == t.kind == 'file' and
        not result.binary):
      b_text = ctx.upstream_bytes('base', b_rel,
                                  customer_rel).decode('utf-8',
                                                       errors='replace')
      t_text = ctx.upstream_bytes('target', t_rel,
                                  customer_rel).decode('utf-8',
                                                       errors='replace')
      result.marker_only = (
          _normalize_versions(b_text) == _normalize_versions(t_text))
    results.append(result)
  return results


def pair_renames(ctx, results):
  """Pairs removed and added upstream files that are renames."""
  removed = [
      r for r in results
      if r.category in ('upstream-deleted', 'conflict-deleted') and
      r.base_path and not r.binary and not r.link
  ]
  added = [
      r for r in results
      if r.category == 'upstream-added' and not r.binary and not r.link
  ]
  renamed_dirs = {}
  for m in ctx.mappings:
    if m.kind == 'module' and m.name in ctx.renames:
      renamed_dirs[m.customer] = ctx.renames[m.name]
  new_dirs = {m.name: m.customer for m in ctx.mappings if m.kind == 'module'}
  for old in removed:
    old_text = None
    best = (0.0, None)
    for new in added:
      if new.renamed_from or posixpath.splitext(
          new.path)[1] != posixpath.splitext(old.path)[1]:
        continue
      if new.mapping == old.mapping:
        if old_text is None:
          old_text = ctx.upstream_bytes('base', old.base_path,
                                        old.path).decode('utf-8', 'replace')
        new_text = ctx.upstream_bytes('target', new.target_path,
                                      new.path).decode('utf-8', 'replace')
        matcher = difflib.SequenceMatcher(None, old_text, new_text,
                                          autojunk=False)
        if matcher.real_quick_ratio() < RENAME_SIMILARITY:
          continue
        if matcher.quick_ratio() < RENAME_SIMILARITY:
          continue
        score = matcher.ratio()
      elif (old.mapping in renamed_dirs and
            new.mapping == new_dirs.get(renamed_dirs[old.mapping]) and
            old.path[len(old.mapping):] == new.path[len(new.mapping):]):
        score = 1.0
      else:
        continue
      if score >= RENAME_SIMILARITY and score > best[0]:
        best = (score, new)
    if best[1]:
      old.renamed_to = best[1].path
      best[1].renamed_from = old.path


def _collect_variables(root):
  result = {}
  for name in sorted(os.listdir(root)) if os.path.isdir(root) else []:
    if name.endswith('.tf'):
      result.update(hcl_lite.variables(_read_text(os.path.join(root, name))))
  return result


def variable_diff(base_dir, target_dir):
  b = _collect_variables(base_dir)
  t = _collect_variables(target_dir)
  common = set(b) & set(t)
  return {
      'removed':
          sorted(set(b) - set(t)),
      'added_required':
          sorted(n for n in set(t) - set(b) if not t[n]['has_default']),
      'default_removed':
          sorted(n for n in common
                 if b[n]['has_default'] and not t[n]['has_default']),
      'type_changed': [{
          'name': n,
          'base': b[n]['type'],
          'target': t[n]['type']
      } for n in sorted(common) if b[n]['type'] != t[n]['type']],
  }


def _tfvars_keys(path):
  try:
    text = _read_text(path)
  except OSError:
    return None
  return set(hcl_lite.tfvars_keys(text, path.endswith('.json')))


def _unreadable_reason(path, repo):
  rel = _rel(path, repo)
  label = path if rel.startswith('../') else rel
  if os.path.islink(path) and not os.path.exists(path):
    return f'{label} (broken symlink to {os.readlink(path)})'
  return f'{label} (cannot be read)'


def stage_variables(ctx):
  data_tfvars = []
  for path in ctx.data_paths:
    for rel_path in walk_tree(path) if os.path.isdir(path) else {
        os.path.basename(path): path
    }:
      if rel_path.endswith(('.tfvars', '.tfvars.json')):
        data_tfvars.append(
            _join(path, rel_path) if os.path.isdir(path) else path)
  result = []
  for m in ctx.mappings:
    if m.kind != 'stage' or not m.base or not m.target:
      continue
    diff = variable_diff(_join(ctx.base_cat['root'], m.base),
                         _join(ctx.target_cat['root'], m.target))
    files = [
        _join(ctx.repo, f)
        for f in ctx.scan.tfvars_files
        if posixpath.dirname(f) == m.customer
    ]
    prefixes = (m.name, posixpath.basename(m.customer))
    files += [
        p for p in data_tfvars if os.path.basename(p).startswith(prefixes)
    ]
    keys = set()
    unreadable = []
    for path in files:
      found = _tfvars_keys(path)
      if found is None:
        unreadable.append(_unreadable_reason(path, ctx.repo))
      else:
        keys |= found
    removed = set(diff['removed'])
    entry = dict(diff)
    entry.update({
        'stage': m.customer,
        'upstream': m.name,
        'tfvars_files': sorted(files),
        'tfvars_set_removed': sorted(keys & removed),
        'tfvars_unreadable': sorted(unreadable),
    })
    if any(entry[k] for k in ('removed', 'added_required', 'default_removed',
                              'type_changed', 'tfvars_unreadable')):
      result.append(entry)
  return result


def _call_module_name(call, module_by_dir):
  if call['kind'] == 'local' and call.get('resolved'):
    return module_by_dir.get(call['resolved'])
  return git_module_name(call)


def _clip(text, width):
  return text if len(text) <= width else text[:width - 3] + '...'


def type_delta(before, after, width=70, max_runs=2):
  """Summarizes how a type expression changed as a short token diff.

  Full Fabric types run to thousands of characters; the report shows what
  was removed (-) and added (+), after a few words of context.
  """
  a, b = (before or '').split(), (after or '').split()
  matcher = difflib.SequenceMatcher(None, a, b, autojunk=False)
  runs = []
  for tag, i1, i2, j1, j2 in matcher.get_opcodes():
    if tag == 'equal':
      continue
    parts = []
    if i2 > i1:
      parts.append('- ' + _clip(' '.join(a[i1:i2]), width))
    if j2 > j1:
      parts.append('+ ' + _clip(' '.join(b[j1:j2]), width))
    context = ' '.join(a[max(0, i1 - 5):i1])
    if len(context) > 40:
      context = '...' + context[-37:]
    prefix = f'after `{context}` ' if context else ''
    runs.append(prefix + ' '.join(parts))
  if not runs:
    return 'whitespace only'
  more = len(runs) - max_runs
  return '; '.join(runs[:max_runs]) + (f' (+{more} more)' if more > 0 else '')


def _in_module_mapping(ctx, rel_path):
  return any(m.kind == 'module' and _inside(rel_path, m.customer)
             for m in ctx.mappings)


def referenced_modules(ctx):
  """Upstream module names that customer code and mapped stages call.

  Calls made from inside vendored module folders (module internals,
  recipes) do not count: a vendored but unused module is not in use.
  """
  module_by_dir = {
      m.customer: m.name for m in ctx.mappings if m.kind == 'module'
  }
  names = set()
  for call in ctx.scan.calls:
    if _in_module_mapping(ctx, call['file']):
      continue
    name = _call_module_name(call, module_by_dir)
    if name:
      names.add(name)
  modules = ctx.target_cat['modules']
  start = [m.target for m in ctx.mappings if m.kind == 'stage' and m.target]
  start += [modules[n] for n in names if n in modules]
  names |= module_closure(ctx.target_cat['root'], start, modules)
  return names


def module_interface(ctx, by_path):
  """Checks customer-owned module calls against target module interfaces."""
  module_by_dir = {
      m.customer: m.name for m in ctx.mappings if m.kind == 'module'
  }
  owned = ('customer-added', 'customer-changed', 'conflict', 'conflict-added')
  diffs = {}
  hits = []
  for call in ctx.scan.calls:
    result = by_path.get(call['file'])
    if result is not None and result.category not in owned:
      continue
    # Calls between vendored modules are upstream's to keep consistent,
    # unless the customer wrote them.
    if _in_module_mapping(
        ctx, call['file']) and (result is None or result.category
                                not in ('customer-added', 'customer-changed')):
      continue
    name = _call_module_name(call, module_by_dir)
    if not name:
      continue
    where = f'{call["file"]}:{call["line"]} module "{call["name"]}"'
    if name in ctx.renames:
      hits.append({
          'call': where,
          'module': name,
          'issue': f'module renamed upstream to {ctx.renames[name]}: update '
                   'the source'
      })
      continue
    base_dir = ctx.base_cat['modules'].get(name)
    target_dir = ctx.target_cat['modules'].get(name)
    if not base_dir or not target_dir:
      continue
    if name not in diffs:
      diffs[name] = variable_diff(_join(ctx.base_cat['root'], base_dir),
                                  _join(ctx.target_cat['root'], target_dir))
    diff = diffs[name]
    args = set(call['args'])
    for arg in sorted(args & set(diff['removed'])):
      hits.append({
          'call': where,
          'module': name,
          'issue': f'passes `{arg}`, removed in {ctx.target_version}'
      })
    for change in diff['type_changed']:
      if change['name'] in args:
        hits.append({
            'call':
                where,
            'module':
                name,
            'issue':
                f'passes `{change["name"]}`, whose type changed: ' +
                type_delta(change['base'], change['target']),
            'base_type':
                change['base'],
            'target_type':
                change['target'],
        })
    for arg in sorted(
        set(diff['added_required'] + diff['default_removed']) - args):
      hits.append({
          'call': where,
          'module': name,
          'issue': f'does not pass `{arg}`, now required'
      })
  return hits


def schema_changes(ctx, results):
  changes = []
  for r in results:
    if r.kind != 'schema' or not r.base_path or not r.target_path:
      continue
    if r.category not in ('upstream-changed', 'conflict', 'already-updated'):
      continue
    before, error_b = factory_data.load_schema(
        _join(ctx.base_cat['root'], r.base_path))
    after, error_t = factory_data.load_schema(
        _join(ctx.target_cat['root'], r.target_path))
    if error_b or error_t:
      continue
    diff = factory_data.diff_schemas(before, after)
    if any(diff.values()):
      diff['path'] = r.path
      changes.append(diff)
  return changes


def _upstream_schema_index(ctx):
  """{schema file name: [paths relative to the base tree]}, built once."""
  if ctx.upstream_schemas is None:
    index = collections.defaultdict(list)
    root = ctx.base_cat['root']
    for path in factory_data.find_schema_files(
        [_join(root, 'fast'), _join(root, 'modules')], IGNORED_DIRS):
      index[os.path.basename(path)].append(_rel(path, root))
    ctx.upstream_schemas = index
  return ctx.upstream_schemas


def _upstream_stage_of(rel_path, cat):
  """The upstream stage whose folder holds rel_path, or None."""
  for name, path in cat['stages'].items():
    if _inside(rel_path, path):
      return name
  return None


def upstream_schema(ctx, hint, ref, stages=()):
  """Resolves a modeline against the schemas of the base release, by name.

  For data the repository has no schema for: a dataset repository, a
  data/ folder next to the stages, a wrapper's data. Schema names repeat
  across stages (project.schema.json), so when copies differ the folders
  in `hint` (data/2-networking/...) or the stages mapped in the repository
  pick one. Returns (base path, target path or None, upstream stage or
  None) and how it was found, or (None, why not).
  """
  if ref.startswith(('http://', 'https://')):
    return None, 'remote schema (not fetched)'
  root = ctx.base_cat['root']
  candidates = _upstream_schema_index(ctx).get(posixpath.basename(ref), [])

  def same(paths):
    return len({_sha(_read_bytes(_join(root, p))) for p in paths}) == 1

  if len(candidates) > 1 and not same(candidates):
    names = list(ctx.base_cat['stages'])
    hints = set()
    for part in hint.split('/')[:-1]:
      name, _ = _stage_from_name(part, names, words=True)
      if name:
        hints.add(name)
    hints = hints or set(stages)
    candidates = [
        p for p in candidates if _upstream_stage_of(p, ctx.base_cat) in hints
    ]
    if not candidates or not same(candidates):
      stages_with = sorted({
          _upstream_stage_of(p, ctx.base_cat) or 'modules'
          for p in _upstream_schema_index(ctx)[posixpath.basename(ref)]
      })
      return None, (f'{posixpath.basename(ref)} differs between '
                    f'{", ".join(stages_with)}: keep the data in a folder '
                    'named after its stage (for example data/2-networking) '
                    'or plan it together with the stage code (--data)')
  if not candidates:
    return None, 'schema not found in the repository or the release'
  rel = sorted(candidates)[0]
  stage = _upstream_stage_of(rel, ctx.base_cat)
  target = _join(ctx.target_cat['root'], rel)
  if not os.path.isfile(target) and stage in ctx.target_cat['stages']:
    moved = [
        p for p in _walk_names(
            _join(ctx.target_cat['root'], ctx.target_cat['stages'][stage]))
        if os.path.basename(p) == os.path.basename(rel)
    ]
    target = moved[0] if len(moved) == 1 else None
  return (_join(root,
                rel), target if target and os.path.isfile(target) else None,
          stage), 'release schema'


def _walk_names(root):
  return [
      os.path.join(d, n)
      for d, _, names in os.walk(root)
      for n in names
      if factory_data.is_schema_file(n)
  ]


def data_impact(ctx, results):
  """Validates customer factory YAML before and after the upgrade.

  Covers YAML in mapped stages, YAML with a schema modeline anywhere else
  in the repository (a data/ folder, a wrapper's data), YAML behind
  symlinked folders, and --data paths. Schemas come from the repository;
  when it has none for a file, from the base and target releases. Also
  lists mapped stages whose upstream uses datasets but where no data was
  found, so an empty check is not reported as a clean one.
  """
  if not factory_data.available():
    return {
        'skipped':
            'install ' + ' and '.join(factory_data.missing_dependencies())
    }
  by_path = {r.path: r for r in results}
  index = factory_data.SchemaIndex(
      [_join(ctx.repo, s) for s in ctx.scan.schema_files])
  stage_maps = [m for m in ctx.mappings if m.kind == 'stage']
  module_dirs = [
      m.customer for m in ctx.mappings if m.kind == 'module' and m.recursive
  ]
  stage_names = sorted({m.name for m in stage_maps})
  repo_name = os.path.basename(ctx.repo)
  files = []
  seen = set()
  with_data = set()

  def stage_for(rel_path):
    best = None
    for m in stage_maps:
      if _inside(rel_path, m.customer) and (best is None or len(m.customer)
                                            > len(best.customer)):
        best = m
    return best

  def repo_file(rel_path, path):
    real = os.path.realpath(path)
    if real in seen:
      return
    seen.add(real)
    stage = stage_for(rel_path)
    if stage is None and any(_inside(rel_path, d) for d in module_dirs):
      return  # module examples and tests, not data
    hidden = any(p.startswith('.') for p in rel_path.split('/')[:-1])
    if stage is not None and not hidden:
      with_data.add(stage.customer)
    result = by_path.get(rel_path)
    if result is not None and result.category in UPSTREAM_CONTENT:
      return  # upstream's own sample data, used as is
    # Outside stages, only files that declare a schema are factory data;
    # the rest is CI configuration and the like.
    files.append(
        (path, rel_path, f'{repo_name}/{rel_path}', result, stage is None or
         hidden, stage))

  for rel_path in ctx.scan.yaml_files:
    repo_file(rel_path, _join(ctx.repo, rel_path))
  for link in ctx.scan.links:
    if not link['dir'] or link['broken']:
      continue
    full = _join(ctx.repo, link['path'])
    for path in factory_data.find_yaml_files([full], IGNORED_DIRS):
      repo_file(f'{link["path"]}/{_rel(path, full)}', path)
  for root in ctx.data_paths:
    for path in factory_data.find_yaml_files([root], IGNORED_DIRS):
      real = os.path.realpath(path)
      if real in seen:
        continue
      seen.add(real)
      rel = _rel(path,
                 root) if os.path.isdir(root) else posixpath.basename(path)
      files.append(
          (path, path, f'{posixpath.basename(root)}/{rel}', None, False, None))

  summary = collections.Counter()
  details = []
  for path, label, hint, result, loose, stage in files:
    try:
      text = _read_text(path)
    except OSError:
      continue
    ref = factory_data.modeline(text)
    if not ref:
      if not loose:
        summary['no-modeline'] += 1
      continue
    before_path, how = index.resolve(path, ref)
    after_path = before_path
    note = None
    upstream_stage = None
    if before_path:
      schema_rel = _rel(before_path, ctx.repo)
      schema_label = schema_rel
      schema_result = by_path.get(schema_rel)
      if schema_result is not None:
        if schema_result.category in ('upstream-changed', 'upstream-added',
                                      'conflict'):
          after_path = _join(ctx.target_cat['root'], schema_result.target_path)
          if schema_result.category == 'conflict':
            note = 'schema has a pending merge'
        elif schema_result.category in ('upstream-deleted', 'conflict-deleted'):
          after_path = None
      owner = stage_for(schema_rel)
      if owner is not None and not schema_rel.startswith('../'):
        with_data.add(owner.customer)
    else:
      found, why = upstream_schema(ctx, hint, ref, stage_names)
      if not found:
        summary['unresolved'] += 1
        details.append({
            'file': label,
            'status': 'unresolved',
            'reason': f'{how}; {why}'
        })
        continue
      before_path, after_path, upstream_stage = found
      schema_label = (f'{ctx.base_version} '
                      f'{_rel(before_path, ctx.base_cat["root"])}')
      note = 'validated against the release schemas'
      with_data.update(
          m.customer for m in stage_maps if m.name == upstream_stage)
    if stage is not None:
      with_data.add(stage.customer)
    before_schema, error = factory_data.load_schema(before_path)
    if error:
      summary['unresolved'] += 1
      details.append({'file': label, 'status': 'unresolved', 'reason': error})
      continue
    before = factory_data.validate_text(text, before_schema)
    if after_path is None:
      status, after = 'schema-removed', []
    else:
      after_schema, error = factory_data.load_schema(after_path)
      after = factory_data.validate_text(
          text, after_schema) if not error else [error]
      if (factory_data.is_validator_error(before) or
          factory_data.is_validator_error(after)):
        status = 'validator-error'
      elif not before and not after:
        status = 'ok'
      elif not before:
        status = 'breaks'
      elif not after:
        status = 'fixed'
      else:
        status = 'still-invalid'
    summary[status] += 1
    if status != 'ok':
      if status == 'validator-error':
        errors = [
            e for e in (before + after)
            if e.startswith(factory_data.VALIDATOR_ERROR)
        ][:1]
      else:
        errors = (after if status == 'breaks' else before)[:5]
      entry = {
          'file': label,
          'status': status,
          'schema': schema_label,
          'errors': errors,
      }
      if result is not None and result.category.startswith('conflict'):
        entry['note'] = 'file has a pending merge'
      if note:
        entry['note'] = note
      details.append(entry)
  details.sort(key=lambda d: (DATA_ORDER.index(d['status']), d['file']))
  without = sorted(
      m.customer or '.'
      for m in stage_maps
      if m.customer not in with_data and m.base and
      os.path.isdir(_join(ctx.base_cat['root'], f'{m.base}/datasets')))
  return {
      'summary': dict(summary),
      'files': details,
      'stages_without_data': without,
  }


def provider_constraints(root):
  path = _join(root, 'default-versions.tf')
  text = _read_text(path) if os.path.isfile(path) else ''
  result = {}
  for key, pattern in (
      ('terraform', r'required_version\s*=\s*"([^"]+)"'),
      ('google', r'(?<![\w-])google\s*=\s*\{[^}]*?version\s*=\s*"([^"]+)"'),
      ('google-beta', r'google-beta\s*=\s*\{[^}]*?version\s*=\s*"([^"]+)"'),
  ):
    m = re.search(pattern, text, re.S)
    result[key] = m.group(1) if m else None
  return result


def unresolved_sources(ctx, results):
  """Lists local module sources that would not resolve after apply."""
  planned = {m.customer for m in ctx.mappings}
  problems = []
  for r in results:
    if r.kind != 'terraform' or r.binary or r.link or not r.target_path:
      continue
    if r.category not in ('upstream-changed', 'upstream-added', 'conflict'):
      continue
    text = ctx.upstream_bytes('target', r.target_path,
                              r.path).decode('utf-8', 'replace')
    for call in hcl_lite.module_calls(text):
      if hcl_lite.classify_source(call.source) != 'local':
        continue
      target = posixpath.normpath(
          posixpath.join(posixpath.dirname(r.path), call.source))
      if target in planned or os.path.isdir(_join(ctx.repo, target)):
        continue
      problems.append({
          'file': r.path,
          'line': call.line,
          'source': call.source
      })
  return problems


def _pin_version(text):
  parts = [int(p) for p in text.split('.')]
  return tuple(parts + [0] * (3 - len(parts))), len(parts)


def constraint_allows(constraint, version):
  """True if a Terraform version constraint admits version; None if unknown.

  Supports =, !=, >, >=, <, <= and ~> clauses separated by commas.
  """
  wanted = _version(version) if isinstance(version, str) else version
  if not constraint or not wanted:
    return None
  for clause in constraint.split(','):
    m = PIN_RE.match(clause)
    if not m:
      return None
    op, (value, precision) = m.group(1) or '=', _pin_version(m.group(2))
    if op == '~>':
      upper = list(value[:max(precision - 1, 1)])
      upper[-1] += 1
      upper = tuple(upper + [0] * (3 - len(upper)))
      ok = value <= wanted < upper if precision > 1 else wanted >= value
    else:
      ok = {
          '=': wanted == value,
          '!=': wanted != value,
          '>': wanted > value,
          '>=': wanted >= value,
          '<': wanted < value,
          '<=': wanted <= value,
      }[op]
    if not ok:
      return False
  return True


def lower_bound(constraint):
  """The lowest version a constraint asks for (its >=, >, ~> or = floor)."""
  best = None
  for clause in (constraint or '').split(','):
    m = PIN_RE.match(clause)
    if m and (m.group(1) or '=') in ('>=', '>', '~>', '='):
      value = _pin_version(m.group(2))[0]
      best = value if best is None or value > best else best
  return best


def _loaded_version_files(scan):
  """Paths of version files that some Terraform configuration loads.

  Terraform reads the top-level .tf files of a root or child module. A
  file counts when its folder holds configuration besides version files
  (a stage, a module, an environment folder), or when such a folder links
  to it: module versions.tf files can be symlinks to one shared file. A
  template that nothing loads, such as a fork's root default-versions.tf,
  cannot break `terraform init`.
  """
  version_paths = {v['path'] for v in scan.version_files}
  configs = set()
  for d in scan.tf_dirs:
    full = _join(scan.root, d)
    try:
      names = sorted(os.listdir(full))
    except OSError:
      continue
    for n in names:
      path = os.path.join(full, n)
      if (n.endswith('.tf') and not os.path.islink(path) and
          CONFIG_BLOCK_RE.search(hcl_lite.mask(_read_text(path)))):
        configs.add(d)
        break
  loaded = {p for p in version_paths if posixpath.dirname(p) in configs}
  real_root = os.path.realpath(scan.root)
  for link in scan.links:
    if (link['dir'] or link['broken'] or not _is_terraform(link['path']) or
        posixpath.dirname(link['path']) not in configs):
      continue
    real = os.path.realpath(_join(scan.root, link['path']))
    if real.startswith(real_root + os.sep):
      rel = _rel(real, real_root)
      if rel in version_paths:
        loaded.add(rel)
  return loaded


def version_pins_report(ctx, by_path, target_pins):
  """Customer-owned files whose version pins or release stamp are stale.

  Upstream-owned files are updated by apply. A copy of default-versions.tf
  under another name (terraform.tf, versions.tf in a stage) is the
  customer's, is kept, and still pins the base release's providers:
  `terraform init` then fails against the target's modules. Only files
  that a Terraform configuration loads are checked.
  """
  loaded = _loaded_version_files(ctx.scan)
  entries = []
  for info in ctx.scan.version_files:
    if info['path'] not in loaded:
      continue
    result = by_path.get(info['path'])
    if result is not None and result.category not in CUSTOMER_OWNED:
      continue
    pins = []
    for key, constraint in sorted(info['pins'].items()):
      target = target_pins.get(key)
      floor = lower_bound(target)
      allows = constraint_allows(constraint, floor) if floor else None
      pins.append({
          'name': key,
          'constraint': constraint,
          'target': target,
          'allows_target': allows,
      })
    stale = bool(info['marker'] and info['marker'] != ctx.target_version)
    if stale or any(p['allows_target'] is False for p in pins):
      entries.append({
          'file': info['path'],
          'category': result.category if result else 'unmapped',
          'marker': info['marker'],
          'stale_marker': stale,
          'pins': pins,
          'blocks_init': any(p['allows_target'] is False for p in pins),
      })
  return entries


def _addon_files(root):
  files = {}
  addons = _join(root, 'fast/addons')
  for name in _subdirs(addons):
    for rel_path, full in walk_tree(os.path.join(addons, name)).items():
      if _is_terraform(rel_path) and not os.path.islink(full):
        files[f'fast/addons/{name}/{rel_path}'] = full
  return files


def _code_only(text):
  """Terraform text without comments, license headers or blank lines."""
  lines = []
  for line in text.splitlines():
    stripped = line.strip()
    if stripped and not stripped.startswith(('#', '//', '/*', '*')):
      lines.append(stripped)
  return '\n'.join(lines)


def addon_copies(ctx, results):
  """Customer stage files copied from an upstream add-on.

  Add-ons (fast/addons) are enabled by copying or linking their files into
  a stage. A copy is the customer's file, so apply keeps it: report which
  add-on it came from and whether upstream changed that add-on since.
  """
  base_files = _addon_files(ctx.base_cat['root'])
  if not base_files:
    return []
  target_root = ctx.target_cat['root']
  texts = {p: _read_text(f) for p, f in base_files.items()}
  codes = {p: _code_only(t) for p, t in texts.items()}
  copies = []
  for r in results:
    if (r.category != 'customer-added' or r.kind != 'terraform' or r.link or
        _in_module_mapping(ctx, r.path)):
      continue
    full = _join(ctx.repo, r.path)
    if os.path.islink(full) or not os.path.isfile(full):
      continue
    text = _code_only(_read_text(full))
    if not text:
      continue
    best = (0.0, None)
    for path, addon_text in codes.items():
      matcher = difflib.SequenceMatcher(None, text, addon_text, autojunk=False)
      if matcher.real_quick_ratio() < ADDON_MATCH:
        continue
      if matcher.quick_ratio() < ADDON_MATCH:
        continue
      score = matcher.ratio()
      if score > best[0]:
        best = (score, path)
    if best[0] < ADDON_MATCH:
      continue
    path = best[1]
    target_file = _join(target_root, path)
    if not os.path.isfile(target_file):
      status = 'removed upstream'
      changed = None
    else:
      target_text = _read_text(target_file)
      if target_text == texts[path]:
        status = 'unchanged upstream'
        changed = 0
      else:
        status = 'changed upstream'
        diff = difflib.unified_diff(texts[path].splitlines(),
                                    target_text.splitlines(), lineterm='', n=0)
        changed = sum(1 for line in diff
                      if line[:1] in '+-' and line[:3] not in ('+++', '---'))
    copies.append({
        'file': r.path,
        'addon': path.split('/')[2],
        'addon_file': path,
        'similarity': round(best[0], 2),
        'status': status,
        'changed_lines': changed,
    })
  return copies


def repo_hygiene(ctx, by_path=None):
  """Symlinks and committed files that make the repository fragile.

  Paths that also exist in the base or target release are upstream's
  (sample login configs, dataset aliases) and are not reported.
  """
  by_path = by_path or {}

  def upstream(path):
    result = by_path.get(path)
    return result is not None and bool(result.base_path or result.target_path)

  def upstream_link(path):
    result = by_path.get(path)
    return result is not None and result.category in UPSTREAM_CONTENT

  linked = {l['path'] for l in ctx.linked_repos}
  broken, absolute = [], []
  for link in ctx.scan.links:
    if link['path'] in linked or upstream_link(link['path']):
      continue
    entry = {'path': link['path'], 'target': link['target']}
    if link['broken']:
      broken.append(entry)
    elif link['absolute']:
      absolute.append(entry)
  generated = []
  if shutil.which('git'):
    proc = git(['-C', ctx.repo, 'ls-files', '-z'], check=False)
    if proc.returncode == 0:
      top = git(['-C', ctx.repo, 'rev-parse', '--show-prefix'], check=False)
      prefix = top.stdout.decode().strip() if top.returncode == 0 else ''
      for name in proc.stdout.decode('utf-8', 'replace').split('\0'):
        if name and GENERATED_RE.search(name):
          rel = name[len(prefix):] if name.startswith(prefix) else name
          if not upstream(rel):
            generated.append(rel)
  return {
      'broken_links': broken,
      'absolute_links': absolute,
      'generated_tracked': sorted(generated),
  }


def missing_module_roots(calls, repo):
  """Groups local sources that point to a missing folder by their root.

  When every missing source shares a root (for example
  `../../tf-modules/<name>`), the modules are usually a separate checkout
  that belongs at that path.
  """
  roots = collections.defaultdict(list)
  for call in calls:
    if call.get('problem') != 'missing':
      continue
    target = posixpath.normpath(
        posixpath.join(posixpath.dirname(call['file']), call['source']))
    roots[posixpath.dirname(target) or target].append(call['file'])
  hints = []
  for root, files in sorted(roots.items(), key=lambda kv: -len(kv[1])):
    hints.append({
        'root': root,
        'expected_path': _join(os.path.abspath(repo), root),
        'calls': len(files),
        'ignored': _git_ignored(repo, root),
        'exists': os.path.lexists(_join(repo, root)),
    })
  return hints


def breaking_change_impact(changes, interface_hits, stage_variables_):
  """Annotates relevant breaking changes with what they hit in this repo."""
  hits_by_module = collections.Counter(h['module'] for h in interface_hits)
  for change in changes:
    if not change['relevant']:
      continue
    reason = change['reason']
    if reason.startswith('module '):
      name = reason.split(' ', 1)[1]
      count = hits_by_module.get(name, 0)
      change['impact'] = (f'{count} of your module call(s) affected'
                          if count else
                          'no direct call from your own code (upstream code '
                          'is updated by apply); check factory data and '
                          'tfvars that feed this module')
    elif reason.startswith('stage '):
      name = reason.split(' ', 1)[1]
      stage = [s for s in stage_variables_ if s['upstream'] == name]
      change['impact'] = ('stage variables change: see STAGE VARIABLES'
                          if stage else 'stage code is updated by apply')
    else:
      change['impact'] = 'applies to every stage'
  return changes


def build_plan(ctx):
  """Returns (plan dict, [FileResult])."""
  exclusions = collections.defaultdict(set)
  for m in ctx.mappings:
    for other in ctx.mappings:
      if other is not m and other.customer != m.customer and _inside(
          other.customer, m.customer):
        prefix = len(m.customer) + 1 if m.customer else 0
        exclusions[m.customer].add(other.customer[prefix:])
  results = []
  seen = set()
  for m in ctx.mappings:
    for r in diff_mapping(ctx, m, exclusions[m.customer]):
      if r.path not in seen:
        seen.add(r.path)
        results.append(r)
  pair_renames(ctx, results)
  by_path = {r.path: r for r in results}
  summary = collections.Counter(r.category for r in results)
  marker_only = collections.Counter(
      r.category for r in results if r.marker_only)

  stage_names = {m.name for m in ctx.mappings if m.kind == 'stage'}
  module_names = referenced_modules(ctx)
  # Changelog scopes name grouped modules by their group folder too.
  module_names |= {n.split('/')[0] for n in module_names if '/' in n}
  base_v, target_v = _version(ctx.base_version), _version(ctx.target_version)
  upgrading_path = _join(ctx.target_cat['root'], 'fast/stages/UPGRADING.md')
  upgrading = []
  if os.path.isfile(upgrading_path):
    upgrading = release_notes.upgrading_notes(_read_text(upgrading_path),
                                              base_v, target_v)
  stage_mappings = [m for m in ctx.mappings if m.kind == 'stage' and m.target]
  moved = []
  for entry in release_notes.moved_files(ctx.target_cat['root'],
                                         {m.target for m in stage_mappings},
                                         base_v, target_v):
    for m in stage_mappings:
      if m.target == entry['stage']:
        moved.append({
            'file':
                entry['path'],
            'copy_to':
                f'{m.customer}/{entry["file"]}'
                if m.customer else entry['file'],
        })
  providers_b = provider_constraints(ctx.base_cat['root'])
  providers_t = provider_constraints(ctx.target_cat['root'])
  providers = [{
      'name': k,
      'base': providers_b[k],
      'target': providers_t[k]
  } for k in providers_b if providers_b[k] != providers_t[k]]

  fabric_calls = [
      c for c in ctx.scan.calls if c['kind'] == 'git' and c.get('fabric')
  ]
  refs = collections.Counter(c.get('ref') or '(none)' for c in fabric_calls)
  bumpable = sum(1 for c in fabric_calls if c.get('ref') == ctx.base_version)

  state = git_state(ctx.repo)
  warnings = list(ctx.warnings)
  if state.get('git') and state['dirty']:
    warnings.append(f'{state["dirty"]} tracked file(s) have uncommitted '
                    'changes: apply will refuse until they are committed')
  if not factory_data.available():
    warnings.append('factory data checks skipped: install ' +
                    ' and '.join(factory_data.missing_dependencies()))
  if not ctx.mappings:
    warnings.append('no folder could be mapped to an upstream stage or '
                    'module: is this a FAST repository?')
  notes = []
  locks = [
      f for f in ctx.scan.lock_files if any(
          _inside(f, m.customer) for m in stage_mappings)
  ]
  if locks:
    notes.append('lock files present: run `terraform init -upgrade` in ' +
                 ', '.join(sorted({posixpath.dirname(f) or '.'
                                   for f in locks})))
  new_stages = sorted(
      set(ctx.target_cat['stages']) - set(ctx.base_cat['stages']))
  if new_stages:
    notes.append('stages new in the target (not added automatically): ' +
                 ', '.join(new_stages))
  gone = sorted(f'{m.customer or "."} ({m.name})' for m in ctx.mappings
                if m.kind == 'stage' and m.base and not m.target)
  if gone:
    warnings.append('stages that no longer exist in the target: ' +
                    ', '.join(gone) + '. Their files show as upstream '
                    'deletions; upgrades across removed stages (such as the '
                    'legacy stages retired in v44/v45) are not directly '
                    'supported: read fast/stages/UPGRADING.md first')
  if upstream_history(ctx.repo, ctx.base_version):
    notes.append(f'this repository contains the upstream {ctx.base_version} '
                 'tag in its history: a plain `git merge '
                 f'{ctx.target_version}` may be simpler than apply')
  if ctx.template:
    notes.append(f'Fabric modules are sourced from git ({ctx.template}): '
                 'upstream local sources are rewritten to that form')
  for linked in ctx.linked_repos:
    notes.append(f'{linked["path"]} is a {linked["kind"]} (a separate git '
                 'repository): apply writes there too and checks it is clean; '
                 'commit the upgrade in both repositories')
  raw = sorted(r.path for r in results if r.upstream_sources)
  if raw:
    notes.append(f'{len(raw)} file(s) keep upstream module sources (for '
                 'example ../../../modules): apply takes the target as is, '
                 'see UNRESOLVED MODULE SOURCES AFTER UPGRADE')

  stage_vars = stage_variables(ctx)
  interface = module_interface(ctx, by_path)
  breaking = breaking_change_impact(
      release_notes.breaking_changes(ctx.releases, stage_names, module_names),
      interface, stage_vars)

  plan = {
      'tool': {
          'name': 'fast_upgrade.py',
          'digest': provenance.tool_digest()
      },
      'repo': {
          'path': ctx.repo,
          'git': state,
          'detected_version': ctx.detected,
          'confidence': ctx.confidence,
          'data_paths': list(ctx.data_paths),
      },
      'base': _tree_info(ctx.base_cat),
      'target': _tree_info(ctx.target_cat),
      'warnings': warnings,
      'mappings': [dataclasses.asdict(m) for m in ctx.mappings],
      'customer_only': {
          'stages': ctx.customer_stages,
          'modules': ctx.customer_modules
      },
      # Folders that look like FAST stages but match none well enough: ask
      # the user, then plan again with --map FOLDER=STAGE (or =none).
      'stage_candidates': ctx.matching['candidates'],
      'user_mappings': ctx.matching['user'],
      'summary': dict(summary),
      'marker_only': dict(marker_only),
      'files': [dataclasses.asdict(r) for r in results],
      'breaking_changes': breaking,
      'fast_changes': release_notes.fast_changes(ctx.releases),
      'upgrading_notes': upgrading,
      'moved_files': moved,
      'providers': providers,
      'version_pins': version_pins_report(ctx, by_path, providers_t),
      'stage_variables': stage_vars,
      'module_interface': interface,
      'module_renames': [{
          'old': old,
          'new': new,
          'used': old in module_names
      } for old, new in sorted(ctx.renames.items())],
      'schema_changes': schema_changes(ctx, results),
      'data_impact': data_impact(ctx, results),
      'git_refs': {
          'refs': dict(refs),
          'bumpable': bumpable,
          'template': ctx.template
      },
      'unresolved_sources': unresolved_sources(ctx, results),
      'upstream_sources': raw,
      'linked_repos': ctx.linked_repos,
      'missing_module_roots': missing_module_roots(ctx.scan.calls, ctx.repo),
      'addon_copies': addon_copies(ctx, results),
      'hygiene': repo_hygiene(ctx, by_path),
      'notes': notes,
  }
  plan.update(report.build_findings(plan))
  return plan, results


# --------------------------------------------------------------------------
# Apply
# --------------------------------------------------------------------------


def _safe_target(repo, rel_path, extra_roots=()):
  """Returns the absolute path for rel_path, refusing to escape the repo.

  `extra_roots` are real paths of linked module repositories that apply
  has already checked; writes through their symlinks are allowed.
  """
  path = os.path.normpath(_join(repo, rel_path))
  parent = os.path.realpath(os.path.dirname(path))
  for root in (os.path.realpath(repo),) + tuple(extra_roots):
    if parent == root or parent.startswith(root + os.sep):
      return path
  raise Refused(f'{rel_path} resolves outside the repository')


def _write(path, data=None, link=None, executable=False):
  os.makedirs(os.path.dirname(path), exist_ok=True)
  if os.path.lexists(path) and (link is not None or os.path.islink(path)):
    os.unlink(path)
  if link is not None:
    os.symlink(link, path)
    return
  with open(path, 'wb') as f:
    f.write(data)
  mode = os.stat(path).st_mode
  if executable:
    os.chmod(path, mode | 0o111)


def _prune_empty_dirs(repo, path):
  """Removes folders left empty by deleting `path`, up to the repository."""
  real_repo = os.path.realpath(repo)
  parent = os.path.dirname(path)
  while True:
    real = os.path.realpath(parent)
    if not real.startswith(real_repo + os.sep):
      return
    try:
      os.rmdir(parent)
    except OSError:
      return
    parent = os.path.dirname(parent)


def merge_file(current, base, other, labels):
  """Runs `git merge-file`. Returns (merged bytes, conflicts) or (None, -1)."""
  if not shutil.which('git'):
    return None, -1
  with tempfile.TemporaryDirectory(prefix='fast-upgrade-') as tmp:
    paths = []
    for name, data in (('current', current), ('base', base), ('other', other)):
      path = os.path.join(tmp, name)
      with open(path, 'wb') as f:
        f.write(data.replace(b'\r\n', b'\n'))
      paths.append(path)
    args = ['merge-file', '-p', '--diff3']
    for label in labels:
      args += ['-L', label]
    proc = git(args + paths, check=False)
  if 0 <= proc.returncode <= 127:
    return proc.stdout, proc.returncode
  return None, -1


def _manual_hint(result):
  if result.blocked:
    return result.blocked
  hints = {
      'conflict-added': 'you and upstream both added this file: compare '
                        'with the target version',
      'conflict-deleted': 'upstream removed this file you changed: port your '
                          'change or delete it',
      'conflict-customer-deleted': 'you removed this file and upstream '
                                   'changed it: confirm it should stay removed',
      'conflict': 'binary file or symlink changed on both sides',
  }
  hint = hints.get(result.category, 'review manually')
  if result.marker_only:
    hint += ' (upstream change is only a version marker)'
  return hint


def run_apply(ctx, results, dry_run=False, include_deletes=False, bump=False,
              copy_moved=False, allow_dirty=False, moved=()):
  state = git_state(ctx.repo)
  if not allow_dirty:
    if not state.get('git'):
      raise Refused(f'{ctx.repo} is {state.get("reason")}: changes could not '
                    'be reviewed or reverted (use --allow-dirty to proceed '
                    'anyway)')
    if state['dirty']:
      raise Refused(f'{state["dirty"]} tracked file(s) have uncommitted '
                    'changes: commit or stash them first (or --allow-dirty)')
    for linked in ctx.linked_repos:
      if not linked.get('writes', True):
        continue
      linked_state = linked['git']
      if not linked_state.get('git'):
        raise Refused(f'{linked["path"]} ({linked["kind"]} to '
                      f'{linked["target"]}) is '
                      f'{linked_state.get("reason")}: changes there could '
                      'not be reviewed or reverted (or --allow-dirty)')
      if linked_state['dirty']:
        raise Refused(f'{linked["path"]} is a separate repository with '
                      f'{linked_state["dirty"]} uncommitted tracked file(s): '
                      'commit or stash them first (or --allow-dirty)')
  extra_roots = tuple(l['target']
                      for l in ctx.linked_repos
                      if l['outside'] and l.get('writes', True))
  by_path = {r.path: r for r in results}
  labels = [
      'customer', f'base {ctx.base_version}', f'target {ctx.target_version}'
  ]
  records = []
  written = set()

  def record(result, action, outcome, detail=None):
    entry = {
        'path': result.path,
        'category': result.category,
        'action': action,
        'result': outcome,
        'detail': detail
    }
    for linked in ctx.linked_repos:
      if _inside(result.path, linked['path']):
        entry['repository'] = linked['path']
    records.append(entry)

  for r in results:
    if r.category in ('unchanged', 'already-updated', 'customer-changed',
                      'customer-added', 'customer-deleted'):
      continue
    if r.blocked:
      record(r, 'manual', 'manual', r.blocked)
      continue
    if r.sample_data:
      record(
          r, 'skip', 'skipped', 'upstream sample dataset you do not keep: '
          'compare with your own data')
      continue
    path = _safe_target(ctx.repo, r.path, extra_roots)
    if r.category in ('upstream-changed', 'upstream-added'):
      old = by_path.get(r.renamed_from) if r.renamed_from else None
      if old is not None and old.category == 'conflict-deleted':
        current = _read_bytes(_join(ctx.repo, old.path))
        base = ctx.upstream_bytes('base', old.base_path, r.path)
        other = ctx.upstream_bytes('target', r.target_path, r.path)
        merged, conflicts = merge_file(current, base, other, labels)
        if merged is None:
          record(r, 'merge-renamed', 'manual',
                 f'port your changes from {old.path}')
          continue
        if not dry_run:
          _write(path, merged)
        written.add(r.path)
        record(r, 'merge-renamed', 'conflict' if conflicts else 'merged',
               f'your changes from {old.path} merged into the renamed file')
        continue
      if r.link:
        link = os.readlink(_join(ctx.target_cat['root'], r.target_path))
        if not dry_run:
          _write(path, link=link)
      else:
        target_path = _join(ctx.target_cat['root'], r.target_path)
        data = ctx.upstream_bytes('target', r.target_path, r.path)
        if not dry_run:
          _write(path, data, executable=os.access(target_path, os.X_OK))
      written.add(r.path)
      record(r, 'write', 'written')
    elif r.category == 'conflict':
      if r.binary or r.link:
        record(r, 'manual', 'manual', _manual_hint(r))
        continue
      current = _read_bytes(path)
      base = ctx.upstream_bytes('base', r.base_path, r.path)
      other = ctx.upstream_bytes('target', r.target_path, r.path)
      merged, conflicts = merge_file(current, base, other, labels)
      if merged is None:
        record(r, 'merge', 'manual', 'git merge-file unavailable or failed')
        continue
      if not dry_run:
        _write(path, merged, executable=os.access(path, os.X_OK))
      written.add(r.path)
      record(r, 'merge', 'conflict' if conflicts else 'merged',
             f'{conflicts} conflict block(s)' if conflicts else None)
    elif r.category == 'upstream-deleted' or (r.category == 'conflict-deleted'
                                              and r.renamed_to):
      if include_deletes:
        if not dry_run:
          os.unlink(path)
          _prune_empty_dirs(ctx.repo, path)
        record(r, 'delete', 'deleted',
               f'renamed to {r.renamed_to}' if r.renamed_to else None)
      else:
        record(r, 'delete', 'kept', 'rerun with --include-deletes to remove')
    else:
      record(r, 'manual', 'manual', _manual_hint(r))

  bumped = []
  if bump:
    bumped = bump_refs(ctx, written, dry_run)
  copied = []
  if copy_moved:
    for entry in moved:
      dest = _safe_target(ctx.repo, entry['copy_to'])
      if os.path.lexists(dest):
        copied.append({'file': entry['copy_to'], 'result': 'exists'})
        continue
      if not dry_run:
        _write(dest, _read_bytes(_join(ctx.target_cat['root'], entry['file'])))
      copied.append({'file': entry['copy_to'], 'result': 'copied'})
  counts = collections.Counter(r['result'] for r in records)
  touched = collections.Counter(
      r['repository']
      for r in records
      if r.get('repository') and r['result'] not in ('kept', 'manual'))
  return {
      'tool': {
          'name': 'fast_upgrade.py',
          'digest': provenance.tool_digest()
      },
      'dry_run': dry_run,
      'repo': {
          'path': ctx.repo,
          'git': state
      },
      'base': _tree_info(ctx.base_cat),
      'target': _tree_info(ctx.target_cat),
      'counts': dict(counts),
      'records': records,
      'linked_repos': [{
          'path': l['path'],
          'kind': l['kind'],
          'target': l['target'],
          'files': touched.get(l['path'], 0),
      } for l in ctx.linked_repos],
      'refs_bumped': bumped,
      'moved_copied': copied,
      'moved_pending': [] if copy_moved else list(moved),
  }


def bump_refs(ctx, skip, dry_run):
  """Rewrites `?ref=<base>` to the target in customer git sources."""
  files = sorted({
      c['file']
      for c in ctx.scan.calls
      if c['kind'] == 'git' and c.get('fabric') and
      c.get('ref') == ctx.base_version and c['file'] not in skip
  })
  pattern = re.compile(r'([?&]ref=)' + re.escape(ctx.base_version) + r'(?=$|&)')
  changes = []
  for rel_path in files:
    path = _safe_target(ctx.repo, rel_path)
    with open(path, 'r', encoding='utf-8', newline='') as f:
      text = f.read()
    replacements = []
    for call in hcl_lite.module_calls(text):
      if hcl_lite.classify_source(call.source) != 'git':
        continue
      url, _, ref = hcl_lite.parse_git_source(call.source)
      if ref == ctx.base_version and ctx.fabric_re.search(url):
        new = pattern.sub(r'\g<1>' + ctx.target_version, call.source)
        replacements.append((call.source_start, call.source_end, new))
    if replacements and not dry_run:
      with open(path, 'w', encoding='utf-8', newline='') as f:
        f.write(hcl_lite.replace_spans(text, replacements))
    changes.append({'file': rel_path, 'sources': len(replacements)})
  return changes


# --------------------------------------------------------------------------
# Releases, fetch, detect, changelog, check-data
# --------------------------------------------------------------------------


def list_releases(url):
  proc = git(['ls-remote', '--tags', '--refs', url])
  versions = set()
  for line in proc.stdout.decode('utf-8', errors='replace').splitlines():
    m = re.search(r'refs/tags/(v\d+\.\d+\.\d+)$', line)
    if m:
      versions.add(_version(m.group(1)))
  return [
      release_notes.format_version(v) for v in sorted(versions, reverse=True)
  ]


def default_cache_dir():
  if os.environ.get('FAST_UPGRADE_CACHE'):
    return os.environ['FAST_UPGRADE_CACHE']
  base = os.environ.get('XDG_CACHE_HOME') or os.path.join(
      os.path.expanduser('~'), '.cache')
  return os.path.join(base, 'fast-upgrade')


def _escapes(name):
  """True if an archive path is absolute or climbs out of the archive root."""
  norm = posixpath.normpath(name)
  return posixpath.isabs(name) or norm == '..' or norm.startswith('../')


def _unsafe_members(members):
  """Returns the names the 'data' extraction filter would refuse.

  Used on Pythons without tarfile.data_filter. The checks are lexical, so
  a member stored under another link member is refused too: that closes
  symlink chains, and git archives never contain such paths.
  """
  links = {m.name.rstrip('/') for m in members if m.issym() or m.islnk()}
  unsafe = []
  for m in members:
    name = m.name.rstrip('/')
    parts = name.split('/')
    targets = [m.name]
    if m.issym():
      targets.append(posixpath.join(posixpath.dirname(name), m.linkname))
    elif m.islnk():
      targets.append(m.linkname)
    if (m.isdev() or any(_escapes(t) for t in targets) or
        any('/'.join(parts[:i]) in links for i in range(1, len(parts)))):
      unsafe.append(m.name)
  return unsafe


def _extract(data, dest):
  try:
    with tarfile.open(fileobj=io.BytesIO(data)) as tar:
      if TAR_FILTERS:
        tar.extractall(dest, filter='data')
        return
      unsafe = _unsafe_members(tar.getmembers())
      if unsafe:
        raise UpgradeError(f'unsafe path in archive: {unsafe[0]}')
      tar.extractall(dest)  # nosec: members checked above
  except tarfile.TarError as e:
    raise UpgradeError(f'cannot extract release archive: {e}') from e


def fetch_release(version, url=UPSTREAM_URL, from_repo=None, cache_dir=None,
                  refresh=False):
  """Materializes an upstream release. Returns (path, how)."""
  if not SAFE_REF_RE.match(version) or '..' in version:
    raise UpgradeError(f'unsafe ref: {version!r}')
  cache_dir = os.path.abspath(cache_dir or default_cache_dir())
  dest = os.path.join(cache_dir, version.replace('/', '_'))
  if os.path.isdir(dest) and _is_fabric_tree(dest) and not refresh:
    return dest, 'cached'
  os.makedirs(cache_dir, exist_ok=True)
  tmp = tempfile.mkdtemp(prefix='.fetch-', dir=cache_dir)
  try:
    if from_repo:
      paths = [
          p for p in provenance.RELEASE_ENTRIES
          if git(['-C', from_repo, 'cat-file', '-e', f'{version}:{p}'],
                 check=False).returncode == 0
      ]
      if 'fast' not in paths or 'modules' not in paths:
        raise UpgradeError(f'{version} is not a tag of {from_repo} with fast/ '
                           'and modules/ (run git fetch --tags there?)')
      proc = git(['-C', from_repo, 'archive', '--format=tar', version, '--'] +
                 paths)
      _extract(proc.stdout, tmp)
      how = f'git archive of {version} from {os.path.abspath(from_repo)}'
    else:
      git([
          'clone', '--quiet', '--depth', '1', '--branch', version,
          '--filter=blob:none', '--sparse', url, tmp
      ])
      git(['-C', tmp, 'sparse-checkout', 'set', 'fast', 'modules'])
      shutil.rmtree(os.path.join(tmp, '.git'), ignore_errors=True)
      how = f'git clone of {version} from {url}'
    if not _is_fabric_tree(tmp):
      raise UpgradeError(f'{version} does not contain fast/stages and modules')
    if os.path.isdir(dest):
      shutil.rmtree(dest)
    os.replace(tmp, dest)
  except BaseException:
    shutil.rmtree(tmp, ignore_errors=True)
    raise
  return dest, how


def detect(repo, fabric_source=DEFAULT_FABRIC_SOURCE):
  scan = scan_repo(repo, re.compile(fabric_source))
  version, confidence, breakdown = version_consensus(scan.markers)
  kinds = collections.Counter(c['kind'] for c in scan.calls)
  problems = [{
      'file': c['file'],
      'line': c['line'],
      'source': c['source'],
      'problem': c['problem']
  } for c in scan.calls if c.get('problem')]
  roots = collections.Counter(posixpath.dirname(d) for d in scan.module_dirs)
  fabric_refs = collections.Counter(
      c.get('ref') or '(none)'
      for c in scan.calls
      if c['kind'] == 'git' and c.get('fabric'))
  warnings = []
  if confidence == 'mixed':
    warnings.append('version markers disagree (mixed releases): ' +
                    _breakdown_text(breakdown))
  if not version:
    warnings.append('no FAST or Fabric release marker found: ask which '
                    'release this repository was built from')
  if not scan.stage_dirs:
    warnings.append('no stage folder found by marker or name: plan will try '
                    'to match folders by content')
  missing_roots = missing_module_roots(scan.calls, scan.root)
  for hint in missing_roots:
    if not hint['exists'] and hint['calls'] > 1:
      warnings.append(
          f'{hint["calls"]} module sources point to the missing folder '
          f'{hint["root"]}' +
          (' (git-ignored: a separate checkout?)' if hint['ignored'] else '') +
          f': check out or link the modules at {hint["expected_path"]} '
          'before planning')
  state = git_state(scan.root)
  return {
      'tool': {
          'name': 'fast_upgrade.py',
          'digest': provenance.tool_digest()
      },
      'repo': scan.root,
      'git': state,
      'version': {
          'detected': version,
          'confidence': confidence,
          'markers': breakdown
      },
      'stages': [{
          'path': d,
          'marker': info['marker'],
          'found_by': info['reason']
      } for d, info in sorted(scan.stage_dirs.items())],
      'modules': {
          'roots': dict(roots),
          'local_dirs': len(scan.module_dirs),
          'calls': dict(kinds),
          'problems': problems,
          'missing_roots': missing_roots,
      },
      'fabric_git_refs': dict(fabric_refs),
      'factory': {
          'yaml_files': len(scan.yaml_files),
          'schema_files': len(scan.schema_files)
      },
      'tfvars_files': scan.tfvars_files,
      'lock_files': scan.lock_files,
      'upstream_history': upstream_history(scan.root, version),
      'warnings': warnings,
  }


def _inside_module_dir(rel_file, module_names, stage_dirs):
  """True if a file sits in a folder that looks like a vendored module."""
  parts = posixpath.dirname(rel_file).split('/')
  for i in range(len(parts), 0, -1):
    d = '/'.join(parts[:i])
    if d in stage_dirs:
      return False
    if module_key(d, module_names)[0]:
      return True
  return False


def changelog(upstream_dir, base, target, repo=None,
              fabric_source=DEFAULT_FABRIC_SOURCE):
  base_v, target_v = _version(base), _version(target)
  if not base_v or not target_v:
    raise UpgradeError('--from and --to must be releases like v57.0.0')
  if target_v <= base_v:
    raise UpgradeError('--to must be newer than --from')
  path = _join(os.path.abspath(upstream_dir), 'CHANGELOG.md')
  if not os.path.isfile(path):
    raise UpgradeError(f'no CHANGELOG.md in {upstream_dir}')
  releases = release_notes.select_releases(
      release_notes.parse_changelog(_read_text(path)), base_v, target_v)
  stages = modules = None
  if repo:
    cat = catalog(upstream_dir)
    scan = scan_repo(repo, re.compile(fabric_source))
    stages = set()
    for d in scan.stage_dirs:
      name = posixpath.basename(d)
      if name in cat['stages']:
        stages.add(name)
      else:
        stages |= {n for n in cat['stages'] if name.startswith(n + '-')}
    names = set(cat['modules'])
    modules = set()
    for call in scan.calls:
      if _inside_module_dir(call['file'], names, scan.stage_dirs):
        continue
      if call['kind'] == 'local' and call.get('resolved'):
        name = module_key(call['resolved'], names)[0]
      else:
        name = git_module_name(call)
      if name:
        modules.add(name)
    start = [cat['stages'][s] for s in stages]
    start += [cat['modules'][n] for n in modules if n in cat['modules']]
    modules |= module_closure(cat['root'], start, cat['modules'])
    modules |= {n.split('/')[0] for n in modules if '/' in n}
  upgrading_path = _join(os.path.abspath(upstream_dir),
                         'fast/stages/UPGRADING.md')
  notes = []
  if os.path.isfile(upgrading_path):
    notes = release_notes.upgrading_notes(_read_text(upgrading_path), base_v,
                                          target_v)
  return {
      'tool': {
          'name': 'fast_upgrade.py',
          'digest': provenance.tool_digest()
      },
      'upstream':
          os.path.abspath(upstream_dir),
      'from':
          base,
      'to':
          target,
      'releases': [r['version'] for r in releases],
      'filtered_by_repo':
          bool(repo),
      'breaking_changes':
          release_notes.breaking_changes(releases, stages, modules),
      'fast_changes':
          release_notes.fast_changes(releases),
      'module_renames':
          release_notes.declared_module_renames(releases),
      'upgrading_notes':
          notes,
  }


def check_data(paths, schema_paths=()):
  if not factory_data.available():
    raise UpgradeError('check-data needs ' +
                       ' and '.join(factory_data.missing_dependencies()))
  for path in list(paths) + list(schema_paths):
    if not os.path.exists(path):
      raise UpgradeError(f'path not found: {path}')
  index = factory_data.SchemaIndex(
      factory_data.find_schema_files(
          list(schema_paths) or list(paths), IGNORED_DIRS))
  results = [
      factory_data.check_file(p, index)
      for p in factory_data.find_yaml_files(paths, IGNORED_DIRS)
  ]
  counts = collections.Counter(r['status'] for r in results)
  return {
      'tool': {
          'name': 'fast_upgrade.py',
          'digest': provenance.tool_digest()
      },
      'paths': [os.path.abspath(p) for p in paths],
      'counts':
          dict(counts),
      'files': [
          r for r in results
          if r['status'] in ('invalid', 'unresolved', 'validator-error')
      ],
  }


# --------------------------------------------------------------------------
# Rendering
# --------------------------------------------------------------------------


def _limited(items, limit):
  if not limit or len(items) <= limit:
    return items, 0
  return items[:limit], len(items) - limit


def _section(lines, title, items, limit, fmt):
  if not items:
    return
  lines.append('')
  lines.append(f'{title} ({len(items)})')
  shown, more = _limited(items, limit)
  for item in shown:
    lines.append('  ' + fmt(item))
  if more:
    lines.append(f'  ... {more} more (--limit 0 or --json for all)')


def _header(command, tool):
  return f'fast-upgrade {command} | tools {tool["digest"]}'


def render_plan(plan, limit):
  lines = [_header('plan', plan['tool'])]
  repo = plan['repo']
  lines.append(f'repo    {repo["path"]}  [{_git_summary(repo["git"])}]  '
               f'detected {repo["detected_version"] or "unknown"} '
               f'({repo["confidence"]})')
  for key in ('base', 'target'):
    tree = plan[key]
    lines.append(f'{key:<8}{tree["path"]}  {tree["version"]}  '
                 f'tree {tree["digest"]}')
  if 'readiness' in plan:
    lines.extend(report.render_findings(plan, limit))
  _section(lines, 'WARNINGS', plan['warnings'], 0, lambda w: f'- {w}')
  mappings = plan['mappings']
  _section(
      lines, 'MAPPED FOLDERS', mappings, limit,
      lambda m: f'{m["kind"]:<7}{m["customer"] or ".":<44} <- {m["name"]} '
      f'({m["match"]})')
  owned = plan['customer_only']
  if owned['stages'] or owned['modules']:
    lines.append('  yours (no upstream match): ' +
                 ', '.join(owned['stages'] + owned['modules']))
  for u in plan.get('user_mappings', []):
    if u['stage'] is None:
      lines.append(
          f'  set by user: {u["folder"] or "."} is yours (--map =none)')
    elif u['low_similarity']:
      lines.append(f'  set by user: {u["folder"] or "."} <- {u["stage"]}, '
                   f'only {round(u["score"] * 100)}% of its files match: '
                   'review every merge')
  candidates = plan.get('stage_candidates', [])
  if candidates:
    lines.append('')
    lines.append(f'STAGE CANDIDATES ({len(candidates)}): which FAST stage is '
                 'each folder based on?')
    for c in candidates:
      guesses = ', '.join(
          f'{g["stage"]} (files {round(g["files"] * 100)}%, variables '
          f'{round(g["variables"] * 100)}%' +
          (', by name)' if g['by_name'] else ')') for g in c['guesses'])
      lines.append(f'  {c["folder"] or "."}  [{c["reason"]}]  guesses: '
                   f'{guesses}')
    lines.append('  -> plan again with --map <folder>=<stage> for each one, or '
                 '--map <folder>=none if it is your own; pass the same --map '
                 'flags to apply.')
  lines.append('')
  lines.append('FILE ACTIONS')
  for category, help_text in CATEGORY_HELP.items():
    count = plan['summary'].get(category, 0)
    if not count:
      continue
    marker = plan['marker_only'].get(category, 0)
    extra = f' ({marker} version-marker only)' if marker else ''
    lines.append(f'  {category:<26}{count:>6}  {help_text}{extra}')
  files = plan['files']

  def flags(f):
    out = []
    if f['marker_only']:
      out.append('marker only')
    if f['layout_adjusted']:
      out.append('layout adjusted')
    if f['renamed_from']:
      out.append(f'renamed from {f["renamed_from"]}')
    if f['renamed_to']:
      out.append(f'renamed to {f["renamed_to"]}')
    return f' ({", ".join(out)})' if out else ''

  _section(lines, 'CONFLICTS',
           [f for f in files if f['category'] == 'conflict'], limit,
           lambda f: f'{f["path"]} [{f["kind"]}]{flags(f)}')
  _section(
      lines, 'MANUAL REVIEW',
      [f for f in files if f['category'] in MANUAL_CATEGORIES or f['blocked']],
      limit, lambda f: f'{f["path"]} [{f["category"]}]: '
      f'{_manual_hint(FileResult(**f))}')
  _section(lines, 'UPSTREAM DELETIONS',
           [f for f in files if f['category'] == 'upstream-deleted'], limit,
           lambda f: f'{f["path"]}{flags(f)}')
  relevant = [b for b in plan['breaking_changes'] if b['relevant']]
  skipped = len(plan['breaking_changes']) - len(relevant)
  _section(
      lines, 'BREAKING CHANGES (relevant to this repository)', relevant, limit,
      lambda b: f'{b["version"]} [{b["reason"]}] {b["text"]}' +
      (f'\n    impact: {b["impact"]}' if b.get('impact') else ''))
  if skipped:
    lines.append(f'  ({skipped} more affect stages or modules not in use; '
                 'see --json)')
  _section(
      lines, 'UPGRADING NOTES', plan['upgrading_notes'], 0,
      lambda n: f'{", ".join(n["versions"])}: ' + n['text'].replace(
          '\n', '\n    '))
  _section(lines, 'MOVED BLOCKS (copy before terraform plan)',
           plan['moved_files'], 0, lambda m: f'{m["file"]} -> {m["copy_to"]}')
  _section(lines, 'PROVIDERS (run terraform init -upgrade)', plan['providers'],
           0, lambda p: f'{p["name"]}: {p["base"]} -> {p["target"]}')

  def pin_line(p):
    pins = ', '.join(
        f'{x["name"]} "{x["constraint"]}"' +
        (f' (target needs "{x["target"]}")' if x['allows_target'] is
         False else '') for x in p['pins'])
    stamp = f'; stamp {p["marker"]}' if p['stale_marker'] else ''
    lead = 'BLOCKS INIT ' if p['blocks_init'] else ''
    return f'{lead}{p["file"]} [{p["category"]}]: {pins or "no pins"}{stamp}'

  _section(lines, 'VERSION PINS IN YOUR FILES (kept by apply)',
           plan.get('version_pins', []), limit, pin_line)

  def stage_line(s):
    parts = []
    for key, label in (('removed', 'removed'),
                       ('added_required', 'new required'), ('default_removed',
                                                            'default removed'),
                       ('tfvars_set_removed', 'SET IN TFVARS but removed')):
      if s[key]:
        parts.append(f'{label}: {", ".join(s[key])}')
    if s['type_changed']:
      parts.append('type changed: ' +
                   ', '.join(t['name'] for t in s['type_changed']))
    if s['tfvars_unreadable']:
      parts.append('unreadable tfvars: ' + ', '.join(s['tfvars_unreadable']))
    return f'{s["stage"]}: ' + '; '.join(parts)

  _section(lines, 'STAGE VARIABLES', plan['stage_variables'], limit, stage_line)
  _section(lines, 'YOUR MODULE CALLS', plan['module_interface'], limit,
           lambda h: f'{h["call"]} -> {h["module"]}: {h["issue"]}')
  _section(
      lines, 'MODULE RENAMES', plan['module_renames'], 0,
      lambda r: f'{r["old"]} -> {r["new"]}' + (' (in use)'
                                               if r['used'] else ''))

  def schema_line(s):
    parts = []
    for key in ('removed', 'required_added', 'type_changed', 'added'):
      if s[key]:
        shown, more = _limited(s[key], 4)
        tail = f' +{more}' if more else ''
        parts.append(f'{key.replace("_", " ")} {len(s[key])}: '
                     f'{", ".join(shown)}{tail}')
    return f'{s["path"]}: ' + '; '.join(parts)

  _section(lines, 'SCHEMA CHANGES', plan['schema_changes'], limit, schema_line)
  data = plan['data_impact']
  lines.append('')
  if 'skipped' in data:
    lines.append(f'FACTORY DATA: skipped ({data["skipped"]})')
  else:
    counts = ', '.join(f'{k} {v}' for k, v in sorted(data['summary'].items()))
    lines.append(f'FACTORY DATA ({counts or "no files"})')
    shown, more = _limited(data['files'], limit)
    for f in shown:
      detail = f['errors'][0] if f.get('errors') else f.get('reason', '')
      note = f' [{f["note"]}]' if f.get('note') else ''
      lines.append(f'  {f["status"]:<14}{f["file"]}: {detail}{note}')
    if more:
      lines.append(f'  ... {more} more (--limit 0 or --json for all)')
  refs = plan['git_refs']
  if refs['refs']:
    lines.append('')
    lines.append('GIT REFS TO FABRIC ' + ', '.join(
        f'{k} x{v}' for k, v in sorted(refs['refs'].items())) +
                 (f' ({refs["bumpable"]} bumpable with apply --bump-refs)'
                  if refs['bumpable'] else ''))
  _section(lines, 'UNRESOLVED MODULE SOURCES AFTER UPGRADE',
           plan['unresolved_sources'], limit,
           lambda u: f'{u["file"]}:{u["line"]} {u["source"]}')
  _section(lines, 'FILES KEEPING UPSTREAM MODULE SOURCES',
           plan.get('upstream_sources', []), limit, lambda p: p)

  def linked_line(l):
    state = l['git']
    text = (('clean' if not state['dirty'] else f'{state["dirty"]} uncommitted')
            if state.get('git') else state.get('reason'))
    where = 'outside the repository' if l['outside'] else 'inside'
    return (f'{l["path"]} ({l["kind"]}, {where}, {l["mappings"]} mapped '
            f'folder(s)): {text}')

  _section(lines, 'LINKED REPOSITORIES', plan.get('linked_repos', []), 0,
           linked_line)
  hygiene = plan.get('hygiene') or {}
  items = ([
      f'broken link {l["path"]} -> {l["target"]}'
      for l in hygiene.get('broken_links', [])
  ] + [
      f'absolute link {l["path"]} -> {l["target"]}'
      for l in hygiene.get('absolute_links', [])
  ] + [
      f'generated file tracked in git: {p}'
      for p in hygiene.get('generated_tracked', [])
  ])
  _section(lines, 'REPOSITORY HYGIENE', items, limit, lambda i: i)
  _section(
      lines, 'ADD-ON COPIES (yours: not updated by apply)',
      plan.get('addon_copies',
               []), limit, lambda a: f'{a["file"]} ~ {a["addon_file"]} '
      f'({int(a["similarity"] * 100)}%): {a["status"]}' +
      (f', {a["changed_lines"]} line(s)' if a['changed_lines'] else ''))
  _section(lines, 'NOTES', plan['notes'], 0, lambda n: f'- {n}')
  return '\n'.join(lines)


def render_apply(result, limit):
  title = 'apply (DRY RUN: nothing written)' if result['dry_run'] else 'apply'
  lines = [_header(title, result['tool'])]
  lines.append(f'repo    {result["repo"]["path"]}  '
               f'[{_git_summary(result["repo"]["git"])}]')
  lines.append(f'upgrade {result["base"]["version"]} -> '
               f'{result["target"]["version"]}  (trees '
               f'{result["base"]["digest"]} -> {result["target"]["digest"]})')
  counts = result['counts']
  lines.append('')
  for key, text in (('written', 'upstream changes written'),
                    ('merged', 'clean 3-way merges'),
                    ('conflict', 'files with conflict markers to resolve'),
                    ('manual', 'files needing a decision'), ('deleted',
                                                             'files deleted'),
                    ('kept', 'upstream deletions not applied'),
                    ('skipped', 'upstream sample-dataset files not added')):
    if counts.get(key):
      lines.append(f'  {key:<10}{counts[key]:>6}  {text}')
  records = result['records']
  _section(
      lines, 'CONFLICT MARKERS',
      [r for r in records if r['result'] == 'conflict'], limit,
      lambda r: f'{r["path"]}' + (f' ({r["detail"]})' if r['detail'] else ''))
  _section(lines, 'MANUAL', [r for r in records if r['result'] == 'manual'],
           limit, lambda r: f'{r["path"]} [{r["category"]}]: {r["detail"]}')
  _section(lines, 'NOT DELETED', [r for r in records if r['result'] == 'kept'],
           limit, lambda r: r['path'])
  _section(lines, 'REFS BUMPED',
           [b for b in result['refs_bumped'] if b['sources']], limit,
           lambda b: f'{b["file"]} ({b["sources"]} source(s))')
  _section(lines, 'MOVED BLOCKS COPIED', result['moved_copied'], 0,
           lambda m: f'{m["file"]} ({m["result"]})')
  _section(lines, 'MOVED BLOCKS TO COPY (or rerun with --copy-moved)',
           result['moved_pending'], 0,
           lambda m: f'{m["file"]} -> {m["copy_to"]}')
  _section(
      lines, 'LINKED REPOSITORIES (commit the upgrade there too)',
      result.get('linked_repos', []), 0,
      lambda l: f'{l["path"]} ({l["kind"]} to {l["target"]}): '
      f'{l["files"]} file(s) changed')
  return '\n'.join(lines)


def render_detect(result, limit):
  lines = [_header('detect', result['tool'])]
  lines.append(f'repo    {result["repo"]}  [{_git_summary(result["git"])}]')
  version = result['version']
  lines.append(f'release {version["detected"] or "unknown"} '
               f'({version["confidence"]})' +
               (f'  markers: {_breakdown_text(version["markers"])}'
                if version['markers'] else ''))
  _section(
      lines, 'STAGES', result['stages'], limit,
      lambda s: f'{s["path"] or ".":<44} {s["marker"] or "-":<10} '
      f'found by {s["found_by"]}')
  modules = result['modules']
  calls = ', '.join(f'{k} {v}' for k, v in sorted(modules['calls'].items()))
  roots = ', '.join(
      f'{k or "."} ({v})' for k, v in sorted(modules['roots'].items()))
  lines.append('')
  lines.append(f'MODULES  {modules["local_dirs"]} local folder(s) under '
               f'{roots or "no local root"}; module calls: {calls or "none"}')
  if result['fabric_git_refs']:
    lines.append('  git refs to Fabric: ' + ', '.join(
        f'{k} x{v}' for k, v in sorted(result['fabric_git_refs'].items())))
  _section(lines, 'SOURCE PROBLEMS', modules['problems'], limit,
           lambda p: f'{p["file"]}:{p["line"]} {p["source"]} ({p["problem"]})')
  factory = result['factory']
  lines.append('')
  lines.append(f'FACTORY  {factory["yaml_files"]} YAML file(s), '
               f'{factory["schema_files"]} schema(s); tfvars '
               f'{len(result["tfvars_files"])}; lock files '
               f'{len(result["lock_files"])}')
  if result['upstream_history']:
    lines.append('HISTORY  upstream release tag found in git history: '
                 'consider `git merge <target tag>` instead of apply')
  _section(lines, 'WARNINGS', result['warnings'], 0, lambda w: f'- {w}')
  return '\n'.join(lines)


def render_changelog(result, limit):
  lines = [_header('changelog', result['tool'])]
  lines.append(f'{result["from"]} -> {result["to"]}: releases ' +
               (', '.join(result['releases']) or 'none found'))
  entries = result['breaking_changes']
  relevant = [b for b in entries if b['relevant']]
  title = ('BREAKING CHANGES (relevant to the repository)'
           if result['filtered_by_repo'] else 'BREAKING CHANGES')
  _section(lines, title, relevant, limit,
           lambda b: f'{b["version"]} [{b["reason"]}] {b["text"]}')
  if len(entries) > len(relevant):
    lines.append(f'  ({len(entries) - len(relevant)} more affect stages or '
                 'modules not in use; see --json)')
  _section(lines, 'MODULE RENAMES', sorted(result['module_renames'].items()), 0,
           lambda r: f'{r[0]} -> {r[1]}')
  _section(
      lines, 'UPGRADING NOTES', result['upgrading_notes'], 0,
      lambda n: f'{", ".join(n["versions"])}: ' + n['text'].replace(
          '\n', '\n    '))
  _section(lines, 'FAST CHANGES', result['fast_changes'], limit,
           lambda f: f'{f["version"]} {f["text"]}')
  return '\n'.join(lines)


def render_check_data(result, limit):
  lines = [_header('check-data', result['tool'])]
  counts = ', '.join(f'{k} {v}' for k, v in sorted(result['counts'].items()))
  lines.append(f'paths   {", ".join(result["paths"])}')
  lines.append(f'files   {counts or "no YAML files"}')

  def fmt(f):
    if f['status'] == 'invalid':
      shown, more = _limited(f['errors'], 3)
      tail = f' (+{more} more)' if more else ''
      return f'INVALID {f["path"]}: ' + '; '.join(shown) + tail
    if f['status'] == 'validator-error':
      return (f'NOT CHECKED {f["path"]}: the validator failed '
              f'({f["errors"][0]}); check this file by hand')
    return f'UNRESOLVED {f["path"]}: {f.get("reason")}'

  _section(lines, 'PROBLEMS', result['files'], limit, fmt)
  return '\n'.join(lines)


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------


def _emit(args, result, renderer):
  """Prints the result; with --output also writes it to a file.

  JSON written to a file is not echoed: a plan on a real repository runs
  to megabytes, which would only flood the caller's context.
  """
  if args.json:
    output = json.dumps(result, indent=2, sort_keys=True, default=list)
  else:
    output = renderer(result, args.limit)
  path = getattr(args, 'output', None)
  if path:
    with open(path, 'w', encoding='utf-8') as f:
      f.write(output + '\n')
    if args.json:
      print(f'wrote JSON to {os.path.abspath(path)} ({len(output) + 1} bytes; '
            f'tools {result["tool"]["digest"]})')
      return
  print(output)


def cmd_releases(args):
  versions = list_releases(args.upstream)
  if args.json:
    print(
        json.dumps({
            'upstream': args.upstream,
            'releases': versions
        }, indent=2))
    return 0
  if not versions:
    print(f'no release tags found at {args.upstream}')
    return 1
  shown, more = _limited(versions, args.limit)
  print(f'latest {versions[0]} ({len(versions)} releases at {args.upstream})')
  print('  ' + ' '.join(shown) + (f' ... +{more}' if more else ''))
  return 0


def cmd_fetch(args):
  path, how = fetch_release(args.version, args.upstream, args.from_repo,
                            args.cache_dir, args.refresh)
  version = release_version(path)
  print(f'fetched {args.version} ({how}); release marker {version}')
  print(path)
  return 0


def cmd_detect(args):
  _emit(args, detect(args.repo, args.fabric_source), render_detect)
  return 0


def cmd_changelog(args):
  result = changelog(args.upstream_dir, getattr(args, 'from'), args.to,
                     args.repo, args.fabric_source)
  _emit(args, result, render_changelog)
  return 0


def cmd_plan(args):
  ctx = Context(args.repo, args.base, args.target, args.fabric_source,
                args.data, parse_stage_map(args.map))
  if not factory_data.available() and not args.skip_data_checks:
    raise UpgradeError(
        'factory data checks need ' +
        ' and '.join(factory_data.missing_dependencies()) +
        ': run with `uv run`, install them (for example in a virtualenv), '
        'or pass --skip-data-checks to plan without them')
  plan, _ = build_plan(ctx)
  written = []
  full = (os.path.basename(args.markdown)
          if args.markdown else 'plan --markdown')
  for path, render, kind in ((args.markdown, report.render_markdown,
                              'Markdown'),
                             (args.brief,
                              lambda p: report.render_brief(p, full), 'brief'),
                             (args.widget,
                              lambda p: report.render_widget(p, full),
                              'inline HTML'), (args.html, report.render_html,
                                               'HTML')):
    if path:
      with open(path, 'w', encoding='utf-8') as f:
        f.write(render(plan))
      written.append(f'wrote {kind} report to {os.path.abspath(path)}')
  _emit(args, plan, render_plan)
  for line in written:
    print(line, file=sys.stderr)
  return 0


def cmd_apply(args):
  ctx = Context(args.repo, args.base, args.target, args.fabric_source,
                args.data, parse_stage_map(args.map))
  plan, results = build_plan(ctx)
  result = run_apply(ctx, results, dry_run=args.dry_run,
                     include_deletes=args.include_deletes, bump=args.bump_refs,
                     copy_moved=args.copy_moved, allow_dirty=args.allow_dirty,
                     moved=plan['moved_files'])
  _emit(args, result, render_apply)
  counts = result['counts']
  return 2 if counts.get('conflict') or counts.get('manual') else 0


def cmd_check_data(args):
  result = check_data(args.paths, args.schemas)
  _emit(args, result, render_check_data)
  return 2 if result['counts'].get('invalid') else 0


def build_parser():
  parser = argparse.ArgumentParser(
      prog='fast_upgrade.py',
      description='Plan and apply FAST upgrades with a three-way comparison.')
  sub = parser.add_subparsers(dest='command', required=True)

  def common(p, output=False):
    p.add_argument('--json', action='store_true', help='Print JSON.')
    p.add_argument('--limit', type=int, default=DEFAULT_LIMIT,
                   help='Maximum items per list in text output (0 = all).')
    if output:
      p.add_argument('--output', help='Also write the report to this file.')

  def inputs(p):
    p.add_argument('--repo', required=True, help='Customer FAST repository.')
    p.add_argument('--base', required=True,
                   help='Upstream tree of the release the repo came from.')
    p.add_argument('--target', required=True,
                   help='Upstream tree of the release to upgrade to.')
    p.add_argument(
        '--data', action='append', default=[],
        help='Extra factory data or tfvars folder outside the repo '
        '(repeatable), e.g. a fast-config folder.')
    p.add_argument(
        '--map', action='append', default=[], metavar='FOLDER=STAGE',
        help='Say which upstream stage a repository folder is based on '
        '(repeatable), e.g. platform/org=0-org-setup, or FOLDER=none for '
        'a folder that is your own. Overrides the automatic match; use '
        'the same flags for plan and apply.')
    p.add_argument('--fabric-source', default=DEFAULT_FABRIC_SOURCE,
                   help='Regex matching git URLs of Fabric (for mirrors).')

  p = sub.add_parser('releases', help='List upstream release tags.')
  p.add_argument('--upstream', default=UPSTREAM_URL,
                 help='Git URL or path of the Fabric repository.')
  common(p)
  p.set_defaults(func=cmd_releases)

  p = sub.add_parser('fetch', help='Materialize an upstream release.')
  p.add_argument('version', help='Release tag, e.g. v57.0.0.')
  p.add_argument('--upstream', default=UPSTREAM_URL,
                 help='Git URL of the Fabric repository or a mirror.')
  p.add_argument('--from-repo',
                 help='Local Fabric clone to archive the tag from (offline).')
  p.add_argument(
      '--cache-dir', help='Cache folder (default $FAST_UPGRADE_CACHE or '
      '~/.cache/fast-upgrade).')
  p.add_argument('--refresh', action='store_true',
                 help='Fetch again even if cached.')
  p.set_defaults(func=cmd_fetch)

  p = sub.add_parser('detect', help='Describe a FAST repository.')
  p.add_argument('repo', help='Customer FAST repository.')
  p.add_argument('--fabric-source', default=DEFAULT_FABRIC_SOURCE,
                 help='Regex matching git URLs of Fabric (for mirrors).')
  common(p, output=True)
  p.set_defaults(func=cmd_detect)

  p = sub.add_parser('changelog', help='Breaking changes between releases.')
  p.add_argument('--upstream-dir', required=True,
                 help='Upstream tree containing CHANGELOG.md (the target).')
  p.add_argument('--from', required=True, help='Base release, e.g. v57.0.0.')
  p.add_argument('--to', required=True, help='Target release, e.g. v59.0.0.')
  p.add_argument('--repo', help='Filter relevance by what this repo uses.')
  p.add_argument('--fabric-source', default=DEFAULT_FABRIC_SOURCE,
                 help='Regex matching git URLs of Fabric (for mirrors).')
  common(p, output=True)
  p.set_defaults(func=cmd_changelog)

  p = sub.add_parser('analyze', aliases=['plan'],
                     help='Upgrade impact report (read-only).')
  inputs(p)
  p.add_argument(
      '--markdown', metavar='FILE',
      help='Also write the shareable customer report as Markdown '
      '(summary, findings tracker, details, plan, coverage) to '
      'FILE.')
  p.add_argument(
      '--brief', metavar='FILE',
      help='Also write a chat-sized Markdown summary of the '
      'report (verdict, findings, stages, plan) to FILE, for the '
      'agent to show inline.')
  p.add_argument(
      '--html', metavar='FILE',
      help='Also write the same report as a self-contained, '
      'interactive HTML file to FILE.')
  p.add_argument(
      '--widget', metavar='FILE',
      help='Also write a compact interactive HTML summary (under '
      '500 px tall) to FILE, for agents that embed HTML inline in '
      'the chat.')
  p.add_argument(
      '--skip-data-checks', action='store_true',
      help='Plan without pyyaml/jsonschema: factory YAML is '
      'then reported as not checked.')
  common(p, output=True)
  p.set_defaults(func=cmd_plan)

  p = sub.add_parser('migrate', aliases=['apply'],
                     help='Update repository files on a clean git tree.')
  inputs(p)
  p.add_argument('--dry-run', action='store_true',
                 help='Show what would change without writing.')
  p.add_argument('--include-deletes', action='store_true',
                 help='Delete files removed upstream (unchanged by you).')
  p.add_argument(
      '--bump-refs', action='store_true',
      help='Rewrite ?ref=<base> to the target in Fabric git '
      'sources of your own files.')
  p.add_argument('--copy-moved', action='store_true',
                 help='Copy moved-block files for the range into the stages.')
  p.add_argument('--allow-dirty', action='store_true',
                 help='Proceed on a dirty tree or outside git (unsafe).')
  common(p, output=True)
  p.set_defaults(func=cmd_apply)

  p = sub.add_parser('check-data',
                     help='Validate factory YAML against modeline schemas.')
  p.add_argument('paths', nargs='+', help='Files or folders to check.')
  p.add_argument(
      '--schemas', action='append', default=[],
      help='Folder with schemas for by-name resolution '
      '(repeatable; default: the checked paths).')
  common(p, output=True)
  p.set_defaults(func=cmd_check_data)
  return parser


def main(argv=None):
  args = build_parser().parse_args(argv)
  try:
    return args.func(args)
  except Refused as e:
    print(f'REFUSED: {e}', file=sys.stderr)
    return 1
  except UpgradeError as e:
    print(f'ERROR: {e}', file=sys.stderr)
    return 1


if __name__ == '__main__':
  sys.exit(main())
