# Phase 1: Model Catalog Update

**Date**: 2025-11-20
**Priority**: High
**Status**: Pending
**Effort**: Low (1-2 hours)

## Context

Current SKILL.md only documents Gemini 2.5 series. Need to add:
- Imagen 4 (3 variants)
- Veo 3/3.1 (4 variants)
- Gemini 3 (2 variants)

**Related Files**:
- `.claude/skills/ai-multimodal/SKILL.md:71-83` (Model Selection Guide)
- `.claude/skills/ai-multimodal/SKILL.md:59-69` (Capability Matrix)

## Overview

Update model catalog maintaining progressive disclosure - keep SKILL.md under 80 lines overhead while providing complete model information.

## Key Insights

1. **Separation of Concerns**: Image gen (Imagen) vs multimodal understanding (Gemini)
2. **Video Generation is New**: Currently only video analysis exists, not generation
3. **Model Variants**: Fast/Standard/Ultra for different use cases
4. **Backward Compatibility**: Existing scripts use gemini-2.5-flash-image

## Requirements

### Functional
- Document all 9 new model IDs with clear descriptions
- Update capability matrix to include video generation
- Add model selection decision tree
- Maintain token efficiency (progressive disclosure)

### Non-Functional
- Keep SKILL.md main section under 400 lines
- Use reference files for detailed specs
- Clear model naming conventions
- Easy copy-paste model IDs

## Architecture

```
SKILL.md
├── Model Selection Guide (updated)
│   ├── Gemini 3 Series (new)
│   ├── Gemini 2.5 Series (existing)
│   ├── Imagen 4 Series (new)
│   └── Veo 3 Series (new)
└── Capability Matrix (updated)
    └── Add video generation row
```

## Implementation Steps

### 1. Update Model Selection Guide (SKILL.md:71-83)

**Current structure**:
```markdown
### Gemini 2.5 Series (Recommended)
- gemini-2.5-pro
- gemini-2.5-flash
- gemini-2.5-flash-lite
- gemini-2.5-flash-image
```

**New structure**:
```markdown
### Gemini 3 Series (Latest - Advanced Workflows)
- gemini-3-pro-preview: Agentic workflows, 1M context, dynamic thinking
- gemini-3-pro-image-preview: Image generation with conversational editing

### Gemini 2.5 Series (Recommended - General Use)
- gemini-2.5-pro: Highest quality, all features
- gemini-2.5-flash: Best balance, all features
- gemini-2.5-flash-lite: Lightweight, segmentation
- gemini-2.5-flash-image: Image generation only (deprecated - use Imagen 4)

### Imagen 4 Series (Image Generation)
- imagen-4.0-generate-001: Standard quality, balanced speed
- imagen-4.0-ultra-generate-001: Maximum quality, detailed images
- imagen-4.0-fast-generate-001: Fastest generation, good quality

### Veo 3 Series (Video Generation)
- veo-3.1-generate-preview: Latest, native audio, frame control
- veo-3.1-fast-generate-preview: Speed-optimized, business use
- veo-3.0-generate-001: Stable, native audio, 8s videos
- veo-3.0-fast-generate-001: Stable fast variant
```

### 2. Update Capability Matrix (SKILL.md:59-69)

Add video generation row:

```markdown
| Task | Audio | Image | Video | Document | Image Gen | Video Gen |
|------|:-----:|:-----:|:-----:|:--------:|:---------:|:---------:|
| Creation | TTS | - | - | - | ✓ | ✓ |
```

### 3. Add Feature Requirements Section

After line 83, add:

```markdown
### Model Selection by Use Case

**Video Generation**: Veo 3 models only
**Image Generation**: Imagen 4 (recommended) or Gemini 3 Pro Image
**Multimodal Analysis**: Gemini 2.5/3.0 models
**Segmentation**: Requires 2.5+ models
**Object Detection**: Requires 2.0+ models
```

### 4. Update Quick Start Examples

Update line 165 (image generation example):

```bash
# Old (deprecated but still works)
--model gemini-2.5-flash-image

# New (recommended)
--model imagen-4.0-generate-001

# For best quality
--model imagen-4.0-ultra-generate-001

# For fastest generation
--model imagen-4.0-fast-generate-001
```

### 5. Add Video Generation Quick Start

After line 167, add new example:

```bash
**Generate Video**:
```bash
python scripts/gemini_batch_process.py \
  --task generate-video \
  --prompt "A serene beach sunset with gentle waves" \
  --output docs/assets/<output-file-name>.mp4 \
  --model veo-3.1-generate-preview \
  --duration 8 \
  --resolution 1080p
```

## Todo List

- [ ] Update Model Selection Guide with 4 model series
- [ ] Add Gemini 3, Imagen 4, Veo 3 model IDs
- [ ] Update Capability Matrix (add Video Gen column)
- [ ] Add Model Selection by Use Case section
- [ ] Update image generation example (Imagen 4)
- [ ] Add video generation quick start example
- [ ] Mark gemini-2.5-flash-image as deprecated
- [ ] Verify line count stays under 400 lines
- [ ] Test all model IDs are copy-pasteable

## Success Criteria

- [ ] All 9 new models documented with clear descriptions
- [ ] Capability matrix includes video generation
- [ ] Model selection guide helps users choose correct model
- [ ] Quick start examples use latest recommended models
- [ ] SKILL.md maintains progressive disclosure (under 400 lines main section)
- [ ] Backward compatibility note for existing users

## Risk Assessment

**Low Risk**:
- Documentation only changes
- No code modifications
- Backward compatible (old models still work)

**Considerations**:
- Users may not know which Imagen variant to choose
- Video generation pricing not yet documented
- Preview models may have API changes

## Security Considerations

None - documentation changes only.

## Next Steps

After completion:
1. Proceed to Phase 2 (Environment Configuration)
2. Update .env.example with new model variables
3. Ensure model IDs match Google's official documentation
