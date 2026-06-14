# 🏔️ StepLoggerSnowflake - Snowflake Native Implementation

## 📋 Overview

StepLoggerSnowflake is a Snowflake-native implementation of the StepLogger utility, designed to run directly within Snowflake's infrastructure using Snowpark. It provides comprehensive ETL process logging without requiring external connections or AWS dependencies.

### Key Features

- ✅ **Snowpark Native**: Uses Snowpark Session API (no external connectors)
- ✅ **No AWS Dependencies**: No AWS Secrets Manager or external authentication
- ✅ **Zero External Network Calls**: Runs entirely within Snowflake
- ✅ **VARIANT Support**: Native JSON storage with PARSE_JSON
- ✅ **Simple 4-Method Interface**: `__init__`, `start_step`, `log_step`, `close`
- ✅ **Automatic Timing**: Tracks duration between step start and completion
- ✅ **Hierarchical Logging**: Parent-child relationship tracking
- ✅ **Running Totals**: Automatic TOTAL_DURATION and TOTAL_COUNT tracking
- ✅ **Custom Attributes**: Flexible metadata support
- ✅ **Factory Pattern**: Auto-detects environment (Snowflake vs AWS Glue)

---

## 🚀 Quick Start

### 1. Build and Upload Package

```powershell
# Build the deployment package
cd python_snowflake
.\deployment\build_and_deploy.ps1
```

Then run the generated SQL commands in Snowflake:

```sql
-- Upload the package
PUT file://C:/Users/frankf/source/eim_deutils/python_snowflake/dist/eimutils_snowflake.zip
@ULTRA_DEV_RAW.DATA_HUB.EIM_LIBS_DEV 
OVERWRITE=TRUE;

-- Verify upload
LIST @ULTRA_DEV_RAW.DATA_HUB.EIM_LIBS_DEV PATTERN='.*eimutils_snowflake.*';
```

### 2. Create Stored Procedure

```sql
CREATE OR REPLACE PROCEDURE MY_ETL(
    PROCESS_NAME VARCHAR,
    EXECUTION_ID VARCHAR
)
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.9'
PACKAGES = ('snowflake-snowpark-python')
IMPORTS = ('@ULTRA_DEV_RAW.DATA_HUB.EIM_LIBS_DEV/eimutils_snowflake.zip')
HANDLER = 'run_etl'
AS
$$
from eimutils_snowflake import StepLoggerSnowflake

def run_etl(session, process_name: str, execution_id: str):
    logger = StepLoggerSnowflake(
        session=session,
        etl_execution_id=execution_id,
        process_name=process_name
    )
    
    try:
        # Step 1: Extract
        logger.start_step("Extract_Data", operation="EXTRACT")
        logger.log_step("SUCCESS", "Data extracted", record_count=1000)
        
        # Step 2: Transform
        logger.start_step("Transform_Data", operation="TRANSFORM")
        logger.log_step("SUCCESS", "Data transformed", record_count=950)
        
    finally:
        logger.close()
    
    return "Success"
$$;
```

### 3. Run Your ETL

```sql
CALL MY_ETL('My_Process', 'unique-execution-id-123');

-- Query the logs
SELECT * FROM ULTRA_DEV_RAW.DATA_HUB.STEP_LOG 
WHERE ETL_Execution_Id = 'unique-execution-id-123'
ORDER BY Step_Log_Id;
```

---

## 📦 Installation

### Option 1: Upload to Snowflake Stage (Recommended)

```sql
-- Create stage for Python modules
CREATE STAGE IF NOT EXISTS DATA_HUB.PYTHON_MODULES
    DIRECTORY = (ENABLE = TRUE);

-- Upload Python files (from SnowSQL or Snowsight)
PUT file://step_logger_snowflake.py @DATA_HUB.PYTHON_MODULES/step_logger/;
PUT file://step_logger_factory.py @DATA_HUB.PYTHON_MODULES/step_logger/;

-- Verify upload
LIST @DATA_HUB.PYTHON_MODULES/step_logger/;
```

