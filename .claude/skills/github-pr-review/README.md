# GitHub PR Review Skill

## Overview

This skill provides comprehensive GitHub pull request reviews with **actionable inline suggestions** that can be applied directly through GitHub's web UI.

## Auto-Trigger Conditions

This skill should **automatically activate** when:

- User provides a GitHub PR URL (e.g., `https://github.com/owner/repo/pull/123`)
- User asks to "review PR", "review pull request", "check PR"
- User requests code review with applicable suggestions
- User mentions PR number with review context

## Quick Start

### Example Usage

```
User: "Review this PR: https://github.com/The1Studio/TheOneFeature/pull/984"

Claude: [Activates github-pr-review skill]
1. Fetches PR details and diff
2. Activates theone-unity-standards for code analysis
3. Identifies 6 issues (3 critical, 2 important, 1 suggestion)
4. Creates 6 inline suggestions using GitHub API
5. Adds summary comment explaining how to apply

Result: Developer sees "Commit suggestion" buttons on each issue in Files Changed tab
```

## Features

### ✅ What This Skill Does

1. **Fetch PR Details**
   - Gets PR title, body, files, commits
   - Retrieves full diff for analysis

2. **Analyze Code**
   - Integrates with `theone-unity-standards` for Unity projects
   - Categorizes issues by severity (Critical, Important, Nice to Have)
   - Identifies file-specific and line-specific issues

3. **Create Inline Suggestions**
   - Uses GitHub API to create review comments
   - Formats suggestions with ````suggestion` blocks
   - Positions suggestions at exact diff locations

4. **Enable One-Click Fixes**
   - Developer clicks "Commit suggestion" in GitHub UI
   - Changes apply automatically to PR branch
   - Can batch multiple suggestions into one commit

### 🎯 Suggestion Types

#### Single-Line Suggestions

```markdown
Add `sealed` keyword.

\`\`\`suggestion
public sealed class MyClass
\`\`\`
```

#### Multi-Line Suggestions

```markdown
Fix class body with multiple issues.

\`\`\`suggestion
public sealed class MyClass
{
    private readonly IService service;

    public MyClass(IService service)
    {
        this.service = service;
    }
}
\`\`\`
```

#### Complete File Replacements

For major refactoring, provides complete fixed file in collapsible section.

## Usage Examples

### Example 1: Unity C# PR Review

```bash
# User provides PR URL
User: "Review https://github.com/The1Studio/TheOneFeature/pull/984"

# Skill workflow:
1. Fetch PR: gh pr view 984 --repo The1Studio/TheOneFeature
2. Analyze: Use theone-unity-standards skill
3. Create suggestions: 6 inline comments with ````suggestion` blocks
4. Summary: Explain how to apply suggestions

# Developer applies:
- Go to Files Changed tab
- Click "Commit suggestion" on each
- Or "Add suggestion to batch" → "Commit suggestions" (all at once)
```

### Example 2: Quick File Review

```bash
# User asks for specific file review
User: "Check the logging in UserService.cs on PR #456"

# Skill workflow:
1. Fetch PR diff, filter to UserService.cs
2. Identify logging issues
3. Create targeted suggestions
4. Explain fixes

# Result:
- Inline suggestions for each logging issue
- References to TheOne.Logging.ILogger documentation
```

## Integration with Other Skills

### theone-unity-standards

For Unity C# code reviews:

```bash
1. github-pr-review fetches PR
2. theone-unity-standards analyzes code
3. github-pr-review creates suggestions from issues found
4. Summary includes links to theone-unity-standards references
```

### code-reviewer

For general code quality:

```bash
1. github-pr-review fetches PR
2. code-reviewer analyzes code patterns
3. github-pr-review creates suggestions
4. Non-fixable issues documented as discussion points
```

## Technical Implementation

### GitHub API Usage

```bash
# 1. Get latest commit ID
COMMIT_ID=$(gh pr view $PR --repo $REPO --json commits --jq '.commits[-1].oid')

# 2. Create inline suggestion
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  /repos/$REPO/pulls/$PR/comments \
  -f body='Add \`#nullable enable\` directive.

