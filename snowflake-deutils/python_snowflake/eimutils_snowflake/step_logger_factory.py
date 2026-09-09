"""
***********************************************************************************************************************
File: step_logger_factory.py

Purpose: Factory pattern for automatic StepLogger environment detection and instantiation.

This factory automatically detects whether code is running in:
- Snowflake (Snowpark environment) → Returns StepLoggerSnowflake
- AWS Glue / External → Returns StepLogger (traditional)

This allows the same code to work in multiple environments without modification.

Example:
    ```python
    from step_logger_factory import get_step_logger
    import uuid

    # Automatically detects environment and returns appropriate logger
    logger = get_step_logger(
        etl_execution_id=str(uuid.uuid4()),
        process_name="Multi_Environment_Process",
        process_description="Works in Snowflake or AWS Glue"
    )

    try:
        logger.start_step("data_processing")
        # ... processing logic ...
        logger.log_step("SUCCESS", record_count=1000)
    finally:
        logger.close()
    ```

***********************************************************************************************************************
"""

from typing import Dict, Any
import sys


def detect_environment() -> str:
    """
    Detect the current execution environment.

    Returns:
        str: 'snowflake' or 'glue'
    """
    # Check for Snowpark session
    try:
        from snowflake.snowpark.context import get_active_session
        session = get_active_session()
        if session is not None:
            return 'snowflake'
    except Exception:
        pass

    # Check for AWS Glue environment variables
    if 'AWS_EXECUTION_ENV' in sys.modules or 'awsglue' in sys.modules:
        return 'glue'

    # Check for AWS environment variables
    import os
    if os.environ.get('AWS_EXECUTION_ENV') or os.environ.get('GLUE_VERSION'):
        return 'glue'

    # Default to glue (external) for backward compatibility
    return 'glue'


def get_step_logger(
    etl_execution_id: str,
    process_name: str,
    process_type: str = "ETL",
    process_description: str = None,
    env_type: str = "auto",
    custom_attributes: Dict[str, Any] = None,
    # Snowflake-specific parameters
    session=None,
    database: str = None,
    schema: str = "DATA_HUB",
    # AWS Glue-specific parameters
    secret_key: str = None,
    env: str = None,
    **kwargs
):
    """
    Factory function to get the appropriate StepLogger for the current environment.

    This function automatically detects whether you're running in Snowflake or AWS Glue
    and returns the appropriate logger implementation.

    Args:
        etl_execution_id (str): Unique identifier for the ETL execution
        process_name (str): Name of the process being logged
        process_type (str, optional): Type of process. Defaults to 'ETL'
        process_description (str, optional): Description of the process
        env_type (str, optional): Force environment type ('auto', 'snowflake', 'glue').
                                  Defaults to 'auto' for automatic detection
        custom_attributes (Dict[str, Any], optional): Additional metadata

        # Snowflake-specific (only used if env_type='snowflake' or auto-detected):
        session: Snowpark Session (optional, auto-detected if None)
        database (str, optional): Database name (optional, auto-detected if None)
        schema (str, optional): Schema name. Defaults to 'DATA_HUB'

        # AWS Glue-specific (only used if env_type='glue' or auto-detected):
        secret_key (str, optional): AWS Secrets Manager ARN
        env (str, optional): Environment (DEV, STAGE, PROD)

    Returns:
        Union[StepLoggerSnowflake, StepLogger]: Appropriate logger instance

    Raises:
        ImportError: If required dependencies are not available
        RuntimeError: If environment cannot be determined or configured

    Example:
        ```python
        # Automatic detection - works in any environment
        logger = get_step_logger(
            etl_execution_id=str(uuid.uuid4()),
            process_name="My_Process"
        )

        # Force Snowflake
        logger = get_step_logger(
            etl_execution_id=str(uuid.uuid4()),
            process_name="My_Process",
            env_type="snowflake"
        )

        # Force AWS Glue
        logger = get_step_logger(
            etl_execution_id=str(uuid.uuid4()),
            process_name="My_Process",
            env_type="glue",
            secret_key="arn:aws:secretsmanager:...",
            env="DEV"
        )
        ```
    """
    # Determine environment
    if env_type == "auto":
        env_type = detect_environment()

    print(f"StepLogger Factory: Detected environment = {env_type}")

    # Return appropriate logger based on environment
    if env_type == "snowflake":
        return _get_snowflake_logger(
            etl_execution_id=etl_execution_id,
            process_name=process_name,
            process_type=process_type,
            process_description=process_description,
            session=session,
            database=database,
            schema=schema,
            custom_attributes=custom_attributes,
            **kwargs
        )
    elif env_type == "glue":
        return _get_glue_logger(
            etl_execution_id=etl_execution_id,
            process_name=process_name,
            process_type=process_type,
            process_description=process_description,
            secret_key=secret_key,
            env=env,
            custom_attributes=custom_attributes,
            **kwargs
        )
    else:
        raise ValueError(
            f"Unknown environment type: {env_type}. Must be 'auto', 'snowflake', or 'glue'"
        )


