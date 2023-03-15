import logging
from botocore.exceptions import ClientError
import threading
import boto3
import os
import sys
from boto3.s3.transfer import TransferConfig


def Upload_Objects_to_S3(file_name, S3_BucketName, object_name=None):
    """Upload a file to an S3 bucket
    Todo: Determine if the file / object already exists.
    Todo: Force overwrite / don't overwrite.

    :param file_name: File to upload
    :param bucket: Bucket to upload to
    :param object_name: S3 object name. If not specified then file_name is used
    :return: True if file was uploaded, else False
    """

    s3 = boto3.resource('s3')
    try:
        s3.meta.client.put_object(Body=file_name, Bucket=S3_BucketName, Key=object_name)

    except Exception as e:
        print("Error uploading: {}".format(e))

"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------


*******************************************************************************
"""