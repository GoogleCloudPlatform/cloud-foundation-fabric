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

import gitlab


class FastGitlabConfigurator(FastCicdSystemConfigurator):
  config = {
      "gitlab_url": None,
      "gitlab_group": None,
      "gitlab_group_create": False,
  }
  setup_wizard = [
      "upstream_modules", "gitlab_url", "gitlab_token", "gitlab_group",
      "gitlab_repositories", "final_config"
  ]

  def __init__(self, session, config):
    super().__init__(session, config)
    self.config = {**self.config, **config}
    self.config["gitlab_repositories"] = {}
    for k, v in self.utils.get_repositories().items():
      self.config["gitlab_repositories"][k] = k

  def select_gitlab_url(self):
    if self.config["cicd"] == "gitlab-ce":
      default_url = f"https://gitlab.{self.config['domain']}"
      choice = self.input_dialog(
          "gitlab_url",
          f"Gitlab installation URL",
          "Enter your Gitlab CE installation URL:",
          default_url,
      )
      if choice:
        self.config["gitlab_url"] = choice
        return True
      return False
    else:
      self.config["gitlab_url"] = "https://gitlab.com"
      return True

  def select_gitlab_token(self):
    if not os.getenv("GITLAB_TOKEN"):
      choice = self.input_dialog(
          "gitlab_url", f"Gitlab access token",
          "You don't seem to have GITLAB_TOKEN environment variable set.\n\nPlease enter your token below:",
          "", password=True)
      if choice:
        os.environ["GITLAB_TOKEN"] = choice
      return True
    return True

  def get_gitlab(self):
    return gitlab.Gitlab(self.config["gitlab_url"],
                         private_token=os.environ["GITLAB_TOKEN"])

  def select_gitlab_group(self):
    gl = self.get_gitlab()
    groups = gl.groups.list()
    values = {}
    for group in groups:
      if group.name != "GitLab Instance":
        values[group.path] = group.name
    values["_"] = "New group (enter name below)"

    (got_choice, choice, new_choice) = self.select_with_input_dialog(
        "gitlab_group", "Select Gitlab group for repositories",
        "Select existing Gitlab group for repositories, or specify a new one.",
        "New group name:", values, self.config["gitlab_group"])
    if got_choice:
      self.config["gitlab_group"] = choice
      self.config["gitlab_group_create"] = False
      if new_choice:
        self.config["gitlab_group_create"] = True
      return True
    return False

  def select_gitlab_repositories(self):
    values = {}
    if self.config["use_upstream"]:
      self.config["gitlab_repositories"].pop("modules")

    repositories = self.utils.get_repositories()
    for k, v in self.config["gitlab_repositories"].items():
      values[k] = f"{repositories[k]}:"
    (got_choice, choice) = self.multi_input_dialog(
        "gitlab_repositories", "Gitlab repositories",
        "Customize Gitlab repository names. You can leave any empty if you don't want a repository for that stage.",
        values, self.config["gitlab_repositories"])
    if got_choice:
      self.config["gitlab_repositories"] = choice
      return True
    return False

  def get_cicd_system_config(self, config, cicd_config):
    config["bootstrap_identity_providers"] = {
        "gitlab": {
            "attribute_condition":
                f"attribute.namespace_path==\"{config['gitlab_group']}\"",
            "issuer":
                "gitlab",
            "custom_settings":
                None,
        }
    }

    if config["cicd"] == "gitlab-ce":
      config["bootstrap_identity_providers"]["gitlab"]["custom_settings"] = {
          "issuer_uri": config["gitlab_url"],
          "allowed_audiences": [config["gitlab_url"]]
      }

    config["bootstrap_repositories"] = {
        "bootstrap": {
            "branch": "main",
            "identity_provider": "gitlab",
            "name": f"{config['gitlab_group']}/bootstrap",
            "type": "gitlab"
        },
        "cicd": {
            "branch": "main",
            "identity_provider": "gitlab",
            "name": f"{config['gitlab_group']}/cicd",
            "type": "gitlab"
        },
        "resman": {
            "branch": "main",
            "identity_provider": "gitlab",
            "name": f"{config['gitlab_group']}/resman",
            "type": "gitlab"
        },
    }

    cicd_config["gitlab"] = {
        "url":
            "https://gitlab.com"
            if config["cicd"] == "gitlab-com" else config["gitlab_url"],
        "project_visibility":
            "private",
        "shared_runners_enabled":
            True,
    }
    if "modules" not in config["gitlab_repositories"]:
      cicd_config["cicd_repositories"]["modules"] = None

    for k, v in config["gitlab_repositories"].items():
      cicd_config["cicd_repositories"][k] = {
          "branch": "main",
          "identity_provider": "gitlab",
          "name": f"{config['gitlab_group']}/{v}",
          "description": self.utils.get_repository_description(v),
          "type": "gitlab",
          "create": True,
          "create_group": config["gitlab_group_create"],
      }
    return config, cicd_config
