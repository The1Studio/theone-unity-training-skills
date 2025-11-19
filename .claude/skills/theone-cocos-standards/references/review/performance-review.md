# Playable Ads Performance Review

This review focuses on performance issues specific to playable ads including DrawCall optimization, bundle size, update loop performance, and resource management.

## DrawCall Explosion (Critical for Playables)

**Target: <10 DrawCalls for 60fps playables**

```typescript
// ❌ CRITICAL: Individual textures (multiple DrawCalls)
@ccclass('DrawCallBad')
export class DrawCallBad extends Component {
    @property(SpriteFrame)
    private sprite1: SpriteFrame | null = null; // DrawCall 1

    @property(SpriteFrame)
    private sprite2: SpriteFrame | null = null; // DrawCall 2

    @property(SpriteFrame)
    private sprite3: SpriteFrame | null = null; // DrawCall 3

    // 10 sprites = 10 DrawCalls! (BAD)
}

// ✅ CORRECT: Sprite atlas (single DrawCall)
@ccclass('DrawCallGood')
export class DrawCallGood extends Component {
    @property(SpriteAtlas)
    private readonly characterAtlas: SpriteAtlas | null = null; // 1 DrawCall for all
}

// Severity: 🔴 Critical
// Impact: Frame drops, poor performance
// Target: <10 DrawCalls total
// Fix: Use sprite atlases for all sprites
```

## Update Loop Allocations

```typescript
// ❌ CRITICAL: Allocating in update
@ccclass('UpdateAllocationsBad')
export class UpdateAllocationsBad extends Component {
    protected update(dt: number): void {
        // Creates new Vec3 every frame
        const pos = this.node.position.clone(); // 60 allocations/second!
        pos.y += 10 * dt;
        this.node.setPosition(pos);

        // Creates array every frame
        const enemies = this.getAllEnemies().filter(e => e.active); // 60 arrays/second!
    }
}

// ✅ CORRECT: Zero allocations
@ccclass('UpdateAllocationsGood')
export class UpdateAllocationsGood extends Component {
    private readonly tempVec3: Vec3 = new Vec3();
    private readonly activeEnemies: Enemy[] = [];
    private cacheRDirty: boolean = true;

    protected update(dt: number): void {
        // Reuse preallocated vector
        this.node.getPosition(this.tempVec3);
        this.tempVec3.y += 10 * dt;
        this.node.setPosition(this.tempVec3);

        // Use cached array
        const enemies = this.getActiveEnemies();
    }

    private getActiveEnemies(): Enemy[] {
        if (this.cacheDirty) {
            this.activeEnemies.length = 0;
            // Rebuild cache
            this.cacheDirty = false;
        }
        return this.activeEnemies;
    }
}

// Severity: 🔴 Critical
// Impact: Frame drops, GC pauses
// Fix: Preallocate objects, reuse in update
```

## No Object Pooling

```typescript
// ❌ IMPORTANT: instantiate/destroy in gameplay
@ccclass('NoPoolingBad')
export class NoPoolingBad extends Component {
    public shoot(): void {
        const bullet = instantiate(this.bulletPrefab!); // Allocates
        this.scheduleOnce(() => {
            bullet.destroy(); // GC overhead
        }, 2.0);
    }
}

// ✅ CORRECT: Object pooling
@ccclass('NoPoolingGood')
export class NoPoolingGood extends Component {
    private readonly bulletPool: NodePool = new NodePool();

    protected onLoad(): void {
        // Prewarm pool
        for (let i = 0; i < 20; i++) {
            const bullet = instantiate(this.bulletPrefab!);
            this.bulletPool.put(bullet);
        }
    }

    public shoot(): void {
        const bullet = this.bulletPool.get() ?? instantiate(this.bulletPrefab!);
        this.scheduleOnce(() => {
            this.bulletPool.put(bullet);
        }, 2.0);
    }
}

// Severity: 🟡 Important
// Impact: Allocations, GC pauses
// Fix: Implement object pooling for frequent spawn/despawn
```

## Unthrottled Expensive Operations

