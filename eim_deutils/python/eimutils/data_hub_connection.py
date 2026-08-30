"""
*******************************************************************************
File: data_hub_connection.py

Purpose: Core functions invoked by the Data Hub class that interact with the db.

Dependencies/Helpful Notes :

*******************************************************************************
"""

from eimutils.delogging import log_to_console
from datetime import datetime
from typing import Any
import re
import snowflake.connector
import pandas as pd

_IDENTIFIER_RE = re.compile(r'^[A-Za-z_][A-Za-z0-9_$]*$')


def _n(v):
    # None becomes "" because several ISSUE columns are declared NOT NULL VARCHAR.
    # Passing None through would write SQL NULL and cause a NOT NULL constraint violation
    # on those columns. Known limitation: legitimate NULLs cannot be written to
    # NUMBER/TIMESTAMP columns via this helper; callers that need NULL for a numeric or
    # timestamp column must handle it before calling _n().
    if v is None:
        return ""
    if hasattr(v, 'item'):  # coerce numpy scalars (int64, float64, etc.) to native Python types
        return v.item()
    if hasattr(v, 'isoformat'):  # datetime/date/Timestamp — old connector (<3.0) can't bind these
        return str(v)
    return v


def _validate_identifier(name: str) -> None:
    if not _IDENTIFIER_RE.match(name):
        raise ValueError(f"Invalid SQL identifier: {name!r}")


