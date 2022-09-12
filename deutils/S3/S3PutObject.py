"""
*******************************************************************************
File: S3PutObject.py

Purpose: To Upload file as Objects(Byte Araay) to S3

Dependencies/Helpful Notes :

*******************************************************************************
"""

import logging
from botocore.exceptions import ClientError
import threading
import boto3
import os
import sys
from boto3.s3.transfer import TransferConfig


# This module is used to upload objects into S3 Bucket

def upload_objects_to_s3(file_name, s3bucketname, object_name=None):
    """Upload a file to an S3 bucket

    :param s3bucketname: Nam eof S3 Bucket
    :param file_name: File to upload
    :param bucket: Bucket to upload to
    :param object_name: S3 object name. If not specified then file_name is used
    :return: True if file was uploaded, else False
    """

    s3 = boto3.resource('s3')
    try:
        s3.meta.client.put_object(Body=file_name, Bucket=s3bucketname, Key=object_name)

    except Exception as e:
        print("Error uploading: {}".format(e))


"""
*******************************************************************************
Change History:

Author		    Date		    Description
----------	   ----------	    -----------------------------------------------
schandramouly  04/11/2022       Initial Iteration

*******************************************************************************
"""
