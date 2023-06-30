"""
*******************************************************************************
File: app.py

Purpose: This lambda function is invoked by the API Gateway (POST). When a dictionary
    (json object) is passed in that includes the key IssueId and an assoicated
    value the method will update the issue with any other information provided
    by the dictionary and respond with a dictionary (json object) that includes
    the current details of the issue.

Class: N/A

Methods: lambda_handler

Properties: N/A

Dependencies/Helpful Notes : N/A

*******************************************************************************
"""
# this block can be commented out. this is just for local testing.
#import sys
#sys.path.insert(1,'/Users/ffortunato/source/repos/deDataHub/src_dh_layer/python')
import json
import os
from delogging import log_to_console
from data_hub import *

# import requests

def lambda_handler(event, context):
    """
    This function takes the issue data 
    1) Transforms it from JSON to a disctionary.
    2) Retrieves associated publication and Issue data.
    3) Applies any changes to the issue.
    4) Returns success or Failure


    Parameters
    ----------
    event: This is a JSON object. The body variable includes a JSON representation of the parameters being passed to the DataHub class.
    context: I have no idea what this is...


    Returns
    ------
    Success: JSON with a 'body' representing the latest issue data.
    Failure: JSON with a 'body' representing the error encountered.
    """

    log_to_console(__name__,'info','Made it to log.')

    response = {'Status': 'Failure'}
    success = {'Status': 'Success'}
    return_json =  {
                "statusCode": 200,
                "headers": {
                    "content-type": "application/json"
                },
                "body": json.dumps(response),
            }

    try:
        # This is key for ensuring that JSON is translated corretly to a python dictionary.
        my_event    = json.loads(event['body']) #Use this when running the lambda via API
        #my_event    = event['body']  # Use this when testing the lambda directly
        #my_event['CreatedBy'] = "DataHubAPIHandler"
        my_event['ModifieBy'] = "DataHubAPIHandler"

        secrets     = os.environ['Secrets']
        my_data_hub = DataHub(secrets)
        dh_status   = my_data_hub.get_publication_list(my_event)
        dh_status   = my_data_hub.update_issue(my_event)
        response    = success
        log_to_console(__name__,'info','Successfully updated Issue data.')

    except Exception as err:
        log_to_console(__name__,'error',f"DataHubAPIHandler.lambda_handler :: Failed to interact with DataHub class. {err}")
        err_msg = f"Lambda Failed to call Data Hub Layer.  {err}"

    # return  json.dumps(my_data_hub.issue_list[1])
    if response['Status'] == 'Success':
        return_json =  {
            "statusCode": 200,
            "headers": {
                "content-type": "application/json"
            },
            "body": json.dumps(my_data_hub.issue_list[1]),
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
            # "error": err_msg,
        }

    return return_json

"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
ffortunato  2023-05-30  Initial Iteration
ffortunato  2023-05-31  Better Error Loging
ffortunato  2023-06-12  Decent Error Message to API Gateway

*******************************************************************************
"""