"""
Unit tests for api_call.py — no network connectivity required.
"""

import pytest
from unittest.mock import patch, MagicMock


def setUpModule():
    print("\n" + "=" * 70)
    print("  RUNNING: test_api_call.py")
    print("=" * 70)


class TestDownloadFile:
    def test_successful_download_writes_file(self, tmp_path):
        from eimutils.api_call import download_file

        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.content = b"file content here"

        output_file = tmp_path / "output.txt"
        with patch("eimutils.api_call.requests.get", return_value=mock_response):
            download_file("http://example.com/file.txt", str(output_file))

        assert output_file.read_bytes() == b"file content here"

    def test_non_200_logs_error_and_does_not_write(self, tmp_path):
        from eimutils.api_call import download_file

        mock_response = MagicMock()
        mock_response.status_code = 404

        output_file = tmp_path / "output.txt"
        with patch("eimutils.api_call.requests.get", return_value=mock_response):
            with patch("eimutils.api_call.log_to_console") as mock_log:
                download_file("http://example.com/missing.txt", str(output_file))
                mock_log.assert_called_once()
                _, level, _ = mock_log.call_args[0]
                assert level.lower() == "error"

        assert not output_file.exists()

    def test_connection_error_raises(self):
        from eimutils.api_call import download_file
        import requests

        with patch(
            "eimutils.api_call.requests.get",
            side_effect=requests.ConnectionError("connection refused"),
        ):
            with pytest.raises(Exception, match="Issue with file download"):
                download_file("http://example.com/file.txt", "/tmp/out.txt")

    def test_timeout_raises(self):
        from eimutils.api_call import download_file
        import requests

        with patch(
            "eimutils.api_call.requests.get",
            side_effect=requests.Timeout("timed out"),
        ):
            with pytest.raises(Exception, match="Issue with file download"):
                download_file("http://example.com/file.txt", "/tmp/out.txt")

    def test_passes_timeout_to_requests(self):
        from eimutils.api_call import download_file

        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.content = b""

        with patch("eimutils.api_call.requests.get", return_value=mock_response) as mock_get:
            with patch("builtins.open", MagicMock()):
                download_file("http://example.com/file.txt", "/tmp/out.txt")
            _, kwargs = mock_get.call_args
            assert kwargs.get("timeout") is not None


"""
*******************************************************************************
Change History:

Author          Date        Description
----------      ----------  ---------------------------------------------------
ffortunato      2026-04-22  Initial iteration.
*******************************************************************************
"""
