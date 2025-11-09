# SignalBus Event Patterns

## Signal Definition Best Practices

### ✅ USE: Classes or Records

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

### ❌ NEVER: Structs

```csharp
// Bad: Struct signals cause issues
public struct WonSignal { } // ❌ WRONG

// Why structs are problematic:
// 1. SignalBus uses reference equality for subscription tracking
// 2. Structs cause boxing/unboxing overhead when used with generic types
// 3. Each Fire() creates a new copy (value semantics), breaking reference identity
// 4. TryUnsubscribe() won't work correctly - can't match value type references
// 5. Memory allocations from boxing eliminate performance benefits of structs
```

## Complete Signal Usage Pattern

```csharp
public sealed class GameplayService : IInitializable, IDisposable
{
    private readonly SignalBus signalBus;

    [Preserve]
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

## Signal Naming Conventions

- **Action Signals**: `VerbSignal` (e.g., `WonSignal`, `LostSignal`, `RestartSignal`)
- **State Change**: `StateChangedSignal` (e.g., `DifficultyChangedSignal`, `LevelChangedSignal`)
- **User Action**: `UserActionSignal` (e.g., `UserZoomSignal`, `UserClickSignal`)

## Advanced Signal Patterns

### Signal with Multiple Subscribers

```csharp
// Multiple services can subscribe to the same signal
public sealed class AnalyticsService : IInitializable, IDisposable
{
    private readonly SignalBus signalBus;

    void IInitializable.Initialize()
    {
        this.signalBus.Subscribe<LevelCompletedSignal>(this.OnLevelCompleted);
    }

    private void OnLevelCompleted(LevelCompletedSignal signal)
    {
        // Track analytics
        this.TrackEvent("level_completed",
            ("level", signal.LevelNumber),
            ("time", signal.CompletionTime));
    }

    void IDisposable.Dispose()
    {
        this.signalBus.TryUnsubscribe<LevelCompletedSignal>(this.OnLevelCompleted);
    }
}

public sealed class UIService : IInitializable, IDisposable
{
    private readonly SignalBus signalBus;

    void IInitializable.Initialize()
    {
        this.signalBus.Subscribe<LevelCompletedSignal>(this.OnLevelCompleted);
    }

    private void OnLevelCompleted(LevelCompletedSignal signal)
    {
        // Show completion UI
        this.ShowVictoryScreen(signal);
    }

    void IDisposable.Dispose()
    {
        this.signalBus.TryUnsubscribe<LevelCompletedSignal>(this.OnLevelCompleted);
    }
}
```

### Signal Chaining

```csharp
public sealed class GameStateService : IInitializable, IDisposable
{
    private readonly SignalBus signalBus;

    void IInitializable.Initialize()
    {
        this.signalBus.Subscribe<LevelCompletedSignal>(this.OnLevelCompleted);
    }

    private void OnLevelCompleted(LevelCompletedSignal signal)
    {
        // Process level completion
        this.SaveProgress(signal);

        // Fire next signal in chain
        if (this.IsLastLevel(signal.LevelNumber))
        {
            this.signalBus.Fire(new GameCompletedSignal());
        }
        else
        {
            this.signalBus.Fire(new ShowNextLevelSignal(signal.LevelNumber + 1));
        }
    }

    void IDisposable.Dispose()
    {
        this.signalBus.TryUnsubscribe<LevelCompletedSignal>(this.OnLevelCompleted);
    }
}
```