def get_publication_list(connection: Any, params: dict, get_type: str) -> pd.DataFrame:
    """
    Call Get Publication List stored procedure
    :param connection:
    :param params:
        PublisherCode: string
    :return: publication_list dictionary of publication attributes
    """
    cursor = None
    try:
        params_values = []
        if get_type in ("Schedule", "PublisherCode"):
            if not params.get("CurrentDate"):
                params["CurrentDate"] = datetime.now()
            error_msg = "Publication list look up failed for provided PublisherCode: {}. Revisit the parameter list \
                provided to the function.".format(
                params
            )
            sql = """
select	 pr.PublisherId
        ,pr.PublisherCode
        ,pr.PublisherName
        ,pn.PublicationId
        ,pn.PublicationName
        ,pn.PublicationCode
        ,pr.InterfaceCode
        ,pn.SrcFileRegEx
        ,pn.IntervalCode
        ,pn.IntervalLength
        ,pn.RetryIntervalCode
        ,pn.RetryIntervalLength
        ,pn.RetryMax
        ,pn.ProcessingMethodCode
        ,pn.TransferMethodCode
        ,pn.NextExecutionDtm
        ,pn.SLATime
        ,ri.SLAFormat
        ,ri.SLARegEx
        ,pn.Bound
        ,pn.SrcFileFormatCode  -- As FeedFormat
        ,pn.StandardFileFormatCode
        ,pn.GlueWorkflow
        ,pn.SrcPublicationName
        ,pn.SrcFilePath
        ,pn.PublicationFilePath
        ,pn.PublicationArchivePath
        ,pn.PublicationGroupSequence
        ,id.IssueId					LastIssueId
        ,IFNULL(id.IssueName, 'Unknown')	IssueName
        ,id.PeriodStartTime				LastHighWaterMarkDatetime
        ,id.PeriodStartTimeUTC			LastHighWaterMarkDatetimeUTC
        ,id.PeriodEndTime				HighWaterMarkDatetime
        ,id.PeriodEndTimeUTC			HighWaterMarkDatetimeUTC
        ,LastRecordSeq					HighWaterMarkRecordSeq
        ,id.PublicationSeq
        ,subn.SUBSCRIPTIONFILEPATH      SubscriptionFilePath
    from 	DATA_HUB.Publication		  pn
    left join (
        select
             iss.IssueId                                    IssueId
            ,issd.PublicationCode                           PublicationCode
            ,iss.IssueName                                  IssueName
            ,ifnull(iss.PeriodStartTime   ,'1900-01-01')    PeriodStartTime
            ,iss.PeriodEndTime                              PeriodEndTime
            ,ifnull(iss.PeriodStartTimeUTC,'1900-01-01')    PeriodStartTimeUTC
            ,iss.PeriodEndTimeUTC                           PeriodEndTimeUTC
            ,iss.FirstRecordSeq                             FirstRecordSeq
            ,iss.LastRecordSeq                              LastRecordSeq
            ,iss.FirstRecordChecksum                        FirstRecordChecksum
            ,iss.LastRecordChecksum                         LastRecordChecksum
            ,iss.PublicationSeq                             PublicationSeq
        from	 (
            select	 pbn.PublicationCode      PublicationCode
                    ,max(IssueId)             IssueId
            from	 DATA_HUB.Issue				  iss
            join	 DATA_HUB.Publication		  pbn
            on		 iss.PublicationCode		= pbn.PublicationCode
            join	 DATA_HUB.Publisher			  pbr
            on		 pbn.PublisherCode		= pbr.PublisherCode
            join	 DATA_HUB.Ref_Status			  rs
            on		 iss.StatusCode			= rs.StatusCode
            where	 pbr.PublisherCode		= %s
            and		 rs.StatusCode			in ('IL','IC','IA') -- We dont want values from failed issues.
            group by pbn.PublicationCode
        )			  issd
        join	 DATA_HUB.Issue				  iss
        on		 iss.IssueId		      	= issd.IssueId
    )                                     id
    on		id.PublicationCode			= pn.PublicationCode
    join	DATA_HUB.Publisher			  pr
    on		pr.PublisherCode				= pn.PublisherCode
    join	DATA_HUB.Ref_Interval		  ri
    on		pn.IntervalCode				= ri.IntervalCode
    left outer join    DATA_HUB.subscription       subn
    on      subn.PublicationCode       = pn.PublicationCode
    where	pn.IsActive					= 1
    --and		pn.Bound					= 'In'
    and		pn.NextExecutionDtm			<= %s
    and		pr.PublisherCode			=  %s
    order   by pn.PublicationGroupSequence ASC
"""
            params_values = [params['PublisherCode'], params['CurrentDate'], params['PublisherCode']]

        else:
            raise NotImplementedError(
                f"get_type={get_type!r} is not yet implemented. "
                "Supported values: 'Schedule', 'PublisherCode'."
            )

        # print(sql)

        cursor = connection.cursor()
        cursor.execute(sql, params_values)
        rows = cursor.fetchall()
        column_names = [desc[0] for desc in cursor.description]
        df_publication_list = pd.DataFrame(rows, columns=column_names)
        connection.commit()

        if df_publication_list.empty:
            error_msg = "No Publication List Returned  ::" + error_msg
            raise Exception(error_msg)
        """
        elif publication_list[0]['PublicationCode'] == 'NA':
            error_msg = 'No Publication List Returned  ::' + error_msg
            raise Exception(error_msg)
        """

    except snowflake.connector.errors.ProgrammingError as err:
        # Handle programming errors, such as invalid SQL syntax
        error_msg = "connection.get_publication_list :: snowflake.connector.errors.ProgrammingError Something went \
            wrong getting publication list. {}".format(
            err
        )
        log_to_console(__name__, "Error", error_msg)
        raise Exception(error_msg)

    except snowflake.connector.errors.DatabaseError as err:
        # Handle database errors, such as connection issues
        error_msg = "connection.get_publication_list :: snowflake.connector.errors.DatabaseError Something went \
            wrong getting publication list. {}".format(
            err
        )
        log_to_console(__name__, "Error", error_msg)
        raise Exception(error_msg)

    except Exception as err:
        error_msg = "connection.get_publication_list :: Something went \
            wrong (not database related) getting publication list. {}".format(
            err
        )
        # print('data_hub_connection.get_publication_list :: ', error_msg)
        log_to_console(__name__, "Error", error_msg)
        connection.rollback()
        raise Exception(error_msg)
        # return {"Status": "Failed", "Error Message": error_msg}

    finally:
        if cursor:
            cursor.close()
    return df_publication_list


