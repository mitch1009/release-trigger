#!/bin/bash

# Script to parse ISSUES.md and create GitHub issues
# Usage: ./parse-issues.sh <issues_file> <github_token> <repo_owner> <repo_name>

set -euo pipefail

ISSUES_FILE="${1:-}"
GITHUB_TOKEN="${2:-}"
REPO_OWNER="${3:-}"
REPO_NAME="${4:-}"

if [ -z "$ISSUES_FILE" ] || [ -z "$GITHUB_TOKEN" ] || [ -z "$REPO_OWNER" ] || [ -z "$REPO_NAME" ]; then
  echo "Usage: $0 <issues_file> <github_token> <repo_owner> <repo_name>"
  exit 1
fi

if [ ! -f "$ISSUES_FILE" ]; then
  echo "Error: Issues file not found: $ISSUES_FILE"
  exit 1
fi

REPO="$REPO_OWNER/$REPO_NAME"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Parsing ISSUES.md and creating GitHub issues...${NC}"
echo -e "${BLUE}Repository: $REPO${NC}"
echo -e "${BLUE}========================================${NC}"

# Extract milestone title
MILESTONE_TITLE=$(grep -E "^## Milestone:" "$ISSUES_FILE" | sed 's/^## Milestone: //' | head -n 1 | xargs)

if [ -z "$MILESTONE_TITLE" ]; then
  echo -e "${YELLOW}Warning: No milestone title found${NC}"
  MILESTONE_NUMBER=""
else
  echo -e "${GREEN}Found milestone: $MILESTONE_TITLE${NC}"
  
  # Check if milestone exists
  MILESTONE_NUMBER=$(gh api "repos/$REPO/milestones" --jq ".[] | select(.title == \"$MILESTONE_TITLE\") | .number" 2>/dev/null || echo "")
  
  if [ -z "$MILESTONE_NUMBER" ]; then
    echo -e "${YELLOW}Creating milestone: $MILESTONE_TITLE${NC}"
    MILESTONE_NUMBER=$(gh api "repos/$REPO/milestones" \
      -X POST \
      -f title="$MILESTONE_TITLE" \
      -f state="open" \
      --jq '.number' 2>/dev/null || echo "")
    
    if [ -n "$MILESTONE_NUMBER" ]; then
      echo -e "${GREEN}✓ Created milestone #$MILESTONE_NUMBER: $MILESTONE_TITLE${NC}"
    else
      echo -e "${RED}✗ Failed to create milestone${NC}"
      MILESTONE_NUMBER=""
    fi
  else
    echo -e "${GREEN}✓ Milestone already exists: #$MILESTONE_NUMBER${NC}"
  fi
fi

echo ""

# Function to extract issue content
extract_issue_section() {
  local issue_num=$1
  local file=$2
  
  awk -v issue_num="$issue_num" '
    BEGIN { 
      in_issue = 0
      issue_found = 0
      content = ""
    }
    /^## Issue #/ {
      # Check if this is the issue we're looking for
      if ($0 ~ "^## Issue #" issue_num ":") {
        in_issue = 1
        issue_found = 1
        content = $0 "\n"
        next
      }
      # If we were in an issue and hit a new one, stop
      if (in_issue && issue_found) {
        exit
      }
      in_issue = 0
    }
    /^---$/ {
      # Stop at horizontal rule if we've found our issue
      if (in_issue && issue_found) {
        exit
      }
    }
    in_issue && issue_found {
      content = content $0 "\n"
    }
    END {
      if (issue_found) {
        print content
      }
    }
  ' "$file"
}

# Function to create GitHub issue
create_issue() {
  local issue_num=$1
  local title="$2"
  local body="$3"
  local milestone_num="${4:-}"
  
  # Escape title for search
  ESCAPED_TITLE=$(echo "$title" | sed 's/"/\\"/g')
  
  # Check if issue already exists (search by title pattern)
  EXISTING_ISSUE=$(gh issue list --repo "$REPO" \
    --search "in:title \"Issue #$issue_num\"" \
    --json number,title \
    --jq ".[] | select(.title | contains(\"$title\")) | .number" 2>/dev/null | head -n 1 || echo "")
  
  if [ -n "$EXISTING_ISSUE" ]; then
    echo -e "${YELLOW}⚠ Issue #$EXISTING_ISSUE already exists: $title${NC}"
    
    # Update milestone if provided
    if [ -n "$milestone_num" ] && [ -n "$EXISTING_ISSUE" ]; then
      gh issue edit "$EXISTING_ISSUE" --repo "$REPO" --milestone "$milestone_num" 2>/dev/null || true
      echo -e "${GREEN}  ✓ Updated milestone for issue #$EXISTING_ISSUE${NC}"
    fi
    
    # Add labels if missing (ignore errors if labels don't exist)
    gh issue edit "$EXISTING_ISSUE" --repo "$REPO" --add-label "enhancement,automated,multi-language" 2>/dev/null || true
    
    return 0
  fi
  
  # Create the issue
  echo -e "${BLUE}Creating issue #$issue_num: $title${NC}"
  
  # Prepare body file (GitHub CLI has issues with complex bodies)
  TEMP_BODY=$(mktemp)
  echo -e "$body" > "$TEMP_BODY"
  
  # Try to create with labels, fallback without if labels don't exist
  ISSUE_NUMBER=$(gh issue create \
    --repo "$REPO" \
    --title "Issue #$issue_num: $title" \
    --body-file "$TEMP_BODY" \
    ${milestone_num:+--milestone "$milestone_num"} \
    --label "enhancement,automated,multi-language" \
    --json number \
    --jq '.number' 2>/dev/null || \
    gh issue create \
      --repo "$REPO" \
      --title "Issue #$issue_num: $title" \
      --body-file "$TEMP_BODY" \
      ${milestone_num:+--milestone "$milestone_num"} \
      --json number \
      --jq '.number' 2>/dev/null || echo "")
  
  rm -f "$TEMP_BODY"
  
  if [ -n "$ISSUE_NUMBER" ]; then
    echo -e "${GREEN}✓ Created issue #$ISSUE_NUMBER: $title${NC}"
    return 0
  else
    echo -e "${RED}✗ Failed to create issue: $title${NC}"
    return 1
  fi
}

