# Expense Tracker — Full DevOps Learning Project

## Overview

A personal budget/expense tracker API built to learn DevOps fundamentals across the full pipeline: 
app development → containerization → CI/CD → multiple orchestration platforms → monitoring.

**TL;DR**: FastAPI app → DynamoDB persistence → Docker image → GitHub Actions CI/CD → Kubernetes deployment → Prometheus + Grafana monitoring.

## Architecture

### High-level flow 
Git push
→ GitHub Actions (build Docker image & push to ECR)
→ Docker image in Amazon ECR
→ Kubernetes deployment (k3d local)
→ FastAPI app serves HTTP requests
→ DynamoDB stores expense data
→ Prometheus scrapes metrics
→ Grafana visualizes dashboards


### Components
- **App**: FastAPI (Python) CRUD API
  - `POST /expenses` — create expense
  - `GET /expenses` — list all expenses
  - `GET /expenses/summary` — totals grouped by category
  - `DELETE /expenses/{id}` — remove expense
  - `GET /metrics` — Prometheus metrics endpoint
- **Database**: AWS DynamoDB (always-free tier)
- **Container Registry**: Amazon ECR (image storage)
- **Orchestration**: Kubernetes via k3d (local cluster)
- **CI/CD**: GitHub Actions (automated build/push on every git push)
- **Monitoring**: Prometheus (metrics scraping) + Grafana (dashboards)

## Tech Stack
- **Language**: Python 3.12
- **Framework**: FastAPI + Uvicorn
- **Persistence**: AWS DynamoDB
- **Containerization**: Docker
- **Container Registry**: Amazon ECR
- **Orchestration**: Kubernetes (k3d locally)
- **CI/CD**: GitHub Actions
- **Metrics**: Prometheus
- **Visualization**: Grafana
- **Infrastructure-as-Code**: Kubernetes YAML manifests, Terraform (AWS)

## Project Structure
expense-tracker/
├── main.py # FastAPI app with Prometheus metrics
├── dynamo_db.py # DynamoDB integration
├── Dockerfile # Container definition
├── requirements.txt # Python dependencies
├── .github/
│ └── workflows/
│ └── ci-cd.yml # GitHub Actions pipeline
├── k8s/ # Kubernetes manifests
│ ├── deployment.yaml # App deployment
│ ├── service.yaml # App service (load balancer)
│ ├── prometheus-config.yaml
│ ├── prometheus-deployment.yaml
│ ├── prometheus-service.yaml
│ ├── grafana-deployment.yaml
│ └── grafana-service.yaml
└── README.md # This file


## How to Run Locally

### Prerequisites
- Docker installed
- k3d installed (`k3d --version` to verify)
- kubectl installed
- Python 3.12 + venv
- AWS credentials configured (`aws configure`)

### Step 1: Start the app locally (without Kubernetes)
```bash
# Setup
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Run
uvicorn main:app --reload

# Test in another terminal
curl http://localhost:8000/expenses
curl http://localhost:8000/metrics  # Prometheus metrics endpoint
```

### Step 2: Deploy to Kubernetes (k3d)

**Start the cluster:**
```bash
k3d cluster create expense-tracker
```

**Create secrets for AWS credentials:**
```bash
# For DynamoDB access
kubectl create secret generic aws-credentials \
  --from-literal=access-key-id=<YOUR_AWS_ACCESS_KEY> \
  --from-literal=secret-access-key=<YOUR_AWS_SECRET_KEY>

# For ECR image pull (use your AWS account ID)
kubectl create secret docker-registry ecr-credentials \
  --docker-server=<YOUR_ACCOUNT_ID>.dkr.ecr.eu-west-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region eu-west-1)
```

**Deploy all resources:**
```bash
kubectl apply -f k8s/
```

**Verify everything is running:**
```bash
kubectl get pods,deployments,services
```

**Access the app:**
```bash
kubectl get service expense-tracker
curl http://<EXTERNAL-IP>:8000/expenses
```

