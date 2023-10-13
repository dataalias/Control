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

import posting_group_connection as pg_connect
import aws_secrets as pg_secret
from delogging import log_to_console

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
        self.issue_list = []
        self.publication_list = ()
        self.publication_idx = -1
        self.publication_code = 'Unknown'

        self.secret = self.get_secret(
            secret_key=secret_key
        )
        self.db_connection = self.connect(
            host=self.secret['host'],
            user=self.secret['user'],
            password=self.secret['password'],
            database=self.secret['database'],
            dbInstanceIdentifier=self.secret['dbInstanceIdentifier']
        )

    @classmethod
    def get_secret(cls, secret_key):
        return pg_secret.get_secret(secret_key)

    @classmethod
    def connect(cls, host, user, password, database, dbInstanceIdentifier):
        """
        Get database connection object to manage all stored procedures calls
        :return: connection to the dh database.
        """
        return pg_connect.connect_database(
            host=host,
            user=user,
            password=password,
            database=database,
            dbInstanceIdentifier=dbInstanceIdentifier

        )
    
    
    
    def get_publication_list(self, params):
        """
        THIS IS BS FOR TESTING
        Return publication list
        :return:
        """
        response = {'Status': 'Failure'}
        success = {'Status': 'Success'}
        try:
            self.publication_list = pg_connect.get_publication_list(self.db_connection, params)

        except Exception as err:
            error_msg = "data_hub.get_publication_list :: Failed. Error:{}".format(err)
            log_to_console(__name__,'Error',error_msg)

    def update_posting_group_processing_status(self):
        """
        :param self DataHub object.
        :return: response {'Status': 'Failure'} _or_ {'Status': 'Failure'}
        """
        response = {'Status': 'Failure'}
        success = {'Status': 'Success'}
        try:

            response.update(success)
        except Exception as e:
            print("pg.update_posting_group_processing_status :: Unable to update pgp status: ", e)
            self.db_connection.rollback()

        return response

"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
ffortunato	08/09/2022  Initial Iteration
ffortunato	08/09/2022  o update_posting_group_processing_status
*******************************************************************************
"""