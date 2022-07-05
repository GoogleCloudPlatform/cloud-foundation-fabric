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
import json
import shutil
import tempfile
from pathlib import Path

from .dialogs import FastDialogs
from .utils import FastUtils
from .terraform import FastTerraform
from .git import FastGit

from github import Github


class FastCicdConfigurator(FastDialogs):
  config = {"git": "ssh"}
  utils = None
  terraform = None

  setup_wizard = ["terraform", "git"]

  def __init__(self, session, config):
    super().__init__(session)
    self.config = {**self.config, **config}
    self.utils = FastUtils()
    self.terraform = FastTerraform()

  def select_terraform(self):
    (got_choice, choice) = self.yesno_dialog(
        "terraform", f"Run Terraform?",
        f"Now that CI/CD is configured, would you like me to run Terraform?")
    if got_choice:
      if choice:
        for stage in ["00-bootstrap", "00-cicd"]:
          stage_dir = f"stages/{stage}"
          providers = self.utils.get_outputs_path(
          ) + f"/providers/{stage}-providers.tf"
          if not os.path.exists(f"{stage_dir}/{stage}-providers.tf"
                               ) and os.path.exists(providers):
            print(f"Copying {providers} to {stage_dir}...")
            shutil.copy2(providers, stage_dir)

          if stage != "00-bootstrap":
            bootstrap_auto_vars = self.utils.get_outputs_path(
            ) + "/tfvars/00-bootstrap.auto.tfvars.json"
            if not os.path.exists(f"{stage_dir}/00-bootstrap.auto.tfvars.json"
                                 ) and os.path.exists(bootstrap_auto_vars):
              print(f"Copying {bootstrap_auto_vars} to {stage_dir}...")
              shutil.copy2(bootstrap_auto_vars, stage_dir)

          output_path = self.config[
              "bootstrap_output_path"] if stage == "00-bootstrap" else self.config[
                  "cicd_output_path"]
          self.terraform.init(self, os.path.dirname(output_path))
          self.terraform.apply(self, os.path.dirname(output_path))
      return True
    return got_choice

  def select_git(self):
    tf_output_str = self.terraform.output(
        os.path.dirname(self.config["cicd_output_path"]))
    tf_outputs = json.loads(tf_output_str)
    if "tfvars" in tf_outputs:
      self.config["cicd_ssh_urls"] = tf_outputs["tfvars"]["value"][
          "cicd_ssh_urls"]
      self.config["cicd_https_urls"] = tf_outputs["tfvars"]["value"][
          "cicd_https_urls"]
      self.config["cicd_import_ok"] = True
    else:
      self.config["cicd_import_ok"] = False
    (got_choice, choice) = self.select_dialog(
        "cicd", "Push FAST to source control system?",
        "Would you like to initialize the CI/CD repositories with FAST stages?",
        {
            "ssh": "Yes, push via SSH",
            "https": "Yes, push via HTTPS",
            "no": "No, but thanks",
        }, self.config["git"])
    if got_choice:
      self.config["git"] = choice
      if self.config["git"] != "no":
        git = FastGit()
        for repository, name in self.utils.get_repositories().items():
          stage = self.utils.get_repository_stage(repository)
          temp_dir = tempfile.mkdtemp(prefix=stage)
          if stage:
            if repository == "networking":
              stage += self.config["networking_model"]

            print(f"Setting up stage {stage} in: {temp_dir}")
            self.utils.copy_with_patterns(
                f"stages/{stage}", temp_dir,
                self.utils.get_stage_files_to_include())

            provider_path = self.utils.get_outputs_path(
            ) + f"/providers/{stage}-providers.tf"
            if os.path.exists(provider_path):
              print(f"Copying {provider_path} to {temp_dir}")
              shutil.copy2(provider_path,
                           temp_dir + "/" + os.path.basename(provider_path))

            globals_path = self.utils.get_outputs_path(
            ) + f"/tfvars/globals.auto.tfvars.json"
            if os.path.exists(globals_path):
              print(f"Copying {globals_path} to {temp_dir}")
              shutil.copy2(globals_path,
                           temp_dir + "/" + os.path.basename(globals_path))

            workflow_path = self.utils.get_outputs_path(
            ) + f"/workflows/{repository}-workflow.yaml"
            if os.path.exists(workflow_path):
              print(f"Copying {workflow_path} to {temp_dir}")
              if "gitlab" in self.config["cicd"]:
                workflow_file = temp_dir + "/.gitlab-ci.yml"
              elif "github" in self.config["cicd"]:
                workflow_file = temp_dir + "/.github/workflows/cicd.yml"

              Path(os.path.dirname(workflow_file)).mkdir(
                  parents=True, exist_ok=True)
              shutil.copy2(workflow_path, workflow_file)

            for dependencies in self.utils.get_repository_dependencies(
                repository):
              for dependency in dependencies:
                dependency_path = self.utils.get_outputs_path(
                ) + f"/tfvars/{dependency}.auto.tfvars.json"
                if os.path.exists(dependency_path):
                  print(f"Copying {dependency_path} to {temp_dir}")
                  shutil.copy2(dependency_path,
                               temp_dir + os.path.basename(dependency_path))

            print(f"Fixing up module sources in {temp_dir}")
            module_repository = module_tag = None
            if self.config["use_upstream"]:
              module_repository = self.utils.get_fabric_repository()
              module_tag = self.config["upstream_tag"]
            else:
              module_tag = None
              if self.config["git"] == "ssh":
                module_repository = self.config["cicd_ssh_urls"]["modules"]
              else:
                module_repository = self.config["cicd_https_urls"]["modules"]

            for path in Path(temp_dir).rglob('*.tf'):
              path_name = path.relative_to(temp_dir)
              self.utils.change_module_source(f"{temp_dir}/{path_name}",
                                              module_repository, tag=module_tag)

          else:
            # Modules stage
            self.utils.copy_with_patterns(
                os.path.abspath("../"), temp_dir,
                self.utils.get_module_stage_files_to_include())
            stage = "modules"

          if stage == "modules" and self.config["use_upstream"]:
            continue

          print(f"Initializing Git repository in {temp_dir} for stage {stage}")
          git.run(["init", "--initial-branch", "main"], temp_dir)

          git_origin = None
          if self.config["git"] == "ssh":
            git_origin = self.config["cicd_ssh_urls"][repository]
          elif self.config["git"] == "https":
            git_origin = self.config["cicd_https_urls"][repository]

          if git_origin:
            print(f"Adding origin {git_origin} for stage {stage}")
            git.run(["remote", "add", "origin", git_origin], temp_dir)

            print(f"Fetching origin")
            fetch_ok, fetch_stderr = git.run(["fetch", "origin", "main"],
                                             temp_dir, allow_fail=True)
            print(f"Adding all files in Git for stage {stage}")
            git.run(["add", "--all"], temp_dir)

            print(f"Committing all files {stage}")
            git.run(["commit", "-a", "-m", "Fabric FAST import"], temp_dir)

            if fetch_ok is not None:
              print(f"Rebasing {stage}")
              git.run(["rebase", "origin/main", "main"], temp_dir)

            print(f"Pushing commit for {stage}")
            git.run(["push", "origin", "main"], temp_dir)
      return True
    return False


