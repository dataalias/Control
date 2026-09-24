"""
***********************************************************************************************************************
File:		s3helper.py
Purpose:	S3 helper functions.
Author:		ffortunato
Date:		20231101
***********************************************************************************************************************
"""

from io import BytesIO
import os
import sys
from eimutils.delogging import log_to_console
import threading

# from datetime import *
import boto3
from boto3.s3.transfer import TransferConfig

# import botocore
# from botocore.exceptions import ClientError
import zipfile
import re

"""
***********************************************************************************************************************
Name:		s3_create_folder
Purpose:	Create a folder in S3 bucket.
Example:	s3_create_folder(s3_bucket_name, s3_bucket_path, s3_sub_folders)
Parameters:
        s3_bucket_name - Name of the S3 bucket
        s3_bucket_path - Path in the S3 bucket where the folder should be created
        s3_sub_folders - Subfolder name to create within the specified path
Called by:
Calls:
Errors:
Author:		ffortunato
Date:		20220401
***********************************************************************************************************************
"""


def s3_create_folder(s3_bucket_name, s3_bucket_path, s3_sub_folders):
    try:
        # Iterate result set to process further for folder creation in S3 bucket
        s3_resource = boto3.resource("s3")
        s3_client = boto3.client("s3")
        log_to_console(__name__, "Info", f"BucketName:{s3_bucket_name} BucketPath:{s3_bucket_path} \
                       BucketSubFolder:{s3_sub_folders}")
        folder_exist = False
        for obj in s3_resource.Bucket(s3_bucket_name).objects.filter(
            Prefix=s3_bucket_path + s3_sub_folders
        ):
            if obj.key.endswith(s3_sub_folders):
                folder_exist = True
                break
        # create the folder of current day
        if folder_exist is False:
            s3_client.put_object(
                Bucket=s3_bucket_name, Key=s3_bucket_path + s3_sub_folders
            )
            log_to_console(__name__, "Info", "Day directory created on S3")
        else:
            log_to_console(__name__, "Info", "Sub folders already exist")
        return "Success"
    except Exception as e:
        e_msg = "s3helper.s3_create_folder :: s3 error. " + str(e)
        log_to_console(__name__, "Error", e_msg)
        raise


"""
***********************************************************************************************************************
Name:		upload_objects_to_s3
Purpose:	# This module is used to upload objects into S3 Bucket
Example:	upload_objects_to_s3(file_name, s3bucketname, object_name=None)
Parameters:
        file_name - File to upload
        s3bucketname - Name of S3 Bucket
        object_name - S3 object name. If not specified then file_name is used
Called by:
Calls:
Errors:
Author:		ffortunato
Date:		20220401
***********************************************************************************************************************
"""


def upload_objects_to_s3(file_name, s3bucketname, object_name=None):
    """Upload a local file to an S3 bucket.

    :param file_name: Local path of the file to upload
    :param s3bucketname: S3 bucket name
    :param object_name: S3 key. Defaults to the basename of file_name if not provided.
    """
    if object_name is None:
        object_name = os.path.basename(file_name)

    s3 = boto3.resource("s3")
    try:
        with open(file_name, "rb") as f:
            s3.meta.client.put_object(Body=f.read(), Bucket=s3bucketname, Key=object_name)

    except Exception as e:
        e_msg = "s3helper.upload_objects_to_s3 :: s3 error uploading file. " + str(e)
        log_to_console(__name__, "Error", e_msg)
        raise


"""
***********************************************************************************************************************
Name:		Read_Objects_From_S3
Purpose:    Read a file From S3 bucket
Example:	Read_Objects_From_S3(S3_BucketName, object_name=None)
Parameters:
        S3_BucketName - Name of S3 Bucket
        object_name - S3 object name. If not specified then file_name is used
Called by:
Calls:
Errors:
Author:		ffortunato
Date:		20220401
***********************************************************************************************************************
"""


