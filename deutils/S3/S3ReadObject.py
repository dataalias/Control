import logging
from botocore.exceptions import ClientError
import threading
import boto3
import os
import sys
from boto3.s3.transfer import TransferConfig


def Read_Objects_From_S3(S3_BucketName, object_name=None):
    # Multipart upload
    """REad a file From S3 bucket

    :param bucket: Bucket to read From
    :param object_name: S3 object name. If not specified then file_name is used
    :return: Object
    """

    s3 = boto3.resource('s3')
    try:
        obj = s3.Object(S3_BucketName, object_name)
        return obj

    except Exception as e:
        print("Error Reading File: {}".format(e))

"""
*******************************************************************************
Change History:

Author		Date		Description
----------	----------	-------------------------------------------------------


*******************************************************************************
"""