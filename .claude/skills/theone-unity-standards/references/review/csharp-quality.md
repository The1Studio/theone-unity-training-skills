# C# Code Quality Review

## LINQ vs Manual Loops

### Check List
- [ ] Are manual loops replaced with LINQ where appropriate?
- [ ] Is LINQ readable and not over-complicated?

### Common Violations

#### ❌ Verbose Manual Loop
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

### ✅ Concise LINQ
```csharp
// Good: LINQ
var activeEnemies = allEnemies
    .Where(e => e.IsActive && e.Health > 0)
    .ToList();

// Good: Count
var count = players.Count(p => p.Score > 100);
```

## Expression-Bodied Members

### Check List
- [ ] Are simple methods using `=>`?
- [ ] Are simple properties using `=>`?

### Common Violations

#### ❌ Verbose Full Body
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

### ✅ Concise Expression Body
```csharp
// Good: Expression body
public int GetHealth() => this.currentHealth;

public string Name => this.name;
```

## Null Handling

### Check List
- [ ] Is `??` used instead of verbose null checks?
- [ ] Is `?.` used for null-conditional access?
- [ ] Is `??=` used for lazy initialization?

### Common Violations

#### ❌ Verbose Null Checks
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

### ✅ Concise Null Handling
```csharp
// Good: Null coalescing
var result = playerName ?? "Unknown";

// Good: Null-conditional
var damage = player?.Weapon?.Damage ?? 0;

// Good: Null-coalescing assignment
this.cache ??= new Dictionary<string, int>();
```

## Pattern Matching

### Check List
- [ ] Is pattern matching used instead of type checks?
- [ ] Are switch expressions used where appropriate?

### Common Violations

#### ❌ Old Style Type Checks
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

### ✅ Modern Pattern Matching
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

## Collection Initialization

### Common Violations

#### ❌ Verbose Initialization
```csharp
// Bad: Verbose collection init
var list = new List<string>();
list.Add("Item1");
list.Add("Item2");
list.Add("Item3");

// Bad: Verbose dictionary init
var dict = new Dictionary<string, int>();
dict.Add("Health", 100);
dict.Add("Mana", 50);
```

### ✅ Concise Initialization
```csharp
// Good: Collection initializer
var list = new List<string> { "Item1", "Item2", "Item3" };

// Good: Dictionary initializer
var dict = new Dictionary<string, int>
{
    ["Health"] = 100,
    ["Mana"] = 50
};
```

## String Interpolation

### Common Violations

#### ❌ String Concatenation
```csharp
// Bad: String concatenation
var message = "Player " + playerName + " scored " + score + " points";

// Bad: String.Format
var message = string.Format("Player {0} scored {1} points", playerName, score);
```

### ✅ String Interpolation
```csharp
// Good: String interpolation
var message = $"Player {playerName} scored {score} points";

// Good: With formatting
var message = $"Time: {time:F2}s, Score: {score:N0}";
```

## var Usage

### Check List
- [ ] Is `var` used when type is obvious from right side?

### Common Violations

#### ❌ Explicit Types When Obvious
```csharp
// Bad: Type is obvious
List<Enemy> enemies = new List<Enemy>();
Dictionary<string, int> scores = new Dictionary<string, int>();
PlayerController controller = GetComponent<PlayerController>();
```

### ✅ var When Obvious
```csharp
// Good: Use var
var enemies = new List<Enemy>();
var scores = new Dictionary<string, int>();
var controller = GetComponent<PlayerController>();
```

## Extension Methods

### Common Violations

#### ❌ Utility Classes
```csharp
// Bad: Static utility class
public static class VectorUtils
{
    public static bool IsNearZero(Vector3 vector)
    {
        return vector.magnitude < 0.01f;
    }
}

// Usage
if (VectorUtils.IsNearZero(velocity))
```

### ✅ Extension Methods
```csharp
// Good: Extension method
public static class VectorExtensions
{
    public static bool IsNearZero(this Vector3 vector)
    {
        return vector.magnitude < 0.01f;
    }
}

// Usage
if (velocity.IsNearZero())
```

## Complete Example

### ❌ Verbose Code (Multiple Issues)
```csharp
public class PlayerManager
{
    private Dictionary<string, Player> players;

    public List<Player> GetActivePlayers()
    {
        List<Player> result = new List<Player>();
        foreach (var kvp in this.players)
        {
            Player player = kvp.Value;
            if (player != null && player.IsActive)
            {
                result.Add(player);
            }
        }
        return result;
    }

    public string GetPlayerName(string id)
    {
        Player player = null;
        if (this.players.ContainsKey(id))
        {
            player = this.players[id];
        }

        if (player != null)
        {
            return player.Name;
        }
        else
        {
            return "Unknown";
        }
    }
}
```

### ✅ Concise Code (Fixed)
```csharp
public class PlayerManager
{
    private Dictionary<string, Player> players = new();

    public List<Player> GetActivePlayers() =>
        this.players.Values
            .Where(p => p.IsActive)
            .ToList();

    public string GetPlayerName(string id) =>
        this.players.TryGetValue(id, out var player)
            ? player.Name
            : "Unknown";
}
```

## Review Severity

### 🟡 Important Issues
- Using manual loops instead of LINQ
- Verbose null checks instead of null operators
- Not using expression bodies for simple members
- Not using pattern matching
- Not using var when type is obvious

### 🟢 Suggestions
- Could use collection initializers
- Could use string interpolation
- Could use extension methods instead of utility classes
- Could use switch expressions
