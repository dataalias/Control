import datahub.connection as dh_connect
import secrets.aws_secrets as dh_secret


class DataHub:

    def __init__(self, secret_key):
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
    def connect(cls, host, user, password, database):
        """
        Get database connection object to manage all stored procedures calls
        :return:
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
        publication_list = {}
        try:
            publication_list = dh_connect.get_publication_list(self.db_connection, params)
        except Exception as e:
            print("Can't get publication list :: ", e)

        return publication_list

    def insert_new_issue(self, issue):
        """
        Create a record given a set of parameters needed to create an issue. The newly issued
        IssueId will be updated in the parameter set for use when updating later.
        :param issue: This dictionary object includes each of the parameters needs to insert a new issue.
        :return: success or failure.
        """
        response = {'Status': 'Failure'}
        success = {'Status': 'Success'}
        try:
            print('from:', __name__, 'Issue val: ', issue)
            issue_id = dh_connect.insert_new_issue(self.db_connection, issue)
            self.db_connection.commit()
            issue.update(issue_id[0])
            response.update(success)
        except Exception as e:
            print("Can't insert new issue ", e)
            self.db_connection.rollback()

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
            response = dh_connect.update_issue(self.db_connection, issue)
            self.db_connection.commit()
            response.update(success)
        except Exception as e:
            print("Can't update issue: ", e)
            self.db_connection.rollback()

        return response
