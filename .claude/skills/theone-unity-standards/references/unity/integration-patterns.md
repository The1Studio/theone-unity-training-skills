# Service/Bridge/Adapter Integration Patterns

## Pattern Structure

When integrating third-party systems or complex features:

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

## Complete Example: Difficulty System Integration

### 1. ADAPTER: Convert System Values to Game Parameters

```csharp
public class DifficultyGameAdapter
{
    private readonly IDifficultyService difficultyService;

    [Preserve]
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
```

### 2. BRIDGE: Connect Game Events to System

```csharp
public class DifficultyGameBridge : IInitializable, IDisposable
{
    private readonly IDifficultyService difficultyService;
    private readonly DifficultyGameAdapter adapter;
    private readonly IGameplayService gameplayService;
    private readonly SignalBus signalBus;

    [Preserve]
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
```

### 3. REGISTRATION: Extension Method for Clean DI Setup

```csharp
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

## Why Use This Pattern?

### Separation of Concerns
- **Core logic** is independent of Unity/Game specifics
- **Adapter** handles conversion between systems
- **Bridge** handles event flow between systems

### Testability
- Test core logic without Unity
- Mock adapter for game-specific tests
- Mock bridge for integration tests

### Maintainability
- Easy to swap third-party systems
- Changes to game don't affect core logic
- Changes to core logic don't affect game

### Flexibility
- Same core logic can be used in different projects
- Multiple adapters for different game genres
- Multiple bridges for different event systems

## Advanced Integration Examples

### Analytics Integration

```csharp
// Adapter: Convert game events to analytics format
public class AnalyticsAdapter
{
    public AnalyticsEvent ConvertLevelCompleted(LevelCompletedSignal signal)
    {
        return new AnalyticsEvent
        {
            Name = "level_completed",
            Properties = new Dictionary<string, object>
            {
                ["level"] = signal.LevelNumber,
                ["time"] = signal.CompletionTime,
                ["score"] = signal.Score,
            }
        };
    }
}

// Bridge: Connect game events to analytics
public class AnalyticsBridge : IInitializable, IDisposable
{
    private readonly SignalBus signalBus;
    private readonly IAnalyticsService analyticsService;
    private readonly AnalyticsAdapter adapter;

    void IInitializable.Initialize()
    {
        this.signalBus.Subscribe<LevelCompletedSignal>(this.OnLevelCompleted);
    }

    private void OnLevelCompleted(LevelCompletedSignal signal)
    {
        var analyticsEvent = this.adapter.ConvertLevelCompleted(signal);
        this.analyticsService.Track(analyticsEvent);
    }

    void IDisposable.Dispose()
    {
        this.signalBus.TryUnsubscribe<LevelCompletedSignal>(this.OnLevelCompleted);
    }
}
```

### IAP Integration

```csharp
// Adapter: Convert IAP products to game items
public class IAPAdapter
{
    public GameItem ConvertProduct(IAPProduct product)
    {
        return new GameItem
        {
            Id = product.ProductId,
            Name = product.Title,
            Description = product.Description,
            Price = product.Price,
            Currency = product.CurrencyCode,
        };
    }
}

// Bridge: Connect IAP events to game
public class IAPBridge : IInitializable, IDisposable
{
    private readonly IIAPService iapService;
    private readonly IAPAdapter adapter;
    private readonly SignalBus signalBus;
    private readonly CurrencyController currencyController;

    void IInitializable.Initialize()
    {
        this.iapService.OnPurchaseComplete += this.OnPurchaseComplete;
        this.signalBus.Subscribe<PurchaseRequestedSignal>(this.OnPurchaseRequested);
    }

    private void OnPurchaseRequested(PurchaseRequestedSignal signal)
    {
        this.iapService.Purchase(signal.ProductId);
    }

    private void OnPurchaseComplete(IAPPurchase purchase)
    {
        var gameItem = this.adapter.ConvertProduct(purchase.Product);
        this.currencyController.Earn(gameItem.Price);
        this.signalBus.Fire(new PurchaseCompletedSignal(gameItem));
    }

    void IDisposable.Dispose()
    {
        this.iapService.OnPurchaseComplete -= this.OnPurchaseComplete;
        this.signalBus.TryUnsubscribe<PurchaseRequestedSignal>(this.OnPurchaseRequested);
    }
}
```
