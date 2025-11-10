# TheOne Studio Unity Training Skills

Claude Code skill for Unity engineers at TheOne Studio. Enforces company standards for C# coding, Unity architecture, and code quality.

## What's This?

One unified skill that teaches Claude (and engineers) how to write Unity code the TheOne Studio way:

- **Code Quality First** - Nullable types, access modifiers, exceptions, logging
- **Modern C# Patterns** - LINQ, expression bodies, null-coalescing, records
- **Unity Architecture** - VContainer/SignalBus OR TheOne.DI/Publisher patterns
- **Performance** - LINQ optimization, allocation prevention

## Quick Start

### Install

```bash
# Clone repository
git clone https://github.com/The1Studio/theone-unity-training-skills.git

# Copy skill globally
mkdir -p ~/.claude/skills
cp -r theone-unity-training-skills/.claude/skills/theone-unity-standards ~/.claude/skills/
```

### Verify

```bash
claude
# Then ask: "What skills are available?"
# You should see: theone-unity-standards
```

### Configure Project (Optional but Recommended)

Add to your Unity project's `CLAUDE.md` to ensure the skill is used:

```markdown
# Project: [Your Unity Project Name]

## Skills to Use

When working with this Unity project, always use the `theone-unity-standards` skill for:
- Writing C# code
- Implementing Unity features
- Reviewing code changes
- Refactoring existing code

This skill enforces:
- Code quality first (nullable types, sealed classes, internal by default)
- Modern C# patterns (LINQ, expression bodies, records)
- Unity architecture (VContainer/SignalBus OR TheOne.DI/Publisher)
- Performance best practices

## Unity Standards

Follow TheOne Studio standards:
- VContainer + SignalBus (or TheOne.DI + Publisher)
- Data Controllers only (never direct data access)
- UniTask for async operations
- TheOne.Logging for runtime (Debug.Log for editor only)
```

**Why add this?**
- Ensures Claude always uses the skill for your Unity project
- Provides context about your project's architecture
- Makes standards explicit for all team members
- Claude will automatically apply patterns when you ask it to implement features

## Usage

### Automatic Activation

The skill automatically triggers when Claude detects:
- Unity C# code context (.cs files in Unity project)
- Keywords: "implement", "refactor", "review", "Unity", "C#"
- Architecture terms: "VContainer", "SignalBus", "DI", "event"
- Requests for code generation or review

```bash
cd /path/to/unity/project
claude

# Examples - skill auto-triggers:
"Implement a scoring system"                    # ✓ Auto-uses skill
"Refactor this code"                            # ✓ Auto-applies patterns
"Review my changes"                             # ✓ Auto-checks quality
"Add VContainer dependency injection"           # ✓ Auto-uses skill
```

### Manual Activation

If you want to explicitly use the skill:

```bash
# In Claude Code session:
"Use the theone-unity-standards skill to implement this feature"
"Apply theone-unity-standards patterns to this code"
"Review this code using theone-unity-standards"
```

### How It Works

1. **Skill Description** - Claude reads the skill's description which says:
   > "Triggers when writing, reviewing, or refactoring Unity C# code, implementing features, setting up dependency injection, working with events, or reviewing code changes."

2. **Project Context** - If your project has `CLAUDE.md` mentioning the skill, Claude will prioritize using it

3. **Code Context** - When working with .cs files in Unity projects, the skill becomes relevant

4. **Your Instructions** - When you mention Unity patterns, VContainer, SignalBus, etc.

## What It Enforces

### 🔴 Code Quality (Priority 1)

```csharp
#nullable enable

internal sealed class GameService  // internal by default, sealed
{
    private readonly ILogger logger;              // readonly
    private const int MaxRetries = 3;             // const

    [SerializeField] private Button btn = null!;  // null! for Unity

    public GameService(ILogger logger)
    {
        ArgumentNullException.ThrowIfNull(logger, nameof(logger));  // nameof
        this.logger = logger;
    }

    public Player GetPlayer(string id)
    {
        return players.TryGetValue(id, out var player)
            ? player
            : throw new KeyNotFoundException($"Player not found: {id}");  // throw, not log
    }

    private void Log()
    {
        this.logger.Info("Started");  // TheOne.Logging, not Debug.Log
    }
}
```

### 🟡 Modern C# (Priority 2)

