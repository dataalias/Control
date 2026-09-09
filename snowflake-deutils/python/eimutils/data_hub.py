from eimutils.aws_secrets import get_secrets
from eimutils.delogging import log_to_console
from typing import Any
from eimutils.data_hub_connection import (
    get_publication_list,
    prepare_issues,
    insert_new_issue,
    update_issue,
    is_issue_absent,
)
from eimutils.utils import get_snowflake_connection_from_secret
import json
import pandas as pd
import warnings

"""
*******************************************************************************
File: data_hub.py

Purpose: Defines the class methods and properties for dh.


Class: dh :: Class to allow python packages to interact with the datahub database.

Methods:
    __init__ :: Takes the provided secret key and creates a Snowflake database connection to the database
                that hosts the DATA_HUB schema.
    connect :: Private, establishes the database connection.
    get_secret :: Private, looks up the secret data from AWS.
    get_publication_list: Returns a list of publications associated with the provided publisher_code
    * get_publication_record: Deprecated

    get_publication_code: Returns the active publication code for the data hub object.
    set_publication_code: Allows the user to set / change the active publication Code.
    get_publication_idx: Returns the active publication index  for the data hub object.
    set_publication_idx: N/A set publication code now sets the index as well.

    get_issue_details: NOT YET IMPLEMENTED — raises NotImplementedError.

    write_issue: Insert or update the current publication's issue — inserts if no IssueId exists yet,
        updates otherwise. Accepts an optional dict of values to merge before writing.
    insert_new_issue: Deprecated — use write_issue().
    update_issue: Deprecated — use write_issue().
    is_issue_absent: Returns a true or false based on the file name's presence in data hub.
    get_issue_id: Gets the IssueId of the current publication -1 if the issue hasn't been inserted yet.
    set_issue_val
    notify_subscriber_of_distribution: (Not Yet Implemented) Requires IssueId and kicks off downstream posting
        groups if all dependencies are met.


    TODO: make get_publication_list part of the class __init__.
Properties:

    publication_list = () :: Dataframe of publications associated with the publisher.
    issue_list = [] :: An array of issues derived from the publication list. This is a list of the issues that we are
        trying to load. The LAST position in the list (issue_list[-1]) is a lookup dictionary mapping publication
        codes to their integer indices in the list. Positions [0..N-2] are individual issue dictionaries, one per
        publication. Always access the index via issue_list[len(issue_list) - 1] or issue_list[-1].
    publication_idx = int :: Position of the active publication_code for the object.
    publication_code = str :: Currently active publication code for the object.

Dependencies/Helpful Notes :

*******************************************************************************
"""

"""
TODO: Consolidate data_hub_connection into the class
TODO: Forget getter and setter — just call the property directly.
TODO: Clarify params for each of the calls, specifically get_publication_list.
TODO: Configuration for datahub connection
"""


