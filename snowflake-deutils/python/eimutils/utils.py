"""
***********************************************************************************************************************
File: deUtils.py

Purpose: Creates some nice helper functions

Dependencies/Helpful Notes :

***********************************************************************************************************************
"""

from __future__ import annotations

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
    aws_region - Region the secret is stored. e.g. us-west-2. Required.
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
        elif f"SFSVCUSER{envlayer}" in dictSecrets:
            my_user = dictSecrets[f"SFSVCUSER{envlayer}"]
        elif "DSSFSVCUSER" in dictSecrets:
            my_user = dictSecrets["DSSFSVCUSER"]
        elif "SFSVCUSER" in dictSecrets:
            my_user = dictSecrets["SFSVCUSER"]
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
            if '-' not in my_account:
                my_account = f"EDS-{my_account}"
                msg = f"Account '{dictSecrets['SFACCOUNT']}' missing hyphen. Prepended 'EDS-' prefix."
                log_to_console(__name__, "Info", msg)
            else:
                msg = "Valid account returned from secret."
                log_to_console(__name__, "Info", msg)
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
Function: gspread_try_catch

Purpose:
    Due to the "gspread" library returning Exception for each object and those objects' methods,
    and in an attempt to handle these exceptions with the least amount of try/catch blocks,
    this function was created. When working with this function, the gspread documentation
    would be handy to have nearby. You can find that here: https://docs.gspread.org/en/v6.0.1/index.html

Example of Usages Are:
    Creating a gspread client using the "service_account_from_dict()" method and
    passing in credentials to that method for authentication:
    ```
    gs_api = gspread_try_catch(gspread, "service_account_from_dict", gs_creds)
    ```
    This will return a Client instance (gspread.client.Client).
    Documentation: https://docs.gspread.org/en/v6.0.1/api/client.html#gspread.Client

    Using the gspread client to create a Spreadsheet Model using the "open_by_key()"
    method and passing in the spreadsheet's ID using an unnamed argument:
    ```
    spreadsheet = gspread_try_catch(gs_api, "open_by_key", "123456789qwertyuiop")
    ```
    This will return a Spreadsheet instance (gspread.spreadsheet.Spreadsheet).
    Documentation: https://docs.gspread.org/en/v6.0.1/api/models/spreadsheet.html#spreadsheet

    Using the Spreadsheet object, create a Worksheet Model using the "worksheet()" method
    and pass the name of the Worksheet as an unnamed argument:
    ```
    worksheet = gspread_try_catch(spreadsheet, "worksheet", "Sheet1")
    ```
    This will return a Worksheet instance (gspread.worksheet.Worksheet).
    Documentation: https://docs.gspread.org/en/v6.0.1/api/models/worksheet.html#gspread.worksheet.Worksheet

    Get values of the Worksheet we created above using the "batch_get()" method.
    We'll use keyword arguments for "ranges" (values of these cell ranges),
    "major_dimension" (how to return the values, in our case vertically by columns),
    and "value_render_option" (use "FORMATTED_VALUE" to return values as they appear in
    the spreadsheet).
    ```
    gspread_try_catch(worksheet, "batch_get",
                      ranges=["A1:E2"], major_dimension="COLUMNS", value_render_option="FORMATTED_VALUE")
    ```
    This will return a List of Values from the Worksheet.
    Documentation: https://docs.gspread.org/en/v6.0.1/api/models/worksheet.html#gspread.worksheet.Worksheet.batch_get

Parameters:
    gspread_object  - Can be the gspread Client itself or a gspread Client's model (a Spreadsheet, Worksheet, or Cell).
    method          - A method of the passed "gspread_object" argument.
    args            - Positional arguments for the gspread_object's method.
    kwargs          - Keyword arguments for the gspread_object's method

Calls:

Called by:

Returns: Return of a gspread Object Instance's Method.
***********************************************************************************************************************
"""


def gspread_try_catch(gspread_object, method, *args, **kwargs):
    try:
        return getattr(gspread_object, method)(*args, **kwargs)
    except Exception as e:
        log_to_console(
            __name__,
            "Err",
            f"Encountered the following error:{str(e)} :: Starting to sleep for 20 seconds and then trying again.",
        )
        time.sleep(20)
        try:
            return getattr(gspread_object, method)(*args, **kwargs)
        except Exception as e:
            log_to_console(
                __name__,
                "Err",
                f"Second attempt to use the method failed. See below exception: {str(e)}",
            )
            raise e


"""
***********************************************************************************************************************
Function: duplicates_test

