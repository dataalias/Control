"""
*******************************************************************************
File: posting_group_connection.py

Purpose: Core functions invoked by the Posting Group class that interact with the db.

Dependencies/Helpful Notes :

*******************************************************************************
"""

import pyodbc
from delogging import log_to_console


def connect_database(host, user, password, database, dbInstanceIdentifier):
    """
    Creates a pymssql connection for use by the class
    :return: pymssql connection
    """
    try:
        dbInstanceIdentifier = dbInstanceIdentifier + '_64'
        conn_string = "DSN={};Database={};UID={};PWD={}".format(dbInstanceIdentifier,database,user,password)
        print(conn_string)
        conn = pyodbc.connect(conn_string)
    except pyodbc.Error as err:
        # TODO: log errors in CloudWatch
        print("connection.connect_database :: Connection error.", err)
        return {'Status': 'Failure'}

    return conn

def get_publication_list(connection, params):
    """
    THIS IS JUST TESTING DELETE THIS FUNCITON.

    Call Get Publication List stored procedure
    :param connection:
    :param params:
        PublisherCode: string
    :return: publication_list dictionary of publication attributes
    """
    try:
        print(params)
        if 'PublisherCode' in params:
            # print('usp_GetPublicationList')
            sql = f"[ctl].[usp_GetPublicationList] @pPublisherCode = N'{params['PublisherCode']}', " \
                                             f"@pNextExecutionDateTime = N'{params['CurrentDate']}'"
            
            print(params['PublisherCode'] )
            print(params['CurrentDate'])

            sql = "{call [ctl].[usp_GetPublicationList]('" + params['PublisherCode'] + '', '' + params['CurrentDate']+ "')}"
            print(sql)

        elif 'PublicationFilePath' in params:
            # print('usp_GetPublicationRecord')
            sql = f"[ctl].[usp_GetPublicationRecord] @pPublicationFilePath = N'{params['PublicationFilePath']}'"

        elif 'IssueId' in params:
            # print('usp_GetIssueDetails')
            sql = f"[ctl].[usp_GetIssueDetails] @pIssueId = N'{params['IssueId']}'"

        elif 'FileName' in params:
            # print('usp_GetIssueDetails')
            sql = f"[ctl].[usp_GetIssueDetails] @pFileName = N'{params['FileName']}'"

        else:
            # print('Cant determine what data to get from database.')
            sql = 'N/A'

        cursor = connection.cursor()
        cursor.execute(sql)
        publication_list = cursor.fetchall()
        connection.commit()

    except pyodbc.Error as err:
        error_msg = "connection.get_publication_list :: pymssql Something went wrong getting publication list. {}".format(err)
        log_to_console(__name__,'Error',error_msg)
        return {"Status": error_msg}
    
    except Exception as e:
        error_msg = "connection.get_publication_list :: Something went wrong getting publication list. {}".format(e)
        # print('data_hub_connection.get_publication_list :: ', error_msg)
        log_to_console(__name__,'Error',error_msg)
        connection.rollback()
        return {"Status": error_msg}

"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
ffortunato  08/09/2022  Initial Iteration
*******************************************************************************
"""