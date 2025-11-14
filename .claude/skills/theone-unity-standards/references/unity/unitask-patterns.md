# UniTask Async/Await Patterns

Both VContainer and TheOne.DI projects use UniTask for async operations.

## Required Patterns

- Use `async UniTaskVoid` or `UniTask.Void(async () => {})` instead of `async void`
- Use `.Forget()` if not `await`ing `UniTask`
- Use `CancellationToken` for async methods
- Add `Async` suffix for async methods
- Use `UniTask.WaitForSeconds` instead of `UniTask.Delay`

## Async Method Patterns

### ✅ GOOD: async UniTask

```csharp
public async UniTask DoWorkAsync(CancellationToken cancellationToken)
{
    await UniTask.WaitForSeconds(1f, cancellationToken: cancellationToken);

    var workResult = await this.ProcessDataAsync(cancellationToken);
    return workResult;
}
```

### ✅ GOOD: async UniTaskVoid for Fire-and-Forget

```csharp
public async UniTaskVoid FireAndForgetAsync()
{
    await UniTask.Delay(100);

    // Do work that doesn't need to be awaited
    Debug.Log("Background work");
}
```

### ✅ GOOD: Use Forget() When Not Awaiting

```csharp
public void StartWork()
{
    // Fire-and-forget without creating async void
    this.DoWorkAsync(default).Forget();
}
```

### ❌ WRONG: async void

```csharp
// Bad: async void
public async void DoWork() // ❌ Don't use async void
{
    await UniTask.Delay(100);
}
```

## UniTask Timing

### ✅ GOOD: WaitForSeconds

```csharp
// Use WaitForSeconds for Unity-friendly delays
await UniTask.WaitForSeconds(1f, cancellationToken: token);
```

### ❌ WRONG: Delay (Less Unity-Friendly)

```csharp
// Bad: Delay is less Unity-friendly
await UniTask.Delay(1000, cancellationToken: token);
```

## Complete Service Example

```csharp
public sealed class LoadingService : IAsyncEarlyLoadable, IDisposable
{
    private readonly IAssetsManager assetsManager;
    private CancellationTokenSource? cts;
    private GameObject? loadedPrefab;

    [Inject] // Or [Preserve] for VContainer
    public LoadingService(IAssetsManager assetsManager)
    {
        this.assetsManager = assetsManager;
    }

    public async UniTask LoadAsync(IProgress<float> progress, CancellationToken cancellationToken)
    {
        this.cts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);

        try
        {
            // Load assets with progress reporting
            this.loadedPrefab = await this.assetsManager.LoadAsync<GameObject>(
                "path/to/prefab",
                this.cts.Token
            );

            progress?.Report(0.5f);

            // Wait for initialization
            await UniTask.WaitForSeconds(1f, cancellationToken: this.cts.Token);

            progress?.Report(1f);
        }
        catch (OperationCanceledException)
        {
            // Handle cancellation
            Debug.Log("Loading cancelled");
        }
    }

    public void Dispose()
    {
        // Cancel ongoing operations
        this.cts?.Cancel();
        this.cts?.Dispose();

        // Unload assets
        this.assetsManager.Unload(this.loadedPrefab);
    }
}
```

## Advanced UniTask Patterns

### Timeout Pattern

```csharp
public async UniTask<bool> TryLoadWithTimeoutAsync(float timeoutSeconds)
{
    var cts = new CancellationTokenSource();

    try
    {
        // Create timeout task
        var timeoutTask = UniTask.Delay(
            TimeSpan.FromSeconds(timeoutSeconds),
            cancellationToken: cts.Token
        );

        // Create load task
        var loadTask = this.LoadAsync(cts.Token);

        // Wait for first to complete
        var result = await UniTask.WhenAny(loadTask, timeoutTask);

        if (result == 0)
        {
            // Load completed
            return true;
        }
        else
        {
            // Timeout
            Debug.LogWarning("Load timeout");
            return false;
        }
    }
    finally
    {
        cts.Cancel();
        cts.Dispose();
    }
}
```

### Parallel Loading Pattern

```csharp
public async UniTask LoadMultipleAsync(CancellationToken cancellationToken)
{
    // Start multiple loads in parallel
    var task1 = this.assetsManager.LoadAsync<GameObject>("prefab1", cancellationToken);
    var task2 = this.assetsManager.LoadAsync<Texture2D>("texture1", cancellationToken);
    var task3 = this.assetsManager.LoadAsync<AudioClip>("audio1", cancellationToken);

    // Wait for all to complete
    await UniTask.WhenAll(task1, task2, task3);

    // All assets loaded
    Debug.Log("All assets loaded");
}
```

### Retry Pattern

```csharp
public async UniTask<T> LoadWithRetryAsync<T>(string path, int maxRetries, CancellationToken cancellationToken)
    where T : UnityEngine.Object
{
    for (int i = 0; i < maxRetries; i++)
    {
        try
        {
            return await this.assetsManager.LoadAsync<T>(path, cancellationToken);
        }
        catch (Exception ex)
        {
            Debug.LogWarning($"Load failed (attempt {i + 1}/{maxRetries}): {ex.Message}");

            if (i < maxRetries - 1)
            {
                // Wait before retry
                await UniTask.WaitForSeconds(1f, cancellationToken: cancellationToken);
            }
            else
            {
                // Last retry failed, rethrow
                throw;
            }
        }
    }

    throw new InvalidOperationException("This should never be reached");
}
```

## [Preserve] for Reflection

Both frameworks require `[Preserve]` for classes instantiated via reflection:

```csharp
// Use [Preserve] for:
// - DI container registration
// - JSON deserialization
// - CSV deserialization
// - Any reflection-based instantiation

public sealed class PlayerData
{
    [Preserve]
    public PlayerData() { } // Constructor used by JSON deserializer
}
```

## MonoBehaviour UniTask Integration

```csharp
public class GameManager : MonoBehaviour
{
    private CancellationTokenSource? cts;

    private async void Start()
    {
        // Create cancellation token tied to GameObject lifetime
        this.cts = new CancellationTokenSource();

        // Use GetCancellationTokenOnDestroy() for automatic cleanup
        await this.InitializeAsync(this.GetCancellationTokenOnDestroy());
    }

    private async UniTask InitializeAsync(CancellationToken cancellationToken)
    {
        // Async initialization
        await UniTask.WaitForSeconds(1f, cancellationToken: cancellationToken);

        Debug.Log("Initialized");
    }

    private void OnDestroy()
    {
        // Cancel ongoing operations
        this.cts?.Cancel();
        this.cts?.Dispose();
    }
}
```

## Error Handling

```csharp
public async UniTask LoadSafelyAsync(CancellationToken cancellationToken)
{
    try
    {
        await this.LoadAsync(cancellationToken);
    }
    catch (OperationCanceledException)
    {
        // Handle cancellation gracefully
        Debug.Log("Load cancelled");
    }
    catch (Exception ex)
    {
        // Handle other errors
        Debug.LogError($"Load failed: {ex.Message}");
        throw; // Re-throw if needed
    }
}
```