### Option 2: Inline in Stored Procedures

Copy the code directly into your stored procedure definition (see [deploy_stored_procedure.sql](deployment/deploy_stored_procedure.sql)).

### Option 3: Automated Deployment

```bash
# Using the deployment script
python deployment/deploy.py \
    --env DEV \
    --connection-file connection.json
```

---

## 🏗️ Architecture

### Comparison: AWS Glue vs Snowflake Native

| Aspect | AWS Glue Version | Snowflake Native Version |
|--------|------------------|--------------------------|
| **Connection** | `snowflake.connector.connect()` | `snowflake.snowpark.Session` |
| **Authentication** | AWS Secrets Manager | Snowflake session context |
| **Dependencies** | boto3, snowflake-connector-python | snowflake-snowpark-python only |
| **Deployment** | Wheel file to S3/Glue | Stage upload or inline |
| **Execution** | Glue job trigger | Task, stored proc, worksheet |
| **Network** | External calls | Internal only |
| **Cost** | Glue + Snowflake compute | Snowflake compute only |

### Data Flow

```
┌─────────────────────────────────────────────┐
│ Snowflake Native Execution                  │
│  ┌───────────────────────────────────────┐ │
│  │ Python Environment (Snowpark)         │ │
│  │  ├─ StepLoggerSnowflake              │ │
│  │  ├─ Session from context             │ │
│  │  └─ No external authentication        │ │
│  └───────────────────────────────────────┘ │
│                    ↓ Internal               │
│         ┌──────────────────────┐            │
│         │ DATA_HUB.STEP_LOG    │            │
│         │  (VARIANT column)    │            │
│         └──────────────────────┘            │
└─────────────────────────────────────────────┘
```

---

## 📚 API Reference

### StepLoggerSnowflake Class

#### Constructor

```python
logger = StepLoggerSnowflake(
    etl_execution_id: str,           # Unique execution ID (UUID)
    process_name: str,                # Process name
    process_type: str = "ETL",        # Process type
    process_description: str = None,  # Optional description
    session: Session = None,          # Snowpark session (auto-detected)
    database: str = None,             # Database name (auto-detected)
    schema: str = "DATA_HUB",         # Schema name
    custom_attributes: Dict = None    # Additional metadata
)
```

#### Methods

**`start_step(step_name, operation=None, custom_attributes=None)`**
- Begin timing a step (no database write)
- Raises RuntimeError if step already in progress

**`log_step(status, description=None, db_name=None, record_count=None, custom_attributes=None)`**
- Log completed step with timing information
- `status`: "SUCCESS" or "FAILED"
- Returns: Step_Log_Id

**`close(custom_attributes=None)`**
- Log process completion and cleanup
- Always call in `finally` block

#### Properties

- `TOTAL_DURATION`: Cumulative duration (seconds)
- `TOTAL_COUNT`: Cumulative record count
- `step_number`: Current step number
- `parent_step_log_id`: Parent log ID

---

## 🎯 Usage Examples

### Example 1: Basic ETL Process

```python
from snowflake.snowpark.context import get_active_session
from step_logger_snowflake import StepLoggerSnowflake
import uuid

session = get_active_session()
logger = StepLoggerSnowflake(
    session=session,
    etl_execution_id=str(uuid.uuid4()),
    process_name="Customer_ETL"
)

try:
    # Extract
    logger.start_step("Extract", operation="EXTRACT")
    df = session.table("CUSTOMERS")
    count = df.count()
    logger.log_step("SUCCESS", f"Extracted {count} rows", record_count=count)
    
    # Transform
    logger.start_step("Transform", operation="TRANSFORM")
    df_transformed = df.filter(df["ACTIVE"] == True)
    count_transformed = df_transformed.count()
    logger.log_step("SUCCESS", "Filtered inactive", record_count=count_transformed)
    
    # Load
    logger.start_step("Load", operation="LOAD")
    df_transformed.write.mode("overwrite").save_as_table("CUSTOMERS_CLEAN")
    logger.log_step("SUCCESS", "Loaded to table", record_count=count_transformed)
    
finally:
    logger.close()
```