def Read_Objects_From_S3(S3_BucketName, object_name=None):
    # Multipart upload
    """REad a file From S3 bucket

    :param s3bucketname: Name of S3 Bucket
    :param bucket: Bucket to read From
    :param object_name: S3 object name. If not specified then file_name is used
    :return: Object
    """

    s3 = boto3.resource("s3")
    try:
        obj = s3.Object(S3_BucketName, object_name)
        return obj

    except Exception as e:
        e_msg = "s3helper.Read_Objects_From_S3 :: s3 error reading file. " + str(e)
        log_to_console(__name__, "Error", e_msg)
        raise


"""
***********************************************************************************************************************
Name:		unzip_file
Purpose:    Read a .zip file From S3 bucket and write the uncompressed contents back
Example:	unzip_file(s3bucket, s3folder, s3unzipfolder, zipfile)
Parameters:
        s3bucket - Name of S3 Bucket (Both source and destination)
        s3folder - Source folder that holds the compressed file.
        s3unzipfolder - Destination folder to write the uncompressed contents.
        zipfile - Source file that will be unzipped / decompressed.
Called by:
Calls:
Errors:
Author:		ffortunato
Date:		20220401
***********************************************************************************************************************
"""


def unzip_file(s3bucket, s3folder, s3unzipfolder, zip_filename):

    try:
        response = {"Status": "Failure"}
        resource = boto3.resource("s3")

        zip_obj = resource.Object(bucket_name=s3bucket, key=f"{s3folder}{zip_filename}")
        buffer = BytesIO(zip_obj.get()["Body"].read())
        z = zipfile.ZipFile(buffer)

        for filename in z.namelist():
            # Strip path traversal components so an adversarial zip can't write outside s3unzipfolder
            safe_name = filename.lstrip("/").replace("../", "").replace("..\\", "")
            if not safe_name or safe_name.endswith("/"):
                continue  # skip directories and empty entries
            log_to_console(__name__, "Info", f"Copying file {safe_name} to {s3bucket}/{s3unzipfolder}{safe_name}")

            with z.open(filename) as zf:
                response = resource.meta.client.put_object(
                    Body=zf.read(),
                    Bucket=s3bucket,
                    Key=f"{s3unzipfolder}{safe_name}",
                )

        log_to_console(__name__, "Info", f"Done Unzipping {zip_filename}")
    except Exception as e:
        e_msg = f"s3helper.unzip_file failed: {e}"
        log_to_console(__name__, "Error", e_msg)
        raise
    return response


def unzip_file_nested(s3bucket, s3folder, zipfilename, dh, env, file_name_prefix=""):
    """
    Read a .zip file From S3 bucket and write the uncompressed contents back
    to a new s3 bucket.

    :param s3bucket: Name of S3 Bucket (Both source and destination)
    :param s3folder: Source folder that holds the compressed file.
    :param zipfilename: Source file that will be unzipped / decompressed.
    :param df: Dataframe that includes regex and associated file location. See Readme.md for more detail.
    :param env: enum{dev,stg,prod}  used to determine bucket path.
    :return:
    """
    try:
        response = {"Status": "Failure"}
        resource = boto3.resource("s3")

        zip_obj = resource.Object(bucket_name=s3bucket, key=f"{s3folder}{zipfilename}")
        # print("zip_obj=", zip_obj)
        msg = f"Unpacking: {s3bucket}{s3folder}{zipfilename}"
        log_to_console("unzip_file", "Info", msg)
        buffer = BytesIO(zip_obj.get()["Body"].read())
        z = zipfile.ZipFile(buffer)

        for filename in z.namelist():
            # Strip path traversal so a crafted zip can't write outside the intended prefix
            safe_name = filename.lstrip("/").replace("../", "").replace("..\\", "")
            if not safe_name or safe_name.endswith("/"):
                continue  # skip directories and empty entries

            regex_matches = dh.publication_list[
                dh.publication_list["SRCFILEREGEX"].apply(
                    lambda x: True if re.search(x, safe_name) else False
                )
            ]
            if len(regex_matches) > 0:
                if len(regex_matches) > 1:
                    log_to_console(
                        "unzip_file", "Warn",
                        f"File '{safe_name}' matched {len(regex_matches)} publications; "
                        f"routing to first match: {regex_matches.iloc[0]['PUBLICATIONCODE']}"
                    )
                s3unzipfolder = regex_matches.iloc[0]["PUBLICATIONFILEPATH"]
                publication_code = regex_matches.iloc[0]["PUBLICATIONCODE"]

                dest_key = f"{env}{s3unzipfolder}{file_name_prefix}{safe_name}"

                # Upload first — only record the issue after a successful write so a
                # failed upload doesn't permanently mark the file as processed.
                with z.open(filename) as zf:
                    response = resource.meta.client.put_object(
                        Body=zf.read(),
                        Bucket=s3bucket,
                        Key=dest_key,
                    )

                dh.set_publication_code(publication_code)
                issue = {}
                issue["IssueName"] = f"{file_name_prefix}{safe_name}"
                issue["StatusCode"] = "IP"
                dh.set_issue_val(issue)
                dh.insert_new_issue()

                msg = f"Copied file {safe_name} to {s3bucket}/{dest_key}"
                log_to_console("unzip_file", "Info", msg)
            else:
                msg = f"File _NOT_ extracted: {safe_name}"
                log_to_console("unzip_file", "Warn", msg)

        log_to_console("unzip_file", "Info", f"Done Unzipping {zipfilename}")
    except Exception as e:
        msg = f"S3UnZip.unzip_file failed: {e}"
        log_to_console("unzip_file", "Error", msg)
        raise
    return response


