"""
*******************************************************************************
File: data_hub_connection.py

Purpose: Core functions invoked by the Data Hub class that interact with the db.

Dependencies/Helpful Notes :

*******************************************************************************
"""

import pymssql


def connect_database(host, user, password, database):
    """
    Creates a pymssql connection for use by the class
    :return: pymssql connection
    """
    try:

        db_connection = pymssql.connect(host, user, password, database)

    except pymssql.Error as err:
        # TODO: log errors in CloudWatch
        print("connection.connect_database :: Connection error.", err)
        return {'Status': 'Failure'}

    return db_connection


def get_publication_list(connection, params):
    """
    Call Get Publication List stored procedure
    :param connection:
    :param params:
        PublisherCode: string
    :return: publication_list dictionary of publication attributes
    """
    try:
        # print(params)
        if 'PublisherCode' in params:
            # print('usp_GetPublicationList')
            sql = f"[ctl].[usp_GetPublicationList] @pPublisherCode = N'{params['PublisherCode']}', " \
                                             f"@pNextExecutionDateTime = N'{params['CurrentDate']}'"
        elif 'PublicationFilePath' in params:
            # print('usp_GetPublicationRecord')
            sql = f"[ctl].[usp_GetPublicationRecord] @pPublicationFilePath = N'{params['PublicationFilePath']}'"

        elif 'IssueId' in params:
            # print('usp_GetIssueDetails')
            sql = f"[ctl].[usp_GetIssueDetails] @pIssueId = N'{params['IssueId']}'"
        else:
            # print('Cant determine what data to get from database.')
            sql = 'N/A'

        # print(sql)
        cursor = connection.cursor(as_dict=True)
        cursor.execute(sql)
        publication_list = cursor.fetchall()
        connection.commit()

    except pymssql.Error as err:
        # TODO: log errors in CloudWatch
        error_msg = "pymssql Something went wrong getting publication list. {}".format(err)
        print('data_hub_connection.get_publication_list :: ', error_msg)
        return {"Status": error_msg}
    except Exception as e:
        # TODO: log errors in CloudWatch
        error_msg = "connection.get_publication_list :: Something went wrong getting publication list. {}".format(e)
        print('data_hub_connection.get_publication_list :: ', error_msg)
        connection.rollback()
        return {"Status": error_msg}

    finally:
        cursor.close()

    return publication_list


def get_publication_record(connection, params):
    """
    DEPRECATED
    Call Get Publication List stored procedure
    :param connection:
    :param params:
        PublicationFilePath: string
    :return: publication_list dictionary of publication attributes
    """
    try:
        sql = f"[ctl].[usp_GetPublicationRecord] @pPublicationFilePath = N'{params['PublicationFilePath']}'"
        print(sql)
        cursor = connection.cursor(as_dict=True)
        cursor.execute(sql)
        publication_list = cursor.fetchall()
        connection.commit()
    except pymssql.Error as err:
        # TODO: log errors in CloudWatch
        error_msg = "Something went wrong getting publication record. {}".format(err)
        print('connection.get_publication_record :: ', error_msg)
        connection.rollback()
        return {"Status": error_msg}
    finally:
        cursor.close()

    return publication_list


