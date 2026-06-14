"""
Integration tests for the StepLogger class.

This module provides test coverage for the StepLogger class using a real
Snowflake connection. Tests validate the full lifecycle: init, start_step,
log_step, and close against the actual DATA_HUB.STEP_LOG table.

Requires AWS credentials and access to the Snowflake dev environment.
"""

import unittest
import uuid
import os
import tracemalloc

from eimutils.step_logger import StepLogger, StepStatus
from eimutils.delogging import log_to_console


def setUpModule():
    print("\n" + "=" * 70)
    print("  RUNNING: test_step_logger.py")
    print("=" * 70)


class TestStepLogger(unittest.TestCase):
    """Integration test suite for StepLogger class."""

    @classmethod
    def setUpClass(cls):
        """Set up class-level fixtures - configure environment for Snowflake access."""
        tracemalloc.start()
        msg = "TestStepLogger.setUpClass :: Class Created."
        log_to_console(__name__, "Info", msg)

        os.environ["ENV"] = "dev"
        os.environ["AWS_SECRET_ARN_SF_CONN"] = (
            "arn:aws:secretsmanager:MY_AWS_REGION:MY_AWS_ACCOUNT:secret:MY_AWS_SECRET"
        )
        os.environ["AWS_REGION"] = "MY_AWS_REGION"

    @classmethod
    def tearDownClass(cls):
        """Tear down class-level fixtures."""
        msg = "TestStepLogger.tearDownClass :: Class Torn Down."
        log_to_console(__name__, "Info", msg)

    def test_010_init_basic(self):
        """Test basic initialization of StepLogger with a real Snowflake connection."""
        msg = "TestStepLogger.test_010_init_basic :: Starting Test."
        log_to_console(__name__, "Info", msg)

        try:
            logger = StepLogger(
                secret_key=os.environ["AWS_SECRET_ARN_SF_CONN"],
                env=os.environ["ENV"],
                etl_execution_id=str(uuid.uuid4()),
                process_name="UnitTest_Init_Basic",
                process_description="Unit test - basic initialization",
            )

            # Verify attributes are set correctly
            self.assertEqual(logger.env, os.environ["ENV"].upper())
            self.assertEqual(logger.process_name, "UnitTest_Init_Basic")
            self.assertEqual(logger.process_type, "ETL")
            self.assertEqual(logger.database, f"ULTRA_{os.environ['ENV'].upper()}_RAW")
            self.assertIsNotNone(logger.db_connection)
            self.assertIsNotNone(logger.parent_step_log_id)
            self.assertGreater(logger.parent_step_log_id, 0)

            # Verify initial state
            self.assertEqual(logger.TOTAL_DURATION, 0)
            self.assertEqual(logger.TOTAL_COUNT, 0)
            self.assertEqual(logger.step_number, 1)
            self.assertIsNone(logger.current_step_name)
            self.assertIsNone(logger.current_step_start)

            logger.close()
            msg = "TestStepLogger.test_010_init_basic :: Successful."
            log_to_console(__name__, "Info", msg)

        except Exception as err:
            msg = f"TestStepLogger.test_010_init_basic :: Failed :: {err}"
            log_to_console(__name__, "Error", msg)
            self.fail(f"Init basic test failed: {err}")

    def test_020_start_and_log_step(self):
        """Test start_step and log_step with a real Snowflake connection."""
        msg = "TestStepLogger.test_020_start_and_log_step :: Starting Test."
        log_to_console(__name__, "Info", msg)

        try:
            logger = StepLogger(
                secret_key=os.environ["AWS_SECRET_ARN_SF_CONN"],
                env=os.environ["ENV"],
                etl_execution_id=str(uuid.uuid4()),
                process_name="UnitTest_Start_Log_Step",
                process_description="Unit test - start and log step",
            )

            # Start a step
            logger.start_step(
                "extract_data",
                operation="EXTRACT",
                custom_attributes={"source": "unit_test"},
            )

            self.assertEqual(logger.current_step_name, "extract_data")
            self.assertEqual(logger.operation, "EXTRACT")
            self.assertIsNotNone(logger.current_step_start)

            # Log the step as successful
            step_id = logger.log_step(
                status="SUCCESS",
                description="Unit test extract completed",
                record_count=100,
                custom_attributes={"test_key": "test_value"},
            )

            # Verify step was logged
            self.assertIsNotNone(step_id)
            self.assertGreater(step_id, 0)

            # Verify state after logging
            self.assertEqual(logger.step_number, 2)
            self.assertEqual(logger.TOTAL_COUNT, 100)
            self.assertGreaterEqual(logger.TOTAL_DURATION, 0)
            self.assertIsNone(logger.current_step_name)
            self.assertIsNone(logger.current_step_start)

            logger.close()
            msg = "TestStepLogger.test_020_start_and_log_step :: Successful."
            log_to_console(__name__, "Info", msg)

        except Exception as err:
            msg = f"TestStepLogger.test_020_start_and_log_step :: Failed :: {err}"
            log_to_console(__name__, "Error", msg)
            self.fail(f"Start and log step test failed: {err}")

    def test_030_log_step_failed_status(self):
        """Test logging a step with FAILED status."""
        msg = "TestStepLogger.test_030_log_step_failed_status :: Starting Test."
        log_to_console(__name__, "Info", msg)

        try:
            logger = StepLogger(
                secret_key=os.environ["AWS_SECRET_ARN_SF_CONN"],
                env=os.environ["ENV"],
                etl_execution_id=str(uuid.uuid4()),
                process_name="UnitTest_Failed_Step",
                process_description="Unit test - failed step logging",
            )

            logger.start_step("failing_step")

            step_id = logger.log_step(
                status="FAILED",
                description="Step failed due to simulated error",
                custom_attributes={"error": "simulated_timeout"},
            )

            self.assertIsNotNone(step_id)
            self.assertGreater(step_id, 0)
            # FAILED step should not add to TOTAL_COUNT
            self.assertEqual(logger.TOTAL_COUNT, 0)

            logger.close()
            msg = "TestStepLogger.test_030_log_step_failed_status :: Successful."
            log_to_console(__name__, "Info", msg)

        except Exception as err:
            msg = f"TestStepLogger.test_030_log_step_failed_status :: Failed :: {err}"
            log_to_console(__name__, "Error", msg)
            self.fail(f"Failed step test failed: {err}")

    def test_040_log_step_no_active_step(self):
        """Test log_step raises error when no step is active."""
        msg = "TestStepLogger.test_040_log_step_no_active_step :: Starting Test."
        log_to_console(__name__, "Info", msg)

        try:
            logger = StepLogger(
                secret_key=os.environ["AWS_SECRET_ARN_SF_CONN"],
                env=os.environ["ENV"],
                etl_execution_id=str(uuid.uuid4()),
                process_name="UnitTest_No_Active_Step",
            )

            with self.assertRaises(ValueError) as context:
                logger.log_step()

            self.assertIn("No step is currently started", str(context.exception))

            logger.close()
            msg = "TestStepLogger.test_040_log_step_no_active_step :: Successful."
            log_to_console(__name__, "Info", msg)

        except Exception as err:
            msg = f"TestStepLogger.test_040_log_step_no_active_step :: Failed :: {err}"
            log_to_console(__name__, "Error", msg)
            self.fail(f"No active step test failed: {err}")

    def test_050_log_step_invalid_status(self):
        """Test log_step raises error for invalid status."""
        msg = "TestStepLogger.test_050_log_step_invalid_status :: Starting Test."
        log_to_console(__name__, "Info", msg)

        try:
            logger = StepLogger(
                secret_key=os.environ["AWS_SECRET_ARN_SF_CONN"],
                env=os.environ["ENV"],
                etl_execution_id=str(uuid.uuid4()),
                process_name="UnitTest_Invalid_Status",
            )

            logger.start_step("test_step")

            with self.assertRaises(ValueError) as context:
                logger.log_step(status="INVALID")

            self.assertIn("Invalid status", str(context.exception))

            logger.close()
            msg = "TestStepLogger.test_050_log_step_invalid_status :: Successful."
            log_to_console(__name__, "Info", msg)

        except Exception as err:
            msg = f"TestStepLogger.test_050_log_step_invalid_status :: Failed :: {err}"
            log_to_console(__name__, "Error", msg)
            self.fail(f"Invalid status test failed: {err}")

    def test_060_step_status_enum(self):
        """Test StepStatus enum values."""
        msg = "TestStepLogger.test_060_step_status_enum :: Starting Test."
        log_to_console(__name__, "Info", msg)

        self.assertEqual(StepStatus.START.value, "START")
        self.assertEqual(StepStatus.SUCCESS.value, "SUCCESS")
        self.assertEqual(StepStatus.FAILED.value, "FAILED")
        self.assertEqual(StepStatus.END.value, "END")

        msg = "TestStepLogger.test_060_step_status_enum :: Successful."
        log_to_console(__name__, "Info", msg)


