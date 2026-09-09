"""
EIMUtils Snowflake - Snowflake-native utilities using Snowpark

This package provides Snowflake-native implementations of common EIM utilities,
designed to run directly within Snowflake's infrastructure using Snowpark.
"""

from .step_logger_snowflake import StepLoggerSnowflake
from .step_logger_factory import get_step_logger

__version__ = "1.0.0"
__all__ = ["StepLoggerSnowflake", "get_step_logger"]