def prepare_issues(publication_list: pd.DataFrame) -> list:
    """
    Use the Publication List to prepare an array of issues that will be processed.
    :param publication_list:
    :return: An Array of issues.

    {'PUBCODE1':0,
    'PUBCODE2':1,
    'PUBCODE3':2}
    """

    issue_list = []
    index = {}
    try:
        for (
            iteration,
            publication,
        ) in publication_list.iterrows():  # enumerate(publication_list):
            index[publication["PUBLICATIONCODE"]] = iteration  # ['PublicationCode']
            issue = {
                "PublicationCode": publication["PUBLICATIONCODE"],
                "StatusCode": "IP",
                "ReportDate": datetime.now().strftime("%Y-%m-%d"),
                "SrcDFPublisherId": "UNK",
                "SrcDFPublicationId": "UNK",
                "SrcDFIssueId": "UNK",
                "SrcIssueName": "UNK",
                "SrcDFCreatedDate": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                "DataLakePath": publication["PUBLICATIONFILEPATH"],
                "IssueName": publication["ISSUENAME"],
                "PublicationSeq": "-1",
                "DailyPublicationSeq": "-1",
                "FirstRecordSeq": "-1",
                "LastRecordSeq": "-1",
                "FirstRecordChecksum": "UNK",
                "LastRecordChecksum": "UNK",
                "PeriodStartTime": publication["LASTHIGHWATERMARKDATETIME"],
                "PeriodEndTime": publication["HIGHWATERMARKDATETIME"],
                "PeriodStartTimeUTC": publication["LASTHIGHWATERMARKDATETIMEUTC"],
                "PeriodEndTimeUTC": publication["HIGHWATERMARKDATETIMEUTC"],
                "IssueConsumedDate": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                "RecordCount": "0",
                "RetryCount": "0",
                # 'ETLExecutionId ' :'-1',
                "CreatedBy": "dh",
                "CreatedDtm": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
                "ModifiedBy": "dh",
                "ModifiedDtm": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            }
            # If we happened to get the data based on issue Id we can fill out more of this dictionary.
            # This also assumes we are only looping once or we will get the same issue id for several publication.
            # ToDo think about that!
            """
            if 'IssueId' in publication:
                issue['IssueId'] = publication[29]#['IssueId']
            if 'IssueName' in publication:
                issue['IssueName'] = publication[30]#['IssueName']
            """

            issue["StatusCode"] = "IP"
            # issue['ReportDate'] = '1900-01-01'
            issue["RecordCount"] = (
                -1
            )  # ['RecordCount']  # Maybe you want to start with a different status.
            issue["ETLExecutionId"] = "-1"

            # pd.isna() catches both Python None and pandas NaN (which is what
            # pandas stores for None in a mixed-type column during iteration).
            for key in ("PeriodStartTime", "PeriodStartTimeUTC", "PeriodEndTime", "PeriodEndTimeUTC"):
                if issue[key] is None or pd.isna(issue[key]):
                    issue[key] = "1900-01-01"

            issue_list.append(issue)
            issue = {}  # Clean out the issue for the next loop.

        # issue_list[0] = index
        issue_list.append(index)

    except Exception as err:
        error_msg = f"data_hub_connection.prepare_issues :: Exception building issue: {err}"
        log_to_console(__name__, "Error", error_msg)
        raise Exception(error_msg)

    return issue_list


