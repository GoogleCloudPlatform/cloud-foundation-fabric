# Copyright 2019 Google LLC
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

from flask import Flask, request

app = Flask(__name__)


@app.route('/', methods=['GET'])
def hello():
    return "Running"


@app.route('/handle_webhook', methods=['POST'])
def handle_webhook():

    req = request.get_json()

    print(req)

    # You can also use the google.cloud.dialogflowcx_v3.types.WebhookRequest protos instead of manually writing the json object
    # Please see https://googleapis.dev/python/dialogflow/latest/dialogflow_v2/types.html?highlight=webhookresponse#google.cloud.dialogflow_v2.types.WebhookResponse for an overview
    res = {
        "fulfillment_response": {
            "messages": [
                {
                    "text": {
                        "text": ['This answer is coming from the webhook!']
                    }
                }
            ]
        }
    }

    # Returns json
    return res


if __name__ == '__main__':
    # This is used when running locally, only to verify it does not have
    # significant errors. It cannot demonstrate restricting access using
    # Identity-Aware Proxy when run locally, only when deployed.
    #
    # When deploying to Google App Engine, a webserver process such as
    # Gunicorn will serve the app. This can be configured by adding an
    # `entrypoint` to app.yaml.
    app.run(host='127.0.0.1', port=8080, debug=True)