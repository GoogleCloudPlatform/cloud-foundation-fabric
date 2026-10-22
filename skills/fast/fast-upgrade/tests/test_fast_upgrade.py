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
"""Tests for the fast-upgrade frozen tools and skill documents.

Run with: uv run --with pyyaml --with jsonschema --with pytest -m pytest \
            skills/fast/fast-upgrade/tests -q
      or: python3 -m pytest skills/fast/fast-upgrade/tests -q
          (Python >= 3.10 with PyYAML, jsonschema and pytest installed)

The scripts under test declare their dependencies inline (PEP 723), but
this file imports them, so the `--with` flags supply the dependencies here.

Fixtures are generated in temporary folders, never committed: two small
synthetic upstream releases (v1.0.0 and v2.0.0) and customer repositories
built from them in several layouts. The integration tests at the end run
against real Fabric releases and are skipped unless FAST_UPGRADE_FABRIC_REPO
points to a Fabric clone that has the release tags (FAST_UPGRADE_BASE and
FAST_UPGRADE_TARGET, default v57.0.0 and v59.0.0).
"""

import contextlib
import copy
import io
import json
import os
import posixpath
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import textwrap
import unittest
import warnings
from unittest import mock

_BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
sys.path.insert(0, os.path.join(_BASE, 'scripts'))

import factory_data  # noqa: E402
import fast_upgrade as fu  # noqa: E402
import hcl_lite  # noqa: E402
import plan_review  # noqa: E402
import provenance  # noqa: E402
import release_notes  # noqa: E402
import report  # noqa: E402

needs_data = unittest.skipUnless(factory_data.available(),
                                 'needs PyYAML and jsonschema')
needs_git = unittest.skipUnless(shutil.which('git'), 'needs git')

V1, V2 = 'v1.0.0', 'v2.0.0'
FABRIC_GIT = ('git::https://github.com/GoogleCloudPlatform/'
              'cloud-foundation-fabric.git')
SAFE = ('upstream-changed', 'upstream-added', 'upstream-deleted', 'unchanged',
        'already-updated', 'customer-changed', 'customer-added',
        'customer-deleted')
DELTA = ('unchanged', 'customer-changed', 'customer-added', 'customer-deleted')


def _d(text):
  return textwrap.dedent(text).lstrip('\n')


# --------------------------------------------------------------------------
# Synthetic upstream releases
# --------------------------------------------------------------------------

DEFAULT_VERSIONS = _d('''
    # Fabric release: @@V@@

    terraform {
      required_version = ">= 1.10.0"
      required_providers {
        google = {
          source  = "hashicorp/google"
          version = "@@G@@"
        }
        google-beta = {
          source  = "hashicorp/google-beta"
          version = "@@G@@"
        }
      }
    }
    ''')
MODULE_VERSIONS = _d('''
    # Fabric release: @@V@@

    terraform {
      required_version = ">= 1.10.0"
    }
    ''')
CHANGELOG_V1 = _d('''
    # Changelog

    ## [v1.0.0] - 2025-12-01

    ### BREAKING CHANGES

    - `modules/project`: first release note, never selected from v1.0.0.
    ''')
CHANGELOG_V2 = _d('''
    # Changelog

    All notable changes to this project will be documented in this file.

    ## [Unreleased]

    ### BREAKING CHANGES

    - `modules/project`: unreleased change, never selected.

    ## [v2.0.0] - 2026-02-01

    ### BREAKING CHANGES

    - `modules/project`: `custom_roles` variable type changed from `map(list(string))`
      to `map(object({ permissions = list(string) }))`. [[#12](https://github.com/example/fabric/pull/12)]
    - `modules/old-mod`: module renamed to `new-mod`. [[#13](https://github.com/example/fabric/pull/13)]
    - `modules/net-vpc`: `subnets_legacy` removed. [[#14](https://github.com/example/fabric/pull/14)]
    - `fast/stages/2-project-factory`: bucket `description` removed from the project schema.
    `fast/stages/2-networking`: unbulleted change to a stage not in use.
    - Minimum `google` provider version is now 8.0.0.

    ### FAST

    - [[#20](https://github.com/example/fabric/pull/20)] Improve org setup ([someone](https://github.com/someone)) <!-- 2026-01-10 10:00:00+00:00 -->

    ## [v1.1.0] - 2026-01-15

    ### BREAKING CHANGES

    - `fast/stages/0-org-setup`: variable `legacy_flag` removed. <!-- a note -->

    ## [v1.0.0] - 2025-12-01

    ### BREAKING CHANGES

    - `modules/project`: first release note, never selected from v1.0.0.
    ''')
UPGRADING_V1 = _d('''
    # FAST release upgrading notes

    > v0.9.0 notes, never selected.
    ''')
UPGRADING_V2 = UPGRADING_V1 + _d('''

    > v1.1.0 removes `legacy_flag` from stage `0-org-setup`.

    ## v2.0.0

    Copy the moved blocks of `0-org-setup` before planning.
    ''')
ORG_MAIN_V1 = _d('''
    module "organization" {
      source          = "../../../modules/organization"
      organization_id = var.organization_id
    }

    module "automation-project" {
      source       = "../../../modules/project"
      name         = "automation"
      custom_roles = var.custom_roles
    }
    ''')
ORG_MAIN_V2 = _d('''
    module "organization" {
      source          = "../../../modules/organization"
      organization_id = var.organization_id
    }

    module "automation-project" {
      source       = "../../../modules/project"
      name         = "automation"
      custom_roles = var.custom_roles
      parent       = "organizations/${var.organization_id}"
    }
    ''')
ORG_VARIABLES_V1 = _d('''
    variable "organization_id" {
      description = "Organization id."
      type        = string
    }

    variable "custom_roles" {
      description = "Custom roles."
      type        = map(list(string))
      default     = {}
    }

    variable "legacy_flag" {
      description = "Removed in v1.1.0."
      type        = bool
      default     = false
    }
    ''')
ORG_VARIABLES_V2 = _d('''
    variable "organization_id" {
      description = "Organization id."
      type        = string
    }

    variable "custom_roles" {
      description = "Custom roles."
      type = map(object({
        permissions = list(string) # granted permissions
      }))
      default = {}
    }

    variable "billing_account" {
      description = "Billing account id."
      type        = string
    }
    ''')
ORG_OUTPUTS = 'output "organization_id" {\n  value = var.organization_id\n}\n'
ORG_BILLING = _d('''
    module "billing" {
      source          = "../../../modules/billing-account"
      billing_account = var.billing_account
    }
    ''')
ORG_README = '# Organization setup\n\nThis stage ships with FAST @@V@@.\n'
MOVED_OLD = 'moved {\n  from = module.org\n  to   = module.organization\n}\n'
MOVED_NEW = _d('''
    moved {
      from = module.automation
      to   = module.automation-project
    }
    ''')
PF_MAIN = _d('''
    module "factory" {
      source = "../../../modules/project-factory"
      data   = var.factories_config
    }
    ''')
PF_VARIABLES = _d('''
    variable "factories_config" {
      type    = any
      default = {}
    }
    ''')
PF_LEGACY = 'locals {\n  legacy = true\n}\n'
PROD_APP = _d('''
    # yaml-language-server: $schema=../../schemas/project.schema.json
    name: prod-app
    buckets:
      logs:
        location: EU
    ''')
SCHEMA_V1 = {
    '$schema': 'http://json-schema.org/draft-07/schema#',
    'type': 'object',
    'additionalProperties': False,
    'properties': {
        'name': {
            'type': 'string'
        },
        'labels': {
            'type': 'object'
        },
        'buckets': {
            'type': 'object',
            'additionalProperties': {
                '$ref': '#/definitions/bucket'
            },
        },
    },
    'definitions': {
        'bucket': {
            'type': 'object',
            'additionalProperties': False,
            'properties': {
                'location': {
                    'type': 'string'
                },
                'description': {
                    'type': 'string'
                },
            },
        },
    },
}
SCHEMA_V2 = copy.deepcopy(SCHEMA_V1)
del SCHEMA_V2['definitions']['bucket']['properties']['description']
SCHEMA_V2['properties']['labels'] = {'type': 'array'}
SCHEMA_V2['properties']['notification_config'] = {
    'type': 'object',
    'required': ['topic'],
    'properties': {
        'topic': {
            'type': 'string'
        }
    },
}
SCHEMA_V2['required'] = ['name']
PROJECT_MAIN_V1 = _d('''
    resource "google_project" "project" {
      name       = var.name
      project_id = var.name
    }

    resource "google_project_iam_custom_role" "roles" {
      for_each    = var.custom_roles
      role_id     = each.key
      title       = each.key
      permissions = each.value
    }
    ''')
PROJECT_MAIN_V2 = _d('''
    resource "google_project" "project" {
      name       = var.name
      project_id = var.name
      folder_id  = var.parent
    }

    resource "google_project_iam_custom_role" "roles" {
      for_each    = var.custom_roles
      role_id     = each.key
      title       = each.key
      permissions = each.value.permissions
    }

    module "billing" {
      source          = "../billing-account"
      billing_account = "000000-000000-000000"
    }
    ''')
PROJECT_VARIABLES_V1 = _d('''
    variable "name" {
      type = string
    }

    variable "custom_roles" {
      type    = map(list(string))
      default = {}
    }
    ''')
PROJECT_VARIABLES_V2 = _d('''
    variable "name" {
      type = string
    }

    variable "custom_roles" {
      type = map(object({
        permissions = list(string)
      }))
      default = {}
    }

    variable "parent" {
      type = string
    }
    ''')
PROJECT_OUTPUTS = 'output "id" {\n  value = google_project.project.project_id\n}\n'
HELPER_V1 = '#!/bin/sh\necho "first"\n'
HELPER_V2 = '#!/bin/sh\necho "second"\n'
ORGANIZATION_MAIN = _d('''
    resource "google_organization_iam_member" "viewer" {
      org_id = var.organization_id
      role   = "roles/viewer"
      member = "group:viewers@example.com"
    }
    ''')
ORGANIZATION_VARIABLES = 'variable "organization_id" {\n  type = string\n}\n'
PFM_MAIN_V1 = _d('''
    module "projects" {
      source   = "../project"
      for_each = var.data
      name     = each.key
    }
    ''')
PFM_MAIN_V2 = _d('''
    module "projects" {
      source   = "../project"
      for_each = var.data
      name     = each.key
      parent   = "folders/1234"
    }
    ''')
PFM_VARIABLES = 'variable "data" {\n  type    = any\n  default = {}\n}\n'
SA_MAIN = 'resource "google_service_account" "sa" {\n  account_id = var.name\n}\n'
SA_VARIABLES = 'variable "name" {\n  type = string\n}\n'
SA_OUTPUTS = 'output "email" {\n  value = google_service_account.sa.email\n}\n'
VPC_MAIN = 'resource "google_compute_network" "n" {\n  name = var.network_name\n}\n'
VPC_VARIABLES = 'variable "network_name" {\n  type = string\n}\n'
COREDNS_MAIN = 'locals {\n  coredns = var.config\n}\n'
COREDNS_VARIABLES = 'variable "config" {\n  type    = string\n  default = ""\n}\n'
BILLING_MAIN = _d('''
    resource "google_billing_account_iam_member" "user" {
      billing_account_id = var.billing_account
      role               = "roles/billing.user"
      member             = "group:billing@example.com"
    }
    ''')
BILLING_VARIABLES = 'variable "billing_account" {\n  type = string\n}\n'


def upstream_files(version):
  """Returns {path: content} for a synthetic upstream release.

  v1.0.0 -> v2.0.0 changes: a module variable type (custom_roles), a new
  required module variable (parent), a removed and an added stage variable,
  a schema that drops `buckets.*.description`, a declared module rename
  (old-mod -> new-mod), a new module dependency (billing-account), a moved
  block, a provider bump, version-marker-only changes, a deleted stage
  file, a changed executable script and a new stage.
  """
  new = version == V2
  google = '>= 8.0.0, < 9.0.0' if new else '>= 7.0.0, < 8.0.0'
  mod_versions = MODULE_VERSIONS.replace('@@V@@', version)
  fast_marker = f'# FAST release: {version}\n'
  schema = SCHEMA_V2 if new else SCHEMA_V1
  files = {
      'default-versions.tf':
          DEFAULT_VERSIONS.replace('@@V@@', version).replace('@@G@@', google),
      'CHANGELOG.md':
          CHANGELOG_V2 if new else CHANGELOG_V1,
      'fast/README.md':
          '# FAST\n',
      'fast/stages/UPGRADING.md':
          UPGRADING_V2 if new else UPGRADING_V1,
      'fast/stages/0-org-setup/fast_version.txt':
          fast_marker,
      'fast/stages/0-org-setup/README.md':
          ORG_README.replace('@@V@@', version),
      'fast/stages/0-org-setup/main.tf':
          ORG_MAIN_V2 if new else ORG_MAIN_V1,
      'fast/stages/0-org-setup/variables.tf':
          ORG_VARIABLES_V2 if new else ORG_VARIABLES_V1,
      'fast/stages/0-org-setup/outputs.tf':
          ORG_OUTPUTS,
      'fast/stages/0-org-setup/moved/v0.9.0-v1.0.0.tf':
          MOVED_OLD,
      'fast/stages/2-project-factory/fast_version.txt':
          fast_marker,
      'fast/stages/2-project-factory/main.tf':
          PF_MAIN,
      'fast/stages/2-project-factory/variables.tf':
          PF_VARIABLES,
      'fast/stages/2-project-factory/schemas/project.schema.json':
          json.dumps(schema, indent=2) + '\n',
      'fast/stages/2-project-factory/data/projects/prod-app.yaml':
          PROD_APP,
      'fast/extras/0-cicd-github/fast_version.txt':
          fast_marker,
      'fast/extras/0-cicd-github/main.tf':
          'locals {\n  cicd = "github"\n}\n',
      'modules/project/main.tf':
          PROJECT_MAIN_V2 if new else PROJECT_MAIN_V1,
      'modules/project/variables.tf':
          PROJECT_VARIABLES_V2 if new else PROJECT_VARIABLES_V1,
      'modules/project/outputs.tf':
          PROJECT_OUTPUTS,
      'modules/project/versions.tf':
          mod_versions,
      'modules/project/scripts/helper.sh':
          HELPER_V2 if new else HELPER_V1,
      'modules/organization/main.tf':
          ORGANIZATION_MAIN,
      'modules/organization/variables.tf':
          ORGANIZATION_VARIABLES,
      'modules/organization/versions.tf':
          mod_versions,
      'modules/project-factory/main.tf':
          PFM_MAIN_V2 if new else PFM_MAIN_V1,
      'modules/project-factory/variables.tf':
          PFM_VARIABLES,
      'modules/project-factory/versions.tf':
          mod_versions,
      'modules/net-vpc/main.tf':
          VPC_MAIN,
      'modules/net-vpc/variables.tf':
          VPC_VARIABLES,
      'modules/net-vpc/versions.tf':
          mod_versions,
      'modules/net-vpc/README.md':
          '# net-vpc\n',
      'modules/cloud-config-container/coredns/main.tf':
          COREDNS_MAIN,
      'modules/cloud-config-container/coredns/variables.tf':
          COREDNS_VARIABLES,
  }
  sa = 'new-mod' if new else 'old-mod'
  files.update({
      f'modules/{sa}/main.tf': SA_MAIN,
      f'modules/{sa}/variables.tf': SA_VARIABLES,
      f'modules/{sa}/outputs.tf': SA_OUTPUTS,
      f'modules/{sa}/versions.tf': mod_versions,
  })
  if new:
    files.update({
        'fast/stages/0-org-setup/billing.tf': ORG_BILLING,
        'fast/stages/0-org-setup/moved/v1.0.0-v2.0.0.tf': MOVED_NEW,
        'fast/stages/3-new-stage/fast_version.txt': fast_marker,
        'fast/stages/3-new-stage/main.tf': 'locals {\n  new = true\n}\n',
        'modules/billing-account/main.tf': BILLING_MAIN,
        'modules/billing-account/variables.tf': BILLING_VARIABLES,
        'modules/billing-account/versions.tf': mod_versions,
    })
  else:
    files['fast/stages/2-project-factory/legacy.tf'] = PF_LEGACY
  return files


# Customer additions shared by several archetypes.
TEAM_A = _d('''
    # yaml-language-server: $schema=../../schemas/project.schema.json
    name: team-a
    buckets:
      state:
        location: EU
        description: Terraform state
    ''')
TEAM_B = _d('''
    # yaml-language-server: $schema=../../schemas/project.schema.json
    name: team-b
    ''')
A_EXTRA = {
    'fast/stages/2-project-factory/data/projects/team-a.yaml':
        TEAM_A,
    'fast/stages/2-project-factory/data/projects/team-b.yaml':
        TEAM_B,
    'fast/stages/2-project-factory/data/projects/team-c.yaml':
        'name: team-c\n',
    'fast/stages/0-org-setup/terraform.tfvars':
        'organization_id = "123456"\nlegacy_flag     = true\n',
}
# Archetype B: edits on both sides.
B_EDITS = {
    'modules/project/main.tf': ('  permissions = each.value\n',
                                '  permissions = distinct(each.value)\n'),
    'fast/stages/0-org-setup/variables.tf':
        ('variable "organization_id" {',
         '# Managed by the platform team.\nvariable "organization_id" {'),
    'modules/old-mod/main.tf':
        ('  account_id = var.name\n', '  account_id   = var.name\n'
         '  display_name = "Customer SA"\n'),
    'fast/stages/2-project-factory/legacy.tf':
        ('  legacy = true\n', '  legacy = false\n'),
}
B_EXTRA = {'fast/stages/0-org-setup/billing.tf': 'locals {\n  mine = 1\n}\n'}
B_REMOVE = ('fast/stages/0-org-setup/README.md', 'modules/net-vpc/README.md')

# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------

_GIT_ENV = dict(os.environ, GIT_CONFIG_GLOBAL=os.devnull,
                GIT_CONFIG_NOSYSTEM='1', GIT_AUTHOR_NAME='test',
                GIT_AUTHOR_EMAIL='test@example.com', GIT_COMMITTER_NAME='test',
                GIT_COMMITTER_EMAIL='test@example.com')


def _git(repo, *args, check=True):
  proc = subprocess.run(['git', '-C', repo] + list(args), capture_output=True,
                        text=True, env=_GIT_ENV)
  if check and proc.returncode:
    raise AssertionError(f'git {" ".join(args)} failed: {proc.stderr}')
  return proc


def _commit_all(repo, message='snapshot'):
  if not os.path.isdir(os.path.join(repo, '.git')):
    _git(repo, 'init', '-q', '-b', 'main')
  _git(repo, 'add', '-A')
  _git(repo, 'commit', '-q', '--no-verify', '--allow-empty', '-m', message)


def _write(root, rel_path, content, mode=None):
  path = os.path.join(root, *rel_path.split('/'))
  os.makedirs(os.path.dirname(path), exist_ok=True)
  with open(path, 'w', encoding='utf-8', newline='') as f:
    f.write(content)
  if mode is not None:
    os.chmod(path, mode)
  return path


def _read(root, rel_path):
  with open(os.path.join(root, *rel_path.split('/')), encoding='utf-8',
            newline='') as f:
    return f.read()


def _exists(root, rel_path):
  return os.path.lexists(os.path.join(root, *rel_path.split('/')))


def _make_tree(root, files):
  for rel_path, content in files.items():
    _write(root, rel_path, content, 0o755 if rel_path.endswith('.sh') else None)
  return root


def _tree_digest(root):
  """Digest of every file under root (excluding .git), for no-op checks."""
  entries = []
  for dirpath, dirnames, filenames in os.walk(root):
    dirnames[:] = sorted(d for d in dirnames if d != '.git')
    for name in sorted(filenames):
      path = os.path.join(dirpath, name)
      with open(path, 'rb') as f:
        entries.append((os.path.relpath(path, root), f.read()))
  return entries


def _run(module, argv, stdin_text=None):
  """Runs module.main(argv) capturing output. Returns (code, out, err)."""
  out, err = io.StringIO(), io.StringIO()
  old_stdin = sys.stdin
  if stdin_text is not None:
    sys.stdin = io.StringIO(stdin_text)
  try:
    with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
      code = module.main(argv)
  finally:
    sys.stdin = old_stdin
  return code, out.getvalue(), err.getvalue()


_TMP = None
UP = {}


def setUpModule():  # pylint: disable=invalid-name
  global _TMP
  _TMP = tempfile.mkdtemp(prefix='fast-upgrade-test-')
  for version in (V1, V2):
    UP[version] = _make_tree(os.path.join(_TMP, 'upstream', version),
                             upstream_files(version))


def tearDownModule():  # pylint: disable=invalid-name
  shutil.rmtree(_TMP, ignore_errors=True)