# end unzip_file


"""
***********************************************************************************************************************
Name:		multi_part_upload_with_s3
Purpose:    Upload a file to an S3 bucket using multipart upload.
Example:	multi_part_upload_with_s3(file_name, s3bukcetname, object_name=None)
Parameters:
        file_name - File to upload
        s3bukcetname - Name of S3 Bucket
        object_name - S3 object name. If not specified then file_name is used
Returns:
        True if file was uploaded, else False
Called by:
Calls:
Errors:
Author:		ffortunato
Date:		20240401
***********************************************************************************************************************
"""


def multi_part_upload_with_s3(file_name, s3bukcetname, object_name=None):
    # Multipart upload
    """Upload a file to an S3 bucket

    :param s3bukcetname: Bucket to upload to
    :param file_name: File to upload
    :param bucket: Bucket to upload to
    :param object_name: S3 object name. If not specified then file_name is used
    :return: True if file was uploaded, else False
    """
    config = TransferConfig(
        multipart_threshold=1024 * 25,
        max_concurrency=10,
        multipart_chunksize=1024 * 25,
        use_threads=True,
    )
    s3 = boto3.resource("s3")
    try:
        s3.meta.client.upload_file(
            file_name,
            s3bukcetname,
            object_name,
            Config=config,
            Callback=ProgressPercentage(file_name),
        )
    except Exception as e:
        e_msg = "s3helper.multi_part_upload_with_s3 :: s3 error uploading file. " + str(e)
        log_to_console(__name__, "Error", e_msg)
        raise


class ProgressPercentage(object):
    def __init__(self, filename):
        self._filename = filename
        self._size = float(os.path.getsize(filename))
        self._seen_so_far = 0
        self._lock = threading.Lock()

    def __call__(self, bytes_amount):
        with self._lock:
            self._seen_so_far += bytes_amount
            percentage = (self._seen_so_far / self._size) * 100 if self._size else 100.0
            sys.stdout.write(
                "\r%s  %s / %s  (%.2f%%)"
                % (self._filename, self._seen_so_far, self._size, percentage)
            )
            sys.stdout.flush()


"""
***********************************************************************************************************************
Change History:

Author		Date		Description
--------	----------	-------------------------------------------------------
ffortunato  2023-06-01  Initial Iteration.
jgabriel    2024-09-05  + unzip_file_nested
ffortunato  2024-09-05  + unzip_file_nested
ffortunato  07-22-2025  o formatting
ffortunato  06-26-2026  o s3unzipfolder = regex_matches.iloc[0]["PUBLICATIONFILEPATH"]
                        o publication_code = regex_matches.iloc[0]["PUBLICATIONCODE"]
***********************************************************************************************************************
"""
