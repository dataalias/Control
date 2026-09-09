# StepLogger Wiki

## Table of Contents
- [Overview](#overview)
- [Database Schema](#database-schema)
- [Class Architecture](#class-architecture)
- [Properties](#properties)
- [Methods](#methods)
- [Usage Examples](#usage-examples)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## Overview

### Purpose
The **StepLogger** class provides a simple, hierarchical logging system for ETL processes and other data operations. It automatically tracks timing, maintains totals, and logs structured data to a Snowflake database table.

### Key Features
- **Simple 4-method interface**: `__init__`, `start_step`, `log_step`, `close`
- **Automatic process start/end logging** with manual step tracking
- **Hierarchical logging** with parent-child relationships
- **Automatic timing calculation** between `start_step` and `log_step` calls
- **Total duration and record count tracking** across all steps
- **Custom attributes support** for flexible metadata logging
- **Standardized step descriptions** with MessageType, StepNumber, Operation, Description
- **Uses Snowflake sequences** for unique ID generation

### Dependencies
- **Database**: Snowflake connection required
- **eimutils.delogging**: For console logging functionality
- **eimutils.utils**: For Snowflake connection management
- **AWS Secrets Manager**: For database credential storage
- **Database Objects**: 
  - `DATA_HUB.STEP_LOG` table
  - `DATA_HUB.SEQ__STEP_LOG_ID` sequence

### File Location
```
python/eimutils/step_logger.py
```

---

## Database Schema

### STEP_LOG Table Definition

```sql
CREATE SEQUENCE ULTRA_@ENV@_RAW.DATA_HUB.SEQ__STEP_LOG_ID;

CREATE TABLE IF NOT EXISTS ULTRA_@ENV@_RAW.DATA_HUB.STEP_LOG(
    Step_Log_Id bigint DEFAULT ULTRA_@ENV@_RAW.DATA_HUB.SEQ__STEP_LOG_ID.NEXTVAL,
    Parent_Log_Id int NOT NULL DEFAULT 0,
    Process_Name varchar(256) NULL,
    Process_Type varchar(256) NULL,
    Step_Name varchar(256) NULL,
    Step_Desc VARIANT NULL,
    Step_Status varchar(10) NULL,
    Start_Dtm datetime NOT NULL,
    Duration_In_Seconds int NULL,
    Db_Name varchar(50) NULL,
    Record_Count int NULL,
    ETL_Execution_Id varchar(250) NOT NULL,
    CONSTRAINT Pk_StepLog__LogId PRIMARY KEY (Step_Log_Id)
);
```

### Column Descriptions

| Column Name | Data Type | Description |
|------------|-----------|-------------|
| `Step_Log_Id` | bigint | Primary key, auto-generated from sequence |
| `Parent_Log_Id` | int | Links steps to parent process (hierarchical structure) |
| `Process_Name` | varchar(256) | Name of the overall process |
| `Process_Type` | varchar(256) | Category of process (ETL, BATCH, etc.) |
| `Step_Name` | varchar(256) | Name of the individual step |
| `Step_Desc` | VARIANT | Structured metadata stored as parsed JSON (Snowflake VARIANT) |
| `Step_Status` | varchar(10) | START, SUCCESS, FAILED, or END |
| `Start_Dtm` | datetime | Timestamp when step started |
| `Duration_In_Seconds` | int | Calculated step duration |
| `Db_Name` | varchar(50) | Database/source name processed |
| `Record_Count` | int | Number of records processed |
| `ETL_Execution_Id` | varchar(250) | Unique identifier linking related processes |

### Hierarchical Structure

```
Process Start (Parent_Log_Id = -1)
├── Step 1 (Parent_Log_Id = Process Start ID)
├── Step 2 (Parent_Log_Id = Process Start ID)
├── Step 3 (Parent_Log_Id = Process Start ID)
└── Process End (Parent_Log_Id = Process Start ID)
```

---

## Class Architecture

### StepStatus Enum

```python
class StepStatus(Enum):
    """Enumeration of valid step status values for the STEP_LOG table."""
    
    START = "START"      # Process beginning
    SUCCESS = "SUCCESS"  # Successful step completion
    FAILED = "FAILED"    # Step encountered error
    END = "END"         # Process completion
```

### Class Hierarchy

```
StepLogger
├── Properties (instance variables)
├── Public Methods
│   ├── __init__()
│   ├── start_step()
│   ├── log_step()
│   ├── close()
│   └── get_next_sequence_value()
└── Private Methods
    ├── _get_connection()
    ├── _log_process_start()
    └── _insert_step_log()
```

---

## Properties

### Core Properties

| Property | Type | Description |
|----------|------|-------------|
| `secret_key` | str | AWS Secrets Manager ARN for database credentials |
| `env` | str | Environment identifier (DEV, STAGE, PROD) |
| `etl_execution_id` | str | Unique identifier for ETL execution |
| `process_name` | str | Name of the process being logged |
| `process_type` | str | Type of process (default: 'ETL') |
| `database` | str | Snowflake database name (ULTRA_{env}_RAW) |
| `aws_region` | str | AWS region (default: 'us-west-2') |

### Process Tracking Properties

| Property | Type | Description |
|----------|------|-------------|
| `parent_step_log_id` | int | ID of the process START record |
| `process_start_time` | datetime | When the process was initialized |
| `TOTAL_DURATION` | int | Running total of all step durations (seconds) |
| `TOTAL_COUNT` | int | Running total of all record counts |
| `step_number` | int | Sequential step counter for descriptions |

### Current Step Tracking Properties

| Property | Type | Description |
|----------|------|-------------|
| `current_step_name` | str | Name of currently active step |
| `current_step_start` | datetime | Start time of currently active step |
| `current_step_custom_attributes` | dict | Custom attributes from start_step() |
| `db_connection` | object | Active Snowflake database connection |

---

## Methods

### Public Methods

#### `__init__(secret_key, env, etl_execution_id, process_name, process_type="ETL", process_description="", custom_attributes=None)`

**Purpose**: Initialize StepLogger, establish database connection, and log process start.

**Parameters**:
- `secret_key` (str): AWS Secrets Manager ARN containing database credentials
- `env` (str): Environment identifier used to construct database name
- `etl_execution_id` (str): Unique identifier for this ETL execution run
- `process_name` (str): Human-readable name for the process being logged
- `process_type` (str, optional): Category of process being executed (default: "ETL")
- `process_description` (str, optional): Detailed description of what this process does
- `custom_attributes` (Dict[str, Any], optional): Additional metadata to include in the process start log

**Side Effects**:
- Establishes database connection
- Logs a START record to DATA_HUB.STEP_LOG table
- Sets parent_step_log_id to the ID of the START record
- Initializes timing and counter variables

**Example**:
```python
logger = StepLogger(
    secret_key="arn:aws:secretsmanager:us-west-2:123456789:secret:db-creds",
    env="DEV",
    etl_execution_id=str(uuid.uuid4()),
    process_name="Daily_Customer_ETL",
    process_description="Processes daily customer data updates",
    custom_attributes={
        "version": "2.1",
        "source_system": "CRM"
    }
)
```

---

#### `start_step(step_name, operation=None, custom_attributes=None)`

**Purpose**: Begin timing a new step without writing to the database.

**Parameters**:
- `step_name` (str): Unique name for the step being started
- `operation` (str, optional): Type of operation being performed ("EXTRACT", "TRANSFORM", "LOAD", etc.)
- `custom_attributes` (Dict[str, Any], optional): Additional metadata to associate with this step

**Side Effects**:
- Sets current_step_name to the provided step_name
- Sets current_step_start to the current timestamp
- Stores operation and custom_attributes for later use
- Logs start message to console

**Example**:
```python
logger.start_step(
    step_name="extract_customer_data",
    operation="EXTRACT",
    custom_attributes={
        "source_table": "customers",
        "filter_criteria": "active_only",
        "expected_rows": 10000
    }
)
```

---

#### `log_step(status="SUCCESS", description="", db_name=None, record_count=None, custom_attributes=None)`

**Purpose**: Log the completed step to the database with calculated timing and metadata.

**Parameters**:
- `status` (str, optional): Final status of the step ("SUCCESS" or "FAILED", case-insensitive, default: "SUCCESS")
- `description` (str, optional): Human-readable description of what the step accomplished
- `db_name` (str, optional): Name of database or data source processed during this step
- `record_count` (int, optional): Number of records processed during this step
- `custom_attributes` (Dict[str, Any], optional): Additional metadata (takes precedence over start_step attributes)

**Returns**: 
- `int`: The Step_Log_Id of the inserted step record

**Side Effects**:
- Inserts a record into DATA_HUB.STEP_LOG table
- Increments step_number for next step
- Adds duration to TOTAL_DURATION
- Adds record_count to TOTAL_COUNT (if provided)
- Resets current step tracking variables
- Commits database transaction

**Step Description JSON Structure**:
```json
{
    "MessageType": "SUCCESS" | "FAILED" | "INFO",
    "StepNumber": 0,
    "Operation": "EXTRACT",
    "Description": "Successfully processed customer data",
    ...custom_attributes_from_start_step,
    ...custom_attributes_from_log_step
}
```

**Example**:
```python
step_id = logger.log_step(
    status="SUCCESS",
    description="Successfully processed customer data",
    db_name="PROD_CRM",
    record_count=15000,
    custom_attributes={
        "processing_time_ms": 2500,
        "validation_errors": 0,
        "data_quality_score": 0.98
    }
)
```

---

#### `close(custom_attributes=None)`

**Purpose**: Log process completion and close the database connection.

**Parameters**:
- `custom_attributes` (Dict[str, Any], optional): Additional metadata to include in the process completion log

**Side Effects**:
- Logs an END record to DATA_HUB.STEP_LOG table with:
  - Step_Status = "END"
  - Step_Name = "{process_name}_END"
  - Duration_In_Seconds = total accumulated duration from all steps
  - Record_Count = total accumulated record count from all steps
- Closes the database connection
- Handles any errors gracefully

**Example**:
```python
logger.close(custom_attributes={
    "final_status": "success",
    "total_files_processed": 25,
    "completion_time": datetime.now().isoformat(),
    "environment": "production"
})
```

---

#### `get_next_sequence_value()`

**Purpose**: Retrieve the next value from the DATA_HUB.SEQ__STEP_LOG_ID sequence.

**Returns**: 
- `int`: The next sequence value from DATA_HUB.SEQ__STEP_LOG_ID

**Warning**: Each call consumes a sequence value from the database, creating gaps in the actual Step_Log_Id sequence. Use sparingly and only for debugging.

**Example**:
```python
# For testing/debugging only
next_id = logger.get_next_sequence_value()
print(f"Next sequence value would be: {next_id}")
```

### Private Methods

#### `_get_connection()`
**Purpose**: Establish and return a Snowflake database connection using AWS Secrets Manager.

#### `_log_process_start(process_description, custom_attributes=None)`
**Purpose**: Log the initial process start record and return its Step_Log_Id for use as parent_step_log_id.

#### `_insert_step_log(step_data)`
**Purpose**: Insert a new step log record into the DATA_HUB.STEP_LOG table with explicit sequence management.

---

## Usage Examples

### Basic ETL Process

```python
import uuid
from eimutils.step_logger import StepLogger

def run_basic_etl():
    etl_id = str(uuid.uuid4())
    logger = StepLogger(
        secret_key="arn:aws:secretsmanager:us-west-2:123456:secret:prod-db",
        env="PROD",
        etl_execution_id=etl_id,
        process_name="Customer_Data_ETL",
        process_description="Daily customer data processing pipeline"
    )
    
    try:
        # Extract Phase
        logger.start_step("extract_customers", operation="EXTRACT")
        extracted_data = extract_customer_data()
        logger.log_step(
            status="SUCCESS",
            description="Successfully extracted customer data",
            record_count=len(extracted_data)
        )
        
        # Transform Phase
        logger.start_step("transform_customers", operation="TRANSFORM")
        transformed_data = transform_customer_data(extracted_data)
        logger.log_step(
            status="SUCCESS",
            description="Data transformation completed",
            record_count=len(transformed_data)
        )
        
        # Load Phase
        logger.start_step("load_customers", operation="LOAD")
        load_customer_data(transformed_data)
        logger.log_step(
            status="SUCCESS",
            description="Successfully loaded data to warehouse",
            record_count=len(transformed_data)
        )
        
    except Exception as e:
        if logger.current_step_name:
            logger.log_step(
                status="FAILED",
                description=f"Step failed: {str(e)}",
                custom_attributes={"error": str(e)}
            )
        raise
    finally:
        logger.close()
```

### Error Handling Example

```python
def process_with_error_handling():
    logger = StepLogger(
        secret_key="your-secret-arn",
        env="DEV",
        etl_execution_id=str(uuid.uuid4()),
        process_name="Error_Handling_Example"
    )
    
    try:
        logger.start_step("risky_operation", operation="PROCESS")
        
        try:
            result = risky_database_operation()
            logger.log_step(
                status="SUCCESS",
                description="Risky operation succeeded",
                record_count=result.count
            )
        except ConnectionTimeout as e:
            logger.log_step(
                status="FAILED",
                description="Database connection timed out",
                custom_attributes={
                    "error_type": "ConnectionTimeout",
                    "timeout_seconds": 30,
                    "retry_count": 3
                }
            )
            raise
    finally:
        logger.close()
```

### Step Numbering Example

The StepLogger automatically assigns sequential step numbers starting from 0:

```python
logger = StepLogger(...)
# Process START gets StepNumber = 0

logger.start_step("step1")
logger.log_step(status="SUCCESS")  # Gets StepNumber = 1

logger.start_step("step2")  
logger.log_step(status="SUCCESS")  # Gets StepNumber = 2

logger.close()  # Process END gets StepNumber = 3
```

---

## Best Practices

### 1. Always Use Try/Finally
```python
logger = StepLogger(...)
try:
    # Your processing logic
    pass
finally:
    logger.close()  # Ensures cleanup even if errors occur
```

### 2. Descriptive Step Names
```python
# Good
logger.start_step("extract_customer_delta_records")
logger.start_step("validate_data_quality_rules")

# Avoid
logger.start_step("step1")
logger.start_step("process")
```

### 3. Meaningful Custom Attributes
```python
logger.start_step(
    "extract_data",
    operation="EXTRACT",
    custom_attributes={
        "source_table": "customers",
        "filter_condition": "modified_date >= '2025-01-01'",
        "expected_row_count": 50000
    }
)
```

### 4. Consistent Error Logging
```python
try:
    # Processing logic
    pass
except SpecificException as e:
    logger.log_step(
        status="FAILED",
        description=f"Specific error occurred: {str(e)}",
        custom_attributes={
            "error_type": type(e).__name__,
            "error_details": str(e)
        }
    )
    raise
```

### 5. Use ETL Execution ID Consistently
```python
# Generate once per pipeline run
execution_id = str(uuid.uuid4())

# Use same ID for related processes
main_logger = StepLogger(etl_execution_id=execution_id, process_name="Main_Process")
sub_logger = StepLogger(etl_execution_id=execution_id, process_name="Sub_Process")
```

---

## Troubleshooting

### Common Issues

#### 1. Database Connection Timeouts
**Symptom**: `Failed to establish database connection: timeout`

**Solutions**:
- Check AWS credentials and permissions
- Verify network connectivity to Snowflake
- Confirm Snowflake account availability
- Validate secret ARN format and accessibility

#### 2. Invalid Step Status
**Symptom**: `Invalid status 'COMPLETE'. Must be 'SUCCESS' or 'FAILED'`

**Solution**: Use "SUCCESS" instead of "COMPLETE" (updated in recent versions)
```python
# Correct
logger.log_step(status="SUCCESS")

# Incorrect (old version)
logger.log_step(status="COMPLETE")
```

#### 3. No Active Step Error
**Symptom**: `No step is currently started. Call start_step() first.`

**Solution**: Always call `start_step()` before `log_step()`
```python
logger.start_step("my_step")
# ... processing logic ...
logger.log_step(status="SUCCESS")
```

#### 4. Sequence Value Gaps
**Symptom**: Non-consecutive Step_Log_Id values in database

**Causes**: 
- Multiple calls to `get_next_sequence_value()`
- Failed transactions that consumed sequence values
- Multiple concurrent StepLogger instances

**Solutions**:
- Avoid using `get_next_sequence_value()` in production
- Handle exceptions properly to minimize failed transactions

#### 5. JSON Serialization Errors
**Symptom**: `Object of type 'datetime' is not JSON serializable`

**Solution**: Convert datetime objects to strings in custom_attributes:
```python
custom_attributes = {
    "timestamp": datetime.now().isoformat(),  # Convert to string
    "date_processed": "2025-01-29"
}
```

### Debug Information

All StepLogger operations are automatically logged to console via `log_to_console`. Monitor console output for:
- Initialization messages
- Step timing information
- Database operation confirmations
- Error messages and stack traces

### Performance Considerations

- **Database Connection**: Each StepLogger instance maintains its own connection
- **Transaction Management**: Each step is committed individually
- **Memory Usage**: Minimal - only tracks current step and running totals
- **Sequence Usage**: One sequence value consumed per database insert

---

## Version History

| Date | Author | Description |
|------|---------|-------------|
| 2025-08-20 | ffortunato | Rewritten as simple 4-method StepLogger (init, start_step, log_step, close) |

---

*Last Updated: January 29, 2025*  
*Wiki Version: 1.0*
