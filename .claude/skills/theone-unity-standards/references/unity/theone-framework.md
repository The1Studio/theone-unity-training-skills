# TheOne.DI + Publisher/Subscriber Framework

Some TheOne Studio projects use an alternative framework stack instead of VContainer+SignalBus.

## Framework Stack

**Use:**
- **TheOne.DI** - DI container wrapper (instead of VContainer)
- **IPublisher<T> / ISubscriber<T>** - Event messaging (instead of SignalBus)
- **`[Inject]` attribute** - Constructor injection marker
- **TheOne.Extensions** - Extension methods
- **TheOne.Logging.ILogger** - Logging (runtime, no guards, no prefixes, no constructor logs), Debug.Log (editor only)
- **TheOne.ResourceManagement** - Asset loading/unloading
- **TheOne.Data** - Player data (JSON), blueprints (CSV)
- **TheOne.Pooling** - Object pooling
- **TheOne.Lifecycle** - Async loading screens

## Dependency Injection Pattern

```csharp
public sealed class ExampleService : IAsyncEarlyLoadable, IDisposable
{
    private readonly IAssetsManager assetsManager;
    private readonly IPublisher<ExampleSignal> publisher;
    private IDisposable? subscription;
    private GameObject? loadedPrefab;

    [Inject] // ✅ Use [Inject] attribute with TheOne.DI
    public ExampleService(
        IAssetsManager assetsManager,
        IPublisher<ExampleSignal> publisher,
        ISubscriber<ExampleSignal> subscriber
    )
    {
        this.assetsManager = assetsManager;
        this.publisher = publisher;
        this.subscription = subscriber.Subscribe(this.OnSignal);
    }

    private void OnSignal(ExampleSignal signal)
    {
        if (signal.Value < 0)
        {
            throw new ArgumentException($"Invalid value: {signal.Value}", nameof(signal));
        }

        this.publisher.Publish(new ExampleSignal(signal.Value * 2));
    }

    public void Dispose()
    {
        this.subscription?.Dispose();
        this.assetsManager.Unload(this.loadedPrefab);
    }
}
```

## Publisher/Subscriber Event Pattern

### Signal Definition

```csharp
// Define signals as records (same as SignalBus)
public sealed record ExampleSignal(int Value);
public sealed record LevelCompletedSignal(int Level, float Time);
```

### Publishing Events

```csharp
public sealed class GameService
{
    private readonly IPublisher<LevelCompletedSignal> levelCompletedPublisher;

    [Inject]
    public GameService(IPublisher<LevelCompletedSignal> publisher)
    {
        this.levelCompletedPublisher = publisher;
    }

    public void CompleteLevel(int level, float time)
    {
        // Publish event
        this.levelCompletedPublisher.Publish(new LevelCompletedSignal(level, time));
    }
}
```

### Subscribing to Events

```csharp
public sealed class AnalyticsService : IDisposable
{
    private IDisposable? subscription;

    [Inject]
    public AnalyticsService(ISubscriber<LevelCompletedSignal> subscriber)
    {
        // Subscribe returns IDisposable
        this.subscription = subscriber.Subscribe(this.OnLevelCompleted);
    }

    private void OnLevelCompleted(LevelCompletedSignal signal)
    {
        // Handle event
        this.TrackEvent("level_completed", ("level", signal.Level));
    }

    public void Dispose()
    {
        // Dispose subscription to unsubscribe
        this.subscription?.Dispose();
    }
}
```

## Resource Management

**Critical Rules:**
- Assets loaded in `Initialize`/`OnInstantiate` MUST be unloaded in `Dispose`/`OnCleanup`
- Avoid `Find`/`GetComponent` at runtime (`Update`/`Tick`), only in initialization (`Awake`/`Start`/`OnSpawn`)

```csharp
public sealed class PrefabService : IAsyncEarlyLoadable, IDisposable
{
    private readonly IAssetsManager assetsManager;
    private GameObject? loadedPrefab;

    public async UniTask LoadAsync(IProgress<float> progress, CancellationToken cancellationToken)
    {
        // Load asset
        this.loadedPrefab = await this.assetsManager.LoadAsync<GameObject>(
            "path/to/prefab",
            cancellationToken
        );
    }

    public void Dispose()
    {
        // Unload asset
        this.assetsManager.Unload(this.loadedPrefab);
    }
}
```

## When to Use This Stack

**Check project dependencies:**
- If you see `TheOne.DI` package → Use this pattern
- If you see `IPublisher<T>`/`ISubscriber<T>` → Use Publisher/Subscriber (not SignalBus)
- If you see `[Inject]` attribute in existing code → Follow that pattern

## Key Differences from VContainer+SignalBus

| Aspect | VContainer+SignalBus | TheOne.DI+Publisher/Subscriber |
|--------|---------------------|-------------------------------|
| DI Container | VContainer | TheOne.DI |
| Constructor Marker | `[Preserve]` | `[Inject]` |
| Events | SignalBus | IPublisher<T>/ISubscriber<T> |
| Subscribe | `signalBus.Subscribe<T>(handler)` | `subscriber.Subscribe(handler)` |
| Publish | `signalBus.Fire(signal)` | `publisher.Publish(signal)` |
| Unsubscribe | `signalBus.TryUnsubscribe<T>(handler)` | `subscription.Dispose()` |
| Initialization | `IInitializable.Initialize()` | `IAsyncEarlyLoadable.LoadAsync()` |

## Complete Example

```csharp
public sealed class DifficultyService : IAsyncEarlyLoadable, IDisposable
{
    private readonly IAssetsManager assetsManager;
    private readonly IPublisher<DifficultyChangedSignal> difficultyPublisher;
    private IDisposable? levelCompletedSubscription;
    private DifficultyConfig? config;

    [Inject]
    public DifficultyService(
        IAssetsManager assetsManager,
        IPublisher<DifficultyChangedSignal> difficultyPublisher,
        ISubscriber<LevelCompletedSignal> levelCompletedSubscriber
    )
    {
        this.assetsManager = assetsManager;
        this.difficultyPublisher = difficultyPublisher;
        this.levelCompletedSubscription = levelCompletedSubscriber.Subscribe(this.OnLevelCompleted);
    }

    public async UniTask LoadAsync(IProgress<float> progress, CancellationToken cancellationToken)
    {
        // Load configuration
        this.config = await this.assetsManager.LoadAsync<DifficultyConfig>(
            "Configs/DifficultyConfig",
            cancellationToken
        );
    }

    private void OnLevelCompleted(LevelCompletedSignal signal)
    {
        // Calculate new difficulty
        var newDifficulty = this.CalculateDifficulty(signal);

        // Publish difficulty change
        this.difficultyPublisher.Publish(new DifficultyChangedSignal(newDifficulty));
    }

    public void Dispose()
    {
        // Unsubscribe from events
        this.levelCompletedSubscription?.Dispose();

        // Unload assets
        this.assetsManager.Unload(this.config);
    }
}
```
