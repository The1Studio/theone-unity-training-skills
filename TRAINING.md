# TheOne Studio Unity Skills Training Guide

Complete hands-on training program for mastering TheOne Studio Unity patterns using Claude Code skills.

> **📚 Multi-Team Training:** This is the Unity-specific training program. For other frameworks, see:
> - **Cocos Creator Training** - Coming soon (playable ads optimization)
> - **React Native Training** - Coming soon (mobile app patterns)
> - **All Skills**: [README.md](./README.md)

## Training Overview

This training program is designed to take Unity engineers from beginner to proficient in TheOne Studio's coding standards through hands-on exercises with Claude Code.

**Duration:** 2-3 weeks (self-paced)
**Prerequisites:** Basic Unity and C# knowledge
**Tools Required:** Claude Code CLI, Unity Editor, Git

## Training Structure

### Week 1: C# Concise Coding Fundamentals
- Day 1-2: LINQ and collection operations
- Day 3-4: Modern C# features (null-coalescing, pattern matching)
- Day 5: Extension methods and expression bodies

### Week 2: Unity Architecture Patterns
- Day 1-2: VContainer dependency injection
- Day 3-4: SignalBus event system
- Day 5: Data Controller pattern

### Week 3: Integration and Review
- Day 1-2: Service/Bridge/Adapter pattern
- Day 3-4: Code review and refactoring
- Day 5: Final project

## Setup

### 1. Install Skills

```bash
# Clone repository
git clone https://github.com/The1Studio/theone-unity-training-skills.git

# Install globally
mkdir -p ~/.claude/skills
cp theone-unity-training-skills/.claude/skills/*.md ~/.claude/skills/

# Verify installation
claude
# Ask: "What skills are available?"
```

### 2. Create Training Project

```bash
# Create practice directory
mkdir -p ~/unity-training
cd ~/unity-training

# Create Unity project (or use existing test project)
# Unity Hub → New Project → 3D Core
```

### 3. Verify Claude Code Works

```bash
cd ~/unity-training
claude

# Test command:
"List the available TheOne Studio skills"

# Expected: Should list all 3 skills
```

---

## Week 1: C# Concise Coding

### Day 1-2: LINQ Mastery

#### Exercise 1.1: Collections Filtering

**Setup:**
```bash
cd ~/unity-training
claude
```

**Task:**
Ask Claude to create a player management system with these requirements:
```
"Create a PlayerManager class with the following methods:
1. GetActivePlayers() - return all active players
2. GetTopScorers(int count) - return top N players by score
3. GetPlayersByLevel(int minLevel) - return players above level threshold
4. GetAverageScore() - calculate average score of all players

Use verbose loops first, then I'll refactor with LINQ."
```

**What You'll Learn:**
- How to identify opportunities for LINQ
- `Where()`, `OrderBy()`, `Take()`, `Select()`, `Average()`
- Method chaining

**Self-Check:**
```csharp
// Did Claude convert this:
List<Player> activePlayers = new List<Player>();
foreach (var player in allPlayers)
{
    if (player.IsActive)
        activePlayers.Add(player);
}

// To this:
var activePlayers = allPlayers.Where(p => p.IsActive).ToList();
```

#### Exercise 1.2: Complex LINQ Queries

**Task:**
```
"Create an EnemySpawner that needs to:
1. Find all spawn points that are:
   - Active
   - Not currently occupied
   - Within 50 units of player
   - Have cooldown expired

2. Group enemies by type and count them
3. Get the 5 nearest enemies to a position

Show me verbose version first, then refactor with LINQ."
```

**Challenge:**
Refactor the verbose code yourself, then ask Claude to review:
```
"Review my LINQ refactoring and suggest improvements"
```

**What You'll Learn:**
- Complex filtering with multiple conditions
- `GroupBy()` for grouping
- `OrderBy()` with custom comparers
- Combining multiple LINQ operations

#### Exercise 1.3: Performance Considerations

**Task:**
```
"Create a GameManager with an Update method that finds all enemies
within attack range every frame. Show me the performance issue,
then optimize it."
```

**What You'll Learn:**
- When LINQ is too slow (Update/FixedUpdate)
- Caching query results
- Using for loops in hot paths
- Balancing conciseness vs performance

