# 🚀 StepLoggerSnowflake Deployment Guide

## 📋 Overview

This guide covers deploying StepLoggerSnowflake to your Snowflake environment for production use.

---

## 🎯 Deployment Options

### Option 1: Stored Procedure (Recommended for Production)

Best for:
- Scheduled tasks
- Callable from SQL
- Multiple user access
- Production workflows

### Option 2: Python Worksheet (Best for Development)

Best for:
- Ad-hoc analysis
- Development and testing
- Quick prototyping
- Single user scenarios

### Option 3: Native App Package (Advanced)

Best for:
- Cross-account distribution
- Marketplace deployment
- External customers

---

## 🛠️ Prerequisites

### 1. Database Objects

Ensure these objects exist in your Snowflake environment:

```sql
-- Check if STEP_LOG table exists
SELECT * FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'DATA_HUB'
  AND TABLE_NAME = 'STEP_LOG';

-- Check if sequence exists
SELECT * FROM INFORMATION_SCHEMA.SEQUENCES
WHERE SEQUENCE_SCHEMA = 'DATA_HUB'
  AND SEQUENCE_NAME = 'SEQ__STEP_LOG_ID';

-- Check if STEP_DESC is VARIANT
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'DATA_HUB'
  AND TABLE_NAME = 'STEP_LOG'
  AND COLUMN_NAME = 'STEP_DESC';
```

If missing, run migration:

```sql
-- Create/update table structure
@database_change/V10__EIMARC-6701--StepLogger__StepDesc__Variant.sql
```

### 2. Permissions

Verify you have necessary permissions:

```sql
-- Test permissions
USE DATABASE ULTRA_DEV_RAW;
USE SCHEMA DATA_HUB;

-- Should succeed if you have permissions
SELECT CURRENT_DATABASE(), CURRENT_SCHEMA(), CURRENT_ROLE();

-- Test sequence access
SELECT DATA_HUB.SEQ__STEP_LOG_ID.NEXTVAL;

-- Test table insert
INSERT INTO DATA_HUB.STEP_LOG
SELECT 
    DATA_HUB.SEQ__STEP_LOG_ID.NEXTVAL,
    -1, 'TEST', 'ETL', 'TEST_STEP',
    PARSE_JSON('{"test": true}'),
    'SUCCESS',
    CURRENT_TIMESTAMP(),
    0, NULL, 0,
    'test-' || UUID_STRING();

-- Clean up test
DELETE FROM DATA_HUB.STEP_LOG WHERE Process_Name = 'TEST';
```

### 3. Python Dependencies

In Snowflake, only these packages are needed:
- `snowflake-snowpark-python` (always available)

No additional packages required!

---

## 📦 Deployment Steps

### Step 1: Upload Python Files

#### Option A: Using SnowSQL

```bash
# Connect to Snowflake
snowsql -a your-account -u your-user

# Upload files
PUT file://step_logger_snowflake.py @DATA_HUB.PYTHON_MODULES/step_logger/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
PUT file://step_logger_factory.py @DATA_HUB.PYTHON_MODULES/step_logger/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

# Verify
LIST @DATA_HUB.PYTHON_MODULES/step_logger/;
```

#### Option B: Using Snowsight

1. Navigate to **Data** → **Databases** → **DATA_HUB** → **Stages**
2. Create stage `PYTHON_MODULES` if not exists
3. Upload files via UI

#### Option C: Using SQL

```sql
-- Create stage
CREATE STAGE IF NOT EXISTS DATA_HUB.PYTHON_MODULES
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Python modules for stored procedures';

-- Upload files (requires SnowSQL or programmatic access)
-- See Option A or use deployment script
```

### Step 2: Deploy Stored Procedures

```sql
-- Run deployment script
@python_snowflake/deployment/deploy_stored_procedure.sql
```

This creates:
- `SP_LOG_ETL_STEP`: Simple step logging procedure
- `SP_EXAMPLE_ETL_PROCESS`: Full example with StepLogger pattern

### Step 3: Grant Permissions

```sql
-- Grant to service role
GRANT USAGE ON STAGE DATA_HUB.PYTHON_MODULES TO ROLE PIPELINE_DEV_SVC;
GRANT USAGE ON DATABASE ULTRA_DEV_RAW TO ROLE PIPELINE_DEV_SVC;
GRANT USAGE ON SCHEMA DATA_HUB TO ROLE PIPELINE_DEV_SVC;
GRANT SELECT, INSERT ON TABLE DATA_HUB.STEP_LOG TO ROLE PIPELINE_DEV_SVC;
GRANT USAGE ON SEQUENCE DATA_HUB.SEQ__STEP_LOG_ID TO ROLE PIPELINE_DEV_SVC;

-- Grant execute on procedures
GRANT USAGE ON PROCEDURE DATA_HUB.SP_LOG_ETL_STEP(...) TO ROLE PIPELINE_DEV_SVC;
GRANT USAGE ON PROCEDURE DATA_HUB.SP_EXAMPLE_ETL_PROCESS(...) TO ROLE PIPELINE_DEV_SVC;
```

