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
"""FROZEN SCRIPT — findings, readiness and the shareable upgrade reports.

`build_findings(plan)` turns every section of a `fast_upgrade.py plan`
into findings with a severity, a stage, the files involved, evidence and
the action to take, then derives an overall readiness verdict, what the
analysis could not check (coverage) and an ordered upgrade checklist.

`render_markdown(plan)` writes the customer report as Markdown: summary,
a findings tracker with Owner/Status/Target date columns, every finding in
detail, per-stage view, the upgrade plan as a task list, breaking changes,
file actions, coverage and technical appendices. It renders on Git hosts
and in merge requests, imports into Google Docs and diffs between runs.

`render_brief(plan)` condenses the report into one chat message, and
`render_widget(plan)` into one compact interactive HTML card, for agents
to show the report inline.

`render_html(plan)` writes the same content as one self-contained,
interactive HTML file (no external resources) for walkthroughs. Both HTML
files follow the host's theme tokens when an IDE provides them.

Absolute local paths are replaced with placeholders in every report.

Severities:
  blocker  the upgrade cannot succeed until this is fixed
  high     likely breaks `terraform plan` or changes infrastructure
  medium   needs a decision or a manual step
  low      cleanup or a follow-up
  info     for awareness
"""

import collections
import datetime
import html
import json
import os
import posixpath
import re

SEVERITIES = ('blocker', 'high', 'medium', 'low', 'info')
READINESS = {
    'BLOCKED': 'Blockers must be resolved before the upgrade can be applied.',
    'NEEDS WORK': 'The upgrade can proceed once the high-severity findings '
                  'are handled.',
    'READY WITH REVIEW': 'No blocker or high-severity finding: apply, then '
                         'review terraform plan for every stage.',
}
_DATA_STATUS = {
    'breaks': ('medium', 'factory file(s) are rejected by the target schema',
               'Update these files to the target schema. Editors and CI '
               'validation reject them; at runtime the factories do not '
               'validate, so a removed attribute is usually ignored silently '
               'and its setting no longer has any effect. Check the '
               'CHANGELOG entry for each attribute.'),
    'schema-removed': ('high', 'factory file(s) use a schema removed upstream',
                       'Find the replacement schema or factory in the target '
                       'release and migrate the data.'),
    'still-invalid': ('medium', 'factory file(s) are invalid today and stay '
                      'invalid', 'Pre-existing problems: fix them while '
                      'upgrading or confirm the factory tolerates them.'),
    'validator-error': ('low', 'factory file(s) could not be validated',
                        'The validator failed on these files: check them by '
                        'hand against the target schema.'),
    'unresolved': ('low', 'factory file(s) reference a schema that was not '
                   'found', 'Fix the yaml-language-server modeline or check '
                   'the files by hand.'),
    'fixed': ('info', 'factory file(s) become valid with the target schema',
              'No action needed.'),
}
# File categories apply has nothing to write for.
_QUIET = ('unchanged', 'already-updated', 'customer-changed', 'customer-added',
          'customer-deleted')
_MANUAL = ('conflict-added', 'conflict-deleted', 'conflict-customer-deleted')


def _needs_person(f):
  """apply leaves this file to a person: a manual category, or an upstream
  change behind a symlinked folder. Unused sample datasets never count."""
  if f.get('sample_data'):
    return False
  return f['category'] in _MANUAL or bool(
      f.get('blocked') and f['category'] not in _QUIET)


def _manual_count(plan):
  """Files that need a decision, not counting unused sample datasets."""
  return sum(1 for f in plan['files'] if _needs_person(f))


def _written(f, categories):
  """True if apply writes this file: not a skipped sample, not blocked."""
  return (f['category'] in categories and not f.get('sample_data') and
          not f.get('blocked'))


def _auto_count(plan):
  """Files apply takes from upstream without a merge."""
  return sum(1 for f in plan['files']
             if _written(f, ('upstream-changed', 'upstream-added')))


def _merge_count(plan):
  """Files apply merges three ways."""
  return sum(1 for f in plan['files'] if _written(f, ('conflict',)))


def _apply_order(mapping):
  """Sort key for stage mappings in FAST's apply order.

  Stages go by level (0, 1, 2, 3); within a level the core stages under
  fast/stages come first, then add-ons and extras, which build on them.
  """
  name = mapping.get('name') or ''
  level = re.match(r'(\d+)-', name)
  base = mapping.get('base') or mapping.get('target') or ''
  rank = 0 if base.startswith('fast/stages/') else 1
  return (int(level.group(1)) if level else 99, rank, name,
          mapping.get('customer') or '')


def _owner(path, stages, modules):
  """The stage folder (longest match), 'modules' or 'repository'.

  A stage at the repository root ('') matches last, so module folders it
  vendors still count as modules.
  """
  for stage in stages:
    if stage and (path == stage or path.startswith(stage + '/')):
      return stage
  for module in modules:
    if path == module or path.startswith(module + '/'):
      return 'modules'
  return '.' if '' in stages else 'repository'


def _owner_lists(plan):
  stages = sorted(
      (m['customer'] for m in plan['mappings'] if m['kind'] == 'stage'),
      key=len, reverse=True)
  modules = [m['customer'] for m in plan['mappings'] if m['kind'] == 'module']
  return stages, modules


def _clip(text, width):
  text = ' '.join(str(text).split())
  return text if len(text) <= width else text[:width - 3] + '...'


def _plain(text):
  """CHANGELOG Markdown as plain text: links keep their label, no backticks."""
  text = re.sub(r'\[\[([^\]]+)\]\([^)]*\)\]', r'(\1)', text)
  text = re.sub(r'\[([^\]]+)\]\([^)]*\)', r'\1', text)
  return text.replace('`', '')


def _call_file(call):
  return call.split(':', 1)[0]


class _Collector:
  """Accumulates findings and attributes them to customer stages."""

  def __init__(self, plan):
    self.items = []
    self.stages, self.modules = _owner_lists(plan)

  def owner(self, path):
    return _owner(path, self.stages, self.modules)

  def add(self, severity, category, title, detail='', files=(), action='',
          evidence='', stage=None):
    files = [f for f in files if f]
    if stage is None:
      owners = {self.owner(f) for f in files}
      stage = owners.pop() if len(owners) == 1 else (
          'multiple' if owners else 'repository')
    self.items.append({
        'severity': severity,
        'category': category,
        'stage': stage,
        'title': title,
        'detail': detail,
        'files': files,
        'action': action,
        'evidence': evidence,
    })


def _warning_finding(add, warning):
  rules = (
      ('no folder could be mapped', 'blocker', 'No folder maps to FAST'),
      ('uncommitted changes', 'high', 'Uncommitted changes in the repository'),
      ('looks like', 'high', 'The base release may be wrong'),
      ('mixed releases', 'high', 'Release markers disagree'),
      ('no longer exist in the target', 'high', 'Stages removed upstream'),
      ('no CHANGELOG', 'medium', 'Breaking changes cannot be listed'),
      ('same release', 'info', 'Base and target are the same release'),
  )
  for needle, severity, title in rules:
    if needle in warning:
      add(severity, 'setup', title, warning,
          action='Resolve this before applying the upgrade.',
          stage='repository')
      return
  add('high', 'setup', 'Setup warning', warning,
      action='Resolve this before applying the upgrade.', stage='repository')