class _Case(unittest.TestCase):
  """Temporary folder per test, plus customer repository builders."""

  def setUp(self):
    self.tmp = tempfile.mkdtemp(prefix='fast-upgrade-case-')
    self.addCleanup(shutil.rmtree, self.tmp, True)

  def path(self, *parts):
    return os.path.join(self.tmp, *parts)

  def upstream_copy(self, version, name, extra=None):
    """A modified copy of a synthetic upstream release."""
    root = self.path(name)
    shutil.copytree(UP[version], root, symlinks=True)
    _make_tree(root, extra or {})
    return root

  def fork(self, name='repo', commit=True, extra=None, remove=(), edits=None,
           base=None):
    """A customer repository: the base release's fast/ and modules/."""
    repo = self.path(name)
    for top in ('fast', 'modules'):
      shutil.copytree(os.path.join(base or UP[V1], top),
                      os.path.join(repo, top), symlinks=True)
    for rel_path, content in (extra or {}).items():
      _write(repo, rel_path, content)
    for rel_path in remove:
      os.unlink(os.path.join(repo, *rel_path.split('/')))
    for rel_path, (old, new) in (edits or {}).items():
      text = _read(repo, rel_path)
      self.assertIn(old, text, rel_path)
      _write(repo, rel_path, text.replace(old, new, 1))
    if commit:
      _commit_all(repo)
    return repo

  def reorganized(self, extra=None):
    """Archetype C: stages renamed under stages/, modules in tf-modules/."""
    repo = self.path('reorg')
    shutil.copytree(os.path.join(UP[V1], 'fast/stages/0-org-setup'),
                    os.path.join(repo, 'stages/0-org-setup-acme'))
    shutil.copytree(os.path.join(UP[V1], 'fast/stages/2-project-factory'),
                    os.path.join(repo, 'stages/project-factory'))
    for name in ('organization', 'project', 'project-factory'):
      shutil.copytree(os.path.join(UP[V1], 'modules', name),
                      os.path.join(repo, 'tf-modules', name))
    for stage in ('0-org-setup-acme', 'project-factory'):
      rel_path = f'stages/{stage}/main.tf'
      _write(
          repo, rel_path,
          _read(repo, rel_path).replace('../../../modules/',
                                        '../../tf-modules/'))
    for rel_path, content in (extra or {}).items():
      _write(repo, rel_path, content)
    _commit_all(repo)
    return repo

  def git_sourced(self, extra=None):
    """Archetype D: one stage at the root, Fabric modules from git."""
    repo = self.path('gitsrc')
    shutil.copytree(os.path.join(UP[V1], 'fast/stages/0-org-setup'),
                    os.path.join(repo, '0-org-setup'))
    text = _read(repo, '0-org-setup/main.tf')
    for name in ('organization', 'project'):
      text = text.replace(f'"../../../modules/{name}"',
                          f'"{FABRIC_GIT}//modules/{name}?ref={V1}"')
    _write(repo, '0-org-setup/main.tf', text)
    _write(
        repo, '0-org-setup/custom.tf',
        _d(f'''
        module "extra" {{
          source       = "{FABRIC_GIT}//modules/project?ref={V1}"
          name         = "extra"
          custom_roles = {{}}
        }}

        module "other" {{
          source = "git::https://example.com/other.git//modules/x?ref={V1}"
        }}
        '''))
    for rel_path, content in (extra or {}).items():
      _write(repo, rel_path, content)
    _commit_all(repo)
    return repo

  def plan(self, repo, base=None, target=None, **kwargs):
    ctx = fu.Context(repo, base or UP[V1], target or UP[V2], **kwargs)
    plan, results = fu.build_plan(ctx)
    return ctx, plan, results

  @staticmethod
  def files(plan):
    return {f['path']: f for f in plan['files']}

  @staticmethod
  def mappings(plan):
    return {(m['kind'], m['customer']): m for m in plan['mappings']}


# --------------------------------------------------------------------------
# Unit tests: helper modules
# --------------------------------------------------------------------------


class TestHclLite(unittest.TestCase):

  def test_mask_blanks_comments_and_strings_preserving_offsets(self):
    text = ('a = "x # not a comment" # real comment\n'
            '/* block\n{ */ b = 1 // tail\n')
    masked = hcl_lite.mask(text)
    self.assertEqual(len(masked), len(text))
    self.assertEqual(masked.count('\n'), text.count('\n'))
    self.assertNotIn('comment', masked)
    self.assertNotIn('{', masked)
    self.assertIn('b = 1', masked)
    kept = hcl_lite.mask(text, strings=False)
    self.assertIn('"x # not a comment"', kept)
    self.assertNotIn('real comment', kept)

  def test_heredoc_and_interpolation_do_not_confuse_blocks(self):
    text = _d('''
        locals {
          doc = <<EOT
        module "fake" {
          source = "../nope"
        }
        EOT
          quoted = "${lookup(var.m, "k", "}")}"
        }

        module "real" {
          source = "../real"
        }
        ''')
    calls = hcl_lite.module_calls(text)
    self.assertEqual([c.name for c in calls], ['real'])
    self.assertEqual(calls[0].source, '../real')

  def test_template_escapes_and_unterminated_strings(self):
    # `$${` and `%%{` are literal text, not template sequences; a broken
    # string ends at its line (even after an escaped quote) instead of
    # swallowing the rest of the file.
    text = _d('''
        locals {
          a = "$${not_a_template"
          b = "%%{ not_a_directive"
          c = "unterminated \\"
        }

        module "m" {
          source = "../m" // trailing
        }
        ''')
    masked = hcl_lite.mask(text)
    self.assertEqual(len(masked), len(text))
    self.assertEqual(masked.count('\n'), text.count('\n'))
    calls = hcl_lite.module_calls(text)
    self.assertEqual([(c.name, c.source) for c in calls], [('m', '../m')])
    self.assertEqual(text[calls[0].source_start:calls[0].source_end], '../m')

  def test_module_calls_literal_sources_and_top_level_args(self):
    text = _d('''
        module "a" {
          source   = "../x" # comment
          for_each = {}
          foo      = 1
          nested = {
            bar = 2
          }
        }

        module "b" {
          source = var.dynamic
        }

        module "c" {
          source = "../${var.name}"
        }
        ''')
    calls = hcl_lite.module_calls(text)
    self.assertEqual(len(calls), 1)
    call = calls[0]
    self.assertEqual((call.name, call.source, call.line), ('a', '../x', 2))
    self.assertEqual(call.args, frozenset({'foo', 'nested'}))
    self.assertEqual(text[call.source_start:call.source_end], '../x')

  def test_variables_types_defaults_and_comments(self):
    variables = hcl_lite.variables(ORG_VARIABLES_V2)
    self.assertEqual(sorted(variables),
                     ['billing_account', 'custom_roles', 'organization_id'])
    self.assertEqual(variables['custom_roles']['type'],
                     'map(object({ permissions = list(string) }))')
    self.assertTrue(variables['custom_roles']['has_default'])
    self.assertFalse(variables['billing_account']['has_default'])
    self.assertEqual(variables['organization_id']['line'], 1)

  def test_tfvars_keys(self):
    text = 'a = 1\nb = {\n  c = 2\n}\n# d = 3\ne = "=="\n'
    self.assertEqual(hcl_lite.tfvars_keys(text), ['a', 'b', 'e'])
    self.assertEqual(hcl_lite.tfvars_keys('{"x": 1, "y": 2}', True), ['x', 'y'])
    self.assertEqual(hcl_lite.tfvars_keys('not json', True), [])
    self.assertEqual(hcl_lite.tfvars_keys('[1, 2]', True), [])

  def test_classify_source(self):
    cases = {
        './a': 'local',
        '../a/b': 'local',
        FABRIC_GIT + '//modules/x?ref=v1.0.0': 'git',
        'github.com/org/repo//modules/x': 'git',
        'git@github.com:org/repo.git': 'git',
        'bitbucket.org/org/repo': 'git',
        'hashicorp/consul/aws': 'registry',
        'app.terraform.io/org/name/google': 'registry',
        'https://example.com/module.zip': 'other',
        's3::https://bucket/module.zip': 'other',
    }
    for source, kind in cases.items():
      with self.subTest(source=source):
        self.assertEqual(hcl_lite.classify_source(source), kind)

  def test_parse_git_source(self):
    cases = {
        FABRIC_GIT + '//modules/project?ref=v57.0.0':
            ('https://github.com/GoogleCloudPlatform/'
             'cloud-foundation-fabric.git', 'modules/project', 'v57.0.0'),
        'github.com/GoogleCloudPlatform/cloud-foundation-fabric//modules/'
        'net-vpc?ref=v1.0.0&depth=1':
            ('github.com/GoogleCloudPlatform/cloud-foundation-fabric',
             'modules/net-vpc', 'v1.0.0'),
        'git::ssh://git@host.example.com/org/repo.git//modules/x/':
            ('ssh://git@host.example.com/org/repo.git', 'modules/x', None),
        'git::https://example.com/repo.git':
            ('https://example.com/repo.git', '', None),
    }
    for source, expected in cases.items():
      with self.subTest(source=source):
        self.assertEqual(hcl_lite.parse_git_source(source), expected)

  def test_replace_spans(self):
    text = 'abc def ghi'
    self.assertEqual(
        hcl_lite.replace_spans(text, [(0, 3, 'X'), (8, 11, 'YYYY')]),
        'X def YYYY')


class TestReleaseNotes(unittest.TestCase):

  def test_versions(self):
    self.assertEqual(release_notes.parse_version('v1.2.3'), (1, 2, 3))
    self.assertEqual(release_notes.parse_version('1.2.3'), (1, 2, 3))
    for bad in ('v1.2', '', None, 'latest', 'v1.2.3-rc1'):
      with self.subTest(value=bad):
        self.assertIsNone(release_notes.parse_version(bad))
    self.assertEqual(release_notes.format_version((10, 0, 1)), 'v10.0.1')

  def test_parse_changelog(self):
    releases = release_notes.parse_changelog(CHANGELOG_V2)
    self.assertEqual([r['version'] for r in releases],
                     ['v2.0.0', 'v1.1.0', 'v1.0.0'])
    self.assertEqual(releases[0]['date'], '2026-02-01')
    breaking = releases[0]['sections']['BREAKING CHANGES']
    self.assertEqual(len(breaking), 6)
    self.assertIn('to `map(object({ permissions = list(string) }))`',
                  breaking[0])
    self.assertTrue(breaking[4].startswith('`fast/stages/2-networking`'))
    self.assertNotIn('<!--', releases[1]['sections']['BREAKING CHANGES'][0])
    self.assertNotIn('unreleased',
                     json.dumps([r['sections'] for r in releases]).lower())

  def test_select_releases_is_base_exclusive_and_target_inclusive(self):
    releases = release_notes.parse_changelog(CHANGELOG_V2)
    selected = release_notes.select_releases(releases, (1, 0, 0), (2, 0, 0))
    self.assertEqual([r['version'] for r in selected], ['v1.1.0', 'v2.0.0'])
    self.assertEqual(
        release_notes.select_releases(releases, (1, 1, 0), (1, 1, 0)), [])

  def test_relevance(self):
    cases = [
        (('`modules/project`: x', set(), {'project'}), (True,
                                                        'module project')),
        (('`modules/net-vpc`: x', set(), {'project'}), (False, 'not used')),
        (('`fast/stages/2-networking`: x', {'2-networking'}, set()),
         (True, 'stage 2-networking')),
        (('`2-security`: x', {'2-security'}, set()), (True,
                                                      'stage 2-security')),
        (('`project, net-vpc`: x', set(), {'net-vpc'}), (True,
                                                         'module net-vpc')),
        (('`provider`: x', set(), set()), (True, 'global')),
        (('No scope at all', set(), set()), (True, 'global')),
        (('`modules/project`: x', None, None), (True, 'unfiltered')),
    ]
    for args, expected in cases:
      with self.subTest(entry=args[0]):
        self.assertEqual(release_notes.relevance(*args), expected)

  def test_condense_and_fast_changes(self):
    releases = release_notes.select_releases(
        release_notes.parse_changelog(CHANGELOG_V2), (1, 0, 0), (2, 0, 0))
    self.assertEqual(release_notes.fast_changes(releases), [{
        'version': 'v2.0.0',
        'text': '#20 Improve org setup'
    }])

  def test_declared_module_renames(self):
    releases = [{
        'version': 'v2.0.0',
        'sections': {
            'BREAKING CHANGES': [
                '`modules/old-mod`: module renamed to `new-mod`.',
                '`modules/agent`: renamed to `modules/geap-agent`.',
                '`modules/same`: renamed to `same` (no-op).',
                '`fast/stages/x`: renamed to `y`.',
            ]
        }
    }]
    self.assertEqual(release_notes.declared_module_renames(releases), {
        'old-mod': 'new-mod',
        'agent': 'geap-agent'
    })

  def test_upgrading_notes(self):
    notes = release_notes.upgrading_notes(UPGRADING_V2, (1, 0, 0), (2, 0, 0))
    self.assertEqual([n['versions'] for n in notes], [['v1.1.0'], ['v2.0.0']])
    self.assertIn('legacy_flag', notes[0]['text'])
    self.assertTrue(notes[1]['text'].startswith('## v2.0.0'))

  def test_moved_files(self):
    moved = release_notes.moved_files(UP[V2], {'fast/stages/0-org-setup'},
                                      (1, 0, 0), (2, 0, 0))
    self.assertEqual(moved, [{
        'stage': 'fast/stages/0-org-setup',
        'file': 'v1.0.0-v2.0.0.tf',
        'path': 'fast/stages/0-org-setup/moved/v1.0.0-v2.0.0.tf',
    }])


@needs_data
class TestFactoryData(_Case):

  def test_modeline(self):
    self.assertEqual(
        factory_data.modeline(
            '  # yaml-language-server: $schema=../s.schema.json  \nx: 1\n'),
        '../s.schema.json')
    self.assertIsNone(factory_data.modeline('x: 1\n'))

  def test_schema_index_resolution(self):
    a = _write(self.tmp, 'a/schemas/project.schema.json', '{}')
    _write(self.tmp, 'b/schemas/project.schema.json', '{}')
    c = _write(self.tmp, 'c/schemas/folder.schema.json', '{"type": "object"}')
    d = _write(self.tmp, 'd/schemas/folder.schema.json', '{"type": "string"}')
    data = _write(self.tmp, 'a/data/p.yaml', 'x: 1\n')
    outside = _write(self.tmp, 'elsewhere/p.yaml', 'x: 1\n')
    index = factory_data.SchemaIndex(
        [a, os.path.join(self.tmp, 'b/schemas/project.schema.json'), c, d])
    self.assertEqual(index.resolve(data, '../schemas/project.schema.json'),
                     (os.path.normpath(a), 'modeline'))
    path, how = index.resolve(outside, '../schemas/project.schema.json')
    self.assertEqual(how, 'by-name')
    self.assertEqual(path, sorted([a, path])[0] if path == a else path)
    self.assertEqual(index.resolve(outside, 'x/folder.schema.json'),
                     (None, 'ambiguous schema name'))
    self.assertEqual(index.resolve(outside, 'https://example.com/s.json'),
                     (None, 'remote schema (not fetched)'))
    self.assertEqual(index.resolve(outside, 'nope.schema.json'),
                     (None, 'schema not found'))

  def test_load_schema(self):
    good = _write(self.tmp, 's.schema.json', '{"type": "object"}')
    yml = _write(self.tmp, 's.schema.yaml', 'type: object\n')
    bad = _write(self.tmp, 'bad.schema.json', '[unclosed')
    self.assertEqual(factory_data.load_schema(good), ({'type': 'object'}, None))
    self.assertEqual(factory_data.load_schema(yml), ({'type': 'object'}, None))
    self.assertEqual(
        factory_data.load_schema(bad)[1], 'schema is not valid JSON or YAML')
    self.assertIn('cannot read schema',
                  factory_data.load_schema(self.path('missing.json'))[1])

  def test_validate_text(self):
    self.assertEqual(factory_data.validate_text(TEAM_B, SCHEMA_V2), [])
    errors = factory_data.validate_text(TEAM_A, SCHEMA_V2)
    self.assertEqual(len(errors), 1)
    self.assertTrue(
        errors[0].startswith('buckets/state: Additional properties'))
    multi = 'name: a\n---\nname: 1\n'
    self.assertEqual(factory_data.validate_text(multi, SCHEMA_V2),
                     ["doc 1: name: 1 is not of type 'string'"])
    self.assertTrue(
        factory_data.validate_text(
            'a: [', SCHEMA_V2)[0].startswith('<yaml>: invalid YAML'))

  def test_schema_paths_and_diff(self):
    paths, required = factory_data.schema_paths(SCHEMA_V2)
    self.assertIn('buckets.*.location', paths)
    self.assertEqual(paths['labels'], {'array'})
    self.assertEqual(required, {'name', 'notification_config.topic'})
    diff = factory_data.diff_schemas(SCHEMA_V1, SCHEMA_V2)
    self.assertEqual(
        diff, {
            'added': ['notification_config'],
            'removed': ['buckets.*.description'],
            'required_added': ['name'],
            'type_changed': ['labels'],
        })

  def test_schema_paths_survives_ref_cycles_and_items(self):
    schema = {
        'type': 'object',
        'properties': {
            'node': {
                '$ref': '#/definitions/node'
            },
            'tags': {
                'type': 'array',
                'items': {
                    'type': 'string'
                }
            },
            'any': {
                'anyOf': [{
                    'type': 'string'
                }, {
                    'type': 'number'
                }]
            },
        },
        'definitions': {
            'node': {
                'type': 'object',
                'properties': {
                    'child': {
                        '$ref': '#/definitions/node'
                    }
                },
            }
        },
    }
    paths, _ = factory_data.schema_paths(schema)
    self.assertIn('node.child', paths)
    self.assertIn('tags.[]', paths)
    self.assertEqual(paths['any'], {'string', 'number'})

  def test_find_files_and_check_file(self):
    schema = _write(self.tmp, 'd/schemas/project.schema.json',
                    json.dumps(SCHEMA_V2))
    _write(self.tmp, 'd/schemas/extra.schema.yaml', 'type: object\n')
    ok = _write(self.tmp, 'd/data/ok.yaml', TEAM_B)
    bad = _write(self.tmp, 'd/data/bad.yml', TEAM_A)
    plain = _write(self.tmp, 'd/data/plain.yaml', 'name: x\n')
    lost = _write(self.tmp, 'd/data/lost.yaml',
                  '# yaml-language-server: $schema=../nowhere.schema.json\n')
    _write(self.tmp, 'd/.terraform/ignored.yaml', 'x: 1\n')
    root = self.path('d')
    found = factory_data.find_yaml_files([root], fu.IGNORED_DIRS)
    self.assertEqual(found, sorted([ok, bad, plain, lost]))
    self.assertEqual(len(factory_data.find_schema_files([root])), 2)
    index = factory_data.SchemaIndex([schema])
    self.assertEqual(factory_data.check_file(ok, index)['status'], 'ok')
    self.assertEqual(factory_data.check_file(bad, index)['status'], 'invalid')
    self.assertEqual(
        factory_data.check_file(plain, index)['status'], 'no-modeline')
    result = factory_data.check_file(lost, index)
    self.assertEqual((result['status'], result['reason']),
                     ('unresolved', 'schema not found'))


class TestProvenance(_Case):

  def test_digest_is_stable_and_covers_every_script(self):
    digest = provenance.tool_digest()
    self.assertRegex(digest, r'^[0-9a-f]{16}$')
    self.assertEqual(digest, provenance.tool_digest())
    scripts = sorted(n for n in os.listdir(os.path.join(_BASE, 'scripts'))
                     if n.endswith('.py'))
    self.assertEqual(sorted(provenance.FROZEN_FILES), scripts)

  def test_digest_changes_with_content_but_not_line_endings(self):
    copy_dir = self.path('scripts')
    shutil.copytree(os.path.join(_BASE, 'scripts'), copy_dir,
                    ignore=shutil.ignore_patterns('__pycache__'))
    self.assertEqual(provenance.tool_digest(copy_dir), provenance.tool_digest())
    path = os.path.join(copy_dir, 'hcl_lite.py')
    with open(path, 'rb') as f:
      data = f.read()
    with open(path, 'wb') as f:
      f.write(data.replace(b'\n', b'\r\n'))
    self.assertEqual(provenance.tool_digest(copy_dir), provenance.tool_digest())
    with open(path, 'ab') as f:
      f.write(b'# tampered\r\n')
    self.assertNotEqual(provenance.tool_digest(copy_dir),
                        provenance.tool_digest())
    os.unlink(path)
    self.assertNotEqual(provenance.tool_digest(copy_dir),
                        provenance.tool_digest())

  def test_tree_digest_is_location_independent_and_content_sensitive(self):
    files = {
        'fast/stages/0-org-setup/main.tf': 'locals {}\n',
        'modules/project/main.tf': 'resource "x" "y" {}\n',
        'CHANGELOG.md': '# Changelog\n',
        'README.md': 'not part of a release tree\n',
    }
    one, two = self.path('one'), self.path('two')
    for root in (one, two):
      for rel, text in files.items():
        _write(root, rel, text)
    digest = provenance.tree_digest(one)
    self.assertRegex(digest, r'^[0-9a-f]{16}$')
    self.assertEqual(provenance.tree_digest(two), digest)
    # Files outside the release entries, ignored folders and ignored file
    # names do not count; default-versions.tf is optional.
    _write(two, 'README.md', 'changed\n')
    _write(two, 'modules/project/.terraform/x.json', '{}\n')
    _write(two, 'modules/project/.DS_Store', 'x')
    self.assertEqual(
        provenance.tree_digest(two, ignored_dirs={'.terraform'},
                               ignored_file_re=re.compile(r'\.DS_Store$')),
        digest)
    _write(two, 'modules/project/main.tf', 'resource "x" "z" {}\n')
    self.assertNotEqual(
        provenance.tree_digest(two, ignored_dirs={'.terraform'},
                               ignored_file_re=re.compile(r'\.DS_Store$')),
        digest)

  def test_tree_digest_hashes_symlinks_by_target(self):
    root = self.path('tree')
    _write(root, 'fast/stages/0-org-setup/main.tf', 'locals {}\n')
    _write(root, 'modules/a/main.tf', '')
    _write(root, 'modules/b/main.tf', '')
    link = os.path.join(root, 'fast/stages/0-org-setup/data')
    os.symlink('../../../modules/a', link)
    digest = provenance.tree_digest(root)
    # Spelling is not a change: tar filters may drop the trailing slash
    # that a git checkout keeps.
    for spelling in ('../../../modules/a/', './../../../modules/a'):
      with self.subTest(spelling=spelling):
        os.unlink(link)
        os.symlink(spelling, link)
        self.assertEqual(provenance.link_target(link), '../../../modules/a')
        self.assertEqual(provenance.tree_digest(root), digest)
    os.unlink(link)
    os.symlink('../../../modules/b', link)
    self.assertNotEqual(provenance.tree_digest(root), digest)

  def test_cli(self):
    code, out, _ = _run(provenance, ['--verbose'])
    self.assertEqual(code, 0)
    self.assertIn(f'frozen tools: {provenance.tool_digest()}', out)
    self.assertIn('fast_upgrade.py:', out)


