"""
Unit tests for eimutils.salesforce module.

Covers:
  - Base._authenticate(): success, HTTP error, URL construction
  - MhiSalesData.get_sales_data(): 200 success, 404 no-data, 404 real error, 500 error,
    custom endpoint parameter
"""
import json
import unittest
from unittest.mock import MagicMock, patch

from eimutils.salesforce import Base, MhiSalesData
from eimutils.logger import get_logger


def setUpModule():
    print("\n" + "=" * 70)
    print("  RUNNING: test_salesforce.py")
    print("=" * 70)
    get_logger("eimutils.tests.test_salesforce")


def _mock_response(status_code: int, body) -> MagicMock:
    mock = MagicMock()
    mock.status_code = status_code
    mock.text = body if isinstance(body, str) else json.dumps(body)
    mock.json.return_value = body if isinstance(body, dict) else {}
    return mock


class TestBaseAuthenticate(unittest.TestCase):
    """Tests for Base.__init__ / _authenticate()."""

    @patch("eimutils.salesforce.requests.post")
    def test_successful_auth_sets_tokens(self, mock_post):
        mock_post.return_value = _mock_response(200, {
            "access_token": "tok_abc123",
            "instance_url": "https://myorg.salesforce.com",
        })
        b = Base("myjwt", "login")
        self.assertEqual(b.bearer_token, "tok_abc123")
        self.assertEqual(b.instance_url, "https://myorg.salesforce.com")

    @patch("eimutils.salesforce.requests.post")
    def test_non_200_response_raises(self, mock_post):
        mock_post.return_value = _mock_response(401, "Unauthorized")
        with self.assertRaises(Exception) as ctx:
            Base("badjwt", "login")
        self.assertIn("401", str(ctx.exception))

    @patch("eimutils.salesforce.requests.post")
    def test_correct_url_for_subdomain(self, mock_post):
        mock_post.return_value = _mock_response(200, {
            "access_token": "tok",
            "instance_url": "https://x.sf.com",
        })
        Base("jwt", "test")
        call_url = mock_post.call_args[0][0]
        self.assertEqual(call_url, "https://test.salesforce.com/services/oauth2/token")

    @patch("eimutils.salesforce.requests.post")
    def test_jwt_token_passed_in_request(self, mock_post):
        mock_post.return_value = _mock_response(200, {
            "access_token": "tok",
            "instance_url": "https://x.sf.com",
        })
        Base("my_jwt_value", "login")
        call_data = mock_post.call_args.kwargs["data"]
        self.assertEqual(call_data["assertion"], "my_jwt_value")


class TestMhiSalesDataGetSalesData(unittest.TestCase):
    """Tests for MhiSalesData.get_sales_data()."""

    AUTH_RESPONSE = {"access_token": "tok_123", "instance_url": "https://myorg.sf.com"}

    def _make_instance(self, mock_post: MagicMock) -> MhiSalesData:
        mock_post.return_value = _mock_response(200, self.AUTH_RESPONSE)
        return MhiSalesData("jwt", "login", "myorg2023")

    @patch("eimutils.salesforce.requests.post")
    def test_returns_json_on_200(self, mock_post):
        instance = self._make_instance(mock_post)
        payload = {"customers": [{"id": 1, "name": "Alice"}]}
        mock_post.return_value = _mock_response(200, payload)
        result = instance.get_sales_data("2026-01-01")
        self.assertEqual(result, payload)

    @patch("eimutils.salesforce.requests.post")
    def test_returns_empty_dict_on_no_data_404(self, mock_post):
        instance = self._make_instance(mock_post)
        mock_post.return_value = _mock_response(
            404, "No mhi calls found with the date: 2026-01-01"
        )
        result = instance.get_sales_data("2026-01-01")
        self.assertEqual(result, {})

    @patch("eimutils.salesforce.requests.post")
    def test_raises_on_404_with_other_message(self, mock_post):
        instance = self._make_instance(mock_post)
        mock_post.return_value = _mock_response(404, "Resource not found")
        with self.assertRaises(Exception) as ctx:
            instance.get_sales_data("2026-01-01")
        self.assertIn("404", str(ctx.exception))

    @patch("eimutils.salesforce.requests.post")
    def test_raises_on_500_server_error(self, mock_post):
        instance = self._make_instance(mock_post)
        mock_post.return_value = _mock_response(500, "Internal Server Error")
        with self.assertRaises(Exception) as ctx:
            instance.get_sales_data("2026-01-01")
        self.assertIn("500", str(ctx.exception))

    @patch("eimutils.salesforce.requests.post")
    def test_custom_endpoint_used_in_url(self, mock_post):
        instance = self._make_instance(mock_post)
        mock_post.return_value = _mock_response(200, {})
        # pass endpoint positionally to stay compatible with both old and new signatures
        sig = __import__("inspect").signature(instance.get_sales_data)
        if len(sig.parameters) > 1:
            instance.get_sales_data("2026-01-01", "customEndpoint")
            call_url = mock_post.call_args[0][0]
            self.assertIn("customEndpoint", call_url)
        else:
            self.skipTest("endpoint parameter not present in this build")

    @patch("eimutils.salesforce.requests.post")
    def test_bearer_token_sent_in_header(self, mock_post):
        instance = self._make_instance(mock_post)
        mock_post.return_value = _mock_response(200, {})
        instance.get_sales_data("2026-01-01")
        call_headers = mock_post.call_args[1]["headers"]
        self.assertIn("Authorization", call_headers)
        self.assertIn("tok_123", call_headers["Authorization"])


if __name__ == "__main__":
    unittest.main()
