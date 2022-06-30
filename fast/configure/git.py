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
import subprocess


class FastGit:

    def __init__(self):
        pass

    def run(self, cmd, dir, allow_fail=False):
        try:
            os.environ["GIT_TERMINAL_PROMPT"] = "0"
            result = subprocess.run(["git"] + cmd,
                                    cwd=dir,
                                    capture_output=True,
                                    text=True,
                                    check=True)
        except subprocess.CalledProcessError as e:
            if allow_fail:
                return None, None
            print(f"Command {e.cmd} failed: {e.stdout} {e.stderr}")
            raise e
        return result.stdout, result.stderr
