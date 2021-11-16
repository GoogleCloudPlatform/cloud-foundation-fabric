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

from yamale.validators import DefaultValidators, Validator
import yamale
import datetime
import sys
import os
import yaml
import re
import email.utils
from googleapiclient.discovery import build
import googleapiclient.errors
from google.cloud.iam_credentials_v1 import IAMCredentialsClient
from google.oauth2.credentials import Credentials

validate_users = True
allow_groups = True

_user_validation_cache = {}
_user_service = None
_group_service = None


def _validate_user(service_account, customer_id, user_id):
    global _user_service
    global _group_service
    global _user_validation_cache
    global allow_groups
    if not _user_service:
        client = IAMCredentialsClient()
        name = 'projects/-/serviceAccounts/%s' % service_account
        response = client.generate_access_token(
            name=name,
            scope=[
                'https://www.googleapis.com/auth/admin.directory.user.readonly'
            ])
        credentials = Credentials(response.access_token)
        _user_service = build('admin', 'directory_v1', credentials=credentials)

    if not _group_service and allow_groups:
        client = IAMCredentialsClient()
        name = 'projects/-/serviceAccounts/%s' % service_account
        response = client.generate_access_token(
            name=name,
            scope=[
                'https://www.googleapis.com/auth/admin.directory.group.readonly'
            ])
        credentials = Credentials(response.access_token)
        _group_service = build('admin', 'directory_v1', credentials=credentials)

    _user_validation_cache[user_id] = False
    try:
        results = _user_service.users().get(userKey=user_id).execute()
        if isinstance(results, dict):
            _user_validation_cache[user_id] = True
    except googleapiclient.errors.Error as e:
        try:
            results = _user_service.users().list(customer=customer_id,
                                                 query='email=%s' %
                                                 user_id).execute()
            if 'users' in results:
                _user_validation_cache[user_id] = True
            else:
                raise googleapiclient.errors.Error('Pass to group handler')
        except googleapiclient.errors.Error as e:
            if allow_groups:
                try:
                    group = _group_service.groups().get(
                        groupKey=user_id).execute()
                    if 'id' in group:
                        _user_validation_cache[user_id] = True
                except googleapiclient.errors.Error as e:
                    pass
            else:
                pass
    return _user_validation_cache[user_id]


class Apis(Validator):
    """ Custom apis validator """
    tag = 'apis'
    config = {}
    approval_type = 'all'

    def __init__(self, *args, **kwargs):
        self.approval_type = kwargs.pop('type', 'all')
        super().__init__(*args, **kwargs)

    def _is_valid(self, value):
        if not isinstance(value, list):
            return False

        for api in value:
            if self.approval_type == 'all':
                if api not in Apis.config['approved'] and api not in Apis.config[
                        'holdForApproval']:
                    return False
            if self.approval_type == 'approved':
                if api not in Apis.config['approved']:
                    return False

        return True


class Environments(Validator):
    """ Custom environment validator """
    tag = 'environments'
    config = {}

    def _is_valid(self, value):
        if not isinstance(value, list):
            return False

        if self.is_required and len(value) == 0:
            return False

        for env in value:
            if env not in Environments.config['environments']:
                return False

        return True


class Environment(Validator):
    """ Custom environment validator """
    tag = 'environment'
    config = {}

    def _is_valid(self, value):
        if not isinstance(value, str):
            return False

        if value not in Environment.config['environments']:
            return False

        return True


class Folder(Validator):
    """ Custom folder validator """
    tag = 'folder'
    config = {}

    def _is_valid(self, value):
        return value in Folder.config['folders']


class Email(Validator):
    """ Custom email validator """
    tag = 'email'
    config = {}

    def _is_valid(self, value):
        if '@' in email.utils.parseaddr(value)[1]:
            return True
        return False


class _False(Validator):
    """ Custom false validator """
    tag = 'false'
    config = {}

    def _is_valid(self, value):
        if not isinstance(value, bool):
            return False
        if value is not False:
            return False
        return True


