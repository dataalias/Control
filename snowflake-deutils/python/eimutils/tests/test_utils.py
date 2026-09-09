"""
Unit tests for eimutils.utils module.

Covers:
  - _validate_identifier(): valid names, SQL-injection patterns
  - duplicates_test(): DataFrame path — no dupes, dupes, missing inputs
  - get_snowflake_connection_from_secret(): user/key/role/account resolution logic
    using mocked AWS secrets and Snowflake connector
  - gspread_try_catch(): success, retry-on-first-failure, raises-on-both-failures
"""
import json
import unittest
from unittest.mock import MagicMock, patch

import pandas as pd

from eimutils.utils import _validate_identifier, duplicates_test, gspread_try_catch, snowflake_pipeline_logging
from eimutils.logger import get_logger


def setUpModule():
    print("\n" + "=" * 70)
    print("  RUNNING: test_utils.py")
    print("=" * 70)
    get_logger("eimutils.tests.test_utils")


class TestValidateIdentifier(unittest.TestCase):
    """Tests for the _validate_identifier SQL identifier guard."""

    def test_simple_name_passes(self):
        _validate_identifier("MyColumn")

    def test_snake_case_passes(self):
        _validate_identifier("my_col_1")

    def test_leading_underscore_passes(self):
        _validate_identifier("_private")

    def test_dollar_sign_passes(self):
        _validate_identifier("COL$1")

    def test_leading_digit_raises(self):
        with self.assertRaises(ValueError):
            _validate_identifier("1badname")

    def test_space_raises(self):
        with self.assertRaises(ValueError):
            _validate_identifier("bad name")

    def test_hyphen_raises(self):
        with self.assertRaises(ValueError):
            _validate_identifier("bad-name")

    def test_semicolon_injection_raises(self):
        with self.assertRaises(ValueError):
            _validate_identifier("col; DROP TABLE x")

    def test_empty_string_raises(self):
        with self.assertRaises(ValueError):
            _validate_identifier("")


class TestDuplicatesTest(unittest.TestCase):
    """Tests for duplicates_test() using in-memory DataFrames."""

    def test_no_duplicates_with_partition_returns_none(self):
        df = pd.DataFrame({"group": ["A", "B", "C"], "id": [1, 2, 3]})
        result = duplicates_test(column="id", partition="group", input=df)
        self.assertIsNone(result)

    def test_duplicates_with_partition_raises_runtime_error(self):
        df = pd.DataFrame({"group": ["A", "A", "B"], "id": [1, 1, 2]})
        with self.assertRaises(RuntimeError) as ctx:
            duplicates_test(column="id", partition="group", input=df)
        self.assertIn("Duplication", str(ctx.exception))

    def test_no_duplicates_no_partition_returns_none(self):
        df = pd.DataFrame({"id": [10, 20, 30]})
        result = duplicates_test(column="id", input=df)
        self.assertIsNone(result)

    def test_duplicates_no_partition_raises(self):
        df = pd.DataFrame({"id": [1, 1, 2]})
        with self.assertRaises(RuntimeError):
            duplicates_test(column="id", input=df)

    def test_no_input_raises_value_error(self):
        with self.assertRaises(ValueError):
            duplicates_test(column="id")

    def test_partial_snowflake_params_raises_value_error(self):
        with self.assertRaises(ValueError):
            duplicates_test(column="id", db="DB")  # missing schema, table, cursor


_BASE_SECRETS = {
    "SFSVCUSER": "test_user",
    "SFSVCPKEY": "fake_pkey",
    "SFSVCPPRS": "fake_passphrase",
    "SFACCOUNT": "EDS-myaccount",
}

_SNOWFLAKE_PATCHES = (
    patch("eimutils.utils.get_secrets"),
    patch("eimutils.utils.getDERKey", return_value=b"der"),
    patch("eimutils.utils.getPEMKey", return_value=b"pem"),
    patch("eimutils.utils.connect_database"),
)


