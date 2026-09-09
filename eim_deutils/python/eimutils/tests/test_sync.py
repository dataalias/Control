"""
Structural tests that enforce repo-level invariants without hitting any external service.

Currently covers:
  - step_logger_snowflake.py: the dhui/ copy must be byte-for-byte identical to
    the canonical python_snowflake/ copy (both are intentionally duplicated but must
    stay in sync — see CLAUDE.md).
"""
import os
import unittest

_REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))

_CANONICAL = os.path.join(
    _REPO_ROOT, "python_snowflake", "eimutils_snowflake", "step_logger_snowflake.py"
)
_DHUI_COPY = os.path.join(
    _REPO_ROOT, "dhui", "eimutils_snowflake", "step_logger_snowflake.py"
)


def setUpModule():
    print("\n" + "=" * 70)
    print("  RUNNING: test_sync.py")
    print("=" * 70)


class TestStepLoggerSnowflakeSync(unittest.TestCase):
    """Enforce that both copies of step_logger_snowflake.py stay identical."""

    def test_both_files_exist(self):
        self.assertTrue(os.path.isfile(_CANONICAL), f"Canonical file missing: {_CANONICAL}")
        self.assertTrue(os.path.isfile(_DHUI_COPY), f"dhui copy missing: {_DHUI_COPY}")

    def test_copies_are_identical(self):
        """Fails if dhui/ has drifted from python_snowflake/ — copy canonical to fix.

        Line endings are normalised before comparison so CRLF vs LF differences
        (which are invisible and editor-dependent) don't cause spurious failures.
        """
        with open(_CANONICAL, encoding="utf-8") as f:
            canonical_text = f.read().replace("\r\n", "\n").replace("\r", "\n")
        with open(_DHUI_COPY, encoding="utf-8") as f:
            dhui_text = f.read().replace("\r\n", "\n").replace("\r", "\n")

        self.assertEqual(
            canonical_text,
            dhui_text,
            "dhui/eimutils_snowflake/step_logger_snowflake.py has drifted from "
            "python_snowflake/eimutils_snowflake/step_logger_snowflake.py. "
            "Fix: overwrite the dhui copy with the canonical version.",
        )
