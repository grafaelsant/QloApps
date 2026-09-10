"""Property-based tests for analyzer module using Hypothesis."""

import math
from hypothesis import given, strategies as st
from PIL import Image

from app.analyzer import (
    validate_dimensions,
    calculate_luminance,
    classify_luminance,
    calculate_sharpness,
    classify_sharpness,
    evaluate_image,
    MIN_WIDTH,
    MIN_HEIGHT,
    LUMINANCE_UNDEREXPOSED_THRESHOLD,
    LUMINANCE_OVEREXPOSED_THRESHOLD,
    SHARPNESS_MIN_THRESHOLD,
)

# Custom Strategies
dimension_strategy = st.integers(min_value=1, max_value=3000)
color_component_strategy = st.integers(min_value=0, max_value=255)
luminance_float_strategy = st.floats(min_value=-1000.0, max_value=1000.0, allow_nan=False, allow_infinity=False)
sharpness_float_strategy = st.floats(min_value=0.0, max_value=50000.0, allow_nan=False, allow_infinity=False)


# 1. validate_dimensions properties
@given(w=dimension_strategy, h=dimension_strategy)
def test_prop_validate_dimensions_orientation_symmetry(w: int, h: int):
    """
    Validation result must be symmetric under orientation transpose (W, H) vs (H, W).
    """
    img1 = Image.new("RGB", (w, h))
    img2 = Image.new("RGB", (h, w))

    valid1, out_w1, out_h1 = validate_dimensions(img1)
    valid2, out_w2, out_h2 = validate_dimensions(img2)

    assert valid1 == valid2
    assert (out_w1, out_h1) == (w, h)
    assert (out_w2, out_h2) == (h, w)


@given(w=dimension_strategy, h=dimension_strategy)
def test_prop_validate_dimensions_thresholds(w: int, h: int):
    """
    validate_dimensions should be True iff max(w, h) >= MIN_WIDTH and min(w, h) >= MIN_HEIGHT.
    """
    img = Image.new("RGB", (w, h))
    is_valid, out_w, out_h = validate_dimensions(img)

    expected = (max(w, h) >= MIN_WIDTH) and (min(w, h) >= MIN_HEIGHT)
    assert is_valid == expected
    assert out_w == w
    assert out_h == h


# 2. classify_luminance properties
@given(lum=luminance_float_strategy)
def test_prop_classify_luminance_partition(lum: float):
    """
    classify_luminance partitions the real numbers exhaustively into three disjoint categories.
    """
    classification = classify_luminance(lum)
    assert classification in {"UNDEREXPOSED", "OPTIMAL", "OVEREXPOSED"}

    if lum < LUMINANCE_UNDEREXPOSED_THRESHOLD:
        assert classification == "UNDEREXPOSED"
    elif lum > LUMINANCE_OVEREXPOSED_THRESHOLD:
        assert classification == "OVEREXPOSED"
    else:
        assert classification == "OPTIMAL"


@given(lum1=luminance_float_strategy, lum2=luminance_float_strategy)
def test_prop_classify_luminance_monotonicity(lum1: float, lum2: float):
    """
    classify_luminance must be monotonically non-decreasing.
    UNDEREXPOSED (0) <= OPTIMAL (1) <= OVEREXPOSED (2).
    """
    order = {"UNDEREXPOSED": 0, "OPTIMAL": 1, "OVEREXPOSED": 2}
    if lum1 <= lum2:
        assert order[classify_luminance(lum1)] <= order[classify_luminance(lum2)]


# 3. calculate_luminance properties
@given(
    w=st.integers(min_value=2, max_value=80),
    h=st.integers(min_value=2, max_value=80),
    gray_val=color_component_strategy,
)
def test_prop_calculate_luminance_grayscale_uniform(w: int, h: int, gray_val: int):
    """
    A uniform grayscale image must have luminance exactly equal to gray_val.
    """
    img = Image.new("L", (w, h), color=gray_val)
    lum = calculate_luminance(img)
    assert math.isclose(lum, float(gray_val), abs_tol=1e-3)


@given(
    w=st.integers(min_value=2, max_value=80),
    h=st.integers(min_value=2, max_value=80),
    r=color_component_strategy,
    g=color_component_strategy,
    b=color_component_strategy,
)
def test_prop_calculate_luminance_bounds_and_range(w: int, h: int, r: int, g: int, b: int):
    """
    Luminance of any valid RGB image must be within [0.0, 255.0].
    """
    img = Image.new("RGB", (w, h), color=(r, g, b))
    lum = calculate_luminance(img)
    assert 0.0 <= lum <= 255.0


# 4. classify_sharpness properties
@given(score=sharpness_float_strategy)
def test_prop_classify_sharpness_partition(score: float):
    """
    classify_sharpness partitions the non-negative real numbers into BLURRY or SHARP.
    """
    classification = classify_sharpness(score)
    assert classification in {"BLURRY", "SHARP"}

    if score < SHARPNESS_MIN_THRESHOLD:
        assert classification == "BLURRY"
    else:
        assert classification == "SHARP"


# 5. calculate_sharpness properties
@given(
    w=st.integers(min_value=4, max_value=60),
    h=st.integers(min_value=4, max_value=60),
    r=color_component_strategy,
    g=color_component_strategy,
    b=color_component_strategy,
)
def test_prop_calculate_sharpness_uniform_image(w: int, h: int, r: int, g: int, b: int):
    """
    A solid color image has zero edge variation; its sharpness score must be 0.0 and classified as BLURRY.
    """
    img = Image.new("RGB", (w, h), color=(r, g, b))
    sharpness = calculate_sharpness(img)
    assert sharpness == 0.0
    assert classify_sharpness(sharpness) == "BLURRY"


# 6. evaluate_image consistency properties
@given(
    w=st.integers(min_value=10, max_value=100),
    h=st.integers(min_value=10, max_value=100),
    r=color_component_strategy,
    g=color_component_strategy,
    b=color_component_strategy,
)
def test_prop_evaluate_image_invariants(w: int, h: int, r: int, g: int, b: int):
    """
    evaluate_image invariants between warnings and final assessment.
    """
    img = Image.new("RGB", (w, h), color=(r, g, b))
    result = evaluate_image(img)

    assessment = result["assessment"]
    warnings = result["warnings"]
    metrics = result["metrics"]

    # Assessment invariant
    if warnings:
        assert assessment == "EVIDENCE_REQUIRES_RETAKE"
    else:
        assert assessment == "EVIDENCE_VALID"

    # Dimension warning invariant
    is_valid_dim, expected_w, expected_h = validate_dimensions(img)
    assert metrics["width"] == expected_w
    assert metrics["height"] == expected_h
    if not is_valid_dim:
        assert "LOW_RESOLUTION" in warnings
    else:
        assert "LOW_RESOLUTION" not in warnings

    # Luminance warning invariant
    if metrics["luminance_status"] in {"UNDEREXPOSED", "OVEREXPOSED"}:
        assert metrics["luminance_status"] in warnings
    else:
        assert "UNDEREXPOSED" not in warnings
        assert "OVEREXPOSED" not in warnings

    # Sharpness warning invariant
    if metrics["sharpness_status"] == "BLURRY":
        assert "BLURRY_IMAGE" in warnings
    else:
        assert "BLURRY_IMAGE" not in warnings
