---
name: release-process
description: Guide for cutting a new release of the Cloud Foundation Fabric (CFF) repository. Use this skill when asked to create, prepare, or draft a new release.
---

# Cloud Foundation Fabric Release Process

This skill guides maintainers through the process of cutting a new release for the Cloud Foundation Fabric (CFF) repository.

> **CRITICAL:** Release names and tags MUST ALWAYS be prefixed with `v` (e.g., `v55.1.0`, `v56.0.0`).

## Prerequisites

- **Permissions:** You must have write/release permissions on the repository.
- **GitHub Token:** A valid GitHub token (can be easily derived by running `gh auth token`).
- **Environment:** You can run the tools using either `uv` (recommended) or a standard Python virtual environment with `tools/requirements.txt` installed.

## 1. Preparation

Start from the `master` branch and ensure you are up to date:

```bash
git checkout master
git pull
```

Identify the **latest released version** by extracting it from the `default-versions.tf` file:

```bash
LATEST_RELEASE=$(grep -oP '(?<=# Fabric release: ).*' default-versions.tf)
echo "Latest release is: $LATEST_RELEASE"
```

## 2. Generate and Review Changelog

Run the changelog script, specifying the bump type (e.g., `major`, `minor`, `patch`):

```bash
# Set your bump type here (major, minor, or patch)
BUMP_TYPE="minor"

# Option A: Using uv (Recommended)
uv run tools/changelog.py --release-from $LATEST_RELEASE --bump $BUMP_TYPE --write --token $(gh auth token)

# Option B: Using a standard virtual environment
./tools/changelog.py --release-from $LATEST_RELEASE --bump $BUMP_TYPE --write --token $(gh auth token)
```

**Review the changes:**
Run `git diff CHANGELOG.md` and carefully inspect the output. Look for:
- PRs missing labels (they will appear under a "no subsection" or similar area).
- Weird or unclear names in PR titles.

**If you find issues:**
1. Click the PR link in the diff.
2. Manually fix the labels or title on GitHub.
3. Re-run the `changelog.py` command above.
4. Repeat until the changelog is clean.

## 3. Bump Versions

Once the changelog is correct, extract the newly generated release version from the top of the changelog and bump the repository versions:

```bash
NEW_RELEASE=$(grep -oP '(?<=^## \[).*(?=\] - )' CHANGELOG.md | head -n 1)
# Ensure it has the 'v' prefix
if [[ $NEW_RELEASE != v* ]]; then NEW_RELEASE="v$NEW_RELEASE"; fi
echo "New release is: $NEW_RELEASE"

# Option A: Using uv (Recommended)
uv run tools/versions.py --fabric-release $NEW_RELEASE --write-defaults

# Option B: Using a standard virtual environment
./tools/versions.py --fabric-release $NEW_RELEASE --write-defaults
```

## 4. Commit and Push

Commit the prepared release files and push to `master`:

```bash
git add CHANGELOG.md default-versions.tf
git commit -m "prep $NEW_RELEASE"
git push origin master
```

**Important:** Wait for the GitHub Actions workflows on `master` to finish successfully before proceeding to the next step. You can monitor the progress directly from your terminal:

```bash
# Watch the latest workflow run on the master branch
gh run watch $(gh run list --branch master --limit 1 --json databaseId -q '.[0].databaseId')
```

## 5. Create the GitHub Release

You can create the release either automatically via the GitHub CLI or manually via the GitHub UI.

### Option A: Automated via GitHub CLI (Recommended)

This script extracts any "BREAKING CHANGES" from the changelog and converts the heading to Title Case.

```bash
# 1. Extract the section for the new release from CHANGELOG.md
# We use awk to grab everything from the new release header until the next release header
RELEASE_NOTES=$(awk "/^## \[v$NEW_RELEASE\]/{flag=1; next} /^## \[v/{flag=0} flag" CHANGELOG.md)

# 2. Extract just the BREAKING CHANGES section (if any)
BREAKING_CHANGES=$(echo "$RELEASE_NOTES" | awk '/^### BREAKING CHANGES/{flag=1; print; next} /^### /{flag=0} flag')

# 3. Format breaking changes
if [ -n "$(echo "$BREAKING_CHANGES" | tr -d '[:space:]')" ]; then
  # Convert "### BREAKING CHANGES" to "### Breaking Changes"
  FORMATTED_BREAKING_CHANGES=$(echo "$BREAKING_CHANGES" | sed 's/^### BREAKING CHANGES/### Breaking Changes/')
  echo "$FORMATTED_BREAKING_CHANGES"
fi
```

> **CRITICAL:** Show the extracted and formatted breaking changes to the user and wait for their approval before proceeding to create the release.

Once approved, run the appropriate command to create the release.

If there were breaking changes:
```bash
gh release create "$NEW_RELEASE" --title "$NEW_RELEASE" --generate-notes --notes "$FORMATTED_BREAKING_CHANGES"
```

If there were no breaking changes:
```bash
gh release create "$NEW_RELEASE" --title "$NEW_RELEASE" --generate-notes
```

### Option B: Manual via GitHub UI

Go to the [GitHub Releases UI](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/releases/new) and configure the release:

1. **Tag:** Create a new tag matching the new version (e.g., `v56.0.0`).
2. **Title:** Use the exact same version string as the tag.
3. **Release Notes:** Click the **"Generate release notes"** button.
4. **Breaking Changes:** If the `CHANGELOG.md` contains a "BREAKING CHANGES" section for this release, copy it, paste it at the **top** of the generated release notes, and change the heading to "Breaking Changes".

Click **Publish release**.
