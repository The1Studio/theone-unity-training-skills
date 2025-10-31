# TheOne Studio Unity Architecture Patterns

## Skill Purpose
This skill enforces TheOne Studio's Unity architecture patterns, ensuring engineers implement VContainer dependency injection, SignalBus events, Data Controllers, and Service/Bridge/Adapter integration correctly.

## When This Skill Triggers
- When implementing Unity features in TheOne Studio projects
- When setting up dependency injection
- When working with events and signals
- When accessing or modifying game data
- When integrating third-party systems or plugins

## Critical Framework Rules

### ⚠️ MANDATORY FRAMEWORKS

**✅ USE THESE:**
- **VContainer** (NOT Zenject) - for dependency injection
- **SignalBus** from GameFoundation (NOT MessagePipe) - for events

**❌ NEVER USE:**
- Zenject (deprecated, use VContainer)
- MessagePipe directly (use SignalBus wrapper)
- Direct data model access (use Controllers)

## 1. Dependency Injection with VContainer

### Service Registration Pattern

```csharp
// In GameLifetimeScope.cs or similar composition root
using VContainer;
using VContainer.Unity;

public class GameLifetimeScope : LifetimeScope
{
    protected override void Configure(IContainerBuilder builder)
    {
        // Register singleton services
        builder.Register<AnalyticService>(Lifetime.Singleton)
            .AsImplementedInterfaces();

        // Register as interfaces and self
        builder.Register<GameplayService>(Lifetime.Singleton)
            .AsInterfacesAndSelf();

        // Register with auto-initialization
        builder.RegisterEntryPoint<LevelService>();

        // Register controllers
        builder.Register<UITemplateLevelDataController>(Lifetime.Singleton);

        // Register components in scene
        builder.RegisterComponentInHierarchy<ToastController>();

        // Register components in new prefab
        builder.RegisterComponentInNewPrefabResource<PlayerController>(
            nameof(PlayerController),
            Lifetime.Singleton
        ).UnderTransform(this.transform);
    }
}
```

### Service Implementation Pattern

```csharp
namespace TheOneStudio.YourFeature.Services
{
    using GameFoundation.Signals;
    using VContainer.Unity;

    public sealed class YourService : IInitializable, IDisposable
    {
        #region Dependency Injection

        private readonly SignalBus signalBus;
        private readonly IAnalyticServices analyticService;
        private readonly UITemplateDataController dataController;

        public YourService(
            SignalBus signalBus,
            IAnalyticServices analyticService,
            UITemplateDataController dataController)
        {
            this.signalBus = signalBus;
            this.analyticService = analyticService;
            this.dataController = dataController;
        }

        #endregion

        #region IInitializable Implementation

        void IInitializable.Initialize()
        {
            // Subscribe to signals
            this.signalBus.Subscribe<WonSignal>(this.OnWon);
            this.signalBus.Subscribe<LostSignal>(this.OnLost);

            // Initialize service logic
            this.LoadConfiguration();
        }

        #endregion

        #region Signal Handlers

        private void OnWon(WonSignal signal)
        {
            // Handle win event
            var currentLevel = this.dataController.CurrentLevel;
            this.analyticService.Track("level_won", ("level", currentLevel));
        }

        private void OnLost(LostSignal signal)
        {
            // Handle loss event
        }

        #endregion

        #region IDisposable Implementation

        void IDisposable.Dispose()
        {
            // Always unsubscribe from signals
            this.signalBus.TryUnsubscribe<WonSignal>(this.OnWon);
            this.signalBus.TryUnsubscribe<LostSignal>(this.OnLost);
        }

        #endregion

        private void LoadConfiguration()
        {
            // Service initialization logic
        }
    }
}
```

### Constructor Injection Rules

**✅ ALWAYS:**
- Use constructor injection (never field or property injection)
- Store dependencies as `readonly` fields
- Inject interfaces, not concrete types (when possible)
- Add `[Preserve]` attribute to prevent code stripping

**❌ NEVER:**
- Field injection with `[Inject]`
- Property injection
- Service locator pattern
- Static dependencies

```csharp
using System.Runtime.CompilerServices;

public sealed class YourService
{
    private readonly SignalBus signalBus; // ✅ readonly field
    private readonly IGameplayService gameplayService; // ✅ interface

    [Preserve] // ✅ Prevent code stripping
    public YourService(
        SignalBus signalBus,
        IGameplayService gameplayService)
    {
        this.signalBus = signalBus;
        this.gameplayService = gameplayService;
    }
}
```

## 2. SignalBus Event System

### Signal Definition

