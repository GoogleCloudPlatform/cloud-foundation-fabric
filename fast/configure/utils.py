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
import re
import sys
import shutil
import subprocess
import tempfile
import glob
import fnmatch

from googleapiclient import http
import google_auth_httplib2
import google.auth

from .terraform import FastTerraform


class FastUtils:
  VERSION = "0.1.0"

  fabric_repository = "https://github.com/GoogleCloudPlatform/cloud-foundation-fabric.git"
  fabric_github_path = "GoogleCloudPlatform/cloud-foundation-fabric"

  outputs_path = None

  repositories = {
      "modules": "Fabric modules",
      "bootstrap": "Bootstrap stage",
      "cicd": "CI/CD setup stage",
      "resman": "Resource management stage",
      "networking": "Networking setup stage",
      "security": "Security configuration stage",
      "data-platform": "Data platform stage",
      "project-factory": "Project factory stage",
  }

  repository_stages = {
      "modules": None,
      "bootstrap": "00-bootstrap",
      "cicd": "00-cicd",
      "resman": "01-resman",
      "networking": "02-networking-",
      "security": "02-security",
      "data-platform": "03-data-platform",
      "project-factory": "03-project-factory",
  }

  repository_dependencies = {
      "modules": [],
      "bootstrap": [],
      "cicd": ["00-bootstrap"],
      "resman": ["00-bootstrap"],
      "networking": ["00-bootstrap", "01-resman"],
      "security": ["00-bootstrap", "01-resman"],
      "data-platform": [],
      "project-factory": [],
  }

  stages_include = [
      "*.tf",
      "*.md",
      "*.png",
      "*.svg",
      "*.yaml",
      "data",
      "dev",
  ]

  modules_include = [
      "LICENSE",
      "*.md",
      "*.tf",
      "*.png",
      "assets",
      "examples",
      "modules",
      "tests",
      "tools",
  ]

  indent_spaces = 2
  terraform = None

  def __new__(cls):
    if not hasattr(cls, "instance"):
      cls.instance = super(FastUtils, cls).__new__(cls)
    return cls.instance

  def __init__(self):
    self.terraform = FastTerraform()

  def get_version(self):
    return self.VERSION

  def get_outputs_path(self):
    if self.outputs_path is None:
      self.outputs_path = os.getcwd() + "/outputs"
      print(f"Using path for outputs: {self.outputs_path}")
      if not os.path.isdir(self.outputs_path):
        os.mkdir(self.outputs_path)
    return self.outputs_path

  def get_current_user_from_gcloud(self):
    result = subprocess.run(
        ["gcloud", "config", "list", "--format", "value(core.account)"],
        capture_output=True)
    return result.stdout.decode("utf-8").strip() + result.stderr.decode(
        "utf-8").strip()

  def get_branded_http(self):
    credentials, project_id = google.auth.default(
        ['https://www.googleapis.com/auth/cloud-platform'])
    branded_http = google_auth_httplib2.AuthorizedHttp(credentials)
    branded_http = http.set_user_agent(
        branded_http,
        f"google-pso-tool/cloud-foundation-fabric/configure/{self.get_version()}"
    )
    return branded_http

  def change_module_source(self, filename, target_repository, tag=None):

    def change_module_source_sub(matchobj):
      module_source = matchobj.group(2)
      if "../modules" in module_source:
        module_source = module_source.replace("../", "")
        module_source = f"git::{target_repository}//" + module_source
        if tag:
          module_source += f"?ref={tag}"
      return matchobj.group(1) + module_source + matchobj.group(3)

    temp_f = tempfile.NamedTemporaryFile(delete=False)
    source_re = re.compile(r"(source[\s]*=[\s]*\")(.+?)(\")")
    with open(filename, "r") as f:
      while True:
        line = f.readline()
        if not line:
          break
        line = re.sub(source_re, change_module_source_sub, line)
        temp_f.write(line.encode("utf-8"))
      temp_f.close()
    shutil.move(temp_f.name, filename)

  def copy_with_patterns(self, source_dir, target_dir, patterns):
    current_dir = os.getcwd()
    os.chdir(source_dir)
    for filename in glob.glob(f"*"):
      include_file = False
      filename_basename = filename
      for pattern in patterns:
        if fnmatch.fnmatch(filename_basename, pattern):
          include_file = True
          break
      if include_file:
        if os.path.isdir(filename):
          shutil.copytree(filename, f"{target_dir}/{filename}")
        else:
          shutil.copy2(filename, target_dir)
    os.chdir(current_dir)

  def print_hcl_scalar(self, f, scalar):
    if scalar is None:
      f.write("null")
    if isinstance(scalar, str):
      f.write("\"" + scalar.replace("\"", "\\\"") + "\"")
    elif isinstance(scalar, bool):
      f.write("true" if scalar is True else "false")
    elif isinstance(scalar, int) or isinstance(scalar, float):
      f.write(str(scalar))
    elif isinstance(scalar, list):
      first = True
      f.write("[")
      for v in scalar:
        if not first:
          f.write(", ")
        self.print_hcl_scalar(f, v)
        first = False
      f.write("]")

  def print_hcl(self, content, f, indent=0):
    if isinstance(content, dict):
      if indent != 0:
        f.write("{\n")
      for k, v in content.items():
        f.write((indent * self.indent_spaces) * " ")
        f.write(f"{k} = ")
        self.print_hcl(v, f, indent + 1)
      if indent != 0:
        f.write(((indent - 1) * self.indent_spaces) * " ")
        f.write("}")
    else:
      self.print_hcl_scalar(f, content)
    f.write("\n")

  def write_bootstrap_config(self, filename, config):
    with open(filename, "w") as f:
      ba_id = config["billing_account"].split("/")[-1]
      ba_org = config["billing_account_org"].split("/")[-1]
      org = config["organization"].split("/")[-1]
      domain = config["domain"]
      directory_customer_id = config["directory_customer_id"]
      prefix = config["prefix"]

      bootstrap_config = {
          "billing_account": {
              "id": ba_id,
              "organization_id": ba_org,
          },
          "organization": {
              "id": org,
              "domain": domain,
              "customer_id": directory_customer_id,
          },
          "prefix": prefix,
          "outputs_location": self.get_outputs_path(),
          "bootstrap_user": self.get_current_user_from_gcloud(),
      }
      if "bootstrap_repositories" in config:
        bootstrap_config["cicd_repositories"] = config["bootstrap_repositories"]
      if "bootstrap_identity_providers" in config:
        bootstrap_config["federated_identity_providers"] = config[
            "bootstrap_identity_providers"]

      f.write("# Written by configure.py\n\n")
      self.print_hcl(bootstrap_config, f)
    self.terraform.format(filename)

  def get_fabric_repository(self):
    return self.fabric_repository

  def get_fabric_github_path(self):
    return self.fabric_github_path

  def get_repositories(self):
    return self.repositories

  def get_repository_description(self, repository):
    return self.repositories[repository]

  def get_repository_stage(self, repository):
    return self.repository_stages[repository]

  def get_repository_dependencies(self, repository):
    return self.repository_dependencies[repository]

  def get_stage_files_to_include(self):
    return self.stages_include

  def get_module_stage_files_to_include(self):
    return self.modules_include
