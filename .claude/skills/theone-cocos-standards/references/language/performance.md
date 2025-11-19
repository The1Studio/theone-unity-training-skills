# TypeScript Performance Optimization

## Zero Allocations in update()

**Critical Rule**: Never allocate objects in `update()`, `lateUpdate()`, or any method called every frame.

```typescript
import { _decorator, Component, Node, Vec3, Quat } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('OptimizedController')
export class OptimizedController extends Component {
    @property(Node)
    private readonly targetNode: Node | null = null;

    // ✅ EXCELLENT: Preallocated reusable objects
    private readonly tempVec3: Vec3 = new Vec3();
    private readonly tempQuat: Quat = new Quat();
    private readonly tempVec3Array: Vec3[] = [];

    // ✅ EXCELLENT: No allocations in update
    protected update(dt: number): void {
        if (!this.targetNode) return;

        // Reuse preallocated vector
        this.targetNode.getPosition(this.tempVec3);
        this.tempVec3.y += 10 * dt;
        this.targetNode.setPosition(this.tempVec3);

        // Reuse preallocated quaternion
        this.targetNode.getRotation(this.tempQuat);
        Quat.rotateY(this.tempQuat, this.tempQuat, dt);
        this.targetNode.setRotation(this.tempQuat);
    }

    // ✅ EXCELLENT: Reuse array instead of creating new one
    public updateMultipleNodes(nodes: Node[]): void {
        this.tempVec3Array.length = 0; // Clear without allocating

        for (const node of nodes) {
            node.getPosition(this.tempVec3);
            this.tempVec3Array.push(this.tempVec3.clone());
        }
    }
}

// ❌ WRONG: Allocating in update
protected update(dt: number): void {
    if (!this.targetNode) return;

    // Creates new Vec3 every frame (60 allocations/second)
    const currentPos = this.targetNode.position.clone();
    currentPos.y += 10 * dt;
    this.targetNode.setPosition(currentPos);

    // Creates new array every frame
    const positions = this.nodes.map(n => n.position.clone());
}

// ❌ WRONG: String concatenation in update
protected update(dt: number): void {
    // Creates new string every frame
    const debugInfo = `Position: ${this.node.position.x}, ${this.node.position.y}`;
    console.log(debugInfo);
}
```

## Object Pooling Pattern

```typescript
import { _decorator, Component, Node, Prefab, instantiate, NodePool } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('BulletPool')
export class BulletPool extends Component {
    @property(Prefab)
    private readonly bulletPrefab: Prefab | null = null;

    private readonly pool: NodePool = new NodePool();
    private static readonly INITIAL_POOL_SIZE: number = 20;

    // ✅ EXCELLENT: Prewarm pool on initialization
    protected onLoad(): void {
        if (!this.bulletPrefab) {
            throw new Error('BulletPool: bulletPrefab is required');
        }

        for (let i = 0; i < BulletPool.INITIAL_POOL_SIZE; i++) {
            const bullet = instantiate(this.bulletPrefab);
            this.pool.put(bullet);
        }
    }

    // ✅ EXCELLENT: Get from pool (no allocation if available)
    public getBullet(): Node {
        let bullet: Node;

        if (this.pool.size() > 0) {
            bullet = this.pool.get()!;
        } else {
            // Only allocate if pool is empty
            if (!this.bulletPrefab) {
                throw new Error('BulletPool: bulletPrefab is required');
            }
            bullet = instantiate(this.bulletPrefab);
        }

        bullet.active = true;
        return bullet;
    }

    // ✅ EXCELLENT: Return to pool (no deallocation)
    public returnBullet(bullet: Node): void {
        bullet.active = false;
        this.pool.put(bullet);
    }

    // ✅ EXCELLENT: Clear pool on cleanup
    protected onDestroy(): void {
        this.pool.clear();
    }
}

// Usage in game
@ccclass('Gun')
export class Gun extends Component {
    private readonly bulletPool!: BulletPool;

    public shoot(): void {
        // ✅ GOOD: Get from pool instead of instantiate
        const bullet = this.bulletPool.getBullet();
        bullet.setPosition(this.node.position);

        // Set up bullet with timeout to return to pool
        this.scheduleOnce(() => {
            this.bulletPool.returnBullet(bullet);
        }, 3.0);
    }
}

// ❌ WRONG: Creating new instances every time
public shoot(): void {
    // Allocates and deallocates constantly
    const bullet = instantiate(this.bulletPrefab!);
    bullet.setPosition(this.node.position);

    this.scheduleOnce(() => {
        bullet.destroy(); // Triggers garbage collection
    }, 3.0);
}
```

