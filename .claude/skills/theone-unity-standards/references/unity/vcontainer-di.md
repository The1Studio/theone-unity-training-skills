# VContainer Dependency Injection Patterns

## Complete Service Registration Pattern

```csharp
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

## Complete Service Implementation Pattern

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

        [Preserve]
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

## Separate DI Assembly Pattern

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

## Conditional Feature Registration

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
