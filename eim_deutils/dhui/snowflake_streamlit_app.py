"""
DataHub Management System - Snowflake Native Version

This version is optimized for deployment in Snowflake's native Streamlit environment.
It uses Snowflake's native authentication and Snowpark for better integration.

Author: Assistant (Claude)
Date: 2025-01-27
"""

import streamlit as st
import pandas as pd
from snowflake.snowpark import Session
import logging
import os
import sys
import zipfile
from datetime import datetime
from typing import Dict, List, Optional, Any
import uuid

# Import StepLoggerSnowflake from stage
from snowflake.snowpark import Session as SnowparkSession

# Get current session and download from stage
session = SnowparkSession.builder.getOrCreate()
session.file.get(
    "@ULTRA_DEV_RAW.DATA_HUB.EIM_LIBS_DEV/eimutils_snowflake-1.0.0-py3-none-any.whl",
    "/tmp/"
)

# Extract the wheel (a zip archive) so Python can import from it
_whl_path = '/tmp/eimutils_snowflake-1.0.0-py3-none-any.whl'
if os.path.exists(_whl_path):
    with zipfile.ZipFile(_whl_path, 'r') as _z:
        _z.extractall('/tmp/')
if '/tmp/' not in sys.path:
    sys.path.insert(0, '/tmp/')

from eimutils_snowflake.step_logger_snowflake import StepLoggerSnowflake  # noqa: E402

STEP_LOGGER_AVAILABLE = True
IMPORT_METHOD = "stage_download"

# Configure OpenTelemetry to prevent injection errors
os.environ.setdefault("OTEL_SDK_DISABLED", "true")
os.environ.setdefault("SNOWFLAKE_OTEL_DISABLED", "true")

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def log_ui_operation(
    table_name: str,
    operation: str,
    record_id: str = None,
    update_data: Dict[str, Any] = None,
    success: bool = True,
    error_message: str = None
) -> bool:
    """
    Log UI operations using StepLoggerSnowflake.

    Args:
        table_name (str): Name of the table
        operation (str): Type of operation (UPDATE, INSERT, DELETE)
        record_id (str): ID of the record being modified
        update_data (Dict[str, Any]): Data being updated
        success (bool): Whether the operation was successful
        error_message (str): Error message if operation failed

    Returns:
        bool: True if logging was successful, False otherwise
    """
    if not STEP_LOGGER_AVAILABLE:
        return False

    try:
        from snowflake.snowpark.context import get_active_session
        session = get_active_session()

        step_logger = StepLoggerSnowflake(
            session=session,
            etl_execution_id=str(uuid.uuid4()),
            process_name=f"UI_{operation}_{table_name}",
            process_description="Streamlit UI operation",
            process_type="UI_OPERATIONS"
        )

        step_name = f"{operation}_{table_name}"
        custom_attrs = {
            "TableName": table_name,
            "Operation": operation,
            "RecordId": record_id or "unknown",
            "UpdateData": update_data or {},
            "Timestamp": datetime.now().isoformat(),
        }

        if error_message:
            custom_attrs["ErrorMessage"] = error_message

        step_logger.start_step(
            step_name=step_name,
            operation=operation,
            custom_attributes=custom_attrs
        )

        status = "SUCCESS" if success else "FAILED"
        description = f"{operation} operation on {table_name}"
        if record_id:
            description += f" for record {record_id}"
        if error_message:
            description += f" - Error: {error_message}"

        step_logger.log_step(
            status=status,
            description=description,
            db_name="DATA_HUB",
            record_count=1 if success else 0,
            custom_attributes=custom_attrs
        )

        step_logger.close()
        return True

    except Exception as e:
        logger.error(f"Error logging UI operation: {e}")
        return False


def normalize_column_name(col_name: str) -> str:
    """Normalize a single column name to match the pattern used in normalize_column_names"""
    # Convert to title case and handle common patterns
    normalized = col_name.title()

    # Handle specific patterns
    if col_name.upper() == "PUBLISHERID":
        normalized = "PublisherId"
    elif col_name.upper() == "CONTACTID":
        normalized = "ContactId"
    elif col_name.upper() == "PUBLISHERCODE":
        normalized = "PublisherCode"
    elif col_name.upper() == "PUBLISHERNAME":
        normalized = "PublisherName"
    elif col_name.upper() == "PUBLISHERDESC":
        normalized = "PublisherDesc"
    elif col_name.upper() == "INTERFACECODE":
        normalized = "InterfaceCode"
    elif col_name.upper() == "SECRETKEY":
        normalized = "SecretKey"
    elif col_name.upper() == "PUBLICATIONID":
        normalized = "PublicationId"
    elif col_name.upper() == "PUBLICATIONCODE":
        normalized = "PublicationCode"
    elif col_name.upper() == "PUBLICATIONNAME":
        normalized = "PublicationName"
    elif col_name.upper() == "PUBLICATIONDESC":
        normalized = "PublicationDesc"
    elif col_name.upper() == "SUBSCRIBERID":
        normalized = "SubscriberId"
    elif col_name.upper() == "SUBSCRIBERCODE":
        normalized = "SubscriberCode"
    elif col_name.upper() == "SUBSCRIBERNAME":
        normalized = "SubscriberName"
    elif col_name.upper() == "SUBSCRIBERDESC":
        normalized = "SubscriberDesc"
    elif col_name.upper() == "SUBSCRIPTIONID":
        normalized = "SubscriptionId"
    elif col_name.upper() == "SUBSCRIPTIONCODE":
        normalized = "SubscriptionCode"
    elif col_name.upper() == "ISSUEID":
        normalized = "IssueId"
    elif col_name.upper() == "ISSUENAME":
        normalized = "IssueName"
    elif col_name.upper() == "STATUSCODE":
        normalized = "StatusCode"
    elif col_name.upper() == "REPORTDATE":
        normalized = "ReportDate"
    elif col_name.upper() == "DATALAKEPATH":
        normalized = "DataLakePath"
    elif col_name.upper() == "RECORDCOUNT":
        normalized = "RecordCount"
    elif col_name.upper() == "CREATEDBY":
        normalized = "CreatedBy"
    elif col_name.upper() == "CREATEDDTM":
        normalized = "CreatedDtm"
    elif col_name.upper() == "MODIFIEDBY":
        normalized = "ModifiedBy"
    elif col_name.upper() == "MODIFIEDDTM":
        normalized = "ModifiedDtm"
    # Issue table specific columns
    elif col_name.upper() == "SRCDFPUBLISHERID":
        normalized = "SrcDFPublisherId"
    elif col_name.upper() == "SRCDFPUBLICATIONID":
        normalized = "SrcDFPublicationId"
    elif col_name.upper() == "SRCDFISSUEID":
        normalized = "SrcDFIssueId"
    elif col_name.upper() == "SRCISSUENAME":
        normalized = "SrcIssueName"
    elif col_name.upper() == "SRCDFCREATEDDATE":
        normalized = "SrcDFCreatedDate"
    elif col_name.upper() == "PUBLICATIONSEQ":
        normalized = "PublicationSeq"
    elif col_name.upper() == "DAILYPUBLICATIONSEQ":
        normalized = "DailyPublicationSeq"
    elif col_name.upper() == "FIRSTRECORDSEQ":
        normalized = "FirstRecordSeq"
    elif col_name.upper() == "LASTRECORDSEQ":
        normalized = "LastRecordSeq"
    elif col_name.upper() == "FIRSTRECORDCHECKSUM":
        normalized = "FirstRecordChecksum"
    elif col_name.upper() == "LASTRECORDCHECKSUM":
        normalized = "LastRecordChecksum"
    elif col_name.upper() == "PERIODSTARTTIME":
        normalized = "PeriodStartTime"
    elif col_name.upper() == "PERIODENDTIME":
        normalized = "PeriodEndTime"
    elif col_name.upper() == "PERIODSTARTTIMEUTC":
        normalized = "PeriodStartTimeUTC"
    elif col_name.upper() == "PERIODENDTIMEUTC":
        normalized = "PeriodEndTimeUTC"
    elif col_name.upper() == "ISSUECONSUMEDDATE":
        normalized = "IssueConsumedDate"
    elif col_name.upper() == "RETRYCOUNT":
        normalized = "RetryCount"
    elif col_name.upper() == "ETLEXECUTIONID":
        normalized = "ETLExecutionId"
    else:
        # For any other columns, use title case
        normalized = col_name.title()

    return normalized


def normalize_column_names(df: pd.DataFrame) -> pd.DataFrame:
    """
    Normalize column names to handle Snowflake case sensitivity.
    Converts column names to proper case format.
    """
    if df.empty:
        return df

    # Create a mapping for common column name patterns
    column_mapping = {}
    for col in df.columns:
        # Convert to title case and handle common patterns
        normalized = col.title()

        # Handle specific patterns
        if col.upper() == "PUBLISHERID":
            normalized = "PublisherId"
        elif col.upper() == "CONTACTID":
            normalized = "ContactId"
        elif col.upper() == "PUBLISHERCODE":
            normalized = "PublisherCode"
        elif col.upper() == "PUBLISHERNAME":
            normalized = "PublisherName"
        elif col.upper() == "PUBLISHERDESC":
            normalized = "PublisherDesc"
        elif col.upper() == "INTERFACECODE":
            normalized = "InterfaceCode"
        elif col.upper() == "SECRETKEY":
            normalized = "SecretKey"
        elif col.upper() == "PUBLICATIONID":
            normalized = "PublicationId"
        elif col.upper() == "PUBLICATIONCODE":
            normalized = "PublicationCode"
        elif col.upper() == "PUBLICATIONNAME":
            normalized = "PublicationName"
        elif col.upper() == "PUBLICATIONDESC":
            normalized = "PublicationDesc"
        elif col.upper() == "SUBSCRIBERID":
            normalized = "SubscriberId"
        elif col.upper() == "SUBSCRIBERCODE":
            normalized = "SubscriberCode"
        elif col.upper() == "SUBSCRIBERNAME":
            normalized = "SubscriberName"
        elif col.upper() == "SUBSCRIBERDESC":
            normalized = "SubscriberDesc"
        elif col.upper() == "SUBSCRIPTIONID":
            normalized = "SubscriptionId"
        elif col.upper() == "SUBSCRIPTIONCODE":
            normalized = "SubscriptionCode"
        elif col.upper() == "ISSUEID":
            normalized = "IssueId"
        elif col.upper() == "ISSUENAME":
            normalized = "IssueName"
        elif col.upper() == "STATUSCODE":
            normalized = "StatusCode"
        elif col.upper() == "REPORTDATE":
            normalized = "ReportDate"
        elif col.upper() == "DATALAKEPATH":
            normalized = "DataLakePath"
        elif col.upper() == "RECORDCOUNT":
            normalized = "RecordCount"
        elif col.upper() == "CREATEDBY":
            normalized = "CreatedBy"
        elif col.upper() == "CREATEDDTM":
            normalized = "CreatedDtm"
        elif col.upper() == "MODIFIEDBY":
            normalized = "ModifiedBy"
        elif col.upper() == "MODIFIEDDTM":
            normalized = "ModifiedDtm"

        column_mapping[col] = normalized

    return df.rename(columns=column_mapping)


def get_table_schema(crud: "SnowflakeDataHubCRUD", table_name: str) -> List[str]:
    """
    Get the column names for a specific table with caching.
    """
    try:
        # Query to get column information
        query = f"""
        SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = 'DATA_HUB'
        AND TABLE_NAME = '{table_name.upper()}'
        ORDER BY ORDINAL_POSITION
        """
        df = crud.execute_query(query)
        return df["Column_Name"].tolist() if not df.empty else []
    except Exception as e:
        logger.error(f"Failed to get schema for {table_name}: {str(e)}")
        return []


@st.cache_data(ttl=600)  # Cache for 10 minutes (schema doesn't change often)
def get_table_columns(_crud: "SnowflakeDataHubCRUD", table_name: str) -> List[Dict]:
    """
    Get detailed column information for a specific table.
    Returns list of column info including name, data type, nullable, etc.
    """
    try:
        query = f"""
        SELECT
            COLUMN_NAME,
            DATA_TYPE,
            IS_NULLABLE,
            COLUMN_DEFAULT,
            ORDINAL_POSITION
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = 'DATA_HUB'
        AND TABLE_NAME = '{table_name.upper()}'
        ORDER BY ORDINAL_POSITION
        """
        df = _crud.execute_query(query)
        return df.to_dict("records") if not df.empty else []
    except Exception as e:
        logger.error(f"Failed to get columns for {table_name}: {str(e)}")
        return []


