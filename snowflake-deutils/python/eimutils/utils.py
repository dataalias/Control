"""
***********************************************************************************************************************
File: deUtils.py

Purpose: Creates some nice helper functions

Dependencies/Helpful Notes :

***********************************************************************************************************************
"""

from eimutils.aws_secrets import get_secrets
from eimutils.decrypt import getDERKey, getPEMKey
from eimutils.delogging import log_to_console
from eimutils.logger import get_logger
from eimutils.snowflake_connection import connect_database
from typing import Any, Union

import pandas as pd
import re
import time
import json
from datetime import datetime, timedelta, date
import pytz

get_logger(__name__)

_IDENTIFIER_RE = re.compile(r'^[A-Za-z_][A-Za-z0-9_$]*$')


def _validate_identifier(name: str) -> None:
    if not _IDENTIFIER_RE.match(name):
        raise ValueError(f"Invalid SQL identifier: {name!r}")


"""
***********************************************************************************************************************
Function: get_snowflake_connection_from_secret

Purpose: Generate a database connection from AWS secret.

Parameters:
    secret_arn - AWS secret name from the account the process is running in
                 that contains the db connection information. Required.
    env - Snowflake environment, DEV/STAGE/PROD. Required.
    aws_region - Region the secret is stored. e.g. MY_AWS_REGION. Required.
    envlayer - Environment layer, RAW/CURATION/WAREHOUSE.  Required when build 3.1 roles.
    brand - {MY_ORG, MY_BRAND_2, or MY_BRAND_3} Required when build 3.1 roles.
    project - Name of the project that is used within the role. Required when build 3.1 roles.
    spark_session - flag indicating, whether sfOptions for spark dataframe usage should be returned


Calls:
    get_secret
    connect_database

Called by:

Returns: database connection, SfOptions (only for Spark sessions)

***********************************************************************************************************************
"""


