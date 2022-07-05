#!/usr/bin/env python3

# Copyright 2022 Google LLC
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
import sys
from .dialogs import FastDialogs
from .utils import FastUtils

from googleapiclient import discovery


class FastConfigurator(FastDialogs):
  utils = None
  session = None
  config = {
      "billing_account": None,
      "billing_account_in_org": None,
      "billing_account_org": None,
      "organization": None,
      "networking_model": "nva",
      "cicd": "custom",
      "directory_customer_id": None,
      "domain": None,
      "prefix": None,
  }
  setup_wizard = [
      "billing_account", "organization", "billing_account_in_org",
      "billing_account_org", "prerequisites", "cicd", "networking", "prefix",
      "final_config"
  ]
  groups = [
      "gcp-billing-admins", "gcp-devops", "gcp-network-admins",
      "gcp-organization-admins", "gcp-security-admins", "gcp-support"
  ]
  crm = None

  def __init__(self, session):
    self.session = session
    self.utils = FastUtils()
    self.crm = discovery.build('cloudresourcemanager', 'v3',
                               http=self.utils.get_branded_http())

  def select_billing_account(self):
    service = discovery.build('cloudbilling', 'v1',
                              http=self.utils.get_branded_http())
    ba_request = service.billingAccounts().list()
    ba_response = ba_request.execute()
    values = {}
    for ba in ba_response["billingAccounts"]:
      ba_id = ba["name"].split("/")[-1]
      values[ba["name"]] = f"{ba['displayName']} ({ba_id})"
    (got_choice, choice) = self.select_dialog("billing_account",
                                              "Select billing account to use",
                                              f"Select billing account to use",
                                              values,
                                              self.config['billing_account'])
    if got_choice:
      self.config['billing_account'] = choice
    return got_choice

  def pick_organization(self, id, title, text, value):
    org_request = self.crm.organizations().search()
    org_response = org_request.execute()
    values = {}
    for org in org_response["organizations"]:
      values[org["name"]] = "%s (%s)" % (org["displayName"],
                                         org["name"].split("/")[1])

    return self.select_dialog(id, title, text, values, value)

  def select_organization(self):
    (got_choice, choice) = self.pick_organization(
        "organization", "Select organization",
        "Select organization to deploy Fabric FAST into",
        self.config["organization"])
    if got_choice:
      org_request = self.crm.organizations().get(name=choice)
      org_response = org_request.execute()
      self.config["domain"] = org_response["displayName"]
      self.config["directory_customer_id"] = org_response["directoryCustomerId"]
      self.config["organization"] = choice
    return got_choice

  def select_billing_account_in_org(self):
    (got_choice, choice) = self.yesno_dialog(
        "billing_account_in_org", f"Billing account in organization",
        f"Does the billing account {self.config['billing_account']} belong\nto the organization {self.config['organization']}?\n\n(this cannot be checked automatically yet)"
    )
    if got_choice:
      self.config["billing_account_in_org"] = choice
    return got_choice

  def select_billing_account_org(self):
    if not self.config["billing_account_in_org"]:
      ba_id = self.config["billing_account"].split("/")[-1]
      (got_choice, choice) = self.pick_organization(
          "billing_account_org", "Select billing account organization",
          f"Select which organization the billing account {ba_id} belongs to:",
          self.config["billing_account_org"])
      if got_choice:
        self.config["billing_account_org"] = choice
      return got_choice
    else:
      self.config["billing_account_org"] = self.config["organization"]
    return True

  def select_prerequisites(self):

    user_account = self.utils.get_current_user_from_gcloud()
    if "gserviceaccount.com" in user_account:
      user_account_iam = f"serviceAccount:{user_account}"
    else:
      user_account_iam = f"user:{user_account}"

    iam_request = self.crm.organizations().getIamPolicy(
        resource=self.config["organization"],
        body={"options": {
            "requestedPolicyVersion": 3
        }})
    iam_response = iam_request.execute()
    has_bindings = {
        "roles/billing.admin": False,
        "roles/logging.admin": False,
        "roles/iam.organizationRoleAdmin": False,
        "roles/resourcemanager.projectCreator": False,
    }
    to_add = dict(has_bindings)
    for binding in iam_response["bindings"]:
      if binding["role"] in has_bindings:
        has_bindings[binding["role"]] = True
        if user_account_iam not in binding["members"]:
          binding["members"].append(user_account_iam)
          to_add[binding["role"]] = True

    for role, binding_exist in has_bindings.items():
      if not binding_exist:
        iam_response["bindings"].append({
            "role": role,
            "members": [user_account_iam],
        })
        to_add[role] = True

    if not self.config["billing_account_in_org"]:
      ba_iam_request = self.crm.organizations().getIamPolicy(
          resource=self.config["billing_account_org"],
          body={"options": {
              "requestedPolicyVersion": 3
          }})
      ba_iam_response = iam_request.execute()

    anything_to_add = False
    text = f"The following IAM roles in {self.config['organization']} will be added for: {user_account}\n"
    for role, will_be_added in to_add.items():
      if will_be_added:
        text += f"\n  - {role}"
        anything_to_add = True

    if anything_to_add:
      choice = self.confirm_dialog(
          "prerequisites",
          f"Adding bootstrap permissions",
          text,
      )
      if choice:
        set_iam_request = self.crm.organizations().setIamPolicy(
            resource=self.config["organization"], body={"policy": iam_response})
        set_iam_response = set_iam_request.execute()
      else:
        return False

    return True

  def select_prefix(self):
    default_prefix = self.config["domain"].replace(".", "")[0:4]
    choice = self.input_dialog(
        "prefix",
        f"Resource prefix",
        "Select your own short organization resource prefix (eg. 4 letters):",
        default_prefix,
    )
    if choice:
      self.config["prefix"] = choice
      return True
    return False

  def select_final_config(self):
    bootstrap_output_path = "stages/00-bootstrap/terraform.tfvars"
    choice = self.input_dialog(
        "final_config",
        f"Bootstrap Terraform configuration",
        "Write the bootstrap stage Terraform configuration to the following file:",
        bootstrap_output_path,
    )
    if choice:
      self.config["bootstrap_output_path"] = bootstrap_output_path
      self.utils.write_bootstrap_config(bootstrap_output_path, self.config)
      return True
    return False

  def select_cicd(self):
    (got_choice, choice) = self.select_dialog(
        "cicd", "Select CI/CD",
        "Select the CI/CD system that you will be using.", {
            "github": "GitHub",
            "gitlab-com": "Gitlab.com",
            "gitlab-ce": "Gitlab (self-hosted)",
            "cloudbuild": "Cloud Build",
            "cloudbuild": "Cloud Source Repositories and Cloud Build",
            "custom": "Roll your own (custom CI/CD)",
        }, self.config['cicd'])
    if got_choice:
      self.config['cicd'] = choice
    return got_choice

  def select_networking(self):
    (got_choice, choice) = self.select_dialog(
        "networking", "Select networking model",
        f"You can pick between multiple networking models for your organization.\nFor more information, see the FAST repository.",
        {
            "vpn":
                "Connectivity between hub and spokes via VPN HA tunnels",
            "nva":
                "Connectivity between hub and the spokes via VPC network peering (supports network virtual appliances)",
            "peering":
                "Connectivity between hub and spokes via VPC peering",
        }, self.config['networking_model'])
    if got_choice:
      self.config['networking_model'] = choice
    return got_choice