@st.cache_data(ttl=600)  # Cache for 10 minutes (schema doesn't change often)
def get_primary_key_columns(
    _crud: "SnowflakeDataHubCRUD", table_name: str
) -> List[str]:
    """
    Get primary key column names for a specific table.
    Uses SHOW PRIMARY KEYS which works in Snowflake.
    """
    try:
        query = f"SHOW PRIMARY KEYS IN TABLE DATA_HUB.{table_name.upper()}"
        df = _crud.execute_query(query)
        if not df.empty and "column_name" in df.columns:
            return df["column_name"].tolist()
        else:
            # Fallback: assume common primary key patterns
            common_pks = {
                "PUBLISHER": ["PublisherCode"],
                "PUBLICATION": ["PublicationCode"],
                "SUBSCRIBER": ["SubscriberCode"],
                "SUBSCRIPTION": ["SubscriptionCode"],
                "ISSUE": ["IssueId"],
                "REF_STATUS": ["StatusCode"],
                "REF_INTERFACE": ["InterfaceCode"],
                "REF_FILE_FORMAT": ["FileFormatCode"],
            }
            return common_pks.get(table_name.upper(), [])
    except Exception as e:
        logger.error(f"Failed to get primary key for {table_name}: {str(e)}")
        # Fallback: assume common primary key patterns
        common_pks = {
            "PUBLISHER": ["PublisherCode"],
            "PUBLICATION": ["PublicationCode"],
            "SUBSCRIBER": ["SubscriberCode"],
            "SUBSCRIPTION": ["SubscriptionCode"],
            "ISSUE": ["IssueId"],
            "REF_STATUS": ["StatusCode"],
            "REF_INTERFACE": ["InterfaceCode"],
            "REF_FILE_FORMAT": ["FileFormatCode"],
        }
        return common_pks.get(table_name.upper(), [])


def render_dynamic_update_form(
    _crud: "SnowflakeDataHubCRUD",
    table_name: str,
    record_data: Dict,
    primary_key: str,
    primary_key_value: str,
    update_function,
):
    """
    Render a dynamic update form based on table schema.
    Shows all updatable columns with appropriate input types.
    """
    # Get table schema
    columns = get_table_columns(_crud, table_name)
    primary_keys = get_primary_key_columns(_crud, table_name)

    if not columns:
        st.error(f"Could not retrieve schema for table {table_name}")
        return

    # Fetch current record data to ensure we have all current values
    try:
        current_record_query = f"SELECT * FROM DATA_HUB.{table_name.upper()} WHERE {primary_key} = :primary_key_value"
        logger.info(
            f"Executing query: {current_record_query} with value: {primary_key_value}"
        )
        current_df = _crud.execute_query(
            current_record_query, {"primary_key_value": primary_key_value}
        )
        logger.info(
            f"Query result: {current_df.shape[0]} rows, columns: {list(current_df.columns)}"
        )

        if not current_df.empty:
            current_record = current_df.iloc[0].to_dict()
            logger.info(f"Current record data: {current_record}")
            # Update record_data with current values
            record_data.update(current_record)
            logger.info(f"Updated record_data keys: {list(record_data.keys())}")
        else:
            logger.warning(f"No record found for {primary_key}={primary_key_value}")
            st.error(
                f"No record found in database for {primary_key}={primary_key_value}"
            )
    except Exception as e:
        logger.error(f"Could not fetch current record data: {str(e)}")
        st.error(f"Database error: {str(e)}")
        # Continue with existing record_data

    # Filter out non-editable columns
    editable_columns = [
        col
        for col in columns
        if col["Column_Name"].upper()
        not in ["CREATEDBY", "CREATEDDTM", "MODIFIEDBY", "MODIFIEDDTM"]
        and col["Column_Name"] not in primary_keys
    ]

    if not editable_columns:
        st.warning("No editable fields found for this record.")
        return

    # Display current record details for context
    st.subheader(f"Update {table_name.title()}")
    st.info(f"**Selected {primary_key}**: {primary_key_value}")

    # Skip the grid display and go straight to the form

    with st.form(f"update_{table_name.lower()}_form"):

        form_data = {}
        col1, col2 = st.columns(2)

        for i, col_info in enumerate(editable_columns):
            col_name = col_info["Column_Name"]
            data_type = col_info["Data_Type"].upper()

            # Try to get current value with normalized column name
            normalized_col_name = normalize_column_name(col_name)
            _missing = object()
            for _key in (normalized_col_name, col_name, col_name.upper(), col_name.lower()):
                current_value = record_data.get(_key, _missing)
                if current_value is not _missing:
                    break
            else:
                current_value = ""

            # Debug logging
            logger.info(
                f"Form field {col_name}: current_value='{current_value}', available_keys={list(record_data.keys())}"
            )

            # Determine input type based on column name and data type
            with col1 if i % 2 == 0 else col2:
                if col_name.upper().endswith("CODE") and col_name.upper() in [
                    "PUBLISHERCODE",
                    "PUBLICATIONCODE",
                    "SUBSCRIBERCODE",
                    "SUBSCRIPTIONCODE",
                    "INTERFACECODE",
                    "STATUSCODE",
                    "FILEFORMATCODE",
                ]:
                    # Handle foreign key fields with dropdowns
                    if col_name.upper() == "PUBLISHERCODE":
                        publishers = _crud.get_publishers()
                        options = {
                            p["PublisherCode"]: p["PublisherCode"] for p in publishers
                        }
                        if options:
                            selected = st.selectbox(
                                col_name.replace("Code", " Code"),
                                list(options.keys()),
                                index=(
                                    list(options.values()).index(current_value)
                                    if current_value in options.values()
                                    else 0
                                ),
                                help=f"Select the {col_name.lower()}",
                                key=f"update_{normalized_col_name}",
                            )
                            form_data[normalized_col_name] = options[selected]
                        else:
                            value = st.text_input(
                                col_name.replace("Code", " Code"),
                                value=current_value,
                                help=f"Enter the {col_name.lower()}",
                                key=f"update_{normalized_col_name}",
                            )
                            form_data[normalized_col_name] = value
                    elif col_name.upper() == "PUBLICATIONCODE":
                        publications = _crud.get_publications()
                        options = {
                            p["PublicationCode"]: p["PublicationCode"]
                            for p in publications
                        }
                        if options:
                            selected = st.selectbox(
                                col_name.replace("Code", " Code"),
                                list(options.keys()),
                                index=(
                                    list(options.values()).index(current_value)
                                    if current_value in options.values()
                                    else 0
                                ),
                                help=f"Select the {col_name.lower()}",
                            )
                            form_data[normalized_col_name] = options[selected]
                        else:
                            form_data[normalized_col_name] = st.text_input(
                                col_name.replace("Code", " Code"),
                                value=current_value,
                                help=f"Enter the {col_name.lower()}",
                                key=f"update_{normalized_col_name}",
                            )
                    elif col_name.upper() == "SUBSCRIBERCODE":
                        subscribers = _crud.get_subscribers()
                        options = {
                            p["SubscriberCode"]: p["SubscriberCode"]
                            for p in subscribers
                        }
                        if options:
                            selected = st.selectbox(
                                col_name.replace("Code", " Code"),
                                list(options.keys()),
                                index=(
                                    list(options.values()).index(current_value)
                                    if current_value in options.values()
                                    else 0
                                ),
                                help=f"Select the {col_name.lower()}",
                            )
                            form_data[normalized_col_name] = options[selected]
                        else:
                            form_data[normalized_col_name] = st.text_input(
                                col_name.replace("Code", " Code"),
                                value=current_value,
                                help=f"Enter the {col_name.lower()}",
                                key=f"update_{normalized_col_name}",
                            )
                    elif col_name.upper() == "STATUSCODE":
                        _statuses = _crud.get_ref_statuses()
                        status_options = (
                            [s["StatusCode"] for s in _statuses]
                            if _statuses
                            else ["ACTIVE", "INACTIVE", "PENDING", "RESOLVED"]
                        )
                        current_index = (
                            status_options.index(current_value)
                            if current_value in status_options
                            else 0
                        )
                        form_data[normalized_col_name] = st.selectbox(
                            col_name.replace("Code", " Code"),
                            status_options,
                            index=current_index,
                            help=f"Select the {col_name.lower()}",
                            key=f"update_{normalized_col_name}",
                        )
                    else:
                        # Default text input for other codes
                        form_data[normalized_col_name] = st.text_input(
                            col_name.replace("Code", " Code"),
                            value=current_value,
                            help=f"Enter the {col_name.lower()}",
                        )
                elif col_name.upper().endswith("NAME"):
                    # Name fields
                    form_data[normalized_col_name] = st.text_input(
                        col_name.replace("Name", " Name"),
                        value=current_value,
                        help=f"Enter the {col_name.lower()}",
                        key=f"update_{normalized_col_name}",
                    )
                elif col_name.upper().endswith("DESC"):
                    # Description fields
                    form_data[normalized_col_name] = st.text_area(
                        col_name.replace("Desc", " Description"),
                        value=current_value,
                        help=f"Enter the {col_name.lower()}",
                        key=f"update_{normalized_col_name}",
                    )
                elif col_name.upper() in ["REPORTDATE", "CREATEDDTM", "MODIFIEDDTM"]:
                    # Date fields
                    try:
                        if current_value:
                            date_value = datetime.strptime(
                                str(current_value), "%Y-%m-%d"
                            ).date()
                        else:
                            date_value = datetime.now().date()
                    except Exception:
                        date_value = datetime.now().date()

                    form_data[normalized_col_name] = st.date_input(
                        col_name.replace("Dtm", " Date").replace("Date", " Date"),
                        value=date_value,
                        help=f"Select the {col_name.lower()}",
                        key=f"update_{normalized_col_name}",
                    )
                elif (
                    col_name.upper() in ["RECORDCOUNT"]
                    or "INT" in data_type
                    or "NUMBER" in data_type
                ):
                    # Numeric fields
                    try:
                        numeric_value = int(current_value) if current_value else 0
                    except (ValueError, TypeError):
                        numeric_value = 0

                    form_data[normalized_col_name] = st.number_input(
                        col_name.replace("Count", " Count"),
                        value=numeric_value,
                        help=f"Enter the {col_name.lower()}",
                        key=f"update_{normalized_col_name}",
                    )
                elif col_name.upper() in [
                    "DATALAKEPATH",
                    "FILEEXTENSION",
                    "DOTFILEEXTENSION",
                ]:
                    # Path/extension fields
                    form_data[normalized_col_name] = st.text_input(
                        col_name,
                        value=current_value,
                        help=f"Enter the {col_name.lower()}",
                        key=f"update_{normalized_col_name}",
                    )
                else:
                    # Default text input
                    form_data[normalized_col_name] = st.text_input(
                        col_name,
                        value=current_value,
                        help=f"Enter the {col_name.lower()}",
                        key=f"update_{normalized_col_name}",
                    )

        submitted = st.form_submit_button(
            f"Update {table_name.title()}", type="primary"
        )

        if submitted:

            # Convert date fields to string format
            for col_name, value in form_data.items():
                if col_name.upper() in [
                    "REPORTDATE",
                    "CREATEDDTM",
                    "MODIFIEDDTM",
                ] and hasattr(value, "strftime"):
                    form_data[col_name] = value.strftime("%Y-%m-%d")

            # Debug logging
            logger.info(f"Form data being submitted: {form_data}")
            logger.info(f"Primary key value: {primary_key_value}")

            if update_function(primary_key_value, form_data):
                st.success(f"[SUCCESS] {table_name.title()} updated successfully!")
                st.rerun()
            else:
                st.error(f"[ERROR] Failed to update {table_name.lower()}")


def render_simple_update_form(
    crud: "SnowflakeDataHubCRUD",
    table_name: str,
    record_data: Dict,
    primary_key: str,
    primary_key_value: str,
    update_function,
):
    """
    Render a simplified update form for better performance.
    """
    with st.form(f"update_{table_name.lower()}_form"):
        st.subheader(f"Update {table_name.title()}")

        # Create form fields based on common patterns
        form_data = {}
        col1, col2 = st.columns(2)

        # Handle common fields
        with col1:
            if "Name" in str(record_data.keys()):
                name_field = next((k for k in record_data.keys() if "Name" in k), None)
                if name_field:
                    form_data[name_field] = st.text_input(
                        name_field.replace("Code", "").replace("Name", " Name"),
                        value=record_data.get(name_field, ""),
                        help=f"Enter the {name_field.lower()}",
                    )

            if "Code" in str(record_data.keys()) and primary_key not in str(
                record_data.keys()
            ):
                code_field = next(
                    (k for k in record_data.keys() if "Code" in k and k != primary_key),
                    None,
                )
                if code_field:
                    form_data[code_field] = st.text_input(
                        code_field.replace("Code", " Code"),
                        value=record_data.get(code_field, ""),
                        help=f"Enter the {code_field.lower()}",
                    )

        with col2:
            # Handle other common fields
            for key, value in record_data.items():
                if (
                    key not in form_data
                    and key != primary_key
                    and "Created" not in key
                    and "Modified" not in key
                ):
                    if isinstance(value, (int, float)):
                        form_data[key] = st.number_input(
                            key,
                            value=int(value) if value else 0,
                            help=f"Enter the {key.lower()}",
                        )
                    else:
                        form_data[key] = st.text_input(
                            key,
                            value=str(value) if value else "",
                            help=f"Enter the {key.lower()}",
                        )

        submitted = st.form_submit_button(
            f"Update {table_name.title()}", type="primary"
        )

        if submitted:
            if update_function(primary_key_value, form_data):
                st.success(f"[SUCCESS] {table_name.title()} updated successfully!")
                st.rerun()
            else:
                st.error(f"[ERROR] Failed to update {table_name.lower()}")


