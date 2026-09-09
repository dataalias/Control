"""
Unit tests for the dates_to_process function.

This module provides comprehensive test coverage for the dates_to_process function,
including various date scenarios, error handling, and edge cases.
Tests use real datetime - no mocking.
"""

import unittest
from datetime import datetime, date, timedelta

import pytz

from eimutils.utils import dates_to_process
from eimutils.delogging import log_to_console
from eimutils.logger import get_logger


def setUpModule():
    print("\n" + "=" * 70)
    print("  RUNNING: test_date_function.py")
    print("=" * 70)
    get_logger("eimutils.tests.test_date_function")


class TestDatesToProcess(unittest.TestCase):
    """Test suite for dates_to_process function."""

    @classmethod
    def setUpClass(cls):
        log_to_console(__name__, "Info", "TestDatesToProcess :: Starting.")

    @classmethod
    def tearDownClass(cls):
        log_to_console(__name__, "Info", "TestDatesToProcess :: Complete.")

    def _get_yesterday(self):
        """Helper to get yesterday's date in US/Pacific timezone (same logic as the function)."""
        return (datetime.today().astimezone(pytz.timezone('US/Pacific')) - timedelta(1)).date()

    def test_not_provided_dates_with_existing_data(self):
        """Test when both dates are 'Not Provided' and last_processed_date is provided."""
        yesterday = self._get_yesterday()
        # Set last_processed_date to 5 days before yesterday so we get a range
        last_processed = yesterday - timedelta(days=4)

        file_dt_from, file_dt_to, file_dt_list = dates_to_process(
            file_dt_from="Not Provided",
            file_dt_to="Not Provided",
            last_processed_date=last_processed,
        )

        self.assertEqual(file_dt_from, last_processed.strftime("%Y-%m-%d"))
        self.assertEqual(file_dt_to, yesterday.strftime("%Y-%m-%d"))
        # Should generate 5 dates (last_processed through yesterday inclusive)
        expected_dates = [
            (last_processed + timedelta(days=x)).strftime("%Y-%m-%d")
            for x in range(5)
        ]
        self.assertEqual(file_dt_list, expected_dates)

    def test_not_provided_dates_with_no_existing_data(self):
        """Test when both dates are 'Not Provided' and last_processed_date is None."""
        yesterday = self._get_yesterday()

        file_dt_from, file_dt_to, file_dt_list = dates_to_process(
            file_dt_from="Not Provided",
            file_dt_to="Not Provided",
            last_processed_date=None,
        )

        # When no data exists, it should default to yesterday
        self.assertEqual(file_dt_from, yesterday.strftime("%Y-%m-%d"))
        self.assertEqual(file_dt_to, yesterday.strftime("%Y-%m-%d"))
        self.assertEqual(file_dt_list, [yesterday.strftime("%Y-%m-%d")])

    def test_not_provided_dates_when_up_to_date(self):
        """Test when both dates are 'Not Provided' and table is already up to date."""
        yesterday = self._get_yesterday()

        file_dt_from, file_dt_to, file_dt_list = dates_to_process(
            file_dt_from="Not Provided",
            file_dt_to="Not Provided",
            last_processed_date=yesterday,
        )

        # When already up to date, should return yesterday's date only
        self.assertEqual(file_dt_from, yesterday.strftime("%Y-%m-%d"))
        self.assertEqual(file_dt_to, yesterday.strftime("%Y-%m-%d"))
        self.assertEqual(file_dt_list, [yesterday.strftime("%Y-%m-%d")])

    def test_provided_dates_valid_format(self):
        """Test when both dates are provided in valid YYYY-MM-DD format."""
        file_dt_from, file_dt_to, file_dt_list = dates_to_process(
            file_dt_from="2026-01-01",
            file_dt_to="2026-01-05",
            last_processed_date=None,
        )

        self.assertEqual(file_dt_from, "2026-01-01")
        self.assertEqual(file_dt_to, "2026-01-05")
        expected_dates = [
            "2026-01-01",
            "2026-01-02",
            "2026-01-03",
            "2026-01-04",
            "2026-01-05",
        ]
        self.assertEqual(file_dt_list, expected_dates)

    def test_provided_dates_same_day(self):
        """Test when both provided dates are the same day."""
        file_dt_from, file_dt_to, file_dt_list = dates_to_process(
            file_dt_from="2026-01-15",
            file_dt_to="2026-01-15",
            last_processed_date=None,
        )

        self.assertEqual(file_dt_from, "2026-01-15")
        self.assertEqual(file_dt_to, "2026-01-15")
        self.assertEqual(file_dt_list, ["2026-01-15"])

    def test_provided_dates_invalid_format(self):
        """Test that invalid date format raises an exception."""
        with self.assertRaises(Exception) as context:
            dates_to_process(
                file_dt_from="01-01-2026",  # Wrong format MM-DD-YYYY
                file_dt_to="2026-01-05",
                last_processed_date=None,
            )

        self.assertIn("Incorrect FILE_DT_FROM/FILE_DT_TO passed", str(context.exception))
        self.assertIn("Try again", str(context.exception))

    def test_provided_dates_invalid_date(self):
        """Test that invalid date values raise an exception."""
        with self.assertRaises(Exception) as context:
            dates_to_process(
                file_dt_from="2026-02-30",  # Invalid date (Feb 30)
                file_dt_to="2026-03-01",
                last_processed_date=None,
            )

        self.assertIn("Incorrect FILE_DT_FROM/FILE_DT_TO passed", str(context.exception))

    def test_provided_dates_non_date_string(self):
        """Test that non-date strings raise an exception."""
        with self.assertRaises(Exception) as context:
            dates_to_process(
                file_dt_from="not-a-date",
                file_dt_to="2026-01-05",
                last_processed_date=None,
            )

        self.assertIn("Incorrect FILE_DT_FROM/FILE_DT_TO passed", str(context.exception))

    def test_provided_dates_large_range(self):
        """Test with a larger date range to verify list generation."""
        file_dt_from, file_dt_to, file_dt_list = dates_to_process(
            file_dt_from="2026-01-01",
            file_dt_to="2026-01-31",
            last_processed_date=None,
        )

        self.assertEqual(file_dt_from, "2026-01-01")
        self.assertEqual(file_dt_to, "2026-01-31")
        self.assertEqual(len(file_dt_list), 31)
        self.assertEqual(file_dt_list[0], "2026-01-01")
        self.assertEqual(file_dt_list[-1], "2026-01-31")

    def test_last_processed_date_ignored_when_dates_provided(self):
        """Test that last_processed_date is ignored when explicit dates are provided."""
        file_dt_from, file_dt_to, file_dt_list = dates_to_process(
            file_dt_from="2026-01-01",
            file_dt_to="2026-01-03",
            last_processed_date=date(2025, 12, 1),  # Should be ignored
        )

        self.assertEqual(file_dt_from, "2026-01-01")
        self.assertEqual(file_dt_to, "2026-01-03")
        expected_dates = ["2026-01-01", "2026-01-02", "2026-01-03"]
        self.assertEqual(file_dt_list, expected_dates)