**Access Grafana dashboard:**
```bash
kubectl get service grafana
# Open http://<EXTERNAL-IP>:3000 in your browser
# Login: admin / admin
```

Once logged in, you'll see Prometheus data visualized showing:
- Total requests over time
- Request rate (requests per second)
- Request latency

## CI/CD Pipeline

Every time you push to `main`, GitHub Actions automatically:
1. Builds a new Docker image
2. Tags it with the latest commit
3. Pushes it to Amazon ECR

The workflow runs in ~2 minutes. View it at: **GitHub → Actions tab**

To redeploy the updated image to Kubernetes:
```bash
kubectl rollout restart deployment/expense-tracker
```

## Key Learnings

### What went well
- **CI/CD automation** — GitHub Actions successfully builds and pushes images on every push
- **Containerization** — Docker build reproducible, runs locally and on k3d identically
- **Kubernetes deployment** — cleaner abstractions than ECS for this project scale
- **Metrics integration** — Prometheus metrics collection and Grafana visualization straightforward
- **Local development** — k3d provides realistic Kubernetes environment without AWS overhead

### Challenges & Trade-offs

**1. ECS credential handling in bridge mode**
- Attempted AWS ECS deployment with EC2 + bridge networking
- Task IAM roles + `ECS_ENABLE_TASK_IAM_ROLE=true` config should work, but struggled with credential proxy not activating
- **Lesson**: ECS bridge mode requires careful credential setup; `awsvpc` network mode would have been simpler but unavailable on EC2 launch type
- **Resolution**: Pivoted to Kubernetes, which has cleaner credential patterns

**2. ECS vs Kubernetes**
- ECS: simpler for simple apps, but AWS-specific, less portable
- Kubernetes: more concepts to learn, but abstractions are cleaner and skills transfer across cloud providers
- **Decision**: Kubernetes wins for learning value

**3. Local testing vs cloud**
- Running everything locally (k3d) is faster iteration than constantly provisioning/tearing down AWS resources
- DynamoDB runs in AWS (not local), so some cloud infrastructure is still necessary

### What I'd do differently next time
1. **Start with Kubernetes locally** — skip ECS entirely for learning
2. **Get credentials right from the start** — don't defer security; test end-to-end before moving on
3. **Add integration tests to CI/CD** — pipeline should validate app works, not just that image builds
4. **Use Kustomize for multi-environment setup** — if managing dev/staging/prod, avoid YAML duplication

## Expenses API Examples

**Create an expense:**
```bash
curl -X POST http://localhost:8000/expenses \
  -H "Content-Type: application/json" \
  -d '{"amount": 50.00, "category": "food", "description": "lunch", "date": "2026-08-14"}'
```

**List all expenses:**
```bash
curl http://localhost:8000/expenses
```

**Get summary by category:**
```bash
curl http://localhost:8000/expenses/summary
```

**Delete an expense:**
```bash
curl -X DELETE http://localhost:8000/expenses/<EXPENSE_ID>
```

## Cleanup

**Stop the Kubernetes cluster:**
```bash
k3d cluster delete expense-tracker
```

**Remove Docker image:**
```bash
docker rmi expense-tracker:latest
```

## Next Steps (if continuing)

- **Argo CD** — GitOps deployments (git push → auto-deploy to Kubernetes)
- **Kustomize** — environment management (dev/staging/prod without duplication)
- **Helm charts** — package and distribute the application
- **Kubernetes security** — RBAC, network policies, pod security policies
- **EKS migration** — move from local k3d to AWS EKS for production-like setup

## Resources

- [Kubernetes Docs](https://kubernetes.io/docs)
- [Prometheus Docs](https://prometheus.io/docs)
- [Grafana Docs](https://grafana.com/docs)
- [FastAPI](https://fastapi.tiangolo.com)
- [AWS DynamoDB](https://docs.aws.amazon.com/dynamodb)
- [k3d](https://k3d.io)

---

**Built as a DevOps learning project in August 2026.**

Demonstrates: containerization, CI/CD automation, Kubernetes orchestration, and observability patterns.