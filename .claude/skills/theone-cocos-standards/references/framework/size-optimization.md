# Bundle Size Optimization (<5MB Target)

## Texture Compression (Biggest Impact)

**Target: <5MB total bundle size for playable ads**

Texture compression is the single biggest factor in bundle size. Enable compression for all platforms.

### Build Settings Configuration

```json
// Project Settings → Build → Web Mobile
{
    "textureCompression": {
        "web-mobile": "auto",     // Auto-select best compression
        "web-desktop": "auto",
        "android": "etc1",        // ETC1 for Android
        "ios": "pvrtc"            // PVRTC for iOS
    },
    "packAutoAtlas": true,       // Auto-generate atlases
    "md5Cache": false,           // Disable for smaller output
    "inlineSpriteFrames": true   // Reduce file count
}
```

### Texture Size Guidelines

```typescript
// ✅ EXCELLENT: Optimal texture sizes for playables

// Character sprites: 512x512 max (often 256x256 is enough)
// UI elements: 256x256 max
// Backgrounds: 1024x1024 max (or use tiled smaller textures)
// Effects: 128x128 or 256x256
// Icons: 64x64 or 128x128

// ❌ WRONG: Oversized textures
// - 2048x2048 for small character sprites
// - High-res images that won't be seen at that scale
// Use appropriate sizes for display resolution
```

## Asset Optimization Priority

### 1. Textures (50-60% of bundle)

```typescript
// ✅ EXCELLENT: Sprite atlas configuration
// Combine multiple small textures into single atlas
// - Character animations: single atlas
// - UI elements: single atlas
// - Effects: single atlas

// Auto-atlas settings (Project Settings):
// - Max Width: 2048
// - Max Height: 2048
// - Padding: 2
// - Allow Rotation: true
// - Force Square: false

// ❌ WRONG: Individual texture files
// Each separate texture = separate HTTP request + worse compression
```

### 2. Audio (20-30% of bundle)

```typescript
// ✅ EXCELLENT: Audio optimization
// - Format: MP3 or OGG (not WAV)
// - Background music: 128kbps max, short loops (<30 seconds)
// - Sound effects: 64kbps, very short (<2 seconds)

// ❌ WRONG: Uncompressed audio
// - WAV files: 10-20x larger than compressed
// - Long music tracks: use short loops
// - High bitrate: 320kbps unnecessary for playables
```

### 3. Code (5-10% of bundle)

```typescript
// ✅ EXCELLENT: Code minification
// rollup.config.js or webpack.config.js
export default {
    mode: 'production',
    optimization: {
        minimize: true,
        minimizer: [
            new TerserPlugin({
                terserOptions: {
                    compress: {
                        drop_console: true,      // Remove console.log
                        drop_debugger: true,     // Remove debugger
                        dead_code: true,         // Remove unreachable code
                        unused: true             // Remove unused variables
                    },
                    mangle: { toplevel: true }   // Shorten variable names
                }
            })
        ]
    }
};

// ✅ EXCELLENT: Import only what you need
import { Vec3, Node } from 'cc'; // Specific imports

// ❌ WRONG: Import entire module
import * as cc from 'cc'; // Imports everything (larger bundle)
```

### 4. Fonts (5-10% of bundle)

```typescript
// ✅ EXCELLENT: Bitmap fonts for playables
// - Pre-render characters to texture
// - Include only needed characters: "0123456789,."
// - Much smaller than TTF fonts

// Create bitmap font:
// 1. Use BMFont tool or online generator
// 2. Include only needed characters
// 3. Export as .fnt + .png
// 4. Import to Cocos Creator as BitmapFont

// ❌ WRONG: TTF fonts
// - Large file size (hundreds of KB)
// - System fonts vary by platform
// - Use bitmap fonts for playables
```

## Build Configuration for Minimum Size

```json
// Project Settings → Build → Web Mobile

{
    // Bundle settings
    "inlineSpriteFrames": true,      // Reduce file count
    "md5Cache": false,               // Disable MD5 in filenames
    "mainBundleCompressionType": "default",
    "mainBundleIsRemote": false,

    // Code optimization
    "debug": false,                  // Disable debug mode
    "sourceMaps": false,             // Disable source maps
    "separateEngine": false,         // Include engine in bundle

    // Texture optimization
    "packAutoAtlas": true,           // Auto-generate atlases
    "textureCompression": "auto",    // Enable compression

    // Feature exclusions
    "excludeScenes": [],             // Remove unused scenes
    "useBuiltinServer": false        // Playables don't need server
}
```

## Removing Unused Assets

