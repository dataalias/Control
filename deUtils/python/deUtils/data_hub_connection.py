"""
*******************************************************************************
File: data_hub_connection.py

Purpose: Core functions invoked by the Data Hub class that interact with the db.

Dependencies/Helpful Notes :

*******************************************************************************
"""
from deUtils.delogging import log_to_console
import pymssql
from datetime import datetime

def connect_database(host, user, password, database):
    """
    Creates a pymssql connection for use by the class
    :return: pymssql connection
    """
    try:

        db_connection = pymssql.connect(host, user, password, database)

    except pymssql.Error as err:
        # TODO: log errors in CloudWatch
        e_msg = "connection.connect_database :: Connection error. " + err
        log_to_console(__name__,'Error',e_msg)
        return {'Status': 'Failure'}

    return db_connection


def get_publication_list(connection, params, get_type):
    """
    Call Get Publication List stored procedure
    :param connection:
    :param params:
        PublisherCode: string
    :return: publication_list dictionary of publication attributes
    """
    try:
        # print(params)
        if get_type == 'Schedule':
            error_msg = "Publication list look up failed for provided TriggerTypeCode: {}. Revisit the parameter list provided to the function.".format(params['TriggerTypeCode'])
            sql = f"[ctl].[usp_GetPublicationListScheduled] " \
                                             f"@pNextExecutionDateTime = N'{params['CurrentDate']}'"            
        elif get_type == 'PublisherCode':
            if not params['CurrentDate']:
                params['CurrentDate'] = datetime.now()
                print(params['CurrentDate'])
            #print('exec ctl.usp_GetPublicationList @pPublisherCode=',params['PublisherCode'],'@pNextExecutionDateTime = ',params['CurrentDate'])
            error_msg = "Publication list look up failed for provided PublisherCode: {}. Revisit the parameter list provided to the function.".format(params['PublisherCode'])
            sql = f"[ctl].[usp_GetPublicationList] @pPublisherCode = N'{params['PublisherCode']}', " \
                                             f"@pNextExecutionDateTime = N'{params['CurrentDate']}'"
        elif get_type == 'PublicationFilePath':
            #print('exec ctl.usp_GetPublicationRecord @pPublicationFilePath=',params['PublicationFilePath'])
            error_msg = "Publication list look up failed for provided PublicationFilePath: {}. Revisit the parameter list provided to the function.".format(params['PublicationFilePath'])
            sql = f"[ctl].[usp_GetPublicationRecord] @pPublicationFilePath = N'{params['PublicationFilePath']}'"

        elif get_type == 'IssueId':
            #print('exec ctl.usp_GetIssueDetails @pIssueId = ',params['IssueId'])
            error_msg = "Publication list look up failed for provided IssueId: {}. Revisit the parameter list provided to the function.".format(params['IssueId'])
            sql = f"[ctl].[usp_GetIssueDetails] @pIssueId = N'{params['IssueId']}'"

        elif get_type == 'FileName':
            error_msg = "Publication list look up failed for provided FileName: {}. Revisit the parameter list provided to the function.".format(params['FileName'])
            #print('exec ctl.usp_GetIssueDetails @pFileName = ',params['FileName'])
            sql = f"[ctl].[usp_GetIssueDetails] @pFileName = N'{params['FileName']}'"

        else:
            # print('Cant determine what data to get from database.')
            sql = 'N/A'
        #print(sql)
        cursor = connection.cursor(as_dict=True)
        cursor.execute(sql)
        publication_list = cursor.fetchall()
        connection.commit()
        
        if not publication_list:
            error_msg = 'No Publication List Returned  ::' + error_msg
            raise Exception(error_msg)
        
        elif publication_list[0]['PublicationCode'] == 'NA':
            error_msg = 'No Publication List Returned  ::' + error_msg
            raise Exception(error_msg)
        
    except pymssql.Error as err:
        error_msg = "connection.get_publication_list :: pymssql Something went wrong getting publication list. {}".format(err)
        log_to_console(__name__,'Error',error_msg)
        raise Exception (error_msg)
        #return {"Status": "Failed", "Error Message": error_msg}
    
    except Exception as e:
        error_msg = "connection.get_publication_list :: Something went wrong (not database related) getting publication list. {}".format(e)
        # print('data_hub_connection.get_publication_list :: ', error_msg)
        log_to_console(__name__,'Error',error_msg)
        connection.rollback()
        raise Exception (error_msg)
        #return {"Status": "Failed", "Error Message": error_msg}

    finally:
        cursor.close()

    return publication_list


