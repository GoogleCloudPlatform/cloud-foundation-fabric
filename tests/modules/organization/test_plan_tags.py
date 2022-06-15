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


def test_keys(plan_runner):
    "Test tag keys."
    tags = """{
    foo = null
    bar = {
      description = null
      iam         = null
      values      = null
    }
    foobar = {
      description = "Foobar tag."
      iam = {
        "roles/resourcemanager.tagAdmin" = [
          "user:user1@example.com", "user:user2@example.com"
        ]
      }
      values = {
        one = null
        two = {
          description = "Foobar 2."
          iam = {
            "roles/resourcemanager.tagViewer" = [
              "user:user3@example.com"
            ]
          }
        }
        three = {
          description = "Foobar 3."
          iam = {
            "roles/resourcemanager.tagViewer" = [
              "user:user3@example.com"
            ]
            "roles/resourcemanager.tagAdmin" = [
              "user:user4@example.com"
            ]
          }
        }
      }
    }
  }"""
    _, resources = plan_runner(tags=tags)
    assert len(resources) == 10
    resource_values = {}
    for r in resources:
        resource_values.setdefault(r["type"], []).append(r["values"])
    assert len(resource_values["google_tags_tag_key"]) == 3
    assert len(resource_values["google_tags_tag_value"]) == 3
    result = [r["role"] for r in resource_values["google_tags_tag_value_iam_binding"]]
    expected = [
        "roles/resourcemanager.tagAdmin",
        "roles/resourcemanager.tagViewer",
        "roles/resourcemanager.tagViewer",
    ]
    assert result == expected


def test_bindings(plan_runner):
    "Test tag bindings."
    tag_bindings = '{foo = "tagValues/123456789012"}'
    _, resources = plan_runner(tag_bindings=tag_bindings)
    assert len(resources) == 1
