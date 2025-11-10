# TheOne Studio Unity Training Skills

⚠️ **Unity 6 (C# 9)** - Claude Code skill enforcing TheOne Studio Unity standards

## What's This?

One unified skill teaching Claude how to write Unity code following TheOne Studio standards:
- **Code Quality First** (Priority 1) - Nullable types, sealed classes, exceptions over logging
- **Modern C# Patterns** (Priority 2) - LINQ, expression bodies, records
- **Unity Architecture** (Priority 3) - VContainer/SignalBus OR TheOne.DI/Publisher
- **Performance** (Priority 4) - LINQ optimization, allocation prevention

**For detailed patterns and examples**: See [SKILL.md](.claude/skills/theone-unity-standards/SKILL.md)

---

## Installation Guide

### Step 1: Install Skill Globally

```bash
# Clone repository
git clone https://github.com/The1Studio/theone-unity-training-skills.git

# Copy skill to global Claude config
mkdir -p ~/.claude/skills
cp -r theone-unity-training-skills/.claude/skills/theone-unity-standards ~/.claude/skills/
```

### Step 2: Verify Installation

```bash
claude
# Ask: "What skills are available?"
# Should see: theone-unity-standards
```

### Step 3: Configure Your Unity Project (Recommended)

Create `CLAUDE.md` in your Unity project root:

```markdown
# Project: [Your Unity Project Name]

## Development Standards

Use `theone-unity-standards` skill for all C# code in this project.

**Architecture**:
- DI: VContainer + SignalBus (or TheOne.DI + Publisher)
- Data: Controllers only (never direct data access)
- Async: UniTask (not coroutines)
- Logging: TheOne.Logging (runtime), Debug.Log (editor only)

**Code Quality**:
- `#nullable enable` in all files
- All classes `sealed` unless designed for inheritance
- All implementations `internal` (only API `public`)
- Throw exceptions for errors (never log errors)
```

---

## Usage Guide

### Automatic Activation

Claude automatically uses the skill when:
- Working with Unity C# code (`.cs` files)
- Keywords: "implement", "refactor", "review", "Unity"
- Architecture terms: "VContainer", "SignalBus", "DI", "controller"
- Your project has `CLAUDE.md` mentioning the skill

### Manual Activation

Explicitly invoke the skill:

```bash
# In Claude Code session:
"Use theone-unity-standards to implement this feature"
"Apply theone-unity-standards patterns"
"Review using theone-unity-standards"
```

---

## What It Enforces (4 Priority Levels)

### 🔴 Priority 1: Code Quality (CHECK FIRST)

10 mandatory rules enforced before any code:

1. Enable nullable reference types (`#nullable enable`)
2. Use least accessible access modifier (private by default)
3. Fix ALL warnings (zero tolerance)
4. Throw exceptions for errors (NEVER log errors)
5. TheOne.Logging for runtime (Debug.Log = editor only)
6. Use `readonly` for fields
7. Use `const` for constants
8. Use `nameof` for strings
9. Using directive in deepest scope
10. No inline comments

### 🟡 Priority 2: Modern C# Patterns

- LINQ over loops
- Expression-bodied members
- Null-coalescing operators (`??`, `?.`, `??=`)
- Pattern matching
- Records for data

### 🟢 Priority 3: Unity Architecture

**Choose ONE stack per project**:

**Option 1: VContainer + SignalBus**
- Constructor injection with `[Preserve]`
- IInitializable/IDisposable lifecycle
- SignalBus for events

**Option 2: TheOne.DI + Publisher**
- Constructor injection with `[Inject]`
- IAsyncEarlyLoadable lifecycle
- IPublisher/ISubscriber for events

**Universal Rules (BOTH options)**:
- ✅ Data Controllers only (NEVER direct data access)
- ✅ UniTask for async (NOT coroutines)
- ✅ Unload assets in Dispose
- ✅ TheOne.Logging for runtime

### 🔵 Priority 4: Performance

- No allocations in Update/FixedUpdate
- LINQ avoided in hot paths
- `.ToArray()` instead of `.ToList()` when not modified

---

## Quick Reference

### Class Types Decision Tree

```
Is this a MonoBehaviour?
├─ YES → Unity component
│   └─ Use: SerializeField, Unity lifecycle methods
│
└─ NO → Pure C# class (Service/System/Controller)
    └─ Use: Constructor injection, no SerializeField
```

### Code Review Checklist

**Before committing, verify**:

🔴 **Code Quality**:
- [ ] `#nullable enable` in all files
- [ ] All classes `sealed`
- [ ] All implementations `internal`
- [ ] Zero compiler warnings
- [ ] Exceptions thrown (no error logging)
- [ ] TheOne.Logging used (runtime)

🟡 **Modern C#**:
- [ ] LINQ instead of loops
- [ ] Expression bodies used
- [ ] Null-coalescing operators used

🟢 **Unity Architecture**:
- [ ] VContainer or TheOne.DI used correctly
- [ ] Data accessed through Controllers only
- [ ] All events unsubscribed in Dispose
- [ ] `[Preserve]` or `[Inject]` on constructors

---

## Documentation

### Complete Reference (Detailed Patterns)
- **Main Skill**: [SKILL.md](.claude/skills/theone-unity-standards/SKILL.md)
- **C# Patterns**: [references/csharp/](https://github.com/The1Studio/theone-unity-training-skills/tree/master/.claude/skills/theone-unity-standards/references/csharp)
- **Unity Architecture**: [references/unity/](https://github.com/The1Studio/theone-unity-training-skills/tree/master/.claude/skills/theone-unity-standards/references/unity)
- **Code Review**: [references/review/](https://github.com/The1Studio/theone-unity-training-skills/tree/master/.claude/skills/theone-unity-standards/references/review)

### Training & Contributing
- **Training Program**: [TRAINING.md](TRAINING.md) - 3-week hands-on training
- **Contributing Guide**: [CONTRIBUTING.md](CONTRIBUTING.md) - How to improve skills

---

## Common Mistakes

### ❌ DON'T

```csharp
// Wrong: Nullable warnings ignored
string? name;  // Fix the warning!

// Wrong: Logging errors
Debug.Log("Error: Player not found");  // Throw exception!

// Wrong: Debug.Log in runtime
public void Start() { Debug.Log("Started"); }  // Use TheOne.Logging

// Wrong: Direct data access
var level = DataManager.Instance.GetLevel(id);  // Use controller!

// Wrong: Not sealed
public class GameService { }  // Add sealed!
```

### ✅ DO

```csharp
// Correct: All quality rules enforced
#nullable enable

internal sealed class GameService
{
    private readonly ILogger logger;
    private readonly LevelDataController controller;

    public GameService(ILogger logger, LevelDataController controller)
    {
        this.logger = logger;
        this.controller = controller;
    }

    public Level GetLevel(string id)
    {
        return this.controller.GetLevel(id)
            ?? throw new KeyNotFoundException($"Level not found: {id}");
    }
}
```

---

## Support

- **Ask Claude**: "Explain theone-unity-standards patterns"
- **Review Files**: `.claude/skills/theone-unity-standards/*.md`
- **GitHub Issues**: [Report issues](https://github.com/The1Studio/theone-unity-training-skills/issues)

---

## License

Internal use for TheOne Studio only.

---

**Version**: 2.0.0 (Unified skill - code quality first priority)
**Last Updated**: 2025-11-10
**Maintained by**: TheOne Studio Engineering Team
