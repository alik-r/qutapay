PROJECT ?= $(shell gcloud config get-value project 2>/dev/null)
REGION ?= europe-west1
PLATFORM_DIR := deploy/terraform/10-platform

.PHONY: guard init plan up down

guard:
	@test -n "$(PROJECT)" || { echo "No project. Run: gcloud config set project <id>"; exit 1; }

init: guard
	terraform -chdir=$(PLATFORM_DIR) init -input=false -backend-config="bucket=$(PROJECT)-tfstate"

plan: init
	terraform -chdir=$(PLATFORM_DIR) plan

up: init
	terraform -chdir=$(PLATFORM_DIR) apply -auto-approve -input=false
	gcloud container clusters get-credentials qutapay --region $(REGION) --project $(PROJECT)

down: init
	terraform -chdir=$(PLATFORM_DIR) destroy -auto-approve -input=false