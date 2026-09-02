FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

# Cloud Run sends traffic to $PORT, which defaults to 8080 and is set from the
# `port` key in terraform.yaml. Bind to 0.0.0.0, not localhost, or Cloud Run
# will never reach the container and the deploy will time out.
ENV PORT=8080
EXPOSE 8080

# Run as a non-root user.
RUN useradd --create-home --uid 1000 app
USER app

CMD exec gunicorn --bind "0.0.0.0:$PORT" --workers 1 --threads 8 --timeout 0 main:app
