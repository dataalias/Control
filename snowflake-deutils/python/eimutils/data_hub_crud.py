"""
*******************************************************************************
File: data_hub_crud.py

Purpose: Generic CRUD operations class for DataHub management operations.

This module provides database connectivity and basic CRUD operations for all DataHub tables.

Dependencies/Helpful Notes :

*******************************************************************************
"""

from eimutils.delogging import log_to_console
import pandas as pd
from eimutils.utils import get_snowflake_connection_from_secret


class DataHubCRUD:
    """
    Generic CRUD operations class for DataHub management operations.
    This class provides database connectivity and basic CRUD operations for all DataHub tables.
    """

    def __init__(self):
        """Initialize DataHubCRUD with empty connection"""
        self.connection = None

    def initialize(
        self,
        secret_arn: str,
        env: str,
        aws_region: str = "MY_AWS_REGION",
        envlayer: str = "",
        brand: str = "",
        project: str = "",
        database: str = "MY_ORG_DEV_RAW",
    ):
        """
        Initialize database connection using AWS Secrets Manager

        Args:
            secret_arn: AWS Secrets Manager ARN for database credentials
            env: Environment (DEV, STAGE, PROD)
            aws_region: AWS region for secrets manager
            envlayer: Snowflake environment layer (e.g. RAW)
            brand: Brand segment (e.g. MY_ORG)
            project: Project segment (e.g. CARE)
            database: Snowflake database name

        Returns:
            Connection object or error dict
        """
        try:
            self.connection = get_snowflake_connection_from_secret(
                secret_arn=secret_arn,
                env=env,
                aws_region=aws_region,
                envlayer=envlayer,
                brand=brand,
                project=project,
                database=database,
            )

            if isinstance(self.connection, dict):
                raise ConnectionError(f"get_snowflake_connection_from_secret failed: {self.connection}")

            cursor = self.connection.cursor()
            cursor.execute("USE SCHEMA DATA_HUB")
            cursor.close()

            return self.connection
        except Exception as e:
            self.connection = None
            log_to_console(__name__, "Error", f"Failed to initialize connection: {str(e)}")
            raise

    def execute_query(self, query: str, params=None) -> pd.DataFrame:
        """
        Execute a SELECT query and return results as DataFrame

        Args:
            query: SQL SELECT query
            params: Query parameters (tuple or None)

        Returns:
            pandas DataFrame with query results
        """
        if not self.connection:
            raise Exception("Database connection not initialized")

        try:
            cursor = self.connection.cursor()
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)

            # Fetch results and column names
            results = cursor.fetchall()
            column_names = [desc[0] for desc in cursor.description]

            # Convert to DataFrame
            df = pd.DataFrame(results, columns=column_names)
            cursor.close()

            return df
        except Exception as e:
            if "cursor" in locals():
                cursor.close()
            raise e

    def execute_command(self, query: str, params=None) -> int:
        """
        Execute an INSERT/UPDATE/DELETE command

        Args:
            query: SQL command (INSERT/UPDATE/DELETE)
            params: Query parameters (tuple or None)

        Returns:
            Number of affected rows
        """
        if not self.connection:
            raise Exception("Database connection not initialized")

        try:
            cursor = self.connection.cursor()
            if params:
                result = cursor.execute(query, params)
            else:
                result = cursor.execute(query)

            rows_affected = cursor.rowcount
            self.connection.commit()
            cursor.close()

            return rows_affected
        except Exception as e:
            self.connection.rollback()
            if "cursor" in locals():
                cursor.close()
            raise e

    def get_publishers(self) -> list:
        """Get all publishers"""
        try:
            df = self.execute_query(
                "SELECT * FROM DATA_HUB.Publisher ORDER BY PublisherCode"
            )
            return df.to_dict("records")
        except Exception:
            return []

    def get_subscribers(self) -> list:
        """Get all subscribers"""
        try:
            df = self.execute_query(
                "SELECT * FROM DATA_HUB.Subscriber ORDER BY SubscriberCode"
            )
            return df.to_dict("records")
        except Exception:
            return []

    def get_publications(self) -> list:
        """Get all publications"""
        try:
            df = self.execute_query(
                "SELECT * FROM DATA_HUB.Publication ORDER BY PublicationCode"
            )
            return df.to_dict("records")
        except Exception:
            return []

    def validate_referential_integrity(
        self, table_name: str, operation: str, data: dict
    ) -> tuple:
        """
        Validate referential integrity for CRUD operations

        Args:
            table_name: Name of the table being operated on
            operation: CREATE, UPDATE, or DELETE
            data: Data dictionary to validate

        Returns:
            Tuple of (is_valid: bool, message: str)
        """
        try:
            # Basic validation - check for duplicate keys
            if operation == "CREATE" and table_name == "Publisher":
                if "PublisherCode" in data:
                    existing = self.execute_query(
                        "SELECT COUNT(*) FROM DATA_HUB.Publisher WHERE PublisherCode = %s",
                        (data["PublisherCode"],),
                    )
                    if not existing.empty and existing.iloc[0, 0] > 0:
                        return (
                            False,
                            f"Publisher with code '{data['PublisherCode']}' already exists",
                        )

            return True, "Validation passed"
        except Exception as e:
            return False, f"Validation error: {str(e)}"

    def log_activity(self, activity_name: str, details: dict, status):
        """
        Log activity for audit trail

        Args:
            activity_name: Name of the activity
            details: Activity details dictionary
            status: Activity status
        """
        try:
            # This would integrate with StepLogger if available
            log_to_console(__name__, "Info", f"{activity_name}: {details}")
        except Exception:
            pass  # Don't fail operations if logging fails


"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
ffortunato  2025-01-27  Moved DataHubCRUD class from data_hub_connection.py to dedicated file
*******************************************************************************
"""