class TestDatesToProcessEdgeCases(unittest.TestCase):
    """Test edge cases for dates_to_process function."""

    @classmethod
    def setUpClass(cls):
        log_to_console(__name__, "Info", "TestDatesToProcessEdgeCases :: Starting.")

    @classmethod
    def tearDownClass(cls):
        log_to_console(__name__, "Info", "TestDatesToProcessEdgeCases :: Complete.")

    def _get_yesterday(self):
        """Helper to get yesterday's date in US/Pacific timezone."""
        return (datetime.today().astimezone(pytz.timezone('US/Pacific')) - timedelta(1)).date()

    def test_cross_month_date_range(self):
        """Test date range that crosses month boundary."""
        file_dt_from, file_dt_to, file_dt_list = dates_to_process(
            file_dt_from="2026-01-30",
            file_dt_to="2026-02-02",
            last_processed_date=None,
        )

        expected_dates = ["2026-01-30", "2026-01-31", "2026-02-01", "2026-02-02"]
        self.assertEqual(file_dt_list, expected_dates)

    def test_cross_year_date_range(self):
        """Test date range that crosses year boundary."""
        file_dt_from, file_dt_to, file_dt_list = dates_to_process(
            file_dt_from="2025-12-30",
            file_dt_to="2026-01-02",
            last_processed_date=None,
        )

        expected_dates = ["2025-12-30", "2025-12-31", "2026-01-01", "2026-01-02"]
        self.assertEqual(file_dt_list, expected_dates)

    def test_leap_year_february(self):
        """Test date range including leap year February 29."""
        # 2024 is a leap year
        file_dt_from, file_dt_to, file_dt_list = dates_to_process(
            file_dt_from="2024-02-28",
            file_dt_to="2024-03-01",
            last_processed_date=None,
        )

        expected_dates = ["2024-02-28", "2024-02-29", "2024-03-01"]
        self.assertEqual(file_dt_list, expected_dates)

    def test_multiple_days_behind(self):
        """Test when last_processed_date is multiple days behind."""
        yesterday = self._get_yesterday()
        # Set last_processed to 5 days before yesterday
        last_processed = yesterday - timedelta(days=5)

        file_dt_from, file_dt_to, file_dt_list = dates_to_process(
            file_dt_from="Not Provided",
            file_dt_to="Not Provided",
            last_processed_date=last_processed,
        )

        self.assertEqual(file_dt_from, last_processed.strftime("%Y-%m-%d"))
        self.assertEqual(file_dt_to, yesterday.strftime("%Y-%m-%d"))
        # Should generate 6 dates (last_processed through yesterday inclusive)
        expected_dates = [
            (last_processed + timedelta(days=x)).strftime("%Y-%m-%d")
            for x in range(6)
        ]
        self.assertEqual(file_dt_list, expected_dates)


if __name__ == "__main__":
    unittest.main()
