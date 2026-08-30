# eimutils Full Project Review — Action Items

Generated: 2026-06-23  
Branch: `enh-EIMARCH-0000-Audits`

Legend: 🔴 Critical · 🟠 High · 🟡 Medium · 🟢 Low  
`[x]` = resolved · `[ ]` = open

---

## 🔴 Critical

- [x] **C1** `data_hub_connection.py:232` — `PeriodEndTimeUTC` mapped to `HIGHWATERMARKDATETIME` (local time) instead of `HIGHWATERMARKDATETIMEUTC`. Every issue created from a publication list lookup stores the wrong UTC timestamp.
- [x] **C2** `data_hub_connection.py:137-144` — `FileName`, `IssueId`, `PublicationFilePath` `get_type` branches fall through to `sql = "N/A"` → `cursor.execute("N/A")` raises `ProgrammingError`. These are documented as working features with no SQL implementation.
- [x] **C3** `data_hub_connection.py:150-151` — `error_msg` is only defined inside the `"Schedule"/"PublisherCode"` branch. In the `"N/A"` else-branch, the except handler references undefined `error_msg` → `NameError` masks the real error.
- [x] **C4** `data_hub_connection.py:381-387` — Generic `except` returns `{"message": error_msg}` instead of raising. Caller merges this into the issue dict; `IssueId` is never set; `get_issue_id()` raises `KeyError`. Insert failures are silently swallowed.
- [x] **C5** `Database/Control/Tables/Publisher.sql:39` — FK `CONSTRAINT FK_RefContact__ContactId FOREIGN KEY ( ContactId )` references a column (`ContactId`) that was replaced by `ContactName varchar(255)`. DDL will fail at runtime.
- [x] **C6** `Database/Control/Procedure/USP_INSERT_NEW_ISSUE.sql:26-43` — INSERT VALUES list is shifted by one position: `pPublisherCode` is passed as the value for `PublisherId` (AUTOINCREMENT integer). Corrupts every row the procedure inserts.
- [x] **C7** `dhui/snowflake_streamlit_app.py:34` — `sys.path.append('/tmp/eimutils_snowflake-1.0.0-py3-none-any.whl')` does not work. Python cannot import from a `.whl` path directly. `STEP_LOGGER_AVAILABLE` is always `False`; step logging is silently disabled.
- [x] **C8** `dhui/snowflake_streamlit_app.py:831-837` — `session.sql(query, param_list).to_pandas()` is called inside the `for key, value in params.items()` loop. Query runs once per parameter with a partially-substituted query string. Only the last iteration's result is used. Data correctness bug for any multi-parameter query.

---

## 🟠 High

