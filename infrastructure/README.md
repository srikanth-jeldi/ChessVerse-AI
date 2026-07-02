# Infrastructure

This folder contains the first production deployment assets for ChessVerse AI.

## Local Development

Run the backend with PostgreSQL and Redis:

```bash
docker compose up --build
```

Health check:

```bash
curl http://localhost:8080/api/v1/health
```

## Kubernetes

Apply the namespace, create a real secret from `secret.example.yaml`, then deploy:

```bash
kubectl apply -f infrastructure/k8s/namespace.yaml
kubectl apply -f infrastructure/k8s/secret.yaml
kubectl apply -f infrastructure/k8s/backend.yaml
kubectl apply -f infrastructure/k8s/ingress.yaml
```

For AWS, the intended target is EKS with AWS Load Balancer Controller, RDS PostgreSQL, ElastiCache Redis, CloudWatch, and Secrets Manager.

Authentication uses email delivery and guest access, so this deployment does
not require an SMS provider or social OAuth secrets.

## Budget Hostinger VPS

The single-server, Docker-based MVP deployment is documented in
[`../docs/HOSTINGER-VPS-DEPLOYMENT.md`](../docs/HOSTINGER-VPS-DEPLOYMENT.md).
It includes Flutter Web, Spring Boot, PostgreSQL, Stockfish, automatic HTTPS,
container health checks and an optional off-server database backup workflow.