### Example 2: Error Handling

```python
logger = StepLoggerSnowflake(
    session=session,
    etl_execution_id=str(uuid.uuid4()),
    process_name="Data_Validation"
)

try:
    logger.start_step("Validate_Schema")
    try:
        # Validation logic
        result = validate_data()
        logger.log_step("SUCCESS", "Schema validated")
    except ValueError as e:
        logger.log_step(
            "FAILED",
            f"Validation failed: {str(e)}",
            custom_attributes={
                "error_type": type(e).__name__,
                "error_message": str(e)
            }
        )
        raise
finally:
    logger.close()
```

### Example 3: Batch Processing

```python
batches = [
    {"name": "batch_1", "filter": "REGION = 'NORTH'"},
    {"name": "batch_2", "filter": "REGION = 'SOUTH'"},
    {"name": "batch_3", "filter": "REGION = 'EAST'"},
]

logger = StepLoggerSnowflake(
    session=session,
    etl_execution_id=str(uuid.uuid4()),
    process_name="Regional_Batch_Processing"
)

try:
    for i, batch in enumerate(batches, 1):
        logger.start_step(
            f"Process_Batch_{i}",
            custom_attributes={"batch_name": batch['name']}
        )
        
        # Process batch
        df = session.table("DATA").filter(batch['filter'])
        count = df.count()
        
        logger.log_step(
            "SUCCESS",
            f"Processed {batch['name']}",
            record_count=count,
            custom_attributes={"batch_number": i}
        )
finally:
    logger.close()
```

---

## 🚢 Deployment

### Deployment Options

#### 1. Stored Procedure (Recommended for Production)

```sql
-- Deploy using provided SQL script
@deployment/deploy_stored_procedure.sql

-- Call the stored procedure
CALL DATA_HUB.SP_EXAMPLE_ETL_PROCESS('My_Process', UUID_STRING());
```

#### 2. Python Worksheet (Best for Development)

Copy `step_logger_snowflake.py` content directly into worksheet and use it.

#### 3. Automated Deployment

```bash
# Create connection file (connection.json)
{
    "account": "your-account",
    "user": "your-user",
    "password": "your-password",
    "warehouse": "DEV_WH_R"
}

# Run deployment
python deployment/deploy.py --env DEV --connection-file connection.json
```

### Deployment Checklist

- [ ] DATA_HUB.STEP_LOG table exists
- [ ] DATA_HUB.SEQ__STEP_LOG_ID sequence exists
- [ ] STEP_DESC column is VARIANT type
- [ ] Python files uploaded to stage
- [ ] Stored procedures created
- [ ] Permissions granted
- [ ] Validation tests passed

---

## 📊 Database Schema

### STEP_LOG Table

```sql
CREATE TABLE DATA_HUB.STEP_LOG (
    Step_Log_Id         BIGINT PRIMARY KEY,
    Parent_Log_Id       INT NOT NULL DEFAULT 0,
    Process_Name        VARCHAR(256),
    Process_Type        VARCHAR(256),
    Step_Name           VARCHAR(256),
    Step_Desc           VARIANT,           -- JSON metadata
    Step_Status         VARCHAR(10),       -- START, SUCCESS, FAILED, END
    Start_Dtm           DATETIME NOT NULL,
    Duration_In_Seconds INT,
    Db_Name             VARCHAR(50),
    Record_Count        INT,
    ETL_Execution_Id    VARCHAR(250) NOT NULL
);
```

### Step_Desc Structure

