# TypeScript Quality & Code Hygiene

## Enable TypeScript Strict Mode

```typescript
// ✅ GOOD: Enable strict mode in tsconfig.json
{
    "compilerOptions": {
        "strict": true,
        "noImplicitAny": true,
        "strictNullChecks": true,
        "strictFunctionTypes": true,
        "strictBindCallApply": true,
        "strictPropertyInitialization": true,
        "noImplicitThis": true,
        "alwaysStrict": true
    }
}

// Declare nullable explicitly
public playerName: string | null = null; // Can be null
public requiredName: string = ''; // Never null

// ❌ BAD: Ignoring nullability
public playerName: string; // Uninitialized, can be undefined
```

## Use Access Modifiers (public/private/protected)

```typescript
// ✅ GOOD: Explicit access modifiers
import { _decorator, Component, Node } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('GameService')
export class GameService extends Component {
    // Private implementation details
    private readonly playerNodes: Node[] = [];
    private currentLevel: number = 1;

    // Protected for subclass access
    protected readonly maxHealth: number = 100;

    // Public API only when necessary
    public getCurrentLevel(): number {
        return this.currentLevel;
    }

    // Private helper methods
    private loadGameData(): void {
        // Implementation
    }
}

// ❌ BAD: No access modifiers (implicitly public)
@ccclass('GameService')
export class GameService extends Component {
    playerNodes: Node[] = []; // Implicitly public
    currentLevel: number = 1; // Implicitly public
}
```

## Enable ESLint with TypeScript Support

```json
// ✅ GOOD: .eslintrc.json configuration
{
    "parser": "@typescript-eslint/parser",
    "extends": [
        "eslint:recommended",
        "plugin:@typescript-eslint/recommended"
    ],
    "plugins": ["@typescript-eslint"],
    "rules": {
        "@typescript-eslint/explicit-function-return-type": "error",
        "@typescript-eslint/no-explicit-any": "error",
        "@typescript-eslint/no-unused-vars": "error",
        "@typescript-eslint/explicit-member-accessibility": "error"
    }
}
```

## Throw Exceptions for Errors

**Critical Rule**: Throw exceptions instead of silent failures or returning undefined.

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('PlayerService')
export class PlayerService extends Component {
    @property(Node)
    private readonly playerNode: Node | null = null;

    // ✅ EXCELLENT: Throw exception for errors
    protected onLoad(): void {
        if (!this.playerNode) {
            throw new Error('PlayerService: playerNode is required');
        }
    }

    public getPlayer(id: string): Player {
        const player = this.players.get(id);
        if (!player) {
            // Throw exception, don't return undefined
            throw new Error(`Player not found: ${id}`);
        }
        return player;
    }

    public loadLevel(levelId: number): void {
        if (levelId < 1 || levelId > 100) {
            throw new RangeError(`Invalid level ID: ${levelId}. Must be 1-100.`);
        }

        const levelData = this.loadLevelData(levelId);
        if (!levelData) {
            throw new Error(`Failed to load level data for level ${levelId}`);
        }

        this.initializeLevel(levelData);
    }
}

// ❌ WRONG: Silent failure
public getPlayer(id: string): Player | undefined {
    const player = this.players.get(id);
    // Returning undefined - caller doesn't know why it failed
    return player;
}

// ❌ WRONG: Logging error instead of throwing
public loadLevel(levelId: number): void {
    if (levelId < 1) {
        console.error('Invalid level ID'); // Don't just log
        return; // Silent failure
    }
}
```

## Logging: console.log for Development Only

**Logging Guidelines:**
- **console.log**: Use ONLY for development debugging
- **Remove in production**: Wrap in `CC_DEBUG` or remove entirely
- **Performance impact**: console.log can slow down playable ads
- **Bundle size**: Logging strings increase bundle size

```typescript
import { _decorator, Component } from 'cc';
const { ccclass } = _decorator;

@ccclass('GameManager')
export class GameManager extends Component {
    private currentScore: number = 0;

    // ✅ EXCELLENT: Conditional logging for development
    protected onLoad(): void {
        if (CC_DEBUG) {
            console.log('GameManager initialized');
        }
    }

    public addScore(points: number): void {
        this.currentScore += points;

        // ✅ GOOD: Development-only debug logging
        if (CC_DEBUG) {
            console.log(`Score updated: ${this.currentScore}`);
        }
    }

    private loadGameData(): void {
        try {
            const data = this.fetchData();
            this.processData(data);
        } catch (error) {
            // ✅ GOOD: Log errors in development
            if (CC_DEBUG) {
                console.error('Failed to load game data:', error);
            }
            // Always throw for caller to handle
            throw error;
        }
    }
}

// ❌ WRONG: Unconditional console.log in production
public addScore(points: number): void {
    console.log(`Adding ${points} points`); // Will be in production build
    this.currentScore += points;
}

// ❌ WRONG: Verbose logging everywhere
public update(dt: number): void {
    console.log('Update called'); // Called every frame!
    console.log(`Delta time: ${dt}`); // Performance impact
}

