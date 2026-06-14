# Streamlit Deployment Guide with StepLoggerSnowflake Integration

This guide covers the complete process of deploying the DataHub Management System Streamlit app to Snowflake with StepLoggerSnowflake logging integration.

## Prerequisites

- Snowflake CLI (`snow`) installed and configured
- Access to Snowflake database `ULTRA_DEV_RAW` and schema `DATA_HUB`
- Python environment with required packages
- StepLoggerSnowflake wheel file (`eimutils_snowflake-1.0.0-py3-none-any.whl`)

## Overview

The deployment process involves:
1. Building the StepLoggerSnowflake package
2. Uploading the package to Snowflake stage
3. Deploying the Streamlit app
4. Verifying the integration

## Step 1: Build StepLoggerSnowflake Package

### 1.1 Navigate to Python Snowflake Directory
```bash
cd python_snowflake
```

### 1.2 Build the Wheel Package
```bash
python -m build
```

This creates the wheel file: `dist/eimutils_snowflake-1.0.0-py3-none-any.whl`

## Step 2: Upload StepLoggerSnowflake to Snowflake Stage

### 2.1 Create Stage (if not exists)
```sql
CREATE STAGE IF NOT EXISTS ULTRA_DEV_RAW.DATA_HUB.EIM_LIBS_DEV;
```

### 2.2 Upload Wheel File to Stage
```bash
snow stage upload @ULTRA_DEV_RAW.DATA_HUB.EIM_LIBS_DEV python_snowflake/dist/eimutils_snowflake-1.0.0-py3-none-any.whl
```

### 2.3 Verify Upload
```sql
LIST @ULTRA_DEV_RAW.DATA_HUB.EIM_LIBS_DEV;
```

You should see: `eimutils_snowflake-1.0.0-py3-none-any.whl`

## Step 3: Prepare Streamlit App Files

### 3.1 Ensure Required Files Exist
The `dhui` folder should contain:
- `snowflake_streamlit_app.py` - Main Streamlit application
- `environment.yml` - Package dependencies
- `snowflake.yml` - Streamlit configuration
- `eimutils_snowflake/` - Local StepLoggerSnowflake package (fallback)

### 3.2 Verify StepLoggerSnowflake Import Strategy
The app uses the `stage_download` method:
```python
# Import StepLoggerSnowflake from stage
from snowflake.snowpark import Session as SnowparkSession

# Get current session and download from stage
session = SnowparkSession.builder.getOrCreate()
session.file.get(
    "@ULTRA_DEV_RAW.DATA_HUB.EIM_LIBS_DEV/eimutils_snowflake-1.0.0-py3-none-any.whl",
    "/tmp/"
)

# Add to Python path and import
import sys
sys.path.append('/tmp/eimutils_snowflake-1.0.0-py3-none-any.whl')
from step_logger_snowflake import StepLoggerSnowflake

STEP_LOGGER_AVAILABLE = True
IMPORT_METHOD = "stage_download"
```

## Step 4: Deploy Streamlit App

### 4.1 Navigate to dhui Directory
```bash
cd dhui
```

### 4.2 Deploy Using Snowflake CLI
```bash
snow streamlit deploy datahub_management_system --database ULTRA_DEV_RAW --schema DATA_HUB --replace
```

### 4.3 Verify Deployment
The command should complete successfully with output similar to:
```
Streamlit app 'datahub_management_system' successfully deployed.
```

## Step 5: Verify StepLoggerSnowflake Integration

### 5.1 Access the Streamlit App
1. Open Snowflake UI
2. Navigate to Apps → Streamlit
3. Open `datahub_management_system`

### 5.2 Test UI Operations
1. Navigate to any table (Publisher, Publication, Subscriber, etc.)
2. Update a record
3. Check that the operation completes successfully

### 5.3 Verify Logging
Check the `DATA_HUB.STEP_LOG` table for new entries:
```sql
SELECT * FROM DATA_HUB.STEP_LOG 
WHERE PROCESS_NAME = 'Streamlit_UI_Operations'
ORDER BY CREATED_DTM DESC
LIMIT 10;
```