def _findings(plan):
  c = _Collector(plan)
  add = c.add
  files = plan['files']
  target = plan['target']['version']
  base = plan['base']['version']

  for warning in plan['warnings']:
    if not warning.startswith('factory data checks skipped'):
      _warning_finding(add, warning)

  for hint in plan.get('missing_module_roots', []):
    if hint['exists']:
      continue
    note = (' The path is git-ignored in this repository, so it is expected '
            'to be a separate checkout.' if hint['ignored'] else '')
    add(
        'blocker', 'modules',
        f'Module sources point to a missing folder: {hint["root"]}',
        f'{hint["calls"]} module call(s) resolve under {hint["root"]}, which '
        f'does not exist.{note} Without it, modules cannot be compared and '
        '`terraform init` fails.',
        action=f'Check out or link the modules at {hint["root"]} (relative to '
        'the repository root) and run the plan again.',
        evidence='detect: SOURCE PROBLEMS (missing)', stage='repository')

  for pin in plan.get('version_pins', []):
    bad = [p for p in pin['pins'] if p['allows_target'] is False]
    if pin['blocks_init']:
      add(
          'blocker', 'versions',
          f'Version constraints in {pin["file"]} exclude {target}',
          'This file is yours, so apply keeps it, but it pins: ' +
          '; '.join(f'{p["name"]} "{p["constraint"]}" (the target needs '
                    f'"{p["target"]}")' for p in bad) +
          '. terraform init fails because no provider version satisfies '
          'both this file and the upgraded modules.', files=[pin['file']],
          action='Change these constraints to the target default-versions.tf '
          'values (or delete the file if it only duplicates them), then run '
          '`terraform init -upgrade`.',
          evidence=f'target default-versions.tf; release stamp '
          f'{pin["marker"] or "none"}')
    elif pin['stale_marker']:
      add(
          'low', 'versions',
          f'Release stamp in {pin["file"]} still says {pin["marker"]}',
          'The file is yours and is kept by apply; its release comment will '
          'no longer match the modules.', files=[pin['file']],
          action=f'Update the stamp to {target} after the upgrade.')

  for s in plan['stage_variables']:
    stage = s['stage'] or '.'
    if s['tfvars_set_removed']:
      add(
          'high', 'variables',
          f'{stage}: tfvars set variables the target no longer declares',
          'Set but removed: ' + ', '.join(s['tfvars_set_removed']) +
          '. Terraform only warns about undeclared variables in tfvars '
          'files, so these settings silently stop having any effect.',
          files=s['tfvars_files'], stage=stage,
          action='Find where each setting moved (CHANGELOG, stage README, '
          'factory data) and migrate the value; then remove the old key.',
          evidence=f'variables.tf of {s["upstream"]} in {base} and {target}')
    required = s['added_required'] + s['default_removed']
    if required:
      add(
          'high', 'variables', f'{stage}: new required variables',
          'Required in the target without a default: ' + ', '.join(required) +
          '. terraform plan fails unless a tfvars file or an earlier stage '
          'output provides them.', stage=stage,
          action='Add values to the stage tfvars, or confirm that the '
          'output tfvars of an earlier stage provide them.',
          evidence=f'variables.tf of {s["upstream"]}')
    if s['type_changed']:
      add(
          'high', 'variables', f'{stage}: variable types changed',
          'Changed: ' + ', '.join(t['name'] for t in s['type_changed']) +
          '. Values that matched the old type can be rejected or silently '
          'dropped (object attributes not in the new type are discarded).',
          stage=stage,
          action='Compare each value you set with the new type (see the '
          'appendix for both types).', evidence=f'variables.tf of '
          f'{s["upstream"]}')
    unset = sorted(set(s['removed']) - set(s['tfvars_set_removed']))
    if unset:
      add(
          'low', 'variables', f'{stage}: variables removed upstream',
          'Removed: ' + ', '.join(unset) + '. None is set in the tfvars '
          'files that were scanned.', stage=stage,
          action='Remove them from any other place that sets them (CI/CD '
          'variables, -var flags, wrapper scripts).')
    if s['tfvars_unreadable']:
      add(
          'medium', 'variables', f'{stage}: tfvars files could not be read',
          'Not checked: ' + '; '.join(s['tfvars_unreadable']) + '.',
          stage=stage,
          action='Make the files available (fix the symlink or pass the '
          'folder with --data) and run the plan again.')

  by_call = collections.OrderedDict()
  for hit in plan['module_interface']:
    by_call.setdefault((hit['call'], hit['module']), []).append(hit['issue'])
  for (call, module), issues in by_call.items():
    add('high', 'module-calls', f'Your call to {module} needs changes',
        f'{call}: ' + '; '.join(issues), files=[_call_file(call)],
        action='Update the arguments to the target module interface.',
        evidence=f'variables.tf of modules/{module} in {base} and {target}')

  for rename in plan['module_renames']:
    if rename['used']:
      add(
          'high', 'modules',
          f'Module {rename["old"]} was renamed to {rename["new"]}',
          'Sources that reference the old name stop resolving.',
          action=f'Point sources at {rename["new"]} and add moved blocks if '
          'resource addresses change.', evidence='CHANGELOG / target tree')

  groups = collections.defaultdict(list)
  for f in files:
    if f.get('sample_data'):
      if f['category'] in ('conflict-customer-deleted', 'upstream-added'):
        groups[('sample', c.owner(f['path']))].append(f['path'])
      continue
    if f['blocked'] and f['category'] not in _QUIET:
      groups[('blocked', c.owner(f['path']))].append(f['path'])
      continue
    if f['category'] == 'conflict':
      key = 'conflict-marker' if f['marker_only'] else 'conflict'
      groups[(key, c.owner(f['path']))].append(f['path'])
    elif f['category'] in ('conflict-added', 'conflict-deleted',
                           'conflict-customer-deleted'):
      groups[(f['category'], c.owner(f['path']))].append(f['path'])
    elif f['category'] == 'upstream-deleted':
      groups[('deleted', c.owner(f['path']))].append(f['path'])
    elif f['category'] == 'customer-changed':
      groups[('kept', c.owner(f['path']))].append(f['path'])
  texts = {
      'conflict': ('high', 'changed on both sides',
                   'apply runs a 3-way merge: resolve any conflict markers, '
                   'then check the merged files still express your change.'),
      'conflict-marker': ('low', 'changed by you; upstream changed only the '
                          'release stamp', 'apply merges them; usually clean.'),
      'conflict-added': ('high', 'added by you and upstream with different '
                         'content', 'Compare with the target and merge by '
                         'hand.'),
      'conflict-deleted': ('high', 'removed upstream but changed by you',
                           'Port your change to where upstream moved the code '
                           'or delete the file.'),
      'conflict-customer-deleted': ('medium', 'removed by you but changed '
                                    'upstream', 'Confirm they should stay '
                                    'removed.'),
      'deleted': ('low', 'removed upstream', 'Review, then remove with apply '
                  '--include-deletes.'),
      'kept': ('info', 'changed by you only (kept as is)',
               'Check they still work with the upgraded modules.'),
      'sample': ('low', 'changed upstream in sample datasets you do not keep',
                 'Your data lives elsewhere, so apply does not add these. '
                 'Compare them with your own dataset: new or renamed keys '
                 '(defaults.yaml especially) may be needed there.'),
      'blocked': ('high', 'blocked from automatic update (under a symlinked '
                  'folder)', 'apply never writes through a symlink: port '
                  'these upstream changes in the linked folder by hand.'),
  }
  for (key, stage), paths in sorted(groups.items(), key=lambda kv:
                                    (kv[0][1], kv[0][0])):
    severity, text, action = texts[key]
    add(
        severity, 'files', f'{stage}: {len(paths)} file(s) {text}',
        files=sorted(paths), stage=stage, action=action,
        evidence='three-way comparison of your repository, '
        f'{base} and {target}')

  by_file = collections.OrderedDict()
  for u in plan['unresolved_sources']:
    by_file.setdefault(u['file'], []).append(f'line {u["line"]}: {u["source"]}')
  raw = set(plan.get('upstream_sources', []))
  for path, sources in by_file.items():
    why = (' The file keeps upstream module sources, so the target copy is '
           'taken as is.' if path in raw else '')
    add(
        'high', 'modules', f'Module sources in {path} will not resolve',
        'After apply: ' + '; '.join(sources) + '.' + why, files=[path],
        action='Point the sources at your module location, or restore the '
        'module folder they expect; `terraform init` fails otherwise.',
        evidence='target file content checked against the repository layout')

  if plan['moved_files']:
    add(
        'high', 'state', 'Moved blocks must be copied before terraform plan',
        'Resource addresses change in this release range. Without these '
        'moved blocks Terraform plans to destroy and recreate resources.',
        files=[m['copy_to'] for m in plan['moved_files']],
        action='Run apply with --copy-moved (or copy the files by hand), '
        'plan, then remove them after the first successful apply.',
        evidence=', '.join(m['file'] for m in plan['moved_files']))

  for b in plan['breaking_changes']:
    if not b['relevant']:
      continue
    impact = b.get('impact', '')
    severity = 'high' if 'of your module call' in impact else 'medium'
    add(
        severity, 'breaking-change',
        f'{b["version"]}: {_clip(_plain(b["text"]), 110)}',
        b['text'] + (f'\n\nImpact here: {impact}.' if impact else ''),
        action='Read the change and its pull request; confirm your '
        'configuration does not rely on the old behaviour.',
        evidence=f'CHANGELOG {b["version"]} ({b["reason"]})',
        stage='repository')

  for note in plan['upgrading_notes']:
    add('medium', 'upgrade-note',
        f'Upgrade note for {", ".join(note["versions"])}', note['text'],
        action='Follow the documented procedure.',
        evidence='fast/stages/UPGRADING.md', stage='repository')

  if plan['providers']:
    add(
        'medium', 'versions', 'Provider and Terraform versions change',
        '; '.join(f'{p["name"]}: {p["base"]} -> {p["target"]}'
                  for p in plan['providers']) +
        '. Major provider versions can change resource defaults.',
        action='Run `terraform init -upgrade` in every stage and read the '
        'provider upgrade guide for major versions.',
        evidence='default-versions.tf', stage='repository')

  data = plan['data_impact']
  if 'skipped' not in data:
    by_status = collections.defaultdict(list)
    for f in data['files']:
      by_status[f['status']].append(f)
    for status, (severity, text, action) in _DATA_STATUS.items():
      entries = by_status.get(status)
      if not entries:
        continue
      lines = []
      for f in entries[:30]:
        first = (f.get('errors') or [f.get('reason', '')])[0]
        lines.append(f'{f["file"]}: {_clip(first, 160)}')
      if len(entries) > 30:
        lines.append(f'... and {len(entries) - 30} more')
      add(
          severity, 'factory-data', f'{len(entries)} {text}', '\n'.join(lines),
          files=[f['file'] for f in entries], action=action,
          evidence='schemas: ' +
          ', '.join(sorted({f.get('schema') or '?' for f in entries})[:5]))
    without = data.get('stages_without_data', [])
    if without:
      add(
          'medium', 'factory-data',
          f'No factory data found for {len(without)} stage(s)',
          'Upstream configures these stages with YAML datasets, but no data '
          'for them was found in the repository, behind its symlinks, or in '
          '--data folders: ' + ', '.join(without) + '. Their data was not '
          'checked against the target schemas.',
          action='Pass the folder or repository that holds this data with '
          '--data <path> (repeatable) and run the plan again.',
          evidence='datasets/ in the base release', stage='repository')

  hygiene = plan.get('hygiene', {})
  if hygiene.get('broken_links'):
    add(
        'medium', 'hygiene', 'Broken symlinks', '\n'.join(
            f'{l["path"]} -> {l["target"]}' for l in hygiene['broken_links']),
        files=[l['path'] for l in hygiene['broken_links']],
        action='Remove them or recreate them with fast-links.sh on the '
        'machine or pipeline that runs Terraform.')
  if hygiene.get('absolute_links'):
    add(
        'medium', 'hygiene', 'Symlinks with absolute targets',
        'They only work on the machine that created them:\n' + '\n'.join(
            f'{l["path"]} -> {l["target"]}' for l in hygiene['absolute_links']),
        files=[l['path'] for l in hygiene['absolute_links']],
        action='Use relative links, or generate them per environment and '
        'keep them out of git.')
  if hygiene.get('generated_tracked'):
    add(
        'medium', 'hygiene', 'Generated provider/tfvars files are committed',
        'These are written per environment by fast-links.sh or the CI/CD '
        'setup (provider backends, stage outputs, workload identity). '
        'Committed copies go stale after the upgrade.',
        files=hygiene['generated_tracked'],
        action='Stop tracking them (git rm --cached) and add them to '
        '.gitignore; regenerate them from the output bucket.')

  for linked in plan.get('linked_repos', []):
    state = linked['git']
    if not linked.get('writes', True):
      add(
          'medium', 'repository',
          f'{linked["path"]} is a symlink to a separate checkout',
          'Its files were compared and its YAML validated through the link, '
          'but apply never writes through a symlink: upstream changes there '
          'are listed as blocked and must be ported in that checkout.',
          stage='repository',
          action='Review and commit changes in that checkout separately, and '
          'release it together with this repository.')
    elif not state.get('git'):
      add(
          'high', 'repository', f'{linked["path"]} is not a git repository',
          f'It is a {linked["kind"]}; apply would write there with no way '
          'to review or revert.', stage='repository',
          action='Make it a git checkout (or pass --allow-dirty knowingly).')
    elif state.get('dirty'):
      add(
          'high', 'repository', f'{linked["path"]} has uncommitted changes',
          f'{state["dirty"]} tracked file(s) are modified in this separate '
          'repository; apply refuses until they are committed.',
          stage='repository', action='Commit or stash them first.')
    else:
      add(
          'medium', 'repository', f'{linked["path"]} is a separate repository',
          f'The {linked["kind"]} holds {linked["mappings"]} mapped folder(s). '
          'apply writes there too; the upgrade needs a commit and review in '
          'that repository as well.', stage='repository',
          action='Branch both repositories and release them together.')

  for copy in plan.get('addon_copies', []):
    if copy['status'] == 'unchanged upstream':
      severity, text = 'info', 'unchanged upstream since your copy'
    elif copy['status'] == 'removed upstream':
      severity, text = 'high', 'removed upstream'
    else:
      severity = 'medium'
      text = f'changed upstream ({copy["changed_lines"]} line(s))'
    add(
        severity, 'addons',
        f'{copy["file"]} is a copy of add-on {copy["addon"]}: {text}',
        f'Matched {copy["addon_file"]} at {int(copy["similarity"] * 100)}% '
        'similarity. Copies are yours, so apply does not update them.',
        files=[copy['file']],
        action='Diff your copy against the add-on in the target release and '
        'port the upstream changes.', evidence=copy['addon_file'])

  refs = dict(plan['git_refs']['refs'])
  unpinned = refs.pop('(none)', 0)
  if unpinned:
    add(
        'medium', 'modules',
        f'{unpinned} Fabric git source(s) have no ?ref= pin',
        'They follow the default branch, so module code changes whenever '
        'upstream does, independently of this upgrade.',
        action=f'Pin them to {target} (?ref={target}) as part of the upgrade.',
        stage='repository')
  other = {r: n for r, n in refs.items() if r not in (base, target)}
  if other:
    add(
        'medium', 'modules', 'Fabric git sources pinned to other releases',
        ', '.join(f'{r} x{n}' for r, n in sorted(other.items())),
        action='Align them with the target release deliberately; they are '
        'not bumped automatically.', stage='repository')
  if plan['git_refs']['bumpable']:
    add(
        'low', 'modules',
        f'{plan["git_refs"]["bumpable"]} Fabric git source(s) pinned to {base}',
        action='Run apply with --bump-refs to move them to the target.',
        stage='repository')

  owned = plan['customer_only']
  if owned['stages'] or owned['modules']:
    add(
        'info', 'coverage', 'Folders with no upstream match',
        ', '.join(owned['stages'] + owned['modules']) + ': not compared with '
        'upstream.', action='Review them by hand against the target modules.',
        stage='repository')

  for cand in plan.get('stage_candidates', []):
    folder = cand['folder'] or '.'
    best = cand['guesses'][0]
    add(
        'high', 'mapping',
        f'{folder} looks like a FAST stage but matches none clearly '
        f'(best guess {best["stage"]})',
        f'Why it looks like a stage: {cand["reason"]}.\n' + '\n'.join(
            f'{g["stage"]} ({g["path"]}): {round(g["files"] * 100)}% of the '
            f'files, {round(g["variables"] * 100)}% of the variables' +
            (', matches the folder name' if g['by_name'] else '')
            for g in cand['guesses']) +
        '\nUntil it is mapped, apply leaves the folder untouched and no '
        'upstream change reaches it.',
        action=f'Confirm which stage it is based on and plan again with '
        f'`--map {folder}=<stage>`, or `--map {folder}=none` if it is your '
        'own. Pass the same flags to apply.', stage=folder)
  for u in plan.get('user_mappings', []):
    if u['stage'] and u['low_similarity']:
      folder = u['folder'] or '.'
      add(
          'high', 'mapping',
          f'{folder} was mapped to {u["stage"]} by hand; only '
          f'{round(u["score"] * 100)}% of its files match',
          'Upstream changes are merged three ways into a folder that has '
          'drifted far from the stage: expect many conflicts, and merges that '
          'apply cleanly but do not fit your code.',
          action='Review every merged file in this folder. Where it diverges '
          'too far, port the upstream changes by hand instead.', stage=folder)

  if plan['schema_changes']:
    add('info', 'factory-data',
        f'{len(plan["schema_changes"])} factory schema(s) change',
        '\n'.join(s['path'] for s in plan['schema_changes']),
        files=[s['path'] for s in plan['schema_changes']],
        action='Their effect on your data is listed under factory data.')

  for note in plan['notes']:
    add('info', 'note', _clip(note, 110), note, stage='repository')

  order = {s: i for i, s in enumerate(SEVERITIES)}
  c.items.sort(key=lambda f:
               (order[f['severity']], f['category'], f['stage'], f['title']))
  for i, f in enumerate(c.items, 1):
    f['id'] = f'F{i:03d}'
  return c.items


