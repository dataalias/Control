"""
*******************************************************************************
File: deUtils.py

Purpose: Creates some nice helper functions

Dependencies/Helpful Notes : 

*******************************************************************************
"""

from secrets.aws_secrets import *
from DataHub.connection import *
from delogging.delogging import *
from ftp.ftp import *

"""
*******************************************************************************
Function: get_db_connection_from_secret

Purpose: Generate a database connection from AWS secret.

Parameters:
     secret_name - AWS secret name from the account the process is running in
                   that contains the db connection information.  

Calls:
    get_secret
    connect_database
    
Called by:

Returns: database connection

*******************************************************************************
"""


def get_db_connection_from_secret(secret_name):

    try:
        # get the secret
        db_connection_secret = get_secret(secret_name)

        # get the values into variables
        user = db_connection_secret["user"]
        host = db_connection_secret["host"]
        password = db_connection_secret["password"]
        database = db_connection_secret["database"]

        # get the database connection
        db_connection = connect_database(host, user, password, database)

    except Exception as e:
        log_to_console(__name__, 'Err', str(e))

    return db_connection


def get_ftp_connection_from_secret(secret_name):

    try:
        # get the secret
        ftp_connection_secret = get_secret(secret_name)
        print('ftp keys: ', ftp_connection_secret)

        # get the values into variables
        ftp_username = ftp_connection_secret["FTP_USERNAME"]
        ftp_host = ftp_connection_secret["FTP_URL"]
        ftp_password = ftp_connection_secret["FTP_PASSWORD"]
        ftp_port = int(ftp_connection_secret["FTP_PORT"])
        ftp_directory = ftp_connection_secret["FTP_FOLDER"]

        # get the database connection
        ftp_connection = open_ftp_connection(ftp_host, ftp_port, ftp_username, ftp_password, ftp_directory)

    except Exception as e:
        log_to_console(__name__, 'Err', str(e))
        return{'Status': 'Failure'}

    return ftp_connection


"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
Frank		04/08/2022  Initial Iteration
                        + get_db_connection_from_secret

*******************************************************************************
"""