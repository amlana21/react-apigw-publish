export AWS_PROFILE=<your-aws-profile>
export AWS_DEFAULT_REGION ?= us-east-1
export AWS_REGION ?= $(AWS_DEFAULT_REGION)
export AWS_ACCOUNT ?= <your-aws-account-id>
export environment=dev
export ENV=$(environment)


1-plan-infra:
	@echo "Planning infrastructure deployment..."
	@cd infrastructure/environments/$(environment) && terraform init
	@cd infrastructure/environments/$(environment) && terraform plan
	@echo "Infrastructure deployment plan completed."


2-deploy-infra:
	@echo "Deploying infrastructure..."
	@cd infrastructure/environments/$(environment) && terraform apply -auto-approve
	@echo "Infrastructure deployment completed."

2-1-build-app:
	@echo "Building application..."
	@aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(AWS_ACCOUNT).dkr.ecr.$(AWS_REGION).amazonaws.com
	@cd src/api-app && docker build --platform linux/amd64 -t api-app:latest .
	@docker tag api-app:latest $(AWS_ACCOUNT).dkr.ecr.$(AWS_REGION).amazonaws.com/$(environment)-app-repo:latest
	@docker push $(AWS_ACCOUNT).dkr.ecr.$(AWS_REGION).amazonaws.com/$(environment)-app-repo:latest
	@echo "Application build completed."

3-destroy-infra:
	@echo "Destroying infrastructure..."
	@cd infrastructure/environments/$(environment) && terraform destroy -auto-approve
	@echo "Infrastructure destruction completed."

4-clean:
	@echo "Cleaning up local Docker images..."
	@docker rmi api-app:latest || true
	@docker rmi $(AWS_ACCOUNT).dkr.ecr.$(AWS_REGION).amazonaws.com/$(environment)-app-repo:latest || true
	@echo "Local Docker images cleaned up."