class _True(Validator):
    """ Custom true validator """
    tag = 'true'
    config = {}

    def _is_valid(self, value):
        if not isinstance(value, bool):
            return False
        if value is not True:
            return False
        return True


class User(Validator):
    """ Custom user validator """
    tag = 'user'
    config = {}

    def _is_valid(self, value):
        if not isinstance(value, str):
            return False

        if value.find('@') != -1:
            domain = value.split("@")[1]
            if domain not in User.config['secondaryDomains']:
                return False
        elif User.config['domain'] == '':
            return False
        if validate_users:
            user_name = value
            if User.config['domain'] != '':
                user_name = '%s@%s' % (user_name, User.config['domain'])
            if not _validate_user(User.config['terraformServiceAccount'],
                                  User.config['cloudIdentityCustomerId'],
                                  user_name):
                return False
        return True


class Teams(Validator):
    """ Custom teams validator """
    tag = 'teams'
    config = {}

    def _is_valid(self, value):
        if not isinstance(value, dict):
            return False

        for k, v in value.items():
            if k not in Teams.config['projectGroups']:
                return False
            if not isinstance(v, list):
                return False
            for user in v:
                if user.find('@') != -1:
                    domain = user.split("@")[1]
                    if domain not in Teams.config['secondaryDomains']:
                        return False
                elif Teams.config['domain'] == '':
                    return False
                if validate_users:
                    user_name = user
                    if Teams.config['domain'] != '':
                        user_name = '%s@%s' % (user_name,
                                               Teams.config['domain'])
                    if not _validate_user(
                            Teams.config['terraformServiceAccount'],
                            Teams.config['cloudIdentityCustomerId'], user_name):
                        return False

        return True


class TeamName(Validator):
    """ Custom team name validator """
    tag = 'teamname'
    config = {}

    def _is_valid(self, value):
        if not isinstance(value, str):
            return False
        if value in Teams.config['projectGroups']:
            _last_team_name = value
            return True
        return False


class Labels(Validator):
    """ Custom labels validator """
    tag = 'labels'
    config = {}

    def _is_valid(self, value):
        if not isinstance(value, dict):
            return False

        label_re = re.compile('[^a-z0-9_\-]')
        for k, v in value.items():
            if re.search(label_re, k) or re.search(label_re, v):
                return False
            if len(k) > 63 or len(v) > 63:
                return False

        return True


class Bytes(Validator):
    """ Custom bytes validator """
    tag = 'bytes'
    config = {}
    _min = None
    _max = None

    def __init__(self, *args, **kwargs):
        self._min = kwargs.pop('min', None)
        self._max = kwargs.pop('max', None)
        super().__init__(*args, **kwargs)

    def _is_valid(self, value):
        bytes_length = len(str(value).encode('utf-8'))
        if self._min and bytes_length < int(self._min):
            return False
        if self._max and bytes_length > int(self._max):
            return False
        return True


class ServiceAccountRole(Validator):
    """ Custom service account role validator """
    tag = 'sarole'
    config = {}
    approval_type = 'all'

    def __init__(self, *args, **kwargs):
        self.approval_type = kwargs.pop('type', 'all')
        super().__init__(*args, **kwargs)

    def _is_valid(self, value):
        if not isinstance(value, str):
            return False
        if 'serviceAccountRoles' not in self.config:
            return False
        if value not in self.config['serviceAccountRoles']:
            return False
        if self.approval_type == 'approved':
            if 'approved' in self.config[
                    'serviceAccountRoles'] and not self.config[
                        'serviceAccountRoles'][value]['approved']:
                return False
        return True


class ServiceAccountIamRole(Validator):
    """ Custom service account IAM role validator """
    tag = 'saiamrole'
    config = {}
    approval_type = 'all'

    def __init__(self, *args, **kwargs):
        self.approval_type = kwargs.pop('type', 'all')
        super().__init__(*args, **kwargs)

    def _is_valid(self, value):
        if not isinstance(value, str):
            return False
        if value not in self.config['approved'] and value not in self.config[
                'holdForApproval']:
            return False
        if self.approval_type == 'approved':
            if value not in self.config['approved']:
                return False
        return True


class ProjectRoles(Validator):
    """ Custom project group role validator """
    tag = 'projectroles'
    config = {}
    approval_type = 'all'
    error_msg = ''

    def __init__(self, *args, **kwargs):
        self.approval_type = kwargs.pop('type', 'all')
        super().__init__(*args, **kwargs)

    def fail(self, value):
        if self.error_msg != '':
            return '\'%s\': %s' % (value, self.error_msg)
        return super().fail(value)

    def _is_valid(self, value):
        if not isinstance(value, dict):
            self.error_msg = 'wrong format, expecting a map'
            return False
        if 'projectGroupsRoles' not in self.config:
            self.error_msg = 'no configuration for project group roles'
            return False
        for group, roles in value.items():
            if group not in self.config['projectGroupsRoles']:
                self.error_msg = 'no such project group: %s' % (group)
                return False
            if not isinstance(roles, list):
                self.error_msg = 'wrong format for group %s, expecting a list' % (
                    group)
                return False
            for role in roles:
                check_group = group
                if role in self.config['projectGroupsRoles']['_common']:
                    check_group = '_common'
                if role not in self.config['projectGroupsRoles'][check_group]:
                    self.error_msg = 'not such project group: %s' % (group)
                    return False
                if self.approval_type == 'approved':
                    if 'approved' in self.config['projectGroupsRoles'][
                            check_group][
                                role] and not self.config['projectGroupsRoles'][
                                    check_group][role]['approved']:
                        self.error_msg = 'role %s for group %s requires manual approval' % (
                            role, group)
                        return False
        return True


class ProjectIamRoles(Validator):
    """ Custom project group IAM role validator """
    tag = 'projectiamroles'
    config = {}
    approval_type = 'all'
    error_msg = ''

    def __init__(self, *args, **kwargs):
        self.approval_type = kwargs.pop('type', 'all')
        super().__init__(*args, **kwargs)

    def fail(self, value):
        if self.error_msg != '':
            return '\'%s\': %s' % (value, self.error_msg)
        return super().fail(value)

    def _is_valid(self, value):
        if not isinstance(value, dict):
            self.error_msg = 'wrong format, expecting a map'
            return False
        for group, iamroles in value.items():
            if group not in self.config:
                self.error_msg = 'no such project group: %s' % (group)
                return False
            if not isinstance(iamroles, list):
                self.error_msg = 'wrong format for group%s, expecting a list' % (
                    group)
                return False
            for iamrole in iamroles:
                check_group = group
                if iamrole in self.config['_common'][
                        'approved'] or iamrole in self.config['_common'][
                            'holdForApproval']:
                    check_group = '_common'
                if iamrole not in self.config[check_group][
                        'approved'] and iamrole not in self.config[check_group][
                            'holdForApproval']:
                    self.error_msg = 'permission %s not allowed for project group %s' % (
                        iamrole, group)
                    return False
                if self.approval_type == 'approved':
                    if iamrole not in self.config[check_group]['approved']:
                        self.error_msg = 'permission %s for group %s requires manual approval' % (
                            iamrole, group)
                        return False
        return True