# --------------------------------------------------------------------------
# Unit tests: fast_upgrade building blocks
# --------------------------------------------------------------------------


class TestClassify(unittest.TestCase):

  def test_truth_table(self):
    cases = [
        (('x', 'x', 'x'), 'unchanged'),
        (('y', 'x', 'y'), 'already-updated'),
        (('y', None, 'y'), 'already-updated'),
        ((None, 'x', None), 'already-updated'),
        (('y', 'x', 'x'), 'customer-changed'),
        (('y', None, None), 'customer-added'),
        ((None, 'x', 'x'), 'customer-deleted'),
        (('x', 'x', 'y'), 'upstream-changed'),
        ((None, None, 'y'), 'upstream-added'),
        (('x', 'x', None), 'upstream-deleted'),
        ((None, 'x', 'y'), 'conflict-customer-deleted'),
        (('y', 'x', None), 'conflict-deleted'),
        (('y', None, 'z'), 'conflict-added'),
        (('y', 'x', 'z'), 'conflict'),
    ]
    for args, expected in cases:
      with self.subTest(args=args):
        self.assertEqual(fu.classify(*args), expected)

  def test_every_category_is_documented(self):
    produced = {
        fu.classify(c, b, t)
        for c in ('x', 'y', 'z', None)
        for b in ('x', 'y', None)
        for t in ('x', 'z', None)
    }
    self.assertEqual(produced, set(fu.CATEGORY_HELP))


class TestVersions(_Case):

  def test_version_consensus(self):
    self.assertEqual(
        fu.version_consensus([('a', 'stage', V1), ('b', 'stage', V1)]),
        (V1, 'high', {
            'stage': {
                V1: 2
            }
        }))
    version, confidence, _ = fu.version_consensus([('a', 'stage', V2),
                                                   ('b', 'stage', V1)])
    self.assertEqual((version, confidence), (V1, 'mixed'))
    version, confidence, _ = fu.version_consensus([('a', 'stage', V2),
                                                   ('m', 'module', V1),
                                                   ('n', 'module', V1)])
    self.assertEqual((version, confidence), (V2, 'mixed'))
    self.assertEqual(
        fu.version_consensus([('g', 'git-ref', V1)])[:2], (V1, 'high'))
    self.assertEqual(fu.version_consensus([]), (None, 'none', {}))

  def test_release_version(self):
    self.assertEqual(fu.release_version(UP[V1]), V1)
    root = self.upstream_copy(V2, 'nodefault')
    os.unlink(os.path.join(root, 'default-versions.tf'))
    self.assertEqual(fu.release_version(root), V2)
    self.assertIsNone(fu.release_version(self.path('empty')))

  def test_type_delta(self):
    delta = fu.type_delta('map(list(string))',
                          'map(object({ permissions = list(string) }))')
    self.assertIn('- map(list(string))', delta)
    self.assertIn('+ map(object({ permissions = list(string) }))', delta)
    self.assertEqual(fu.type_delta('a  b', 'a b'), 'whitespace only')
    delta = fu.type_delta('object({ a = string b = number c = bool })',
                          'object({ a = string b = string c = bool })')
    self.assertEqual(delta, 'after `a = string b =` - number + string')

  def test_file_kind(self):
    cases = {
        'x/fast_version.txt': 'marker',
        'main.tf': 'terraform',
        'versions.tofu': 'terraform',
        'a.auto.tfvars': 'tfvars',
        'a.tfvars.json': 'tfvars',
        'schemas/p.schema.json': 'schema',
        'data/p.yaml': 'data',
        'README.md': 'docs',
        'x.sh': 'script',
        'LICENSE': 'other',
    }
    for path, kind in cases.items():
      with self.subTest(path=path):
        self.assertEqual(fu.file_kind(path), kind)


class TestScanAndCatalog(_Case):

  def test_catalog_finds_stages_extras_and_grouped_modules(self):
    cat = fu.catalog(UP[V2])
    self.assertEqual(cat['version'], V2)
    self.assertEqual(cat['stages']['0-org-setup'], 'fast/stages/0-org-setup')
    self.assertEqual(cat['stages']['0-cicd-github'],
                     'fast/extras/0-cicd-github')
    self.assertEqual(cat['modules']['cloud-config-container/coredns'],
                     'modules/cloud-config-container/coredns')
    self.assertNotIn('cloud-config-container', cat['modules'])
    self.assertIn('new-mod', cat['modules'])
    with self.assertRaisesRegex(fu.UpgradeError, 'not a Cloud Foundation'):
      fu.catalog(self.tmp)

  def test_module_key_and_git_module_name(self):
    names = {'project', 'cloud-config-container/coredns'}
    self.assertEqual(fu.module_key('tf-modules/project', names),
                     ('project', 'tf-modules'))
    self.assertEqual(
        fu.module_key('modules/cloud-config-container/coredns', names),
        ('cloud-config-container/coredns', 'modules'))
    self.assertEqual(fu.module_key('lib/other', names), (None, 'lib'))
    call = {'kind': 'git', 'fabric': True, 'subdir': 'modules/project'}
    self.assertEqual(fu.git_module_name(call), 'project')
    call['subdir'] = 'modules/cloud-config-container/coredns'
    self.assertEqual(fu.git_module_name(call), 'cloud-config-container/coredns')
    call['subdir'] = 'fast/stages/0-org-setup'
    self.assertIsNone(fu.git_module_name(call))
    self.assertIsNone(
        fu.git_module_name({
            'kind': 'git',
            'fabric': False,
            'subdir': 'modules/project'
        }))

  def test_scan_repo(self):
    repo = self.fork(
        commit=False, extra={
            **A_EXTRA,
            'fast/stages/0-org-setup/.terraform.lock.hcl':
                '# lock\n',
            'fast/stages/0-org-setup/terraform.tfstate':
                '{}',
            'fast/stages/0-org-setup/.terraform/modules/x/main.tf':
                'module "m" {\n  source = "../y"\n}\n',
            'fast/stages/0-org-setup/assets/1-nested/main.tf':
                'locals {}\n',
            'fast/stages/0-org-setup/broken.tf':
                'module "gone" {\n  source = "../../../modules/gone"\n}\n'
                'module "out" {\n  source = "../../../../outside"\n}\n',
        })
    scan = fu.scan_repo(repo, re.compile(fu.DEFAULT_FABRIC_SOURCE))
    self.assertEqual(sorted(scan.stage_dirs), [
        'fast/extras/0-cicd-github', 'fast/stages/0-org-setup',
        'fast/stages/2-project-factory'
    ])
    self.assertEqual(scan.stage_dirs['fast/stages/0-org-setup']['reason'],
                     'marker')
    self.assertIn('modules/project', scan.module_dirs)
    self.assertEqual(scan.tfvars_files,
                     ['fast/stages/0-org-setup/terraform.tfvars'])
    self.assertEqual(scan.lock_files,
                     ['fast/stages/0-org-setup/.terraform.lock.hcl'])
    self.assertNotIn('.terraform', json.dumps(scan.calls))
    problems = {c['source']: c['problem'] for c in scan.calls if 'problem' in c}
    self.assertEqual(
        problems, {
            '../../../modules/gone': 'missing',
            '../../../../outside': 'outside repository'
        })
    self.assertEqual(fu.version_consensus(scan.markers)[:2], (V1, 'high'))

  def test_walk_tree_ignores_state_and_does_not_follow_links(self):
    root = self.path('w')
    _write(root, 'a.tf', 'x')
    _write(root, 'terraform.tfstate', '{}')
    _write(root, 'plan.tfplan', 'x')
    _write(root, '.terraform/x.tf', 'x')
    _write(root, 'real/b.tf', 'x')
    os.symlink('real', os.path.join(root, 'alias'))
    files = fu.walk_tree(root)
    self.assertEqual(sorted(files), ['a.tf', 'alias', 'real/b.tf'])
    self.assertEqual(sorted(fu.walk_tree(root, top_level_only=True)),
                     ['a.tf', 'alias'])
    self.assertEqual(
        fu.read_entry(os.path.join(root, 'alias')).digest, 'link:real')
    # Compared in normal form, written back verbatim.
    os.symlink('real/', os.path.join(root, 'alias2'))
    entry = fu.read_entry(os.path.join(root, 'alias2'))
    self.assertEqual((entry.digest, entry.link), ('link:real', 'real/'))

  def test_source_rewriter(self):
    layout = fu.SourceRewriter({'modules/project': 'tf-modules/project'})
    text = 'module "p" {\n  source = "../../../modules/project"\n}\n'
    self.assertIn(
        '"../../tf-modules/project"',
        layout.rewrite(text, 'fast/stages/0-org-setup/main.tf',
                       'stages/org/main.tf'))
    # The upstream spelling is kept when it already resolves correctly.
    same = fu.SourceRewriter({'modules/project': 'modules/project'})
    self.assertEqual(
        same.rewrite(text, 'modules/x/recipe/main.tf',
                     'modules/x/recipe/main.tf'), text)
    template = FABRIC_GIT + '//{subdir}?ref={ref}'
    git = fu.SourceRewriter({}, template, V2)
    self.assertIn(
        f'"{FABRIC_GIT}//modules/project?ref={V2}"',
        git.rewrite(text, 'fast/stages/0-org-setup/main.tf',
                    '0-org-setup/main.tf'))
    self.assertEqual(git.rewrite('locals {}\n', 'fast/a.tf', 'a.tf'),
                     'locals {}\n')

  def test_git_template(self):
    calls = [{
        'kind': 'git',
        'fabric': True,
        'ref': V1,
        'subdir': 'modules/project',
        'source': f'{FABRIC_GIT}//modules/project?ref={V1}'
    }, {
        'kind': 'git',
        'fabric': True,
        'ref': V1,
        'subdir': 'modules/folder',
        'source': f'{FABRIC_GIT}//modules/folder?ref={V1}'
    }]
    self.assertEqual(fu.git_template(calls, re.compile('x')),
                     (FABRIC_GIT + '//{subdir}?ref={ref}', V1))
    self.assertEqual(fu.git_template([], re.compile('x')), (None, None))


# --------------------------------------------------------------------------
# plan
# --------------------------------------------------------------------------


@needs_git
class TestPlanVanillaFork(_Case):
  """Archetype A: an unmodified fork plus customer data and tfvars."""

  def setUp(self):
    super().setUp()
    self.repo = self.fork(extra=A_EXTRA)
    self.ctx, self.plan_, self.results = self.plan(self.repo)
    self.by_path = self.files(self.plan_)

  def test_file_categories(self):
    expected = {
        'fast/stages/0-org-setup/fast_version.txt':
            'upstream-changed',
        'fast/stages/0-org-setup/README.md':
            'upstream-changed',
        'fast/stages/0-org-setup/main.tf':
            'upstream-changed',
        'fast/stages/0-org-setup/variables.tf':
            'upstream-changed',
        'fast/stages/0-org-setup/outputs.tf':
            'unchanged',
        'fast/stages/0-org-setup/billing.tf':
            'upstream-added',
        'fast/stages/0-org-setup/moved/v1.0.0-v2.0.0.tf':
            'upstream-added',
        'fast/stages/0-org-setup/moved/v0.9.0-v1.0.0.tf':
            'unchanged',
        'fast/stages/0-org-setup/terraform.tfvars':
            'customer-added',
        'fast/stages/2-project-factory/legacy.tf':
            'upstream-deleted',
        'fast/stages/2-project-factory/schemas/project.schema.json':
            'upstream-changed',
        'fast/stages/2-project-factory/data/projects/prod-app.yaml':
            'unchanged',
        'fast/stages/2-project-factory/data/projects/team-a.yaml':
            'customer-added',
        'fast/stages/UPGRADING.md':
            'upstream-changed',
        'fast/README.md':
            'unchanged',
        'fast/extras/0-cicd-github/main.tf':
            'unchanged',
        'modules/project/main.tf':
            'upstream-changed',
        'modules/project/scripts/helper.sh':
            'upstream-changed',
        'modules/project/versions.tf':
            'upstream-changed',
        'modules/old-mod/main.tf':
            'upstream-deleted',
        'modules/new-mod/main.tf':
            'upstream-added',
        'modules/billing-account/main.tf':
            'upstream-added',
        'modules/net-vpc/main.tf':
            'unchanged',
        'modules/cloud-config-container/coredns/main.tf':
            'unchanged',
    }
    for path, category in expected.items():
      with self.subTest(path=path):
        self.assertEqual(self.by_path[path]['category'], category)
    self.assertTrue(
        set(self.plan_['summary']) <= set(SAFE), self.plan_['summary'])
    self.assertNotIn('fast/stages/3-new-stage/main.tf', self.by_path)
    self.assertNotIn('CHANGELOG.md', self.by_path)

  def test_marker_only_and_renames(self):
    for path in ('fast/stages/0-org-setup/fast_version.txt',
                 'fast/stages/0-org-setup/README.md',
                 'modules/project/versions.tf'):
      with self.subTest(path=path):
        self.assertTrue(self.by_path[path]['marker_only'])
    self.assertFalse(self.by_path['modules/project/main.tf']['marker_only'])
    for name in ('main.tf', 'variables.tf', 'outputs.tf', 'versions.tf'):
      with self.subTest(name=name):
        self.assertEqual(self.by_path[f'modules/old-mod/{name}']['renamed_to'],
                         f'modules/new-mod/{name}')
        self.assertEqual(
            self.by_path[f'modules/new-mod/{name}']['renamed_from'],
            f'modules/old-mod/{name}')
    self.assertEqual(self.plan_['module_renames'], [{
        'old': 'old-mod',
        'new': 'new-mod',
        'used': False
    }])

  def test_mappings(self):
    mappings = self.mappings(self.plan_)
    stage = mappings[('stage', 'fast/stages/0-org-setup')]
    self.assertEqual((stage['name'], stage['match']), ('0-org-setup', 'name'))
    self.assertEqual(mappings[('stage', 'fast/extras/0-cicd-github')]['match'],
                     'name')
    self.assertFalse(mappings[('files', 'fast/stages')]['recursive'])
    self.assertFalse(mappings[('files', 'fast')]['recursive'])
    grouped = mappings[('module', 'modules/cloud-config-container/coredns')]
    self.assertEqual(grouped['name'], 'cloud-config-container/coredns')
    self.assertEqual(mappings[('module', 'modules/new-mod')]['match'],
                     'renamed from old-mod')
    self.assertEqual(mappings[('module', 'modules/billing-account')]['match'],
                     'new dependency')
    self.assertEqual(self.plan_['customer_only'], {'stages': [], 'modules': []})

  def test_breaking_changes_relevance(self):
    changes = self.plan_['breaking_changes']
    self.assertEqual(len(changes), 7)
    relevant = {(b['version'], b['reason']) for b in changes if b['relevant']}
    self.assertEqual(
        relevant, {('v1.1.0', 'stage 0-org-setup'),
                   ('v2.0.0', 'module project'),
                   ('v2.0.0', 'stage 2-project-factory'), ('v2.0.0', 'global')})
    self.assertEqual([n['versions'] for n in self.plan_['upgrading_notes']],
                     [['v1.1.0'], ['v2.0.0']])

  def test_stage_variables_and_tfvars(self):
    self.assertEqual(len(self.plan_['stage_variables']), 1)
    stage = self.plan_['stage_variables'][0]
    self.assertEqual(stage['stage'], 'fast/stages/0-org-setup')
    self.assertEqual(stage['removed'], ['legacy_flag'])
    self.assertEqual(stage['added_required'], ['billing_account'])
    self.assertEqual([t['name'] for t in stage['type_changed']],
                     ['custom_roles'])
    self.assertEqual(stage['tfvars_set_removed'], ['legacy_flag'])

  def test_providers_moved_blocks_and_notes(self):
    self.assertEqual([p['name'] for p in self.plan_['providers']],
                     ['google', 'google-beta'])
    self.assertEqual(self.plan_['providers'][0]['target'], '>= 8.0.0, < 9.0.0')
    self.assertEqual(self.plan_['moved_files'], [{
        'file': 'fast/stages/0-org-setup/moved/v1.0.0-v2.0.0.tf',
        'copy_to': 'fast/stages/0-org-setup/v1.0.0-v2.0.0.tf'
    }])
    self.assertIn(
        'stages new in the target (not added automatically): '
        '3-new-stage', self.plan_['notes'])
    self.assertEqual(self.plan_['warnings'], [])
    self.assertEqual(self.plan_['unresolved_sources'], [])
    self.assertEqual(self.plan_['module_interface'], [])
    self.assertEqual(self.plan_['repo']['detected_version'], V1)

  @needs_data
  def test_schema_changes_and_factory_data(self):
    self.assertEqual(self.plan_['schema_changes'], [{
        'path': 'fast/stages/2-project-factory/schemas/project.schema.json',
        'added': ['notification_config'],
        'removed': ['buckets.*.description'],
        'required_added': ['name'],
        'type_changed': ['labels'],
    }])
    data = self.plan_['data_impact']
    self.assertEqual(data['summary'], {'breaks': 1, 'ok': 1, 'no-modeline': 1})
    self.assertEqual(len(data['files']), 1)
    broken = data['files'][0]
    self.assertEqual(broken['file'],
                     'fast/stages/2-project-factory/data/projects/team-a.yaml')
    self.assertEqual(broken['status'], 'breaks')
    self.assertIn("'description' was unexpected", broken['errors'][0])

  def test_render(self):
    text = fu.render_plan(self.plan_, fu.DEFAULT_LIMIT)
    self.assertTrue(
        text.startswith(
            f'fast-upgrade plan | tools {provenance.tool_digest()}'))
    for section in ('MAPPED FOLDERS', 'FILE ACTIONS', 'UPSTREAM DELETIONS',
                    'BREAKING CHANGES (relevant to this repository) (4)',
                    '(3 more affect stages or modules not in use; see --json)',
                    'UPGRADING NOTES', 'MOVED BLOCKS', 'PROVIDERS',
                    'STAGE VARIABLES', 'SET IN TFVARS but removed: legacy_flag',
                    'MODULE RENAMES', 'NOTES'):
      with self.subTest(section=section):
        self.assertIn(section, text)
    self.assertIn('version-marker only', text)
    self.assertNotIn('CONFLICTS', text)
    short = fu.render_plan(self.plan_, 1)
    self.assertIn('more (--limit 0 or --json for all)', short)
    # Both input trees are stamped with their content digest.
    for key in ('base', 'target'):
      with self.subTest(tree=key):
        tree = self.plan_[key]
        self.assertEqual(
            tree['digest'],
            provenance.tree_digest(tree['path'], ignored_dirs=fu.IGNORED_DIRS,
                                   ignored_file_re=fu.IGNORED_FILE_RE))
        self.assertIn(f'{tree["version"]}  tree {tree["digest"]}', text)
    self.assertNotEqual(self.plan_['base']['digest'],
                        self.plan_['target']['digest'])


