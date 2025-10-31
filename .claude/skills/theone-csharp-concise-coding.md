# TheOne Studio C# Concise Coding Standards

## Skill Purpose
This skill enforces TheOne Studio's C# coding standards, ensuring engineers write concise, idiomatic, and professional C# code using modern language features, LINQ, extension methods, and pattern matching.

## When This Skill Triggers
- When writing any C# code (Unity or non-Unity)
- When reviewing or refactoring existing C# code
- When converting verbose code to concise patterns
- When implementing new features in C#

## Core Principles

### 1. **Use LINQ Instead of Verbose Loops**

#### ❌ AVOID: Verbose Loops
```csharp
// Bad: Manual loop with temporary list
List<Enemy> activeEnemies = new List<Enemy>();
foreach (var enemy in allEnemies)
{
    if (enemy.IsActive)
    {
        activeEnemies.Add(enemy);
    }
}

// Bad: Loop for counting
int count = 0;
foreach (var item in items)
{
    if (item.IsValid)
    {
        count++;
    }
}

// Bad: Loop for transformation
List<string> names = new List<string>();
foreach (var player in players)
{
    names.Add(player.Name);
}
```

#### ✅ PREFERRED: LINQ
```csharp
// Good: Filter with Where
var activeEnemies = allEnemies.Where(e => e.IsActive).ToList();

// Good: Count with Count
var count = items.Count(item => item.IsValid);

// Good: Transform with Select
var names = players.Select(p => p.Name).ToList();

// Good: Complex queries
var topScorers = players
    .Where(p => p.Score > 1000)
    .OrderByDescending(p => p.Score)
    .Take(10)
    .Select(p => new { p.Name, p.Score })
    .ToList();
```

### 2. **Use Extension Methods Instead of Utility Classes**

#### ❌ AVOID: Static Utility Classes
```csharp
// Bad: Utility class with static methods
public static class StringUtility
{
    public static bool IsNullOrEmpty(string value)
    {
        return string.IsNullOrEmpty(value);
    }

    public static string Capitalize(string value)
    {
        if (string.IsNullOrEmpty(value)) return value;
        return char.ToUpper(value[0]) + value.Substring(1);
    }
}

// Usage (bad):
var result = StringUtility.Capitalize(text);
```

#### ✅ PREFERRED: Extension Methods
```csharp
// Good: Extension methods
public static class StringExtensions
{
    public static bool IsNullOrEmpty(this string value)
    {
        return string.IsNullOrEmpty(value);
    }

    public static string Capitalize(this string value)
    {
        return string.IsNullOrEmpty(value)
            ? value
            : char.ToUpper(value[0]) + value.Substring(1);
    }

    public static string OrDefault(this string value, string defaultValue = "")
    {
        return value.IsNullOrEmpty() ? defaultValue : value;
    }
}

// Usage (good):
var result = text.Capitalize();
var name = playerName.OrDefault("Unknown");
```

### 3. **Use Expression-Bodied Members**

#### ❌ AVOID: Verbose Method Bodies
```csharp
// Bad: Single-line methods with full body
public int GetHealth()
{
    return this.currentHealth;
}

public bool IsAlive()
{
    return this.currentHealth > 0;
}

// Bad: Simple property getters
private string name;
public string Name
{
    get { return this.name; }
}
```

#### ✅ PREFERRED: Expression-Bodied Members
```csharp
// Good: Expression-bodied methods
public int GetHealth() => this.currentHealth;

public bool IsAlive() => this.currentHealth > 0;

// Good: Expression-bodied properties
public string Name => this.name;

public string FullName => $"{this.firstName} {this.lastName}";

// Good: Expression-bodied property with setter
public string DisplayName
{
    get => this.displayName ?? this.name;
    set => this.displayName = value;
}
```

### 4. **Use Null-Coalescing Operators**

#### ❌ AVOID: Verbose Null Checks
```csharp
// Bad: Verbose null checks
string result;
if (playerName != null)
{
    result = playerName;
}
else
{
    result = "Unknown";
}

// Bad: Nested null checks
if (player != null)
{
    if (player.Weapon != null)
    {
        var damage = player.Weapon.Damage;
    }
}

// Bad: Manual null assignment
if (this.cache == null)
{
    this.cache = new Dictionary<string, object>();
}
```