class TestGetSnowflakeConnectionFromSecret(unittest.TestCase):
    """Tests for get_snowflake_connection_from_secret() with mocked dependencies."""

    @patch("eimutils.utils.connect_database")
    @patch("eimutils.utils.getPEMKey", return_value=b"pem")
    @patch("eimutils.utils.getDERKey", return_value=b"der")
    @patch("eimutils.utils.get_secrets")
    def test_returns_connection_with_base_secret(self, mock_secrets, _der, _pem, mock_conn):
        from eimutils.utils import get_snowflake_connection_from_secret
        mock_secrets.return_value = json.dumps(_BASE_SECRETS)
        mock_conn.return_value = MagicMock(name="conn")
        conn = get_snowflake_connection_from_secret("arn:fake", "DEV", "us-west-2")
        self.assertIsNotNone(conn)

    @patch("eimutils.utils.connect_database")
    @patch("eimutils.utils.getPEMKey", return_value=b"pem")
    @patch("eimutils.utils.getDERKey", return_value=b"der")
    @patch("eimutils.utils.get_secrets")
    def test_account_without_hyphen_gets_eds_prefix(self, mock_secrets, _der, _pem, mock_conn):
        from eimutils.utils import get_snowflake_connection_from_secret
        mock_secrets.return_value = json.dumps({**_BASE_SECRETS, "SFACCOUNT": "uvnv"})
        mock_conn.return_value = MagicMock()
        get_snowflake_connection_from_secret("arn:fake", "DEV", "us-west-2")
        sf_account = mock_conn.call_args[0][1]
        self.assertTrue(sf_account.startswith("EDS-"), f"Expected EDS- prefix, got {sf_account!r}")

    @patch("eimutils.utils.connect_database")
    @patch("eimutils.utils.getPEMKey", return_value=b"pem")
    @patch("eimutils.utils.getDERKey", return_value=b"der")
    @patch("eimutils.utils.get_secrets")
    def test_account_with_hyphen_is_used_as_is(self, mock_secrets, _der, _pem, mock_conn):
        from eimutils.utils import get_snowflake_connection_from_secret
        mock_secrets.return_value = json.dumps({**_BASE_SECRETS, "SFACCOUNT": "EDS-uvnv"})
        mock_conn.return_value = MagicMock()
        get_snowflake_connection_from_secret("arn:fake", "DEV", "us-west-2")
        sf_account = mock_conn.call_args[0][1]
        self.assertEqual(sf_account, "EDS-uvnv")

    @patch("eimutils.utils.connect_database")
    @patch("eimutils.utils.getPEMKey", return_value=b"pem")
    @patch("eimutils.utils.getDERKey", return_value=b"der")
    @patch("eimutils.utils.get_secrets")
    def test_composite_role_built_from_brand_and_project(self, mock_secrets, _der, _pem, mock_conn):
        from eimutils.utils import get_snowflake_connection_from_secret
        mock_secrets.return_value = json.dumps(_BASE_SECRETS)
        mock_conn.return_value = MagicMock()
        get_snowflake_connection_from_secret(
            "arn:fake", "DEV", "us-west-2",
            envlayer="RAW", brand="MY_ORG", project="CARE"
        )
        sf_role = mock_conn.call_args[0][3]
        self.assertEqual(sf_role, "MY_ORG_DEV_CARE_RAW_ADMIN")

    @patch("eimutils.utils.connect_database")
    @patch("eimutils.utils.getPEMKey", return_value=b"pem")
    @patch("eimutils.utils.getDERKey", return_value=b"der")
    @patch("eimutils.utils.get_secrets")
    def test_raises_when_no_valid_user(self, mock_secrets, _der, _pem, mock_conn):
        from eimutils.utils import get_snowflake_connection_from_secret
        mock_secrets.return_value = json.dumps(
            {"SFACCOUNT": "EDS-acct", "SFSVCPKEY": "k", "SFSVCPPRS": "p"}
        )
        with self.assertRaises(Exception) as ctx:
            get_snowflake_connection_from_secret("arn:fake", "DEV", "us-west-2")
        self.assertIn("user", str(ctx.exception).lower())

    @patch("eimutils.utils.connect_database")
    @patch("eimutils.utils.getPEMKey", return_value=b"pem")
    @patch("eimutils.utils.getDERKey", return_value=b"der")
    @patch("eimutils.utils.get_secrets")
    def test_raises_when_no_valid_key(self, mock_secrets, _der, _pem, mock_conn):
        from eimutils.utils import get_snowflake_connection_from_secret
        mock_secrets.return_value = json.dumps(
            {"SFSVCUSER": "user", "SFACCOUNT": "EDS-acct"}
        )
        with self.assertRaises(Exception) as ctx:
            get_snowflake_connection_from_secret("arn:fake", "DEV", "us-west-2")
        self.assertIn("key", str(ctx.exception).lower())

    @patch("eimutils.utils.connect_database")
    @patch("eimutils.utils.getPEMKey", return_value=b"pem")
    @patch("eimutils.utils.getDERKey", return_value=b"der")
    @patch("eimutils.utils.get_secrets")
    def test_dw30_user_key_takes_priority(self, mock_secrets, _der, _pem, mock_conn):
        from eimutils.utils import get_snowflake_connection_from_secret
        mock_secrets.return_value = json.dumps({
            "DW30SFSVCUSER": "dw30_user",
            "SFSVCUSER": "fallback_user",
            "DW30SFSVCPKEY": "pkey",
            "DW30SFSVCPPRS": "pprs",
            "SFACCOUNT": "EDS-acct",
        })
        mock_conn.return_value = MagicMock()
        get_snowflake_connection_from_secret("arn:fake", "DEV", "us-west-2")
        sf_user = mock_conn.call_args[0][0]
        self.assertEqual(sf_user, "dw30_user")


