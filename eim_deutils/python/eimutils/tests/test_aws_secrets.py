"""
Unit tests for aws_secrets module.

Covers:
  - get_secrets(): string and binary secret responses, all ClientError branches
  - get_secrets_dict(): JSON parsing and error propagation
  - AwsSecrets: singleton behavior, get_secret(), get_sfdc_jwt_token()
"""
import base64
import json
import unittest
from unittest.mock import MagicMock, patch

from botocore.exceptions import ClientError

from eimutils.aws_secrets import AwsSecrets, get_secrets, get_secrets_dict
from eimutils.logger import get_logger


def setUpModule():
    print("\n" + "=" * 70)
    print("  RUNNING: test_aws_secrets.py")
    print("=" * 70)
    get_logger("eimutils.tests.test_aws_secrets")


def _client_error(code: str) -> ClientError:
    return ClientError({"Error": {"Code": code, "Message": "test"}}, "GetSecretValue")


def _mock_boto_client(response: dict) -> MagicMock:
    client = MagicMock()
    client.get_secret_value.return_value = response
    return client


class TestGetSecrets(unittest.TestCase):
    """Tests for get_secrets() with mocked boto3."""

    @patch("boto3.session.Session")
    def test_returns_secret_string(self, mock_session):
        payload = json.dumps({"KEY": "VALUE"})
        mock_session.return_value.client.return_value = _mock_boto_client(
            {"SecretString": payload}
        )
        result = get_secrets("arn:fake", "us-west-2")
        self.assertEqual(result, payload)

    @patch("boto3.session.Session")
    def test_returns_decoded_binary_secret(self, mock_session):
        raw = b'{"KEY": "BINVAL"}'
        mock_session.return_value.client.return_value = _mock_boto_client(
            {"SecretBinary": base64.b64encode(raw)}
        )
        result = get_secrets("arn:fake", "us-west-2")
        self.assertEqual(result, raw)

    @patch("boto3.session.Session")
    def test_raises_on_unexpected_format(self, mock_session):
        mock_session.return_value.client.return_value = _mock_boto_client({})
        with self.assertRaises(Exception):
            get_secrets("arn:fake", "us-west-2")

    @patch("boto3.session.Session")
    def test_raises_on_decryption_failure(self, mock_session):
        mock_session.return_value.client.return_value.get_secret_value.side_effect = (
            _client_error("DecryptionFailureException")
        )
        with self.assertRaises(ClientError):
            get_secrets("arn:fake", "us-west-2")

    @patch("boto3.session.Session")
    def test_raises_on_resource_not_found(self, mock_session):
        mock_session.return_value.client.return_value.get_secret_value.side_effect = (
            _client_error("ResourceNotFoundException")
        )
        with self.assertRaises(ClientError):
            get_secrets("arn:fake", "us-west-2")

    @patch("boto3.session.Session")
    def test_raises_on_invalid_parameter(self, mock_session):
        mock_session.return_value.client.return_value.get_secret_value.side_effect = (
            _client_error("InvalidParameterException")
        )
        with self.assertRaises(ClientError):
            get_secrets("arn:fake", "us-west-2")

    @patch("boto3.session.Session")
    def test_raises_on_unknown_client_error(self, mock_session):
        mock_session.return_value.client.return_value.get_secret_value.side_effect = (
            _client_error("SomeOtherErrorCode")
        )
        with self.assertRaises(Exception):
            get_secrets("arn:fake", "us-west-2")


class TestGetSecretsDict(unittest.TestCase):
    """Tests for get_secrets_dict()."""

    @patch("eimutils.aws_secrets.get_secrets")
    def test_returns_parsed_dict(self, mock_get_secrets):
        mock_get_secrets.return_value = json.dumps({"SFUSER": "myuser", "KEY": "val"})
        result = get_secrets_dict("arn:fake", "us-west-2")
        self.assertEqual(result, {"SFUSER": "myuser", "KEY": "val"})

    @patch("eimutils.aws_secrets.get_secrets")
    def test_raises_on_invalid_json(self, mock_get_secrets):
        mock_get_secrets.return_value = "not-json-at-all"
        with self.assertRaises(ValueError):
            get_secrets_dict("arn:fake", "us-west-2")


class TestAwsSecretsSingleton(unittest.TestCase):
    """Tests for AwsSecrets singleton class."""

    def setUp(self):
        AwsSecrets._instance = None

    def tearDown(self):
        AwsSecrets._instance = None

    @patch("eimutils.aws_secrets.get_secrets_dict")
    def test_second_call_returns_same_instance(self, mock_dict):
        mock_dict.return_value = {"KEY": "VAL"}
        a = AwsSecrets("arn:fake", "us-west-2")
        b = AwsSecrets("arn:fake", "us-west-2")
        self.assertIs(a, b)
        mock_dict.assert_called_once()

    @patch("eimutils.aws_secrets.get_secrets_dict")
    def test_get_secret_returns_dict(self, mock_dict):
        mock_dict.return_value = {"KEY": "VALUE"}
        instance = AwsSecrets("arn:fake", "us-west-2")
        self.assertEqual(instance.get_secret(), {"KEY": "VALUE"})

    @patch("eimutils.aws_secrets.get_secrets_dict")
    def test_attributes_set_on_init(self, mock_dict):
        mock_dict.return_value = {}
        instance = AwsSecrets("arn:my-secret", "us-east-1")
        self.assertEqual(instance.secret_arn, "arn:my-secret")
        self.assertEqual(instance.aws_region, "us-east-1")


class TestGetSfdcJwtToken(unittest.TestCase):
    """Tests for AwsSecrets.get_sfdc_jwt_token()."""

    def setUp(self):
        AwsSecrets._instance = None

    def tearDown(self):
        AwsSecrets._instance = None

    @patch("eimutils.aws_secrets.get_secrets_dict")
    def test_returns_encoded_token(self, mock_dict):
        mock_dict.return_value = {
            "SALESFORCECKEY": "consumer_key",
            "SALESFORCEPKEY": "private_key_pem",
            "SALESFORCEURL": "https://login.salesforce.com",
            "SALESFORCEUSER": "user@example.com",
        }
        instance = AwsSecrets("arn:fake", "us-west-2")

        with patch("jwt.encode", return_value="mocked_jwt_token") as mock_jwt:
            token = instance.get_sfdc_jwt_token()
            self.assertEqual(token, "mocked_jwt_token")
            call_kwargs = mock_jwt.call_args
            claim = call_kwargs[0][0]
            self.assertEqual(claim["iss"], "consumer_key")
            self.assertEqual(claim["aud"], "https://login.salesforce.com")
            self.assertEqual(claim["sub"], "user@example.com")
            self.assertIn("exp", claim)

    @patch("eimutils.aws_secrets.get_secrets_dict")
    def test_raises_on_missing_salesforce_key(self, mock_dict):
        mock_dict.return_value = {}  # No Salesforce keys
        instance = AwsSecrets("arn:fake", "us-west-2")
        with self.assertRaises(KeyError):
            instance.get_sfdc_jwt_token()


if __name__ == "__main__":
    unittest.main()
