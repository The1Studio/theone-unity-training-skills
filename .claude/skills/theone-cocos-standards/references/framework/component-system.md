# Cocos Creator Component System

## Entity-Component (EC) System Overview

Cocos Creator uses an Entity-Component (EC) architecture where:
- **Node** = Entity (game object container)
- **Component** = Behavior/functionality attached to Node
- **Scene** = Collection of Node hierarchies

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass, property } = _decorator;

// ✅ EXCELLENT: Complete component structure
@ccclass('PlayerController')
export class PlayerController extends Component {
    // @property decorator exposes fields to Inspector
    @property(Node)
    private readonly targetNode: Node | null = null;

    @property(Number)
    private readonly moveSpeed: number = 100;

    // Private fields not exposed
    private currentHealth: number = 100;
    private static readonly MAX_HEALTH: number = 100;

    // Lifecycle methods in execution order:
    // 1. onLoad() - Component initialization
    // 2. start() - After all components loaded
    // 3. onEnable() - When enabled (can be called multiple times)
    // 4. update(dt) - Every frame
    // 5. lateUpdate(dt) - After all update() calls
    // 6. onDisable() - When disabled
    // 7. onDestroy() - Cleanup
}
```

## @ccclass Decorator

```typescript
import { _decorator, Component } from 'cc';
const { ccclass } = _decorator;

// ✅ EXCELLENT: @ccclass with explicit name
@ccclass('GameManager')
export class GameManager extends Component {
    // Component implementation
}

// ✅ GOOD: @ccclass without name (uses class name)
@ccclass
export class PlayerController extends Component {
    // Component implementation
}

// ❌ WRONG: Missing @ccclass decorator
export class GameManager extends Component {
    // Won't work - Cocos can't serialize this component
}

// ❌ WRONG: Not extending Component
@ccclass('GameManager')
export class GameManager {
    // Won't work - must extend Component
}
```

## @property Decorator

```typescript
import { _decorator, Component, Node, Sprite, Label } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('PropertyExamples')
export class PropertyExamples extends Component {
    // ✅ EXCELLENT: Node reference
    @property(Node)
    private readonly playerNode: Node | null = null;

    // ✅ EXCELLENT: Component reference
    @property(Sprite)
    private readonly spriteComponent: Sprite | null = null;

    // ✅ EXCELLENT: Primitive types
    @property(Number)
    private readonly moveSpeed: number = 100;

    @property(String)
    private readonly playerName: string = 'Player';

    @property(Boolean)
    private readonly enableDebug: boolean = false;

    // ✅ EXCELLENT: Array of nodes
    @property([Node])
    private readonly enemyNodes: Node[] = [];

    // ✅ EXCELLENT: Array of numbers
    @property([Number])
    private readonly levelScores: number[] = [];

    // ✅ EXCELLENT: Enum property
    @property({ type: Enum(GameState) })
    private currentState: GameState = GameState.LOADING;

    // ✅ EXCELLENT: Property with custom display name and tooltip
    @property({
        type: Number,
        displayName: 'Movement Speed',
        tooltip: 'Player movement speed in units per second',
        min: 0,
        max: 500,
        step: 10,
    })
    private readonly speed: number = 100;

    // ✅ EXCELLENT: readonly for properties that shouldn't be reassigned
    @property(Node)
    private readonly targetNode: Node | null = null; // Can't reassign after initialization

    // Private field (not exposed to Inspector)
    private currentHealth: number = 100;
}

// ❌ WRONG: Property without type
@property
private playerNode: Node | null = null; // Won't serialize correctly

// ❌ WRONG: Mutable property that should be readonly
@property(Node)
private targetNode: Node | null = null; // Should be readonly if not reassigned
```

## Component Lifecycle Methods

### 1. onLoad() - Initialization

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('GameManager')
export class GameManager extends Component {
    @property(Node)
    private readonly playerNode: Node | null = null;

    @property(Node)
    private readonly uiRoot: Node | null = null;

    // ✅ EXCELLENT: onLoad for initialization and validation
    protected onLoad(): void {
        // Validate required references
        if (!this.playerNode) {
            throw new Error('GameManager: playerNode is required');
        }
        if (!this.uiRoot) {
            throw new Error('GameManager: uiRoot is required');
        }

        // Initialize component state
        this.initializeGameState();

        // Cache references (DO NOT reference other components yet)
        this.cacheNodeReferences();
    }

    private initializeGameState(): void {
        // Setup initial state
    }

    private cacheNodeReferences(): void {
        // Cache child nodes for faster access
    }
}

// ❌ WRONG: Accessing other components in onLoad
protected onLoad(): void {
    // Don't do this - other components may not be loaded yet
    const playerController = this.playerNode!.getComponent(PlayerController);
    playerController.initialize(); // May be undefined!
}

// ❌ WRONG: Heavy operations in onLoad
protected onLoad(): void {
    // Avoid expensive operations - onLoad should be fast
    this.loadAllLevelData(); // Should be async in start()
    this.generateProceduralContent(); // Too expensive for onLoad
}
```