**Key Takeaway:**
```csharp
// ❌ DON'T: LINQ in Update (too slow)
void Update()
{
    var nearbyEnemies = allEnemies
        .Where(e => Vector3.Distance(e.position, transform.position) < 10f)
        .ToList();
}

// ✅ DO: Cache or use for loop
private List<Enemy> nearbyEnemiesCache = new List<Enemy>();

void Update()
{
    this.nearbyEnemiesCache.Clear();
    for (int i = 0; i < allEnemies.Count; i++)
    {
        if (Vector3.Distance(allEnemies[i].position, transform.position) < 10f)
            this.nearbyEnemiesCache.Add(allEnemies[i]);
    }
}
```

### Day 3-4: Modern C# Features

#### Exercise 2.1: Null-Coalescing Operators

**Task:**
```
"Create a ConfigManager that loads configuration from multiple sources
with fallback logic. Use verbose null checking first, then refactor
using ??, ?., and ??= operators."
```

**Examples to Practice:**
```csharp
// Before
string playerName;
if (savedData != null && savedData.PlayerName != null)
    playerName = savedData.PlayerName;
else
    playerName = "Player";

// After (you refactor)
var playerName = savedData?.PlayerName ?? "Player";
```

**Self-Practice:**
Create 5 different scenarios with null checking, then refactor each one.

#### Exercise 2.2: Pattern Matching

**Task:**
```
"Create a DamageCalculator that applies different damage based on
weapon type (Sword, Bow, Magic). Use old-style type checking first,
then refactor with pattern matching."
```

**Challenge Levels:**

**Level 1: Basic Pattern Matching**
```csharp
// Convert this:
if (weapon is Sword)
{
    Sword sword = (Sword)weapon;
    damage = sword.BaseDamage * sword.SharpnessModifier;
}

// To this (you write):
if (weapon is Sword sword)
{
    damage = sword.BaseDamage * sword.SharpnessModifier;
}
```

**Level 2: Switch Expressions**
```csharp
// Convert switch statement to switch expression
var damage = weapon switch
{
    Sword s => s.BaseDamage * s.SharpnessModifier,
    Bow b => b.BaseDamage * b.RangeModifier,
    Magic m => m.BaseDamage * m.ManaModifier,
    _ => 0
};
```

**Level 3: Property Patterns**
```csharp
// Pattern match on properties
if (weapon is { Rarity: Rarity.Legendary, Level: > 50 })
{
    ApplyBonusDamage(weapon);
}
```

#### Exercise 2.3: Records and Init Properties

**Task:**
```
"Create data classes for:
1. PlayerData (id, name, level, score)
2. GameConfig (difficulty, maxPlayers, timeLimit)
3. LevelResult (levelId, score, time, stars)

Show me old-style classes, then convert to records with init."
```

**What You'll Learn:**
- When to use records vs classes
- Init-only properties
- With expressions for copying
- Required properties

### Day 5: Extension Methods

#### Exercise 3.1: Create Extension Methods

**Task:**
```
"I have a StringUtility class with these static methods:
- IsNullOrEmpty
- Capitalize
- TruncateWithEllipsis
- ToTitleCase

Convert them to extension methods and show usage examples."
```

**Practice:**
Create extension methods for:
- `List<T>` - Shuffle, GetRandom, IsEmpty
- `Vector3` - SetX, SetY, SetZ
- `Transform` - ResetLocal, SetLocalPositionX

**Template:**
```csharp
public static class YourExtensions
{
    public static T GetRandom<T>(this List<T> list)
    {
        return list[Random.Range(0, list.Count)];
    }

    // Add more...
}
```

#### Exercise 3.2: Unity-Specific Extensions

**Task:**
```
"Create extension methods for common Unity operations:
1. GameObject.GetOrAddComponent<T>()
2. Transform.DestroyChildren()
3. Component.GetComponentInChildrenRequired<T>() (throws if not found)
4. LayerMask.Contains(int layer)

Show me when and why to use each one."
```

---

## Week 2: Unity Architecture Patterns

### Day 1-2: VContainer Dependency Injection

#### Exercise 4.1: Basic Service Registration

**Task:**
```
"Create a simple game with:
1. GameplayService (handles game loop)
2. ScoreService (tracks score)
3. GameLifetimeScope (DI container)

Show me how to register and inject services using VContainer."
```

