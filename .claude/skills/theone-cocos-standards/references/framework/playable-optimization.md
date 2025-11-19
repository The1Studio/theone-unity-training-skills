# Playable Ads Performance Optimization

## DrawCall Batching (Critical for Playables)

**Target: <10 DrawCalls for smooth 60fps playables**

```typescript
import { _decorator, Component, Sprite, SpriteAtlas, SpriteFrame } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('SpriteAtlasManager')
export class SpriteAtlasManager extends Component {
    // ✅ EXCELLENT: Use sprite atlas for DrawCall batching
    @property(SpriteAtlas)
    private readonly characterAtlas: SpriteAtlas | null = null;

    @property(SpriteAtlas)
    private readonly uiAtlas: SpriteAtlas | null = null;

    private readonly spriteFrameCache: Map<string, SpriteFrame> = new Map();

    protected onLoad(): void {
        if (!this.characterAtlas || !this.uiAtlas) {
            throw new Error('SpriteAtlasManager: atlases are required');
        }

        // ✅ EXCELLENT: Prewarm sprite frames from atlas
        this.prewarmAtlas(this.characterAtlas, 'character');
        this.prewarmAtlas(this.uiAtlas, 'ui');
    }

    private prewarmAtlas(atlas: SpriteAtlas, prefix: string): void {
        const spriteFrames = atlas.getSpriteFrames();
        for (const frame of spriteFrames) {
            const key = `${prefix}_${frame.name}`;
            this.spriteFrameCache.set(key, frame);
        }
    }

    // ✅ EXCELLENT: Get sprite frame from cache (batched in same DrawCall)
    public getSpriteFrame(atlasName: string, frameName: string): SpriteFrame | null {
        const key = `${atlasName}_${frameName}`;
        return this.spriteFrameCache.get(key) ?? null;
    }
}

// Usage: All sprites from same atlas = single DrawCall
@ccclass('CharacterSprite')
export class CharacterSprite extends Component {
    @property(Sprite)
    private readonly sprite: Sprite | null = null;

    private atlasManager!: SpriteAtlasManager;

    protected start(): void {
        const manager = this.node.parent?.getComponent(SpriteAtlasManager);
        if (!manager) throw new Error('SpriteAtlasManager not found');
        this.atlasManager = manager;

        // ✅ GOOD: Set sprite frame from atlas (batched)
        const frame = this.atlasManager.getSpriteFrame('character', 'idle_01');
        if (frame && this.sprite) {
            this.sprite.spriteFrame = frame;
        }
    }
}

// ❌ WRONG: Individual textures (multiple DrawCalls)
@property(SpriteFrame)
private characterIdleFrame: SpriteFrame | null = null; // DrawCall 1

@property(SpriteFrame)
private characterWalkFrame: SpriteFrame | null = null; // DrawCall 2

@property(SpriteFrame)
private characterJumpFrame: SpriteFrame | null = null; // DrawCall 3
// Result: 3 DrawCalls for 3 sprites!

// ✅ BETTER: Single atlas
@property(SpriteAtlas)
private characterAtlas: SpriteAtlas | null = null; // DrawCall 1 for all frames
```

## GPU Skinning (Skeletal Animations)

```typescript
import { _decorator, Component, SkeletalAnimation } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('AnimationController')
export class AnimationController extends Component {
    @property(SkeletalAnimation)
    private readonly skeleton: SkeletalAnimation | null = null;

    protected onLoad(): void {
        if (!this.skeleton) {
            throw new Error('AnimationController: skeleton is required');
        }

        // ✅ EXCELLENT: Enable GPU skinning for better performance
        // GPU handles bone transformations instead of CPU
        this.skeleton.useBakedAnimation = true; // Baked animation data
    }

    public playAnimation(animName: string, loop: boolean = false): void {
        if (!this.skeleton) return;

        const state = this.skeleton.getState(animName);
        if (state) {
            state.wrapMode = loop ? SkeletalAnimation.WrapMode.Loop : SkeletalAnimation.WrapMode.Normal;
            this.skeleton.play(animName);
        }
    }
}

// ❌ WRONG: CPU skinning (default, slower)
// Don't set useBakedAnimation to false for playables
```

## Object Pooling for Playables

