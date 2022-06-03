"""
*******************************************************************************
File: data_hub.py

Purpose: Defines the class methods and properties for DataHub.


Class: DataHub :: Class to allow python packages to interact with the datahub database.

Methods:
    __init__ :: Takes the provided secret key and creates a mssql database connection to the database
                that hosts the ctl and pg schema.
    connect :: Private, establishes the database connection.
    get_secret :: Private, looks up the secret data from AWS.
    get_publication_list: Returns a list of publications associated with the provided publisher_code
    get_publication_code: Returns the active publication code for the data hub object.
    set_publication_code: Allows the user to set / change the active publication Code.
    get_publication_idx: Returns the active publication index  for the data hub object.
    set_publication_idx: N/A set publication code now sets the index as well.
    insert_new_issue: Takes stored issue information and inserts it to the db. Returns IssueId
    update_issue: Takes stored issue information and updates it to the db based on stored IssueId
    is_issue_absent: Returns a true or false based on the file name's presence in data hub.

    T0D0: write_issue -- combine functionality of insert and update issue functions.
    T0D0: make get_publication_list part ofd the class __init__.
Properties:

    publication_list = () :: Tuple of publications associated with the publisher.
    issue_list = [] :: An array of issues derived from the publication list. This is a list of the issues that we are
        trying to load. The first position in the list is a dictionary that points to the other dictionaries in the
        list that represent issues. Subsequent dictionaries in this list represent individual issues.
        The [0] position of the array equates later dictionaries in this array with their publication_code.
    publication_idx = int :: Position of the active publication_code for the object.
    publication_code = str :: Currently active publication code for the object.

Dependencies/Helpful Notes :

*******************************************************************************
"""

import DataHub.connection as dh_connect
import secrets.aws_secrets as dh_secret


class DataHub:
    """
    This class is used to interact with the Control/DataHub database objects.
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
            database=self.secret['database']
        )

    def get_publication_code(self):
        """
        Simple setter method for the publication_code
        :return:
        """
        # print('in get_publication_code and I should return:', self.publication_code)
        return self.publication_code

    def set_publication_code(self, publication_code):
        """
        We are going to set the publication code and get the index from the publication list too.
        :param publication_code: The code for the publication the calling program is interacting with currently.
        :return:
        """
        try:
            self.publication_code = publication_code
           # print('Im setting publications hard', publication_code)
            if self.publication_list:
                self.publication_idx = self.issue_list[0][self.publication_code]
                # print(self.publication_idx)
        except Exception as e:
            print('DataHub.set_publication_code Failed', self.publication_code, e)

    def get_publication_idx(self):
        """
        Simple setter method for the publication_code
        :return:
        """
        return self.publication_idx

    def set_issue_val(self, issue_updates):
        """
        Simple setter method for the publication_code
        :param issue_updates :: A dictionary list of issue attributes and values that need to be modified for the
            currently active publication.
        :return:
        """
        self.issue_list[self.publication_idx].update(issue_updates)

    def __del__(self):
        self.db_connection.close()

    @classmethod
    def connect(cls, host, user, password, database):
        """
        Get database connection object to manage all stored procedures calls
        :return: connection to the DataHub database.
        """
        return dh_connect.connect_database(
            host=host,
            user=user,
            password=password,
            database=database
        )

    @classmethod
    def get_secret(cls, secret_key):
        return dh_secret.get_secret(secret_key)

    def get_publication_list(self, params):
        """
        Return publication data
        :return:
        """
        response = {'Status': 'Failure'}
        success = {'Status': 'Success'}
        try:
            self.publication_list = dh_connect.get_publication_list(self.db_connection, params)
            self.issue_list = dh_connect.prepare_issues(self.publication_list)
            response = success
        except Exception as e:
            print("Can't get publication list :: ", e)

        return response

    def insert_new_issue(self):#, issue):
        """
        Create a record given a set of parameters needed to create an issue. The newly issued
        IssueId will be updated in the parameter set for use when updating later.
        :param issue: This dictionary object includes each of the parameters needs to insert a new issue.
        :return: success or failure.
        """
        response = {'Status': 'Failure'}
        success = {'Status': 'Success'}
        try:
            # print('from:', __name__, 'Issue val: ', issue)
            issue_id = dh_connect.insert_new_issue(self.db_connection, self.issue_list[self.publication_idx])
            # print(issue_id)
            self.db_connection.commit()
            self.issue_list[self.publication_idx].update(issue_id[0])
            response.update(success)
        except Exception as e:
            print("DataHub.insert_new_issue :: Can't insert new issue to database. ", e)
            self.db_connection.rollback()
        finally:
            return response

    def update_issue(self, issue):
        """
        Update an existing records by taking the data issue
        :param issue:
        :return:
        """
        response = {'Status': 'Failure'}
        success = {'Status': 'Success'}
        try:
            # print('DataHub.update_issue About to update:', issue)
            # print('Updating Issue List')
            # print(self.issue_list[self.publication_idx])
            self.issue_list[self.publication_idx].update(issue)
            response = dh_connect.update_issue(self.db_connection, self.issue_list[self.publication_idx])
            # response = dh_connect.update_issue(self.db_connection, issue)
            self.db_connection.commit()
            response.update(success)
        except Exception as e:
            print("Can't update issue: ", e)
            self.db_connection.rollback()

        return response

    def is_issue_absent(self, file_name):
        # Determine if the file has already been processed by looking at ctl.issue.
        try:
            response = dh_connect.is_issue_absent(self.db_connection, file_name)
        except Exception as e:
            print("Failed to execute is_issue_absent: ", e)
        return response

