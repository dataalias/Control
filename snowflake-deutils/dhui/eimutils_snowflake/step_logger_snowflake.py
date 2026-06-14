"""
***********************************************************************************************************************
File: step_logger_snowflake.py

Purpose: Snowflake-native step logging functionality using Snowpark for the DATA_HUB.STEP_LOG table.

This StepLogger variant is optimized for running directly within Snowflake's infrastructure:
- Uses Snowpark Session instead of external connectors
- No AWS dependencies or external authentication
- Leverages Snowflake's internal session context
- Optimized for Snowflake stored procedures, tasks, and notebooks

Key Features:
    - Simple 4-method interface: __init__, start_step, log_step, close
    - Automatic process start/end logging with manual step tracking
    - Hierarchical logging with parent-child relationships
    - Automatic timing calculation between start_step and log_step calls
    - Total duration and record count tracking across all steps
    - Custom attributes support for flexible metadata logging
    - Native Snowpark DataFrame operations
    - VARIANT column support for JSON metadata

Dependencies:
    - snowflake-snowpark-python
    - Snowflake DATA_HUB.STEP_LOG table
    - Snowflake DATA_HUB.SEQ__STEP_LOG_ID sequence

Example:
    ```python
    from snowflake.snowpark.context import get_active_session
    from step_logger_snowflake import StepLoggerSnowflake
    import uuid

    # Get Snowflake session (automatically available in stored procedures)
    session = get_active_session()

    # Initialize logger
    logger = StepLoggerSnowflake(
        session=session,
        etl_execution_id=str(uuid.uuid4()),
        process_name="My_Snowflake_Process",
        process_description="Native Snowflake ETL process"
    )

    try:
        # Start timing a step
        logger.start_step("data_extraction")
        # ... your processing logic here ...
        logger.log_step(status="SUCCESS", record_count=1000)

        # Start another step
        logger.start_step("data_transformation")
        # ... more processing ...
        logger.log_step(status="SUCCESS", record_count=950)

    finally:
        # Always close to log process completion
        logger.close()
    ```

***********************************************************************************************************************
"""

import json
from typing import Dict, Any, Optional
from datetime import datetime
from enum import Enum

try:
    from snowflake.snowpark import Session
    from snowflake.snowpark.context import get_active_session
    # from snowflake.snowpark.exceptions import SnowparkSQLException
    SNOWPARK_AVAILABLE = True
except ImportError:
    SNOWPARK_AVAILABLE = False
    Session = None


class StepStatus(Enum):
    """
    Enumeration of valid step status values for the STEP_LOG table.
    """
    START = "START"
    SUCCESS = "SUCCESS"
    FAILED = "FAILED"
    END = "END"


