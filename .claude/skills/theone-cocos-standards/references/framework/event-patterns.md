# Cocos Creator Event Patterns

## EventDispatcher Pattern (Custom Events)

```typescript
import { _decorator, Component, EventTarget } from 'cc';
const { ccclass } = _decorator;

// ✅ EXCELLENT: Centralized event system
export enum GameEvent {
    SCORE_CHANGED = 'score_changed',
    LEVEL_COMPLETE = 'level_complete',
    PLAYER_DIED = 'player_died',
    ENEMY_SPAWNED = 'enemy_spawned',
}

export interface ScoreChangedEvent {
    oldScore: number;
    newScore: number;
    combo: number;
}

export interface LevelCompleteEvent {
    level: number;
    stars: number;
    time: number;
}

@ccclass('EventManager')
export class EventManager extends Component {
    private static instance: EventManager | null = null;
    private readonly eventTarget: EventTarget = new EventTarget();

    protected onLoad(): void {
        if (EventManager.instance) {
            throw new Error('EventManager: instance already exists');
        }
        EventManager.instance = this;
    }

    protected onDestroy(): void {
        this.eventTarget.clear();
        EventManager.instance = null;
    }

    // ✅ EXCELLENT: Type-safe emit
    public static emit<T>(event: GameEvent, data?: T): void {
        if (!EventManager.instance) {
            throw new Error('EventManager: instance not initialized');
        }
        EventManager.instance.eventTarget.emit(event, data);
    }

    // ✅ EXCELLENT: Type-safe subscribe
    public static on<T>(event: GameEvent, callback: (data: T) => void, target?: any): void {
        if (!EventManager.instance) {
            throw new Error('EventManager: instance not initialized');
        }
        EventManager.instance.eventTarget.on(event, callback, target);
    }

    // ✅ EXCELLENT: Type-safe unsubscribe
    public static off<T>(event: GameEvent, callback: (data: T) => void, target?: any): void {
        if (!EventManager.instance) {
            throw new Error('EventManager: instance not initialized');
        }
        EventManager.instance.eventTarget.off(event, callback, target);
    }

    // ✅ EXCELLENT: Once (auto-unsubscribe after first call)
    public static once<T>(event: GameEvent, callback: (data: T) => void, target?: any): void {
        if (!EventManager.instance) {
            throw new Error('EventManager: instance not initialized');
        }
        EventManager.instance.eventTarget.once(event, callback, target);
    }
}

// Usage in component
@ccclass('ScoreManager')
export class ScoreManager extends Component {
    private currentScore: number = 0;

    public addScore(points: number): void {
        const oldScore = this.currentScore;
        this.currentScore += points;

        // ✅ EXCELLENT: Emit typed event
        EventManager.emit<ScoreChangedEvent>(GameEvent.SCORE_CHANGED, {
            oldScore,
            newScore: this.currentScore,
            combo: 1,
        });
    }
}

// Subscriber component
@ccclass('ScoreDisplay')
export class ScoreDisplay extends Component {
    protected onEnable(): void {
        // ✅ EXCELLENT: Subscribe in onEnable
        EventManager.on<ScoreChangedEvent>(GameEvent.SCORE_CHANGED, this.onScoreChanged, this);
    }

    protected onDisable(): void {
        // ✅ CRITICAL: Always unsubscribe in onDisable
        EventManager.off<ScoreChangedEvent>(GameEvent.SCORE_CHANGED, this.onScoreChanged, this);
    }

    private onScoreChanged(data: ScoreChangedEvent): void {
        console.log(`Score: ${data.oldScore} → ${data.newScore}`);
        this.updateDisplay(data.newScore);
    }

    private updateDisplay(score: number): void {
        // Update UI
    }
}

// ❌ WRONG: No unsubscription (memory leak)
protected onEnable(): void {
    EventManager.on<ScoreChangedEvent>(GameEvent.SCORE_CHANGED, this.onScoreChanged, this);
}

// Missing onDisable - memory leak!

// ❌ WRONG: String-based events (not type-safe)
EventManager.emit('score_changed', { score: 100 }); // Typo-prone
```

## Node Event System (Built-in Events)

