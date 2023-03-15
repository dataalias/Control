# my packages
# import json
from delogging.delogging import log_to_console
from helper.deUtils import get_db_connection_from_secret
# from sqlalchemy import select
# from DataHubODBC.DataHubODBC import *
from DataHub.data_hub import *
from datetime import datetime

"""
This just a main to test the projects
auth ff

"""

log_to_console(__name__, 'Info', 'Start')

# Open and close a connection for fun...
data_hub_connection = get_db_connection_from_secret("dev/devadw/DataHub/Glue_svc")
log_to_console(__name__, 'Info', data_hub_connection)
"""
sql = f"EXEC [ctl].[usp_GetPublicationList] @pPublisherCode = N'8x8CC'"
cursor = data_hub_connection.cursor(as_dict=True)
cursor.execute('[ctl].[usp_GetPublicationList] \'8x8CC\'')
publication_list = cursor.fetchall()
print(publication_list)
"""
data_hub_connection.close()

# Testing pymssql objects. DATAHUB
log_to_console(__name__, 'Info', 'Starting basic py ms sql testing...')

CurrentDate = datetime.now().strftime("%m/%d/%Y %H:%M:%S")

MyDataHub = DataHub("dev/devadw/DataHub/Glue_svc")
MyPublicationInputParms = {'PublisherCode': '8x8CC', 'CurrentDate': CurrentDate}
MyPublications = MyDataHub.get_publication_list(MyPublicationInputParms)
for row in MyPublications:
    print(row)

MyIssueInputParams = {'PublicationCode': '8x8CRI'
                    , 'DataLakePath': 'Unknown'
                    , 'IssueName': '8x8CRI_19000101_000000.txt'
                    , 'SrcIssueName': 'Unknown'
                    , 'StatusCode': 'IP'
                    , 'ReportDate': '1900-01-01'
                    , 'SrcDFPublisherId': 'UNK'
                    , 'SrcDFPublicationId': 'UNK'
                    , 'SrcDFIssueId': 'UNK'
                    , 'SrcDFCreatedDate': '1900-01-01'
                    , 'FirstRecordSeq': '-1'
                    , 'LastRecordSeq': '-1'
                    , 'FirstRecordChecksum': 'UNK'
                    , 'LastRecordChecksum': 'UNK'
                    , 'PeriodStartTime': '1900-01-01'
                    , 'PeriodEndTime': '1900-01-01'
                    , 'PeriodStartTimeUTC': '1900-01-01'
                    , 'PeriodEndTimeUTC': '1900-01-01'
                    , 'RecordCount': 0
                    , 'ETLExecutionId': 0
                    , 'CreateBy': 'admin'
                    , 'ModifiedBy': 'admin2'
                    , 'ModifiedDtm':  '1900-01-01'
                    , 'IssueId': '-1'
                    , 'Verbose': 0
                    , 'ETLExecutionId': '-1'}

NewValue = '-99'
MyIssueInputParams['IssueId'] = NewValue
try:
    MyIssueStatus = MyDataHub.insert_new_issue(MyIssueInputParams)
    print(MyIssueStatus)
except Exception as e:
    print('Cant create issue: ', e)
print(MyIssueInputParams)

MyIssueInputParams['StatusCode'] = 'IL'
try:
    MyIssueStatus = MyDataHub.update_issue(MyIssueInputParams)
    print(MyIssueStatus)
except Exception as e:
    print('Cant create issue: ', e)


#MyIssueInputParams.update(MyIssueId[0])
#print(MyIssueInputParams)

# MyResult = get_secret("dev/Glue_svc/devadw")
# Get the secret and then get publication records.
"""
try:
    MySecret = get_secret("dev/devadw/DataHub/Glue_svc")
    log_to_console(__name__, 'Info', MySecret)

    CurrentDate = datetime.date.today()
    MyPublication = Publication(MySecret['host'], MySecret['user'], MySecret['password'], MySecret['database'], '8x8CC',
                            CurrentDate)
    print(MyPublication.get_publication_list())
except Exception as e:
    print(e)
"""

"""
# Testing SQL Alchemy objects. DATAHUB ODBC
log_to_console(__name__, 'Info', 'Starting SQL Alchemy portion of things...')
# from DataHubODBC.DataHubODBC import *

password = ""
odbc_connection_string = "mssql+pyodbc://Glue_svc:]X[V`c3[J5gRu2\"JuN?V@devadw:1433/DataHub?driver=SQL+Server"
print(odbc_connection_string)

try:
    engine = create_engine(odbc_connection_string)
    print(engine)

    session = Session(engine)
    log_to_console(__name__, 'Info', "Session Created")
    stmt = select(Publication).where(Publication.PublicationCode.in_(["8x8CRZ", "8x8CR", "8x8CRI"]))
    #stmt = session.query(Publication).filter(Publication.PublicationCode.in_(["8x8CRZ", "8x8CR", "8x8CRI"]))
    #session.query(MyUserClass).filter(MyUserClass.id.in_((123,456))).all()
    for Publication in session.scalars(stmt):
        print(Publication)
except Exception as e:
    print("Problem with engine:", e)
"""

