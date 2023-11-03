wf_tmpl = """name: $NAME
on:
  workflow_dispatch:
$EVENT
defaults:
  run: { shell: bash }

jobs:
$PREBUILD
  build:
$NEEDS
    strategy:
      fail-fast: false
      matrix: { os: $OPERSYS }
    runs-on: ${{ matrix.os }}-latest
    steps:
    - uses: actions/checkout@v1
    - uses: actions/setup-python@v2
      with: {python-version: '3.8'}
    - name: Run script
      env:
$CONTEXTS
      run: |
$RUN
        python .github/scripts/build-$NAME.py
"""

pre_tmpl = """prebuild:
  runs-on: ubuntu-latest
  outputs:
    out: ${{ toJson(steps) }}
  steps:
  - uses: actions/checkout@v1
  - uses: actions/setup-python@v2
    with: {python-version: '3.8'}
  - name: Create release
    id: step1
    env:
      CONTEXT_GITHUB: ${{ toJson(github) }}
    run: |
      pip install -Uq ghapi
      python .github/scripts/prebuild.py
"""

context_example = """{
  "token": "***",
  "job": "build",
  "ref": "refs/heads/master",
  "sha": "4bd52759a74c8173301c39a45b9f7dbc3aa5a30c",
  "repository": "fastai/hugo-mathjax",
  "repository_owner": "fastai",
  "repositoryUrl": "git://github.com/fastai/hugo-mathjax.git",
  "run_id": "390437408",
  "run_number": "3",
  "retention_days": "90",
  "actor": "jph00",
  "workflow": "Python",
  "head_ref": "",
  "base_ref": "",
  "event_name": "workflow_dispatch",
  "event": {
    "inputs": null,
    "organization": {
      "avatar_url": "https://avatars3.githubusercontent.com/u/20547620?v=4",
      "description": null,
      "events_url": "https://api.github.com/orgs/fastai/events",
      "hooks_url": "https://api.github.com/orgs/fastai/hooks",
      "id": 20547620,
      "issues_url": "https://api.github.com/orgs/fastai/issues",
      "login": "fastai",
      "members_url": "https://api.github.com/orgs/fastai/members{/member}",
      "node_id": "MDEyOk9yZ2FuaXphdGlvbjIwNTQ3NjIw",
      "public_members_url": "https://api.github.com/orgs/fastai/public_members{/member}",
      "repos_url": "https://api.github.com/orgs/fastai/repos",
      "url": "https://api.github.com/orgs/fastai"
    },
    "ref": "refs/heads/master",
    "repository": {
      "archive_url": "https://api.github.com/repos/fastai/hugo-mathjax/{archive_format}{/ref}",
      "archived": false,
      "assignees_url": "https://api.github.com/repos/fastai/hugo-mathjax/assignees{/user}",
      "blobs_url": "https://api.github.com/repos/fastai/hugo-mathjax/git/blobs{/sha}",
      "branches_url": "https://api.github.com/repos/fastai/hugo-mathjax/branches{/branch}",
      "clone_url": "https://github.com/fastai/hugo-mathjax.git",
      "collaborators_url": "https://api.github.com/repos/fastai/hugo-mathjax/collaborators{/collaborator}",
      "comments_url": "https://api.github.com/repos/fastai/hugo-mathjax/comments{/number}",
      "commits_url": "https://api.github.com/repos/fastai/hugo-mathjax/commits{/sha}",
      "compare_url": "https://api.github.com/repos/fastai/hugo-mathjax/compare/{base}...{head}",
      "contents_url": "https://api.github.com/repos/fastai/hugo-mathjax/contents/{+path}",
      "contributors_url": "https://api.github.com/repos/fastai/hugo-mathjax/contributors",
      "created_at": "2020-11-11T18:59:57Z",
      "default_branch": "master",
      "deployments_url": "https://api.github.com/repos/fastai/hugo-mathjax/deployments",
      "description": "Hugo with goldmark-mathjax",
      "disabled": false,
      "downloads_url": "https://api.github.com/repos/fastai/hugo-mathjax/downloads",
      "events_url": "https://api.github.com/repos/fastai/hugo-mathjax/events",
      "fork": false,
      "forks": 0,
      "forks_count": 0,
      "forks_url": "https://api.github.com/repos/fastai/hugo-mathjax/forks",
      "full_name": "fastai/hugo-mathjax",
      "git_commits_url": "https://api.github.com/repos/fastai/hugo-mathjax/git/commits{/sha}",
      "git_refs_url": "https://api.github.com/repos/fastai/hugo-mathjax/git/refs{/sha}",
      "git_tags_url": "https://api.github.com/repos/fastai/hugo-mathjax/git/tags{/sha}",
      "git_url": "git://github.com/fastai/hugo-mathjax.git",
      "has_downloads": true,
      "has_issues": true,
      "has_pages": false,
      "has_projects": true,
      "has_wiki": true,
      "homepage": null,
      "hooks_url": "https://api.github.com/repos/fastai/hugo-mathjax/hooks",
      "html_url": "https://github.com/fastai/hugo-mathjax",
      "id": 312063075,
      "issue_comment_url": "https://api.github.com/repos/fastai/hugo-mathjax/issues/comments{/number}",
      "issue_events_url": "https://api.github.com/repos/fastai/hugo-mathjax/issues/events{/number}",
      "issues_url": "https://api.github.com/repos/fastai/hugo-mathjax/issues{/number}",
      "keys_url": "https://api.github.com/repos/fastai/hugo-mathjax/keys{/key_id}",
      "labels_url": "https://api.github.com/repos/fastai/hugo-mathjax/labels{/name}",
      "language": "Shell",
      "languages_url": "https://api.github.com/repos/fastai/hugo-mathjax/languages",
      "license": {
        "key": "apache-2.0",
        "name": "Apache License 2.0",
        "node_id": "MDc6TGljZW5zZTI=",
        "spdx_id": "Apache-2.0",
        "url": "https://api.github.com/licenses/apache-2.0"
      },
      "merges_url": "https://api.github.com/repos/fastai/hugo-mathjax/merges",
      "milestones_url": "https://api.github.com/repos/fastai/hugo-mathjax/milestones{/number}",
      "mirror_url": null,
      "name": "hugo-mathjax",
      "node_id": "MDEwOlJlcG9zaXRvcnkzMTIwNjMwNzU=",
      "notifications_url": "https://api.github.com/repos/fastai/hugo-mathjax/notifications{?since,all,participating}",
      "open_issues": 0,
      "open_issues_count": 0,
      "owner": {
        "avatar_url": "https://avatars3.githubusercontent.com/u/20547620?v=4",
        "events_url": "https://api.github.com/users/fastai/events{/privacy}",
        "followers_url": "https://api.github.com/users/fastai/followers",
        "following_url": "https://api.github.com/users/fastai/following{/other_user}",
        "gists_url": "https://api.github.com/users/fastai/gists{/gist_id}",
        "gravatar_id": "",
        "html_url": "https://github.com/fastai",
        "id": 20547620,
        "login": "fastai",
        "node_id": "MDEyOk9yZ2FuaXphdGlvbjIwNTQ3NjIw",
        "organizations_url": "https://api.github.com/users/fastai/orgs",
        "received_events_url": "https://api.github.com/users/fastai/received_events",
        "repos_url": "https://api.github.com/users/fastai/repos",
        "site_admin": false,
        "starred_url": "https://api.github.com/users/fastai/starred{/owner}{/repo}",
        "subscriptions_url": "https://api.github.com/users/fastai/subscriptions",
        "type": "Organization",
        "url": "https://api.github.com/users/fastai"
      },
      "private": false,
      "pulls_url": "https://api.github.com/repos/fastai/hugo-mathjax/pulls{/number}",
      "pushed_at": "2020-11-29T21:59:38Z",
      "releases_url": "https://api.github.com/repos/fastai/hugo-mathjax/releases{/id}",
      "size": 69,
      "ssh_url": "git@github.com:fastai/hugo-mathjax.git",
      "stargazers_count": 1,
      "stargazers_url": "https://api.github.com/repos/fastai/hugo-mathjax/stargazers",
      "statuses_url": "https://api.github.com/repos/fastai/hugo-mathjax/statuses/{sha}",
      "subscribers_url": "https://api.github.com/repos/fastai/hugo-mathjax/subscribers",
      "subscription_url": "https://api.github.com/repos/fastai/hugo-mathjax/subscription",
      "svn_url": "https://github.com/fastai/hugo-mathjax",
      "tags_url": "https://api.github.com/repos/fastai/hugo-mathjax/tags",
      "teams_url": "https://api.github.com/repos/fastai/hugo-mathjax/teams",
      "trees_url": "https://api.github.com/repos/fastai/hugo-mathjax/git/trees{/sha}",
      "updated_at": "2020-11-29T21:59:40Z",
      "url": "https://api.github.com/repos/fastai/hugo-mathjax",
      "watchers": 1,
      "watchers_count": 1
    },
    "sender": {
      "avatar_url": "https://avatars1.githubusercontent.com/u/346999?v=4",
      "events_url": "https://api.github.com/users/jph00/events{/privacy}",
      "followers_url": "https://api.github.com/users/jph00/followers",
      "following_url": "https://api.github.com/users/jph00/following{/other_user}",
      "gists_url": "https://api.github.com/users/jph00/gists{/gist_id}",
      "gravatar_id": "",
      "html_url": "https://github.com/jph00",
      "id": 346999,
      "login": "jph00",
      "node_id": "MDQ6VXNlcjM0Njk5OQ==",
      "organizations_url": "https://api.github.com/users/jph00/orgs",
      "received_events_url": "https://api.github.com/users/jph00/received_events",
      "repos_url": "https://api.github.com/users/jph00/repos",
      "site_admin": false,
      "starred_url": "https://api.github.com/users/jph00/starred{/owner}{/repo}",
      "subscriptions_url": "https://api.github.com/users/jph00/subscriptions",
      "type": "User",
      "url": "https://api.github.com/users/jph00"
    },
    "workflow": ".github/workflows/python.yml"
  },
  "server_url": "https://github.com",
  "api_url": "https://api.github.com",
  "graphql_url": "https://api.github.com/graphql",
  "workspace": "/home/runner/work/hugo-mathjax/hugo-mathjax",
  "action": "run",
  "event_path": "/home/runner/work/_temp/_github_workflow/event.json",
  "action_repository": "actions/setup-python",
  "action_ref": "v2",
  "path": "/home/runner/work/_temp/_runner_file_commands/add_path_d8387f6c-8c1b-44df-8a07-0c815679dd81",
  "env": "/home/runner/work/_temp/_runner_file_commands/set_env_d8387f6c-8c1b-44df-8a07-0c815679dd81"
}"""

needs_example = """{
  "prebuild": {
    "result": "success",
    "outputs": {
      "out": "{  \\"step1\\": {    \\"outputs\\": {      \\"tag\\": \\"v0.79.0\\"    },    \\"outcome\\": \\"success\\",    \\"conclusion\\": \\"success\\"  }}"
    }
  }
}"""