def _coverage(plan):
  items = []
  total = sum(plan['summary'].values())
  items.append(('File comparison', 'checked',
                f'{total} files in {len(plan["mappings"])} mapped folders '
                'compared three ways.'))
  owned = plan['customer_only']['stages'] + plan['customer_only']['modules']
  if owned:
    items.append(
        ('Folders with no upstream match', 'not checked', ', '.join(owned)))
  asked = [c['folder'] or '.' for c in plan.get('stage_candidates', [])]
  if asked:
    items.append(('Stage-like folders waiting for a mapping', 'not checked',
                  ', '.join(asked) + ': confirm each with --map.'))
  unreadable = [
      u for s in plan['stage_variables'] for u in s['tfvars_unreadable']
  ]
  items.append(
      ('Stage variables and tfvars', 'partial' if unreadable else 'checked',
       f'{len(unreadable)} tfvars file(s) unreadable'
       if unreadable else 'Declared variables compared; tfvars keys '
       'checked against them.'))
  items.append(('Your module calls', 'checked',
                'Arguments checked against the target interface of upstream '
                'modules. Calls to non-Fabric modules are not checked.'))
  items.append(('Provider and Terraform pins', 'checked',
                'Every .tf file with required_version or required_providers.'))
  missing = [h for h in plan.get('missing_module_roots', []) if not h['exists']]
  if missing:
    items.append(('Module folders', 'partial',
                  'Missing: ' + ', '.join(h['root'] for h in missing)))
  data = plan['data_impact']
  if 'skipped' in data:
    items.append(('Factory YAML data', 'not checked', data['skipped']))
  else:
    summary = data['summary']
    gaps = {
        k: summary.get(k, 0)
        for k in ('no-modeline', 'unresolved', 'validator-error')
    }
    without = data.get('stages_without_data', [])
    found = sum(summary.values())
    status = 'partial' if any(gaps.values()) or without else 'checked'
    if without and not found:
      status = 'not checked'
    detail = (f'{found} YAML file(s) found; '
              f'{gaps["no-modeline"]} without a schema modeline, '
              f'{gaps["unresolved"]} with an unresolved schema, '
              f'{gaps["validator-error"]} the validator could not check.')
    if without:
      detail += (' No data found for: ' + ', '.join(without) +
                 ' (pass it with --data).')
    items.append(('Factory YAML data', status, detail))
  items.append(('Terraform state and plan', 'not checked',
                'This is static analysis. Run terraform plan in every stage '
                'and review it (plan_review.py) before any apply.'))
  items.append(('CI/CD pipelines and wrapper scripts', 'not checked',
                'Pipelines, -var flags and variables set outside tfvars are '
                'not scanned.'))
  items.append(('Resources changed outside Terraform', 'not checked',
                'Drift is only visible in terraform plan.'))
  return [{'area': a, 'status': s, 'detail': d} for a, s, d in items]


def _checklist(plan, findings):
  counts = collections.Counter(f['severity'] for f in findings)
  target = plan['target']['version']
  stages = [
      m['customer'] or '.'
      for m in sorted((m for m in plan['mappings']
                       if m['kind'] == 'stage'), key=_apply_order)
  ]
  steps = [
      'Commit or stash local changes' +
      (' in every linked repository' if plan.get('linked_repos') else '') +
      f', then create a branch such as fast-upgrade-{target}.'
  ]
  if counts['blocker']:
    steps.append(f'Resolve the {counts["blocker"]} blocker finding(s).')
  asked = plan.get('stage_candidates', [])
  if asked:
    steps.append(f'Confirm which FAST stage each of the {len(asked)} '
                 'stage-like folder(s) is based on, then plan again with '
                 '`--map <folder>=<stage>` (or `=none`).')
  steps.append('Preview with `fast_upgrade.py apply --dry-run`, then run '
               'apply.')
  merges = _merge_count(plan)
  if merges:
    steps.append(f'Resolve conflict markers in {merges} merged '
                 'file(s) and review each merge.')
  manual = _manual_count(plan)
  if manual:
    steps.append(f'Decide on {manual} file(s) that need manual handling.')
  if plan['moved_files']:
    steps.append('Copy the moved-block files into their stages.')
  pins = plan.get('version_pins', [])
  if any(p['blocks_init'] for p in pins):
    steps.append('Widen the provider or Terraform constraints that exclude '
                 'the target in your own files.')
  if any(p['stale_marker'] and not p['blocks_init'] for p in pins):
    steps.append('Update the release stamps in your own version files.')
  if plan['stage_variables']:
    steps.append('Update tfvars for removed, new and retyped variables.')
  data = plan['data_impact']
  if 'skipped' not in data and any(
      f['status'] in ('breaks', 'schema-removed') for f in data['files']):
    steps.append('Migrate factory YAML that the target schema rejects.')
  if plan['unresolved_sources']:
    steps.append('Fix module sources that do not resolve after apply.')
  if counts['high']:
    steps.append(f'Work through the {counts["high"]} high-severity '
                 'finding(s).')
  steps.append('Run `terraform init -upgrade` in each stage, in order: ' +
               ', '.join(stages) + '.')
  steps.append('Run terraform plan in each stage and review it for deletes '
               'and replacements (plan_review.py); explain every one.')
  steps.append('Open a review for the branch; apply stage by stage in order, '
               'starting with a non-production environment.')
  return [{'id': f'S{i:02d}', 'text': t} for i, t in enumerate(steps, 1)]


def _highlights(plan, findings, coverage):
  """A few plain sentences for the top of the customer report."""
  taken = _auto_count(plan)
  manual = _manual_count(plan)
  points = [
      f'{taken} file(s) take upstream changes automatically; '
      f'{_merge_count(plan)} need a 3-way merge; {manual} need '
      'a decision. Files you own are never overwritten.'
  ]
  for severity in ('blocker', 'high'):
    groups = collections.OrderedDict()
    for f in findings:
      if f['severity'] == severity:
        groups.setdefault(f['category'], []).append(f)
    for items in groups.values():
      more = len(items) - 1
      points.append(f'{severity.capitalize()}: {items[0]["title"]}' +
                    (f' (and {more} similar)' if more else ''))
  gaps = [c['area'] for c in coverage if c['status'] != 'checked']
  if gaps:
    points.append(f'{len(gaps)} area(s) not fully checked: ' + ', '.join(gaps) +
                  '.')
  return points


def build_findings(plan):
  """Returns {'findings', 'readiness', 'coverage', 'checklist'}."""
  findings = _findings(plan)
  coverage = _coverage(plan)
  counts = collections.Counter(f['severity'] for f in findings)
  if counts['blocker']:
    status = 'BLOCKED'
  elif counts['high']:
    status = 'NEEDS WORK'
  else:
    status = 'READY WITH REVIEW'
  return {
      'findings': findings,
      'readiness': {
          'status': status,
          'summary': READINESS[status],
          'counts': {
              s: counts.get(s, 0) for s in SEVERITIES
          },
          'highlights': _highlights(plan, findings, coverage),
      },
      'coverage': coverage,
      'checklist': _checklist(plan, findings),
  }


def render_findings(plan, limit):
  """Text lines for the top of the plan report."""
  readiness = plan['readiness']
  counts = ', '.join(f'{k} {v}' for k, v in readiness['counts'].items() if v)
  lines = [
      '', f'READINESS  {readiness["status"]}  ({counts or "no findings"})',
      f'  {readiness["summary"]}'
  ]
  lines += [f'  - {p}' for p in readiness.get('highlights', [])]
  shown = [f for f in plan['findings'] if f['severity'] != 'info']
  if shown:
    lines.append('')
    lines.append(f'FINDINGS ({len(shown)}; info items in --markdown, --html '
                 'and --json)')
    subset = shown if not limit else shown[:limit]
    for f in subset:
      lines.append(f'  {f["id"]} {f["severity"].upper():<8}{f["title"]}')
      if f['action']:
        lines.append(f'       -> {f["action"]}')
    if len(subset) < len(shown):
      lines.append(f'  ... {len(shown) - len(subset)} more (--limit 0, '
                   '--markdown, --html or --json for all)')
  gaps = [c for c in plan['coverage'] if c['status'] != 'checked']
  if gaps:
    lines.append('')
    lines.append('NOT CHECKED')
    for c in gaps:
      lines.append(f'  {c["status"]:<12}{c["area"]}: {c["detail"]}')
  return lines


# --------------------------------------------------------------------------
# HTML
# --------------------------------------------------------------------------

# Any other person's home folder, e.g. the target of a symlink committed
# from someone's workstation: the user name is personal data. Only absolute
# paths match, not a repository folder that happens to be called home/.
_HOME_RE = re.compile(r'(?<![\w.\-/])(?:/usr/local/google)?/(?:home|Users)/'
                      r'[^/\s"\'`]+')


def _scrub(value, replacements):
  if isinstance(value, str):
    for old, new in replacements:
      value = value.replace(old, new)
    return _HOME_RE.sub('<home>', value)
  if isinstance(value, list):
    return [_scrub(v, replacements) for v in value]
  if isinstance(value, dict):
    return {k: _scrub(v, replacements) for k, v in value.items()}
  return value


def shareable(plan):
  """The plan without absolute local paths, for the customer report."""
  repo = plan['repo']['path']
  pairs = [(repo, '<repo>'), (plan['base']['path'], '<base>'),
           (plan['target']['path'], '<target>')]
  for key in ('path', 'target'):
    for linked in plan.get('linked_repos', []):
      if linked.get(key, '').startswith('/'):
        pairs.append((linked[key], f'<linked:{linked["path"]}>'))
  data_paths = [
      p for p in plan['repo'].get('data_paths', []) if p.startswith('/')
  ]
  for i, path in enumerate(data_paths, 1):
    pairs.append((path, '<data>' if len(data_paths) == 1 else f'<data{i}>'))
  home = os.path.expanduser('~')
  if home and home != '/':
    pairs.append((home, '~'))
  pairs.sort(key=lambda p: -len(p[0]))
  data = _scrub(plan, [p for p in pairs if p[0]])
  data['repo']['name'] = posixpath.basename(repo.rstrip('/')) or repo
  data['files'] = [{
      'path': f['path'],
      'category': f['category'],
      'kind': f['kind'],
      'marker_only': f['marker_only'],
      'renamed_from': f['renamed_from'],
      'renamed_to': f['renamed_to'],
      'blocked': f['blocked'],
      'sample_data': f.get('sample_data', False),
  } for f in data['files'] if f['category'] != 'unchanged']
  data['unchanged_files'] = plan['summary'].get('unchanged', 0)
  # Counts computed once, here, so every view agrees with the Markdown.
  data['apply_counts'] = {
      'updated': _auto_count(data),
      'merges': _merge_count(data),
      'decide': _manual_count(data),
  }
  data['stage_files'] = {
      s['name']: s['file_counts'] for s in _stage_data(data)[1]
  }
  return data


def _json_for_script(data):
  text = json.dumps(data, sort_keys=True, default=list)
  return (text.replace('<', '\\u003c').replace('>', '\\u003e').replace(
      '&', '\\u0026').replace('\u2028', '\\u2028').replace('\u2029', '\\u2029'))


def render_html(plan, generated=None):
  """Returns a self-contained, shareable HTML report for a plan."""
  data = shareable(plan)
  generated = generated or datetime.datetime.now(
      datetime.timezone.utc).strftime('%Y-%m-%d %H:%M UTC')
  data['generated'] = generated
  title = (f'FAST upgrade assessment: {data["repo"]["name"]} '
           f'{plan["base"]["version"]} to {plan["target"]["version"]}')
  return _fill(_TEMPLATE, title, data)


def _fill(template, title, data):
  """Fills __TITLE__ and __DATA__ in one pass, so neither value is
  substituted again (a folder named __DATA__ stays a plain name)."""
  values = {'__TITLE__': html.escape(title), '__DATA__': _json_for_script(data)}
  return re.sub(r'__TITLE__|__DATA__', lambda m: values[m.group(0)], template)


