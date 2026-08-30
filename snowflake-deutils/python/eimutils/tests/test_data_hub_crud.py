"""
Integration tests for the DataHubCRUD class.

Validates database connectivity, query execution, list retrieval,
referential integrity checks, and error handling against the live
Snowflake dev environment.

Requires AWS credentials and access to the Snowflake dev environment.
"""

import os
import unittest
from eimutils.data_hub_crud import DataHubCRUD
from eimutils.delogging import log_to_console


def setUpModule():
    print("\n" + "=" * 70)
    print("  RUNNING: test_data_hub_crud.py")
    print("=" * 70)


class DataHubCRUDIntegrationTest(unittest.TestCase):

    crud = None

    @classmethod
    def setUpClass(cls):
        os.environ["ENV"] = "dev"
        os.environ["AWS_SECRET_ARN_SF_CONN"] = (
            "arn:aws:secretsmanager:MY_AWS_REGION:MY_AWS_ACCOUNT:secret:MY_AWS_SECRET"
        )
        os.environ["AWS_REGION"] = "MY_AWS_REGION"

        try:
            cls.crud = DataHubCRUD()
            cls.crud.initialize(
                secret_arn=os.environ["AWS_SECRET_ARN_SF_CONN"],
                env=os.environ["ENV"],
                aws_region=os.environ["AWS_REGION"],
                envlayer="RAW",
                brand="MY_ORG",
                project="CARE",
                database="MY_ORG_DEV_RAW",
            )
            log_to_console(__name__, "Info", "DataHubCRUDIntegrationTest.setUpClass :: Complete.")
        except Exception as e:
            raise unittest.SkipTest(f"Skipping DataHubCRUD integration tests: credentials unavailable ({e})")

    @classmethod
    def tearDownClass(cls):
        if cls.crud and cls.crud.connection and not isinstance(cls.crud.connection, dict):
            cls.crud.connection.close()
        log_to_console(__name__, "Info", "DataHubCRUDIntegrationTest.tearDownClass :: Complete.")

    def test_010_initialize_creates_connection(self):
        self.assertIsNotNone(self.crud.connection, "Expected a live connection after initialize.")
        self.assertNotIsInstance(self.crud.connection, dict, "Expected connection object, not error dict.")

    def test_020_execute_query_returns_dataframe(self):
        df = self.crud.execute_query("SELECT CURRENT_TIMESTAMP() AS NOW")
        self.assertFalse(df.empty, "Expected non-empty DataFrame.")
        self.assertIn("NOW", df.columns)

    def test_030_get_publishers_returns_list(self):
        publishers = self.crud.get_publishers()
        self.assertIsInstance(publishers, list)

    def test_040_get_subscribers_returns_list(self):
        subscribers = self.crud.get_subscribers()
        self.assertIsInstance(subscribers, list)

    def test_050_get_publications_returns_list(self):
        publications = self.crud.get_publications()
        self.assertIsInstance(publications, list)

    def test_060_validate_integrity_duplicate(self):
        publishers = self.crud.get_publishers()
        if not publishers:
            self.skipTest("No publishers in database to test duplicate validation.")
        existing_code = publishers[0]["PUBLISHERCODE"]
        valid, msg = self.crud.validate_referential_integrity(
            "Publisher", "CREATE", {"PublisherCode": existing_code}
        )
        self.assertFalse(valid, "Expected validation to fail for a duplicate PublisherCode.")
        self.assertIn(existing_code, msg)

    def test_070_validate_integrity_new_code(self):
        valid, msg = self.crud.validate_referential_integrity(
            "Publisher", "CREATE", {"PublisherCode": "DOES_NOT_EXIST_XYZ_99999"}
        )
        self.assertTrue(valid, "Expected validation to pass for a new PublisherCode.")

    def test_080_log_activity_does_not_raise(self):
        try:
            self.crud.log_activity("test_080", {"key": "value"}, "success")
        except Exception as e:
            self.fail(f"log_activity raised unexpectedly: {e}")

    def test_090_execute_query_without_connection_raises(self):
        crud = DataHubCRUD()
        with self.assertRaises(Exception):
            crud.execute_query("SELECT 1")

    def test_100_execute_command_without_connection_raises(self):
        crud = DataHubCRUD()
        with self.assertRaises(Exception):
            crud.execute_command("SELECT 1")


"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
ffortunato  2026-04-20  Initial Iteration

*******************************************************************************
"""
