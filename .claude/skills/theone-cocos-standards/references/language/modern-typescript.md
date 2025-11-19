# Modern TypeScript Patterns

## Array Methods Over Loops

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass } = _decorator;

interface Enemy {
    node: Node;
    isActive: boolean;
    health: number;
    damage: number;
}

@ccclass('EnemyManager')
export class EnemyManager extends Component {
    private readonly enemies: Enemy[] = [];

    // ✅ EXCELLENT: Array methods for filtering
    public getActiveEnemies(): Enemy[] {
        return this.enemies.filter(enemy => enemy.isActive);
    }

    // ✅ EXCELLENT: Array methods for mapping
    public getEnemyPositions(): Vec3[] {
        return this.enemies.map(enemy => enemy.node.position.clone());
    }

    // ✅ EXCELLENT: Array methods for reduction
    public getTotalDamage(): number {
        return this.enemies.reduce((total, enemy) => total + enemy.damage, 0);
    }

    // ✅ EXCELLENT: Chaining array methods
    public getActiveEnemyDamage(): number {
        return this.enemies
            .filter(enemy => enemy.isActive)
            .reduce((total, enemy) => total + enemy.damage, 0);
    }

    // ✅ EXCELLENT: find instead of manual loop
    public findEnemyById(id: string): Enemy | undefined {
        return this.enemies.find(enemy => enemy.node.uuid === id);
    }

    // ✅ EXCELLENT: some/every for existence checks
    public hasActiveEnemies(): boolean {
        return this.enemies.some(enemy => enemy.isActive);
    }

    public areAllEnemiesDead(): boolean {
        return this.enemies.every(enemy => enemy.health <= 0);
    }
}

// ❌ BAD: Manual loops
public getActiveEnemies(): Enemy[] {
    const active: Enemy[] = [];
    for (let i = 0; i < this.enemies.length; i++) {
        if (this.enemies[i].isActive) {
            active.push(this.enemies[i]);
        }
    }
    return active;
}

// ❌ BAD: Manual accumulation
public getTotalDamage(): number {
    let total = 0;
    for (const enemy of this.enemies) {
        total += enemy.damage;
    }
    return total;
}
```

## Arrow Functions and Callbacks

```typescript
import { _decorator, Component, Node, EventTouch } from 'cc';
const { ccclass } = _decorator;

@ccclass('InputHandler')
export class InputHandler extends Component {
    private readonly buttons: Node[] = [];

    // ✅ EXCELLENT: Arrow functions for callbacks
    protected onEnable(): void {
        this.buttons.forEach(button => {
            button.on(Node.EventType.TOUCH_START, this.onButtonClick, this);
        });
    }

    protected onDisable(): void {
        this.buttons.forEach(button => {
            button.off(Node.EventType.TOUCH_START, this.onButtonClick, this);
        });
    }

    // ✅ GOOD: Arrow function preserves this context
    private readonly onButtonClick = (event: EventTouch): void => {
        const button = event.target as Node;
        this.handleButtonClick(button);
    };

    // ✅ GOOD: Arrow function for event handling
    private setupAsyncOperation(): void {
        setTimeout(() => {
            this.processData();
        }, 1000);
    }

    // ✅ GOOD: Arrow function in Promise chains
    private async loadData(): Promise<void> {
        fetch('data.json')
            .then(response => response.json())
            .then(data => this.processData(data))
            .catch(error => this.handleError(error));
    }
}

// ❌ BAD: Function expression loses this context
protected onEnable(): void {
    this.buttons.forEach(function(button) {
        // 'this' is undefined or wrong context
        button.on(Node.EventType.TOUCH_START, this.onButtonClick, this);
    });
}

// ❌ BAD: Verbose function syntax
private setupAsyncOperation(): void {
    const self = this;
    setTimeout(function() {
        self.processData();
    }, 1000);
}
```

## Destructuring

```typescript
import { _decorator, Component, Node, Vec3 } from 'cc';
const { ccclass, property } = _decorator;

interface PlayerData {
    id: string;
    name: string;
    level: number;
    health: number;
    position: { x: number; y: number; z: number };
}

@ccclass('PlayerController')
export class PlayerController extends Component {
    // ✅ EXCELLENT: Destructuring in parameters
    public updatePlayer({ id, name, level, health, position }: PlayerData): void {
        console.log(`Updating ${name} (${id}) at level ${level}`);

        // ✅ EXCELLENT: Nested destructuring
        const { x, y, z } = position;
        this.node.setPosition(x, y, z);
    }

    // ✅ EXCELLENT: Destructuring with defaults
    public loadConfig({ speed = 100, jumpHeight = 50, maxHealth = 100 } = {}): void {
        this.speed = speed;
        this.jumpHeight = jumpHeight;
        this.maxHealth = maxHealth;
    }

