.PHONY: up down logs status health restart clean

COMPOSE_DIR := floci-ui
COMPOSE := docker compose -f $(COMPOSE_DIR)/docker-compose.yml --profile multicloud

up:
	$(COMPOSE) up -d --build

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f

status:
	@docker ps --format 'table {{.Names}}\t{{.Ports}}\t{{.Status}}' | grep -E 'floci|NAMES' || true

health:
	@echo "AWS  (4566):" && curl -sf http://localhost:4566/_floci/health | head -c 120 && echo
	@echo "Azure (4577):" && curl -sf http://localhost:4577/_floci/health && echo
	@echo "GCP  (4588):" && curl -sf http://localhost:4588/_floci-gcp/health | head -c 120 && echo
	@echo "API  (4501):" && curl -sf http://localhost:4501/api/clouds && echo
	@echo "UI   (4500): HTTP $$(curl -s -o /dev/null -w '%{http_code}' http://localhost:4500/)"

restart: down up

clean: down
	docker volume prune -f
