"""
***********************************************************************************************************************
File: api_call.py

Purpose: Call and API.

Dependencies/Helpful Notes :

***********************************************************************************************************************
"""

from eimutils.delogging import log_to_console
import requests


"""
***********************************************************************************************************************
Function: download_file

Purpose: Downlaod file from API.

Parameters:
     url - URL of the file to download
     local_filename - Local file name to save the downloaded content

Calls:
Called by:
Returns:

***********************************************************************************************************************
"""


def download_file(url: str, local_filename: str) -> None:
    # Download the file from the URL
    try:
        response = requests.get(url, timeout=30)
        if response.status_code == 200:
            with open(local_filename, "wb") as file:
                file.write(response.content)
            log_to_console(__name__, "Info", f"Downloaded {local_filename}")
        else:
            log_to_console(
                __name__, "Error", f"Failed to download file: {response.status_code}"
            )
    except Exception as e:
        e_msg = "Issue with file download: " + str(e)
        log_to_console(__name__, "Error", e_msg)
        raise Exception(e_msg)


"""
***********************************************************************************************************************
Change History:

Author		Date		Description
----------	----------	-----------------------------------------------------------------------------------------------
ffortunato  2024-11-01  + initial iteration
ffortunato  2025-07-22  o formatting.
***********************************************************************************************************************
"""
