# GitHub PR Review Workflow Examples

## Example 1: Unity C# Code Review

### Scenario
User provides a Unity C# PR that needs review against TheOne Studio standards.

### Workflow

```bash
# Step 1: User provides PR
# User: "Review this PR: https://github.com/The1Studio/TheOneFeature/pull/984"

# Step 2: Fetch PR details
gh pr view 984 --repo The1Studio/TheOneFeature --json title,body,files,commits
gh pr diff 984 --repo The1Studio/TheOneFeature

# Step 3: Activate theone-unity-standards skill for analysis
# Skill analyzes code and identifies issues:
# - Missing #nullable enable (3 files)
# - Missing sealed keyword (3 files)
# - Public fields instead of properties
# - #region comments usage

# Step 4: Create suggestions
COMMIT_ID=$(gh pr view 984 --repo The1Studio/TheOneFeature --json commits --jq '.commits[-1].oid')

# Suggestion 1: Add nullable to GachaDataController.cs
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  /repos/The1Studio/TheOneFeature/pulls/984/comments \
  -f body='Add `#nullable enable` directive at the top of the file.

```suggestion
#nullable enable

namespace TheOneFeature.Core.Features.Gacha.Scripts.Controllers
```' \
  -f commit_id="$COMMIT_ID" \
  -f path="Core/Features/Gacha/Scripts/Controllers/GachaDataController.cs" \
  -F position=1

# Suggestion 2: Fix class body in GachaDataController.cs
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  /repos/The1Studio/TheOneFeature/pulls/984/comments \
  -f body='Remove `#region` comments and fix `sealed` keyword, property naming, and access modifier.

```suggestion
    public sealed class GachaDataController : IInitializable
    {
        private readonly UserDataManager userDataManager;

        public GachaDataController(UserDataManager userDataManager)
        {
            this.userDataManager = userDataManager;
        }

        private GachaLocalData GachaLocalData => this.userDataManager.Get<GachaLocalData>();

        public void Initialize()
        {
            // TODO: Add initialization logic
        }
    }
```' \
  -f commit_id="$COMMIT_ID" \
  -f path="Core/Features/Gacha/Scripts/Controllers/GachaDataController.cs" \
  -F position=7

# Step 5: Add summary comment
gh pr comment 984 --repo The1Studio/TheOneFeature --body "## ✅ Suggested Changes Ready

I've added 6 inline suggestions on the Files Changed tab.

**How to apply:**
1. Go to Files Changed tab
2. Click 'Commit suggestion' on each
3. Or use 'Add suggestion to batch' for all at once

**Issues resolved:**
- ✅ Nullable reference types enabled
- ✅ Sealed keywords added
- ✅ Regions removed
- ✅ Properties with proper naming"
```

## Example 2: Quick Single-File Review

### Scenario
User asks to review a single file change with specific issues.

### Workflow

```bash
# User: "Review the logging in UserService.cs on PR #123"

# Step 1: Get PR and focus on specific file
gh pr diff 123 --repo MyOrg/MyRepo | grep -A 50 "UserService.cs"

# Step 2: Identify issues
# - Using Debug.Log instead of ILogger
# - Logging in constructor
# - Using logger?.Method() with null-conditional

# Step 3: Create targeted suggestions
COMMIT_ID=$(gh pr view 123 --repo MyOrg/MyRepo --json commits --jq '.commits[-1].oid')

gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  /repos/MyOrg/MyRepo/pulls/123/comments \
  -f body='Use `TheOne.Logging.ILogger` instead of Debug.Log for runtime code.

```suggestion
        this.logger.Info("User service initialized");
```

**Why:** Debug.Log is only for editor scripts. Use TheOne.Logging.ILogger for runtime logging.' \
  -f commit_id="$COMMIT_ID" \
  -f path="Services/UserService.cs" \
  -F position=15
```

## Example 3: Batch Suggestions for Multiple Files

### Scenario
PR has same issue across multiple files.

### Workflow

```bash
# User: "Review PR #456 and fix all nullable warnings"

# Step 1: Analyze all files
FILES=(
  "Models/UserModel.cs"
  "Models/GameModel.cs"
  "Models/LevelModel.cs"
)

COMMIT_ID=$(gh pr view 456 --repo MyOrg/MyRepo --json commits --jq '.commits[-1].oid')

# Step 2: Create suggestion for each file
for file in "${FILES[@]}"; do
  gh api \
    --method POST \
    -H "Accept: application/vnd.github+json" \
    /repos/MyOrg/MyRepo/pulls/456/comments \
    -f body='Add `#nullable enable` directive.

```suggestion
#nullable enable

namespace $(echo $file | sed "s|/|.|g" | sed "s|.cs||")
```' \
    -f commit_id="$COMMIT_ID" \
    -f path="$file" \
    -F position=1
done

# Step 3: Inform about batch application
gh pr comment 456 --repo MyOrg/MyRepo --body "## 📦 Batch Suggestions Added