def get_validators(cfg_file=None,
                   approved_apis_file=None,
                   approved_sa_iam_roles_file=None,
                   approved_project_iam_roles_file=None,
                   backend=False):
    if not cfg_file:
        if os.path.exists('config.yaml'):
            cfg_file = 'config.yaml'
        if os.path.exists('../config.yaml'):
            cfg_file = '../config.yaml'
        if cfg_file is None:
            print('Could not find config file in current directory or ../',
                  file=sys.stderr)
            sys.exit(1)

    if not approved_apis_file:
        if os.path.exists('projectApprovedApis.yaml'):
            approved_apis_file = 'projectApprovedApis.yaml'
        if os.path.exists('../projectApprovedApis.yaml'):
            approved_apis_file = '../projectApprovedApis.yaml'
        if approved_apis_file is None:
            print(
                'Could not find approved APIs file in current directory or ../',
                file=sys.stderr)
            sys.exit(1)

    if not approved_sa_iam_roles_file:
        if os.path.exists('projectServiceAccountPermissions.yaml'):
            approved_sa_iam_roles_file = 'projectServiceAccountPermissions.yaml'
        if os.path.exists('../projectServiceAccountPermissions.yaml'):
            approved_sa_iam_roles_file = '../projectServiceAccountPermissions.yaml'
        if approved_sa_iam_roles_file is None:
            print(
                'Could not find approved SA IAM roles file in current directory or ../',
                file=sys.stderr)
            sys.exit(1)

    if not approved_project_iam_roles_file:
        if os.path.exists('projectGroupsPermissions.yaml'):
            approved_project_iam_roles_file = 'projectGroupsPermissions.yaml'
        if os.path.exists('../projectGroupsPermissions.yaml'):
            approved_project_iam_roles_file = '../projectGroupsPermissions.yaml'
        if approved_project_iam_roles_file is None:
            print(
                'Could not find approved project groups IAM roles file in current directory or ../',
                file=sys.stderr)
            sys.exit(1)

    if isinstance(cfg_file, dict):  # Coming from Project Factory frontend
        projectFactoryConfig = cfg_file
    else:
        with open(cfg_file, 'r') as stream:
            try:
                projectFactoryConfig = yaml.safe_load(stream)
            except yaml.YAMLError as exc:
                print(exc, file=sys.stderr)
                sys.exit(1)
    if backend:
        projectFactoryConfig['terraformServiceAccount'] = projectFactoryConfig[
            'app']['backend']['serviceAccount']

    if isinstance(approved_apis_file, dict):
        approvedApisConfig = approved_apis_file
    else:
        with open(approved_apis_file, 'r') as stream:
            try:
                approvedApisConfig = yaml.safe_load(stream)
            except yaml.YAMLError as exc:
                print(exc, file=sys.stderr)
                sys.exit(1)

    if isinstance(approved_sa_iam_roles_file, dict):
        approvedSAIamRolesConfig = approved_sa_iam_roles_file
    else:
        with open(approved_sa_iam_roles_file, 'r') as stream:
            try:
                approvedSAIamRolesConfig = yaml.safe_load(stream)
            except yaml.YAMLError as exc:
                print(exc, file=sys.stderr)
                sys.exit(1)

    if isinstance(approved_project_iam_roles_file, dict):
        approvedProjectIamRolesConfig = approved_project_iam_roles_file
    else:
        with open(approved_project_iam_roles_file, 'r') as stream:
            try:
                approvedProjectIamRolesConfig = yaml.safe_load(stream)
            except yaml.YAMLError as exc:
                print(exc, file=sys.stderr)
                sys.exit(1)

    validators = DefaultValidators.copy()
    Apis.config = approvedApisConfig
    validators[Apis.tag] = Apis
    Environments.config = projectFactoryConfig
    validators[Environments.tag] = Environments
    Environment.config = projectFactoryConfig
    validators[Environment.tag] = Environment
    Folder.config = projectFactoryConfig
    validators[Folder.tag] = Folder
    Teams.config = projectFactoryConfig
    validators[Teams.tag] = Teams
    User.config = projectFactoryConfig
    validators[User.tag] = User
    validators[Email.tag] = Email
    validators[_False.tag] = _False
    validators[_True.tag] = _True
    Labels.config = projectFactoryConfig
    validators[Labels.tag] = Labels
    validators[Bytes.tag] = Bytes
    ServiceAccountRole.config = projectFactoryConfig
    validators[ServiceAccountRole.tag] = ServiceAccountRole
    ServiceAccountIamRole.config = approvedSAIamRolesConfig
    validators[ServiceAccountIamRole.tag] = ServiceAccountIamRole
    ProjectRoles.config = projectFactoryConfig
    validators[ProjectRoles.tag] = ProjectRoles
    ProjectIamRoles.config = approvedProjectIamRolesConfig
    validators[ProjectIamRoles.tag] = ProjectIamRoles
    TeamName.config = projectFactoryConfig
    validators[TeamName.tag] = TeamName

    return validators
