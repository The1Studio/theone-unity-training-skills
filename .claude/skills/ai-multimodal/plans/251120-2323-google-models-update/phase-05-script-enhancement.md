# Phase 5: Script Enhancement

**Date**: 2025-11-20
**Priority**: High
**Status**: Pending
**Effort**: Medium (4-5 hours)

## Context

Update `gemini_batch_process.py` to support new models and video generation capability. Current script supports audio/image/video analysis and image generation only.

**Related Files**:
- `.claude/skills/ai-multimodal/scripts/gemini_batch_process.py:1-344`
- `.claude/skills/ai-multimodal/scripts/tests/test_gemini_batch_process.py`

## Overview

Extend batch processing script with Imagen 4 support, Veo video generation, model validation, and environment variable integration.

## Key Insights

1. **Two Generation APIs**: `generate_images()` for Imagen 4 vs `generate_content()` for Flash Image
2. **New Task Type**: `generate-video` requires different API calls
3. **Model Validation**: Prevent invalid model/task combinations
4. **Env Var Integration**: Read IMAGE_GEN_MODEL, VIDEO_GEN_MODEL, MULTIMODAL_MODEL
5. **Backward Compatibility**: Existing --model flag overrides env vars

## Requirements

### Functional
- Support all new model IDs (Imagen 4, Veo, Gemini 3)
- Add `generate-video` task type
- Use Imagen 4 API (`generate_images()`)
- Read model from environment variables
- Validate model + task compatibility
- Progress tracking for video generation
- Maintain backward compatibility

### Non-Functional
- Clear error messages for invalid combinations
- Consistent CLI interface
- Dry-run support for new tasks
- Comprehensive logging
- Test coverage for new features

## Architecture

```
gemini_batch_process.py
├── API Key Detection (existing)
├── Model Selection (enhanced)
│   ├── Read from env vars (new)
│   ├── CLI override (existing)
│   └── Smart defaults (new)
├── Model Validation (new)
│   ├── validate_model_task_combination()
│   └── get_supported_models()
├── Task Handlers (enhanced)
│   ├── generate_image() - updated for Imagen 4
│   ├── generate_video() - new
│   ├── analyze_media() - updated models
│   └── extract_document() - updated models
└── CLI Arguments (enhanced)
    ├── --resolution (new)
    ├── --aspect-ratio (new)
    ├── --reference-images (new)
    └── --duration (new)
```

## Implementation Steps

### 1. Add Environment Variable Loading

After line 83 (find_api_key function), add model detection:

```python
def get_default_model(task: str) -> str:
    """Get default model for task from environment or fallback.

    Priority:
    1. Environment variable for specific capability
    2. Legacy GEMINI_MODEL variable
    3. Hard-coded defaults
    """
    if task == 'generate' and not args.files:  # Image generation
        model = os.getenv('IMAGE_GEN_MODEL')
        if model:
            return model
        # Fallback to legacy
        model = os.getenv('GEMINI_IMAGE_GEN_MODEL')
        if model:
            return model
        return 'imagen-4.0-generate-001'  # New default

    elif task == 'generate-video':
        model = os.getenv('VIDEO_GEN_MODEL')
        if model:
            return model
        return 'veo-3.1-generate-preview'  # New default

    elif task in ['analyze', 'transcribe', 'extract']:
        model = os.getenv('MULTIMODAL_MODEL')
        if model:
            return model
        # Fallback to legacy
        model = os.getenv('GEMINI_MODEL')
        if model:
            return model
        return 'gemini-2.5-flash'  # Existing default

    return 'gemini-2.5-flash'
```

### 2. Add Model Validation

