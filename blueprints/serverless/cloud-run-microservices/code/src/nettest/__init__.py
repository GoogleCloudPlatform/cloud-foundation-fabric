# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import flask
import logging
import subprocess
import base64
import sys
import re
iphostregex = re.compile(
  r'([A-Z0-9][A-Z0-9-]{0,61}\.)*[A-Z0-9][A-Z0-9-]{0,61}',
  re.IGNORECASE)
urlregex = re.compile(
        r'^https?://' # http:// or https://
        r'(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+(?:[A-Z]{2,6}\.?|[A-Z0-9-]{2,}\.?)|' #domain...
        r'localhost|' #localhost...
        r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})' # ...or ip
        r'(?::\d+)?' # optional port
        r'(?:/?|[/?]\S+)$', re.IGNORECASE)

logger = logging.getLogger()
logger.setLevel(logging.DEBUG)

# If `entrypoint` is not defined in app.yaml, App Engine will look for an app
# called `app` in `main.py`.
app = flask.Flask(__name__)

@app.route('/http')
def dohttp():
  url = flask.request.args.get('url')
  if re.match(urlregex, url) is None:
    return 'Invalid URL'
  logging.info("Entering DoHTTP")
  logging.info("---- Invoking cURL ----")
  process = subprocess.Popen(['/bin/sh', '-c', 'curl --silent --verbose '+url+' 2>&1'],
                             stdout=subprocess.PIPE)
  output = process.stdout.read().decode('utf-8')
  logging.info(output)
  rc = process.wait()
  logging.info('Subprocess Returned:'+ str(rc))
  resp = flask.Response()
  resp.headers['Content-Type'] = 'text/plain; charset=utf-8'
  resp.data = 'curl --silent --verbose '+url+'\n\n'+output
  return resp

@app.route('/ping')
def doping():
  host = flask.request.args.get('host')
  if re.match(iphostregex, host) is None:
    return 'Invalid Host'
  logging.info("Entering DoPing")
  logging.info("---- Invoking Ping "+host+" ----")
  process = subprocess.Popen(['/bin/sh', '-c', 'ping -c 4 '+host+' 2>&1'],
                             stdout=subprocess.PIPE)
  output = process.stdout.read().decode('utf-8')
  logging.info(output)
  rc = process.wait()
  logging.info('Subprocess Returned:'+ str(rc))
  resp = flask.Response()
  resp.headers['Content-Type'] = 'text/plain'
  resp.data = output
  return resp

@app.route('/iperf')
def doiperf():
  host = flask.request.args.get('host')
  if re.match(iphostregex, host) is None:
    return 'Invalid Host'
  rev = flask.request.args.get('reverse')
  nodelay = flask.request.args.get('nodelay')
  udp = flask.request.args.get('udp')
  bandwidth = flask.request.args.get('bandwidth')
  plen = flask.request.args.get('plen')
  npackets = flask.request.args.get('npackets')
  streams = flask.request.args.get('streams')
  port = flask.request.args.get('port')
  time = flask.request.args.get('time')
  args = ''
  if rev is not None:
    args = args + ' -R'
  if nodelay is not None:
    args = args + ' -N'
  if udp is not None:
    args = args + ' -u'
  if bandwidth is not None:
    ibandwidth = int(bandwidth)
    if ibandwidth > 0:
      args = args + ' -b '+str(ibandwidth)+'M'
  if plen is not None:
    iplen = int(plen)
    if iplen > 0:
      args = args + ' -l '+str(iplen)
  if npackets is not None:
    args = args + ' -k '+str(npackets)
  if streams is not None:
    istreams = int(streams)
    if istreams > 0:
      args = args + ' -P '+str(istreams)
  if port is not None:
    iport = int(port)
    if iport > 0:
      args = args + ' -p '+str(iport)
  if time is not None:
    itime = int(time)
    if itime > 0:
      args = args + ' -t '+str(itime)
  logging.info("---- Invoking iperf3 -c "+host+args+" ----")
  process = subprocess.Popen(['/bin/sh', '-c', 'iperf3 -c '+host+args+' 2>&1'],
                             stdout=subprocess.PIPE)
  output = process.stdout.read().decode('utf-8')
  logging.info(output)
  rc = process.wait()
  logging.info('Subprocess Returned:'+ str(rc))
  resp = flask.Response()
  resp.headers['Content-Type'] = 'text/plain'
  resp.data = output
  return resp

@app.route('/dns')
def dodns():
  host = flask.request.args.get('host')
  if re.match(iphostregex, host) is None:
    return 'Invalid Host'
  logging.info("Entering DoDns")
  logging.info("---- Invoking nslookup "+host+" ----")
  process = subprocess.Popen(['/bin/sh', '-c', 'dig '+host+' 2>&1'],
                             stdout=subprocess.PIPE)
  output = process.stdout.read().decode('utf-8')
  logging.info(output)
  rc = process.wait()
  logging.info('Subprocess Returned:'+ str(rc))
  resp = flask.Response()
  resp.headers['Content-Type'] = 'text/plain'
  resp.data = output
  return resp

@app.route('/')
def domain():
  resp = flask.Response()
  resp.headers['Content-Type'] = 'text/html'
  resp.data = (
    '<!doctype html>'
    '<html>'
    '<body>'
    '<p><form action="/dns" method="get">'
    'DNS Lookup: <input name="host" type="text"> '
    '<input type="submit" value="DNS">'
    '</form></p>'
    '<p><form action="/ping" method="get">'
    'Ping Host: <input name="host" type="text"> '
    '<input type="submit" value="Ping">'
    '</form></p>'
    '<p><form action="/http" method="get">'
    'HTTP URL: <input name="url" type="text"> '
    '<input type="submit" value="GET">'
    '</form></p>'
    '<p><form action="/iperf" method="get">'
    'IPerf to Host: <input name="host" type="text"> '
    '<input type="submit" value="IPerf">'
    '</form></p>'
    '</body>'
    '</html>'
  )
  return resp

def create_app(test_config=None):
  return app
