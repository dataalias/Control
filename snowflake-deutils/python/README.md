# eimutils

## Overview
`eimutils` is a Python package that provides classes and helper functions that accelerate the development of Python-based ETL jobs, typically run from AWS Glue or Lambda. The package covers Snowflake connectivity, AWS Secrets Manager integration, DataHub pub/sub workflow management, step logging, S3 operations, Salesforce API access, and address parsing.

---

# Class DataHub

## Overview
The `DataHub` class allows Python packages to interact with the DataHub Snowflake database. At a high level the class connects to the associated DataHub database and interacts with the tables and procedures within. The class is typically used to read feed metadata from the database and prepare an array of dictionaries that describe the metadata and actual values for a specific feed (Publication {metadata} and Issue {feed details}).

    data_hub.py         - DataHub class definition.
    data_hub_connection.py - Low-level database functions called by DataHub.

## Data Hub

Data Hub consists of a series of functions and classes that allow users to track inbound and outbound data feeds from publishing and subscribing systems.

### Class: DataHub

The DataHub class allows Python packages to interact with the DataHub database. A full list of methods and properties follows.

### Data Hub Methods

| Method | Description |
|--------|-------------|
| `__init__(secret_key, env)` | Connects to the Snowflake DataHub database using the provided AWS secret ARN and environment. |
| `connect()` | Private. Establishes the Snowflake database connection. |
| `get_secrets()` | Private. Retrieves and parses credentials from AWS Secrets Manager. |
| `get_publication_list(params)` | Retrieves publications using one of: `PublisherCode` (list of all publications), `PublicationFilePath` (single publication by path), `IssueId` (single publication by issue), or `FileName` (single publication by file name). Returns `{"Status": "Success" \| "Failure"}`. |
| `set_publication_code(publication_code)` | Sets the active publication code and updates the internal index pointer. Re-raises on failure. |
| `get_publication_code()` | Returns the currently active publication code. |
| `get_publication_idx()` | Returns the active publication index within `issue_list`. |
| `get_current_publication()` | Returns the current publication as a dictionary. |
| `get_issue_id()` | Returns the `IssueId` of the current publication; `-1` if not yet inserted. |
| `set_issue_val(issue_updates)` | Updates issue fields in memory (no database write). Pass a dictionary of column-name/value pairs. |
| `insert_new_issue()` | Fetches the next `IssueId` from `DATA_HUB.SEQ_ISSUE_ID`, inserts a new Issue row, and updates `issue_list` with the returned ID. |
| `update_issue(issue)` | Updates an existing Issue row by `IssueId`. |
| `is_issue_absent(file_name)` | Returns `True` if the file has not been processed; `False` if found in DataHub with a non-failed status. |

> **Deprecated:** `get_publication_record` and `get_issue_details` — use `get_publication_list` instead.  
> **TODO:** `write_issue` — combine `insert_new_issue` and `update_issue`.

### Data Hub Properties

| Property | Type | Description |
|----------|------|-------------|
| `publication_list` | `pd.DataFrame` | DataFrame of publications associated with the publisher, returned by `get_publication_list`. |
| `issue_list` | `list` | Array of issue dictionaries derived from the publication list. `issue_list[0]` is a lookup index mapping publication codes to their positions; subsequent entries are individual issue dictionaries. |
| `publication_idx` | `int` | Position in `issue_list` corresponding to the active `publication_code`. |
| `publication_code` | `str` | Currently active publication code. |

The publication list and issue list remain in lock-step. As the user sets publication codes, pointers to both lists are updated automatically. The user only needs to call `set_publication_code` to switch context.

### An Example

```python
from eimutils.data_hub import DataHub

# Parameters for retrieving the publication list
pub_list_parms = {
    'PublisherCode': 'MyPublisherCode',
    'CurrentDate': '2099-Dec-31 23:59:59'  # or datetime.today().strftime('%Y-%b-%d %H:%M:%S')
}

# Create the DataHub object with your AWS secret ARN and environment
dh = DataHub('arn:aws:secretsmanager:MY_AWS_REGION:123456789:secret:my-secret', 'dev')

# Retrieve the publication list
dh.get_publication_list(pub_list_parms)

# If several publications are returned, set the active publication
dh.set_publication_code('MyPublicationCode')

# Determine if the file has already been processed (True = not yet seen)
if dh.is_issue_absent(file_name):

    # Stage values in memory
    issue_updates = {
        'DataLakePath': 's3://' + dl_bucket + s3_key,
        'SrcIssueName': file_name,
        'IssueName':    file_name,
    }
    dh.set_issue_val(issue_updates)

    # Write to the database; IssueId is assigned from SEQ_ISSUE_ID
    dh.insert_new_issue()

    # ... do your ETL work ...

    # Mark the issue complete
    dh.update_issue({'StatusCode': 'IC'})

    # Or mark it failed
    # dh.update_issue({'StatusCode': 'IF'})
```