Purpose: test for partitioned duplicate entries in a dataframe or a Snowflake table based on input type.

Parameters:
    input      - Pandas DataFrame or schema name if using Snowflake. Required.
    column     - The column name to check for duplicates. Required.
    partition  - The partition column if any, defaults to an empty string.
    db         - database name if using Snowflake.
    schema     - schema name if using Snowflake.
    table_name - table name if using Snowflake.
    snow_cur   - Snowflake cursor.

Calls:

Called by:

Returns: None if no duplicates found; raises RuntimeError if duplicates are detected.

***********************************************************************************************************************
"""


def duplicates_test(
    column,
    partition="",
    input=None,
    db=None,
    schema=None,
    table_name=None,
    snow_cur=None,
):

    try:

        # For Pandas DataFrames
        if isinstance(input, pd.DataFrame):
            df = input
            if partition:
                results = df.groupby([partition, column]).size().reset_index()
            else:
                results = df.groupby([column]).size().reset_index()
            dupes = (results.iloc[:, -1] > 1).sum()
            # duplicate_test_boolean_outcome = False if dupes == 0 else True
            duplicate_test_boolean_outcome = False if dupes == 0 else True

        # For Snowflake tables
        elif all([db, schema, table_name, snow_cur]):
            # Validate identifiers to prevent SQL injection
            _validate_identifier(db)
            _validate_identifier(schema)
            _validate_identifier(table_name)
            _validate_identifier(column)
            if partition:
                _validate_identifier(partition)
            # Set up group by clause
            group_by_columns = [column]
            if partition:
                group_by_columns.insert(0, partition)
            group_by_clause = ", ".join(group_by_columns)

            results_qr = f"""
            SELECT count(*) AS cnt
            FROM {db}.{schema}.{table_name}
            GROUP BY {group_by_clause}
            HAVING cnt > 1
            """
            dupes = snow_cur.execute(results_qr).fetchall()
            duplicate_test_boolean_outcome = False if len(dupes) == 0 else True

        else:
            raise ValueError("Invalid input or insufficient parameters for operation.")

        # Duplicates found error
        if duplicate_test_boolean_outcome:
            raise RuntimeError("Duplication in partition.")

    except Exception as e:
        log_to_console(__name__, "Err", str(e))
        raise


"""
***********************************************************************************************************************
Name:		snowflake_pipeline_logging
Purpose:	Log to the Data Engineering Logging Snowflake table. Deprecated — use StepLogger instead.
Example:	snowflake_pipeline_logging(env=env, job_name=args['JOB_NAME'], job_status="SUCCESS", job_details="Testing",
                               source_location=job_run_details_source, table_name=job_run_details_table,
                               row_count=job_run_details_rows)