@needs_git
class TestPlanScenarios(_Case):

  def test_edits_on_both_sides(self):
    repo = self.fork(edits=B_EDITS, extra=B_EXTRA, remove=B_REMOVE)
    _, plan, _ = self.plan(repo)
    by_path = self.files(plan)
    expected = {
        'modules/project/main.tf': 'conflict',
        'fast/stages/0-org-setup/variables.tf': 'conflict',
        'modules/old-mod/main.tf': 'conflict-deleted',
        'modules/new-mod/main.tf': 'upstream-added',
        'fast/stages/2-project-factory/legacy.tf': 'conflict-deleted',
        'fast/stages/0-org-setup/billing.tf': 'conflict-added',
        'fast/stages/0-org-setup/README.md': 'conflict-customer-deleted',
        'modules/net-vpc/README.md': 'customer-deleted',
    }
    for path, category in expected.items():
      with self.subTest(path=path):
        self.assertEqual(by_path[path]['category'], category)
    self.assertEqual(by_path['modules/old-mod/main.tf']['renamed_to'],
                     'modules/new-mod/main.tf')
    self.assertIsNone(
        by_path['fast/stages/2-project-factory/legacy.tf']['renamed_to'])
    text = fu.render_plan(plan, 0)
    self.assertIn('CONFLICTS (2)', text)
    self.assertIn('MANUAL REVIEW (4)', text)
    self.assertIn('you and upstream both added this file', text)
    self.assertIn('(upstream change is only a version marker)', text)

  def test_reorganized_layout_has_no_false_conflicts(self):
    repo = self.reorganized()
    _, plan, _ = self.plan(repo)
    mappings = self.mappings(plan)
    self.assertEqual(mappings[('stage', 'stages/0-org-setup-acme')]['match'],
                     'prefix')
    pf = mappings[('stage', 'stages/project-factory')]
    self.assertEqual(pf['name'], '2-project-factory')
    self.assertTrue(pf['match'].startswith('content 0.'))
    self.assertEqual(
        mappings[('module', 'tf-modules/billing-account')]['match'],
        'new dependency')
    self.assertNotIn(('module', 'tf-modules/net-vpc'), mappings)
    by_path = self.files(plan)
    self.assertTrue(set(plan['summary']) <= set(SAFE), plan['summary'])
    self.assertNotIn('customer-changed', plan['summary'])
    main = by_path['stages/0-org-setup-acme/main.tf']
    self.assertEqual(main['category'], 'upstream-changed')
    self.assertTrue(main['layout_adjusted'])
    self.assertEqual(by_path['stages/project-factory/main.tf']['category'],
                     'unchanged')
    self.assertEqual(by_path['stages/0-org-setup-acme/billing.tf']['category'],
                     'upstream-added')
    self.assertEqual(plan['unresolved_sources'], [])

  def test_reorganized_apply_writes_customer_layout(self):
    repo = self.reorganized()
    ctx, plan, results = self.plan(repo)
    result = fu.run_apply(ctx, results, moved=plan['moved_files'])
    self.assertEqual(result['counts'].get('conflict', 0), 0)
    billing = _read(repo, 'stages/0-org-setup-acme/billing.tf')
    self.assertIn('source          = "../../tf-modules/billing-account"',
                  billing)
    self.assertEqual(_read(repo, 'tf-modules/billing-account/main.tf'),
                     BILLING_MAIN)
    self.assertIn('"../billing-account"',
                  _read(repo, 'tf-modules/project/main.tf'))
    self.assertEqual(result['moved_pending'], [{
        'file': 'fast/stages/0-org-setup/moved/v1.0.0-v2.0.0.tf',
        'copy_to': 'stages/0-org-setup-acme/v1.0.0-v2.0.0.tf'
    }])

  def test_customer_only_stages_and_modules(self):
    repo = self.reorganized(
        extra={
            'stages/9-custom/main.tf':
                'module "mine" {\n  source = "../../tf-modules/my-module"\n}\n',
            'tf-modules/my-module/main.tf':
                'locals {\n  mine = true\n}\n',
        })
    _, plan, _ = self.plan(repo)
    self.assertEqual(plan['customer_only'], {
        'stages': ['stages/9-custom'],
        'modules': ['tf-modules/my-module']
    })
    self.assertIn(
        'yours (no upstream match): stages/9-custom, '
        'tf-modules/my-module', fu.render_plan(plan, 0))
    self.assertNotIn('stages/9-custom/main.tf', self.files(plan))

  def test_git_sourced_modules(self):
    repo = self.git_sourced()
    ctx, plan, results = self.plan(repo)
    self.assertEqual(plan['git_refs']['refs'], {V1: 3})
    self.assertEqual(plan['git_refs']['bumpable'], 3)
    self.assertEqual(plan['git_refs']['template'],
                     FABRIC_GIT + '//{subdir}?ref={ref}')
    by_path = self.files(plan)
    self.assertEqual(by_path['0-org-setup/main.tf']['category'],
                     'upstream-changed')
    self.assertEqual(by_path['0-org-setup/custom.tf']['category'],
                     'customer-added')
    self.assertEqual(plan['unresolved_sources'], [])
    issues = sorted(h['issue'] for h in plan['module_interface'])
    self.assertEqual(len(issues), 2)
    self.assertEqual(issues[0], 'does not pass `parent`, now required')
    self.assertTrue(
        issues[1].startswith('passes `custom_roles`, whose type changed: '))
    hit = [h for h in plan['module_interface'] if 'base_type' in h][0]
    self.assertEqual(hit['base_type'], 'map(list(string))')
    self.assertTrue(any('sourced from git' in n for n in plan['notes']))
    result = fu.run_apply(ctx, results, bump=True, moved=plan['moved_files'])
    self.assertIn(f'ref={V2}"', _read(repo, '0-org-setup/main.tf'))
    self.assertIn(f'{FABRIC_GIT}//modules/billing-account?ref={V2}',
                  _read(repo, '0-org-setup/billing.tf'))
    custom = _read(repo, '0-org-setup/custom.tf')
    self.assertIn(f'//modules/project?ref={V2}"', custom)
    self.assertIn(f'example.com/other.git//modules/x?ref={V1}"', custom)
    self.assertEqual(result['refs_bumped'], [{
        'file': '0-org-setup/custom.tf',
        'sources': 1
    }])

  def test_fabric_source_regex_for_mirrors(self):
    mirror = 'git::https://git.example.com/mirror/fabric.git'
    repo = self.git_sourced(
        extra={
            '0-org-setup/custom.tf':
                f'module "m" {{\n  source = "{mirror}//modules/project?ref={V1}"'
                '\n  name   = "m"\n}\n'
        })
    _, plan, _ = self.plan(repo)
    self.assertEqual(plan['git_refs']['refs'], {V1: 2})
    _, plan, _ = self.plan(repo, fabric_source='cloud-foundation-fabric|mirror')
    self.assertEqual(plan['git_refs']['refs'], {V1: 3})

  def test_module_rename_in_use_is_flagged(self):
    custom = _d('''
        module "sa" {
          source = "../../../modules/old-mod"
          name   = "x"
        }
        ''')
    repo = self.fork(extra={'fast/stages/0-org-setup/custom.tf': custom})
    _, plan, _ = self.plan(repo)
    self.assertEqual(plan['module_renames'], [{
        'old': 'old-mod',
        'new': 'new-mod',
        'used': True
    }])
    self.assertEqual([h['issue'] for h in plan['module_interface']],
                     ['module renamed upstream to new-mod: update the source'])
    rename = [b for b in plan['breaking_changes'] if 'old-mod' in b['text']][0]
    self.assertEqual((rename['relevant'], rename['reason']),
                     (True, 'module old-mod'))

  def test_crlf_and_ignored_files(self):
    repo = self.fork(
        commit=False, extra={
            'fast/stages/0-org-setup/terraform.tfstate': '{}',
            'fast/stages/0-org-setup/.terraform.lock.hcl': '# lock\n',
            'fast/stages/0-org-setup/.terraform/x.tf': 'locals {}\n',
        })
    _write(repo, 'modules/net-vpc/main.tf', VPC_MAIN.replace('\n', '\r\n'))
    _commit_all(repo)
    _, plan, _ = self.plan(repo)
    by_path = self.files(plan)
    self.assertEqual(by_path['modules/net-vpc/main.tf']['category'],
                     'unchanged')
    self.assertFalse(
        [p for p in by_path if 'tfstate' in p or '.terraform' in p])
    self.assertIn(
        'lock files present: run `terraform init -upgrade` in '
        'fast/stages/0-org-setup', plan['notes'])

  def test_link_spelling_is_not_a_customer_change(self):
    # Like 2-networking/datasets/classic: a fetched release may hold the
    # normalized target ('data') while a checkout keeps 'data/'.
    link = 'fast/stages/2-project-factory/classic'
    base = self.upstream_copy(V1, 'base')
    target = self.upstream_copy(V2, 'target')
    for root in (base, target):
      os.symlink('data', os.path.join(root, *link.split('/')))
    repo = self.fork(commit=False, base=base)
    os.unlink(os.path.join(repo, *link.split('/')))
    os.symlink('data/', os.path.join(repo, *link.split('/')))
    _commit_all(repo)
    _, plan, _ = self.plan(repo, base=base, target=target)
    self.assertEqual(self.files(plan)[link]['category'], 'unchanged')
    self.assertNotIn('customer-changed', plan['summary'])

  def test_symlinked_folder_is_blocked(self):
    repo = self.fork(commit=False)
    data = os.path.join(repo, 'fast/stages/2-project-factory/data')
    shutil.move(data, os.path.join(repo, 'shared-data'))
    os.symlink('../../../shared-data', data)
    _commit_all(repo)
    target = self.upstream_copy(
        V2, 'target', {
            'fast/stages/2-project-factory/data/projects/prod-app.yaml':
                PROD_APP + 'labels: []\n'
        })
    ctx, plan, results = self.plan(repo, target=target)
    by_path = self.files(plan)
    entry = by_path['fast/stages/2-project-factory/data/projects/prod-app.yaml']
    self.assertEqual(entry['blocked'],
                     'a parent folder is a symlink in your repository')
    self.assertTrue(by_path['fast/stages/2-project-factory/data']['link'])
    before = _read(repo, 'shared-data/projects/prod-app.yaml')
    result = fu.run_apply(ctx, results)
    manual = [r['path'] for r in result['records'] if r['result'] == 'manual']
    self.assertIn('fast/stages/2-project-factory/data/projects/prod-app.yaml',
                  manual)
    self.assertEqual(_read(repo, 'shared-data/projects/prod-app.yaml'), before)

  def test_wrong_base_is_warned_and_explains_silent_keeps(self):
    repo = self.fork()
    _, plan, _ = self.plan(repo, base=UP[V2], target=UP[V2])
    warnings = ' '.join(plan['warnings'])
    self.assertIn('looks like v1.0.0 but the base is v2.0.0', warnings)
    self.assertIn('base and target are the same release', warnings)
    # With a base that is too new, upstream changes look like the customer's.
    self.assertEqual(
        self.files(plan)['modules/project/main.tf']['category'],
        'customer-changed')

  def test_mixed_markers_warning(self):
    repo = self.fork(extra={
        'fast/stages/0-org-setup/fast_version.txt': f'# FAST release: {V2}\n'
    })
    _, plan, _ = self.plan(repo)
    self.assertEqual(plan['repo']['confidence'], 'mixed')
    self.assertIn('version markers disagree', ' '.join(plan['warnings']))

  def test_dirty_tree_is_warned(self):
    repo = self.fork()
    _write(repo, 'modules/net-vpc/main.tf', VPC_MAIN + '# local edit\n')
    _, plan, _ = self.plan(repo)
    self.assertIn('1 tracked file(s) have uncommitted changes',
                  ' '.join(plan['warnings']))

  def test_removed_stage_warns_about_unsupported_path(self):
    base = self.upstream_copy(
        V1, 'legacy-base', {
            'fast/stages/1-legacy/fast_version.txt': f'# FAST release: {V1}\n',
            'fast/stages/1-legacy/main.tf': 'locals {\n  legacy = 1\n}\n',
        })
    repo = self.fork(base=base)
    _, plan, _ = self.plan(repo, base=base)
    self.assertIn(
        'stages that no longer exist in the target: fast/stages/1-legacy '
        '(1-legacy)', ' '.join(plan['warnings']))
    self.assertEqual(
        self.files(plan)['fast/stages/1-legacy/main.tf']['category'],
        'upstream-deleted')

  @needs_data
  def test_data_folder_outside_the_repository(self):
    repo = self.fork()
    config = self.path('fast-config')
    _write(config, '0-org-setup.auto.tfvars', 'legacy_flag = true\n')
    ext = _write(config, 'data/projects/ext.yaml', TEAM_A)
    _, plan, _ = self.plan(repo, data_paths=[config])
    stage = plan['stage_variables'][0]
    self.assertEqual(stage['tfvars_set_removed'], ['legacy_flag'])
    self.assertIn(os.path.join(config, '0-org-setup.auto.tfvars'),
                  stage['tfvars_files'])
    statuses = {f['file']: f['status'] for f in plan['data_impact']['files']}
    self.assertEqual(statuses, {ext: 'breaks'})
    with self.assertRaisesRegex(fu.UpgradeError, 'data path not found'):
      self.plan(repo, data_paths=[self.path('missing')])

  def test_refusals(self):
    repo = self.fork()
    with self.assertRaisesRegex(fu.UpgradeError,
                                'downgrades are not supported'):
      self.plan(repo, base=UP[V2], target=UP[V1])
    with self.assertRaisesRegex(fu.UpgradeError, 'not a Cloud Foundation'):
      self.plan(repo, base=self.tmp)
    with self.assertRaisesRegex(fu.UpgradeError, 'not a directory'):
      self.plan(self.path('nope'))
    nomarker = self.upstream_copy(V1, 'nomarker')
    os.unlink(os.path.join(nomarker, 'default-versions.tf'))
    for name in ('0-org-setup', '2-project-factory'):
      os.unlink(os.path.join(nomarker, f'fast/stages/{name}/fast_version.txt'))
    with self.assertRaisesRegex(fu.UpgradeError, 'cannot read the release'):
      self.plan(repo, base=nomarker)


# --------------------------------------------------------------------------
# apply
# --------------------------------------------------------------------------


@needs_git
class TestApply(_Case):

  def test_refuses_outside_git_and_dirty_trees(self):
    repo = self.fork(commit=False)
    ctx, _, results = self.plan(repo)
    with self.assertRaisesRegex(fu.Refused, 'not a git repository'):
      fu.run_apply(ctx, results)
    fu.run_apply(ctx, results, dry_run=True, allow_dirty=True)
    repo = self.fork(name='dirty')
    _write(repo, 'modules/net-vpc/main.tf', VPC_MAIN + '# edit\n')
    ctx, _, results = self.plan(repo)
    with self.assertRaisesRegex(fu.Refused, 'uncommitted changes'):
      fu.run_apply(ctx, results)
    # Untracked files (reports, plans) do not make the tree dirty.
    repo = self.fork(name='untracked')
    _write(repo, '.fast-upgrade/plan.txt', 'report\n')
    ctx, _, results = self.plan(repo)
    fu.run_apply(ctx, results, dry_run=True)

  def test_dry_run_writes_nothing(self):
    repo = self.fork(extra=A_EXTRA)
    before = _tree_digest(repo)
    ctx, plan, results = self.plan(repo)
    result = fu.run_apply(ctx, results, dry_run=True, include_deletes=True,
                          copy_moved=True, moved=plan['moved_files'])
    self.assertEqual(_tree_digest(repo), before)
    self.assertTrue(result['dry_run'])
    self.assertGreater(result['counts']['written'], 0)
    self.assertIn('DRY RUN', fu.render_apply(result, 0))

  def test_apply_takes_upstream_and_keeps_customer_files(self):
    repo = self.fork(extra=A_EXTRA)
    ctx, plan, results = self.plan(repo)
    result = fu.run_apply(ctx, results, moved=plan['moved_files'])
    summary = plan['summary']
    self.assertEqual(result['counts']['written'],
                     summary['upstream-changed'] + summary['upstream-added'])
    self.assertEqual(result['counts']['kept'], summary['upstream-deleted'])
    self.assertEqual(_read(repo, 'modules/project/main.tf'), PROJECT_MAIN_V2)
    self.assertEqual(_read(repo, 'fast/stages/0-org-setup/billing.tf'),
                     ORG_BILLING)
    self.assertEqual(_read(repo, 'modules/new-mod/main.tf'), SA_MAIN)
    self.assertEqual(_read(repo, 'modules/billing-account/main.tf'),
                     BILLING_MAIN)
    self.assertTrue(
        os.access(os.path.join(repo, 'modules/project/scripts/helper.sh'),
                  os.X_OK))
    self.assertEqual(
        _read(repo, 'fast/stages/2-project-factory/data/projects/team-a.yaml'),
        TEAM_A)
    self.assertTrue(_exists(repo, 'fast/stages/2-project-factory/legacy.tf'))
    self.assertTrue(_exists(repo, 'modules/old-mod/main.tf'))
    self.assertEqual(result['moved_pending'], plan['moved_files'])
    text = fu.render_apply(result, 0)
    self.assertIn('NOT DELETED', text)
    self.assertIn('MOVED BLOCKS TO COPY', text)

  def test_deletes_and_moved_blocks_only_when_asked(self):
    repo = self.fork(extra=A_EXTRA)
    ctx, plan, results = self.plan(repo)
    result = fu.run_apply(ctx, results, include_deletes=True, copy_moved=True,
                          moved=plan['moved_files'])
    self.assertEqual(result['counts']['deleted'],
                     plan['summary']['upstream-deleted'])
    self.assertFalse(_exists(repo, 'fast/stages/2-project-factory/legacy.tf'))
    self.assertFalse(_exists(repo, 'modules/old-mod'))
    self.assertEqual(_read(repo, 'fast/stages/0-org-setup/v1.0.0-v2.0.0.tf'),
                     MOVED_NEW)
    self.assertEqual(result['moved_copied'], [{
        'file': 'fast/stages/0-org-setup/v1.0.0-v2.0.0.tf',
        'result': 'copied'
    }])

  def test_existing_moved_block_file_is_not_overwritten(self):
    repo = self.fork(
        extra={'fast/stages/0-org-setup/v1.0.0-v2.0.0.tf': '# mine\n'})
    ctx, plan, results = self.plan(repo)
    result = fu.run_apply(ctx, results, copy_moved=True,
                          moved=plan['moved_files'])
    self.assertEqual(result['moved_copied'][0]['result'], 'exists')
    self.assertEqual(_read(repo, 'fast/stages/0-org-setup/v1.0.0-v2.0.0.tf'),
                     '# mine\n')

  def test_round_trip_re_plans(self):
    repo = self.fork(extra=A_EXTRA)
    ctx, plan, results = self.plan(repo)
    fu.run_apply(ctx, results, include_deletes=True, copy_moved=True,
                 moved=plan['moved_files'])
    _, replan, _ = self.plan(repo)
    self.assertNotIn('upstream-changed', replan['summary'])
    self.assertNotIn('upstream-added', replan['summary'])
    self.assertNotIn('upstream-deleted', replan['summary'])
    self.assertGreater(replan['summary']['already-updated'], 0)
    _, delta, _ = self.plan(repo, base=UP[V2], target=UP[V2])
    self.assertTrue(set(delta['summary']) <= set(DELTA), delta['summary'])
    added = {
        f['path'] for f in delta['files'] if f['category'] == 'customer-added'
    }
    self.assertIn('fast/stages/0-org-setup/terraform.tfvars', added)
    self.assertIn('fast/stages/0-org-setup/v1.0.0-v2.0.0.tf', added)
    detected = fu.detect(repo)
    self.assertEqual(
        (detected['version']['detected'], detected['version']['confidence']),
        (V2, 'high'))

  def test_conflicts_merges_and_manual_items(self):
    repo = self.fork(edits=B_EDITS, extra=B_EXTRA, remove=B_REMOVE)
    ctx, plan, results = self.plan(repo)
    result = fu.run_apply(ctx, results, moved=plan['moved_files'])
    outcome = {r['path']: r['result'] for r in result['records']}
    self.assertEqual(outcome['modules/project/main.tf'], 'conflict')
    self.assertEqual(outcome['fast/stages/0-org-setup/variables.tf'], 'merged')
    self.assertEqual(outcome['modules/new-mod/main.tf'], 'merged')
    self.assertEqual(outcome['modules/old-mod/main.tf'], 'kept')
    for path in ('fast/stages/2-project-factory/legacy.tf',
                 'fast/stages/0-org-setup/billing.tf',
                 'fast/stages/0-org-setup/README.md'):
      with self.subTest(path=path):
        self.assertEqual(outcome[path], 'manual')
    self.assertNotIn('modules/net-vpc/README.md', outcome)
    merged = _read(repo, 'modules/project/main.tf')
    for marker in ('<<<<<<< customer', '||||||| base v1.0.0', '=======',
                   '>>>>>>> target v2.0.0', 'distinct(each.value)',
                   'each.value.permissions'):
      with self.subTest(marker=marker):
        self.assertIn(marker, merged)
    # The non-overlapping upstream change in the same file merged cleanly.
    self.assertIn('folder_id  = var.parent', merged.split('<<<<<<<')[0])
    variables = _read(repo, 'fast/stages/0-org-setup/variables.tf')
    self.assertIn('# Managed by the platform team.', variables)
    self.assertIn('variable "billing_account"', variables)
    self.assertNotIn('<<<<<<<', variables)
    self.assertIn('display_name = "Customer SA"',
                  _read(repo, 'modules/new-mod/main.tf'))
    self.assertEqual(_read(repo, 'fast/stages/0-org-setup/billing.tf'),
                     B_EXTRA['fast/stages/0-org-setup/billing.tf'])
    # `git diff --check` is how the skill verifies that no marker is left.
    check = _git(repo, 'diff', '--check', check=False)
    self.assertNotEqual(check.returncode, 0)
    self.assertIn('modules/project/main.tf', check.stdout)
    self.assertIn('leftover conflict marker', check.stdout)
    self.assertNotIn('variables.tf', check.stdout)

  def test_bump_refs_only_touches_fabric_sources_at_the_base(self):
    pinned = (f'module "pinned" {{\n  source = "{FABRIC_GIT}//modules/net-vpc'
              f'?ref=v0.9.0"\n  network_name = "n"\n}}\n')
    repo = self.git_sourced(extra={'0-org-setup/pinned.tf': pinned})
    ctx, plan, results = self.plan(repo)
    fu.run_apply(ctx, results, bump=True, moved=plan['moved_files'])
    self.assertEqual(_read(repo, '0-org-setup/pinned.tf'), pinned)
    ctx, plan, results = self.plan(repo)
    self.assertEqual(plan['git_refs']['bumpable'], 0)


# --------------------------------------------------------------------------
# releases, fetch, detect, changelog, check-data
# --------------------------------------------------------------------------


