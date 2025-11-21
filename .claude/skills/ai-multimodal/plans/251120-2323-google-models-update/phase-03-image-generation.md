# Phase 3: Image Generation Enhancement

**Date**: 2025-11-20
**Priority**: Medium
**Status**: Pending
**Effort**: Medium (3-4 hours)

## Context

Current image generation reference only documents `gemini-2.5-flash-image`. Need to add Imagen 4 support with 3 quality variants and updated API patterns.

**Related Files**:
- `.claude/skills/ai-multimodal/references/image-generation.md:15-21` (Model section)
- `.claude/skills/ai-multimodal/references/image-generation.md:529-559` (Troubleshooting)
- `.claude/skills/ai-multimodal/scripts/gemini_batch_process.py` (generation logic)

## Overview

Expand image generation capabilities to support Imagen 4 models while maintaining Flash Image backward compatibility. Add quality/speed trade-off guidance.

## Key Insights

1. **Imagen 4 API Changes**: Different model IDs, potentially different config
2. **Three Quality Tiers**: Standard/Ultra/Fast for different needs
3. **Cost vs Quality**: Users need guidance on variant selection
4. **API Compatibility**: Imagen 4 may have different parameters than Flash Image
5. **Troubleshooting Updated**: aspect_ratio parameter structure may differ

## Requirements

### Functional
- Document all 3 Imagen 4 variants with examples
- Add model comparison matrix (quality/speed/cost)
- Update code examples to use Imagen 4
- Maintain Flash Image examples (backward compat)
- Add variant selection decision tree
- Update troubleshooting for Imagen 4

### Non-Functional
- Examples are copy-pasteable
- Clear quality/cost trade-offs
- Performance benchmarks where available
- Token-efficient (progressive disclosure)

## Architecture

```
references/image-generation.md
├── Model Section (updated)
│   ├── Imagen 4 (new primary)
│   ├── Gemini 3 Pro Image (new alternative)
│   └── Flash Image (deprecated but documented)
├── Quick Start (updated to Imagen 4)
├── Model Comparison (new section)
└── Troubleshooting (updated for Imagen 4)
```

## Implementation Steps

### 1. Update Model Section (line 15-21)

Replace with comprehensive model documentation:

```markdown
## Models

### Imagen 4 (Recommended)

**imagen-4.0-generate-001** - Standard quality, balanced performance
- Best for: General use, prototyping, iterative workflows
- Quality: High
- Speed: Medium (~5-10s per image)
- Cost: ~$0.02/image (estimated)
- Output: 1-4 images per request
- Resolution: 1K or 2K
- Updated: June 2025

**imagen-4.0-ultra-generate-001** - Maximum quality
- Best for: Final production, marketing assets, detailed artwork
- Quality: Ultra (highest available)
- Speed: Slow (~15-25s per image)
- Cost: ~$0.04/image (estimated)
- Output: 1-4 images per request
- Resolution: 2K preferred
- Updated: June 2025

**imagen-4.0-fast-generate-001** - Fastest generation
- Best for: Rapid iteration, bulk generation, real-time use
- Quality: Good
- Speed: Fast (~2-5s per image)
- Cost: ~$0.01/image (estimated)
- Output: 1-4 images per request
- Resolution: 1K
- Updated: June 2025

### Gemini 3 Pro Image (Alternative)

**gemini-3-pro-image-preview** - Conversational image generation
- Best for: Iterative refinement with natural language editing
- Quality: High
- Context: 65k input / 32k output tokens
- Cost: $2/1M text input, $0.134/image output (resolution-dependent)
- Unique: Native 4K text rendering, grounded generation
- Updated: January 2025

### Legacy Models

**gemini-2.5-flash-image** - Legacy image generation
- Status: Deprecated (use Imagen 4 instead)
- Still functional for backward compatibility
- Input: 65,536 tokens
- Output: 32,768 tokens
- Cost: $1/1M input
```

### 2. Add Model Comparison Matrix (after line 21)

```markdown
## Model Comparison

| Model | Quality | Speed | Cost | Best For |
|-------|---------|-------|------|----------|
| imagen-4.0-ultra | ⭐⭐⭐⭐⭐ | 🐢 Slow | 💰💰 High | Production assets |
| imagen-4.0-standard | ⭐⭐⭐⭐ | ⚡ Medium | 💰 Medium | General use |
| imagen-4.0-fast | ⭐⭐⭐ | 🚀 Fast | 💵 Low | Rapid iteration |
| gemini-3-pro-image | ⭐⭐⭐⭐ | ⚡ Medium | 💰 Medium | Text rendering |
| gemini-2.5-flash-image | ⭐⭐⭐ | ⚡ Medium | 💵 Low | Legacy (deprecated) |

**Selection Guide**:
- **Marketing/Production**: Use `imagen-4.0-ultra` for final deliverables
- **General Development**: Use `imagen-4.0-generate-001` for balanced workflow
- **Prototyping/Iteration**: Use `imagen-4.0-fast` for quick feedback
- **Text-Heavy Images**: Use `gemini-3-pro-image` for 4K text rendering
```

### 3. Update Quick Start Examples (line 24-48)

Replace with Imagen 4 examples:

```markdown
## Quick Start

### Basic Generation (Imagen 4)

```python
from google import genai
from google.genai import types
import os