    // ✅ EXCELLENT: Array destructuring
    public getPlayerPosition(): Vec3 {
        const [x, y, z] = [this.node.position.x, this.node.position.y, this.node.position.z];
        return new Vec3(x, y, z);
    }

    // ✅ EXCELLENT: Rest operator with destructuring
    public handleInput({ type, ...eventData }: InputEvent): void {
        switch (type) {
            case 'touch':
                this.handleTouch(eventData);
                break;
            case 'key':
                this.handleKey(eventData);
                break;
        }
    }
}

// ❌ BAD: No destructuring
public updatePlayer(playerData: PlayerData): void {
    console.log(`Updating ${playerData.name} (${playerData.id}) at level ${playerData.level}`);
    this.node.setPosition(playerData.position.x, playerData.position.y, playerData.position.z);
}

// ❌ BAD: Verbose property access
public loadConfig(config: Config): void {
    this.speed = config.speed !== undefined ? config.speed : 100;
    this.jumpHeight = config.jumpHeight !== undefined ? config.jumpHeight : 50;
    this.maxHealth = config.maxHealth !== undefined ? config.maxHealth : 100;
}
```

## Spread Operator

```typescript
import { _decorator, Component } from 'cc';
const { ccclass } = _decorator;

interface GameConfig {
    playerName: string;
    difficulty: string;
    soundEnabled: boolean;
}

@ccclass('GameManager')
export class GameManager extends Component {
    private readonly defaultConfig: GameConfig = {
        playerName: 'Player',
        difficulty: 'normal',
        soundEnabled: true,
    };

    // ✅ EXCELLENT: Spread for object merging
    public createConfig(overrides: Partial<GameConfig>): GameConfig {
        return { ...this.defaultConfig, ...overrides };
    }

    // ✅ EXCELLENT: Spread for array concatenation
    private readonly baseEnemies: string[] = ['goblin', 'orc'];
    private readonly bossEnemies: string[] = ['dragon', 'demon'];

    public getAllEnemies(): string[] {
        return [...this.baseEnemies, ...this.bossEnemies];
    }

    // ✅ EXCELLENT: Spread for array cloning
    public cloneEnemyList(): string[] {
        return [...this.baseEnemies];
    }

    // ✅ EXCELLENT: Spread in function calls
    public calculateMaxValue(...values: number[]): number {
        return Math.max(...values);
    }

    // ✅ EXCELLENT: Spread for immutable updates
    public addEnemy(enemy: string): void {
        this.baseEnemies = [...this.baseEnemies, enemy];
    }
}

// ❌ BAD: Manual merging
public createConfig(overrides: Partial<GameConfig>): GameConfig {
    const config: GameConfig = {
        playerName: overrides.playerName ?? this.defaultConfig.playerName,
        difficulty: overrides.difficulty ?? this.defaultConfig.difficulty,
        soundEnabled: overrides.soundEnabled ?? this.defaultConfig.soundEnabled,
    };
    return config;
}

// ❌ BAD: Manual concatenation
public getAllEnemies(): string[] {
    const enemies: string[] = [];
    for (const enemy of this.baseEnemies) {
        enemies.push(enemy);
    }
    for (const enemy of this.bossEnemies) {
        enemies.push(enemy);
    }
    return enemies;
}
```

## Optional Chaining (?.)

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass, property } = _decorator;

interface Player {
    name: string;
    stats?: {
        health?: number;
        level?: number;
    };
    inventory?: {
        items?: Item[];
    };
}

@ccclass('PlayerManager')
export class PlayerManager extends Component {
    @property(Node)
    private readonly playerNode: Node | null = null;

    // ✅ EXCELLENT: Optional chaining for safe access
    public getPlayerName(): string | undefined {
        return this.playerNode?.name;
    }

    // ✅ EXCELLENT: Deep optional chaining
    public getPlayerHealth(player: Player): number | undefined {
        return player?.stats?.health;
    }

    // ✅ EXCELLENT: Optional chaining with arrays
    public getFirstItem(player: Player): Item | undefined {
        return player?.inventory?.items?.[0];
    }

    // ✅ EXCELLENT: Optional chaining with methods
    public getComponentName(): string | undefined {
        return this.playerNode?.getComponent(PlayerController)?.getName?.();
    }

    // ✅ EXCELLENT: Combining with nullish coalescing
    public getDisplayName(): string {
        return this.playerNode?.name ?? 'Unknown Player';
    }
}

// ❌ BAD: Manual null checking
public getPlayerName(): string | undefined {
    if (this.playerNode !== null && this.playerNode !== undefined) {
        return this.playerNode.name;
    }
    return undefined;
}

// ❌ BAD: Nested null checks
public getPlayerHealth(player: Player): number | undefined {
    if (player) {
        if (player.stats) {
            if (player.stats.health !== undefined) {
                return player.stats.health;
            }
        }
    }
    return undefined;
}
```