""" TESTING FTP
DB_SERVER = 'localhost'  # 'SDL485'
DB_NAME = 'DataHub'
DB_USER = 'sa'
DB_PASSWORD = 'somebadpassword11@@'

ftpHost = "transfer.goalsolutions.com"
ftpPort = 443
ftpUsername = "ffortunato"
ftpPassword = "password2022!!"
ftpDirectory = '/Home/ffortunato'

print("Construct DataHub")
#(self, host, user, password, database):
myDataHub = DataHub(DB_SERVER, DB_USER, DB_PASSWORD, DB_NAME)
#print(myDataHub.host)

ftp = open_ftp_connection(ftpHost, ftpPort, ftpUsername, ftpPassword, ftpDirectory)
LogToConsole(__name__, 'Info', ftp)

db = connect_database(DB_SERVER, DB_USER, DB_PASSWORD, DB_NAME)
LogToConsole(__name__, 'Info', db)

cursor = db.cursor(as_dict=True)

files_on_site = ftp.listdir()
for file in files_on_site:
    LogToConsole(__name__, 'Info', "File: {0}".format(str(file)))
    results = cursor.execute('select top 1 IssueName from ctl.issue where IssueName = %s', file)
    results = cursor.fetchall()

    if results:
        LogToConsole(__name__, 'Info', 'issue already processed found')
    else:
        LogToConsole(__name__, 'Info', 'issue not found')
        CurrentFileDate = file.replace('goalstructuredsol_', '').replace('.zip', '')
        LogToConsole(__name__, 'Info', "FileDate: {0}".format(str(CurrentFileDate)))
"""

log_to_console(__name__, 'Info', 'End')


"""
cursor = dh_con.cursor(as_dict=True)
results = cursor.execute('select IssueId from ctl.issue where Statusid=%s and SrcIssueName=%s', (8, zip_file_name))
result = cursor.fetchall()
cursor.close()
"""

"""
        ftp_file = ftp_con.file(file, "r")
        print("MyDir: ", local_directory)
        dest = local_directory + '\\' + file
        print("Dest: ", dest)
        print('Src: ', file)
        # phys_file = ftp_con.get(file, local_directory_file)
        # mem_file = ftp_con.open(file, "r+", bufsize=32768)
        mem_file = ftp_con.getfo(file, dest)
        print(type(mem_file))

        mem_file.write(dest)
        print(phys_file)
"""


"""local_directory = 'D:/Users/ffortunato/Documents/CallZip/'
local_directory_file = 'D:/Users/ffortunato/Documents/CallZip/MyFile.txt'
print(local_directory)
print(os.getcwd())
os.chdir(local_directory)
print(os.getcwd())
local_directory = os.getcwd()
print(local_directory)

f = open(local_directory_file, "a")
f.write("Now the file has more content!\r\n")
f.close()


Path(local_directory+'file.').touch()
"""
"""
import time
import math

chunk_size = 6000000 #6 MB
chunk_count = int(math.ceil(ftp_file_size / float(chunk_size)))
multipart_upload = s3_conn.create_multipart_upload(Bucket=bucket_name, Key=s3_key_val)
parts = []
for i in range(chunk_count):
    print("Transferring chunk {}...".format(i + 1), "of ", chunk_count)

    start_time = time.time()
    ftp_file.prefetch(chunk_size * (i+1) # This statement is where the magic was to keep reading forward.
    chunk = ftp_file.read(int(chunk_size))
    part = s3_conn.upload_part(
        Bucket=bucket_name,
        Key=s3_file_path,
        PartNumber=part_number,
        UploadId=multipart_upload["UploadId"],
        Body=chunk
    )
    end_time = time.time()
    total_seconds = end_time - start_time
    print("speed is {} kb/s total seconds taken {}".format(math.ceil((int(chunk_size) / 1024) / total_seconds),
                                                           total_seconds))
    part_output = {"PartNumber": i, "ETag": part["ETag"]}

    parts.append(part)
    print("Chunk {} Transferred Successfully!".format(i + 1))

part_info = {"Parts": parts}
s3_conn.complete_multipart_upload(
    Bucket=bucket_name,
    Key=s3_key_val,
    UploadId=multipart_upload["UploadId"],
    MultipartUpload=part_info
)
"""



