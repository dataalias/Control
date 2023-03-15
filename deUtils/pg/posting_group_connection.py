"""
*******************************************************************************
File: posting_group_connection.py

Purpose: Core functions invoked by the Posting Group class that interact with the db.

Dependencies/Helpful Notes :

*******************************************************************************
"""

import pymssql


def connect_database(host, user, password, database):
    """
    Creates a pymssql connection for use by the class
    :return: pymssql connection
    """
    try:
        conn = pymssql.connect(host, user, password, database)
    except pymssql.Error as err:
        # TODO: log errors in CloudWatch
        print("connection.connect_database :: Connection error.", err)
        return {'Status': 'Failure'}

    return conn


"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
ffortunato  08/09/2022  Initial Iteration
*******************************************************************************
"""