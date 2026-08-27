# Expense Tracker — Full-Stack DevOps Project

A complete full-stack application demonstrating containerization, CI/CD automation, Kubernetes orchestration, and observability patterns.

## Project Summary

**What it is**: A personal expense tracking API (FastAPI backend) with a React frontend, containerized, tested, deployed to Kubernetes, and monitored with Prometheus + Grafana.

**Why it matters**: Demonstrates production-grade DevOps patterns — multi-tier architecture, automated pipelines, container orchestration, and observability.

## Architecture
┌─────────────────────────────────────────────────────────────┐
│ Client Browser │
│ (http://localhost) │
└────────────────────────┬────────────────────────────────────┘
│
┌────────────────▼─────────────────┐
│ Kubernetes Cluster (k3d) │
│ │
│ ┌──────────────────────────┐ │
│ │ Nginx Frontend Pod │ │
│ │ (React app, port 80) │ │
│ └──────┬───────────────────┘ │
│ │ │
│ ┌──────▼───────────────────┐ │
│ │ FastAPI Backend Pod │ │
│ │ (port 8000) │ │
│ └──────┬───────────────────┘ │
│ │ │
└─────────┼───────────────────────┘
│
┌─────────▼──────────────┐
│ AWS DynamoDB │
│ (Expense Data) │
└────────────────────────┘
    ┌────────────────────────┐
    │  Prometheus Pod        │
    │  (Metrics scraping)    │
    └────────────┬───────────┘
                 │
    ┌────────────▼──────────┐
    │   Grafana Pod         │
    │   (Dashboards)        │
    └───────────────────────┘


## Tech Stack

| Component | Technology |
|-----------|-----------|
| Backend API | FastAPI (Python 3.12) |
| Frontend | React + Recharts (charting) |
| Database | AWS DynamoDB |
| Container Runtime | Docker |
| Orchestration | Kubernetes (k3d locally) |
| Container Registry | Amazon ECR |
| CI/CD | GitHub Actions |
| Metrics | Prometheus |
| Visualization | Grafana |
| IaC (networking) | Terraform |

## Key Features

- **CRUD API**: Create, read, delete expenses; get category summaries
- **React UI**: Add expenses, view list, category breakdown chart
- **Containerization**: Both frontend (nginx) and backend (Python) in separate Docker images
- **Automated Pipeline**: Git push → test → build → push to ECR
- **Kubernetes-native**: Deployments, Services, ConfigMaps, Secrets
- **Observability**: Prometheus scrapes app metrics, Grafana dashboards show request rates and latency
- **Multi-tier**: Frontend and backend decoupled, nginx proxies /api/ to backend

## Project Structure
expense-tracker/
├── main.py # FastAPI app
├── dynamo_db.py # DynamoDB integration
├── Dockerfile # Backend container
├── requirements.txt # Python dependencies
│
├── frontend/ # React app
│ ├── src/
│ │ ├── App.js
│ │ ├── App.css
│ │ └── components/
│ │ ├── ExpenseForm.js
│ │ ├── ExpenseList.js
│ │ └── ExpenseSummary.js
│ ├── Dockerfile # Frontend container (nginx)
│ ├── nginx.conf # Nginx config
│ └── package.json
│
├── .github/
│ └── workflows/
│ └── ci-cd.yml # GitHub Actions pipeline
│
├── k8s/ # Kubernetes manifests
│ ├── deployment.yaml # Backend deployment
│ ├── service.yaml # Backend service
│ ├── prometheus-config.yaml # Prometheus config
│ ├── prometheus-deployment.yaml
│ ├── prometheus-service.yaml
│ ├── grafana-deployment.yaml
│ └── grafana-service.yaml
│
├── terraform/ # AWS infrastructure
│ ├── main.tf
│ └── variables.tf
│
└── README.md # This file


## How to Run

### Prerequisites

- Docker installed
- k3d installed (`k3d --version`)
- kubectl installed
- Python 3.12 + venv
- AWS credentials configured
- Node.js 18+ (for frontend development)

### Local Development (without Kubernetes)

```bash
# Backend setup
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Create DynamoDB table
aws dynamodb create-table \
  --table-name expenses \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

# Start backend
./venv/bin/python -m uvicorn main:app --reload
```

In another terminal:

```bash
# Frontend setup
cd frontend
npm install
REACT_APP_API_URL=http://localhost:8000 npm start
```

Open http://localhost:3000 in your browser. You should see the expense tracker UI.

### Deploy to Kubernetes (k3d)

**1. Create the cluster**
```bash
k3d cluster create expense-tracker
```

**2. Create AWS credentials secret**
```bash
kubectl create secret generic aws-credentials \
  --from-literal=access-key-id=<YOUR_AWS_KEY> \
  --from-literal=secret-access-key=<YOUR_AWS_SECRET>

kubectl create secret docker-registry ecr-credentials \
  --docker-server=353925322836.dkr.ecr.eu-west-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region eu-west-1)
```

**3. Create DynamoDB table** (if not already done)
```bash
aws dynamodb create-table \
  --table-name expenses \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

**4. Deploy all services**
```bash
kubectl apply -f k8s/
```

**5. Verify everything is running**
```bash
kubectl get pods,deployments,services
```

**6. Access the app**
```bash
kubectl get service expense-tracker
# Open http://<EXTERNAL-IP>:8000/expenses in browser
```

**7. Access Grafana**
```bash
kubectl get service grafana
# Open http://<EXTERNAL-IP>:3000 in browser
# Login: admin / admin
```

You should see:
- Expense tracker API responding
- Prometheus scraping metrics from the app
- Grafana dashboards showing request counts and latency

### CI/CD Pipeline

Every push to `main` triggers GitHub Actions:

1. Builds Docker images for both frontend and backend
2. Pushes images to Amazon ECR
3. (Can optionally trigger Kubernetes deployment)

View pipeline status: **GitHub → Actions tab**

## API Endpoints

### Backend (FastAPI)

```bash
# Create expense
POST /expenses
{
  "amount": 50.00,
  "category": "food",
  "description": "lunch",
  "date": "2026-08-26"
}

# List expenses
GET /expenses

# Get summary by category
GET /expenses/summary

# Delete expense
DELETE /expenses/{expense_id}

# Prometheus metrics
GET /metrics
```

### Frontend

- **http://localhost:3000** — React UI (development)
- **http://<SERVICE_IP>:80** — Production (Kubernetes)

## Design Decisions & Trade-offs

### Frontend Containerization (Nginx)

**Why nginx?**
- Lightweight web server for static React files
- Built-in reverse proxy to backend (`/api/` routes)
- Eliminates CORS complexity (same domain for frontend + backend)

**Alternative**: Could run Node.js server, but adds overhead. Nginx is simpler for a static SPA.

### Kubernetes over ECS

**Why Kubernetes?**
- Portable across cloud providers (k3d local → AWS EKS → GKE)
- Industry standard for microservices
- Better abstractions for multi-tier apps (Services, Ingress, ConfigMaps)

**Why not ECS?**
- AWS-specific (skills don't transfer)
- Task definitions are less intuitive than Kubernetes manifests
- Credential handling in bridge networking is complex

### Local k3d for Development

**Why k3d?**
- Full Kubernetes locally without cloud costs
- Fast iteration (redeploy in seconds)
- Same manifests work on production EKS

**What's missing from k3d?**
- EKS-specific features (IAM roles, CloudWatch integration)
- Multi-AZ high availability
- Production-grade networking and security policies

## Lessons Learned

### What went well
1. **CI/CD automation** — GitHub Actions reliably builds and pushes both images
2. **Containerization** — identical Docker build process for dev and production
3. **Kubernetes patterns** — Deployments, Services, ConfigMaps/Secrets work seamlessly
4. **Prometheus integration** — metrics collection straightforward, minimal code changes
5. **Multi-tier architecture** — frontend and backend properly decoupled

### Challenges

1. **CORS complexity** — initially had frontend/backend on different ports. Solution: nginx reverse proxy eliminates the problem entirely.
2. **DynamoDB credentials** — had to create Kubernetes Secrets for both DynamoDB and ECR authentication. Learned the importance of credential separation.
3. **Kubernetes learning curve** — more concepts than ECS, but cleaner mental model once understood.
4. **Local development** — frontend needs `REACT_APP_API_URL` set correctly depending on environment (local vs k3d vs production).

### What I'd do differently

1. **Start with Kubernetes** — skip ECS entirely for learning. Kubernetes patterns are more transferable.
2. **Use Kustomize earlier** — if managing multiple environments, use Kustomize to avoid YAML duplication.
3. **Add integration tests to CI/CD** — currently only builds images. Should validate the app works.
4. **Implement proper RBAC** — Kubernetes has role-based access control; didn't implement it here for simplicity.

## Scaling this further

### Next steps (if continuing)

- **Argo CD** — GitOps deployments (git push → auto-deploy to Kubernetes)
- **Kustomize** — multi-environment setup (dev/staging/prod without duplicating manifests)
- **Helm charts** — package the application for distribution and reuse
- **AWS EKS migration** — deploy to managed Kubernetes on AWS (same manifests)
- **Structured logging** — add ELK stack or AWS CloudWatch for centralized logs
- **Distributed tracing** — add Jaeger to track requests across services
- **Network policies** — restrict pod-to-pod communication to only what's needed
- **Pod security policies** — enforce container security best practices

### Cost optimization

If deploying to EKS:
- Use Fargate (serverless containers) instead of EC2 for lower overhead
- Auto-scaling: scale pods based on CPU/memory, scale nodes based on pod demand
- Reserved instances or Spot instances for cost savings
- Horizontal pod autoscaling (HPA) for load spikes

## Repository

**GitHub**: [spaxqwii/expense-tracker](https://github.com/spaxqwii/expense-tracker)

Branch: `main` (all code, CI/CD, Kubernetes manifests)

## Resources

- [Kubernetes Documentation](https://kubernetes.io/docs)
- [Prometheus Documentation](https://prometheus.io/docs)
- [Grafana Documentation](https://grafana.com/docs)
- [FastAPI](https://fastapi.tiangolo.com)
- [AWS DynamoDB](https://docs.aws.amazon.com/dynamodb)
- [k3d](https://k3d.io)
- [Docker](https://docs.docker.com)

## Key Takeaways

✅ **Multi-tier containerized applications**: Both frontend and backend run in Docker, independently deployable
✅ **Kubernetes fundamentals**: Deployments, Services, ConfigMaps, Secrets, Ingress patterns
✅ **CI/CD automation**: GitHub Actions reliably builds and publishes images
✅ **Production observability**: Prometheus metrics + Grafana dashboards for visibility
✅ **Infrastructure as Code**: Terraform for cloud resources, YAML manifests for Kubernetes
✅ **Cloud database integration**: DynamoDB for scalable, serverless data layer

---

**Built: August 2026**  
**Status**: Complete and working on k3d Kubernetes locally  
**Portfolio value**: Demonstrates full DevOps pipeline from code → container → orchestration → monitoring