class DataHub:
    """
    This class is used to interact with the dh/dh database objects.
    """

    def __init__(self, secret_key: str, env: str) -> None:
        """
        Creates a connection to the control/datahub database using an AWS secret key.
        We also set up some properties for use later. The definition for these properties are in the class comments.

        :param secret_key: AWS Secrets Manager ARN containing Snowflake credentials.
        :param env: Environment name ("DEV", "STAGE", or "PROD"). Uppercased internally and used to construct
            the target database name (e.g. ULTRA_DEV_RAW).
        """
        self.issue_list = []
        self.publication_list = pd.DataFrame()
        self.publication_idx = -1
        self.publication_code = "Unknown"
        self.current_publication = {}
        self.get_type = "Unknown"
        self.aws_region = "us-west-2"
        self.secret_key = secret_key
        self.env = env.upper()
        self.database = f"ULTRA_{self.env}_RAW"

        self.secret = self.get_secrets()
        self.db_connection = self.connect()

    def __enter__(self):
        return self

    def __exit__(self, *_):
        self.close()
        return False

    def close(self):
        if hasattr(self, "db_connection") and self.db_connection:
            self.db_connection.close()
            self.db_connection = None

    def __del__(self):
        try:
            self.close()
        except Exception:
            pass

    # @classmethod
    # def connect(cls, host, user, password, database):
    def connect(self) -> Any:
        """
        Get database connection object to manage all stored procedures calls
        :return: connection to the dh database.
        """
        # get_snowflake_connection_from_secret(secret_arn, env, aws_region, \
        # envlayer='', brand='', project='', spark_session = False):

        return get_snowflake_connection_from_secret(
            secret_arn=self.secret_key,
            env=self.env,
            aws_region=self.aws_region,
            envlayer="RAW",
            brand="",
            project="",
            database=self.database,
            spark_session=False,
        )

    # @classmethod
    def get_secrets(self) -> dict:
        # dictSecrets = json.loads(secrets)
        return json.loads(get_secrets(self.secret_key, self.aws_region))

    def get_publication_code(self) -> str:
        """
        Simple getter method for the publication_code
        :return:
        """
        # print('in get_publication_code and I should return:', self.publication_code)
        return self.publication_code

    def set_publication_code(self, publication_code: str) -> None:
        """
        We are going to set the publication code and get the index from the publication list too.
        :param publication_code: The code for the publication the calling program is interacting with currently.
        :return:
        """
        try:
            self.publication_code = publication_code
            if not self.publication_list.empty:
                self.publication_idx = self.issue_list[len(self.issue_list) - 1][
                    self.publication_code
                ]
                self.current_publication = self.publication_list.iloc[
                    self.publication_idx
                ].to_dict()
        except Exception as err:
            error_msg = "data_hub.set_publication_code Failed :: publication_code:{} \
                Error:{}".format(
                self.publication_code, err
            )
            log_to_console(__name__, "Error", error_msg)
            raise

    def get_current_publication(self) -> dict:
        """
        Simple getter method for the current publication
        :return: the current publication as a dictionary
        """
        return self.current_publication

    # depricate this one ... just use the property.
    def get_publication_idx(self) -> int:
        """
        Simple getter method for the publication_idx
        :return:
        """
        return self.publication_idx

    def get_issue_id(self) -> int:
        """
        Simple getter method for the current issue ID
        :return:
        """
        try:
            return self.issue_list[self.publication_idx]["IssueId"]
        except Exception as err:
            error_msg = "data_hub.get_issue_id :: Failed. Error:{}".format(err)
            log_to_console(__name__, "Error", error_msg)
            return -1

    def set_issue_val(self, issue_updates: dict) -> None:
        """
        Simple setter method for updating the classes issue_list. Changes not written to database.
        :param issue_updates :: A dictionary list of issue attributes and values that need to be modified for the
            currently active publication.
        :return:
        """
        if self.publication_idx < 0:
            raise RuntimeError(
                "set_issue_val called before a publication was selected. "
                "Call get_publication_list() and set_publication_code() first."
            )
        self.issue_list[self.publication_idx].update(issue_updates)

    def get_publication_list(self, params: dict) -> dict:
        """
        Return publication list
        :return:
        """
        response = {"Status": "Failure"}
        success = {"Status": "Success"}
        try:
            if "TriggerTypeCode" in params and params["TriggerTypeCode"] == "SCH":
                self.get_type = "Schedule"
            elif "PublisherCode" in params:
                self.get_type = "PublisherCode"
            elif "PublicationFilePath" in params:
                self.get_type = "PublicationFilePath"
            elif "IssueId" in params:
                self.get_type = "IssueId"
            elif "FileName" in params:
                self.get_type = "FileName"
            else:
                error_msg = "data_hub.get_publication_list :: Failed. '(DataHub Custom) Invalid parameters passed to \
                    get_publication list.: {}".format(
                    params
                )
                raise Exception(error_msg)

            self.publication_list = get_publication_list(
                self.db_connection, params, self.get_type
            )
            self.issue_list = prepare_issues(self.publication_list)

            # set the publication code and index to the first value returned.
            if not self.publication_list.empty:
                self.publication_code = self.publication_list.loc[
                    0, "PUBLICATIONCODE"
                ]
                self.publication_idx = 0
                response = success

        except NotImplementedError:
            raise
        except Exception as err:
            error_msg = "data_hub.get_publication_list :: Failed. Error: {}".format(err)
            log_to_console(__name__, "Error", error_msg)
            if self.publication_list.empty:
                # No publication list was returned. This isn't necessarily an error.
                response["Message"] = "No Publication list was returned."
            else:
                raise Exception(error_msg)

        return response

    def write_issue(self, issue: dict = None) -> dict:
        """
        Insert or update the current publication's issue depending on whether an IssueId already exists.
        Merges any values in `issue` into the active issue before writing.

        :param issue: Optional dict of issue attributes to apply before writing.
        :return: {'Status': 'Success'} on successful execution.
        """
        if issue:
            self.issue_list[self.publication_idx].update(issue)

        current_issue = self.issue_list[self.publication_idx]
        issue_id = current_issue.get("IssueId")
        has_id = issue_id is not None and str(issue_id) != "-1"

        if not has_id:
            return self._insert_new_issue()
        else:
            return self._update_issue()

    def _insert_new_issue(self) -> dict:
        response = {"Status": "Failure"}
        success = {"Status": "Success"}
        try:
            issue_id = insert_new_issue(
                self.db_connection, self.issue_list[self.publication_idx]
            )
            self.issue_list[self.publication_idx].update(issue_id)
            response = success
        except Exception as err:
            error_msg = "data_hub.write_issue (insert) :: Failed inserting new issue. Error:{}".format(err)
            log_to_console(__name__, "Error", error_msg)
            self.db_connection.rollback()
            raise Exception(error_msg)
        return response

    def _update_issue(self) -> dict:
        response = {"Status": "Failure"}
        success = {"Status": "Success"}
        try:
            response = update_issue(
                self.db_connection, self.issue_list[self.publication_idx]
            )
            response.update(success)
        except Exception as err:
            error_msg = "data_hub.write_issue (update) :: Failed updating existing issue. Error:{}".format(err)
            log_to_console(__name__, "Error", error_msg)
            self.db_connection.rollback()
            raise Exception(error_msg)
        return response

    def insert_new_issue(self) -> dict:
        """
        Deprecated — use write_issue() instead.

        Create a record given a set of parameters needed to create an issue. The newly issued
        IssueId will be updated in the parameter set for use when updating later.
        :return: success or failure.
        """
        warnings.warn(
            "insert_new_issue() is deprecated; use write_issue() instead.",
            DeprecationWarning,
            stacklevel=2,
        )
        response = {"Status": "Failure"}
        success = {"Status": "Success"}
        try:
            # print('dh.insert_new_issue')
            # print(self.issue_list[self.publication_idx])
            issue_id = insert_new_issue(
                self.db_connection, self.issue_list[self.publication_idx]
            )
            self.issue_list[self.publication_idx].update(issue_id)
            response = success

        except Exception as err:
            error_msg = "data_hub.insert_new_issue :: Failed inserting new issue to database. Error:{}".format(
                err
            )
            log_to_console(__name__, "Error", error_msg)
            self.db_connection.rollback()
            raise Exception(error_msg)

        return response

    def update_issue(self, issue: dict) -> dict:
        """
        Deprecated — use write_issue() instead.

        Update an existing record in the database with the issue passed.
        :param issue: A dictionary object that includes all or a subset of values used to update an issue record prior
            to writing to the database.
        :return:  {'Status': 'Success'} on successful execution
                  {'Status': 'Failure'} on failure of execution
        """
        warnings.warn(
            "update_issue() is deprecated; use write_issue() instead.",
            DeprecationWarning,
            stacklevel=2,
        )
        response = {"Status": "Failure"}
        success = {"Status": "Success"}
        try:
            self.issue_list[self.publication_idx].update(issue)
            response = update_issue(
                self.db_connection, self.issue_list[self.publication_idx]
            )
            response.update(success)
        except Exception as err:
            error_msg = "data_hub.update_issue :: Failed updating existing issue to database. Error :: {}".format(
                err
            )
            log_to_console(__name__, "Error", error_msg)
            self.db_connection.rollback()
            raise Exception(error_msg)

        return response

    def notify_subscriber_of_distribution(self, issue_id: int) -> dict:
        """
        Kicks off downstream posting groups for all subscribers once all issue dependencies are met.
        :param issue_id: IssueId of the issue whose distributions should be notified.
        :return: Status dictionary.
        """
        raise NotImplementedError("notify_subscriber_of_distribution is not yet implemented.")

    def get_issue_details(self, identifier) -> dict:
        """
        Gets the latest issue details for a given file name or issue ID.
        :param identifier: File name (str) or IssueId (int) to look up.
        :return: Issue details dictionary.
        """
        raise NotImplementedError("get_issue_details is not yet implemented.")

    def is_issue_absent(self, file_name: str) -> bool:
        """
        This function determines if an issue has been processed already via a lookup in the issue table.
        :param  self: DataHub object.
                file_name: Name of the file to be looked up.
        :return: True: The file is absent and should be processed by the system.
                 False: The file has already been processed and should _not_ be loaded again.
        """
        # Determine if the file has already been processed by looking at ctl.issue.
        try:
            return is_issue_absent(self.db_connection, file_name)
        except Exception as err:
            error_msg = (
                "data_hub.is_issue_absent :: Failed looking up issue. Error:{}".format(
                    err
                )
            )
            log_to_console(__name__, "Error", error_msg)
            raise Exception(error_msg)


"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
acosta		01-08-2022  Initial Iteration
ffortunato  04-08-2022  + get_db_connection_from_secret
ffortunato  04-11-2022  o pyODBC --> pymssql
ffortunato  04-22-2022  + multiple new methods for the class.
                        + issue_list to maintain issue data along with the class
ffortunato  07-29-2022  + Improving exception messages but still more to do.
ffortunato  08-05-2022  + notify_subscriber_of_distribution
ffortunato  2023-05-22    o modified logging to us log to console.
ffortunato  2023-09-18    ~ working with imports...
ffortunato  2025-07-22    o foratting.
*******************************************************************************
"""