### 2. start() - Post-Initialization

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('PlayerController')
export class PlayerController extends Component {
    @property(Node)
    private readonly enemyManagerNode: Node | null = null;

    private enemyManager!: EnemyManager;

    protected onLoad(): void {
        // Validate references
        if (!this.enemyManagerNode) {
            throw new Error('PlayerController: enemyManagerNode is required');
        }
    }

    // ✅ EXCELLENT: start() for referencing other components
    protected start(): void {
        // Safe to get components from other nodes now
        const enemyManager = this.enemyManagerNode!.getComponent(EnemyManager);
        if (!enemyManager) {
            throw new Error('EnemyManager component not found');
        }
        this.enemyManager = enemyManager;

        // Initialize based on other components
        this.setupPlayerBasedOnEnemies();

        // Start async operations
        this.loadPlayerDataAsync();
    }

    private setupPlayerBasedOnEnemies(): void {
        const enemyCount = this.enemyManager.getEnemyCount();
        this.adjustDifficultyBasedOnEnemies(enemyCount);
    }

    private async loadPlayerDataAsync(): Promise<void> {
        // Async loading is safe in start()
    }
}

// ❌ WRONG: Using start() instead of onLoad for validation
protected start(): void {
    // Too late - might be used before start() is called
    if (!this.playerNode) {
        throw new Error('playerNode is required');
    }
}
```

### 3. onEnable() - Activation

```typescript
import { _decorator, Component, Node, EventTouch } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('InputHandler')
export class InputHandler extends Component {
    @property(Node)
    private readonly buttonNode: Node | null = null;

    // ✅ EXCELLENT: onEnable() for registering listeners
    protected onEnable(): void {
        // Register event listeners
        if (this.buttonNode) {
            this.buttonNode.on(Node.EventType.TOUCH_START, this.onTouchStart, this);
            this.buttonNode.on(Node.EventType.TOUCH_END, this.onTouchEnd, this);
        }

        // Subscribe to global events
        EventManager.on(GameEvent.LEVEL_COMPLETE, this.onLevelComplete, this);

        // Resume component operations
        this.resumeGameLogic();
    }

    protected onDisable(): void {
        // ✅ CRITICAL: Always unregister in onDisable
        if (this.buttonNode) {
            this.buttonNode.off(Node.EventType.TOUCH_START, this.onTouchStart, this);
            this.buttonNode.off(Node.EventType.TOUCH_END, this.onTouchEnd, this);
        }

        EventManager.off(GameEvent.LEVEL_COMPLETE, this.onLevelComplete, this);

        // Pause component operations
        this.pauseGameLogic();
    }

    private onTouchStart(event: EventTouch): void {
        // Handle touch
    }

    private onTouchEnd(event: EventTouch): void {
        // Handle touch end
    }

    private onLevelComplete(): void {
        // Handle level complete
    }
}

// ❌ WRONG: Registering listeners in onLoad
protected onLoad(): void {
    // Don't register here - won't be unregistered properly when disabled
    this.node.on(Node.EventType.TOUCH_START, this.onTouchStart, this);
}

// ❌ WRONG: Not unregistering in onDisable
protected onEnable(): void {
    this.node.on(Node.EventType.TOUCH_START, this.onTouchStart, this);
}

protected onDisable(): void {
    // Missing unregistration - memory leak!
}
```

### 4. update(dt) - Per-Frame Logic

```typescript
import { _decorator, Component, Node, Vec3 } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('PlayerMovement')
export class PlayerMovement extends Component {
    @property(Number)
    private readonly moveSpeed: number = 100;

    private readonly tempVec3: Vec3 = new Vec3();
    private inputDirection: Vec3 = new Vec3(1, 0, 0);

