"""
*******************************************************************************
File: snowflake_connection.py

Purpose: Core functions invoked by the Data Hub class that interact with the db.

Dependencies/Helpful Notes :

*******************************************************************************
"""

from eimutils.delogging import log_to_console
from typing import Any
import snowflake.connector as sfc

"""
***********************************************************************************************************************
Name:		connect_database
Purpose:    Creates a Snowflake connection.
Example:	connect_database(sf_user, sf_account, pkbDER, sf_role='', sf_database='')
Parameters:

Returns:    db_connection
Called by:  get_snowflake_connection_from_secret
Calls:
Errors:
Author:		ffortunato
Date:		20240401
***********************************************************************************************************************
"""


def connect_database(sf_user: str, sf_account: str, pkbDER: bytes, sf_role: str = "", sf_database: str = "") -> Any:
    """
    Creates a Snowflake connection using private key authentication.
    :return: Snowflake connection
    """
    try:
        if sf_database != "":

            db_connection = sfc.connect(
                user=sf_user,
                account=sf_account,
                private_key=pkbDER,
                role=sf_role,
                database=sf_database,
            )
        else:
            db_connection = sfc.connect(
                user=sf_user,
                account=sf_account,
                private_key=pkbDER,
            )
    except sfc.Error as err:
        e_msg = (
            "snowflake_connection.connect_database :: Connection error. "
            + str(err)
            + " Additional Details :: Database: "
            + sf_database
            + " Role: "
            + sf_role
        )
        log_to_console(__name__, "Error", e_msg)
        raise err
        # return {'Status': 'Failure'}

    return db_connection


"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
ffortunato  2023-11-03  Initial Iteration
ffortunato  2024-09-20  - role=sf_role,
ffortunato  2024-10-02  + database
ffortunato  2025-07-22  o formatting
ffortunato  2025-08-15  + user, account, role
*******************************************************************************
"""