\`\`\`suggestion
#nullable enable

namespace MyNamespace
\`\`\`' \
  -f commit_id="$COMMIT_ID" \
  -f path="path/to/file.cs" \
  -F position=1

# 3. Add summary comment
gh pr comment $PR --repo $REPO --body "## ✅ Suggestions Ready
..."
```

### Position Calculation

**Important:** `position` is the diff line number, NOT file line number.

```diff
@@ -0,0 +1,10 @@
+namespace MyNamespace    # position: 1
+{                        # position: 2
+    public class Foo     # position: 3
```

## Files in This Skill

```
.claude/skills/github-pr-review/
├── SKILL.md                           # Main skill documentation
├── README.md                          # This file
└── references/
    ├── workflow-examples.md           # Complete workflow examples
    └── api-reference.md               # GitHub API reference
```

## Quick Reference

### Common Issues & Suggestions

| Issue | Suggestion Template |
|-------|---------------------|
| Missing `#nullable enable` | Add directive at line 1 |
| Missing `sealed` keyword | Add to class declaration |
| Public fields | Convert to properties |
| `#region` comments | Remove regions, keep code only |
| Debug.Log in runtime | Use TheOne.Logging.ILogger |
| Constructor logging | Remove logs from constructor |
| `logger?.Method()` | Use `logger.Method()` directly |

### Bash Helper Functions

```bash
# Get PR diff position for pattern
get_position() {
  local pr=$1 repo=$2 file=$3 pattern=$4
  gh pr diff $pr --repo $repo | \
    awk -v file="$file" -v pat="$pattern" '
      /^diff --git/ && $0 ~ file { found=1; pos=0 }
      found && /^@@/ { pos=0; next }
      found && /^[+ ]/ { pos++; if ($0 ~ pat) { print pos; exit } }
    '
}

# Create suggestion at position
create_suggestion() {
  local pr=$1 repo=$2 file=$3 pos=$4 body=$5
  local commit=$(gh pr view $pr --repo $repo --json commits --jq '.commits[-1].oid')

  gh api POST /repos/$repo/pulls/$pr/comments \
    -f body="$body" \
    -f commit_id="$commit" \
    -f path="$file" \
    -F position=$pos
}
```

## Troubleshooting

### Issue: Suggestion doesn't show "Commit suggestion" button

**Solution:** Check ````suggestion` syntax:
- Three backticks
- Word "suggestion" (lowercase)
- Proper indentation inside block

### Issue: "404 Not Found" when creating suggestion

**Solution:** Verify:
- PR exists and is open
- File path is correct
- Position is valid diff position

### Issue: Suggestion applies but breaks code

**Solution:**
- Match exact indentation
- Include enough context
- Test locally first

## Best Practices

### ✅ DO:

1. **Use for fixable issues only**
   - Syntax errors, missing keywords
   - Simple refactoring, formatting

2. **Group related changes**
   - Combine `#nullable enable` + `sealed` together
   - Fix entire method/class body at once

3. **Provide context**
   - Explain WHY the change is needed
   - Link to coding standards

4. **Test suggestions**
   - Verify position is correct
   - Check indentation matches

### ❌ DON'T:

1. **Don't suggest for architectural issues**
   - Use regular comments for discussion
   - Suggest design pattern changes separately

2. **Don't create overlapping suggestions**
   - Each should apply independently
   - Avoid same lines multiple times

3. **Don't suggest without explanation**
   - Always include reasoning
   - Reference documentation

## Future Enhancements

- [ ] Auto-detect position from file line number
- [ ] Batch creation of multiple suggestions
- [ ] Template library for common fixes
- [ ] Integration with CI/CD for auto-suggestions
- [ ] Support for other languages beyond C#

## References

- [GitHub Suggested Changes Documentation](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/commenting-on-a-pull-request)
- [GitHub REST API - Pull Request Review Comments](https://docs.github.com/en/rest/pulls/comments)
- [TheOne Studio Unity Standards](../theone-unity-standards/SKILL.md)

---

**Last Updated:** 2025-11-14
**Version:** 1.0.0
**Author:** The1Studio