def prepare_issues(publication_list):
    """
    Use the Publication List to prepare an array of issues that will be processed.
    :param publication_list:
    :return: An Array of issues.
    """
    issue_list = []
    index = {}
    issue_list.append(index)
    try:
        for iteration, publication in enumerate(publication_list):
            index[publication['PublicationCode']] = iteration + 1

            issue = {
                'PublicationCode': publication['PublicationCode'],
                'DataLakePath': publication['PublicationFilePath'],  # 's3://dev-ascent-datalake/RawData/8x8CC/8x8CRZ/',
                'IssueName':  'Unknown', # publication['IssueName'],
                'SrcIssueName': 'Unknown',
                'StatusCode': 'IP',  # Maybe you want to start with a different status.
                'ReportDate': '1900-01-01',
                'SrcDFPublisherId': 'UNK',
                'SrcDFPublicationId': 'UNK',
                'SrcDFIssueId': 'UNK',
                'SrcDFCreatedDate': '',  # Technically you can read this from the ftp site.
                'FirstRecordSeq': '-1',
                'LastRecordSeq': '-1',
                'FirstRecordChecksum': 'UNK',
                'LastRecordChecksum': 'UNK',
                'PeriodStartTime': '1900-01-01',
                'PeriodStartTimeUTC': '1900-01-01',
                'PeriodEndTime': '1900-01-01',
                'PeriodEndTimeUTC': '1900-01-01',
                'RecordCount': '-1',
                'ETLExecutionId': '-1',
                'CreateBy': 'dh',
                'ModifiedBy': 'dh',
                'IssueId': '-1',
                'Verbose': '0'
            }
            # If we happened to get the data based on issue Id we can fill out more of this dictionary.
            # This also assumes we are only looping once or we will get the same issue id for several publication.
            # ToDo think about that!

            if 'IssueId' in publication:
                issue['IssueId'] = publication['IssueId']
            if 'IssueName' in publication:
                issue['IssueName'] = publication['IssueName']

            issue_list.append(issue)

        issue_list[0] = index
    except Exception as e:
        print('data_hub_connection.prepare_issues :: Exception building issue ', e)

    return issue_list


def insert_new_issue(connection, issue):
    """
    Call new issue stored procedure
    :param connection:
    :param issue:
    :return dict:
    """
    try:
        # print('Going to process: ', issue, ' connection:', connection)

        sql = (f"EXEC [ctl].[usp_InsertNewIssue] "
               f"@pPublicationCode = N'{issue['PublicationCode']}' "
               f",@pDataLakePath = N'{issue['DataLakePath']}' "
               f",@pIssueName = N'{issue['IssueName']}' "
               f",@pSrcIssueName = N'{issue['SrcIssueName']}' "
               f",@pStatusCode = N'{issue['StatusCode']}' "
               f",@pSrcPublisherId = N'{issue['SrcDFPublisherId']}' "
               f",@pSrcPublicationId = N'{issue['SrcDFPublicationId']}' "
               f",@pSrcDFIssueId = N'{issue['SrcDFIssueId']}' "
               f",@pSrcDFCreatedDate = N'{issue['SrcDFCreatedDate']}' "
               f",@pFirstRecordSeq = N'{issue['FirstRecordSeq']}' "
               f",@pLastRecordSeq = N'{issue['LastRecordSeq']}' "
               f",@pFirstRecordChecksum = N'{issue['FirstRecordChecksum']}' "
               f",@pLastRecordChecksum = N'{issue['LastRecordChecksum']}' "
               f",@pPeriodStartTime = N'{issue['PeriodStartTime']}' "
               f",@pPeriodStartTimeUTC = N'{issue['PeriodStartTimeUTC']}' "
               f",@pPeriodEndTime = N'{issue['PeriodEndTimeUTC']}' "
               f",@pRecordCount = N'{issue['RecordCount']}' "
               f",@pETLExecutionId = N'{issue['ETLExecutionId']}' "
               f",@pCreateBy = N'{issue['CreateBy']}' "
               f",@pIssueId = N'-1'"
               f",@pVerbose = N'0'"
               )
        # print('This is the SQL to execute :: ', sql)

        cursor = connection.cursor(as_dict=True)
        cursor.execute(sql)
        issue_id = cursor.fetchall()
        connection.commit()

    except pymssql.Error as err:
        # TODO: log errors in CloudWatch
        connection.rollback()
        error_msg = "connection.insert_new_issue :: Something went wrong inserting new issue. {}".format(err)
        print(error_msg)
        return {"message": error_msg}
    except Exception as e:
        error_msg = "connection.insert_new_issue :: Something went wrong inserting new issue. {}".format(e)
        print(error_msg)
        return {"message": error_msg}
    finally:
        if cursor:
            cursor.close()

    return issue_id