def insert_new_issue(connection: Any, issue: dict) -> dict:
    """
    Call new issue stored procedure
    :param connection:
    :param issue:
    :return dict:
    """
    log_to_console("datahub_connection.insert_new_issue", "Info", "Starting.")
    try:
        sql = """ INSERT INTO DATA_HUB.ISSUE (
  IssueId
 ,PublicationCode
 ,StatusCode
 ,ReportDate
 ,SrcDFPublisherId
 ,SrcDFPublicationId
 ,SrcDFIssueId
 ,SrcIssueName
 ,SrcDFCreatedDate
 ,DataLakePath
 ,IssueName
 ,PublicationSeq
 ,DailyPublicationSeq
 ,FirstRecordSeq
 ,LastRecordSeq
 ,FirstRecordChecksum
 ,LastRecordChecksum
 ,PeriodStartTime
 ,PeriodEndTime
 ,PeriodStartTimeUTC
 ,PeriodEndTimeUTC
 ,IssueConsumedDate
 ,RecordCount
 ,RetryCount
 ,ETLExecutionId
 ,CreatedBy
 ,CreatedDtm
 ,ModifiedBy
 ,ModifiedDtm
 ) VALUES (
  %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
  %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
  %s, %s, %s, %s, %s, %s, %s, %s, %s
 );
"""

        cursor = None
        cursor = connection.cursor()
        try:
            cursor.execute("SELECT DATA_HUB.SEQ_ISSUE_ID.NEXTVAL")
            next_id = int(cursor.fetchone()[0])
        except snowflake.connector.errors.ProgrammingError:
            # Sequence not yet deployed — fall back to MAX(IssueId) + 1 across all issues.
            # Uses a fresh cursor because the previous one may be in an aborted state.
            cursor.close()
            cursor = connection.cursor()
            cursor.execute("SELECT IFNULL(MAX(IssueId), 0) + 1 FROM DATA_HUB.Issue")
            next_id = int(cursor.fetchone()[0])

        values = (
            next_id,
            _n(issue['PublicationCode']), _n(issue['StatusCode']), _n(issue['ReportDate']),
            _n(issue['SrcDFPublisherId']), _n(issue['SrcDFPublicationId']), _n(issue['SrcDFIssueId']),
            _n(issue['SrcIssueName']), _n(issue['SrcDFCreatedDate']), _n(issue['DataLakePath']),
            _n(issue['IssueName']), _n(issue['PublicationSeq']), _n(issue['DailyPublicationSeq']),
            _n(issue['FirstRecordSeq']), _n(issue['LastRecordSeq']), _n(issue['FirstRecordChecksum']),
            _n(issue['LastRecordChecksum']), _n(issue['PeriodStartTime']), _n(issue['PeriodEndTime']),
            _n(issue['PeriodStartTimeUTC']), _n(issue['PeriodEndTimeUTC']), _n(issue['IssueConsumedDate']),
            _n(issue['RecordCount']), _n(issue['RetryCount']), _n(issue['ETLExecutionId']),
            _n(issue['CreatedBy']), _n(issue['CreatedDtm']), _n(issue['ModifiedBy']), _n(issue['ModifiedDtm']),
        )
        # print((sql, values))
        cursor.execute(sql, values)
        connection.commit()
        issue_id_dict = {"IssueId": str(next_id)}
        # print(issue_id_dict['IssueId'])

    except snowflake.connector.errors.ProgrammingError as err:
        connection.rollback()
        # Handle programming errors, such as invalid SQL syntax
        error_msg = "data_hub_connection.insert_new_issue :: snowflake.connector.errors.ProgrammingError \
            {} Issue: {} ".format(
            err, issue["IssueName"]
        )
        log_to_console(__name__, "Error", error_msg)
        raise Exception(error_msg)

    except snowflake.connector.errors.DatabaseError as err:
        connection.rollback()
        # Handle database errors, such as connection issues
        error_msg = "connection.insert_new_issue :: snowflake.connector.errors.DatabaseError \
            Something went wrong inserting the issue. {} Issue: {} ".format(
            err, issue["IssueName"]
        )
        log_to_console(__name__, "Error", error_msg)
        raise Exception(error_msg)

    except Exception as err:
        error_msg = "connection.insert_new_issue :: Something went wrong inserting new issue.  \
            {} Issue: {} ".format(
            err, issue["IssueName"]
        )
        log_to_console(__name__, "Error", error_msg)
        raise Exception(error_msg)
    finally:
        if cursor:
            cursor.close()

    return issue_id_dict


