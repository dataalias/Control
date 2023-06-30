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
    
    try: 
        now = datetime.now()
        FileDate = now.strftime("%Y%m%d%H%M%S")
        CurrenDate = now.strftime("%Y-%m-%d %H:%M:%S")

        # Pop the dePostingGroupDW.fifo
        # Insert Posting Group Processing Record for specific issue
        # Execute any process whos parent dependencies are met. (loop)
        # Set distribution to complete.

        response = success

    except Exception as err:
        err_msg = f"PostingGroupTrigger.lambda_handler :: Failed to interact with PostingGroup class. {err}"
        log_to_console(__name__,'error',err_msg)
        raise(err_msg)
    
    log_to_console(__name__,'info','End: PostingGroupTrigger.lambda_handler.')   
    return response

"""
*******************************************************************************
Change History:
no
Author		Date		Description
----------	----------	-------------------------------------------------------
ffortunato  2023-06-21  Initial Iteration
*******************************************************************************
"""