def update_issue(connection, issue):
    """
    Call update issue stored procedure
    :param connection:
    :param issue:
    :return dict:
    """
    if 'IssueId' not in issue:
        raise "Issue Id not found"
    try:
        sql = (f"EXEC [ctl].[usp_UpdateIssue] "
               f"@pIssueId = N'{issue['IssueId']}' "
               f",@pStatusCode = N'{issue['StatusCode']}' "
               f",@pReportDate = N'{issue['ReportDate']}' "
               f",@pSrcDFPublisherId = N'{issue['SrcDFPublisherId']}' "
               f",@pSrcDFPublicationId = N'{issue['SrcDFPublicationId']}' "
               f",@pSrcDFIssueId = N'{issue['SrcDFIssueId']}' "
               f",@pSrcDFCreatedDate = N'{issue['SrcDFCreatedDate']}' "
               f",@pDataLakePath = N'{issue['DataLakePath']}' "
               f",@pIssueName = N'{issue['IssueName']}' "
               f",@pSrcIssueName = N'{issue['SrcIssueName']}' "
               # f",@pPublicationSeq = N'{issue['PublicationSeq']}' "
               f",@pFirstRecordSeq = N'{issue['FirstRecordSeq']}' "
               f",@pLastRecordSeq = N'{issue['LastRecordSeq']}' "
               f",@pFirstRecordChecksum = N'{issue['FirstRecordChecksum']}' "
               f",@pLastRecordChecksum = N'{issue['LastRecordChecksum']}' "
               f",@pPeriodStartTime = N'{issue['PeriodStartTime']}' "
               f",@pPeriodStartTimeUTC = N'{issue['PeriodStartTimeUTC']}' "
               f",@pPeriodEndTime = N'{issue['PeriodEndTime']}' "
               f",@pPeriodEndTimeUTC = N'{issue['PeriodEndTimeUTC']}' "
               # f",@pIssueConsumedDate = N'{issue['IssueConsumedDate']}' "
               f",@pRecordCount = N'{issue['RecordCount']}' "
               f",@pModifiedBy = N'{issue['ModifiedBy']}' "
               # f",@pModifiedDtm = N'{issue['ModifiedDtm']}' "
               f",@pVerbose = N'0' "
               f",@pETLExecutionId = N'{issue['ETLExecutionId']}' "
               )

        cursor = connection.cursor(as_dict=True)
        cursor.execute(sql)
        connection.commit()

    except pymssql.Error as err:
        # log errors in CloudWatch
        connection.rollback()
        error_msg = "Something went wrong updating the issue. {}".format(err)
        print('connection.update_issue :: ', error_msg)
        return {"Status": error_msg}

    finally:
        cursor.close()

    return {"Status": "Success"}


def is_issue_absent(connection, file_name):
    # Determine if the file has already been processed by looking at ctl.issue.
    cursor = connection.cursor(as_dict=True)
    cursor.execute('select top 1 IssueId from ctl.issue where Statusid<>%s and SrcIssueName=%s', (5, file_name))
    result = cursor.fetchall()
    cursor.close()
    if len(result) > 0:
        return False
    else:
        return True


def notify_subscriber_of_distribution(connection, params):
    """
    DEPRECATED
    Call Get Publication List stored procedure
    :param connection:
    :param params dictionary:
        IssueId: Key Indicator for the issue being notified.
    :return: Success or Failure
    """
    try:
        sql = f"ctl.usp_NotifySubscriberOfDistribution @pIssueId = N'{params['IssueId']}'"
        # print(sql)
        cursor = connection.cursor(as_dict=True)
        cursor.execute(sql)
        connection.commit()

    except pymssql.Error as err:
        # TODO: log errors in CloudWatch
        error_msg = "Something went wrong getting publication record. {}".format(err)
        print('connection.get_publication_record :: ', error_msg)
        connection.rollback()
        return {"Status": error_msg}
    finally:
        cursor.close()

    return {'Status': 'Success'}


"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
acosta      04/08/2022  Initial Iteration
ffortunato  04/11/2022  pyODBC --> pymssql
                        + several new functions.
ffortunato  05/03/2022  o for iteration, publication in enumerate(publication_list):
ffortunato  07/29/2022  + Improving exception messages but still more to do.
ffortunato  08/09/2022  + connection.commit(), connection.rollback()
                        These are need to make sure there are no blocking 
                        processs on the database. 
*******************************************************************************
"""