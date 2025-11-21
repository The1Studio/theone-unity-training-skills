# Phase 7: Testing & Validation

**Date**: 2025-11-20
**Priority**: High
**Status**: Pending
**Effort**: Medium (4-5 hours)

## Context

Add comprehensive test coverage for new models and capabilities. Current tests only cover existing audio/image/video analysis and legacy image generation.

**Related Files**:
- `.claude/skills/ai-multimodal/scripts/tests/test_gemini_batch_process.py`
- `.claude/skills/ai-multimodal/scripts/tests/requirements.txt`
- `.claude/skills/ai-multimodal/scripts/requirements.txt`

## Overview

Expand test suite to cover Imagen 4, Veo video generation, Gemini 3, environment variable loading, and model validation.

## Key Insights

1. **API Testing**: May require mocking (preview models)
2. **Integration Tests**: Need real API calls (optional)
3. **Unit Tests**: Pure validation logic (always)
4. **Cost Awareness**: Video generation tests are expensive
5. **CI/CD Ready**: Tests should run without API key

## Requirements

### Functional
- Test environment variable loading (all variants)
- Test model validation logic
- Test Imagen 4 API calls (mocked + optional real)
- Test Veo API calls (mocked + optional real)
- Test model selection defaults
- Test invalid model/task combinations
- Test CLI argument parsing
- Test backward compatibility

### Non-Functional
- Fast unit tests (<1s each)
- Optional integration tests (with flag)
- No API key required for unit tests
- Clear test output
- Good coverage (>80%)

## Architecture

```
tests/
├── test_gemini_batch_process.py (updated)
│   ├── Test Environment Variables
│   ├── Test Model Validation
│   ├── Test Imagen 4 Integration
│   ├── Test Veo Integration
│   └── Test Backward Compatibility
├── test_model_selection.py (new)
│   ├── Test get_default_model()
│   ├── Test validate_model_task_combination()
│   └── Test get_supported_models()
└── conftest.py (new)
    └── Shared fixtures and mocks
```

## Implementation Steps

### 1. Create conftest.py

Add shared test fixtures:

```python
"""Shared test fixtures for ai-multimodal tests."""
import pytest
from unittest.mock import Mock, MagicMock
import os

@pytest.fixture
def mock_client():
    """Mock Gemini API client."""
    client = MagicMock()
    return client

@pytest.fixture
def mock_env_vars(monkeypatch):
    """Mock environment variables."""
    def _set_vars(**kwargs):
        for key, value in kwargs.items():
            if value is None:
                monkeypatch.delenv(key, raising=False)
            else:
                monkeypatch.setenv(key, value)
    return _set_vars

@pytest.fixture
def temp_output_dir(tmp_path):
    """Create temporary output directory."""
    output_dir = tmp_path / "output"
    output_dir.mkdir()
    return output_dir

@pytest.fixture(autouse=True)
def cleanup_env(monkeypatch):
    """Clean up environment variables after each test."""
    yield
    # Remove all model env vars
    for var in ['IMAGE_GEN_MODEL', 'VIDEO_GEN_MODEL', 'MULTIMODAL_MODEL',
                'GEMINI_MODEL', 'GEMINI_IMAGE_GEN_MODEL']:
        monkeypatch.delenv(var, raising=False)
```

### 2. Create test_model_selection.py

New file for model selection logic:

```python
"""Tests for model selection and validation."""
import pytest
from gemini_batch_process import (
    get_default_model,
    validate_model_task_combination,
    get_supported_models
)

class TestGetDefaultModel:
    """Test default model selection logic."""

    def test_image_generation_default(self, mock_env_vars):
        """Should default to Imagen 4 for image generation."""
        mock_env_vars()  # Clear env
        model = get_default_model('generate')
        assert model == 'imagen-4.0-generate-001'

    def test_image_generation_env_override(self, mock_env_vars):
        """Should use IMAGE_GEN_MODEL env var."""
        mock_env_vars(IMAGE_GEN_MODEL='imagen-4.0-ultra-generate-001')
        model = get_default_model('generate')
        assert model == 'imagen-4.0-ultra-generate-001'

    def test_video_generation_default(self, mock_env_vars):
        """Should default to Veo 3.1 for video generation."""
        mock_env_vars()
        model = get_default_model('generate-video')
        assert model == 'veo-3.1-generate-preview'

    def test_video_generation_env_override(self, mock_env_vars):
        """Should use VIDEO_GEN_MODEL env var."""
        mock_env_vars(VIDEO_GEN_MODEL='veo-3.0-generate-001')
        model = get_default_model('generate-video')
        assert model == 'veo-3.0-generate-001'

    def test_analysis_default(self, mock_env_vars):
        """Should default to Gemini 2.5 Flash for analysis."""
        mock_env_vars()
        model = get_default_model('analyze')
        assert model == 'gemini-2.5-flash'

    def test_analysis_env_override(self, mock_env_vars):
        """Should use MULTIMODAL_MODEL env var."""
        mock_env_vars(MULTIMODAL_MODEL='gemini-3-pro-preview')
        model = get_default_model('analyze')
        assert model == 'gemini-3-pro-preview'

    def test_legacy_gemini_model_fallback(self, mock_env_vars):
        """Should fall back to GEMINI_MODEL for analysis."""
        mock_env_vars(GEMINI_MODEL='gemini-2.5-pro')
        model = get_default_model('analyze')
        assert model == 'gemini-2.5-pro'

class TestValidateModelTaskCombination:
    """Test model/task validation logic."""

    def test_video_generation_requires_veo(self):
        """Video generation should only accept Veo models."""
        # Valid
        validate_model_task_combination('veo-3.1-generate-preview', 'generate-video')
        validate_model_task_combination('veo-3.0-generate-001', 'generate-video')

        # Invalid
        with pytest.raises(ValueError, match='requires Veo model'):
            validate_model_task_combination('gemini-2.5-flash', 'generate-video')

        with pytest.raises(ValueError, match='requires Veo model'):
            validate_model_task_combination('imagen-4.0-generate-001', 'generate-video')

    def test_image_generation_model_validation(self):
        """Image generation should accept Imagen/Gemini image models."""
        # Valid Imagen 4
        validate_model_task_combination('imagen-4.0-generate-001', 'generate')
        validate_model_task_combination('imagen-4.0-ultra-generate-001', 'generate')
        validate_model_task_combination('imagen-4.0-fast-generate-001', 'generate')

        # Valid Gemini
        validate_model_task_combination('gemini-3-pro-image-preview', 'generate')
        validate_model_task_combination('gemini-2.5-flash-image', 'generate')

        # Invalid
        with pytest.raises(ValueError, match='requires Imagen/Gemini image model'):
            validate_model_task_combination('veo-3.0-generate-001', 'generate')

        with pytest.raises(ValueError, match='requires Imagen/Gemini image model'):
            validate_model_task_combination('gemini-2.5-flash', 'generate')

    def test_analysis_accepts_all_gemini(self):
        """Analysis should accept any Gemini model."""
        validate_model_task_combination('gemini-3-pro-preview', 'analyze')
        validate_model_task_combination('gemini-2.5-flash', 'analyze')
        validate_model_task_combination('gemini-2.5-pro', 'analyze')

class TestGetSupportedModels:
    """Test supported models listing."""

    def test_returns_all_capabilities(self):
        """Should return models for all capabilities."""
        models = get_supported_models()
        assert 'image_generation' in models
        assert 'video_generation' in models
        assert 'multimodal_analysis' in models

    def test_imagen_4_models_included(self):
        """Should include all Imagen 4 variants."""
        models = get_supported_models()
        assert 'imagen-4.0-generate-001' in models['image_generation']
        assert 'imagen-4.0-ultra-generate-001' in models['image_generation']
        assert 'imagen-4.0-fast-generate-001' in models['image_generation']

    def test_veo_models_included(self):
        """Should include all Veo variants."""
        models = get_supported_models()
        assert 'veo-3.1-generate-preview' in models['video_generation']
        assert 'veo-3.0-generate-001' in models['video_generation']

    def test_gemini_3_models_included(self):
        """Should include Gemini 3 models."""
        models = get_supported_models()
        assert 'gemini-3-pro-preview' in models['multimodal_analysis']
```