def get_snowflake_connection_from_secret(
    secret_arn: str,
    env: str,
    aws_region: str,
    envlayer: str = "",
    brand: str = "",
    project: str = "",
    database: str = "",
    spark_session: bool = False,
) -> Any:

    # Testing
    """
    print('The following were passed into get_snowflake_connection_from_secret:')
    print('secret_arn: {}'.format(secret_arn))
    print('env: {}'.format(env))
    print('aws_region: {}'.format(aws_region))
    print('envlayer: {}'.format(envlayer))
    print('brand: {}'.format(brand))
    print('project: {}'.format(project))
    print('project: {}'.format(database))
    print('spark_session: {}'.format(spark_session))
    """

    try:
        # get the secret
        # ToDo: Add Role to the secret. Then we can remove env.
        msg = "Executing. About to get secrets."
        log_to_console(__name__, "Info", msg)
        secrets = get_secrets(secret_arn, aws_region)
        dictSecrets = json.loads(secrets)

        msg = "Validating secret values."
        log_to_console(__name__, "Info", msg)

        # Identifying the user
        if "DW30SFSVCUSER" in dictSecrets:
            my_user = dictSecrets["DW30SFSVCUSER"]
        else:
            msg = "Valid user not returned from secret."
            log_to_console(__name__, "Err", msg)
            raise ValueError(msg)

        # Identifying the keys
        # Decrypt the pkbDER & pkbPEM key
        if "DW30SFSVCPKEY" in dictSecrets and "DW30SFSVCPPRS" in dictSecrets:
            my_pkbDER = getDERKey(
                dictSecrets["DW30SFSVCPKEY"], dictSecrets["DW30SFSVCPPRS"]
            )
            my_pkbPEM = getPEMKey(
                dictSecrets["DW30SFSVCPKEY"], dictSecrets["DW30SFSVCPPRS"]
            )

        elif (
            f"SFSVCPKEY{envlayer}" in dictSecrets
            and f"SFSVCPPRS{envlayer}" in dictSecrets
        ):
            my_pkbDER = getDERKey(
                dictSecrets[f"SFSVCPKEY{envlayer}"], dictSecrets[f"SFSVCPPRS{envlayer}"]
            )
            my_pkbPEM = getPEMKey(
                dictSecrets[f"SFSVCPKEY{envlayer}"], dictSecrets[f"SFSVCPPRS{envlayer}"]
            )
        elif "DSSFSVCPKEY" in dictSecrets and "DSSFSVCPPRS" in dictSecrets:
            my_pkbDER = getDERKey(
                dictSecrets["DSSFSVCPKEY"], dictSecrets["DSSFSVCPPRS"]
            )
            my_pkbPEM = getPEMKey(
                dictSecrets["DSSFSVCPKEY"], dictSecrets["DSSFSVCPPRS"]
            )
        elif "SFSVCPKEY" in dictSecrets and "SFSVCPPRS" in dictSecrets:
            my_pkbDER = getDERKey(dictSecrets["SFSVCPKEY"], dictSecrets["SFSVCPPRS"])
            my_pkbPEM = getPEMKey(dictSecrets["SFSVCPKEY"], dictSecrets["SFSVCPPRS"])

        else:
            msg = "Valid private key not returned from secret."
            log_to_console(__name__, "Err", msg)
            raise ValueError(msg)

        # Identifying the role.
        if brand != "" and project != "":
            my_role = f"{brand}_{env}_{project}_{envlayer}_ADMIN"
            msg = "Built 3.1 Composite Role."
            log_to_console(__name__, "Info", msg)

        elif f"SFROLE{envlayer}" in dictSecrets:
            my_role = dictSecrets[f"SFROLE{envlayer}"]
            msg = "Retrieved 3.1 Role from secret."
            log_to_console(__name__, "Info", msg)

        elif "SFROLE" in dictSecrets:
            my_role = dictSecrets["SFROLE"]
            msg = "Retrieved 3.1 Role from secret."
            log_to_console(__name__, "Info", msg)

            # ToDo: Remove hack so i dont need to wait on platform to remove the care secret for pipeline role.
            if my_role == "PIPELINE_DEV_SVC":
                my_role = ""
                msg = "Removed Role from secret."
                log_to_console(__name__, "Info", msg)

        elif "DSROLE" in dictSecrets:
            my_role = dictSecrets["DSROLE"]
            msg = "Retrieved 3.1 Data Science Role from secret."
            log_to_console(__name__, "Info", msg)

        elif "SFSVCUSER" in dictSecrets and dictSecrets["SFSVCUSER"] == f"EIM_{env}_BRAZE_SVC_USER":
            my_role = f"EIM_{env}_BRAZE_ADMIN"
            msg = "Assuming default role for braze."
            log_to_console(__name__, "Info", msg)

        else:
            # default for DW30
            my_role = f"EIM_{env}_DW3_ADMIN"
            msg = "Built default 3.0 Role."
            log_to_console(__name__, "Info", msg)
        # Identify the Account
        if "SFACCOUNT" in dictSecrets:
            my_account = dictSecrets["SFACCOUNT"]
            msg = "Valid account returned from secret."
            if '-' not in my_account:
                my_account = f"EDS-{my_account}"
                msg = "Valid account returned from secret. Prepending the org name."
            log_to_console(__name__, "Warn", msg)
        else:
            my_account = "EDS-uvnv"
            msg = "Valid account not returned from secret. Using default value."
            log_to_console(__name__, "Warn", msg)

        # ToDo: Create the connection to snowflake using connect_database in snowflake_connection.py
        msg = "Creating Snowflake connection."
        log_to_console(__name__, "Info", msg)

        # Testing
        """
        print("\n")
        print('='*100)
        print('account: {}'.format(my_account))
        print('database: {}'.format(database))
        print('user: {}'.format(my_user))
        # print('pkbDER: {}'.format(my_pkbDER))
        print('role: {}'.format(my_role))
        print('='*100)
        print("\n")
        """

        db_connection = connect_database(
            my_user, my_account, my_pkbDER, my_role, database
        )

    except Exception as e:
        log_to_console(__name__, "Err", str(e))
        raise

    # Return the baseline for sfOptions if spark session is used
    if spark_session:
        sfOptions = {
            "sfURL": "uvnv.snowflakecomputing.com",
            "sfUser": my_user,
            "pem_private_key": my_pkbPEM,
            "sfDatabase": f"{env}",
            "sfSchema": "",
            "sfWarehouse": "",
        }
        return db_connection, sfOptions
    else:
        return db_connection


"""
***********************************************************************************************************************
Function: read_google_sheet

Purpose: Read data from a Google Sheet and return a DataFrame.

Parameters:
    google_sheet  - name or ID of the Google Sheet. Required.
    name          - name of the worksheet to read. Required.
    client        - authenticated Google Sheet client. Required.
    spark_session - Spark Session if using Spark.

Calls:

Called by:

Returns: Pandas DataFrame or pyspark.sql.DataFrame

***********************************************************************************************************************
"""


def read_google_sheet(google_sheet, name, client, spark_session=None):

    try:
        # Reading google sheet
        data_sheet = client.open(google_sheet).worksheet(name)

        # Getting all values from the sheet
        data_values = data_sheet.get_all_values()
        headers = data_values[0]
        rows = data_values[1:]

        # Returning appropriate DataFrame type
        if spark_session:
            df = spark_session.createDataFrame(rows, headers)
        else:
            df = pd.DataFrame(rows, columns=headers)

    except Exception as e:
        log_to_console(__name__, "Err", str(e))
        raise

    return df

"""
***********************************************************************************************************************
Change History:

Author      Date        Description
----------  ----------  -----------------------------------------------------------------------------------------------
Frank       2023-09-19  Initial Iteration
Darren      2024-02-14  Added env layer (raw/curation/warehouse) to user/key/pass/role
Frank       2024-03-19  Added send_datadog_metric
Frank       2024-03-22  redid datadog loggin a bit.
Frank       2024-03-26  data dog try and catch.
Frank       2024-04-18  Additional Logging. Building 3.1 Roles.
Frank       2024-07-16  Data Science Credentials.
ffortunato  2025-07-22  o formatting
ffortunato  2025-08-14  o secret key changes.
ffortunato  2025-08-21  o logging changes.
***********************************************************************************************************************
"""