# --------------------------------------------------------------------------
# Markdown
# --------------------------------------------------------------------------
#
# Written to read well in IDE and agent Markdown views as much as on Git
# hosts: GitHub alerts for the verdict, severity badges, narrow tables,
# long text in lists rather than table cells, one Mermaid diagram, and
# only the escaping that GitHub-flavoured Markdown needs.

SEV_ICON = {'blocker': '🔴', 'high': '🟠', 'medium': '🟡', 'low': '🔵', 'info': '⚪'}
SEV_MEANING = {
    'blocker': 'Stops the upgrade until fixed',
    'high': 'Likely breaks `terraform plan` or changes infrastructure',
    'medium': 'Needs a decision or a manual step',
    'low': 'Cleanup or a follow-up',
    'info': 'For awareness',
}
_ALERT = {
    'BLOCKED': 'CAUTION',
    'NEEDS WORK': 'WARNING',
    'READY WITH REVIEW': 'TIP'
}
_COVERAGE_ICON = {'checked': '✅', 'partial': '⚠️', 'not checked': '❌'}
FILE_ACTIONS = collections.OrderedDict((
    ('conflict', 'Changed by you and upstream: 3-way merge, review the result'),
    ('conflict-added', 'Added by you and upstream with different content: '
     'decide by hand'),
    ('conflict-deleted', 'Removed upstream but changed by you: decide by hand'),
    ('conflict-customer-deleted', 'Removed by you but changed upstream: '
     'decide by hand'),
    ('upstream-changed', 'Changed upstream only: takes the target version'),
    ('upstream-added', 'New upstream: added'),
    ('upstream-deleted', 'Removed upstream: deleted only when approved'),
    ('customer-changed', 'Changed by you only: kept'),
    ('customer-added', 'Yours only: kept'),
    ('customer-deleted', 'Removed by you, unchanged upstream: stays removed'),
    ('already-updated', 'Already matches the target: nothing to do'),
))
_SECTIONS = ('1. Summary', '2. Findings tracker', '3. Findings in detail',
             '4. By stage', '5. Upgrade plan', '6. Breaking changes',
             '7. File actions', '8. Coverage', 'Appendix A. Technical details',
             'Appendix B. All changed files')
_KEEP_RE = re.compile(r'(`+)[^`]+?\1(?!`)|\[[^\[\]\n]+\]\(https?://[^)\s]+\)')
MD_FILE_LIMIT = 100


def _esc(text):
  """Escapes only what GFM would otherwise format, so raw text stays clean."""
  text = text.replace('\\', '\\\\').replace('*', '\\*').replace('`', '\\`')
  text = re.sub(r'(?<![A-Za-z0-9])_|_(?![A-Za-z0-9])', r'\\_', text)
  text = re.sub(r'<(?=[A-Za-z/!?])', r'\\<', text).replace('](', '\\](')
  return text.replace('~', '\\~') if text.count('~') > 1 else text


def _md(text):
  """One line of plain text, safe in a Markdown paragraph or table cell."""
  return _esc(' '.join(str(text).split()))


def _prose(text):
  """Like _md, but keeps the code spans and web links the text already has."""
  text = ' '.join(str(text).split())
  parts, last = [], 0
  for m in _KEEP_RE.finditer(text):
    parts += [_esc(text[last:m.start()]), m.group(0)]
    last = m.end()
  return ''.join(parts + [_esc(text[last:])])


def _code(text):
  text = ' '.join(str(text).split())
  if not text:
    return ''
  run = max((len(m) for m in re.findall('`+', text)), default=0)
  fence = '`' * (run + 1)
  pad = ' ' if run or text[0] == ' ' or text[-1] == ' ' else ''
  return f'{fence}{pad}{text}{pad}{fence}'


def _block(text):
  """A fenced text block that survives backticks in the content."""
  run = max((len(m) for m in re.findall('`+', text)), default=0)
  fence = '`' * max(3, run + 1)
  return [f'{fence}text', text.strip('\n'), fence]


def _cell(value):
  """GFM splits table rows on every unescaped pipe, even in code spans.

  A pipe is escaped when an odd number of backslashes precedes it.
  """
  return re.sub(r'(?<!\\)((?:\\\\)*)\|', r'\1\\|', str(value))


def _md_table(head, rows):
  if not rows:
    return []
  lines = [
      '| ' + ' | '.join(head) + ' |', '|' + '|'.join('---' for _ in head) + '|'
  ]
  lines += ['| ' + ' | '.join(_cell(c) for c in row) + ' |' for row in rows]
  return lines + ['']


def _anchor(title):
  """The heading anchor GitHub and most IDE previews generate."""
  return re.sub(r'[^a-z0-9 -]', '', title.lower()).replace(' ', '-')


def _badge(severity):
  return f'{SEV_ICON[severity]} {severity.capitalize()}'


def _sev_summary(items):
  counts = collections.Counter(f['severity'] for f in items)
  return ' · '.join(
      f'{SEV_ICON[s]} {counts[s]}' for s in SEVERITIES if counts[s]) or '—'


def _file_notes(f):
  notes = []
  if f['marker_only']:
    notes.append('release stamp only')
  if f['renamed_from']:
    notes.append('renamed from ' + _code(f['renamed_from']))
  if f['renamed_to']:
    notes.append('renamed to ' + _code(f['renamed_to']))
  if f['blocked']:
    notes.append(_md(f['blocked']))
  if f.get('sample_data'):
    notes.append('upstream sample dataset you do not keep')
  return '; '.join(notes)


def _detail_lines(detail):
  """Paragraphs as prose, line lists as bullets, anything indented as code."""
  lines = []
  for para in re.split(r'\n\s*\n', detail.strip()):
    rows = para.strip('\n').split('\n')
    if len(rows) == 1:
      lines.append(_prose(rows[0]))
    elif any(r[:1].isspace() for r in rows):
      lines += _block(para)
    else:
      lines += [f'- {_prose(r)}' for r in rows if r.strip()]
    lines.append('')
  return lines


def _md_finding(f):
  lines = [
      f'#### {f["id"]} · {_prose(f["title"])}', '',
      f'{_badge(f["severity"])} · Stage {_code(f["stage"])} · '
      f'{_md(f["category"])}', ''
  ]
  if f['detail'].strip():
    lines += ['**What we found**', ''] + _detail_lines(f['detail'])
  if f['action']:
    lines += [f'> **What to do:** {_prose(f["action"])}', '']
  if f['files']:
    lines += [f'**Files ({len(f["files"])})**', '']
    lines += [f'- {_code(p)}' for p in f['files'][:MD_FILE_LIMIT]]
    if len(f['files']) > MD_FILE_LIMIT:
      lines.append(f'- … and {len(f["files"]) - MD_FILE_LIMIT} more '
                   '(see Appendix B)')
    lines.append('')
  if f['evidence']:
    lines += [f'*Evidence: {_md(f["evidence"])}*', '']
  return lines + ['---', '']


def _stage_flow(mappings, by_stage):
  """A Mermaid flowchart of the stages by level, coloured by worst finding."""
  levels = collections.OrderedDict()
  for m in sorted((m for m in mappings if m['kind'] == 'stage'),
                  key=lambda m: m['customer']):
    name = m['customer'] or '.'
    match = re.match(r'(\d+)-', posixpath.basename(name))
    levels.setdefault(match.group(1) if match else 'other', []).append(name)
  if not levels:
    return []
  order = sorted((k for k in levels if k != 'other'), key=int)
  if 'other' in levels:
    order.append('other')
  lines = ['```mermaid', 'flowchart LR']
  classes = collections.defaultdict(list)
  node = 0
  for level in order:
    title = 'Other stages' if level == 'other' else f'Stage {level}'
    lines.append(f'  subgraph L{level}["{title}"]')
    for name in levels[level]:
      node += 1
      items = by_stage.get(name, [])
      counts = collections.Counter(f['severity'] for f in items)
      worst = next((s for s in SEVERITIES[:3] if counts[s]), 'ok')
      summary = ', '.join(f'{counts[s]} {s}' for s in SEVERITIES[:3]
                          if counts[s]) or 'no blocker, high or medium'
      label = f'{posixpath.basename(name)}: {summary}'.replace('"', "'")
      lines.append(f'    s{node}["{label}"]')
      classes[worst].append(f's{node}')
    lines.append('  end')
  numbered = [f'L{k}' for k in order if k != 'other']
  if len(numbered) > 1:
    lines.append('  ' + ' --> '.join(numbered))
  styles = {
      'blocker': 'fill:#fce8e6,stroke:#d93025,color:#202124',
      'high': 'fill:#feefe3,stroke:#e8710a,color:#202124',
      'medium': 'fill:#fef7e0,stroke:#f9ab00,color:#202124',
      'ok': 'fill:#e6f4ea,stroke:#188038,color:#202124',
  }
  for name, ids in classes.items():
    lines.append(f'  classDef {name} {styles[name]}')
    lines.append(f'  class {",".join(ids)} {name}')
  return lines + ['```', '']


def _stage_data(data):
  """Findings per stage, and one plain summary per stage or area."""
  mappings = data['mappings']
  by_stage = collections.defaultdict(list)
  for f in data['findings']:
    by_stage[f['stage']].append(f)
  owners = _owner_lists(data)
  file_cats = collections.defaultdict(collections.Counter)
  for f in data['files']:
    cats = file_cats[_owner(f['path'], *owners)]
    if _written(f, ('upstream-changed', 'upstream-added')):
      cats['updated'] += 1
    elif _written(f, ('conflict',)):
      cats['to merge'] += 1
    elif _needs_person(f):
      cats['to decide'] += 1
    elif _written(f, ('upstream-deleted',)):
      cats['removed upstream'] += 1
  upstream = {
      (m['customer'] or '.'): f'{m["name"]} ({m["match"]})'
      for m in mappings
      if m['kind'] == 'stage'
  }
  stages = []
  for name in sorted(set(by_stage) | set(file_cats)):
    cats = file_cats[name]
    work = [(cats[label], label) for label in ('updated', 'to merge',
                                               'to decide', 'removed upstream')]
    counts = collections.Counter(f['severity'] for f in by_stage[name])
    stages.append({
        'name': name,
        'upstream': upstream.get(name, ''),
        'counts': {
            s: counts[s] for s in SEVERITIES if counts[s]
        },
        'ids': [f['id'] for f in by_stage[name]],
        'files': ' · '.join(f'{n} {label}' for n, label in work if n),
        'file_counts': {
            label: n for n, label in work if n
        },
    })
  return by_stage, stages


def _stage_rows(data):
  """Findings per stage, and one Markdown table row per stage or area."""
  by_stage, stages = _stage_data(data)
  rows = [[
      _code(s['name']),
      _md(s['upstream'] or '—'),
      _sev_summary(by_stage[s['name']]), ', '.join(s['ids']) or '—',
      s['files'] or '—'
  ] for s in stages]
  return by_stage, rows


