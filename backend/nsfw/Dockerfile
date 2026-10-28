# Campus Voice photo check (see server.py). Build: docker build -t campusnsfw backend/nsfw
# The model is downloaded at build time from a pinned revision and checked
# against its sha256; the running container needs no network.

FROM python:3.12-slim AS model
ARG MODEL_REV=8587de998f441aac03fdd57a85d2e4cb808c7d64
ARG MODEL_SHA256=432763a6899ebc418c55f784b98f90565e5fc694c778d2ffcb0294b12f6a7404
ADD https://huggingface.co/AdamCodd/vit-base-nsfw-detector/resolve/${MODEL_REV}/onnx/model_uint8.onnx /model.onnx
RUN echo "${MODEL_SHA256}  /model.onnx" | sha256sum -c -

FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 OMP_NUM_THREADS=2
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY --from=model --chmod=444 /model.onnx /app/model.onnx
COPY server.py smoke_test.py ./
RUN useradd --uid 65533 --no-create-home --shell /usr/sbin/nologin nsfw
USER nsfw
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=3)"
CMD ["python", "server.py"]
