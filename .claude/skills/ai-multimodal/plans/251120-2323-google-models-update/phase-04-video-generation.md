# Phase 4: Video Generation Integration

**Date**: 2025-11-20
**Priority**: High
**Status**: Pending
**Effort**: High (6-8 hours)

## Context

Video generation is a **completely new capability** for the skill. Currently only video *analysis* exists. Veo 3/3.1 enables text-to-video and image-to-video generation.

**Related Files**:
- `.claude/skills/ai-multimodal/references/video-analysis.md` (analysis only)
- `.claude/skills/ai-multimodal/scripts/gemini_batch_process.py` (needs generation task)
- New file needed: `.claude/skills/ai-multimodal/references/video-generation.md`

## Overview

Implement complete Veo video generation capability including text-to-video, image-to-video, video extension, and frame control features.

## Key Insights

1. **New Capability**: This is not an update, it's a new feature
2. **Native Audio**: Veo generates video with synchronized audio
3. **Two Modes**: Text-to-video and image-to-video (up to 3 reference images)
4. **Fixed Duration**: 8 seconds only (for now)
5. **Preview Status**: veo-3.1 models are preview (API may change)
6. **Multiple Resolutions**: 720p and 1080p support

## Requirements

### Functional
- Text-to-video generation
- Image-to-video generation (1-3 reference images)
- Video extension (continue from existing video)
- Frame control for specific camera movements
- Resolution selection (720p/1080p)
- Aspect ratio support (16:9, 9:16, 1:1)
- Native audio generation
- Safety filters for video content

### Non-Functional
- Progress tracking for long generation (30s-2min)
- Error handling for quota/rate limits
- File size validation
- Output format standardization (MP4)
- Clear pricing/cost warnings

## Architecture

```
Video Generation System
├── references/video-generation.md (new)
│   ├── Text-to-Video
│   ├── Image-to-Video
│   ├── Video Extension
│   ├── Frame Control
│   └── Best Practices
├── scripts/gemini_batch_process.py (updated)
│   ├── generate_video() function (new)
│   ├── --task generate-video (new)
│   └── Model validation
└── SKILL.md (updated)
    └── Video generation quick start
```

## Implementation Steps

### 1. Create Video Generation Reference

Create `.claude/skills/ai-multimodal/references/video-generation.md`:

```markdown
# Video Generation Reference

Comprehensive guide for video creation using Veo models via Gemini API.

## Core Capabilities

- **Text-to-Video**: Generate 8-second videos from text prompts
- **Image-to-Video**: Animate images with text direction
- **Video Extension**: Continue previously generated videos
- **Frame Control**: Precise camera movements and effects
- **Native Audio**: Synchronized audio generation
- **Multiple Resolutions**: 720p and 1080p output
- **Aspect Ratios**: 16:9, 9:16, 1:1

## Models

### Veo 3.1 Preview (Latest)

**veo-3.1-generate-preview** - Latest with advanced controls
- Frame-specific generation
- Up to 3 reference images for image-to-video
- Video extension capability
- Native audio generation
- Resolution: 720p, 1080p
- Duration: 8 seconds at 24fps
- Status: Preview (API may change)
- Updated: September 2025

**veo-3.1-fast-generate-preview** - Speed-optimized
- Optimized for business use cases
- Programmatic ad creation
- Social media content
- Same features as standard but faster
- Status: Preview
- Updated: September 2025

### Veo 3.0 Stable

**veo-3.0-generate-001** - Production-ready
- Native audio generation
- Text-to-video and image-to-video
- 720p and 1080p (16:9 only)
- 8 seconds at 24fps
- Status: Stable
- Updated: July 2025

**veo-3.0-fast-generate-001** - Stable fast variant
- Speed-optimized stable version
- Same reliability as 3.0
- Status: Stable
- Updated: July 2025

## Model Comparison

| Model | Speed | Features | Audio | Status | Best For |
|-------|-------|----------|-------|--------|----------|
| veo-3.1-preview | Medium | All | ✓ | Preview | Latest features |
| veo-3.1-fast | Fast | All | ✓ | Preview | Business/speed |
| veo-3.0-001 | Medium | Standard | ✓ | Stable | Production |
| veo-3.0-fast | Fast | Standard | ✓ | Stable | Production/speed |

## Quick Start

### Text-to-Video

```python
from google import genai
from google.genai import types
import os