class TestStepLoggerIntegration(unittest.TestCase):
    """Full ETL workflow integration tests for StepLogger."""

    @classmethod
    def setUpClass(cls):
        """Set up integration test fixtures."""
        tracemalloc.start()
        log_to_console(__name__, "Info", "TestStepLoggerIntegration.setUpClass :: Setup.")

        os.environ["ENV"] = "dev"
        os.environ["AWS_SECRET_ARN_SF_CONN"] = (
            "arn:aws:secretsmanager:MY_AWS_REGION:MY_AWS_ACCOUNT:secret:MY_AWS_SECRET"
        )
        os.environ["AWS_REGION"] = "MY_AWS_REGION"

    @classmethod
    def tearDownClass(cls):
        """Tear down integration test fixtures."""
        log_to_console(__name__, "Info", "TestStepLoggerIntegration.tearDownClass :: Done.")

    def test_070_complete_etl_workflow(self):
        """Test a complete ETL workflow: init -> extract -> transform -> load -> close."""
        msg = "TestStepLoggerIntegration.test_070_complete_etl_workflow :: Starting Test."
        log_to_console(__name__, "Info", msg)

        try:
            logger = StepLogger(
                secret_key=os.environ["AWS_SECRET_ARN_SF_CONN"],
                env=os.environ["ENV"],
                etl_execution_id=str(uuid.uuid4()),
                process_name="UnitTest_ETL_Workflow",
                process_description="Unit test - complete ETL workflow",
                custom_attributes={"version": "1.9.3", "environment": "test"},
            )

            # Step 1: Extract
            logger.start_step(
                "extract_source_data",
                operation="EXTRACT",
                custom_attributes={"source": "unit_test_db", "table": "customers"},
            )
            extract_step_id = logger.log_step(
                status="SUCCESS",
                description="Successfully extracted customer data",
                record_count=15000,
                custom_attributes={"extraction_method": "full"},
            )
            self.assertIsNotNone(extract_step_id)
            self.assertEqual(logger.step_number, 2)

            # Step 2: Transform
            logger.start_step(
                "transform_data",
                operation="TRANSFORM",
                custom_attributes={"rules": "business_logic_v2"},
            )
            transform_step_id = logger.log_step(
                status="SUCCESS",
                description="Data transformation completed",
                record_count=14500,
                custom_attributes={"validation_errors": 0},
            )
            self.assertIsNotNone(transform_step_id)
            self.assertEqual(logger.step_number, 3)

            # Step 3: Load
            logger.start_step(
                "load_target_data",
                operation="LOAD",
                custom_attributes={"target": "data_warehouse"},
            )
            load_step_id = logger.log_step(
                status="SUCCESS",
                description="Successfully loaded data to target",
                record_count=14500,
                custom_attributes={"load_method": "upsert"},
            )
            self.assertIsNotNone(load_step_id)
            self.assertEqual(logger.step_number, 4)

            # Close
            logger.close(
                custom_attributes={
                    "success_rate": 1.0,
                    "data_quality_passed": True,
                }
            )

            # Verify final totals
            expected_count = 15000 + 14500 + 14500
            self.assertEqual(logger.TOTAL_COUNT, expected_count)
            self.assertGreaterEqual(logger.TOTAL_DURATION, 0)
            self.assertEqual(logger.step_number, 5)  # 3 steps + 1 for init + 1 for close

            msg = "TestStepLoggerIntegration.test_070_complete_etl_workflow :: Successful."
            log_to_console(__name__, "Info", msg)

        except Exception as err:
            msg = f"TestStepLoggerIntegration.test_070_complete_etl_workflow :: Failed :: {err}"
            log_to_console(__name__, "Error", msg)
            self.fail(f"Complete ETL workflow test failed: {err}")

    def test_080_error_scenario(self):
        """Test error handling in a multi-step process with a failed step."""
        msg = "TestStepLoggerIntegration.test_080_error_scenario :: Starting Test."
        log_to_console(__name__, "Info", msg)

        try:
            logger = StepLogger(
                secret_key=os.environ["AWS_SECRET_ARN_SF_CONN"],
                env=os.environ["ENV"],
                etl_execution_id=str(uuid.uuid4()),
                process_name="UnitTest_Error_Scenario",
                process_description="Unit test - error scenario",
            )

            try:
                # Successful step
                logger.start_step("successful_step", operation="EXTRACT")
                logger.log_step("SUCCESS", record_count=100)

                # Failed step
                logger.start_step("failing_step", operation="TRANSFORM")
                logger.log_step(
                    status="FAILED",
                    description="Step failed due to simulated connection timeout",
                    custom_attributes={
                        "error_type": "ConnectionTimeout",
                        "retry_count": 3,
                    },
                )
            finally:
                logger.close(
                    custom_attributes={"had_errors": True, "partial_success": True}
                )

            # Verify state after error
            self.assertEqual(logger.TOTAL_COUNT, 100)  # Only successful step counted
            self.assertGreaterEqual(logger.TOTAL_DURATION, 0)

            msg = "TestStepLoggerIntegration.test_080_error_scenario :: Successful."
            log_to_console(__name__, "Info", msg)

        except Exception as err:
            msg = f"TestStepLoggerIntegration.test_080_error_scenario :: Failed :: {err}"
            log_to_console(__name__, "Error", msg)
            self.fail(f"Error scenario test failed: {err}")


if __name__ == "__main__":
    unittest.main(verbosity=2, buffer=True)