```csharp
// ✅ LINQ instead of loops
var activeEnemies = allEnemies.Where(e => e.IsActive).ToList();

// ✅ Expression bodies
public int Health => this.currentHealth;

// ✅ Null-coalescing
var name = playerName ?? "Unknown";

// ✅ Pattern matching
if (obj is Player player) player.TakeDamage(10);

// ✅ Records for data
public sealed record PlayerData(string Name, int Score);
```

### 🟢 Unity Architecture (Priority 3)

**Option 1: VContainer + SignalBus**
```csharp
public sealed class GameService : IInitializable, IDisposable
{
    private readonly SignalBus signalBus;
    private readonly LevelDataController levelController;

    [Preserve]
    public GameService(SignalBus signalBus, LevelDataController levelController)
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
}
```

**Option 2: TheOne.DI + Publisher**
```csharp
public sealed class GameService : IAsyncEarlyLoadable, IDisposable
{
    private readonly IPublisher<WonSignal> publisher;
    private IDisposable? subscription;

    [Inject]
    public GameService(
        IPublisher<WonSignal> publisher,
        ISubscriber<WonSignal> subscriber)
    {
        this.publisher = publisher;
        this.subscription = subscriber.Subscribe(this.OnWon);
    }

    public void Dispose()
    {
        this.subscription?.Dispose();
    }
}
```

**Universal Rules (Both Options)**:
- ✅ Use Data Controllers (NEVER direct data access)
- ✅ Use UniTask for async operations
- ✅ Unload assets in Dispose
- ✅ TheOne.Logging for runtime

## Common Mistakes Prevented

### ❌ DON'T

```csharp
// Wrong: Nullable warnings ignored
string? name;  // Warning not fixed

// Wrong: Logging errors instead of throwing
Debug.Log("Error: Player not found");  // Should throw exception

// Wrong: Debug.Log in runtime code
public void Start() { Debug.Log("Started"); }  // Use TheOne.Logging

// Wrong: Direct data access
var level = DataManager.Instance.GetLevel(id);  // Use controller

// Wrong: Missing sealed
public class GameService { }  // Should be sealed

// Wrong: SerializeField without null!
[SerializeField] private Button btn;  // With #nullable enable, needs null!
```

### ✅ DO

```csharp
#nullable enable

internal sealed class GameService
{
    private readonly ILogger logger;
    private readonly LevelDataController levelController;  // Use controller

    [SerializeField] private Button btn = null!;  // null! for Unity

    public GameService(ILogger logger, LevelDataController levelController)
    {
        ArgumentNullException.ThrowIfNull(logger, nameof(logger));
        this.logger = logger;
        this.levelController = levelController;
    }

    public Level GetLevel(string id)
    {
        // Use controller, not direct access
        return this.levelController.GetLevel(id)
            ?? throw new KeyNotFoundException($"Level not found: {id}");
    }

    private void LogGameStart()
    {
        this.logger.Info("Game started");  // TheOne.Logging
    }
}
```

## Code Review Checklist

Before committing:

**🔴 Code Quality (CHECK FIRST)**:
- [ ] `#nullable enable` in all files
- [ ] All classes `sealed`
- [ ] All implementations `internal` (only API `public`)
- [ ] Zero compiler warnings
- [ ] Exceptions thrown for errors (no logging)
- [ ] TheOne.Logging (runtime) vs Debug.Log (editor only)
- [ ] `readonly`/`const` used
- [ ] `nameof()` for strings
- [ ] `[SerializeField]` uses `null!`

**🟡 Modern C#**:
- [ ] LINQ instead of loops
- [ ] Expression bodies where appropriate
- [ ] Null-coalescing operators used

**🟢 Unity Architecture**:
- [ ] VContainer/TheOne.DI used correctly
- [ ] Data accessed through Controllers only
- [ ] All signals unsubscribed in Dispose
- [ ] `[Preserve]` or `[Inject]` on constructors

## Documentation

- **Complete Reference**: [.claude/skills/theone-unity-standards/SKILL.md](.claude/skills/theone-unity-standards/SKILL.md)
- **Training Program**: [TRAINING.md](TRAINING.md) - 3-week hands-on training
- **Contributing**: [CONTRIBUTING.md](CONTRIBUTING.md) - How to improve skills

## Support

- Review skill files: `.claude/skills/theone-unity-standards/*.md`
- Ask Claude: "Explain the theone-unity-standards patterns"
- Create issues on GitHub for improvements

## License

Internal use for TheOne Studio only.

---

**Version**: 2.0.0 (Unified skill - code quality first priority)
**Last Updated**: 2025-01-31
**Maintained by**: TheOne Studio Engineering Team