## Caching Expensive Operations

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('EnemyManager')
export class EnemyManager extends Component {
    @property([Node])
    private readonly enemyNodes: Node[] = [];

    // ✅ EXCELLENT: Cache component references
    private readonly enemyControllers: EnemyController[] = [];
    private cachedActiveEnemies: EnemyController[] = [];
    private activeEnemiesDirty: boolean = true;

    protected onLoad(): void {
        // Cache component references on initialization
        for (const node of this.enemyNodes) {
            const controller = node.getComponent(EnemyController);
            if (controller) {
                this.enemyControllers.push(controller);
            }
        }
    }

    // ✅ EXCELLENT: Mark cache as dirty instead of recalculating
    public onEnemyStateChanged(): void {
        this.activeEnemiesDirty = true;
    }

    // ✅ EXCELLENT: Lazy recalculation only when needed
    public getActiveEnemies(): EnemyController[] {
        if (this.activeEnemiesDirty) {
            this.cachedActiveEnemies = this.enemyControllers.filter(e => e.isActive);
            this.activeEnemiesDirty = false;
        }
        return this.cachedActiveEnemies;
    }

    protected update(dt: number): void {
        // ✅ GOOD: Use cached active enemies
        const activeEnemies = this.getActiveEnemies();

        for (const enemy of activeEnemies) {
            enemy.update(dt);
        }
    }
}

// ❌ WRONG: Finding components every frame
protected update(dt: number): void {
    for (const node of this.enemyNodes) {
        const controller = node.getComponent(EnemyController); // Expensive lookup!
        if (controller?.isActive) {
            controller.update(dt);
        }
    }
}

// ❌ WRONG: Filtering every frame
protected update(dt: number): void {
    const activeEnemies = this.enemyControllers.filter(e => e.isActive); // Allocates array every frame!
    for (const enemy of activeEnemies) {
        enemy.update(dt);
    }
}
```

## Throttling Expensive Operations

```typescript
import { _decorator, Component } from 'cc';
const { ccclass } = _decorator;

@ccclass('AIController')
export class AIController extends Component {
    private frameCount: number = 0;
    private static readonly AI_UPDATE_INTERVAL: number = 10; // Every 10 frames
    private static readonly PATHFINDING_INTERVAL: number = 60; // Every 60 frames (1 second at 60fps)

    // ✅ EXCELLENT: Update AI every N frames, not every frame
    protected update(dt: number): void {
        this.frameCount++;

        // Run expensive AI logic every 10 frames instead of every frame
        if (this.frameCount % AIController.AI_UPDATE_INTERVAL === 0) {
            this.updateAIDecision();
        }

        // Run very expensive pathfinding every 60 frames (1 second)
        if (this.frameCount % AIController.PATHFINDING_INTERVAL === 0) {
            this.recalculatePath();
        }

        // Cheap operations can run every frame
        this.moveTowardsTarget(dt);
    }

    private updateAIDecision(): void {
        // Expensive: Check all enemies, evaluate threats, etc.
    }

    private recalculatePath(): void {
        // Very expensive: A* pathfinding
    }

    private moveTowardsTarget(dt: number): void {
        // Cheap: Simple movement
    }
}

// ❌ WRONG: Expensive operations every frame
protected update(dt: number): void {
    this.recalculatePath(); // A* pathfinding 60 times per second!
    this.updateAIDecision(); // Complex AI logic 60 times per second!
    this.moveTowardsTarget(dt);
}
```

## Time-Based Throttling

```typescript
import { _decorator, Component } from 'cc';
const { ccclass } = _decorator;

@ccclass('PerformanceMonitor')
export class PerformanceMonitor extends Component {
    private lastUpdateTime: number = 0;
    private static readonly UPDATE_INTERVAL: number = 1.0; // 1 second

    // ✅ EXCELLENT: Time-based throttling
    protected update(dt: number): void {
        const currentTime = Date.now() / 1000;

        if (currentTime - this.lastUpdateTime >= PerformanceMonitor.UPDATE_INTERVAL) {
            this.performExpensiveOperation();
            this.lastUpdateTime = currentTime;
        }
    }