You should see entries with:
- `PROCESS_NAME`: 'Streamlit_UI_Operations'
- `STEP_NAME`: 'UPDATE_Publisher' (or similar)
- `STATUS`: 'SUCCESS' or 'FAILED'
- `CUSTOM_ATTRIBUTES`: JSON with operation details

## Troubleshooting

### Issue: StepLoggerSnowflake Import Fails
**Symptoms**: UI operations work but no logging occurs

**Solutions**:
1. Verify stage file exists:
   ```sql
   LIST @ULTRA_DEV_RAW.DATA_HUB.EIM_LIBS_DEV;
   ```

2. Check file permissions:
   ```sql
   GRANT USAGE ON STAGE ULTRA_DEV_RAW.DATA_HUB.EIM_LIBS_DEV TO ROLE YOUR_ROLE;
   ```

3. Re-upload the wheel file if needed

### Issue: Streamlit Deployment Fails
**Symptoms**: `snow streamlit deploy` command fails

**Solutions**:
1. Check Snowflake CLI configuration:
   ```bash
   snow connection list
   ```

2. Verify database and schema access:
   ```sql
   USE DATABASE ULTRA_DEV_RAW;
   USE SCHEMA DATA_HUB;
   ```

3. Check if app already exists and needs replacement:
   ```bash
   snow streamlit list --database ULTRA_DEV_RAW --schema DATA_HUB
   ```

### Issue: Environment Dependencies Missing
**Symptoms**: App fails to start or import errors

**Solutions**:
1. Verify `environment.yml` contains required packages:
   ```yaml
   name: sf_env
   channels:
     - snowflake
   dependencies:
     - snowflake-snowpark-python
   ```

2. Check Snowflake Anaconda channel availability

## File Structure After Deployment

```
dhui/
├── docs/
│   └── STREAMLIT_DEPLOYMENT_GUIDE.md
├── eimutils_snowflake/
│   ├── __init__.py
│   └── step_logger_snowflake.py
├── environment.yml
├── snowflake_streamlit_app.py
└── snowflake.yml
```

## Key Configuration Files

### environment.yml
```yaml
name: sf_env
channels:
  - snowflake
dependencies:
  - snowflake-snowpark-python
```

### snowflake.yml
```yaml
definition_version: 1
streamlit:
  name: datahub_management_system
  main_file: snowflake_streamlit_app.py
  query_warehouse: DEV_WH_R
```

## Monitoring and Maintenance

### Regular Checks
1. **Stage File Integrity**: Periodically verify the wheel file in the stage
2. **Log Table Growth**: Monitor `DATA_HUB.STEP_LOG` table size
3. **App Performance**: Check Streamlit app response times

### Updates
1. **Code Changes**: Update `snowflake_streamlit_app.py` and redeploy
2. **Package Updates**: Rebuild and re-upload wheel file if StepLoggerSnowflake changes
3. **Dependencies**: Update `environment.yml` for new package requirements

## Security Considerations

1. **Stage Access**: Ensure only authorized roles can access the stage
2. **Log Data**: StepLoggerSnowflake logs sensitive operation data
3. **User Permissions**: Verify users have appropriate database permissions

## Performance Optimization

1. **Caching**: The app uses `@st.cache_data` for database queries
2. **Session Management**: StepLoggerSnowflake instances are reused in session state
3. **Batch Operations**: Consider batching multiple UI operations for efficiency

---

## Quick Reference Commands

```bash
# Build package
cd python_snowflake && python -m build

# Upload to stage
snow stage upload @ULTRA_DEV_RAW.DATA_HUB.EIM_LIBS_DEV python_snowflake/dist/eimutils_snowflake-1.0.0-py3-none-any.whl

# Deploy Streamlit app
cd dhui && snow streamlit deploy datahub_management_system --database ULTRA_DEV_RAW --schema DATA_HUB --replace

# Verify logging
# Run in Snowflake SQL editor:
SELECT * FROM DATA_HUB.STEP_LOG WHERE PROCESS_NAME = 'Streamlit_UI_Operations' ORDER BY CREATED_DTM DESC LIMIT 10;
```

This completes the deployment process for the DataHub Management System with StepLoggerSnowflake integration.
