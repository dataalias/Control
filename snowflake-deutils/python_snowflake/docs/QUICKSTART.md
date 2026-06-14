# ⚡ StepLoggerSnowflake - Quick Start Guide

Get up and running with StepLoggerSnowflake in 5 minutes!

---

## 🎯 Option 1: Python Worksheet (Fastest)

### Step 1: Copy the Code

1. Open Snowsight → **Projects** → **Worksheets** → **+ Python Worksheet**
2. Copy the entire content of `step_logger_snowflake.py`
3. Paste into the worksheet

### Step 2: Write Your First Logger

Add this to the bottom of the worksheet:

```python
# Your first StepLogger!
from snowflake.snowpark.context import get_active_session
import uuid

session = get_active_session()

logger = StepLoggerSnowflake(
    session=session,
    etl_execution_id=str(uuid.uuid4()),
    process_name="My_First_Process",
    process_description="Testing StepLogger in Snowflake"
)

try:
    # Extract step
    logger.start_step("Extract_Sample_Data", operation="EXTRACT")
    df = session.table("SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER")
    count = df.count()
    logger.log_step("SUCCESS", f"Extracted {count} rows", record_count=count)
    
    # Transform step
    logger.start_step("Filter_Active_Customers", operation="TRANSFORM")
    # Simple filter
    filtered_count = count - 100
    logger.log_step("SUCCESS", "Filtered data", record_count=filtered_count)
    
finally:
    logger.close()

# Check the results
print(f"✓ Process completed!")
print(f"  Total Duration: {logger.TOTAL_DURATION} seconds")
print(f"  Total Records: {logger.TOTAL_COUNT}")
```

### Step 3: Run It!

Click **▶ Run** button. You should see:

```
✓ Process completed!
  Total Duration: 3 seconds
  Total Records: 150000
```

### Step 4: View the Logs

Run this SQL in a SQL worksheet:

```sql
SELECT *
FROM DATA_HUB.STEP_LOG
WHERE Process_Name = 'My_First_Process'
ORDER BY Step_Log_Id DESC;
```

**🎉 Congratulations! You've logged your first process!**

---

## 🎯 Option 2: Stored Procedure (Production-Ready)

### Step 1: Deploy the Stored Procedure

Run this SQL:

```sql
-- Quick inline stored procedure
CREATE OR REPLACE PROCEDURE DATA_HUB.MY_FIRST_ETL()
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.9'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'run_etl'
AS
$$
import json
from datetime import datetime
import uuid

def run_etl(session):
    """Simple ETL with inline StepLogger"""
    
    # Minimal inline logger
    def log_step(session, process, step_name, status, description, record_count=None):
        seq = session.sql("SELECT DATA_HUB.SEQ__STEP_LOG_ID.NEXTVAL as id").collect()[0]['ID']
        step_desc = json.dumps({"Description": description, "MessageType": status})
        query = f"""
            INSERT INTO DATA_HUB.STEP_LOG
            SELECT {seq}, -1, '{process}', '{step_name}', 
                   PARSE_JSON('{step_desc}'), '{status}',
                   CURRENT_TIMESTAMP(), 1, {record_count or 'NULL'}, 
                   '{str(uuid.uuid4())}'
        """
        session.sql(query).collect()
        return seq
    
    # Your ETL logic
    process_name = "My_Stored_Proc_ETL"
    
    # Start
    log_step(session, process_name, "START", "START", "Process started")
    
    # Extract
    df = session.table("SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.CUSTOMER")
    count = df.count()
    log_step(session, process_name, "Extract", "SUCCESS", f"Extracted {count} rows", count)
    
    # End
    log_step(session, process_name, "END", "END", "Process completed", count)
    
    return f"✓ Process completed with {count} records"
$$;
```

### Step 2: Run It

```sql
CALL DATA_HUB.MY_FIRST_ETL();
```

Result: `✓ Process completed with 150000 records`

### Step 3: View Logs

```sql
SELECT *
FROM DATA_HUB.STEP_LOG
WHERE Process_Name = 'My_Stored_Proc_ETL'
ORDER BY Step_Log_Id DESC;
```

**🎉 You now have a production-ready logged procedure!**

---

## 🎯 Option 3: Using the Factory (Smart)

The factory automatically detects your environment!