client = genai.Client(api_key=os.getenv('GEMINI_API_KEY'))

# Standard quality (recommended)
response = client.models.generate_images(
    model='imagen-4.0-generate-001',
    prompt='A serene mountain landscape at sunset with snow-capped peaks',
    config=types.ImageGenerationConfig(
        number_of_images=1,
        aspect_ratio='16:9',
        size='1K'
    )
)

# Save image
for i, image in enumerate(response.images):
    with open(f'output-{i}.png', 'wb') as f:
        f.write(image.data)
```

### Quality Variants

```python
# Ultra quality (production)
response = client.models.generate_images(
    model='imagen-4.0-ultra-generate-001',
    prompt='Professional product photography of smartphone',
    config=types.ImageGenerationConfig(
        number_of_images=1,
        size='2K'  # Use 2K for ultra
    )
)

# Fast generation (iteration)
response = client.models.generate_images(
    model='imagen-4.0-fast-generate-001',
    prompt='Quick concept sketch of robot character',
    config=types.ImageGenerationConfig(
        number_of_images=4  # Generate multiple variants
    )
)
```

### Legacy Flash Image (Backward Compatibility)

```python
# Still works but deprecated
response = client.models.generate_content(
    model='gemini-2.5-flash-image',
    contents='A futuristic cityscape',
    config=types.GenerateContentConfig(
        response_modalities=['Image'],
        image_config=types.ImageConfig(
            aspect_ratio='16:9'
        )
    )
)
```
```

### 4. Add API Differences Section (new)

```markdown
## API Differences

### Imagen 4 vs Flash Image

**Imagen 4** uses `generate_images()`:
```python
response = client.models.generate_images(
    model='imagen-4.0-generate-001',
    prompt='...',
    config=types.ImageGenerationConfig(...)
)
```

**Flash Image** uses `generate_content()`:
```python
response = client.models.generate_content(
    model='gemini-2.5-flash-image',
    contents='...',
    config=types.GenerateContentConfig(
        response_modalities=['Image'],
        image_config=types.ImageConfig(...)
    )
)
```

**Key Differences**:
1. Different method: `generate_images()` vs `generate_content()`
2. Different config: `ImageGenerationConfig` vs `GenerateContentConfig`
3. Parameter names: `prompt` vs `contents`
4. Response structure: `response.images` vs `response.candidates[0].content.parts`
```

### 5. Update Troubleshooting Section (line 529-559)

Add Imagen 4-specific troubleshooting:

```markdown
## Troubleshooting

### Imagen 4 Configuration

**Correct Usage**:
```python
from google.genai import types

config = types.ImageGenerationConfig(
    number_of_images=1,      # 1-4 images
    aspect_ratio='16:9',     # 1:1, 16:9, 9:16, 4:3, 3:4
    size='1K',               # 1K or 2K
    include_safety_attributes=True
)

response = client.models.generate_images(
    model='imagen-4.0-generate-001',
    prompt='Your prompt here',
    config=config
)
```

**Common Errors**:

1. **Wrong method**: Using `generate_content()` instead of `generate_images()`
   ```python
   # ❌ Wrong
   client.models.generate_content(model='imagen-4.0-generate-001', ...)

   # ✅ Correct
   client.models.generate_images(model='imagen-4.0-generate-001', ...)
   ```

2. **Invalid size for model**: 2K only works with Ultra/Standard
   ```python
   # ❌ Wrong
   model='imagen-4.0-fast-generate-001', size='2K'

   # ✅ Correct
   model='imagen-4.0-fast-generate-001', size='1K'
   ```

3. **Model not available**: Check region restrictions
   - Imagen 4 may have limited availability
   - Check: https://ai.google.dev/gemini-api/docs/imagen

### Flash Image Configuration (Legacy)

[Keep existing troubleshooting section lines 529-559]
```

## Todo List

- [ ] Update model section with all Imagen 4 variants
- [ ] Add Gemini 3 Pro Image documentation
- [ ] Create model comparison matrix
- [ ] Update quick start examples (Imagen 4)
- [ ] Add backward compatibility examples (Flash Image)
- [ ] Document API differences between models
- [ ] Update troubleshooting with Imagen 4 errors
- [ ] Add quality/speed/cost selection guide
- [ ] Test all code examples are syntactically correct
- [ ] Verify all model IDs match Google docs

## Success Criteria

- [ ] All 3 Imagen 4 variants documented with examples
- [ ] Clear model selection guidance based on use case
- [ ] Code examples are copy-pasteable and functional
- [ ] Backward compatibility maintained (Flash Image)
- [ ] API differences clearly explained
- [ ] Troubleshooting covers common Imagen 4 issues
- [ ] Progressive disclosure maintained (core info in SKILL.md)

## Risk Assessment

**Medium Risk**:
- Imagen 4 API may differ from documentation assumptions
- Pricing estimates may be inaccurate
- Model availability may vary by region

**Mitigation**:
- Mark pricing as "estimated"
- Note preview/beta status
- Provide fallback to Flash Image
- Include validation in scripts

## Security Considerations

- Same safety filters apply
- SynthID watermark automatic on Imagen 4
- Person generation restrictions in EEA/CH/UK

## Next Steps

After completion:
1. Proceed to Phase 4 (Video Generation Integration)
2. Test Imagen 4 API with real requests
3. Update scripts to use new API methods
