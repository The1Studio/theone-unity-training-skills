# Architecture Review: VContainer, SignalBus, Controllers

## VContainer Dependency Injection Review

### Check List
- [ ] Are all dependencies injected via constructor?
- [ ] Are injected fields marked as `readonly`?
- [ ] Is `[Preserve]` attribute added to constructors?
- [ ] Are services registered correctly in LifetimeScope?
- [ ] Is field/property injection avoided?

### Common Violations

#### ❌ Field Injection
```csharp
// Bad: Field injection
public class MyService
{
    [Inject] private SignalBus signalBus; // ❌ WRONG
}
```

#### ❌ Missing readonly
```csharp
// Bad: Missing readonly
public class MyService
{
    private SignalBus signalBus; // ❌ Should be readonly

    public MyService(SignalBus signalBus)
    {
        this.signalBus = signalBus;
    }
}
```

#### ❌ Missing [Preserve]
```csharp
// Bad: Missing [Preserve]
public MyService(SignalBus signalBus) // ❌ Missing attribute
{
    this.signalBus = signalBus;
}
```

### ✅ Correct Pattern
```csharp
public sealed class MyService
{
    private readonly SignalBus signalBus;
    private readonly IAnalyticServices analyticService;

    [Preserve]
    public MyService(
        SignalBus signalBus,
        IAnalyticServices analyticService)
    {
        this.signalBus = signalBus;
        this.analyticService = analyticService;
    }
}
```

## SignalBus Event System Review

### Check List
- [ ] Are signals using class/record (not struct)?
- [ ] Are signal subscriptions in Initialize()?
- [ ] Are signal unsubscriptions in Dispose()?
- [ ] Is TryUnsubscribe() used (not Unsubscribe())?
- [ ] Is MessagePipe avoided (use SignalBus)?

### Common Violations

#### ❌ Struct Signal
```csharp
// Bad: Struct signal
public struct WonSignal { } // ❌ Use class or record
```

#### ❌ Subscribe in Constructor
```csharp
// Bad: Subscribe in constructor
public MyService(SignalBus signalBus)
{
    signalBus.Subscribe<WonSignal>(OnWon); // ❌ Should be in Initialize
}
```

#### ❌ Using Unsubscribe Without Try
```csharp
// Bad: Using Unsubscribe without try
void IDisposable.Dispose()
{
    this.signalBus.Unsubscribe<WonSignal>(OnWon); // ❌ Use TryUnsubscribe
}
```

#### ❌ Not Unsubscribing
```csharp
// Bad: Not unsubscribing
public class MyService : IInitializable
{
    void IInitializable.Initialize()
    {
        this.signalBus.Subscribe<WonSignal>(OnWon);
    }
    // ❌ Missing IDisposable implementation!
}
```

### ✅ Correct Pattern
```csharp
// Good: Record signal
public sealed record WonSignal;

public sealed class MyService : IInitializable, IDisposable
{
    private readonly SignalBus signalBus;

    [Preserve]
    public MyService(SignalBus signalBus)
    {
        this.signalBus = signalBus;
    }

    void IInitializable.Initialize()
    {
        this.signalBus.Subscribe<WonSignal>(this.OnWon);
    }

    private void OnWon(WonSignal signal)
    {
        // Handle event
    }

    void IDisposable.Dispose()
    {
        this.signalBus.TryUnsubscribe<WonSignal>(this.OnWon);
    }
}
```

## Data Controller Usage Review

### Check List
- [ ] Is data accessed through controllers (not directly)?
- [ ] Are business rules in controllers (not scattered)?
- [ ] Do controllers fire signals on data changes?

### Common Violations

#### ❌ Direct Data Access
```csharp
// Bad: Direct data access
public class GameService
{
    private readonly UITemplateUserLevelData levelData;

    public void CompleteLevel()
    {
        this.levelData.CurrentLevel++; // ❌ NEVER ACCESS DIRECTLY
        this.levelData.TotalWins++;
    }
}
```

### ✅ Correct Pattern
```csharp
// Good: Use controller
public class GameService
{
    private readonly UITemplateLevelDataController levelController;

    public void CompleteLevel()
    {
        this.levelController.PassCurrentLevel(); // ✅ Use controller
    }
}
```

## Complete Architecture Review Example

### ❌ Bad Code (Multiple Violations)
```csharp
public class GameService
{
    // ❌ Field injection
    [Inject] private SignalBus signalBus;

    // ❌ Not readonly
    private UITemplateUserLevelData levelData;

    // ❌ Missing [Preserve]
    public GameService(UITemplateUserLevelData levelData)
    {
        this.levelData = levelData;

        // ❌ Subscribe in constructor
        this.signalBus.Subscribe<WonSignal>(OnWon);
    }

    private void OnWon(WonSignal signal)
    {
        // ❌ Direct data access
        this.levelData.CurrentLevel++;
    }

    // ❌ Missing IDisposable - memory leak!
}
```

### ✅ Good Code (Correct Pattern)
```csharp
public sealed class GameService : IInitializable, IDisposable
{
    // ✅ readonly fields
    private readonly SignalBus signalBus;
    private readonly UITemplateLevelDataController levelController;

    // ✅ Constructor injection with [Preserve]
    [Preserve]
    public GameService(
        SignalBus signalBus,
        UITemplateLevelDataController levelController)
    {
        this.signalBus = signalBus;
        this.levelController = levelController;
    }

    // ✅ Subscribe in Initialize
    void IInitializable.Initialize()
    {
        this.signalBus.Subscribe<WonSignal>(this.OnWon);
    }

    private void OnWon(WonSignal signal)
    {
        // ✅ Use controller
        this.levelController.PassCurrentLevel();
    }

    // ✅ Unsubscribe in Dispose
    void IDisposable.Dispose()
    {
        this.signalBus.TryUnsubscribe<WonSignal>(this.OnWon);
    }
}
```

## Review Severity

### 🔴 Critical Issues
- Field injection instead of constructor injection
- Direct data access (not using Controllers)
- Missing IDisposable implementation (memory leak)
- Not unsubscribing from signals
- Using struct for signals

### 🟡 Important Issues
- Missing [Preserve] attribute
- Missing readonly on injected fields
- Subscribing in constructor instead of Initialize
- Using Unsubscribe instead of TryUnsubscribe

### 🟢 Suggestions
- Could seal the class
- Could use explicit interface implementation
- Could add XML documentation