---

# Class StepLogger

## Overview
The `StepLogger` class provides a simple, 4-method interface for logging ETL process steps to a Snowflake database. It automatically handles timing calculations, maintains running totals, and creates a hierarchical parent-child relationship between the process log and step logs.

Data is logged to:
```
ULTRA_@ENV@_RAW.DATA_HUB.STEP_LOG
```
Table definition: https://MY_ORG.atlassian.net/wiki/spaces/EIM/pages/4189258488/class+StepLogger#Table-Schema

The table uses a sequence (`SEQ__STEP_LOG_ID`) so each logging call knows its own ID and parent ID definitively.

### Logging Hierarchy

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
- **Hierarchical Logging**: Process start record becomes the parent for all step logs
- **Running Totals**: Automatically accumulates `TOTAL_DURATION` and `TOTAL_COUNT`
- **Custom Attributes**: Flexible metadata support via `custom_attributes` dict on all calls
- **Standardized Descriptions**: Consistent JSON step description format with required fields
- **Error Handling**: Comprehensive exception handling with rollback support
- **Connection Management**: Automatic database connection lifecycle management

### StepLogger Methods

| Method | Description |
|--------|-------------|
| `__init__(secret_key, env, etl_execution_id, process_name, process_type, process_description, custom_attributes)` | Connects to Snowflake and logs the process START record. Stores `parent_step_log_id` for all subsequent steps. |
| `start_step(step_name, operation, custom_attributes)` | Begins timing a step (no DB write). Records step name, operation, and timestamp. |
| `log_step(status, description, db_name, record_count, custom_attributes)` | Calculates duration since `start_step`, inserts the step record, and updates running totals. Returns `Step_Log_Id`. |
| `close(custom_attributes)` | Logs the process END record with accumulated `TOTAL_DURATION` and `TOTAL_COUNT`; closes the connection. Safe to call multiple times. |

### StepStatus Values

Pass one of these strings to the `status` parameter of `log_step`:

| Value | Meaning |
|-------|---------|
| `SUCCESS` | Step completed successfully |
| `FAILED` | Step encountered an error |
| `START` | Used internally by `__init__` for the process start record |
| `END` | Used internally by `close` for the process end record |

In practice, ETL code only passes `SUCCESS` or `FAILED` to `log_step`.

## Examples
```
python/eimutils/examples/step_logger_example.py
```

---

# Module: deutils / utils

Commonly used Python functions for Glue Jobs and Lambda.

### `get_snowflake_connection_from_secret(secret_arn, env, aws_region, envlayer, brand, project, database, spark_session)`
Retrieves AWS secrets, decrypts the private key, resolves the appropriate Snowflake role (composite 3.1 roles or legacy), and returns a Snowflake connection. Pass `spark_session=True` to receive `sfOptions` dict for Spark DataFrame usage instead.

### `read_google_sheet(google_sheet, name, client, spark_session)`
Reads an entire worksheet from a Google Sheet using a `gspread` client. Returns a Pandas or Spark DataFrame.

### `gspread_try_catch(gspread_object, method, *args, **kwargs)`
Wrapper that calls `gspread` methods with a single retry (waits 20 seconds on first failure).

### `duplicates_test(column, partition, input, db, schema, table_name, snow_cur)`
Tests for duplicate values in a Pandas DataFrame or a Snowflake table. Raises `RuntimeError` if duplicates are found.

### `snowflake_pipeline_logging(env, job_name, job_status, job_details, source_location, table_name, row_count, region, job_id)`
Inserts ETL job execution records into `DATA_HUB.ISSUE`. Supports single or multi-value inserts; validates list lengths.

### `dates_to_process(file_dt_from, file_dt_to, last_processed_date)`
Generates the date range to process. Defaults to yesterday if dates are not provided. Returns `(start_date, end_date, list_of_dates)` in `YYYY-MM-DD` format.

---

# Module: delogging

Small helper functions for standardized logging.

### `log_to_console(function_name, message_type, message)`
Unified logging function. Maps message type strings (`info`, `err`, `error`, `warn`, `warning`) to Python logging levels. Auto-registers a handler if none exists on the logger or root, making it safe to call without a prior `get_logger` call. `message` may be any type.

---

# Module: logger

Core logging setup for the package.

### `get_logger(name, level)`
Returns a pre-configured `logging.Logger` with ISO 8601 UTC timestamps (`YYYY-MM-DDTHH:MM:SS.sssZ`). Attaches a `stdout` StreamHandler and prevents log propagation to the root logger. Idempotent — repeated calls for the same name reuse the existing logger.

