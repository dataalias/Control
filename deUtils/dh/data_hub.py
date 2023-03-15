"""
*******************************************************************************
File: data_hub.py

Purpose: Defines the class methods and properties for dh.


Class: dh :: Class to allow python packages to interact with the datahub database.

Methods:
    __init__ :: Takes the provided secret key and creates a mssql database connection to the database
                that hosts the ctl and pg schema.
    connect :: Private, establishes the database connection.
    get_secret :: Private, looks up the secret data from AWS.
    get_publication_list: Returns a list of publications associated with the provided publisher_code
    * get_publication_record: Deprecated
    get_publication_code: Returns the active publication code for the data hub object.
    set_publication_code: Allows the user to set / change the active publication Code.
    get_publication_idx: Returns the active publication index  for the data hub object.
    set_publication_idx: N/A set publication code now sets the index as well.
    insert_new_issue: Takes stored issue information and inserts it to the db. Returns IssueId
    update_issue: Takes stored issue information and updates it to the db based on stored IssueId
    is_issue_absent: Returns a true or false based on the file name's presence in data hub.
    get_issue_id: Gets the IssueId of the current publication -1 if the issue hasn't been inserted yet.
    set_issue_val
    notify_subscriber_of_distribution: Requires IssueId and kicks off down stream posting groups if all dependencies
        are met.


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

import dh.data_hub_connection as dh_connect
import secrets.aws_secrets as dh_secret


class DataHub:
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
            database=self.secret['database']
        )

    def __del__(self):
        self.db_connection.close()

    @classmethod
    def connect(cls, host, user, password, database):
        """
        Get database connection object to manage all stored procedures calls
        :return: connection to the dh database.
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
            print('dh.set_publication_code Failed', self.publication_code, e)

    def get_publication_idx(self):
        """
        Simple setter method for the publication_code
        :return:
        """
        return self.publication_idx

    def get_issue_id(self):
        """
        Simple setter method for the publication_code
        :return:
        """
        try:
            return self.issue_list[self.publication_idx]['IssueId']
        except Exception as e:
            print('dh.get_issue_id Failed', e)
            return -1

    def set_issue_val(self, issue_updates):
        """
        Simple setter method for the publication_code
        :param issue_updates :: A dictionary list of issue attributes and values that need to be modified for the
            currently active publication.
        :return:
        """
        self.issue_list[self.publication_idx].update(issue_updates)


    def get_publication_list(self, params):
        """
        Return publication list
        :return:
        """
        response = {'Status': 'Failure'}
        success = {'Status': 'Success'}
        try:
            self.publication_list = dh_connect.get_publication_list(self.db_connection, params)
            self.issue_list = dh_connect.prepare_issues(self.publication_list)
            # set the publication code and index to the first value returned.
            if self.publication_list:

                # print(self.publication_list)
                # print(self.issue_list)
                self.publication_code = self.publication_list[0]['PublicationCode']
                self.publication_idx = self.issue_list[0][self.publication_code]
                # print('DataHub.get_publication_code() = ', self.publication_code)
                # print('DataHub.get_publication_idx() = ', self.publication_idx)

            response = success

        except Exception as e:
            print("dh.get_publication_list :: Can't get publication list :: ", e)

        return response

    def get_publication_record(self, params):
        """
        DEPRECATED
        Return publication record.
        :return:
        """
        response = {'Status': 'Failure'}
        success = {'Status': 'Success'}
        try:
            self.publication_list = dh_connect.get_publication_record(self.db_connection, params)
            self.issue_list = dh_connect.prepare_issues(self.publication_list)
            response = success
        except Exception as e:
            print("dh.get_publication_record :: Can't get publication record :: ", e)

        return response

    def insert_new_issue(self):  # , issue):
        """
        Create a record given a set of parameters needed to create an issue. The newly issued
        IssueId will be updated in the parameter set for use when updating later.
        :param issue: This dictionary object includes each of the parameters needs to insert a new issue.
        :return: success or failure.
        """
        response = {'Status': 'Failure'}
        success = {'Status': 'Success'}
        try:
            issue_id = dh_connect.insert_new_issue(self.db_connection, self.issue_list[self.publication_idx])
            # print('Issue Id Returned:', issue_id)
            self.db_connection.commit()
            self.issue_list[self.publication_idx].update(issue_id[0])
            response.update(success)
        except Exception as e:
            print("dh.insert_new_issue :: Can't insert new issue to database. ", e)
            self.db_connection.rollback()
        finally:
            return response

    def update_issue(self, issue):
        """
        Update an existing record in the database with the issue passed. This is derived from the
            currently active publication's associated issue stored as a property in the data hub class.
        :param issue: A dictionary object that includes all or a subset of values used to update an issue record prior
            to writing to the database.
        :return:  {'Status': 'Success'} on successful execution
                  {'Status': 'Failure'} on failure of execution
        """
        response = {'Status': 'Failure'}
        success = {'Status': 'Success'}
        try:
            # print('dh.update_issue About to update:', issue)
            # print('Updating Issue List')
            # print(self.issue_list[self.publication_idx])
            self.issue_list[self.publication_idx].update(issue)
            response = dh_connect.update_issue(self.db_connection, self.issue_list[self.publication_idx])
            # response = dh_connect.update_issue(self.db_connection, issue)
            self.db_connection.commit()
            response.update(success)
        except Exception as e:
            print("dh.update_issue :: Can't update issue: ", e)
            self.db_connection.rollback()

        return response

    def is_issue_absent(self, file_name):
        """
        This function determines if an issue has been processed already via a lookup in the issue table.
        :param file_name: Name of the file to be looked up.
        :return: True: The file is absent and should be processed by the system.
                 False: The file has already been processed and should _not_ be loaded again.
        """
        # Determine if the file has already been processed by looking at ctl.issue.
        response = False
        try:
            response = dh_connect.is_issue_absent(self.db_connection, file_name)
        except Exception as e:
            print("dh.is_issue_absent :: Failed to execute is_issue_absent: ", e)
        return response

    def notify_subscriber_of_distribution(self):
        """
        :param self DataHub object.
        :return: response {'Status': 'Failure'} _or_ {'Status': 'Failure'}
        """
        response = {'Status': 'Failure'}
        success = {'Status': 'Success'}
        try:
            # print('DataHub.notify_subscriber_of_distribution About to notify: ', self.issue_list[self.publication_idx]['IssueId'])
            response = dh_connect.notify_subscriber_of_distribution(self.db_connection,
                                                                    self.issue_list[self.publication_idx])
            response.update(success)
        except Exception as e:
            print("dh.notify_subscriber_of_distribution :: Unable to trigger notification and down stream process: ", e)
            self.db_connection.rollback()

        return response


"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
acosta		01/08/2022  Initial Iteration
ffortunato  04/08/2022  + get_db_connection_from_secret
ffortunato  04/11/2022  o pyODBC --> pymssql
ffortunato  04/22/2022  + multiple new methods for the class.
                        + issue_list to maintain issue data along with the class
ffortunato  07/29/2022  + Improving exception messages but still more to do.
ffortunato  08/05/2022  + notify_subscriber_of_distribution
ffortunato  03/15/2023  o merge conflicts
*******************************************************************************
"""