    private performExpensiveOperation(): void {
        // Expensive operation that runs once per second
    }
}

// Alternative using scheduleOnce
@ccclass('TimerBased')
export class TimerBased extends Component {
    private static readonly CHECK_INTERVAL: number = 2.0; // 2 seconds

    protected start(): void {
        this.scheduleCheckRecurring();
    }

    private scheduleCheckRecurring(): void {
        this.performCheck();
        this.scheduleOnce(this.scheduleCheckRecurring, TimerBased.CHECK_INTERVAL);
    }

    private performCheck(): void {
        // Expensive check operation
    }
}
```

## Avoid Expensive Lookups

```typescript
import { _decorator, Component, Node, find } from 'cc';
const { ccclass } = _decorator;

@ccclass('GameManager')
export class GameManager extends Component {
    // ✅ EXCELLENT: Cache references in onLoad
    private uiRootNode!: Node;
    private playerNode!: Node;
    private enemyNodes: Node[] = [];

    protected onLoad(): void {
        // Cache node references once
        const uiRoot = find('Canvas/UI');
        if (!uiRoot) {
            throw new Error('GameManager: UI root not found');
        }
        this.uiRootNode = uiRoot;

        const player = find('Canvas/Player');
        if (!player) {
            throw new Error('GameManager: Player not found');
        }
        this.playerNode = player;

        // Cache array of enemy nodes
        const enemyParent = find('Canvas/Enemies');
        if (enemyParent) {
            this.enemyNodes = enemyParent.children.slice();
        }
    }

    protected update(dt: number): void {
        // ✅ GOOD: Use cached references
        this.updatePlayer(this.playerNode, dt);
        this.updateEnemies(this.enemyNodes, dt);
    }
}

// ❌ WRONG: Finding nodes every frame
protected update(dt: number): void {
    const player = find('Canvas/Player'); // Expensive search every frame!
    const enemies = find('Canvas/Enemies')?.children; // Expensive search every frame!

    if (player) {
        this.updatePlayer(player, dt);
    }
    if (enemies) {
        this.updateEnemies(enemies, dt);
    }
}

// ❌ WRONG: getComponent every frame
protected update(dt: number): void {
    const playerController = this.playerNode.getComponent(PlayerController); // Expensive lookup!
    playerController?.update(dt);
}

// ✅ BETTER: Cache component reference
private playerController!: PlayerController;

protected onLoad(): void {
    const controller = this.playerNode.getComponent(PlayerController);
    if (!controller) {
        throw new Error('PlayerController not found');
    }
    this.playerController = controller;
}

protected update(dt: number): void {
    this.playerController.update(dt);
}
```

## String Concatenation Performance

```typescript
import { _decorator, Component } from 'cc';
const { ccclass } = _decorator;

@ccclass('DebugDisplay')
export class DebugDisplay extends Component {
    // ✅ EXCELLENT: Use template literals for readability
    public getDebugInfo(player: Player): string {
        return `Player: ${player.name}, HP: ${player.health}/${player.maxHealth}, Level: ${player.level}`;
    }

    // ✅ EXCELLENT: Build strings efficiently with array join (for large strings)
    public generateReport(players: Player[]): string {
        const lines: string[] = [];
        lines.push('=== Player Report ===');

        for (const player of players) {
            lines.push(`${player.name}: Level ${player.level}, HP ${player.health}`);
        }

        lines.push('=== End Report ===');
        return lines.join('\n');
    }

    // ✅ EXCELLENT: Avoid string operations in update loop
    private debugText: string = '';
    private frameCount: number = 0;

    protected update(dt: number): void {
        this.frameCount++;

        // Only update debug text every 30 frames
        if (this.frameCount % 30 === 0) {
            this.debugText = this.generateDebugText();
        }
    }
}

// ❌ WRONG: String concatenation in loop
public generateReport(players: Player[]): string {
    let report = '=== Player Report ===\n';

    for (const player of players) {
        report += `${player.name}: Level ${player.level}\n`; // Allocates new string each iteration
    }

    report += '=== End Report ===';
    return report;
}

// ❌ WRONG: Building strings in update
protected update(dt: number): void {
    this.debugText = `FPS: ${1/dt}, Position: ${this.node.position}`; // Allocates every frame
}
```

## Number Operations Performance

```typescript
import { _decorator, Component } from 'cc';
const { ccclass } = _decorator;