# Page configuration
st.set_page_config(
    page_title="DataHub Management System",
    page_icon=":office:",
    layout="wide",
    initial_sidebar_state="expanded",
)


@st.cache_resource
def get_snowflake_session():
    """
    Get Snowflake session using native authentication.
    When running in Snowflake's native environment, use the built-in session.
    """
    try:
        # When running natively in Snowflake, use the built-in session
        # This automatically uses the current user's authentication
        session = Session.builder.getOrCreate()

        logger.info("Successfully connected to Snowflake using native session")
        return session
    except Exception as e:
        logger.error(f"Failed to connect to Snowflake: {str(e)}")
        st.error(f"[ERROR] Connection failed: {str(e)}")
        return None


class SnowflakeDataHubCRUD:
    """
    Snowflake-native CRUD operations using Snowpark.
    This replaces the original DataHubCRUD for Snowflake deployment.
    """

    def __init__(self, session: Session):
        self.session = session

    def execute_query(self, query: str, params: Optional[Dict] = None) -> pd.DataFrame:
        """
        Execute a SELECT query using Snowpark and return results as DataFrame.

        Args:
            query: SQL SELECT query
            params: Query parameters (dict or None)

        Returns:
            pandas DataFrame with query results
        """
        try:
            if params:
                # Replace named parameters with positional parameters
                param_list = []
                for key, value in params.items():
                    query = query.replace(f":{key}", "?")
                    param_list.append(value)
                df = self.session.sql(query, param_list).to_pandas()
            else:
                df = self.session.sql(query).to_pandas()

            # Normalize column names to handle Snowflake case sensitivity
            df = normalize_column_names(df)

            logger.info(f"Query executed successfully: {query[:100]}...")
            return df
        except Exception as e:
            logger.error(f"Query execution failed: {str(e)}")
            st.error(f"[ERROR] Query failed: {str(e)}")
            return pd.DataFrame()

    def execute_command(self, query: str, params: Optional[Dict] = None) -> int:
        """
        Execute an INSERT/UPDATE/DELETE command using Snowpark.

        Args:
            query: SQL command (INSERT/UPDATE/DELETE)
            params: Query parameters (dict or None)

        Returns:
            Number of affected rows
        """
        try:

            if params:
                # Replace named parameters with positional parameters using regex for precision
                import re

                param_list = []

                # Extract parameter names from the query in the order they appear
                param_pattern = r":(\w+)"
                param_names_in_order = re.findall(param_pattern, query)

                # Build param_list in the exact order they appear in the query
                for param_name in param_names_in_order:
                    if param_name in params:
                        value = params[param_name]
                        # Convert Python None to SQL NULL (None)
                        if value is None:
                            param_list.append(None)
                        else:
                            param_list.append(value)
                    else:
                        # If parameter not found, add None
                        param_list.append(None)

                # Replace parameters in the query
                query = re.sub(r":\w+", "?", query)
                result = self.session.sql(query, param_list).collect()
            else:
                result = self.session.sql(query).collect()

            logger.info(f"Command executed successfully: {query[:100]}...")
            return len(result)
        except Exception as e:
            logger.error(f"Command execution failed: {str(e)}")
            st.error(f"[ERROR] Command failed: {str(e)}")
            return 0

    @st.cache_data(ttl=300)  # Cache for 5 minutes
    def get_publishers(_self) -> List[Dict]:
        """Get all publishers using Snowpark with caching."""
        try:
            df = _self.execute_query(
                "SELECT * FROM DATA_HUB.Publisher ORDER BY PublisherCode"
            )
            return df.to_dict("records")
        except Exception as e:
            logger.error(f"Failed to get publishers: {str(e)}")
            return []

    @st.cache_data(ttl=300)  # Cache for 5 minutes
    def get_subscribers(_self) -> List[Dict]:
        """Get all subscribers using Snowpark with caching."""
        try:
            df = _self.execute_query(
                "SELECT * FROM DATA_HUB.Subscriber ORDER BY SubscriberCode"
            )
            return df.to_dict("records")
        except Exception as e:
            logger.error(f"Failed to get subscribers: {str(e)}")
            return []

    @st.cache_data(ttl=300)  # Cache for 5 minutes
    def get_publications(_self) -> List[Dict]:
        """Get all publications using Snowpark with caching."""
        try:
            df = _self.execute_query(
                "SELECT * FROM DATA_HUB.Publication ORDER BY PublicationCode"
            )
            return df.to_dict("records")
        except Exception as e:
            logger.error(f"Failed to get publications: {str(e)}")
            return []

    def create_publisher(self, data: Dict) -> bool:
        """Create a new publisher."""
        try:
            query = """
            INSERT INTO DATA_HUB.Publisher
            (PublisherCode, PublisherName, InterfaceCode, CreatedBy, CreatedDtm, ModifiedBy, ModifiedDtm)
            VALUES (:PublisherCode, :PublisherName, :InterfaceCode, :CreatedBy, :CreatedDtm, :ModifiedBy, :ModifiedDtm)
            """

            # Add audit fields
            data["CreatedBy"] = st.session_state.get("user", "streamlit_user")
            data["CreatedDtm"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            data["ModifiedBy"] = st.session_state.get("user", "streamlit_user")
            data["ModifiedDtm"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            rows_affected = self.execute_command(query, data)
            if rows_affected > 0:
                # Clear cache after successful creation
                st.cache_data.clear()
            return rows_affected > 0
        except Exception as e:
            logger.error(f"Failed to create publisher: {str(e)}")
            return False

    def update_publisher(self, publisher_code: str, data: Dict) -> bool:
        """Update an existing publisher."""
        try:
            logger.info(
                f"update_publisher called with publisher_code: {publisher_code}"
            )
            logger.info(f"update_publisher data: {data}")

            # Build dynamic UPDATE query based on provided data
            set_clauses = []
            params = {}

            # Add fields from form data in the EXACT order they appear in the SQL query
            # Order: PublisherName, PublisherDesc, InterfaceCode, SecretKey, ModifiedBy, ModifiedDtm, PublisherCode

            # First add the form fields (in query order)
            if "PublisherName" in data:
                set_clauses.append("PublisherName = :PublisherName")
                params["PublisherName"] = data["PublisherName"]
            if "PublisherDesc" in data:
                set_clauses.append("PublisherDesc = :PublisherDesc")
                params["PublisherDesc"] = data["PublisherDesc"]
            if "InterfaceCode" in data:
                set_clauses.append("InterfaceCode = :InterfaceCode")
                params["InterfaceCode"] = data["InterfaceCode"]
            if "SecretKey" in data:
                set_clauses.append("SecretKey = :SecretKey")
                params["SecretKey"] = data["SecretKey"]

            # Then add audit fields (in query order)
            set_clauses.append("ModifiedBy = :ModifiedBy")
            params["ModifiedBy"] = st.session_state.get("user", "streamlit_user")

            set_clauses.append("ModifiedDtm = :ModifiedDtm")
            params["ModifiedDtm"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            # Finally add the WHERE clause parameter
            params["PublisherCode"] = publisher_code

            # TEMPORARY: Hardcoded query for testing
            query = """
            UPDATE DATA_HUB.Publisher
            SET PublisherName = :PublisherName,
                PublisherDesc = :PublisherDesc,
                InterfaceCode = :InterfaceCode,
                SecretKey = :SecretKey,
                ModifiedBy = :ModifiedBy,
                ModifiedDtm = :ModifiedDtm
            WHERE PublisherCode = :PublisherCode
            """

            rows_affected = self.execute_command(query, params)
            logger.info(f"Rows affected: {rows_affected}")

            if rows_affected > 0:
                # Clear cache after successful update
                st.cache_data.clear()

                # Log the successful update operation
                if STEP_LOGGER_AVAILABLE:
                    log_ui_operation(
                        table_name="Publisher",
                        operation="UPDATE",
                        record_id=publisher_code,
                        update_data=data,
                        success=True
                    )

                return True
            else:
                # Log the failed update operation
                if STEP_LOGGER_AVAILABLE:
                    log_ui_operation(
                        table_name="Publisher",
                        operation="UPDATE",
                        record_id=publisher_code,
                        update_data=data,
                        success=False,
                        error_message="No rows affected"
                    )
                return False

        except Exception as e:
            logger.error(f"Failed to update publisher: {str(e)}")

            # Log the failed update operation
            if STEP_LOGGER_AVAILABLE:
                log_ui_operation(
                    table_name="Publisher",
                    operation="UPDATE",
                    record_id=publisher_code,
                    update_data=data,
                    success=False,
                    error_message=str(e)
                )

            return False

    def delete_publisher(self, publisher_code: str) -> bool:
        """Delete a publisher (with referential integrity check)."""
        try:
            # Check for dependent records
            dependent_query = """
            SELECT COUNT(*) as count FROM DATA_HUB.Publication
            WHERE PublisherCode = :PublisherCode
            """
            dependent_df = self.execute_query(
                dependent_query, {"PublisherCode": publisher_code}
            )

            if not dependent_df.empty and dependent_df.iloc[0]["Count"] > 0:
                st.warning(
                    "[WARNING] Cannot delete publisher with existing publications"
                )
                return False

            query = (
                "DELETE FROM DATA_HUB.Publisher WHERE PublisherCode = :PublisherCode"
            )
            rows_affected = self.execute_command(
                query, {"PublisherCode": publisher_code}
            )
            if rows_affected > 0:
                # Clear cache after successful deletion
                st.cache_data.clear()
            return rows_affected > 0
        except Exception as e:
            logger.error(f"Failed to delete publisher: {str(e)}")
            return False

    def create_publication(self, data: Dict) -> bool:
        """Create a new publication."""
        try:
            query = """
            INSERT INTO DATA_HUB.Publication
            (PublicationCode, PublicationName, PublisherCode, CreatedBy, CreatedDtm, ModifiedBy, ModifiedDtm)
            VALUES (:PublicationCode, :PublicationName, :PublisherCode, :CreatedBy, :CreatedDtm,
                    :ModifiedBy, :ModifiedDtm)
            """

            # Add audit fields
            data["CreatedBy"] = st.session_state.get("user", "streamlit_user")
            data["CreatedDtm"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            data["ModifiedBy"] = st.session_state.get("user", "streamlit_user")
            data["ModifiedDtm"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            rows_affected = self.execute_command(query, data)
            return rows_affected > 0
        except Exception as e:
            logger.error(f"Failed to create publication: {str(e)}")
            return False

    def update_publication(self, publication_code: str, data: Dict) -> bool:
        """Update an existing publication."""
        try:
            logger.info(
                f"update_publication called with publication_code: {publication_code}"
            )
            logger.info(f"update_publication data: {data}")

            # Build dynamic UPDATE query based on provided data
            set_clauses = []
            params = {}

            # Add fields from form data in the EXACT order they appear in the SQL query
            # Order: PublicationName, PublicationDesc, PublisherCode, ModifiedBy, ModifiedDtm, PublicationCode (WHERE)

            # First add the form fields (in query order)
            if "PublicationName" in data:
                set_clauses.append("PublicationName = :PublicationName")
                params["PublicationName"] = data["PublicationName"]
            if "PublicationDesc" in data:
                set_clauses.append("PublicationDesc = :PublicationDesc")
                params["PublicationDesc"] = data["PublicationDesc"]
            if "PublisherCode" in data:
                set_clauses.append("PublisherCode = :PublisherCode")
                params["PublisherCode"] = data["PublisherCode"]

            # Then add audit fields (in query order)
            set_clauses.append("ModifiedBy = :ModifiedBy")
            params["ModifiedBy"] = st.session_state.get("user", "streamlit_user")

            set_clauses.append("ModifiedDtm = :ModifiedDtm")
            params["ModifiedDtm"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            # Finally add the WHERE clause parameter
            params["PublicationCode"] = publication_code

            query = f"""
            UPDATE DATA_HUB.Publication
            SET {', '.join(set_clauses)}
            WHERE PublicationCode = :PublicationCode
            """

            logger.info(f"Generated query: {query}")
            logger.info(f"Query parameters: {params}")

            rows_affected = self.execute_command(query, params)
            logger.info(f"Rows affected: {rows_affected}")

            if rows_affected > 0:
                # Clear cache after successful update
                st.cache_data.clear()

                # Log the successful update operation
                if STEP_LOGGER_AVAILABLE:
                    log_ui_operation(
                        table_name="Publication",
                        operation="UPDATE",
                        record_id=publication_code,
                        update_data=data,
                        success=True
                    )

                return True
            else:
                # Log the failed update operation
                if STEP_LOGGER_AVAILABLE:
                    log_ui_operation(
                        table_name="Publication",
                        operation="UPDATE",
                        record_id=publication_code,
                        update_data=data,
                        success=False,
                        error_message="No rows affected"
                    )
                return False
        except Exception as e:
            logger.error(f"Failed to update publication: {str(e)}")

            # Log the failed update operation
            if STEP_LOGGER_AVAILABLE:
                log_ui_operation(
                    table_name="Publication",
                    operation="UPDATE",
                    record_id=publication_code,
                    update_data=data,
                    success=False,
                    error_message=str(e)
                )

            return False

    def delete_publication(self, publication_code: str) -> bool:
        """Delete a publication."""
        try:
            query = "DELETE FROM DATA_HUB.Publication WHERE PublicationCode = :PublicationCode"
            rows_affected = self.execute_command(
                query, {"PublicationCode": publication_code}
            )
            return rows_affected > 0
        except Exception as e:
            logger.error(f"Failed to delete publication: {str(e)}")
            return False

    def create_subscriber(self, data: Dict) -> bool:
        """Create a new subscriber."""
        try:
            query = """
            INSERT INTO DATA_HUB.Subscriber
            (SubscriberCode, SubscriberName, CreatedBy, CreatedDtm, ModifiedBy, ModifiedDtm)
            VALUES (:SubscriberCode, :SubscriberName, :CreatedBy, :CreatedDtm, :ModifiedBy, :ModifiedDtm)
            """

            # Add audit fields
            data["CreatedBy"] = st.session_state.get("user", "streamlit_user")
            data["CreatedDtm"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            data["ModifiedBy"] = st.session_state.get("user", "streamlit_user")
            data["ModifiedDtm"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            rows_affected = self.execute_command(query, data)
            return rows_affected > 0
        except Exception as e:
            logger.error(f"Failed to create subscriber: {str(e)}")
            return False

    def update_subscriber(self, subscriber_code: str, data: Dict) -> bool:
        """Update an existing subscriber."""
        try:
            logger.info(
                f"update_subscriber called with subscriber_code: {subscriber_code}"
            )
            logger.info(f"update_subscriber data: {data}")

            # Build dynamic UPDATE query based on provided data
            set_clauses = []
            params = {}

            # Add fields from form data in the EXACT order they appear in the SQL query
            # Order: SubscriberName, ModifiedBy, ModifiedDtm, SubscriberCode (WHERE)

            # First add the form fields (in query order)
            if "SubscriberName" in data:
                set_clauses.append("SubscriberName = :SubscriberName")
                params["SubscriberName"] = data["SubscriberName"]

            # Then add audit fields (in query order)
            set_clauses.append("ModifiedBy = :ModifiedBy")
            params["ModifiedBy"] = st.session_state.get("user", "streamlit_user")

            set_clauses.append("ModifiedDtm = :ModifiedDtm")
            params["ModifiedDtm"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            # Finally add the WHERE clause parameter
            params["SubscriberCode"] = subscriber_code

            query = f"""
            UPDATE DATA_HUB.Subscriber
            SET {', '.join(set_clauses)}
            WHERE SubscriberCode = :SubscriberCode
            """

            logger.info(f"Generated query: {query}")
            logger.info(f"Query parameters: {params}")

            rows_affected = self.execute_command(query, params)
            logger.info(f"Rows affected: {rows_affected}")

            if rows_affected > 0:
                # Clear cache after successful update
                st.cache_data.clear()

                # Log the successful update operation
                if STEP_LOGGER_AVAILABLE:
                    log_ui_operation(
                        table_name="Subscriber",
                        operation="UPDATE",
                        record_id=subscriber_code,
                        update_data=data,
                        success=True
                    )

                return True
            else:
                # Log the failed update operation
                if STEP_LOGGER_AVAILABLE:
                    log_ui_operation(
                        table_name="Subscriber",
                        operation="UPDATE",
                        record_id=subscriber_code,
                        update_data=data,
                        success=False,
                        error_message="No rows affected"
                    )
                return False
        except Exception as e:
            logger.error(f"Failed to update subscriber: {str(e)}")

            # Log the failed update operation
            if STEP_LOGGER_AVAILABLE:
                log_ui_operation(
                    table_name="Subscriber",
                    operation="UPDATE",
                    record_id=subscriber_code,
                    update_data=data,
                    success=False,
                    error_message=str(e)
                )

            return False

    def delete_subscriber(self, subscriber_code: str) -> bool:
        """Delete a subscriber."""
        try:
            query = (
                "DELETE FROM DATA_HUB.Subscriber WHERE SubscriberCode = :SubscriberCode"
            )
            rows_affected = self.execute_command(
                query, {"SubscriberCode": subscriber_code}
            )
            return rows_affected > 0
        except Exception as e:
            logger.error(f"Failed to delete subscriber: {str(e)}")
            return False

    @st.cache_data(ttl=300)  # Cache for 5 minutes
    def get_subscriptions(_self) -> List[Dict]:
        """Get all subscriptions using Snowpark with caching."""
        try:
            df = _self.execute_query(
                "SELECT * FROM DATA_HUB.Subscription ORDER BY SubscriptionCode"
            )
            return df.to_dict("records")
        except Exception as e:
            logger.error(f"Failed to get subscriptions: {str(e)}")
            return []

    def create_subscription(self, data: Dict) -> bool:
        """Create a new subscription."""
        try:
            query = """
            INSERT INTO DATA_HUB.Subscription
            (SubscriptionCode, PublicationCode, SubscriberCode, CreatedBy, CreatedDtm)
            VALUES (:SubscriptionCode, :PublicationCode, :SubscriberCode, :CreatedBy, :CreatedDtm)
            """

            # Add audit fields
            data["CreatedBy"] = st.session_state.get("user", "streamlit_user")
            data["CreatedDtm"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            rows_affected = self.execute_command(query, data)
            return rows_affected > 0
        except Exception as e:
            logger.error(f"Failed to create subscription: {str(e)}")
            return False

    def update_subscription(self, subscription_code: str, data: Dict) -> bool:
        """Update an existing subscription."""
        try:
            logger.info(
                f"update_subscription called with subscription_code: {subscription_code}"
            )
            logger.info(f"update_subscription data: {data}")

            # Build dynamic UPDATE query based on provided data
            set_clauses = []
            params = {}

            # Add fields from form data in the EXACT order they appear in the SQL query
            # Order: PublicationCode, SubscriberCode, ModifiedBy, ModifiedDtm, SubscriptionCode (WHERE)

            # First add the form fields (in query order)
            if "PublicationCode" in data:
                set_clauses.append("PublicationCode = :PublicationCode")
                params["PublicationCode"] = data["PublicationCode"]
            if "SubscriberCode" in data:
                set_clauses.append("SubscriberCode = :SubscriberCode")
                params["SubscriberCode"] = data["SubscriberCode"]

            # Then add audit fields (in query order)
            set_clauses.append("ModifiedBy = :ModifiedBy")
            params["ModifiedBy"] = st.session_state.get("user", "streamlit_user")

            set_clauses.append("ModifiedDtm = :ModifiedDtm")
            params["ModifiedDtm"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            # Finally add the WHERE clause parameter
            params["SubscriptionCode"] = subscription_code

            query = f"""
            UPDATE DATA_HUB.Subscription
            SET {', '.join(set_clauses)}
            WHERE SubscriptionCode = :SubscriptionCode
            """

            logger.info(f"Generated query: {query}")
            logger.info(f"Query parameters: {params}")

            rows_affected = self.execute_command(query, params)
            logger.info(f"Rows affected: {rows_affected}")

            if rows_affected > 0:
                # Clear cache after successful update
                st.cache_data.clear()

                # Log the successful update operation
                if STEP_LOGGER_AVAILABLE:
                    log_ui_operation(
                        table_name="Subscription",
                        operation="UPDATE",
                        record_id=subscription_code,
                        update_data=data,
                        success=True
                    )

                return True
            else:
                # Log the failed update operation
                if STEP_LOGGER_AVAILABLE:
                    log_ui_operation(
                        table_name="Subscription",
                        operation="UPDATE",
                        record_id=subscription_code,
                        update_data=data,
                        success=False,
                        error_message="No rows affected"
                    )
                return False
        except Exception as e:
            logger.error(f"Failed to update subscription: {str(e)}")

            # Log the failed update operation
            if STEP_LOGGER_AVAILABLE:
                log_ui_operation(
                    table_name="Subscription",
                    operation="UPDATE",
                    record_id=subscription_code,
                    update_data=data,
                    success=False,
                    error_message=str(e)
                )

            return False

    def delete_subscription(self, subscription_code: str) -> bool:
        """Delete a subscription."""
        try:
            query = "DELETE FROM DATA_HUB.Subscription WHERE SubscriptionCode = :SubscriptionCode"
            rows_affected = self.execute_command(
                query, {"SubscriptionCode": subscription_code}
            )
            return rows_affected > 0
        except Exception as e:
            logger.error(f"Failed to delete subscription: {str(e)}")
            return False

    @st.cache_data(ttl=300)  # Cache for 5 minutes
    def get_issues(_self) -> List[Dict]:
        """Get all issues using Snowpark with caching."""
        try:
            df = _self.execute_query("SELECT * FROM DATA_HUB.Issue ORDER BY IssueName")
            return df.to_dict("records")
        except Exception as e:
            logger.error(f"Failed to get issues: {str(e)}")
            return []

    def create_issue(self, data: Dict) -> bool:
        """Create a new issue."""
        try:
            query = """
            INSERT INTO DATA_HUB.Issue
            (PublicationCode, StatusCode, ReportDate, IssueName, DataLakePath, RecordCount, CreatedBy, CreatedDtm)
            VALUES (:PublicationCode, :StatusCode, :ReportDate, :IssueName, :DataLakePath, :RecordCount,
                    :CreatedBy, :CreatedDtm)
            """

            # Add audit fields
            data["CreatedBy"] = st.session_state.get("user", "streamlit_user")
            data["CreatedDtm"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            rows_affected = self.execute_command(query, data)
            return rows_affected > 0
        except Exception as e:
            logger.error(f"Failed to create issue: {str(e)}")
            return False

    def update_issue(self, issue_id: str, data: Dict) -> bool:
        """Update an existing issue."""
        try:
            logger.info(f"update_issue called with issue_id: {issue_id}")
            logger.info(f"update_issue data: {data}")

            # TEMPORARY: Use hardcoded query to ensure correct parameter order
            query = """
            UPDATE DATA_HUB.Issue
            SET PublicationCode = :PublicationCode,
                StatusCode = :StatusCode,
                ReportDate = :ReportDate,
                SrcDFPublisherId = :SrcDFPublisherId,
                SrcDFPublicationId = :SrcDFPublicationId,
                SrcDFIssueId = :SrcDFIssueId,
                SrcIssueName = :SrcIssueName,
                SrcDFCreatedDate = CASE WHEN :SrcDFCreatedDate = '' THEN NULL ELSE :SrcDFCreatedDate END,
                DataLakePath = :DataLakePath,
                IssueName = :IssueName,
                PublicationSeq = :PublicationSeq,
                DailyPublicationSeq = :DailyPublicationSeq,
                FirstRecordSeq = :FirstRecordSeq,
                LastRecordSeq = :LastRecordSeq,
                FirstRecordChecksum = :FirstRecordChecksum,
                LastRecordChecksum = :LastRecordChecksum,
                PeriodStartTime = CASE WHEN :PeriodStartTime = '' THEN CURRENT_TIMESTAMP() ELSE :PeriodStartTime END,
                PeriodEndTime = CASE WHEN :PeriodEndTime = '' THEN NULL ELSE :PeriodEndTime END,
                PeriodStartTimeUTC = CASE WHEN :PeriodStartTimeUTC = '' THEN NULL ELSE :PeriodStartTimeUTC END,
                PeriodEndTimeUTC = CASE WHEN :PeriodEndTimeUTC = '' THEN NULL ELSE :PeriodEndTimeUTC END,
                IssueConsumedDate = CASE WHEN :IssueConsumedDate = '' THEN NULL ELSE :IssueConsumedDate END,
                RecordCount = :RecordCount,
                RetryCount = :RetryCount,
                ETLExecutionId = :ETLExecutionId,
                ModifiedBy = :ModifiedBy,
                ModifiedDtm = :ModifiedDtm
            WHERE IssueId = :IssueId
            """

            # Build parameters in the EXACT order they appear in the SQL query
            params = {}

            # Add form fields in query order
            params["PublicationCode"] = data.get("PublicationCode", "")
            params["StatusCode"] = data.get("StatusCode", "")
            params["ReportDate"] = data.get("ReportDate", "")
            params["SrcDFPublisherId"] = data.get("SrcDFPublisherId", "")
            params["SrcDFPublicationId"] = data.get("SrcDFPublicationId", "")
            params["SrcDFIssueId"] = data.get("SrcDFIssueId", "")
            params["SrcIssueName"] = data.get("SrcIssueName", "")
            # Use empty strings for date/timestamp fields - SQL will convert to NULL
            params["SrcDFCreatedDate"] = data.get("SrcDFCreatedDate", "")
            params["DataLakePath"] = data.get("DataLakePath", "")
            params["IssueName"] = data.get("IssueName", "")
            params["PublicationSeq"] = data.get("PublicationSeq", 0)
            params["DailyPublicationSeq"] = data.get("DailyPublicationSeq", 0)
            params["FirstRecordSeq"] = data.get("FirstRecordSeq", 0)
            params["LastRecordSeq"] = data.get("LastRecordSeq", 0)
            params["FirstRecordChecksum"] = data.get("FirstRecordChecksum", "")
            params["LastRecordChecksum"] = data.get("LastRecordChecksum", "")
            # Use empty strings for timestamp fields - SQL will convert to NULL
            params["PeriodStartTime"] = data.get("PeriodStartTime", "")
            params["PeriodEndTime"] = data.get("PeriodEndTime", "")
            params["PeriodStartTimeUTC"] = data.get("PeriodStartTimeUTC", "")
            params["PeriodEndTimeUTC"] = data.get("PeriodEndTimeUTC", "")
            params["IssueConsumedDate"] = data.get("IssueConsumedDate", "")
            params["RecordCount"] = data.get("RecordCount", 0)
            params["RetryCount"] = data.get("RetryCount", 0)
            params["ETLExecutionId"] = data.get("ETLExecutionId", "")

            # Add audit fields
            params["ModifiedBy"] = st.session_state.get("user", "streamlit_user")
            params["ModifiedDtm"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            # Add WHERE clause parameter
            params["IssueId"] = issue_id

            rows_affected = self.execute_command(query, params)
            logger.info(f"Rows affected: {rows_affected}")

            if rows_affected > 0:
                # Clear cache after successful update
                st.cache_data.clear()

                # Log the successful update operation
                if STEP_LOGGER_AVAILABLE:
                    log_ui_operation(
                        table_name="Issue",
                        operation="UPDATE",
                        record_id=issue_id,
                        update_data=data,
                        success=True
                    )

                return True
            else:
                # Log the failed update operation
                if STEP_LOGGER_AVAILABLE:
                    log_ui_operation(
                        table_name="Issue",
                        operation="UPDATE",
                        record_id=issue_id,
                        update_data=data,
                        success=False,
                        error_message="No rows affected"
                    )
                return False
        except Exception as e:
            logger.error(f"Failed to update issue: {str(e)}")

            # Log the failed update operation
            if STEP_LOGGER_AVAILABLE:
                log_ui_operation(
                    table_name="Issue",
                    operation="UPDATE",
                    record_id=issue_id,
                    update_data=data,
                    success=False,
                    error_message=str(e)
                )

            return False

    def delete_issue(self, issue_id: str) -> bool:
        """Delete an issue."""
        try:
            query = "DELETE FROM DATA_HUB.Issue WHERE IssueId = :IssueId"
            rows_affected = self.execute_command(query, {"IssueId": issue_id})
            return rows_affected > 0
        except Exception as e:
            logger.error(f"Failed to delete issue: {str(e)}")
            return False

    @st.cache_data(ttl=300)  # Cache for 5 minutes
    def get_ref_statuses(_self) -> List[Dict]:
        """Get all reference statuses using Snowpark with caching."""
        try:
            df = _self.execute_query(
                "SELECT * FROM DATA_HUB.REF_Status ORDER BY StatusCode"
            )
            return df.to_dict("records")
        except Exception as e:
            logger.error(f"Failed to get reference statuses: {str(e)}")
            return []

    @st.cache_data(ttl=300)  # Cache for 5 minutes
    def get_ref_interfaces(_self) -> List[Dict]:
        """Get all reference interfaces using Snowpark with caching."""
        try:
            df = _self.execute_query(
                "SELECT * FROM DATA_HUB.REF_Interface ORDER BY InterfaceCode"
            )
            return df.to_dict("records")
        except Exception as e:
            logger.error(f"Failed to get reference interfaces: {str(e)}")
            return []

    @st.cache_data(ttl=300)  # Cache for 5 minutes
    def get_ref_file_formats(_self) -> List[Dict]:
        """Get all reference file formats using Snowpark with caching."""
        try:
            df = _self.execute_query(
                "SELECT * FROM DATA_HUB.REF_File_Format ORDER BY FileFormatCode"
            )
            return df.to_dict("records")
        except Exception as e:
            logger.error(f"Failed to get reference file formats: {str(e)}")
            return []

    def create_ref_status(self, data: Dict) -> bool:
        """Create a new reference status."""
        try:
            query = """
            INSERT INTO DATA_HUB.REF_Status
            (StatusCode, StatusName, StatusDesc, StatusType, CreatedBy, CreatedDtm)
            VALUES (:StatusCode, :StatusName, :StatusDesc, :StatusType, :CreatedBy, :CreatedDtm)
            """

            # Add audit fields
            data["CreatedBy"] = st.session_state.get("user", "streamlit_user")
            data["CreatedDtm"] = datetime.now().strftime("%Y-%m-%d")

            rows_affected = self.execute_command(query, data)
            if rows_affected > 0:
                # Clear cache after successful creation
                st.cache_data.clear()
            return rows_affected > 0
        except Exception as e:
            logger.error(f"Failed to create reference status: {str(e)}")
            return False

    def update_ref_status(self, status_code: str, data: Dict) -> bool:
        """Update an existing reference status."""
        try:
            logger.info(f"update_ref_status called with status_code: {status_code}")
            logger.info(f"update_ref_status data: {data}")

            # Build dynamic UPDATE query based on provided data
            set_clauses = []
            params = {}

            # Add fields from form data in the EXACT order they appear in the SQL query
            # Order: StatusName, StatusDesc, StatusType, ModifiedBy, ModifiedDtm, StatusCode (WHERE)

            # First add the form fields (in query order)
            if "StatusName" in data:
                set_clauses.append("StatusName = :StatusName")
                params["StatusName"] = data["StatusName"]
            if "StatusDesc" in data:
                set_clauses.append("StatusDesc = :StatusDesc")
                params["StatusDesc"] = data["StatusDesc"]
            if "StatusType" in data:
                set_clauses.append("StatusType = :StatusType")
                params["StatusType"] = data["StatusType"]

            # Then add audit fields (in query order)
            set_clauses.append("ModifiedBy = :ModifiedBy")
            params["ModifiedBy"] = st.session_state.get("user", "streamlit_user")

            set_clauses.append("ModifiedDtm = :ModifiedDtm")
            params["ModifiedDtm"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            # Finally add the WHERE clause parameter
            params["StatusCode"] = status_code

            query = f"""
            UPDATE DATA_HUB.REF_Status
            SET {', '.join(set_clauses)}
            WHERE StatusCode = :StatusCode
            """

            logger.info(f"Generated query: {query}")
            logger.info(f"Query parameters: {params}")

            rows_affected = self.execute_command(query, params)
            logger.info(f"Rows affected: {rows_affected}")

            if rows_affected > 0:
                # Clear cache after successful update
                st.cache_data.clear()

                # Log the successful update operation
                if STEP_LOGGER_AVAILABLE:
                    log_ui_operation(
                        table_name="REF_Status",
                        operation="UPDATE",
                        record_id=status_code,
                        update_data=data,
                        success=True
                    )

                return True
            else:
                # Log the failed update operation
                if STEP_LOGGER_AVAILABLE:
                    log_ui_operation(
                        table_name="REF_Status",
                        operation="UPDATE",
                        record_id=status_code,
                        update_data=data,
                        success=False,
                        error_message="No rows affected"
                    )
                return False
        except Exception as e:
            logger.error(f"Failed to update reference status: {str(e)}")

            # Log the failed update operation
            if STEP_LOGGER_AVAILABLE:
                log_ui_operation(
                    table_name="REF_Status",
                    operation="UPDATE",
                    record_id=status_code,
                    update_data=data,
                    success=False,
                    error_message=str(e)
                )

            return False

    def delete_ref_status(self, status_code: str) -> bool:
        """Delete a reference status."""
        try:
            query = "DELETE FROM DATA_HUB.REF_Status WHERE StatusCode = :StatusCode"
            rows_affected = self.execute_command(query, {"StatusCode": status_code})
            if rows_affected > 0:
                # Clear cache after successful deletion
                st.cache_data.clear()
            return rows_affected > 0
        except Exception as e:
            logger.error(f"Failed to delete reference status: {str(e)}")
            return False

    def create_ref_interface(self, data: Dict) -> bool:
        """Create a new reference interface."""
        try:
            query = """
            INSERT INTO DATA_HUB.REF_Interface
            (InterfaceCode, InterfaceName, InterfaceDesc, CreatedBy, CreatedDtm)
            VALUES (:InterfaceCode, :InterfaceName, :InterfaceDesc, :CreatedBy, :CreatedDtm)
            """

            # Add audit fields
            data["CreatedBy"] = st.session_state.get("user", "streamlit_user")
            data["CreatedDtm"] = datetime.now().strftime("%Y-%m-%d")

            rows_affected = self.execute_command(query, data)
            if rows_affected > 0:
                # Clear cache after successful creation
                st.cache_data.clear()
            return rows_affected > 0
        except Exception as e:
            logger.error(f"Failed to create reference interface: {str(e)}")
            return False

    def update_ref_interface(self, interface_code: str, data: Dict) -> bool:
        """Update an existing reference interface."""
        try:
            logger.info(
                f"update_ref_interface called with interface_code: {interface_code}"
            )
            logger.info(f"update_ref_interface data: {data}")

            # Build dynamic UPDATE query based on provided data
            set_clauses = []
            params = {}

            # Add fields from form data in the EXACT order they appear in the SQL query
            # Order: InterfaceName, InterfaceDesc, ModifiedBy, ModifiedDtm, InterfaceCode (WHERE)

            # First add the form fields (in query order)
            if "InterfaceName" in data:
                set_clauses.append("InterfaceName = :InterfaceName")
                params["InterfaceName"] = data["InterfaceName"]
            if "InterfaceDesc" in data:
                set_clauses.append("InterfaceDesc = :InterfaceDesc")
                params["InterfaceDesc"] = data["InterfaceDesc"]

            # Then add audit fields (in query order)
            set_clauses.append("ModifiedBy = :ModifiedBy")
            params["ModifiedBy"] = st.session_state.get("user", "streamlit_user")

            set_clauses.append("ModifiedDtm = :ModifiedDtm")
            params["ModifiedDtm"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            # Finally add the WHERE clause parameter
            params["InterfaceCode"] = interface_code

            query = f"""
            UPDATE DATA_HUB.REF_Interface
            SET {', '.join(set_clauses)}
            WHERE InterfaceCode = :InterfaceCode
            """

            logger.info(f"Generated query: {query}")
            logger.info(f"Query parameters: {params}")

            rows_affected = self.execute_command(query, params)
            logger.info(f"Rows affected: {rows_affected}")

            if rows_affected > 0:
                # Clear cache after successful update
                st.cache_data.clear()

                # Log the successful update operation
                if STEP_LOGGER_AVAILABLE:
                    log_ui_operation(
                        table_name="REF_Interface",
                        operation="UPDATE",
                        record_id=interface_code,
                        update_data=data,
                        success=True
                    )

                return True
            else:
                # Log the failed update operation
                if STEP_LOGGER_AVAILABLE:
                    log_ui_operation(
                        table_name="REF_Interface",
                        operation="UPDATE",
                        record_id=interface_code,
                        update_data=data,
                        success=False,
                        error_message="No rows affected"
                    )
                return False
        except Exception as e:
            logger.error(f"Failed to update reference interface: {str(e)}")

            # Log the failed update operation
            if STEP_LOGGER_AVAILABLE:
                log_ui_operation(
                    table_name="REF_Interface",
                    operation="UPDATE",
                    record_id=interface_code,
                    update_data=data,
                    success=False,
                    error_message=str(e)
                )

            return False

    def delete_ref_interface(self, interface_code: str) -> bool:
        """Delete a reference interface."""
        try:
            query = "DELETE FROM DATA_HUB.REF_Interface WHERE InterfaceCode = :InterfaceCode"
            rows_affected = self.execute_command(
                query, {"InterfaceCode": interface_code}
            )
            if rows_affected > 0:
                # Clear cache after successful deletion
                st.cache_data.clear()
            return rows_affected > 0
        except Exception as e:
            logger.error(f"Failed to delete reference interface: {str(e)}")
            return False

    def create_ref_file_format(self, data: Dict) -> bool:
        """Create a new reference file format."""
        try:
            query = """
            INSERT INTO DATA_HUB.REF_File_Format
            (FileFormatCode, FileFormatName, FileFormatDesc, FileExtension, DotFileExtension, CreatedBy, CreatedDtm)
            VALUES (:FileFormatCode, :FileFormatName, :FileFormatDesc,
            :FileExtension, :DotFileExtension, :CreatedBy, :CreatedDtm)
            """

            # Add audit fields
            data["CreatedBy"] = st.session_state.get("user", "streamlit_user")
            data["CreatedDtm"] = datetime.now().strftime("%Y-%m-%d")

            rows_affected = self.execute_command(query, data)
            if rows_affected > 0:
                # Clear cache after successful creation
                st.cache_data.clear()
            return rows_affected > 0
        except Exception as e:
            logger.error(f"Failed to create reference file format: {str(e)}")
            return False

    def update_ref_file_format(self, file_format_code: str, data: Dict) -> bool:
        """Update an existing reference file format."""
        try:
            logger.info(
                f"update_ref_file_format called with file_format_code: {file_format_code}"
            )
            logger.info(f"update_ref_file_format data: {data}")

            # Build dynamic UPDATE query based on provided data
            set_clauses = []
            params = {}

            # Add fields from form data in the EXACT order they appear in the SQL query
            # Order: FileFormatName, FileFormatDesc, FileExtension, DotFileExtension,
            # ModifiedBy, ModifiedDtm, FileFormatCode (WHERE)

            # First add the form fields (in query order)
            if "FileFormatName" in data:
                set_clauses.append("FileFormatName = :FileFormatName")
                params["FileFormatName"] = data["FileFormatName"]
            if "FileFormatDesc" in data:
                set_clauses.append("FileFormatDesc = :FileFormatDesc")
                params["FileFormatDesc"] = data["FileFormatDesc"]
            if "FileExtension" in data:
                set_clauses.append("FileExtension = :FileExtension")
                params["FileExtension"] = data["FileExtension"]
            if "DotFileExtension" in data:
                set_clauses.append("DotFileExtension = :DotFileExtension")
                params["DotFileExtension"] = data["DotFileExtension"]

            # Then add audit fields (in query order)
            set_clauses.append("ModifiedBy = :ModifiedBy")
            params["ModifiedBy"] = st.session_state.get("user", "streamlit_user")

            set_clauses.append("ModifiedDtm = :ModifiedDtm")
            params["ModifiedDtm"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

            # Finally add the WHERE clause parameter
            params["FileFormatCode"] = file_format_code

            query = f"""
            UPDATE DATA_HUB.REF_File_Format
            SET {', '.join(set_clauses)}
            WHERE FileFormatCode = :FileFormatCode
            """

            logger.info(f"Generated query: {query}")
            logger.info(f"Query parameters: {params}")

            rows_affected = self.execute_command(query, params)
            logger.info(f"Rows affected: {rows_affected}")

            if rows_affected > 0:
                # Clear cache after successful update
                st.cache_data.clear()

                # Log the successful update operation
                if STEP_LOGGER_AVAILABLE:
                    log_ui_operation(
                        table_name="REF_File_Format",
                        operation="UPDATE",
                        record_id=file_format_code,
                        update_data=data,
                        success=True
                    )

                return True
            else:
                # Log the failed update operation
                if STEP_LOGGER_AVAILABLE:
                    log_ui_operation(
                        table_name="REF_File_Format",
                        operation="UPDATE",
                        record_id=file_format_code,
                        update_data=data,
                        success=False,
                        error_message="No rows affected"
                    )
                return False
        except Exception as e:
            logger.error(f"Failed to update reference file format: {str(e)}")

            # Log the failed update operation
            if STEP_LOGGER_AVAILABLE:
                log_ui_operation(
                    table_name="REF_File_Format",
                    operation="UPDATE",
                    record_id=file_format_code,
                    update_data=data,
                    success=False,
                    error_message=str(e)
                )

            return False

    def delete_ref_file_format(self, file_format_code: str) -> bool:
        """Delete a reference file format."""
        try:
            query = "DELETE FROM DATA_HUB.REF_File_Format WHERE FileFormatCode = :FileFormatCode"
            rows_affected = self.execute_command(
                query, {"FileFormatCode": file_format_code}
            )
            if rows_affected > 0:
                # Clear cache after successful deletion
                st.cache_data.clear()
            return rows_affected > 0
        except Exception as e:
            logger.error(f"Failed to delete reference file format: {str(e)}")
            return False


def render_publisher_management(crud: "SnowflakeDataHubCRUD"):
    """Render publisher management interface."""
    st.header("Publisher Management")

    # Get current publishers
    publishers = crud.get_publishers()

    if not publishers:
        st.warning("No publishers found or unable to connect to database")
        return

    # Create tabs for different operations
    list_tab, create_tab, update_tab, delete_tab = st.tabs(
        [
            "List Publishers",
            "Create Publisher",
            "Update Publisher",
            "Delete Publisher",
        ]
    )

    with list_tab:
        st.subheader("Current Publishers")

        # Display publishers in a table
        if publishers:
            df = pd.DataFrame(publishers)
            st.dataframe(df, use_container_width=True)

            # Export options
            col1, col2 = st.columns(2)
            with col1:
                csv = df.to_csv(index=False)
                st.download_button(
                    label="Download CSV",
                    data=csv,
                    file_name=f"publishers_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
                    mime="text/csv",
                )
            with col2:
                json_data = df.to_json(orient="records", indent=2)
                st.download_button(
                    label="Download JSON",
                    data=json_data,
                    file_name=f"publishers_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json",
                    mime="application/json",
                )
        else:
            st.info("No publishers found")

    with create_tab:
        st.subheader("Create New Publisher")

        with st.form("create_publisher_form"):
            col1, col2 = st.columns(2)

            with col1:
                publisher_code = st.text_input(
                    "Publisher Code *", help="Unique identifier for the publisher"
                )
                publisher_name = st.text_input(
                    "Publisher Name *", help="Display name for the publisher"
                )

            with col2:
                interface_code = st.text_input(
                    "Interface Code", help="Interface identifier"
                )

            submitted = st.form_submit_button("Create Publisher", type="primary")

            if submitted:
                if not publisher_code or not publisher_name:
                    st.error("[ERROR] Publisher Code and Name are required")
                else:
                    data = {
                        "PublisherCode": publisher_code,
                        "PublisherName": publisher_name,
                        "InterfaceCode": interface_code or "DEFAULT",
                    }

                    if crud.create_publisher(data):
                        st.success("[SUCCESS] Publisher created successfully!")
                        st.rerun()
                    else:
                        st.error("[ERROR] Failed to create publisher")

    with update_tab:
        st.subheader("Update Publisher")

        if publishers:
            publisher_options = {
                p["PublisherCode"]: p["PublisherCode"] for p in publishers
            }
            selected_publisher = st.selectbox(
                "Select Publisher to Update", list(publisher_options.keys())
            )

            if selected_publisher:
                publisher_code = publisher_options[selected_publisher]
                publisher_data = next(
                    p for p in publishers if p["PublisherCode"] == publisher_code
                )

                # Use dynamic update form for better functionality
                render_dynamic_update_form(
                    _crud=crud,
                    table_name="Publisher",
                    record_data=publisher_data,
                    primary_key="PublisherCode",
                    primary_key_value=publisher_code,
                    update_function=crud.update_publisher,
                )
        else:
            st.info("No publishers available for update")

    with delete_tab:
        st.subheader("Delete Publisher")

        if publishers:
            publisher_options = {
                p["PublisherCode"]: p["PublisherCode"] for p in publishers
            }
            selected_publisher = st.selectbox(
                "Select Publisher to Delete", list(publisher_options.keys())
            )

            if selected_publisher:
                publisher_code = publisher_options[selected_publisher]

                st.warning("[WARNING] This action cannot be undone!")

                if st.button("Delete Publisher", type="primary"):
                    if crud.delete_publisher(publisher_code):
                        st.success("[SUCCESS] Publisher deleted successfully!")
                        st.rerun()
                    else:
                        st.error("[ERROR] Failed to delete publisher")
        else:
            st.info("No publishers available for deletion")


def render_publication_management(crud: "SnowflakeDataHubCRUD"):
    """Render publication management interface."""
    st.header("Publication Management")

    # Get current publications
    publications = crud.get_publications()

    if not publications:
        st.warning("No publications found or unable to connect to database")
        return

    # Create tabs for different operations
    list_tab, create_tab, update_tab, delete_tab = st.tabs(
        [
            "List Publications",
            "Create Publication",
            "Update Publication",
            "Delete Publication",
        ]
    )

    with list_tab:
        st.subheader("Current Publications")

        # Display publications in a table
        if publications:
            df = pd.DataFrame(publications)
            st.dataframe(df, use_container_width=True)

            # Export options
            col1, col2 = st.columns(2)
            with col1:
                csv = df.to_csv(index=False)
                st.download_button(
                    label="Download CSV",
                    data=csv,
                    file_name=f"publications_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
                    mime="text/csv",
                )
            with col2:
                json_data = df.to_json(orient="records", indent=2)
                st.download_button(
                    label="Download JSON",
                    data=json_data,
                    file_name=f"publications_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json",
                    mime="application/json",
                )
        else:
            st.info("No publications found")

    with create_tab:
        st.subheader("Create New Publication")

        # Get publishers for dropdown
        publishers = crud.get_publishers()
        publisher_options = {p["PublisherCode"]: p["PublisherCode"] for p in publishers}

        with st.form("create_publication_form"):
            col1, col2 = st.columns(2)
            with col1:
                publication_code = st.text_input(
                    "Publication Code *", help="Unique identifier for the publication"
                )
                publication_name = st.text_input(
                    "Publication Name *", help="Display name for the publication"
                )

            with col2:
                publisher_code = st.selectbox(
                    "Publisher *",
                    list(publisher_options.keys()),
                    help="Select the publisher for this publication",
                )

            submitted = st.form_submit_button("Create Publication", type="primary")

            if submitted:
                if not publication_code or not publication_name or not publisher_code:
                    st.error(
                        "[ERROR] Publication Code, Name, and Publisher are required"
                    )
                else:
                    data = {
                        "PublicationCode": publication_code,
                        "PublicationName": publication_name,
                        "PublisherCode": publisher_options[publisher_code],
                    }

                    if crud.create_publication(data):
                        st.success("[SUCCESS] Publication created successfully!")
                        st.rerun()
                    else:
                        st.error("[ERROR] Failed to create publication")

    with update_tab:
        st.subheader("Update Publication")

        if publications:
            publication_options = {
                p["PublicationCode"]: p["PublicationCode"] for p in publications
            }
            selected_publication = st.selectbox(
                "Select Publication to Update", list(publication_options.keys())
            )

            if selected_publication:
                publication_code = publication_options[selected_publication]
                publication_data = next(
                    p for p in publications if p["PublicationCode"] == publication_code
                )

                # Use dynamic update form for better functionality
                render_dynamic_update_form(
                    _crud=crud,
                    table_name="Publication",
                    record_data=publication_data,
                    primary_key="PublicationCode",
                    primary_key_value=publication_code,
                    update_function=crud.update_publication,
                )
        else:
            st.info("No publications available for update")

    with delete_tab:
        st.subheader("Delete Publication")

        if publications:
            publication_options = {
                p["PublicationCode"]: p["PublicationCode"] for p in publications
            }
            selected_publication = st.selectbox(
                "Select Publication to Delete", list(publication_options.keys())
            )

            if selected_publication:
                publication_code = publication_options[selected_publication]

                st.warning("[WARNING] This action cannot be undone!")

                if st.button("Delete Publication", type="primary"):
                    if crud.delete_publication(publication_code):
                        st.success("[SUCCESS] Publication deleted successfully!")
                        st.rerun()
                    else:
                        st.error("[ERROR] Failed to delete publication")
        else:
            st.info("No publications available for deletion")


def render_subscriber_management(crud: "SnowflakeDataHubCRUD"):
    """Render subscriber management interface."""
    st.header("Subscriber Management")

    # Get current subscribers
    subscribers = crud.get_subscribers()

    if not subscribers:
        st.warning("No subscribers found or unable to connect to database")
        return

    # Create tabs for different operations
    list_tab, create_tab, update_tab, delete_tab = st.tabs(
        [
            "List Subscribers",
            "Create Subscriber",
            "Update Subscriber",
            "Delete Subscriber",
        ]
    )

    with list_tab:
        st.subheader("Current Subscribers")

        # Display subscribers in a table
        if subscribers:
            df = pd.DataFrame(subscribers)
            st.dataframe(df, use_container_width=True)

            # Export options
            col1, col2 = st.columns(2)
            with col1:
                csv = df.to_csv(index=False)
                st.download_button(
                    label="Download CSV",
                    data=csv,
                    file_name=f"subscribers_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
                    mime="text/csv",
                )
            with col2:
                json_data = df.to_json(orient="records", indent=2)
                st.download_button(
                    label="Download JSON",
                    data=json_data,
                    file_name=f"subscribers_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json",
                    mime="application/json",
                )
        else:
            st.info("No subscribers found")

    with create_tab:
        st.subheader("Create New Subscriber")

        with st.form("create_subscriber_form"):
            col1, col2 = st.columns(2)

            with col1:
                subscriber_code = st.text_input(
                    "Subscriber Code *", help="Unique identifier for the subscriber"
                )
                subscriber_name = st.text_input(
                    "Subscriber Name *", help="Display name for the subscriber"
                )

            submitted = st.form_submit_button("Create Subscriber", type="primary")

            if submitted:
                if not subscriber_code or not subscriber_name:
                    st.error("[ERROR] Subscriber Code and Name are required")
                else:
                    data = {
                        "SubscriberCode": subscriber_code,
                        "SubscriberName": subscriber_name,
                    }

                    if crud.create_subscriber(data):
                        st.success("[SUCCESS] Subscriber created successfully!")
                        st.rerun()
                    else:
                        st.error("[ERROR] Failed to create subscriber")

    with update_tab:
        st.subheader("Update Subscriber")

        if subscribers:
            subscriber_options = {
                p["SubscriberCode"]: p["SubscriberCode"] for p in subscribers
            }
            selected_subscriber = st.selectbox(
                "Select Subscriber to Update", list(subscriber_options.keys())
            )

            if selected_subscriber:
                subscriber_code = subscriber_options[selected_subscriber]
                subscriber_data = next(
                    p for p in subscribers if p["SubscriberCode"] == subscriber_code
                )

                # Use dynamic update form for better functionality
                render_dynamic_update_form(
                    _crud=crud,
                    table_name="Subscriber",
                    record_data=subscriber_data,
                    primary_key="SubscriberCode",
                    primary_key_value=subscriber_code,
                    update_function=crud.update_subscriber,
                )
        else:
            st.info("No subscribers available for update")

    with delete_tab:
        st.subheader("Delete Subscriber")

        if subscribers:
            subscriber_options = {
                p["SubscriberCode"]: p["SubscriberCode"] for p in subscribers
            }
            selected_subscriber = st.selectbox(
                "Select Subscriber to Delete", list(subscriber_options.keys())
            )

            if selected_subscriber:
                subscriber_code = subscriber_options[selected_subscriber]

                st.warning("[WARNING] This action cannot be undone!")

                if st.button("Delete Subscriber", type="primary"):
                    if crud.delete_subscriber(subscriber_code):
                        st.success("[SUCCESS] Subscriber deleted successfully!")
                        st.rerun()
                    else:
                        st.error("[ERROR] Failed to delete subscriber")
        else:
            st.info("No subscribers available for deletion")


def render_subscription_management(crud: "SnowflakeDataHubCRUD"):
    """Render subscription management interface."""
    st.header("Subscription Management")

    # Get current subscriptions
    subscriptions = crud.get_subscriptions()

    if not subscriptions:
        st.warning("No subscriptions found or unable to connect to database")
        return

    # Create tabs for different operations
    list_tab, create_tab, update_tab, delete_tab = st.tabs(
        [
            "List Subscriptions",
            "Create Subscription",
            "Update Subscription",
            "Delete Subscription",
        ]
    )

    with list_tab:
        st.subheader("Current Subscriptions")

        # Display subscriptions in a table
        if subscriptions:
            df = pd.DataFrame(subscriptions)
            st.dataframe(df, use_container_width=True)

            # Export options
            col1, col2 = st.columns(2)
            with col1:
                csv = df.to_csv(index=False)
                st.download_button(
                    label="Download CSV",
                    data=csv,
                    file_name=f"subscriptions_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
                    mime="text/csv",
                )
            with col2:
                json_data = df.to_json(orient="records", indent=2)
                st.download_button(
                    label="Download JSON",
                    data=json_data,
                    file_name=f"subscriptions_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json",
                    mime="application/json",
                )
        else:
            st.info("No subscriptions found")

    with create_tab:
        st.subheader("Create New Subscription")

        # Get publications and subscribers for dropdowns
        publications = crud.get_publications()
        subscribers = crud.get_subscribers()

        publication_options = {
            p["PublicationCode"]: p["PublicationCode"] for p in publications
        }
        subscriber_options = {
            p["SubscriberCode"]: p["SubscriberCode"] for p in subscribers
        }

        with st.form("create_subscription_form"):
            col1, col2 = st.columns(2)

            with col1:
                subscription_code = st.text_input(
                    "Subscription Code *", help="Unique identifier for the subscription"
                )
                publication_code = st.selectbox(
                    "Publication *",
                    list(publication_options.keys()),
                    help="Select the publication for this subscription",
                )

            with col2:
                subscriber_code = st.selectbox(
                    "Subscriber *",
                    list(subscriber_options.keys()),
                    help="Select the subscriber for this subscription",
                )

            submitted = st.form_submit_button("Create Subscription", type="primary")

            if submitted:
                if not subscription_code or not publication_code or not subscriber_code:
                    st.error(
                        "[ERROR] Subscription Code, Publication, and Subscriber are required"
                    )
                else:
                    data = {
                        "SubscriptionCode": subscription_code,
                        "PublicationCode": publication_options[publication_code],
                        "SubscriberCode": subscriber_options[subscriber_code],
                    }

                    if crud.create_subscription(data):
                        st.success("[SUCCESS] Subscription created successfully!")
                        st.rerun()
                    else:
                        st.error("[ERROR] Failed to create subscription")

    with update_tab:
        st.subheader("Update Subscription")

        if subscriptions:
            subscription_options = {
                f"{p['SubscriptionCode']}": p["SubscriptionCode"] for p in subscriptions
            }
            selected_subscription = st.selectbox(
                "Select Subscription to Update", list(subscription_options.keys())
            )

            if selected_subscription:
                subscription_code = subscription_options[selected_subscription]
                subscription_data = next(
                    p
                    for p in subscriptions
                    if p["SubscriptionCode"] == subscription_code
                )

                # Use dynamic update form for better functionality
                render_dynamic_update_form(
                    _crud=crud,
                    table_name="Subscription",
                    record_data=subscription_data,
                    primary_key="SubscriptionCode",
                    primary_key_value=subscription_code,
                    update_function=crud.update_subscription,
                )
        else:
            st.info("No subscriptions available for update")

    with delete_tab:
        st.subheader("Delete Subscription")

        if subscriptions:
            subscription_options = {
                f"{p['SubscriptionCode']}": p["SubscriptionCode"] for p in subscriptions
            }
            selected_subscription = st.selectbox(
                "Select Subscription to Delete", list(subscription_options.keys())
            )

            if selected_subscription:
                subscription_code = subscription_options[selected_subscription]

                st.warning("[WARNING] This action cannot be undone!")

                if st.button("Delete Subscription", type="primary"):
                    if crud.delete_subscription(subscription_code):
                        st.success("[SUCCESS] Subscription deleted successfully!")
                        st.rerun()
                    else:
                        st.error("[ERROR] Failed to delete subscription")
        else:
            st.info("No subscriptions available for deletion")


def render_issue_management(crud: "SnowflakeDataHubCRUD"):
    """Render issue management interface."""
    st.header("Issue Management")

    # Get current issues
    issues = crud.get_issues()

    if not issues:
        st.warning("No issues found or unable to connect to database")
        return

    # Create tabs for different operations
    list_tab, create_tab, update_tab, delete_tab = st.tabs(
        [
            "List Issues",
            "Create Issue",
            "Update Issue",
            "Delete Issue",
        ]
    )

    with list_tab:
        st.subheader("Current Issues")

        # Display issues in a table
        if issues:
            df = pd.DataFrame(issues)
            st.dataframe(df, use_container_width=True)

            # Export options
            col1, col2 = st.columns(2)
            with col1:
                csv = df.to_csv(index=False)
                st.download_button(
                    label="Download CSV",
                    data=csv,
                    file_name=f"issues_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
                    mime="text/csv",
                )
            with col2:
                json_data = df.to_json(orient="records", indent=2)
                st.download_button(
                    label="Download JSON",
                    data=json_data,
                    file_name=f"issues_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json",
                    mime="application/json",
                )
        else:
            st.info("No issues found")

    with create_tab:
        st.subheader("Create New Issue")

        # Get publications for dropdown
        publications = crud.get_publications()
        publication_options = {
            p["PublicationCode"]: p["PublicationCode"] for p in publications
        }

        with st.form("create_issue_form"):
            col1, col2 = st.columns(2)

            with col1:
                publication_code = st.selectbox(
                    "Publication *",
                    list(publication_options.keys()),
                    help="Select the publication for this issue",
                )
                status_code = st.selectbox(
                    "Status *",
                    ["ACTIVE", "INACTIVE", "PENDING", "RESOLVED"],
                    help="Select the status for this issue",
                )
                report_date = st.date_input(
                    "Report Date *",
                    value=datetime.now().date(),
                    help="Date when the issue was reported",
                )

            with col2:
                issue_name = st.text_input(
                    "Issue Name *", help="Name/description of the issue"
                )
                data_lake_path = st.text_input(
                    "Data Lake Path *",
                    value="/Raw Data Zone/...",
                    help="Path to the data in the data lake",
                )
                record_count = st.number_input(
                    "Record Count *",
                    min_value=0,
                    value=0,
                    help="Number of records affected",
                )

            submitted = st.form_submit_button("Create Issue", type="primary")

            if submitted:
                if not publication_code or not issue_name or not data_lake_path:
                    st.error(
                        "[ERROR] Publication, Issue Name, and Data Lake Path are required"
                    )
                else:
                    data = {
                        "PublicationCode": publication_options[publication_code],
                        "StatusCode": status_code,
                        "ReportDate": report_date.strftime("%Y-%m-%d"),
                        "IssueName": issue_name,
                        "DataLakePath": data_lake_path,
                        "RecordCount": int(record_count),
                    }

                    if crud.create_issue(data):
                        st.success("[SUCCESS] Issue created successfully!")
                        st.rerun()
                    else:
                        st.error("[ERROR] Failed to create issue")

    with update_tab:
        st.subheader("Update Issue")

        if issues:
            issue_options = {p["IssueId"]: p["IssueId"] for p in issues}
            selected_issue = st.selectbox(
                "Select Issue to Update", list(issue_options.keys())
            )

            if selected_issue:
                issue_id = issue_options[selected_issue]
                issue_data = next(p for p in issues if p["IssueId"] == issue_id)

                # Use dynamic update form for better functionality
                render_dynamic_update_form(
                    _crud=crud,
                    table_name="Issue",
                    record_data=issue_data,
                    primary_key="IssueId",
                    primary_key_value=issue_id,
                    update_function=crud.update_issue,
                )
        else:
            st.info("No issues available for update")

    with delete_tab:
        st.subheader("Delete Issue")

        if issues:
            issue_options = {p["IssueId"]: p["IssueId"] for p in issues}
            selected_issue = st.selectbox(
                "Select Issue to Delete", list(issue_options.keys())
            )

            if selected_issue:
                issue_id = issue_options[selected_issue]

                st.warning("[WARNING] This action cannot be undone!")

                if st.button("Delete Issue", type="primary"):
                    if crud.delete_issue(issue_id):
                        st.success("[SUCCESS] Issue deleted successfully!")
                        st.rerun()
                    else:
                        st.error("[ERROR] Failed to delete issue")
        else:
            st.info("No issues available for deletion")


def render_ref_status_management(crud: "SnowflakeDataHubCRUD"):
    """Render reference status management interface."""
    st.header("Reference Status Management")

    # Get current reference statuses
    statuses = crud.get_ref_statuses()

    if not statuses:
        st.warning("No reference statuses found or unable to connect to database")
        return

    # Create tabs for different operations
    list_tab, create_tab, update_tab, delete_tab = st.tabs(
        [
            "List Statuses",
            "Create Status",
            "Update Status",
            "Delete Status",
        ]
    )

    with list_tab:
        st.subheader("Current Reference Statuses")

        # Display statuses in a table
        if statuses:
            df = pd.DataFrame(statuses)
            st.dataframe(df, use_container_width=True)

            # Export options
            col1, col2 = st.columns(2)
            with col1:
                csv = df.to_csv(index=False)
                st.download_button(
                    label="Download CSV",
                    data=csv,
                    file_name=f"ref_statuses_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
                    mime="text/csv",
                )
            with col2:
                json_data = df.to_json(orient="records", indent=2)
                st.download_button(
                    label="Download JSON",
                    data=json_data,
                    file_name=f"ref_statuses_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json",
                    mime="application/json",
                )
        else:
            st.info("No reference statuses found")

    with create_tab:
        st.subheader("Create New Reference Status")

        with st.form("create_ref_status_form"):
            col1, col2 = st.columns(2)

            with col1:
                status_code = st.text_input(
                    "Status Code *", help="Unique identifier for the status"
                )
                status_name = st.text_input(
                    "Status Name *", help="Display name for the status"
                )

            with col2:
                status_desc = st.text_input(
                    "Status Description *", help="Description of the status"
                )
                status_type = st.selectbox(
                    "Status Type *",
                    ["Issue", "Distribution", "Processing", "General"],
                    help="Type of status",
                )

            submitted = st.form_submit_button("Create Status", type="primary")

            if submitted:
                if not status_code or not status_name or not status_desc:
                    st.error("[ERROR] Status Code, Name, and Description are required")
                else:
                    data = {
                        "StatusCode": status_code,
                        "StatusName": status_name,
                        "StatusDesc": status_desc,
                        "StatusType": status_type,
                    }

                    if crud.create_ref_status(data):
                        st.success("[SUCCESS] Reference status created successfully!")
                        st.rerun()
                    else:
                        st.error("[ERROR] Failed to create reference status")

    with update_tab:
        st.subheader("Update Reference Status")

        if statuses:
            status_options = {p["StatusCode"]: p["StatusCode"] for p in statuses}
            selected_status = st.selectbox(
                "Select Status to Update", list(status_options.keys())
            )

            if selected_status:
                status_code = status_options[selected_status]
                status_data = next(
                    p for p in statuses if p["StatusCode"] == status_code
                )

                # Use dynamic update form for better functionality
                render_dynamic_update_form(
                    _crud=crud,
                    table_name="REF_Status",
                    record_data=status_data,
                    primary_key="StatusCode",
                    primary_key_value=status_code,
                    update_function=crud.update_ref_status,
                )
        else:
            st.info("No reference statuses available for update")

    with delete_tab:
        st.subheader("Delete Reference Status")

        if statuses:
            status_options = {p["StatusCode"]: p["StatusCode"] for p in statuses}
            selected_status = st.selectbox(
                "Select Status to Delete", list(status_options.keys())
            )

            if selected_status:
                status_code = status_options[selected_status]

                st.warning("[WARNING] This action cannot be undone!")

                if st.button("Delete Status", type="primary"):
                    if crud.delete_ref_status(status_code):
                        st.success("[SUCCESS] Reference status deleted successfully!")
                        st.rerun()
                    else:
                        st.error("[ERROR] Failed to delete reference status")
        else:
            st.info("No reference statuses available for deletion")


def render_ref_interface_management(crud: "SnowflakeDataHubCRUD"):
    """Render reference interface management interface."""
    st.header("Reference Interface Management")

    # Get current reference interfaces
    interfaces = crud.get_ref_interfaces()

    if not interfaces:
        st.warning("No reference interfaces found or unable to connect to database")
        return

    # Create tabs for different operations
    list_tab, create_tab, update_tab, delete_tab = st.tabs(
        [
            "List Interfaces",
            "Create Interface",
            "Update Interface",
            "Delete Interface",
        ]
    )

    with list_tab:
        st.subheader("Current Reference Interfaces")

        # Display interfaces in a table
        if interfaces:
            df = pd.DataFrame(interfaces)
            st.dataframe(df, use_container_width=True)

            # Export options
            col1, col2 = st.columns(2)
            with col1:
                csv = df.to_csv(index=False)
                st.download_button(
                    label="Download CSV",
                    data=csv,
                    file_name=f"ref_interfaces_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
                    mime="text/csv",
                )
            with col2:
                json_data = df.to_json(orient="records", indent=2)
                st.download_button(
                    label="Download JSON",
                    data=json_data,
                    file_name=f"ref_interfaces_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json",
                    mime="application/json",
                )
        else:
            st.info("No reference interfaces found")

    with create_tab:
        st.subheader("Create New Reference Interface")

        with st.form("create_ref_interface_form"):
            col1, col2 = st.columns(2)

            with col1:
                interface_code = st.text_input(
                    "Interface Code *", help="Unique identifier for the interface"
                )
                interface_name = st.text_input(
                    "Interface Name", help="Display name for the interface"
                )

            with col2:
                interface_desc = st.text_input(
                    "Interface Description *", help="Description of the interface"
                )

            submitted = st.form_submit_button("Create Interface", type="primary")

            if submitted:
                if not interface_code or not interface_desc:
                    st.error("[ERROR] Interface Code and Description are required")
                else:
                    data = {
                        "InterfaceCode": interface_code,
                        "InterfaceName": interface_name or "",
                        "InterfaceDesc": interface_desc,
                    }

                    if crud.create_ref_interface(data):
                        st.success(
                            "[SUCCESS] Reference interface created successfully!"
                        )
                        st.rerun()
                    else:
                        st.error("[ERROR] Failed to create reference interface")

    with update_tab:
        st.subheader("Update Reference Interface")

        if interfaces:
            interface_options = {
                p["InterfaceCode"]: p["InterfaceCode"] for p in interfaces
            }
            selected_interface = st.selectbox(
                "Select Interface to Update", list(interface_options.keys())
            )

            if selected_interface:
                interface_code = interface_options[selected_interface]
                interface_data = next(
                    p for p in interfaces if p["InterfaceCode"] == interface_code
                )

                # Use dynamic update form for better functionality
                render_dynamic_update_form(
                    _crud=crud,
                    table_name="REF_Interface",
                    record_data=interface_data,
                    primary_key="InterfaceCode",
                    primary_key_value=interface_code,
                    update_function=crud.update_ref_interface,
                )
        else:
            st.info("No reference interfaces available for update")

    with delete_tab:
        st.subheader("Delete Reference Interface")

        if interfaces:
            interface_options = {
                p["InterfaceCode"]: p["InterfaceCode"] for p in interfaces
            }
            selected_interface = st.selectbox(
                "Select Interface to Delete", list(interface_options.keys())
            )

            if selected_interface:
                interface_code = interface_options[selected_interface]

                st.warning("[WARNING] This action cannot be undone!")

                if st.button("Delete Interface", type="primary"):
                    if crud.delete_ref_interface(interface_code):
                        st.success(
                            "[SUCCESS] Reference interface deleted successfully!"
                        )
                        st.rerun()
                    else:
                        st.error("[ERROR] Failed to delete reference interface")
        else:
            st.info("No reference interfaces available for deletion")


def render_ref_file_format_management(crud: "SnowflakeDataHubCRUD"):
    """Render reference file format management interface."""
    st.header("Reference File Format Management")

    # Get current reference file formats
    file_formats = crud.get_ref_file_formats()

    if not file_formats:
        st.warning("No reference file formats found or unable to connect to database")
        return

    # Create tabs for different operations
    list_tab, create_tab, update_tab, delete_tab = st.tabs(
        [
            "List File Formats",
            "Create File Format",
            "Update File Format",
            "Delete File Format",
        ]
    )

    with list_tab:
        st.subheader("Current Reference File Formats")

        # Display file formats in a table
        if file_formats:
            df = pd.DataFrame(file_formats)
            st.dataframe(df, use_container_width=True)

            # Export options
            col1, col2 = st.columns(2)
            with col1:
                csv = df.to_csv(index=False)
                st.download_button(
                    label="Download CSV",
                    data=csv,
                    file_name=f"ref_file_formats_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
                    mime="text/csv",
                )
            with col2:
                json_data = df.to_json(orient="records", indent=2)
                st.download_button(
                    label="Download JSON",
                    data=json_data,
                    file_name=f"ref_file_formats_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json",
                    mime="application/json",
                )
        else:
            st.info("No reference file formats found")

    with create_tab:
        st.subheader("Create New Reference File Format")

        with st.form("create_ref_file_format_form"):
            col1, col2 = st.columns(2)

            with col1:
                file_format_code = st.text_input(
                    "File Format Code *", help="Unique identifier for the file format"
                )
                file_format_name = st.text_input(
                    "File Format Name *", help="Display name for the file format"
                )
                file_format_desc = st.text_input(
                    "File Format Description *", help="Description of the file format"
                )

            with col2:
                file_extension = st.text_input(
                    "File Extension *", help="File extension (e.g., csv, json)"
                )
                dot_file_extension = st.text_input(
                    "Dot File Extension *",
                    help="File extension with dot (e.g., .csv, .json)",
                )

            submitted = st.form_submit_button("Create File Format", type="primary")

            if submitted:
                if not all(
                    [
                        file_format_code,
                        file_format_name,
                        file_format_desc,
                        file_extension,
                        dot_file_extension,
                    ]
                ):
                    st.error("[ERROR] All fields are required")
                else:
                    data = {
                        "FileFormatCode": file_format_code,
                        "FileFormatName": file_format_name,
                        "FileFormatDesc": file_format_desc,
                        "FileExtension": file_extension,
                        "DotFileExtension": dot_file_extension,
                    }

                    if crud.create_ref_file_format(data):
                        st.success(
                            "[SUCCESS] Reference file format created successfully!"
                        )
                        st.rerun()
                    else:
                        st.error("[ERROR] Failed to create reference file format")

    with update_tab:
        st.subheader("Update Reference File Format")

        if file_formats:
            file_format_options = {
                p["FileFormatCode"]: p["FileFormatCode"] for p in file_formats
            }
            selected_file_format = st.selectbox(
                "Select File Format to Update", list(file_format_options.keys())
            )

            if selected_file_format:
                file_format_code = file_format_options[selected_file_format]
                file_format_data = next(
                    p for p in file_formats if p["FileFormatCode"] == file_format_code
                )

                # Use dynamic update form for better functionality
                render_dynamic_update_form(
                    _crud=crud,
                    table_name="REF_File_Format",
                    record_data=file_format_data,
                    primary_key="FileFormatCode",
                    primary_key_value=file_format_code,
                    update_function=crud.update_ref_file_format,
                )
        else:
            st.info("No reference file formats available for update")

    with delete_tab:
        st.subheader("Delete Reference File Format")

        if file_formats:
            file_format_options = {
                p["FileFormatCode"]: p["FileFormatCode"] for p in file_formats
            }
            selected_file_format = st.selectbox(
                "Select File Format to Delete", list(file_format_options.keys())
            )

            if selected_file_format:
                file_format_code = file_format_options[selected_file_format]

                st.warning("[WARNING] This action cannot be undone!")

                if st.button("Delete File Format", type="primary"):
                    if crud.delete_ref_file_format(file_format_code):
                        st.success(
                            "[SUCCESS] Reference file format deleted successfully!"
                        )
                        st.rerun()
                    else:
                        st.error("[ERROR] Failed to delete reference file format")
        else:
            st.info("No reference file formats available for deletion")


def main():
    """Main application entry point with performance optimizations."""
    st.title("DataHub Management System")
    st.markdown("**Snowflake Native Deployment**")

    # Initialize session state
    if "user" not in st.session_state:
        st.session_state["user"] = "streamlit_user"

    # Show loading indicator while connecting
    with st.spinner("Connecting to Snowflake..."):
        # Get Snowflake session
        session = get_snowflake_session()

    if not session:
        st.error(
            "[ERROR] Unable to connect to Snowflake. Please check your configuration."
        )
        st.stop()

    # Initialize CRUD operations
    crud = SnowflakeDataHubCRUD(session)

    # Sidebar for navigation
    with st.sidebar:
        st.header("Configuration")
        # Get current database and schema from the session
        try:
            current_db = session.get_current_database()
            current_schema = session.get_current_schema()
            st.info(f"Connected to: {current_db}")
            st.info(f"Schema: {current_schema}")
        except Exception:
            st.info("Connected to: Snowflake")
            st.info("Schema: Current session")
        st.info(f"User: {st.session_state['user']}")

        st.header("Navigation")
        page = st.selectbox(
            "Select Management Area",
            [
                "Publishers",
                "Publications",
                "Subscribers",
                "Subscriptions",
                "Issues",
                "Reference Statuses",
                "Reference Interfaces",
                "Reference File Formats",
            ],
        )

    # Main content area with lazy loading
    if page == "Publishers":
        with st.spinner("Loading Publishers..."):
            render_publisher_management(crud)
    elif page == "Publications":
        with st.spinner("Loading Publications..."):
            render_publication_management(crud)
    elif page == "Subscribers":
        with st.spinner("Loading Subscribers..."):
            render_subscriber_management(crud)
    elif page == "Subscriptions":
        with st.spinner("Loading Subscriptions..."):
            render_subscription_management(crud)
    elif page == "Issues":
        with st.spinner("Loading Issues..."):
            render_issue_management(crud)
    elif page == "Reference Statuses":
        with st.spinner("Loading Reference Statuses..."):
            render_ref_status_management(crud)
    elif page == "Reference Interfaces":
        with st.spinner("Loading Reference Interfaces..."):
            render_ref_interface_management(crud)
    elif page == "Reference File Formats":
        with st.spinner("Loading Reference File Formats..."):
            render_ref_file_format_management(crud)

    # Footer
    st.markdown("---")
    st.markdown("**DataHub Management System** - Powered by Snowflake & Streamlit")


if __name__ == "__main__":
    main()
