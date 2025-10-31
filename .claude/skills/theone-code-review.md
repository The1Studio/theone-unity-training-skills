# TheOne Studio Code Review Standards

## Skill Purpose
This skill provides automated code review for TheOne Studio Unity projects, checking adherence to C# concise coding standards, Unity architecture patterns, and identifying common mistakes before they reach production.

## When This Skill Triggers
- When reviewing code changes or pull requests
- After implementing new features
- When refactoring existing code
- Before committing code to repository
- When onboarding new engineers (teaching by review)

## Code Review Process

### 1. Architecture Review

#### VContainer Dependency Injection
**Check:**
- [ ] Are all dependencies injected via constructor?
- [ ] Are injected fields marked as `readonly`?
- [ ] Is `[Preserve]` attribute added to constructors?
- [ ] Are services registered correctly in LifetimeScope?
- [ ] Is field/property injection avoided?

**❌ Common Violations:**
```csharp
// Bad: Field injection
public class MyService
{
    [Inject] private SignalBus signalBus; // ❌ WRONG
}

// Bad: Missing readonly
public class MyService
{
    private SignalBus signalBus; // ❌ Should be readonly

    public MyService(SignalBus signalBus)
    {
        this.signalBus = signalBus;
    }
}

// Bad: Missing [Preserve]
public MyService(SignalBus signalBus) // ❌ Missing attribute
{
    this.signalBus = signalBus;
}
```

**✅ Correct Pattern:**
```csharp
public sealed class MyService
{
    private readonly SignalBus signalBus;
    private readonly IAnalyticServices analyticService;

    [Preserve]
    public MyService(
        SignalBus signalBus,
        IAnalyticServices analyticService)
    {
        this.signalBus = signalBus;
        this.analyticService = analyticService;
    }
}
```

#### SignalBus Event System
**Check:**
- [ ] Are signals using class/record (not struct)?
- [ ] Are signal subscriptions in Initialize()?
- [ ] Are signal unsubscriptions in Dispose()?
- [ ] Is TryUnsubscribe() used (not Unsubscribe())?
- [ ] Is MessagePipe avoided (use SignalBus)?

**❌ Common Violations:**
```csharp
// Bad: Struct signal
public struct WonSignal { } // ❌ Use class or record

// Bad: Subscribe in constructor
public MyService(SignalBus signalBus)
{
    signalBus.Subscribe<WonSignal>(OnWon); // ❌ Should be in Initialize
}

// Bad: Using Unsubscribe without try
void IDisposable.Dispose()
{
    this.signalBus.Unsubscribe<WonSignal>(OnWon); // ❌ Use TryUnsubscribe
}

// Bad: Not unsubscribing
public class MyService : IInitializable
{
    void IInitializable.Initialize()
    {
        this.signalBus.Subscribe<WonSignal>(OnWon);
    }
    // ❌ Missing IDisposable implementation!
}
```

**✅ Correct Pattern:**
```csharp
// Good: Record signal
public sealed record WonSignal;

public sealed class MyService : IInitializable, IDisposable
{
    private readonly SignalBus signalBus;

    [Preserve]
    public MyService(SignalBus signalBus)
    {
        this.signalBus = signalBus;
    }

    void IInitializable.Initialize()
    {
        this.signalBus.Subscribe<WonSignal>(this.OnWon);
    }

    private void OnWon(WonSignal signal)
    {
        // Handle event
    }

    void IDisposable.Dispose()
    {
        this.signalBus.TryUnsubscribe<WonSignal>(this.OnWon);
    }
}
```

#### Data Controller Usage
**Check:**
- [ ] Is data accessed through controllers (not directly)?
- [ ] Are business rules in controllers (not scattered)?
- [ ] Do controllers fire signals on data changes?

**❌ Common Violations:**
```csharp
// Bad: Direct data access
public class GameService
{
    private readonly UITemplateUserLevelData levelData;

    public void CompleteLevel()
    {
        this.levelData.CurrentLevel++; // ❌ NEVER ACCESS DIRECTLY
        this.levelData.TotalWins++;
    }
}
```

