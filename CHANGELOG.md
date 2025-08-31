# Changelog

All notable changes to hylang-migrations will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-01-XX

### Added
- Initial release of hylang-migrations
- Pure Hylang implementation of database migrations for SQLite
- CLI tool `hylang-migrate` with commands:
  - `init` - Initialize migration system
  - `create` - Create new migration files
  - `migrate` - Apply pending migrations
  - `rollback` - Rollback last migration
  - `status` - Show migration status
  - `install-claude-agent` - Install Claude Code subagents
- Dynamic migration discovery from .hy files
- Transaction-based migration execution with rollback support
- Migration history tracking with checksums
- Support for:
  - Tables with indexes
  - Foreign key relationships
  - Triggers
  - Complex SQL operations
- Demo application showing complete workflow
- Claude Code subagents for Hylang assistance:
  - hylang-migrate-assistant
  - hyrule-expert
  - lisp-parenthesis-fixer
- Parenthesis analyzer tool for debugging Lisp code
- Integration with SQLObject ORM
- Configuration file support (.migrations)
- Comprehensive test suite

### Documentation
- Complete README with installation and usage instructions
- Demo with 4 example migrations
- Claude subagent documentation
- Installation guide

### Developer Tools
- dodo.hy task automation for building and deployment
- PyPI packaging configuration
- Development environment setup

## Future Releases

### [0.2.0] - Planned
- PostgreSQL support
- MySQL/MariaDB support
- Migration dependencies
- Parallel migration execution
- Migration templates
- Web UI for migration management

### [0.3.0] - Planned
- MongoDB support
- Cloud database support (AWS RDS, Google Cloud SQL)
- Migration validation and testing framework
- Performance optimizations
- Advanced rollback strategies