```typescript
// ❌ IMPORTANT: Expensive operations every frame
@ccclass('UnthrottledBad')
export class UnthrottledBad extends Component {
    protected update(dt: number): void {
        this.recalculatePathfinding(); // A* every frame (60 times/second)!
        this.updateComplexAI();        // Expensive every frame!
    }
}

// ✅ CORRECT: Throttle expensive operations
@ccclass('UnthrottledGood')
export class UnthrottledGood extends Component {
    private frameCount: number = 0;

    protected update(dt: number): void {
        this.frameCount++;

        // Pathfinding once per second
        if (this.frameCount % 60 === 0) {
            this.recalculatePathfinding();
        }

        // AI 6 times per second
        if (this.frameCount % 10 === 0) {
            this.updateComplexAI();
        }

        // Cheap operations every frame
        this.moveTowardsTarget(dt);
    }
}

// Severity: 🟡 Important
// Impact: Poor performance, frame drops
// Fix: Throttle to every N frames (10-60)
```

## Bundle Size >5MB

```typescript
// ❌ CRITICAL: Bundle exceeds playable limit
// Build output: 7.2MB (too large for most ad networks!)

// Common causes:
// 1. Uncompressed textures → Enable compression
// 2. Oversized textures → Reduce to 512x512 max
// 3. Uncompressed audio → Use MP3/OGG at 64-128kbps
// 4. Unused assets → Remove from project
// 5. No code minification → Enable in build settings

// ✅ CORRECT: Optimized to <5MB
// - Enable texture compression (Project Settings)
// - Use sprite atlases (combine textures)
// - Compress audio (64-128kbps)
// - Remove unused assets
// - Enable code minification (drop_console, dead_code)

// Severity: 🔴 Critical
// Impact: Playable rejected by ad networks
// Target: <5MB total bundle
// Fix: Apply size optimization techniques
```

## Loading Resources During Gameplay

```typescript
// ❌ IMPORTANT: Loading during gameplay
@ccclass('LoadingInGameplayBad')
export class LoadingInGameplayBad extends Component {
    protected update(dt: number): void {
        if (this.shouldSpawnEnemy()) {
            // Loading causes frame drop!
            resources.load('sprites/enemy', SpriteFrame, (err, sprite) => {
                this.spawnEnemy(sprite);
            });
        }
    }
}

// ✅ CORRECT: Preload at startup
@ccclass('LoadingInGameplayGood')
export class LoadingInGameplayGood extends Component {
    private enemySprite: SpriteFrame | null = null;

    protected start(): void {
        // Preload once
        resources.load('sprites/enemy', SpriteFrame, (err, sprite) => {
            if (!err) {
                this.enemySprite = sprite;
            }
        });
    }

    protected update(dt: number): void {
        if (this.shouldSpawnEnemy() && this.enemySprite) {
            this.spawnEnemy(this.enemySprite); // Instant, no loading
        }
    }
}

// Severity: 🟡 Important
// Impact: Frame drops during loading
// Fix: Preload all resources at startup
```

## GPU Skinning Disabled

```typescript
// ❌ IMPORTANT: CPU skinning (slower)
@ccclass('CPUSkinningBad')
export class CPUSkinningBad extends Component {
    @property(SkeletalAnimation)
    private skeleton: SkeletalAnimation | null = null;

    protected onLoad(): void {
        // Using default CPU skinning (slower)
    }
}

// ✅ CORRECT: Enable GPU skinning
@ccclass('GPUSkinningGood')
export class GPUSkinningGood extends Component {
    @property(SkeletalAnimation)
    private readonly skeleton: SkeletalAnimation | null = null;

    protected onLoad(): void {
        if (this.skeleton) {
            // GPU handles bone transformations (faster)
            this.skeleton.useBakedAnimation = true;
        }
    }
}

// Severity: 🟢 Nice to Have
// Impact: Better performance for skeletal animations
// Fix: Enable useBakedAnimation for GPU skinning
```

## Summary: Performance Review Checklist

**🔴 Critical (Must Fix):**
- [ ] DrawCall count <10 (use sprite atlases)
- [ ] Zero allocations in update() loop
- [ ] Bundle size <5MB total
- [ ] No loading resources during gameplay

**🟡 Important (Should Fix):**
- [ ] Object pooling for bullets, effects, enemies
- [ ] Expensive operations throttled (every 10-60 frames)
- [ ] Component references cached (not getComponent in update)
- [ ] Node references cached (not find() in update)

**🟢 Nice to Have:**
- [ ] GPU skinning enabled (useBakedAnimation = true)
- [ ] Texture dimensions optimized (512x512 max)
- [ ] Audio compressed (64-128kbps)
- [ ] WeakMap for auto-cleanup caches

**Performance targets: 60fps, <10 DrawCalls, <5MB bundle for playable ads.**