```typescript
import { _decorator, Component, Node, EventTouch, EventKeyboard } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('TouchHandler')
export class TouchHandler extends Component {
    @property(Node)
    private readonly buttonNode: Node | null = null;

    // ✅ EXCELLENT: Touch event handling
    protected onEnable(): void {
        if (!this.buttonNode) return;

        this.buttonNode.on(Node.EventType.TOUCH_START, this.onTouchStart, this);
        this.buttonNode.on(Node.EventType.TOUCH_MOVE, this.onTouchMove, this);
        this.buttonNode.on(Node.EventType.TOUCH_END, this.onTouchEnd, this);
        this.buttonNode.on(Node.EventType.TOUCH_CANCEL, this.onTouchCancel, this);
    }

    protected onDisable(): void {
        if (!this.buttonNode) return;

        this.buttonNode.off(Node.EventType.TOUCH_START, this.onTouchStart, this);
        this.buttonNode.off(Node.EventType.TOUCH_MOVE, this.onTouchMove, this);
        this.buttonNode.off(Node.EventType.TOUCH_END, this.onTouchEnd, this);
        this.buttonNode.off(Node.EventType.TOUCH_CANCEL, this.onTouchCancel, this);
    }

    private onTouchStart(event: EventTouch): void {
        const location = event.getUILocation();
        console.log(`Touch start at: ${location.x}, ${location.y}`);
    }

    private onTouchMove(event: EventTouch): void {
        const delta = event.getUIDelta();
        console.log(`Touch delta: ${delta.x}, ${delta.y}`);
    }

    private onTouchEnd(event: EventTouch): void {
        console.log('Touch ended');
    }

    private onTouchCancel(event: EventTouch): void {
        console.log('Touch cancelled');
    }
}

// ✅ EXCELLENT: Keyboard event handling
@ccclass('KeyboardHandler')
export class KeyboardHandler extends Component {
    protected onEnable(): void {
        this.node.on(Node.EventType.KEY_DOWN, this.onKeyDown, this);
        this.node.on(Node.EventType.KEY_UP, this.onKeyUp, this);
    }

    protected onDisable(): void {
        this.node.off(Node.EventType.KEY_DOWN, this.onKeyDown, this);
        this.node.off(Node.EventType.KEY_UP, this.onKeyUp, this);
    }

    private onKeyDown(event: EventKeyboard): void {
        switch (event.keyCode) {
            case macro.KEY.w:
            case macro.KEY.up:
                this.moveUp();
                break;
            case macro.KEY.s:
            case macro.KEY.down:
                this.moveDown();
                break;
        }
    }

    private onKeyUp(event: EventKeyboard): void {
        this.stopMovement();
    }
}
```

## Event Cleanup Patterns

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass, property } = _decorator;

// ✅ EXCELLENT: Comprehensive cleanup pattern
@ccclass('CompleteEventCleanup')
export class CompleteEventCleanup extends Component {
    @property(Node)
    private readonly targetNode: Node | null = null;

    // Track registered listeners for complete cleanup
    private readonly registeredListeners: Array<{
        node: Node;
        eventType: string;
        callback: Function;
    }> = [];

    protected onEnable(): void {
        if (!this.targetNode) return;

        // Register and track listeners
        this.registerListener(
            this.targetNode,
            Node.EventType.TOUCH_START,
            this.onTouchStart
        );
        this.registerListener(
            this.node,
            Node.EventType.CHILD_ADDED,
            this.onChildAdded
        );

        // Subscribe to global events
        EventManager.on(GameEvent.LEVEL_COMPLETE, this.onLevelComplete, this);
    }

    protected onDisable(): void {
        // Unregister all tracked listeners
        for (const { node, eventType, callback } of this.registeredListeners) {
            node.off(eventType, callback, this);
        }
        this.registeredListeners.length = 0;

        // Unsubscribe from global events
        EventManager.off(GameEvent.LEVEL_COMPLETE, this.onLevelComplete, this);
    }

    private registerListener(node: Node, eventType: string, callback: Function): void {
        node.on(eventType, callback, this);
        this.registeredListeners.push({ node, eventType, callback });
    }

    private onTouchStart(event: EventTouch): void {
        // Handle touch
    }

    private onChildAdded(child: Node): void {
        // Handle child added
    }

    private onLevelComplete(): void {
        // Handle level complete
    }
}

// ✅ EXCELLENT: Automatic cleanup with disposable pattern
interface IDisposable {
    dispose(): void;
}

class EventSubscription implements IDisposable {
    constructor(
        private readonly eventManager: EventManager,
        private readonly event: GameEvent,
        private readonly callback: Function,
        private readonly target: any
    ) {}

    public dispose(): void {
        EventManager.off(this.event, this.callback as any, this.target);
    }
}

@ccclass('DisposablePattern')
export class DisposablePattern extends Component {
    private readonly subscriptions: IDisposable[] = [];