def prepare_issues(publication_list, get_type):
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
                'IssueName':  publication['IssueName'],
                'SrcIssueName': 'Unknown',
                'SrcDFPublisherId': 'UNK',
                'SrcDFPublicationId': 'UNK',
                'SrcDFIssueId': 'UNK',
                'SrcDFCreatedDate': '',  # Technically you can read this from the ftp site.
                'FirstRecordSeq': '-1',
                'LastRecordSeq': '-1',
                'FirstRecordChecksum': 'UNK',
                'LastRecordChecksum': 'UNK',
                'PeriodStartTime': publication['LastHighWaterMarkDatetime'],
                'PeriodStartTimeUTC': publication['LastHighWaterMarkDatetimeUTC'],
                'PeriodEndTime': publication['HighWaterMarkDatetime'],
                'PeriodEndTimeUTC': publication['HighWaterMarkDatetimeUTC'],
                'IssueConsumedDate': '1900-01-01',
                #'RecordCount': publication['RecordCount'],
                #'ETLExecutionId': publication['ETLExecutionId'],
                'KeyStoreName': publication['KeyStoreName'],
                'CreatedBy': 'dh',
                'ModifiedBy': 'dh',
                'ModifiedDtm': datetime.now().strftime("%Y/%m/%d %H:%M:%S"),
                'Verbose': '0'
            }
            # If we happened to get the data based on issue Id we can fill out more of this dictionary.
            # This also assumes we are only looping once or we will get the same issue id for several publication.
            # ToDo think about that!

            if 'IssueId' in publication:
                issue['IssueId'] = publication['IssueId']
            if 'IssueName' in publication:
                issue['IssueName'] = publication['IssueName']
            if 'StatusCode' in publication:
                issue['StatusCode'] = publication['StatusCode']  # Maybe you want to start with a different status.
            else:
                issue['StatusCode'] = 'IP'
            if 'ReportDate' in publication:
                issue['ReportDate'] = publication['ReportDate']  # Maybe you want to start with a different status.
            else:
                issue['ReportDate'] = '1909-01-01'
            if 'RecordCount' in publication:
                issue['RecordCount'] = publication['RecordCount']  # Maybe you want to start with a different status.
            else:
                issue['RecordCount'] = '-1'
            if 'ETLExecutionId' in publication:
                issue['ETLExecutionId'] = publication['ETLExecutionId']  # Maybe you want to start with a different status.
            else:
                issue['ETLExecutionId'] = '-1'
            
            if  issue['PeriodStartTime'] == None:
                issue['PeriodStartTime'] = '1900-01-01'
                #print('PeriodStartTime was none')
            if  issue['PeriodStartTimeUTC'] == None:
                issue['PeriodStartTimeUTC'] = '1900-01-01'
                #print('PeriodStartTimeUTC was none')
            if  issue['PeriodEndTime'] == None:
                issue['PeriodEndTime'] = '1900-01-01'
                #print('PeriodEndTime was none')
            if  issue['PeriodEndTimeUTC'] == None:
                issue['PeriodEndTimeUTC'] = '1900-01-01'
                #print('PeriodEndTimeUTC was none')

            issue_list.append(issue)

        issue_list[0] = index
        issue = {} # Clean out the issue for the next loop.
    except Exception as e:
        error_msg = 'data_hub_connection.prepare_issues :: Exception building issue ', e
        log_to_console(__name__,'Error',error_msg)

    return issue_list


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
               #f",@pPeriodStartTimeUTC = N'{issue['PeriodStartTimeUTC']}' "
               f",@pPeriodEndTime = N'{issue['PeriodEndTime']}' "
               #f",@pPeriodEndTimeUTC = N'{issue['PeriodEndTimeUTC']}' "
               f",@pRecordCount = N'{issue['RecordCount']}' "
               f",@pETLExecutionId = N'{issue['ETLExecutionId']}' "
               f",@pCreateBy = N'{issue['CreatedBy']}' "
               f",@pIssueId = N'-1'"
               f",@pVerbose = N'0'"
               )
        #print("\r\n This is the SQL to execute :: {sql}, \r\n")

        cursor = connection.cursor(as_dict=True)
        cursor.execute(sql)
        issue_id = cursor.fetchall()
        connection.commit()

    except pymssql.Error as err:
        # TODO: log errors in CloudWatch
        connection.rollback()
        error_msg = "connection.insert_new_issue :: Something went wrong inserting new issue. {}".format(err)
        log_to_console(__name__,'Error',error_msg)
        return {"message": error_msg}
    except Exception as e:
        error_msg = "connection.insert_new_issue :: Something went wrong inserting new issue. {}".format(e)
        log_to_console(__name__,'Error',error_msg)
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
               #f",@pPublicationSeq = N'{issue['PublicationSeq']}' "  # This is taken care of in the insert new issue procedure.
               f",@pFirstRecordSeq = N'{issue['FirstRecordSeq']}' "
               f",@pLastRecordSeq = N'{issue['LastRecordSeq']}' "
               f",@pFirstRecordChecksum = N'{issue['FirstRecordChecksum']}' "
               f",@pLastRecordChecksum = N'{issue['LastRecordChecksum']}' "
               f",@pPeriodStartTime = N'{issue['PeriodStartTime']}' "
               f",@pPeriodStartTimeUTC = N'{issue['PeriodStartTimeUTC']}' "
               f",@pPeriodEndTime = N'{issue['PeriodEndTime']}' "
               f",@pPeriodEndTimeUTC = N'{issue['PeriodEndTimeUTC']}' "
               f",@pIssueConsumedDate = N'{issue['IssueConsumedDate']}' "
               f",@pRecordCount = N'{issue['RecordCount']}' "
               f",@pModifiedBy = N'{issue['ModifiedBy']}' "
               f",@pModifiedDtm = N'{issue['ModifiedDtm']}' "
               f",@pVerbose = N'0' "
               f",@pETLExecutionId = N'{issue['ETLExecutionId']}' "
               )

        cursor = connection.cursor(as_dict=True)
        cursor.execute(sql)
        connection.commit()

    except pymssql.Error as err:
        # log errors in CloudWatch
        connection.rollback()
        error_msg = "data_hub_connection.update_issue() :: Something went wrong updating the issue. {}".format(err)
        log_to_console(__name__,'Error',error_msg)
        return {"Status": error_msg}

    except Exception as e:
        # log errors in CloudWatch
        connection.rollback()
        error_msg = "data_hub_connection.update_issue() :: Something (not database related) went wrong updating the issue. {}".format(e)
        log_to_console(__name__,'Error',error_msg)
        return {"Status": error_msg}

    finally:
        cursor.close()

    return {"Status": "Success"}


