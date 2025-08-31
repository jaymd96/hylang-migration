# Makefile for Hylang SQLite Migration Tool

.PHONY: help install test migrate rollback status create clean

# Default database path
DB_PATH ?= database.db

# Python/Hy interpreter
PYTHON ?= python3
HY ?= hy

help:
	@echo "Hylang SQLite Migration Tool"
	@echo "============================"
	@echo ""
	@echo "Available commands:"
	@echo "  make install      - Install dependencies"
	@echo "  make init        - Initialize migration system"
	@echo "  make create NAME=migration_name - Create new migration"
	@echo "  make migrate     - Run pending migrations"
	@echo "  make rollback    - Rollback last migration"
	@echo "  make status      - Show migration status"
	@echo "  make test        - Run test suite"
	@echo "  make clean       - Clean up temporary files"
	@echo ""
	@echo "Environment variables:"
	@echo "  DB_PATH         - Database file path (default: database.db)"

install:
	@echo "Installing dependencies..."
	$(PYTHON) -m pip install -r requirements.txt

init:
	@echo "Initializing migration system..."
	$(HY) cli.hy init --db $(DB_PATH)

create:
ifndef NAME
	@echo "Error: NAME is required"
	@echo "Usage: make create NAME=migration_name"
	@exit 1
endif
	@echo "Creating migration: $(NAME)"
	$(HY) cli.hy create $(NAME)

migrate:
	@echo "Running migrations on $(DB_PATH)..."
	$(HY) cli.hy migrate --db $(DB_PATH)

migrate-dry:
	@echo "Running migrations (dry run) on $(DB_PATH)..."
	$(HY) cli.hy migrate --db $(DB_PATH) --dry-run

rollback:
	@echo "Rolling back last migration on $(DB_PATH)..."
	$(HY) cli.hy rollback --db $(DB_PATH) --steps 1

rollback-all:
	@echo "Rolling back ALL migrations on $(DB_PATH)..."
	@echo "WARNING: This will rollback all migrations!"
	@read -p "Are you sure? (y/N) " confirm && [ "$$confirm" = "y" ] || exit 1
	$(HY) cli.hy rollback --db $(DB_PATH) --steps 999

status:
	@echo "Migration status for $(DB_PATH):"
	@$(HY) cli.hy status --db $(DB_PATH)

list:
	@echo "Listing all migrations:"
	@$(HY) cli.hy list

list-pending:
	@echo "Listing pending migrations:"
	@$(HY) cli.hy list --pending

test:
	@echo "Running test suite..."
	$(HY) test_migrations.hy

backup:
	@echo "Creating database backup..."
	@cp $(DB_PATH) $(DB_PATH).backup.$(shell date +%Y%m%d_%H%M%S)
	@echo "Backup created: $(DB_PATH).backup.$(shell date +%Y%m%d_%H%M%S)"

clean:
	@echo "Cleaning up..."
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@find . -type f -name ".coverage" -delete 2>/dev/null || true
	@find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	@echo "Cleanup complete"

# Development helpers
dev-setup: install init
	@echo "Development environment ready"

check-syntax:
	@echo "Checking Hy syntax..."
	@for file in *.hy migrations/*.hy; do \
		echo "Checking $$file..."; \
		$(HY) -c "(import $$file)" 2>&1 | grep -q "Error" && echo "  ✗ Error in $$file" || echo "  ✓ $$file OK"; \
	done

# Docker support (stub)
docker-build:
	@echo "Building Docker image..."
	@echo "TODO: Create Dockerfile"

docker-run:
	@echo "Running in Docker..."
	@echo "TODO: Implement Docker support"

.DEFAULT_GOAL := help