```typescript
// ✅ EXCELLENT: Regular asset cleanup

// 1. Use Cocos Creator's "Find References" feature
// - Right-click asset → Find References
// - Delete if no references found

// 2. Check build output
// - Review build folder size after each build
// - Identify largest files
// - Remove unused assets

// 3. Remove debug assets before build
// - Test levels
// - Debug sprites and textures
// - Development-only tools
// - Temporary assets

// ❌ WRONG: Keep all assets "just in case"
// - Unused textures add unnecessary size
// - Clean up regularly during development
```

## Real-World Example: Size Breakdown

```typescript
// Target: <5MB playable bundle
// Typical optimized breakdown:

// Textures: 2.5MB (50%)
// - Character sprites: 800KB (sprite atlas, ETC1 compressed)
// - UI elements: 600KB (sprite atlas, ETC1 compressed)
// - Background: 700KB (1024x1024, compressed, or tiled)
// - Effects: 400KB (sprite atlas, compressed)

// Code: 400KB (8%)
// - Cocos engine: 200KB (minified, tree-shaken)
// - Game logic: 200KB (minified, dead code removed)

// Audio: 1.5MB (30%)
// - Background music: 1MB (MP3, 128kbps, 60s loop)
// - Sound effects: 500KB (MP3, 64kbps, 10 short clips)

// Other: 600KB (12%)
// - Bitmap fonts: 200KB (only needed characters)
// - Config files: 100KB (JSON, minified)
// - Misc assets: 300KB

// Total: 5.0MB (within ad network limit)

// ❌ BAD EXAMPLE: Unoptimized (12MB+)
// - Textures: 8MB (no compression, individual files)
// - Audio: 3MB (WAV files, long tracks)
// - Code: 800KB (no minification, dev mode)
// - Fonts: 400KB (TTF fonts)
// Total: 12.2MB (rejected by ad networks!)
```

## Monitoring Bundle Size

```bash
# ✅ EXCELLENT: Monitor size regularly

# 1. Check build output size
du -sh build/web-mobile/

# 2. Break down by asset type
du -sh build/web-mobile/assets/
du -sh build/web-mobile/src/

# 3. Find largest files
find build/web-mobile -type f -exec du -h {} \; | sort -rh | head -20

# 4. Set size budget in CI/CD
# Fail build if bundle >5MB
# Alert if bundle >4.5MB (warning threshold)
```

## Lazy Loading Pattern (Optional)

```typescript
import { _decorator, Component, resources, Prefab } from 'cc';
const { ccclass } = _decorator;

@ccclass('LazyLoader')
export class LazyLoader extends Component {
    // ✅ EXCELLENT: Load levels on demand
    // For playables with multiple levels, load only current level

    private levelPrefabs: Map<number, Prefab> = new Map();

    public async loadLevel(levelId: number): Promise<void> {
        if (this.levelPrefabs.has(levelId)) {
            return; // Already loaded
        }

        const path = `levels/level_${levelId}`;
        return new Promise((resolve, reject) => {
            resources.load(path, Prefab, (err, prefab) => {
                if (err) {
                    reject(err);
                    return;
                }
                this.levelPrefabs.set(levelId, prefab);
                resolve();
            });
        });
    }

    // ✅ GOOD: Unload previous level
    public async switchLevel(fromLevel: number, toLevel: number): Promise<void> {
        const prevPrefab = this.levelPrefabs.get(fromLevel);
        if (prevPrefab) {
            prevPrefab.decRef();
            this.levelPrefabs.delete(fromLevel);
        }
        await this.loadLevel(toLevel);
    }
}

// ❌ WRONG: Loading all levels at start
// - Increases initial bundle size
// - Longer load time
// - Only load what's needed for first level
```

## Size Optimization Checklist

**🔴 Critical (Biggest Impact):**
- [ ] Enable texture compression (auto or platform-specific)
- [ ] Use sprite atlases (combine textures)
- [ ] Reduce texture dimensions (512x512 max for characters)
- [ ] Compress audio (MP3/OGG, 64-128kbps)
- [ ] Remove unused assets

**🟡 Important:**
- [ ] Enable code minification (drop_console, dead_code removal)
- [ ] Use bitmap fonts (not TTF)
- [ ] Disable source maps in production
- [ ] Import specific modules (tree shaking)
- [ ] Remove debug/test assets

**🟢 Nice to Have:**
- [ ] Lazy load levels (if multiple levels)
- [ ] Monitor bundle size in CI/CD
- [ ] Set size budget alerts (<5MB hard limit)
- [ ] Track size trends over time

**Target: <5MB total bundle size for playable ad approval.**
