# Data Controller Patterns

## ⚠️ CRITICAL RULE: Never Access Data Directly

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

## Complete Controller Implementation

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

## Controller Benefits

1. **Encapsulation**: Data access logic centralized
   - All data access goes through one place
   - Easy to find and modify business logic

2. **Validation**: Business rules enforced in one place
   - Prevent invalid data states
   - Enforce constraints (e.g., level can't be negative)

3. **Consistency**: All code uses same access patterns
   - Team members use the same API
   - No confusion about how to access data

4. **Events**: Controllers fire signals when data changes
   - Other systems can react to data changes
   - Loose coupling between systems

5. **Testing**: Easy to mock controllers for tests
   - Test business logic without real data
   - Mock controller responses for UI tests

## Analytics Integration Pattern

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

## Advanced Controller Patterns

### Controller with Caching

```csharp
public class PlayerDataController
{
    private readonly PlayerData playerData;
    private readonly SignalBus signalBus;
    private float? cachedPowerLevel; // Cached computed value

    public float PowerLevel
    {
        get
        {
            // Return cached value if available
            if (this.cachedPowerLevel.HasValue)
                return this.cachedPowerLevel.Value;

            // Compute and cache
            this.cachedPowerLevel = this.CalculatePowerLevel();
            return this.cachedPowerLevel.Value;
        }
    }

    public void AddExperience(int amount)
    {
        this.playerData.Experience += amount;

        // Invalidate cache when data changes
        this.cachedPowerLevel = null;

        this.signalBus.Fire(new ExperienceGainedSignal(amount));
    }
}
```

### Controller with Validation

```csharp
public class CurrencyController
{
    private readonly CurrencyData currencyData;
    private readonly SignalBus signalBus;

    public bool CanAfford(int amount) => this.currencyData.Gold >= amount;

    public bool TrySpend(int amount)
    {
        if (!this.CanAfford(amount))
        {
            this.signalBus.Fire(new InsufficientFundsSignal());
            return false;
        }

        this.currencyData.Gold -= amount;
        this.signalBus.Fire(new CurrencySpentSignal(amount, this.currencyData.Gold));
        return true;
    }

    public void Earn(int amount)
    {
        if (amount <= 0)
            throw new ArgumentException("Amount must be positive", nameof(amount));

        this.currencyData.Gold += amount;
        this.signalBus.Fire(new CurrencyEarnedSignal(amount, this.currencyData.Gold));
    }
}
```
