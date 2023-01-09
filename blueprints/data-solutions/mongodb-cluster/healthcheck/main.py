#!/usr/bin/env python3
#
# Copyright 2023 Google LLC
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

from os import getenv
from functools import partial
from http.server import HTTPServer, BaseHTTPRequestHandler
from pymongo import MongoClient
from sys import stderr
import json


class MongoDBHealthHandler(BaseHTTPRequestHandler):

  def __init__(self, mongodb_port, *args, **kwargs):
    self.mongodb_port = mongodb_port
    super().__init__(*args, **kwargs)

  def do_HEAD(self):

    mongo_uri = 'mongodb://localhost:%d/' % (self.mongodb_port)
    client = MongoClient(mongo_uri, self.mongodb_port, timeoutMS=5000,
                         socketTimeoutMS=5000, connectTimeoutMS=5000,
                         directConnection=True)
    self.response = {"ok": 0, "error": ""}
    try:
      self.response = client.admin.command('ping')
      if 'ok' in self.response:
        self.response['ok'] = int(self.response['ok'])
      self.send_response(200)
    except Exception as e:
      print('Error pinging server: %s' % (e), file=stderr)
      self.response['error'] = str(e)
      self.send_response(500)

    self.send_header('Content-type', 'application/json')
    self.end_headers()

  def do_GET(self):
    self.do_HEAD()
    self.wfile.write(
        json.dumps(
            self.response, default=lambda o:
            f"<<non-serializable: {type(o).__qualname__}>>").encode('utf-8'))


def main(port=80, mongodb_port=27017, server_class=HTTPServer):
  server_address = ('', port)
  handler_class = handler = partial(MongoDBHealthHandler, mongodb_port)
  httpd = server_class(server_address, handler_class)
  httpd.serve_forever()


if __name__ == "__main__":
  port = 8080 if not getenv('PORT') else int(getenv('PORT'))
  mongodb_port = 27017 if not getenv('MONGO_PORT') else int(
      getenv('MONGO_PORT'))
  main(port, mongodb_port)
