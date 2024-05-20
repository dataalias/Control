"""
*******************************************************************************
File: S3UnZip.py

Purpose: This module will unzip File from S3 and Upload the Unzipped file back to S3

Dependencies/Helpful Notes :

*******************************************************************************
"""
import botocore
import boto3
import zipfile
from datetime import *
from io import BytesIO
import json
import re


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


def s3_unzip_file_multi_dest(S3_BucketName, S3_Zip_Folder, S3_Unzipped_Folder, data_hub):
    """
    :param S3_BucketName: This is the s3 bucket where we are doing our work.
    :param S3_Zip_Folder: This is the path for the zip file.
    :param S3_Unzipped_Folder:
    :param data_hub:  A dh object with publication and issues tuple and list.
    :return:
    """

    response = {'Status': 'Failure'}

    try:
        print('Start: S3UnZip.s3_unzip_file_multi_dest')
        print('Source: bucket_name=', S3_BucketName, 'key=', S3_Zip_Folder, 'Unzip=', S3_Unzipped_Folder)

        zip_count_01 = 0
        zip_count_02 = 0

        resource = boto3.resource('s3')
        zip_obj = resource.Object(bucket_name=S3_BucketName, key=f"{S3_Zip_Folder}")
        buffer = BytesIO(zip_obj.get()["Body"].read())
        z = zipfile.ZipFile(buffer)


        # Look up the name in our dictionary and then parse the file date to determine the final resting space.
        # and we better pass the Rec_Issue and Idx_Issue so we can post them up appropriately.
        # for each file within the zip
        # ToDo add file type to publication list. Then use that to determine file path so this is generic.
        # use the file name mask to do the match...

        for filename in z.namelist():
            file_info = z.getinfo(filename)
            if file_info.filename[-3:] == 'csv':
                # if zip_count_01 == 0:
                s3_folder = S3_Unzipped_Folder['Index']
                # S3_Unzipped_Folder['Index'] = s3_folder + filename
                data_hub.set_publication_code('8x8CRI')
                issue_updates = {}
                issue_updates['IssueName'] = filename
                issue_updates['DataLakePath'] = 's3://' + S3_BucketName + '/' + s3_folder + filename
                data_hub.set_issue_val(issue_updates)
                zip_count_01 = zip_count_01 + 1

            elif file_info.filename[-3:] == '.au':
                s3_folder = S3_Unzipped_Folder['Recording']
                data_hub.set_publication_code('8x8CR')
                issue_updates = {}
                issue_updates['DataLakePath'] = 's3://' + S3_BucketName + '/' + s3_folder
                if zip_count_02 == 0:
                    data_hub.set_issue_val(issue_updates)
                zip_count_02 = zip_count_02 + 1

            else:
                # There is nothing to write to the bucket...
                continue

            # Now copy the files to the 'unzipped' S3 folder
            # print(f"Copying file {filename} to {S3_BucketName}/{s3_folder}{filename}")

            response = resource.meta.client.put_object(
                Body=z.open(filename).read(),
                Bucket=S3_BucketName,
                Key=f'{s3_folder}{filename}'
            )
            s3_folder = ''

        print('Complete: S3UnZip.s3_unzip_file_multi_dest')
        #print(f"Done Unzipping {S3_Zip_Folder}")
        #print(response)

    except resource.meta.client.exceptions as err:
        print("Bucket {} already exists!".format(err.response['Error']['BucketName']))

    except botocore.exceptions.ClientError as b_e:
        print('S3UnZip.s3_unzip_file_multi_dest failed: ', b_e, ' ', response)

    except Exception as e:
        print('S3UnZip.s3_unzip_file_multi_dest failed: ', e, ' ', response)

    finally:
        return response
# s3_unzip_file_multi_dest

"""
*******************************************************************************
Change History:

Author		    Date		    Description
----------      ----------	    -----------------------------------------------
schandramouly   04/11/2022       Initial Iteration
ffortunato      05/03/2022      + multi dest (hack)
                                o clean up unzip.
*******************************************************************************
"""
