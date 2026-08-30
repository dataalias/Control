# Database/Control

Reference DDL and scripts for the DATA_HUB pub/sub schema. Objects are organized by type under `Database/Control/`.

---

## Schemas

| Schema | Purpose |
|--------|---------|
| DATA_HUB | Primary schema. Holds all pub/sub control tables, views, procedures, and sequences. Role-based access (read / write / admin) provisioned per environment (DEV, STAGE, PROD). |
| audit | Audit/step-logging schema. Hosts `STEP_LOG` for ETL process tracking. |
| pg | Posting Group schema for posting-group processing objects. |

---

## Sequences

| Object | Purpose |
|--------|---------|
| SEQ_ISSUE_ID | Explicit sequence for `DATA_HUB.ISSUE.IssueId`. Provides a safe next value before each INSERT, eliminating the `MAX(IssueId)` race condition present with AUTOINCREMENT. Created by the V11 migration; Python reads `SEQ_ISSUE_ID.NEXTVAL` before every issue insert. |

---

## Tables

### Core pub/sub tables

| Table | Purpose |
|-------|---------|
| Publisher | A vendor or third-party entity that delivers files for ingestion. Stores name, interface code, and contact information. |
| Publication | Metadata for each feed a publisher produces: source paths, file formats, interval/retry settings, trigger type, SLA time, and processing method. |
| Subscriber | A system that receives and loads publisher files. Stores name, interface code, and notification details. |
| Subscription | Maps a publication to the subscribers that will load it. Links publications and subscribers with interface and file-format details. |
| Issue | The central workflow table. One row per file-load attempt. Tracks status, period start/end times, record counts, checksums, sequence markers, and ETL execution IDs. |
| Distribution | One row per subscriber per issue. Tracks which subscriber receives which issue, with status and retry count. |
| Contact | Contact information for parties interested in a given publication or record. |

### Reference (lookup) tables

| Table | Purpose |
|-------|---------|
| REF_File_Format | Supported file formats (CSV, JSON, XLSX, Parquet, ZIP, etc.) with extensions and descriptions. |
| REF_Interface | Interface types used to deliver files (API, FTP, SFTP, S3, Email, Table, File Share, etc.). |
| REF_Interval | Feed-delivery intervals (Minute, Hour, Day, Week, Month, Year, Immediately) with SLA format rules. |
| REF_Status | All statuses an Issue or Distribution can pass through (Prepared, Staging, Loaded, Complete, Failed, Archived, etc.). |
| REF_Storage_Method | How data is stored at rest: Transaction or Snapshot. |
| REF_Transfer_Method | How data is transferred: Delta (changes only) or Snapshot (full entity). |
| REF_Trigger_Type | What initiates a publication run: Scheduled, S3 File Put, or Unknown. |
| REF_Method | Deprecated. Previously listed processing methods (Snapshot, Delta, Transaction). |

### Audit table

| Table | Purpose |
|-------|---------|
| STEP_LOG | Logs individual steps within an ETL process. Captures step name, start/end times, status, record counts, and a description. Written by the `StepLogger` Python class. |

---

## Views

| View | Purpose |
|------|---------|
| PUBLICATION_LIST | Joins Publisher, Publication, Issue, Subscription, and REF_Interval to surface the latest successful issue (high-water mark) for each active publication. Used by pipeline scheduling logic to determine what needs to run and when. |

---

## Stored Procedures

| Procedure | Purpose |
|-----------|---------|
| USP_INSERT_NEW_ISSUE | Inserts a new Issue row into the pub/sub workflow. Legacy helper; the Python layer (`data_hub_connection.insert_new_issue`) now handles this directly using `SEQ_ISSUE_ID.NEXTVAL`. |
| USP_INSERT_NEW_PUBLISHER | Inserts a new Publisher/vendor record. Partially implemented. |

---

## Domain Data

| Script | Purpose |
|--------|---------|
| Domain/ctlDomainData.sql | Populates all reference tables with seed values (REF_Trigger_Type, REF_File_Format, REF_Transfer_Method, REF_Storage_Method, REF_Method, REF_Interval, REF_Interface, REF_Status). Run once per environment after schema creation. |

---

## Test / Utility Scripts

| Script | Purpose |
|--------|---------|
| Test/tst_DataHub.sql | End-to-end test suite. Creates test publishers, subscribers, publications, subscriptions, and issues; exercises the full status-progression lifecycle. |
| Test/tst_StepLogging.sql | Demonstrates the step-logging pattern with error handling. Used as a reference template for ETL procedures. |
| Test/tst_RemoveAllDataHubObjects.sql | Drops all DATA_HUB objects (schemas, tables, views, procedures, sequences). Use to fully reset an environment. |

---

## Migration Scripts (`database_change/`)

Versioned scripts applied by `schemachange` via the `schema_change_pipeline.py` wrapper script. Each filename follows the pattern `V{n}__{ticket}--{description}.sql`.

### Applying a migration outside the pipeline

There is no local CLI shortcut. To apply a script manually, execute it directly against the target environment in a Snowflake worksheet or SnowSQL — the same SQL runs whether applied by the pipeline or by hand.

> schemachange tracks applied versions in `DATA_HUB.SCHEMACHANGE_HISTORY`. A script whose version already appears there will not be re-executed by the pipeline.

### Authoring rules

- schemachange splits files on `;` — do **not** use bare `BEGIN...END` blocks or anonymous scripting blocks with internal semicolons.
- Wrap multi-statement logic in a **JavaScript stored procedure** (no internal `;` required in JS) and `DROP` it immediately after the `CALL`. See `V11` for a working example.
- `ALTER TABLE ... ALTER COLUMN ... SET DEFAULT` is unsupported in Snowflake. Use explicit sequence reads in application code instead.

### Version history

| Version | Description |
|---------|-------------|
| V5 | EIMARC-5490 — AUTOINCREMENT ORDER on sequence columns. |
| V6 | EIMARC-5490 — Ownership correction. |
| V9 | EIMARC-6701 — STEP_LOG table and sequence for StepLogger. |
| V10 | EIMARC-6701 — STEP_LOG Step_Desc column changed to VARIANT. |
| V11 | EIMARC-7266 — Creates `DATA_HUB.SEQ_ISSUE_ID` seeded from `MAX(IssueId) + 1000`. Implemented as a JavaScript stored procedure (self-drops after execution) to avoid schemachange semicolon-splitting errors. |

---

## Design Notes

- **Pub/Sub architecture**: Publishers produce Publications; Subscribers consume them via Subscriptions; each load attempt is an Issue with a child Distribution per Subscriber.
- **Status workflow**: Issues and Distributions progress through a defined status chain (e.g., `IF` → `IS` → `IL` → `IC`). Only statuses `IL`, `IC`, and `IA` count as successful for high-water-mark queries.
- **Environment templating**: Some DDL uses `@ENV@` placeholders replaced at deploy time for multi-environment promotion.
- **Sequence vs AUTOINCREMENT**: Existing environments use `SEQ_ISSUE_ID` (V11 migration) so Python can fetch the next ID before inserting. Greenfield environments use `AUTOINCREMENT` on the column; the sequence is created separately and Python always reads `NEXTVAL` explicitly.
