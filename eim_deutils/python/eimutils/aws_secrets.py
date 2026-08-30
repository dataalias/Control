"""
***********************************************************************************************************************
File: aws_secrets.py

Purpose: Gets secret values from AWS Secrets.

Dependencies/Helpful Notes :

***********************************************************************************************************************
"""

# Use this code snippet in your app.
# If you need more information about configurations or implementing the sample code, visit the AWS docs:
# https://aws.amazon.com/developers/getting-started/python/

import boto3
from botocore.exceptions import ClientError
import base64
import json
from eimutils.logger import get_logger

logger = get_logger(__name__)


class AwsSecrets:
    """Singleton class for managing AWS Secrets Manager interactions.

    This class provides a singleton interface for retrieving secrets from AWS Secrets Manager
    and generating Salesforce JWT tokens. It ensures efficient secret management by caching
    secrets and preventing redundant AWS API calls.

    Attributes:
        srcArn (str): The AWS Secrets Manager ARN for the secret.
        aws_region (str): The AWS region where the secret is stored.
        secret (dict): The cached secret values retrieved from AWS Secrets Manager.

    Example:
        Basic usage:
            aws_secrets = AwsSecrets(
                "arn:aws:secretsmanager:us-west-2:123456789012:secret:my-secret-abcdef",
                "us-west-2"
            )
            secrets_dict = aws_secrets.get_secret()
            jwt_token = aws_secrets.get_sfdc_jwt_token()
    """

    _instance = None
    # Caching note: secrets are fetched once at first instantiation and held for the
    # process lifetime. Rotated credentials are not picked up without a process restart.
    # This is acceptable for Glue jobs (short-lived) and Streamlit sessions (restarted
    # on deploy). If you need TTL-based refresh, replace the singleton pattern here.

    def __new__(cls, secret_arn: str, aws_region: str):
        """Create or return existing singleton instance.

        Implements singleton pattern to ensure only one instance exists per process.
        If instance doesn't exist, creates new instance and initializes it with
        the provided AWS Secrets Manager ARN and region.

        Args:
            secret_arn (str): The AWS Secrets Manager ARN containing the secret data.
            aws_region (str): The AWS region where the secret is stored.

        Returns:
            AwsSecrets: The singleton instance of the AwsSecrets class.
        """
        if cls._instance is None:
            cls._instance = super(AwsSecrets, cls).__new__(cls)
            cls._instance.initialize_aws_secrets(secret_arn, aws_region)
        elif cls._instance.secret_arn != secret_arn:
            raise ValueError(
                f"AwsSecrets singleton already initialised with ARN "
                f"'{cls._instance.secret_arn}'. Cannot reinitialise with "
                f"'{secret_arn}' in the same process."
            )
        return cls._instance

    def initialize_aws_secrets(self, secret_arn: str, aws_region: str):
        """Initialize the AWS Secrets instance with ARN and region.

        Sets up the instance attributes and retrieves the secret values from
        AWS Secrets Manager. This method is called automatically during
        singleton initialization.

        Args:
            secret_arn (str): The AWS Secrets Manager ARN containing the secret data.
            aws_region (str): The AWS region where the secret is stored.

        Note:
            This method should not be called directly. It's invoked automatically
            by the __new__ method during singleton creation.
        """
        self.secret_arn = secret_arn
        self.aws_region = aws_region
        self.secret = get_secrets_dict(self.secret_arn, self.aws_region)

    def get_secret(self) -> dict:
        """Retrieve the cached secret values dictionary.

        Returns the complete dictionary of secret key-value pairs that were
        retrieved from AWS Secrets Manager during initialization.

        Returns:
            dict: Dictionary containing all secret key-value pairs from AWS Secrets Manager.
        """
        return self.secret

    def get_sfdc_jwt_token(self) -> str:
        """Generate a Salesforce JWT token using stored credentials.

        Creates a JWT token for Salesforce authentication using the private key,
        consumer key, username, and URL stored in AWS Secrets Manager. The token
        is valid for 5 minutes (300 seconds) and uses RS256 algorithm.

        Returns:
            str: A signed JWT token ready for Salesforce OAuth 2.0 authentication.

        Raises:
            KeyError: If required Salesforce credentials are missing from secrets.
            Exception: If JWT token generation fails.

        Note:
            Requires the following keys in the AWS secret:
            - SALESFORCECKEY: Consumer key for the connected app
            - SALESFORCEPKEY: Private key for signing the JWT
            - SALESFORCEURL: Salesforce authentication URL (audience)
            - SALESFORCEUSER: Username for the Salesforce user (subject)
        """
        import time
        import jwt

        claim = {
            "iss": self.secret["SALESFORCECKEY"],
            "exp": int(time.time()) + 300,
            "aud": self.secret["SALESFORCEURL"],
            "sub": self.secret["SALESFORCEUSER"],
        }

        return jwt.encode(
            claim,
            self.secret["SALESFORCEPKEY"],
            algorithm="RS256",
            headers={"alg": "RS256"},
        )


