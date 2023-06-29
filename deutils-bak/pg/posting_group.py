"""
*******************************************************************************
File: posting_group.py

Purpose: Defines the class methods and properties for posting groups.


Class: PostingGroup :: Class to allow python packages to interact with the datahub database.

Methods:
    __init__ :: Takes the provided secret key and creates a mssql database connection to the database
                that hosts the ctl and pg schema.
    connect :: Private, establishes the database connection.

Properties:


Dependencies/Helpful Notes :

*******************************************************************************
"""

import pg.posting_group_connection as pg_connect
import secrets.aws_secrets as pg_secret


class PostingGroup:
    """
    This class is used to interact with the dh/dh database objects.
    """

    def __init__(self, secret_key):
        """
        Creates a connection to the control/datahub database using an AWS secret key.
        We also set up some properties for use later. The definition for these properties are in the class comments.

        :param secret_key: This is the key in aws secrets that stores credentials to the database.
        """

        self.secret = self.get_secret(
            secret_key=secret_key
        )
        self.db_connection = self.connect(
            host=self.secret['host'],
            user=self.secret['user'],
            password=self.secret['password'],
            database=self.secret['database']
        )

    @classmethod
    def get_secret(cls, secret_key):
        return pg_secret.get_secret(secret_key)

    @classmethod
    def connect(cls, host, user, password, database):
        """
        Get database connection object to manage all stored procedures calls
        :return: connection to the dh database.
        """
        return pg_connect.connect_database(
            host=host,
            user=user,
            password=password,
            database=database
        )

    def update_posting_group_processing_status(self):

"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
ffortunato	08/09/2022  Initial Iteration
*******************************************************************************
"""