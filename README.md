# TheOne Studio Unity Training Skills

Claude Code skills for training Unity engineers at TheOne Studio. These skills enforce company standards for C# coding, Unity architecture patterns, and code review practices.

## 📦 What's Included

This repository contains 3 Claude Code skills designed to help Unity engineers write better code, plus comprehensive training and contribution guides:

### 📚 Documentation
- **[TRAINING.md](TRAINING.md)** - Complete 3-week hands-on training program
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - How to contribute and improve skills
- **GitHub Templates** - Issue and PR templates for contributions

### 🎯 Skills

### 1. **theone-csharp-concise-coding**
Enforces concise, idiomatic C# coding standards including:
- LINQ instead of verbose loops
- Extension methods instead of utility classes
- Expression-bodied members
- Null-coalescing operators
- Pattern matching
- Modern C# features (records, init, with)

### 2. **theone-unity-patterns**
Enforces TheOne Studio's Unity architecture patterns:
- VContainer dependency injection (NOT Zenject)
- SignalBus event system (NOT MessagePipe)
- Data Controller pattern (never access data directly)
- Service/Bridge/Adapter integration pattern
- Assembly definition best practices
- Lifecycle management (IInitializable, IDisposable)

### 3. **theone-code-review**
Automated code review checking:
- Architecture adherence (VContainer, SignalBus, Controllers)
- C# code quality (LINQ, expression bodies, null handling)
- Unity best practices (component access, lifecycle)
- Performance (allocations, LINQ in hot paths)
- Testing coverage
- Documentation quality

## 🚀 Quick Start

### Installation

#### Option 1: Global Installation (Recommended)
Install skills globally for use across all Unity projects:

```bash
# Clone the repository
git clone https://github.com/The1Studio/theone-unity-training-skills.git

# Copy skills to global Claude config
mkdir -p ~/.claude/skills
cp theone-unity-training-skills/.claude/skills/*.md ~/.claude/skills/
```

#### Option 2: Per-Project Installation
Install skills for a specific Unity project:

```bash
# Navigate to your Unity project
cd /path/to/your/unity/project

# Copy skills to project
mkdir -p .claude/skills
cp /path/to/theone-unity-training-skills/.claude/skills/*.md .claude/skills/
```

### Verification

After installation, verify the skills are available:

```bash
# Using Claude Code CLI
claude

# Then in Claude, ask:
# "What skills are available?"
```

You should see:
- `theone-csharp-concise-coding`
- `theone-unity-patterns`
- `theone-code-review`

## 📖 Usage

### Automatic Triggering

Skills activate automatically when relevant:

```bash
# Start Claude Code in your Unity project
cd /path/to/unity/project
claude

# Skills trigger automatically when:
# - Writing C# code → theone-csharp-concise-coding
# - Implementing Unity features → theone-unity-patterns
# - Reviewing code → theone-code-review
```

### Manual Invocation

Explicitly invoke a skill:

```bash
# In Claude Code session:
"Use the theone-csharp-concise-coding skill to review this code..."
"Apply theone-unity-patterns to implement this feature..."
"Use theone-code-review to check my pull request..."
```

### Example Workflows

#### 1. Implementing a New Feature
```bash
# Claude automatically uses theone-unity-patterns
"Implement a new difficulty adjustment system using VContainer and SignalBus"

# Claude will:
# ✓ Use VContainer for DI
# ✓ Use SignalBus for events
# ✓ Create Data Controllers
# ✓ Follow Service/Bridge/Adapter pattern
```

#### 2. Refactoring Code
```bash
# Claude automatically uses theone-csharp-concise-coding
"Refactor this code to be more concise"

# Claude will convert:
# - Manual loops → LINQ
# - Verbose null checks → ??/?.
# - Type checks → Pattern matching
# - Full methods → Expression bodies
```

#### 3. Code Review
```bash
# Claude automatically uses theone-code-review
"Review this code for issues"

# Claude will check:
# ✓ Architecture patterns
# ✓ C# code quality
# ✓ Unity best practices
# ✓ Performance issues
# ✓ Test coverage
```

## 📚 Skill Details

### theone-csharp-concise-coding

**Purpose:** Enforce concise, professional C# coding

**Key Principles:**
- Use LINQ over verbose loops
- Extension methods over utility classes
- Expression-bodied members for simplicity
- Null-coalescing operators (`??`, `?.`, `??=`)
- Pattern matching for type checks
- Modern C# features (C# 9-12)

