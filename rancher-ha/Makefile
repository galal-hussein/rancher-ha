MODULE := $(shell basename $$PWD)
TIMESTAMP := $(shell date +%Y-%m-%d-%H%M%S)

.PHONY: get plan plan-destroy plan-output apply

state-pull:
	@terraform remote pull

init:
	@terraform init

init-s3:
	@terraform init -backend=true -backend-config="bucket=$(AWS_S3_BUCKET)" -backend-config="key=$(AWS_ENV_NAME)/$(MODULE)/terraform.tfstate" -backend-config="region=$(AWS_DEFAULT_REGION)"
get:
	@terraform get

plan: get
	@terraform plan -var-file ../main-vars.tfvars -var-file ./$(MODULE).tfvars

plan-output: get
	@terraform plan -var-file ../main-vars.tfvars -var-file ./$(MODULE).tfvars -out $(MODULE)-$(TIMESTAMP).plan

plan-destroy: get
	@terraform plan -var-file ../main-vars.tfvars -var-file ./$(MODULE).tfvars -destroy -out $(MODULE)-$(TIMESTAMP)-destroy.plan

apply: get
	@terraform apply -var-file ../main-vars.tfvars -var-file ./$(MODULE).tfvars

apply-plan:
	@terraform apply $(PLAN)

clean:
	@rm *.plan