@needs_git
class TestReleasesFetchDetect(_Case):

  def fabric_clone(self):
    """A local Fabric-like git repository with both release tags."""
    repo = self.path('fabric')
    _make_tree(repo, upstream_files(V1))
    _commit_all(repo, 'release v1')
    _git(repo, 'tag', V1)
    for top in ('fast', 'modules'):
      shutil.rmtree(os.path.join(repo, top))
    _make_tree(repo, upstream_files(V2))
    _commit_all(repo, 'release v2')
    _git(repo, 'tag', V2)
    return repo

  def test_releases(self):
    repo = self.fabric_clone()
    self.assertEqual(fu.list_releases(repo), [V2, V1])
    code, out, _ = _run(fu, ['releases', '--upstream', repo])
    self.assertEqual(code, 0)
    self.assertIn(f'latest {V2} (2 releases', out)
    code, out, _ = _run(fu, ['releases', '--upstream', repo, '--json'])
    self.assertEqual(json.loads(out)['releases'], [V2, V1])

  def test_fetch_from_local_clone_and_cache(self):
    repo = self.fabric_clone()
    cache = self.path('cache')
    path, how = fu.fetch_release(V1, from_repo=repo, cache_dir=cache)
    self.assertTrue(how.startswith(f'git archive of {V1}'))
    self.assertEqual(fu.release_version(path), V1)
    self.assertTrue(_exists(path, 'CHANGELOG.md'))
    self.assertTrue(_exists(path, 'fast/stages/2-project-factory/legacy.tf'))
    self.assertEqual(fu.fetch_release(V1, from_repo=repo, cache_dir=cache),
                     (path, 'cached'))
    self.assertNotEqual(
        fu.fetch_release(V1, from_repo=repo, cache_dir=cache, refresh=True)[1],
        'cached')
    code, out, _ = _run(
        fu, ['fetch', V2, '--from-repo', repo, '--cache-dir', cache])
    self.assertEqual(code, 0)
    self.assertEqual(out.splitlines()[-1], os.path.join(cache, V2))
    self.assertIn(f'release marker {V2}', out)

  def test_fetch_by_clone(self):
    repo = self.fabric_clone()
    path, how = fu.fetch_release(V2, url='file://' + repo,
                                 cache_dir=self.path('cache'))
    self.assertTrue(how.startswith(f'git clone of {V2}'))
    self.assertEqual(fu.release_version(path), V2)
    self.assertFalse(_exists(path, '.git'))
    # The same release has the same digest however it was fetched.
    archived, _ = fu.fetch_release(V2, from_repo=repo,
                                   cache_dir=self.path('cache2'))
    self.assertEqual(provenance.tree_digest(path),
                     provenance.tree_digest(archived))

  def test_fetch_refuses_unsafe_or_missing_refs(self):
    repo = self.fabric_clone()
    for ref in ('v1.0.0; rm -rf /', '../v1.0.0', '-v1', 'a..b'):
      with self.subTest(ref=ref):
        with self.assertRaisesRegex(fu.UpgradeError, 'unsafe ref'):
          fu.fetch_release(ref, from_repo=repo, cache_dir=self.path('c'))
    with self.assertRaisesRegex(fu.UpgradeError, 'is not a tag of'):
      fu.fetch_release('v9.9.9', from_repo=repo, cache_dir=self.path('c'))
    self.assertEqual(os.listdir(self.path('c')), [])

  def test_detect(self):
    repo = self.fork(extra=A_EXTRA)
    result = fu.detect(repo)
    self.assertEqual(result['version']['detected'], V1)
    self.assertEqual(result['version']['confidence'], 'high')
    self.assertEqual([s['path'] for s in result['stages']], [
        'fast/extras/0-cicd-github', 'fast/stages/0-org-setup',
        'fast/stages/2-project-factory'
    ])
    self.assertEqual(result['modules']['roots'], {'modules': 3})
    self.assertEqual(result['factory']['yaml_files'], 4)
    self.assertEqual(result['warnings'], [])
    self.assertTrue(result['git']['git'])
    self.assertFalse(result['upstream_history'])
    text = fu.render_detect(result, 0)
    self.assertIn(f'release {V1} (high)', text)
    self.assertIn('found by marker', text)

  def test_detect_git_sourced_and_unknown(self):
    result = fu.detect(self.git_sourced())
    self.assertEqual(result['fabric_git_refs'], {V1: 3})
    self.assertEqual(result['modules']['calls'], {'git': 4})
    plain = self.path('plain')
    _write(plain, 'main.tf', 'locals {}\n')
    result = fu.detect(plain)
    self.assertIsNone(result['version']['detected'])
    warnings = ' '.join(result['warnings'])
    self.assertIn('no FAST or Fabric release marker found', warnings)
    self.assertIn('no stage folder found', warnings)
    self.assertFalse(result['git']['git'])

  def test_detect_upstream_history(self):
    fabric = self.fabric_clone()
    fork = self.path('fork')
    subprocess.run(['git', 'clone', '-q', fabric, fork], check=True,
                   env=_GIT_ENV, capture_output=True)
    result = fu.detect(fork)
    self.assertTrue(result['upstream_history'])
    self.assertIn('HISTORY', fu.render_detect(result, 0))


def _tar(*entries):
  """An in-memory tar archive of (name, kind, payload) entries."""
  buf = io.BytesIO()
  with tarfile.open(fileobj=buf, mode='w') as tar:
    for name, kind, payload in entries:
      info = tarfile.TarInfo(name)
      if kind == 'file':
        data = payload.encode('utf-8')
        info.size = len(data)
        tar.addfile(info, io.BytesIO(data))
        continue
      info.type = {
          'dir': tarfile.DIRTYPE,
          'symlink': tarfile.SYMTYPE,
          'hardlink': tarfile.LNKTYPE,
          'fifo': tarfile.FIFOTYPE,
      }[kind]
      info.mode = 0o755 if kind == 'dir' else 0o644
      info.linkname = payload or ''
      tar.addfile(info)
  return buf.getvalue()


@contextlib.contextmanager
def _without_tar_filters():
  """Runs fast_upgrade as on a Python without tar extraction filters."""
  with mock.patch.object(fu, 'TAR_FILTERS', False), warnings.catch_warnings():
    # Python 3.12 and 3.13 warn about extracting without a filter.
    warnings.simplefilter('ignore', DeprecationWarning)
    yield


class TestExtract(_Case):
  """Release archives never write outside the destination folder."""

  # Like a real release: a folder symlink and a file symlink, both in-tree.
  SAFE = (
      ('fast/', 'dir', None),
      ('fast/stages/2-networking/datasets/hub/main.tf', 'file', 'locals {}\n'),
      ('fast/stages/2-networking/datasets/classic', 'symlink', 'hub/'),
      ('default-versions.tf', 'file', 'terraform {}\n'),
      ('modules/project/versions.tf', 'symlink', '../../default-versions.tf'),
  )
  # Refused with and without tar filters.
  ESCAPING = {
      'climbing-name': [('fast/../../evil', 'file', 'x')],
      'absolute-symlink': [('fast/link', 'symlink', '/etc')],
      'climbing-symlink': [('fast/link', 'symlink', '../../evil')],
      'climbing-hard-link': [('fast/link', 'hardlink', '../evil')],
      'symlink-chain': [('fast/a', 'symlink', '..'),
                        ('fast/a/b', 'symlink', '..'),
                        ('fast/a/b/evil', 'file', 'x')],
      'special-file': [('fast/pipe', 'fifo', None)],
  }
  # Kept inside the destination by the 'data' filter; the fallback's
  # lexical checks refuse them outright.
  FALLBACK_ONLY = {
      'absolute-name': [('/evil', 'file', 'x')],
      'member-under-a-link': [('fast/link', 'symlink', '.'),
                              ('fast/link/main.tf', 'file', 'x')],
  }

  def extract(self, entries, name='safe'):
    dest = self.path('box', name)
    os.makedirs(dest)
    fu._extract(_tar(*entries), dest)
    return dest

  def assert_safe_tree(self, dest):
    self.assertEqual(
        _read(dest, 'fast/stages/2-networking/datasets/classic/main.tf'),
        'locals {}\n')
    link = os.path.join(dest, 'modules', 'project', 'versions.tf')
    self.assertEqual(os.readlink(link), '../../default-versions.tf')
    self.assertEqual(_read(dest, 'modules/project/versions.tf'),
                     'terraform {}\n')

  @unittest.skipUnless(tarfile.__dict__.get('data_filter'),
                       'needs tar extraction filters')
  def test_with_tar_filters(self):
    self.assertTrue(fu.TAR_FILTERS)
    self.assert_safe_tree(self.extract(self.SAFE))
    for case, entries in self.ESCAPING.items():
      with self.subTest(case=case):
        with self.assertRaisesRegex(fu.UpgradeError, 'cannot extract release'):
          self.extract(entries, case)
    for case, entries in self.FALLBACK_ONLY.items():
      with self.subTest(case=case):
        self.extract(entries, case)
    self.assertEqual(
        sorted(os.listdir(self.path('box'))),
        sorted(['safe'] + list(self.ESCAPING) + list(self.FALLBACK_ONLY)))

  def test_without_tar_filters(self):
    with _without_tar_filters():
      self.assert_safe_tree(self.extract(self.SAFE))
      for case, entries in {**self.ESCAPING, **self.FALLBACK_ONLY}.items():
        with self.subTest(case=case):
          with self.assertRaisesRegex(fu.UpgradeError,
                                      'unsafe path in archive'):
            self.extract(entries, case)
          # Checked before extraction starts: nothing is written at all.
          self.assertEqual(os.listdir(self.path('box', case)), [])

  def test_corrupt_archive(self):
    for filters in (False, True):
      with self.subTest(filters=filters):
        with mock.patch.object(fu, 'TAR_FILTERS', filters):
          with self.assertRaisesRegex(fu.UpgradeError,
                                      'cannot extract release archive'):
            fu._extract(b'not a tar archive', self.tmp)


class TestChangelogAndCheckData(_Case):

  def test_changelog_unfiltered(self):
    result = fu.changelog(UP[V2], V1, V2)
    self.assertEqual(result['releases'], ['v1.1.0', V2])
    self.assertEqual(len(result['breaking_changes']), 7)
    self.assertTrue(
        all(b['reason'] == 'unfiltered' for b in result['breaking_changes']))
    self.assertEqual(result['module_renames'], {'old-mod': 'new-mod'})
    self.assertEqual(len(result['upgrading_notes']), 2)
    text = fu.render_changelog(result, 0)
    self.assertIn('BREAKING CHANGES (7)', text)
    self.assertIn('old-mod -> new-mod', text)
    self.assertIn('#20 Improve org setup', text)

  @needs_git
  def test_changelog_filtered_by_repository(self):
    result = fu.changelog(UP[V2], V1, V2, repo=self.fork())
    relevant = [b for b in result['breaking_changes'] if b['relevant']]
    self.assertEqual(len(relevant), 4)
    self.assertIn('(3 more affect stages or modules not in use',
                  fu.render_changelog(result, 0))

  def test_changelog_errors(self):
    with self.assertRaisesRegex(fu.UpgradeError, 'releases like v57.0.0'):
      fu.changelog(UP[V2], 'latest', V2)
    with self.assertRaisesRegex(fu.UpgradeError, 'newer than --from'):
      fu.changelog(UP[V2], V2, V1)
    with self.assertRaisesRegex(fu.UpgradeError, 'no CHANGELOG.md'):
      fu.changelog(self.tmp, V1, V2)

  @needs_data
  def test_check_data_cli(self):
    root = self.path('data')
    _write(root, 'schemas/project.schema.json', json.dumps(SCHEMA_V2))
    _write(root, 'projects/ok.yaml', TEAM_B)
    code, out, _ = _run(fu, ['check-data', root])
    self.assertEqual(code, 0)
    self.assertIn('files   ok 1', out)
    _write(root, 'projects/bad.yaml', TEAM_A)
    code, out, _ = _run(fu, ['check-data', root])
    self.assertEqual(code, 2)
    self.assertIn('INVALID', out)
    # A modeline that points nowhere resolves by name with --schemas.
    moved = self.path('elsewhere')
    _write(moved, 'p.yaml', TEAM_B)
    code, out, _ = _run(fu, ['check-data', moved, '--json'])
    self.assertEqual(json.loads(out)['counts'], {'unresolved': 1})
    code, out, _ = _run(fu, [
        'check-data', moved, '--schemas',
        os.path.join(root, 'schemas'), '--json'
    ])
    self.assertEqual((code, json.loads(out)['counts']), (0, {'ok': 1}))
    code, _, err = _run(fu, ['check-data', self.path('missing')])
    self.assertEqual(code, 1)
    self.assertIn('path not found', err)


# --------------------------------------------------------------------------
# plan_review
# --------------------------------------------------------------------------


def _rc(address, actions, type_='google_project', change=None, **extra):
  rc = {
      'address': address,
      'mode': 'managed',
      'type': type_,
      'name': address.split('.')[-1],
      'change': dict({'actions': actions}, **(change or {})),
  }
  rc.update(extra)
  return rc


def _plan_json(changes, drift=()):
  return json.dumps({
      'format_version': '1.2',
      'terraform_version': '1.13.3',
      'planned_values': {},
      'resource_changes': list(changes),
      'resource_drift': list(drift),
  })


class TestPlanReview(_Case):

  def test_classify(self):
    cases = [
        (_rc('a.b', ['create']), 'create'),
        (_rc('a.b', ['update']), 'update'),
        (_rc('a.b', ['delete']), 'delete'),
        (_rc('a.b', ['delete', 'create']), 'replace'),
        (_rc('a.b', ['create', 'delete']), 'replace'),
        (_rc('a.b', ['no-op']), 'no-op'),
        (_rc('a.b', []), 'no-op'),
        (_rc('a.b', ['no-op'], previous_address='a.old'), 'moved'),
        (_rc('a.b', ['no-op'], change={'importing': {
            'id': 'x'
        }}), 'import'),
        (_rc('a.b', ['forget']), 'forget'),
        (_rc('a.b', ['read'], mode='data'), 'read'),
        (_rc('a.b', ['frobnicate']), 'unknown'),
    ]
    for rc, kind in cases:
      with self.subTest(actions=rc['change']['actions'], kind=kind):
        self.assertEqual(plan_review.classify(rc)[0], kind)
    _, detail = plan_review.classify(
        _rc('a.b', ['delete'], action_reason='delete_because_each_key'))
    self.assertEqual(detail['hint'],
                     plan_review.REASON_HINTS['delete_because_each_key'])

  def test_review(self):
    plan = json.loads(
        _plan_json([
            _rc('terraform_data.x', ['create', 'delete'], 'terraform_data'),
            _rc('google_storage_bucket.b', ['delete', 'create'],
                'google_storage_bucket', change={
                    'replace_paths': [['location']]
                }, action_reason='replace_because_cannot_update'),
            _rc('google_project.p', ['delete'],
                action_reason='delete_because_no_resource_config'),
            _rc('google_project_iam_binding.b', ['update'],
                'google_project_iam_binding'),
            _rc('google_project_iam_member.m', ['update'],
                'google_project_iam_member'),
            _rc('module.a.google_folder.f', ['no-op'], 'google_folder',
                previous_address='google_folder.f'),
            _rc('google_folder.i', ['no-op'], 'google_folder',
                change={'importing': {
                    'id': 'folders/1'
                }}),
            _rc('google_tags_tag_key.k', ['forget'], 'google_tags_tag_key'),
            _rc('google_x.y', ['frobnicate'], 'google_x'),
            _rc('data.google_project.p', ['read'], mode='data'),
        ], drift=[{
            'address': 'google_project.p'
        }]))
    result = plan_review.review(plan)
    self.assertEqual(
        result['counts'], {
            'replace': 2,
            'delete': 1,
            'update': 2,
            'moved': 1,
            'import': 1,
            'forget': 1,
            'unknown': 1,
            'read': 1
        })
    self.assertEqual(
        [d['address'] for d in result['destructive']],
        ['google_project.p', 'google_storage_bucket.b', 'terraform_data.x'])
    self.assertIn('project IDs can never be reused',
                  result['destructive'][0]['critical'])
    self.assertNotIn('critical', result['destructive'][2])
    self.assertEqual([s['address'] for s in result['sensitive']],
                     ['google_project_iam_binding.b'])
    self.assertEqual(result['moved'], [{
        'from': 'google_folder.f',
        'to': 'module.a.google_folder.f'
    }])
    self.assertEqual((len(result['forget']), len(
        result['unknown']), result['drift'], result['verdict']),
                     (1, 1, 1, 'destructive'))

  def test_critical_types(self):
    for resource_type in ('google_org_policy_custom_constraint',
                          'google_kms_crypto_key', 'google_folder',
                          'google_organization_iam_custom_role'):
      with self.subTest(type=resource_type):
        self.assertIsNotNone(
            plan_review._match(plan_review.CRITICAL_TYPES, resource_type))
    self.assertIsNone(
        plan_review._match(plan_review.CRITICAL_TYPES,
                           'google_project_iam_member'))

  def test_load_plan_rejects_non_plans(self):
    self.assertIn('not valid JSON', plan_review.load_plan(b'nope')[1])
    self.assertIn('not a terraform plan',
                  plan_review.load_plan(b'{"format_version": "1.0"}')[1])
    state = json.dumps({'format_version': '1.0', 'values': {}}).encode()
    self.assertIn('prints state instead', plan_review.load_plan(state)[1])
    self.assertIn('not a terraform plan', plan_review.load_plan(b'[1]')[1])

  def test_cli_verdicts_and_exit_codes(self):
    code, out, _ = _run(plan_review, [], stdin_text=_plan_json([]))
    self.assertEqual(code, 0)
    self.assertIn('VERDICT: no changes', out)
    self.assertIn('input plan <stdin> sha256:', out)
    safe = _plan_json([
        _rc('google_project.p', ['update']),
        _rc('google_project_iam_policy.p', ['update'],
            'google_project_iam_policy')
    ])
    code, out, _ = _run(plan_review, [], stdin_text=safe)
    self.assertEqual(code, 0)
    self.assertIn('VERDICT: no deletes or replacements', out)
    self.assertIn('SENSITIVE UPDATES (1)', out)
    path = _write(
        self.tmp, 'plan.json',
        _plan_json([
            _rc('terraform_data.keyed["x"]', ['delete'], 'terraform_data',
                action_reason='delete_because_each_key'),
            _rc('terraform_data.forced', ['delete', 'create'], 'terraform_data',
                change={'replace_paths': [['triggers_replace']]},
                action_reason='replace_because_cannot_update'),
        ]))
    code, out, _ = _run(plan_review, [path])
    self.assertEqual(code, 2)
    self.assertIn(f'input plan {os.path.abspath(path)} sha256:', out)
    self.assertIn('DESTRUCTIVE (2)', out)
    self.assertIn('why: delete_because_each_key: its for_each key changed', out)
    self.assertIn('replace paths: triggers_replace', out)
    self.assertIn('VERDICT: 2 destructive or unrecognized change(s)', out)
    code, out, _ = _run(plan_review, [path, '--json'])
    data = json.loads(out)
    self.assertEqual((code, data['verdict']), (2, 'destructive'))
    self.assertEqual(data['tool']['digest'], provenance.tool_digest())
    code, _, err = _run(plan_review, [], stdin_text='{"values": {}}')
    self.assertEqual(code, 1)
    self.assertIn('ERROR:', err)
    code, _, err = _run(plan_review, [self.path('missing.json')])
    self.assertEqual(code, 1)
    self.assertIn('cannot read', err)


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------


@needs_git
class TestCli(_Case):

  def args(self, repo, *extra):
    return ['--repo', repo, '--base', UP[V1], '--target', UP[V2]] + list(extra)

  def test_plan_text_json_and_output(self):
    repo = self.fork(extra=A_EXTRA)
    plan = ['plan'
           ] + ([] if factory_data.available() else ['--skip-data-checks'])
    code, out, _ = _run(fu, plan + self.args(repo))
    self.assertEqual(code, 0)
    self.assertTrue(out.startswith('fast-upgrade plan | tools '))
    code, out, _ = _run(fu, plan + self.args(repo, '--json'))
    self.assertEqual(json.loads(out)['base']['version'], V1)
    report_path = self.path('plan.json')
    code, out, _ = _run(
        fu, plan + self.args(repo, '--json', '--output', report_path))
    self.assertEqual(len(out.splitlines()), 1)
    self.assertIn('wrote JSON to', out)
    with open(report_path, encoding='utf-8') as f:
      self.assertEqual(json.load(f)['target']['version'], V2)
    text_report = self.path('plan.txt')
    code, out, _ = _run(fu, plan + self.args(repo, '--output', text_report))
    with open(text_report, encoding='utf-8') as f:
      self.assertEqual(f.read(), out)

  def test_apply_exit_codes(self):
    repo = self.fork(edits=B_EDITS, extra=B_EXTRA, remove=B_REMOVE)
    code, out, _ = _run(fu, ['apply'] + self.args(repo, '--dry-run'))
    self.assertEqual(code, 2)
    self.assertIn('apply (DRY RUN: nothing written)', out)
    code, out, _ = _run(fu, ['apply'] + self.args(repo))
    self.assertEqual(code, 2)
    self.assertIn('CONFLICT MARKERS (1)', out)
    code, _, err = _run(fu, ['apply'] + self.args(repo))
    self.assertEqual(code, 1)
    self.assertIn('REFUSED:', err)
    clean = self.fork(name='clean', extra=A_EXTRA)
    code, _, _ = _run(fu, ['apply'] + self.args(clean))
    self.assertEqual(code, 0)

  def test_errors_exit_1(self):
    repo = self.fork()
    code, _, err = _run(
        fu, ['plan', '--repo', repo, '--base', UP[V2], '--target', UP[V1]])
    self.assertEqual(code, 1)
    self.assertIn('ERROR: target v1.0.0 is older than base v2.0.0', err)
    code, _, err = _run(
        fu, ['changelog', '--upstream-dir', UP[V2], '--from', V2, '--to', V1])
    self.assertEqual(code, 1)
    with self.assertRaises(SystemExit):
      with contextlib.redirect_stderr(io.StringIO()):
        fu.main(['plan'])

  def test_detect_and_changelog_commands(self):
    repo = self.fork()
    code, out, _ = _run(fu, ['detect', repo, '--json'])
    self.assertEqual((code, json.loads(out)['version']['detected']), (0, V1))
    code, out, _ = _run(fu, [
        'changelog', '--upstream-dir', UP[V2], '--from', V1, '--to', V2,
        '--repo', repo
    ])
    self.assertEqual(code, 0)
    self.assertIn('BREAKING CHANGES (relevant to the repository) (4)', out)