def is_issue_absent(connection, file_name):
    # Determine if the file has already been processed by looking at ctl.issue.
    try: 
        sql = 'select top 1 IssueId from ctl.issue i join ctl.RefStatus s on i.StatusId = s.StatusId where s.StatusCode not in (\'IF\') and SrcIssueName=\'{}\''.format(file_name)
        cursor = connection.cursor(as_dict=True)
        cursor.execute(sql)
        result = cursor.fetchall()
        cursor.close()
    except pymssql.Error as err:
        error_msg = "data_hub_connection.is_issue_absent :: Something went wrong looking up the issue. {}".format(err)
        log_to_console(__name__,'Error',error_msg)

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
        error_msg = "data_hub_connection.notify_subscriber_of_distribution :: Something went wrong in pymssql notifying subscriber. {}".format(err)
        log_to_console(__name__,'Error',error_msg)
        connection.rollback()
        return {"Status": error_msg}
    except Exception as e:
        # TODO: log errors in CloudWatch
        error_msg = "data_hub_connection.notify_subscriber_of_distribution :: Something went wrong notifying subscriber. {}".format(e)
        log_to_console(__name__,'Error',error_msg)
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
ffortunato  20230522    o modified logging to us log to console.  
ffortunato  20230615    + TriggerTypeCode - Scheduled.
ffortunato  20230626    + Passing KeyStoreName to issue.
ffortunato  20230804    + IssueConsumedDate.
*******************************************************************************
"""