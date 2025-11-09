# LINQ Patterns

## 1. Use LINQ Instead of Verbose Loops

### ❌ AVOID: Verbose Loops
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

### ✅ PREFERRED: LINQ
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

## 2. Use Extension Methods Instead of Utility Classes

### ❌ AVOID: Static Utility Classes
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

### ✅ PREFERRED: Extension Methods
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

## 7. Use var for Type Inference

### ❌ AVOID: Redundant Type Declarations
```csharp
// Bad: Redundant type on both sides
Dictionary<string, List<Player>> playerGroups = new Dictionary<string, List<Player>>();
List<Enemy> enemies = new List<Enemy>();
Player player = new Player();
```

### ✅ PREFERRED: var for Clarity
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

## LINQ Performance Optimizations

### Use .ToArray() vs .ToList()

```csharp
// ✅ GOOD: ToArray() when not modifying
public IReadOnlyList<Enemy> GetActiveEnemies()
{
    return enemies.Where(e => e.IsActive).ToArray(); // Readonly, no modification needed
}

// ✅ GOOD: ToList() when modifying
public List<Enemy> GetModifiableEnemies()
{
    var list = enemies.Where(e => e.IsActive).ToList();
    list.Add(newEnemy); // Will be modified
    return list;
}
```

### Use Readonly Collection Interfaces

```csharp
// ✅ GOOD: Readonly interfaces when no modification needed
public IReadOnlyList<string> Names { get; }
public IReadOnlyCollection<Player> Players { get; }
public IReadOnlyDictionary<string, int> Scores { get; }

// ❌ BAD: Mutable interfaces when readonly is sufficient
public List<string> Names { get; } // Allows external modification
public Dictionary<string, int> Scores { get; } // Exposes mutability
```

### Avoid Unnecessary Enumeration

```csharp
// ✅ GOOD: Don't enumerate if not needed
var query = items.Where(i => i.IsValid); // IEnumerable, not yet evaluated
if (needsList)
{
    return query.ToList(); // Enumerate only when needed
}
return query;

// ❌ BAD: Premature enumeration
var list = items.Where(i => i.IsValid).ToList(); // Always allocates
if (needsList)
{
    return list;
}
return list; // Wasted allocation if enumeration not needed
```