#### ✅ PREFERRED: Null-Coalescing Operators
```csharp
// Good: Null coalescing (??)
var result = playerName ?? "Unknown";

// Good: Null-conditional (?.)
var damage = player?.Weapon?.Damage ?? 0;

// Good: Null-coalescing assignment (??=)
this.cache ??= new Dictionary<string, object>();

// Good: Null-coalescing with method calls
var position = transform?.position ?? Vector3.zero;
var count = items?.Count ?? 0;
```

### 5. **Use Pattern Matching Instead of Type Checks**

#### ❌ AVOID: Old-Style Type Checks
```csharp
// Bad: Type check with cast
if (obj is Player)
{
    Player player = (Player)obj;
    player.TakeDamage(10);
}

// Bad: Type check with as operator
Player player = obj as Player;
if (player != null)
{
    player.TakeDamage(10);
}

// Bad: Switch with type checks
switch (obj.GetType().Name)
{
    case "Player":
        ((Player)obj).TakeDamage(10);
        break;
    case "Enemy":
        ((Enemy)obj).TakeDamage(20);
        break;
}
```

#### ✅ PREFERRED: Pattern Matching
```csharp
// Good: Pattern matching with is
if (obj is Player player)
{
    player.TakeDamage(10);
}

// Good: Switch with pattern matching
var damage = obj switch
{
    Player player => player.TakeDamage(10),
    Enemy enemy => enemy.TakeDamage(20),
    Boss boss => boss.TakeDamage(50),
    _ => 0
};

// Good: Property pattern matching
if (weapon is { Damage: > 100, Rarity: Rarity.Legendary })
{
    ApplyBonusDamage(weapon);
}
```

### 6. **Use Collection Expressions (C# 12+)**

#### ❌ AVOID: Verbose Collection Initialization
```csharp
// Bad: Explicit collection initialization
List<string> names = new List<string>();
names.Add("Alice");
names.Add("Bob");
names.Add("Charlie");

// Bad: Array initialization
int[] numbers = new int[] { 1, 2, 3, 4, 5 };

// Bad: Dictionary initialization
Dictionary<string, int> scores = new Dictionary<string, int>();
scores.Add("Alice", 100);
scores.Add("Bob", 200);
```

#### ✅ PREFERRED: Collection Expressions
```csharp
// Good: Collection initializers
var names = new List<string> { "Alice", "Bob", "Charlie" };

// Good: Array initialization (concise)
int[] numbers = { 1, 2, 3, 4, 5 };

// Good: Dictionary initializers
var scores = new Dictionary<string, int>
{
    { "Alice", 100 },
    { "Bob", 200 },
    { "Charlie", 300 }
};

// Good (C# 12+): Collection expressions
List<string> names = ["Alice", "Bob", "Charlie"];
int[] numbers = [1, 2, 3, 4, 5];
```

### 7. **Use var for Type Inference**

#### ❌ AVOID: Redundant Type Declarations
```csharp
// Bad: Redundant type on both sides
Dictionary<string, List<Player>> playerGroups = new Dictionary<string, List<Player>>();
List<Enemy> enemies = new List<Enemy>();
Player player = new Player();
```

#### ✅ PREFERRED: var for Clarity
```csharp
// Good: Use var when type is obvious
var playerGroups = new Dictionary<string, List<Player>>();
var enemies = new List<Enemy>();
var player = new Player();

// Good: var with LINQ
var activeEnemies = allEnemies.Where(e => e.IsActive).ToList();

// Still OK to be explicit when type is not obvious
IEnumerable<Player> query = GetPlayers(); // OK if needed for interface type
```

### 8. **Use Modern C# Features**

#### Records for Data Classes
```csharp
// Good: Use records for immutable data
public sealed record PlayerData(string Name, int Score, int Level);

// Good: Records with validation
public sealed record WeaponData
{
    public required string Name { get; init; }
    public required int Damage { get; init; }
    public Rarity Rarity { get; init; } = Rarity.Common;

    public WeaponData
    {
        if (Damage < 0) throw new ArgumentException("Damage cannot be negative");
    }
}
```

#### Init-Only Properties
```csharp
// Good: Init-only for immutability
public class GameConfig
{
    public required string GameName { get; init; }
    public required int MaxPlayers { get; init; }
    public float TimeLimit { get; init; } = 300f;
}

// Usage:
var config = new GameConfig
{
    GameName = "MyGame",
    MaxPlayers = 10
};
```