**✅ USE: Classes or Records**
```csharp
// Good: Record for simple signals
public sealed record WonSignal;
public sealed record LostSignal;
public sealed record RestartSignal;

// Good: Class for signals with data
public class DifficultyChangedSignal
{
    public float OldDifficulty { get; set; }
    public float NewDifficulty { get; set; }
    public string Reason { get; set; }
}

// Good: Record with properties
public sealed record LevelCompletedSignal(int LevelNumber, float CompletionTime, int Score);
```

**❌ NEVER: Structs**
```csharp
// Bad: Don't use structs for signals
public struct WonSignal { } // ❌ WRONG
```

### Signal Usage Pattern

```csharp
public sealed class GameplayService : IInitializable, IDisposable
{
    private readonly SignalBus signalBus;

    public GameplayService(SignalBus signalBus)
    {
        this.signalBus = signalBus;
    }

    void IInitializable.Initialize()
    {
        // ✅ Subscribe to signals
        this.signalBus.Subscribe<RestartSignal>(this.OnRestart);
        this.signalBus.Subscribe<DifficultyChangedSignal>(this.OnDifficultyChanged);
    }

    private void OnRestart(RestartSignal signal)
    {
        // Handle restart
        this.ResetGame();
    }

    private void OnDifficultyChanged(DifficultyChangedSignal signal)
    {
        // Handle difficulty change
        this.ApplyDifficulty(signal.NewDifficulty);
    }

    public void CompleteLevel(int level, float time, int score)
    {
        // ✅ Fire signal
        this.signalBus.Fire(new LevelCompletedSignal(level, time, score));
    }

    void IDisposable.Dispose()
    {
        // ✅ Always unsubscribe (use TryUnsubscribe to avoid exceptions)
        this.signalBus.TryUnsubscribe<RestartSignal>(this.OnRestart);
        this.signalBus.TryUnsubscribe<DifficultyChangedSignal>(this.OnDifficultyChanged);
    }
}
```

### Signal Naming Conventions

- **Action Signals**: `VerbSignal` (e.g., `WonSignal`, `LostSignal`, `RestartSignal`)
- **State Change**: `StateChangedSignal` (e.g., `DifficultyChangedSignal`, `LevelChangedSignal`)
- **User Action**: `UserActionSignal` (e.g., `UserZoomSignal`, `UserClickSignal`)

## 3. Data Controller Pattern

### ⚠️ CRITICAL RULE: Never Access Data Directly

**❌ WRONG: Direct Data Access**
```csharp
// ❌ NEVER DO THIS
var level = uiTemplateUserLevelData.CurrentLevel;
var sessionTime = gameSessionData.OpenTime;
var gold = playerData.Gold;
```

**✅ CORRECT: Always Use Controllers**
```csharp
// ✅ ALWAYS DO THIS
var level = levelDataController.CurrentLevel;
var sessionTime = sessionDataController.OpenTime;
var gold = playerDataController.Gold;
```

### Controller Implementation

```csharp
namespace TheOneStudio.YourGame.Models.Controllers
{
    using GameFoundation.Signals;
    using TheOneStudio.YourGame.Models.Data;
    using TheOneStudio.YourGame.Blueprints;

    public class UITemplateLevelDataController : IUITemplateControllerData
    {
        #region Dependency Injection

        private readonly UITemplateLevelBlueprint levelBlueprint;
        private readonly UITemplateUserLevelData levelData;
        private readonly SignalBus signalBus;

        [Preserve]
        public UITemplateLevelDataController(
            UITemplateLevelBlueprint levelBlueprint,
            UITemplateUserLevelData levelData,
            SignalBus signalBus)
        {
            this.levelBlueprint = levelBlueprint;
            this.levelData = levelData;
            this.signalBus = signalBus;
        }

        #endregion

        #region Public Properties (Controlled Access)

        public int CurrentLevel => this.levelData.CurrentLevel;

        public int TotalWins => this.levelData.TotalWinCount;

        public float WinRate => this.CalculateWinRate();

        #endregion

        #region Public Methods (Business Logic)

        public void PassCurrentLevel()
        {
            // Update data
            this.levelData.CurrentLevel++;
            this.levelData.TotalWinCount++;

            // Fire signal for other systems
            this.signalBus.Fire(new LevelPassedSignal(this.CurrentLevel));

            // Track analytics
            this.TrackLevelCompletion();
        }

        public void FailCurrentLevel()
        {
            this.levelData.FailCount++;
            this.signalBus.Fire(new LevelFailedSignal(this.CurrentLevel));
        }

        public LevelConfig GetLevelConfig(int levelNumber)
        {
            return this.levelBlueprint.GetConfig(levelNumber);
        }

        #endregion

        #region Private Methods

        private float CalculateWinRate()
        {
            var totalGames = this.levelData.TotalWinCount + this.levelData.FailCount;
            return totalGames > 0
                ? (float)this.levelData.TotalWinCount / totalGames
                : 0f;
        }

        private void TrackLevelCompletion()
        {
            // Analytics tracking logic
        }

        #endregion
    }
}
```

