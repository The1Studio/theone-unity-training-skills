# Contributing to TheOne Studio Unity Training Skills

Thank you for helping improve our Unity training skills! This guide will help you contribute effectively.

## Table of Contents
1. [Getting Started](#getting-started)
2. [How to Contribute](#how-to-contribute)
3. [Skill Development Process](#skill-development-process)
4. [Writing Good Skills](#writing-good-skills)
5. [Testing Your Changes](#testing-your-changes)
6. [Submission Guidelines](#submission-guidelines)
7. [Review Process](#review-process)

## Getting Started

### Prerequisites
- Git installed and configured
- Claude Code CLI installed
- Access to The1Studio GitHub organization
- Familiarity with Unity and C# development

### Fork and Clone
```bash
# 1. Fork the repository on GitHub (if you don't have write access)
# Or clone directly if you have write access:
git clone https://github.com/The1Studio/theone-unity-training-skills.git
cd theone-unity-training-skills

# 2. Create a new branch for your contribution
git checkout -b feature/improve-csharp-skill

# 3. Install skills locally for testing
cp -r .claude/skills ~/.claude/skills/
```

## How to Contribute

### Types of Contributions

#### 1. **Improve Existing Skills**
- Add more examples
- Clarify confusing patterns
- Fix errors or outdated information
- Add edge cases and common mistakes

#### 2. **Create New Skills**
- Company-specific patterns
- New technology integrations
- Advanced Unity features
- Performance optimization patterns

#### 3. **Add Training Examples**
- Hands-on exercises
- Before/after code samples
- Real-world scenarios
- Common pitfalls

#### 4. **Improve Documentation**
- README updates
- Installation guides
- Usage examples
- Best practices

## Skill Development Process

### Step 1: Identify the Need

**Ask yourself:**
- What pattern do engineers struggle with?
- What mistakes are repeated in code reviews?
- What new technology needs guidelines?
- What company standard isn't documented?

**Examples:**
- "Engineers keep using `GetComponent` in Update loop"
- "New hire doesn't understand when to use ScriptableObjects"
- "Team needs guidance on Unity UI Toolkit patterns"

### Step 2: Research and Document

**Gather information:**
```bash
# Study existing codebase
grep -r "pattern_name" /path/to/unity/projects/

# Check documentation
cat ~/.claude/theone-studio-patterns.md

# Review recent code reviews
gh pr list --state merged --limit 20
```

**Document findings:**
- Common patterns (good examples)
- Anti-patterns (what NOT to do)
- Edge cases and gotchas
- Performance considerations

### Step 3: Write the Skill

**Skill Structure Template:**
```markdown
# Skill Name

## Skill Purpose
[Clear, one-sentence description]

## When This Skill Triggers
- [Automatic trigger condition 1]
- [Automatic trigger condition 2]
- [Manual invocation scenario]

## Core Principles

### 1. Principle Name

#### ❌ AVOID: [What not to do]
\`\`\`csharp
// Bad example with explanation
\`\`\`

#### ✅ PREFERRED: [What to do instead]
\`\`\`csharp
// Good example with explanation
\`\`\`

### 2. Next Principle
[Continue pattern...]

## Summary
[Key takeaways checklist]
```

### Step 4: Add Real Examples

**From actual code:**
```bash
# Find real examples in your codebase
cd /path/to/unity/project
grep -A 10 "public class.*Service" **/*.cs > examples.txt
```

**Create before/after pairs:**
```markdown
### Example: Player Health System

#### ❌ Before (Common Mistake)
\`\`\`csharp
// From pull request #123 (before review)
public class Player : MonoBehaviour
{
    public int health = 100; // Public field, no encapsulation

    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            health -= 10; // Direct modification
        }
    }
}
\`\`\`

#### ✅ After (Skill-Corrected)
\`\`\`csharp
// After applying theone-unity-patterns
public class Player : MonoBehaviour
{
    private readonly PlayerDataController playerController;

    [Preserve]
    public Player(PlayerDataController playerController)
    {
        this.playerController = playerController;
    }

    private void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space))
        {
            this.playerController.TakeDamage(10);
        }
    }
}
\`\`\`

**Why this is better:**
- Uses Data Controller pattern
- Proper encapsulation
- Signals fired on data change
- Testable (can mock controller)
```

## Writing Good Skills

### Best Practices

#### 1. **Be Specific and Actionable**
```markdown
❌ Bad: "Use good naming conventions"
✅ Good: "Name services with 'Service' suffix (e.g., GameplayService, AnalyticService)"
```

#### 2. **Show, Don't Just Tell**
```markdown
❌ Bad: "Always unsubscribe from signals"
✅ Good:
### Signal Unsubscription

\`\`\`csharp
void IDisposable.Dispose()
{
    // ✅ Use TryUnsubscribe to avoid exceptions
    this.signalBus.TryUnsubscribe<WonSignal>(this.OnWon);
}
\`\`\`
```

#### 3. **Explain the "Why"**
```markdown
### Why Use Controllers?

❌ Direct data access breaks:
- Encapsulation (anyone can modify data)
- Validation (no business rules)
- Observability (no signals on changes)
- Testing (hard to mock)

✅ Controllers provide:
- Single source of truth
- Validation and business logic
- Event notifications
- Easy mocking for tests
```

#### 4. **Include Common Mistakes**
```markdown
### Common Mistakes to Avoid

1. **Forgetting to Unsubscribe**
   ```csharp
   // ❌ Memory leak - subscribed but never unsubscribed
   public class BadService : IInitializable
   {
       void IInitializable.Initialize()
       {
           signalBus.Subscribe<WonSignal>(OnWon);
           // Missing IDisposable!
       }
   }
   ```

2. **Using Zenject Instead of VContainer**
   ```csharp
   // ❌ WRONG - Zenject is deprecated
   [Inject] private SignalBus signalBus;

   // ✅ CORRECT - VContainer with constructor injection
   private readonly SignalBus signalBus;
   public MyService(SignalBus signalBus) { ... }
   ```
```

#### 5. **Provide Quick Reference**
```markdown
## Quick Reference Checklist

When implementing a service:
- [ ] Use VContainer (not Zenject)
- [ ] Constructor injection with [Preserve]
- [ ] Implement IInitializable for setup
- [ ] Implement IDisposable for cleanup
- [ ] Subscribe in Initialize()
- [ ] Unsubscribe in Dispose() with TryUnsubscribe
- [ ] Use Controllers for data access
```

## Testing Your Changes

### Local Testing

#### 1. **Install Your Modified Skill**
```bash
# Copy modified skill to Claude config
cp .claude/skills/theone-csharp-concise-coding.md ~/.claude/skills/

# Restart Claude Code
exit  # if in session
claude  # start new session
```

#### 2. **Test Skill Triggering**
```bash
# In Claude Code session, test if skill applies automatically:
"Implement a new Unity service for player inventory"

# Claude should automatically:
# - Use VContainer patterns
# - Apply concise C# code
# - Follow controller pattern
```

#### 3. **Test Explicit Invocation**
```bash
# Ask Claude to use the skill explicitly:
"Use theone-csharp-concise-coding skill to review this code:
[paste code]"

# Verify Claude applies the patterns correctly
```

#### 4. **Test with Real Scenarios**

Create a test Unity project:
```bash
# Create test directory
mkdir -p /tmp/skill-test
cd /tmp/skill-test

# Create test C# file
cat > BadCode.cs <<'EOF'
public class PlayerService
{
    public List<Player> players;

    public List<Player> GetActivePlayers()
    {
        List<Player> result = new List<Player>();
        foreach (var player in players)
        {
            if (player.IsActive)
            {
                result.Add(player);
            }
        }
        return result;
    }
}
EOF

# Ask Claude to refactor
claude
"Use theone-csharp-concise-coding to refactor BadCode.cs"
```

**Verify Claude outputs:**
```csharp
// Expected output with skill applied:
public class PlayerService
{
    private readonly List<Player> players;

    public IEnumerable<Player> GetActivePlayers() =>
        this.players.Where(p => p.IsActive);
}
```

### Testing Checklist

Before submitting, verify:
- [ ] Skill file is valid markdown
- [ ] Code examples compile (at least syntactically)
- [ ] Claude triggers skill automatically in relevant scenarios
- [ ] Claude applies patterns correctly when skill is invoked
- [ ] Examples are clear and educational
- [ ] No typos or grammar errors
- [ ] Links work (if any)

## Submission Guidelines

### Commit Messages

Follow conventional commits:
```bash
# Format: <type>(<scope>): <description>

# Examples:
git commit -m "feat(skill): add Unity UI Toolkit patterns to theone-unity-patterns"
git commit -m "fix(skill): correct VContainer registration example in theone-unity-patterns"
git commit -m "docs(skill): add more LINQ examples to theone-csharp-concise-coding"
git commit -m "refactor(skill): reorganize theone-code-review sections for clarity"
```

**Types:**
- `feat`: New skill or major addition
- `fix`: Fix incorrect information or examples
- `docs`: Documentation improvements
- `refactor`: Reorganize without changing content
- `test`: Add testing examples or scenarios
- `chore`: Maintenance tasks

### Pull Request Template

**Title Format:**
```
<type>: <brief description>

Examples:
feat: Add Unity Addressables skill
fix: Correct SignalBus unsubscribe example
docs: Improve installation instructions
```

**PR Description:**
```markdown
## Changes
[Describe what you changed and why]

## Type of Change
- [ ] New skill
- [ ] Improve existing skill
- [ ] Fix error/outdated info
- [ ] Documentation update

## Testing
- [ ] Tested locally with Claude Code
- [ ] Verified examples compile
- [ ] Checked against real Unity project

## Examples
[Include before/after if applicable]

## Related Issues
Fixes #123
Related to #456
```

### Branch Naming

```bash
# Format: <type>/<short-description>

# Examples:
git checkout -b feature/add-addressables-skill
git checkout -b fix/vcontainer-example
git checkout -b docs/improve-installation
git checkout -b improve/csharp-linq-examples
```

## Review Process

### What Reviewers Look For

#### 1. **Accuracy**
- Are examples correct and up-to-date?
- Do patterns follow TheOne Studio standards?
- Are there any misleading statements?

#### 2. **Clarity**
- Is the skill easy to understand?
- Are examples well-explained?
- Is the "why" clear, not just the "what"?

#### 3. **Completeness**
- Are edge cases covered?
- Are common mistakes documented?
- Are there enough examples?

#### 4. **Consistency**
- Does it match the style of other skills?
- Are naming conventions consistent?
- Is formatting uniform?

### Review Timeline

- **Initial Review:** Within 2 business days
- **Follow-up:** Within 1 business day
- **Merge:** After approval from 1+ senior engineers

### Addressing Review Feedback

```bash
# Make requested changes
nano .claude/skills/theone-unity-patterns.md

# Commit with reference to review
git add .
git commit -m "fix(skill): address review feedback - clarify SignalBus lifecycle

- Add more detail on when to subscribe/unsubscribe
- Include memory leak example
- Improve IDisposable explanation

Addresses feedback from @senior-engineer in PR #123"

# Push changes
git push origin feature/improve-unity-patterns
```

## Common Contribution Scenarios

### Scenario 1: Found a Mistake in a Skill

```bash
# 1. Create branch
git checkout -b fix/correct-vcontainer-lifetime

# 2. Fix the error
nano .claude/skills/theone-unity-patterns.md
# Change: Lifetime.Scoped → Lifetime.Singleton (if appropriate)

# 3. Test locally
cp .claude/skills/theone-unity-patterns.md ~/.claude/skills/

# 4. Commit and push
git add .
git commit -m "fix(skill): correct VContainer Lifetime in registration example

The example showed Lifetime.Scoped but should be Lifetime.Singleton
for services that should live for the application lifetime."

git push origin fix/correct-vcontainer-lifetime

# 5. Create PR on GitHub
gh pr create --title "fix: correct VContainer Lifetime in registration example" \
  --body "Fixes incorrect Lifetime usage in DI registration section"
```

### Scenario 2: Add New Pattern from Code Review

```bash
# 1. Document the pattern you found
git checkout -b feat/add-object-pooling-pattern

# 2. Add to appropriate skill
nano .claude/skills/theone-unity-patterns.md

# Add new section:
## Object Pooling Pattern

### When to Use
- Frequently instantiated/destroyed objects
- Performance-critical scenarios (bullets, particles, enemies)
- Avoiding garbage collection spikes

### Implementation
[Add detailed example...]

# 3. Test the addition
cp .claude/skills/theone-unity-patterns.md ~/.claude/skills/
# Test with Claude...

# 4. Commit and create PR
git add .
git commit -m "feat(skill): add object pooling pattern to theone-unity-patterns

Based on performance issues found in code review #456 where frequent
enemy spawning caused GC spikes. Added comprehensive object pooling
example with Unity's ObjectPool<T>."

git push origin feat/add-object-pooling-pattern
gh pr create
```

### Scenario 3: Create Entirely New Skill

```bash
# 1. Create branch
git checkout -b feat/add-unity-ui-toolkit-skill

# 2. Create new skill file
nano .claude/skills/theone-unity-ui-toolkit.md

# Follow skill template:
# Skill Name
## Skill Purpose
## When This Skill Triggers
## Core Principles
...

# 3. Update README to reference new skill
nano README.md
# Add to "What's Included" section

# 4. Test thoroughly
cp .claude/skills/theone-unity-ui-toolkit.md ~/.claude/skills/

# 5. Create PR with comprehensive description
git add .
git commit -m "feat(skill): add theone-unity-ui-toolkit skill

New skill covering Unity UI Toolkit (UXML/USS) best practices:
- UXML structure and naming conventions
- USS styling patterns
- C# UI manipulation best practices
- Data binding patterns
- Performance considerations

Addresses need from multiple code reviews where engineers
struggled with UI Toolkit patterns."

git push origin feat/add-unity-ui-toolkit-skill
gh pr create --fill
```

## Getting Help

### Questions?

- **GitHub Discussions:** Ask in repository discussions
- **Slack:** #unity-engineering channel
- **Code Review:** Tag senior engineers in PR
- **Office Hours:** Weekly skill contribution workshop (Fridays 2-3pm)

### Resources

- **Skill Template:** `.claude/skills/template-skill.md` (if exists)
- **Style Guide:** This document
- **Unity Docs:** https://docs.unity3d.com/
- **C# Reference:** https://learn.microsoft.com/en-us/dotnet/csharp/

## Recognition

Contributors will be:
- Credited in skill files (at the bottom)
- Mentioned in release notes
- Recognized in team meetings
- Added to contributors list

## License

By contributing, you agree that your contributions will be used internally at TheOne Studio.

---

**Thank you for helping make our Unity training skills better!** 🎉

Every contribution, no matter how small, helps the entire team write better code.