"""

crz_issue = {
    'PublicationCode': '8x8CRZ',
    'DataLakePath': 's3://dev-ascent-datalake/RawData/8x8CC/8x8CRZ/',
    'IssueName': 'Unknown',
    'SrcIssueName': 'Unknown',
    'StatusCode': 'IP',
    'ReportDate': '1900-01-01',
    'SrcDFPublisherId': 'UNK',
    'SrcDFPublicationId': 'UNK',
    'SrcDFIssueId': 'UNK',
    'SrcDFCreatedDate': '', #Technically you can read this from the ftp site.
    'FirstRecordSeq': '-1',
    'LastRecordSeq': '-1',
    'FirstRecordChecksum': 'UNK',
    'LastRecordChecksum': 'UNK',
    'PeriodStartTime': '1900-01-01',
    'PeriodStartTimeUTC': '1900-01-01',
    'PeriodEndTime': '1900-01-01',
    'PeriodEndTimeUTC': '1900-01-01',
    'RecordCount': '-1',
    'ETLExecutionId': '-1',
    'CreateBy': 'ffortunato',
    'ModifiedBy': 'ffortunato',
    'IssueId': '-1',
    'Verbose': '0'
}
cr_issue = {
    'PublicationCode': '8x8CR',
    'DataLakePath': 's3://dev-ascent-datalake/RawData/8x8CC/8x8CR/',
    'IssueName': 'Unknown',
    'SrcIssueName': 'Unknown',
    'StatusCode': 'IP',
    'ReportDate': '1900-01-01',
    'SrcDFPublisherId': 'UNK',
    'SrcDFPublicationId': 'UNK',
    'SrcDFIssueId': 'UNK',
    'SrcDFCreatedDate': '', #Technically you can read this from the ftp site.
    'FirstRecordSeq': '-1',
    'LastRecordSeq': '-1',
    'FirstRecordChecksum': 'UNK',
    'LastRecordChecksum': 'UNK',
    'PeriodStartTime': '1900-01-01',
    'PeriodStartTimeUTC': '1900-01-01',
    'PeriodEndTime': '1900-01-01',
    'PeriodEndTimeUTC': '1900-01-01',
    'RecordCount': '-1',
    'ETLExecutionId': '-1',
    'CreateBy': 'ffortunato',
    'IssueId': '-1',
    'Verbose': '0'
}
cri_issue = {
    'PublicationCode': '8x8CRI',
    'DataLakePath': 's3://dev-ascent-datalake/RawData/8x8CC/8x8CRI/',
    'IssueName': 'Unknown',
    'SrcIssueName': 'Unknown',
    'StatusCode': 'IP',
    'ReportDate': '1900-01-01',
    'SrcDFPublisherId': 'UNK',
    'SrcDFPublicationId': 'UNK',
    'SrcDFIssueId': 'UNK',
    'SrcDFCreatedDate': '', #Technically you can read this from the ftp site.
    'FirstRecordSeq': '-1',
    'LastRecordSeq': '-1',
    'FirstRecordChecksum': 'UNK',
    'LastRecordChecksum': 'UNK',
    'PeriodStartTime': '1900-01-01',
    'PeriodStartTimeUTC': '1900-01-01',
    'PeriodEndTime': '1900-01-01',
    'PeriodEndTimeUTC': '1900-01-01',
    'RecordCount': '-1',
    'ETLExecutionId': '-1',
    'CreateBy': 'ffortunato',
    'IssueId': '-1',
    'Verbose': '0'
}
"""

"""
MyDataHub.issue_list[MyDataHub.get_publication_idx()]['DataLakePath'] = 's3://' + dl_bucket + s3_key
MyDataHub.issue_list[MyDataHub.get_publication_idx()]['SrcIssueName'] = file
MyDataHub.issue_list[MyDataHub.get_publication_idx()]['IssueName'] = file
MyDataHub.issue_list[MyDataHub.get_publication_idx()]['PeriodStartTime'] = file[18:22] + '/' + file[22:24] + '/' + file[24:26]
MyDataHub.issue_list[MyDataHub.get_publication_idx()]['PeriodEndTime'] = file[18:22] + '/' + file[22:24] + '/' + file[24:26]
"""
"""
MyDataHub.issue_list[pubn_id]['DataLakePath'] = 's3://' + dl_bucket + s3_key
MyDataHub.issue_list[pubn_id]['SrcIssueName'] = file
MyDataHub.issue_list[pubn_id]['IssueName'] = file
MyDataHub.issue_list[pubn_id]['PeriodStartTime'] = file[18:22] + '/' + file[22:24] + '/' + file[24:26]
MyDataHub.issue_list[pubn_id]['PeriodEndTime'] = file[18:22] + '/' + file[22:24] + '/' + file[24:26]
"""

"""
def del_publication_code(self):
    """
# We are going to set the publication code and get the index from the publication list too.
# :param publication_code:
# :return:
"""
del self.publication_code

publication_code = property(get_publication_code, set_publication_code, del_publication_code)
"""


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