**✅ Correct Pattern:**
```csharp
// Good: Use controller
public class GameService
{
    private readonly UITemplateLevelDataController levelController;

    public void CompleteLevel()
    {
        this.levelController.PassCurrentLevel(); // ✅ Use controller
    }
}
```

### 2. C# Code Quality Review

#### LINQ vs Manual Loops
**Check:**
- [ ] Are manual loops replaced with LINQ where appropriate?
- [ ] Is LINQ readable and not over-complicated?

**❌ Verbose Code:**
```csharp
// Bad: Manual loop
List<Enemy> activeEnemies = new List<Enemy>();
foreach (var enemy in allEnemies)
{
    if (enemy.IsActive && enemy.Health > 0)
    {
        activeEnemies.Add(enemy);
    }
}

// Bad: Manual counting
int count = 0;
foreach (var player in players)
{
    if (player.Score > 100)
    {
        count++;
    }
}
```

**✅ Concise Code:**
```csharp
// Good: LINQ
var activeEnemies = allEnemies
    .Where(e => e.IsActive && e.Health > 0)
    .ToList();

// Good: Count
var count = players.Count(p => p.Score > 100);
```

#### Expression-Bodied Members
**Check:**
- [ ] Are simple methods using `=>`?
- [ ] Are simple properties using `=>`?

**❌ Verbose:**
```csharp
// Bad: Full method body for one line
public int GetHealth()
{
    return this.currentHealth;
}

public string Name
{
    get { return this.name; }
}
```

**✅ Concise:**
```csharp
// Good: Expression body
public int GetHealth() => this.currentHealth;

public string Name => this.name;
```

#### Null Handling
**Check:**
- [ ] Is `??` used instead of verbose null checks?
- [ ] Is `?.` used for null-conditional access?
- [ ] Is `??=` used for lazy initialization?

**❌ Verbose:**
```csharp
// Bad: Verbose null check
string result;
if (playerName != null)
    result = playerName;
else
    result = "Unknown";

// Bad: Nested null checks
if (player != null)
{
    if (player.Weapon != null)
    {
        damage = player.Weapon.Damage;
    }
}

// Bad: Lazy init
if (this.cache == null)
{
    this.cache = new Dictionary<string, int>();
}
```

**✅ Concise:**
```csharp
// Good: Null coalescing
var result = playerName ?? "Unknown";

// Good: Null-conditional
var damage = player?.Weapon?.Damage ?? 0;

// Good: Null-coalescing assignment
this.cache ??= new Dictionary<string, int>();
```

#### Pattern Matching
**Check:**
- [ ] Is pattern matching used instead of type checks?
- [ ] Are switch expressions used where appropriate?

**❌ Old Style:**
```csharp
// Bad: Type check with cast
if (obj is Player)
{
    Player player = (Player)obj;
    player.TakeDamage(10);
}

// Bad: Switch with types
switch (obj.GetType().Name)
{
    case "Player":
        ((Player)obj).Attack();
        break;
}
```

**✅ Modern:**
```csharp
// Good: Pattern matching
if (obj is Player player)
{
    player.TakeDamage(10);
}

// Good: Switch expression
var action = obj switch
{
    Player p => p.Attack(),
    Enemy e => e.Attack(),
    _ => 0
};
```

### 3. Unity-Specific Review

#### Component Access
**Check:**
- [ ] Is `TryGetComponent` used instead of `GetComponent` with null check?
- [ ] Is null-conditional used with Unity methods?

**❌ Verbose:**
```csharp
// Bad: GetComponent with null check
var enemy = gameObject.GetComponent<Enemy>();
if (enemy != null)
{
    enemy.TakeDamage(10);
}

// Bad: Null check before method call
var weapon = GetComponentInChildren<Weapon>();
if (weapon != null)
{
    weapon.Fire();
}
```

**✅ Concise:**
```csharp
// Good: TryGetComponent
if (gameObject.TryGetComponent<Enemy>(out var enemy))
{
    enemy.TakeDamage(10);
}

// Good: Null-conditional
GetComponentInChildren<Weapon>()?.Fire();
```