class StepLoggerSnowflake:
    """
    A Snowflake-native step logging class for ETL processes and data operations.

    This version is optimized for Snowflake's internal execution environment,
    using Snowpark Session for database operations instead of external connectors.

    Key Features:
        - **Snowpark Native**: Uses Snowpark Session API
        - **No External Auth**: Leverages Snowflake's session context
        - **Simple 4-method interface**: Easy to use with minimal setup
        - **Automatic timing**: Calculates duration between start_step and log_step calls
        - **Hierarchical logging**: Process start becomes parent for all step logs
        - **Running totals**: Automatically maintains TOTAL_DURATION and TOTAL_COUNT
        - **Custom attributes**: Support for flexible metadata on all operations

    Method Interface:
        - **__init__**: Establishes session and logs process start
        - **start_step**: Begins timing a step (no database write)
        - **log_step**: Logs completed step with calculated timing to database
        - **close**: Logs process completion

    Database Schema:
        Logs to DATA_HUB.STEP_LOG table with VARIANT Step_Desc column

    Attributes:
        session (Session): Snowpark session for database operations
        database (str): Snowflake database name
        schema (str): Schema name (default: DATA_HUB)
        process_name (str): Name of the process being logged
        process_type (str): Type of process (default: 'ETL')
        etl_execution_id (str): Unique identifier for the ETL execution
        parent_step_log_id (int): ID of the process start record
        TOTAL_DURATION (int): Running total of all step durations in seconds
        TOTAL_COUNT (int): Running total of all record counts processed
        step_number (int): Sequential step counter
    """

    def __init__(
        self,
        etl_execution_id: str,
        process_name: str,
        process_type: str = "ETL",
        process_description: str = None,
        session: Session = None,
        database: str = None,
        schema: str = "DATA_HUB",
        custom_attributes: Dict[str, Any] = None,
    ):
        """
        Initialize the StepLogger with Snowpark session and log process start.

        Args:
            etl_execution_id (str): Unique identifier for the ETL execution
            process_name (str): Name of the process being logged
            process_type (str, optional): Type of process. Defaults to 'ETL'
            process_description (str, optional): Description of the process
            session (Session, optional): Snowpark session. If None, gets active session
            database (str, optional): Database name. If None, uses current database
            schema (str, optional): Schema name. Defaults to 'DATA_HUB'
            custom_attributes (Dict[str, Any], optional): Additional metadata

        Raises:
            ImportError: If snowflake-snowpark-python is not available
            RuntimeError: If no active Snowpark session is found
        """
        if not SNOWPARK_AVAILABLE:
            raise ImportError(
                "snowflake-snowpark-python is required for StepLoggerSnowflake. "
                "Install with: pip install snowflake-snowpark-python"
            )

        # Get or validate session
        if session is None:
            try:
                self.session = get_active_session()
            except Exception as e:
                raise RuntimeError(
                    f"No active Snowpark session found. "
                    f"Ensure you're running in Snowflake context or pass session explicitly. Error: {e}"
                )
        else:
            self.session = session

        # Auto-detect database if not provided
        if database is None:
            try:
                database = self.session.get_current_database()
            except Exception:
                database = "ULTRA_DEV_RAW"  # Default fallback

        self.database = database
        self.schema = schema
        self.etl_execution_id = etl_execution_id
        self.process_name = process_name
        self.process_type = process_type
        self.process_description = process_description

        # Initialize tracking variables
        self.parent_step_log_id = -1
        self.step_number = 0
        self.TOTAL_DURATION = 0
        self.TOTAL_COUNT = 0
        self.process_start_time = datetime.now()

        # Current step tracking
        self.current_step_name = None
        self.current_step_start = None
        self.current_step_custom_attributes = None
        self.operation = None

        # Log process start
        self.parent_step_log_id = self._log_process_start(
            process_description, custom_attributes
        )

        self._log(f"StepLoggerSnowflake initialized for process: {process_name}")

    def start_step(
        self,
        step_name: str,
        operation: str = None,
        custom_attributes: Dict[str, Any] = None,
    ):
        """
        Begin timing a step without writing to database.

        Args:
            step_name (str): Name of the step being started
            operation (str, optional): Operation type (e.g., 'EXTRACT', 'TRANSFORM')
            custom_attributes (Dict[str, Any], optional): Additional metadata

        Raises:
            RuntimeError: If a step is already in progress
        """
        if self.current_step_name is not None:
            raise RuntimeError(
                f"Step '{self.current_step_name}' is already in progress. "
                f"Call log_step() before starting a new step."
            )

        self.current_step_name = step_name
        self.current_step_start = datetime.now()
        self.current_step_custom_attributes = custom_attributes
        self.operation = operation or "PROCESS"

        self._log(f"Started step: {step_name}")

    def log_step(
        self,
        status: str,
        description: str = None,
        db_name: str = None,
        record_count: int = None,
        custom_attributes: Dict[str, Any] = None,
    ) -> Optional[int]:
        """
        Log the completion of the current step with timing information.

        Args:
            status (str): 'SUCCESS' or 'FAILED'
            description (str, optional): Description of what occurred
            db_name (str, optional): Database name if applicable
            record_count (int, optional): Number of records processed
            custom_attributes (Dict[str, Any], optional): Additional metadata

        Returns:
            Optional[int]: Step_Log_Id of the inserted record, or None if failed

        Raises:
            RuntimeError: If no step is currently in progress
            ValueError: If status is not 'SUCCESS' or 'FAILED'
        """
        if self.current_step_name is None:
            raise RuntimeError(
                "No step in progress. Call start_step() before log_step()."
            )

        # Validate status
        if status.upper() not in ["SUCCESS", "FAILED"]:
            raise ValueError(
                f"Invalid status '{status}'. Must be 'SUCCESS' or 'FAILED'"
            )

        status = status.upper()

        # Calculate duration
        end_time = datetime.now()
        duration_seconds = int((end_time - self.current_step_start).total_seconds())

        # Build step description
        step_desc = {
            "MessageType": "SUCCESS" if status == "SUCCESS" else "ERROR",
            "StepNumber": self.step_number,
            "Operation": self.operation,
            "Description": description or f"Step {self.current_step_name} completed",
        }

        # Add custom attributes
        if self.current_step_custom_attributes:
            step_desc.update(self.current_step_custom_attributes)
        if custom_attributes:
            step_desc.update(custom_attributes)

        # Increment step number
        self.step_number += 1

        # Log to database
        step_id = self._insert_step_log(
            {
                "Parent_Log_Id": self.parent_step_log_id,
                "Process_Name": self.process_name,
                "Process_Type": self.process_type,
                "Step_Name": self.current_step_name,
                "Step_Desc": step_desc,
                "Step_Status": status,
                "Start_Dtm": self.current_step_start,
                "Duration_In_Seconds": duration_seconds,
                "Db_Name": db_name,
                "Record_Count": record_count,
                "ETL_Execution_Id": self.etl_execution_id,
            }
        )

        self._log(
            f"Logged step: {self.current_step_name} ({status}) - "
            f"Duration: {duration_seconds}s - ID: {step_id}"
        )

        # Update totals
        self.TOTAL_DURATION += duration_seconds
        if record_count is not None:
            self.TOTAL_COUNT += record_count

        # Reset current step tracking
        self.current_step_name = None
        self.current_step_start = None
        self.current_step_custom_attributes = None

        return step_id

    def close(self, custom_attributes: Dict[str, Any] = None):
        """
        Log process completion.

        Args:
            custom_attributes (Dict[str, Any], optional): Additional metadata
        """
        try:
            # Build completion description
            completion_desc = {
                "MessageType": "INFO",
                "StepNumber": self.step_number,
                "Operation": "Process Completion",
                "Description": f"Process {self.process_name} completed",
            }

            if custom_attributes:
                completion_desc.update(custom_attributes)

            self.step_number += 1

            completion_id = self._insert_step_log(
                {
                    "Parent_Log_Id": self.parent_step_log_id,
                    "Process_Name": self.process_name,
                    "Process_Type": self.process_type,
                    "Step_Name": f"{self.process_name}_END",
                    "Step_Desc": completion_desc,
                    "Step_Status": StepStatus.END.value,
                    "Start_Dtm": datetime.now(),
                    "Duration_In_Seconds": self.TOTAL_DURATION,
                    "Db_Name": None,
                    "Record_Count": self.TOTAL_COUNT,
                    "ETL_Execution_Id": self.etl_execution_id,
                }
            )

            self._log(
                f"Process completion logged - Total Duration: {self.TOTAL_DURATION}s - "
                f"Total Count: {self.TOTAL_COUNT} - ID: {completion_id}"
            )

        except Exception as e:
            self._log(f"Failed to log process completion: {e}", level="ERROR")

    def _log_process_start(
        self, process_description: str = None, custom_attributes: Dict[str, Any] = None
    ) -> int:
        """
        Log the process start record.

        Args:
            process_description (str, optional): Description of the process
            custom_attributes (Dict[str, Any], optional): Additional metadata

        Returns:
            int: Step_Log_Id of the start record

        Raises:
            Exception: If logging fails
        """
        try:
            # Build start description
            start_desc = {
                "MessageType": "INFO",
                "StepNumber": self.step_number,
                "Operation": "Process Start",
                "Description": process_description
                or f"Started {self.process_name} process",
            }

            if custom_attributes:
                start_desc.update(custom_attributes)

            self.step_number += 1

            # Insert START record
            start_step_log_id = self._insert_step_log(
                {
                    "Parent_Log_Id": self.parent_step_log_id,
                    "Process_Name": self.process_name,
                    "Process_Type": self.process_type,
                    "Step_Name": f"{self.process_name}_START",
                    "Step_Desc": start_desc,
                    "Step_Status": StepStatus.START.value,
                    "Start_Dtm": self.process_start_time,
                    "Duration_In_Seconds": 0,
                    "Db_Name": None,
                    "Record_Count": None,
                    "ETL_Execution_Id": self.etl_execution_id,
                }
            )

            self._log(
                f"Process start logged with Step_Log_Id: {start_step_log_id} "
                f"(parent for subsequent steps)"
            )

            return start_step_log_id

        except Exception as e:
            self._log(f"Failed to log process start: {e}", level="ERROR")
            raise

    def _insert_step_log(self, step_data: Dict[str, Any]) -> Optional[int]:
        """
        Insert a new step log record using Snowpark.

        Args:
            step_data (Dict[str, Any]): Dictionary containing step log data

        Returns:
            Optional[int]: Step_Log_Id of inserted record, or None if failed
        """
        try:
            # Get sequence value
            seq_query = (
                f"SELECT {self.database}.{self.schema}.SEQ__STEP_LOG_ID.NEXTVAL as id"
            )
            result = self.session.sql(seq_query).collect()
            step_log_id = result[0]['ID']

            self._log(f"Retrieved sequence value: {step_log_id}")

            # Convert Step_Desc dict to JSON string
            step_desc_json = json.dumps(step_data.get('Step_Desc', {}))

            # Format datetime
            start_dtm = step_data['Start_Dtm'].strftime('%Y-%m-%d %H:%M:%S')

            # Build INSERT with SELECT and PARSE_JSON for VARIANT column
            query = f"""
                INSERT INTO {self.database}.{self.schema}.STEP_LOG
                (Step_Log_Id, Parent_Log_Id, Process_Name, Process_Type, Step_Name,
                 Step_Desc, Step_Status, Start_Dtm, Duration_In_Seconds,
                 Db_Name, Record_Count, ETL_Execution_Id)
                SELECT
                    {step_log_id},
                    {step_data['Parent_Log_Id']},
                    '{step_data['Process_Name']}',
                    '{step_data['Process_Type']}',
                    '{step_data['Step_Name']}',
                    PARSE_JSON('{step_desc_json}'),
                    '{step_data['Step_Status']}',
                    TO_TIMESTAMP('{start_dtm}', 'YYYY-MM-DD HH24:MI:SS'),
                    {step_data.get('Duration_In_Seconds', 0)},
                    {f"'{step_data['Db_Name']}'" if step_data.get('Db_Name') else 'NULL'},
                    {step_data.get('Record_Count') if step_data.get('Record_Count') is not None else 'NULL'},
                    '{step_data['ETL_Execution_Id']}'
            """

            # Execute insert
            self.session.sql(query).collect()

            self._log(f"Successfully inserted step log with ID: {step_log_id}")

            return step_log_id

        except Exception as e:
            self._log(f"Failed to insert step log: {e}", level="ERROR")
            return None

    def _log(self, message: str, level: str = "INFO"):
        """
        Internal logging method.

        Args:
            message (str): Log message
            level (str): Log level (INFO, ERROR, DEBUG)
        """
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        print(f"{timestamp} , {level} , step_logger_snowflake , {message}")


"""
***********************************************************************************************************************
Change History:

Author      Date        Description
----------  ----------  -------------------------------------------------------
ffortunato  2025-10-13  Created Snowflake-native version using Snowpark
ffortunato  2025-10-13  Implemented session-based connection (no external auth)
ffortunato  2025-10-13  Added VARIANT support with PARSE_JSON for Step_Desc
ffortunato  2025-10-13  Optimized for Snowflake stored procedures and tasks
***********************************************************************************************************************
"""