```typescript
import { _decorator, Component, Node, Prefab, instantiate, NodePool } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('PlayableObjectPool')
export class PlayableObjectPool extends Component {
    @property(Prefab)
    private readonly bulletPrefab: Prefab | null = null;

    @property(Prefab)
    private readonly effectPrefab: Prefab | null = null;

    private readonly bulletPool: NodePool = new NodePool();
    private readonly effectPool: NodePool = new NodePool();
    private static readonly PREWARM_COUNT: number = 20;

    // ✅ EXCELLENT: Prewarm pools to avoid allocations during gameplay
    protected onLoad(): void {
        if (!this.bulletPrefab || !this.effectPrefab) {
            throw new Error('PlayableObjectPool: prefabs are required');
        }

        // Prewarm bullet pool
        for (let i = 0; i < PlayableObjectPool.PREWARM_COUNT; i++) {
            const bullet = instantiate(this.bulletPrefab);
            this.bulletPool.put(bullet);
        }

        // Prewarm effect pool
        for (let i = 0; i < PlayableObjectPool.PREWARM_COUNT; i++) {
            const effect = instantiate(this.effectPrefab);
            this.effectPool.put(effect);
        }
    }

    // ✅ EXCELLENT: Get from pool (zero allocations in gameplay)
    public getBullet(): Node {
        if (this.bulletPool.size() > 0) {
            const bullet = this.bulletPool.get()!;
            bullet.active = true;
            return bullet;
        }

        // Fallback: create new (should be rare if prewarmed correctly)
        if (!this.bulletPrefab) {
            throw new Error('bulletPrefab is null');
        }
        return instantiate(this.bulletPrefab);
    }

    public returnBullet(bullet: Node): void {
        bullet.active = false;
        this.bulletPool.put(bullet);
    }

    protected onDestroy(): void {
        this.bulletPool.clear();
        this.effectPool.clear();
    }
}

// ❌ WRONG: Creating/destroying objects during gameplay
public shoot(): void {
    const bullet = instantiate(this.bulletPrefab!); // Allocates every time
    this.scheduleOnce(() => {
        bullet.destroy(); // Triggers GC
    }, 2.0);
}
```

## Update Loop Optimization for Playables

```typescript
import { _decorator, Component, Node, Vec3 } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('OptimizedUpdate')
export class OptimizedUpdate extends Component {
    @property([Node])
    private readonly enemies: Node[] = [];

    // ✅ EXCELLENT: Preallocate to avoid allocations in update
    private readonly tempVec3: Vec3 = new Vec3();
    private readonly activeEnemies: Node[] = [];
    private activeEnemiesDirty: boolean = true;
    private frameCount: number = 0;

    // ✅ EXCELLENT: Update expensive operations every N frames
    protected update(dt: number): void {
        this.frameCount++;

        // Cheap operations: every frame
        this.updateMovement(dt);

        // Expensive operations: every 10 frames (6 times/second at 60fps)
        if (this.frameCount % 10 === 0) {
            this.updateAI();
        }

        // Very expensive: every 60 frames (once per second at 60fps)
        if (this.frameCount % 60 === 0) {
            this.updatePathfinding();
        }
    }

    private updateMovement(dt: number): void {
        // Use cached active enemies list
        const activeEnemies = this.getActiveEnemies();

        for (const enemy of activeEnemies) {
            // Reuse preallocated vector
            enemy.getPosition(this.tempVec3);
            this.tempVec3.y += 10 * dt;
            enemy.setPosition(this.tempVec3);
        }
    }

    private getActiveEnemies(): Node[] {
        if (this.activeEnemiesDirty) {
            this.activeEnemies.length = 0;
            for (const enemy of this.enemies) {
                if (enemy.active) {
                    this.activeEnemies.push(enemy);
                }
            }
            this.activeEnemiesDirty = false;
        }
        return this.activeEnemies;
    }

    private updateAI(): void {
        // Expensive AI logic
    }

    private updatePathfinding(): void {
        // Very expensive pathfinding
    }
}

// ❌ WRONG: All logic in update, allocations everywhere
protected update(dt: number): void {
    // Allocates array every frame
    const activeEnemies = this.enemies.filter(e => e.active);

    for (const enemy of activeEnemies) {
        // Allocates vector every frame
        const pos = enemy.position.clone();
        pos.y += 10 * dt;
        enemy.setPosition(pos);
    }

    // Expensive operations every frame
    this.updatePathfinding(); // 60 times/second!
    this.updateAI(); // 60 times/second!
}
```

## Resource Loading and Preloading