    protected onEnable(): void {
        // ✅ EXCELLENT: Track subscriptions for auto-cleanup
        this.subscriptions.push(
            new EventSubscription(
                EventManager.instance!,
                GameEvent.SCORE_CHANGED,
                this.onScoreChanged,
                this
            )
        );
    }

    protected onDisable(): void {
        // ✅ EXCELLENT: Dispose all subscriptions
        for (const subscription of this.subscriptions) {
            subscription.dispose();
        }
        this.subscriptions.length = 0;
    }

    private onScoreChanged(data: ScoreChangedEvent): void {
        // Handle score change
    }
}
```

## Event Performance Best Practices

```typescript
import { _decorator, Component } from 'cc';
const { ccclass } = _decorator;

@ccclass('PerformanceOptimizedEvents')
export class PerformanceOptimizedEvents extends Component {
    // ✅ EXCELLENT: Throttle frequent events
    private lastEmitTime: number = 0;
    private static readonly EMIT_THROTTLE_MS: number = 100; // Max 10 events/second

    public emitThrottled(event: GameEvent, data: any): void {
        const now = Date.now();
        if (now - this.lastEmitTime >= PerformanceOptimizedEvents.EMIT_THROTTLE_MS) {
            EventManager.emit(event, data);
            this.lastEmitTime = now;
        }
    }

    // ✅ EXCELLENT: Batch events to reduce overhead
    private readonly pendingEvents: Array<{ event: GameEvent; data: any }> = [];
    private batchEmitScheduled: boolean = false;

    public emitBatched(event: GameEvent, data: any): void {
        this.pendingEvents.push({ event, data });

        if (!this.batchEmitScheduled) {
            this.batchEmitScheduled = true;
            this.scheduleOnce(() => {
                this.flushBatchedEvents();
            }, 0);
        }
    }

    private flushBatchedEvents(): void {
        for (const { event, data } of this.pendingEvents) {
            EventManager.emit(event, data);
        }
        this.pendingEvents.length = 0;
        this.batchEmitScheduled = false;
    }

    // ✅ EXCELLENT: Debounce events (emit only after quiet period)
    private debounceTimer: number | null = null;
    private static readonly DEBOUNCE_MS: number = 300;

    public emitDebounced(event: GameEvent, data: any): void {
        if (this.debounceTimer !== null) {
            clearTimeout(this.debounceTimer);
        }

        this.debounceTimer = setTimeout(() => {
            EventManager.emit(event, data);
            this.debounceTimer = null;
        }, PerformanceOptimizedEvents.DEBOUNCE_MS) as any;
    }
}

// ❌ WRONG: Emitting events in update loop
protected update(dt: number): void {
    // Emits 60 events per second!
    EventManager.emit(GameEvent.PLAYER_MOVED, this.node.position);
}

// ✅ BETTER: Throttle or emit only on significant changes
private lastPosition: Vec3 = new Vec3();
private static readonly MOVE_THRESHOLD: number = 1.0;

protected update(dt: number): void {
    const distance = Vec3.distance(this.node.position, this.lastPosition);

    if (distance >= PerformanceOptimizedEvents.MOVE_THRESHOLD) {
        EventManager.emit(GameEvent.PLAYER_MOVED, this.node.position.clone());
        this.lastPosition.set(this.node.position);
    }
}
```

## Summary: Event Pattern Checklist

**EventDispatcher (Custom Events):**
- [ ] Use centralized EventManager with EventTarget
- [ ] Define event names as enum (not strings)
- [ ] Use typed event data interfaces
- [ ] Subscribe in onEnable(), unsubscribe in onDisable()
- [ ] Always pass `this` as target parameter for proper cleanup

**Node Events (Built-in):**
- [ ] Use Node.EventType constants (TOUCH_START, KEY_DOWN, etc.)
- [ ] Register listeners in onEnable()
- [ ] Unregister listeners in onDisable() with same parameters
- [ ] Handle EventTouch and EventKeyboard properly

**Event Cleanup:**
- [ ] Track all registered listeners for complete cleanup
- [ ] Unregister in both onDisable() and onDestroy()
- [ ] Use disposable pattern for automatic cleanup
- [ ] Clear event collections in onDestroy()

**Performance:**
- [ ] Throttle frequent events (max 10/second)
- [ ] Batch events to reduce overhead
- [ ] Debounce events for user input
- [ ] Never emit events in update() without throttling

**Always unsubscribe from events to prevent memory leaks.**