# --------------------------------------------------------------------------
# Deep checks, findings and the shareable report
# --------------------------------------------------------------------------

ADDON_V1 = _d('''
    module "test-vm" {
      source     = "../../../modules/compute-vm"
      project_id = var.project_id
      zone       = "europe-west1-b"
      name       = "test-vm"
      network_interfaces = [{
        network    = var.network
        subnetwork = var.subnetwork
      }]
      tags = ["ssh", "http-server"]
    }
    ''')
ADDON_V2 = ADDON_V1.replace(
    '  tags = ["ssh", "http-server"]\n', '  tags = ["ssh", "http-server"]\n'
    '  shielded_config = {}\n')


class TestFactoryDataView(unittest.TestCase):

  def test_terraform_view_makes_keys_and_dates_strings(self):
    import datetime  # pylint: disable=import-outside-toplevel
    doc = {
        113008: 'a',
        True: 'b',
        None: 'c',
        'when': datetime.date(2024, 1, 2),
        'list': [{
            1: datetime.date(2024, 1, 3)
        }],
    }
    self.assertEqual(
        factory_data.terraform_view(doc), {
            '113008': 'a',
            'true': 'b',
            'null': 'c',
            'when': '2024-01-02',
            'list': [{
                '1': '2024-01-03'
            }],
        })

  @needs_data
  def test_numeric_keys_and_dates_validate_like_terraform(self):
    schema = {
        'type': 'object',
        'properties': {
            'values': {
                'type': 'object',
                'propertyNames': {
                    'pattern': '^[0-9]+$'
                },
                'additionalProperties': {
                    'type': 'string'
                },
            },
            'expires': {
                'type': 'string'
            },
        },
    }
    text = 'values:\n  113008: team-a\n  471209: team-b\nexpires: 2026-01-01\n'
    self.assertEqual(factory_data.validate_text(text, schema), [])

  @needs_data
  def test_validator_failure_is_not_invalid_data(self):
    schema = {'$ref': '#/definitions/missing'}
    errors = factory_data.validate_text('name: x\n', schema)
    self.assertTrue(factory_data.is_validator_error(errors), errors)
    self.assertFalse(factory_data.is_validator_error(['name: bad']))
    self.assertFalse(factory_data.is_validator_error([]))


class TestVersionConstraints(unittest.TestCase):

  def test_constraint_allows(self):
    cases = [
        ('>= 7.40.0, < 8.0.0', '8.4.0', False),
        ('>= 7.40.0, < 8.0.0', '7.50.1', True),
        ('>= 8.4.0, < 9.0.0', '8.4.0', True),
        ('~> 8.4', '8.9.0', True),
        ('~> 8.4', '9.0.0', False),
        ('~> 8.4.1', '8.5.0', False),
        ('= 1.2.3', '1.2.3', True),
        ('!= 1.2.3', '1.2.3', False),
        ('1.2', '1.2.0', True),
        ('> 1.0.0', '1.0.0', False),
        ('<= 1.0.0', '1.0.0', True),
    ]
    for constraint, version, expected in cases:
      with self.subTest(constraint=constraint, version=version):
        self.assertEqual(fu.constraint_allows(constraint, version), expected)
    self.assertIsNone(fu.constraint_allows('>= banana', '1.0.0'))
    self.assertIsNone(fu.constraint_allows(None, '1.0.0'))

  def test_lower_bound(self):
    self.assertEqual(fu.lower_bound('>= 8.4.0, < 9.0.0'), (8, 4, 0))
    self.assertEqual(fu.lower_bound('~> 1.10'), (1, 10, 0))
    self.assertIsNone(fu.lower_bound('< 9.0.0'))
    self.assertIsNone(fu.lower_bound(None))


@needs_git
class TestDeepChecks(_Case):

  def test_customer_version_pins_block_init(self):
    pins = DEFAULT_VERSIONS.replace('@@V@@',
                                    V1).replace('@@G@@', '>= 7.0.0, < 8.0.0')
    repo = self.fork(extra={'fast/stages/0-org-setup/terraform.tf': pins})
    ctx, plan, _ = self.plan(repo)
    self.assertIn('pin', ctx.breakdown)
    [entry] = plan['version_pins']
    self.assertEqual(entry['file'], 'fast/stages/0-org-setup/terraform.tf')
    self.assertTrue(entry['blocks_init'])
    self.assertTrue(entry['stale_marker'])
    google = {p['name']: p for p in entry['pins']}['google']
    self.assertIs(google['allows_target'], False)
    self.assertEqual(google['target'], '>= 8.0.0, < 9.0.0')
    blockers = [f for f in plan['findings'] if f['severity'] == 'blocker']
    self.assertEqual([f['files'] for f in blockers],
                     [['fast/stages/0-org-setup/terraform.tf']])
    self.assertEqual(blockers[0]['stage'], 'fast/stages/0-org-setup')
    self.assertEqual(plan['readiness']['status'], 'BLOCKED')
    self.assertIn('BLOCKS INIT fast/stages/0-org-setup/terraform.tf',
                  fu.render_plan(plan, 0))

  def test_vanilla_fork_has_no_blocker_and_no_pins(self):
    _, plan, _ = self.plan(self.fork(extra=A_EXTRA))
    self.assertEqual(plan['version_pins'], [])
    self.assertEqual(plan['linked_repos'], [])
    self.assertEqual(plan['addon_copies'], [])
    self.assertEqual(plan['readiness']['counts']['blocker'], 0)
    self.assertEqual(plan['readiness']['status'], 'NEEDS WORK')
    self.assertEqual([f['id'] for f in plan['findings']],
                     [f'F{i:03d}' for i in range(1,
                                                 len(plan['findings']) + 1)])
    order = [fu.SEVERITIES.index(f['severity']) for f in plan['findings']]
    self.assertEqual(order, sorted(order))
    titles = ' | '.join(f['title'] for f in plan['findings'])
    self.assertIn('tfvars set variables the target no longer declares', titles)
    self.assertIn('new required variables', titles)
    self.assertIn('Moved blocks must be copied', titles)
    coverage = {c['area']: c['status'] for c in plan['coverage']}
    self.assertEqual(coverage['Terraform state and plan'], 'not checked')
    self.assertEqual(coverage['File comparison'], 'checked')
    steps = ' '.join(s['text'] for s in plan['checklist'])
    self.assertIn('terraform init -upgrade', steps)
    self.assertIn('Copy the moved-block files', steps)

  def test_file_keeping_upstream_sources_is_not_a_conflict(self):
    # One stage of a reorganized repository still uses upstream-relative
    # sources: comparing it with rewritten upstream code used to flag a
    # conflict on every such file.
    repo = self.reorganized(
        extra={'stages/0-org-setup-acme/main.tf': ORG_MAIN_V1})
    ctx, plan, results = self.plan(repo)
    entry = self.files(plan)['stages/0-org-setup-acme/main.tf']
    self.assertEqual(entry['category'], 'upstream-changed')
    self.assertTrue(entry['upstream_sources'])
    self.assertEqual(plan['upstream_sources'],
                     ['stages/0-org-setup-acme/main.tf'])
    unresolved = {(u['file'], u['source']) for u in plan['unresolved_sources']}
    self.assertIn(
        ('stages/0-org-setup-acme/main.tf', '../../../modules/project'),
        unresolved)
    self.assertIn(
        'Module sources in stages/0-org-setup-acme/main.tf will not '
        'resolve', [f['title'] for f in plan['findings']])
    self.assertEqual(
        self.files(plan)['stages/project-factory/main.tf']['upstream_sources'],
        False)
    fu.run_apply(ctx, results)
    self.assertEqual(_read(repo, 'stages/0-org-setup-acme/main.tf'),
                     ORG_MAIN_V2)

  def _linked_modules_repo(self):
    mods = self.path('mods')
    shutil.copytree(os.path.join(UP[V1], 'modules'), mods, symlinks=True)
    _commit_all(mods)
    repo = self.path('repo')
    shutil.copytree(os.path.join(UP[V1], 'fast'), os.path.join(repo, 'fast'),
                    symlinks=True)
    os.symlink(os.path.join('..', 'mods'), os.path.join(repo, 'modules'))
    _write(repo, '.gitignore', 'modules\n')
    _commit_all(repo)
    return repo, mods

  def test_symlinked_module_repository_is_checked_and_written(self):
    repo, mods = self._linked_modules_repo()
    ctx, plan, results = self.plan(repo)
    [linked] = plan['linked_repos']
    self.assertEqual(
        (linked['path'], linked['kind'], linked['outside'], linked['ignored']),
        ('modules', 'symlink', True, True))
    self.assertEqual(linked['git']['dirty'], 0)
    self.assertIn('modules is a separate repository',
                  [f['title'] for f in plan['findings']])
    self.assertIn('LINKED REPOSITORIES (1)', fu.render_plan(plan, 0))
    result = fu.run_apply(ctx, results)
    self.assertEqual(_read(mods, 'project/main.tf'), PROJECT_MAIN_V2)
    [summary] = result['linked_repos']
    self.assertEqual(summary['path'], 'modules')
    self.assertGreater(summary['files'], 0)
    self.assertTrue(
        all(
            r.get('repository') == 'modules'
            for r in result['records']
            if r['path'].startswith('modules/')))
    self.assertIn('LINKED REPOSITORIES (commit the upgrade there too)',
                  fu.render_apply(result, 0))

  def test_dirty_linked_repository_refuses_apply(self):
    repo, mods = self._linked_modules_repo()
    _write(mods, 'net-vpc/README.md', '# edited\n')
    ctx, plan, results = self.plan(repo)
    self.assertEqual(plan['linked_repos'][0]['git']['dirty'], 1)
    self.assertIn('modules has uncommitted changes',
                  [f['title'] for f in plan['findings']])
    with self.assertRaisesRegex(fu.Refused, 'separate repository with 1 '
                                'uncommitted'):
      fu.run_apply(ctx, results)
    fu.run_apply(ctx, results, dry_run=True, allow_dirty=True)

  def test_broken_tfvars_link_is_reported_with_its_target(self):
    repo = self.fork(commit=False)
    link = 'fast/stages/0-org-setup/0-globals.auto.tfvars.json'
    os.symlink('/nonexistent/tfvars/0-globals.auto.tfvars.json',
               os.path.join(repo, *link.split('/')))
    _write(repo, 'fast/stages/0-org-setup/0-org-setup-providers.tf',
           'provider "google" {}\n')
    os.symlink(os.path.join(repo, 'fast/stages/0-org-setup/outputs.tf'),
               os.path.join(repo, 'fast/stages/0-org-setup/abs-link.tf'))
    _commit_all(repo)
    _, plan, _ = self.plan(repo)
    [stage] = [
        s for s in plan['stage_variables']
        if s['stage'] == 'fast/stages/0-org-setup'
    ]
    self.assertEqual(stage['tfvars_unreadable'], [
        f'{link} (broken symlink to '
        '/nonexistent/tfvars/0-globals.auto.tfvars.json)'
    ])
    hygiene = plan['hygiene']
    self.assertEqual([l['path'] for l in hygiene['broken_links']], [link])
    self.assertEqual([l['path'] for l in hygiene['absolute_links']],
                     ['fast/stages/0-org-setup/abs-link.tf'])
    self.assertEqual(hygiene['generated_tracked'], [
        'fast/stages/0-org-setup/0-globals.auto.tfvars.json',
        'fast/stages/0-org-setup/0-org-setup-providers.tf',
    ])
    titles = [f['title'] for f in plan['findings']]
    for title in ('Broken symlinks', 'Symlinks with absolute targets',
                  'Generated provider/tfvars files are committed',
                  'fast/stages/0-org-setup: tfvars files could not be read'):
      self.assertIn(title, titles)
    coverage = {c['area']: c['status'] for c in plan['coverage']}
    self.assertEqual(coverage['Stage variables and tfvars'], 'partial')
    self.assertIn('REPOSITORY HYGIENE (4)', fu.render_plan(plan, 0))

  def test_addon_copy_is_matched_and_upstream_changes_reported(self):
    path = 'fast/addons/2-networking-test/main.tf'
    base = self.upstream_copy(V1, 'addon-base', {path: ADDON_V1})
    target = self.upstream_copy(V2, 'addon-target', {path: ADDON_V2})
    repo = self.fork(
        base=base, extra={
            'fast/stages/0-org-setup/test-vm.tf':
                '# Copied from the test add-on.\n' + ADDON_V1,
            'fast/stages/0-org-setup/unrelated.tf':
                'locals {\n  mine = 1\n}\n',
        })
    _, plan, _ = self.plan(repo, base=base, target=target)
    [copy] = plan['addon_copies']
    self.assertEqual(copy['file'], 'fast/stages/0-org-setup/test-vm.tf')
    self.assertEqual(copy['addon'], '2-networking-test')
    self.assertEqual(copy['status'], 'changed upstream')
    self.assertEqual(copy['changed_lines'], 1)
    self.assertIn(
        'fast/stages/0-org-setup/test-vm.tf is a copy of add-on '
        '2-networking-test: changed upstream (1 line(s))',
        [f['title'] for f in plan['findings']])

  def test_missing_module_folder_is_explained(self):
    repo = self.reorganized()
    shutil.rmtree(os.path.join(repo, 'tf-modules'))
    _commit_all(repo)
    result = fu.detect(repo)
    [hint] = result['modules']['missing_roots']
    self.assertEqual((hint['root'], hint['calls'], hint['exists']),
                     ('tf-modules', 3, False))
    self.assertIn('3 module sources point to the missing folder tf-modules',
                  ' '.join(result['warnings']))
    _, plan, _ = self.plan(repo)
    self.assertIn('Module sources point to a missing folder: tf-modules',
                  [f['title'] for f in plan['findings']])
    self.assertEqual(plan['readiness']['status'], 'BLOCKED')

  def test_findings_for_edits_on_both_sides(self):
    repo = self.fork(edits=B_EDITS, extra=B_EXTRA, remove=B_REMOVE)
    _, plan, _ = self.plan(repo)
    by_title = {f['title']: f for f in plan['findings']}
    conflicts = [t for t in by_title if 'changed on both sides' in t]
    self.assertTrue(conflicts)
    self.assertTrue(all(by_title[t]['severity'] == 'high' for t in conflicts))
    steps = ' '.join(s['text'] for s in plan['checklist'])
    self.assertIn('Resolve conflict markers', steps)
    text = fu.render_plan(plan, 0)
    self.assertIn('READINESS  NEEDS WORK', text)
    self.assertIn('FINDINGS (', text)
    self.assertIn('NOT CHECKED', text)


@needs_git
class TestStageMapping(_Case):
  """Stage-like folders the automatic match misses, and --map answers."""

  DRIFTED = 'platform/core-org'

  def drifted(self, keep_variables=True, extra=None):
    """0-org-setup moved to platform/core-org and mostly rewritten."""
    repo = self.fork(commit=False, extra=extra)
    os.makedirs(os.path.join(repo, 'platform'))
    shutil.move(os.path.join(repo, 'fast/stages/0-org-setup'),
                os.path.join(repo, *self.DRIFTED.split('/')))
    _write(repo, f'{self.DRIFTED}/main.tf',
           'locals {\n  org = var.organization_id\n}\n')
    _write(repo, f'{self.DRIFTED}/outputs.tf',
           'output "org" {\n  value = local.org\n}\n')
    if not keep_variables:
      _write(
          repo, f'{self.DRIFTED}/variables.tf',
          'variable "organization_id" {\n  type = string\n}\n\n'
          'variable "mine" {\n  type = string\n}\n')
    _commit_all(repo)
    return repo

  def test_close_stage_like_folder_is_a_candidate(self):
    repo = self.drifted()
    _, plan, _ = self.plan(repo)
    [candidate] = plan['stage_candidates']
    self.assertEqual(candidate['folder'], self.DRIFTED)
    self.assertEqual(candidate['reason'], 'fast_version.txt')
    best = candidate['guesses'][0]
    self.assertEqual((best['stage'], best['path']),
                     ('0-org-setup', 'fast/stages/0-org-setup'))
    self.assertEqual((best['files'], best['variables']), (0.33, 1.0))
    self.assertNotIn(('stage', self.DRIFTED), self.mappings(plan))
    self.assertNotIn(self.DRIFTED, plan['customer_only']['stages'])
    self.assertFalse(
        any(f['path'].startswith(self.DRIFTED + '/') for f in plan['files']))
    [finding] = [f for f in plan['findings'] if f['category'] == 'mapping']
    self.assertEqual((finding['severity'], finding['stage']),
                     ('high', self.DRIFTED))
    self.assertIn(f'--map {self.DRIFTED}=<stage>', finding['action'])
    self.assertEqual(plan['readiness']['status'], 'NEEDS WORK')
    self.assertIn('Confirm which FAST stage',
                  ' '.join(s['text'] for s in plan['checklist']))
    coverage = {c['area']: c['status'] for c in plan['coverage']}
    self.assertEqual(coverage['Stage-like folders waiting for a mapping'],
                     'not checked')
    text = fu.render_plan(plan, 0)
    self.assertIn('STAGE CANDIDATES (1)', text)
    self.assertIn(
        f'{self.DRIFTED}  [fast_version.txt]  guesses: '
        '0-org-setup 100%', text)

  def test_map_sets_the_stage_and_apply_writes_it(self):
    repo = self.drifted()
    ctx, plan, results = self.plan(
        repo, stage_map={self.DRIFTED: 'fast/stages/0-org-setup'})
    mapping = self.mappings(plan)[('stage', self.DRIFTED)]
    self.assertEqual((mapping['name'], mapping['match']),
                     ('0-org-setup', 'set by user'))
    self.assertEqual(plan['stage_candidates'], [])
    self.assertEqual(plan['user_mappings'], [{
        'folder': self.DRIFTED,
        'stage': '0-org-setup',
        'score': 0.33,
        'low_similarity': True
    }])
    titles = [
        f['title'] for f in plan['findings'] if f['category'] == 'mapping'
    ]
    self.assertEqual(titles, [
        f'{self.DRIFTED} was mapped to 0-org-setup by hand; only 33% of its '
        'files match'
    ])
    files = self.files(plan)
    self.assertEqual(files[f'{self.DRIFTED}/variables.tf']['category'],
                     'upstream-changed')
    self.assertEqual(files[f'{self.DRIFTED}/main.tf']['category'], 'conflict')
    fu.run_apply(ctx, results)
    self.assertEqual(_read(repo, f'{self.DRIFTED}/variables.tf'),
                     ORG_VARIABLES_V2)

  def test_map_from_the_command_line_for_plan_and_apply(self):
    repo = self.drifted()
    flags = ['--map', f'./{self.DRIFTED}/=0-org-setup']
    checks = [] if factory_data.available() else ['--skip-data-checks']
    code, out, _ = _run(fu, [
        'plan', '--repo', repo, '--base', UP[V1], '--target', UP[V2], '--json'
    ] + flags + checks)
    self.assertEqual(code, 0)
    plan = json.loads(out)
    self.assertEqual(plan['stage_candidates'], [])
    self.assertIn(('stage', self.DRIFTED), self.mappings(plan))
    code, _, _ = _run(
        fu,
        ['apply', '--repo', repo, '--base', UP[V1], '--target', UP[V2]] + flags)
    self.assertIn(code, (0, 2))
    self.assertEqual(_read(repo, f'{self.DRIFTED}/variables.tf'),
                     ORG_VARIABLES_V2)

  def test_map_none_keeps_the_folder_as_yours(self):
    repo = self.drifted()
    ctx, plan, results = self.plan(repo, stage_map={self.DRIFTED: None})
    self.assertEqual(plan['stage_candidates'], [])
    self.assertIn(self.DRIFTED, plan['customer_only']['stages'])
    self.assertNotIn('mapping', {f['category'] for f in plan['findings']})
    self.assertIn(f'set by user: {self.DRIFTED} is yours',
                  fu.render_plan(plan, 0))
    before = _read(repo, f'{self.DRIFTED}/variables.tf')
    fu.run_apply(ctx, results)
    self.assertEqual(_read(repo, f'{self.DRIFTED}/variables.tf'), before)

  def test_map_overrides_the_automatic_match(self):
    repo = self.fork()
    stage = 'fast/stages/0-org-setup'
    _, plan, _ = self.plan(repo, stage_map={stage: None})
    self.assertNotIn(('stage', stage), self.mappings(plan))
    self.assertIn(stage, plan['customer_only']['stages'])
    _, plan, _ = self.plan(repo, stage_map={stage: '0-org-setup'})
    self.assertEqual(
        self.mappings(plan)[('stage', stage)]['match'], 'set by user')
    [user] = plan['user_mappings']
    self.assertFalse(user['low_similarity'])
    self.assertNotIn('mapping', {f['category'] for f in plan['findings']})

  def test_low_file_similarity_still_asks_by_interface(self):
    repo = self.drifted(keep_variables=False)
    _, plan, _ = self.plan(repo)
    [candidate] = plan['stage_candidates']
    best = candidate['guesses'][0]
    self.assertEqual((best['stage'], best['files'], best['variables']),
                     ('0-org-setup', 0.0, 0.25))

  def test_unrelated_folders_are_not_candidates(self):
    repo = self.fork(
        extra={
            # Not built like a stage.
            'apps/web/main.tf':
                'resource "null_resource" "web" {}\n',
            'apps/web/variables.tf':
                'variable "region" {\n  type = string\n}\n',
            # Built like a stage, but like none of FAST's.
            'platform/other/fast_version.txt':
                f'# FAST release: {V1}\n',
            'platform/other/main.tf':
                'locals {\n  x = var.zzz\n}\n',
            'platform/other/variables.tf':
                'variable "zzz" {\n  type = string\n}\n',
        })
    _, plan, _ = self.plan(repo)
    self.assertEqual(plan['stage_candidates'], [])
    self.assertIn('platform/other', plan['customer_only']['stages'])

  def test_stage_variables_make_a_folder_stage_like(self):
    repo = self.fork(
        extra={
            'envs/platform/main.tf':
                'locals {\n  p = var.prefix\n}\n',
            'envs/platform/variables.tf':
                ''.join(f'variable "{n}" {{\n  type = string\n}}\n'
                        for n in ('prefix', 'billing_account', 'organization',
                                  'organization_id', 'custom_roles')),
        })
    _, plan, _ = self.plan(repo)
    [candidate] = plan['stage_candidates']
    self.assertEqual(candidate['folder'], 'envs/platform')
    self.assertTrue(candidate['reason'].startswith('FAST stage variables'))

  def test_parse_stage_map(self):
    self.assertEqual(
        fu.parse_stage_map(
            ['a/b=0-org-setup', './c/=none', '.=fast/stages/2-networking/']), {
                'a/b': '0-org-setup',
                'c': None,
                '': 'fast/stages/2-networking'
            })
    for bad, message in (
        ('nofolder', 'use FOLDER=STAGE'),
        ('a=', 'use FOLDER=STAGE'),
        ('=0-org-setup', 'use FOLDER=STAGE'),
        ('../x=0-org-setup', 'inside the repository'),
        ('/abs=0-org-setup', 'inside the repository'),
    ):
      with self.subTest(value=bad):
        with self.assertRaisesRegex(fu.UpgradeError, message):
          fu.parse_stage_map([bad])
    with self.assertRaisesRegex(fu.UpgradeError, 'more than once'):
      fu.parse_stage_map(['a=0-org-setup', 'a/=none'])

  def test_invalid_maps_are_refused(self):
    repo = self.drifted(extra={'docs/README.md': '# docs\n'})
    for stage_map, message in (
        ({
            self.DRIFTED: '9-nope'
        }, 'not a stage of the base release v1.0.0; '
         'use one of: 0-cicd-github, 0-org-setup, 2-project-factory'),
        ({
            'missing': '0-org-setup'
        }, 'no such folder'),
        ({
            'docs': '0-org-setup'
        }, 'has no .tf files'),
    ):
      with self.subTest(stage_map=stage_map):
        with self.assertRaisesRegex(fu.UpgradeError, re.escape(message)):
          self.plan(repo, stage_map=stage_map)


