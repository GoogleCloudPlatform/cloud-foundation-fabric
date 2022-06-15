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


def test_no_prefix_suffix(apply_runner):
    _, output = apply_runner()
    assert output["names"]["project"]["tf"] == "cloud-dev-tf"
    assert output["names"]["bucket"]["tf-org"] == "cloud-dev-tf-org"
    assert output["labels"]["project"]["tf"] == {
        "environment": "dev",
        "scope": "global",
        "team": "cloud",
    }
    assert output["labels"]["bucket"]["tf-org"] == {
        "environment": "dev",
        "team": "cloud",
    }


def test_prefix(apply_runner):
    _, output = apply_runner(prefix="myco")
    assert output["names"]["project"]["tf"] == "myco-cloud-dev-tf"
    assert output["names"]["bucket"]["tf-org"] == "myco-cloud-dev-tf-org"


def test_suffix(apply_runner):
    _, output = apply_runner(suffix="myco")
    assert output["names"]["project"]["tf"] == "cloud-dev-tf-myco"
    assert output["names"]["bucket"]["tf-org"] == "cloud-dev-tf-org-myco"


def test_resource_prefix(apply_runner):
    _, output = apply_runner(prefix="myco", use_resource_prefixes="true")
    assert output["names"]["project"]["tf"] == "project-myco-cloud-dev-tf"
    assert output["names"]["bucket"]["tf-org"] == "bucket-myco-cloud-dev-tf-org"


def test_separator(apply_runner):
    _, output = apply_runner(separator_override='{ dataset = "_" }')
    assert output["names"]["dataset"] == {
        "foobar": "cloud_dev_foobar",
        "frobniz": "cloud_dev_frobniz",
    }