class TestGspreadTryCatch(unittest.TestCase):
    """Tests for gspread_try_catch() retry logic."""

    @patch("eimutils.utils.time.sleep")
    def test_returns_on_first_success(self, mock_sleep):
        obj = MagicMock()
        obj.my_method.return_value = "result"
        result = gspread_try_catch(obj, "my_method", "arg1")
        self.assertEqual(result, "result")
        mock_sleep.assert_not_called()

    @patch("eimutils.utils.time.sleep")
    def test_retries_after_first_failure(self, mock_sleep):
        obj = MagicMock()
        obj.my_method.side_effect = [RuntimeError("first fail"), "retry_result"]
        result = gspread_try_catch(obj, "my_method")
        self.assertEqual(result, "retry_result")
        mock_sleep.assert_called_once_with(20)

    @patch("eimutils.utils.time.sleep")
    def test_raises_after_two_failures(self, mock_sleep):
        obj = MagicMock()
        obj.my_method.side_effect = [RuntimeError("fail1"), ValueError("fail2")]
        with self.assertRaises(ValueError):
            gspread_try_catch(obj, "my_method")

    @patch("eimutils.utils.time.sleep")
    def test_passes_args_and_kwargs(self, mock_sleep):
        obj = MagicMock()
        obj.my_method.return_value = 42
        result = gspread_try_catch(obj, "my_method", "pos_arg", kw="val")
        obj.my_method.assert_called_with("pos_arg", kw="val")
        self.assertEqual(result, 42)


_SPL_DEFAULTS = dict(
    env="DEV",
    job_name="test_job",
    job_status="SUCCESS",
    job_details="ok",
    job_id="run-123",
)


class TestSnowflakePipelineLoggingSQL(unittest.TestCase):
    """Validate the SQL generated by snowflake_pipeline_logging without a real DB."""

    def _capture_sql(self, **kwargs):
        """Return the SQL string passed to cursor.execute()."""
        mock_cur = MagicMock()
        mock_con = MagicMock()
        mock_con.cursor.return_value = mock_cur
        with patch("eimutils.utils.get_snowflake_connection_from_secret", return_value=mock_con):
            snowflake_pipeline_logging(**{**_SPL_DEFAULTS, **kwargs})
        return mock_cur.execute.call_args[0][0]

    def test_single_value_no_double_parens(self):
        sql = self._capture_sql(source_location="s3://x", table_name="T", row_count=10)
        self.assertIn("VALUES", sql)
        self.assertNotIn("((", sql)

    def test_single_value_contains_row_count(self):
        sql = self._capture_sql(source_location="s3://x", table_name="T", row_count=42)
        self.assertIn("42", sql)

    def test_multi_value_no_double_parens(self):
        sql = self._capture_sql(
            source_location=["s3://a", "s3://b"],
            table_name=["TABLE_A", "TABLE_B"],
            row_count=[10, 20],
        )
        self.assertIn("VALUES", sql)
        self.assertNotIn("((", sql)

    def test_multi_value_both_rows_present(self):
        sql = self._capture_sql(
            source_location=["s3://a", "s3://b"],
            table_name=["TABLE_A", "TABLE_B"],
            row_count=[10, 20],
        )
        self.assertIn("10", sql)
        self.assertIn("20", sql)

    def test_empty_lists_generates_valid_sql(self):
        sql = self._capture_sql(source_location=[], table_name=[], row_count=[])
        self.assertIn("VALUES", sql)
        self.assertNotIn("((", sql)

    def test_unknown_env_raises_value_error(self):
        with self.assertRaises(ValueError, msg="Should reject unsupported env"):
            snowflake_pipeline_logging(
                env="QA", job_name="j", job_status="SUCCESS",
                job_details="", source_location="", table_name="", row_count=0, job_id="x",
            )

    def test_non_int_row_count_single_raises(self):
        """row_count that can't be cast to int must raise before touching SQL."""
        mock_cur = MagicMock()
        mock_con = MagicMock()
        mock_con.cursor.return_value = mock_cur
        with patch("eimutils.utils.get_snowflake_connection_from_secret", return_value=mock_con):
            with self.assertRaises((ValueError, TypeError)):
                snowflake_pipeline_logging(
                    **{**_SPL_DEFAULTS,
                       "source_location": "s3://x", "table_name": "T", "row_count": "not_int"}
                )

    def test_sql_injection_in_row_count_list_raises(self):
        """A non-integer in the list row_count must raise, not reach the DB."""
        mock_cur = MagicMock()
        mock_con = MagicMock()
        mock_con.cursor.return_value = mock_cur
        with patch("eimutils.utils.get_snowflake_connection_from_secret", return_value=mock_con):
            with self.assertRaises((ValueError, TypeError)):
                snowflake_pipeline_logging(
                    **{**_SPL_DEFAULTS,
                       "source_location": ["s3://x"],
                       "table_name": ["T"],
                       "row_count": ["1); DROP TABLE ISSUE; --"]}
                )

    def test_single_quotes_in_job_name_are_escaped(self):
        sql = self._capture_sql(
            source_location="s3://x", table_name="T", row_count=0,
            job_name="O'Brien_job",
        )
        self.assertNotIn("O'Brien", sql)
        self.assertIn("O''Brien", sql)


if __name__ == "__main__":
    unittest.main()