client = genai.Client(api_key=os.getenv('GEMINI_API_KEY'))

# Basic generation
response = client.models.generate_video(
    model='veo-3.1-generate-preview',
    prompt='A serene beach at sunset with gentle waves rolling onto the shore',
    config=types.VideoGenerationConfig(
        resolution='1080p',
        aspect_ratio='16:9'
    )
)

# Save video
with open('output.mp4', 'wb') as f:
    f.write(response.video.data)
```

### Image-to-Video

```python
import PIL.Image

# Load reference image
ref_image = PIL.Image.open('beach.jpg')

# Animate the image
response = client.models.generate_video(
    model='veo-3.1-generate-preview',
    prompt='Camera slowly pans across the scene from left to right',
    reference_images=[ref_image],
    config=types.VideoGenerationConfig(
        resolution='1080p'
    )
)
```

### Multiple Reference Images

```python
# Use up to 3 reference images for complex scenes
img1 = PIL.Image.open('foreground.jpg')
img2 = PIL.Image.open('background.jpg')
img3 = PIL.Image.open('subject.jpg')

response = client.models.generate_video(
    model='veo-3.1-generate-preview',
    prompt='Combine these elements into a cohesive animated scene',
    reference_images=[img1, img2, img3],
    config=types.VideoGenerationConfig(
        resolution='1080p',
        aspect_ratio='16:9'
    )
)
```

## Advanced Features

### Video Extension

```python
# Continue from previously generated video
previous_video = open('part1.mp4', 'rb').read()

