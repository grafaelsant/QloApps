#!/usr/bin/env python3
"""Standalone Byte-Level Mutation Fuzzing Harness for Image Processing & Analyzer.

Mutates binary image payloads using random bit flips, byte deletions, insertions,
and stream truncation, testing both Pillow image decoding resilience and downstream
quality evaluation functions in app.analyzer.
"""

import argparse
import glob
import io
import os
import random
import sys
import time
from typing import List

from PIL import Image, UnidentifiedImageError

# Ensure app package is accessible
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.analyzer import evaluate_image


def load_seed_corpus(fixtures_dir: str) -> List[bytes]:
    """Load sample JPEG images from fixtures as seed corpus."""
    corpus = []
    pattern = os.path.join(fixtures_dir, "*.jpg")
    for filepath in glob.glob(pattern):
        with open(filepath, "rb") as f:
            corpus.append(f.read())
    if not corpus:
        # Fallback synthetic seed if fixtures directory is missing or empty
        img = Image.new("RGB", (64, 64), color=(200, 100, 50))
        buf = io.BytesIO()
        img.save(buf, format="JPEG")
        corpus.append(buf.getvalue())
    return corpus


def mutate_bytes(data: bytes, mutation_rate: float = 0.001) -> bytes:
    """Apply random mutations to byte array: bit flips, substitutions, deletions, insertions."""
    mutated = bytearray(data)
    # Vary mutation rate dynamically: 50% subtle mutations (to test decoder/analyzer), 50% aggressive
    rate = random.choice([0.0001, 0.0005, 0.001, 0.01, 0.05])
    num_mutations = max(1, int(len(mutated) * rate))

    mutation_types = ["flip", "replace", "delete", "insert", "truncate"]

    for _ in range(num_mutations):
        m_type = random.choice(mutation_types)
        if not mutated:
            break

        idx = random.randint(0, len(mutated) - 1)

        if m_type == "flip":
            bit = 1 << random.randint(0, 7)
            mutated[idx] ^= bit
        elif m_type == "replace":
            mutated[idx] = random.randint(0, 255)
        elif m_type == "delete" and len(mutated) > 10:
            del mutated[idx]
        elif m_type == "insert":
            mutated.insert(idx, random.randint(0, 255))
        elif m_type == "truncate" and len(mutated) > 20:
            cut_idx = random.randint(10, len(mutated) - 1)
            mutated = mutated[:cut_idx]

    return bytes(mutated)


def run_fuzz(iterations: int, fixtures_dir: str, seed: int = None) -> int:
    """Run byte mutation fuzzing iterations."""
    if seed is not None:
        random.seed(seed)

    corpus = load_seed_corpus(fixtures_dir)
    print(f"[FUZZ HARNESS] Loaded {len(corpus)} seed files from {fixtures_dir}")
    print(f"[FUZZ HARNESS] Running {iterations} iterations...")

    start_time = time.time()
    crashes = 0
    decoded_count = 0
    rejected_count = 0

    for i in range(1, iterations + 1):
        seed_data = random.choice(corpus)
        mutated_data = mutate_bytes(seed_data)

        try:
            # 1. Image decoding step
            img = Image.open(io.BytesIO(mutated_data))
            img.load()
            decoded_count += 1

            # 2. Analyzer evaluation step
            analysis = evaluate_image(img)
            assert analysis["assessment"] in {"EVIDENCE_VALID", "EVIDENCE_REQUIRES_RETAKE"}
            assert 0.0 <= analysis["metrics"]["luminance"] <= 255.0
            assert analysis["metrics"]["sharpness_score"] >= 0.0

        except (UnidentifiedImageError, OSError, ValueError, Image.DecompressionBombError):
            # Gracefully rejected corrupt/malformed payload
            rejected_count += 1
        except Exception as e:
            # Unexpected crash or invariant violation!
            crashes += 1
            print(f"\n[CRASH DETECTED] Iteration #{i}: {type(e).__name__}: {e}")
            break

        if i % 500 == 0 or i == iterations:
            elapsed = time.time() - start_time
            rate = i / elapsed if elapsed > 0 else 0
            print(f"Iter {i}/{iterations} ({rate:.1f} exec/s) | Decoded: {decoded_count} | Cleanly Rejected: {rejected_count} | Crashes: {crashes}")

    elapsed = time.time() - start_time
    print(f"\n[FUZZ HARNESS COMPLETED] in {elapsed:.2f}s. Total Crashes: {crashes}")
    return 1 if crashes > 0 else 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Image Processing Fuzz Harness")
    parser.add_argument("--iterations", type=int, default=1000, help="Number of fuzz iterations (default: 1000)")
    parser.add_argument("--fixtures", type=str, default=os.path.join(os.path.dirname(__file__), "fixtures"), help="Path to fixtures")
    parser.add_argument("--seed", type=int, default=None, help="Random seed for reproducibility")

    args = parser.parse_args()
    sys.exit(run_fuzz(iterations=args.iterations, fixtures_dir=args.fixtures, seed=args.seed))
