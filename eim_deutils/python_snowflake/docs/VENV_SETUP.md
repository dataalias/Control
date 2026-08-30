# 🐍 Virtual Environment Setup for StepLoggerSnowflake

## Overview

This project uses a dedicated virtual environment named `.venv_snow` to isolate Snowflake dependencies from other Python projects.

---

## ⚡ Quick Start

### Windows PowerShell
```powershell
.\activate_venv.ps1
```

### Windows Command Prompt
```cmd
activate_venv.bat
```

### Linux/Mac
```bash
source .venv_snow/bin/activate
```

---

## 📦 Manual Setup

### 1. Create Virtual Environment

```bash
# From the python_snowflake directory
python -m venv .venv_snow
```

### 2. Activate Virtual Environment

**Windows PowerShell:**
```powershell
.venv_snow\Scripts\Activate.ps1
```

**Windows CMD:**
```cmd
.venv_snow\Scripts\activate.bat
```

**Linux/Mac:**
```bash
source .venv_snow/bin/activate
```

### 3. Upgrade pip

```bash
python -m pip install --upgrade pip setuptools wheel
```

### 4. Install Dependencies

```bash
pip install -r requirements.txt
```

---

## 📋 Installed Packages

The virtual environment includes:

- **snowflake-snowpark-python** - Snowpark for Python (core)
- **snowflake-connector-python** - Snowflake connector (for deployment)
- All required dependencies

---

## 🔍 Verify Installation

```bash
# Check Python version
python --version

# List installed packages
pip list

# Check Snowflake packages specifically
pip list | grep snowflake
```

---

## 🎯 Using the Virtual Environment

### Run Examples

```bash
# Activate venv first
.\activate_venv.ps1

# Run examples (requires Snowflake connection)
python examples/basic_usage.py
```

### Deploy to Snowflake

```bash
# Activate venv first
.\activate_venv.ps1

# Run deployment script
python deployment/deploy.py --env DEV --connection-file connection.json
```

### Interactive Python

```bash
# Activate venv
.\activate_venv.ps1

# Start Python
python

# Test imports
>>> from step_logger_snowflake import StepLoggerSnowflake
>>> from step_logger_factory import get_step_logger
>>> print("Success!")
```

---

## 🚪 Deactivating

To leave the virtual environment:

```bash
deactivate
```

---

## 🧹 Cleanup

To remove the virtual environment:

### Windows
```powershell
Remove-Item -Recurse -Force .venv_snow
```

### Linux/Mac
```bash
rm -rf .venv_snow
```

Then recreate using the steps above.

---

## 🔧 Troubleshooting

### PowerShell Execution Policy Error

**Error**: "cannot be loaded because running scripts is disabled"

**Solution**:
```powershell
# Run PowerShell as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Then try activating again
.\activate_venv.ps1
```

### Package Installation Fails

**Error**: "Could not find a version that satisfies the requirement"

**Solution**:
```bash
# Upgrade pip first
python -m pip install --upgrade pip

# Try installing again
pip install -r requirements.txt
```

### Import Errors

**Error**: "ModuleNotFoundError: No module named 'snowflake'"

**Solution**:
```bash
# Make sure venv is activated (you should see (.venv_snow) in prompt)
.\activate_venv.ps1

# If still fails, reinstall packages
pip install -r requirements.txt
```

---

## 📊 Virtual Environment Info

```bash
# Activate venv first
.\activate_venv.ps1

# Show Python location (should be in .venv_snow)
where python

# Show pip location (should be in .venv_snow)
where pip

# Show installed packages and their locations
pip show snowflake-snowpark-python
```

---

## 🎓 Best Practices

### DO:
✅ Always activate venv before working with the project
✅ Install all dependencies via `requirements.txt`
✅ Deactivate when switching to other projects
✅ Add `.venv_snow/` to `.gitignore`

### DON'T:
❌ Install packages globally (use venv)
❌ Commit `.venv_snow/` to git
❌ Mix packages from different environments
❌ Forget to activate before running code

---

## 🔄 Updating Dependencies

To update Snowflake packages:

```bash
# Activate venv
.\activate_venv.ps1

# Update specific package
pip install --upgrade snowflake-snowpark-python

# Or update all packages
pip install --upgrade -r requirements.txt

# Freeze updated versions (optional)
pip freeze > requirements_frozen.txt
```

---

## 📝 Environment Variables

The virtual environment automatically:
- Sets `PYTHONPATH` to include the venv
- Updates `PATH` to prioritize venv executables
- Isolates packages from system Python

No additional configuration needed!

---

## 🆘 Getting Help

If you encounter issues:

1. Check this guide's troubleshooting section
2. Verify Python version: `python --version` (should be 3.9+)
3. Check venv is activated: Look for `(.venv_snow)` in prompt
4. Try recreating venv from scratch
5. Review Snowflake documentation

---

## 🎉 Success!

When properly activated, you'll see:
```
(.venv_snow) C:\...\python_snowflake>
```

Your Python and pip commands now use the isolated environment! 🚀

---

*Virtual Environment Documentation - StepLoggerSnowflake*

