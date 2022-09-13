"""
*******************************************************************************
File: S3Upload.py

Purpose: This module will upload file to S3, if the size of teh file is > 25MB
Multipart upload is automatically initiated

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


def multi_part_upload_with_s3(file_name, s3bukcetname, object_name=None):
    # Multipart upload
    """Upload a file to an S3 bucket

    :param s3bukcetname: Bucket to upload to
    :param file_name: File to upload
    :param bucket: Bucket to upload to
    :param object_name: S3 object name. If not specified then file_name is used
    :return: True if file was uploaded, else False
    """
    config = TransferConfig(multipart_threshold=1024 * 25, max_concurrency=10,
                            multipart_chunksize=1024 * 25, use_threads=True)
    s3 = boto3.resource('s3')
    try:
        s3.meta.client.upload_file(file_name, s3bukcetname, object_name,
                                   ExtraArgs={'ACL': 'public-read'},
                                   Config=config,
                                   Callback=ProgressPercentage(file_name)
                                   )
    except Exception as e:
        print("Error uploading: {}".format(e))


class ProgressPercentage(object):
    def __init__(self, filename):
        self._filename = filename
        self._size = float(os.path.getsize(filename))
        self._seen_so_far = 0
        self._lock = threading.Lock()


def __call__(self, bytes_amount):
    # To simplify we'll assume this is hooked up
    # to a single filename.
    with self._lock:
        self._seen_so_far += bytes_amount
        percentage = (self._seen_so_far / self._size) * 100
        sys.stdout.write(
            "\r%s  %s / %s  (%.2f%%)" % (
                self._filename, self._seen_so_far, self._size,
                percentage))
        sys.stdout.flush()


"""
*******************************************************************************
Change History:

Author		    Date		    Description
----------	   ----------	    -----------------------------------------------
schandramouly  04/11/2022       Initial Iteration

*******************************************************************************
"""
