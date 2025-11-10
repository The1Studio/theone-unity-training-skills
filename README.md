# TheOne Studio Unity Training Skills

⚠️ **Unity 6 (C# 9)** - Claude Code skill for TheOne Studio Unity development standards

## About

One unified skill teaching Claude how to write Unity code following TheOne Studio standards with **code quality first** priority:

1. **Code Quality** - Nullable types, sealed classes, internal by default, throw exceptions
2. **Modern C#** - LINQ, expression bodies, records, pattern matching
3. **Unity Architecture** - VContainer/SignalBus OR TheOne.DI/Publisher, Controllers only
4. **Performance** - LINQ optimization, no allocations in hot paths

## Setup

### 1. Install Skill

```bash
# Clone repository
git clone https://github.com/The1Studio/theone-unity-training-skills.git

# Copy to global Claude config
mkdir -p ~/.claude/skills
cp -r theone-unity-training-skills/.claude/skills/theone-unity-standards ~/.claude/skills/
```

### 2. Verify

```bash
claude
# Ask: "What skills are available?"
# Should see: theone-unity-standards
```

### 3. Configure Project (Recommended)

Create `CLAUDE.md` in your Unity project root:

```markdown
# Project: [Your Unity Project Name]

Use `theone-unity-standards` skill for all C# code.

**Standards**:
- Architecture: VContainer + SignalBus (or TheOne.DI + Publisher)
- Data: Controllers only (never direct access)
- Async: UniTask (not coroutines)
- Logging: TheOne.Logging (runtime), Debug.Log (editor only)
- Code Quality: `#nullable enable`, sealed classes, internal by default
```

## Usage

Claude automatically uses the skill when working with Unity C# code.

**Manual activation**: "Use theone-unity-standards to implement this feature"

## What It Enforces

### Code Quality (Priority 1)
- `#nullable enable` in all files
- All classes `sealed` unless designed for inheritance
- All implementations `internal` (only API `public`)
- Throw exceptions for errors (never log)
- TheOne.Logging for runtime (Debug.Log for editor only)

### Architecture (Priority 3)
- VContainer + SignalBus OR TheOne.DI + Publisher
- Data Controllers only (NEVER direct data access)
- UniTask for async operations
- Unsubscribe from all events in Dispose

### Quick Decision
```
Is this a MonoBehaviour?
├─ YES → Use SerializeField, Unity lifecycle
└─ NO  → Use constructor injection, no SerializeField
```

## Documentation

- **Complete Reference**: [SKILL.md](.claude/skills/theone-unity-standards/SKILL.md)
- **Training Program**: [TRAINING.md](TRAINING.md)
- **Contributing**: [CONTRIBUTING.md](CONTRIBUTING.md)

## Support

- Ask Claude: "Explain theone-unity-standards patterns"
- GitHub Issues: [Report issues](https://github.com/The1Studio/theone-unity-training-skills/issues)

---

**Version**: 2.0.0 | **Updated**: 2025-11-10 | **TheOne Studio Engineering Team**
