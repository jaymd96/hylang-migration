# Release Guide for hylang-migrations

## Prerequisites

1. **PyPI Account**: Create accounts at:
   - https://pypi.org (production)
   - https://test.pypi.org (testing)

2. **API Tokens**: Generate API tokens for both accounts

3. **Configure ~/.pypirc**: Copy `.pypirc.template` to `~/.pypirc` and add your tokens

## Release Process

### 1. Update Version
Edit `pyproject.toml` and update the version number:
```toml
version = "0.1.0"  # Change this
```

Also update `src/hylang_migrations/__init__.py`:
```python
__version__ = "0.1.0"  # Match pyproject.toml
```

### 2. Update Documentation
- Update CHANGELOG.md with release notes
- Ensure README.md is current
- Check all documentation is accurate

### 3. Clean and Build
```bash
# Clean previous builds
rm -rf dist/ build/ *.egg-info

# Build the package
python3 -m build
```

### 4. Test on TestPyPI
```bash
# Upload to TestPyPI
python3 -m twine upload --repository testpypi dist/*

# Test installation from TestPyPI
pip install -i https://test.pypi.org/simple/ hylang-migrations
```

### 5. Release to PyPI
```bash
# Upload to production PyPI
python3 -m twine upload dist/*
```

### 6. Tag the Release
```bash
git tag -a v0.1.0 -m "Release v0.1.0"
git push origin v0.1.0
```

## Using dodo.hy Tasks

The project includes a `dodo.hy` file with automation tasks:

```bash
# Install doit
pip install doit

# Build the package
python3 -c "import hy; from dodo import task_build; task_build()"

# Run tests
python3 -c "import hy; from dodo import task_test; task_test()"

# Clean build artifacts
python3 -c "import hy; from dodo import task_clean; task_clean()"
```

## Package Structure

The built package includes:
- Source distribution (`.tar.gz`): Complete source with demos and tools
- Wheel (`.whl`): Installable package with Hy source files
- Entry points: `hylang-migrate` and `hy-migrate` CLI commands

## Testing the Package

After installation, test with:

```bash
# Check CLI is installed
hylang-migrate --help

# Run demo
cd demo
hy run_demo.hy

# Test migrations
hylang-migrate init --db test.db
hylang-migrate create --name create_test_table
hylang-migrate migrate --db test.db
hylang-migrate status --db test.db
```

## Troubleshooting

### Import Errors
- Ensure Hy is installed: `pip install hy>=1.0.0`
- Hy files use hyphens, Python uses underscores in function names

### Build Issues
- Clean all artifacts: `rm -rf dist/ build/ *.egg-info __pycache__`
- Ensure hatchling is installed: `pip install --upgrade build hatchling`

### TestPyPI Issues
- Dependencies might not be available on TestPyPI
- Install dependencies from PyPI first, then the package from TestPyPI

## Support

Report issues at: https://github.com/yourusername/hylang-migrations/issues