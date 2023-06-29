"""
*******************************************************************************
File: app.py

Purpose: Lambda Handler for Schedule driven and S3 event . 

Class: N/A

Methods: lambda_handler

Properties: N/A

Dependencies/Helpful Notes : N/A

*******************************************************************************
"""

from io import BytesIO
import json
import os
import io
import csv
import boto3
import pymssql
from data_hub import *
from datetime import datetime, timezone, date
import sys
import boto3

"""Sample pure Lambda function

    Parameters
    ----------
    event: dict, required
        S3 Event 

        This lambda is triggered based on S3 file upload event

    context: object, required
        Lambda Context runtime methods and attributes

        Context doc: https://docs.aws.amazon.com/lambda/latest/dg/python-context-object.html

    Returns
    ------
    IssueId,FileName,Filepath to the glue workflow

        Thislambda function does two things.
        1. Match the File name and extract issue if already exists.
        2. Insert new issue if filename is not matching
    This function interacty with Datahub in two ways.
    params={"FileName":(IssueName)}
    params={"FilePath":(S3FilePath)}

    Issue Status :

        1. IS - Issue Started (First time the issue is created)
        2. IP - Issue Prepared ( Issue prepared )

"""


def lambda_handler(event, context):
 
    Environment = os.environ['MyLambdaEnvName']
    Secrets     = os.environ['Secrets']
    Key = event['Records'][0]['s3']['object']['key']

    StripCharactar = "/"
    S3FilePath = StripCharactar.join(Key.split(StripCharactar)[:3])
    S3FilePath = S3FilePath.replace('+',' ')
    S3FileName = Key.split('/')[-1]

    S3FilePath = S3FilePath + "/"

    # Extract S3 Key
    BucketName            = event['Records'][0]['s3']['bucket']['name']
    S3FullFilePath        = os.path.dirname(Key)
    PublicationListExists = False
    IssuedetailsFound     = False
    IssueInserted         = False
    IssueUpdated          = False
    try:
        MyDataHub = DataHub(Secrets)
        #pass File path and get publication details
        MyPublicationInputParms = {'PublicationFilePath': S3FilePath}

        MyPublications = MyDataHub.get_publication_list(MyPublicationInputParms)
        PublicationListExists = True
    except Exception as e:    
            log_to_console(__name__,'error',f"DataHubS3Trigger.lambda_handler :: Failed to get publication list. {e}")
            
    '''
    If Publication Exists,check if issue is already created
    '''
    if PublicationListExists:
        for results in MyDataHub.publication_list:
                
            WorkflowName = results['GlueWorkflow']
            PublicationCode = results['PublicationCode']
            # Pass the file name and check if issue has been already created
            MyPublicationInputParms = {'FileName': S3FileName}
            try:
                MyPublications = MyDataHub.get_publication_list(MyPublicationInputParms)
                IssueId        = str(MyDataHub.get_issue_id())
                IssuedetailsFound = True
            except Exception as e:    
                log_to_console(__name__,'error',f"DataHubS3Trigger.lambda_handler :: Failed to get Issue details. {e}")
    else:
        log_to_console(__name__,'error',f"DataHubS3Trigger.lambda_handler :: Publication Not found.")
                
    if IssuedetailsFound:
    # -1 is returned if issue does not exists. Insert issue 
        if IssueId == '-1':
                    
            issue_updates = {}
            try:
                issue_updates['CreatedBy'] = "DataHubTrigger"
                issue_updates['ModifiedBy'] = "DataHubTrigger"
                MyDataHub.set_publication_code(PublicationCode)
                issue_updates['StatusCode'] = 'IS'
                MyDataHub.set_issue_val(issue_updates)
                MyDataHub.insert_new_issue()    
                IssueId = str(MyDataHub.get_issue_id())
                IssueInserted = True
            except Exception as e:
                log_to_console(__name__,'error',f"DataHubS3Trigger.lambda_handler :: Failed to Insert Issue. {e}")
        else:
    # Update existing issue if issue already exists
            issue_updates['StatusCode'] = 'IP'
            MyDataHub.set_issue_val(issue_updates)
            MyDataHub.insert_new_issue()   
            IssueUpdated = True
    else:
        log_to_console(__name__,'error',f"DataHubS3Trigger.lambda_handler :: Issue Not found.")
    """
    Triggers WorkFlow with Issue ID,Filepath and FileName
    """
    if IssueInserted or IssueUpdated:
        try:
            session = boto3.session.Session()
            glue_client = session.client('glue')
            workflow_run_id = glue_client.start_workflow_run(Name = WorkflowName,RunProperties = {"FileName" :S3FileName,"FilePath" : S3FullFilePath, "IssueId" : IssueId})
        
            print(f'workflow_run_id: {workflow_run_id}')
        except Exception as e:
            log_to_console(__name__,'error',f"DataHubS3Trigger.lambda_handler :: Failed to start workflow. {e}")
    else:
        log_to_console(__name__,'error',f"DataHubS3Trigger.lambda_handler :: Issue Neither created nor updated.")
                    
    

    

"""
*******************************************************************************
Change History:

Author		    Date		Description
----------  	----------	-------------------------------------------------------
ffortunato  2023-04-15  Initial Iteration
ffortunato  2023-05-17  Used additional try catch to catch all exceptions

*******************************************************************************
"""