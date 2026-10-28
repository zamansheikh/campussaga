"""Campus Voice photo check: a tiny HTTP service around an NSFW classifier.

POST /classify   body: image bytes (JPEG/PNG)  ->  {"nsfw": 0.97, "sfw": 0.03, "model": "..."}
GET  /health     ->  {"status": "ok", "model": "..."}

The model (AdamCodd/vit-base-nsfw-detector, Apache-2.0, uint8-quantized ONNX) is baked
into the image: no network at runtime. Photos are classified in memory and
never stored or logged.
"""

import io
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import numpy as np
import onnxruntime as ort
from PIL import Image

MODEL_PATH = os.environ.get("MODEL_PATH", "/app/model.onnx")
MODEL_NAME = "AdamCodd/vit-base-nsfw-detector@8587de9 uint8"
SIZE = 384  # the model's input (preprocessor_config.json)
MAX_BYTES = 10 << 20

opts = ort.SessionOptions()
# A shared VPS: a couple of threads is plenty for a few photos a minute.
opts.intra_op_num_threads = int(os.environ.get("THREADS", "2"))
opts.inter_op_num_threads = 1
SESSION = ort.InferenceSession(MODEL_PATH, sess_options=opts, providers=["CPUExecutionProvider"])
INPUT = SESSION.get_inputs()[0].name


def classify(data: bytes) -> dict:
    """Scores for one image: softmax over (sfw, nsfw)."""
    img = Image.open(io.BytesIO(data))
    img.draft("RGB", (SIZE * 2, SIZE * 2))  # cheap JPEG downscale first
    img = img.convert("RGB").resize((SIZE, SIZE), Image.BILINEAR)
    x = np.asarray(img, dtype=np.float32) / 255.0
    x = (x - 0.5) / 0.5  # image_mean = image_std = 0.5
    x = x.transpose(2, 0, 1)[None, ...]
    logits = SESSION.run(None, {INPUT: x})[0][0].astype(np.float64)
    p = np.exp(logits - logits.max())
    p /= p.sum()
    return {"sfw": round(float(p[0]), 4), "nsfw": round(float(p[1]), 4), "model": MODEL_NAME}


class Handler(BaseHTTPRequestHandler):
    def _send(self, code: int, body: dict) -> None:
        raw = json.dumps(body).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def do_GET(self):  # noqa: N802
        if self.path == "/health":
            self._send(200, {"status": "ok", "model": MODEL_NAME})
        else:
            self._send(404, {"error": "not found"})

    def do_POST(self):  # noqa: N802
        if self.path != "/classify":
            self._send(404, {"error": "not found"})
            return
        n = int(self.headers.get("Content-Length") or 0)
        if n <= 0 or n > MAX_BYTES:
            self._send(413 if n > MAX_BYTES else 400, {"error": "send the image bytes (at most 10 MB)"})
            return
        data = self.rfile.read(n)
        try:
            out = classify(data)
        except Exception:  # undecodable image: say so, never echo it
            self._send(400, {"error": "not an image"})
            return
        self._send(200, out)

    def log_message(self, fmt, *args):  # no per-request logs: nothing about photos
        pass


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8000"))
    print(f"nsfw: {MODEL_NAME} on :{port}", flush=True)
    ThreadingHTTPServer(("0.0.0.0", port), Handler).serve_forever()