### Controller Benefits

1. **Encapsulation**: Data access logic centralized
2. **Validation**: Business rules enforced in one place
3. **Consistency**: All code uses same access patterns
4. **Events**: Controllers fire signals when data changes
5. **Testing**: Easy to mock controllers for tests

## 4. Service/Bridge/Adapter Integration Pattern

When integrating third-party systems or complex features:

### Pattern Structure

```
YourFeature/
├── Core/
│   ├── Services/          # Core business logic (framework-agnostic)
│   ├── Models/            # Data models
│   └── Interfaces/        # Abstractions
├── Integration/
│   ├── Adapters/          # Convert system output to game parameters
│   ├── Bridges/           # Connect game events to system
│   └── Services/          # Game-specific service implementations
└── DI/
    └── VContainer/        # Dependency injection registration
```

### Example: Difficulty System Integration

```csharp
// 1. ADAPTER: Convert system values to game parameters
public class DifficultyGameAdapter
{
    private readonly IDifficultyService difficultyService;

    public DifficultyGameAdapter(IDifficultyService difficultyService)
    {
        this.difficultyService = difficultyService;
    }

    public GameDifficultyParameters GetGameParameters()
    {
        var systemDifficulty = this.difficultyService.CurrentDifficulty;

        return new GameDifficultyParameters
        {
            EnemyCount = this.CalculateEnemyCount(systemDifficulty),
            EnemySpeed = this.CalculateEnemySpeed(systemDifficulty),
            EnemyHealth = this.CalculateEnemyHealth(systemDifficulty),
        };
    }

    private int CalculateEnemyCount(float difficulty) =>
        Mathf.RoundToInt(5 + difficulty * 3);

    private float CalculateEnemySpeed(float difficulty) =>
        1f + difficulty * 0.5f;

    private float CalculateEnemyHealth(float difficulty) =>
        100f + difficulty * 50f;
}

// 2. BRIDGE: Connect game events to system
public class DifficultyGameBridge : IInitializable, IDisposable
{
    private readonly IDifficultyService difficultyService;
    private readonly DifficultyGameAdapter adapter;
    private readonly IGameplayService gameplayService;
    private readonly SignalBus signalBus;

    public DifficultyGameBridge(
        IDifficultyService difficultyService,
        DifficultyGameAdapter adapter,
        IGameplayService gameplayService,
        SignalBus signalBus)
    {
        this.difficultyService = difficultyService;
        this.adapter = adapter;
        this.gameplayService = gameplayService;
        this.signalBus = signalBus;
    }

    void IInitializable.Initialize()
    {
        // Subscribe to game events
        this.signalBus.Subscribe<LevelStartedSignal>(this.OnLevelStarted);
        this.signalBus.Subscribe<LevelCompletedSignal>(this.OnLevelCompleted);

        // Subscribe to system events
        this.difficultyService.OnDifficultyChanged += this.OnDifficultyChanged;
    }

    private void OnLevelStarted(LevelStartedSignal signal)
    {
        // Apply current difficulty to game
        var parameters = this.adapter.GetGameParameters();
        this.gameplayService.ApplyDifficulty(parameters);
    }

    private void OnLevelCompleted(LevelCompletedSignal signal)
    {
        // Update difficulty system based on performance
        var performance = new PerformanceData
        {
            CompletionTime = signal.CompletionTime,
            Score = signal.Score,
            Success = true
        };

        this.difficultyService.RecordPerformance(performance);
    }

    private void OnDifficultyChanged(float newDifficulty)
    {
        // Notify game of difficulty change
        this.signalBus.Fire(new DifficultyChangedSignal
        {
            NewDifficulty = newDifficulty
        });
    }

    void IDisposable.Dispose()
    {
        this.signalBus.TryUnsubscribe<LevelStartedSignal>(this.OnLevelStarted);
        this.signalBus.TryUnsubscribe<LevelCompletedSignal>(this.OnLevelCompleted);
        this.difficultyService.OnDifficultyChanged -= this.OnDifficultyChanged;
    }
}

// 3. REGISTRATION: Extension method for clean DI setup
public static class DifficultyIntegrationVContainer
{
    public static void RegisterDifficultyIntegration(this IContainerBuilder builder)
    {
        // Register core difficulty system
        builder.RegisterModule(new DifficultyModule());

        // Register adapter
        builder.Register<DifficultyGameAdapter>(Lifetime.Singleton);

        // Register bridge as entry point (auto-initialized)
        builder.RegisterEntryPoint<DifficultyGameBridge>();
    }
}
```

