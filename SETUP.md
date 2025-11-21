# TheOne Training Skills - Setup Guide

Complete guide for installing and configuring TheOne Studio training skills for Claude Code.

## Prerequisites

- Claude Code CLI installed
- Git installed
- Basic terminal knowledge

## Quick Setup (Recommended)

### 1. Clone Repository

```bash
cd ~/Work  # or your preferred location
git clone https://github.com/The1Studio/theone-training-skills.git
cd theone-training-skills
```

### 2. Install All Skills Globally

```bash
# Create global skills directory if it doesn't exist
mkdir -p ~/.claude/skills

# Install all TheOne Studio skills
cp -r .claude/skills/theone-unity-standards ~/.claude/skills/
cp -r .claude/skills/theone-cocos-standards ~/.claude/skills/
cp -r .claude/skills/theone-react-native-standards ~/.claude/skills/
```

### 3. Verify Installation

```bash
# Start Claude Code
claude

# Ask Claude to list skills
# You should see: theone-unity-standards, theone-cocos-standards, theone-react-native-standards
```

**Expected output:**
- ✅ theone-unity-standards (Unity 6 + C# 9)
- ✅ theone-cocos-standards (Cocos Creator + TypeScript)
- ✅ theone-react-native-standards (React Native + TypeScript)

## Selective Installation

Install only the skills you need for your team:

### Unity Team Only

```bash
mkdir -p ~/.claude/skills
cp -r .claude/skills/theone-unity-standards ~/.claude/skills/
```

### Cocos Playable Team Only

```bash
mkdir -p ~/.claude/skills
cp -r .claude/skills/theone-cocos-standards ~/.claude/skills/
```

### React Native Team Only

```bash
mkdir -p ~/.claude/skills
cp -r .claude/skills/theone-react-native-standards ~/.claude/skills/
```

## Project Configuration

### Auto-Trigger Setup

Skills automatically activate based on project context. To ensure proper triggering:

#### Unity Projects

Create or update `CLAUDE.md` in your Unity project root:

```markdown
# [Your Unity Project Name]

Use `theone-unity-standards` skill for all Unity C# code.

## Technology Stack
- Unity 6 (C# 9)
- VContainer for dependency injection
- SignalBus for event system
- UniTask for async operations
```

#### Cocos Creator Projects

Create or update `CLAUDE.md` in your Cocos project root:

```markdown
# [Your Cocos Project Name]

Use `theone-cocos-standards` skill for all Cocos TypeScript code.

## Technology Stack
- Cocos Creator 3.8
- TypeScript
- Playable ads optimization
```

#### React Native Projects

Create or update `CLAUDE.md` in your React Native project root:

```markdown
# [Your React Native Project Name]

Use `theone-react-native-standards` skill for all React Native code.

## Technology Stack
- React Native 0.74+
- Expo
- TypeScript
- Zustand for state management
```

## Manual Skill Activation

You can explicitly activate skills in your conversations:

```
"Use theone-unity-standards to implement this feature"
"Use theone-cocos-standards to optimize playable performance"
"Use theone-react-native-standards to refactor this component"
```

## Updating Skills

### Pull Latest Changes

```bash
cd ~/Work/theone-training-skills  # or your clone location
git pull origin master
```

### Re-install Updated Skills

```bash
# Remove old versions
rm -rf ~/.claude/skills/theone-*-standards

# Install updated versions
cp -r .claude/skills/theone-unity-standards ~/.claude/skills/
cp -r .claude/skills/theone-cocos-standards ~/.claude/skills/
cp -r .claude/skills/theone-react-native-standards ~/.claude/skills/
```

## Global CLAUDE.md Configuration

### Add to User-Level CLAUDE.md

Edit `/home/[your-username]/.claude/CLAUDE.md` and add:

```markdown
## TheOne Studio Skills

**Available Training Skills** (from [theone-training-skills](https://github.com/The1Studio/theone-training-skills)):

31. **[TheOne Unity Standards](./skills/theone-unity-standards/SKILL.md)** 🎮 **UNITY 6 + C# 9**
   - Complete Unity development standards
   - VContainer dependency injection
   - SignalBus event system
   - Data Controllers pattern
   - UniTask async patterns
   - Code quality enforcement (nullable, access modifiers, exceptions)
   - Modern C# patterns (LINQ, expression bodies, null-coalescing)
   - Performance optimization guidelines
   - Code review checklists

32. **[TheOne Cocos Standards](./skills/theone-cocos-standards/SKILL.md)** 🎨 **COCOS CREATOR + TYPESCRIPT**
   - Cocos Creator development standards
   - TypeScript best practices
   - Component lifecycle management
   - Playable ads optimization (<5MB builds)
   - GPU skinning and batching
   - DrawCall optimization
   - Performance-first patterns
   - Code review guidelines

33. **[TheOne React Native Standards](./skills/theone-react-native-standards/SKILL.md)** 📱 **REACT NATIVE + TYPESCRIPT**
   - React Native development standards
   - Functional components and Hooks
   - Expo and React Navigation patterns
   - State management (Zustand/Jotai)
   - Performance optimization (FlatList, memoization)
   - TypeScript integration
   - Testing strategies
   - Code review checklists

### Auto-Trigger Configuration

Skills trigger automatically when:

**Unity:**
- Working in Unity projects
- Editing `.cs` files
- User mentions "Unity", "VContainer", "SignalBus"
- Files like `*.asmdef` present

**Cocos:**
- Working in Cocos Creator projects
- Editing `.ts` files in `assets/` directory
- User mentions "Cocos", "playable ads", "Creator"
- Files like `project.json` present

**React Native:**
- Working in React Native projects
- Editing `.tsx`/`.ts` files
- User mentions "React Native", "Expo", "mobile app"
- Files like `app.json`, `metro.config.js` present
```

## Verification Checklist

After installation, verify:

- [ ] Skills directory exists: `~/.claude/skills/`
- [ ] Three TheOne skills installed:
  - [ ] `theone-unity-standards/`
  - [ ] `theone-cocos-standards/`
  - [ ] `theone-react-native-standards/`
- [ ] Each skill has `SKILL.md` file
- [ ] Each skill has `references/` directory
- [ ] Claude Code recognizes skills (ask "What skills are available?")
- [ ] Skills auto-trigger in appropriate projects

## Troubleshooting

### Skills Not Appearing

**Check installation:**
```bash
ls -la ~/.claude/skills/ | grep theone
```

**Should see:**
```
theone-cocos-standards
theone-react-native-standards
theone-unity-standards
```

### Skills Not Auto-Triggering

1. **Check project CLAUDE.md** - Does it reference the skill?
2. **Check file types** - Are you editing the correct file types (.cs, .ts, .tsx)?
3. **Restart Claude session** - Exit and restart `claude` command
4. **Manually activate** - Use explicit skill invocation

### Skill Content Outdated

```bash
# Update repository
cd ~/Work/theone-training-skills
git pull

# Re-install skills
rm -rf ~/.claude/skills/theone-*-standards
cp -r .claude/skills/theone-*-standards ~/.claude/skills/
```

### Permission Issues

```bash
# Ensure correct permissions
chmod -R 755 ~/.claude/skills/theone-*-standards
```

## Team Rollout

### For Team Leads

1. **Share repository link** with team members
2. **Walk through installation** in team meeting
3. **Configure team projects** with appropriate CLAUDE.md files
4. **Monitor PR reviews** - Reference skills in code review comments
5. **Gather feedback** - Update skills based on team experiences

### For Developers

1. **Install skills** following Quick Setup
2. **Configure projects** with CLAUDE.md
3. **Use in development** - Let skills guide code quality
4. **Reference in PRs** - Cite skill sections when reviewing
5. **Report issues** - Suggest improvements to team lead

## Support

### Getting Help

1. **Ask Claude** - "Explain theone-[framework]-standards patterns"
2. **Check documentation** - Read individual SKILL.md files
3. **GitHub Issues** - [Report issues](https://github.com/The1Studio/theone-training-skills/issues)
4. **Team Lead** - Contact your team lead for skill-specific questions

### Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for:
- Proposing pattern changes
- Adding new standards
- Reporting skill bugs
- Improving documentation

## Next Steps

After successful installation:

1. **Unity Developers** → Read [Unity Training Program](./TRAINING.md)
2. **Cocos Developers** → Explore [Cocos Skill Reference](./.claude/skills/theone-cocos-standards/SKILL.md)
3. **React Native Developers** → Review [React Native Patterns](./.claude/skills/theone-react-native-standards/SKILL.md)

---

**Installation complete!** 🎉 Your Claude Code is now trained with TheOne Studio standards.

**Questions?** Open an issue or contact your team lead.
