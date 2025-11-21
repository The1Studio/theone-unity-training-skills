# Phase 6: Reference Documentation

**Date**: 2025-11-20
**Priority**: Medium
**Status**: Pending
**Effort**: Medium (3-4 hours)

## Context

Need to create video-generation.md reference and update existing references to mention new models. Maintain progressive disclosure pattern.

**Related Files**:
- New: `.claude/skills/ai-multimodal/references/video-generation.md`
- Update: `.claude/skills/ai-multimodal/references/image-generation.md`
- Update: `.claude/skills/ai-multimodal/references/audio-processing.md`
- Update: `.claude/skills/ai-multimodal/references/vision-understanding.md`

## Overview

Create comprehensive video generation reference and update existing references with model recommendations and cross-references.

## Key Insights

1. **Progressive Disclosure**: SKILL.md → references → examples
2. **Cross-Referencing**: Link related capabilities across references
3. **Model Updates**: Mention Gemini 3 where relevant
4. **Consistency**: Same structure across all references
5. **Practical Focus**: Emphasize working code examples

## Requirements

### Functional
- Create complete video-generation.md (done in Phase 4)
- Update image-generation.md with Imagen 4 (done in Phase 3)
- Update audio-processing.md with Gemini 3 mention
- Update vision-understanding.md with Gemini 3 mention
- Add cross-references between related capabilities

### Non-Functional
- Consistent structure across references
- Progressive disclosure (basics → advanced)
- Copy-pasteable examples
- Clear file size limits
- Token-efficient

## Architecture

```
references/
├── video-generation.md (created in Phase 4)
├── image-generation.md (updated in Phase 3)
├── audio-processing.md (update mentions)
├── vision-understanding.md (update mentions)
├── video-analysis.md (add cross-ref to generation)
└── document-extraction.md (no changes)
```

## Implementation Steps

### 1. Update audio-processing.md

Add Gemini 3 mention in model section:

```markdown
## Models

### Recommended Models

**gemini-3-pro-preview** (Latest)
- Best for: Complex audio analysis with reasoning
- Context: 1M tokens
- Features: All audio capabilities + dynamic thinking
- Updated: January 2025

**gemini-2.5-flash** (Balanced)
- Best for: Most audio tasks (recommended)
- Context: 1M-2M tokens
- Cost: $1/1M input, $0.10/1M output
- Updated: 2025

**gemini-2.5-pro** (Quality)
- Best for: High-accuracy transcription, complex analysis
- Context: 1M-2M tokens
- Cost: $3/1M input, $12/1M output

### Model Selection
- **General use**: gemini-2.5-flash (best price/performance)
- **Highest quality**: gemini-2.5-pro or gemini-3-pro-preview
- **Long audio**: gemini-2.5-flash (2M context)
```

### 2. Update vision-understanding.md

Add Gemini 3 mention and cross-reference to image generation:

```markdown
## Models

### Latest Models

**gemini-3-pro-preview** (Latest)
- Advanced visual reasoning with dynamic thinking
- 1M context window
- Best for: Complex visual analysis, agentic workflows
- Updated: January 2025

**gemini-3-pro-image-preview** (Image Generation)
- Visual understanding + image generation
- Native 4K text rendering in images
- See: [Image Generation Reference](./image-generation.md)
- Updated: January 2025

### Recommended Models

**gemini-2.5-flash** (Balanced)
- Best for: Most vision tasks (recommended)
- Supports: Segmentation, object detection, OCR
- Context: 1M-2M tokens
- Updated: 2025

**gemini-2.5-pro** (Quality)
- Highest quality vision understanding
- All features supported
- Updated: 2025

### Model Selection
- **Complex reasoning**: gemini-3-pro-preview
- **Image generation + analysis**: gemini-3-pro-image-preview
- **General vision tasks**: gemini-2.5-flash (recommended)
- **Highest quality**: gemini-2.5-pro
- **Segmentation required**: gemini-2.5+ models only
```

### 3. Update video-analysis.md

Add cross-reference to video generation:

At the top of the file, add:

```markdown
# Video Analysis Reference

Comprehensive guide for video understanding and analysis using Gemini API.

> **Note**: This guide covers video *analysis* (understanding existing videos). For video *generation* (creating new videos), see [Video Generation Reference](./video-generation.md).

---
```

