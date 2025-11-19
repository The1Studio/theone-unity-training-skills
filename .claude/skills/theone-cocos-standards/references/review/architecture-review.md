# Cocos Creator Architecture Review

This review focuses on Cocos Creator-specific architectural issues including component lifecycle violations, event management problems, and performance issues specific to playable ads.

## Component Lifecycle Violations

### Accessing Components in onLoad

```typescript
// ❌ CRITICAL: Accessing other components in onLoad
@ccclass('BadLifecycle')
export class BadLifecycle extends Component {
    @property(Node)
    private playerNode: Node | null = null;

    protected onLoad(): void {
        // WRONG: Other components may not be loaded yet
        const controller = this.playerNode!.getComponent(PlayerController);
        controller.initialize(); // May be undefined!
    }
}

// ✅ CORRECT: Access components in start()
@ccclass('GoodLifecycle')
export class GoodLifecycle extends Component {
    @property(Node)
    private readonly playerNode: Node | null = null;

    private playerController!: PlayerController;

    protected onLoad(): void {
        if (!this.playerNode) {
            throw new Error('GoodLifecycle: playerNode is required');
        }
    }

    protected start(): void {
        const controller = this.playerNode!.getComponent(PlayerController);
        if (!controller) {
            throw new Error('PlayerController not found');
        }
        this.playerController = controller;
        this.playerController.initialize();
    }
}

// Severity: 🔴 Critical
// Impact: Undefined behavior, crashes
// Fix: Move component access from onLoad() to start()
```

### Event Listener Memory Leaks

```typescript
// ❌ CRITICAL: Not unregistering event listeners
@ccclass('EventLeakBad')
export class EventLeakBad extends Component {
    protected onEnable(): void {
        this.node.on(Node.EventType.TOUCH_START, this.onTouchStart, this);
        EventManager.on(GameEvent.SCORE_CHANGED, this.onScoreChanged, this);
    }

    // MISSING: onDisable() - memory leak!
}

// ✅ CORRECT: Always unregister in onDisable
@ccclass('EventLeakGood')
export class EventLeakGood extends Component {
    protected onEnable(): void {
        this.node.on(Node.EventType.TOUCH_START, this.onTouchStart, this);
        EventManager.on(GameEvent.SCORE_CHANGED, this.onScoreChanged, this);
    }

    protected onDisable(): void {
        this.node.off(Node.EventType.TOUCH_START, this.onTouchStart, this);
        EventManager.off(GameEvent.SCORE_CHANGED, this.onScoreChanged, this);
    }

    private onTouchStart(event: EventTouch): void {}
    private onScoreChanged(data: ScoreChangedEvent): void {}
}

// Severity: 🔴 Critical
// Impact: Memory leaks, performance degradation
// Fix: Always implement onDisable() to unregister listeners
```

### Missing Required Reference Validation

```typescript
// ❌ CRITICAL: No validation of required references
@ccclass('NoValidation')
export class NoValidation extends Component {
    @property(Node)
    private targetNode: Node | null = null;

    protected onLoad(): void {
        this.targetNode!.setPosition(0, 0, 0); // Will crash if null
    }
}

// ✅ CORRECT: Validate in onLoad
@ccclass('WithValidation')
export class WithValidation extends Component {
    @property(Node)
    private readonly targetNode: Node | null = null;

    protected onLoad(): void {
        if (!this.targetNode) {
            throw new Error('WithValidation: targetNode is required');
        }
        this.targetNode.setPosition(0, 0, 0);
    }
}

// Severity: 🔴 Critical
// Impact: Runtime crashes with unhelpful errors
// Fix: Validate all required @property references in onLoad()
```

### Resource Cleanup Violations

```typescript
// ❌ CRITICAL: Not releasing resources
@ccclass('ResourceLeakBad')
export class ResourceLeakBad extends Component {
    private readonly loadedAssets: Map<string, Asset> = new Map();

    protected onDestroy(): void {
        // MISSING: decRef() and clear()
    }
}

// ✅ CORRECT: Complete cleanup
@ccclass('ResourceLeakGood')
export class ResourceLeakGood extends Component {
    private readonly loadedAssets: Map<string, Asset> = new Map();

    protected onDestroy(): void {
        for (const [id, asset] of this.loadedAssets) {
            asset.decRef();
        }
        this.loadedAssets.clear();
        this.unscheduleAllCallbacks();
    }
}

// Severity: 🔴 Critical
// Impact: Memory leaks
// Fix: Release resources and clear collections in onDestroy()
```

## Performance Violations (Playable-Specific)

### Allocations in Update Loop

```typescript
// ❌ CRITICAL: Allocating every frame
@ccclass('UpdateAllocationsBad')
export class UpdateAllocationsBad extends Component {
    protected update(dt: number): void {
        const pos = this.node.position.clone(); // 60 allocations/second
        pos.y += 10 * dt;
        this.node.setPosition(pos);
    }
}

// ✅ CORRECT: Preallocate and reuse
@ccclass('UpdateAllocationsGood')
export class UpdateAllocationsGood extends Component {
    private readonly tempVec3: Vec3 = new Vec3();

    protected update(dt: number): void {
        this.node.getPosition(this.tempVec3);
        this.tempVec3.y += 10 * dt;
        this.node.setPosition(this.tempVec3);
    }
}

// Severity: 🔴 Critical
// Impact: Frame drops, GC pauses
// Fix: Preallocate objects, reuse in update
```

### Component Lookup in Update

```typescript
// ❌ IMPORTANT: getComponent in update
@ccclass('ComponentLookupBad')
export class ComponentLookupBad extends Component {
    @property(Node)
    private playerNode: Node | null = null;

    protected update(dt: number): void {
        const controller = this.playerNode!.getComponent(PlayerController); // Expensive!
        controller?.update(dt);
    }
}

// ✅ CORRECT: Cache component reference
@ccclass('ComponentLookupGood')
export class ComponentLookupGood extends Component {
    @property(Node)
    private readonly playerNode: Node | null = null;

    private playerController!: PlayerController;

    protected start(): void {
        if (!this.playerNode) {
            throw new Error('playerNode is required');
        }
        const controller = this.playerNode.getComponent(PlayerController);
        if (!controller) {
            throw new Error('PlayerController not found');
        }
        this.playerController = controller;
    }

    protected update(dt: number): void {
        this.playerController.update(dt);
    }
}

// Severity: 🟡 Important
// Impact: Significant performance overhead
// Fix: Cache component references in start()
```

## Summary: Architecture Review Checklist

**🔴 Critical (Must Fix):**
- [ ] No component access in onLoad() (use start())
- [ ] All event listeners unregistered in onDisable()
- [ ] Required @property references validated in onLoad()
- [ ] Resources released in onDestroy()
- [ ] Zero allocations in update() loop
- [ ] readonly used for @property fields not reassigned

**🟡 Important (Should Fix):**
- [ ] Component references cached (not getComponent in update)
- [ ] Expensive operations throttled (every N frames)
- [ ] Node references cached (not find() in update)
- [ ] Arrays cleared with .length = 0 (not new array)

**🟢 Nice to Have:**
- [ ] Object pooling for frequent spawn/despawn
- [ ] WeakMap for auto-cleanup caches
- [ ] Disposable pattern for subscription management

**Always fix lifecycle and event cleanup issues - they cause crashes and memory leaks.**
