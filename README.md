# hylang-migrations

Pure Hylang database migration tool for SQLite.

## Installation

```bash
pip install hylang-migrations
```

## Usage

```bash
# Initialize migration system
hylang-migrate init --db database.db

# Create a new migration
hylang-migrate create --name create_users_table

# Run migrations
hylang-migrate migrate --db database.db

# Check status
hylang-migrate status --db database.db

# Rollback last migration
hylang-migrate rollback --db database.db
```

## Writing Migrations

Create `.hy` files in your migrations directory:

```hy
(defclass Migration001 []
  (defn __init__ [self]
    (setv self.version "001")
    (setv self.name "create_users_table")
    (setv self.connection None))
  
  (defn set-connection [self conn]
    (setv self.connection conn))
  
  (defn up [self]
    "Apply migration"
    (when self.connection
      (setv cursor (.cursor self.connection))
      (.execute cursor "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)")))
  
  (defn down [self]
    "Rollback migration"
    (when self.connection
      (setv cursor (.cursor self.connection))
      (.execute cursor "DROP TABLE users"))))

(setv migration (Migration001))
```

## Features

- Pure Hylang (Lisp) implementation
- SQLite support
- Transaction-based migrations
- Migration history tracking
- CLI interface
- Claude Code subagents for Hylang assistance

## License

MIT