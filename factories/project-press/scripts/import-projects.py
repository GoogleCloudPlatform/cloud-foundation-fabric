#!/usr/bin/env python3
# Copyright 2021 Google LLC
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
#
## Instructions:
# - IMPORTANT NOTE: As Terraform plan requires the resources to be imported before the plan execution and that
#   changes state file, if you want to run the imports via CI/CD pipeline, you should modify the
#   pipeline to operate on a COPY of the state file (eg. gsutil cp + terraform init -backend-config=bucket=)
# - You can mark a project to be imported by adding "import: true" into the project request file.
# - The project ID *has* to match the project ID format, otherwise you risk your old project being deleted.
# - Do not apply until you happy with Terraform plan output.
#
import argparse
import glob
from types import prepare_class
import yaml
import sys
import subprocess
from googleapiclient import discovery

parser = argparse.ArgumentParser(description='Import existing GCP projects')
parser.add_argument('dir', type=str, help='Directory with project files')
parser.add_argument('--config',
                    type=str,
                    default='config.yaml',
                    help='Location of Project Factory config.yaml')
parser.add_argument('--terraform-dir',
                    type=str,
                    default='terraform/',
                    help='Location of Terraform directory containing main.tf')
parser.add_argument('--dry-run',
                    action='store_true',
                    default=False,
                    help='Just show commands to be run')
args = parser.parse_args()

APIS = [
    'cloudbilling.googleapis.com',
    'cloudresourcemanager.googleapis.com',
    'compute.googleapis.com',
    'iam.googleapis.com',
    'iap.googleapis.com',
    'servicenetworking.googleapis.com',
]

if args.dry_run:
    print('DRY RUN MODE ENABLED!', file=sys.stderr)

config = {}
with open(args.config, 'r') as cfg:
    config = yaml.load(cfg, Loader=yaml.SafeLoader)


def execute_terraform(tf_args, dry_run_enabled=True):
    if dry_run_enabled and args.dry_run:
        print('terraform %s' % (' '.join(tf_args)), file=sys.stderr)
        return
    result = subprocess.run(["terraform"] + tf_args,
                            capture_output=True,
                            text=True,
                            cwd=args.terraform_dir)
    if result.returncode != 0:
        print('Error when executing `terraform %s` in %s, return code %d' %
              (' '.join(tf_args), args.terraform_dir, result.returncode),
              file=sys.stderr)
        print('Standard output: %s' % (result.stdout), file=sys.stderr)
        print('Standard error: %s' % (result.stderr), file=sys.stderr)
        sys.exit(result.returncode)
    return result.stdout


tf_state = execute_terraform(['state', 'list'], False).split("\n")

service_usage = discovery.build('serviceusage', 'v1')
service = discovery.build('cloudresourcemanager', 'v1')
compute_service = discovery.build('compute', 'v1')
iam = discovery.build('iam', 'v1')
for project_file in glob.glob('%s/*.yaml' % args.dir):
    with open(project_file, 'r') as project_cfg:
        _project = yaml.load(project_cfg, Loader=yaml.SafeLoader)
        project = _project['project']
        if not 'import' in project or not project['import']:
            continue

        pcfg = {'id': '', 'project_ids': {}, 'project_nums': {}}
        for project_env_index, env in enumerate(project['environments']):
            env_index = config['environments'].index(env)

            pcfg['id'] = project['projectId']
            project_state = 'module.project["%s"].module.project-factory[%d].module.project-factory.google_project.main' % (
                pcfg['id'], project_env_index)
            if project_state in tf_state:
                print('Project %s (%s) already imported, skipping...' %
                      (pcfg['id'], env),
                      file=sys.stderr)
                continue
            print('Starting to import project %s (%s)...' % (pcfg['id'], env),
                  file=sys.stderr)

            if 'customProjectId' in project:
                if len(project['environments']) > 1:
                    print(
                        'Importing projects with custom project IDs with more than one environment is not supported: %s (%s)...'
                        % (pcfg['id'], env),
                        file=sys.stderr)
                    sys.exit(1)
                pcfg['project_ids'][env] = project['customProjectId']
            else:
                pcfg['project_ids'][env] = config['projectIdFormat'].replace(
                    '%id%', project['projectId']).replace('%env%', env).replace(
                        '%folder%', project['folder'])

            request = service.projects().get(projectId=pcfg['project_ids'][env])
            response = request.execute()
            pcfg['project_nums'][env] = response['projectNumber']

            for api in APIS:
                api_request = service_usage.services().get(
                    name="projects/%s/services/%s" %
                    (pcfg['project_nums'][env], api))
                response = api_request.execute()
                api_state = 'module.project["%s"].module.project-factory[%d].module.project-factory.module.project_services.google_project_service.project_services["%s"]' % (
                    pcfg['id'], project_env_index, api)
                if response['state'] != 'DISABLED' and api_state not in tf_state:
                    execute_terraform([
                        'import', api_state,
                        '%s/%s' % (pcfg['project_ids'][env], api)
                    ])
            execute_terraform([
                'import',
                'module.project["%s"].module.project-factory[%d].module.project-factory.google_project.main'
                % (pcfg['id'], project_env_index),
                'projects/%s' % (pcfg['project_ids'][env])
            ])

            sa_name = 'projects/%s/serviceAccounts/project-service-account@%s.iam.gserviceaccount.com' % (
                pcfg['project_ids'][env], pcfg['project_ids'][env])
            request = iam.projects().serviceAccounts().get(name=sa_name)
            try:
                response = request.execute()
                if 'name' in response:
                    execute_terraform([
                        'import',
                        'module.project["%s"].module.project-factory[%d].module.project-factory.google_service_account.default_service_account'
                        % (pcfg['id'], project_env_index), sa_name
                    ])
            except Exception:
                pass

            shared_vpc = config['sharedVpcProjects'][project['folder']][env]
            if shared_vpc != '':
                execute_terraform([
                    'import',
                    'module.shared-vpc["%s"].google_compute_shared_vpc_service_project.service_project[%d]'
                    % (pcfg['id'], project_env_index),
                    '%s/%s' % (shared_vpc, pcfg['project_ids'][env])
                ])

            request = compute_service.projects().get(
                project=pcfg['project_ids'][env])
            response = request.execute()

            metadatas = []
            if 'commonInstanceMetadata' in response:
                for item in response['commonInstanceMetadata']['items']:
                    metadatas.append(item['key'])
            for key, value in config['defaultProjectMetadata'].items():
                if key in metadatas:
                    print(
                        'Existing project common metadata key in project %s (%s): %s (you need to remove this key before the Terraform applies cleanly)'
                        % (pcfg['id'], env, key),
                        file=sys.stderr)

                    #execute_terraform([
                    #    'import',
                    #    'module.project["%s"].google_compute_project_metadata_item.project_metadata["%s-%s"]'
                    #    % (pcfg['id'], env, key),
                    #    '%s' % (key)
                    #])

            print('Finished importing project %s (%s).' % (pcfg['id'], env),
                  file=sys.stderr)
