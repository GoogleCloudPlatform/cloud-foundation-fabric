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
import logging
import subprocess
import base64
import sys
import re
import streamlit as st
import numpy as np
import pandas as pd
import plotly.express as px

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

def dohttp(http_input):
  if re.match(urlregex, http_input) is None:
    st.error('Invalid URL')
  else:
    st.info("Running curl")
    
    process = subprocess.Popen(['curl', '--silent', '--verbose', http_input], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = process.communicate()

    if stderr:
        st.code(stderr.decode('utf-8'), language='bash')

    st.code(stdout.decode('utf-8'), language='bash')
    st.write('Subprocess Returned:', process.returncode)

def parse_data(data, regex_expr):
    data_matches = re.findall(regex_expr, data)
    data_arr = np.array(data_matches, dtype=float)
    return data_arr

def plot_generic(data, x_label, y_label):
    fig = px.bar(x=np.arange(1, len(data) + 1), y=data)
    fig.update_layout(xaxis_title=x_label)
    fig.update_layout(yaxis_title=y_label)
    st.plotly_chart(fig)

def doping(host):
  if re.match(iphostregex, host) is None:
    return 'Invalid Host'
  logging.info("Entering DoPing")
  logging.info("---- Invoking Ping "+host+" ----")
  process = subprocess.Popen(['/bin/sh', '-c', 'ping -c 10 '+host+' 2>&1'],
                             stdout=subprocess.PIPE)
  st.info(f"Running ping")

  output = process.stdout.read().decode('utf-8')
  logging.info(output)

  rc = process.wait()
  logging.info('Subprocess Returned:'+ str(rc))
  st.markdown('#### Ping output')
  st.code(output, language='bash')
  regex_expr = r"time=(\d+\.\d+) ms"
  ping_data = parse_data(output, regex_expr)
  try:
    plot_generic(ping_data,"Ping Attempt", "Ping Time (ms)")
  except:
    st.info("No data to plot")
def doiperf(iperf_input):
  input_parts = iperf_input.split()
  host = input_parts[0] if input_parts else ""
  args = input_parts[1:] if len(input_parts) > 1 else []
  if re.match(iphostregex, host):
    command = f"iperf3 -c {host} {' '.join(args)}"
    st.info(f"Running {command} ...")
    try:
        process = subprocess.Popen(
            ["/bin/sh", "-c", command],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        output = process.stdout.read().decode('utf-8')
        iperf_regex = r"(\d+(?:\.\d+)?)\s*(?:[KMG]?bits/sec)"
        iperf_data = parse_data(output, iperf_regex)
        regex_pattern_units = r"(\s+[a-zA-Z]+/[a-zA-Z]+)"
        result = re.search(regex_pattern_units, output)
        if result: 
          result = result.group(1)
          st.code(output, language='bash')
          plot_generic(iperf_data, "Sec interval ", f"Bitrate {result}")
        else:
          st.error('Host not found or iperf not enabled on server')

    except Exception as e:
      st.error(f"Error: {str(e)}")




def dodns(dns_input):
  st.title("DNS Lookup")
  if re.match(iphostregex, dns_input) is None:
      st.write('Invalid Host')
  else:
      st.info("running dig command...")
      try:
          process = subprocess.Popen(['dig', dns_input], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
          stdout, stderr = process.communicate()
          if stderr:
              st.write(stderr.decode('utf-8'))
          st.code(stdout.decode('utf-8'), language='bash')
          st.write('Subprocess Returned:', process.returncode)
      except Exception as e:
        st.error(f"Error: {str(e)}")

def create_app(test_config=None):
  return app

def main(): 
  st.markdown('# VPC Network Tester')
  col1, col2 = st.columns(2)
  with col1:
    ping_input = st.text_input('Ping to Host', '10.0.1.4')
    http_input = st.text_input('HTTP Test', 'http://10.0.1.4')
    iperf_input = st.text_input('IPerf to Host', '10.0.1.4')
    dns_input = st.text_input('DNS Lookup', '10.0.1.4')

  with col2:
    st.text("")
    st.text("")
    button_ping = st.button('Ping')
    st.text("")
    st.text("")
    button_http = st.button('GET')
    st.text("")
    st.text("")
    st.text("")
    button_iperf = st.button('IPerf')
    st.text("")
    button_dns = st.button('DNS Lookup')
 
  if button_ping:
    doping(ping_input)
  if button_iperf:
    doiperf(iperf_input)
  if button_http: 
    dohttp(http_input)
  if button_dns:
    dodns(dns_input)


if __name__ == '__main__':
  main()