@needs_git
class TestGenericLayouts(_Case):
  """What any fork can carry besides the stage and module folders."""

  def release_fork(self, name='repo', extra=None, **kwargs):
    """A fork that also kept the release files next to fast/."""
    repo = self.fork(name, commit=False, extra=extra, **kwargs)
    for rel_path in fu.RELEASE_ROOT_FILES:
      if not _exists(repo, rel_path):
        _write(repo, rel_path, _read(UP[V1], rel_path))
    _commit_all(repo)
    return repo

  def test_release_files_next_to_fast_are_upgraded(self):
    repo = self.release_fork(extra=A_EXTRA)
    ctx, plan, results = self.plan(repo)
    files = self.files(plan)
    for rel_path in fu.RELEASE_ROOT_FILES:
      self.assertEqual(files[rel_path]['category'], 'upstream-changed')
    self.assertIn(('files', ''), self.mappings(plan))
    # The root default-versions.tf pins the base providers, but it is the
    # release's own file, so it is upgraded instead of blocking init.
    self.assertEqual(plan['version_pins'], [])
    self.assertEqual(plan['readiness']['counts']['blocker'], 0)
    fu.run_apply(ctx, results, include_deletes=True)
    for rel_path in fu.RELEASE_ROOT_FILES:
      self.assertEqual(_read(repo, rel_path), _read(UP[V2], rel_path))
    result = fu.detect(repo)
    self.assertEqual(result['version']['detected'], V2)
    self.assertEqual(result['version']['confidence'], 'high')

  def test_rewritten_release_files_stay_the_customers(self):
    repo = self.release_fork(
        extra={
            'CHANGELOG.md': '# Platform changes\n',
            'default-versions.tf': 'terraform {\n  required_version = '
                                   '">= 1.10.0"\n}\n',
        })
    _, plan, _ = self.plan(repo)
    files = self.files(plan)
    for rel_path in fu.RELEASE_ROOT_FILES:
      self.assertNotIn(rel_path, files)
    self.assertNotIn(('files', ''), self.mappings(plan))

  def test_stamped_default_versions_is_merged(self):
    stamped = _read(UP[V1], 'default-versions.tf') + '# ours\n'
    repo = self.release_fork(extra={'default-versions.tf': stamped})
    _, plan, _ = self.plan(repo)
    files = self.files(plan)
    self.assertEqual(files['default-versions.tf']['category'], 'conflict')
    self.assertNotIn(
        'CHANGELOG.md',
        {f['path'] for f in plan['files'] if f['category'] == 'conflict'})

  def test_reorganized_stages_folder_maps_no_release_files(self):
    # stages/ at the repository root is not a copy of fast/: the files next
    # to it are the customer's.
    repo = self.reorganized(
        extra={'CHANGELOG.md': _read(UP[V1], 'CHANGELOG.md')})
    _, plan, _ = self.plan(repo)
    self.assertNotIn('CHANGELOG.md', self.files(plan))

  def test_module_root_files_are_mapped_when_fully_vendored(self):
    base = self.upstream_copy(V1, 'mods-base', {'modules/README.md': '# 1\n'})
    target = self.upstream_copy(V2, 'mods-target',
                                {'modules/README.md': '# 2\n'})
    repo = self.fork(base=base)
    ctx, plan, results = self.plan(repo, base=base, target=target)
    self.assertEqual(
        self.files(plan)['modules/README.md']['category'], 'upstream-changed')
    self.assertIn(('files', 'modules'), self.mappings(plan))
    fu.run_apply(ctx, results)
    self.assertEqual(_read(repo, 'modules/README.md'), '# 2\n')

  def test_version_pins_only_in_files_terraform_loads(self):
    pins = DEFAULT_VERSIONS.replace('@@V@@',
                                    V1).replace('@@G@@', '>= 7.0.0, < 8.0.0')
    repo = self.fork(
        commit=False,
        extra={
            # A template kept for copying: nothing loads it.
            'templates/versions.tf': pins,
            # Loaded through a symlink from a stage.
            'shared/versions.tf': pins,
            # One file holding both the pins and the configuration.
            'tools/single/main.tf': pins + 'resource "null_resource" "x" {}\n',
        })
    os.symlink('../../../shared/versions.tf',
               os.path.join(repo, 'fast/stages/0-org-setup/shared-versions.tf'))
    _commit_all(repo)
    _, plan, _ = self.plan(repo)
    self.assertEqual(sorted(p['file'] for p in plan['version_pins']),
                     ['shared/versions.tf', 'tools/single/main.tf'])
    self.assertTrue(all(p['blocks_init'] for p in plan['version_pins']))

  def test_generated_file_names(self):
    for name, generated in (
        ('fast/stages/1-vpcsc/wif-login-config.json', True),
        ('ci_wif.json', True),
        ('a/gh-wif-config.json', True),
        ('swift-config.json', False),
        ('wifi-setup.json', False),
        ('0-org-setup-providers.tf', True),
        ('0-globals.auto.tfvars.json', True),
    ):
      self.assertEqual(bool(fu.GENERATED_RE.search(name)), generated, name)

  def test_upstream_shipped_files_are_not_generated_files(self):
    wif = 'fast/stages/0-org-setup/wif-login-config.json'
    base = self.upstream_copy(V1, 'wif-base', {wif: '{}\n'})
    target = self.upstream_copy(V2, 'wif-target', {wif: '{"v": 2}\n'})
    repo = self.fork(
        base=base, extra={
            'fast/stages/0-org-setup/swift-config.json':
                '{}\n',
            'fast/stages/0-org-setup/ci-wif-config.json':
                '{}\n',
            'fast/stages/0-org-setup/0-org-setup-providers.tf':
                'provider "google" {}\n',
        })
    _, plan, _ = self.plan(repo, base=base, target=target)
    self.assertEqual(plan['hygiene']['generated_tracked'], [
        'fast/stages/0-org-setup/0-org-setup-providers.tf',
        'fast/stages/0-org-setup/ci-wif-config.json',
    ])

  def test_new_upstream_datasets_follow_the_forks_choice(self):
    ds = 'fast/stages/2-project-factory/datasets'
    base = self.upstream_copy(V1, 'ds-base', {
        f'{ds}/classic/a.yaml': 'name: a\n',
        f'{ds}/hardened/a.yaml': 'name: a\n',
    })
    target = self.upstream_copy(
        V2, 'ds-target', {
            f'{ds}/classic/a.yaml': 'name: a2\n',
            f'{ds}/hardened/a.yaml': 'name: a2\n',
            f'{ds}/minimal/a.yaml': 'name: m\n',
        })
    # A fork that keeps every base dataset gets the new one too.
    _, plan, _ = self.plan(self.fork('all', base=base), base=base,
                           target=target)
    files = self.files(plan)
    self.assertEqual(files[f'{ds}/minimal/a.yaml']['category'],
                     'upstream-added')
    self.assertFalse(files[f'{ds}/minimal/a.yaml'].get('sample_data'))
    # A fork that curates its datasets does not.
    repo = self.fork('curated', base=base, commit=False)
    shutil.rmtree(os.path.join(repo, *f'{ds}/hardened'.split('/')))
    _commit_all(repo)
    ctx, plan, results = self.plan(repo, base=base, target=target)
    files = self.files(plan)
    self.assertTrue(files[f'{ds}/hardened/a.yaml'].get('sample_data'))
    self.assertTrue(files[f'{ds}/minimal/a.yaml'].get('sample_data'))
    self.assertFalse(files[f'{ds}/classic/a.yaml'].get('sample_data'))
    self.assertNotIn(
        f'{ds}/minimal/a.yaml',
        {
            f['path'] for f in plan['files'] if report._needs_person(f)  # pylint: disable=protected-access
        })
    fu.run_apply(ctx, results, include_deletes=True)
    self.assertFalse(_exists(repo, f'{ds}/minimal'))
    self.assertFalse(_exists(repo, f'{ds}/hardened'))
    self.assertEqual(_read(repo, f'{ds}/classic/a.yaml'), 'name: a2\n')

  def test_nested_module_groups_are_cataloged(self):
    base = self.upstream_copy(V1, 'nested-base',
                              {'modules/group/sub/leaf/main.tf': COREDNS_MAIN})
    cat = fu.catalog(base)
    self.assertEqual(cat['modules']['group/sub/leaf'], 'modules/group/sub/leaf')

  def test_one_stage_repository_named_after_its_stage(self):
    repo = self.path('gcp-org-setup')
    shutil.copytree(os.path.join(UP[V1], 'fast/stages/0-org-setup'), repo)
    _commit_all(repo)
    _, plan, _ = self.plan(repo)
    mapping = self.mappings(plan)[('stage', '')]
    self.assertEqual(mapping['name'], '0-org-setup')
    self.assertEqual(mapping['match'], 'repository unnumbered name')

  def test_external_data_folder_is_masked_in_reports(self):
    repo = self.fork()
    config = self.path('fast-config')
    _write(config, 'data/projects/ext.yaml', TEAM_A)
    _, plan, _ = self.plan(repo, data_paths=[config])
    self.assertEqual(plan['repo']['data_paths'], [config])
    text = json.dumps(report.shareable(plan))
    self.assertNotIn(config, text)
    self.assertIn('<data>', text)

  def test_unpinned_fabric_sources_are_a_finding(self):
    repo = self.git_sourced(
        extra={
            '0-org-setup/unpinned.tf':
                f'module "loose" {{\n  source = "{FABRIC_GIT}//modules/'
                'project"\n  name   = "loose"\n}\n'
        })
    _, plan, _ = self.plan(repo)
    [finding
    ] = [f for f in plan['findings'] if 'have no ?ref= pin' in f['title']]
    self.assertEqual(finding['severity'], 'medium')
    self.assertNotIn('(none)', ' '.join(f['detail'] for f in plan['findings']))

  def test_checklist_follows_the_apply_order(self):
    _, plan, _ = self.plan(self.fork(extra=A_EXTRA))
    [init
    ] = [s['text'] for s in plan['checklist'] if 'init -upgrade' in s['text']]
    self.assertIn(
        'fast/stages/0-org-setup, fast/extras/0-cicd-github, '
        'fast/stages/2-project-factory.', init)

  def test_stage_view_counts_module_files_on_the_modules_row(self):
    repo = self.fork(edits=B_EDITS, extra=B_EXTRA, remove=B_REMOVE)
    _, plan, _ = self.plan(repo)
    data = report.shareable(plan)
    self.assertIn('modules', data['stage_files'])
    self.assertNotIn('modules/project', data['stage_files'])
    self.assertEqual(
        data['apply_counts']['merges'],
        sum(c.get('to merge', 0) for c in data['stage_files'].values()))
    self.assertEqual(
        data['apply_counts']['updated'],
        sum(c.get('updated', 0) for c in data['stage_files'].values()))


class TestReportHelpers(unittest.TestCase):
  # pylint: disable=protected-access

  def test_apply_order(self):

    def stage(customer, name, base=None):
      return {
          'kind': 'stage',
          'name': name,
          'customer': customer,
          'base': base or customer,
          'target': None
      }

    mappings = [
        stage('fast/addons/2-networking-test', '2-networking-test'),
        stage('fast/stages/2-networking', '2-networking'),
        stage('fast/extras/0-cicd-github', '0-cicd-github'),
        stage('fast/stages/1-vpcsc', '1-vpcsc'),
        # A renamed copy sorts by its upstream stage.
        stage('envs/org', '0-org-setup', 'fast/stages/0-org-setup'),
        stage('platform', 'custom', 'platform'),
    ]
    self.assertEqual(
        [m['customer'] for m in sorted(mappings, key=report._apply_order)], [
            'envs/org', 'fast/extras/0-cicd-github', 'fast/stages/1-vpcsc',
            'fast/stages/2-networking', 'fast/addons/2-networking-test',
            'platform'
        ])

  def test_counts_skip_sample_datasets_and_blocked_files(self):
    plan = {
        'files': [
            {
                'path': 'a',
                'category': 'upstream-changed'
            },
            {
                'path': 'b',
                'category': 'upstream-added',
                'sample_data': True
            },
            {
                'path': 'c',
                'category': 'upstream-changed',
                'blocked': 'link'
            },
            {
                'path': 'd',
                'category': 'conflict'
            },
            {
                'path': 'e',
                'category': 'conflict',
                'blocked': 'link'
            },
            {
                'path': 'f',
                'category': 'conflict-deleted'
            },
            {
                'path': 'g',
                'category': 'conflict-added',
                'sample_data': True
            },
            {
                'path': 'h',
                'category': 'customer-changed',
                'blocked': 'link'
            },
        ]
    }
    self.assertEqual(report._auto_count(plan), 1)
    self.assertEqual(report._merge_count(plan), 1)
    self.assertEqual(report._manual_count(plan), 3)

  def test_owner(self):
    stages, modules = ['fast/stages/0-org-setup'], ['modules/project']
    self.assertEqual(
        report._owner('fast/stages/0-org-setup/main.tf', stages, modules),
        'fast/stages/0-org-setup')
    self.assertEqual(report._owner('modules/project/main.tf', stages, modules),
                     'modules')
    self.assertEqual(report._owner('CHANGELOG.md', stages, modules),
                     'repository')
    # A stage at the repository root does not claim the vendored modules.
    self.assertEqual(report._owner('modules/project/main.tf', [''], modules),
                     'modules')
    self.assertEqual(report._owner('main.tf', [''], modules), '.')

  def test_home_folders_are_masked_but_not_repository_folders(self):
    self.assertEqual(
        report._scrub('/home/alice/x, data/home/x.yaml, /Users/bob/y', []),
        '<home>/x, data/home/x.yaml, <home>/y')

  def test_table_cells_escape_pipes_once(self):
    self.assertEqual(report._cell('a|b'), 'a\\|b')
    self.assertEqual(report._cell('a\\|b'), 'a\\|b')
    self.assertEqual(report._cell('a\\\\|b'), 'a\\\\\\|b')

  def test_fill_substitutes_once(self):
    out = report._fill('<t>__TITLE__</t>__DATA__', '__DATA__', {'k': 1})
    self.assertEqual(out, '<t>__DATA__</t>{"k": 1}')

  def test_csv_export_guards_formulas(self):
    self.assertIn(r'/^[=+\-@\t\r]/.test(v)', report._TEMPLATE)


@needs_git
class TestHtmlReport(_Case):

  def test_report_is_self_contained_and_shareable(self):
    repo = self.fork(extra=A_EXTRA)
    _, plan, _ = self.plan(repo)
    plan['findings'][0]['title'] = 'x </script><img src=y onerror=alert(1)>'
    html_text = report.render_html(plan, generated='2026-01-01 00:00 UTC')
    self.assertTrue(html_text.startswith('<!DOCTYPE html>'))
    self.assertNotIn(self.tmp, html_text)
    self.assertNotIn(UP[V1], html_text)
    self.assertNotIn('</script><img', html_text)
    self.assertNotRegex(html_text, r'(src|href)="(https?:)?//')
    m = re.search(r'<script type="application/json" id="data">(.*?)</script>',
                  html_text, re.S)
    data = json.loads(m.group(1))
    self.assertEqual(data['findings'][0]['title'], plan['findings'][0]['title'])
    self.assertEqual(data['readiness'], plan['readiness'])
    self.assertEqual(data['repo']['path'], '<repo>')
    self.assertEqual(data['repo']['name'], 'repo')
    self.assertEqual(data['base']['path'], '<base>')
    self.assertEqual(data['generated'], '2026-01-01 00:00 UTC')
    self.assertNotIn('unchanged', {f['category'] for f in data['files']})
    self.assertEqual(data['unchanged_files'], plan['summary']['unchanged'])

  def test_plan_html_flag(self):
    repo = self.fork(extra=A_EXTRA)
    path = self.path('report.html')
    code, out, err = _run(fu, [
        'plan', '--repo', repo, '--base', UP[V1], '--target', UP[V2], '--html',
        path
    ] + ([] if factory_data.available() else ['--skip-data-checks']))
    self.assertEqual(code, 0)
    self.assertIn('READINESS', out)
    self.assertIn('wrote HTML report to', err)
    with open(path, encoding='utf-8') as f:
      self.assertIn('FAST upgrade assessment', f.read())

  def test_plan_requires_data_checks_unless_skipped(self):
    repo = self.fork(extra=A_EXTRA)
    args = ['plan', '--repo', repo, '--base', UP[V1], '--target', UP[V2]]
    with mock.patch.object(factory_data, 'available', return_value=False), \
        mock.patch.object(factory_data, 'missing_dependencies',
                          return_value=['jsonschema']):
      code, _, err = _run(fu, args)
      self.assertEqual(code, 1)
      self.assertIn('factory data checks need jsonschema', err)
      self.assertIn('--skip-data-checks', err)
      code, out, _ = _run(fu, args + ['--skip-data-checks', '--json'])
      self.assertEqual(code, 0)
      plan = json.loads(out)
    self.assertIn('skipped', plan['data_impact'])
    coverage = {c['area']: c['status'] for c in plan['coverage']}
    self.assertEqual(coverage['Factory YAML data'], 'not checked')
    self.assertNotIn('setup', {f['category'] for f in plan['findings']})


