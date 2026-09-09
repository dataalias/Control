"""
Unit tests for the delogging module.

Covers:
  - message_type string to logging level mapping
  - case-insensitive message_type matching
  - unknown type falls back to INFO
  - logger name comes from function_name argument
  - message content is passed through unchanged
"""

import logging
import unittest

from eimutils.delogging import log_to_console
from eimutils.logger import get_logger


def setUpModule():
    print("\n" + "=" * 70)
    print("  RUNNING: test_delogging.py")
    print("=" * 70)
    get_logger("test_delogging.demo")  # register handler so messages below are visible
    print("  Sample log_to_console output:")
    log_to_console("test_delogging.demo", "Info",  "Sample INFO  message from eimutils.delogging")
    log_to_console("test_delogging.demo", "Warn",  "Sample WARN  message from eimutils.delogging")
    log_to_console("test_delogging.demo", "Error", "Sample ERROR message from eimutils.delogging")
    print()


class TestLevelMapping(unittest.TestCase):
    """Each supported message_type string maps to the correct logging level."""

    def _capture(self, message_type: str) -> logging.LogRecord:
        """Emit one log call and return the captured LogRecord."""
        with self.assertLogs("test.delogging", level=logging.DEBUG) as cm:
            log_to_console("test.delogging", message_type, "msg")
        return cm.records[0]

    def test_info_maps_to_info(self):
        self.assertEqual(self._capture("Info").levelno, logging.INFO)

    def test_err_maps_to_error(self):
        self.assertEqual(self._capture("Err").levelno, logging.ERROR)

    def test_error_maps_to_error(self):
        self.assertEqual(self._capture("Error").levelno, logging.ERROR)

    def test_warn_maps_to_warning(self):
        self.assertEqual(self._capture("Warn").levelno, logging.WARNING)

    def test_warning_maps_to_warning(self):
        self.assertEqual(self._capture("Warning").levelno, logging.WARNING)

    def test_unknown_type_defaults_to_info(self):
        self.assertEqual(self._capture("SomethingElse").levelno, logging.INFO)


class TestCaseInsensitivity(unittest.TestCase):
    """message_type matching is case-insensitive."""

    def _level(self, message_type: str) -> int:
        with self.assertLogs("test.delogging", level=logging.DEBUG) as cm:
            log_to_console("test.delogging", message_type, "msg")
        return cm.records[0].levelno

    def test_info_uppercase(self):
        self.assertEqual(self._level("INFO"), logging.INFO)

    def test_info_lowercase(self):
        self.assertEqual(self._level("info"), logging.INFO)

    def test_err_uppercase(self):
        self.assertEqual(self._level("ERR"), logging.ERROR)

    def test_error_uppercase(self):
        self.assertEqual(self._level("ERROR"), logging.ERROR)

    def test_warn_uppercase(self):
        self.assertEqual(self._level("WARN"), logging.WARNING)

    def test_warning_lowercase(self):
        self.assertEqual(self._level("warning"), logging.WARNING)

    def test_mixed_case_error(self):
        self.assertEqual(self._level("eRrOr"), logging.ERROR)


class TestMessageContent(unittest.TestCase):
    """Message text and logger name are passed through correctly."""

    def test_message_is_preserved(self):
        msg = "Processing file s3://bucket/path/file.csv"
        with self.assertLogs("test.delogging", level=logging.DEBUG) as cm:
            log_to_console("test.delogging", "Info", msg)
        self.assertEqual(cm.records[0].getMessage(), msg)

    def test_empty_message(self):
        with self.assertLogs("test.delogging", level=logging.DEBUG) as cm:
            log_to_console("test.delogging", "Info", "")
        self.assertEqual(cm.records[0].getMessage(), "")

    def test_special_characters_preserved(self):
        msg = 'Error: file "data.csv" not found @ s3://bucket/path'
        with self.assertLogs("test.delogging", level=logging.DEBUG) as cm:
            log_to_console("test.delogging", "Error", msg)
        self.assertEqual(cm.records[0].getMessage(), msg)

    def test_function_name_becomes_logger_name(self):
        logger_name = "eimutils.snowflake_connection"
        with self.assertLogs(logger_name, level=logging.DEBUG) as cm:
            log_to_console(logger_name, "Info", "connected")
        self.assertEqual(cm.records[0].name, logger_name)

    def test_different_logger_names_are_independent(self):
        with self.assertLogs("module.a", level=logging.DEBUG) as cm_a:
            log_to_console("module.a", "Info", "from a")
        with self.assertLogs("module.b", level=logging.DEBUG) as cm_b:
            log_to_console("module.b", "Error", "from b")

        self.assertEqual(cm_a.records[0].name, "module.a")
        self.assertEqual(cm_b.records[0].name, "module.b")
        self.assertEqual(cm_a.records[0].levelno, logging.INFO)
        self.assertEqual(cm_b.records[0].levelno, logging.ERROR)


class TestNoSideEffects(unittest.TestCase):
    """log_to_console does not raise and emits exactly one record per call."""

    def test_does_not_raise_on_valid_inputs(self):
        try:
            with self.assertLogs("test.delogging", level=logging.DEBUG):
                log_to_console("test.delogging", "Info", "all good")
        except Exception as e:
            self.fail(f"log_to_console raised unexpectedly: {e}")

    def test_exactly_one_record_per_call(self):
        with self.assertLogs("test.delogging", level=logging.DEBUG) as cm:
            log_to_console("test.delogging", "Warn", "only one")
        self.assertEqual(len(cm.records), 1)

    def test_multiple_calls_emit_multiple_records(self):
        with self.assertLogs("test.delogging", level=logging.DEBUG) as cm:
            log_to_console("test.delogging", "Info", "first")
            log_to_console("test.delogging", "Error", "second")
            log_to_console("test.delogging", "Warn", "third")
        self.assertEqual(len(cm.records), 3)
        self.assertEqual(cm.records[0].levelno, logging.INFO)
        self.assertEqual(cm.records[1].levelno, logging.ERROR)
        self.assertEqual(cm.records[2].levelno, logging.WARNING)


if __name__ == "__main__":
    unittest.main()