## Nullish Coalescing (??)

```typescript
import { _decorator, Component } from 'cc';
const { ccclass } = _decorator;

interface GameConfig {
    playerName?: string;
    maxHealth?: number;
    soundVolume?: number;
    enableTutorial?: boolean;
}

@ccclass('ConfigManager')
export class ConfigManager extends Component {
    // ✅ EXCELLENT: Nullish coalescing for defaults
    public loadConfig(config: GameConfig): void {
        const playerName = config.playerName ?? 'Player';
        const maxHealth = config.maxHealth ?? 100;
        const soundVolume = config.soundVolume ?? 0.5;
        const enableTutorial = config.enableTutorial ?? true;

        console.log({ playerName, maxHealth, soundVolume, enableTutorial });
    }

    // ✅ EXCELLENT: Nullish coalescing preserves falsy values
    public getVolume(volume?: number): number {
        // Returns 0 if volume is 0 (not using || which would return 1)
        return volume ?? 1;
    }

    // ✅ EXCELLENT: Chaining nullish coalescing
    public getPlayerName(primaryName?: string, secondaryName?: string): string {
        return primaryName ?? secondaryName ?? 'Unknown';
    }

    // ✅ EXCELLENT: Nullish coalescing with optional chaining
    public getHealthDisplay(player?: Player): string {
        const health = player?.stats?.health ?? 0;
        return `Health: ${health}`;
    }
}

// ❌ BAD: Using || operator (treats 0, '', false as null)
public getVolume(volume?: number): number {
    return volume || 1; // Returns 1 even if volume is 0
}

// ❌ BAD: Manual null/undefined checks
public loadConfig(config: GameConfig): void {
    const playerName = config.playerName !== null && config.playerName !== undefined
        ? config.playerName
        : 'Player';
}

// ❌ BAD: Verbose ternary
public getPlayerName(name?: string): string {
    return name !== undefined && name !== null ? name : 'Unknown';
}
```

## Type Guards

```typescript
import { _decorator, Component, Node } from 'cc';
const { ccclass } = _decorator;

// ✅ EXCELLENT: Type guard for interface
interface Player {
    type: 'player';
    health: number;
    level: number;
}

interface Enemy {
    type: 'enemy';
    health: number;
    damage: number;
}

type Entity = Player | Enemy;

function isPlayer(entity: Entity): entity is Player {
    return entity.type === 'player';
}

function isEnemy(entity: Entity): entity is Enemy {
    return entity.type === 'enemy';
}

@ccclass('CombatManager')
export class CombatManager extends Component {
    public handleEntity(entity: Entity): void {
        if (isPlayer(entity)) {
            // TypeScript knows entity is Player
            console.log(`Player level: ${entity.level}`);
        } else if (isEnemy(entity)) {
            // TypeScript knows entity is Enemy
            console.log(`Enemy damage: ${entity.damage}`);
        }
    }

    // ✅ EXCELLENT: Type guard for null/undefined
    private isValidNode(node: Node | null | undefined): node is Node {
        return node !== null && node !== undefined;
    }

    public processNode(node: Node | null): void {
        if (this.isValidNode(node)) {
            // TypeScript knows node is Node (not null)
            node.setPosition(0, 0, 0);
        }
    }

    // ✅ EXCELLENT: Type guard for component
    private hasPlayerController(node: Node): node is Node & { getComponent(PlayerController): PlayerController } {
        return node.getComponent(PlayerController) !== null;
    }

    public updatePlayer(node: Node): void {
        if (this.hasPlayerController(node)) {
            // TypeScript knows component exists
            const controller = node.getComponent(PlayerController)!;
            controller.update();
        }
    }
}

// ❌ BAD: No type guards, type assertions everywhere
public handleEntity(entity: Entity): void {
    if (entity.type === 'player') {
        console.log(`Player level: ${(entity as Player).level}`); // Type assertion
    } else {
        console.log(`Enemy damage: ${(entity as Enemy).damage}`); // Type assertion
    }
}
```

## Utility Types