class FastCicdSystemConfigurator(FastDialogs):
  config = {}
  utils = None
  terraform = None

  def __init__(self, session, config):
    super().__init__(session)
    self.config = {**self.config, **super().config}
    self.config = {**self.config, **config}
    self.utils = FastUtils()
    self.terraform = FastTerraform()

  def select_upstream_modules(self):
    g = Github()
    repo = g.get_repo(self.utils.get_fabric_github_path())
    tags = repo.get_tags()
    latest_tag = tags[0].name

    (got_choice, choice) = self.yesno_dialog(
        "modules", f"Use upstream modules?",
        f"Would you like to use the upstream Fabric modules at version {latest_tag}?\nOtherwise we will fork the modules into your own repository."
    )
    if got_choice:
      self.config["use_upstream"] = choice
      self.config["upstream_tag"] = latest_tag
    return got_choice

  def get_cicd_system_config(self, config, cicd_config):
    return config, cicd_config

  def write_cicd_config(self, filename):
    with open(filename, "w") as f:
      cicd_config = {
          "cicd_repositories": {},
          "outputs_location": self.utils.get_outputs_path(),
      }

      self.config, cicd_config = self.get_cicd_system_config(
          self.config, cicd_config)

      f.write("# Written by configure.py\n\n")
      self.utils.print_hcl(cicd_config, f)
    self.terraform.format(filename)

  def select_final_config(self):
    cicd_output_path = "stages/00-cicd/terraform.tfvars"
    choice = self.input_dialog(
        "final_config",
        f"CI/CD Terraform configuration",
        "Write the CI/CD stage Terraform configuration to the following file:",
        cicd_output_path,
    )
    if choice:
      self.config["cicd_output_path"] = cicd_output_path
      self.write_cicd_config(cicd_output_path)
      self.utils.write_bootstrap_config(self.config["bootstrap_output_path"],
                                        self.config)
      return True
    return False
