# Unity-Specific Code Review

## Component Access

### Check List
- [ ] Is `TryGetComponent` used instead of `GetComponent` with null check?
- [ ] Is null-conditional used with Unity methods?

### Common Violations

#### ❌ GetComponent with Null Check
```csharp
// Bad: GetComponent with null check
var enemy = gameObject.GetComponent<Enemy>();
if (enemy != null)
{
    enemy.TakeDamage(10);
}

// Bad: Null check before method call
var weapon = GetComponentInChildren<Weapon>();
if (weapon != null)
{
    weapon.Fire();
}
```

### ✅ Concise Component Access
```csharp
// Good: TryGetComponent
if (gameObject.TryGetComponent<Enemy>(out var enemy))
{
    enemy.TakeDamage(10);
}

// Good: Null-conditional
GetComponentInChildren<Weapon>()?.Fire();
```

## MonoBehaviour Lifecycle

### Check List
- [ ] Are Unity lifecycle methods ordered correctly?
- [ ] Is proper cleanup in OnDestroy()?

### ✅ Correct Order
```csharp
public class MyBehaviour : MonoBehaviour
{
    // Awake → OnEnable → Start → Update → LateUpdate → OnDisable → OnDestroy

    private void Awake()
    {
        // Initialize references
    }

    private void OnEnable()
    {
        // Subscribe to events
    }

    private void Start()
    {
        // Initialize gameplay
    }

    private void Update()
    {
        // Per-frame logic
    }

    private void LateUpdate()
    {
        // After all Update calls
    }

    private void OnDisable()
    {
        // Pause/disable logic
    }

    private void OnDestroy()
    {
        // Cleanup subscriptions, unsubscribe from events
    }
}
```

## Component Caching

### Common Violations

#### ❌ GetComponent in Update
```csharp
// Bad: GetComponent every frame
private void Update()
{
    var rigidbody = GetComponent<Rigidbody>();
    rigidbody.AddForce(Vector3.up);
}
```

### ✅ Cache Components
```csharp
// Good: Cache in Awake
private Rigidbody rb;

private void Awake()
{
    this.rb = GetComponent<Rigidbody>();
}

private void Update()
{
    this.rb.AddForce(Vector3.up);
}
```

## SerializeField vs Public

### Common Violations

#### ❌ Public Fields for Inspector
```csharp
// Bad: Public fields
public float speed = 5f;
public GameObject prefab;
```

### ✅ SerializeField with Private
```csharp
// Good: SerializeField with private
[SerializeField] private float speed = 5f;
[SerializeField] private GameObject prefab;
```

## Coroutines vs UniTask

### Common Violations

#### ❌ Coroutines for Async
```csharp
// Bad: Coroutines
private IEnumerator LoadAsync()
{
    yield return new WaitForSeconds(1f);
    Debug.Log("Loaded");
}

private void Start()
{
    StartCoroutine(LoadAsync());
}
```

### ✅ UniTask
```csharp
// Good: UniTask
private async UniTask LoadAsync(CancellationToken cancellationToken)
{
    await UniTask.WaitForSeconds(1f, cancellationToken: cancellationToken);
    Debug.Log("Loaded");
}

private async void Start()
{
    await LoadAsync(this.GetCancellationTokenOnDestroy());
}
```

## Find and FindObjectOfType

### Common Violations

#### ❌ Find in Update
```csharp
// Bad: Find every frame
private void Update()
{
    var player = GameObject.Find("Player");
    var enemy = FindObjectOfType<Enemy>();
}
```

### ✅ Find Once or Use DI
```csharp
// Good: Find once in Awake
private GameObject player;
private Enemy enemy;

private void Awake()
{
    this.player = GameObject.Find("Player");
    this.enemy = FindObjectOfType<Enemy>();
}

// Better: Use dependency injection
private readonly Player player;

[Preserve]
public GameController(Player player)
{
    this.player = player;
}
```

## Destroy vs Dispose

### Check List
- [ ] Are Unity objects destroyed properly?
- [ ] Are managed resources disposed?

### Common Violations

#### ❌ Not Destroying GameObjects
```csharp
// Bad: Not destroying
private void RemoveEnemy()
{
    this.enemy = null; // ❌ GameObject still exists in scene
}
```

### ✅ Proper Cleanup
```csharp
// Good: Destroy GameObject
private void RemoveEnemy()
{
    if (this.enemy != null)
    {
        Destroy(this.enemy.gameObject);
        this.enemy = null;
    }
}

// Good: Dispose managed resources
public void Dispose()
{
    this.subscription?.Dispose();
    this.cts?.Cancel();
    this.cts?.Dispose();
}
```

## Vector3 and Quaternion

### Common Violations

#### ❌ Creating New Vectors
```csharp
// Bad: Creating new vectors
transform.position = new Vector3(0, 0, 0);
transform.rotation = new Quaternion(0, 0, 0, 1);
```

### ✅ Use Static Properties
```csharp
// Good: Use static properties
transform.position = Vector3.zero;
transform.rotation = Quaternion.identity;
```

## Layer and Tag Comparison

### Common Violations

#### ❌ String Comparison
```csharp
// Bad: String comparison
if (gameObject.tag == "Player")
{
    // ...
}
```

### ✅ CompareTag
```csharp
// Good: CompareTag
if (gameObject.CompareTag("Player"))
{
    // ...
}
```

## Complete Example

### ❌ Bad Unity Code
```csharp
public class EnemyController : MonoBehaviour
{
    // ❌ Public fields
    public float speed = 5f;
    public GameObject projectilePrefab;

    private void Update()
    {
        // ❌ GetComponent every frame
        var rb = GetComponent<Rigidbody>();

        // ❌ Find every frame
        var player = GameObject.Find("Player");

        // ❌ String tag comparison
        if (player.tag == "Player")
        {
            // ❌ Creating new Vector3
            var direction = new Vector3(1, 0, 0);
            rb.AddForce(direction * this.speed);
        }

        // ❌ GetComponent with null check
        var weapon = GetComponent<Weapon>();
        if (weapon != null)
        {
            weapon.Fire();
        }
    }
}
```

### ✅ Good Unity Code
```csharp
public class EnemyController : MonoBehaviour
{
    // ✅ SerializeField
    [SerializeField] private float speed = 5f;
    [SerializeField] private GameObject projectilePrefab;

    // ✅ Cached components
    private Rigidbody rb;
    private Transform playerTransform;
    private Weapon weapon;

    private void Awake()
    {
        // ✅ Cache components once
        this.rb = GetComponent<Rigidbody>();

        // ✅ Find once
        var player = GameObject.Find("Player");
        this.playerTransform = player?.transform;

        // ✅ TryGetComponent
        TryGetComponent<Weapon>(out this.weapon);
    }

    private void Update()
    {
        if (this.playerTransform == null) return;

        // ✅ CompareTag
        if (this.playerTransform.CompareTag("Player"))
        {
            // ✅ Use Vector3.right
            this.rb.AddForce(Vector3.right * this.speed);
        }

        // ✅ Null-conditional
        this.weapon?.Fire();
    }
}
```

## Review Severity

### 🔴 Critical Issues
- GetComponent/Find in Update (performance issue)
- Not destroying GameObjects (memory leak)
- Not disposing managed resources (memory leak)

### 🟡 Important Issues
- Public fields instead of SerializeField
- GetComponent with null check instead of TryGetComponent
- Creating new Vector3/Quaternion instead of using static properties
- String tag comparison instead of CompareTag
- Not caching components

### 🟢 Suggestions
- Could use null-conditional operators
- Could use UniTask instead of Coroutines
- Could use dependency injection instead of Find
