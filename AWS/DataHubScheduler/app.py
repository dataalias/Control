"""
*******************************************************************************
File: app.py

Purpose: This lambda function is invoked 

Class: N/A

Methods: lambda_handler

Properties: N/A

Dependencies/Helpful Notes : N/A

*******************************************************************************
"""

import json
import boto3
import os
from delogging import log_to_console
from data_hub import *
from datetime import datetime
from pytz import timezone
#import pytz

# this block can be commented out. this is just for local testing.
"""
import sys
sys.path.insert(1,'D:\\Users\\ffortunato\\source\\AscentRepo\\deDataHub\\src_dh_layer\\python')
my_event={'Key01':'Val01'}
my_context={'Key01':'Val01'}
lambda_handler(my_event, my_context)
"""

def lambda_handler(event, context):
    """

    Parameters
    ----------
    event: This is a JSON object. The body variable includes a JSON representation of the parameters being passed to the DataHub class.
    context: I have no idea what this is...


    Returns
    ------
    Success: JSON with a 'body' representing the latest issue data.
    Failure: JSON with a 'body' representing the error encountered.
    """

    log_to_console(__name__,'info','Start: DataHubScheduler.lambda_handler.')

    response = {'Status': 'Failure'}
    success = {'Status': 'Success'}
    return_json =  {
                "statusCode": 200,
                "headers": {
                    "content-type": "application/json"
                },
                "body": json.dumps(response),
            }
    now = datetime.now()
    FileDate = now.strftime("%Y%m%d%H%M%S")
    
    CurrenDateUTC = now.strftime("%Y-%m-%d %H:%M:%S")
    #CurrentDate = CurrenDateUTC.astimezone(timezone('US/Pacific'))
    CurrentDate = now.astimezone(timezone('US/Pacific')).strftime("%Y-%m-%d %H:%M:%S")

    # Testing
    # CurrenDate = '2024-01-01 01:00:59.123'
    
    YearMonDay = now.strftime("%Y/%m/%d/")

    # Gettin session objects ready
    session = boto3.session.Session()
    glue_client = session.client('glue')

    try:
        # This is key for ensuring that JSON is translated corretly to a python dictionary.
        log_to_console(__name__,'info','Set: Defining and setting new variables.')
        params = {}
        issue_updates = {}

        #key = event['Records'][0]['s3']['object']['key']
        environment     = os.environ['MyLambdaEnvName']
        aws_region      = os.environ['Region']
        dh_db_secret    = os.environ['DataHubConnectionSecret']
        datalake_bucket = os.environ['DatalakeBucket']
        trigger_type_code = os.environ['TriggerTypeCode']
        db_dw = os.environ['db_dw']
        
        
        params['TriggerTypeCode'] = trigger_type_code
        params['CurrentDate'] = CurrentDate
        my_data_hub = DataHub(dh_db_secret)

        dh_status   = my_data_hub.get_publication_list(params)
        #my_publication_list = my_data_hub.publication_list
        # Iterate through each of the feeds.
        if my_data_hub.publication_list:
            for publication in my_data_hub.publication_list: #my_publication_list:
                
                issue_updates['IssueName'] = publication['PublicationCode'] + '_' + FileDate + '.csv'
                issue_updates['DataLakePath'] = 's3://' + datalake_bucket + '/' + publication['PublicationFilePath'] + YearMonDay
                issue_updates['CreatedBy'] = "DataHubScheduler"
                issue_updates['ModifiedBy'] = "DataHubScheduler"
                
                #Insert the issue
                my_data_hub.set_publication_code(publication['PublicationCode'])
                my_data_hub.set_issue_val(issue_updates)
                my_data_hub.insert_new_issue()

                #Fire the work flow with the issue as the payload.
                GlueWorkflow = environment + db_dw +'_'+ publication['GlueWorkflow']
                print('Workflow: ', GlueWorkflow)
                
                issue =  my_data_hub.issue_list[my_data_hub.publication_idx]
                issue_id_str = str(issue['IssueId'])
                #print(issue_id_str)
                issue['IssueId']=issue_id_str
                
                workflow_run_id = glue_client.start_workflow_run(Name = GlueWorkflow, RunProperties = issue)
                print('workflow: ',workflow_run_id)

                #reset
                issue_updates={}
                issue={}
                GlueWorkflow=''
            response    = success
            log_to_console(__name__,'info',f"Successfully updated Issue data. DataHub status: {dh_status}")
        else:
            response    = success
            response['Message'] = 'No PublicationList was returned from the database.'

    except Exception as err:
        log_to_console(__name__,'error',f"DataHubAPIHandler.lambda_handler :: Failed to interact with DataHub class. {err}")
        err_msg = f"Lambda Failed to call Data Hub Layer.  {err}"

    # Return success or Failure + error message.
    if response['Status'] == 'Success':
        return_json =  {
            "statusCode": 200,
            "headers": {
                "content-type": "application/json"
            },
            "body": json.dumps(response),
        }
    else:
        response['error'] = err_msg
        # print(json.dumps(response))
        return_json = {
            "statusCode": 200,
            "headers": {
                "content-type": "application/json"
            },
            "body": json.dumps(response)
        }
    #print(return_json)
    return return_json

"""
*******************************************************************************
Change History:
no
Author		Date		Description
----------	----------	-------------------------------------------------------
ffortunato  2023-06-15  Initial Iteration
                        Iterating through publications
ffortunato  2023-06-19  Ficing Up parameters for Glue Workflow call.
ffortunato  2023-06-27  +UTC --> PST.
                        +More elegantly handle no publication list.
*******************************************************************************
"""