def _get_snowflake_logger(
    etl_execution_id: str,
    process_name: str,
    process_type: str,
    process_description: str,
    session,
    database: str,
    schema: str,
    custom_attributes: Dict[str, Any],
    **kwargs
):
    """
    Get StepLoggerSnowflake instance.

    Args:
        See get_step_logger() for parameter descriptions

    Returns:
        StepLoggerSnowflake: Snowflake-native logger instance

    Raises:
        ImportError: If Snowpark is not available
    """
    try:
        from step_logger_snowflake import StepLoggerSnowflake
    except ImportError:
        try:
            from eimutils_snowflake.step_logger_snowflake import StepLoggerSnowflake
        except ImportError:
            raise ImportError(
                "StepLoggerSnowflake not found. "
                "Ensure step_logger_snowflake.py is available."
            )

    print("Initializing StepLoggerSnowflake...")

    return StepLoggerSnowflake(
        etl_execution_id=etl_execution_id,
        process_name=process_name,
        process_type=process_type,
        process_description=process_description,
        session=session,
        database=database,
        schema=schema,
        custom_attributes=custom_attributes,
    )


def _get_glue_logger(
    etl_execution_id: str,
    process_name: str,
    process_type: str,
    process_description: str,
    secret_key: str,
    env: str,
    custom_attributes: Dict[str, Any],
    **kwargs
):
    """
    Get StepLogger instance (AWS Glue version).

    Args:
        See get_step_logger() for parameter descriptions

    Returns:
        StepLogger: AWS Glue-compatible logger instance

    Raises:
        ImportError: If eimutils is not available
        ValueError: If required parameters are missing
    """
    try:
        from eimutils.step_logger import StepLogger
    except ImportError:
        try:
            import sys
            import os
            # Try to add parent directory to path
            parent_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
            sys.path.insert(0, parent_dir)
            from python.eimutils.step_logger import StepLogger
        except ImportError:
            raise ImportError(
                "StepLogger not found. "
                "Ensure eimutils package is installed or available."
            )

    # Validate required parameters for Glue
    if not secret_key:
        raise ValueError(
            "secret_key is required for AWS Glue environment. "
            "Provide the AWS Secrets Manager ARN."
        )
    if not env:
        raise ValueError(
            "env is required for AWS Glue environment. "
            "Provide environment (DEV, STAGE, PROD)."
        )

    print("Initializing StepLogger (AWS Glue)...")

    return StepLogger(
        secret_key=secret_key,
        env=env,
        etl_execution_id=etl_execution_id,
        process_name=process_name,
        process_type=process_type,
        process_description=process_description,
        custom_attributes=custom_attributes,
    )


def get_logger_info() -> Dict[str, Any]:
    """
    Get information about available logger implementations.

    Returns:
        Dict[str, Any]: Dictionary with logger availability information
    """
    info = {
        "detected_environment": detect_environment(),
        "snowflake_available": False,
        "glue_available": False,
        "snowpark_version": None,
        "eimutils_version": None,
    }

    # Check Snowflake availability
    try:
        # from snowflake.snowpark import Session
        import snowflake.snowpark as snowpark
        info["snowflake_available"] = True
        info["snowpark_version"] = getattr(snowpark, '__version__', 'unknown')
    except ImportError:
        pass

    # Check Glue/eimutils availability
    try:
        from eimutils import __version__
        info["glue_available"] = True
        info["eimutils_version"] = __version__
    except ImportError:
        pass

    return info


"""
***********************************************************************************************************************
Change History:

Author      Date        Description
----------  ----------  -------------------------------------------------------
ffortunato  2025-10-13  Created factory pattern for multi-environment support
ffortunato  2025-10-13  Added automatic environment detection
ffortunato  2025-10-13  Implemented Snowflake and Glue logger selection
***********************************************************************************************************************
"""