def render_markdown(plan, generated=None):
  """Returns the shareable customer report as GitHub-flavoured Markdown.

  It reads well in IDE and agent Markdown views, renders on any Git host
  or merge request, imports into Google Docs, and diffs cleanly between
  runs. The findings tracker has empty Owner, Status and Due columns for
  the customer to fill in, and the upgrade plan is a task list.
  """
  data = shareable(plan)
  generated = generated or datetime.datetime.now(
      datetime.timezone.utc).strftime('%Y-%m-%d %H:%M UTC')
  readiness, findings = data['readiness'], data['findings']
  base, target = data['base']['version'], data['target']['version']
  mappings, summary = data['mappings'], data['summary']
  counts = readiness['counts']
  status = readiness['status']
  out = [f'# FAST upgrade assessment: {_md(data["repo"]["name"])}', '']
  out += _md_table(['**Upgrade**', f'{_md(base)} → {_md(target)}'], [
      [
          '**Detected release**',
          f'{_md(data["repo"].get("detected_version") or "unknown")} '
          f'({_md(data["repo"].get("confidence", ""))} confidence)'
      ],
      ['**Generated**', _md(generated)],
      ['**Tools digest**', _code(data['tool']['digest'])],
  ])
  out += [
      f'> [!{_ALERT.get(status, "NOTE")}]',
      f'> **{status}**: {_md(readiness["summary"])}', ''
  ]
  out += [
      '**Contents:** ' + ' · '.join(f'[{t}](#{_anchor(t)})' for t in _SECTIONS),
      ''
  ]

  # 1. Summary
  out += [f'## {_SECTIONS[0]}', '']
  out += _md_table(['Severity', 'Findings', 'Meaning'], [
      [_badge(s), f'**{counts.get(s, 0)}**', SEV_MEANING[s]] for s in SEVERITIES
  ])
  out += ['### Key points', '']
  out += [f'- {_prose(p)}' for p in readiness.get('highlights', [])] + ['']
  urgent = [f for f in findings if f['severity'] in ('blocker', 'high')]
  if urgent:
    out += [
        '### Start here', '', 'Blocker and high findings, most severe first:',
        ''
    ]
    for i, f in enumerate(urgent, 1):
      out.append(f'{i}. {SEV_ICON[f["severity"]]} **{f["id"]}** '
                 f'{_prose(f["title"])}')
      if f['action']:
        out.append(f'   - {_prose(f["action"])}')
    out.append('')
  out += [
      '> [!NOTE]',
      '> Static analysis of this repository against the two upstream '
      'releases. It does not read Terraform state: validate every stage '
      'with `terraform plan` before any apply. The report names '
      'resources in this repository; share it only with people '
      'entitled to see them.', ''
  ]

  # 2. Tracker
  out += [
      f'## {_SECTIONS[1]}', '',
      'One row per finding, most severe first. Fill in Owner, Status and '
      'Due, or import the table into your tracker. Details for each ID '
      f'are in [{_SECTIONS[2]}](#{_anchor(_SECTIONS[2])}).', ''
  ]
  out += _md_table(
      ['ID', 'Severity', 'Stage', 'Finding', 'Owner', 'Status', 'Due'], [[
          f['id'],
          _badge(f['severity']),
          _code(f['stage']),
          _prose(f['title']), '', 'Open', ''
      ] for f in findings]) or ['No findings.', '']

  # 3. Details
  out += [f'## {_SECTIONS[2]}', '']
  for severity in SEVERITIES:
    items = [f for f in findings if f['severity'] == severity]
    if items:
      out += [f'### {_badge(severity)} ({len(items)})', '']
      for f in items:
        out += _md_finding(f)
  if not findings:
    out += ['No findings.', '']

  # 4. Stages
  by_stage, rows = _stage_rows(data)
  out += [f'## {_SECTIONS[3]}', '']
  flow = _stage_flow(mappings, by_stage)
  if flow:
    out += [
        'Stages apply level by level, left to right. Colour shows the '
        'most severe finding in each stage.', ''
    ] + flow
  out += _md_table(
      ['Stage', 'Upstream match', 'Findings', 'IDs', 'Files from upstream'],
      rows)

  # 5. Plan
  out += [
      f'## {_SECTIONS[4]}', '',
      'In order. In a merge request description the boxes can be ticked.', ''
  ]
  out += [f'- [ ] **{s["id"]}** {_prose(s["text"])}' for s in data['checklist']]
  out.append('')

  # 6. Breaking changes
  changes = data['breaking_changes']
  relevant = [b for b in changes if b.get('relevant')]
  out += [
      f'## {_SECTIONS[5]}', '',
      f'**{len(relevant)}** of {len(changes)} breaking change(s) between '
      f'{_md(base)} and {_md(target)} apply to this repository.', ''
  ]
  for b in relevant:
    out.append(f'- **{_md(b["version"])}** · {_md(b.get("reason", ""))}: '
               f'{_prose(b["text"])}')
    if b.get('impact'):
      out.append(f'  - **Impact on you:** {_prose(b["impact"])}')
  if relevant:
    out.append('')
  other = [b for b in changes if not b.get('relevant')]
  if other:
    out += [
        '### Not used by this repository', '',
        'Listed for completeness; they concern modules or stages this '
        'repository does not use.', ''
    ]
    out += [f'- **{_md(b["version"])}**: {_prose(b["text"])}' for b in other]
    out.append('')
  out += ['### Upgrade notes', '']
  for note in data['upgrading_notes']:
    out += [f'#### {_md(", ".join(note["versions"]))}', '']
    out += _block(note['text']) + ['']
  if not data['upgrading_notes']:
    out += ['None in this release range.', '']

  # 7. File actions
  out += [
      f'## {_SECTIONS[6]}', '',
      'What `apply` does with each file. Files you own are never '
      f'overwritten. {data["unchanged_files"]} file(s) identical in your '
      'repository and both releases are not listed.', ''
  ]
  out += _md_table(['Action', 'Files', 'Meaning'],
                   [[_code(c), f'**{summary[c]}**', FILE_ACTIONS[c]]
                    for c in FILE_ACTIONS
                    if summary.get(c)])
  attention = [
      f for f in data['files'] if _written(f, ('conflict',)) or _needs_person(f)
  ]
  if attention:
    out += ['### Files that need a person', '']
    out += _md_table(
        ['File', 'Action', 'Notes'],
        [[_code(f['path']),
          _code(f['category']),
          _file_notes(f) or f['kind']] for f in attention])

  # 8. Coverage
  out += [
      f'## {_SECTIONS[7]}', '',
      'What this report checked and what it could not. Anything not fully '
      'checked needs a human review or a `terraform plan`.', ''
  ]
  out += _md_table(['Area', 'Status', 'Detail'], [[
      _md(c['area']), f'{_COVERAGE_ICON.get(c["status"], "")} {c["status"]}',
      _md(c['detail'])
  ] for c in data['coverage']])

  # Appendix A
  out += [f'## {_SECTIONS[8]}', '']

  def section(title, head, rows):
    if rows:
      out.extend([f'### {title}', ''] + _md_table(head, rows))

  section('Mapped folders', ['Your folder', 'Kind', 'Upstream', 'Matched by'],
          [[
              _code(m['customer'] or '.'), m['kind'],
              _md(m['name']),
              _md(m['match'])
          ] for m in mappings])
  section('Version pins in your files', ['File', 'Pins', 'Blocks init'], [[
      _code(p['file']), '; '.join(
          _code(f'{x["name"]} {x["constraint"]}') +
          (f' → needs {_code(x["target"])}' if x['allows_target'] is
           False else '') for x in p['pins']) +
      (f'; release stamp {_md(p["marker"])}' if p['marker'] else ''),
      '🔴 yes' if p['blocks_init'] else 'no'
  ] for p in data.get('version_pins', [])])
  section('Providers', ['Name', 'Base', 'Target'],
          [[_md(p['name']),
            _code(p['base'] or ''),
            _code(p['target'] or '')] for p in data['providers']])
  section('Variable type changes',
          ['Stage', 'Variable', 'Base type', 'Target type'], [[
              _code(s['stage'] or '.'),
              _code(t['name']),
              _code(t['base']),
              _code(t['target'])
          ] for s in data['stage_variables'] for t in s['type_changed']])
  section(
      'Your module calls', ['Call', 'Module', 'Issue'],
      [[_code(h['call']), _code(h['module']),
        _md(h['issue'])] for h in data['module_interface']])
  if 'skipped' not in data['data_impact']:
    section('Factory data', ['File', 'Status', 'Detail'], [[
        _code(f['file']),
        _code(f['status']),
        _md('; '.join(f.get('errors') or [f.get('reason') or '']))
    ] for f in data['data_impact']['files']])
  section('Schema changes',
          ['Schema', 'Removed', 'Newly required', 'Type changed'], [[
              _code(s['path']),
              _md(', '.join(s['removed'])),
              _md(', '.join(s['required_added'])),
              _md(', '.join(s['type_changed']))
          ] for s in data['schema_changes']])
  section('Linked repositories', ['Folder', 'Kind', 'State'], [[
      _code(l['path']),
      _md(l['kind']),
      _md(('clean' if not l['git'].get('dirty'
                                      ) else f'{l["git"]["dirty"]} uncommitted'
          ) if l['git'].get('git') else l['git'].get('reason', ''))
  ] for l in data.get('linked_repos', [])])
  section('Add-on copies',
          ['Your file', 'Add-on file', 'Similarity', 'Upstream'], [[
              _code(a['file']),
              _code(a['addon_file']),
              str(a['similarity']),
              _md(a['status'])
          ] for a in data.get('addon_copies', [])])
  section(
      'Git references to Fabric', ['Ref', 'Sources'],
      [[_code(k), str(v)] for k, v in sorted(data['git_refs']['refs'].items())])
  if data['notes']:
    out += ['### Notes', ''] + [f'- {_prose(n)}' for n in data['notes']] + ['']
  git = data['repo']['git']
  section('Provenance', ['Item', 'Value'], [
      ['Tools digest', _code(data['tool']['digest'])],
      ['Base release', f'{_md(base)} (tree {_code(data["base"]["digest"])})'],
      [
          'Target release',
          f'{_md(target)} (tree {_code(data["target"]["digest"])})'
      ],
      [
          'Repository git',
          _md((git.get('head') or '') +
              (' (dirty)' if git.get('dirty') else ''))
          if git.get('git') else _md(git.get('reason', ''))
      ],
  ])

  # Appendix B
  out += [f'## {_SECTIONS[9]}', '']
  out += _md_table(
      ['File', 'Action', 'Kind', 'Notes'],
      [[_code(f['path']),
        _code(f['category']), f['kind'],
        _file_notes(f)] for f in data['files']]) or ['No changed files.', '']
  out += [
      '---', '', f'*Generated by `fast_upgrade.py` (tools '
      f'{_code(data["tool"]["digest"])}). Static analysis only: validate '
      'every stage with `terraform plan`.*', ''
  ]
  return '\n'.join(out)


BRIEF_TEXT = 220


def _clip_md(text, width):
  """_clip for Markdown: a code span cut in half is closed again."""
  text = _clip(text, width)
  if text.endswith('...') and text.count('`') % 2:
    text = text[:-3] + '`...'
  return text


def render_brief(plan, full_report='report.md'):
  """Returns the report condensed for an agent's chat answer.

  Everything a reader needs to act fits in one message: the verdict,
  counts, key points, every blocker and high finding with its fix, every
  finding in one table, stages, the breaking changes that apply, the
  upgrade plan and what was not checked. Per-finding detail, file lists
  and appendices stay in `full_report`. It avoids features chat views may
  not render (alerts, Mermaid, heading anchors).
  """
  data = shareable(plan)
  readiness, findings = data['readiness'], data['findings']
  counts, status = readiness['counts'], readiness['status']
  base, target = data['base']['version'], data['target']['version']
  icon = {'BLOCKED': '🔴', 'NEEDS WORK': '🟠'}.get(status, '🟢')
  out = [
      f'## FAST upgrade assessment: {_md(data["repo"]["name"])} '
      f'({_md(base)} → {_md(target)})', '',
      f'> {icon} **{status}**: {_md(readiness["summary"])}', '',
      ' · '.join(f'{_badge(s)} **{counts.get(s, 0)}**' for s in SEVERITIES), ''
  ]
  out += ['### Key points', '']
  out += [f'- {_prose(p)}' for p in readiness.get('highlights', [])] + ['']

  urgent = [f for f in findings if f['severity'] in ('blocker', 'high')]
  if urgent:
    out += ['### Start here', '']
    for i, f in enumerate(urgent, 1):
      out.append(f'{i}. {SEV_ICON[f["severity"]]} **{f["id"]}** '
                 f'{_prose(f["title"])}')
      if f['action']:
        out.append(f'   - {_prose(f["action"])}')
    out.append('')

  others = [f for f in findings if f['severity'] not in ('blocker', 'high')]
  if others:
    out += ['### Other findings', '']
    out += _md_table(['ID', 'Severity', 'Finding', 'What to do'], [[
        f['id'],
        _badge(f['severity']),
        _prose(f['title']),
        _prose(_clip_md(f['action'], 140)) if f['action'] else '—'
    ] for f in others])

  _, rows = _stage_rows(data)
  out += ['### By stage', '']
  out += _md_table(['Stage', 'Findings', 'IDs', 'Files from upstream'],
                   [[r[0], r[2], r[3], r[4]] for r in rows])

  relevant = [b for b in data['breaking_changes'] if b.get('relevant')]
  if relevant:
    out += [
        f'### Breaking changes that apply ({len(relevant)} of '
        f'{len(data["breaking_changes"])})', ''
    ]
    for b in relevant:
      text = re.sub(r'\[\[([^\]]+)\]\([^)]*\)\]', r'(\1)', b['text'])
      text = re.sub(r'\[([^\]]+)\]\([^)]*\)', r'\1', text)
      out.append(f'- **{_md(b["version"])}**: '
                 f'{_prose(_clip_md(text, BRIEF_TEXT))}')
      if b.get('impact'):
        out.append(f'  - Impact: {_prose(b["impact"])}')
    out.append('')

  out += ['### Upgrade plan', '']
  out += [
      f'{i}. {_prose(s["text"])}' for i, s in enumerate(data['checklist'], 1)
  ] + ['']

  gaps = [c for c in data['coverage'] if c['status'] != 'checked']
  if gaps:
    out += ['### Not fully checked', '']
    out += [
        f'- {_COVERAGE_ICON.get(c["status"], "")} **{_md(c["area"])}** '
        f'({c["status"]}): {_md(c["detail"])}' for c in gaps
    ] + ['']

  out += [
      f'*Static analysis only: validate every stage with `terraform '
      f'plan`. Details for each finding, every file and the appendices '
      f'are in the full report, {_code(full_report)}.*', ''
  ]
  return '\n'.join(out)