// ✅ BETTER: Remove logs in production or use build-time removal
// Configure build process to strip console.log in production builds
```

**Production Build Configuration:**

```javascript
// Build configuration to remove console.log in production
// rollup.config.js or webpack.config.js
export default {
    plugins: [
        // Remove console statements in production
        terser({
            compress: {
                drop_console: true, // Remove all console.* calls
                pure_funcs: ['console.log', 'console.debug'], // Remove specific calls
            }
        })
    ]
};
```

## Use readonly for Immutable Fields

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('PlayerController')
export class PlayerController extends Component {
    // ✅ GOOD: readonly for @property fields that aren't reassigned
    @property(Node)
    private readonly targetNode: Node | null = null;

    @property(Number)
    private readonly moveSpeed: number = 100;

    // ✅ GOOD: readonly for injected dependencies
    private readonly eventManager: EventManager;

    // Regular mutable field
    private currentHealth: number = 100;

    constructor(eventManager: EventManager) {
        super();
        this.eventManager = eventManager;
    }

    // ❌ WRONG: Can't reassign readonly field
    public setTarget(node: Node): void {
        // this.targetNode = node; // Error: Cannot assign to 'targetNode' because it is a read-only property
    }
}

// ❌ BAD: Mutable when shouldn't be
@ccclass('GameConfig')
export class GameConfig extends Component {
    @property(Number)
    private maxHealth: number = 100; // Should be readonly
}
```

## Use const for Constants

```typescript
// ✅ GOOD: const for constants
const MAX_PLAYERS = 4;
const DEFAULT_PLAYER_NAME = 'Player';
const GAME_VERSION = '1.0.0';

// ✅ GOOD: Static readonly for class constants
@ccclass('GameRules')
export class GameRules extends Component {
    private static readonly MAX_HEALTH: number = 100;
    private static readonly MIN_LEVEL: number = 1;
    private static readonly MAX_LEVEL: number = 50;

    public static isValidLevel(level: number): boolean {
        return level >= GameRules.MIN_LEVEL && level <= GameRules.MAX_LEVEL;
    }
}

// ✅ GOOD: Enum for related constants
export enum GameState {
    LOADING = 'loading',
    PLAYING = 'playing',
    PAUSED = 'paused',
    GAME_OVER = 'game_over',
}

// ❌ BAD: let for constants
let maxPlayers = 4; // Should be const
let defaultPlayerName = 'Player'; // Should be const

// ❌ BAD: Magic numbers without constants
public checkHealth(): boolean {
    return this.health > 0 && this.health <= 100; // What is 100?
}

// ✅ BETTER: Named constant
private static readonly MAX_HEALTH: number = 100;

public checkHealth(): boolean {
    return this.health > 0 && this.health <= GameRules.MAX_HEALTH;
}
```

## No Inline Comments (Use Descriptive Names)

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass, property } = _decorator;

// ✅ EXCELLENT: Self-explanatory code, no inline comments
@ccclass('PlayerController')
export class PlayerController extends Component {
    @property(Node)
    private readonly healthBarNode: Node | null = null;

    private currentHealth: number = 100;
    private static readonly MAX_HEALTH: number = 100;
    private static readonly CRITICAL_HEALTH_THRESHOLD: number = 20;

    public takeDamage(amount: number): void {
        this.currentHealth = Math.max(0, this.currentHealth - amount);
        this.updateHealthBar();

        if (this.isHealthCritical()) {
            this.triggerLowHealthWarning();
        }

        if (this.isDead()) {
            this.handlePlayerDeath();
        }
    }

    private isHealthCritical(): boolean {
        return this.currentHealth <= PlayerController.CRITICAL_HEALTH_THRESHOLD;
    }

    private isDead(): boolean {
        return this.currentHealth === 0;
    }

    private triggerLowHealthWarning(): void {
        // Implementation
    }

    private handlePlayerDeath(): void {
        // Implementation
    }

    private updateHealthBar(): void {
        if (!this.healthBarNode) return;

        const healthPercentage = this.currentHealth / PlayerController.MAX_HEALTH;
        this.healthBarNode.scale = new Vec3(healthPercentage, 1, 1);
    }
}

// ❌ BAD: Inline comments explaining unclear code
@ccclass('PlayerController')
export class PlayerController extends Component {
    private h: number = 100; // health

    public td(a: number): void { // take damage
        this.h = Math.max(0, this.h - a); // subtract damage but don't go below 0
        this.uh(); // update health bar

        if (this.h <= 20) { // if health is critical
            this.tlhw(); // trigger low health warning
        }

        if (this.h === 0) { // if dead
            this.hpd(); // handle player death
        }
    }
}

// ❌ BAD: Comments explaining what code does (should be obvious)
public addScore(points: number): void {
    // Add points to current score
    this.currentScore += points;

    // Check if score exceeds maximum
    if (this.currentScore > MAX_SCORE) {
        // Set score to maximum
        this.currentScore = MAX_SCORE;
    }
}

// ✅ BETTER: Descriptive names make comments unnecessary
public addScore(points: number): void {
    this.currentScore += points;
    this.clampScoreToMaximum();
}

