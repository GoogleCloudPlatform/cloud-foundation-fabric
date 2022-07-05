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
import shutil

try:
  from configure.utils import FastUtils
  from configure.configurator import FastConfigurator
  from configure.cicd import FastCicdConfigurator
  from configure.cicd_systems.gitlab import FastGitlabConfigurator
  from configure.cicd_systems.github import FastGithubConfigurator
  from prompt_toolkit import PromptSession
  from prompt_toolkit.cursor_shapes import CursorShape
except ImportError as e:
  print(
      ("Looks like you don't have some of the Python dependencies installed.\n"
       f"Error: {e}\n"
       "please install the requirements: pip install -r requirements.txt."))
  sys.exit(1)


def check_prerequisites():
  GIT = shutil.which("git")
  if not GIT:
    print(
        "You don't have Git installed (how did you get here?), please install it."
    )
    return False

  TERRAFORM = shutil.which("terraform")
  if not TERRAFORM:
    print("You don't have Terraform installed, please install it.")
    return False
  return True


def main():
  if not check_prerequisites():
    sys.exit(1)

  session = PromptSession(cursor=CursorShape.BLINKING_BLOCK)
  VERSION = FastUtils().get_version()
  print(f"Fabric FAST configurator v{VERSION}")

  configurator = FastConfigurator(session)
  config = configurator.run_wizard()

  if "gitlab" in config["cicd"] or config["cicd"] == "github":
    if "gitlab" in config["cicd"]:
      gitlab_configurator = FastGitlabConfigurator(session, config)
      config = gitlab_configurator.run_wizard()
    elif config["cicd"] == "github":
      github_configurator = FastGithubConfigurator(session, config)
      config = github_configurator.run_wizard()

    cicd_configurator = FastCicdConfigurator(session, config)
    config = cicd_configurator.run_wizard()

  # print("Full configuration: ", config)
  print("All done!")


if __name__ == "__main__":
  main()
