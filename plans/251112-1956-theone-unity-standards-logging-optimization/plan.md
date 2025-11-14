# TheOne Unity Standards - Logging Optimization Plan

**Created:** 2025-11-12 19:56
**Status:** 🟢 In Progress
**Priority:** High
**Reference:** [PR #9](https://github.com/The1Studio/DynamicUserDifficultyUITemplate/pull/9)

## Overview

Optimize `theone-unity-standards` skill based on PR feedback from @frostbun regarding logging patterns, null handling, and code quality standards.

## Phases

| Phase | Description | Status | Files |
|-------|-------------|--------|-------|
| 01 | Logging Specification | ⏳ Pending | SKILL.md, quality-hygiene.md |
| 02 | Constructor Logging | ⏳ Pending | All framework files |
| 03 | Null Handling | ⏳ Pending | All files with logger usage |
| 04 | Verbose Logs | ⏳ Pending | All example files |
| 05 | Inline Comments | ⏳ Pending | All code examples |

## Key Changes

### 1. Logging Specification
- `ILogger` → `TheOne.Logging.ILogger` (fully qualified)
- Remove `#if UNITY_EDITOR || DEVELOPMENT_BUILD` guards
- Remove manual log prefixes `[GameService]`, `[prefix]`
- ILogger handles prefixes and compilation internally

### 2. Constructor Logging
- NEVER log in constructors
- Constructors must be fast and side-effect free
- Remove all constructor log examples

### 3. Logger Null Handling
- `this.logger?.Debug()` → `this.logger.Debug()`
- No null checks for DI-injected logger
- Nullable annotation for documentation only

### 4. Verbose Logging
- Remove unnecessary debug logs
- Keep only essential logs
- Add guidelines for necessary vs verbose

### 5. Inline Comments
- Strengthen "no inline comments" rule
- Use descriptive names instead
- Add before/after examples

## Files to Update

- `.claude/skills/theone-unity-standards/SKILL.md`
- `.claude/skills/theone-unity-standards/references/csharp/quality-hygiene.md`
- `.claude/skills/theone-unity-standards/references/unity/theone-framework.md`
- `.claude/skills/theone-unity-standards/references/unity/vcontainer-di.md`
- `.claude/skills/theone-unity-standards/references/unity/unitask-patterns.md`
- `.claude/skills/theone-unity-standards/references/review/performance-review.md`
- `.claude/skills/theone-unity-standards/references/review/unity-specifics.md`

## Success Criteria

- [ ] All files use `TheOne.Logging.ILogger`
- [ ] Zero conditional compilation guards in examples
- [ ] Zero manual log prefixes
- [ ] Zero constructor logging
- [ ] Zero `logger?.` null-conditional usage
- [ ] Zero inline comments in examples
- [ ] Clear rules documented for each change

## Timeline

- Plan creation: 10 min ✅
- Implementation: 30-40 min 🔄
- Validation: 10 min ⏳
- Total: ~1 hour