Add to Resources section:

```markdown
## Related Capabilities

- **Video Generation**: Create videos from text/images - [video-generation.md](./video-generation.md)
- **Image Understanding**: Analyze video frames - [vision-understanding.md](./vision-understanding.md)
- **Audio Processing**: Extract and analyze audio tracks - [audio-processing.md](./audio-processing.md)
```

### 4. Add Navigation Section to SKILL.md

Update lines 226-263 to include video generation:

```markdown
## Reference Navigation

For detailed implementation guidance, see:

### Audio Processing
- `references/audio-processing.md` - Transcription, analysis, TTS
  - Timestamp handling and segment analysis
  - Multi-speaker identification
  - Non-speech audio analysis
  - Text-to-speech generation

### Image Understanding
- `references/vision-understanding.md` - Captioning, detection, OCR
  - Object detection and localization
  - Pixel-level segmentation
  - Visual question answering
  - Multi-image comparison

### Image Generation
- `references/image-generation.md` - Text-to-image with Imagen 4
  - Imagen 4 quality variants (Standard/Ultra/Fast)
  - Prompt engineering strategies
  - Image editing and composition
  - Aspect ratio selection

### Video Analysis
- `references/video-analysis.md` - Scene detection, temporal understanding
  - YouTube URL processing
  - Timestamp-based queries
  - Video clipping and FPS control
  - Long video optimization

### Video Generation (New)
- `references/video-generation.md` - Text-to-video with Veo
  - Text-to-video generation
  - Image-to-video animation
  - Camera control and framing
  - Native audio generation

### Document Extraction
- `references/document-extraction.md` - PDF processing, structured output
  - Table and form extraction
  - Chart and diagram analysis
  - JSON schema validation
  - Multi-page handling
```

### 5. Create Cross-Reference Map

Add at end of each reference file:

```markdown
---

## Related References

**Current**: [Reference Name]

**Related Capabilities**:
- [Capability 1](./file-1.md) - Brief description
- [Capability 2](./file-2.md) - Brief description
- [Capability 3](./file-3.md) - Brief description

**Back to**: [Skill Overview](../SKILL.md)
```

Example for video-generation.md:

```markdown
---

## Related References

**Current**: Video Generation

**Related Capabilities**:
- [Video Analysis](./video-analysis.md) - Understanding existing videos
- [Image Generation](./image-generation.md) - Creating static images
- [Image Understanding](./vision-understanding.md) - Analyzing reference images

**Back to**: [AI Multimodal Skill](../SKILL.md)
```

### 6. Update Example Commands

Ensure all reference files use latest model recommendations:

**Before**:
```bash
--model gemini-2.5-flash
```

**After** (for image generation):
```bash
--model imagen-4.0-generate-001
```

**After** (for analysis):
```bash
--model gemini-2.5-flash  # or gemini-3-pro-preview for complex reasoning
```

## Todo List

- [ ] Create video-generation.md (completed in Phase 4)
- [ ] Update image-generation.md (completed in Phase 3)
- [ ] Update audio-processing.md with Gemini 3 mentions
- [ ] Update vision-understanding.md with Gemini 3 mentions
- [ ] Add cross-reference to video-analysis.md
- [ ] Update SKILL.md navigation section
- [ ] Add "Related References" sections to all references
- [ ] Update all example commands with latest models
- [ ] Ensure consistent structure across references
- [ ] Verify all internal links work

## Success Criteria

- [ ] video-generation.md fully documented
- [ ] All references mention appropriate new models
- [ ] Cross-references connect related capabilities
- [ ] Navigation section in SKILL.md updated
- [ ] All examples use latest recommended models
- [ ] Consistent structure across all references
- [ ] Progressive disclosure maintained
- [ ] All links functional

## Risk Assessment

**Low Risk**:
- Documentation changes only
- No breaking changes
- Internal consistency checks

**Considerations**:
- Keep references under 600 lines each
- Maintain token efficiency
- Avoid redundancy between SKILL.md and references

## Security Considerations

None - documentation only.

## Next Steps

After completion:
1. Proceed to Phase 7 (Testing & Validation)
2. Review all documentation for consistency
3. Test all code examples
4. Validate all links work