**Self-Check Checklist:**
- [ ] Services registered in GameLifetimeScope.Configure()
- [ ] Constructor injection used (not field injection)
- [ ] Dependencies marked as readonly
- [ ] [Preserve] attribute added to constructors

**Common Mistakes to Avoid:**
```csharp
// ❌ WRONG: Field injection
public class GameplayService
{
    [Inject] private ScoreService scoreService;
}

// ✅ CORRECT: Constructor injection
public class GameplayService
{
    private readonly ScoreService scoreService;

    [Preserve]
    public GameplayService(ScoreService scoreService)
    {
        this.scoreService = scoreService;
    }
}
```

#### Exercise 4.2: Lifecycle Management

**Task:**
```
"Create a service that:
1. Subscribes to Unity events in Initialize()
2. Updates some state periodically
3. Cleans up in Dispose()

Show me the IInitializable and IDisposable pattern."
```

**Template:**
```csharp
public sealed class YourService : IInitializable, IDisposable
{
    [Preserve]
    public YourService(/* dependencies */)
    {
        // DON'T subscribe here!
    }

    void IInitializable.Initialize()
    {
        // ✅ Subscribe here
    }

    void IDisposable.Dispose()
    {
        // ✅ Unsubscribe here
    }
}
```

#### Exercise 4.3: Component Registration

**Task:**
```
"Register Unity components in the DI container:
1. Register existing UI component from scene
2. Register new component from prefab resource
3. Register component under specific transform

Explain when to use each registration method."
```

### Day 3-4: SignalBus Event System

#### Exercise 5.1: Signal Definition and Usage

**Task:**
```
"Create a game event system with signals for:
1. GameStarted
2. GamePaused
3. GameOver (with score and time)
4. LevelCompleted (with level number and stars)
5. PlayerDied (with cause of death)

Show me how to define and use each signal type."
```

**Signal Design Checklist:**
- [ ] Use `sealed record` for simple signals
- [ ] Use `class` for signals with complex data
- [ ] NEVER use `struct` for signals
- [ ] Name signals as actions (VerbSignal) or state changes (StateChangedSignal)

#### Exercise 5.2: Signal Subscription Lifecycle

**Task:**
```
"Create a UI manager that:
1. Subscribes to game events in Initialize()
2. Updates UI based on signals
3. Properly unsubscribes in Dispose()

Show me the complete lifecycle pattern."
```

**Critical Pattern:**
```csharp
public sealed class UIManager : IInitializable, IDisposable
{
    private readonly SignalBus signalBus;

    [Preserve]
    public UIManager(SignalBus signalBus)
    {
        this.signalBus = signalBus;
    }

    void IInitializable.Initialize()
    {
        // ✅ Subscribe
        this.signalBus.Subscribe<GameStartedSignal>(this.OnGameStarted);
        this.signalBus.Subscribe<GameOverSignal>(this.OnGameOver);
    }

    private void OnGameStarted(GameStartedSignal signal) { }
    private void OnGameOver(GameOverSignal signal) { }

    void IDisposable.Dispose()
    {
        // ✅ MUST unsubscribe (use TryUnsubscribe to avoid exceptions)
        this.signalBus.TryUnsubscribe<GameStartedSignal>(this.OnGameStarted);
        this.signalBus.TryUnsubscribe<GameOverSignal>(this.OnGameOver);
    }
}
```

#### Exercise 5.3: Signal Fire and Forget

**Task:**
```
"Create a GameplayService that fires signals when:
1. Player completes a level
2. Difficulty changes
3. Achievement is unlocked

Show me how to fire signals with data."
```

### Day 5: Data Controller Pattern

#### Exercise 6.1: Create a Data Controller

**Task:**
```
"Create a PlayerDataController that:
1. Wraps PlayerData model
2. Provides read-only access to player stats
3. Provides methods for updating data (LevelUp, AddGold, etc.)
4. Fires signals when data changes

Show me the complete pattern with before/after examples."
```

**Critical Rule:**
```csharp
// ❌ NEVER access data directly
public class GameService
{
    private readonly PlayerData playerData;

    public void AddGold(int amount)
    {
        playerData.Gold += amount; // ❌ WRONG!
    }
}

// ✅ ALWAYS use controller
public class GameService
{
    private readonly PlayerDataController playerController;

    public void AddGold(int amount)
    {
        playerController.AddGold(amount); // ✅ CORRECT!
    }
}
```