#### With Expressions (Record Copying)
```csharp
// Good: Non-destructive mutation with 'with'
var originalPlayer = new PlayerData("Alice", 100, 5);
var leveledUpPlayer = originalPlayer with { Level = 6, Score = 150 };
```

### 9. **Avoid Unnecessary Variables**

#### ❌ AVOID: Temporary Variables
```csharp
// Bad: Unnecessary temporary variable
var temp = player.GetHealth();
return temp;

// Bad: Intermediate variable for simple transformation
var enemies = GetAllEnemies();
var activeEnemies = enemies.Where(e => e.IsActive);
return activeEnemies.ToList();
```

#### ✅ PREFERRED: Direct Return
```csharp
// Good: Direct return
return player.GetHealth();

// Good: Chain operations
return GetAllEnemies()
    .Where(e => e.IsActive)
    .ToList();
```

### 10. **Use Deconstructors and Tuples**

#### Tuples for Multiple Returns
```csharp
// Good: Return multiple values with tuples
public (int health, int mana) GetStats()
{
    return (this.currentHealth, this.currentMana);
}

// Usage with deconstruction:
var (health, mana) = player.GetStats();

// Good: Named tuple members
public (int Health, int Mana, int Stamina) GetFullStats()
{
    return (Health: this.health, Mana: this.mana, Stamina: this.stamina);
}
```

## Unity-Specific Concise Patterns

### Component Access
```csharp
// Good: Null-conditional with TryGetComponent
if (gameObject.TryGetComponent<Enemy>(out var enemy))
{
    enemy.TakeDamage(10);
}

// Good: GetComponentInChildren with null-conditional
transform.GetComponentInChildren<Weapon>()?.Fire();

// Good: LINQ with GetComponentsInChildren
var allWeapons = GetComponentsInChildren<Weapon>()
    .Where(w => w.IsActive)
    .ToList();
```

### Vector Operations
```csharp
// Good: Concise vector calculations
var direction = (target.position - transform.position).normalized;
var distance = Vector3.Distance(a, b);
var midpoint = (a + b) / 2f;

// Good: Null-conditional for nullable transforms
var position = targetTransform?.position ?? Vector3.zero;
```

## Code Review Checklist

When reviewing C# code, check for:

- [ ] **LINQ Usage**: Are loops being used where LINQ would be more concise?
- [ ] **Extension Methods**: Are utility methods appropriate candidates for extensions?
- [ ] **Expression Bodies**: Can simple methods/properties use `=>`?
- [ ] **Null Handling**: Are null checks using `??`, `?.`, or `??=`?
- [ ] **Pattern Matching**: Are type checks using modern pattern matching?
- [ ] **var Usage**: Is `var` being used appropriately?
- [ ] **Unnecessary Variables**: Can any temporary variables be eliminated?
- [ ] **Modern Features**: Are records, init, or with expressions applicable?
- [ ] **Collection Initialization**: Are collections using concise initializers?
- [ ] **Tuples**: Would tuples improve multiple return values?

## When to Prioritize Readability Over Conciseness

Sometimes verbose code is more readable. Prefer verbose when:

1. **Complex Logic**: Multi-step calculations are clearer with intermediate variables
2. **Debugging**: Temporary variables help when stepping through debugger
3. **Team Familiarity**: Junior team members may need more explicit code
4. **Performance-Critical**: Manual loops may be faster than LINQ in hot paths

```csharp
// OK: Verbose for clarity in complex logic
var baseScore = player.Kills * 100;
var bonusScore = player.Assists * 50;
var timeBonus = CalculateTimeBonus(player.CompletionTime);
var finalScore = (baseScore + bonusScore + timeBonus) * player.Multiplier;

// Instead of one-liner that's hard to read:
var finalScore = (player.Kills * 100 + player.Assists * 50 +
    CalculateTimeBonus(player.CompletionTime)) * player.Multiplier;
```

## Summary

**Default to concise, idiomatic C# code:**
- Use LINQ over manual loops
- Prefer extension methods over utility classes
- Use expression bodies for simple members
- Leverage null-coalescing operators
- Apply pattern matching for type checks
- Use var for type inference
- Eliminate unnecessary variables
- Employ modern C# features (records, init, with)

**But balance with:**
- Readability for your team
- Debuggability when needed
- Performance in critical paths

This skill ensures TheOne Studio engineers write professional, maintainable C# code that senior engineers would be proud of.
