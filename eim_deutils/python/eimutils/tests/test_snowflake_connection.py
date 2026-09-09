"""
Unit tests for snowflake_connection.py.

Covers:
  - connect_database(): with database+role, without database, connection error handling
"""
import unittest
from unittest.mock import MagicMock, patch

import snowflake.connector as sfc

from eimutils.snowflake_connection import connect_database
from eimutils.logger import get_logger


def setUpModule():
    print("\n" + "=" * 70)
    print("  RUNNING: test_snowflake_connection.py")
    print("=" * 70)
    get_logger("eimutils.tests.test_snowflake_connection")


class TestConnectDatabase(unittest.TestCase):
    """Unit tests for connect_database() with mocked sfc.connect."""

    @patch("eimutils.snowflake_connection.sfc.connect")
    def test_connect_with_database_and_role(self, mock_connect):
        mock_connect.return_value = MagicMock(name="conn")
        conn = connect_database("myuser", "EDS-acct", b"der_key", "MY_ROLE", "MY_DB")
        mock_connect.assert_called_once_with(
            user="myuser",
            account="EDS-acct",
            private_key=b"der_key",
            role="MY_ROLE",
            database="MY_DB",
        )
        self.assertIsNotNone(conn)

    @patch("eimutils.snowflake_connection.sfc.connect")
    def test_connect_without_database_omits_db_and_role(self, mock_connect):
        mock_connect.return_value = MagicMock(name="conn")
        connect_database("myuser", "EDS-acct", b"der_key")
        mock_connect.assert_called_once_with(
            user="myuser",
            account="EDS-acct",
            private_key=b"der_key",
        )

    @patch("eimutils.snowflake_connection.sfc.connect")
    def test_returns_connection_object(self, mock_connect):
        expected_conn = MagicMock(name="real_conn")
        mock_connect.return_value = expected_conn
        result = connect_database("u", "a", b"k", "ROLE", "DB")
        self.assertIs(result, expected_conn)

    @patch("eimutils.snowflake_connection.sfc.connect")
    def test_snowflake_error_is_propagated(self, mock_connect):
        mock_connect.side_effect = sfc.Error("connection refused")
        with self.assertRaises(sfc.Error):
            connect_database("user", "EDS-acct", b"der_key", "ROLE", "DB")

    @patch("eimutils.snowflake_connection.sfc.connect")
    def test_empty_database_uses_no_db_branch(self, mock_connect):
        mock_connect.return_value = MagicMock()
        connect_database("user", "EDS-acct", b"der_key", "ROLE", "")
        # empty string database → no-database branch
        call_kwargs = mock_connect.call_args[1]
        self.assertNotIn("database", call_kwargs)


if __name__ == "__main__":
    unittest.main()