---

# Module: aws_secrets

AWS Secrets Manager integration and Salesforce JWT token generation.

### Class: `AwsSecrets`
Singleton class. Retrieves and caches secrets from AWS Secrets Manager to prevent redundant API calls. Also generates RS256-signed Salesforce JWT tokens (5-minute validity).

| Method | Description |
|--------|-------------|
| `__new__(secret_arn, aws_region)` | Singleton constructor; creates one instance per ARN. |
| `initialize_aws_secrets(secret_arn, aws_region)` | Fetches secrets from AWS on first use. |
| `get_secret()` | Returns the cached secret dictionary. |
| `get_sfdc_jwt_token()` | Generates and returns a signed Salesforce JWT bearer token. |

### `get_secrets(secret_arn, aws_region)`
Retrieves a secret string or binary from AWS Secrets Manager. Handles `DecryptionFailure`, `InternalServiceError`, `InvalidParameter`, `InvalidRequest`, and `ResourceNotFound`.

### `get_secrets_dict(secret_arn, aws_region)`
Wraps `get_secrets` and parses the result as JSON, returning a dictionary.

---

# Module: salesforce

Salesforce OAuth 2.0 integration.

### Class: `Base`
Base class for Salesforce JWT bearer token authentication. Exchanges a JWT for an access token on initialization; stores `bearer_token` and `instance_url`.

### Class: `MhiSalesData(Base)`
Specialized subclass for retrieving MHI sales data from a Salesforce Apex REST endpoint.

| Method | Description |
|--------|-------------|
| `get_sales_data(call_date)` | POSTs to Salesforce and returns sales data for a given date. Returns empty dict on 404; raises on other errors. |

---

# Module: snowflake_connection

Low-level Snowflake connectivity.

### `connect_database(sf_user, sf_account, pkbDER, sf_role, sf_database)`
Creates and returns a Snowflake connection using private key (DER bytes) authentication. Role and database are optional.

---

# Module: decrypt

Private key decryption utilities for Snowflake key-pair authentication.

### `getDERKey(dw30sfpkey, dw30sfpprs)`
Decrypts an encrypted PEM private key and returns it in DER format (bytes).

### `getPEMKey(dw30sfpkey, dw30sfpprs)`
Decrypts an encrypted PEM private key and returns it as a PEM string with whitespace stripped.

---

# Module: s3helper

Composite S3 operations built on `boto3`.

### `s3_create_folder(s3_bucket_name, s3_bucket_path, s3_sub_folders)`
Creates a folder path in an S3 bucket if it does not already exist. Returns `"Success"` or `"Failure"`.

### `upload_objects_to_s3(file_name, s3bucketname, object_name)`
Uploads file content to an S3 bucket. Logs errors on failure.

### `Read_Objects_From_S3(S3_BucketName, object_name)`
Retrieves an S3 object reference.

### `multi_part_upload_with_s3(file_name, s3bucketname, object_name)`
Uploads a file to S3 using multipart upload with threading and a progress callback.

### Class: `ProgressPercentage`
Callback class that displays multipart upload progress (bytes transferred and percentage).

### `unzip_file(s3bucket, s3folder, s3unzipfolder, zip_filename)`
Reads a `.zip` from an S3 source folder and writes extracted contents to a destination folder within the same bucket. Assumes all archive contents go to a single folder.

### `unzip_file_nested(s3bucket, s3folder, zipfilename, dh, env, file_name_prefix)`

```python
def unzip_file_nested(s3bucket, s3folder, zipfilename, dh, env, file_name_prefix=''):
```

Reads a `.zip` from an S3 bucket and writes the uncompressed contents to separate S3 locations based on regex patterns from a DataHub publication list. Also inserts issue records into DataHub for each matched file.

| Parameter | Description |
|-----------|-------------|
| `s3bucket` | S3 bucket name (source and destination) |
| `s3folder` | Source folder containing the compressed file |
| `zipfilename` | File to decompress |
| `dh` | DataHub object containing the regex mapping and issue data |
| `env` | Environment string (`dev`, `stage`, `prod`) |
| `file_name_prefix` | Optional string to prepend to extracted filenames |

DataFrame input example (`dh.publication_list`):
```python
{
   'SRCFILEREGEX': {
      0: '[a-f0-9]{8}-...-[a-f0-9]{12}.zip',
      1: '[a-f0-9]{8}-...-[a-f0-9]{12}_Contacts.csv.gz',
      2: '[a-f0-9]{8}-...-[a-f0-9]{12}_Scores.csv.gz',
   },
   'PUBLICATIONFILEPATH': {
      0: '/internal/callminer/zip/',
      1: '/internal/callminer/contacts/',
      2: '/internal/callminer/scores/',
   }
}
```