Parameters: env, job_name, job_status, job_details, source_location, table_name, row_count, region
Called by:
Calls:
Errors:
Author:		jgabriel
Date:		20241224
***********************************************************************************************************************
"""


def snowflake_pipeline_logging(
    env: str,
    job_name: str,
    job_status: str,
    job_details: str,
    source_location: Union[str, list[str]],
    table_name: Union[str, list[str]],
    row_count: Union[int, list[int]],
    region: str = "us-west-2",
    job_id: str = "Not Provided",
):
    """
    Function used to log ETL Pipeline activity to the @ENV@.MY_ORG_DL_MONITORING.JOB_RUN_DETAILS Snowflake table.
    Can be used for single value insert statement or multi-value insert statements. If used for a single insert,
    then source_location and table_name should be strings and row_count should  be an integer. If used for a
    multi-value insert statement, then source_location and table_name should both be lists containing strings whereas
    row_count should be a list containing integers. Each of these three lists need to be of equal value in length
    (i.e.: each list containing the same number of elements).

    :param env: Environment of Glue Job and Database. Can only be: "DEV", "STAGE", or "PROD".
    :param job_name: Name of Glue Job.
    :param job_status: The Status of the Glue Job. Should either be "SUCCESS" or "FAIL".
    :param job_details: Notes regarding a specific run. For example, if JOB_STATUS is "FAIL", detail the cause here.
    :param source_location: Source of the ETL Data. Can be an S3 path, the name of an API (Meta, Google Ads, Reddit,
    etc.), the name of a file, etc.
    :param table_name: The fully-qualified table name (database.schema.table_name)
    :param row_count: The count of rows inserted into the database table.
    :param region: The AWS Account Region. Defaults to "us-west-2", but can be specified if this changes.
    :raises ValueError: A ValueError Exception will be raised if the condition for source_location, table_name, and
    row_count are not met in relation to a single value or multi-value insert statement (see description).
    """
    log_to_console(
        __name__,
        "\033[91mWarn\033[0m",
        "\033[91mUse of this function -- eimutils.utils.snowflake_pipeline_logging -- \
        should be deprecated and replaced with StepLogger. \
        See: \033[94mhttps://MY_ORG.atlassian.net/wiki/spaces/EIM/pages/4189258488/class+StepLogger\033[0m",
    )
    env = env.upper()
    database, schema, table = f"MY_ORG_{env}_RAW", "DATA_HUB", "ISSUE"
    job_status = "IC" if job_status == "SUCCESS" else "IF"

    def _esc(val: str) -> str:
        return str(val).replace("'", "''")

    # Get the AWS Secrets used for the Snowflake Connection.
    _secret_map = {
        "DEV": "arn:aws:secretsmanager:us-west-2:MY_ACCOUNT_ID:secret:eim_dev_dw30_keys-L7xm5U",
        "STAGE": "arn:aws:secretsmanager:us-west-2:MY_ACCOUNT_ID:secret:eim_stage_dw30_keys-XsUKxP",
        "PROD": "arn:aws:secretsmanager:us-west-2:MY_ACCOUNT_ID:secret:eim_prod_dw30_keys-IGFHqu",
    }
    if env not in _secret_map:
        raise ValueError(f"snowflake_pipeline_logging: unsupported env {env!r}. Must be DEV, STAGE, or PROD.")
    snow_secret = _secret_map[env]

    # Connect to Snowflake.
    snow_con = get_snowflake_connection_from_secret(snow_secret, env, region)
    snow_cur = snow_con.cursor()

    # Build the query
    multi_row = False

    # Edge-case: all three args are lists but empty — list check would raise TypeError on int row_count.
    if (
        isinstance(source_location, list)
        and isinstance(table_name, list)
        and isinstance(row_count, list)
        and len(source_location) == 0
        and len(table_name) == 0
        and len(row_count) == 0
    ):
        log_to_console(__name__, "Info", "in the 'Edge Case' if statement.")
        insert_values = f"""
        left('{_esc(job_name)}', 25),
        '{_esc(job_status)}',
        CURRENT_DATE(),
        '-1',
        '-1',
        '-1',
        'UNK',
        CURRENT_DATE(),
        NULL,
        NULL,
        '-1',
        '-1',
        '-1',
        '-1',
        NULL,
        NULL,
        CURRENT_TIMESTAMP(),
        CURRENT_TIMESTAMP(),
        CONVERT_TIMEZONE('America/Los_Angeles', 'UTC', CURRENT_TIMESTAMP()),
        CONVERT_TIMEZONE('America/Los_Angeles', 'UTC', CURRENT_TIMESTAMP()),
        CURRENT_TIMESTAMP(),
        NULL,
        '0',
        '{_esc(job_id)}',
        CURRENT_USER(),
        CURRENT_TIMESTAMP(),
        CURRENT_USER(),
        CURRENT_TIMESTAMP()
        """

    # If we have a list for "source_location", "table_name", and "row_count".
    elif (
        isinstance(source_location, list)
        and isinstance(table_name, list)
        and isinstance(row_count, list)
    ):
        # Check and make sure all lists are of equal value. Otherwise, zip will stop at the end of the shortest list.
        iter_lists = iter([source_location, table_name, row_count])
        list_length = len(source_location)
        if not all(len(mylist) == list_length for mylist in iter_lists):
            raise ValueError(
                "The lists for 'source_location', 'table_name', and 'row_count' are not equal in length. \
                             Please confirm values."
            )

        multi_row = True
        combined_table_name_row_counts = zip(source_location, table_name, row_count)
        insert_values = ",\n\t".join(
            f"""
        (left('{_esc(job_name)}', 25),
        '{_esc(job_status)}',
        CURRENT_DATE(),
        '-1',
        '-1',
        '-1',
        'UNK',
        CURRENT_DATE(),
        '{_esc(x)}',
        '{_esc(y).upper()}',
        '-1',
        '-1',
        '-1',
        '-1',
        NULL,
        NULL,
        CURRENT_TIMESTAMP(),
        CURRENT_TIMESTAMP(),
        CONVERT_TIMEZONE('America/Los_Angeles', 'UTC', CURRENT_TIMESTAMP()),
        CONVERT_TIMEZONE('America/Los_Angeles', 'UTC', CURRENT_TIMESTAMP()),
        CURRENT_TIMESTAMP(),
        {int(z)},
        '0',
        '{_esc(job_id)}',
        CURRENT_USER(),
        CURRENT_TIMESTAMP(),
        CURRENT_USER(),
        CURRENT_TIMESTAMP())
        """
            for x, y, z in combined_table_name_row_counts
        )

    # If strings were passed in for "source_location", "table_name", and "row_count".
    elif (
        isinstance(source_location, str)
        and isinstance(table_name, str)
        and isinstance(row_count, int)
    ):
        insert_values = f"""
        left('{_esc(job_name)}', 25),
        '{_esc(job_status)}',
        CURRENT_DATE(),
        '-1',
        '-1',
        '-1',
        'UNK',
        CURRENT_DATE(),
        '{_esc(source_location)}',
        '{_esc(table_name).upper()}',
        '-1',
        '-1',
        '-1',
        '-1',
        NULL,
        NULL,
        CURRENT_TIMESTAMP(),
        CURRENT_TIMESTAMP(),
        CONVERT_TIMEZONE('America/Los_Angeles', 'UTC', CURRENT_TIMESTAMP()),
        CONVERT_TIMEZONE('America/Los_Angeles', 'UTC', CURRENT_TIMESTAMP()),
        CURRENT_TIMESTAMP(),
        {int(row_count)},
        '0',
        '{_esc(job_id)}',
        CURRENT_USER(),
        CURRENT_TIMESTAMP(),
        CURRENT_USER(),
        CURRENT_TIMESTAMP()
        """

    # If "source_location", "table_name", and "row_count" not all lists or not all strings.
    else:
        raise ValueError(
            "The parameters source_location, table_name, and row_count must all be lists or \
                         source_location, table_name, must each be a string and row_count must be an integer!"
        )

    values_clause = insert_values if multi_row else f"({insert_values})"
    insert_statement = f"""
    INSERT INTO {database}.{schema}.{table} (
        PUBLICATIONCODE,
        STATUSCODE,
        REPORTDATE,
        SRCDFPUBLISHERID,
        SRCDFPUBLICATIONID,
        SRCDFISSUEID,
        SRCISSUENAME,
        SRCDFCREATEDDATE,
        DATALAKEPATH,
        ISSUENAME,
        PUBLICATIONSEQ,
        DAILYPUBLICATIONSEQ,
        FIRSTRECORDSEQ,
        LASTRECORDSEQ,
        FIRSTRECORDCHECKSUM,
        LASTRECORDCHECKSUM,
        PERIODSTARTTIME,
        PERIODENDTIME,
        PERIODSTARTTIMEUTC,
        PERIODENDTIMEUTC,
        ISSUECONSUMEDDATE,
        RECORDCOUNT,
        RETRYCOUNT,
        ETLEXECUTIONID,
        CREATEDBY,
        CREATEDDTM,
        MODIFIEDBY,
        MODIFIEDDTM
    )
    VALUES
        {values_clause};
    """

    # Execute the query
    try:
        insert_rows = snow_cur.execute(insert_statement)
        snow_con.commit()
        log_to_console(
            __name__,
            "Info",
            f"Number of rows inserted into {database}.{schema}.{table}: {insert_rows}.",
        )
    finally:
        snow_cur.close()
        snow_con.close()


"""
***********************************************************************************************************************
Name: dates_to_process
Purpose: Get the dates to process for a given table by using the last processed date in the table or user passed dates.
Parameters:
    file_dt_from: The start date to process - can be passed by user or a string "Not Provided" when running normally
    file_dt_to: The end date to process - can be passed by user or a string "Not Provided" when running normally
    last_processed_date: The last processed date from the table