```typescript
import { _decorator, Component, resources, SpriteFrame, AudioClip } from 'cc';
const { ccclass } = _decorator;

@ccclass('ResourcePreloader')
export class ResourcePreloader extends Component {
    private readonly loadedResources: Map<string, Asset> = new Map();

    // ✅ EXCELLENT: Preload all resources at game start
    protected async start(): Promise<void> {
        await this.preloadAllResources();
    }

    private async preloadAllResources(): Promise<void> {
        const resourcePaths = [
            'sprites/character',
            'sprites/enemies',
            'audio/bgm',
            'audio/sfx',
        ];

        const promises = resourcePaths.map(path => this.preloadResource(path));
        await Promise.all(promises);

        console.log('All resources preloaded');
    }

    private async preloadResource(path: string): Promise<void> {
        return new Promise((resolve, reject) => {
            resources.load(path, (err, asset) => {
                if (err) {
                    console.error(`Failed to load ${path}:`, err);
                    reject(err);
                    return;
                }

                this.loadedResources.set(path, asset);
                resolve();
            });
        });
    }

    public getResource<T extends Asset>(path: string): T | null {
        return (this.loadedResources.get(path) as T) ?? null;
    }

    protected onDestroy(): void {
        // ✅ EXCELLENT: Release all loaded resources
        for (const [path, asset] of this.loadedResources) {
            asset.decRef();
        }
        this.loadedResources.clear();
    }
}

// ❌ WRONG: Loading resources during gameplay
protected update(dt: number): void {
    if (this.shouldSpawnEnemy()) {
        // Loading during gameplay causes frame drops!
        resources.load('sprites/enemy', SpriteFrame, (err, sprite) => {
            this.spawnEnemy(sprite);
        });
    }
}

// ✅ BETTER: Preload and reuse
protected start(): void {
    resources.load('sprites/enemy', SpriteFrame, (err, sprite) => {
        this.enemySprite = sprite;
    });
}

protected update(dt: number): void {
    if (this.shouldSpawnEnemy() && this.enemySprite) {
        this.spawnEnemy(this.enemySprite); // Instant, no loading
    }
}
```

## Memory Management for Playables

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass } = _decorator;

@ccclass('MemoryOptimized')
export class MemoryOptimized extends Component {
    // ✅ EXCELLENT: Use typed arrays for large datasets
    private positions: Float32Array = new Float32Array(300); // 100 Vec3s
    private velocities: Float32Array = new Float32Array(300);

    // ✅ EXCELLENT: Reuse arrays instead of creating new ones
    private readonly tempArray: number[] = [];

    protected update(dt: number): void {
        // Reuse array, don't allocate
        this.tempArray.length = 0;

        for (let i = 0; i < 100; i++) {
            this.tempArray.push(i * dt);
        }
    }

    // ✅ EXCELLENT: WeakMap for caches (automatic cleanup)
    private readonly nodeCache: WeakMap<Node, CachedData> = new WeakMap();

    public getCachedData(node: Node): CachedData | undefined {
        return this.nodeCache.get(node);
    }

    protected onDestroy(): void {
        // ✅ EXCELLENT: Clear references
        this.tempArray.length = 0;
        // WeakMap entries are auto-cleared when nodes are destroyed
    }
}
```

## Summary: Playable Optimization Checklist

**DrawCall Batching (<10 target):**
- [ ] Use sprite atlases for all sprites (not individual textures)
- [ ] Prewarm sprite frame cache in onLoad()
- [ ] Group UI elements into single atlas
- [ ] Use same material for similar objects

**Animation Performance:**
- [ ] Enable GPU skinning (useBakedAnimation = true)
- [ ] Bake skeletal animations
- [ ] Limit simultaneous animations

**Object Pooling:**
- [ ] Pool bullets, effects, enemies (anything spawned frequently)
- [ ] Prewarm pools in onLoad() (at least 20 objects)
- [ ] Never instantiate/destroy during gameplay

**Update Loop:**
- [ ] Zero allocations in update()
- [ ] Throttle expensive operations (every 10-60 frames)
- [ ] Cache active object lists
- [ ] Reuse preallocated vectors/arrays

**Resource Management:**
- [ ] Preload all resources at game start
- [ ] Never load resources during gameplay
- [ ] Release resources in onDestroy()
- [ ] Use WeakMap for auto-cleanup caches

**Target: 60fps with <10 DrawCalls and <5MB bundle size for playable ads.**