@needs_git
class TestMarkdownReport(_Case):

  def test_report_sections_tracker_and_scrubbing(self):
    repo = self.fork(extra=A_EXTRA)
    _, plan, _ = self.plan(repo)
    first = plan['findings'][0]
    first['title'] = 'pipe | <b>tag</b> *star* run `terraform init`'
    first['detail'] = ('link from /home/someone/work/x.tf\n'
                       'second line with ``` fence')
    text = report.render_markdown(plan, generated='2026-01-01 00:00 UTC')
    self.assertTrue(text.startswith('# FAST upgrade assessment: repo\n'))
    for heading in ('## 1. Summary', '## 2. Findings tracker',
                    '## 3. Findings in detail', '## 4. By stage',
                    '## 5. Upgrade plan', '## 6. Breaking changes',
                    '## 7. File actions', '## 8. Coverage',
                    '## Appendix A. Technical details',
                    '## Appendix B. All changed files'):
      self.assertIn('\n' + heading + '\n', text)
    self.assertIn(f'**{plan["readiness"]["status"]}**:', text)
    self.assertRegex(text, r'\n> \[!(CAUTION|WARNING|TIP)\]\n')
    self.assertIn('[2. Findings tracker](#2-findings-tracker)', text)
    self.assertNotIn(self.tmp, text)
    self.assertNotIn(UP[V1], text)
    self.assertNotIn('/home/someone', text)
    # Every finding is in the tracker, with columns for the customer.
    self.assertIn('| ID | Severity | Stage | Finding | Owner | Status | Due |',
                  text)
    rows = [l for l in text.splitlines() if re.match(r'\| F\d{3} \|', l)]
    self.assertEqual(len(rows), len(plan['findings']))
    # Only what GFM would format is escaped; existing code spans are kept.
    row = rows[0]
    self.assertIn('pipe \\| \\<b>tag\\</b> \\*star\\* run `terraform init`',
                  row)
    self.assertEqual(len(re.findall(r'(?<!\\)\|', row)), 8)
    self.assertIn(report.SEV_ICON[first['severity']], row)
    self.assertNotIn('custom\\_roles', report._md('custom_roles'))  # pylint: disable=protected-access
    # Line lists become bullets; the home folder is masked.
    self.assertIn('- link from \\<home>/work/x.tf', text)
    self.assertIn('- second line with \\`\\`\\` fence', text)
    # The plan is a task list with one item per checklist step.
    self.assertEqual(text.count('\n- [ ] **S'), len(plan['checklist']))
    self.assertIn('2026-01-01 00:00 UTC', text)
    if any(m['kind'] == 'stage' for m in plan['mappings']):
      self.assertIn('```mermaid\nflowchart LR\n', text)

  def test_plan_markdown_flag(self):
    repo = self.fork(extra=A_EXTRA)
    path = self.path('report.md')
    code, out, err = _run(fu, [
        'plan', '--repo', repo, '--base', UP[V1], '--target', UP[V2],
        '--markdown', path
    ] + ([] if factory_data.available() else ['--skip-data-checks']))
    self.assertEqual(code, 0)
    self.assertIn('READINESS', out)
    self.assertIn('wrote Markdown report to', err)
    with open(path, encoding='utf-8') as f:
      self.assertIn('## 2. Findings tracker', f.read())

  def test_brief_is_chat_sized_and_complete(self):
    repo = self.fork(extra=A_EXTRA)
    _, plan, _ = self.plan(repo)
    text = report.render_brief(plan, 'report.md')
    status = plan['readiness']['status']
    self.assertTrue(text.startswith('## FAST upgrade assessment: repo ('))
    self.assertIn(f'**{status}**', text)
    for f in plan['findings']:
      self.assertIn(
          f'**{f["id"]}**' if f['severity'] in ('blocker',
                                                'high') else f'| {f["id"]} |',
          text)
    self.assertIn('### Upgrade plan', text)
    self.assertIn('`report.md`', text)
    # Nothing chat views may not render, and none of the long sections.
    for absent in ('[!', '```mermaid', '](#', 'Appendix', self.tmp):
      self.assertNotIn(absent, text)
    self.assertLess(len(text.splitlines()), 200)

  def test_clip_md_closes_code_spans(self):
    clipped = report._clip_md('see `a very long code span here` ok', 20)  # pylint: disable=protected-access
    self.assertEqual(clipped.count('`') % 2, 0)
    self.assertTrue(clipped.endswith('`...'))

  def test_plan_brief_flag(self):
    repo = self.fork(extra=A_EXTRA)
    brief, full = self.path('brief.md'), self.path('full.md')
    code, _, err = _run(fu, [
        'plan', '--repo', repo, '--base', UP[V1], '--target', UP[V2],
        '--markdown', full, '--brief', brief
    ] + ([] if factory_data.available() else ['--skip-data-checks']))
    self.assertEqual(code, 0)
    self.assertIn('wrote brief report to', err)
    with open(brief, encoding='utf-8') as f:
      self.assertIn('`full.md`', f.read())


@needs_git
class TestInlineWidget(_Case):

  def test_widget_is_self_contained_complete_and_shareable(self):
    repo = self.fork(extra=A_EXTRA)
    _, plan, _ = self.plan(repo)
    plan['findings'][0]['title'] = 'x </script><img src=y onerror=alert(1)>'
    text = report.render_widget(plan, 'report.md', generated='2026-01-01')
    self.assertTrue(text.startswith('<!DOCTYPE html>'))
    self.assertNotIn(self.tmp, text)
    self.assertNotIn(UP[V1], text)
    self.assertNotIn('</script><img', text)
    self.assertNotRegex(text, r'(src|href)="(https?:)?//')
    # Chat embeds have a fixed height budget: no viewport-sized layouts.
    for absent in ('100vh', 'h-screen', 'min-h-screen'):
      self.assertNotIn(absent, text)
    # Host theme tokens with fallbacks, never pinned on :root.
    self.assertIn('var(--card,#fff)', text)
    self.assertNotIn(':root', text)
    m = re.search(r'<script type="application/json" id="data">(.*?)</script>',
                  text, re.S)
    data = json.loads(m.group(1))
    self.assertEqual(data['status'], plan['readiness']['status'])
    self.assertEqual([f['id'] for f in data['findings']],
                     [f['id'] for f in plan['findings']])
    self.assertEqual(len(data['plan']), len(plan['checklist']))
    self.assertEqual(data['full_report'], 'report.md')
    for f in data['findings']:
      self.assertLessEqual(len(f['detail']), report.WIDGET_DETAIL)
      self.assertLessEqual(len(f['files']), report.WIDGET_FILES)

  def test_full_html_follows_the_host_theme(self):
    repo = self.fork(extra=A_EXTRA)
    _, plan, _ = self.plan(repo)
    text = report.render_html(plan)
    self.assertIn('var(--card,#fff)', text)
    for pinned in ('#e8f0fe', '#f1f3f4'):
      self.assertNotIn(pinned, text)

  def test_plan_widget_flag(self):
    repo = self.fork(extra=A_EXTRA)
    path, full = self.path('card.html'), self.path('full.md')
    code, _, err = _run(fu, [
        'plan', '--repo', repo, '--base', UP[V1], '--target', UP[V2],
        '--markdown', full, '--widget', path
    ] + ([] if factory_data.available() else ['--skip-data-checks']))
    self.assertEqual(code, 0)
    self.assertIn('wrote inline HTML report to', err)
    with open(path, encoding='utf-8') as f:
      self.assertIn('"full_report": "full.md"', f.read())


# --------------------------------------------------------------------------
# Skill documents
# --------------------------------------------------------------------------

_DOCS = ['SKILL.md', 'README.md', 'TESTING.md'] + [
    posixpath.join('references', n)
    for n in sorted(os.listdir(os.path.join(_BASE, 'references')))
] if os.path.isdir(os.path.join(_BASE, 'references')) else ['SKILL.md']
_LINK_RE = re.compile(r'\[[^\]]*\]\(([^)\s]+)\)')


def _doc(name):
  with open(os.path.join(_BASE, name), encoding='utf-8') as f:
    return f.read()


def _option_strings(parser):
  options = set()
  for action in parser._actions:  # pylint: disable=protected-access
    options.update(o for o in action.option_strings if o.startswith('--'))
    for sub in getattr(action, 'choices', None) or {}:
      if hasattr(action.choices[sub], '_actions'):
        options |= _option_strings(action.choices[sub])
  return options


def _subcommands():
  parser = fu.build_parser()
  for action in parser._actions:  # pylint: disable=protected-access
    if isinstance(getattr(action, 'choices', None), dict):
      return set(action.choices)
  return set()


class TestSkillDocuments(unittest.TestCase):

  def test_frontmatter(self):
    text = _doc('SKILL.md')
    m = re.match(r'^---\nname: (.+)\ndescription: (.+)\n---\n', text)
    self.assertIsNotNone(m, 'SKILL.md must start with name/description')
    name, description = m.group(1).strip(), m.group(2).strip()
    self.assertEqual(name, os.path.basename(os.path.abspath(_BASE)))
    self.assertRegex(name, r'^[a-z0-9]+(-[a-z0-9]+)*$')
    self.assertLessEqual(len(name), 64)
    self.assertLessEqual(len(description), 1024)
    self.assertIn('Use when', description)

  def test_relative_links_resolve(self):
    for name in _DOCS:
      base = os.path.dirname(os.path.join(_BASE, name))
      for target in _LINK_RE.findall(_doc(name)):
        if target.startswith(('http://', 'https://', 'mailto:', '#')):
          continue
        with self.subTest(doc=name, link=target):
          path = os.path.normpath(os.path.join(base, target.split('#')[0]))
          self.assertTrue(os.path.exists(path), path)

  def test_documented_commands_and_flags_exist(self):
    subcommands = _subcommands()
    flags = {
        'fast_upgrade.py': _option_strings(fu.build_parser()),
        'plan_review.py': {'--json'},
        'provenance.py': {'--verbose'},
    }
    skill = _doc('SKILL.md')
    for sub in subcommands:
      with self.subTest(documented=sub):
        self.assertIn(f'fast_upgrade.py {sub}', skill.replace('`', ''))
    for name in _DOCS:
      text = _doc(name).replace('\\\n', ' ')
      for line in text.splitlines():
        for m in re.finditer(r'fast_upgrade\.py\s+([a-z-]+)', line):
          with self.subTest(doc=name, subcommand=m.group(1)):
            self.assertIn(m.group(1), subcommands)
        for script, known in flags.items():
          if script not in line or sum(s in line for s in flags) > 1:
            continue
          for flag in re.findall(r'(?<![\w-])--[a-z][a-z-]*', line):
            with self.subTest(doc=name, script=script, flag=flag):
              self.assertIn(flag, known)

  def test_no_local_paths(self):
    for name in _DOCS:
      text = _doc(name)
      with self.subTest(doc=name):
        self.assertNotRegex(text, r'/(Users|home)/[a-z]')

  def test_testing_md_cites_existing_tests_and_playbooks(self):
    text = _doc('TESTING.md')
    classes = {
        name: value
        for name, value in globals().items()
        if isinstance(value, type) and issubclass(value, unittest.TestCase)
    }
    methods = {
        m for c in classes.values() for m in dir(c) if m.startswith('test_')
    }
    for name in sorted(set(re.findall(r'`(Test\w+)`', text))):
      with self.subTest(test_class=name):
        self.assertIn(name, classes)
    for name in sorted(set(re.findall(r'`(test_\w+)`', text))):
      with self.subTest(test=name):
        self.assertIn(name, methods)
    playbooks = os.path.join(_BASE, '..', '..', '..', 'tools',
                             'skill-turn-harness', 'playbooks', 'fast',
                             'fast-upgrade')
    for name in sorted(set(re.findall(r'`([\w-]+\.yaml)`', text))):
      with self.subTest(playbook=name):
        self.assertTrue(os.path.isfile(os.path.join(playbooks, name)), name)

  def test_testing_md_harness_command_works_from_the_repository_root(self):
    # The harness copies a playbook's link_paths from the folder it is started
    # in to a temporary workspace, and resolves --skill-src in that workspace.
    root = os.path.join(_BASE, '..', '..', '..')
    text = _doc('TESTING.md').replace('\\\n', ' ')
    commands = re.findall(r'harness\.py\s+(\S+\.yaml)\s+--skill-src\s+(\S+)',
                          text)
    self.assertTrue(commands, 'TESTING.md must show how to run a playbook')
    for playbook, skill_src in commands:
      with self.subTest(playbook=playbook, skill_src=skill_src):
        self.assertTrue(os.path.isfile(os.path.join(root, playbook)))
        self.assertEqual(os.path.normpath(os.path.join(root, skill_src)),
                         os.path.normpath(_BASE))
    playbooks = os.path.join(root, 'tools', 'skill-turn-harness', 'playbooks',
                             'fast', 'fast-upgrade')
    for name in sorted(os.listdir(playbooks)):
      with open(os.path.join(playbooks, name), encoding='utf-8') as f:
        block = re.search(r'^\s*link_paths:\n((?:[ \t]+- .+\n)+)', f.read(),
                          re.M)
      if block is None:
        continue
      paths = re.findall(r'- (\S+)', block.group(1))
      for path in paths:
        with self.subTest(playbook=name, link_path=path):
          self.assertTrue(os.path.exists(os.path.join(root, path)), path)
      for _, skill_src in commands:
        with self.subTest(playbook=name, skill_src=skill_src):
          self.assertTrue(
              any(skill_src == p or skill_src.startswith(p.rstrip('/') + '/')
                  for p in paths), f'{skill_src} is not copied by {name}')


# --------------------------------------------------------------------------
# Integration: real Fabric releases (opt-in)
# --------------------------------------------------------------------------

REAL_REPO = os.environ.get('FAST_UPGRADE_FABRIC_REPO')
REAL_BASE = os.environ.get('FAST_UPGRADE_BASE', 'v57.0.0')
REAL_TARGET = os.environ.get('FAST_UPGRADE_TARGET', 'v59.0.0')


def _tree_entries(root):
  """{path: bytes, or ('link', target)} below root, without .git and
  .fast-upgrade. Links are recorded, not followed: releases have loops."""
  entries = {}
  for dirpath, dirnames, filenames in os.walk(root):
    keep = []
    for name in dirnames:
      path = os.path.join(dirpath, name)
      if dirpath == root and name in ('.git', '.fast-upgrade'):
        continue
      if os.path.islink(path):
        filenames.append(name)
      else:
        keep.append(name)
    dirnames[:] = keep
    for name in filenames:
      path = os.path.join(dirpath, name)
      rel = os.path.relpath(path, root).replace(os.sep, '/')
      if os.path.islink(path):
        entries[rel] = ('link', os.readlink(path))
      else:
        with open(path, 'rb') as f:
          entries[rel] = f.read()
  return entries


def _minimal_rewrite(text, upstream_rel, customer_rel, new_target):
  """Rewrites local module sources like a customer would, only if broken."""
  up_dir = posixpath.dirname(upstream_rel)
  cu_dir = posixpath.dirname(customer_rel)
  spans = []
  for call in hcl_lite.module_calls(text):
    if hcl_lite.classify_source(call.source) != 'local':
      continue
    target = posixpath.normpath(posixpath.join(up_dir, call.source))
    if not target.startswith('modules/'):
      continue
    wanted = new_target(target)
    if wanted.startswith('git::'):
      spans.append((call.source_start, call.source_end, wanted))
    elif posixpath.normpath(posixpath.join(cu_dir, call.source)) != wanted:
      spans.append((call.source_start, call.source_end,
                    posixpath.relpath(wanted, cu_dir or '.')))
  return hcl_lite.replace_spans(text, spans)


@unittest.skipUnless(
    REAL_REPO, 'set FAST_UPGRADE_FABRIC_REPO to a Fabric '
    'clone with release tags to run the integration tests')
class TestIntegration(unittest.TestCase):
  """End-to-end runs on real releases: slow, and opt-in."""

  @classmethod
  def setUpClass(cls):
    cls.tmp = tempfile.mkdtemp(prefix='fast-upgrade-int-')
    cache = os.path.join(cls.tmp, 'cache')
    cls.base = fu.fetch_release(REAL_BASE, from_repo=REAL_REPO,
                                cache_dir=cache)[0]
    cls.target = fu.fetch_release(REAL_TARGET, from_repo=REAL_REPO,
                                  cache_dir=cache)[0]

  @classmethod
  def tearDownClass(cls):
    shutil.rmtree(cls.tmp, ignore_errors=True)

  def copy_tree(self, rel_src, repo, rel_dest, rewrite=None):
    src = os.path.join(self.base, rel_src)
    dest = os.path.join(repo, rel_dest)
    shutil.copytree(src, dest, symlinks=True)
    if not rewrite:
      return
    for dirpath, _, filenames in os.walk(dest):
      for name in filenames:
        path = os.path.join(dirpath, name)
        if os.path.islink(path) or not name.endswith(('.tf', '.tofu')):
          continue
        rel = os.path.relpath(path, dest).replace(os.sep, '/')
        with open(path, encoding='utf-8') as f:
          text = f.read()
        new = _minimal_rewrite(text, posixpath.join(rel_src, rel),
                               posixpath.join(rel_dest, rel), rewrite)
        if new != text:
          with open(path, 'w', encoding='utf-8') as f:
            f.write(new)

  def plan(self, repo, base=None, target=None):
    ctx = fu.Context(repo, base or self.base, target or self.target)
    plan, results = fu.build_plan(ctx)
    return ctx, plan, results

  def test_fork_round_trip(self):
    repo = os.path.join(self.tmp, 'fork')
    for top in ('fast', 'modules'):
      self.copy_tree(top, repo, top)
    project = os.path.join(repo, 'modules/project/main.tf')
    with open(project, 'a', encoding='utf-8') as f:
      f.write('\n# customer tweak\n')
    _write(repo, 'fast/stages/2-project-factory/data/projects/team-x.yaml',
           TEAM_A.replace('team-a', 'team-x'))
    _commit_all(repo)
    ctx, plan, results = self.plan(repo)
    self.assertEqual(plan['repo']['detected_version'], REAL_BASE)
    manual = [
        f['path']
        for f in plan['files']
        if f['category'] in fu.MANUAL_CATEGORIES
    ]
    self.assertEqual(manual, [])
    conflicts = [
        f['path'] for f in plan['files'] if f['category'] == 'conflict'
    ]
    self.assertTrue(set(conflicts) <= {'modules/project/main.tf'}, conflicts)
    result = fu.run_apply(ctx, results, include_deletes=True, copy_moved=True,
                          moved=plan['moved_files'])
    marked = _git(repo, 'diff', '--check', check=False).stdout
    self.assertEqual('leftover conflict marker' in marked,
                     bool(result['counts'].get('conflict')), marked)
    _, replan, _ = self.plan(repo)
    for category in ('upstream-changed', 'upstream-added', 'upstream-deleted'):
      self.assertNotIn(category, replan['summary'])
    _, delta, _ = self.plan(repo, base=self.target)
    self.assertTrue(set(delta['summary']) <= set(DELTA), delta['summary'])
    changed = {
        f['path'] for f in delta['files'] if f['category'] == 'customer-changed'
    }
    self.assertTrue(changed <= {'modules/project/main.tf'}, changed)

  def test_reorganized_layout(self):
    repo = os.path.join(self.tmp, 'reorg')
    moved = lambda target: 'tf/' + target
    self.copy_tree('fast/stages/0-org-setup', repo, 'stages/org-bootstrap',
                   moved)
    self.copy_tree('fast/stages/2-project-factory', repo,
                   'stages/2-project-factory-acme', moved)
    self.copy_tree('modules', repo, 'tf/modules', moved)
    _commit_all(repo)
    _, plan, _ = self.plan(repo)
    mappings = {m['customer']: m for m in plan['mappings']}
    self.assertEqual(mappings['stages/org-bootstrap']['name'], '0-org-setup')
    self.assertTrue(
        mappings['stages/org-bootstrap']['match'].startswith('content'))
    self.assertEqual(mappings['stages/2-project-factory-acme']['match'],
                     'prefix')
    self.assertTrue(set(plan['summary']) <= set(SAFE), plan['summary'])
    self.assertNotIn('customer-changed', plan['summary'])
    self.assertTrue(any(f['layout_adjusted'] for f in plan['files']))
    self.assertEqual(plan['unresolved_sources'], [])

  def test_git_sourced_stage(self):
    repo = os.path.join(self.tmp, 'gitsrc')
    git = lambda target: f'{FABRIC_GIT}//{target}?ref={REAL_BASE}'
    self.copy_tree('fast/stages/2-project-factory', repo, '2-project-factory',
                   git)
    _commit_all(repo)
    ctx, plan, results = self.plan(repo)
    self.assertGreater(plan['git_refs']['bumpable'], 0)
    self.assertTrue(set(plan['summary']) <= set(SAFE), plan['summary'])
    self.assertNotIn('customer-changed', plan['summary'])
    self.assertEqual(plan['unresolved_sources'], [])
    fu.run_apply(ctx, results, bump=True, include_deletes=True,
                 moved=plan['moved_files'])
    _, replan, _ = self.plan(repo)
    self.assertNotIn('upstream-changed', replan['summary'])
    self.assertNotIn('upstream-added', replan['summary'])
    self.assertEqual(replan['git_refs']['bumpable'], 0)

  def test_checkout_of_base_is_vanilla(self):
    repo = os.path.join(self.tmp, 'checkout')
    os.makedirs(repo)
    archive = subprocess.run(
        ['git', '-C', REAL_REPO, 'archive', REAL_BASE, 'fast', 'modules'],
        check=True, capture_output=True).stdout
    with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
      # Verbatim like a checkout: link targets keep git's spelling.
      tar.extractall(repo,
                     **({
                         'filter': 'fully_trusted'
                     } if fu.TAR_FILTERS else {}))
    _, plan, _ = self.plan(repo)
    vanilla = {
        'upstream-changed', 'upstream-added', 'upstream-deleted', 'unchanged'
    }
    self.assertTrue(set(plan['summary']) <= vanilla, plan['summary'])

  def test_full_release_copy_upgrades_to_the_target(self):
    # Everything a release ships, including CHANGELOG.md, default-versions.tf
    # and modules/README.md, plus one file of the customer's.
    repo = os.path.join(self.tmp, 'full')
    shutil.copytree(self.base, repo, symlinks=True)
    mine = 'fast/stages/2-project-factory/data/projects/team-x.yaml'
    _write(repo, mine, TEAM_A.replace('team-a', 'team-x'))
    _commit_all(repo)
    ctx, plan, results = self.plan(repo)
    self.assertEqual(plan['readiness']['counts']['blocker'], 0)
    self.assertEqual(plan['version_pins'], [])
    self.assertEqual(plan['hygiene']['generated_tracked'], [])
    fu.run_apply(ctx, results, include_deletes=True)
    got, want = _tree_entries(repo), _tree_entries(self.target)
    self.assertIsNotNone(got.pop(mine, None))
    self.assertEqual(sorted(set(got) ^ set(want)), [])
    self.assertEqual([p for p in want if got[p] != want[p]], [])
    result = fu.detect(repo)
    self.assertEqual(result['version']['detected'], REAL_TARGET)
    self.assertEqual(result['version']['confidence'], 'high')

  def test_release_archive_without_tar_filters(self):
    with _without_tar_filters():
      path, _ = fu.fetch_release(REAL_TARGET, from_repo=REAL_REPO,
                                 cache_dir=os.path.join(self.tmp, 'nofilter'))
    self.assertEqual(provenance.tree_digest(path),
                     provenance.tree_digest(self.target))


if __name__ == '__main__':
  unittest.main()