```json
{
    "MessageType": "SUCCESS|ERROR|INFO",
    "StepNumber": 1,
    "Operation": "EXTRACT|TRANSFORM|LOAD|...",
    "Description": "Human-readable description",
    "custom_field_1": "value1",
    "custom_field_2": "value2"
}
```

### Querying JSON Data

```sql
-- Query specific JSON fields
SELECT 
    Step_Log_Id,
    Process_Name,
    Step_Desc:MessageType::VARCHAR as message_type,
    Step_Desc:StepNumber::INTEGER as step_number,
    Step_Desc:Description::VARCHAR as description,
    Step_Desc:custom_field_1::VARCHAR as custom_value
FROM DATA_HUB.STEP_LOG
WHERE Process_Name = 'My_Process'
ORDER BY Step_Log_Id DESC;
```

---

## 🔧 Configuration

### Environment Variables

None required! Uses Snowflake session context.

### Connection Parameters

Automatically detected from active Snowpark session:
- Database: `session.get_current_database()`
- Schema: Defaults to `DATA_HUB`
- User: `session.get_current_user()`
- Warehouse: `session.get_current_warehouse()`

---

## 🐛 Troubleshooting

### Common Issues

**Issue: "No active Snowpark session found"**
```python
# Solution: Pass session explicitly
from snowflake.snowpark import Session
session = Session.builder.configs(connection_params).create()
logger = StepLoggerSnowflake(session=session, ...)
```

**Issue: "STEP_LOG table not found"**
```sql
-- Solution: Create table using migration script
@database_change/V10__EIMARC-6701--StepLogger__StepDesc__Variant.sql
```

**Issue: "Expression type does not match VARIANT"**
```python
# Solution: Already fixed in current version
# Uses PARSE_JSON() for VARIANT conversion
```

**Issue: "Permission denied"**
```sql
-- Solution: Grant necessary permissions
GRANT USAGE ON DATABASE ULTRA_DEV_RAW TO ROLE your_role;
GRANT USAGE ON SCHEMA DATA_HUB TO ROLE your_role;
GRANT SELECT, INSERT ON TABLE DATA_HUB.STEP_LOG TO ROLE your_role;
```

---

## 🧪 Testing

### Run Tests

```python
# In Snowflake Python worksheet
from examples.basic_usage import *

# Run all examples
example_basic_snowflake_usage()
example_with_error_handling()
example_batch_processing()
```

### Verify Logs

```sql
SELECT *
FROM DATA_HUB.STEP_LOG
WHERE ETL_Execution_Id = 'your-execution-id'
ORDER BY Step_Log_Id;
```

---

## 📈 Performance Considerations

- **Sequence Calls**: One per step (minimal overhead)
- **INSERT Performance**: Direct table insert (no network latency)
- **JSON Parsing**: Native PARSE_JSON (optimized)
- **Session Reuse**: No connection overhead

---

## 🔄 Migration from AWS Glue

### Code Changes Required

| AWS Glue Code | Snowflake Native Code |
|---------------|----------------------|
| `from eimutils.step_logger import StepLogger` | `from step_logger_snowflake import StepLoggerSnowflake` |
| `StepLogger(secret_key=..., env=...)` | `StepLoggerSnowflake(session=session, ...)` |
| No other changes | No other changes |

### Using Factory for Both

```python
# Works in both environments automatically
from step_logger_factory import get_step_logger

logger = get_step_logger(
    etl_execution_id=str(uuid.uuid4()),
    process_name="My_Process",
    # AWS-specific (ignored in Snowflake)
    secret_key="arn:...",
    env="DEV"
)
```

---

## 📝 License

Same license as parent eimutils package.

## 👥 Contributors

- Frank Fortunato
- Drew Ostrowski

## 📞 Support

For issues or questions:
1. Check [Troubleshooting](#troubleshooting) section
2. Review [examples](examples/)
3. Contact data engineering team

---

*StepLoggerSnowflake - Native Snowflake logging without the external dependencies* 🏔️