#### MonoBehaviour Lifecycle
**Check:**
- [ ] Are Unity lifecycle methods ordered correctly?
- [ ] Is proper cleanup in OnDestroy()?

**✅ Correct Order:**
```csharp
public class MyBehaviour : MonoBehaviour
{
    // Awake → OnEnable → Start → Update → LateUpdate → OnDisable → OnDestroy

    private void Awake() { }

    private void OnEnable() { }

    private void Start() { }

    private void Update() { }

    private void LateUpdate() { }

    private void OnDisable() { }

    private void OnDestroy()
    {
        // Cleanup subscriptions, unsubscribe from events
    }
}
```

### 4. Performance Review

#### Allocation Checks
**Check:**
- [ ] Are allocations in Update/FixedUpdate avoided?
- [ ] Are object pools used for frequent instantiation?
- [ ] Are string concatenations optimized?

**❌ Performance Issues:**
```csharp
// Bad: Allocation in Update
private void Update()
{
    var enemies = new List<Enemy>(); // ❌ Allocates every frame
    var position = new Vector3(0, 0, 0); // ❌ Unnecessary allocation
}

// Bad: String concatenation in loop
foreach (var player in players)
{
    var name = "Player: " + player.Name; // ❌ Creates garbage
}
```

**✅ Optimized:**
```csharp
// Good: Reuse collection
private List<Enemy> enemyCache = new List<Enemy>();

private void Update()
{
    this.enemyCache.Clear(); // Reuse instead of new
}

// Good: StringBuilder or string interpolation
var names = players.Select(p => $"Player: {p.Name}").ToList();
```

#### LINQ Performance
**Check:**
- [ ] Is LINQ avoided in Update/FixedUpdate hot paths?
- [ ] Are LINQ chains optimized (avoid multiple iterations)?

**❌ Performance Issue:**
```csharp
// Bad: Multiple LINQ iterations
private void Update()
{
    var active = enemies.Where(e => e.IsActive).ToList();
    var alive = active.Where(e => e.Health > 0).ToList();
    var close = alive.Where(e => Vector3.Distance(e.transform.position, transform.position) < 10f).ToList();
}
```

**✅ Optimized:**
```csharp
// Good: Single iteration
private void Update()
{
    var closeEnemies = enemies
        .Where(e => e.IsActive
                 && e.Health > 0
                 && Vector3.Distance(e.transform.position, transform.position) < 10f)
        .ToList();
}

// Even better: Cache and use for loop for hot paths
private void Update()
{
    for (int i = 0; i < enemies.Count; i++)
    {
        var e = enemies[i];
        if (e.IsActive && e.Health > 0 && Vector3.Distance(e.transform.position, transform.position) < 10f)
        {
            // Process
        }
    }
}
```

### 5. Testing Review

#### Test Structure
**Check:**
- [ ] Are tests organized with [TestFixture]?
- [ ] Do test names describe what they test?
- [ ] Are Arrange-Act-Assert sections clear?

**✅ Good Test:**
```csharp
[TestFixture]
public class DifficultyServiceTests
{
    [Test]
    public void RecordWin_IncreasesWinStreak()
    {
        // Arrange
        var service = new DifficultyService();

        // Act
        service.RecordWin();
        service.RecordWin();

        // Assert
        Assert.AreEqual(2, service.CurrentWinStreak);
    }

    [Test]
    public void RecordLoss_ResetsWinStreak()
    {
        // Arrange
        var service = new DifficultyService();
        service.RecordWin();

        // Act
        service.RecordLoss();

        // Assert
        Assert.AreEqual(0, service.CurrentWinStreak);
    }
}
```

### 6. Documentation Review

#### Code Comments
**Check:**
- [ ] Are complex algorithms explained?
- [ ] Are TODOs tracked and prioritized?
- [ ] Are public APIs documented with XML comments?
- [ ] Is obsolete code marked with [Obsolete]?