### Step 4: Test Deployment

```sql
-- Test simple logging
CALL DATA_HUB.SP_LOG_ETL_STEP(
    'test-' || UUID_STRING(),
    'Deployment_Test',
    'Test_Step',
    'SUCCESS',
    PARSE_JSON('{"test": "deployment"}'),
    1,
    100
);

-- Test full process
CALL DATA_HUB.SP_EXAMPLE_ETL_PROCESS('Test_Process', 'test-' || UUID_STRING());

-- Verify logs
SELECT * FROM DATA_HUB.STEP_LOG
WHERE Process_Name IN ('Deployment_Test', 'Test_Process')
ORDER BY Step_Log_Id DESC;
```

---

## 🤖 Automated Deployment

### Using Deployment Script

```bash
# 1. Create connection file
cat > connection.json << EOF
{
  "account": "your-account",
  "user": "your-user",
  "password": "your-password",
  "warehouse": "DEV_WH_R"
}
EOF

# 2. Run deployment
python python_snowflake/deployment/deploy.py \
    --env DEV \
    --connection-file connection.json \
    --source-dir python_snowflake

# 3. Verify output
# ✓ Connected successfully
# ✓ Uploading Python files...
# ✓ Creating stored procedures...
# ✓ Granting permissions...
# ✓ Running validation tests...
# ✓ Deployment completed successfully!
```

### Deployment Script Options

```bash
python deployment/deploy.py \
    --env DEV|STAGE|PROD \              # Target environment
    --connection-file connection.json \  # Connection parameters
    --source-dir python_snowflake \      # Source directory
    --role PIPELINE_DEV_SVC             # Target role (optional)
```

---

## 📝 Usage After Deployment

### In Python Worksheet

```python
from snowflake.snowpark.context import get_active_session
from step_logger_snowflake import StepLoggerSnowflake
import uuid

session = get_active_session()
logger = StepLoggerSnowflake(
    session=session,
    etl_execution_id=str(uuid.uuid4()),
    process_name="My_Process"
)

try:
    logger.start_step("Extract")
    # ... processing ...
    logger.log_step("SUCCESS", record_count=1000)
finally:
    logger.close()
```

### In Stored Procedure

```sql
CREATE OR REPLACE PROCEDURE MY_ETL_PROCESS()
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.9'
PACKAGES = ('snowflake-snowpark-python')
IMPORTS = ('@DATA_HUB.PYTHON_MODULES/step_logger/step_logger_snowflake.py')
HANDLER = 'run_process'
AS
$$
from step_logger_snowflake import StepLoggerSnowflake
import uuid

def run_process(session):
    logger = StepLoggerSnowflake(
        session=session,
        etl_execution_id=str(uuid.uuid4()),
        process_name="MY_ETL_PROCESS"
    )
    
    try:
        logger.start_step("Process_Data")
        # ... your logic ...
        logger.log_step("SUCCESS", record_count=1000)
    finally:
        logger.close()
    
    return "Success"
$$;

-- Call it
CALL MY_ETL_PROCESS();
```

### In Scheduled Task

```sql
CREATE OR REPLACE TASK DAILY_ETL_TASK
    WAREHOUSE = DEV_WH_R
    SCHEDULE = 'USING CRON 0 2 * * * UTC'
AS
    CALL MY_ETL_PROCESS();

-- Resume task
ALTER TASK DAILY_ETL_TASK RESUME;
```

---

## 🔍 Verification & Monitoring

### Check Deployment Status

```sql
-- List stages
SHOW STAGES IN SCHEMA DATA_HUB;

-- List files in stage
LIST @DATA_HUB.PYTHON_MODULES/step_logger/;

-- List stored procedures
SHOW PROCEDURES IN SCHEMA DATA_HUB;

-- Check recent logs
SELECT 
    Process_Name,
    Step_Name,
    Step_Status,
    Start_Dtm,
    Duration_In_Seconds,
    Record_Count
FROM DATA_HUB.STEP_LOG
ORDER BY Step_Log_Id DESC
LIMIT 20;
```

### Monitor Performance

```sql
-- Process execution times
SELECT 
    Process_Name,
    COUNT(*) as num_steps,
    SUM(Duration_In_Seconds) as total_duration,
    SUM(Record_Count) as total_records,
    MAX(Start_Dtm) as last_run
FROM DATA_HUB.STEP_LOG
WHERE Step_Status = 'END'
GROUP BY Process_Name
ORDER BY last_run DESC;

-- Failed steps
SELECT *
FROM DATA_HUB.STEP_LOG
WHERE Step_Status = 'FAILED'
ORDER BY Start_Dtm DESC;
```

