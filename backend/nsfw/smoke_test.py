"""Smoke test with SAFE generated images only (solid colours, gradients)."""

import io
import time

import numpy as np
from PIL import Image

import server


def jpeg(arr: np.ndarray) -> bytes:
    buf = io.BytesIO()
    Image.fromarray(arr.astype(np.uint8)).save(buf, "JPEG", quality=85)
    return buf.getvalue()


def main() -> None:
    w = h = 480
    images = {
        "grey": np.full((h, w, 3), 128),
        "blue": np.tile(np.array([30, 60, 200]), (h, w, 1)),
        "gradient": np.dstack([np.tile(np.linspace(0, 255, w), (h, 1))] * 3),
        "stripes": np.dstack([(np.indices((h, w))[1] // 20 % 2) * 255] * 3),
    }
    times = []
    for name, arr in images.items():
        t = time.perf_counter()
        out = server.classify(jpeg(arr))
        times.append(time.perf_counter() - t)
        assert set(out) >= {"sfw", "nsfw", "model"}, out
        assert 0 <= out["nsfw"] <= 1 and abs(out["sfw"] + out["nsfw"] - 1) < 0.01, out
        print(f"{name:9s} nsfw={out['nsfw']:.4f}")
        assert out["nsfw"] < 0.5, f"{name}: a plain image must not look NSFW: {out}"
    failed = False
    try:
        server.classify(b"not an image")
    except Exception:
        failed = True
    assert failed, "garbage must fail"
    print(f"ok: {len(times)} images, mean {1000 * sum(times) / len(times):.0f} ms, max {1000 * max(times):.0f} ms")


if __name__ == "__main__":
    main()