```typescript
import { _decorator, Component } from 'cc';
const { ccclass } = _decorator;

interface GameConfig {
    playerName: string;
    maxHealth: number;
    difficulty: string;
    soundEnabled: boolean;
}

@ccclass('ConfigManager')
export class ConfigManager extends Component {
    // ✅ EXCELLENT: Partial for optional properties
    public updateConfig(updates: Partial<GameConfig>): void {
        // All properties are optional
    }

    // ✅ EXCELLENT: Required for mandatory properties
    public validateConfig(config: Required<GameConfig>): void {
        // All properties are required
    }

    // ✅ EXCELLENT: Readonly for immutable objects
    private readonly defaultConfig: Readonly<GameConfig> = {
        playerName: 'Player',
        maxHealth: 100,
        difficulty: 'normal',
        soundEnabled: true,
    };

    // ✅ EXCELLENT: Pick for selecting properties
    public getDisplayInfo(config: GameConfig): Pick<GameConfig, 'playerName' | 'difficulty'> {
        return {
            playerName: config.playerName,
            difficulty: config.difficulty,
        };
    }

    // ✅ EXCELLENT: Omit for excluding properties
    public getPublicConfig(config: GameConfig): Omit<GameConfig, 'soundEnabled'> {
        const { soundEnabled, ...publicConfig } = config;
        return publicConfig;
    }

    // ✅ EXCELLENT: Record for key-value mappings
    private readonly difficultyMultipliers: Record<string, number> = {
        easy: 0.5,
        normal: 1.0,
        hard: 1.5,
        expert: 2.0,
    };

    // ✅ EXCELLENT: ReturnType for function return types
    private createPlayer(): { name: string; level: number } {
        return { name: 'Player', level: 1 };
    }

    type PlayerType = ReturnType<typeof this.createPlayer>;
}
```

## Async/Await Patterns

```typescript
import { _decorator, Component } from 'cc';
const { ccclass } = _decorator;

@ccclass('DataManager')
export class DataManager extends Component {
    // ✅ EXCELLENT: Async/await for sequential operations
    public async loadGameData(): Promise<void> {
        try {
            const playerData = await this.fetchPlayerData();
            const levelData = await this.fetchLevelData(playerData.currentLevel);
            await this.initializeGame(playerData, levelData);
        } catch (error) {
            console.error('Failed to load game data:', error);
            throw error;
        }
    }

    // ✅ EXCELLENT: Promise.all for parallel operations
    public async loadAllData(): Promise<void> {
        try {
            const [playerData, configData, assetsData] = await Promise.all([
                this.fetchPlayerData(),
                this.fetchConfigData(),
                this.fetchAssetsData(),
            ]);

            this.initializeWithData(playerData, configData, assetsData);
        } catch (error) {
            console.error('Failed to load data:', error);
            throw error;
        }
    }

    // ✅ EXCELLENT: Promise.allSettled for partial failures
    public async loadDataWithFallback(): Promise<void> {
        const results = await Promise.allSettled([
            this.fetchPlayerData(),
            this.fetchConfigData(),
            this.fetchAssetsData(),
        ]);

        results.forEach((result, index) => {
            if (result.status === 'fulfilled') {
                console.log(`Data ${index} loaded:`, result.value);
            } else {
                console.error(`Data ${index} failed:`, result.reason);
            }
        });
    }

    // ✅ EXCELLENT: Error handling with async/await
    public async savePlayerData(data: PlayerData): Promise<boolean> {
        try {
            await this.validateData(data);
            await this.uploadData(data);
            return true;
        } catch (error) {
            if (error instanceof ValidationError) {
                console.error('Invalid data:', error.message);
            } else if (error instanceof NetworkError) {
                console.error('Network error:', error.message);
            } else {
                console.error('Unknown error:', error);
            }
            return false;
        }
    }

    private async fetchPlayerData(): Promise<PlayerData> {
        // Implementation
    }

    private async fetchLevelData(level: number): Promise<LevelData> {
        // Implementation
    }
}

// ❌ BAD: Promise chains (callback hell)
public loadGameData(): void {
    this.fetchPlayerData()
        .then(playerData => {
            return this.fetchLevelData(playerData.currentLevel);
        })
        .then(levelData => {
            return this.initializeGame(playerData, levelData); // playerData not in scope!
        })
        .catch(error => {
            console.error('Failed:', error);
        });
}
```

## Summary: Modern TypeScript Checklist

**Use these patterns for cleaner, more maintainable code:**

- [ ] Array methods (map/filter/reduce) instead of manual loops
- [ ] Arrow functions for callbacks and event handlers
- [ ] Destructuring for cleaner parameter handling
- [ ] Spread operator for object/array operations
- [ ] Optional chaining (?.) for safe property access
- [ ] Nullish coalescing (??) for default values
- [ ] Type guards for type-safe narrowing
- [ ] Utility types (Partial, Required, Readonly, Pick, Omit, Record)
- [ ] Async/await for asynchronous operations
- [ ] Promise.all/allSettled for parallel operations

**Modern TypeScript makes code more concise, readable, and type-safe.**
