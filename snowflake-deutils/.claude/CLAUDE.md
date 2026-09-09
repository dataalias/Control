# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**eimutils** is a shared Python utility library for MY_ORGANIZATION EIM (Enterprise Information Management) data engineering pipelines. It is deployed as a wheel to S3 (`s3://MY_ORG-eim-glue/{env}/lib/eimutils/`) and consumed by AWS Glue jobs, Lambda functions, and Snowflake stored procedures.

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

`dhui/` contains a duplicate `eimutils_snowflake/` package including its own `step_logger_snowflake.py` and `step_logger_factory.py`. This duplication is intentional — the Snowflake native Streamlit app (`dhui/snowflake_streamlit_app.py`) needs a self-contained copy.

### Streamlit UI (dhui/)

`dhui/snowflake_streamlit_app.py` is a Snowflake-native Streamlit app for managing the DATA_HUB schema. It runs inside Snowflake's built-in Streamlit environment (Snowpark session, no AWS).

Key implementation notes:
- **Wheel import**: Extract zip to `/tmp/` with `zipfile.ZipFile(...).extractall('/tmp/')` then `sys.path.insert(0, '/tmp/')`. `sys.path.append('.whl')` does NOT work for imports in Snowflake.
- **Rerun**: Use `st.rerun()` — `st.experimental_rerun()` was removed in Streamlit ≥ 1.27.
- **Cache on instance methods**: Use `_self` (underscore prefix) as the parameter name — Streamlit excludes it from hashing, allowing `@st.cache_data` on instance methods with non-hashable `Session` objects.
- **Column names**: Snowflake returns uppercase; `normalize_column_names()` maps to camelCase; `COUNT(*)` alias `count` → `"Count"` via `.title()`.

### Database DDL

`Database/Control/` holds greenfield DDL for the full `DATA_HUB` schema (tables, sequences, stored procedures, reference data). DDL files use `MY_ORG_@ENV@_RAW.DATA_HUB.<table>` three-part names with `@ENV@` replaced at deploy time.

`database_change/` holds versioned migration scripts (`V{n}__{TICKET}--{Description}.sql`) applied via schemachange. The pipeline downloads and runs `schema_change_pipeline-{PIPELINE_VERSION}.py` from S3. V7 and V8 are intentionally absent — the gap is known and benign.

### Environment Separation

| Branch pattern | Environment | ECR image tag |
|---|---|---|
| `enh*`, `feat*`, `dev*`, `hot*` | DEV | `:dev` |
| `staging`, `release*` | STAGE | `:stage` |
| `main` | PROD | `:latest` |

Pipeline variables `DEUTILS_VERSION` (read from `pyproject.toml`) and `PIPELINE_VERSION` (hardcoded in the `repodata` step) are written to `vars.env` and sourced by downstream steps.

### AWS Glue Compatibility Constraints

`pyproject.toml` pins dependencies per Python version to match what AWS Glue pre-installs:
- Python < 3.11: `snowflake-connector-python<3.0.0`, `urllib3<2.0.0`, `pytz<2022.2`, `pandas<2.0.0`
- Python ≥ 3.11: modern unpinned versions

Do not relax these pins without verifying against the target Glue runtime. The pandas split is critical — pandas 2.x pulls numpy 2.x which breaks `awswrangler` 2.x pre-installed in Glue.

### Error Handling Contract

There is a deliberate three-layer contract:
1. **Connection layer** (`data_hub_connection.py`): always raises on failure.
2. **Business layer** (`data_hub.py`): catches and re-raises with context.
3. **CRUD public API** (`data_hub_crud.py`): logs and returns safe defaults (`[]`, `{}`) — these are called directly by the Streamlit UI which has no try/except.

Do not change `data_hub_crud.py` list methods to raise — the soft-failure behavior is intentional.

### StepLogger Design

`StepLogger` (`step_logger.py`) has a 4-method interface: `__init__` → `start_step` → `log_step` → `close`.

- `Step_Desc` is a **VARIANT** column (not VARCHAR). SQL uses `PARSE_JSON(%s)` in a `SELECT` clause — `PARSE_JSON` cannot be used in a `VALUES` clause with parameters.
- `start_step` raises `RuntimeError` if called while a step is already active.
- `close()` is idempotent — safe to call multiple times.
- `MessageType` in `Step_Desc` JSON uses `"SUCCESS"`, `"FAILED"`, or `"INFO"` (START/END records use `"INFO"`).
- `env` parameter is validated against `^[A-Za-z][A-Za-z0-9_]*$` to prevent SQL injection via the database identifier.

### SQL Injection Guards

- `utils.py`: `_esc()` helper escapes single quotes in all string values passed to `snowflake_pipeline_logging` SQL.
- `step_logger_snowflake.py`: `_e()` helper (defined inside `_insert_step_log`) escapes all f-string-interpolated values.
- `snowflake_connection.py` / `step_logger.py`: `env` is validated as a safe SQL identifier before use in database names.

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

- Project wiki: https://MY_ORG.atlassian.net/wiki/spaces/EIM/pages/3109683221/eimutils

## Known Intentional Decisions

- **`cryptography` pin**: `pyproject.toml` pins `cryptography>=38.0.0,<39.0.0`. This is an old release with known CVEs. The pin is a conscious trade-off for Glue runtime compatibility — do not widen it without testing against the target Glue environment.
- **Duplicate `step_logger_snowflake.py`**: Exists in both `python_snowflake/eimutils_snowflake/` and `dhui/eimutils_snowflake/`. The duplication is intentional — the Streamlit app needs a self-contained copy. Keep both in sync when making changes.
- **`data_hub_crud.py` soft failures**: List methods return `[]` on exception rather than raising. This is by design for Streamlit UI resilience.
- **`notify_subscriber_of_distribution`** and **`get_issue_details`**: Stubbed with `NotImplementedError` — not yet implemented.
- **V7/V8 migration gap**: `database_change/` goes V6 → V9. V7 and V8 were intentionally skipped.
- **`issue_list[-1]`**: The DataHub lookup index is the **last** element (`[-1]`), not `[0]`. The list is ordered ascending; the last entry is the most recent matching publication.

## Hints

Ignore the .venv folder unless question specifically about libraries / requirements are asked.
Ignore files and folders in the .gitignore or prompt me if you think they are needed.