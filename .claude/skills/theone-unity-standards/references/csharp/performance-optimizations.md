# Performance Optimizations

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