response = client.models.extend_video(
    model='veo-3.1-generate-preview',
    video=previous_video,
    prompt='The scene transitions to nighttime with stars appearing'
)
```

### Frame Control

```python
# Precise camera movements
response = client.models.generate_video(
    model='veo-3.1-generate-preview',
    prompt='A mountain landscape',
    config=types.VideoGenerationConfig(
        resolution='1080p',
        camera_motion='zoom_in',  # Options: zoom_in, zoom_out, pan_left, pan_right, tilt_up, tilt_down, static
        motion_speed='slow'  # Options: slow, medium, fast
    )
)
```

## Prompt Engineering

### Effective Video Prompts

**Structure**:
1. **Subject**: What's in the scene
2. **Action**: What's happening
3. **Camera**: How it's filmed
4. **Style**: Visual treatment
5. **Timing**: Pacing details

**Example**:
```
"A hummingbird [subject] hovers near a red flower, then flies away [action].
Slow-motion close-up shot [camera] with vibrant colors and soft focus background [style].
Gentle, peaceful pacing [timing]."
```

### Action Verbs

**Movement**:
- "walks", "runs", "flies", "swims", "dances"
- "rotates", "spins", "rolls", "bounces"
- "emerges", "disappears", "transforms"

**Camera**:
- "zoom in on", "pull back from", "follow"
- "orbit around", "track alongside"
- "tilt up to reveal", "pan across"

**Transitions**:
- "gradually changes from... to..."
- "morphs into", "dissolves into"
- "cuts to", "fades to"

### Timing Control

```python
# Explicit timing in prompt
prompt = '''
0-2s: Close-up of a seed in soil
2-4s: Time-lapse of sprout emerging
4-6s: Growing into a small plant
6-8s: Zoom out to show garden context
'''
```

## Configuration Options

### Resolution

```python
config = types.VideoGenerationConfig(
    resolution='1080p'  # Options: 720p, 1080p
)
```

**Considerations**:
- 1080p: Higher quality, longer generation time, larger file
- 720p: Faster generation, smaller file, good for drafts

### Aspect Ratios

```python
config = types.VideoGenerationConfig(
    aspect_ratio='16:9'  # Options: 16:9, 9:16, 1:1
)
```

**Use Cases**:
- 16:9: Landscape, YouTube, traditional video
- 9:16: Mobile, TikTok, Instagram Stories
- 1:1: Square, Instagram feed, versatile

### Audio Control

```python
config = types.VideoGenerationConfig(
    include_audio=True  # Default: True
)
```

Native audio is generated automatically and synchronized with video content.

## Best Practices

### 1. Prompt Quality

**Be specific**:
- ❌ "A person walking"
- ✅ "A young woman in a red coat walking through a park in autumn"

**Include motion**:
- ❌ "A city street"
- ✅ "A busy city street with cars passing and people crossing"

**Specify camera**:
- ❌ "A mountain"
- ✅ "Aerial drone shot slowly ascending over a snow-capped mountain"

### 2. Reference Images

**Quality**:
- Use high-resolution images (1080p+)
- Clear, well-lit subjects
- Minimal motion blur

**Composition**:
- Match desired final aspect ratio
- Leave room for motion/movement
- Consider camera angle in prompt

### 3. Performance Optimization

**Generation Time**:
- 720p: ~30-60 seconds
- 1080p: ~60-120 seconds
- Fast models: 30-50% faster

**Strategies**:
- Use 720p for iteration/drafts
- Use fast models for rapid feedback
- Batch multiple requests
- Use async processing for UI responsiveness

## Common Use Cases

### 1. Product Demos

```python
response = client.models.generate_video(
    model='veo-3.0-fast-generate-001',
    prompt='''
    Professional product video:
    - Sleek smartphone rotating on a pedestal
    - Clean white background with soft shadows
    - Slow 360-degree rotation
    - Spotlight highlighting premium design
    - Modern, minimalist aesthetic
    ''',
    config=types.VideoGenerationConfig(
        resolution='1080p',
        aspect_ratio='1:1'
    )
)
```

### 2. Social Media Content

```python
response = client.models.generate_video(
    model='veo-3.1-fast-generate-preview',
    prompt='''
    Trendy social media clip:
    - Text overlay "NEW ARRIVAL" appears
    - Fashion product showcase
    - Quick cuts and dynamic camera
    - Vibrant colors, high energy
    - Upbeat pacing
    ''',
    config=types.VideoGenerationConfig(
        resolution='1080p',
        aspect_ratio='9:16'  # Mobile
    )
)
```

### 3. Explainer Animations

```python
response = client.models.generate_video(
    model='veo-3.1-generate-preview',
    prompt='''
    Educational animation:
    - Simple diagram illustrating data flow
    - Arrows and icons animating in sequence
    - Clean, clear visual hierarchy
    - Smooth transitions between steps
    - Professional corporate style
    ''',
    config=types.VideoGenerationConfig(
        resolution='720p',
        aspect_ratio='16:9'
    )
)
```

## Safety & Content Policy

### Safety Settings

```python
config = types.VideoGenerationConfig(
    safety_settings=[
        types.SafetySetting(
            category=types.HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
            threshold=types.HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE
        )
    ]
)
```

### Prohibited Content

- Violence, gore, harm
- Sexually explicit content
- Hate speech, harassment
- Copyrighted characters/brands
- Real people (without consent)
- Misleading/deceptive content

## Limitations

- **Duration**: Fixed 8 seconds (as of Sept 2025)
- **Frame Rate**: 24fps only
- **File Size**: ~5-20MB per video
- **Generation Time**: 30s-2min depending on resolution
- **Reference Images**: Max 3 images
- **Preview Status**: API may change (3.1 models)
- **Audio**: Cannot upload custom audio (native only)
- **No real-time**: Pre-generation required

## Troubleshooting

### Long Generation Times

```python
import time

# Track generation progress
start = time.time()
response = client.models.generate_video(...)
duration = time.time() - start
print(f"Generated in {duration:.1f}s")
```

**Expected times**:
- Fast models + 720p: 30-45s
- Standard models + 720p: 45-90s
- Fast models + 1080p: 45-60s
- Standard models + 1080p: 60-120s

### Safety Filter Blocking

```python
try:
    response = client.models.generate_video(...)
