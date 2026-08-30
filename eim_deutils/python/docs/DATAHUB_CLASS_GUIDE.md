# DataHub Class - Comprehensive Guide

## Overview

The `DataHub` class provides a Python interface for managing publications and issues in the DataHub database schema. It simplifies ETL workflows by providing methods to query publications, insert/update issues, and track data processing states.

**Package:** `eimutils.data_hub`  
**Version:** 1.11.1  
**Database Schema:** `DATA_HUB` (Snowflake)

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Architecture](#architecture)
3. [Installation](#installation)
4. [Class Structure](#class-structure)
5. [Methods Reference](#methods-reference)
6. [Usage Patterns](#usage-patterns)
7. [Error Handling](#error-handling)
8. [Best Practices](#best-practices)
9. [Examples](#examples)
10. [Troubleshooting](#troubleshooting)
11. [Related Classes](#related-classes)

---

## Quick Start

```python
from eimutils.data_hub import DataHub
from datetime import datetime

# Initialize DataHub
with DataHub(
    secret_key="arn:aws:secretsmanager:...",
    env="DEV"
) as dh:
    # Get publications for a publisher
    params = {
        "PublisherCode": "PUBR01",
        "CurrentDate": datetime.now()
    }
    dh.get_publication_list(params)
    
    # Set active publication
    dh.set_publication_code("PUBN01-ACCT")
    
    # Check if file has been processed
    if dh.is_issue_absent("myfile.csv"):
        # Prepare and insert new issue
        issue_data = {
            "IssueName": "myfile.csv",
            "StatusCode": "IC",
            "RecordCount": 0
        }
        dh.set_issue_val(issue_data)
        dh.insert_new_issue()
        
        # ... process data ...
        
        # Update issue status
        dh.update_issue({
            "StatusCode": "IC",
            "RecordCount": 1500
        })
```

---

## Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────┐
│              DataHub Class                      │
│  (data_hub.py)                                  │
│  - Connection Management                        │
│  - Publication Queries                          │
│  - Issue CRUD Operations                        │
└──────────────┬──────────────────────────────────┘
               │
               │ uses
               │
┌──────────────▼──────────────────────────────────┐
│       DataHub Connection Layer                  │
│  (data_hub_connection.py)                       │
│  - get_publication_list()                       │
│  - prepare_issues()                             │
│  - insert_new_issue()                           │
│  - update_issue()                               │
│  - is_issue_absent()                            │
└──────────────┬──────────────────────────────────┘
               │
               │ queries
               │
┌──────────────▼──────────────────────────────────┐
│         Snowflake Database                      │
│  Schema: DATA_HUB                               │
│  Tables: Publisher, Publication, Issue,         │
│          Subscriber, Subscription               │
└─────────────────────────────────────────────────┘
```

### Database Schema

The DataHub class interacts with these primary tables:

- **Publisher**: Data source systems
- **Publication**: Individual data feeds from publishers
- **Issue**: Specific instances of publication data (files/batches)
- **Subscriber**: Data consumer systems
- **Subscription**: Relationships between publications and subscribers
- **Ref_Status**: Status code reference table
- **Ref_Interval**: Interval/schedule reference table

---

## Installation

```bash
# Install from PyPI
pip install eimutils==1.11.1

# For AWS Glue (Python 3.9/3.10)
pip install eimutils==1.11.1,snowflake-connector-python<3.0.0,urllib3<2.0.0
```

**Dependencies:**
- Python >= 3.9
- boto3 (AWS SDK)
- snowflake-connector-python
- pandas
- cryptography

---

## Class Structure

### Constructor

```python
def __init__(self, secret_key: str, env: str) -> None
```

**Parameters:**
- `secret_key` (str): AWS Secrets Manager ARN containing Snowflake credentials
- `env` (str): Environment name - "DEV", "STAGE", or "PROD"

**Properties Initialized:**
- `issue_list`: Array of issue dictionaries for current publications. `issue_list[-1]` is a lookup dict mapping publication codes to list indices; `issue_list[0..N-2]` are individual issue dicts.
- `publication_list`: DataFrame of publications for current publisher
- `publication_idx`: Index of currently active publication (int)
- `publication_code`: Code of currently active publication (str)
- `current_publication`: Dictionary of active publication details
- `db_connection`: Snowflake database connection object
- `database`: Constructed database name (e.g., "ULTRA_DEV_RAW")

### Context Manager Support

The DataHub class implements the context manager protocol:

```python
with DataHub(secret_key, env) as dh:
    # Use dh here
    pass
# Connection automatically closed
```

---

## Methods Reference

### Connection & Initialization

#### `__init__(secret_key, env)`
Initializes DataHub instance and establishes database connection.

**Example:**
```python
dh = DataHub(
    secret_key="arn:aws:secretsmanager:us-west-2:...",
    env="DEV"
)
```

#### `close()`
Explicitly closes the database connection.

**Example:**
```python
dh.close()
```

---

### Publication Management

#### `get_publication_list(params: dict) -> dict`
Retrieves publications based on various criteria.

**Parameters:**
- `params` (dict): Query parameters. Supported keys:
  - `PublisherCode` (str): Publisher identifier (most common)
  - `FileName` (str): File name to match
  - `IssueId` (int): Specific issue ID
  - `PublicationFilePath` (str): File path pattern
  - `TriggerTypeCode` (str): "SCH" for scheduled publications
  - `CurrentDate` (datetime): Reference date for scheduling

**Returns:**
- `dict`: `{"Status": "Success"}` or `{"Status": "Failure", "Message": "..."}`

**Side Effects:**
- Populates `self.publication_list` DataFrame
- Populates `self.issue_list` array
- Sets `self.publication_code` and `self.publication_idx` to first result

**Example:**
```python
params = {
    "PublisherCode": "PUBR01",
    "CurrentDate": datetime.now()
}
response = dh.get_publication_list(params)

if response["Status"] == "Success":
    print(f"Found {len(dh.publication_list)} publications")
```

#### `set_publication_code(publication_code: str) -> None`
Sets the active publication for subsequent operations.

**Parameters:**
- `publication_code` (str): Publication code to activate

**Side Effects:**
- Updates `self.publication_code`
- Updates `self.publication_idx`
- Updates `self.current_publication` dictionary

**Example:**
```python
dh.set_publication_code("PUBN01-ACCT")
```

#### `get_publication_code() -> str`
Returns the currently active publication code.

**Returns:**
- `str`: Current publication code

**Example:**
```python
code = dh.get_publication_code()
print(f"Active publication: {code}")
```

#### `get_current_publication() -> dict`
Returns full details of the currently active publication.

**Returns:**
- `dict`: Publication attributes including:
  - `PUBLICATIONCODE`: Publication identifier
  - `PUBLICATIONNAME`: Display name
  - `PUBLICATIONFILEPATH`: S3/file path
  - `INTERVALCODE`: Schedule type (DY, HR, etc.)
  - `SLATIME`: SLA deadline time
  - And other metadata fields

**Example:**
```python
pub = dh.get_current_publication()
print(f"Name: {pub['PUBLICATIONNAME']}")
print(f"Path: {pub['PUBLICATIONFILEPATH']}")
```

#### `get_publication_idx() -> int`
Returns the index of the active publication in the publication list.

**Returns:**
- `int`: Zero-based index

**Example:**
```python
idx = dh.get_publication_idx()
```

---

### Issue Management

#### `set_issue_val(issue_updates: dict) -> None`
Updates issue attributes for the active publication without writing to database.

**Parameters:**
- `issue_updates` (dict): Key-value pairs of issue fields to update

**Common Fields:**
- `IssueName`: File name or batch identifier
- `SrcIssueName`: Source system file name
- `StatusCode`: Issue status (IC, IP, PR, IF, IA)
- `RecordCount`: Number of records processed
- `ETLExecutionId`: Glue job run ID or execution identifier
- `PeriodStartTime`: Data window start time
- `PeriodEndTime`: Data window end time
- `DataLakePath`: S3 path where data is stored
- `FirstRecordSeq`: First record sequence number
- `LastRecordSeq`: Last record sequence number

**Example:**
```python
issue = {
    "IssueName": "Account_20241001.csv",
    "SrcIssueName": "Account.csv",
    "StatusCode": "IC",  # Issue Complete
    "RecordCount": 1500,
    "ETLExecutionId": "jr_abc123xyz",
    "PeriodStartTime": "2024-10-01 00:00:00",
    "PeriodEndTime": "2024-10-01 23:59:59"
}
dh.set_issue_val(issue)
```

#### `insert_new_issue() -> dict`
Inserts a new issue record into the database using `SEQ_ISSUE_ID.NEXTVAL`.

**Returns:**
- `dict`: `{"Status": "Success"}` or `{"Status": "Failure"}`

**Side Effects:**
- Updates `self.issue_list[publication_idx]["IssueId"]` with new ID
- Commits transaction to database

**Example:**
```python
# First prepare issue data
dh.set_issue_val({
    "IssueName": "myfile.csv",
    "StatusCode": "IC",
    "RecordCount": 0
})

# Then insert
response = dh.insert_new_issue()
if response["Status"] == "Success":
    issue_id = dh.get_issue_id()
    print(f"Created issue ID: {issue_id}")
```

#### `update_issue(issue: dict) -> dict`
Updates an existing issue record in the database.

**Parameters:**
- `issue` (dict): Fields to update (merged with current issue state)

**Returns:**
- `dict`: `{"Status": "Success"}` or error dict

**Side Effects:**
- Updates database record
- Commits transaction

**Example:**
```python
# Update status and record count
update = {
    "StatusCode": "IC",
    "RecordCount": 1500,
    "LastRecordSeq": 1500
}
response = dh.update_issue(update)
```

#### `is_issue_absent(file_name: str) -> bool`
Checks if a file has already been processed (exists in Issue table).

**Parameters:**
- `file_name` (str): File name to check (matches against SrcIssueName)

**Returns:**
- `bool`: `True` if file is absent (should be processed), `False` if already exists

**Example:**
```python
if dh.is_issue_absent("Account_20241001.csv"):
    print("File not processed yet - proceed with ETL")
else:
    print("File already processed - skip")
```

#### `get_issue_id() -> int`
Returns the IssueId for the currently active publication.

**Returns:**
- `int`: Issue ID, or `-1` if no issue exists yet

**Example:**
```python
issue_id = dh.get_issue_id()
if issue_id == -1:
    print("No issue created yet")
else:
    print(f"Current issue ID: {issue_id}")
```

---

## Usage Patterns

### Pattern 1: Check and Insert New Issue

```python
with DataHub(secret_key, env) as dh:
    # Get publications
    params = {"PublisherCode": "PUBR01", "CurrentDate": datetime.now()}
    dh.get_publication_list(params)
    dh.set_publication_code("PUBN01-ACCT")
    
    # Check if file already processed
    file_name = "Account_20241001.csv"
    if dh.is_issue_absent(file_name):
        # Prepare new issue
        issue_data = {
            "IssueName": file_name,
            "SrcIssueName": "Account.csv",
            "StatusCode": "IP",  # In Progress
            "ETLExecutionId": job_run_id,
            "RecordCount": 0
        }
        dh.set_issue_val(issue_data)
        dh.insert_new_issue()
        
        # Get new issue ID for logging
        issue_id = dh.get_issue_id()
        print(f"Created issue {issue_id}")
```

### Pattern 2: Process and Update Issue

```python
with DataHub(secret_key, env) as dh:
    dh.get_publication_list(params)
    dh.set_publication_code("PUBN01-ACCT")
    
    # Insert initial issue
    dh.set_issue_val({
        "IssueName": "myfile.csv",
        "StatusCode": "IP",  # In Progress
        "RecordCount": 0
    })
    dh.insert_new_issue()
    
    try:
        # Process data
        df = process_data()
        record_count = len(df)
        
        # Update with success
        dh.update_issue({
            "StatusCode": "IC",  # Issue Complete
            "RecordCount": record_count,
            "FirstRecordSeq": 1,
            "LastRecordSeq": record_count
        })
    except Exception as e:
        # Update with failure
        dh.update_issue({
            "StatusCode": "IF",  # Issue Failed
            "RecordCount": 0
        })
        raise
```

### Pattern 3: Multi-Publication Processing

```python
with DataHub(secret_key, env) as dh:
    # Get all publications for publisher
    params = {"PublisherCode": "PUBR01", "CurrentDate": datetime.now()}
    dh.get_publication_list(params)
    
    # Loop through each publication
    for idx, row in dh.publication_list.iterrows():
        pub_code = row["PUBLICATIONCODE"]
        pub_name = row["PUBLICATIONNAME"]
        
        # Set active publication
        dh.set_publication_code(pub_code)
        
        # Process this publication
        print(f"Processing {pub_name}")
        
        # ... insert/update issue as needed ...
```

### Pattern 4: Scheduled Publication Check

```python
with DataHub(secret_key, env) as dh:
    # Get scheduled publications due now
    params = {
        "TriggerTypeCode": "SCH",
        "CurrentDate": datetime.now()
    }
    dh.get_publication_list(params)
    
    if dh.publication_list.empty:
        print("No publications due")
    else:
        print(f"Found {len(dh.publication_list)} due publications")
        # Process each...
```

---

## Error Handling

### Exception Types

The DataHub class may raise:
- `Exception`: General errors (with descriptive messages)
- `ConnectionError`: Database connection failures
- `ValueError`: Invalid parameters or data

### Error Response Pattern

Methods return dicts with status:
```python
{"Status": "Success"}  # Success
{"Status": "Failure", "Message": "error details"}  # Failure
```

### Best Practice Error Handling

```python
try:
    with DataHub(secret_key, env) as dh:
        response = dh.get_publication_list(params)
        
        if response["Status"] != "Success":
            error_msg = response.get("Message", "Unknown error")
            log_to_console(__name__, "Error", error_msg)
            return
        
        # Continue processing...
        
except Exception as e:
    log_to_console(__name__, "Error", f"DataHub error: {str(e)}")
    raise
```

---

## Best Practices

### 1. Always Use Context Manager

```python
# GOOD
with DataHub(secret_key, env) as dh:
    dh.get_publication_list(params)

# AVOID
dh = DataHub(secret_key, env)
dh.get_publication_list(params)
dh.close()  # Easy to forget!
```

### 2. Check Issue Absence Before Inserting

```python
# GOOD
if dh.is_issue_absent(file_name):
    dh.insert_new_issue()

# AVOID - may create duplicates
dh.insert_new_issue()
```

### 3. Set Initial Status to "IP" (In Progress)

```python
# GOOD - indicates processing started
dh.set_issue_val({"StatusCode": "IP", "RecordCount": 0})
dh.insert_new_issue()

# Later update to IC/IF based on outcome
```

### 4. Always Update Final Status

```python
try:
    # Process data
    dh.update_issue({"StatusCode": "IC", "RecordCount": count})
except Exception:
    dh.update_issue({"StatusCode": "IF"})
    raise
```

### 5. Use Meaningful ETLExecutionId

```python
# GOOD
import uuid
execution_id = str(uuid.uuid4())
# or for AWS Glue:
execution_id = job_run_id

dh.set_issue_val({"ETLExecutionId": execution_id})
```

### 6. Validate Publication Exists

```python
response = dh.get_publication_list(params)
if response["Status"] != "Success":
    log_to_console(__name__, "Error", "No publications found")
    return

if dh.publication_list.empty:
    log_to_console(__name__, "Warn", "Empty publication list")
    return
```

### 7. Set Publication Code Before Issue Operations

```python
# GOOD
dh.get_publication_list(params)
dh.set_publication_code("PUBN01-ACCT")
dh.insert_new_issue()

# AVOID - will use wrong publication
dh.get_publication_list(params)
dh.insert_new_issue()  # Uses first publication by default
```

---

## Examples

See comprehensive examples in:
- `python/eimutils/examples/data_hub_example.py`
- `python/eimutils/tests/test_data_hub.py`

---

## Troubleshooting

### Issue: "No Publication list was returned"

**Cause:** No publications match the query criteria.

**Solution:**
- Verify `PublisherCode` is correct and active in database
- Check `CurrentDate` is not too far in future
- Verify publications have `NextExecutionDtm <= CurrentDate`
- Check publication `IsActive = 1` flag

### Issue: "Valid user not returned from secret"

**Cause:** AWS secret doesn't contain expected user key.

**Solution:**
- Verify secret ARN is correct
- Check secret contains `SFSVCUSER` or `SFSVCUSERRAW` key
- Verify AWS credentials have permission to access secret

### Issue: IssueId is -1

**Cause:** No issue has been inserted yet for the active publication.

**Solution:**
- Call `insert_new_issue()` before calling `get_issue_id()`
- Or handle `-1` as "no issue exists" condition

### Issue: Duplicate issues created

**Cause:** Not checking if issue already exists.

**Solution:**
- Always call `is_issue_absent()` before inserting:
```python
if dh.is_issue_absent(file_name):
    dh.insert_new_issue()
```

### Issue: Connection closed unexpectedly

**Cause:** Context manager exited or explicit `close()` called.

**Solution:**
- Keep all operations within the `with` block
- Don't call `close()` manually when using context manager

---

## Related Classes

### DataHubCRUD

Located in `python/eimutils/data_hub_crud.py`, provides generic CRUD operations for DataHub administration:

```python
from eimutils.data_hub_crud import DataHubCRUD

crud = DataHubCRUD()
crud.initialize(secret_arn, env)

# Get all publishers
publishers = crud.get_publishers()

# Get all subscribers
subscribers = crud.get_subscribers()

# Execute custom queries
df = crud.execute_query("SELECT * FROM DATA_HUB.Publication WHERE IsActive = 1")
```

**Use Cases:**
- Administration and maintenance
- Bulk data retrieval
- Custom queries not covered by DataHub class

### StepLogger

Located in `python/eimutils/step_logger.py`, provides hierarchical ETL step logging:

```python
from eimutils.step_logger import StepLogger

logger = StepLogger(secret_key, env, etl_execution_id, "MyProcess", "Description")
logger.start_step("extract")
# ... processing ...
logger.log_step(status="SUCCESS", record_count=1000)
logger.close()
```

**Use Cases:**
- Detailed step-by-step logging within ETL processes
- Performance tracking and timing
- Process audit trail

---

## Status Codes Reference

Common status codes used in the Issue table:

| Code | Meaning | When to Use |
|------|---------|-------------|
| `IP` | In Progress | Issue created, processing started |
| `IC` | Issue Complete | Processing finished successfully |
| `IF` | Issue Failed | Processing encountered an error |
| `IA` | Issue Archived | Historical issue (archived) |
| `IL` | Issue Loaded | Data loaded to target system |

---

## Additional Resources

- **Main Documentation:** [Confluence - eimutils](https://MY_ORG.atlassian.net/wiki/spaces/EIM/pages/3109683221/eim_deutils)
- **Database Schema:** `Database/Control/Tables/` in repository
- **Migration History:** `database_change/` for schema evolution
- **Package Versions:** [Package Upgrades History](https://MY_ORG.atlassian.net/wiki/spaces/EIM/pages/4054351977/Package+Upgrades+eimutils+1.5.0)

---

## Version History

| Version | Changes | Date |
|---------|---------|------|
| 1.11.1 | Comprehensive API documentation, audit fixes, docstring corrections | 2026-05-26 |
| 1.10.0 | SQL injection fixes, improved validation | 2026-04-22 |
| 1.9.0 | dates_to_process enhancements | 2026-01-02 |
| 1.8.0 | Dependency cleanup | 2025-10-20 |
| 1.6.0 | StepLogger class added | 2025-08-20 |
| 1.2.0 | Unit testing in pipeline | 2024-11-05 |
| 1.1.1 | Initial DataHub class | 2024-10-03 |

---

**Last Updated:** 2026-05-26  
**Maintained By:** EIM Data Engineering Team
