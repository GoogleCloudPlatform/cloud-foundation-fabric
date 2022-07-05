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
import os
import sys
from ..cicd import FastCicdSystemConfigurator

from github import Github


class FastGithubConfigurator(FastCicdSystemConfigurator):
  config = {
      "github_organization": None,
  }
  setup_wizard = [
      "upstream_modules", "github_token", "github_organization",
      "github_repositories", "final_config"
  ]

  def __init__(self, session, config):
    super().__init__(session, config)
    self.config = {**self.config, **config}
    self.config["github_repositories"] = {}
    for k, v in self.utils.get_repositories().items():
      self.config["github_repositories"][k] = k

  def select_github_token(self):
    if not os.getenv("GITHUB_TOKEN"):
      choice = self.input_dialog(
          "github_token", f"GitHub access token",
          "You don't seem to have GITHUB_TOKEN environment variable set.\n\nPlease enter your token below:",
          "", password=True)
      if choice:
        os.environ["GITHUB_TOKEN"] = choice
      return True
    return True

  def get_github(self):
    return Github(os.environ["GITHUB_TOKEN"])

  def select_github_organization(self):
    gh = self.get_github()
    organizations = gh.get_user().get_orgs()
    values = {}
    for org in organizations:
      values[org.login] = org.name if org.name else org.login

    (got_choice, choice) = self.select_dialog(
        "github_group", "Select GitHub organization",
        "Select the GitHub organization for the repositories.", values,
        self.config["github_organization"])
    if got_choice:
      self.config["github_organization"] = choice
      return True
    return False

  def select_github_repositories(self):
    values = {}
    if self.config["use_upstream"]:
      self.config["github_repositories"].pop("modules")

    repositories = self.utils.get_repositories()
    for k, v in self.config["github_repositories"].items():
      values[k] = f"{repositories[k]}:"
    (got_choice, choice) = self.multi_input_dialog(
        "github_repositories", "GitHub repositories",
        "Customize GitHub repository names. You can leave any empty if you don't want a repository for that stage.",
        values, self.config["github_repositories"])
    if got_choice:
      self.config["github_repositories"] = choice
      return True
    return False

  def get_cicd_system_config(self, config, cicd_config):
    config["bootstrap_identity_providers"] = {
        "github": {
            "attribute_condition":
                f"attribute.namespace_path==\"{config['github_organization']}\"",
            "issuer":
                "github",
            "custom_settings":
                None,
        }
    }

    config["bootstrap_repositories"] = {
        "bootstrap": {
            "branch": "main",
            "identity_provider": "github",
            "name": f"{config['github_organization']}/bootstrap",
            "type": "github"
        },
        "cicd": {
            "branch": "main",
            "identity_provider": "github",
            "name": f"{config['github_organization']}/cicd",
            "type": "github"
        },
        "resman": {
            "branch": "main",
            "identity_provider": "github",
            "name": f"{config['github_organization']}/resman",
            "type": "github"
        },
    }

    cicd_config["github"] = {
        "url": None,
        "visibility": "private",
    }
    if "modules" not in config["github_repositories"]:
      cicd_config["cicd_repositories"]["modules"] = None

    for k, v in config["github_repositories"].items():
      cicd_config["cicd_repositories"][k] = {
          "branch": "main",
          "identity_provider": "github",
          "name": f"{config['github_organization']}/{v}",
          "description": self.utils.get_repository_description(v),
          "type": "github",
          "create": True,
          "create_group": False,
      }
    return config, cicd_config