### 3. Update test_gemini_batch_process.py

Add tests for new functionality:

```python
"""Tests for new model capabilities."""
import pytest
from unittest.mock import Mock, patch, MagicMock
from gemini_batch_process import generate_image, generate_video

class TestImagenGeneration:
    """Test Imagen 4 image generation."""

    @patch('gemini_batch_process.genai.Client')
    def test_imagen4_uses_generate_images_api(self, mock_client_class, temp_output_dir):
        """Imagen 4 should use generate_images() API."""
        mock_client = MagicMock()
        mock_response = MagicMock()
        mock_response.images = [MagicMock(data=b'fake_image_data')]
        mock_client.models.generate_images.return_value = mock_response
        mock_client_class.return_value = mock_client

        output_path = temp_output_dir / "test.png"
        config = {'num_images': 1, 'aspect_ratio': '16:9', 'size': '1K'}

        generate_image(mock_client, "test prompt", "imagen-4.0-generate-001", output_path, config)

        # Should call generate_images, not generate_content
        mock_client.models.generate_images.assert_called_once()
        mock_client.models.generate_content.assert_not_called()

    @patch('gemini_batch_process.genai.Client')
    def test_flash_image_uses_generate_content_api(self, mock_client_class, temp_output_dir):
        """Legacy Flash Image should use generate_content() API."""
        mock_client = MagicMock()
        mock_response = MagicMock()
        mock_part = MagicMock()
        mock_part.inline_data.data = b'fake_image_data'
        mock_response.candidates[0].content.parts = [mock_part]
        mock_client.models.generate_content.return_value = mock_response
        mock_client_class.return_value = mock_client

        output_path = temp_output_dir / "test.png"
        config = {'aspect_ratio': '1:1'}

        generate_image(mock_client, "test prompt", "gemini-2.5-flash-image", output_path, config)

        # Should call generate_content, not generate_images
        mock_client.models.generate_content.assert_called_once()
        mock_client.models.generate_images.assert_not_called()

class TestVideoGeneration:
    """Test Veo video generation."""

    @patch('gemini_batch_process.genai.Client')
    def test_veo_generates_video(self, mock_client_class, temp_output_dir):
        """Veo should generate video file."""
        mock_client = MagicMock()
        mock_response = MagicMock()
        mock_response.video.data = b'fake_video_data'
        mock_client.models.generate_video.return_value = mock_response
        mock_client_class.return_value = mock_client

        output_path = temp_output_dir / "test.mp4"
        config = {'resolution': '1080p', 'aspect_ratio': '16:9'}

        result = generate_video(mock_client, "test prompt", "veo-3.1-generate-preview", output_path, config)

        mock_client.models.generate_video.assert_called_once()
        assert output_path.exists()
        assert result == str(output_path)

    def test_non_veo_model_raises_error(self, mock_client, temp_output_dir):
        """Non-Veo models should raise ValueError."""
        output_path = temp_output_dir / "test.mp4"
        config = {}

        with pytest.raises(ValueError, match='requires Veo model'):
            generate_video(mock_client, "test", "gemini-2.5-flash", output_path, config)

class TestBackwardCompatibility:
    """Test that existing functionality still works."""

    def test_legacy_model_flag_works(self, mock_env_vars):
        """CLI --model flag should override env vars."""
        mock_env_vars(IMAGE_GEN_MODEL='imagen-4.0-ultra-generate-001')

        # Simulate CLI override
        cli_model = 'gemini-2.5-flash-image'

        # Validation should pass (backward compat)
        validate_model_task_combination(cli_model, 'generate')

    def test_existing_tasks_unchanged(self):
        """Existing tasks should still work."""
        # These should not raise
        validate_model_task_combination('gemini-2.5-flash', 'transcribe')
        validate_model_task_combination('gemini-2.5-flash', 'analyze')
        validate_model_task_combination('gemini-2.5-flash', 'extract')
```

