FROM python:3.11-slim-bookworm AS builder
WORKDIR /app
RUN pip install --no-cache-dir \
    poetry \
    poetry-plugin-export \
    setuptools \
    wheel
COPY pyproject.toml poetry.lock README.md ./
COPY src/ ./src/
RUN mkdir -p dist \
    && poetry export --without-hashes \
        --format constraints.txt \
        --output dist/constraints.txt \
    && poetry run python -m pip wheel \
        --isolated \
        --requirement dist/constraints.txt \
        --wheel-dir dist/vendor \
    && poetry build --format wheel

FROM python:3.11-slim-bookworm AS runtime
WORKDIR /app
COPY --from=builder /app/dist /tmp/dist
RUN pip install --no-cache-dir --no-index --no-deps \
        /tmp/dist/vendor/*.whl \
        /tmp/dist/audit_svc-*.whl \
    && rm -rf /tmp/dist \
    && useradd --create-home --uid 10001 appuser
USER appuser
EXPOSE 8080
CMD ["python", "-m", "audit_svc"]
