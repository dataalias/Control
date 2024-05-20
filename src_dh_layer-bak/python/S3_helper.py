"""
All s3 function should land here...
"""
import logging
from botocore.exceptions import ClientError
import threading
import os
import sys
from boto3.s3.transfer import TransferConfig
import boto3
import botocore
import boto3
import zipfile
from datetime import *
from io import BytesIO
import json
import re
import logging
import threading
from boto3.s3.transfer import TransferConfig


def s3_create_folder(s3_bucket_name, s3_bucket_path, s3_sub_folders):
    try:
        #Iterate result set to process further for folder creation in S3 bucket
        s3_resource = boto3.resource('s3')
        s3_client = boto3.client('s3')
        print(f"BucketName:{s3_bucket_name} BucketPath:{s3_bucket_path}  BucketSubFolder:{s3_sub_folders}")
        folder_exist = False
        for obj in s3_resource.Bucket(s3_bucket_name).objects.filter(Prefix=s3_bucket_path + s3_sub_folders):
            if obj.key.endswith(s3_sub_folders):
                folder_exist = True
                break
        #create the folder of current day
        if folder_exist == False:
            s3_client.put_object(Bucket=s3_bucket_name, Key=s3_bucket_path + s3_sub_folders)
            print("Day directory created on S3")
        else:
            print("Sub folders already exist")
        return 'Success'
    except Exception as e:
        print("Unable to create directory on S3.", e)
        return 'Failure'
## ---End of create_folder_in_s3 method


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

def Read_Objects_From_S3(S3_BucketName, object_name=None):
    # Multipart upload
    """REad a file From S3 bucket

    :param s3bucketname: Name of S3 Bucket
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


def unzip_file(s3bucket, s3folder, s3unzipfolder, zipfile):

    try:
        response = {'Status': 'Failure'}
        resource = boto3.resource('s3')

        zip_obj = resource.Object(bucket_name=s3bucket, key=f"{s3folder}{zipfile}")
        print("zip_obj=", zip_obj)
        buffer = BytesIO(zip_obj.get()["Body"].read())
        z = zipfile.ZipFile(buffer)

        for filename in z.namelist():
            file_info = z.getinfo(filename)
            # Now copy the files to the 'unzipped' S3 folder
            print(f"Copying file {filename} to {s3bucket}/{s3unzipfolder}{filename}")

            response = resource.meta.client.put_object(
                Body=z.open(filename).read(),
                Bucket=s3bucket,
                Key=f'{s3unzipfolder}{filename}'
            )

        print(f"Done Unzipping {zipfile}")
    except Exception as e:
        print('S3UnZip.unzip_file failed: ', e)
    return response

# unzip_file


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

Author		Date		Description
----------	----------	-------------------------------------------------------


*******************************************************************************
"""