    // ✅ EXCELLENT: Efficient update implementation
    protected update(dt: number): void {
        // Reuse preallocated vector
        this.node.getPosition(this.tempVec3);

        // Calculate movement
        this.tempVec3.x += this.inputDirection.x * this.moveSpeed * dt;
        this.tempVec3.y += this.inputDirection.y * this.moveSpeed * dt;

        // Apply new position
        this.node.setPosition(this.tempVec3);
    }
}

// Throttled expensive operations
@ccclass('AIController')
export class AIController extends Component {
    private frameCount: number = 0;
    private static readonly AI_UPDATE_INTERVAL: number = 10;

    // ✅ EXCELLENT: Throttle expensive operations
    protected update(dt: number): void {
        this.frameCount++;

        // Cheap operations every frame
        this.moveTowardsTarget(dt);

        // Expensive AI decisions every 10 frames
        if (this.frameCount % AIController.AI_UPDATE_INTERVAL === 0) {
            this.updateAIDecision();
        }
    }

    private moveTowardsTarget(dt: number): void {
        // Simple movement calculation
    }

    private updateAIDecision(): void {
        // Complex AI logic
    }
}

// ❌ WRONG: Allocations in update
protected update(dt: number): void {
    const currentPos = this.node.position.clone(); // Allocates every frame!
    currentPos.x += this.moveSpeed * dt;
    this.node.setPosition(currentPos);
}

// ❌ WRONG: Expensive operations every frame
protected update(dt: number): void {
    this.recalculatePathfinding(); // A* algorithm 60 times per second!
    this.updateComplexAI(); // Too expensive for every frame
}

// ❌ WRONG: Component lookups in update
protected update(dt: number): void {
    const sprite = this.node.getComponent(Sprite); // Cache this in onLoad!
    sprite?.doSomething();
}
```

### 5. lateUpdate(dt) - Post-Update Logic

```typescript
import { _decorator, Component, Node, Camera } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('CameraFollow')
export class CameraFollow extends Component {
    @property(Node)
    private readonly target: Node | null = null;

    @property(Camera)
    private readonly camera: Camera | null = null;

    // ✅ EXCELLENT: lateUpdate for camera following
    // Runs after all update() calls, ensuring target has moved
    protected lateUpdate(dt: number): void {
        if (!this.target || !this.camera) return;

        // Follow target position after target has been updated
        const targetPos = this.target.position;
        this.camera.node.setPosition(targetPos.x, targetPos.y, this.camera.node.position.z);
    }
}

// ✅ GOOD: lateUpdate for UI that depends on game state
@ccclass('HealthBarUpdater')
export class HealthBarUpdater extends Component {
    @property(Node)
    private readonly healthBar: Node | null = null;

    private playerHealth: number = 100;

    // Health is updated in PlayerController.update()
    // UI is updated in lateUpdate() to reflect final health value
    protected lateUpdate(dt: number): void {
        if (!this.healthBar) return;

        const healthPercentage = this.playerHealth / 100;
        this.healthBar.scale = new Vec3(healthPercentage, 1, 1);
    }
}

// ❌ WRONG: Using lateUpdate for regular logic
protected lateUpdate(dt: number): void {
    // This should be in update(), not lateUpdate()
    this.movePlayer(dt);
}
```

### 6. onDestroy() - Cleanup

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('ResourceManager')
export class ResourceManager extends Component {
    private readonly loadedAssets: Map<string, Asset> = new Map();
    private readonly eventListeners: Set<Function> = new Set();
    private readonly scheduledCallbacks: Set<Function> = new Set();

    // ✅ EXCELLENT: Complete cleanup in onDestroy
    protected onDestroy(): void {
        // Unregister all event listeners
        this.node.off(Node.EventType.TOUCH_START);
        EventManager.off(GameEvent.LEVEL_COMPLETE, this.onLevelComplete, this);

        // Clear collections
        this.eventListeners.clear();
        this.scheduledCallbacks.clear();

        // Release loaded assets
        for (const [id, asset] of this.loadedAssets) {
            asset.decRef();
        }
        this.loadedAssets.clear();

        // Unschedule all callbacks
        this.unscheduleAllCallbacks();

        // Clear any references to prevent memory leaks
        this.clearReferences();
    }

    private clearReferences(): void {
        // Clear any cached references
    }
}

// ❌ WRONG: Missing cleanup
protected onDestroy(): void {
    // Forgot to unregister events - memory leak!
    // Forgot to release assets - memory leak!
    // Forgot to unschedule callbacks - may cause errors!
}

// ❌ WRONG: Incomplete cleanup
protected onDestroy(): void {
    this.loadedAssets.clear(); // Cleared map but didn't decRef assets!
}
```