```python
def validate_model_task_combination(model: str, task: str) -> None:
    """Validate model is compatible with task.

    Raises:
        ValueError: If combination is invalid
    """
    # Video generation requires Veo
    if task == 'generate-video':
        if not model.startswith('veo-'):
            raise ValueError(
                f"Video generation requires Veo model, got '{model}'\n"
                f"Valid models: veo-3.1-generate-preview, veo-3.1-fast-generate-preview, "
                f"veo-3.0-generate-001, veo-3.0-fast-generate-001"
            )

    # Image generation models
    if task == 'generate' and not args.files:
        valid_image_models = [
            'imagen-4.0-generate-001',
            'imagen-4.0-ultra-generate-001',
            'imagen-4.0-fast-generate-001',
            'gemini-3-pro-image-preview',
            'gemini-2.5-flash-image',  # Legacy
        ]
        if model not in valid_image_models:
            raise ValueError(
                f"Image generation requires Imagen/Gemini image model, got '{model}'\n"
                f"Valid models: {', '.join(valid_image_models)}"
            )

    # Segmentation requires 2.5+
    if hasattr(args, 'segmentation') and args.segmentation:
        if not (model.startswith('gemini-2.5') or model.startswith('gemini-3')):
            raise ValueError(
                f"Segmentation requires Gemini 2.5+ model, got '{model}'"
            )

    # Object detection requires 2.0+
    if hasattr(args, 'detect_objects') and args.detect_objects:
        if model.startswith('gemini-1.'):
            raise ValueError(
                f"Object detection requires Gemini 2.0+ model, got '{model}'"
            )

def get_supported_models() -> Dict[str, List[str]]:
    """Return all supported models by capability."""
    return {
        'image_generation': [
            'imagen-4.0-generate-001',
            'imagen-4.0-ultra-generate-001',
            'imagen-4.0-fast-generate-001',
            'gemini-3-pro-image-preview',
            'gemini-2.5-flash-image',
        ],
        'video_generation': [
            'veo-3.1-generate-preview',
            'veo-3.1-fast-generate-preview',
            'veo-3.0-generate-001',
            'veo-3.0-fast-generate-001',
        ],
        'multimodal_analysis': [
            'gemini-3-pro-preview',
            'gemini-2.5-flash',
            'gemini-2.5-pro',
            'gemini-2.5-flash-lite',
        ]
    }
```

### 3. Update Image Generation Handler

Replace existing generate function with Imagen 4 support:

```python
def generate_image(client, prompt: str, model: str, output_path: Path, config: Dict[str, Any]) -> str:
    """Generate image using Imagen 4 or legacy Flash Image."""

    # Determine which API to use
    if model.startswith('imagen-4'):
        # Use new Imagen 4 API
        from google.genai import types

        gen_config = types.ImageGenerationConfig(
            number_of_images=config.get('num_images', 1),
            aspect_ratio=config.get('aspect_ratio', '1:1'),
            size=config.get('size', '1K')
        )

        response = client.models.generate_images(
            model=model,
            prompt=prompt,
            config=gen_config
        )

        # Save images
        for i, image in enumerate(response.images):
            output_file = output_path.parent / f"{output_path.stem}_{i}{output_path.suffix}"
            with open(output_file, 'wb') as f:
                f.write(image.data)
            print(f"✓ Saved: {output_file}")

        return str(output_path)

    else:
        # Use legacy Flash Image API (backward compat)
        from google.genai import types

        gen_config = types.GenerateContentConfig(
            response_modalities=['Image'],
            image_config=types.ImageConfig(
                aspect_ratio=config.get('aspect_ratio', '1:1')
            )
        )

        response = client.models.generate_content(
            model=model,
            contents=prompt,
            config=gen_config
        )

        # Save from content parts
        for i, part in enumerate(response.candidates[0].content.parts):
            if part.inline_data:
                output_file = output_path.parent / f"{output_path.stem}_{i}{output_path.suffix}"
                with open(output_file, 'wb') as f:
                    f.write(part.inline_data.data)
                print(f"✓ Saved: {output_file}")

        return str(output_path)
```

### 4. Add Video Generation Handler

New function for video generation:

```python
def generate_video(client, prompt: str, model: str, output_path: Path, config: Dict[str, Any]) -> str:
    """Generate video using Veo models.

    Args:
        client: Gemini API client
        prompt: Text prompt for video generation
        model: Veo model ID
        output_path: Where to save video
        config: Generation config (resolution, aspect_ratio, etc)

    Returns:
        Path to generated video
    """
    from google.genai import types
    import time

    # Validate model
    if not model.startswith('veo-'):
        raise ValueError(f"Video generation requires Veo model, got {model}")

    # Build config
    gen_config = types.VideoGenerationConfig(
        resolution=config.get('resolution', '1080p'),
        aspect_ratio=config.get('aspect_ratio', '16:9'),
        include_audio=config.get('include_audio', True)
    )

    # Handle reference images if provided
    reference_images = config.get('reference_images', [])
    if reference_images:
        import PIL.Image
        images = [PIL.Image.open(img) for img in reference_images]
    else:
        images = None

    # Generate with progress tracking
    print(f"🎬 Generating video with {model}...")
    print(f"   Resolution: {gen_config.resolution}")
    print(f"   Aspect: {gen_config.aspect_ratio}")

    start = time.time()

    try:
        response = client.models.generate_video(
            model=model,
            prompt=prompt,
            reference_images=images,
            config=gen_config
        )

        duration = time.time() - start

        # Save video
        with open(output_path, 'wb') as f:
            f.write(response.video.data)

        # Get file size
        file_size = output_path.stat().st_size / (1024 * 1024)  # MB

        print(f"✓ Generated in {duration:.1f}s")
        print(f"✓ File size: {file_size:.2f} MB")
        print(f"✓ Saved: {output_path}")

        return str(output_path)

    except Exception as e:
        duration = time.time() - start
        print(f"✗ Failed after {duration:.1f}s: {e}")
        raise
```

