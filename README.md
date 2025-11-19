# TheOne Studio - Claude Code Training Skills

Multi-team repository for training Claude Code with TheOne Studio coding standards across different technology stacks.

## Purpose

Train Claude Code to write production-ready code following TheOne Studio best practices for each development team. These skills enforce code quality, architecture patterns, and framework-specific standards through PR reviews and development workflows.

## Available Skills

| Skill | Team | Framework | Status | Documentation |
|-------|------|-----------|--------|---------------|
| `theone-unity-standards` | Unity Game Dev | Unity 6 (C# 9) | ✅ Production | [SKILL.md](./.claude/skills/theone-unity-standards/SKILL.md) |
| `theone-cocos-standards` | Cocos Playable | Cocos Creator (TypeScript) | 🚧 Beta | [SKILL.md](./.claude/skills/theone-cocos-standards/SKILL.md) |
| `theone-react-native-standards` | React Native | React Native (TypeScript) | 🚧 Beta | [SKILL.md](./.claude/skills/theone-react-native-standards/SKILL.md) |

**Legend:** ✅ Production | 🚧 Beta | 🔄 In Development

## Quick Start

### Installation

```bash
# Clone repository
git clone https://github.com/The1Studio/theone-training-skills.git

# Install specific skill globally
mkdir -p ~/.claude/skills
cp -r theone-training-skills/.claude/skills/theone-<framework>-standards ~/.claude/skills/

# Or install all skills
cp -r theone-training-skills/.claude/skills/theone-*-standards ~/.claude/skills/
```

### Verification

```bash
claude
# Ask: "What skills are available?"
# Should see: theone-unity-standards, theone-cocos-standards, theone-react-native-standards
```

### Project Configuration

Create `CLAUDE.md` in your project root with the appropriate skill reference:

```markdown
# Project: [Your Project Name]

Use `theone-[framework]-standards` skill for all code.
```

See individual skill documentation for framework-specific configuration.

## Usage

Claude Code automatically activates skills based on project context. Manual activation:

```
"Use theone-unity-standards to implement this feature"
"Use theone-cocos-standards to optimize playable performance"
"Use theone-react-native-standards to refactor this component"
```

## Skill Philosophy

All skills follow a consistent 4-tier priority hierarchy:

1. **🔴 Code Quality** - Nullable types, access modifiers, exceptions, logging patterns
2. **🟡 Modern Language** - Framework-specific modern patterns and idioms
3. **🟢 Architecture** - DI, state management, component patterns
4. **🔵 Performance** - Optimization, review checklists

Each skill adapts this philosophy to its framework while maintaining consistency.

## Training Programs

- **[Unity Training](./TRAINING.md)** - Complete 2-3 week program for Unity patterns
- **Cocos Training** - Coming soon (playable ads optimization)
- **React Native Training** - Coming soon (mobile app patterns)

## Documentation

### Unity Standards
- [Complete Reference](./CLAUDE/skills/theone-unity-standards/SKILL.md)
- [Training Program](./TRAINING.md)
- Enforces: VContainer/SignalBus, Data Controllers, UniTask, TheOne.Logging

### Cocos Creator Standards
- [Complete Reference](./.claude/skills/theone-cocos-standards/SKILL.md)
- Enforces: Component lifecycle, GPU skinning, <5MB playables, DrawCall batching

### React Native Standards
- [Complete Reference](./.claude/skills/theone-react-native-standards/SKILL.md)
- Enforces: Functional components, Hooks, FlatList, Expo Router, Zustand/Jotai

## Maintenance Workflow

These skills are living documentation maintained through real-world usage:

1. **Use in PR Reviews** - Reference skills when reviewing code
2. **Gather Feedback** - Collect developer feedback from PR discussions
3. **Iterate** - Update skills based on team experiences
4. **Review** - Quarterly consistency reviews across all skills

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for:
- Adding new skills
- Updating existing skills
- Proposing pattern changes
- Reporting issues

## Support

- **Ask Claude**: "Explain theone-[framework]-standards patterns"
- **GitHub Issues**: [Report issues](https://github.com/The1Studio/theone-training-skills/issues)
- **Team Lead**: Contact your team lead for skill-specific questions

## Version History

- **3.0.0** (2025-11-19) - Multi-team ecosystem: Added Cocos Creator and React Native skills
- **2.0.0** (2025-11-10) - Unity skill refinements and logging guidelines
- **1.0.0** (2025-11-01) - Initial Unity standards skill

---

**TheOne Studio Engineering Team** | Maintained by developers, for developers
