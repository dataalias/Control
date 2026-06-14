# Installation Guide for eimutils

## Quick Install

```bash
pip install eimutils
```

## Troubleshooting PyArrow Build Issues

If you encounter PyArrow build errors during installation, try these solutions:

### Option 1: Use Binary-Only Installation (Recommended)
```bash
# Install with binary constraints to avoid building from source
pip install -c constraints.txt eimutils

# Or install PyArrow separately first
pip install --only-binary=pyarrow pyarrow>=14.0.0
pip install eimutils
```

### Option 2: Install with Pre-built Dependencies
```bash
# Force binary installation for problematic packages
pip install --only-binary=:all: eimutils
```

### Option 3: Install Build Tools (Windows)
If you must build from source:
```bash
# Install build dependencies
pip install cmake ninja wheel

# Then install eimutils
pip install eimutils
```

### Option 4: Use Conda (Alternative)
```bash
# Conda typically has pre-built binaries
conda install -c conda-forge pyarrow pandas
pip install eimutils
```

## Development Installation

For development with all optional dependencies:

```bash
# Clone the repository
git clone <repository-url>
cd eim_deutils/python

# Install in development mode with constraints
pip install -c constraints.txt -e ".[dev,test,docs]"

# Or with build tools if needed
pip install -e ".[dev,test,docs,build]"
```

## Environment Requirements

- Python 3.9 or higher
- Windows: Visual Studio Build Tools or equivalent (if building from source)
- macOS: Xcode Command Line Tools (if building from source)
- Linux: GCC compiler suite (if building from source)

## Common Issues

### "Building wheel for pyarrow failed"
**Solution**: Use the binary-only installation methods above.

### "Microsoft Visual C++ 14.0 is required" (Windows)
**Solution**: 
1. Install Microsoft Build Tools for Visual Studio
2. Or use pre-built binaries with `--only-binary=:all:`

### "cmake not found"
**Solution**: Install cmake: `pip install cmake`

## Verification

Test your installation:
```python
import eimutils
from eimutils.step_logger import StepLogger
print("eimutils installed successfully!")
```