_TEMPLATE = r'''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>__TITLE__</title>
<style>
body{--bg:var(--background,#f8f9fa);--panel:var(--card,#fff);
--fg:var(--foreground,#202124);--muted:var(--muted-foreground,#5f6368);
--line:var(--border,#dadce0);--accent:var(--primary,#1a73e8);
--soft:color-mix(in srgb,var(--fg) 6%,transparent);
--blocker:#a50e0e;--high:#d93025;--medium:#e37400;--low:#1a73e8;--info:#5f6368;
--ok:#188038}
*{box-sizing:border-box}
body{margin:0;font:14px/1.5 "Google Sans",Roboto,"Segoe UI",Arial,sans-serif;
background:var(--bg);color:var(--fg)}
header{background:var(--panel);border-bottom:1px solid var(--line);padding:20px 32px}
header h1{margin:0 0 4px;font-size:22px;font-weight:500}
header .meta{color:var(--muted);font-size:13px}
main{max-width:1280px;margin:0 auto;padding:24px 32px 64px}
.banner{border-radius:8px;padding:16px 20px;color:#fff;display:flex;gap:16px;
align-items:center;margin-bottom:20px}
.banner .status{font-size:20px;font-weight:600;letter-spacing:.5px}
.banner.BLOCKED{background:var(--blocker)}
.banner.NEEDS-WORK{background:var(--medium)}
.banner.READY-WITH-REVIEW{background:var(--ok)}
.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(125px,1fr));
gap:12px;margin-bottom:20px}
.points{background:var(--panel);border:1px solid var(--line);border-radius:8px;
padding:12px 20px;margin-bottom:20px}
.points h2{margin:0 0 6px;font-size:15px}
.points ul{margin:0;padding-left:20px}.points li{margin:3px 0}
.card{background:var(--panel);border:1px solid var(--line);border-radius:8px;
padding:12px 16px;cursor:pointer}
.card .n{font-size:26px;font-weight:500}
.card .l{color:var(--muted);font-size:12px;text-transform:uppercase;letter-spacing:.4px}
.card.sel{outline:2px solid var(--accent)}
nav.tabs{display:flex;gap:4px;border-bottom:1px solid var(--line);margin-bottom:16px;
flex-wrap:wrap}
nav.tabs button{background:none;border:0;border-bottom:3px solid transparent;
padding:10px 14px;font:inherit;color:var(--muted);cursor:pointer}
nav.tabs button.on{color:var(--accent);border-bottom-color:var(--accent);font-weight:500}
section{display:none}section.on{display:block}
.toolbar{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin-bottom:12px}
.chip{border:1px solid var(--line);background:var(--panel);color:var(--fg);border-radius:16px;
padding:4px 12px;cursor:pointer;font:inherit;font-size:13px}
.chip.on{background:color-mix(in srgb,var(--accent) 12%,transparent);border-color:var(--accent);color:var(--accent)}
input[type=search],select{font:inherit;padding:6px 10px;border:1px solid var(--line);
border-radius:6px;background:var(--panel);color:var(--fg)}
input[type=search]{min-width:260px}
.sev{display:inline-block;min-width:64px;text-align:center;border-radius:4px;
color:#fff;font-size:11px;font-weight:600;padding:2px 6px;text-transform:uppercase}
.sev.blocker{background:var(--blocker)}.sev.high{background:var(--high)}
.sev.medium{background:var(--medium)}.sev.low{background:var(--low)}
.sev.info{background:var(--info)}
details.f{background:var(--panel);border:1px solid var(--line);border-radius:8px;
margin-bottom:8px}
details.f summary{padding:10px 14px;cursor:pointer;display:flex;gap:10px;
align-items:baseline;list-style:none}
details.f summary::-webkit-details-marker{display:none}
details.f summary .id{color:var(--muted);font-family:monospace;font-size:12px}
details.f summary .t{flex:1}
details.f summary .st{color:var(--muted);font-size:12px;font-family:monospace}
details.f .body{padding:0 14px 12px 88px}
.body h4{margin:10px 0 4px;font-size:12px;color:var(--muted);text-transform:uppercase}
.body pre,.mono{white-space:pre-wrap;word-break:break-word;font:12px/1.5
"Roboto Mono",Consolas,monospace;margin:0}
.body ul{margin:0;padding-left:18px;font:12px/1.6 "Roboto Mono",Consolas,monospace}
table{border-collapse:collapse;width:100%;background:var(--panel);
border:1px solid var(--line);border-radius:8px;overflow:hidden}
th,td{text-align:left;padding:7px 10px;border-bottom:1px solid var(--line);
vertical-align:top;font-size:13px}
th{background:var(--soft);font-weight:500}
td.mono{font-size:12px}
.stage{background:var(--panel);border:1px solid var(--line);border-radius:8px;
padding:12px 16px;margin-bottom:12px}
.stage h3{margin:0 0 6px;font-size:15px;font-family:"Roboto Mono",monospace}
.pill{display:inline-block;background:var(--soft);border-radius:10px;padding:1px 8px;
margin:2px 4px 2px 0;font-size:12px}
.check{display:flex;gap:10px;align-items:flex-start;background:var(--panel);
border:1px solid var(--line);border-radius:8px;padding:10px 14px;margin-bottom:6px}
.check input{margin-top:4px}.check.done span{text-decoration:line-through;color:var(--muted)}
.status-checked{color:var(--ok);font-weight:500}
.status-partial{color:var(--medium);font-weight:500}
.status-not{color:var(--high);font-weight:500}
.muted{color:var(--muted)}.right{margin-left:auto}
button.act{font:inherit;border:1px solid var(--line);background:var(--panel);color:var(--fg);
border-radius:6px;padding:6px 12px;cursor:pointer}
h2{font-size:17px;font-weight:500;margin:24px 0 8px}
footer{color:var(--muted);font-size:12px;margin-top:32px}
@media print{nav.tabs,.toolbar,button.act{display:none}section{display:block!important}
details.f{break-inside:avoid}body{background:#fff}}
</style>
</head>
<body>
<header><h1 id="title"></h1><div class="meta" id="meta"></div></header>
<main>
<div class="banner" id="banner"><div class="status" id="status"></div>
<div id="verdict"></div></div>
<div class="points"><h2>Key points</h2><ul id="points"></ul></div>
<div class="cards" id="cards"></div>
<nav class="tabs" id="tabs"></nav>
<section id="t-findings">
<div class="toolbar"><span id="sevchips"></span>
<select id="catsel"><option value="">All categories</option></select>
<select id="stagesel"><option value="">All stages</option></select>
<input type="search" id="q" placeholder="Search findings, files, text">
<button class="act" id="expand">Expand all</button>
<button class="act" id="csv">Export CSV</button>
<button class="act" onclick="window.print()">Print / PDF</button>
<span class="muted right" id="fcount"></span></div>
<div id="flist"></div>
</section>
<section id="t-stages"><div id="stages"></div></section>
<section id="t-files">
<div class="toolbar"><select id="fcat"><option value="">All actions</option></select>
<input type="search" id="fq" placeholder="Filter paths">
<span class="muted right" id="ffcount"></span></div>
<table><thead><tr><th>Path</th><th>Action</th><th>Kind</th><th>Notes</th></tr></thead>
<tbody id="ftable"></tbody></table>
<p class="muted" id="unchanged"></p>
</section>
<section id="t-breaking">
<div class="toolbar"><label><input type="checkbox" id="allbc"> Show changes that do
not affect this repository</label></div>
<table><thead><tr><th>Release</th><th>Scope</th><th>Change</th><th>Impact here</th></tr>
</thead><tbody id="bctable"></tbody></table>
<h2>Upgrade notes</h2><div id="unotes"></div>
</section>
<section id="t-checklist"><p class="muted">Progress is saved in this browser.</p>
<div id="checklist"></div></section>
<section id="t-coverage"><p>What this report checked, and what it could not.
Anything marked <b>not checked</b> needs a human review or a terraform plan.</p>
<table><thead><tr><th>Area</th><th>Status</th><th>Detail</th></tr></thead>
<tbody id="covtable"></tbody></table></section>
<section id="t-details"><div id="details"></div></section>
<footer id="footer"></footer>
</main>
<script type="application/json" id="data">__DATA__</script>
<script>
(function(){
'use strict';
var D=JSON.parse(document.getElementById('data').textContent);
var SEV=['blocker','high','medium','low','info'];
function $(id){return document.getElementById(id);}
function el(tag,attrs,kids){var e=document.createElement(tag);
 if(attrs)for(var k in attrs){if(k==='text')e.textContent=attrs[k];
 else if(k==='cls')e.className=attrs[k];else e.setAttribute(k,attrs[k]);}
 (kids||[]).forEach(function(c){if(c!=null)e.appendChild(typeof c==='string'?
 document.createTextNode(c):c);});return e;}
function sev(s){return el('span',{cls:'sev '+s,text:s});}
var R=D.readiness,F=D.findings;
$('title').textContent='FAST upgrade assessment: '+D.repo.name;
$('meta').textContent=D.base.version+' \u2192 '+D.target.version+
 ' \u00b7 generated '+D.generated+' \u00b7 tools '+D.tool.digest+
 ' \u00b7 detected release '+(D.repo.detected_version||'unknown')+' ('+
 D.repo.confidence+')';
$('banner').className='banner '+R.status.replace(/ /g,'-');
$('status').textContent=R.status;$('verdict').textContent=R.summary;
(R.highlights||[]).forEach(function(p){$('points').appendChild(el('li',
 {text:p}));});
// cards
var sevOn={};SEV.forEach(function(s){sevOn[s]=s!=='info';});
function card(n,l,fn,key){var c=el('div',{cls:'card'},[el('div',{cls:'n',
 text:String(n)}),el('div',{cls:'l',text:l})]);if(key)c.dataset.key=key;
 c.onclick=fn;$('cards').appendChild(c);return c;}
SEV.forEach(function(s){card(R.counts[s],s,function(){SEV.forEach(function(x){
 sevOn[x]=x===s;});show('findings');renderF();},'sev-'+s).style.borderTop=
 '4px solid var(--'+s+')';});
var S=D.summary,AC=D.apply_counts||{};
card(AC.updated||0,'files updated',
 function(){show('files');$('fcat').value='';renderFiles();});
card(AC.merges||0,'3-way merges',function(){show('files');$('fcat').value=
 'conflict';renderFiles();});
card(D.breaking_changes.filter(function(b){return b.relevant;}).length,
 'breaking changes',function(){show('breaking');});
// tabs
var TABS=[['findings','Findings ('+F.length+')'],['stages','By stage'],
 ['files','File actions'],['breaking','Breaking changes'],['checklist',
 'Checklist'],['coverage','Coverage'],['details','Details']];
TABS.forEach(function(t){var b=el('button',{text:t[1]});b.dataset.tab=t[0];
 b.onclick=function(){show(t[0]);};$('tabs').appendChild(b);});
function show(name){Array.prototype.forEach.call($('tabs').children,function(b){
 b.classList.toggle('on',b.dataset.tab===name);});TABS.forEach(function(t){
 $('t-'+t[0]).classList.toggle('on',t[0]===name);});}
// findings
SEV.forEach(function(s){var c=el('button',{cls:'chip',text:s+' ('+R.counts[s]+
 ')'});c.dataset.sev=s;c.onclick=function(){sevOn[s]=!sevOn[s];renderF();};
 $('sevchips').appendChild(c);});
function uniq(a){return a.filter(function(v,i){return a.indexOf(v)===i;}).sort();}
uniq(F.map(function(f){return f.category;})).forEach(function(c){
 $('catsel').appendChild(el('option',{value:c,text:c}));});
uniq(F.map(function(f){return f.stage;})).forEach(function(c){
 $('stagesel').appendChild(el('option',{value:c,text:c}));});
function findingNode(f){var body=el('div',{cls:'body'});
 if(f.detail){body.appendChild(el('h4',{text:'What we found'}));
  body.appendChild(el('pre',{text:f.detail}));}
 if(f.action){body.appendChild(el('h4',{text:'What to do'}));
  body.appendChild(el('div',{text:f.action}));}
 if(f.files.length){body.appendChild(el('h4',{text:'Files ('+f.files.length+
  ')'}));var ul=el('ul');f.files.slice(0,200).forEach(function(p){
  ul.appendChild(el('li',{text:p}));});if(f.files.length>200)ul.appendChild(
  el('li',{text:'\u2026 '+(f.files.length-200)+' more'}));body.appendChild(ul);}
 if(f.evidence){body.appendChild(el('h4',{text:'Evidence'}));
  body.appendChild(el('div',{cls:'mono',text:f.evidence}));}
 return el('details',{cls:'f'},[el('summary',null,[el('span',{cls:'id',
  text:f.id}),sev(f.severity),el('span',{cls:'t',text:f.title}),el('span',
  {cls:'st',text:f.stage+' \u00b7 '+f.category})]),body]);}
function matches(f){var q=$('q').value.toLowerCase();
 if(!sevOn[f.severity])return false;
 if($('catsel').value&&f.category!==$('catsel').value)return false;
 if($('stagesel').value&&f.stage!==$('stagesel').value)return false;
 if(!q)return true;return [f.id,f.title,f.detail,f.action,f.evidence,f.stage,
 f.files.join(' ')].join(' ').toLowerCase().indexOf(q)>=0;}
function renderF(){Array.prototype.forEach.call($('sevchips').children,function(c){
 c.classList.toggle('on',sevOn[c.dataset.sev]);});
 Array.prototype.forEach.call($('cards').children,function(c){
 c.classList.toggle('sel',!!c.dataset.key&&SEV.filter(function(s){return sevOn[s];
 }).join()===c.dataset.key.slice(4));});
 var list=F.filter(matches);$('flist').textContent='';
 list.forEach(function(f){$('flist').appendChild(findingNode(f));});
 $('fcount').textContent=list.length+' of '+F.length+' findings';
 if(!list.length)$('flist').appendChild(el('p',{cls:'muted',
 text:'No finding matches the filters.'}));}
['catsel','stagesel'].forEach(function(id){$(id).onchange=renderF;});
$('q').oninput=renderF;
$('expand').onclick=function(){var open=this.textContent==='Expand all';
 Array.prototype.forEach.call(document.querySelectorAll('#flist details'),
 function(d){d.open=open;});this.textContent=open?'Collapse all':'Expand all';};
$('csv').onclick=function(){function q(v){v=String(v);if(/^[=+\-@\t\r]/.test(v))
  v="'"+v;return '"'+v.replace(/"/g,'""')+
 '"';}var rows=[['id','severity','category','stage','title','action','files',
 'evidence','detail']].concat(F.filter(matches).map(function(f){return [f.id,
 f.severity,f.category,f.stage,f.title,f.action,f.files.join('\n'),f.evidence,
 f.detail];}));var blob=new Blob([rows.map(function(r){return r.map(q).join(',');
 }).join('\r\n')],{type:'text/csv'});var a=el('a',{href:URL.createObjectURL(blob),
 download:'fast-upgrade-findings.csv'});document.body.appendChild(a);a.click();
 a.remove();};
// stages
(function(){var byStage={};F.forEach(function(f){(byStage[f.stage]=
 byStage[f.stage]||[]).push(f);});var cats=D.stage_files||{};
 var names=uniq(Object.keys(byStage).concat(Object.keys(cats)));
 names.forEach(function(n){var box=el('div',{cls:'stage'},[el('h3',{text:n})]);
  var m=D.mappings.filter(function(x){return (x.customer||'.')===n;})[0];
  if(m)box.appendChild(el('div',{cls:'muted',text:m.kind+' \u2190 upstream '+
   m.name+' ('+m.match+')'}));
  var p=el('div');SEV.forEach(function(s){var k=(byStage[n]||[]).filter(
   function(f){return f.severity===s;}).length;if(k)p.appendChild(el('span',
   {cls:'pill',text:s+': '+k}));});Object.keys(cats[n]||{}).sort().forEach(
   function(c){p.appendChild(el('span',{cls:'pill',text:c+': '+cats[n][c]}));});
  box.appendChild(p);(byStage[n]||[]).filter(function(f){return f.severity!==
   'info';}).forEach(function(f){box.appendChild(findingNode(f));});
  $('stages').appendChild(box);});})();
// files
uniq(D.files.map(function(f){return f.category;})).forEach(function(c){
 $('fcat').appendChild(el('option',{value:c,text:c}));});
function renderFiles(){var c=$('fcat').value,q=$('fq').value.toLowerCase();
 var rows=D.files.filter(function(f){return (!c||f.category===c)&&(!q||
 f.path.toLowerCase().indexOf(q)>=0);});$('ftable').textContent='';
 rows.slice(0,2000).forEach(function(f){var notes=[];if(f.marker_only)
  notes.push('release stamp only');if(f.renamed_from)notes.push('renamed from '+
  f.renamed_from);if(f.renamed_to)notes.push('renamed to '+f.renamed_to);
  if(f.blocked)notes.push(f.blocked);$('ftable').appendChild(el('tr',null,[
  el('td',{cls:'mono',text:f.path}),el('td',{text:f.category}),el('td',
  {text:f.kind}),el('td',{text:notes.join('; ')})]));});
 $('ffcount').textContent=rows.length+' file(s)'+(rows.length>2000?
  ' (first 2000 shown)':'');}
$('fcat').onchange=renderFiles;$('fq').oninput=renderFiles;
$('unchanged').textContent=D.unchanged_files+
 ' file(s) identical in your repository and both releases are not listed.';
// breaking
function renderBC(){var all=$('allbc').checked;$('bctable').textContent='';
 D.breaking_changes.filter(function(b){return all||b.relevant;}).forEach(
 function(b){$('bctable').appendChild(el('tr',null,[el('td',{text:b.version}),
 el('td',{text:b.reason}),el('td',{text:b.text}),el('td',{text:b.impact||
 (b.relevant?'':'not used here')})]));});}
$('allbc').onchange=renderBC;
D.upgrading_notes.forEach(function(n){$('unotes').appendChild(el('details',
 {cls:'f'},[el('summary',null,[el('span',{cls:'t',text:n.versions.join(', ')})]),
 el('div',{cls:'body'},[el('pre',{text:n.text})])]));});
if(!D.upgrading_notes.length)$('unotes').appendChild(el('p',{cls:'muted',
 text:'None in this release range.'}));
// checklist
var KEY='fast-upgrade:'+D.repo.name+':'+D.base.version+':'+D.target.version;
var done={};try{done=JSON.parse(localStorage.getItem(KEY)||'{}');}catch(e){}
D.checklist.forEach(function(s){var cb=el('input',{type:'checkbox'});
 cb.checked=!!done[s.id];var row=el('label',{cls:'check'+(cb.checked?' done':'')},
 [cb,el('span',{text:s.text})]);cb.onchange=function(){done[s.id]=cb.checked;
 row.classList.toggle('done',cb.checked);try{localStorage.setItem(KEY,
 JSON.stringify(done));}catch(e){}};$('checklist').appendChild(row);});
// coverage
D.coverage.forEach(function(c){var cls=c.status==='checked'?'status-checked':
 c.status==='partial'?'status-partial':'status-not';$('covtable').appendChild(
 el('tr',null,[el('td',{text:c.area}),el('td',{cls:cls,text:c.status}),
 el('td',{text:c.detail})]));});
// details
function table(title,head,rows){if(!rows.length)return;$('details').appendChild(
 el('h2',{text:title}));var tb=el('tbody');rows.forEach(function(r){tb.appendChild(
 el('tr',null,r.map(function(v){return el('td',{cls:'mono',text:v==null?'':
 String(v)});})));});$('details').appendChild(el('table',null,[el('thead',null,
 [el('tr',null,head.map(function(h){return el('th',{text:h});}))]),tb]));}
table('Mapped folders',['Your folder','Kind','Upstream','Matched by'],
 D.mappings.map(function(m){return [m.customer||'.',m.kind,m.name,m.match];}));
table('Version pins in your files',['File','Pins','Release stamp','Blocks init'],
 (D.version_pins||[]).map(function(p){return [p.file,p.pins.map(function(x){
 return x.name+' '+x.constraint+(x.allows_target===false?' (target needs '+
 x.target+')':'');}).join('; '),p.marker||'',p.blocks_init?'yes':'no'];}));
table('Providers',['Name','Base','Target'],D.providers.map(function(p){
 return [p.name,p.base,p.target];}));
var tv=[];D.stage_variables.forEach(function(s){s.type_changed.forEach(function(t){
 tv.push([s.stage||'.',t.name,t.base,t.target]);});});
table('Variable type changes',['Stage','Variable','Base type','Target type'],tv);
table('Your module calls',['Call','Module','Issue'],D.module_interface.map(
 function(h){return [h.call,h.module,h.issue];}));
if(!D.data_impact.skipped)table('Factory data',['File','Status','Detail'],
 D.data_impact.files.map(function(f){return [f.file,f.status,(f.errors||
 [f.reason]).join('\n')];}));
table('Schema changes',['Schema','Removed','Newly required','Type changed'],
 D.schema_changes.map(function(s){return [s.path,s.removed.join(', '),
 s.required_added.join(', '),s.type_changed.join(', ')];}));
table('Linked repositories',['Folder','Kind','State'],(D.linked_repos||[]).map(
 function(l){return [l.path,l.kind,l.git.git?(l.git.dirty?l.git.dirty+
 ' uncommitted':'clean'):l.git.reason];}));
table('Add-on copies',['Your file','Add-on file','Similarity','Upstream'],
 (D.addon_copies||[]).map(function(a){return [a.file,a.addon_file,a.similarity,
 a.status];}));
table('Git references to Fabric',['Ref','Sources'],Object.keys(D.git_refs.refs)
 .map(function(k){return [k,D.git_refs.refs[k]];}));
table('Notes',['Note'],D.notes.map(function(n){return [n];}));
table('Provenance',['Item','Value'],[['tools digest',D.tool.digest],
 ['base release',D.base.version+' (tree '+D.base.digest+')'],['target release',
 D.target.version+' (tree '+D.target.digest+')'],['repository git',
 D.repo.git.git?(D.repo.git.head||'')+(D.repo.git.dirty?' (dirty)':''):
 D.repo.git.reason]]);
$('footer').textContent='Generated by fast_upgrade.py (tools '+D.tool.digest+
 '). Static analysis of the repository against the two upstream releases: it '+
 'does not read Terraform state. Validate every stage with terraform plan.';
show('findings');renderF();renderFiles();renderBC();
})();
</script>
</body>
</html>
'''