### 4. Add Integration Tests (Optional)

Create `test_integration.py` (only runs with --integration flag):

```python
"""Integration tests requiring real API calls."""
import pytest
import os

# Skip if no API key or --integration flag
pytestmark = pytest.mark.skipif(
    not os.getenv('GEMINI_API_KEY') or not os.getenv('RUN_INTEGRATION_TESTS'),
    reason="Integration tests require GEMINI_API_KEY and RUN_INTEGRATION_TESTS=1"
)

class TestImagenIntegration:
    """Real Imagen 4 API tests."""

    def test_imagen_standard_generation(self, temp_output_dir):
        """Test actual Imagen 4 generation."""
        from gemini_batch_process import generate_image
        from google import genai

        client = genai.Client(api_key=os.getenv('GEMINI_API_KEY'))
        output = temp_output_dir / "imagen_test.png"

        result = generate_image(
            client,
            "A simple red circle on white background",
            "imagen-4.0-fast-generate-001",  # Use fast for cost
            output,
            {'num_images': 1, 'aspect_ratio': '1:1', 'size': '1K'}
        )

        assert output.exists()
        assert output.stat().st_size > 1000  # Reasonable file size

class TestVeoIntegration:
    """Real Veo API tests."""

    @pytest.mark.slow
    def test_veo_text_to_video(self, temp_output_dir):
        """Test actual Veo video generation (slow/expensive)."""
        from gemini_batch_process import generate_video
        from google import genai

        client = genai.Client(api_key=os.getenv('GEMINI_API_KEY'))
        output = temp_output_dir / "veo_test.mp4"

        result = generate_video(
            client,
            "A simple animation of a bouncing ball",
            "veo-3.0-fast-generate-001",  # Use stable fast
            output,
            {'resolution': '720p', 'aspect_ratio': '16:9'}
        )

        assert output.exists()
        assert output.stat().st_size > 100000  # Reasonable video size
```

### 5. Update requirements.txt

Add testing dependencies:

```
# Testing
pytest>=8.0.0
pytest-cov>=4.1.0
pytest-mock>=3.12.0
```

### 6. Create pytest.ini

Configure pytest:

```ini
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts =
    -v
    --strict-markers
    --cov=scripts
    --cov-report=term-missing
    --cov-report=html

markers =
    slow: marks tests as slow (deselect with '-m "not slow"')
    integration: marks tests as integration tests (require API key)
```

## Todo List

- [ ] Create conftest.py with shared fixtures
- [ ] Create test_model_selection.py
- [ ] Add TestGetDefaultModel tests
- [ ] Add TestValidateModelTaskCombination tests
- [ ] Add TestGetSupportedModels tests
- [ ] Update test_gemini_batch_process.py
- [ ] Add TestImagenGeneration tests
- [ ] Add TestVideoGeneration tests
- [ ] Add TestBackwardCompatibility tests
- [ ] Create test_integration.py (optional)
- [ ] Update requirements.txt with test dependencies
- [ ] Create pytest.ini configuration
- [ ] Run test suite and verify >80% coverage
- [ ] Document how to run integration tests

## Success Criteria

- [ ] All unit tests passing
- [ ] Code coverage >80%
- [ ] Model validation fully tested
- [ ] Environment variable loading tested
- [ ] Imagen 4 API usage tested
- [ ] Veo API usage tested
- [ ] Backward compatibility verified
- [ ] Integration tests available (optional)
- [ ] Tests run without API key (unit tests)
- [ ] Clear documentation for running tests

## Risk Assessment

**Low Risk**:
- Unit tests isolated and fast
- No API dependencies for core tests
- Mock-based testing

**Considerations**:
- Integration tests are expensive (video generation)
- Preview APIs may change (adjust mocks)
- Need clear separation of unit vs integration

## Security Considerations

- No API keys in test code
- Use mocks for sensitive operations
- Integration tests optional (flag-gated)

## Next Steps

After completion:
1. Run full test suite
2. Generate coverage report
3. Fix any failing tests
4. Document test running procedures
5. Update CI/CD if applicable