**Example:**
```csharp
// Before (verbose)
List<Enemy> activeEnemies = new List<Enemy>();
foreach (var enemy in allEnemies)
{
    if (enemy.IsActive)
    {
        activeEnemies.Add(enemy);
    }
}

// After (concise) - Applied by skill
var activeEnemies = allEnemies.Where(e => e.IsActive).ToList();
```

**See:** [.claude/skills/theone-csharp-concise-coding.md](.claude/skills/theone-csharp-concise-coding.md)

### theone-unity-patterns

**Purpose:** Enforce TheOne Studio Unity architecture

**Critical Rules:**
- ✅ VContainer (NOT Zenject)
- ✅ SignalBus (NOT MessagePipe)
- ✅ Controllers (NEVER direct data access)

**Key Patterns:**
- Constructor injection with `[Preserve]`
- IInitializable/IDisposable lifecycle
- Signal subscription/unsubscription
- Service/Bridge/Adapter integration
- Separated DI assemblies

**Example:**
```csharp
// Correct pattern enforced by skill
public sealed class GameService : IInitializable, IDisposable
{
    private readonly SignalBus signalBus;
    private readonly LevelDataController levelController;

    [Preserve]
    public GameService(
        SignalBus signalBus,
        LevelDataController levelController)
    {
        this.signalBus = signalBus;
        this.levelController = levelController;
    }

    void IInitializable.Initialize()
    {
        this.signalBus.Subscribe<WonSignal>(this.OnWon);
    }

    void IDisposable.Dispose()
    {
        this.signalBus.TryUnsubscribe<WonSignal>(this.OnWon);
    }

    private void OnWon(WonSignal signal)
    {
        // Use controller, not direct data access
        this.levelController.PassCurrentLevel();
    }
}
```

**See:** [.claude/skills/theone-unity-patterns.md](.claude/skills/theone-unity-patterns.md)

### theone-code-review

**Purpose:** Automated code quality review

**Review Areas:**
1. **Architecture** - VContainer, SignalBus, Controllers
2. **C# Quality** - LINQ, expression bodies, modern features
3. **Unity Practices** - Lifecycle, component access, cleanup
4. **Performance** - Allocations, hot path optimization
5. **Testing** - Unit test coverage
6. **Documentation** - Comments, XML docs

**Severity Levels:**
- 🔴 **Critical:** Must fix (wrong framework, memory leaks)
- 🟡 **Important:** Should fix (verbose code, missing tests)
- 🟢 **Nice to Have:** Suggestions (naming, comments)

**See:** [.claude/skills/theone-code-review.md](.claude/skills/theone-code-review.md)

## 🎓 Training Program

**New to these skills?** Start with the comprehensive training program:

👉 **[TRAINING.md](TRAINING.md)** - Complete 3-week hands-on training

The training includes:
- **Week 1:** C# Concise Coding (LINQ, modern features, extensions)
- **Week 2:** Unity Architecture (VContainer, SignalBus, Controllers)
- **Week 3:** Integration Patterns & Capstone Project
- **Self-Assessment:** Certification criteria
- **Hands-On Exercises:** Real-world scenarios with Claude Code

### Quick Training Workflows

#### For New Engineers

```bash
# 1. Set up Claude Code with skills
cp -r theone-unity-training-skills/.claude/skills ~/.claude/

# 2. Start working on first task
cd /path/to/unity/project
claude

# 3. Ask Claude to implement a feature
"Implement a new player scoring system"

# Claude will:
# - Use theone-unity-patterns automatically
# - Apply theone-csharp-concise-coding
# - Follow all TheOne Studio standards

# 4. Review what Claude did
"Explain why you used VContainer and Controllers"

# 5. Practice by modifying
"Now let me try to implement enemy spawning, review my code"
```

### For Code Reviews

```bash
# Before committing code
claude

"Use theone-code-review to check my recent changes"

# Claude will provide:
# - Architecture violations (Critical)
# - Code quality issues (Important)
# - Suggestions for improvement (Nice to Have)

# Fix issues, then commit
git add .
git commit -m "feat: implement difficulty system"
```

### For Refactoring

```bash
claude

"Use theone-csharp-concise-coding to refactor EnemyManager.cs"

# Claude will:
# - Convert loops to LINQ
# - Apply expression bodies
# - Add null-coalescing operators
# - Use pattern matching
# - Modernize C# code
```

## 🔧 Customization

### Modifying Skills

Skills are markdown files that can be edited:

```bash
# Edit a skill
nano ~/.claude/skills/theone-csharp-concise-coding.md

# Or use your preferred editor
code ~/.claude/skills/theone-unity-patterns.md
```

### Adding Company-Specific Patterns

Add your own patterns to skills:

