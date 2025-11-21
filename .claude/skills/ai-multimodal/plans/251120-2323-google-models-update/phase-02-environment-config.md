# Phase 2: Environment Configuration

**Date**: 2025-11-20
**Priority**: High
**Status**: Pending
**Effort**: Low (1 hour)

## Context

Current `.env.example` only has basic GEMINI_API_KEY and optional model override. Need granular control for new model types.

**Related Files**:
- `.claude/skills/ai-multimodal/.env.example:1-98`
- `.claude/skills/ai-multimodal/scripts/gemini_batch_process.py:37-83` (API key detection)

## Overview

Add environment variables for model selection across all capabilities while maintaining backward compatibility and clear documentation.

## Key Insights

1. **Model-Specific Variables**: Different models for different tasks
2. **Backward Compatibility**: Default to existing behavior if not set
3. **User Choice**: Allow override without code changes
4. **Progressive Defaults**: Smart defaults (Imagen 4 over Flash Image)

## Requirements

### Functional
- Add variables for Imagen 4 model selection
- Add variables for Veo video generation models
- Add variables for Gemini 3 models
- Maintain existing GEMINI_API_KEY behavior
- Clear comments explaining when to use each

### Non-Functional
- Self-documenting variable names
- Grouped by capability
- Include pricing hints
- Examples for common scenarios

## Architecture

```
.env.example
├── API Authentication (existing)
├── Model Selection (expanded)
│   ├── IMAGE_GEN_MODEL (new - Imagen 4 variants)
│   ├── VIDEO_GEN_MODEL (new - Veo variants)
│   ├── MULTIMODAL_MODEL (new - Gemini 3/2.5)
│   └── GEMINI_MODEL (existing - backward compat)
└── Processing Options (existing)
```

## Implementation Steps

### 1. Add Model Selection Section (after line 23)

Insert comprehensive model selection block:

```bash
# ============================================================================
# Model Selection (Optional)
# ============================================================================
# Override default models for specific capabilities
# If not set, intelligent defaults are used based on task type

# --- Image Generation ---
# Used by: --task generate (image)
# Default: imagen-4.0-generate-001
# Options:
#   imagen-4.0-generate-001        - Standard quality, balanced ($0.02/image est.)
#   imagen-4.0-ultra-generate-001  - Maximum quality ($0.04/image est.)
#   imagen-4.0-fast-generate-001   - Fastest generation ($0.01/image est.)
#   gemini-3-pro-image-preview     - With conversational editing
#   gemini-2.5-flash-image         - Legacy (still works)
IMAGE_GEN_MODEL=imagen-4.0-generate-001

# --- Video Generation ---
# Used by: --task generate-video (new capability)
# Default: veo-3.1-generate-preview
# Options:
#   veo-3.1-generate-preview       - Latest, native audio, frame control (preview)
#   veo-3.1-fast-generate-preview  - Speed-optimized for business (preview)
#   veo-3.0-generate-001           - Stable, native audio, 8s videos
#   veo-3.0-fast-generate-001      - Stable fast variant
VIDEO_GEN_MODEL=veo-3.1-generate-preview

# --- Multimodal Analysis ---
# Used by: --task analyze, transcribe, extract
# Default: gemini-2.5-flash
# Options:
#   gemini-3-pro-preview           - Latest, agentic workflows, 1M context
#   gemini-2.5-flash               - Best price/performance (recommended)
#   gemini-2.5-pro                 - Highest quality
MULTIMODAL_MODEL=gemini-2.5-flash

# --- Legacy Compatibility ---
# Generic model override (use specific variables above instead)
# GEMINI_MODEL=gemini-2.5-flash
```

### 2. Add Video Generation Options (after line 48)

```bash
# ============================================================================
# Video Generation Options (Optional)
# ============================================================================
# Video duration in seconds (8s only for now)
# VEO_DURATION=8

# Video resolution: 720p or 1080p
# VEO_RESOLUTION=1080p

# Aspect ratio: 16:9, 9:16, 1:1 (16:9 is default)
# VEO_ASPECT_RATIO=16:9

# Frame rate: 24fps (fixed for now)
# VEO_FPS=24

# Enable native audio generation
# VEO_AUDIO=true
```

### 3. Add Image Generation Options (after line 68)

```bash
# ============================================================================
# Image Generation Options (Optional)
# ============================================================================
# Number of images to generate (1-4)
# IMAGEN_NUM_IMAGES=1

# Image size: 1K or 2K (Ultra/Standard only)
# IMAGEN_SIZE=1K

# Aspect ratio: 1:1, 16:9, 9:16, 4:3, 3:4
# IMAGEN_ASPECT_RATIO=1:1

# Enable person generation (restricted in EEA, CH, UK)
# IMAGEN_PERSON_GENERATION=true

# Add SynthID watermark (always enabled by default)
# IMAGEN_WATERMARK=true
```

### 4. Add Model Pricing Reference (after line 88)

```bash
# ============================================================================
# Pricing Reference (as of 2025-11)
# ============================================================================
# Gemini 2.5 Flash: $1.00/1M input, $0.10/1M output
# Gemini 2.5 Pro: $3.00/1M input, $12.00/1M output
# Gemini 3 Pro: $2.00/1M input (<200k), $4.00 (>200k), $12/$18 output
# Imagen 4: ~$0.01-$0.04 per image (varies by variant)
# Veo 3: TBD (preview pricing)
# Monitor: https://ai.google.dev/pricing
```

### 5. Update Notes Section (line 90+)

Add to existing notes:

```bash
# 7. New model defaults (Nov 2025):
#    - Image gen: Imagen 4 (was Flash Image)
#    - Video gen: Veo 3.1 (new capability)
#    - Analysis: Gemini 2.5 Flash (unchanged)
# 8. Preview models (veo-3.1, gemini-3) may have API changes
```

## Todo List

- [ ] Add IMAGE_GEN_MODEL variable with Imagen 4 options
- [ ] Add VIDEO_GEN_MODEL variable with Veo options
- [ ] Add MULTIMODAL_MODEL variable with Gemini options
- [ ] Add video generation options section (duration, resolution, etc)
- [ ] Add image generation options section (size, aspect ratio, etc)
- [ ] Add pricing reference section
- [ ] Update notes with model defaults changes
- [ ] Add comments explaining each model variant
- [ ] Include cost estimates where available
- [ ] Test that all variables are valid

## Success Criteria

- [ ] Users can configure any new model via environment variables
- [ ] Clear documentation for when to use each model
- [ ] Backward compatibility maintained (old vars still work)
- [ ] Pricing hints help users make informed decisions
- [ ] Video generation options fully configurable
- [ ] Self-documenting with inline examples

## Risk Assessment

**Low Risk**:
- Optional variables (defaults used if not set)
- No breaking changes to existing setups
- Documentation only

**Considerations**:
- Preview model pricing unknown (use TBD)
- Users may set invalid model combinations
- Need validation in scripts

## Security Considerations

- API key handling unchanged
- No new security concerns
- Same .gitignore rules apply

## Next Steps

After completion:
1. Proceed to Phase 3 (Image Generation Enhancement)
2. Update scripts to read new environment variables
3. Add validation for model + task combinations