private clampScoreToMaximum(): void {
    this.currentScore = Math.min(this.currentScore, MAX_SCORE);
}
```

**When Comments ARE Appropriate:**

```typescript
// ✅ GOOD: Documenting WHY, not WHAT
/**
 * Calculates damage using quadratic formula to create smooth damage curve.
 * Linear damage felt too harsh for new players during playtesting.
 */
private calculateDamage(baseAmount: number, level: number): number {
    return baseAmount * Math.pow(level, 0.8);
}

// ✅ GOOD: Documenting complex algorithms
/**
 * A* pathfinding algorithm implementation.
 * Uses Manhattan distance heuristic for grid-based movement.
 * @see https://en.wikipedia.org/wiki/A*_search_algorithm
 */
private findPath(start: Vec2, end: Vec2): Vec2[] {
    // Implementation
}

// ✅ GOOD: Documenting workarounds
/**
 * WORKAROUND: Cocos Creator 3.8.x has a bug where sprite atlas
 * frames aren't properly loaded on first access. Accessing once
 * in onLoad() ensures they're cached for later use.
 * @see https://github.com/cocos/cocos-engine/issues/12345
 */
protected onLoad(): void {
    this.atlas?.getSpriteFrame('dummy');
}
```

## Proper Null/Undefined Handling

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass, property } = _decorator;

@ccclass('PlayerManager')
export class PlayerManager extends Component {
    @property(Node)
    private readonly playerNode: Node | null = null;

    // ✅ EXCELLENT: Explicit validation and error handling
    protected onLoad(): void {
        if (!this.playerNode) {
            throw new Error('PlayerManager: playerNode is required');
        }
    }

    // ✅ GOOD: Optional chaining for safe access
    public getPlayerName(): string {
        return this.playerNode?.name ?? 'Unknown';
    }

    // ✅ GOOD: Nullish coalescing for default values
    public getPlayerHealth(): number {
        return this.playerNode?.getComponent(PlayerController)?.health ?? 0;
    }

    // ✅ GOOD: Type guard for type safety
    private isValidPlayer(node: Node | null): node is Node {
        return node !== null && node.getComponent(PlayerController) !== null;
    }

    public updatePlayer(): void {
        if (this.isValidPlayer(this.playerNode)) {
            // TypeScript knows playerNode is Node (not null)
            const controller = this.playerNode.getComponent(PlayerController)!;
            controller.update();
        }
    }
}

// ❌ BAD: No null checks
public updatePlayer(): void {
    this.playerNode.position = new Vec3(0, 0, 0); // Can crash if null
}

// ❌ BAD: Unsafe type assertions
public getController(): PlayerController {
    return this.playerNode!.getComponent(PlayerController)!; // Unsafe!
}
```

## Avoid `any` Type

```typescript
// ✅ GOOD: Proper types and interfaces
interface PlayerData {
    id: string;
    name: string;
    level: number;
    health: number;
}

@ccclass('PlayerService')
export class PlayerService extends Component {
    private readonly players: Map<string, PlayerData> = new Map();

    public addPlayer(data: PlayerData): void {
        this.players.set(data.id, data);
    }

    public getPlayer(id: string): PlayerData | undefined {
        return this.players.get(id);
    }
}

// ❌ BAD: Using any type
@ccclass('PlayerService')
export class PlayerService extends Component {
    private players: any = {}; // Type safety lost

    public addPlayer(data: any): void { // No type checking
        this.players[data.id] = data;
    }

    public getPlayer(id: string): any { // Caller doesn't know structure
        return this.players[id];
    }
}

// ✅ GOOD: Use generics instead of any
class DataStore<T> {
    private data: Map<string, T> = new Map();

    public set(key: string, value: T): void {
        this.data.set(key, value);
    }

    public get(key: string): T | undefined {
        return this.data.get(key);
    }
}

// ✅ GOOD: Use unknown for truly unknown types (safer than any)
function parseJSON(json: string): unknown {
    return JSON.parse(json);
}

// Then validate and narrow the type
const result = parseJSON('{"name": "Player"}');
if (isPlayerData(result)) {
    // result is now typed as PlayerData
    console.log(result.name);
}

function isPlayerData(obj: unknown): obj is PlayerData {
    return (
        typeof obj === 'object' &&
        obj !== null &&
        'id' in obj &&
        'name' in obj &&
        'level' in obj &&
        'health' in obj
    );
}
```

## Summary: Quality Checklist

**Before committing code, verify:**

- [ ] TypeScript strict mode enabled in tsconfig.json
- [ ] ESLint configuration active and passing
- [ ] All class members have access modifiers (public/private/protected)
- [ ] Exceptions thrown for errors (no silent failures)
- [ ] console.log removed or wrapped in CC_DEBUG
- [ ] readonly used for non-reassigned fields
- [ ] const used for constants (not let)
- [ ] No inline comments (code is self-explanatory)
- [ ] Optional chaining (?.) for safe property access
- [ ] Nullish coalescing (??) for default values
- [ ] No `any` types without justification
- [ ] Required references validated in onLoad()

**Quality is the foundation of all other patterns. Get this right first.**