### 5. Update CLI Arguments

Add new arguments for video/image generation:

```python
# Update task choices
parser.add_argument(
    '--task',
    choices=['transcribe', 'analyze', 'extract', 'generate', 'generate-video'],
    required=True,
    help='Task to perform'
)

# Add video-specific options
parser.add_argument(
    '--resolution',
    choices=['720p', '1080p'],
    default='1080p',
    help='Video resolution (video generation only)'
)

parser.add_argument(
    '--aspect-ratio',
    default='16:9',
    help='Aspect ratio for image/video generation (e.g., 16:9, 1:1, 9:16)'
)

parser.add_argument(
    '--reference-images',
    nargs='+',
    help='Reference images for video generation (max 3)'
)

parser.add_argument(
    '--num-images',
    type=int,
    default=1,
    help='Number of images to generate (1-4)'
)

parser.add_argument(
    '--size',
    choices=['1K', '2K'],
    default='1K',
    help='Image size for Imagen 4 (1K or 2K)'
)
```

### 6. Update Main Function

Integrate new handlers:

```python
def main():
    args = parse_args()

    # Find API key
    api_key = find_api_key()
    if not api_key:
        print("Error: GEMINI_API_KEY not found")
        sys.exit(1)

    # Initialize client
    client = genai.Client(api_key=api_key)

    # Get model (env var or CLI override)
    if args.model:
        model = args.model
    else:
        model = get_default_model(args.task)

    # Validate combination
    try:
        validate_model_task_combination(model, args.task)
    except ValueError as e:
        print(f"Error: {e}")
        sys.exit(1)

    # Route to handler
    if args.task == 'generate-video':
        config = {
            'resolution': args.resolution,
            'aspect_ratio': args.aspect_ratio,
            'reference_images': args.reference_images or [],
            'include_audio': True
        }
        generate_video(client, args.prompt, model, args.output, config)

    elif args.task == 'generate':
        config = {
            'num_images': args.num_images,
            'aspect_ratio': args.aspect_ratio,
            'size': args.size
        }
        generate_image(client, args.prompt, model, args.output, config)

    # ... existing task handlers
```

## Todo List

- [ ] Add get_default_model() function with env var support
- [ ] Add validate_model_task_combination() function
- [ ] Add get_supported_models() helper
- [ ] Update generate_image() for Imagen 4 API
- [ ] Add generate_video() handler
- [ ] Add CLI arguments (resolution, aspect-ratio, etc)
- [ ] Update main() to route to new handlers
- [ ] Add progress tracking for video generation
- [ ] Add comprehensive error messages
- [ ] Update --help text with examples
- [ ] Add dry-run support for new tasks
- [ ] Update tests for new functionality
- [ ] Add integration tests for Imagen 4
- [ ] Add integration tests for Veo

## Success Criteria

- [ ] All new models accessible via CLI
- [ ] Environment variables properly loaded
- [ ] Model validation prevents invalid combinations
- [ ] Video generation works end-to-end
- [ ] Imagen 4 generation works end-to-end
- [ ] Backward compatibility maintained
- [ ] Clear error messages for misconfigurations
- [ ] Tests pass for all new features
- [ ] Progress tracking works for long operations

## Risk Assessment

**Medium Risk**:
- API changes in preview models (Veo 3.1, Gemini 3)
- Different response structures between APIs
- Validation logic may be incomplete

**Mitigation**:
- Comprehensive error handling
- Clear error messages with model suggestions
- Fallback to stable models
- Extensive testing

## Security Considerations

- API key handling unchanged (secure)
- Input validation for file paths
- Validate reference image file types
- File size limits for outputs

## Next Steps

After completion:
1. Proceed to Phase 6 (Reference Documentation)
2. Test all new CLI options
3. Validate error handling
4. Update help text and examples
