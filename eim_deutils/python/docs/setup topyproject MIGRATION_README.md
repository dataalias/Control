# Migration from setup.py to pyproject.toml

This document explains the migration from the traditional `setup.py` configuration to the modern `pyproject.toml` format.

## What Changed

### Before (setup.py)
```python
from setuptools import setup, find_packages

setup(
    name='eimutils',
    version='1.6.0',
    author='Frank Fortunato',
    description='This project is a wrapper library to call utility functions.',
    packages=find_packages(),
    python_requires=">=3.9",
)
```

### After (pyproject.toml)
```toml
[project]
name = "eimutils"
version = "1.6.0"
description = "This project is a wrapper library to call utility functions."
authors = [{name = "Frank Fortunato"}]
requires-python = ">=3.9"

[tool.setuptools]
packages = ["eimutils"]
```

## Benefits of pyproject.toml

1. **Standard Format**: PEP 518/621 standardized format for Python project configuration
2. **Better Tool Integration**: Works seamlessly with modern Python tools
3. **Cleaner Dependencies**: Clear separation of build-time and runtime dependencies
4. **Version Management**: Dynamic versioning from package attributes
5. **Tool Configuration**: Centralized configuration for multiple tools

## New Features Added

### Dependencies
- **Core Dependencies**: boto3, snowflake-connector-python, usaddress, cryptography, requests
- **Development Dependencies**: pytest, black, flake8, mypy, pre-commit
- **Documentation Dependencies**: sphinx, sphinx-rtd-theme, myst-parser

### Tool Configuration
- **Black**: Code formatting with 88 character line length
- **Flake8**: Linting with extended ignore rules
- **MyPy**: Type checking with strict settings
- **Pytest**: Testing with markers and configuration

### Package Discovery
- **Automatic Package Finding**: Uses setuptools to find packages
- **Exclusions**: Automatically excludes test files and build artifacts
- **Package Data**: Includes markdown, text, and SQL files

## Migration Steps

### 1. Run the Migration Script
```bash
cd python/
python migrate_to_pyproject.py
```

### 2. Test the Build
```bash
# Install build tools
pip install build

# Build the package
python -m build

# Install in development mode
pip install -e .
```

### 3. Verify Installation
```python
import eimutils
print(eimutils.__version__)  # Should print "1.6.0"
```

## Configuration Details

### Build System
```toml
[build-system]
requires = ["setuptools>=80.1.0", "wheel"]
build-backend = "setuptools.build_meta"
```

### Project Metadata
```toml
[project]
name = "eimutils"
version = "1.6.0"
description = "This project is a wrapper library to call utility functions."
readme = "README.md"
requires-python = ">=3.9"
license = {text = "MIT"}
authors = [{name = "Frank Fortunato"}]
```

### Dependencies
```toml
dependencies = [
    "boto3>=1.26.0",
    "snowflake-connector-python>=3.0.0",
    "usaddress>=0.3.0",
    "cryptography>=3.4.0",
    "requests>=2.28.0"
]
```

### Optional Dependencies
```toml
[project.optional-dependencies]
dev = ["pytest>=7.0.0", "black>=23.0.0", "flake8>=6.0.0"]
test = ["pytest>=7.0.0", "pytest-cov>=4.0.0"]
docs = ["sphinx>=6.0.0", "sphinx-rtd-theme>=1.2.0"]
```

## Usage Examples

### Install with Development Dependencies
```bash
pip install -e ".[dev]"
```

### Install with Test Dependencies
```bash
pip install -e ".[test]"
```

### Install with Documentation Dependencies
```bash
pip install -e ".[docs]"
```

## Tool Usage

### Code Formatting
```bash
# Format code with Black
black .

# Check formatting without changes
black --check .
```

### Linting
```bash
# Run flake8
flake8

# Run with specific configuration
flake8 --config pyproject.toml
```

### Type Checking
```bash
# Run mypy
mypy .

# Run with specific configuration
mypy --config-file pyproject.toml .
```

### Testing
```bash
# Run all tests
pytest

# Run specific test markers
pytest -m "not slow"
pytest -m integration
pytest -m unit
```

## CI/CD Integration

### GitHub Actions Example
```yaml
name: Test and Build

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.9", "3.10", "3.11", "3.12"]
    
    steps:
    - uses: actions/checkout@v3
    - name: Set up Python ${{ matrix.python-version }}
      uses: actions/setup-python@v4
      with:
        python-version: ${{ matrix.python-version }}
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -e ".[test,dev]"
    
    - name: Run tests
      run: |
        pytest --cov=eimutils
    
    - name: Check code formatting
      run: |
        black --check .
        flake8 .
    
    - name: Type checking
      run: |
        mypy .
```

## Troubleshooting

### Common Issues

1. **Build Backend Not Found**
   ```bash
   pip install --upgrade setuptools wheel
   ```

2. **Package Not Found**
   - Ensure `__init__.py` exists in package directories
   - Check package discovery configuration

3. **Version Attribute Error**
   - Ensure `__version__` is defined in `__init__.py`
   - Check the attribute path in `pyproject.toml`

4. **Dependency Conflicts**
   - Use virtual environments
   - Check dependency versions in `requirements.txt`

### Rollback
If you need to rollback:
```bash
# Restore setup.py
cp setup.py.backup setup.py

# Remove pyproject.toml
rm pyproject.toml
```

## Next Steps

1. **Test Thoroughly**: Ensure all functionality works with the new configuration
2. **Update CI/CD**: Modify your CI/CD pipelines to use the new tools
3. **Team Training**: Train your team on the new development workflow
4. **Documentation**: Update your project documentation
5. **Cleanup**: Remove `setup.py` once you're confident everything works

## Resources

- [PEP 518 - Specifying Minimum Build System Requirements](https://peps.python.org/pep-0518/)
- [PEP 621 - Storing project metadata in pyproject.toml](https://peps.python.org/pep-0621/)
- [setuptools Documentation](https://setuptools.pypa.io/en/latest/userguide/pyproject_config.html)
- [Python Packaging User Guide](https://packaging.python.org/guides/using-pyproject-toml/)