---

## 🔧 Troubleshooting Deployment

### Issue: Cannot upload to stage

**Error**: `PUT file not found` or `Permission denied`

**Solution**:
```sql
-- Check stage exists
SHOW STAGES LIKE 'PYTHON_MODULES' IN DATA_HUB;

-- Recreate if needed
CREATE OR REPLACE STAGE DATA_HUB.PYTHON_MODULES;

-- Check permissions
SHOW GRANTS ON STAGE DATA_HUB.PYTHON_MODULES;

-- Grant if needed
GRANT READ, WRITE ON STAGE DATA_HUB.PYTHON_MODULES TO ROLE your_role;
```

### Issue: Stored procedure creation fails

**Error**: `SQL compilation error` or `Invalid procedure definition`

**Solution**:
```sql
-- Check syntax of procedure
-- Ensure IMPORTS path matches uploaded files
-- Verify HANDLER function name matches code

-- Test simpler procedure first
CREATE OR REPLACE PROCEDURE TEST_SP()
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.9'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'test'
AS
$$
def test(session):
    return "Hello from Snowflake!"
$$;

CALL TEST_SP();
```

### Issue: Import not found in stored procedure

**Error**: `ModuleNotFoundError: No module named 'step_logger_snowflake'`

**Solution**:
```sql
-- Verify file is uploaded
LIST @DATA_HUB.PYTHON_MODULES/step_logger/;

-- Ensure IMPORTS matches uploaded path
IMPORTS = ('@DATA_HUB.PYTHON_MODULES/step_logger/step_logger_snowflake.py')

-- Try inline code instead (for testing)
-- See deploy_stored_procedure.sql for inline example
```

### Issue: Permission denied on STEP_LOG

**Error**: `Insufficient privileges to operate on table 'STEP_LOG'`

**Solution**:
```sql
-- Check current role
SELECT CURRENT_ROLE();

-- Check table grants
SHOW GRANTS ON TABLE DATA_HUB.STEP_LOG;

-- Grant necessary permissions
GRANT SELECT, INSERT ON TABLE DATA_HUB.STEP_LOG TO ROLE your_role;
GRANT USAGE ON SEQUENCE DATA_HUB.SEQ__STEP_LOG_ID TO ROLE your_role;
```

---

## 🔄 Updating Deployment

### Update Python Files

```bash
# 1. Upload new version
PUT file://step_logger_snowflake.py 
    @DATA_HUB.PYTHON_MODULES/step_logger/ 
    AUTO_COMPRESS=FALSE 
    OVERWRITE=TRUE;

# 2. Recreate stored procedures that use it
CREATE OR REPLACE PROCEDURE ...
```

### Update Stored Procedures

```sql
-- Simply re-run the CREATE OR REPLACE
@python_snowflake/deployment/deploy_stored_procedure.sql

-- Or manually
CREATE OR REPLACE PROCEDURE DATA_HUB.MY_PROCEDURE(...)
...
```

---

## 🌍 Multi-Environment Deployment

### Deploy to Multiple Environments

```bash
# Development
python deployment/deploy.py --env DEV --connection-file conn_dev.json

# Staging
python deployment/deploy.py --env STAGE --connection-file conn_stage.json

# Production
python deployment/deploy.py --env PROD --connection-file conn_prod.json
```

### Environment-Specific Configuration

```sql
-- Use environment-specific databases
-- DEV:   ULTRA_DEV_RAW
-- STAGE: ULTRA_STAGE_RAW
-- PROD:  ULTRA_PROD_RAW

-- Example with variable
SET env = 'DEV';
SET database = 'ULTRA_' || $env || '_RAW';

USE DATABASE IDENTIFIER($database);
```

---

## ✅ Post-Deployment Checklist

- [ ] Python files uploaded to stage
- [ ] Stored procedures created successfully
- [ ] Permissions granted to appropriate roles
- [ ] Test procedure executes without errors
- [ ] Sample logs appear in STEP_LOG table
- [ ] Query STEP_LOG with JSON fields works
- [ ] Documentation updated with environment-specific details
- [ ] Team notified of new deployment
- [ ] Monitoring/alerting configured (if applicable)

---

## 📞 Support

For deployment issues:

1. Check [Troubleshooting](#troubleshooting-deployment) section
2. Review Snowflake query history for errors
3. Check `ACCOUNT_USAGE.QUERY_HISTORY` for details
4. Contact data engineering team

---

## 📚 Additional Resources

- [Snowflake Stored Procedures Documentation](https://docs.snowflake.com/en/sql-reference/stored-procedures-python)
- [Snowpark Python Developer Guide](https://docs.snowflake.com/en/developer-guide/snowpark/python/index)
- [Snowflake Tasks Documentation](https://docs.snowflake.com/en/user-guide/tasks-intro)

---

*Happy Deploying! 🚀*