```python
from step_logger_factory import get_step_logger
import uuid

# Works in Snowflake OR AWS Glue automatically!
logger = get_step_logger(
    etl_execution_id=str(uuid.uuid4()),
    process_name="Smart_Process"
)

try:
    logger.start_step("Process_Data")
    # ... your processing ...
    logger.log_step("SUCCESS", record_count=1000)
finally:
    logger.close()
```

---

## 📊 Understanding Your Logs

### Basic Query

```sql
SELECT 
    Process_Name,
    Step_Name,
    Step_Status,
    Duration_In_Seconds,
    Record_Count,
    Start_Dtm
FROM DATA_HUB.STEP_LOG
WHERE Process_Name = 'YOUR_PROCESS_NAME'
ORDER BY Step_Log_Id;
```

### Query JSON Fields

```sql
SELECT 
    Step_Name,
    Step_Desc:Description::VARCHAR as description,
    Step_Desc:Operation::VARCHAR as operation,
    Step_Desc:MessageType::VARCHAR as message_type,
    Record_Count
FROM DATA_HUB.STEP_LOG
WHERE Process_Name = 'YOUR_PROCESS_NAME';
```

### Get Process Summary

```sql
SELECT 
    Process_Name,
    COUNT(*) as total_steps,
    SUM(Duration_In_Seconds) as total_duration_sec,
    SUM(Record_Count) as total_records,
    MAX(CASE WHEN Step_Status = 'END' THEN Start_Dtm END) as completed_at
FROM DATA_HUB.STEP_LOG
WHERE ETL_Execution_Id = 'your-execution-id'
GROUP BY Process_Name;
```

---

## 🚀 Next Steps

### 1. Try Error Handling

```python
logger.start_step("Risky_Operation")
try:
    result = 1 / 0  # This will fail
    logger.log_step("SUCCESS", "Completed")
except Exception as e:
    logger.log_step(
        "FAILED",
        f"Operation failed: {str(e)}",
        custom_attributes={"error_type": type(e).__name__}
    )
```

### 2. Add Custom Attributes

```python
logger.start_step(
    "Extract_Data",
    operation="EXTRACT",
    custom_attributes={
        "source_table": "customers",
        "extraction_method": "full_load",
        "data_date": "2024-01-15"
    }
)
```

### 3. Track Multiple Batches

```python
batches = ["batch_1", "batch_2", "batch_3"]

for i, batch_name in enumerate(batches, 1):
    logger.start_step(f"Process_Batch_{i}")
    # ... process batch ...
    logger.log_step("SUCCESS", f"Processed {batch_name}", record_count=1000)
```

### 4. Schedule It

```sql
CREATE TASK MY_DAILY_TASK
    WAREHOUSE = DEV_WH_R
    SCHEDULE = 'USING CRON 0 2 * * * UTC'
AS
    CALL DATA_HUB.MY_FIRST_ETL();

ALTER TASK MY_DAILY_TASK RESUME;
```

---

## 📚 Learn More

- [Full README](README.md) - Complete documentation
- [Examples](examples/basic_usage.py) - More detailed examples
- [Deployment Guide](DEPLOYMENT_GUIDE.md) - Production deployment
- [API Reference](README.md#api-reference) - All methods and parameters

---

## 🆘 Quick Troubleshooting

**Can't find STEP_LOG table?**
```sql
-- Check if it exists
SELECT * FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME = 'STEP_LOG' AND TABLE_SCHEMA = 'DATA_HUB';

-- If not, you need to create it first (contact your DBA)
```

**Permission denied?**
```sql
-- Check your role
SELECT CURRENT_ROLE();

-- You need INSERT permission on STEP_LOG
SHOW GRANTS ON TABLE DATA_HUB.STEP_LOG;
```

**Module not found in stored procedure?**
```
-- For inline code (like Option 2), this shouldn't happen
-- For imports, ensure files are uploaded to stage
LIST @DATA_HUB.PYTHON_MODULES/step_logger/;
```

---

## 🎊 Success!

You're now logging ETL processes like a pro! 

**What you've learned:**
- ✅ How to use StepLogger in Python worksheets
- ✅ How to create logged stored procedures
- ✅ How to query your logs
- ✅ How to handle errors
- ✅ How to add custom metadata

**Ready for more?** Check out the [full documentation](README.md)!

---

*Start logging, stop guessing! 📊*

