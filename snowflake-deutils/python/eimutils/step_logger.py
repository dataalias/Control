"""
***********************************************************************************************************************
File: step_logger.py

Purpose: Simple step logging functionality to insert data into the DATA_HUB.STEP_LOG table.

The StepLogger class provides a simple, hierarchical logging system for ETL processes and other
data operations. It automatically tracks timing, maintains totals, and logs structured data
to a Snowflake database table.

Key Features:
    - Simple 4-method interface: __init__, start_step, log_step, close
    - Automatic process start/end logging with manual step tracking
    - Hierarchical logging with parent-child relationships
    - Automatic timing calculation between start_step and log_step calls
    - Total duration and record count tracking across all steps
    - Custom attributes support for flexible metadata logging
    - Standardized step descriptions with MessageType, StepNumber, Operation, Description
    - Uses Snowflake sequences for unique ID generation

Dependencies/Helpful Notes:
    - Requires database connection (Snowflake)
    - Depends on eimutils.delogging for console logging
    - Depends on eimutils.utils for Snowflake connection management
    - Uses DATA_HUB.STEP_LOG table and DATA_HUB.SEQ__STEP_LOG_ID sequence

Example:
    Basic usage pattern:

    ```python
    from eimutils.step_logger import StepLogger
    import uuid

    # Initialize logger
    logger = StepLogger(
        secret_key="your-aws-secret-arn",
        env="DEV",
        etl_execution_id=str(uuid.uuid4()),
        process_name="My_ETL_Process",
        process_description="ETL process for data transformation"
    )

    try:
        # Start timing a step
        logger.start_step("data_extraction",
                         custom_attributes={"source": "database"})

        # ... your processing logic here ...

        # Log the step completion
        logger.log_step(status="SUCCESS",
                       record_count=1000,
                       description="Successfully extracted data")

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
from eimutils.delogging import log_to_console
from eimutils.utils import get_snowflake_connection_from_secret


class StepStatus(Enum):
    """
    Enumeration of valid step status values for the STEP_LOG table.

    This enum defines the allowed status values that can be used when logging steps
    to the database. Each status represents a different phase or outcome of a process step.

    Attributes:
        START (str): Indicates the beginning of a process. Used automatically by StepLogger
                    when initializing and logging the process start.
        SUCCESS (str): Indicates successful completion of a step. Used when a step
                       finishes without errors.
        FAILED (str): Indicates a step encountered an error or failed to complete successfully.
        END (str): Indicates the end of an entire process. Used automatically by StepLogger
                  when closing and logging the process completion.

    Example:
        ```python
        # These are used internally by StepLogger, but can be referenced:
        logger.log_step(status=StepStatus.SUCCESS.value)
        # or more commonly:
        logger.log_step(status="SUCCESS")  # String values are also accepted
        ```
    """

    START = "START"
    SUCCESS = "SUCCESS"
    FAILED = "FAILED"
    END = "END"


class StepLogger:
    """
    A comprehensive step logging class for ETL processes and data operations.

    The StepLogger provides a simple, hierarchical logging system that automatically tracks
    process timing, maintains running totals, and logs structured data to a Snowflake database.
    It follows a parent-child logging hierarchy where the initial process start becomes the
    parent for all subsequent step logs.

    Key Features:
        - **Simple 4-method interface**: Easy to use with minimal setup
        - **Automatic timing**: Calculates duration between start_step and log_step calls
        - **Hierarchical logging**: Process start becomes parent for all step logs
        - **Running totals**: Automatically maintains TOTAL_DURATION and TOTAL_COUNT
        - **Custom attributes**: Support for flexible metadata on all operations
        - **Standardized format**: Consistent step descriptions with required fields
        - **Error handling**: Comprehensive error handling with rollback support
        - **Connection management**: Automatic database connection lifecycle management

    Method Interface:
        - **__init__**: Establishes database connection and logs process start
        - **start_step**: Begins timing a step (no database write)
        - **log_step**: Logs completed step with calculated timing to database
        - **close**: Logs process completion and closes database connection

    Database Schema:
        Logs to DATA_HUB.STEP_LOG table with the following key fields:
        - Step_Log_Id: Unique identifier (from sequence)
        - Parent_Log_Id: Links steps to parent process
        - Process_Name: Name of the overall process
        - Step_Name: Name of the individual step
        - Step_Status: START, SUCCESS, FAILED, or END
        - Start_Dtm: Timestamp when step started
        - Duration_In_Seconds: Calculated step duration
        - Record_Count: Number of records processed (optional)
        - Step_Desc: VARIANT column with structured metadata (JSON)

    Attributes:
        secret_key (str): AWS secret ARN for database authentication
        env (str): Environment identifier (DEV, STAGE, PROD)
        etl_execution_id (str): Unique identifier for the ETL execution
        process_name (str): Name of the process being logged
        process_type (str): Type of process (default: 'ETL')
        database (str): Snowflake database name (constructed from env)
        parent_step_log_id (int): ID of the process start record (parent for all steps)
        TOTAL_DURATION (int): Running total of all step durations in seconds
        TOTAL_COUNT (int): Running total of all record counts processed
        step_number (int): Sequential step counter for descriptions
        current_step_name (str): Name of currently active step (between start_step and log_step)
        current_step_start (datetime): Start time of currently active step
        db_connection: Active Snowflake database connection

    Example:
        ```python
        import uuid
        from eimutils.step_logger import StepLogger

        etl_id = str(uuid.uuid4())
        logger = StepLogger(
            secret_key="arn:aws:secretsmanager:...",
            env="DEV",
            etl_execution_id=etl_id,
            process_name="Customer_Data_ETL",
            process_description="Daily customer data processing",
            custom_attributes={"version": "1.2", "source": "CRM"}
        )

        try:
            # Extract step
            logger.start_step(
                "extract_customers",
                operation="EXTRACT",
                custom_attributes={"table": "customers", "filter": "active"}
            )

            # ... extraction logic ...

            logger.log_step(
                status="SUCCESS",
                description="Successfully extracted customer data",
                record_count=5000,
                custom_attributes={"rows_filtered": 100}
            )

            # Transform step
            logger.start_step("transform_data", operation="TRANSFORM")

            # ... transformation logic ...

            logger.log_step(
                status="SUCCESS",
                description="Data transformation completed",
                record_count=4900
            )

        except Exception as e:
            # Log failure if step was started
            if logger.current_step_name:
                logger.log_step(
                    status="FAILED",
                    description=f"Step failed: {str(e)}",
                    custom_attributes={"error": str(e)}
                )
            raise
        finally:
            # Always close to log process completion
            logger.close(custom_attributes={"final_status": "success"})
        ```

    Raises:
        ValueError: If invalid parameters are provided or if methods are called out of sequence
        Exception: For database connection or query execution errors
    """

    def __init__(
        self,
        secret_key: str,
        env: str,
        etl_execution_id: str,
        process_name: str,
        process_type: str = "ETL",
        process_description: str = "",
        custom_attributes: Dict[str, Any] = None,
    ):
        """
        Initialize StepLogger, establish database connection, and log process start.

        Creates a new StepLogger instance, establishes a connection to the Snowflake database,
        and automatically logs a process start record that becomes the parent for all subsequent
        step logs. The process start is logged with status="START" and captures initial timing.

        Args:
            secret_key (str): AWS Secrets Manager ARN containing database credentials.
                            Should have format: arn:aws:secretsmanager:region:account:secret:name
            env (str): Environment identifier used to construct database name.
                      Valid values: "DEV", "STAGE", "PROD"
                      Results in database: ULTRA_{env}_RAW
            etl_execution_id (str): Unique identifier for this ETL execution run.
                                   Typically a UUID string for tracking related processes.
            process_name (str): Human-readable name for the process being logged.
                               This will be used as the base for START/END step names.
            process_type (str, optional): Category of process being executed.
                                        Defaults to "ETL". Common values: "ETL", "BATCH", "STREAM"
            process_description (str, optional): Detailed description of what this process does.
                                               Stored in the step description JSON.
            custom_attributes (Dict[str, Any], optional): Additional metadata to include in
                                                         the process start log. Will be merged
                                                         into the step description JSON.

        Raises:
            Exception: If database connection cannot be established
            Exception: If process start logging fails

        Side Effects:
            - Establishes database connection (stored in self.db_connection)
            - Logs a START record to DATA_HUB.STEP_LOG table
            - Sets self.parent_step_log_id to the ID of the START record
            - Initializes timing and counter variables
            - Logs initialization message to console

        Example:
            ```python
            import uuid

            logger = StepLogger(
                secret_key="arn:aws:secretsmanager:MY_AWS_REGION:123456789:secret:db-creds",
                env="DEV",
                etl_execution_id=str(uuid.uuid4()),
                process_name="Daily_Customer_ETL",
                process_type="ETL",
                process_description="Processes daily customer data updates",
                custom_attributes={
                    "version": "2.1",
                    "source_system": "CRM",
                    "target_table": "customer_dim"
                }
            )
            ```

        Note:
            The constructor automatically logs a process start record. Always call close()
            when done to log process completion, preferably in a try/finally block.
        """
        self.secret_key = secret_key
        self.env = env.upper()
        self.etl_execution_id = etl_execution_id
        self.process_name = process_name
        self.process_type = process_type
        self.aws_region = "MY_AWS_REGION"
        self.database = f"ULTRA_{self.env}_RAW"

        # Process tracking
        self.process_start_time = datetime.now()
        self.parent_step_log_id = -1  # Will be updated to START record's Step_Log_Id

        # Total tracking properties
        self.TOTAL_DURATION = 0  # Incremented with each step duration
        self.TOTAL_COUNT = 0  # Incremented with each record count
        self.step_number = 0  # Track step numbers for descriptions

        # Current step tracking
        self.current_step_name = None
        self.current_step_start = None
        self.current_step_custom_attributes = None

        log_to_console(
            __name__, "Info", f"Initializing StepLogger for process: {process_name}"
        )

        # Connect to database
        self.db_connection = self._get_connection()

        # Log process start and capture the Step_Log_Id as parent for subsequent steps
        self.parent_step_log_id = self._log_process_start(
            process_description, custom_attributes
        )

    def start_step(
        self,
        step_name: str,
        operation: str = None,
        custom_attributes: Dict[str, Any] = None,
    ) -> None:
        """
        Begin timing a new step without writing to the database.

        This method starts timing for a new step by recording the step name, operation,
        and start timestamp. No database write occurs until log_step() is called.
        This design allows for accurate timing measurement between step start and completion.

        Args:
            step_name (str): Unique name for the step being started. This will be stored
                           as Step_Name in the database when log_step() is called.
                           Should be descriptive and unique within the process.
            operation (str, optional): Type of operation being performed. Common values
                                     include "EXTRACT", "TRANSFORM", "LOAD", "VALIDATE".
                                     This will be included in the step description JSON.
            custom_attributes (Dict[str, Any], optional): Additional metadata to associate
                                                         with this step. Will be merged into
                                                         the step description when log_step()
                                                         is called. These can be overridden
                                                         by custom_attributes in log_step().

        Raises:
            Warning: If a previous step was started but never logged (logged as console warning)

        Side Effects:
            - Sets self.current_step_name to the provided step_name
            - Sets self.current_step_start to the current timestamp
            - Stores operation and custom_attributes for later use in log_step()
            - Logs start message to console

        Example:
            ```python
            # Start timing an extraction step
            logger.start_step(
                step_name="extract_customer_data",
                operation="EXTRACT",
                custom_attributes={
                    "source_table": "customers",
                    "filter_criteria": "active_only",
                    "expected_rows": 10000
                }
            )

            # ... perform your extraction logic here ...

            # Later, log the completion:
            logger.log_step(status="SUCCESS", record_count=9850)
            ```

        Note:
            Must be followed by a call to log_step() to record the step in the database.
            Only one step can be active at a time - starting a new step before logging
            the previous one will generate a warning.
        """
        if self.current_step_name:
            log_to_console(
                __name__,
                "Warning",
                f"Step '{self.current_step_name}' was started but not logged. Starting new step: {step_name}",
            )

        self.current_step_name = step_name
        self.operation = operation
        self.current_step_start = datetime.now()
        self.current_step_custom_attributes = custom_attributes

        log_to_console(__name__, "Info", f"Started timing step: {step_name}")

    def log_step(
        self,
        status: str = "SUCCESS",
        description: str = "",
        db_name: str = None,
        record_count: int = None,
        custom_attributes: Dict[str, Any] = None,
    ) -> int:
        """
        Log the completed step to the database with calculated timing and metadata.

        This method completes the step logging process by calculating the duration since
        start_step() was called, building a structured description, and inserting the
        complete step record into the database. The step timing is automatically calculated
        and totals are updated.

        Args:
            status (str, optional): Final status of the step. Must be "SUCCESS" or "FAILED".
                                  Case-insensitive. Defaults to "SUCCESS".
                                  - "SUCCESS": Step finished successfully
                                  - "FAILED": Step encountered an error
            description (str, optional): Human-readable description of what the step accomplished
                                       or what error occurred. If empty, a default description
                                       is generated based on the step name and status.
            db_name (str, optional): Name of database or data source that was processed during
                                   this step. Useful for tracking which systems were accessed.
            record_count (int, optional): Number of records processed during this step.
                                        Will be added to the running TOTAL_COUNT for the process.
            custom_attributes (Dict[str, Any], optional): Additional metadata to include in the
                                                         step description JSON. These values take
                                                         precedence over custom_attributes from
                                                         start_step() if there are conflicts.

        Returns:
            int: The Step_Log_Id of the inserted step record, which can be used for
                 debugging or creating sub-process hierarchies.

        Raises:
            ValueError: If no step is currently active (start_step() not called first)
            ValueError: If status is not "SUCCESS" or "FAILED"
            Exception: If database insert operation fails

        Side Effects:
            - Inserts a record into DATA_HUB.STEP_LOG table
            - Increments self.step_number for next step
            - Adds duration to self.TOTAL_DURATION
            - Adds record_count to self.TOTAL_COUNT (if provided)
            - Resets current step tracking variables to None
            - Logs completion message to console
            - Commits database transaction

        Step Description JSON Structure:
            The method creates a standardized JSON structure for Step_Desc VARIANT column:
            ```json
            {
                "MessageType": "SUCCESS" | "ERROR",
                "StepNumber": <sequential_number>,
                "Operation": <operation_from_start_step>,
                "Description": <provided_description>,
                ...custom_attributes_from_start_step,
                ...custom_attributes_from_log_step
            }
            ```

        Example:
            ```python
            # After calling start_step()...

            # Log successful completion
            step_id = logger.log_step(
                status="SUCCESS",
                description="Successfully processed customer data",
                db_name="PROD_CRM",
                record_count=15000,
                custom_attributes={
                    "processing_time_ms": 2500,
                    "validation_errors": 0,
                    "data_quality_score": 0.98
                }
            )

            # Log a failure
            step_id = logger.log_step(
                status="FAILED",
                description="Connection timeout to source database",
                custom_attributes={
                    "error_code": "TIMEOUT",
                    "retry_count": 3,
                    "last_error": "Connection timed out after 30s"
                }
            )
            ```

        Note:
            - Must be preceded by a call to start_step()
            - Automatically calculates duration from start_step() timestamp
            - Resets step tracking, so start_step() must be called again for next step
            - Database transaction is committed automatically
        """
        if not self.current_step_name or not self.current_step_start:
            raise ValueError("No step is currently started. Call start_step() first.")

        # Validate status
        if status.upper() not in ["SUCCESS", "FAILED"]:
            raise ValueError(
                f"Invalid status '{status}'. Must be 'SUCCESS' or 'FAILED'"
            )

        status = status.upper()

        # Calculate duration
        end_time = datetime.now()
        duration_seconds = int((end_time - self.current_step_start).total_seconds())

        # Build step description with required fields (using current step_number)
        step_desc = {
            "MessageType": "SUCCESS" if status == "SUCCESS" else "ERROR",
            "StepNumber": self.step_number,
            "Operation": self.operation,
            "Description": description or f"Step {self.current_step_name} completed",
        }

        # Add custom attributes from start_step if they exist
        if self.current_step_custom_attributes:
            step_desc.update(self.current_step_custom_attributes)

        # Add custom attributes from log_step if provided (these take precedence)
        if custom_attributes:
            step_desc.update(custom_attributes)

        # Increment step number after using it in description
        self.step_number += 1

        # Log to database
        step_id = self._insert_step_log(
            {
                "Parent_Log_Id": self.parent_step_log_id,
                "Process_Name": self.process_name,
                "Process_Type": self.process_type,
                "Step_Name": self.current_step_name,
                "Step_Desc": step_desc,  # Pass dict directly for VARIANT column
                "Step_Status": status,
                "Start_Dtm": self.current_step_start,
                "Duration_In_Seconds": duration_seconds,
                "Db_Name": db_name,
                "Record_Count": record_count,
                "ETL_Execution_Id": self.etl_execution_id,
            }
        )

        log_to_console(
            __name__,
            "Info",
            f"Logged step: {self.current_step_name} ({status}) - Duration: {duration_seconds}s - ID: {step_id}",
        )

        # Update totals (step number was already incremented above)
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
        Log process completion and close the database connection.

        This method finalizes the process by logging an END record with summary totals,
        closing the database connection, and performing cleanup. It should always be called
        when the process is complete, preferably in a try/finally block to ensure cleanup
        even if errors occur.

        Args:
            custom_attributes (Dict[str, Any], optional): Additional metadata to include in
                                                         the process completion log. These will
                                                         be merged into the completion step
                                                         description JSON alongside the standard
                                                         completion information.

        Side Effects:
            - Increments step_number for the final END record
            - Logs an END record to DATA_HUB.STEP_LOG table with:
                * Step_Status = "END"
                * Step_Name = "{process_name}_END"
                * Duration_In_Seconds = total accumulated duration from all steps
                * Record_Count = total accumulated record count from all steps
            - Closes the database connection (self.db_connection)
            - Logs completion summary to console
            - Handles any errors gracefully and logs them

        Error Handling:
            If logging the process completion fails, the error is logged to console
            but the database connection is still closed in the finally block.
            This ensures cleanup occurs even if the final log write fails.

        Step Description JSON Structure:
            The completion record includes a standardized JSON structure:
            ```json
            {
                "MessageType": "INFO",
                "StepNumber": <final_step_number>,
                "Operation": "Process Completion",
                "Description": "Process {process_name} completed",
                ...custom_attributes
            }
            ```

        Example:
            ```python
            try:
                logger = StepLogger(...)

                # ... process steps ...

            finally:
                # Always close, even if errors occurred
                logger.close(custom_attributes={
                    "final_status": "success",
                    "total_files_processed": 25,
                    "completion_time": datetime.now().isoformat(),
                    "environment": "production"
                })
            ```

        Note:
            - Should always be called when done with the logger
            - Safe to call multiple times (subsequent calls are no-ops)
            - Automatically includes TOTAL_DURATION and TOTAL_COUNT in the log
            - Connection cleanup is guaranteed even if logging fails
        """
        try:
            # Build completion description with required fields (using current step_number)
            completion_desc = {
                "MessageType": "INFO",
                "StepNumber": self.step_number,
                "Operation": "Process Completion",
                "Description": f"Process {self.process_name} completed",
            }

            # Add custom attributes if provided
            if custom_attributes:
                completion_desc.update(custom_attributes)

            # Increment step number after using it in description
            self.step_number += 1

            completion_id = self._insert_step_log(
                {
                    "Parent_Log_Id": self.parent_step_log_id,
                    "Process_Name": self.process_name,
                    "Process_Type": self.process_type,
                    "Step_Name": f"{self.process_name}_END",
                    "Step_Desc": completion_desc,  # Pass dict directly for VARIANT column
                    "Step_Status": StepStatus.END.value,
                    "Start_Dtm": datetime.now(),
                    "Duration_In_Seconds": self.TOTAL_DURATION,
                    "Db_Name": None,
                    "Record_Count": self.TOTAL_COUNT,
                    "ETL_Execution_Id": self.etl_execution_id,
                }
            )

            log_to_console(
                __name__,
                "Info",
                f"Process completion logged - Total Duration: {self.TOTAL_DURATION}s - \
                    Total Count: {self.TOTAL_COUNT} - ID: {completion_id}",
            )

        except Exception as e:
            log_to_console(__name__, "Error", f"Failed to log process completion: {e}")

        finally:
            # Close database connection
            if self.db_connection:
                self.db_connection.close()
                log_to_console(
                    __name__, "Info", "StepLogger closed - Database connection closed"
                )

    def _get_connection(self):
        """
        Establish and return a Snowflake database connection.

        Uses the eimutils.utils.get_snowflake_connection_from_secret utility to create
        a connection to the Snowflake database using AWS Secrets Manager for authentication.

        Returns:
            Connection: Active Snowflake database connection object

        Raises:
            Exception: If database connection cannot be established

        Note:
            This is a private method used internally during initialization.
        """
        try:
            conn = get_snowflake_connection_from_secret(
                secret_arn=self.secret_key,
                env=self.env,
                aws_region=self.aws_region,
                envlayer="RAW",
                brand="",
                project="",
                database=self.database,
                spark_session=False,
            )
            if isinstance(conn, dict):
                raise ConnectionError(f"get_snowflake_connection_from_secret failed: {conn}")
            # Set database and schema context for SEQ__STEP_LOG_ID.NEXTVAL
            cur = conn.cursor()
            cur.execute(f"USE DATABASE {self.database}")
            cur.execute("USE SCHEMA DATA_HUB")
            cur.close()
            log_to_console(
                __name__, "Info",
                f"Connection established. Context: {self.database}.DATA_HUB"
            )
            return conn
        except Exception as e:
            log_to_console(
                __name__, "Error", f"Failed to establish database connection: {e}"
            )
            raise

    def _get_next_step_log_id(self) -> int:
        """
        Retrieve the next Step_Log_Id from SEQ__STEP_LOG_ID.NEXTVAL.

        Requires USE DATABASE and USE SCHEMA DATA_HUB to be set on the connection
        (done in _get_connection).

        Returns:
            int: The next sequence value

        Raises:
            Exception: If the sequence is not accessible or the query fails
        """
        try:
            cursor = self.db_connection.cursor()
            cursor.execute("SELECT SEQ__STEP_LOG_ID.NEXTVAL")
            next_id = cursor.fetchone()[0]
            cursor.close()
            log_to_console(
                __name__, "Info", f"Next Step_Log_Id (NEXTVAL): {next_id}"
            )
            return next_id
        except Exception as e:
            log_to_console(__name__, "Error", f"Failed to get next Step_Log_Id: {e}")
            raise

    def _log_process_start(
        self, process_description: str, custom_attributes: Dict[str, Any] = None
    ) -> int:
        """
        Log the initial process start record and return its Step_Log_Id.

        This private method creates the initial START record that serves as the parent
        for all subsequent step logs in the hierarchy. The returned Step_Log_Id becomes
        the Parent_Log_Id for all regular step logs.

        Args:
            process_description (str): Description of the overall process
            custom_attributes (Dict[str, Any], optional): Custom metadata for the start record

        Returns:
            int: Step_Log_Id of the inserted START record, used as parent_step_log_id

        Raises:
            Exception: If the database insert operation fails

        Side Effects:
            - Inserts START record into DATA_HUB.STEP_LOG table
            - Uses process_start_time as the Start_Dtm
            - Sets Duration_In_Seconds to 0 (will be updated in close())
            - Logs operation to console

        Note:
            This is a private method called automatically during __init__().
        """
        try:
            # Build start description with required fields (using current step_number = 0)
            start_desc = {
                "MessageType": "INFO",
                "StepNumber": self.step_number,
                "Operation": "Process Start",
                "Description": process_description
                or f"Started {self.process_name} process",
            }

            # Add custom attributes if provided
            if custom_attributes:
                start_desc.update(custom_attributes)

            # Increment step number after using it in description
            self.step_number += 1

            # Insert START record and capture its Step_Log_Id
            start_step_log_id = self._insert_step_log(
                {
                    "Parent_Log_Id": self.parent_step_log_id,  # -1 for root process
                    "Process_Name": self.process_name,
                    "Process_Type": self.process_type,
                    "Step_Name": f"{self.process_name}_START",
                    "Step_Desc": start_desc,  # Pass dict directly for VARIANT column
                    "Step_Status": StepStatus.START.value,
                    "Start_Dtm": self.process_start_time,
                    "Duration_In_Seconds": 0,
                    "Db_Name": None,
                    "Record_Count": None,
                    "ETL_Execution_Id": self.etl_execution_id,
                }
            )

            log_to_console(
                __name__,
                "Info",
                f"Process start logged with Step_Log_Id: {start_step_log_id} \
                    (will become parent_step_log_id for subsequent steps)",
            )

            return start_step_log_id

        except Exception as e:
            log_to_console(__name__, "Error", f"Failed to log process start: {e}")
            raise

    def _insert_step_log(self, step_data: Dict[str, Any]) -> Optional[int]:
        """
        Insert a new step log record into the DATA_HUB.STEP_LOG table.

        This private method handles the actual database insertion for all step log records,
        including process START, regular steps, and process END records. It explicitly
        manages sequence ID generation to ensure predictable Step_Log_Id values.

        Args:
            step_data (Dict[str, Any]): Dictionary containing all column values for the step log.
                                      Must include all required fields for the STEP_LOG table:
                                      - Parent_Log_Id
                                      - Process_Name
                                      - Process_Type
                                      - Step_Name
                                      - Step_Desc (VARIANT - stored as JSON)
                                      - Step_Status
                                      - Start_Dtm
                                      - Duration_In_Seconds
                                      - ETL_Execution_Id
                                      Optional fields: Db_Name, Record_Count

        Returns:
            Optional[int]: Step_Log_Id of the inserted record, or None if insertion failed

        Raises:
            Exception: If sequence retrieval or database insert fails

        Side Effects:
            - Retrieves next value from DATA_HUB.SEQ__STEP_LOG_ID sequence
            - Inserts record into DATA_HUB.STEP_LOG table with explicit Step_Log_Id
            - Commits the database transaction
            - Rolls back transaction if insertion fails
            - Logs all operations to console

        Implementation Details:
            - Explicitly retrieves sequence value rather than using table default
            - Ensures Step_Log_Id is the first column in INSERT for consistency
            - Builds parameterized query to prevent SQL injection
            - Handles transaction management with commit/rollback

        Note:
            This is a private method used by _log_process_start, log_step, and close methods.
        """
        try:
            # Get next Step_Log_Id from SEQ__STEP_LOG_ID.NEXTVAL
            step_log_id = self._get_next_step_log_id()
            cursor = self.db_connection.cursor()

            log_to_console(
                __name__,
                "Info",
                f"Retrieved sequence value for Step_Log_Id: {step_log_id}",
            )

            # CRITICAL: Explicitly add Step_Log_Id as the first column to ensure it's not using table default
            # Remove Step_Log_Id if it somehow exists in step_data already
            if "Step_Log_Id" in step_data:
                del step_data["Step_Log_Id"]

            # Create ordered dictionary with Step_Log_Id first to be explicit
            ordered_step_data = {"Step_Log_Id": step_log_id}
            ordered_step_data.update(step_data)

            # Handle Step_Desc for VARIANT column
            # Convert dict to JSON string - we'll use TO_VARIANT(PARSE_JSON(%s)) in SQL
            if "Step_Desc" in ordered_step_data and isinstance(
                ordered_step_data["Step_Desc"], dict
            ):
                ordered_step_data["Step_Desc"] = json.dumps(
                    ordered_step_data["Step_Desc"]
                )

            # Build INSERT statement with explicit column order (Step_Log_Id first)
            columns = list(ordered_step_data.keys())
            values = list(ordered_step_data.values())

            # Build SELECT statement for INSERT - this allows PARSE_JSON to work properly
            # PARSE_JSON cannot be used directly in VALUES clause with parameters
            select_items = []
            for col in columns:
                if col == "Step_Desc":
                    # Use PARSE_JSON in SELECT clause which supports it
                    select_items.append("PARSE_JSON(%s)")
                else:
                    select_items.append("%s")

            select_str = ", ".join(select_items)
            column_list = ", ".join(columns)

            # Use INSERT INTO ... SELECT instead of INSERT INTO ... VALUES
            query = f"INSERT INTO {self.database}.DATA_HUB.STEP_LOG ({column_list}) SELECT {select_str}"

            log_to_console(
                __name__, "Info", f"Inserting with explicit Step_Log_Id: {step_log_id}"
            )
            log_to_console(
                __name__, "Info", f"Column order: {columns[:3]}..."
            )  # Show first 3 columns
            log_to_console(
                __name__,
                "Debug",
                f"Step_Desc type: {type(ordered_step_data.get('Step_Desc'))}",
            )

            cursor.execute(query, values)

            # Commit and close
            self.db_connection.commit()
            cursor.close()

            log_to_console(
                __name__,
                "Info",
                f"Successfully inserted step log with explicit Step_Log_Id: {step_log_id}",
            )

            return step_log_id

        except Exception as e:
            log_to_console(__name__, "Error", f"Failed to insert step log: {e}")
            if self.db_connection:
                self.db_connection.rollback()
            return None


"""
***********************************************************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
ffortunato  2025-01-29  Rewritten as simple 4-method StepLogger (init, start_step, log_step, close)
ffortunato  2025-01-29  Simple timing between start_step and log_step with parent-child hierarchy
ffortunato  2025-01-29  Added TOTAL_DURATION, TOTAL_COUNT tracking and custom_attributes support
ffortunato  2025-01-29  Standardized step descriptions: MessageType, StepNumber, Operation, Description + custom
ffortunato  2025-01-29  Enhanced _insert_step_log to explicitly use sequence value, not table default
ffortunato  2025-08-20  Fixed initialization to only call NEXTVAL once (for START record),
                        parent_step_log_id = -1 initially
ffortunato  2025-10-13  o Steplog.step_desc to variant
***********************************************************************************************************************
"""