Returns:
    tuple[str, str, list[str]]: The file_dt_from, file_dt_to, and list of dates to process, all in the format YYYY-MM-DD
Raises:
    Exception: Exception if the user passes in improperly formatted dates
Calls:
    None
Called by:
    None
Author:
    Colton Juliano
Date: 2026-01-05
***********************************************************************************************************************
"""


def dates_to_process(
    file_dt_from: str,
    file_dt_to: str,
    last_processed_date: Union[date, None],
) -> tuple[str, str, list[str]]:

    """
    This function returns a list of dates to process in the format YYYY-MM-DD

    Args:
        file_dt_from (str): The start date to process
        file_dt_to (str): The end date to process
        last_processed_date (date): The last processed date from the table

    Raises:
        Exception: Exception if the user passes in improperly formatted dates

    Returns:
        tuple[str, str, list[str]]: The file_dt_from, file_dt_to, and list of dates to process,
        all in the format YYYY-MM-DD
    """
    if file_dt_from == "Not Provided" and file_dt_to == "Not Provided":
        file_dt_list = []
        prev_date = (datetime.today().astimezone(pytz.timezone('US/Pacific')) - timedelta(1)).date()
        start_dt = last_processed_date if last_processed_date else prev_date
        if start_dt < prev_date:
            file_dt_list = [
                (start_dt + timedelta(days=x)).strftime("%Y-%m-%d")
                for x in range((prev_date - start_dt).days + 1)
            ]
        else:
            # Up-to-date: default to yesterday so the job still has a date to report
            file_dt_list.append(prev_date.strftime("%Y-%m-%d"))
        file_dt_from = start_dt.strftime("%Y-%m-%d")
        file_dt_to = prev_date.strftime("%Y-%m-%d")
    elif file_dt_from != "Not Provided" and file_dt_to != "Not Provided":
        try:
            file_dt_from = datetime.strptime(file_dt_from, "%Y-%m-%d")
            file_dt_to = datetime.strptime(file_dt_to, "%Y-%m-%d")
        except ValueError as e:
            raise Exception(f"Incorrect FILE_DT_FROM/FILE_DT_TO passed: {e} Try again")
        # generating date list between file_dt_from and file_dt_to
        file_dt_list = [file_dt_from + timedelta(days=x) for x in range((file_dt_to - file_dt_from).days + 1)]
        file_dt_list = [date.strftime("%Y-%m-%d") for date in file_dt_list]
        file_dt_from = file_dt_from.strftime("%Y-%m-%d")
        file_dt_to = file_dt_to.strftime("%Y-%m-%d")
    else:
        raise ValueError(
            f"Provide both FILE_DT_FROM and FILE_DT_TO, or neither. "
            f"Got file_dt_from={file_dt_from!r}, file_dt_to={file_dt_to!r}."
        )
    log_to_console(__name__, "Info", f"Loading files for dates: {file_dt_from} to {file_dt_to}")
    return file_dt_from, file_dt_to, file_dt_list


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
Andrius     2024-07-04  get_snowflake_connection_from_secret() updated to handle spark session usage.
Andrius     2024-07-04  read_google_sheet added.
Andrius     2024-07-04  duplicates_test added.
Frank       2024-07-16  Data Science Credentials.
jgabriel    2024-08-29  Removed send_datadog_metric
ffortunato  2025-07-22  o formatting
ffortunato  2025-08-14  o secret key changes.
ffortunato  2025-08-21  o logging changes.
Colton      2026-01-05  dates_to_process added.
ffortunato  2026-05-26  o Improved account hyphen check logging. Enhanced error messages.
***********************************************************************************************************************
"""
