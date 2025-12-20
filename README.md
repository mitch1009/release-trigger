# Release Trigger Action

[![Release trigger Build Action](https://github.com/mitch1009/release-trigger/actions/workflows/release.yml/badge.svg)](https://github.com/mitch1009/release-trigger/actions/workflows/release.yml) 

## Description
This action automates the process of version release and manages build information. It supports signing commits and tags using GPG keys and integrates with GitHub CLI for pull request management.

## Inputs
- **gpg_private_key**: (required) GPG secret key for signing commits and tags.
- **gpg_passphrase**: (required) Passphrase for the GPG key.
- **git_user_email**: (required) Email for git commits.
- **git_username**: (required) Username for git commits.
- **git_token**: (required) GitHub token for accessing the GitHub API.
- **version_file_path**: (optional) Path to the version file. Auto-detected if not provided.
- **release_branch**: (required) Name of the release branch (e.g., `main`, `release`, `deploy`).
- **bump_script**: (optional) Custom script for version bumping. Language-specific defaults are used if not provided.
- **language**: (optional) Project language (`rust`, `python`, `js`, `ts`, or `auto`). Defaults to `auto` (auto-detection).
- **working_directory**: (optional) Working directory. Defaults to `.`.

## Outputs
- **release_version**: The version of the release.
- **pr_log**: Log of pull requests.

## Prerequisites

### JavaScript/TypeScript Projects
- [standard-version](https://github.com/conventional-changelog/standard-version) for versioning and release tagging (optional, action can use it automatically)

> You can setup an optional script in your `package.json` file that triggers release and tagging:
 ```json 
 "scripts": {
    "release": "standard-version --sign --tag-prefix {tagname}"
 }
 ```

### Rust Projects
- A `Cargo.toml` file with a `version` field in the `[package]` section
- Optional: [cargo-release](https://github.com/crate-ci/cargo-release) for advanced version management (will be installed automatically if needed)

### Python Projects
- One of the following version files:
  - `pyproject.toml` with `[project] version = "1.2.3"`
  - `setup.py` with `version="1.2.3"`
  - `setup.cfg` with `[metadata] version = 1.2.3`
  - `__version__.py` or `version.py` with `__version__ = "1.2.3"`
- Optional: [bump2version](https://github.com/c4urself/bump2version) for advanced version management (will be installed automatically if `.bumpversion.cfg` exists)

## Supported Languages And frameworks

- [x] **Javascript** - Full support with `package.json` and `standard-version`
- [x] **TypeScript** - Full support with `package.json` and `standard-version`
- [x] **pnpm monorepos** - Full support for JS/TS projects (React, Next.js, Solid.js, NestJS, Angular)
- [x] **Rust** - Full support with `Cargo.toml` and `cargo-release` (or manual version bumping)
- [x] **Python** - Full support with `pyproject.toml`, `setup.py`, `setup.cfg`, or `__version__.py`
- [ ] Flutter
- [ ] Java
- [ ] Go
- [ ] C#
## Usage

The action automatically detects your project language, but you can also specify it explicitly. The `version_file_path` is also auto-detected if not provided.

### Basic Usage (Auto-detection)

```yaml
steps:
  - name: Release Version
    uses: mitch1009/release-trigger@main
    with:
      gpg_private_key: ${{ secrets.GPG_SECRET }}
      gpg_passphrase: ${{ secrets.GPG_PASSPHRASE }}
      git_user_email: "your_email@example.com"
      git_username: "your_username"
      git_token: ${{ GITHUB_TOKEN }}
      release_branch: "main"
```

### Explicit Language Specification

```yaml
steps:
  - name: Release Version
    uses: mitch1009/release-trigger@main
    with:
      gpg_private_key: ${{ secrets.GPG_SECRET }}
      gpg_passphrase: ${{ secrets.GPG_PASSPHRASE }}
      git_user_email: "your_email@example.com"
      git_username: "your_username"
      git_token: ${{ GITHUB_TOKEN }}
      release_branch: "main"
      language: "rust"  # or "python", "js", "ts", "auto"
      version_file_path: "Cargo.toml"  # optional, auto-detected if not provided
```

## Example Workflows

### JavaScript/TypeScript Project

```yaml
name: Release Workflow
on:
  push:
    branches:
      - main
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      - name: Release Version
        uses: mitch1009/release-trigger@main
        with:
          gpg_private_key: ${{ secrets.GPG_SECRET }}
          gpg_passphrase: ${{ secrets.GPG_PASSPHRASE }}
          git_user_email: "your_email@example.com"
          git_username: "your_username"
          git_token: ${{ GITHUB_TOKEN }}
          release_branch: "main"
          # version_file_path and language are auto-detected
```

### Rust Project

```yaml
name: Release Workflow
on:
  push:
    branches:
      - main
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      - name: Release Version
        uses: mitch1009/release-trigger@main
        with:
          gpg_private_key: ${{ secrets.GPG_SECRET }}
          gpg_passphrase: ${{ secrets.GPG_PASSPHRASE }}
          git_user_email: "your_email@example.com"
          git_username: "your_username"
          git_token: ${{ GITHUB_TOKEN }}
          release_branch: "main"
          language: "rust"
          # version_file_path defaults to "Cargo.toml" if not specified
```

### Python Project

```yaml
name: Release Workflow
on:
  push:
    branches:
      - main
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      - name: Release Version
        uses: mitch1009/release-trigger@main
        with:
          gpg_private_key: ${{ secrets.GPG_SECRET }}
          gpg_passphrase: ${{ secrets.GPG_PASSPHRASE }}
          git_user_email: "your_email@example.com"
          git_username: "your_username"
          git_token: ${{ GITHUB_TOKEN }}
          release_branch: "main"
          language: "python"
          # version_file_path auto-detects: pyproject.toml, setup.py, setup.cfg, or __version__.py
```

### Custom Bump Script

You can also provide a custom bump script for any language:

```yaml
steps:
  - name: Release Version
    uses: mitch1009/release-trigger@main
    with:
      gpg_private_key: ${{ secrets.GPG_SECRET }}
      gpg_passphrase: ${{ secrets.GPG_PASSPHRASE }}
      git_user_email: "your_email@example.com"
      git_username: "your_username"
      git_token: ${{ GITHUB_TOKEN }}
      release_branch: "main"
      language: "rust"
      bump_script: "cargo release minor --execute --no-publish --no-push"
```

> Read more about software release guide [here](/release.md)

## License
This action is licensed under the MIT License.

