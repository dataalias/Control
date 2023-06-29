from S3.S3ReadObject import Read_Objects_From_S3
from dh.data_hub import *
import boto3
import json

CONFIG_FILE = 'dev / stg / prodbucket-key...json'


def parse_lambda_parameters(event):
    """

    :return: dictionary of the parameters passed to lambda.

    """
    try:
        status = {'Status':'Failure'}
        success = {'Status':'Success'}
        print(__name__, ':: Starting Function')
        status = success

    except Exception as e:
        print(__name__, ':: Function Failed')

    return status


def lambda_handler(event, context):

    # split Event trigger
    print(event)
    Key = event['Records'][0]['s3']['object']['key']
    print(Key)
    StripCharactar = "/"
    KeyUpd = StripCharactar.join(Key.split(StripCharactar)[:3])
    KeyUpd = KeyUpd.replace('+', ' ')
    S3FileName = Key.split('/')[-1]
    print(S3FileName)
    KeyUpd = KeyUpd + "/"
    print(Key)
    BucketName = event['Records'][0]['s3']['bucket']['name']
    print(BucketName)
    # S3FilePath = "s3://" + BucketName + "/" + KeyUpd
    S3FilePath = KeyUpd
    print(S3FilePath)

    # determine associated bucket based on the event based bucket
    # but honestly, if we can derive env based on the source bucket ... are we in need of a config?

    config_data = Read_Objects_From_S3(BucketName, "DataHubStagingEvent/config/S3_file_event_lambda.json")
    file_content = config_data.get()['Body'].read()
    json_content = json.loads(file_content)
    print(json_content["__Header"]["Env"]["EnvironmentAbbreviation"])
    DATA_HUB_SECRET_KEY = json_content["AWS"]["DataHubDatabaseSecretKey"]
    ODS_SECRET_KEY = json_content["AWS"]["DataHubDatabaseSecretKey"]

    try:
        MyDataHub = DataHub(DATA_HUB_SECRET_KEY)
        MyPublicationInputParms = {'PublicationFilePath': S3FilePath}

        MyPublications = MyDataHub.get_publication_list(MyPublicationInputParms)
        print(MyPublications)
        for results in MyDataHub.publication_list:
            print(results)
            WorkflowName = results['GlueWorkflow']
            #PublicationCode = results['PublicationCode']
            print(MyDataHub.get_publication_code())
            print(WorkflowName)

        #MyDataHub.set_publication_code(PublicationCode)
        MyDataHub.insert_new_issue()
        IssueId = str(MyDataHub.get_issue_id())
    except Exception as e:
        print(e)
        '''print('Error getting object {} from bucket {}. Make sure they exist '
              'and your bucket is in the same region as this '
              'function.'.format(BucketName, BucketName))'''
        raise e

    # session = boto3.session.Session()
    # glue_client = session.client('glue')
    # e=None

    try:
        session = boto3.session.Session()
        glue_client = session.client('glue')
        workflow_run_id = glue_client.start_workflow_run(Name=WorkflowName,
                                                         RunProperties={"FileName": S3FileName, "FilePath": S3FilePath,
                                                                        "IssueId": IssueId})

        print(f'workflow_run_id: {workflow_run_id}')
    except Exception as e:
        print(e)
        print('Error getting object {} from bucket {}. Make sure they exist '
              'and your bucket is in the same region as this '
              'function.'.format(BucketName, BucketName))
        raise e
