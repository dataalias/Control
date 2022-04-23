import pymssql


def connect_database(host, user, password, database):
    """
    Handle MySql Connection
    :return:
    """
    try:
        conn = pymssql.connect(host, user, password, database)
    except pymssql.Error as err:
        # TODO: log errors in CloudWatch
        print("Connection error.", err)
        return {}

    return conn


def get_publication_list(connection, params):
    """
    Call Get Publication List stored procedure
    :param connection:
    :param params:
        PublisherCode: string
    :return: publication_list dictionary of publication attributes
    """
    try:
        sql = f"[ctl].[usp_GetPublicationList] @pPublisherCode = N'{params['PublisherCode']}', " \
                                             f"@pNextExecutionDateTime = N'{params['CurrentDate']}'"
        print(sql)
        cursor = connection.cursor(as_dict=True)
        cursor.execute(sql)
        publication_list = cursor.fetchall()

    except pymssql.Error as err:
        # TODO: log errors in CloudWatch
        error_msg = "Something went wrong getting publication list. {}".format(err)
        print(error_msg)
        return {"message": error_msg}

    return publication_list


def insert_new_issue(connection, issue):
    """
    Call new issue stored procedure
    :param connection:
    :param issue:
    :return dict:
    """
    try:
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
        print('This is the SQL to execute :: ', sql)
        cursor = connection.cursor(as_dict=True)
        cursor.execute(sql)
        issue_id = cursor.fetchall()

    except pymssql.Error as err:
        # TODO: log errors in CloudWatch
        error_msg = "Something went wrong inserting new issue. {}".format(err)
        print(error_msg)
        return {"message": error_msg}

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
               f",@pModifiedDtm = N'{issue['ModifiedDtm']}' "
               f",@pVerbose = N'0' "
               f",@pETLExecutionId = N'{issue['ETLExecutionId']}' "
               )

        cursor = connection.cursor(as_dict=True)
        cursor.execute(sql)

    except pymssql.Error as err:
        # TODO: log errors in CloudWatch
        error_msg = "Something went wrong updating the issue. {}".format(err)
        print(error_msg)
        return {"Status": error_msg}

    return {"Status": "Success"}
