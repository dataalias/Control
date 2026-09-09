# StepLoggerSnowflake - Quick Reference Card

## 📦 Deployment (One-Time Setup)

```powershell
# Build package
cd python_snowflake
.\deployment\build_and_deploy.ps1
```

```sql
-- Upload to Snowflake
PUT file://C:/Users/frankf/source/eim_deutils/python_snowflake/dist/eimutils_snowflake.zip
@ULTRA_DEV_RAW.DATA_HUB.EIM_LIBS_DEV 
OVERWRITE=TRUE;
```

## 🔧 Stored Procedure Template

```sql
CREATE OR REPLACE PROCEDURE MY_PROCEDURE(PARAM1 VARCHAR, PARAM2 VARCHAR)
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.9'
PACKAGES = ('snowflake-snowpark-python')
IMPORTS = ('@ULTRA_DEV_RAW.DATA_HUB.EIM_LIBS_DEV/eimutils_snowflake.zip')
HANDLER = 'my_handler'
AS
$$
from eimutils_snowflake import StepLoggerSnowflake

def my_handler(session, param1: str, param2: str):
    logger = StepLoggerSnowflake(
        session=session,
        etl_execution_id="your-unique-id",
        process_name="Process_Name"
    )
    
    try:
        # Your code here
        logger.start_step("Step_Name")
        logger.log_step("SUCCESS", record_count=100)
    finally:
        logger.close()
    
    return "Success"
$$;
```

## 📝 Basic Usage Pattern

```python
from eimutils_snowflake import StepLoggerSnowflake

def run_etl(session, execution_id: str):
    # 1. Initialize
    logger = StepLoggerSnowflake(
        session=session,
        etl_execution_id=execution_id,
        process_name="My_Process"
    )
    
    try:
        # 2. Start a step
        logger.start_step("Extract_Data", operation="EXTRACT")
        
        # ... do work ...
        
        # 3. Log completion
        logger.log_step(
            "SUCCESS",
            "Extracted 1000 records",
            record_count=1000
        )
        
    finally:
        # 4. Always close
        logger.close()
```

## 🎯 Common Patterns

### Simple Linear Process
```python
logger.start_step("Extract")
logger.log_step("SUCCESS", record_count=1000)

logger.start_step("Transform")
logger.log_step("SUCCESS", record_count=950)

logger.start_step("Load")
logger.log_step("SUCCESS", record_count=950, db_name="TARGET_DB")
```

### With Custom Attributes
```python
logger.start_step("Process_Data")
logger.log_step(
    "SUCCESS",
    "Processing complete",
    record_count=1000,
    custom_attributes={
        "filter_rate": 0.05,
        "source_system": "SAP",
        "query_time_ms": 245
    }
)
```

### With Nested Steps (Context Manager)
```python
logger.start_step("Extract_All")

with logger.step_context("Extract_Source_A"):
    # Work for Source A
    logger.log_step("SUCCESS", record_count=500)

with logger.step_context("Extract_Source_B"):
    # Work for Source B
    logger.log_step("SUCCESS", record_count=600)

logger.log_step("SUCCESS", record_count=1100)
```

### Error Handling
```python
try:
    logger.start_step("Risky_Operation")
    # ... operation that might fail ...
    logger.log_step("SUCCESS")
except Exception as e:
    logger.log_step("FAILED", f"Error: {str(e)}")
    raise  # Re-raise to fail the procedure
```

## 🔍 Querying Logs

### All Steps for an Execution
```sql
SELECT 
    Step_Log_Id,
    Step_Name,
    Step_Status,
    Duration_In_Seconds,
    Record_Count
FROM ULTRA_DEV_RAW.DATA_HUB.STEP_LOG
WHERE ETL_Execution_Id = 'your-execution-id'
ORDER BY Step_Log_Id;
```

