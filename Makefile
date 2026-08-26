.PHONY: help build push deploy monitor logs clean

help:
	@echo "expense-tracker devops project"
	@echo "make build      - build docker image locally"
	@echo "make push       - push to ECR (requires AWS creds)"
	@echo "make deploy     - apply kubernetes manifests"
	@echo "make monitor    - port-forward to grafana"
	@echo "make logs       - stream app logs"
	@echo "make clean      - tear down kubernetes resources"

build:
	docker build -t expense-tracker:latest .

push:
	docker tag expense-tracker:latest 353925322836.dkr.ecr.eu-west-1.amazonaws.com/expense-tracker:latest
	docker push 353925322836.dkr.ecr.eu-west-1.amazonaws.com/expense-tracker:latest

deploy:
	kubectl apply -f k8s/

monitor:
	kubectl port-forward svc/grafana 3000:3000

logs:
	kubectl logs -f -l app=expense-tracker

clean:
