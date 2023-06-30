"""
*******************************************************************************
File: aws_secrets.py

Purpose: Gets secret values from AWS Secrets.

Dependencies/Helpful Notes :

*******************************************************************************
"""
# Use this code snippet in your app.
# If you need more information about configurations or implementing the sample code, visit the AWS docs:
# https://aws.amazon.com/developers/getting-started/python/

import boto3
import json
from botocore.exceptions import ClientError

"""
*******************************************************************************
Function: get_secret

Purpose: Gets AWS secret data.

Parameters:
     secret_name - AWS secret name from the account the process is running in
                   that contains the db connection information.  

Calls:

Called by:

Returns: dictionary of secret values

*******************************************************************************
"""


def get_secret(secret_name):
    # secret_name = "dev/Glue_svc/devadw"
    region_name = "us-east-1"
    #get_secret_value_response = 'N/A'

    # Create a Secrets Manager client

    try:
        session = boto3.session.Session()
        client = session.client(
            service_name='secretsmanager',
            region_name=region_name
        )
    except Exception as e:
        print(__name__, ' :: ', e)
        raise e

    # In this sample we only handle the specific exceptions for the 'GetSecretValue' API.
    # See https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
    # We rethrow the exception by default.

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'DecryptionFailureException':
            # Secrets Manager can't decrypt the protected secret text using the provided KMS key.
            # Deal with the exception here, and/or rethrow at your discretion.
            print(__name__, ' :: ', e)
            raise e
        elif e.response['Error']['Code'] == 'InternalServiceErrorException':
            # An error occurred on the server side.
            # Deal with the exception here, and/or rethrow at your discretion.
            print(__name__, ' :: ', e)
            raise e
        elif e.response['Error']['Code'] == 'InvalidParameterException':
            # You provided an invalid value for a parameter.
            # Deal with the exception here, and/or rethrow at your discretion.
            print(__name__, ' :: ', e)
            raise e
        elif e.response['Error']['Code'] == 'InvalidRequestException':
            # You provided a parameter value that is not valid for the current state of the resource.
            # Deal with the exception here, and/or rethrow at your discretion.
            print(__name__, ' :: ', e)
            raise e
        elif e.response['Error']['Code'] == 'ResourceNotFoundException':
            # We can't find the resource that you asked for.
            # Deal with the exception here, and/or rethrow at your discretion.
            print(__name__, ' :: ', e)
            raise e
        else:
            print(__name__, ' :: ', e)
            raise e
    except Exception as e:
        print(__name__, ' :: ', e)
        raise e
    """
    else:
        get_secret_value_response = "Failed to get secret"
    """
    """
    else:
        # Decrypts secret using the associated KMS key.
        # Depending on whether the secret is a string or binary, one of these fields will be populated.
        if 'SecretString' in get_secret_value_response:
            secret = get_secret_value_response['SecretString']
        else:
            decoded_binary_secret = base64.b64decode(get_secret_value_response['SecretBinary'])
    """
    # Your code goes here.

    connection_parms = json.loads(get_secret_value_response["SecretString"])

    return connection_parms


"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------
ffortunato  04/11/2022  derived from AWS secrets code
ffortunato  08/10/2022  adding some print statements in the error handling.
*******************************************************************************
"""