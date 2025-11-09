# Performance Code Review

## Allocation Checks

### Check List
- [ ] Are allocations in Update/FixedUpdate avoided?
- [ ] Are object pools used for frequent instantiation?
- [ ] Are string concatenations optimized?

### Common Violations

#### ❌ Allocations in Update
```csharp
// Bad: Allocation every frame
private void Update()
{
    var enemies = new List<Enemy>(); // ❌ Allocates every frame
    var position = new Vector3(0, 0, 0); // ❌ Unnecessary allocation
    var name = "Player: " + playerName; // ❌ String allocation
}
```

### ✅ Avoid Allocations
```csharp
// Good: Reuse collection
private List<Enemy> enemyCache = new List<Enemy>();

private void Update()
{
    this.enemyCache.Clear(); // Reuse instead of new
}

// Good: Use static properties
private void Update()
{
    var position = Vector3.zero; // No allocation
}

// Good: Cache strings or use StringBuilder
private string cachedPlayerName;

private void UpdatePlayerName()
{
    this.cachedPlayerName = $"Player: {playerName}";
}
```

## String Operations

### Common Violations

#### ❌ String Concatenation in Loops
```csharp
// Bad: String concatenation in loop
foreach (var player in players)
{
    var name = "Player: " + player.Name; // ❌ Creates garbage
    Debug.Log(name);
}

// Bad: Repeated concatenation
var result = "";
for (int i = 0; i < 100; i++)
{
    result += i.ToString(); // ❌ Creates 100 string objects
}
```

### ✅ Optimized String Operations
```csharp
// Good: String interpolation (compiled to optimized code)
foreach (var player in players)
{
    Debug.Log($"Player: {player.Name}");
}

// Good: StringBuilder for repeated concatenation
var builder = new StringBuilder();
for (int i = 0; i < 100; i++)
{
    builder.Append(i);
}
var result = builder.ToString();
```

## LINQ Performance

### Check List
- [ ] Is LINQ avoided in Update/FixedUpdate hot paths?
- [ ] Are LINQ chains optimized (avoid multiple iterations)?

### Common Violations

#### ❌ Multiple LINQ Iterations
```csharp
// Bad: Multiple LINQ iterations
private void Update()
{
    var active = enemies.Where(e => e.IsActive).ToList();
    var alive = active.Where(e => e.Health > 0).ToList();
    var close = alive.Where(e => Vector3.Distance(e.transform.position, transform.position) < 10f).ToList();
}
```

### ✅ Optimized Iterations
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

## GameObject Instantiation

### Common Violations

#### ❌ Instantiate in Loop
```csharp
// Bad: Instantiate every time
private void SpawnEnemies()
{
    for (int i = 0; i < 10; i++)
    {
        Instantiate(enemyPrefab); // ❌ Expensive
    }
}
```

### ✅ Use Object Pooling
```csharp
// Good: Use object pool
private void SpawnEnemies()
{
    for (int i = 0; i < 10; i++)
    {
        var enemy = objectPool.Get(); // ✅ Reuse from pool
        enemy.Initialize();
    }
}

private void DespawnEnemy(GameObject enemy)
{
    objectPool.Return(enemy); // ✅ Return to pool
}
```

## Component Access Performance

### Common Violations

#### ❌ Repeated GetComponent
```csharp
// Bad: GetComponent in loop
private void Update()
{
    foreach (var enemy in enemies)
    {
        var health = enemy.GetComponent<Health>(); // ❌ Expensive in loop
        health.TakeDamage(1);
    }
}
```

### ✅ Cache Components
```csharp
// Good: Cache components
private List<Health> enemyHealths = new List<Health>();

private void Start()
{
    foreach (var enemy in enemies)
    {
        enemyHealths.Add(enemy.GetComponent<Health>());
    }
}

private void Update()
{
    foreach (var health in enemyHealths)
    {
        health.TakeDamage(1);
    }
}
```

## Physics Performance

### Common Violations

#### ❌ Raycasts in Update
```csharp
// Bad: Raycast every frame
private void Update()
{
    RaycastHit hit;
    if (Physics.Raycast(transform.position, transform.forward, out hit))
    {
        // Process hit
    }
}
```

### ✅ Optimize Raycasts
```csharp
// Good: Raycast with timing
private float lastRaycastTime;
private const float RaycastInterval = 0.1f; // 10 times per second

private void Update()
{
    if (Time.time - this.lastRaycastTime < RaycastInterval)
        return;

    this.lastRaycastTime = Time.time;

    if (Physics.Raycast(transform.position, transform.forward, out var hit))
    {
        // Process hit
    }
}
```