```markdown
## Company-Specific Pattern: Custom Analytics

When tracking analytics, always include:
- Player ID
- Session ID
- Level context
- Timestamp

Example:
\`\`\`csharp
this.analyticService.Track("event_name",
    ("player_id", this.playerId),
    ("session_id", this.sessionId),
    ("level", this.levelController.CurrentLevel)
);
\`\`\`
```

### Creating New Skills

Create additional skills for specific needs:

```bash
# Create new skill
nano ~/.claude/skills/theone-ui-patterns.md
```

Example skill structure:
```markdown
# Skill Name

## Skill Purpose
What this skill does

## When This Skill Triggers
When to use it

## Patterns and Examples
(Your patterns here)
```

## 📊 Best Practices

### For Engineers

1. **Learn by Doing**
   - Let Claude implement features using skills
   - Study the code Claude generates
   - Ask "why" questions to understand patterns

2. **Use for Code Review**
   - Run theone-code-review before commits
   - Fix Critical issues immediately
   - Address Important issues before PR
   - Consider Nice to Have suggestions

3. **Refactor Existing Code**
   - Use skills to modernize old code
   - Learn concise patterns by comparison
   - Apply incrementally to avoid breaking changes

### For Team Leads

1. **Onboarding**
   - Install skills globally for all engineers
   - Include in onboarding checklist
   - Review skill-generated code together

2. **Code Review Process**
   - Require theone-code-review before PR
   - Use skill checklist in PR template
   - Reference skills in code review comments

3. **Continuous Improvement**
   - Update skills as patterns evolve
   - Add company-specific examples
   - Share skill improvements across team

## 🤝 Contributing

**Want to improve the skills?** We encourage all engineers to contribute!

👉 **[CONTRIBUTING.md](CONTRIBUTING.md)** - Complete contribution guide

### Quick Contribution Workflow

```bash
# 1. Fork or clone
git clone https://github.com/The1Studio/theone-unity-training-skills.git
cd theone-unity-training-skills

# 2. Create branch
git checkout -b feature/improve-csharp-skill

# 3. Make your changes
nano .claude/skills/theone-csharp-concise-coding.md

# 4. Test locally
cp .claude/skills/*.md ~/.claude/skills/
claude  # Test with Claude Code

# 5. Submit PR
git add .
git commit -m "feat(skill): add more LINQ examples"
git push origin feature/improve-csharp-skill
gh pr create
```

### Ways to Contribute

- 🐛 **Fix errors** - Correct mistakes or outdated information
- ✨ **Add examples** - Share real-world patterns from your code
- 📚 **Improve clarity** - Make explanations easier to understand
- 🆕 **Create skills** - Propose new skills for emerging patterns
- 📝 **Update docs** - Improve README, TRAINING, or CONTRIBUTING

### GitHub Templates

We provide templates for:
- **Skill Improvement Issues** - Suggest enhancements
- **New Skill Proposals** - Propose new skills
- **Bug Reports** - Report incorrect information
- **Pull Requests** - Structured PR template with checklist

## 📋 Checklist for New Engineers

After installing these skills, engineers should be able to:

- [ ] Understand why VContainer is used (not Zenject)
- [ ] Know when to use SignalBus (not MessagePipe)
- [ ] Always access data through Controllers
- [ ] Write concise LINQ instead of verbose loops
- [ ] Use expression bodies for simple methods
- [ ] Apply null-coalescing operators
- [ ] Implement IInitializable and IDisposable correctly
- [ ] Unsubscribe from all signals in Dispose
- [ ] Follow Service/Bridge/Adapter pattern for integrations
- [ ] Pass code review using theone-code-review skill

## 📞 Support

### Resources
- **Skills Documentation:** `.claude/skills/*.md`
- **TheOne Studio Patterns:** Refer to global `~/.claude/theone-studio-patterns.md`
- **Unity Testing Guide:** `~/.claude/unity-testing-guide.md`

### Getting Help
- Ask Claude: "Explain the theone-unity-patterns skill"
- Review skill files for detailed examples
- Consult with senior engineers for pattern questions
- Create issues on GitHub for skill improvements

## 📄 License

Internal use for TheOne Studio only.

## 🔗 Related Resources

- [VContainer Documentation](https://vcontainer.hadashikick.jp/)
- [Unity Test Framework](https://docs.unity3d.com/Packages/com.unity.test-framework@latest)
- [C# Language Reference](https://learn.microsoft.com/en-us/dotnet/csharp/)

---

**Version:** 1.0.0
**Last Updated:** 2025-01-31
**Maintained by:** TheOne Studio Engineering Team