- [x] **H1** `data_hub.py:244-246` — `.loc[0, ["PUBLICATIONCODE"]]` (list brackets) returns a `pd.Series`, not a `str`. Should be `.loc[0, "PUBLICATIONCODE"]`.
- [x] **H2** `data_hub.py:45,351` — `notify_subscriber_of_distribution` declared in module docstring and change history, but no method body exists anywhere. Calling it raises `AttributeError`.
- [x] **H3** `data_hub_connection.py:381-391,454` — `cursor` variable may be unbound when connection fails before `cursor = connection.cursor()`. `finally: cursor.close()` then raises `NameError`. Same pattern in `update_issue` at line 454.
- [x] **H4** `step_logger.py:950-953` — `_insert_step_log` catches all exceptions, logs them, and returns `None` instead of raising. Docstring says it raises on failure. `parent_step_log_id` silently becomes `None`; every subsequent step row is orphaned.
- [x] **H5** `step_logger.py:384-394` — `start_step` called while a step is already active silently overwrites `current_step_name` / `current_step_start` / `current_step_custom_attributes`. Old step's timing is lost permanently with no DB record written.
- [x] **H6** `step_logger.py:921` — INSERT SQL built with `f"INSERT INTO {self.database}.DATA_HUB.STEP_LOG ..."`. `self.database` derives from `env` (user input); only `.upper()` applied. SQL injection risk via unvalidated identifier.
- [x] **H7** `step_logger.py` / docs — `get_next_sequence_value()` documented as a public method in both `README_StepLogger.md` and `StepLogger_Wiki.md`. Only `_get_next_step_log_id()` (private) exists. Code using the documented API gets `AttributeError`.
- [x] **H8** `README_StepLogger.md:96` / `StepLogger_Wiki.md:59` — DDL in both docs shows `Step_Desc varchar(8000)`. Code uses `PARSE_JSON(%s)` into a `VARIANT` column. Anyone using the README DDL creates a `VARCHAR` column and inserts fail.
- [x] **H9** `s3helper.py:300` — `ExtraArgs={"ACL": "public-read"}` on every multipart upload. Objects become publicly readable. Buckets with S3 Block Public Access will throw `ClientError`, silently breaking all multipart uploads.
- [x] **H10** `aws_secrets.py:63` — Singleton `__new__` returns cached `_instance` unconditionally. Two callers with different ARNs in the same process both get data from the first ARN with no warning.
- [x] **H11** `aws_secrets.py:191` — `logger.debug(f"Secret Retrieved :: Value: {get_secret_value_response}")` logs the full plaintext secret. Credentials leak to CloudWatch/stdout when DEBUG logging is enabled.
- [ ] **H12** `python/pyproject.toml:35-36` — `cryptography>=38.0.0,<39.0.0` forces a 3-year-old release (2022) with known CVEs (e.g., CVE-2023-49083).
- [x] **H13** `python/pyproject.toml:37-39` — Conditional `pandas` version pins (needed for Glue 3.9/3.10 compatibility) are commented out, replaced with unconstrained `pandas`. Reintroduces known breakage with `pandas 2.x` + `numpy 2.x` on Glue.
- [x] **H14** `python/requirements.txt` — `cryptography`, `pyjwt`, `usaddress`, `requests` are missing. Pipeline build/test step will fail with `ModuleNotFoundError` for any test that imports these.
- [x] **H15** `python/pyproject.toml:153-154` — `testpaths = ["tests"]` points to `python/tests/` (doesn't exist). Actual tests are in `python/eimutils/tests/`. Running `pytest` from `python/` collects zero tests silently.
- [x] **H16** `bitbucket-pipelines.yml:193` — Prod deploy step does `aws s3 cp s3://MY_ORG-eim-glue/stage/lib/eimpipeline/...`. Should be `prod/lib/eimpipeline`. Stage artifacts have been deploying to production.
- [x] **H17** `dhui/snowflake_streamlit_app.py:700,777` (+16 more sites) — `st.experimental_rerun()` was removed in Streamlit ≥ 1.27. All ~18 call sites raise `AttributeError`. UI never refreshes after any write operation.
- [x] **H18** `dhui/snowflake_streamlit_app.py:1070` — Referential integrity check uses `dependent_df.iloc[0]["count"]` (lowercase) but `normalize_column_names` applies `.title()` → key is `"Count"`. Raises `KeyError`; publishers with children may be incorrectly deleted.
- [x] **H19** `dhui/eimutils_snowflake/__init__.py:9` — `from .step_logger_factory import get_step_logger` — file `dhui/eimutils_snowflake/step_logger_factory.py` does not exist. Package fails to import.
- [x] **H20** `Database/Control/Tables/Publication.sql:21` — Uses three-part `MY_ORG_@ENV@_RAW.DATA_HUB.Publication` while all other tables use two-part `DATA_HUB.<table>`. Greenfield deployment creates objects in different databases.
- [x] **H21** `Database/Control/Procedure/USP_INSERT_NEW_PUBLISHER.sql` — File name and comments say "PUBLISHER" but procedure is `USP_INSERT_NEW_PUBLICATION`. Both procedure files are identical duplicates. No actual `USP_INSERT_NEW_ISSUE` DDL exists.
- [x] **H22** `Database/Control/Tables/Distribution.sql:30` — `StatusId integer` FK to `REF_Status` while `Issue` table uses `StatusCode varchar`. If `REF_Status` has no `StatusId` column, DDL fails.
- [x] **H23** `dhui/snowflake_streamlit_app.py:587-598` — Status dropdown hardcodes `["ACTIVE","INACTIVE","PENDING","RESOLVED"]`. Should load from `REF_Status` via existing `get_ref_statuses()` method.

---

## 🟡 Medium

- [x] **M1** `data_hub.py:302-305` — Double commit: `update_issue` commits inside the connection layer (line 421) AND `data_hub.py` commits again (line 305). Inconsistent transaction ownership.
- [x] **M2** `data_hub.py:37-38` — `get_issue_details` listed in module docstring but not implemented. No stub or `NotImplementedError`.
- [x] **M3** `data_hub_crud.py:145-173` — `get_publishers`, `get_subscribers`, `get_publications` catch all exceptions and return `[]`. Connection failures look identical to empty tables.
- [x] **M4** `data_hub_connection.py:415` — All `update_issue` values cast to `str` before passing to Snowflake. Bypasses type checking for integers and datetimes; can silently corrupt numeric columns.
- [x] **M5** `test_data_hub.py:605-607` — Cleanup SQL is commented out. Test data accumulates in the DEV database after every integration test run.
- [x] **M6** `step_logger.py:510` — `int()` truncation gives `duration = 0` for sub-second steps. Should use `round()`.
- [x] **M7** `step_logger.py:657` — END record `Start_Dtm` captured inside DB setup overhead rather than at the top of `close()` before any database activity.
- [x] **M8** `utils.py:745-758` — "Up-to-date" branch of `dates_to_process` still appends `start_dt` to `file_dt_list`, causing the last-processed date to re-process.
- [x] **M9** `utils.py:745-770` — Mixed "one date provided, one not" state causes `UnboundLocalError: local variable 'file_dt_list' referenced before assignment`. No test covers this path.
- [x] **M10** `utils.py:564-611` — `snowflake_pipeline_logging` uses unsanitized f-string SQL for `job_name`, `job_status`, `source_location`, `table_name`, `job_id`. SQL injection risk.
- [x] **M11** `s3helper.py:250` — `unzip_file_nested` catches exceptions, logs, and returns partial result without re-raising. Callers who don't inspect the return dict have no idea a failure occurred.
- [x] **M12** `s3helper.py:225` — Magic column indices `.iloc[0, 25]` and `.iloc[0, 5]` for `PublicationFilePath` and `PublicationCode`. A schema change silently reads the wrong values.
- [x] **M13** `salesforce.py:163` — Docstring says returns `list`; function actually returns `dict` (or `{}` on empty). Callers expecting a list will fail.
- [x] **M14** `salesforce.py:73,154` — `requests.post` has no `timeout`. A hung TCP connection blocks the Glue job thread indefinitely.
- [x] **M15** `aws_secrets.py:155` — `get_secrets_dict` calls `json.loads` on the result of `get_secrets`. Binary secret path returns bytes; `json.loads` raises `JSONDecodeError` with no context.
- [x] **M16** `snowflake_connection.py:49-53` — When `sf_database == ""`, `role` is silently dropped from the connection kwargs. Caller providing a role but no database connects without the requested role.
- [x] **M17** `decrypt.py:78` — Regex uses `-*` (zero-or-more dashes) instead of `-+`. Also fails for `ENCRYPTED PRIVATE KEY` header variant.
- [x] **M18** `decrypt.py:38,68` — `getDERKey` and `getPEMKey` have no exception handling; `ValueError`/`TypeError` from a bad PEM or wrong passphrase surfaces with cryptographic low-level messages.
- [x] **M19** `api_call.py:44` — Non-200 response logs an error and returns `None` silently instead of raising. Callers have no exception to catch.
- [x] **M20** `dhui/snowflake_streamlit_app.py:483-491` — `if not current_value` is `True` for `0`, `0.0`, `False`. Zero/False field values are incorrectly treated as missing and overwritten.
- [x] **M21** `dhui/snowflake_streamlit_app.py:900-933` — `@st.cache_data` on instance methods where `self` is non-hashable (`Session` object). Methods already use `_self` (underscore prefix) which Streamlit excludes from hashing — no change needed.
- [x] **M22** `dhui/snowflake_streamlit_app.py:108-127` — `log_ui_operation` never calls `close()`. `STEP_LOG` accumulates processes with no END record. If `log_step` is never reached, subsequent calls raise `RuntimeError`.
- [ ] **M23** `dhui` vs `python_snowflake` — `step_logger_snowflake.py` is duplicated verbatim in both directories with no single source of truth. Changes to one won't propagate to the other.
- [x] **M24** `dhui/docs/DATAHUB_UI_README.md:28-53` — Schema diagram shows nonexistent columns (`ContactId` on Publisher, `GlueWorkflow`/`IsActive` on Publication) and a `Contact` table that has no implementation.
- [x] **M25** `dhui/docs/DATAHUB_UI_README.md:102-133` — Quick Start references wrong files (`launch_datahub_ui.py`, `streamlit_datahub_complete.py`) and describes AWS Secrets Manager setup; none of this applies to the Snowflake-native app.
- [x] **M26** `dhui/docs/DATAHUB_UI_README.md:212` — "System Analytics" page documented with real-time metrics and trend analysis; no such page exists in the app.
- [x] **M27** `python_snowflake/step_logger_snowflake.py:461-479` — INSERT SQL built with f-string interpolation of `process_name`, `step_name`, `etl_execution_id`, `step_desc_json`. SQL injection risk if values contain single quotes.
- [x] **M28** `README.md:9` — "Current Version" shows `1.11.1`; actual version is `1.11.2`.
- [x] **M29** `python/pyproject.toml:5` — `pybind11` in `[build-system].requires` is unnecessary for a pure-Python package.
- [x] **M30** `python/pyproject.toml:40` — `pyjwt>=2.12.0` requires a very new release (April 2026). May block older Glue environments.
- [x] **M31** `python/requirements-local.txt:15,18-19` — `pyarrow`, `streamlit`, `pydantic` are not in `pyproject.toml` optional deps; `pyarrow<19.0.0` upper bound already blocks fresh installs as of mid-2026.
- [x] **M32** `Views/PUBLICATION_LIST.sql:31` — `IssueName` hardcoded as `'Unknown'`. Every new issue gets `IssueName = "Unknown"` instead of the real value.
- [x] **M33** `data_hub_connection.py:90-91` — `subn.SUBSCRIPTIONFILEPATH` in SQL; downstream code accessing `row['SubscriptionFilePath']` (mixed-case) gets `KeyError`.
- [x] **M34** `database_change/V11,V12` — V11 and V12 contain identical SQL. Duplicate migration script should be removed.
- [x] **M35** `database_change/` — Version gap: no V7 or V8. Intentionally skipped per project decision.
- [x] **M36** `database_change/V5:12` — V5 migration creates `SRCDFCREATEDDATE` as `DATE`; greenfield DDL uses `TIMESTAMP_TZ`. Python code writes a datetime string including time component into a `DATE` column.
- [x] **M37** `bitbucket-pipelines.yml:65,120,168` — `pip install aws` installs an unrelated third-party PyPI package, not the AWS CLI (which is installed separately via curl).
- [x] **M38** `bitbucket-pipelines.yml:94-100` — Tests run via `python -m unittest discover`, bypassing all pytest config, markers, and coverage reporting. Stage pipeline has no `flake8` run.
- [x] **M39** `test_step_logger.py` — Zero unit tests with mocks; entire suite requires live Snowflake and AWS credentials. Cannot run in CI without credentials.
- [x] **M40** `Database/Control/Tables/Subscriber.sql:23` — `ContactId integer NOT NULL` with no FK defined; inconsistent with `Publisher`'s `ContactName varchar` approach.

---

## 🟢 Low

- [x] **L1** `data_hub.py:148,187,194` — Three getter method docstrings incorrectly say "setter."
- [x] **L2** `data_hub_example.py:308` — Accesses `PUBLICATIONDESC` column which is not selected by the SQL query; always returns the default `"N/A"`.
- [x] **L3** `test_data_hub.py:538-540` — `dh.db_connection.is_closed()` is not a real Snowflake connector method. Test raises `AttributeError` when run.
- [x] **L4** `step_logger.py:566-681` — `close()` docstring says "safe to call multiple times (no-op)." No guard exists; second call raises from the Snowflake connector.
- [x] **L5** `README_StepLogger.md:664` — Mock test example asserts `step_number == 2` after 1 step + 1 close; correct value is 3.
- [x] **L6** `step_logger_factory.py:57` — `'AWS_EXECUTION_ENV' in sys.modules` checks modules, not environment variables. This condition can never be `True`. Dead code.
- [x] **L7** `decrypt.py` — `default_backend()` is deprecated since `cryptography` 3.x; produces `CryptographyDeprecationWarning` on modern runtimes.
- [x] **L8** `delogging.py:42` — Handler check includes root logger; child loggers in Glue may skip ISO format setup.
- [x] **L9** `step_logger.py:392` — `self.operation` not under `current_step_*` naming convention; not reset after `log_step`. Stale value bleeds into next step if `operation` is not passed.
- [x] **L10** `step_logger.py:513-516` — `MessageType = "INFO"` used in START/END records but docs only list `"SUCCESS"` and `"ERROR"` as valid values. Surprises consumers parsing `Step_Desc`.
- [x] **L11** `utils.py:513` — `snowflake_pipeline_logging` docstring says target table is `MY_ORG_DL_MONITORING.JOB_RUN_DETAILS`; code inserts into `DATA_HUB.ISSUE`.
- [x] **L12** `examples/step_logger_example.py:46-78` — `"{i}"` string literal in custom_attributes should be `i` (variable reference).
- [x] **L13** `test_step_logger.py:164-165` — Comment says "FAILED step should not add to TOTAL_COUNT" but the test only passes because `record_count` is `None`, not because of the `FAILED` status.
- [x] **L14** `README.md:229-255` — `pip install` commands reference wheel version `1.11.0`; current is `1.11.2`.
- [x] **L15** `CHANGELOG.md` — Most entries missing release dates and status.
- [x] **L16** `eimutils/__init__.py:5` — Docstring typo: "Initalize the eimultis package."
- [x] **L17** `dhui/docs/STREAMLIT_DEPLOYMENT_GUIDE.md:117-127` — Verification SQL references columns `STATUS` and `CUSTOM_ATTRIBUTES`; actual `STEP_LOG` columns are `Step_Status` and `Step_Desc`.
- [x] **L18** `bitbucket-pipelines.yml:193` — Stage step echoes `$VERSION` which is never set in that context; always prints empty.
- [x] **L19** `salesforce.py:80` — Auth failure produces two log entries for the same event (logs before raise, then logs again in except).
- [x] **L20** `address_parser.py:49` — Phone regex misses dashed (`217-555-1234`) and dotted (`217.555.1234`) US phone formats.
- [x] **L21** `test_salesforce.py:69` — `mock_post.call_args[1]["data"]` uses positional index; should use `.call_args.kwargs["data"]` for Python 3.8+ clarity.
- [x] **L22** `data_hub_connection.py:258-270` — `None` guards in `prepare_issues` are redundant for `PeriodStartTime` / `PeriodStartTimeUTC` (already covered by SQL `IFNULL`) but not applied to `PeriodEndTime` / `PeriodEndTimeUTC`. Inconsistent and confusing.

---

## Highest-Priority Fixes (Sequenced)

| # | File | Issue | Status |
|---|------|-------|--------|
| 1 | `bitbucket-pipelines.yml:193` | Prod deploy pulls from `stage` S3 bucket | `[x]` |
| 2 | `data_hub_connection.py:232` | `PeriodEndTimeUTC` mapped to wrong column | `[x]` |
| 3 | `dhui/snowflake_streamlit_app.py:831-837` | SQL executed inside param-replacement loop | `[ ]` |
| 4 | `dhui/snowflake_streamlit_app.py` | Replace all `st.experimental_rerun()` with `st.rerun()` | `[ ]` |
| 5 | `dhui/snowflake_streamlit_app.py:34` | Fix wheel import (`sys.path.append` on `.whl` doesn't work) | `[ ]` |
| 6 | `aws_secrets.py:191` | Remove secret value from DEBUG log | `[x]` |
| 7 | `s3helper.py:300` | Remove `ACL: public-read` from multipart upload | `[x]` |
| 8 | `pyproject.toml:37-39` | Restore commented-out pandas version pins | `[ ]` |
| 9 | `pyproject.toml:153-154` | Fix `testpaths` to point to actual test directory | `[x]` |
| 10 | `Database/Control/Tables/Publisher.sql:39` | Remove broken FK on `ContactId` | `[ ]` |