## Collection Performance

### Common Violations

#### ❌ Wrong Collection Type
```csharp
// Bad: List for frequent lookups
private List<string> playerIds = new List<string>();

private bool HasPlayer(string id)
{
    return playerIds.Contains(id); // ❌ O(n) lookup
}
```

### ✅ Use Appropriate Collections
```csharp
// Good: HashSet for frequent lookups
private HashSet<string> playerIds = new HashSet<string>();

private bool HasPlayer(string id)
{
    return playerIds.Contains(id); // ✅ O(1) lookup
}
```

## Boxing and Unboxing

### Common Violations

#### ❌ Boxing in Hot Path
```csharp
// Bad: Boxing value types
private void Update()
{
    var dict = new Dictionary<string, object>();
    dict["health"] = 100; // ❌ Boxing int to object
    dict["damage"] = 25.5f; // ❌ Boxing float to object
}
```

### ✅ Avoid Boxing
```csharp
// Good: Use generic types
private void Update()
{
    var healthDict = new Dictionary<string, int>();
    healthDict["health"] = 100; // ✅ No boxing

    var damageDict = new Dictionary<string, float>();
    damageDict["damage"] = 25.5f; // ✅ No boxing
}
```

## Complete Performance Example

### ❌ Bad Performance Code
```csharp
public class CombatSystem : MonoBehaviour
{
    private void Update()
    {
        // ❌ Multiple allocations
        var enemies = new List<Enemy>();

        // ❌ Multiple LINQ iterations
        var activeEnemies = FindObjectsOfType<Enemy>()
            .Where(e => e.IsActive)
            .ToList();
        var aliveEnemies = activeEnemies
            .Where(e => e.Health > 0)
            .ToList();

        // ❌ GetComponent in loop
        foreach (var enemy in aliveEnemies)
        {
            var health = enemy.GetComponent<Health>();

            // ❌ String concatenation
            var name = "Enemy: " + enemy.name;
            Debug.Log(name);

            // ❌ Creating new Vector3
            var direction = new Vector3(1, 0, 0);
            enemy.transform.position += direction;
        }

        // ❌ Instantiate every time
        if (aliveEnemies.Count < 5)
        {
            Instantiate(enemyPrefab);
        }
    }
}
```

### ✅ Optimized Performance Code
```csharp
public class CombatSystem : MonoBehaviour
{
    // ✅ Cached collections
    private List<Enemy> enemies = new List<Enemy>();
    private List<Health> enemyHealths = new List<Health>();

    // ✅ Object pool
    private ObjectPool<Enemy> enemyPool;

    private void Start()
    {
        // ✅ Find and cache once
        this.enemies.AddRange(FindObjectsOfType<Enemy>());

        // ✅ Cache components
        foreach (var enemy in this.enemies)
        {
            if (enemy.TryGetComponent<Health>(out var health))
            {
                this.enemyHealths.Add(health);
            }
        }

        this.enemyPool = new ObjectPool<Enemy>(
            () => Instantiate(enemyPrefab),
            e => e.gameObject.SetActive(true),
            e => e.gameObject.SetActive(false)
        );
    }

    private void Update()
    {
        // ✅ Single iteration with for loop
        for (int i = 0; i < this.enemies.Count; i++)
        {
            var enemy = this.enemies[i];
            if (!enemy.IsActive || enemy.Health <= 0)
                continue;

            // ✅ Already cached health
            var health = this.enemyHealths[i];

            // ✅ Use Vector3.right
            enemy.transform.position += Vector3.right * Time.deltaTime;
        }

        // ✅ Use object pool
        if (this.enemies.Count < 5)
        {
            var enemy = this.enemyPool.Get();
            this.enemies.Add(enemy);
        }
    }
}
```

## Review Severity

### 🔴 Critical Performance Issues
- Allocations in Update/FixedUpdate
- LINQ in hot paths without caching
- GetComponent/Find in loops
- Instantiate without pooling

### 🟡 Important Performance Issues
- Multiple LINQ iterations
- String concatenation in loops
- Wrong collection types for use case
- Boxing in hot paths
- Repeated raycasts without throttling

### 🟢 Suggestions
- Could use StringBuilder for string building
- Could use HashSet for faster lookups
- Could cache more aggressively
- Could use object pooling
