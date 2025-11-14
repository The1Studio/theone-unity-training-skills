# C# Quality & Code Hygiene

## Enable Nullable Reference Types

```csharp
// ✅ GOOD: Enable nullable annotations in .csproj
<PropertyGroup>
    <Nullable>enable</Nullable>
</PropertyGroup>

// Declare nullable explicitly
public string? OptionalName { get; set; } // Can be null
public string RequiredName { get; set; } = string.Empty; // Never null

// ❌ BAD: Ignoring nullability
public string Name { get; set; } // Warning: Non-nullable property must contain non-null value
```

## Use Least Accessible Access Modifier

```csharp
// ✅ GOOD: Most restrictive access
private readonly IService service; // Only accessible in this class
internal sealed class Helper { } // Only accessible in this assembly
public interface IPublicApi { } // Public only when necessary

// ❌ BAD: Everything public
public IService service; // Unnecessarily exposed
public class Helper { } // Should be internal
```

## Fix All Warnings

**Rule:** Treat warnings as errors. Never ignore compiler warnings.

```csharp
// ✅ GOOD: Fix warnings
#pragma warning disable CS0649 // Field is never assigned - FIX THE CODE INSTEAD

// Better: Actually fix the issue
private readonly string name = string.Empty;
```

## Throw Exceptions for Errors (+ Proper Logging)

**Critical Rule**: Throw exceptions instead of logging errors or returning defaults.

**Logging Guidelines:**
- **TheOne.Logging.ILogger**: Use for runtime scripts (informational logs)
  - ✅ ILogger handles conditional compilation internally (no #if guards needed)
  - ✅ ILogger handles prefixes automatically (no [prefix] needed)
  - ❌ NEVER log in constructors (keep constructors fast and side-effect free)
  - ❌ Remove verbose logs (keep only necessary logs)
  - ❌ No null-conditional operator (DI guarantees non-null: use `this.logger.Debug()` not `this.logger?.Debug()`)
- **Debug.Log**: Use ONLY for editor scripts (#if UNITY_EDITOR)
- **Exceptions**: Use for errors (never log errors - throw!)

```csharp
// ✅ EXCELLENT: TheOne.Logging.ILogger for runtime
public sealed class GameService
{
    private readonly TheOne.Logging.ILogger logger;

    public GameService(TheOne.Logging.ILogger logger)
    {
        this.logger = logger;
    }

    public Player GetPlayer(string id)
    {
        return players.TryGetValue(id, out var player)
            ? player
            : throw new KeyNotFoundException($"Player not found: {id}");
    }

    public void StartGame()
    {
        this.logger.Info("Game started");
        this.LoadLevel(1);
    }

    private void ProcessGameData()
    {
        this.logger.Debug("Processing critical game data");
    }
}

// ✅ GOOD: Debug.Log ONLY in editor scripts
#if UNITY_EDITOR
public class EditorTool
{
    public void ProcessAssets()
    {
        Debug.Log("Processing assets...");
    }
}
#endif

// ❌ WRONG: Conditional compilation guards (ILogger handles this)
public void StartGame()
{
#if UNITY_EDITOR || DEVELOPMENT_BUILD
    this.logger.Info("Game started");
#endif
}

// ❌ WRONG: Manual prefixes (ILogger handles this)
public void StartGame()
{
    this.logger.Info("[GameService] Game started");
}

// ❌ WRONG: Logging in constructor
public GameService(TheOne.Logging.ILogger logger)
{
    this.logger = logger;
    this.logger.Info("GameService created");
}

// ❌ WRONG: Null-conditional operator (DI guarantees non-null)
public void StartGame()
{
    this.logger?.Info("Game started");
}

// ❌ WRONG: Verbose unnecessary logs
public void ProcessItem(Item item)
{
    this.logger.Debug("Entering ProcessItem");
    this.logger.Debug($"Item: {item}");
    var result = item.Calculate();
    this.logger.Debug($"Result: {result}");
    return result;
}

// ❌ WRONG: Return default or log errors
public Player GetPlayer(string id)
{
    if (!players.TryGetValue(id, out var player))
    {
        this.logger.Error("Player not found");
        return null;
    }
    return player;
}

// ❌ WRONG: Debug.Log in runtime code
public void StartGame()
{
    Debug.Log("Game started");
}
```

**Why This Matters:**
- **Exceptions**: Force callers to handle errors properly
- **TheOne.Logging.ILogger**: Structured logging for production with automatic prefix/guard handling
- **Debug.Log**: Only for editor development, stripped from builds
- **No Constructor Logging**: Constructors should be fast and side-effect free
- **No Null Checks**: DI container guarantees non-null dependencies

## Use nameof Instead of String Literals

```csharp
// ✅ GOOD: Use nameof
public void SetName(string value)
{
    ArgumentNullException.ThrowIfNull(value, nameof(value));
    this.name = value;
}

// ❌ BAD: String literals
public void SetName(string value)
{
    if (value == null) throw new ArgumentNullException("value"); // Can break on refactoring
}
```

## Use Using Directive in Deepest Scope

```csharp
// ✅ GOOD: Using in deepest scope (method level)
public void ProcessPlayerData()
{
    using System.Text.Json;

    var json = JsonSerializer.Serialize(this.playerData);
    File.WriteAllText("player.json", json);
}

public void ProcessEnemyData()
{
    // JsonSerializer not needed here, no using directive
    var data = this.enemyData.ToString();
}

// ❌ BAD: Using at file level when only used in one method
using System.Text.Json; // File level - only used in ProcessPlayerData

namespace MyGame
{
    public class DataProcessor
    {
        public void ProcessPlayerData()
        {
            var json = JsonSerializer.Serialize(this.playerData);
        }
    }
}
```

**Benefits:**
- Reduces namespace pollution
- Makes dependencies explicit per scope
- Easier to refactor and move code

## Use readonly and const

```csharp
// ✅ GOOD: readonly for non-reassigned fields
private readonly IService service;
private readonly List<string> names = new();

// ✅ GOOD: const for constants
private const int MaxPlayers = 10;
private const string DefaultName = "Player";

// ❌ BAD: Mutable when not needed
private IService service; // Should be readonly
private int maxPlayers = 10; // Should be const
```

## Add Trailing Commas

```csharp
// ✅ GOOD: Trailing commas (easier diffs)
var player = new Player
{
    Name = "Alice",
    Score = 100,
    Level = 5, // ← Trailing comma
};

var items = new[]
{
    "sword",
    "shield",
    "potion", // ← Trailing comma
};

// ❌ BAD: No trailing comma
var player = new Player
{
    Name = "Alice",
    Score = 100,
    Level = 5 // Hard to add new properties
};
```

## No Inline Comments

```csharp
// ✅ GOOD: Descriptive names, no inline comments
var activeEnemiesInRange = enemies
    .Where(e => e.IsActive)
    .Where(e => Vector3.Distance(e.Position, playerPosition) < attackRange)
    .ToList();

// ❌ BAD: Inline comments
var enemies = allEnemies.Where(e => e.IsActive) // filter active enemies
    .Where(e => Vector3.Distance(e.Position, playerPosition) < 10f) // check range
    .ToList(); // convert to list
```