Added nullable directives to ${#FILES[@]} files.

**Quick apply:**
1. Go to Files Changed
2. Click 'Add suggestion to batch' on all suggestions
3. Click 'Commit suggestions' to apply all at once"
```

## Example 4: Complex Refactoring with Complete File

### Scenario
File needs major refactoring that's easier to show as complete replacement.

### Workflow

```bash
# User: "Review PR #789, the DI setup looks wrong"

# Step 1: Analyze and create fixed version
# (create complete fixed file content)

# Step 2: Add as suggestion with fallback
gh pr comment 789 --repo MyOrg/MyRepo --body "## Major Refactoring Needed

The DI container setup has several issues that require refactoring.

### Issues Found:
- Using Zenject instead of VContainer
- Field injection instead of constructor injection
- Missing IDisposable implementation

### Suggested Fix:

<details>
<summary>Click to expand: Complete fixed ServiceInstaller.cs</summary>

\`\`\`csharp
#nullable enable

namespace MyGame.DI
{
    using VContainer;
    using VContainer.Unity;

    public sealed class ServiceInstaller : LifetimeScope
    {
        protected override void Configure(IContainerBuilder builder)
        {
            builder.Register<UserService>(Lifetime.Singleton);
            builder.Register<GameService>(Lifetime.Singleton);
            builder.Register<LevelDataController>(Lifetime.Singleton);
        }
    }
}
\`\`\`
</details>

**Reference:** [VContainer Documentation](../theone-unity-standards/references/unity/vcontainer-di.md)"
```

## Example 5: Combining Standards Review with Suggestions

### Scenario
Full PR review with multiple skills.

### Workflow

```bash
# User: "Do a complete review of PR #999"

# Step 1: Activate theone-unity-standards for analysis
# (skill analyzes all code)

# Step 2: Categorize issues
# Critical: 3 issues
# Important: 5 issues
# Suggestions: 2 issues

# Step 3: Create suggestions for fixable issues
COMMIT_ID=$(gh pr view 999 --repo MyOrg/MyRepo --json commits --jq '.commits[-1].oid')

# Add suggestions for Critical issues
# (use suggestion blocks)

# Step 4: Add review comment for non-fixable issues
gh pr comment 999 --repo MyOrg/MyRepo --body "## 📋 Complete Review

### ✅ Fixable Issues (Suggestions Added)
I've added 8 inline suggestions for issues that can be fixed automatically.

### ⚠️ Issues Requiring Discussion

**Architecture:**
- [ ] Consider using Data Controllers instead of direct model access
- [ ] SignalBus usage could be simplified with fewer event types

**Performance:**
- [ ] LINQ in Update() loop (line 45) - recommend caching result

### 📖 References
- [Data Controllers Pattern](../theone-unity-standards/references/unity/data-controllers.md)
- [Performance Best Practices](../theone-unity-standards/references/csharp/performance-optimizations.md)"
```

## Example 6: Updating Existing Suggestion

### Scenario
Need to modify a suggestion that was already posted.

### Workflow

```bash
# Step 1: Get comment ID from previous suggestion
COMMENT_ID=2525730158

# Step 2: Update the suggestion
cat > /tmp/updated-suggestion.md << 'EOF'
Add `#nullable enable` and `sealed` keyword.

```suggestion
#nullable enable

namespace MyNamespace
{
    public sealed class MyClass
```
EOF

# Step 3: Update comment
gh api \
  --method PATCH \
  -H "Accept: application/vnd.github+json" \
  /repos/MyOrg/MyRepo/pulls/comments/$COMMENT_ID \
  -f body="$(cat /tmp/updated-suggestion.md)"
```

## Example 7: Error Handling and Validation

### Scenario
Ensure suggestions are valid before posting.

### Workflow

```bash
# Step 1: Validate PR exists
if ! gh pr view $PR_NUMBER --repo $REPO &> /dev/null; then
    echo "Error: PR #$PR_NUMBER not found"
    exit 1
fi

# Step 2: Get latest commit and validate
COMMIT_ID=$(gh pr view $PR_NUMBER --repo $REPO --json commits --jq '.commits[-1].oid')
if [ -z "$COMMIT_ID" ]; then
    echo "Error: Could not get commit ID"
    exit 1
fi

# Step 3: Validate file exists in PR
if ! gh pr diff $PR_NUMBER --repo $REPO | grep -q "$FILE_PATH"; then
    echo "Error: File $FILE_PATH not found in PR"
    exit 1
fi

# Step 4: Create suggestion with error handling
if gh api \
    --method POST \
    -H "Accept: application/vnd.github+json" \
    /repos/$REPO/pulls/$PR_NUMBER/comments \
    -f body="$SUGGESTION_BODY" \
    -f commit_id="$COMMIT_ID" \
    -f path="$FILE_PATH" \
    -F position=$POSITION; then
    echo "✅ Suggestion added successfully"
else
    echo "❌ Failed to add suggestion"
    exit 1
fi
```

## Template: Standard PR Review

```bash
#!/bin/bash
# pr-review.sh - Standard PR review template

PR_NUMBER=$1
REPO=$2

# Validate inputs
if [ -z "$PR_NUMBER" ] || [ -z "$REPO" ]; then
    echo "Usage: $0 <PR_NUMBER> <REPO>"
    exit 1
fi

# Get PR details
echo "📋 Fetching PR #$PR_NUMBER..."
gh pr view $PR_NUMBER --repo $REPO --json title,body,files

# Get commit ID
COMMIT_ID=$(gh pr view $PR_NUMBER --repo $REPO --json commits --jq '.commits[-1].oid')

# Analyze code (integrate with theone-unity-standards)
echo "🔍 Analyzing code..."
# ... analysis logic ...

# Create suggestions
echo "💡 Creating suggestions..."
# ... suggestion creation logic ...

# Add summary
echo "📝 Adding summary..."
gh pr comment $PR_NUMBER --repo $REPO --body "## ✅ Review Complete

Suggestions added: $SUGGESTION_COUNT
Issues found: $ISSUE_COUNT

Go to Files Changed tab to apply suggestions."

echo "✅ Review complete!"
```
