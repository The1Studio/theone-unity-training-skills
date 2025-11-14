# GitHub API Reference for PR Reviews

## GitHub CLI Commands

### Viewing Pull Requests

```bash
# View PR details (JSON format)
gh pr view <NUMBER> --repo <OWNER/REPO> --json title,body,state,author

# View PR with all fields
gh pr view <NUMBER> --repo <OWNER/REPO> --json title,body,files,commits,reviews,comments

# Get PR diff
gh pr diff <NUMBER> --repo <OWNER/REPO>

# Get specific file diff
gh pr diff <NUMBER> --repo <OWNER/REPO> -- path/to/file.cs

# List PR files
gh pr view <NUMBER> --repo <OWNER/REPO> --json files --jq '.files[].path'

# Get latest commit ID
gh pr view <NUMBER> --repo <OWNER/REPO> --json commits --jq '.commits[-1].oid'
```

### Creating Comments

```bash
# Add general PR comment
gh pr comment <NUMBER> --repo <OWNER/REPO> --body "Comment text"

# Add comment from file
gh pr comment <NUMBER> --repo <OWNER/REPO> --body-file comment.md

# Add review comment
gh pr review <NUMBER> --repo <OWNER/REPO> --comment --body "Review text"

# Approve PR
gh pr review <NUMBER> --repo <OWNER/REPO> --approve

# Request changes
gh pr review <NUMBER> --repo <OWNER/REPO> --request-changes --body "Changes needed"
```

## GitHub REST API

### Base URL

```
https://api.github.com
```

### Authentication

```bash
# GitHub CLI handles authentication automatically
# For direct API calls, use GitHub token
-H "Authorization: Bearer $GITHUB_TOKEN"
```

### Create Review Comment (Inline Suggestion)

**Endpoint:**
```
POST /repos/{owner}/{repo}/pulls/{pull_number}/comments
```

**Required Headers:**
```bash
-H "Accept: application/vnd.github+json"
-H "X-GitHub-Api-Version: 2022-11-28"
```

**Required Parameters:**
- `body` (string) - Comment text with suggestion block
- `commit_id` (string) - SHA of commit to comment on
- `path` (string) - Relative path of file to comment on
- `position` (integer) - Position in diff (NOT file line number)

**Optional Parameters:**
- `line` (integer) - Line number in file (for single-line comments)
- `start_line` (integer) - First line of multi-line comment
- `start_side` (string) - "LEFT" or "RIGHT" for diff side

**Example:**

```bash
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  /repos/The1Studio/TheOneFeature/pulls/984/comments \
  -f body='Add `#nullable enable` directive.

```suggestion
#nullable enable

namespace MyNamespace
```' \
  -f commit_id="f25ac9db59e51a684a5b2ac13a82b3ed1d96501d" \
  -f path="Core/Features/Gacha/Scripts/Controllers/GachaDataController.cs" \
  -F position=1
```

**Response:**
```json
{
  "id": 2525730158,
  "node_id": "PRRC_kwDOM7VKWc6Wi5Vu",
  "pull_request_review_id": 3462753277,
  "path": "Core/Features/Gacha/Scripts/Controllers/GachaDataController.cs",
  "position": 1,
  "line": 1,
  "body": "Add `#nullable enable` directive.\n\n```suggestion\n#nullable enable\n\nnamespace MyNamespace\n```",
  "commit_id": "f25ac9db59e51a684a5b2ac13a82b3ed1d96501d",
  "user": {
    "login": "tuha263",
    "id": 9598614
  },
  "created_at": "2025-11-14T04:48:05Z",
  "updated_at": "2025-11-14T04:48:05Z",
  "html_url": "https://github.com/The1Studio/TheOneFeature/pull/984#discussion_r2525730158"
}
```

### Update Review Comment

**Endpoint:**
```
PATCH /repos/{owner}/{repo}/pulls/comments/{comment_id}
```

**Parameters:**
- `body` (string) - Updated comment text

**Example:**

```bash
gh api \
  --method PATCH \
  -H "Accept: application/vnd.github+json" \
  /repos/The1Studio/TheOneFeature/pulls/comments/2525730158 \
  -f body='Updated suggestion text

```suggestion
#nullable enable

namespace UpdatedNamespace
```'
```

### Delete Review Comment

**Endpoint:**
```
DELETE /repos/{owner}/{repo}/pulls/comments/{comment_id}
```

**Example:**

```bash
gh api \
  --method DELETE \
  -H "Accept: application/vnd.github+json" \
  /repos/The1Studio/TheOneFeature/pulls/comments/2525730158
```

### List Review Comments

**Endpoint:**
```
GET /repos/{owner}/{repo}/pulls/{pull_number}/comments
```

**Example:**

```bash
gh api \
  -H "Accept: application/vnd.github+json" \
  /repos/The1Studio/TheOneFeature/pulls/984/comments
```

### Create PR Review

**Endpoint:**
```
POST /repos/{owner}/{repo}/pulls/{pull_number}/reviews
```

**Parameters:**
- `commit_id` (string) - SHA of commit to review
- `body` (string) - Review summary comment
- `event` (string) - "APPROVE", "REQUEST_CHANGES", "COMMENT"
- `comments` (array) - Array of review comments

**Example:**

```bash
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  /repos/The1Studio/TheOneFeature/pulls/984/reviews \
  -f commit_id="f25ac9db59e51a684a5b2ac13a82b3ed1d96501d" \
  -f body="Review complete with suggestions" \
  -f event="COMMENT"
