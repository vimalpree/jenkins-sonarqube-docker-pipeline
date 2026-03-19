# Stage 1: build
FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --prefix=/install -r requirements.txt

# Stage 2: runtime
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /install /usr/local
COPY app.py .
EXPOSE 3000
CMD ["python", "app.py"]
EOF
