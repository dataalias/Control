# StepLogger - ETL Process Logging

A comprehensive, hierarchical logging system for ETL processes and data operations that automatically tracks timing, maintains totals, and logs structured data to Snowflake.

## Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Usage Examples](#usage-examples)
- [API Reference](#api-reference)
- [Best Practices](#best-practices)
- [Error Handling](#error-handling)
- [Troubleshooting](#troubleshooting)
- [Testing](#testing)
- [Contributing](#contributing)

## Overview

The StepLogger class provides a simple, 4-method interface for logging ETL process steps to a Snowflake database. It automatically handles timing calculations, maintains running totals, and creates a hierarchical parent-child relationship between process and step logs.

### Architecture

```
Process Start (Parent)
├── Step 1 (Child)
├── Step 2 (Child)
├── Step 3 (Child)
└── Process End (Child)
```

All step logs are linked to the initial process start record via `Parent_Log_Id`, creating a clear audit trail.

## Key Features

- **Simple 4-Method Interface**: `__init__`, `start_step`, `log_step`, `close`
- **Automatic Timing**: Calculates duration between `start_step` and `log_step` calls
- **Hierarchical Logging**: Process start becomes parent for all step logs
- **Running Totals**: Automatically maintains `TOTAL_DURATION` and `TOTAL_COUNT`
- **Custom Attributes**: Flexible metadata support on all operations
- **Standardized Format**: Consistent step descriptions with required fields
- **Error Handling**: Comprehensive error handling with rollback support
- **Connection Management**: Automatic database connection lifecycle management

## Quick Start

```python
import uuid
from eimutils.step_logger import StepLogger

# Initialize logger
logger = StepLogger(
    secret_key="arn:aws:secretsmanager:MY_AWS_REGION:123456:secret:db-creds",
    env="DEV",
    etl_execution_id=str(uuid.uuid4()),
    process_name="My_ETL_Process",
    process_description="Daily data processing pipeline"
)

try:
    # Start and log a step
    logger.start_step("extract_data", operation="EXTRACT")
    # ... your processing logic here ...
    logger.log_step(status="SUCCESS", record_count=1000)
    
finally:
    # Always close to log process completion
    logger.close()
```

## Installation

### Prerequisites

- Python 3.7+
- Access to Snowflake database
- AWS Secrets Manager credentials configured
- Required dependencies:
  - `eimutils.delogging` (for console logging)
  - `eimutils.utils` (for Snowflake connection)

### Setup

1. Ensure your environment has access to the required `eimutils` modules
2. Configure AWS credentials for Secrets Manager access
3. Verify Snowflake database connectivity
4. Ensure the `DATA_HUB.STEP_LOG` table exists with proper schema

### Database Schema

The StepLogger writes to a `DATA_HUB.STEP_LOG` table with the following key columns:

```sql
CREATE TABLE DATA_HUB.STEP_LOG (
    Step_Log_Id NUMBER NOT NULL,
    Parent_Log_Id NUMBER,
    Process_Name VARCHAR,
    Process_Type VARCHAR,
    Step_Name VARCHAR,
    Step_Desc VARCHAR,  -- JSON string
    Step_Status VARCHAR,  -- START, SUCCESS, FAILED, END
    Start_Dtm TIMESTAMP,
    Duration_In_Seconds NUMBER,
    Db_Name VARCHAR,
    Record_Count NUMBER,
    ETL_Execution_Id VARCHAR
);
```

## Usage Examples

### Basic ETL Process

```python
import uuid
from eimutils.step_logger import StepLogger

def run_etl_process():
    etl_id = str(uuid.uuid4())
    logger = StepLogger(
        secret_key="arn:aws:secretsmanager:MY_AWS_REGION:123456:secret:prod-db",
        env="PROD",
        etl_execution_id=etl_id,
        process_name="Customer_Data_ETL",
        process_type="ETL",
        process_description="Daily customer data processing pipeline",
        custom_attributes={
            "version": "2.1",
            "source_system": "CRM",
            "target_table": "customer_dim"
        }
    )
    
    try:
        # Extract Phase
        logger.start_step(
            "extract_customers",
            operation="EXTRACT",
            custom_attributes={
                "source_table": "customers",
                "filter_criteria": "modified_date >= yesterday",
                "expected_rows": 10000
            }
        )
        
        # Your extraction logic here
        extracted_data = extract_customer_data()
        
        logger.log_step(
            status="SUCCESS",
            description="Successfully extracted customer data from CRM",
            db_name="PROD_CRM",
            record_count=len(extracted_data),
            custom_attributes={
                "extraction_method": "incremental",
                "rows_filtered": 500
            }
        )
        
        # Transform Phase
        logger.start_step(
            "transform_customers",
            operation="TRANSFORM",
            custom_attributes={"transformation_rules": "business_logic_v2.1"}
        )
        
        # Your transformation logic here
        transformed_data = transform_customer_data(extracted_data)
        
        logger.log_step(
            status="SUCCESS",
            description="Applied business rules and data cleansing",
            record_count=len(transformed_data),
            custom_attributes={
                "validation_errors": 0,
                "data_quality_score": 0.98,
                "cleansing_rules_applied": 15
            }
        )
        
        # Load Phase
        logger.start_step(
            "load_customers",
            operation="LOAD",
            custom_attributes={
                "target_table": "customer_dim",
                "load_strategy": "upsert"
            }
        )
        
        # Your loading logic here
        load_customer_data(transformed_data)
        
        logger.log_step(
            status="SUCCESS",
            description="Successfully loaded data to data warehouse",
            db_name="DWH_PROD",
            record_count=len(transformed_data),
            custom_attributes={
                "load_method": "upsert",
                "indexes_rebuilt": True,
                "statistics_updated": True
            }
        )
        
    except Exception as e:
        # Log failure if a step was started
        if logger.current_step_name:
            logger.log_step(
                status="FAILED",
                description=f"Step failed: {str(e)}",
                custom_attributes={
                    "error_type": type(e).__name__,
                    "error_message": str(e),
                    "traceback": traceback.format_exc()
                }
            )
        raise
        
    finally:
        # Always close to log process completion
        logger.close(custom_attributes={
            "final_status": "success",
            "total_files_processed": 1,
            "completion_timestamp": datetime.now().isoformat()
        })
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
            # Risky operation that might fail
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
                    "retry_count": 3,
                    "error_details": str(e)
                }
            )
            raise
            
        except DataValidationError as e:
            logger.log_step(
                status="FAILED", 
                description="Data validation failed",
                custom_attributes={
                    "error_type": "DataValidationError",
                    "validation_rule": e.rule,
                    "failed_records": e.count,
                    "error_details": str(e)
                }
            )
            raise
            
    finally:
        logger.close()
```

### Multiple Processes with Sub-Steps

```python
def complex_data_pipeline():
    \"\"\"Example of a complex pipeline with multiple sub-processes.\"\"\"
    main_logger = StepLogger(
        secret_key="your-secret-arn",
        env="PROD", 
        etl_execution_id=str(uuid.uuid4()),
        process_name="Master_Data_Pipeline",
        process_description="Complete data pipeline with multiple sources"
    )
    
    try:
        # Process multiple data sources
        sources = ["customers", "orders", "products"]
        
        for source in sources:
            main_logger.start_step(
                f"process_{source}",
                operation="ETL",
                custom_attributes={"data_source": source}
            )
            
            # Each source gets its own detailed processing
            records_processed = process_data_source(source, main_logger.etl_execution_id)
            
            main_logger.log_step(
                status="SUCCESS",
                description=f"Successfully processed {source} data",
                record_count=records_processed,
                custom_attributes={
                    "processing_method": "full_refresh",
                    "data_source": source
                }
            )
        
        # Final aggregation step
        main_logger.start_step("aggregate_results", operation="AGGREGATE")
        
        total_records = aggregate_all_sources()
        
        main_logger.log_step(
            status="SUCCESS", 
            description="Aggregated data from all sources",
            record_count=total_records
        )
        
    finally:
        main_logger.close(custom_attributes={
            "sources_processed": len(sources),
            "pipeline_success": True
        })

def process_data_source(source_name, execution_id):
    \"\"\"Process individual data source with detailed logging.\"\"\"
    # This could create its own StepLogger for detailed sub-process tracking
    # using the same execution_id but a different process_name
    pass
```

## API Reference

### StepLogger Class

#### `__init__(secret_key, env, etl_execution_id, process_name, process_type="ETL", process_description="", custom_attributes=None)`

Initialize StepLogger and log process start.

**Parameters:**
- `secret_key` (str): AWS Secrets Manager ARN for database credentials
- `env` (str): Environment identifier ("DEV", "STAGE", "PROD")  
- `etl_execution_id` (str): Unique identifier for ETL execution (typically UUID)
- `process_name` (str): Human-readable process name
- `process_type` (str, optional): Process category (default: "ETL")
- `process_description` (str, optional): Detailed process description
- `custom_attributes` (Dict[str, Any], optional): Additional metadata

**Raises:** Exception if database connection fails

#### `start_step(step_name, operation=None, custom_attributes=None)`

Begin timing a new step (no database write).

**Parameters:**
- `step_name` (str): Unique name for the step
- `operation` (str, optional): Operation type ("EXTRACT", "TRANSFORM", "LOAD", etc.)
- `custom_attributes` (Dict[str, Any], optional): Step metadata

#### `log_step(status="SUCCESS", description="", db_name=None, record_count=None, custom_attributes=None)`

Log completed step with timing and metadata.

**Parameters:**
- `status` (str, optional): "SUCCESS" or "FAILED" (case-insensitive)
- `description` (str, optional): Step description
- `db_name` (str, optional): Database/source name
- `record_count` (int, optional): Records processed
- `custom_attributes` (Dict[str, Any], optional): Additional metadata

**Returns:** int - Step_Log_Id of inserted record

**Raises:** 
- ValueError if no step is active or invalid status
- Exception if database insert fails

#### `close(custom_attributes=None)`

Log process completion and close connection.

**Parameters:**
- `custom_attributes` (Dict[str, Any], optional): Final process metadata

#### `get_next_sequence_value()`

Get next sequence value (for testing/debugging only).

**Returns:** int - Next sequence value

**Warning:** Consumes a sequence value each time called.

### StepStatus Enum

Predefined status values:
- `StepStatus.START.value` = "START"
- `StepStatus.SUCCESS.value` = "SUCCESS" 
- `StepStatus.FAILED.value` = "FAILED"
- `StepStatus.END.value` = "END"

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
logger.start_step("upsert_to_target_table")

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
        "expected_row_count": 50000,
        "extraction_method": "incremental"
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
            "error_code": getattr(e, 'code', None),
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

## Error Handling

### Common Exceptions

1. **Database Connection Errors**
   ```python
   try:
       logger = StepLogger(...)
   except Exception as e:
       print(f"Failed to initialize StepLogger: {e}")
       # Handle gracefully - perhaps use fallback logging
   ```

2. **Invalid Step Status**
   ```python
   try:
       logger.log_step(status="INVALID")
   except ValueError as e:
       print(f"Invalid status provided: {e}")
       logger.log_step(status="FAILED", description="Status error occurred")
   ```

3. **No Active Step**
   ```python
   try:
       logger.log_step()  # Without calling start_step first
   except ValueError as e:
       print(f"No active step: {e}")
       # Start a step first, then log
   ```

### Graceful Degradation

```python
def safe_step_logging(logger, step_name, operation_func, *args, **kwargs):
    \"\"\"Wrapper for safe step logging with fallback.\"\"\"
    try:
        logger.start_step(step_name)
        result = operation_func(*args, **kwargs)
        logger.log_step(status="SUCCESS", record_count=getattr(result, 'count', None))
        return result
    except Exception as e:
        try:
            logger.log_step(status="FAILED", description=str(e))
        except:
            # If logging fails, at least log to console
            print(f"Step {step_name} failed and logging failed: {e}")
        raise
```

## Troubleshooting

### Common Issues

#### 1. Database Connection Timeouts
```
Error: Failed to establish database connection: timeout
```
**Solution:** Check AWS credentials, network connectivity, and Snowflake availability.

#### 2. Sequence Gaps
```
Warning: Step_Log_Id gaps detected
```
**Cause:** Multiple calls to `get_next_sequence_value()` or failed transactions.
**Solution:** Avoid using `get_next_sequence_value()` in production code.

#### 3. JSON Serialization Errors
```
Error: Object of type 'datetime' is not JSON serializable
```
**Solution:** Convert datetime objects to strings in custom_attributes:
```python
custom_attributes = {
    "timestamp": datetime.now().isoformat(),  # Convert to string
    "date_processed": "2025-01-29"
}
```

#### 4. Memory Issues with Large Record Counts
**Solution:** Process in batches and log incrementally:
```python
for batch in data_batches:
    logger.start_step(f"process_batch_{batch_num}")
    # Process batch
    logger.log_step(status="SUCCESS", record_count=len(batch))
```

### Debug Mode

Enable verbose logging for troubleshooting:

```python
import os
os.environ['STEPLOGGER_DEBUG'] = 'true'  # If debug mode is implemented

# Or check console output from log_to_console calls
# All StepLogger operations are logged to console automatically
```

## Testing

### Running Unit Tests

```bash
# Run all tests
python -m unittest python.tests.test_step_logger -v

# Run specific test class
python -m unittest python.tests.test_step_logger.TestStepLogger -v

# Run specific test method
python -m unittest python.tests.test_step_logger.TestStepLogger.test_init_basic -v

# Run from the test file directly
cd python/tests
python test_step_logger.py

# Run with discovery from project root
python -m unittest discover -s python/tests -p "test_*.py" -v
```

### Mock Testing Example

```python
import unittest
from unittest.mock import patch, MagicMock
from datetime import datetime
import sys
import os

# Add path for eimutils import
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))
from eimutils.step_logger import StepLogger

class TestMyETL(unittest.TestCase):
    
    def setUp(self):
        """Set up test fixtures before each test method."""
        self.mock_connection = MagicMock()
        self.mock_cursor = MagicMock()
        self.mock_connection.cursor.return_value = self.mock_cursor
        self.mock_cursor.fetchone.return_value = [12345]
    
    @patch('eimutils.step_logger.get_snowflake_connection_from_secret')
    @patch('eimutils.step_logger.log_to_console')
    def test_my_etl_process(self, mock_log, mock_get_connection):
        # Set up mocks
        mock_get_connection.return_value = self.mock_connection
        
        # Test your ETL process
        logger = StepLogger(
            secret_key="arn:aws:secretsmanager:test",
            env="TEST", 
            etl_execution_id="test-execution-id",
            process_name="Test_ETL_Process",
            process_description="Test ETL process"
        )
        
        # Mock datetime for consistent timing
        with patch('eimutils.step_logger.datetime') as mock_dt:
            mock_dt.now.return_value = datetime(2025, 1, 29, 12, 0, 0)
            
            logger.start_step("test_extraction", operation="EXTRACT")
            logger.log_step(
                status="SUCCESS",
                description="Test extraction completed",
                record_count=100
            )
        
        logger.close()
        
        # Verify database interactions
        self.assertTrue(mock_get_connection.called)
        self.assertTrue(self.mock_cursor.execute.called)
        self.assertTrue(self.mock_connection.commit.called)
        self.assertTrue(self.mock_connection.close.called)
        
        # Verify logger state
        self.assertEqual(logger.TOTAL_COUNT, 100)
        self.assertEqual(logger.step_number, 2)  # 1 step + 1 close

if __name__ == '__main__':
    unittest.main(verbosity=2)
```

## Contributing

### Development Setup

1. Clone the repository
2. Install development dependencies
3. Run tests to ensure everything works
4. Make your changes
5. Add tests for new functionality
6. Ensure all tests pass
7. Submit a pull request

### Code Style

- Follow PEP 8 standards
- Add comprehensive docstrings
- Include type hints where appropriate
- Write unit tests for new features
- Update this README for significant changes

### Adding New Features

When adding new features:

1. **Maintain backward compatibility**
2. **Add comprehensive documentation**
3. **Include unit tests**
4. **Update the README**
5. **Consider performance implications**

---

## License

[Include your license information here]

## Support

For issues, questions, or contributions:
- Create an issue in the project repository
- Contact the development team
- Check the troubleshooting section above

---

**Version:** 2.0  
**Last Updated:** January 29, 2025  
**Compatible Python Versions:** 3.7+