**✅ Good Documentation:**
```csharp
/// <summary>
/// Calculates dynamic difficulty based on player performance.
/// Uses exponential moving average for smooth adjustments.
/// </summary>
/// <param name="recentPerformance">Last N game results</param>
/// <returns>Difficulty value between 0 and 10</returns>
public float CalculateDifficulty(IEnumerable<GameResult> recentPerformance)
{
    // TODO(tuha): Consider player skill level for initial difficulty
    // TODO(priority: high): Add configurable smoothing factor

    // Complex algorithm explanation
    var weights = Enumerable.Range(0, 10)
        .Select(i => Mathf.Exp(-i * 0.2f)) // Exponential decay
        .ToArray();

    // ... implementation
}

[Obsolete("Use CalculateDifficultyV2 instead")]
public float CalculateDifficultyOld() { }
```

## Code Review Checklist

Use this checklist for every code review:

### Architecture
- [ ] VContainer for DI (not Zenject)
- [ ] SignalBus for events (not MessagePipe)
- [ ] Controllers for data access (not direct)
- [ ] Constructor injection only
- [ ] IInitializable and IDisposable implemented
- [ ] All signals unsubscribed in Dispose
- [ ] [Preserve] attribute on constructors

### C# Quality
- [ ] LINQ used instead of manual loops
- [ ] Expression bodies for simple members
- [ ] Null-coalescing operators used
- [ ] Pattern matching for type checks
- [ ] var used for type inference
- [ ] Extension methods instead of utility classes
- [ ] Modern C# features (records, init, with)

### Unity-Specific
- [ ] TryGetComponent instead of GetComponent + null check
- [ ] Null-conditional with Unity methods
- [ ] Lifecycle methods in correct order
- [ ] Proper cleanup in OnDestroy/Dispose

### Performance
- [ ] No allocations in Update/FixedUpdate
- [ ] Object pooling for frequent instantiation
- [ ] LINQ avoided in hot paths
- [ ] String operations optimized

### Testing
- [ ] Unit tests for business logic
- [ ] Test names are descriptive
- [ ] Arrange-Act-Assert structure
- [ ] Edge cases covered

### Documentation
- [ ] Complex logic explained
- [ ] Public APIs documented
- [ ] TODOs tracked
- [ ] Obsolete code marked

## Review Severity Levels

### 🔴 Critical (Must Fix)
- Using Zenject instead of VContainer
- Using MessagePipe instead of SignalBus
- Direct data access (not using Controllers)
- Memory leaks (not unsubscribing)
- Missing IDisposable implementation

### 🟡 Important (Should Fix)
- Verbose code instead of LINQ
- Missing [Preserve] attribute
- Performance issues in hot paths
- Missing unit tests for business logic
- No XML documentation on public APIs

### 🟢 Nice to Have (Suggestion)
- Could use expression body
- Could use null-conditional
- Could use pattern matching
- Could add more comments
- Could improve naming

## Automated Review Tools

### Suggested Tools for CI/CD
- **Roslyn Analyzers** - C# code quality
- **Unity Code Analysis** - Unity-specific issues
- **SonarQube** - Code smells and bugs
- **dotnet format** - Code style enforcement

### Example .editorconfig
```ini
[*.cs]
# Use var when type is obvious
csharp_style_var_for_built_in_types = true
csharp_style_var_when_type_is_apparent = true

# Expression-bodied members
csharp_style_expression_bodied_methods = when_on_single_line
csharp_style_expression_bodied_properties = true

# Null checking
csharp_style_conditional_delegate_call = true
csharp_style_throw_expression = true

# Pattern matching
csharp_style_pattern_matching_over_as_with_null_check = true
csharp_style_pattern_matching_over_is_with_cast_check = true
```

## Summary

Every code review should verify:
1. **Architecture**: VContainer, SignalBus, Controllers pattern followed
2. **Code Quality**: Concise, idiomatic C# using modern features
3. **Unity Best Practices**: Proper lifecycle, component access, cleanup
4. **Performance**: No allocations in hot paths, optimized LINQ
5. **Testing**: Business logic covered with unit tests
6. **Documentation**: Complex logic explained, APIs documented

This ensures code quality, maintainability, and team consistency across TheOne Studio Unity projects.