except Exception as e:
    if 'safety' in str(e).lower():
        print("Video blocked by safety filters")
        # Modify prompt and retry
```

### Quota Exceeded

```python
# Implement exponential backoff
import time

def generate_with_retry(model, prompt, max_retries=3):
    for attempt in range(max_retries):
        try:
            return client.models.generate_video(model=model, prompt=prompt)
        except Exception as e:
            if '429' in str(e):  # Rate limit
                wait = 2 ** attempt
                print(f"Rate limited, waiting {wait}s...")
                time.sleep(wait)
            else:
                raise
    raise Exception("Max retries exceeded")
```

## Cost Estimation

**Pricing**: TBD (preview models)

**Estimated based on compute**:
- Fast + 720p: ~$0.05-$0.10 per video
- Standard + 1080p: ~$0.15-$0.25 per video

**Monitor**: https://ai.google.dev/pricing

## Resources

- [Veo API Docs](https://ai.google.dev/gemini-api/docs/video)
- [Video Generation Guide](https://ai.google.dev/gemini-api/docs/video#model-versions)
- [Content Policy](https://ai.google.dev/gemini-api/docs/safety)
- [Get API Key](https://aistudio.google.com/apikey)
```

### 2. Update gemini_batch_process.py

Add video generation task support (pseudo-code structure):

```python
def generate_video(client, prompt, model, output_path, config):
    """Generate video from text prompt using Veo models."""
    # Validate model is Veo
    if not model.startswith('veo-'):
        raise ValueError(f"Video generation requires Veo model, got {model}")

    # Generate video
    response = client.models.generate_video(
        model=model,
        prompt=prompt,
        config=config
    )

    # Save video
    with open(output_path, 'wb') as f:
        f.write(response.video.data)

    return output_path

# Add to CLI argument parser
parser.add_argument('--task', choices=['transcribe', 'analyze', 'extract', 'generate', 'generate-video'])
parser.add_argument('--resolution', choices=['720p', '1080p'], default='1080p')
parser.add_argument('--aspect-ratio', choices=['16:9', '9:16', '1:1'], default='16:9')
```

### 3. Update SKILL.md Quick Start

Add video generation example after line 167.

## Todo List

- [ ] Create complete video-generation.md reference file
- [ ] Document all 4 Veo models with comparison matrix
- [ ] Add text-to-video examples
- [ ] Add image-to-video examples (1-3 images)
- [ ] Add video extension capability
- [ ] Add frame control examples
- [ ] Document prompt engineering for video
- [ ] Add configuration options (resolution, aspect ratio)
- [ ] Create common use case examples
- [ ] Add safety and content policy section
- [ ] Document limitations and constraints
- [ ] Add troubleshooting section
- [ ] Update gemini_batch_process.py with generate_video()
- [ ] Add --task generate-video CLI option
- [ ] Add video-specific CLI arguments
- [ ] Update SKILL.md with video gen quick start
- [ ] Add video generation to capability matrix

## Success Criteria

- [ ] Complete video generation reference documentation
- [ ] Working text-to-video generation
- [ ] Working image-to-video generation
- [ ] CLI supports video generation task
- [ ] Examples are copy-pasteable and functional
- [ ] Safety filters implemented
- [ ] Error handling for rate limits
- [ ] Progress tracking for long generation
- [ ] Output format standardized (MP4)

## Risk Assessment

**High Risk**:
- Preview API may change without notice
- Pricing unknown (TBD)
- Generation times may exceed user expectations
- Quota limits not documented

**Mitigation**:
- Clearly mark preview status
- Add retry logic with backoff
- Show progress indicators
- Provide cost warnings
- Fall back to stable models

## Security Considerations

- Safety filters mandatory (cannot disable)
- Content policy enforcement
- No generation of real people without consent
- No copyrighted content
- Rate limiting to prevent abuse

## Next Steps

After completion:
1. Proceed to Phase 5 (Script Enhancement)
2. Test video generation end-to-end
3. Validate file outputs are playable
4. Measure actual generation times
