# Installation and Usage Guide

## Installation

### From PyPI (when published)

```bash
pip install hylang-migrations
```

### From Source (Development)

```bash
# Clone the repository
git clone https://github.com/yourusername/hylang-migrations.git
cd hylang-migrations

# Install in development mode
pip install -e .

# Or build and install
python -m build
pip install dist/hylang_migrations-0.1.0-py3-none-any.whl
```

## Quick Start

### 1. Initialize in Your Project

Navigate to your project directory and initialize:

```bash
cd your-project
hylang-migrate init
```

This creates:
- `migrations/` directory for your migration files
- `.migrations` configuration file
- Initial setup for SQLite database

### 2. Create Your First Migration

```bash
hylang-migrate create create_users_table
```

This generates a timestamped migration file like `20240101120000_create_users_table.hy`.

Edit the generated file to add your schema changes:

```hylang
(defn up [self connection]
  "Apply migration"
  (.execute connection
    "CREATE TABLE users (
       id INTEGER PRIMARY KEY AUTOINCREMENT,
       username VARCHAR(255) UNIQUE NOT NULL,
       email VARCHAR(255) UNIQUE NOT NULL,
       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
     )"))

(defn down [self connection]
  "Rollback migration"
  (.execute connection "DROP TABLE IF EXISTS users"))
```

### 3. Run Migrations

```bash
# Run all pending migrations
hylang-migrate migrate

# Preview changes without applying
hylang-migrate migrate --dry-run

# Run up to specific version
hylang-migrate migrate --target 20240101120000
```

### 4. Check Status

```bash
hylang-migrate status
```

### 5. Rollback if Needed

```bash
# Rollback last migration
hylang-migrate rollback

# Rollback last 3 migrations
hylang-migrate rollback --steps 3

# Rollback to specific version
hylang-migrate rollback --to 20240101120000
```

## Command Reference

### Global Options

```bash
hylang-migrate --help
hylang-migrate --version
hylang-migrate --config path/to/config
hylang-migrate --migrations-dir custom/migrations
hylang-migrate --db custom.db
```

### Commands

#### init
Initialize migration system in current project
```bash
hylang-migrate init
```

#### create
Create a new migration file
```bash
hylang-migrate create migration_name
```

#### migrate
Run pending migrations
```bash
hylang-migrate migrate [OPTIONS]
  --target VERSION    Migrate up to specific version
  --dry-run          Preview without executing
  --verbose          Show detailed output
```

#### rollback
Rollback migrations
```bash
hylang-migrate rollback [OPTIONS]
  --steps N          Number of migrations to rollback
  --to VERSION       Rollback to specific version
  --dry-run          Preview without executing
```

#### status
Show migration status
```bash
hylang-migrate status
```

#### list
List all migrations
```bash
hylang-migrate list [OPTIONS]
  --pending          Show only pending migrations
  --applied          Show only applied migrations
```

#### show
Show details of a specific migration
```bash
hylang-migrate show VERSION
```

#### validate
Validate migration files and configuration
```bash
hylang-migrate validate
```

## Configuration

### Configuration File (.migrations)

The tool looks for `.migrations` in your project root:

```ini
[database]
path = database.db
type = sqlite

[migrations]
directory = migrations
table_name = migration_history
auto_transaction = true
verify_checksums = true

[sqlobject]
debug = false
cache = true
lazy_update = true
```

### Environment Variables

You can override configuration with environment variables:

```bash
export DB_PATH=production.db
export MIGRATIONS_DIR=db/migrations
hylang-migrate migrate
```

## Writing Migrations in Hylang

### Basic Structure

```hylang
(defclass MigrationName []
  (defn __init__ [self]
    (setv self.version "20240101120000")
    (setv self.name "migration_name"))
  
  (defn up [self connection]
    "Apply migration"
    ;; Your forward migration logic
    )
  
  (defn down [self connection]
    "Rollback migration"
    ;; Your rollback logic
    ))

(setv migration (MigrationName))
```

### Using SQLObject Models

```hylang
(import sqlobject [SQLObject StringCol IntCol DateTimeCol])

(defclass User [SQLObject]
  (setv username (StringCol :unique True))
  (setv email (StringCol :unique True))
  (setv created-at (DateTimeCol :default datetime.now)))
```

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Database Migrations
on: [push]

jobs:
  migrate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.10'
      
      - name: Install dependencies
        run: |
          pip install hylang-migrations
      
      - name: Run migrations
        run: |
          hylang-migrate migrate --db test.db
```

### Docker Example

```dockerfile
FROM python:3.10-slim

WORKDIR /app

# Install hylang-migrations
RUN pip install hylang-migrations

# Copy migrations
COPY migrations/ migrations/

# Run migrations on container start
CMD ["hylang-migrate", "migrate"]
```

## Troubleshooting

### Common Issues

1. **Migration not found**
   - Check file naming: `YYYYMMDDHHMMSS_name.hy`
   - Ensure file is in migrations directory

2. **Import errors**
   - Install hy: `pip install hy`
   - Check Hylang syntax

3. **Database locked**
   - Close other database connections
   - Check file permissions

4. **Foreign key errors**
   - Enable foreign keys: `PRAGMA foreign_keys = ON`
   - Check migration order

### Debug Mode

Run with verbose output for debugging:

```bash
hylang-migrate migrate --verbose
```

Check migration syntax:

```bash
hylang-migrate validate
```

## Best Practices

1. **Always test migrations**
   - Use `--dry-run` first
   - Test rollbacks
   - Keep backups

2. **Version control**
   - Commit migration files
   - Don't edit applied migrations
   - Document changes

3. **Migration naming**
   - Use descriptive names
   - Follow conventions
   - Keep migrations focused

4. **Performance**
   - Add indexes in separate migrations
   - Batch data migrations
   - Monitor execution time

## Publishing to PyPI

When you're ready to publish:

```bash
# Build the package
python -m build

# Upload to TestPyPI first
python -m twine upload --repository testpypi dist/*

# Test installation
pip install --index-url https://test.pypi.org/simple/ hylang-migrations

# Upload to PyPI
python -m twine upload dist/*
```

## Support

- GitHub Issues: https://github.com/yourusername/hylang-migrations/issues
- Documentation: https://github.com/yourusername/hylang-migrations#readme
