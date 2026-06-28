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

## Amazon SNS Phone OTP

The backend publishes OTP messages directly to Amazon SNS. It uses the AWS
default credential chain locally and EKS Pod Identity in production, so AWS
access keys are never stored in Kubernetes secrets.

After authenticating the AWS CLI, create the least-privilege IAM role:

```powershell
.\infrastructure\aws\setup-sns.ps1 `
  -Region ap-south-1 `
  -TestPhone +919876543210
```

New AWS accounts start in the SMS sandbox. The test number must be verified
with the OTP sent by AWS before ChessVerse can send application OTPs to it.
When an EKS cluster exists, pass `-ClusterName` to create its Pod Identity
association.

Local SNS backend configuration:

```text
SMS_MODE=sns
AWS_REGION=ap-south-1
```

For production India local routes, also configure the approved DLT values:

```text
SMS_SENDER_ID=CHESSV
SMS_INDIA_ENTITY_ID=your-trai-entity-id
SMS_INDIA_TEMPLATE_ID=your-trai-template-id
```