```

## Position Calculation

**Critical:** `position` is the line number in the DIFF, not the file.

### Understanding Diff Position

```diff
@@ -0,0 +1,10 @@              # Hunk header (not counted)
+#nullable enable             # position: 1
+                             # position: 2
+namespace MyNamespace        # position: 3
+{                            # position: 4
+    public class Foo         # position: 5
+    {                        # position: 6
+        // ...               # position: 7
+    }                        # position: 8
+}                            # position: 9
                             # position: 10 (if blank line)
```

### Calculate Position Programmatically

```bash
# Get diff and count to target line
gh pr diff $PR_NUMBER --repo $REPO | \
  awk -v file="$FILE_PATH" -v target="$SEARCH_TEXT" '
    /^diff --git/ { in_file = 0 }
    $0 ~ file { in_file = 1; pos = 0 }
    in_file && /^@@/ { pos = 0; next }
    in_file && /^[+ -]/ { pos++ }
    in_file && $0 ~ target { print pos; exit }
  '
```

### Multi-Line Comments

For multi-line suggestions spanning lines 5-10:

```bash
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  /repos/$REPO/pulls/$PR_NUMBER/comments \
  -f body='Multi-line suggestion

```suggestion
    public sealed class MyClass
    {
        private readonly IService service;

        public MyClass(IService service)
        {
            this.service = service;
        }
    }
```' \
  -f commit_id="$COMMIT_ID" \
  -f path="$FILE_PATH" \
  -F position=5 \
  -F line=10 \
  -F start_line=5
```

## Suggestion Markdown Syntax

### Basic Suggestion

````markdown
```suggestion
code to replace the highlighted lines
```
````

### Multi-Line Suggestion

````markdown
```suggestion
first line
second line
third line
```
````

### Suggestion with Context

````markdown
Add `sealed` keyword to prevent inheritance.

```suggestion
public sealed class MyClass
```

**Reference:** [C# Best Practices](link)
````

## Rate Limiting

GitHub API rate limits:
- **Authenticated:** 5,000 requests per hour
- **Unauthenticated:** 60 requests per hour

Check rate limit:

```bash
gh api /rate_limit
```

## Error Responses

### 404 Not Found

**Cause:** Invalid PR number, repo, or comment ID

```json
{
  "message": "Not Found",
  "documentation_url": "https://docs.github.com/rest"
}
```

### 422 Unprocessable Entity

**Cause:** Invalid position, missing required fields

```json
{
  "message": "Validation Failed",
  "errors": [
    {
      "resource": "PullRequestReviewComment",
      "code": "invalid",
      "field": "position"
    }
  ]
}
```

### 403 Forbidden

**Cause:** Insufficient permissions or rate limit

```json
{
  "message": "Resource not accessible by integration",
  "documentation_url": "https://docs.github.com/rest"
}
```

## Best Practices

### 1. Batch API Calls

```bash
# Bad: Multiple separate calls
for file in "${FILES[@]}"; do
  gh api POST /repos/$REPO/pulls/$PR/comments -f body="..." -f path="$file"
done

# Good: Prepare all data, then call once per file
for file in "${FILES[@]}"; do
  SUGGESTIONS[$file]=$(prepare_suggestion "$file")
done

for file in "${!SUGGESTIONS[@]}"; do
  gh api POST /repos/$REPO/pulls/$PR/comments \
    -f body="${SUGGESTIONS[$file]}" \
    -f path="$file" \
    -F position=$(calculate_position "$file")
done
```

### 2. Error Handling

```bash
if gh api POST /repos/$REPO/pulls/$PR/comments \
  -f body="$BODY" \
  -f commit_id="$COMMIT" \
  -f path="$PATH" \
  -F position=$POS 2>&1; then
  echo "✅ Suggestion added"
else
  echo "❌ Failed to add suggestion"
  exit 1
fi
```

### 3. Validate Before Posting

```bash
# Validate PR exists
gh pr view $PR_NUMBER --repo $REPO > /dev/null 2>&1 || {
  echo "Error: PR not found"
  exit 1
}

# Validate file exists in PR
gh pr diff $PR_NUMBER --repo $REPO | grep -q "$FILE_PATH" || {
  echo "Error: File not in PR"
  exit 1
}

# Then create suggestion
gh api POST ...
```

## Complete Example Script

```bash
#!/bin/bash
# create-pr-suggestions.sh

set -e

PR_NUMBER=$1
REPO=$2
FILE_PATH=$3
SUGGESTION=$4
POSITION=$5

# Validate inputs
if [ -z "$PR_NUMBER" ] || [ -z "$REPO" ] || [ -z "$FILE_PATH" ] || [ -z "$SUGGESTION" ] || [ -z "$POSITION" ]; then
  echo "Usage: $0 <PR_NUMBER> <REPO> <FILE_PATH> <SUGGESTION> <POSITION>"
  exit 1
fi

# Get commit ID
COMMIT_ID=$(gh pr view $PR_NUMBER --repo $REPO --json commits --jq '.commits[-1].oid')

if [ -z "$COMMIT_ID" ]; then
  echo "Error: Could not get commit ID"
  exit 1
fi

# Create suggestion
RESPONSE=$(gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  /repos/$REPO/pulls/$PR_NUMBER/comments \
  -f body="$SUGGESTION" \
  -f commit_id="$COMMIT_ID" \
  -f path="$FILE_PATH" \
  -F position=$POSITION)

# Extract comment URL
COMMENT_URL=$(echo "$RESPONSE" | jq -r '.html_url')

echo "✅ Suggestion created: $COMMENT_URL"
```

**Usage:**

```bash
./create-pr-suggestions.sh 984 "The1Studio/TheOneFeature" \
  "Core/Features/Gacha/Scripts/Controllers/GachaDataController.cs" \
  "Add \`#nullable enable\` directive.

\`\`\`suggestion
#nullable enable

namespace TheOneFeature.Core.Features.Gacha.Scripts.Controllers
\`\`\`" \
  1
```