---

# Module: api_call

### `download_file(url, local_filename)`
Downloads a file from a URL and saves it locally. Raises an exception on failure.

---

# Module: address_parser

## Overview
Processes unstructured input strings, extracts US address information, and returns it in a structured format. Useful for normalizing address data from messy input sources.

## Installation
```bash
pip install usaddress
```

## How It Works
1. Receives a raw string that may contain address data mixed with emails, phone numbers, or other noise.
2. Uses regular expressions to strip irrelevant data.
3. Passes the cleaned string to the `usaddress` library for component extraction.
4. Returns a structured dictionary.

### `extract_addresses(input_string)`
Returns a list of dictionaries, each containing:

| Key | Description |
|-----|-------------|
| `address_line_1` | Primary address line |
| `address_line_2` | Secondary line (suite, apartment, etc.) |
| `city` | City name |
| `state` | State abbreviation |
| `zip_code` | ZIP code |

### Example

```python
from eimutils.address_parser import extract_addresses

parsed = extract_addresses("Hubert B, 456 Elm St, Suite 2, Anytown, CA 90210")
# Returns:
# [{'address_line_1': '456 Elm St', 'address_line_2': 'Suite 2',
#   'city': 'Anytown', 'state': 'CA', 'zip_code': '90210'}]
```

> Input that cannot be parsed is skipped and an error is logged.

---

# Module: DataHubCRUD

Generic CRUD operations for DataHub management tasks (publisher, subscriber, publication administration).

### Class: `DataHubCRUD`

| Method | Description |
|--------|-------------|
| `initialize(secret_arn, env, aws_region, ...)` | Establishes a Snowflake connection and sets the schema to `DATA_HUB`. Returns the connection or raises. |
| `execute_query(query, params)` | Executes a `SELECT` and returns results as a Pandas DataFrame. |
| `execute_command(query, params)` | Executes `INSERT` / `UPDATE` / `DELETE`; returns row count; handles commit/rollback. |
| `get_publishers()` | Returns all publishers as a list of dicts. |
| `get_subscribers()` | Returns all subscribers as a list of dicts. |
| `get_publications()` | Returns all publications as a list of dicts. |
| `validate_referential_integrity(table_name, operation, data)` | Validates referential integrity before a write operation. Returns `(is_valid: bool, message: str)`. |
| `log_activity(activity_name, details, status)` | Writes an activity record to the audit log via `log_to_console`. |

### Example

```python
from eimutils.data_hub_crud import DataHubCRUD

crud = DataHubCRUD()
crud.initialize(
    secret_arn='arn:aws:secretsmanager:MY_AWS_REGION:123456789:secret:my-secret',
    env='dev'
)

# Read
publishers = crud.get_publishers()

# Write
row_count = crud.execute_command(
    "INSERT INTO DATA_HUB.Publisher (PublisherCode, PublisherName) VALUES (%s, %s)",
    params=('ACME', 'Acme Corp')
)
```

---

# Unit Tests

```bash
cd $PROJECT_HOME/eim_deutils/python
python -m pytest
```

Runs regression tests to verify eimutils functions behave correctly during the deployment pipeline.

### Currently tested

| Area | Tests |
|------|-------|
| Secrets | AWS Secrets Manager retrieval |
| DataHub | Insert Issue, Update Issue, is_issue_absent |
| StepLogger | Process start/step/close lifecycle, connection guard |

---

# Lambda Layer

When you need to build a Lambda layer:
https://awstip.com/create-aws-lambda-layers-using-cloud-9-694895903ca5

---

### Change Log

| User | Date | Comment |
|------|------|---------|
| ffortunato | 11/01/2023 | Describing overall package. |
| ffortunato | 02/26/2024 | Added delogging. |
| ffortunato | 09/04/2024 | unzip documentation. |
| ffortunato | 09/11/2024 | unzip_file_nested documentation. |
| ffortunato | 11/05/2024 | Version 1.2.0 + unit testing for regression in pipeline. |
| ffortunato | 01/29/2025 | Version 1.4.0 + subscription / outbound, address function. |
| ffortunato | 01/29/2025 | Version 1.6.0 + class StepLogger. |
| dostrowski | 09/06/2025 | Version 1.6.1 + Salesforce API, basic logger. |
| ffortunato | 04/22/2026 | Version 1.10.0 + SEQ_ISSUE_ID, DataHubCRUD, full README refresh. |

[Github-flavored Markdown](https://guides.github.com/features/mastering-markdown/)
