# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import logging
import os
from locust import HttpUser, LoadTestShape, task, between


class TestUser(HttpUser):

    host = os.getenv("URL", "http://nginx.sample.svc.cluster.local")

    wait_time = between(int(os.getenv('MIN_WAIT_TIME', 1)),
                        int(os.getenv('MAX_WAIT_TIME', 2)))

    @task
    def home(self):
        with self.client.get("/", catch_response=True) as response:
            if response.status_code == 200:
                response.success()
            else:
                logging.info('Response code is ' + str(response.status_code))


class CustomLoadShape(LoadTestShape):

    stages = []

    num_stages = int(os.getenv('NUM_STAGES', 20))
    stage_duration = int(os.getenv('STAGE_DURATION', 60))
    spawn_rate = int(os.getenv('SPAWN_RATE', 1))
    new_users_per_stage = int(os.getenv('NEW_USERS_PER_STAGE', 10))

    for i in range(1, num_stages + 1):
        stages.append({
            'duration': stage_duration * i,
            'users': new_users_per_stage * i,
            'spawn_rate': spawn_rate
        })

    for i in range(1, num_stages):
        stages.append({
            'duration': stage_duration * (num_stages + i),
            'users': new_users_per_stage * (num_stages - i),
            'spawn_rate': spawn_rate
        })

    def tick(self):
        run_time = self.get_run_time()
        for stage in self.stages:
            if run_time < stage['duration']:
                tick_data = (stage['users'], stage['spawn_rate'])
                return tick_data
        return None
