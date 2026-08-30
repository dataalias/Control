"""
***********************************************************************************************************************
File: salesforce.py

Purpose: Salesforce API integration — JWT-based OAuth 2.0 authentication and sales data retrieval.

Classes:
    Base:         Base class for Salesforce authentication using JWT tokens.
    MhiSalesData: Specialized class for retrieving MHI sales data.

Dependencies/Helpful Notes :

***********************************************************************************************************************
"""

import json
import requests
from eimutils.logger import get_logger

logger = get_logger(__name__)


class Base:
    """Base class for Salesforce authentication using JWT tokens.

    This class handles the OAuth 2.0 JWT bearer token authentication flow
    with Salesforce. It exchanges a JWT token for an access token that can
    be used for subsequent API calls.

    Attributes:
        jwt_token (str): The JWT token for authentication.
        sub_domain (str): The Salesforce subdomain for authentication.
        bearer_token (str): The OAuth access token obtained after authentication.
        instance_url (str): The Salesforce instance URL obtained after authentication.
    """

    def __init__(self, jwt_token: str, sub_domain: str) -> None:
        """Initialize the Base class with JWT token and subdomain.

        Args:
            jwt_token (str): The JWT token for Salesforce authentication.
            sub_domain (str): The Salesforce subdomain (e.g., 'login' for production,
                'test' for sandbox environments).

        Raises:
            Exception: If authentication fails during initialization.
        """
        self.jwt_token = jwt_token
        self.sub_domain = sub_domain
        self.bearer_token = None
        self.instance_url = None
        self._authenticate()

    def _authenticate(self) -> None:
        """Authenticate with Salesforce using JWT bearer token flow.

        Performs OAuth 2.0 JWT bearer token authentication with Salesforce.
        Sets the bearer_token and instance_url attributes upon successful
        authentication.

        Raises:
            Exception: If the OAuth request fails or returns a non-200 status code.
        """
        logger.info("Making OAuth request...")
        url = f"https://{self.sub_domain}.salesforce.com/services/oauth2/token"
        logger.info(f"Making OAuth request to {url}")
        data = {
            "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
            "assertion": self.jwt_token,
        }

        try:
            response = requests.post(url, data=data, timeout=30)
            if response.status_code != 200:
                raise Exception(f"Error making OAuth request: {response.status_code}")
            json_data = json.loads(response.text)
            self.bearer_token = json_data["access_token"]
            self.instance_url = json_data["instance_url"]
        except Exception as e:
            logger.error(f"Error making OAuth request: {e}")
            raise
        logger.info("OAuth request successful")


class MhiSalesData(Base):
    """Salesforce client for retrieving MHI sales data.

    This class extends the Base class to provide specific functionality for
    accessing MHI sales data through Salesforce's custom Apex REST endpoints.
    It handles authentication and provides methods to retrieve sales data
    for specified dates.

    Attributes:
        api_sub_domain (str): The Salesforce subdomain used for API calls.

    Inherits all attributes from Base class:
        jwt_token (str): The JWT token for authentication.
        sub_domain (str): The Salesforce subdomain for authentication.
        bearer_token (str): The OAuth access token.
        instance_url (str): The Salesforce instance URL.
    """

    def __init__(
        self, jwt_token: str, auth_sub_domain: str, api_sub_domain: str
    ) -> None:
        """Initialize MhiSalesData with authentication and API subdomains.

        Args:
            jwt_token (str): The JWT token for Salesforce authentication.
            auth_sub_domain (str): The Salesforce subdomain for authentication
                (e.g., 'login' for production, 'test' for sandbox).
            api_sub_domain (str): The Salesforce subdomain for API calls. For example,
                a value of "MY_SALESFORCE_SUBDOMAIN" would get added to the full URL to produce
                "MY_SALESFORCE_SUBDOMAIN.my.salesforce.com".

        Raises:
            Exception: If authentication fails during parent class initialization.
        """
        super().__init__(jwt_token, auth_sub_domain)
        self.api_sub_domain = api_sub_domain

    def get_sales_data(self, call_date: str, endpoint: str = "getSalesData") -> dict:
        """Retrieve sales data for a specified date.

        Makes a POST request to the MHI Salesforce Apex REST service to retrieve
        sales data for the given date. Handles special cases where no data is found
        and returns an empty list instead of raising an exception.

        Args:
            call_date (str): The date for which to retrieve sales data.
                Should be in a format accepted by the Salesforce API (e.g., 'YYYY-MM-DD').

        Returns:
            dict: Sales data records keyed by record identifier. Returns an empty dict if no data
                is found for the specified date.

        Raises:
            Exception: If the API request fails with a status code other than 200,
                or if there's a server error that's not related to missing data.

        Note:
            The method handles a specific server response (HTTP 404 with message
            'No mhi calls found with the date:') as a
            valid "no data found" scenario and returns an empty list.
        """
        url = f"https://{self.api_sub_domain}.my.salesforce.com/services/apexrest/webapi/v1/MHIService/{endpoint}"
        data = {"callDate": call_date}

        logger.info(f"Getting sales data from {url}")
        logger.info(f"Data: {data}")

        headers = {"Authorization": f"Bearer {self.bearer_token}"}
        response = requests.post(url, headers=headers, json=data, timeout=30)

        if response.status_code != 200:
            # Handle specific case where no sales data is found
            if (
                response.status_code == 404
                and response.text == f"No mhi calls found with the date: {call_date}"
            ):
                logger.info("No sales data found for the specified date")
                return {}

            logger.error(f"Error getting sales data: {response.status_code}")
            logger.error(f"Response: {response.text}")
            raise Exception(
                f"Error getting sales data: {response.status_code} - {response.text}"
            )

        logger.info("Successfully got sales data")
        return response.json()