def get_secrets_dict(secret_arn: str, aws_region: str) -> dict:
    """Retrieve secrets from AWS Secrets Manager and convert to dictionary.

    Retrieves the raw secret string from AWS Secrets Manager and converts it
    from JSON format to a Python dictionary for easy access to individual
    secret values.

    Args:
        secret_arn (str): The AWS Secrets Manager ARN containing the secret data.
        aws_region (str): The AWS region where the secret is stored.

    Returns:
        dict: Dictionary containing the secret key-value pairs parsed from JSON.

    Raises:
        json.JSONDecodeError: If the secret value is not valid JSON.
        Exception: If retrieval from AWS Secrets Manager fails.
    """
    secret = get_secrets(secret_arn, aws_region)
    try:
        return json.loads(secret)
    except (json.JSONDecodeError, TypeError) as e:
        raise ValueError(
            f"Secret at ARN '{secret_arn}' is not valid JSON. "
            f"Binary secrets are not supported by this function. Error: {e}"
        ) from e


"""
***********************************************************************************************************************
Function: get_secret

Purpose: Gets AWS secret data.

Parameters:
     secret_name - AWS secret name from the account the process is running in
                   that contains the db connection information.

Calls:

Called by:

Returns: dictionary of secret values

***********************************************************************************************************************
"""


def get_secrets(srcArn, aws_region):

    logger.debug(f"Getting secrets from {srcArn} in {aws_region}")

    session = boto3.session.Session()
    client = session.client(service_name="secretsmanager", region_name=aws_region)

    logger.debug("Session and Client Created")

    try:
        get_secret_value_response = client.get_secret_value(SecretId=srcArn)

        logger.debug("Secret Retrieved :: OK")

    except ClientError as e:
        if e.response["Error"]["Code"] == "DecryptionFailureException":
            msg = "Secrets Manager can't decrypt the protected secret \
                text using the provided KMS key. :: {}".format(
                str(e)
            )
            logger.error(msg)
            raise e
        elif e.response["Error"]["Code"] == "InternalServiceErrorException":
            msg = "An error occurred on the server side.. :: {}".format(str(e))
            logger.error(msg)
            raise e
        elif e.response["Error"]["Code"] == "InvalidParameterException":
            msg = "You provided an invalid value for a parameter. :: {}".format(str(e))
            logger.error(msg)
            raise e
        elif e.response["Error"]["Code"] == "InvalidRequestException":
            msg = "You provided a parameter value that is not valid for the current \
                state of the resource. :: {}".format(
                str(e)
            )
            logger.error(msg)
            raise e
        elif e.response["Error"]["Code"] == "ResourceNotFoundException":
            msg = "We can't find the resource that you asked for. :: {}".format(str(e))
            logger.error(msg)
            raise e
        else:
            msg = "Got an error retrieving the secret. :: {}".format(str(e))
            logger.error(msg)
            raise Exception(msg)
    except Exception as e:
        msg = "Unable to get_secret_value. :: {}".format(str(e))
        logger.error(msg)
        raise e

    try:
        if "SecretString" in get_secret_value_response:
            msg = "Retrieving Secret String"
            logger.info(msg)
            secret = get_secret_value_response["SecretString"]
            return secret
        elif "SecretBinary" in get_secret_value_response:
            logger.info("Retrieving Secret Binary")
            decoded_binary_secret = base64.b64decode(
                get_secret_value_response["SecretBinary"]
            )
            return decoded_binary_secret
        else:
            msg = "Unexpected secret format."
            logger.error(msg)
            raise Exception(msg)
    except Exception as e:
        msg = "Unable to get_secret_value_response. :: {}".format(str(e))
        logger.error(msg)
        raise e


"""
***********************************************************************************************************************
Change History:

Author		Date		Description
----------	----------	-----------------------------------------------------------------------------------------------
ffortunato  2023-11-01  + new flavor of get secrets: getSecrets(srcPS, srcArn):
ffortunato  2023-12-15  + additional exception handling.
ffortunato  2024-01-02  + Minor err msg update.
ffortunato  2024-04-05  + Edits to error handling.
ffortunato  2024-04-09  + Formatting Edits.
ffortunato  2024-04-18  + Additional Error Handling.
ffortunato  2025-07-22  o formatting.
ffortunato  2025-08-14  o small logging change.
dostrowski  2025-09-06  o added AwsSecrets class and get_secrets_dict function.
***********************************************************************************************************************
"""
