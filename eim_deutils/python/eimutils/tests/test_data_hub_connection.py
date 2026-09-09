"""
Unit tests for data_hub_connection.py pure functions.

Covers:
  - prepare_issues(): single publication, multiple publications, None datetime
    fields, exception path, issue_list[-1] index invariant.
"""
import unittest
import pandas as pd

from eimutils.data_hub_connection import prepare_issues
from eimutils.logger import get_logger


def setUpModule():
    print("\n" + "=" * 70)
    print("  RUNNING: test_data_hub_connection.py")
    print("=" * 70)
    get_logger("eimutils.tests.test_data_hub_connection")


def _make_pub_df(rows):
    """Build a minimal publication DataFrame from a list of dicts."""
    defaults = {
        "PUBLICATIONCODE": "PUB_A",
        "PUBLICATIONFILEPATH": "/data/pub_a/",
        "ISSUENAME": "Unknown",
        "LASTHIGHWATERMARKDATETIME": "2026-01-01",
        "HIGHWATERMARKDATETIME": "2026-01-02",
        "LASTHIGHWATERMARKDATETIMEUTC": "2026-01-01",
        "HIGHWATERMARKDATETIMEUTC": "2026-01-02",
    }
    return pd.DataFrame([{**defaults, **r} for r in rows])


class TestPrepareIssues(unittest.TestCase):
    """Tests for prepare_issues()."""

    def test_single_publication_returns_two_elements(self):
        df = _make_pub_df([{"PUBLICATIONCODE": "PUB_A"}])
        result = prepare_issues(df)
        # [issue_dict, index_dict]
        self.assertEqual(len(result), 2)

    def test_last_element_is_index_dict(self):
        df = _make_pub_df([{"PUBLICATIONCODE": "PUB_A"}])
        result = prepare_issues(df)
        index = result[-1]
        self.assertIsInstance(index, dict)
        self.assertIn("PUB_A", index)

    def test_index_maps_code_to_row_position(self):
        df = _make_pub_df([
            {"PUBLICATIONCODE": "PUB_A"},
            {"PUBLICATIONCODE": "PUB_B"},
        ])
        result = prepare_issues(df)
        index = result[-1]
        self.assertIn("PUB_A", index)
        self.assertIn("PUB_B", index)
        # The indexed positions must actually point to the right issue dict
        self.assertEqual(result[index["PUB_A"]]["PublicationCode"], "PUB_A")
        self.assertEqual(result[index["PUB_B"]]["PublicationCode"], "PUB_B")

    def test_multiple_publications_correct_length(self):
        df = _make_pub_df([
            {"PUBLICATIONCODE": "PUB_A"},
            {"PUBLICATIONCODE": "PUB_B"},
            {"PUBLICATIONCODE": "PUB_C"},
        ])
        result = prepare_issues(df)
        # 3 issues + 1 index
        self.assertEqual(len(result), 4)

    def test_none_period_start_time_defaults_to_1900(self):
        df = _make_pub_df([{
            "PUBLICATIONCODE": "PUB_A",
            "LASTHIGHWATERMARKDATETIME": None,
            "LASTHIGHWATERMARKDATETIMEUTC": None,
        }])
        result = prepare_issues(df)
        issue = result[0]
        self.assertEqual(issue["PeriodStartTime"], "1900-01-01")
        self.assertEqual(issue["PeriodStartTimeUTC"], "1900-01-01")

    def test_none_period_end_time_defaults_to_1900(self):
        df = _make_pub_df([{
            "PUBLICATIONCODE": "PUB_A",
            "HIGHWATERMARKDATETIME": None,
            "HIGHWATERMARKDATETIMEUTC": None,
        }])
        result = prepare_issues(df)
        issue = result[0]
        self.assertEqual(issue["PeriodEndTime"], "1900-01-01")
        self.assertEqual(issue["PeriodEndTimeUTC"], "1900-01-01")

    def test_issue_has_required_fields(self):
        df = _make_pub_df([{"PUBLICATIONCODE": "PUB_A"}])
        result = prepare_issues(df)
        issue = result[0]
        for field in ("PublicationCode", "StatusCode", "ReportDate", "IssueName",
                      "PeriodStartTime", "PeriodEndTime", "RecordCount", "ETLExecutionId"):
            self.assertIn(field, issue, f"Missing field: {field}")

    def test_status_code_is_ip(self):
        df = _make_pub_df([{"PUBLICATIONCODE": "PUB_A"}])
        result = prepare_issues(df)
        self.assertEqual(result[0]["StatusCode"], "IP")

    def test_empty_dataframe_raises(self):
        """prepare_issues on an empty DataFrame should raise (no index appended)."""
        df = _make_pub_df([])
        # Empty DataFrame still produces a valid (but empty) result with just the index
        result = prepare_issues(df)
        self.assertEqual(result, [{}])  # only the empty index dict

    def test_exception_in_iteration_raises(self):
        """A bad row (missing required column) must raise, not silently return partial list."""
        df = pd.DataFrame([{"PUBLICATIONCODE": "PUB_A"}])  # missing required columns
        with self.assertRaises(Exception):
            prepare_issues(df)