## 5. Assembly Definition Best Practices

### Separate DI Assembly Pattern

**✅ RECOMMENDED STRUCTURE:**

```
YourFeature/
├── Runtime/
│   ├── YourFeature.asmdef           # Core logic (NO DI framework)
│   │   References: ["TheOne.Logging"]
│   │
│   └── DI/
│       └── YourFeature.VContainer.asmdef  # DI integration
│           References: [
│               "YourFeature",
│               "VContainer",
│               "VContainer.Unity"
│           ]
```

**Core Assembly (framework-agnostic):**
```json
{
    "name": "DynamicUserDifficulty",
    "rootNamespace": "TheOneStudio.DynamicUserDifficulty",
    "references": [
        "TheOne.Logging"
    ]
}
```

**DI Assembly (VContainer integration):**
```json
{
    "name": "DynamicUserDifficulty.VContainer",
    "rootNamespace": "TheOneStudio.DynamicUserDifficulty.DI",
    "references": [
        "DynamicUserDifficulty",
        "VContainer",
        "VContainer.Unity"
    ]
}
```

**Benefits:**
- Core logic is DI framework-agnostic
- Can swap DI frameworks without touching core code
- Clear separation of concerns
- Better testability

## 6. Analytics Pattern

```csharp
public void TrackEvent(string eventName, params (string Key, object Value)[] properties)
{
    this.analyticService.Track(
        new CustomEvent
        {
            EventName = eventName,
            EventProperties = properties
                .Append(("level", this.levelDataController.CurrentLevel))
                .Append(("session_id", this.sessionDataController.SessionId))
                .Append(("timestamp", DateTime.UtcNow))
                .ToDictionary(),
        }
    );
}
```

## 7. Conditional Feature Pattern

```csharp
public class GameLifetimeScope : LifetimeScope
{
    protected override void Configure(IContainerBuilder builder)
    {
        // Core systems (always registered)
        builder.RegisterGameFoundation(this.transform);
        builder.RegisterGameplay();

        // Conditional features
        #if DIFFICULTY_SYSTEM
        this.RegisterDifficultySystem(builder);
        #endif

        #if ANALYTICS_ENABLED
        this.RegisterAnalytics(builder);
        #endif
    }

    #if DIFFICULTY_SYSTEM
    private void RegisterDifficultySystem(IContainerBuilder builder)
    {
        var config = Resources.Load<DifficultyConfig>("Configs/DifficultyConfig");
        if (config == null)
        {
            Debug.LogWarning("[Difficulty] Config not found, skipping registration");
            return;
        }

        builder.RegisterDifficultyIntegration();

        #if UNITY_EDITOR || DEVELOPMENT_BUILD
        // Debug UI only in editor/development
        builder.RegisterComponentOnNewGameObject<DifficultyDebugUI>(Lifetime.Singleton)
            .DontDestroyOnLoad();
        #endif
    }
    #endif
}
```

## Common Mistakes to Avoid

### ❌ DON'T:
1. **Use Zenject** → Use VContainer
2. **Use MessagePipe directly** → Use SignalBus
3. **Access data models directly** → Use Controllers
4. **Use field injection** → Use constructor injection
5. **Forget to unsubscribe from signals** → Implement IDisposable
6. **Use struct signals** → Use class or record
7. **Skip [Preserve] attribute** → Add to constructors
8. **Mix DI framework in core code** → Separate DI assembly

### ✅ DO:
1. **Use VContainer** for dependency injection
2. **Use SignalBus** for all events
3. **Use Controllers** for all data access
4. **Use constructor injection** only
5. **Always implement IDisposable** and unsubscribe
6. **Use class/record signals** for SignalBus
7. **Add [Preserve]** to prevent code stripping
8. **Separate DI code** into own assembly

## Summary Checklist

When implementing Unity features at TheOne Studio:

- [ ] Use VContainer for DI (not Zenject)
- [ ] Use SignalBus for events (not MessagePipe)
- [ ] Access data through Controllers (never direct)
- [ ] Use constructor injection only
- [ ] Implement IInitializable for setup
- [ ] Implement IDisposable for cleanup
- [ ] Unsubscribe from all signals in Dispose
- [ ] Use Service/Bridge/Adapter for integrations
- [ ] Separate DI code into own assembly
- [ ] Add [Preserve] attribute to constructors
- [ ] Track analytics with proper context
- [ ] Follow naming conventions for signals

This ensures code consistency, maintainability, and adherence to TheOne Studio's established architecture.