## Component Execution Order

```typescript
// Execution order when scene loads:
// 1. All components: onLoad() (in hierarchy order)
// 2. All components: start() (in hierarchy order)
// 3. All components: onEnable() (if not already enabled)
// 4. Begin frame loop:
//    - All components: update(dt)
//    - All components: lateUpdate(dt)
// 5. When component disabled:
//    - Component: onDisable()
// 6. When component destroyed:
//    - Component: onDestroy()

// ✅ EXCELLENT: Lifecycle method organization
@ccclass('CompleteLifecycle')
export class CompleteLifecycle extends Component {
    // 1. INITIALIZATION PHASE
    protected onLoad(): void {
        // Initialize component
        // Validate required references
        // Cache node references
        // DO NOT access other components yet
    }

    protected start(): void {
        // Access other components (safe now)
        // Start async operations
        // Initialize based on other components
    }

    // 2. ACTIVATION PHASE
    protected onEnable(): void {
        // Register event listeners
        // Subscribe to global events
        // Resume operations
    }

    // 3. UPDATE PHASE
    protected update(dt: number): void {
        // Per-frame game logic
        // Movement, input, AI
        // Keep allocations zero
    }

    protected lateUpdate(dt: number): void {
        // Logic that depends on update()
        // Camera follow, UI updates
    }

    // 4. DEACTIVATION PHASE
    protected onDisable(): void {
        // Unregister event listeners
        // Unsubscribe from events
        // Pause operations
    }

    // 5. CLEANUP PHASE
    protected onDestroy(): void {
        // Release resources
        // Clear collections
        // Unschedule callbacks
        // Final cleanup
    }
}
```

## Required Reference Validation

```typescript
import { _decorator, Component, Node, Sprite } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('RequiredReferences')
export class RequiredReferences extends Component {
    @property(Node)
    private readonly targetNode: Node | null = null;

    @property(Sprite)
    private readonly spriteComponent: Sprite | null = null;

    @property([Node])
    private readonly enemyNodes: Node[] = [];

    // ✅ EXCELLENT: Validate all required references in onLoad
    protected onLoad(): void {
        if (!this.targetNode) {
            throw new Error('RequiredReferences: targetNode is required');
        }

        if (!this.spriteComponent) {
            throw new Error('RequiredReferences: spriteComponent is required');
        }

        if (this.enemyNodes.length === 0) {
            throw new Error('RequiredReferences: at least one enemy node is required');
        }

        // All references validated - safe to use
        this.initialize();
    }

    private initialize(): void {
        // Can safely use all references here
        this.targetNode!.setPosition(0, 0, 0);
        this.spriteComponent!.sizeMode = Sprite.SizeMode.CUSTOM;
    }
}

// ❌ WRONG: No validation
protected onLoad(): void {
    // Assuming references exist - may crash at runtime
    this.targetNode!.setPosition(0, 0, 0);
}

// ❌ WRONG: Silent validation
protected onLoad(): void {
    if (!this.targetNode) {
        console.error('targetNode is missing'); // Don't just log
        return; // Silent failure
    }
}
```

## Summary: Component System Checklist

**Component Structure:**
- [ ] @ccclass decorator on class
- [ ] Extends Component base class
- [ ] @property decorator for Inspector-exposed fields
- [ ] readonly for properties that aren't reassigned
- [ ] Access modifiers (public/private/protected)

**Lifecycle Implementation:**
- [ ] onLoad() - Validate required references, initialize state
- [ ] start() - Access other components, start async operations
- [ ] onEnable() - Register event listeners
- [ ] update(dt) - Per-frame logic (zero allocations)
- [ ] lateUpdate(dt) - Post-update logic (camera, UI)
- [ ] onDisable() - Unregister event listeners
- [ ] onDestroy() - Release resources, clear references

**Best Practices:**
- [ ] Validate required @property references in onLoad()
- [ ] Throw exceptions for missing required references
- [ ] Cache component references (don't lookup in update)
- [ ] Zero allocations in update/lateUpdate
- [ ] Always unregister listeners in onDisable/onDestroy
- [ ] Use readonly for @property fields when appropriate

**The component lifecycle is the foundation of Cocos Creator architecture.**