# Parse and create issues
ISSUE_NUM=1
CREATED_COUNT=0
EXISTING_COUNT=0
FAILED_COUNT=0

echo -e "${BLUE}Starting issue parsing...${NC}\n"

while true; do
  # Extract issue section
  ISSUE_CONTENT=$(extract_issue_section "$ISSUE_NUM" "$ISSUES_FILE")
  
  if [ -z "$ISSUE_CONTENT" ]; then
    break
  fi
  
  # Extract title (line starting with "## Issue #X:")
  TITLE=$(echo "$ISSUE_CONTENT" | grep -E "^## Issue #" | sed -E 's/^## Issue #[0-9]+: //' | head -n 1 | xargs)
  
  if [ -z "$TITLE" ]; then
    ISSUE_NUM=$((ISSUE_NUM + 1))
    continue
  fi
  
  # Extract description (between "### Description" and next ### section or ---)
  DESCRIPTION=$(echo "$ISSUE_CONTENT" | awk '
    BEGIN { in_desc = 0; desc = "" }
    /^### Description/ { 
      in_desc = 1
      next
    }
    /^### (Tasks|Acceptance Criteria|Implementation Order|Notes|Success Criteria)/ { 
      if (in_desc) exit
    }
    /^---$/ {
      if (in_desc) exit
    }
    in_desc && NF > 0 {
      if (desc != "") desc = desc "\n"
      desc = desc $0
    }
    END { print desc }
  ')
  
  # Extract tasks
  TASKS=$(echo "$ISSUE_CONTENT" | awk '
    BEGIN { in_tasks = 0; tasks = "" }
    /^### Tasks/ { 
      in_tasks = 1
      next
    }
    /^### (Acceptance Criteria|Implementation Order|Notes|Success Criteria)/ { 
      if (in_tasks) exit
    }
    /^---$/ {
      if (in_tasks) exit
    }
    in_tasks {
      if (tasks != "") tasks = tasks "\n"
      tasks = tasks $0
    }
    END { print tasks }
  ')
  
  # Extract acceptance criteria
  ACCEPTANCE=$(echo "$ISSUE_CONTENT" | awk '
    BEGIN { in_acc = 0; acc = "" }
    /^### Acceptance Criteria/ { 
      in_acc = 1
      next
    }
    /^### (Implementation Order|Notes|Success Criteria)|^---$/ { 
      if (in_acc) exit
    }
    in_acc {
      if (acc != "") acc = acc "\n"
      acc = acc $0
    }
    END { print acc }
  ')
  
  # Build issue body
  BODY="## Description\n\n$DESCRIPTION\n\n"
  
  if [ -n "$TASKS" ] && [ "$TASKS" != "" ]; then
    BODY="$BODY### Tasks\n\n$TASKS\n\n"
  fi
  
  if [ -n "$ACCEPTANCE" ] && [ "$ACCEPTANCE" != "" ]; then
    BODY="$BODY### Acceptance Criteria\n\n$ACCEPTANCE\n\n"
  fi
  
  BODY="$BODY---\n\n*This issue was automatically created from [ISSUES.md](.github/ISSUES.md)*"
  
  # Create the issue
  if create_issue "$ISSUE_NUM" "$TITLE" "$BODY" "$MILESTONE_NUMBER"; then
    if gh issue list --repo "$REPO" --search "in:title \"Issue #$ISSUE_NUM\"" --json number --jq '.[0].number' 2>/dev/null | grep -q "$ISSUE_NUM"; then
      CREATED_COUNT=$((CREATED_COUNT + 1))
    else
      EXISTING_COUNT=$((EXISTING_COUNT + 1))
    fi
  else
    FAILED_COUNT=$((FAILED_COUNT + 1))
  fi
  
  echo ""
  ISSUE_NUM=$((ISSUE_NUM + 1))
done

echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Summary:${NC}"
echo -e "  ${GREEN}✓ Created: $CREATED_COUNT issues${NC}"
echo -e "  ${YELLOW}⚠ Existing: $EXISTING_COUNT issues${NC}"
if [ "$FAILED_COUNT" -gt 0 ]; then
  echo -e "  ${RED}✗ Failed: $FAILED_COUNT issues${NC}"
fi
echo -e "  ${BLUE}Total processed: $((ISSUE_NUM - 1)) issues${NC}"
echo -e "${BLUE}========================================${NC}"

if [ "$FAILED_COUNT" -gt 0 ]; then
  exit 1
fi

