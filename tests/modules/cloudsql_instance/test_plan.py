# Copyright 2022 Google LLC
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

from collections import Counter


def test_simple_instance(plan_runner):
  "Test standalone instance."

  _, resources = plan_runner()
  assert len(resources) == 1
  r = resources[0]
  assert r['values']['project'] == 'my-project'
  assert r['values']['name'] == 'db'
  assert r['values']['region'] == 'europe-west1'


def test_prefix(plan_runner):
  "Test instance prefix."

  _, resources = plan_runner(prefix="prefix")
  assert len(resources) == 1
  r = resources[0]
  assert r['values']['name'] == 'prefix-db'

  replicas = """{
    replica1 = { region = "europe-west3", encryption_key_name = null }
    replica2 = { region = "us-central1", encryption_key_name = null }
  }"""

  _, resources = plan_runner(prefix="prefix")
  assert len(resources) == 1
  r = resources[0]
  assert r['values']['name'] == 'prefix-db'


def test_replicas(plan_runner):
  "Test replicated instance."

  replicas = """{
    replica1 = { region = "europe-west3", encryption_key_name = null }
    replica2 = { region = "us-central1", encryption_key_name = null }
  }"""

  _, resources = plan_runner(replicas=replicas, prefix="prefix")
  assert len(resources) == 3

  primary = [r for r in resources if r['name'] == 'primary'][0]
  replica1 = [
      r for r in resources
      if r['name'] == 'replicas' and r['index'] == 'replica1'
  ][0]
  replica2 = [
      r for r in resources
      if r['name'] == 'replicas' and r['index'] == 'replica2'
  ][0]

  assert replica1['values']['name'] == 'prefix-replica1'
  assert replica2['values']['name'] == 'prefix-replica2'

  assert replica1['values']['master_instance_name'] == 'prefix-db'
  assert replica2['values']['master_instance_name'] == 'prefix-db'

  assert replica1['values']['region'] == 'europe-west3'
  assert replica2['values']['region'] == 'us-central1'


def test_mysql_replicas_enables_backup(plan_runner):
  "Test MySQL backup setup with replicas."

  replicas = """{
    replica1 = { region = "europe-west3", encryption_key_name = null }
  }"""
  _, resources = plan_runner(replicas=replicas, database_version="MYSQL_8_0")
  assert len(resources) == 2
  primary = [r for r in resources if r['name'] == 'primary'][0]
  backup_config = primary['values']['settings'][0]['backup_configuration'][0]
  assert backup_config['enabled']
  assert backup_config['binary_log_enabled']


def test_mysql_binary_log_for_regional(plan_runner):
  "Test that the binary log will be enabled for regional MySQL DBs."

  _, resources = plan_runner(database_version="MYSQL_8_0", availability_type="REGIONAL")
  assert len(resources) == 1
  primary = [r for r in resources if r['name'] == 'primary'][0]
  backup_config = primary['values']['settings'][0]['backup_configuration'][0]
  assert backup_config['enabled']
  assert backup_config['binary_log_enabled']


def test_users(plan_runner):
  "Test user creation."

  users = """{
    user1 = "123"
    user2 = null
  }"""

  _, resources = plan_runner(users=users)
  types = Counter(r['type'] for r in resources)
  assert types == {
      'google_sql_user': 2,
      'google_sql_database_instance': 1,
      'random_password': 1
  }


def test_databases(plan_runner):
  "Test database creation."

  databases = '["db1", "db2"]'
  _, resources = plan_runner(databases=databases)

  resources = [r for r in resources if r['type'] == 'google_sql_database']
  assert len(resources) == 2
  assert all(r['values']['instance'] == "db" for r in resources)
  assert sorted(r['values']['name'] for r in resources) == ["db1", "db2"]


def test_simple_instance_ipv4_enable(plan_runner):
  "Test instance ipv4_enabled."

  _, resources = plan_runner(ipv4_enabled="true")
  assert len(resources) == 1 
  assert resources[0]['values']['settings'][0]['ip_configuration'][0]['ipv4_enabled']


def test_replicas_ipv4_enable(plan_runner):
  "Test replicas ipv4_enabled."

  replicas = """{
    replica1 = { region = "europe-west3", encryption_key_name = null }
  }"""

  _, resources = plan_runner(replicas=replicas, ipv4_enabled="true")
  
  assert len(resources) == 2
  assert all([r['values']['settings'][0]['ip_configuration'][0]['ipv4_enabled'] for r in resources])
  
