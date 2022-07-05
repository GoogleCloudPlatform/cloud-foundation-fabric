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
from .utils import FastUtils

from prompt_toolkit import shortcuts
from prompt_toolkit.layout import Layout
from prompt_toolkit.application import Application
from prompt_toolkit.application.current import get_app
from prompt_toolkit.key_binding.defaults import load_key_bindings
from prompt_toolkit.key_binding.key_bindings import KeyBindings, merge_key_bindings
from prompt_toolkit.key_binding.bindings.focus import focus_next, focus_previous
from prompt_toolkit.layout.containers import HSplit
from prompt_toolkit.widgets import (
    Button,
    Dialog,
    Label,
    TextArea,
    ValidationToolbar,
    RadioList,
)
from prompt_toolkit.cursor_shapes import CursorShape


class FastDialogs:
  session = None
  application = None
  outputs_path = None
  utils = None

  config = {
      "use_upstream": True,
      "upstream_tag": None,
      "bootstrap_output_path": None,
      "cicd_output_path": None,
  }

  def __init__(self, session):
    self.session = session
    self.utils = FastUtils()

  def maybe_quit(self):
    result = shortcuts.yes_no_dialog(
        title='Quit configuration process',
        text='Do you want to quit the configuration?').run()
    if result:
      quit()

  def select_dialog(self, id, title, text, values, value):

    def ok_handler():
      get_app().exit(result=radio_list.current_value)

    def previous_handler():
      get_app().exit(result=False)

    def quit_handler():
      get_app().exit()

    tuple_values = []
    for k, v in values.items():
      tuple_values.append((k, v))
    radio_list = RadioList(values=tuple_values, default=value)
    dialog = Dialog(
        title=title,
        body=HSplit(
            [Label(text=text, dont_extend_height=True), radio_list],
            padding=1,
        ),
        buttons=[
            Button(text="Ok", handler=ok_handler),
            Button(text="Previous", handler=previous_handler),
            Button(text="Quit", handler=quit_handler),
        ],
        with_background=True,
    )
    radio_list_app = self._create_app(dialog, style=None)
    while True:
      choice = radio_list_app.run()
      if choice is None:
        self.maybe_quit()
      else:
        if choice is False:
          return (False, None)
        return (True, choice)

  def select_with_input_dialog(self, id, title, text, new_text, values, value):

    def ok_handler():
      if radio_list.current_value == "_":
        get_app().exit(result=(textfield.text, True))
      else:
        get_app().exit(result=(radio_list.current_value, False))

    def previous_handler():
      get_app().exit(result=(False, False))

    def accept_handler(buf):
      get_app().layout.focus(ok_button)
      return True

    def quit_handler():
      get_app().exit()

    tuple_values = []
    for k, v in values.items():
      tuple_values.append((k, v))
    radio_list = RadioList(values=tuple_values, default=value)
    textfield = TextArea(
        text="",
        multiline=False,
        accept_handler=accept_handler,
    )

    ok_button = Button(text="Ok", handler=ok_handler)
    dialog = Dialog(
        title=title,
        body=HSplit(
            [
                Label(text=text, dont_extend_height=True), radio_list,
                Label(text=new_text, dont_extend_height=True), textfield
            ],
            padding=1,
        ),
        buttons=[
            ok_button,
            Button(text="Previous", handler=previous_handler),
            Button(text="Quit", handler=quit_handler),
        ],
        with_background=True,
    )
    radio_list_app = self._create_app(dialog, style=None)
    while True:
      choice, was_new = radio_list_app.run()
      if choice is None:
        self.maybe_quit()
      else:
        if choice is False:
          return (False, None, False)
        return (True, choice, was_new)

  def multi_input_dialog(self, id, title, text, values, value):

    def ok_handler():
      ret = {}
      for k, v in textfields.items():
        ret[k] = v.text
      get_app().exit(result=ret)

    def previous_handler():
      get_app().exit(result=False)

    def accept_handler(buf):
      get_app().layout.focus_next()
      return True

    def quit_handler():
      get_app().exit()

    textfields = {}
    controls = []
    for k, v in values.items():
      textfields[k] = TextArea(
          text=value[k],
          multiline=False,
          accept_handler=accept_handler,
      )
      controls.append(Label(text=v, dont_extend_height=True))
      controls.append(textfields[k])

    dialog = Dialog(
        title=title,
        body=HSplit(
            [Label(text=text, dont_extend_height=True)] + controls,
            padding=1,
        ),
        buttons=[
            Button(text="Ok", handler=ok_handler),
            Button(text="Previous", handler=previous_handler),
            Button(text="Quit", handler=quit_handler),
        ],
        with_background=True,
    )
    multi_input_app = self._create_app(dialog, style=None)
    while True:
      choice = multi_input_app.run()
      if choice is None:
        self.maybe_quit()
      else:
        if choice is False:
          return (False, None)
        return (True, choice)

  def confirm_dialog(self, id, title, text):

    def ok_handler():
      get_app().exit(result=True)

    def previous_handler():
      get_app().exit(result=False)

    def quit_handler():
      get_app().exit()

    dialog = Dialog(
        title=title,
        body=Label(text=text, dont_extend_height=True),
        buttons=[
            Button(text="Ok", handler=ok_handler),
            Button(text="Previous", handler=previous_handler),
            Button(text="Quit", handler=quit_handler),
        ],
        with_background=True,
    )
    confirm_app = self._create_app(dialog, style=None)
    while True:
      choice = confirm_app.run()
      if choice is None:
        self.maybe_quit()
      else:
        return choice

  def input_dialog(self, id, title, text, value="", validator=None,
                   password=False):

    def accept_handler(buf):
      get_app().layout.focus(ok_button)
      return True

    def ok_handler():
      get_app().exit(result=textfield.text)

    def previous_handler():
      get_app().exit(result=False)

    def quit_handler():
      get_app().exit()

    ok_button = Button(text="Ok", handler=ok_handler)
    textfield = TextArea(
        text=value,
        multiline=False,
        password=password,
        validator=validator,
        accept_handler=accept_handler,
    )
    dialog = Dialog(
        title=title,
        body=HSplit([
            Label(text=text, dont_extend_height=True),
            textfield,
            ValidationToolbar(),
        ]),
        buttons=[
            ok_button,
            Button(text="Previous", handler=previous_handler),
            Button(text="Quit", handler=quit_handler),
        ],
        with_background=True,
    )
    input_app = self._create_app(dialog, style=None)
    while True:
      choice = input_app.run()
      if choice is None:
        self.maybe_quit()
      else:
        return choice

  def yesno_dialog(self, id, title, text):

    def yes_handler():
      get_app().exit(result=(True, True))

    def no_handler():
      get_app().exit(result=(True, False))

    def previous_handler():
      get_app().exit(result=(False, None))

    def quit_handler():
      get_app().exit(result=(None, None))

    dialog = Dialog(
        title=title,
        body=Label(text=text, dont_extend_height=True),
        buttons=[
            Button(text="Yes", handler=yes_handler),
            Button(text="No", handler=no_handler),
            Button(text="Previous", handler=previous_handler),
            Button(text="Quit", handler=quit_handler),
        ],
        with_background=True,
    )
    yesno_app = self._create_app(dialog, style=None)
    while True:
      (got_choice, choice) = yesno_app.run()
      if got_choice is None:
        self.maybe_quit()
      else:
        return (got_choice, choice)

  def _create_app(self, dialog, style):
    bindings = KeyBindings()
    bindings.add("tab")(focus_next)
    bindings.add("s-tab")(focus_previous)

    return Application(
        layout=Layout(dialog),
        key_bindings=merge_key_bindings([load_key_bindings(), bindings]),
        mouse_support=False,
        full_screen=True,
        cursor=CursorShape.BLINKING_BLOCK,
    )

  def run_wizard(self):
    dialog_index = 0
    while True:
      dialog = self.setup_wizard[dialog_index]
      dialog_func = f"select_{dialog}"
      go_to_next = getattr(self, dialog_func)()
      if go_to_next:
        dialog_index += 1
      else:
        dialog_index -= 1
      if dialog_index == len(self.setup_wizard):
        break
    return self.config