### Extract Custom Attributes
```sql
SELECT 
    Step_Name,
    Step_Desc:Operation::STRING as operation,
    Step_Desc:Description::STRING as description,
    Step_Desc:filter_rate::FLOAT as filter_rate,
    Step_Desc:source_system::STRING as source_system
FROM ULTRA_DEV_RAW.DATA_HUB.STEP_LOG
WHERE ETL_Execution_Id = 'your-execution-id';
```

### Step Hierarchy (Parent-Child)
```sql
WITH RECURSIVE step_tree AS (
    -- Root
    SELECT 
        Step_Log_Id,
        Parent_Log_Id,
        Step_Name,
        0 as level
    FROM ULTRA_DEV_RAW.DATA_HUB.STEP_LOG
    WHERE Parent_Log_Id = 0
        AND ETL_Execution_Id = 'your-execution-id'
    
    UNION ALL
    
    -- Children
    SELECT 
        s.Step_Log_Id,
        s.Parent_Log_Id,
        s.Step_Name,
        st.level + 1
    FROM ULTRA_DEV_RAW.DATA_HUB.STEP_LOG s
    JOIN step_tree st ON s.Parent_Log_Id = st.Step_Log_Id
)
SELECT 
    REPEAT('  ', level) || Step_Name as hierarchy,
    Step_Log_Id
FROM step_tree
ORDER BY Step_Log_Id;
```

### Failed Processes
```sql
SELECT DISTINCT
    ETL_Execution_Id,
    Process_Name,
    MAX(Start_Dtm) as last_run
FROM ULTRA_DEV_RAW.DATA_HUB.STEP_LOG
WHERE Step_Status = 'FAILED'
GROUP BY ETL_Execution_Id, Process_Name
ORDER BY last_run DESC;
```

## 🔑 Required Stored Procedure Elements

✅ **Must have all of these:**
- `RETURNS VARCHAR` (or other type)
- `LANGUAGE PYTHON`
- `RUNTIME_VERSION = '3.9'`
- `PACKAGES = ('snowflake-snowpark-python')`
- `IMPORTS = ('@STAGE/eimutils_snowflake.zip')`
- `HANDLER = 'function_name'`

## ⚠️ Common Mistakes

❌ **DON'T:**
```python
# Missing finally block
logger = StepLoggerSnowflake(...)
logger.start_step("Step1")
logger.log_step("SUCCESS")
# ❌ Forgot to close!

# Reusing same execution ID
logger = StepLoggerSnowflake(
    etl_execution_id="hardcoded-id"  # ❌ Not unique!
)
```

✅ **DO:**
```python
# Always use try/finally
logger = StepLoggerSnowflake(...)
try:
    logger.start_step("Step1")
    logger.log_step("SUCCESS")
finally:
    logger.close()  # ✅ Always closes

# Use unique IDs
import uuid
logger = StepLoggerSnowflake(
    etl_execution_id=str(uuid.uuid4())  # ✅ Unique!
)
```

## 📊 Step Status Values

- `SUCCESS` - Step completed successfully
- `FAILED` - Step encountered an error
- `INFO` - Informational log entry
- `WARNING` - Warning condition

## 🔄 Update Process

When you update the code:

```powershell
# 1. Rebuild
cd python_snowflake
.\deployment\build_and_deploy.ps1
```

```sql
-- 2. Re-upload
PUT file://C:/Users/frankf/source/eim_deutils/python_snowflake/dist/eimutils_snowflake.zip
@ULTRA_DEV_RAW.DATA_HUB.EIM_LIBS_DEV 
OVERWRITE=TRUE;

-- 3. Recreate procedures (Snowflake caches imports)
CREATE OR REPLACE PROCEDURE MY_PROCEDURE(...)
...
```

## 📞 Need Help?

- Full documentation: `python_snowflake/README.md`
- Deployment guide: `python_snowflake/deployment/DEPLOYMENT_INSTRUCTIONS.md`
- Example procedures: `python_snowflake/deployment/deploy_with_wheel.sql`