# --------------------------------------------------------------------------
# Inline HTML widget
# --------------------------------------------------------------------------
#
# The HTML report sized for an agent's chat: one card under 500 px tall
# for agents whose chat can embed HTML inline. It uses no external
# resources and follows the host's theme tokens when they exist (--card,
# --foreground, --border ...), with light-theme fallbacks elsewhere.

WIDGET_DETAIL = 900
WIDGET_FILES = 8


def _widget_text(text):
  """Markdown from findings and the CHANGELOG as plain text for the DOM."""
  return _plain(str(text)).strip()


def render_widget(plan, full_report='report.md', generated=None):
  """Returns the compact, interactive HTML summary to embed in a chat."""
  data = shareable(plan)
  generated = generated or datetime.datetime.now(
      datetime.timezone.utc).strftime('%Y-%m-%d %H:%M UTC')
  readiness = data['readiness']
  _, stages = _stage_data(data)
  widget = {
      'repo': data['repo']['name'],
      'base': data['base']['version'],
      'target': data['target']['version'],
      'digest': data['tool']['digest'],
      'generated': generated,
      'full_report': full_report,
      'status': readiness['status'],
      'summary': readiness['summary'],
      'counts': readiness['counts'],
      'highlights': [_widget_text(p) for p in readiness.get('highlights', [])],
      'findings': [{
          'id': f['id'],
          'severity': f['severity'],
          'category': f['category'],
          'stage': f['stage'],
          'title': _widget_text(f['title']),
          'action': _widget_text(f['action']),
          'detail': _clip_lines(_widget_text(f['detail']), WIDGET_DETAIL),
          'files': f['files'][:WIDGET_FILES],
          'more': max(0,
                      len(f['files']) - WIDGET_FILES),
      } for f in data['findings']],
      'stages': stages,
      'plan': [_widget_text(s['text']) for s in data['checklist']],
      'breaking': [{
          'version': b['version'],
          'reason': b.get('reason', ''),
          'text': _widget_text(b['text']),
          'impact': _widget_text(b.get('impact') or ''),
      } for b in data['breaking_changes'] if b.get('relevant')],
      'gaps': [c for c in data['coverage'] if c['status'] != 'checked'],
  }
  title = (f'FAST upgrade: {widget["repo"]} {widget["base"]} to '
           f'{widget["target"]}')
  return _fill(_WIDGET_TEMPLATE, title, widget)


