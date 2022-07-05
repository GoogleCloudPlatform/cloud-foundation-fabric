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
import asyncio

from prompt_toolkit.application.current import get_app
from prompt_toolkit.layout.containers import HSplit
from prompt_toolkit.widgets import (
    Button,
    Dialog,
    Label,
    TextArea,
)


class FastTerraform:

  def __init__(self):
    pass

  def format(self, filename):
    result = subprocess.run(["terraform", "fmt", filename])
    if result.returncode != 0:
      raise Exception(f"Unable to terraform fmt {filename}!")

  async def read_subprocess(self, stream, cb):
    while True:
      line = await stream.readline()
      if line:
        cb(line)
      else:
        break

  def read_subprocess_stdout(self, line):
    if line:
      line_decoded = line.decode("utf-8")
      self.tf_stdout += line_decoded
      self.output_label.text += line_decoded
      self.output_label.document._cursor_position = len(self.output_label.text)
      self.tf_app.invalidate()

  def read_subprocess_stderr(self, line):
    if line:
      line_decoded = line.decode("utf-8")
      self.tf_stderr += line_decoded
      self.output_label.text += line_decoded
      self.output_label.document._cursor_position = len(self.output_label.text)
      self.tf_app.invalidate()

  async def async_run_terraform(self, cmd, dir, stdout_cb, stderr_cb):
    os.environ["TF_IN_AUTOMATION"] = "1"
    os.environ["TF_INPUT"] = "0"
    os.environ["TF_CLI_ARGS"] = "-no-color"
    p = await asyncio.subprocess.create_subprocess_shell(
        " ".join(cmd), stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE, cwd=dir)
    await asyncio.wait([
        self.read_subprocess(p.stdout, stdout_cb),
        self.read_subprocess(p.stderr, stderr_cb)
    ])
    self.return_code = await p.wait()
    if self.return_code != 0:
      self.ok_button.text = "Retry"
    else:
      self.ok_button.text = "Ok"
    self.tf_app.invalidate()
    return self.return_code

  async def run_tasks(self, cmd, dir, app):
    tasks = []
    tasks.append(
        asyncio.ensure_future(
            self.async_run_terraform(cmd, dir, self.read_subprocess_stdout,
                                     self.read_subprocess_stderr)))
    tasks.append(app.run_async())
    r = await asyncio.gather(*tasks)
    return r

  def run_terraform_until_ok(self, dialogs, cmd, dir):

    def ok_handler():
      if self.ok_button.text != "Wait...":
        get_app().exit(result=True)

    def previous_handler():
      get_app().exit(result=False)

    def quit_handler():
      get_app().exit(result=None)

    cmd_joined = " ".join(cmd)
    self.ok_button = Button(text="Wait...", handler=ok_handler)
    self.output_label = TextArea(text="", read_only=True, line_numbers=True)
    dialog = Dialog(
        title="Running: Terraform",
        body=HSplit(
            [
                Label(text=f"Running {cmd_joined}:", dont_extend_height=True),
                self.output_label
            ],
            padding=1,
        ),
        buttons=[
            self.ok_button,
            Button(text="Previous", handler=previous_handler),
            Button(text="Quit", handler=quit_handler),
        ],
        with_background=True,
    )

    while True:
      print(f"Running Terraform in {dir}: {cmd_joined}")
      self.ok_button.text = "Wait..."
      self.output_label.text = ""

      self.tf_stdout = self.tf_stderr = ""

      self.tf_app = dialogs._create_app(dialog, style=None)

      loop = asyncio.get_event_loop()
      return_code, result = loop.run_until_complete(
          self.run_tasks(cmd, dir, self.tf_app))
      if result is None:
        dialogs.maybe_quit()
      if return_code == 0 and result:
        return True
      if not result:
        return False

  def run_with_output(self, cmd, dir):
    result = subprocess.run(cmd, cwd=dir, capture_output=True, text=True,
                            check=True)
    return result.stdout, result.stderr

  def init(self, dialogs, dir):
    cmd = ["terraform", "init", "-migrate-state", "-force-copy"]
    return self.run_terraform_until_ok(dialogs, cmd, dir)

  def plan(self, dialogs, dir, flags=None):
    cmd = ["terraform", "plan"]
    if flags:
      cmd = cmd + flags
    return self.run_terraform_until_ok(dialogs, cmd, dir)

  def apply(self, dialogs, dir, flags=None):
    cmd = ["terraform", "apply", "-auto-approve"]
    if flags:
      cmd = cmd + flags
    return self.run_terraform_until_ok(dialogs, cmd, dir)

  def output(self, dir):
    cmd = ["terraform", "output", "-json"]
    output_stdout, output_stderr = self.run_with_output(cmd, dir)
    return output_stdout
