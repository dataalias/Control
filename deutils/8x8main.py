from helper.deUtils import *
from helper.ftps3xfer import *
from delogging.delogging import log_to_console
from S3.S3CreateFolder import s3_create_folder
from S3.S3Upload import s3_multi_part_upload
from ftp.fasttransport import *
from pathlib import Path
from DataHub.data_hub import *
from S3.S3UnZip import s3_unzip_file_multi_dest
import boto3
import math
import time
import os

dl_bucket = 'dev-ascent-datalake'
dl_path_crz = 'RawData/8x8CC/8x8CRZ/'
dl_path_cr = 'RawData/8x8CC/8x8CR/'
dl_path_cri = 'RawData/8x8CC/8x8CRI/'
s3_connection = boto3.client("s3")
CHUNK_SIZE = 6291456  # for parallel processing of chunks for bigger files

pub_list_parms = {}
pub_list_parms['PublisherCode'] = '8x8CC'
pub_list_parms['CurrentDate'] = datetime.today().strftime('%Y-%b-%d %H:%M:%S')

issue_updates = {}

# Instantiate data hub.
MyDataHub = DataHub('dev/devadw/DataHub/Glue_svc')
MyDataHub.get_publication_list(pub_list_parms)

# connect to the ftp site.
ftp_con = get_ftp_connection_from_secret('glue/ftp/moveit')
list_of_files_on_ftp = ftp_con.listdir()

print('Publication List V')
for x in MyDataHub.publication_list:
    print(x)
print('Issue List V')
for y in MyDataHub.issue_list:
    print(y)

"""
print(MyDataHub.get_publication_code())
print('xxxxxxxxx')
print('About to set the publication code')
# Prime data hub to work with the zip file.
"""
MyDataHub.set_publication_code('8x8CRZ')
print(MyDataHub.get_publication_code())
print('Did i get something? ^')


for file in list_of_files_on_ftp:
    # Determine if the file has already been processed by looking at ctl.issue.
    # True file doesn't exist and we continue. False don't process again.
    process = MyDataHub.is_issue_absent(file)
    # process = True

    log_to_console(__name__, 'Info', f"Processing File: {file}")
    # Copy the file from ftp to s3.
    if process:
        # Get folder path
        try:
            s3_key = dl_path_crz + file[18:22] + '/' + file[22:24] + '/' + file[24:26] + '/' + file

            MyDataHub.set_publication_code('8x8CRZ')
            issue_updates['DataLakePath'] = 's3://' + dl_bucket + s3_key
            issue_updates['SrcIssueName'] = file
            issue_updates['IssueName'] = file
            issue_updates['PeriodStartTime'] = file[18:22] + '/' + file[22:24] + '/' + file[24:26]
            issue_updates['PeriodEndTime'] = file[18:22] + '/' + file[22:24] + '/' + file[24:26]
            MyDataHub.set_issue_val(issue_updates)

            # ToDo make this less syntax
            MyDataHub.insert_new_issue(MyDataHub.issue_list[MyDataHub.get_publication_idx()])

            result = transfer_file_from_ftp_to_s3(s3_connection, ftp_con, file, dl_bucket, s3_key, CHUNK_SIZE)
            print(result)
            issue_updates['StatusCode'] = 'IL'
            MyDataHub.update_issue(issue_updates)

            msg = ('FTP transfer Complete. Bucket: ' + dl_bucket + ' s3 Key: ' + s3_key)
            log_to_console(__name__, 'Info', msg)

        except Exception as e:
            print(e)

        # insert the issue and keep going.
        try:
            # Clean up issue_updates, so we don't update too much good stuff.
            issue_updates = {}

            MyDataHub.set_publication_code('8x8CRI')
            issue_updates['StatusCode'] = 'IS'
            MyDataHub.set_issue_val(issue_updates)
            MyDataHub.insert_new_issue(MyDataHub.issue_list[MyDataHub.get_publication_idx()])
            MyDataHub.set_publication_code('8x8CR')
            MyDataHub.set_issue_val(issue_updates)
            MyDataHub.insert_new_issue(MyDataHub.issue_list[MyDataHub.get_publication_idx()])

        except Exception as e:
            msg = ('Unable to update issue data for zip file. ', e)
            log_to_console(__name__, 'Err', msg)

        # now let's unzip what we got.
        try:

            # Todo S3_Unzipped_Folder --> Use the datahub object instead...
            S3_Unzipped_Folder = {'Index': dl_path_cri + file[18:22] + '/' + file[22:24] + '/' + file[24:26] + '/',
                                  'Recording': dl_path_cr + file[18:22] + '/' + file[22:24] + '/' + file[24:26] + '/'}
            s3_unzip_file_multi_dest(dl_bucket, s3_key, S3_Unzipped_Folder, MyDataHub)

            # Update update issues.
            MyDataHub.set_publication_code('8x8CRI')
            issue_updates['StatusCode'] = 'IS'
            MyDataHub.update_issue(issue_updates)

            MyDataHub.insert_new_issue(MyDataHub.issue_list[MyDataHub.get_publication_idx()])
            MyDataHub.set_publication_code('8x8CR')
            issue_updates['StatusCode'] = 'IL'
            MyDataHub.update_issue(issue_updates)

        except Exception as e:
            msg = ('Unzip failed. ', e)
            log_to_console(__name__, 'Info', msg)

        print('about to break')
        break  # after one successful run.

        # Get the data to stage and ods
        try:
            print('Get the data to stage and ods')
        except Exception as e:
            print('Cant load the data to Stage or ODS')

    # if we hit this else there is nothing to do for the file goto the next one.
    else:
        msg = 'Issue present in DataHub. file: ' + file + ' not processed.'
        # log_to_console(__name__, 'Info', msg)

# Final Cleanup