#### Exercise 6.2: Controller with Validation

**Task:**
```
"Create a LevelDataController that:
1. Validates level numbers (1-100)
2. Prevents going to locked levels
3. Fires LevelChangedSignal when level changes
4. Tracks level completion stats

Include validation and error handling."
```

#### Exercise 6.3: Multiple Controllers Integration

**Task:**
```
"Create a game where:
1. PlayerDataController manages player stats
2. LevelDataController manages level progression
3. InventoryDataController manages items
4. GameService coordinates between controllers

Show me how controllers interact through services."
```

---

## Week 3: Integration and Mastery

### Day 1-2: Service/Bridge/Adapter Pattern

#### Exercise 7.1: Third-Party Integration

**Task:**
```
"Integrate a fictional analytics library using Service/Bridge/Adapter:

1. Core: AnalyticsService interface (framework-agnostic)
2. Adapter: Convert game events to analytics format
3. Bridge: Connect game signals to analytics
4. DI: Register everything in VContainer

Show me the complete integration pattern."
```

**Pattern Structure:**
```
Integration/
├── Core/
│   └── IAnalyticsService.cs (interface)
├── Adapters/
│   └── AnalyticsEventAdapter.cs (game → analytics conversion)
├── Bridges/
│   └── AnalyticsBridge.cs (signal → analytics)
└── DI/
    └── AnalyticsVContainer.cs (registration)
```

#### Exercise 7.2: Difficulty System Integration

**Real-World Scenario:**

```
"You need to integrate a dynamic difficulty system:

1. System tracks player performance
2. Adjusts game parameters based on performance
3. Multiple game systems need to react to difficulty changes

Implement using Service/Bridge/Adapter pattern with:
- DifficultyService (core logic)
- DifficultyGameAdapter (difficulty → game parameters)
- DifficultyGameBridge (connects signals)
- Proper VContainer registration"
```

### Day 3-4: Code Review and Refactoring

#### Exercise 8.1: Review Bad Code

**Task:**
Claude will provide you with intentionally bad code. Your job:

1. Identify all violations
2. Categorize by severity (Critical, Important, Nice to Have)
3. Refactor to follow all patterns
4. Ask Claude to review your refactoring

**Example Bad Code:**
```
"Review this code and identify all issues:

```csharp
public class PlayerManager : MonoBehaviour
{
    public PlayerData playerData; // public field

    [Inject] private SignalBus signalBus; // field injection

    void Start()
    {
        signalBus.Subscribe<WonSignal>(OnWon); // subscribe in Start
    }

    void OnWon(WonSignal signal)
    {
        playerData.Level++; // direct data access
        playerData.Gold += 100;
    }

    public List<Enemy> GetActiveEnemies()
    {
        List<Enemy> result = new List<Enemy>();
        foreach (var enemy in allEnemies)
        {
            if (enemy.IsActive)
            {
                result.Add(enemy);
            }
        }
        return result;
    }
}
```

Categorize issues by severity and provide refactored version."
```

**Self-Check:**
Did you catch all these issues?
- [ ] Public field (should be private)
- [ ] Field injection (should be constructor)
- [ ] Subscribe in Start (should be IInitializable)
- [ ] No IDisposable (memory leak)
- [ ] Direct data access (should use controller)
- [ ] Verbose loop (should use LINQ)
- [ ] No [Preserve] attribute

#### Exercise 8.2: Refactor Legacy Code

**Task:**
```
"Here's legacy code from an old project. Refactor it to follow
all TheOne Studio patterns:

1. Convert to VContainer (from old Zenject)
2. Add Data Controllers
3. Apply concise C# patterns
4. Add proper lifecycle management
5. Fix all code review violations

[Claude provides legacy code]

Show me step-by-step refactoring with explanation."
```

### Day 5: Final Project

#### Capstone Exercise: Complete Game System

**Requirements:**

Create a complete feature from scratch demonstrating all learned skills:

```
"Create a Player Progression System with:

Features:
1. Experience points and leveling
2. Unlockable abilities
3. Achievement tracking
4. Stat progression
5. Save/load functionality

Technical Requirements:
✅ Use VContainer for DI
✅ Use SignalBus for events
✅ Use Controllers for all data access
✅ Apply concise C# patterns (LINQ, null-coalescing, etc.)
✅ Follow Service/Bridge/Adapter for integrations
✅ Implement proper lifecycle (IInitializable, IDisposable)
✅ Include unit tests
✅ Pass all code review checks

Components Needed:
1. PlayerProgressionDataController
2. ExperienceService
3. AbilityService
4. AchievementService
5. SaveService
6. Signals: LevelUpSignal, AbilityUnlockedSignal, AchievementEarnedSignal
7. UI integration
8. Game integration

Show me the complete implementation with:
- Architecture diagram
- All code files
- DI registration
- Usage examples
- Unit tests
"
```

**Evaluation Criteria:**

Use `theone-code-review` skill to evaluate:

```
"Use theone-code-review skill to review my Player Progression System.
Provide comprehensive feedback on:
1. Architecture adherence
2. C# code quality
3. Unity best practices
4. Performance
5. Testing
6. Documentation
"
```

**Success Criteria:**
- [ ] 🔴 No Critical issues
- [ ] 🟡 Fewer than 3 Important issues
- [ ] 🟢 Nice to Have issues addressed
- [ ] All patterns correctly applied
- [ ] Code is concise and readable
- [ ] Proper lifecycle management
- [ ] Unit tests pass

---

## Self-Assessment

After completing training, you should be able to:

### C# Concise Coding ✅
- [ ] Convert verbose loops to LINQ
- [ ] Use null-coalescing operators naturally
- [ ] Apply pattern matching for type checks
- [ ] Write extension methods instead of utility classes
- [ ] Use expression-bodied members
- [ ] Know when to prioritize performance over conciseness

### VContainer DI ✅
- [ ] Register services in LifetimeScope
- [ ] Use constructor injection with [Preserve]
- [ ] Implement IInitializable and IDisposable
- [ ] Register Unity components correctly
- [ ] Understand service lifetimes

### SignalBus Events ✅
- [ ] Define signals correctly (class/record, not struct)
- [ ] Subscribe in Initialize()
- [ ] Unsubscribe in Dispose() with TryUnsubscribe
- [ ] Fire signals with appropriate data
- [ ] Understand signal lifecycle

### Data Controllers ✅
- [ ] Never access data models directly
- [ ] Create controllers for all data
- [ ] Implement business logic in controllers
- [ ] Fire signals on data changes
- [ ] Validate data in controllers

### Integration Patterns ✅
- [ ] Understand Service/Bridge/Adapter pattern
- [ ] Integrate third-party libraries correctly
- [ ] Separate DI code into own assembly
- [ ] Follow framework-agnostic core principles

### Code Review ✅
- [ ] Identify Critical, Important, and Nice to Have issues
- [ ] Review code using theone-code-review skill
- [ ] Understand why patterns exist (not just how)
- [ ] Write code that passes review on first try

---

## Continuous Learning

### Weekly Practice
- Refactor one file per week using skills
- Review pull requests with theone-code-review
- Contribute improvements to skills repository

### Monthly Goals
- Master one new C# feature
- Deep dive into one Unity system
- Create a skill contribution

### Resources
- **Skills Repository:** Regular updates with new patterns
- **Code Reviews:** Learn from feedback
- **Team Workshops:** Monthly skill discussions
- **Documentation:** Keep ~/.claude/*.md files updated

---

## Certification (Optional)

After completing training:

1. **Submit Capstone Project** for senior engineer review
2. **Pass Code Review** (< 3 Important issues)
3. **Demonstrate Skills** in 1-on-1 session
4. **Contribute to Skills** (add one example or improvement)

**Certificate:** "TheOne Studio Unity Patterns - Certified"

---

## Getting Help

- **Stuck on Exercise?** Ask Claude: "Explain this pattern step-by-step"
- **Code Not Working?** Ask Claude: "Debug this issue"
- **Need Clarification?** Ask Claude: "Why is this pattern preferred?"
- **Want Examples?** Ask Claude: "Show me more examples of [pattern]"

Remember: Claude with these skills is your AI pair programmer. Don't hesitate to ask questions!

---

**Good luck with your training!** 🚀

By the end, you'll be writing clean, maintainable Unity code that follows TheOne Studio's best practices.
