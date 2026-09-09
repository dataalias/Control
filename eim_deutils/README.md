# eimutils

A Python package of shared utilities for EIM data engineering, built for use in AWS Glue jobs and Lambda functions. The package provides a single-line connection pattern, DataHub pub/sub workflow management, step logging, S3 operations, Salesforce integration, and more.

Additional documentation: [Confluence — eimutils](https://MY_ORG.atlassian.net/wiki/spaces/EIM/pages/3109683221/eimutils)

## Current Version
```
1.11.4
```

---

## What's Inside

| Module | Purpose |
|--------|---------|
| `utils.py` | `get_snowflake_connection_from_secret` — single-line Snowflake connection from an AWS secret. Also: Google Sheet reader, duplicate detection, date-range helpers, pipeline logging. |
| `data_hub.py` | `DataHub` class — manages publication and issue lifecycle against the DataHub Snowflake schema. **[API Guide](python/docs/DATAHUB_CLASS_GUIDE.md)** |
| `data_hub_connection.py` | Low-level DataHub database functions (publication list, issue insert/update). Called by `DataHub`. |
| `data_hub_crud.py` | `DataHubCRUD` class — generic CRUD operations for DataHub administration (publishers, subscribers, publications). |
| `step_logger.py` | `StepLogger` class — hierarchical ETL step logging to `DATA_HUB.STEP_LOG` with automatic timing and running totals. |
| `logger.py` | `get_logger` — pre-configured logger with ISO 8601 UTC timestamps. |
| `delogging.py` | `log_to_console` — lightweight logging helper; maps string severity to Python logging levels. |
| `aws_secrets.py` | `AwsSecrets` singleton and helpers for AWS Secrets Manager retrieval and Salesforce JWT token generation. |
| `salesforce.py` | `MhiSalesData` — Salesforce OAuth 2.0 JWT authentication and Apex REST API client. |
| `snowflake_connection.py` | `connect_database` — creates a Snowflake connection from a decrypted private key. |
| `decrypt.py` | `getDERKey` / `getPEMKey` — decrypts encrypted PEM private keys for Snowflake key-pair auth. |
| `s3helper.py` | S3 operations: folder creation, uploads, multipart uploads, and zip extraction (including `unzip_file_nested` for multi-publication zip archives). |
| `api_call.py` | `download_file` — downloads a file from a URL to local disk. |
| `address_parser.py` | `extract_addresses` — parses US addresses from unstructured text using the `usaddress` library. |

---

## Project Structure

```
eim_deutils/
├── Database/                        # Reference DDL for all DataHub objects
│   └── Control/
│       ├── Domain/                  # Reference data seed scripts
│       ├── Procedure/               # Stored procedures
│       ├── Schemas/                 # Schema definitions (DATA_HUB, audit, pg)
│       ├── Sequences/               # Sequence definitions (SEQ_ISSUE_ID, etc.)
│       ├── Tables/                  # Table DDL
│       ├── Test/                    # Test and cleanup scripts
│       └── Views/                   # View DDL
├── database_change/                 # Versioned schema migrations (schemachange)
│   ├── V5__EIMARC-5490-...sql
│   ├── V6__EIMARC-5490-...sql
│   ├── V9__EIMARC-6701-...sql
│   ├── V10__EIMARC-6701-...sql
│   └── V11__EIMARC-7266-...sql
├── dhui/                            # Data Hub UI — browser tool for domain data management
├── infra/                           # Infrastructure / deployment configuration
├── python/                          # Python package root
│   ├── eimutils/
│   │   ├── examples/
│   │   │   ├── data_hub_example.py
│   │   │   └── step_logger_example.py
│   │   ├── tests/
│   │   │   ├── test_data_hub.py
│   │   │   └── test_step_logger.py
│   │   ├── address_parser.py
│   │   ├── api_call.py
│   │   ├── aws_secrets.py
│   │   ├── data_hub.py
│   │   ├── data_hub_connection.py
│   │   ├── data_hub_crud.py
│   │   ├── decrypt.py
│   │   ├── delogging.py
│   │   ├── logger.py
│   │   ├── s3helper.py
│   │   ├── salesforce.py
│   │   ├── snowflake_connection.py
│   │   ├── step_logger.py
│   │   └── utils.py
│   ├── pyproject.toml
│   └── requirements.txt
├── python_snowflake/                # Snowflake-specific step logger variant
│   └── eimutils_snowflake/
│       ├── step_logger_factory.py
│       └── step_logger_snowflake.py
└── bitbucket-pipelines.yml          # CI/CD pipeline
```

---

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| Python 3.9+ | 3.11 recommended; matches the Bitbucket pipeline image |
| AWS CLI v2 | Required for SSO login and S3 access |
| Active AWS SSO session | Run `aws sso login --profile <your-profile>` before running tests or migrations. Tests that require Snowflake connectivity are automatically skipped when credentials are absent. |
| Snowflake access | Account, warehouse, and role provisioned for your environment (DEV / STAGE / PROD) |

---

## Running Tests Locally

Create a virtual environment and install dependencies:

```powershell
# From the repo root
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r python\requirements.txt
pip install -e python\
```

Run the test suite:

```powershell
cd python
python -m pytest
```

> Some tests require an active AWS SSO session for Snowflake connectivity. Tests that cannot reach AWS are automatically skipped.

---

## CI/CD Pipeline

The `bitbucket-pipelines.yml` pipeline runs on every push:

1. **Lint** — flake8 (max line length 120)
2. **Test** — pytest against the branch environment
3. **Build** — `python -m build --wheel`
4. **Schema migration** — schemachange applies any new `database_change/V*.sql` files
5. **Publish** — wheel uploaded to S3 and PyPI (prod branch only)

Branch → environment mapping: `develop` → DEV, `release/*` → STAGE, `main` → PROD.

---

## Data Hub UI (dhui)

`dhui` is a Streamlit application deployed to Snowflake that provides a browser-based interface for managing DataHub domain data — publishers, publications, subscribers, reference tables, and issue history. It uses `StepLoggerSnowflake` (from `python_snowflake/`) for in-app audit logging.

Deployment runs inside Snowflake using the Snowflake CLI (`snow`). See [`dhui/docs/STREAMLIT_DEPLOYMENT_GUIDE.md`](dhui/docs/STREAMLIT_DEPLOYMENT_GUIDE.md) for full setup and deployment instructions.

---

## Database Migrations

Versioned SQL scripts in `database_change/` are applied by [schemachange](https://github.com/Snowflake-Labs/schemachange). Files follow the naming convention:

```
V{n}__{TICKET}--{Description}.sql
```

**Important:** schemachange splits files on `;`. Procedure bodies must use a JavaScript stored procedure pattern (no internal semicolons) to avoid parse errors. See `V11` for a working example.

### Running migrations

Migrations are applied by the pipeline via a custom wrapper script (`schema_change_pipeline.py`) that is downloaded from S3 and executed as part of the CI/CD run. There is no local CLI command — to apply a migration outside of the pipeline, run the relevant `V*.sql` file directly against the target environment in a Snowflake worksheet or via SnowSQL.

Reference DDL (for greenfield deployments) lives in `Database/Control/`. See [`Database/README.md`](Database/README.md) for a full object inventory.

---

## Security & Best Practices

### Secrets Management

- **Never hardcode credentials** in source code or configuration files
- Always use AWS Secrets Manager for database credentials
- Ensure IAM roles have minimum necessary permissions
- Rotate secrets regularly according to security policy

### SQL Injection Prevention

The package uses parameterized queries throughout:

```python
# SAFE - parameterized query
cursor.execute("SELECT * FROM table WHERE id = %s", (user_id,))

# UNSAFE - never do this
cursor.execute(f"SELECT * FROM table WHERE id = {user_id}")
```

All DataHub methods use secure query patterns. Dynamic SQL construction includes identifier validation to prevent injection attacks.

### Connection Management

Always use context managers for automatic cleanup:

```python
# GOOD - automatic cleanup
with DataHub(secret_key, env) as dh:
    dh.get_publication_list(params)
# Connection closed automatically

# AVOID - manual management
dh = DataHub(secret_key, env)
dh.get_publication_list(params)
dh.close()  # Easy to forget!
```

### Error Handling

- Check return status before proceeding: `if response["Status"] == "Success":`
- Use try/except blocks for exception handling
- Log errors appropriately without exposing sensitive data
- Update issue status to "IF" (Issue Failed) on errors

### Performance Considerations

- Check `is_issue_absent()` before inserting to avoid duplicates
- Close connections when done (or use context managers)
- For high-volume processing, consider batch operations
- Monitor step logs for performance bottlenecks

### Documentation

- **DataHub Class Guide:** See `python/docs/DATAHUB_CLASS_GUIDE.md` for comprehensive API documentation
- **StepLogger Guide:** See `python/docs/StepLogger_Wiki.md` for logging patterns
- **Examples:** See `python/eimutils/examples/` for working code samples

---

# Publishing to PyPI

Install the package in a Glue ETL job by adding to `--additional-python-modules`:

```
eimutils==1.11.4
```

For AWS Glue, pin the Snowflake connector and urllib3 explicitly to avoid OpenSSL issues:

```
eimutils==1.11.4,snowflake-connector-python>=3.12.0,urllib3<2.0.0
```

## Build

Deactivate the virtual environment first, then build:

```powershell
deactivate
py -m pip install --user --upgrade setuptools wheel
python -m build --wheel
```

Reinstall locally for testing:

```powershell
.venv\Scripts\Activate.ps1
pip install -r python\requirements-local.txt
pip install -e python\
# or install the wheel directly:
pip install .\dist\eimutils-1.11.4-py3-none-any.whl
pip install .\dist\eimutils-1.11.4-py3-none-any.whl --no-deps --force-reinstall
```

## Upload to TestPyPI

```powershell
deactivate
py -m pip install --user --upgrade twine
py -m twine upload --repository testpypi dist/* --user '__token__' --password '@@@MyKey@@@'
```

Install from TestPyPI to verify:

```powershell
.venv\Scripts\Activate.ps1
pip install -i https://test.pypi.org/simple/ eimutils==1.11.4
```

## Upload to PyPI (Production)

```powershell
deactivate
py -m twine upload dist/* --user '__token__' --password '@@@MyKey@@@'
```

Reference: https://towardsdatascience.com/how-to-publish-a-python-package-to-pypi-7be9dd5d6dcd  
Package versions history: https://MY_ORG.atlassian.net/wiki/spaces/EIM/pages/4054351977/Package+Upgrades+eimutils+1.5.0

---

## Change Log

| User | Date | Version | Comment |
|------|------|---------|---------|
| ffortunato | 11/01/2023 | — | Initial package documentation. |
| ffortunato | 11/06/2023 | — | Switch to `python -m build`. |
| ffortunato | 11/10/2023 | — | Snowflake connection helper. |
| ffortunato | 01/05/2024 | 1.0.1 | Snowflake role naming convention updates. |
| aresetnikovas | 05/07/2024 | — | `read_google_sheet`, duplicate test. |
| jgabriel | 08/07/2024 | 1.0.4 | `gspread_try_catch`. |
| jgabriel | 08/29/2024 | 1.0.6 | Removed DataDog functionality. |
| jgabriel | 08/29/2024 | 1.0.7 | Role no longer required in Snowflake connector. |
| ffortunato | 11/05/2024 | 1.2.0 | Unit testing added to pipeline. |
| jgabriel | 12/24/2024 | 1.3.0 | `snowflake_pipeline_logging`. |
| dlu | — | 1.4.0 | `dates_to_process`. |
| ffortunato | 06/03/2025 | 1.5.0 | Package version updates. |
| ffortunato | 07/22/2025 | 1.5.1 | PEP 8 / flake8 formatting. |
| ffortunato | 08/01/2025 | 1.5.2 | `snowflake-connector-python>=3.12`. |
| ffortunato | 08/20/2025 | 1.6.0 | `StepLogger` class. |
| ffortunato | 10/20/2025 | 1.7.0 | `dhui`, Snowflake StepLogger variant. |
| ffortunato | 10/20/2025 | 1.8.0 | Dependency cleanup. |
| Colton | 01/02/2026 | 1.9.0 | `dates_to_process` enhancements. |
| dostrowski | 09/06/2025 | 1.9.x | Salesforce API, basic logger. |
| ffortunato | 04/22/2026 | 1.10.0 | `SEQ_ISSUE_ID`, `DataHubCRUD`, `logger.py`, full README refresh. |
| Colton | 05/13/2026 | 1.11.0 | `salesforce.py` update. |

[Github-flavored Markdown](https://guides.github.com/features/mastering-markdown/)
