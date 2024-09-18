# Release Trigger Action



## Description
This action automates the process of version release and manages build information. It supports signing commits and tags using GPG keys and integrates with GitHub CLI for pull request management.

## Inputs
- **gpg_private_key**: (required) GPG secret key for signing commits and tags.
- **gpg_passphrase**: (required) Passphrase for the GPG key.
- **git_user_email**: (required) Email for git commits.
- **git_username**: (required) Username for git commits.
- **git_token**: (required) GitHub token for accessing the GitHub API.
- **version_file_path**: (required) Path to the version file.

## Outputs
- **release_version**: The version of the release.
- **pr_log**: Log of pull requests.

## Prerequisites
Please mae sure you have installed the following libraries in your project - either in monorepo or standalone

- [standard-version](https://github.com/conventional-changelog/standard-version) for versioning and release taging

> You should also setup an optional script in your `package.json` file that trigers release and taging. i.e
 ```json 
 "scripts": {
    "release": "standard-version --sign --tag-prefix {tagname}"
 }
 ```

## Supported Languages And frameworks
> please note that support for other framworks and languages will be implemented in the funture or uport request

- [x] Javascript
- [x] Typescript
- [x] pnpm monorepos (with JS and typescript projects - React, Nextjs, Solidjs, NestJs, Angular)
- [ ] Flutter
- [ ] Python 
- [ ] Java
- [ ] Rust
## Usage
To use this action in your workflow, include the following in your YAML file:

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
     version_file_path: "path/to/version/file"
     release_branch: "your_release_branch" # i.e deploy, release etc
```
## Example Workflow
Here’s an example of how to set up a workflow that uses this action:

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
      uses: actions/checkout@v2
    - name: Release Version
      uses: mitch1009/release-trigger@main
      with:
        gpg_private_key: ${{ secrets.GPG_SECRET }}
        gpg_passphrase: ${{ secrets.GPG_PASSPHRASE }}
        git_user_email: "your_email@example.com"
        git_username: "your_username"
        git_token: ${{ GITHUB_TOKEN }}
        version_file_path: "path/to/version/file"
```

> Read more about software release guide [here](/release.md)

## License
This action is licensed under the MIT License.

