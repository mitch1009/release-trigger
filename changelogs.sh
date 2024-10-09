#!/bin/bash

# Get the previous tag, defaulting to the initial commit if no tags exist
PREVIOUS_TAG=$(git describe --tags --abbrev=0 HEAD^ 2>/dev/null || git rev-list --max-parents=0 HEAD)

# Get the date of the previous tag
PREVIOUS_TAG_DATE=$(git log -1 --format=%aI $PREVIOUS_TAG)

# Fetch merged PRs since the previous tag
PR_LOG=$(gh pr list \
  --search "is:merged merged:>$PREVIOUS_TAG_DATE" \
  --json number,title,author,mergeCommit \
  --jq '
    [.[] | {
      number: .number,
      title: .title,
      author: .author.login,
      sha: .mergeCommit.oid
    }]
  '
)

# Function to get commits for a PR
get_pr_commits() {
  local pr_number=$1
  gh pr view $pr_number --json commits --jq '
    .commits | map("  - " + .messageHeadline) | join("\n")
  '
}

# Generate changelog
echo "Changes since $PREVIOUS_TAG:"
echo "$PR_LOG" | jq -c '.[]' | while read -r pr; do
  pr_number=$(echo $pr | jq -r '.number')
  pr_title=$(echo $pr | jq -r '.title')
  pr_author=$(echo $pr | jq -r '.author')
  pr_sha=$(echo $pr | jq -r '.sha')
  
  echo "- $pr_title (#$pr_number) by @$pr_author"
  commits=$(get_pr_commits $pr_number)
  echo "$commits"
done