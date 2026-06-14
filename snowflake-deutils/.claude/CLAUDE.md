# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**eimutils** is a shared Python utility library for T-Mobile EIM (Enterprise Information Management) data engineering pipelines. It is deployed as a wheel to S3 (`s3://kaena-eim-glue/{env}/lib/eimutils/`) and consumed by AWS Glue jobs, Lambda functions, and Snowflake stored procedures.

## Build, Test, and Lint

All commands run from the `python/` directory unless noted.

```bash
# Install for local development (from repo root)
pip install -r python/requirements.txt
pip install -e python/

# Run all tests
cd python && python -m pytest

# Run a single test file
cd python && python -m pytest eimutils/tests/test_data_hub.py -v

# Run a single test
cd python && python -m pytest eimutils/tests/test_data_hub.py::TestDataHub::test_insert_issue -v

# Lint (pipeline uses max-line-length=120)
cd python && flake8 --max-line-length=120 eimutils/

# Build the wheel
cd python && python -m build --wheel
```

**Version**: Defined in [python/pyproject.toml](../python/pyproject.toml) under `[project] version`. The pipeline and all `pip install ./eimutils-*.whl` references read this value dynamically via `tomllib`.

## Architecture

### Pub/Sub Data Hub Pattern

The central abstraction is a publisher/subscriber workflow stored in the `DATA_HUB` Snowflake schema:

- **Publishers** produce named **Publications** (e.g., a daily file feed).
- Each delivery of a publication is an **Issue** — a single row in `DATA_HUB.ISSUE` with an ID from `SEQ_ISSUE_ID`.
- **Subscribers** receive Issues via **Subscriptions** → **Distributions**.

The `DataHub` class ([python/eimutils/data_hub.py](../python/eimutils/data_hub.py)) is the high-level entry point. It wraps `data_hub_connection.py` (raw SQL) and `data_hub_crud.py` (admin CRUD).

### Key Modules

| Module | Purpose |
|---|---|
| `data_hub.py` | Issue lifecycle: open, update status, close, check subscribers |
| `step_logger.py` | Hierarchical ETL audit log → `DATA_HUB.STEP_LOG`; auto-times each step |
| `utils.py` | `get_snowflake_connection_from_secret`, `dates_to_process`, `duplicates_test` |
| `aws_secrets.py` | AWS Secrets Manager retrieval; Salesforce JWT token generation |
| `snowflake_connection.py` | Key-pair auth Snowflake connections |
| `s3helper.py` | S3 upload/download, multipart, zip extraction with nested publication routing |
| `salesforce.py` | OAuth 2.0 + Apex REST calls |
| `logger.py` | Pre-configured logger with ISO 8601 UTC timestamps |

### Snowflake-Native Variant

`python_snowflake/` contains `StepLoggerSnowflake` — a Snowpark-native version of `StepLogger` with no AWS dependencies. `step_logger_factory.py` auto-detects whether the runtime is AWS Glue or Snowflake and returns the appropriate implementation.

### Database DDL

`Database/Control/` holds greenfield DDL for the full `DATA_HUB` schema (tables, sequences, stored procedures, reference data). DDL files use `@ENV@` placeholders replaced at deploy time.

`database_change/` holds versioned migration scripts (`V{n}__{TICKET}--{Description}.sql`) applied via schemachange. The pipeline downloads and runs `schema_change_pipeline-{PIPELINE_VERSION}.py` from S3.

### Environment Separation

| Branch pattern | Environment | ECR image tag |
|---|---|---|
| `enh*`, `feat*`, `dev*`, `hot*` | DEV | `:dev` |
| `staging`, `release*` | STAGE | `:stage` |
| `main` | PROD | `:latest` |

Pipeline variables `DEUTILS_VERSION` (read from `pyproject.toml`) and `PIPELINE_VERSION` (hardcoded in the `repodata` step) are written to `vars.env` and sourced by downstream steps.

### AWS Glue Compatibility Constraints

`pyproject.toml` pins dependencies per Python version to match what AWS Glue pre-installs:
- Python < 3.11: `snowflake-connector-python<3.0.0`, `urllib3<2.0.0`, `pytz<2022.2`
- Python ≥ 3.11: modern unpinned versions

Do not relax these pins without verifying against the target Glue runtime.

## Deployment

```bash
# Publish to TestPyPI
python -m twine upload --repository testpypi dist/*

# Publish to PyPI
python -m twine upload dist/*
```

Glue install command (include compatible pins):
```
eimutils==<version>,snowflake-connector-python>=3.12.0,urllib3<2.0.0
```

## Confluence / Jira

- Project wiki: https://kaena1.atlassian.net/wiki/spaces/EIM/pages/3109683221/eimutils

## Hints

Ignore the .venv folder unless question specifically about libraries / requirements are asked.
Ignore files and folders in the .gitignore or promopt me if you think the are needed.