def update_issue(connection: Any, issue: dict) -> dict:
    """
    Call update issue stored procedure
    :param connection:
    :param issue:
    :return dict:
    """

    log_to_console("datahub_connection.update_issue", "Info", "Starting.")
    if "IssueId" not in issue:
        raise ValueError("IssueId not found in issue dict")

    try:
        set_parts = []
        values = []
        for col, val in issue.items():
            if col == "IssueId":
                continue
            _validate_identifier(col)
            set_parts.append(f"{col} = %s")
            values.append(_n(val))
        values.append(issue['IssueId'])
        sql = "UPDATE DATA_HUB.ISSUE SET " + ", ".join(set_parts) + " WHERE IssueId = %s"

        cursor = None
        cursor = connection.cursor()
        cursor.execute(sql, values)
        connection.commit()

    except snowflake.connector.errors.ProgrammingError as err:
        connection.rollback()
        # Handle programming errors, such as invalid SQL syntax
        error_msg = "connection.update_issue :: snowflake.connector.errors.ProgrammingError \
            Something went wrong updating the issue.  {} Issue: {} ".format(
            err, issue["IssueName"]
        )
        log_to_console(__name__, "Error", error_msg)
        raise Exception(error_msg)

    except snowflake.connector.errors.DatabaseError as err:
        connection.rollback()
        # Handle database errors, such as connection issues
        error_msg = "connection.update_issue :: snowflake.connector.errors.DatabaseError \
            Something went wrong updating the issue.  {} Issue: {} ".format(
            err, issue["IssueName"]
        )
        log_to_console(__name__, "Error", error_msg)
        raise Exception(error_msg)

    except Exception as err:
        # log errors in CloudWatch
        connection.rollback()
        error_msg = "data_hub_connection.update_issue() :: \
            Something (not database related) went wrong updating the issue.  \
                {} Issue: {} ".format(
            err, issue["IssueName"]
        )
        log_to_console(__name__, "Error", error_msg)
        raise Exception(error_msg)

    finally:
        if cursor:
            cursor.close()

    return {"Status": "Success"}


def is_issue_absent(connection: Any, file_name: str) -> bool:
    # Determine if the file has already been processed by looking at DATA_HUB.issue.
    try:
        sql = (
            "select IssueId from DATA_HUB.issue i "
            "join DATA_HUB.Ref_Status s on i.StatusCode = s.StatusCode "
            "where s.StatusCode not in ('IF') and SrcIssueName = %s LIMIT 1"
        )
        cursor = connection.cursor()
        cursor.execute(sql, (file_name,))
        result = cursor.fetchall()
        cursor.close()

    except snowflake.connector.errors.ProgrammingError as err:
        connection.rollback()
        # Handle programming errors, such as invalid SQL syntax
        error_msg = "connection.is_issue_absent :: snowflake.connector.errors.ProgrammingError \
            Something went wrong checking for the issue. {}".format(
            err
        )
        log_to_console(__name__, "Error", error_msg)
        raise Exception(error_msg)

    except snowflake.connector.errors.DatabaseError as err:
        connection.rollback()
        # Handle database errors, such as connection issues
        error_msg = "connection.is_issue_absent :: snowflake.connector.errors.DatabaseError \
            Something went wrong checking for the issue. {}".format(
            err
        )
        log_to_console(__name__, "Error", error_msg)
        raise Exception(error_msg)

    if len(result) > 0:
        return False
    else:
        return True


"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
acosta      04-08-2022  Initial Iteration
ffortunato  04-11-2022  pyODBC --> pymssql
                        + several new functions.
ffortunato  05-03-2022  o for iteration, publication in enumerate(publication_list):
ffortunato  07-29-2022  + Improving exception messages but still more to do.
ffortunato  08-09-2022  + connection.commit(), connection.rollback()
                        These are need to make sure there are no blocking
                        processs on the database.
ffortunato  2023-05-22    o modified logging to us log to console.
ffortunato  2023-06-15    + TriggerTypeCode - Scheduled.
ffortunato  2023-06-26    + Passing KeyStoreName to issue.
ffortunato  2023-08-04    + IssueConsumedDate.
ffortunato  2024-09-04    o MS SQL to Snowflake error handling.
ffortunato  2024-09-09    o Insert Issue from unzip.
ffortunato  2025-07-22  o formatting.
*******************************************************************************
"""