def _clip_lines(text, width):
  return text if len(text) <= width else text[:width - 3].rstrip() + '...'


_WIDGET_TEMPLATE = r'''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>__TITLE__</title>
<style>
.w{--w-card:var(--card,#fff);--w-fg:var(--foreground,#202124);
--w-muted:var(--muted-foreground,#5f6368);--w-line:var(--border,#dadce0);
--w-accent:var(--primary,#1a73e8);--w-soft:color-mix(in srgb,var(--w-fg) 6%,transparent);
--blocker:#d93025;--high:#e8710a;--medium:#f9ab00;--low:#1a73e8;--info:#80868b;
--ok:#188038}
*{box-sizing:border-box}
html{font-family:system-ui,-apple-system,"Segoe UI",Roboto,Arial,sans-serif}
html,body{margin:0;background:transparent}
body{font-size:13px;line-height:1.45;color:var(--foreground,#202124);padding:6px}
.w{background:var(--w-card);color:var(--w-fg);border:1px solid var(--w-line);
border-radius:12px;padding:14px 16px 10px}
.top{display:flex;align-items:center;gap:10px;flex-wrap:wrap}
.title{font-weight:600;font-size:15px}
.meta{color:var(--w-muted);font-size:12px}
.verdict{margin-left:auto;color:#fff;font-weight:700;font-size:12px;
letter-spacing:.4px;border-radius:999px;padding:3px 10px}
.verdict.BLOCKED{background:var(--blocker)}.verdict.NEEDS-WORK{background:var(--high)}
.verdict.READY-WITH-REVIEW{background:var(--ok)}
.sum{color:var(--w-muted);margin:4px 0 8px}
.chips{display:flex;gap:6px;flex-wrap:wrap;margin-bottom:8px}
.chip{display:flex;align-items:center;gap:6px;border:1px solid var(--w-line);
background:transparent;color:inherit;border-radius:999px;padding:3px 10px;
font:inherit;font-size:12px;cursor:pointer}
.chip b{font-size:13px}.chip.off{opacity:.45}
.dot{width:9px;height:9px;border-radius:50%;display:inline-block;flex:none}
.dot.blocker{background:var(--blocker)}.dot.high{background:var(--high)}
.dot.medium{background:var(--medium)}.dot.low{background:var(--low)}
.dot.info{background:var(--info)}
.tabs{display:flex;gap:2px;border-bottom:1px solid var(--w-line);overflow-x:auto}
.tabs button{background:none;border:0;border-bottom:2px solid transparent;
color:var(--w-muted);font:inherit;font-size:12.5px;padding:6px 10px;cursor:pointer;
white-space:nowrap}
.tabs button.on{color:var(--w-accent);border-bottom-color:var(--w-accent);font-weight:600}
.panel{max-height:290px;overflow:auto;padding:8px 2px 4px}
.row{display:flex;gap:8px;align-items:baseline;padding:5px 0;
border-bottom:1px solid var(--w-soft)}
.id{font-family:ui-monospace,"Roboto Mono",monospace;font-size:11.5px;
color:var(--w-muted);flex:none}
.t{flex:1}.st{color:var(--w-muted);font-size:11.5px;font-family:ui-monospace,monospace}
.act{color:var(--w-muted);font-size:12px;margin:1px 0 0 17px}
.item{padding:5px 0;border-bottom:1px solid var(--w-soft)}
.item .row{border:0;padding:0}
details{border-bottom:1px solid var(--w-soft)}
details summary{list-style:none;cursor:pointer;display:flex;gap:8px;
align-items:baseline;padding:5px 0}
details summary::-webkit-details-marker{display:none}
details .body{padding:0 0 8px 17px;font-size:12px}
.body h4{margin:6px 0 2px;font-size:11px;text-transform:uppercase;
color:var(--w-muted);letter-spacing:.3px}
.body pre{white-space:pre-wrap;word-break:break-word;margin:0;
font:11.5px/1.45 ui-monospace,"Roboto Mono",monospace}
.tools{display:flex;gap:6px;margin-bottom:4px}
.tools input{flex:1;font:inherit;font-size:12px;padding:4px 8px;
border:1px solid var(--w-line);border-radius:6px;background:transparent;color:inherit}
table{border-collapse:collapse;width:100%;font-size:12px}
th,td{text-align:left;padding:5px 6px;border-bottom:1px solid var(--w-soft);
vertical-align:top}
th{color:var(--w-muted);font-weight:600}
.mono{font-family:ui-monospace,"Roboto Mono",monospace;font-size:11.5px}
ul.k{margin:0 0 6px;padding-left:18px}ul.k li{margin:2px 0}
label.c{display:flex;gap:8px;align-items:flex-start;padding:4px 0;
border-bottom:1px solid var(--w-soft)}
label.c input{margin-top:3px}label.c.done span{text-decoration:line-through;
color:var(--w-muted)}
.foot{color:var(--w-muted);font-size:11px;margin-top:6px}
.empty{color:var(--w-muted);padding:8px 0}
</style>
</head>
<body>
<div class="w">
<div class="top"><div><div class="title" id="title"></div>
<div class="meta" id="meta"></div></div><span class="verdict" id="verdict"></span></div>
<div class="sum" id="sum"></div>
<div class="chips" id="chips"></div>
<div class="tabs" id="tabs"></div>
<div class="panel" id="panel"></div>
<div class="foot" id="foot"></div>
</div>
<script type="application/json" id="data">__DATA__</script>
<script>
(function(){
'use strict';
var D=JSON.parse(document.getElementById('data').textContent);
var SEV=['blocker','high','medium','low','info'];
var on={};SEV.forEach(function(s){on[s]=true;});
function $(id){return document.getElementById(id);}
function el(tag,cls,text,kids){var e=document.createElement(tag);if(cls)e.className=cls;
 if(text!=null)e.textContent=text;(kids||[]).forEach(function(k){if(k)e.appendChild(k);});
 return e;}
function dot(s){return el('span','dot '+s);}
$('title').textContent='FAST upgrade · '+D.repo;
$('meta').textContent=D.base+' \u2192 '+D.target+' · '+D.generated;
$('verdict').textContent=D.status;$('verdict').className='verdict '+
 D.status.replace(/ /g,'-');
$('sum').textContent=D.summary;
SEV.forEach(function(s){var c=el('button','chip',null,[dot(s),el('b',null,
 String(D.counts[s]||0)),el('span',null,s)]);c.title='Show or hide '+s+' findings';
 c.onclick=function(){on[s]=!on[s];c.classList.toggle('off',!on[s]);show('findings');};
 $('chips').appendChild(c);});
var TABS=[['start','Start here'],['findings','Findings ('+D.findings.length+')'],
 ['stages','Stages'],['plan','Plan'],['breaking','Breaking ('+D.breaking.length+')'],
 ['gaps','Not checked ('+D.gaps.length+')']];
var current='start';
TABS.forEach(function(t){var b=el('button',null,t[1]);b.dataset.t=t[0];
 b.onclick=function(){show(t[0]);};$('tabs').appendChild(b);});
function show(name){current=name;Array.prototype.forEach.call($('tabs').children,
 function(b){b.classList.toggle('on',b.dataset.t===name);});var p=$('panel');
 p.textContent='';p.scrollTop=0;R[name](p);}
function finding(f){var body=el('div','body');
 if(f.detail){body.appendChild(el('h4',null,'What we found'));
  body.appendChild(el('pre',null,f.detail));}
 if(f.action){body.appendChild(el('h4',null,'What to do'));
  body.appendChild(el('div',null,f.action));}
 if(f.files.length){body.appendChild(el('h4',null,'Files'));
  var pre=f.files.join('\n')+(f.more?'\n\u2026 '+f.more+' more in the full report':'');
  body.appendChild(el('pre',null,pre));}
 return el('details',null,null,[el('summary',null,null,[dot(f.severity),
  el('span','id',f.id),el('span','t',f.title),el('span','st',f.stage)]),body]);}
var R={
 start:function(p){if(D.highlights.length){var ul=el('ul','k');D.highlights.forEach(
  function(h){ul.appendChild(el('li',null,h));});p.appendChild(ul);}
  var u=D.findings.filter(function(f){return f.severity==='blocker'||
  f.severity==='high';});if(!u.length){p.appendChild(el('div','empty',
  'No blocker or high finding.'));return;}
  u.forEach(function(f){p.appendChild(el('div','item',null,[el('div','row',null,
  [dot(f.severity),el('span','id',f.id),el('span','t',f.title)]),f.action?
  el('div','act','\u2192 '+f.action):null]));});},
 findings:function(p){var q=el('input');q.placeholder='Search findings and files';
  q.type='search';var list=el('div');p.appendChild(el('div','tools',null,[q]));
  p.appendChild(list);function draw(){list.textContent='';var s=q.value.toLowerCase();
  var rows=D.findings.filter(function(f){return on[f.severity]&&(!s||[f.id,f.title,
  f.detail,f.action,f.stage,f.files.join(' ')].join(' ').toLowerCase().indexOf(s)>=0);});
  rows.forEach(function(f){list.appendChild(finding(f));});if(!rows.length)
  list.appendChild(el('div','empty','No finding matches.'));}q.oninput=draw;draw();},
 stages:function(p){var tb=el('tbody');D.stages.forEach(function(s){var c=el('td');
  SEV.forEach(function(k){if(s.counts[k]){c.appendChild(dot(k));c.appendChild(
  document.createTextNode(' '+s.counts[k]+'  '));}});tb.appendChild(el('tr',null,null,
  [el('td','mono',s.name),c,el('td','mono',s.ids.join(', ')||'\u2014'),
  el('td',null,s.files||'\u2014')]));});var h=el('tr');['Stage','Findings','IDs',
  'Files from upstream'].forEach(function(t){h.appendChild(el('th',null,t));});
  p.appendChild(el('table',null,null,[el('thead',null,null,[h]),tb]));},
 plan:function(p){var key='fast-upgrade:'+D.repo+':'+D.base+':'+D.target,done={};
  try{done=JSON.parse(localStorage.getItem(key)||'{}');}catch(e){}
  D.plan.forEach(function(t,i){var cb=el('input');cb.type='checkbox';cb.checked=!!done[i];
  var row=el('label','c'+(cb.checked?' done':''),null,[cb,el('span',null,(i+1)+'. '+t)]);
  cb.onchange=function(){done[i]=cb.checked;row.classList.toggle('done',cb.checked);
  try{localStorage.setItem(key,JSON.stringify(done));}catch(e){}};p.appendChild(row);});},
 breaking:function(p){if(!D.breaking.length){p.appendChild(el('div','empty',
  'No breaking change applies to this repository.'));return;}
  D.breaking.forEach(function(b){var body=el('div','body',null,[el('div',null,b.text)]);
  if(b.impact){body.appendChild(el('h4',null,'Impact on you'));body.appendChild(
  el('div',null,b.impact));}p.appendChild(el('details',null,null,[el('summary',null,
  null,[el('span','id',b.version),el('span','t',b.text.length>110?b.text.slice(0,107)+
  '\u2026':b.text),el('span','st',b.reason)]),body]));});},
 gaps:function(p){if(!D.gaps.length){p.appendChild(el('div','empty',
  'Everything in scope was checked.'));return;}D.gaps.forEach(function(g){
  p.appendChild(el('div','row',null,[el('span',null,g.status==='partial'?'\u26a0\ufe0f':
  '\u274c'),el('span','t',null,[el('b',null,g.area+': '),document.createTextNode(
  g.detail)])]));});}
};
$('foot').textContent='Static analysis only: validate every stage with terraform '+
 'plan. Full detail, every file and the appendices: '+D.full_report+' · tools '+D.digest;
show('start');
})();
</script>
</body>
</html>
'''
