"""
***********************************************************************************************************************
File: address_parser.py

Purpose: Parse US addresses from raw strings.

Dependencies/Helpful Notes :

***********************************************************************************************************************
"""

import re
import usaddress
from eimutils.delogging import log_to_console

"""
***********************************************************************************************************************
Function: extract_addresses

Purpose: Extract and parse US address components from a raw input string.

Parameters:
     input_string - Raw string containing address data

Calls:
Called by:
Returns: list[dict] of parsed address components

***********************************************************************************************************************
"""


def extract_addresses(input_string: str) -> list:
    """
    Processes a string, extracts and parses address information, and returns a structured list.

    :param input_string: The input string containing raw address data.
    :return: A list of dictionaries with parsed address details.
    """
    addresses = []

    # Split the input string into lines for processing
    lines = input_string.splitlines()

    for line in lines:
        # Remove irrelevant data like email or phone using regex
        line = re.sub(r"[\w._%+-]+@[\w.-]+\.[a-zA-Z]{2,}", "", line)  # Remove emails
        line = re.sub(
            r"\(?\d{3}\)?[\s.\-]\d{3}[\s.\-]\d{4}|\b\d{10}\b", "", line
        )  # Remove phone numbers

        # Attempt to parse the address using usaddress
        try:
            parsed_address, address_type = usaddress.tag(line)
        except Exception as e:
            log_to_console(__name__, "Warn", f"Skipping unparseable address line: {e}")
            continue

        # Extract components from parsed address
        address_line_1 = (
            parsed_address.get("AddressNumber", "")
            + " "
            + parsed_address.get("StreetName", "")
            + " "
            + parsed_address.get("StreetNamePostType", "")
        ).strip()
        address_line_2 = (
            parsed_address.get("OccupancyType", "")
            + " "
            + parsed_address.get("OccupancyIdentifier", "")
        ).strip()
        city = parsed_address.get("PlaceName", "")
        state = parsed_address.get("StateName", "")
        zip_code = parsed_address.get("ZipCode", "")

        # Append structured data to the list
        addresses.append(
            {
                "address_line_1": address_line_1,
                "address_line_2": address_line_2,
                "city": city,
                "state": state,
                "zip_code": zip_code,
            }
        )

    return addresses


# Example usage
# input_data = "Huhert Dan 456 Elm St Suite 22 Anytown CA 90210"
# parsed_addresses = extract_addresses(input_data)
# for address in parsed_addresses:
#    print(address)


"""
***********************************************************************************************************************
Change History:

Author		Date		Description
----------	----------	-----------------------------------------------------------------------------------------------
dan         2024-11-01  + initial iteration
ffortunato  2025-07-22  o formatting.
***********************************************************************************************************************
"""