@ccclass('MathOptimizations')
export class MathOptimizations extends Component {
    // ✅ EXCELLENT: Use multiplication instead of division
    private static readonly INV_FRAME_RATE: number = 1 / 60;

    public calculateTimedValue(value: number): number {
        return value * MathOptimizations.INV_FRAME_RATE; // Faster than value / 60
    }

    // ✅ EXCELLENT: Use bitwise operations for integer math
    public fastFloor(value: number): number {
        return value | 0; // Faster than Math.floor for positive numbers
    }

    public isPowerOfTwo(value: number): boolean {
        return (value & (value - 1)) === 0; // Faster than logarithm check
    }

    // ✅ EXCELLENT: Cache expensive math operations
    private readonly sinCache: Map<number, number> = new Map();

    public getCachedSin(angle: number): number {
        if (!this.sinCache.has(angle)) {
            this.sinCache.set(angle, Math.sin(angle));
        }
        return this.sinCache.get(angle)!;
    }

    // ✅ EXCELLENT: Use squared distance to avoid sqrt
    public isWithinRange(pos1: Vec3, pos2: Vec3, range: number): boolean {
        const dx = pos2.x - pos1.x;
        const dy = pos2.y - pos1.y;
        const dz = pos2.z - pos1.z;
        const distSquared = dx * dx + dy * dy + dz * dz;
        const rangeSquared = range * range;
        return distSquared <= rangeSquared; // No sqrt needed
    }
}

// ❌ WRONG: Using expensive operations
public isWithinRange(pos1: Vec3, pos2: Vec3, range: number): boolean {
    const distance = Vec3.distance(pos1, pos2); // Uses sqrt internally
    return distance <= range;
}

// ❌ WRONG: Division in hot path
protected update(dt: number): void {
    const value = this.baseValue / 60; // Division is slower than multiplication
}
```

## Memory Management Best Practices

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass } = _decorator;

@ccclass('ResourceManager')
export class ResourceManager extends Component {
    private readonly loadedAssets: Map<string, Asset> = new Map();
    private readonly nodeReferences: Set<Node> = new Set();

    // ✅ EXCELLENT: Clear references on cleanup
    protected onDestroy(): void {
        // Clear maps and sets
        this.loadedAssets.clear();
        this.nodeReferences.clear();

        // Remove event listeners
        this.node.off(Node.EventType.TOUCH_START);
    }

    // ✅ EXCELLENT: Remove unused assets
    public unloadAsset(assetId: string): void {
        const asset = this.loadedAssets.get(assetId);
        if (asset) {
            asset.decRef(); // Release reference
            this.loadedAssets.delete(assetId);
        }
    }

    // ✅ EXCELLENT: Weak references for caches
    private readonly weakNodeCache: WeakMap<Node, CachedData> = new WeakMap();

    public getCachedData(node: Node): CachedData | undefined {
        return this.weakNodeCache.get(node);
    }

    public setCachedData(node: Node, data: CachedData): void {
        this.weakNodeCache.set(node, data);
        // Node is garbage collected → cache entry is automatically removed
    }
}

// ❌ WRONG: Memory leaks
protected onDestroy(): void {
    // Forgot to clear references - memory leak!
    // this.loadedAssets.clear();
    // this.nodeReferences.clear();
}

// ❌ WRONG: Strong references prevent garbage collection
private readonly nodeCache: Map<Node, CachedData> = new Map();
// Nodes are never garbage collected even when destroyed
```

## Summary: Performance Checklist

**Critical for playable ads (<5MB, <10 DrawCalls):**

- [ ] Zero allocations in update() (preallocate and reuse)
- [ ] Object pooling for frequently created/destroyed objects
- [ ] Cache component and node references (no getComponent in update)
- [ ] Throttle expensive operations (every N frames, not every frame)
- [ ] Avoid string operations in hot paths
- [ ] Use multiplication instead of division
- [ ] Use squared distance instead of distance (avoid sqrt)
- [ ] Clear references in onDestroy() to prevent memory leaks
- [ ] Use WeakMap for caches that should be garbage collected
- [ ] Array.length = 0 to clear arrays (don't create new arrays)

**Performance is critical for smooth 60fps playable ads.**
