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


def test_folder(plan_runner):
    "Test folder resources."
    _, resources = plan_runner()
    assert len(resources) == 1
    resource = resources[0]
    assert resource["type"] == "google_folder"
    assert resource["values"]["display_name"] == "folder-a"
    assert resource["values"]["parent"] == "organizations/12345678"


def test_iam(plan_runner):
    "Test IAM."
    group_iam = (
        "{"
        '"owners@example.org" = ["roles/owner", "roles/resourcemanager.folderAdmin"],'
        '"viewers@example.org" = ["roles/viewer"]'
        "}"
    )
    iam = (
        "{"
        '"roles/owner" = ["user:one@example.org", "user:two@example.org"],'
        '"roles/browser" = ["domain:example.org"]'
        "}"
    )
    _, resources = plan_runner(group_iam=group_iam, iam=iam)
    roles = sorted(
        [
            (r["values"]["role"], sorted(r["values"]["members"]))
            for r in resources
            if r["type"] == "google_folder_iam_binding"
        ]
    )
    assert roles == [
        ("roles/browser", ["domain:example.org"]),
        (
            "roles/owner",
            [
                "group:owners@example.org",
                "user:one@example.org",
                "user:two@example.org",
            ],
        ),
        ("roles/resourcemanager.folderAdmin", ["group:owners@example.org"]),
        ("roles/viewer", ["group:viewers@example.org"]),
    ]


def test_iam_multiple_roles(plan_runner):
    "Test folder resources with multiple iam roles."
    iam = (
        "{ "
        '"roles/owner" = ["user:a@b.com"], '
        '"roles/viewer" = ["user:c@d.com"] '
        "} "
    )
    _, resources = plan_runner(iam=iam)
    assert len(resources) == 3


def test_iam_additive_members(plan_runner):
    "Test IAM additive members."
    iam = (
        '{"user:one@example.org" = ["roles/owner"],'
        '"user:two@example.org" = ["roles/owner", "roles/editor"]}'
    )
    _, resources = plan_runner(iam_additive_members=iam)
    roles = set(
        (r["values"]["role"], r["values"]["member"])
        for r in resources
        if r["type"] == "google_folder_iam_member"
    )
    assert roles == set(
        [
            ("roles/owner", "user:one@example.org"),
            ("roles/owner", "user:two@example.org"),
            ("roles/editor", "user:two@example.org"),
        ]
    )
