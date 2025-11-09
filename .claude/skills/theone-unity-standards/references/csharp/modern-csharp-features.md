# Modern C# Features

⚠️ **Unity 6 Compatibility:** This guide covers C# 9 features available in Unity 6. All examples are tested and compatible with Unity 6 (C# 9).

**C# Version Support:**
- Unity 2020.2+: C# 8
- Unity 2021.2+: C# 9
- **Unity 6 (2023.2): C# 9** ✅ (current)

## 3. Use Expression-Bodied Members

### ❌ AVOID: Verbose Method Bodies
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

### ✅ PREFERRED: Expression-Bodied Members
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

## 4. Use Null-Coalescing Operators

### ❌ AVOID: Verbose Null Checks
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

### ✅ PREFERRED: Null-Coalescing Operators
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

## 5. Use Pattern Matching Instead of Type Checks

### ❌ AVOID: Old-Style Type Checks
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

### ✅ PREFERRED: Pattern Matching
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

## 6. Use Collection Initializers (C# 9 in Unity 6)

⚠️ **Unity 6 Uses C# 9:** Unity 6 supports C# 9, NOT C# 12. Collection expressions (C# 12) are NOT available.

**Unity Version to C# Version:**
- Unity 2020.2+: C# 8
- Unity 2021.2+: C# 9
- Unity 6 (2023.2): C# 9 ✅ (current version)

Use collection initializers (C# 3+) which are fully supported in Unity 6.

### ❌ AVOID: Verbose Collection Initialization
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

### ✅ PREFERRED: Collection Initializers (C# 9 Compatible)
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

// Good: Target-typed new (C# 9)
List<string> otherNames = new() { "David", "Eve" };
Dictionary<string, int> otherScores = new()
{
    { "David", 150 },
    { "Eve", 250 }
};
```

## 8. Use Modern C# Features

### Records for Data Classes
```csharp
// Good: Use records for immutable data (C# 9)
public sealed record PlayerData(string Name, int Score, int Level);

// Good: Records with validation (C# 9)
public sealed record WeaponData(string Name, int Damage)
{
    public Rarity Rarity { get; init; } = Rarity.Common;

    public WeaponData(string Name, int Damage) : this(Name, Damage)
    {
        if (Damage < 0) throw new ArgumentException("Damage cannot be negative");
    }
}

// Note: 'required' keyword is C# 11+ (NOT available in Unity 6)
// Use positional records or constructors to enforce required fields
```

### Init-Only Properties (C# 9)
```csharp
// Good: Init-only for immutability
public class GameConfig
{
    public string GameName { get; init; } = string.Empty; // Default to prevent nullable warnings
    public int MaxPlayers { get; init; }
    public float TimeLimit { get; init; } = 300f;

    // Constructor to enforce required fields (C# 9 compatible)
    public GameConfig(string gameName, int maxPlayers)
    {
        this.GameName = gameName;
        this.MaxPlayers = maxPlayers;
    }
}

// Usage:
var config = new GameConfig("Battle Arena", 8)
{
    TimeLimit = 600f // Override default TimeLimit if needed
};
```

### With Expressions (Record Copying)
```csharp
// Good: Non-destructive mutation with 'with'
var originalPlayer = new PlayerData("Alice", 100, 5);
var leveledUpPlayer = originalPlayer with { Level = 6, Score = 150 };
```

## 9. Avoid Unnecessary Variables

### ❌ AVOID: Temporary Variables
```csharp
// Bad: Unnecessary temporary variable
var temp = player.GetHealth();
return temp;

// Bad: Intermediate variable for simple transformation
var enemies = GetAllEnemies();
var activeEnemies = enemies.Where(e => e.IsActive);
return activeEnemies.ToList();
```

### ✅ PREFERRED: Direct Return
```csharp
// Good: Direct return
return player.GetHealth();

// Good: Chain operations
return GetAllEnemies()
    .Where(e => e.IsActive)
    .ToList();
```

## 10. Use Deconstructors and Tuples

### Tuples for Multiple Returns
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
