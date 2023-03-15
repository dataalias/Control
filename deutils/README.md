# deUtils
## Overview
deUtils is intended to provide classes and functions that accelerate the development of python based ETL jobs normally
run from glue. Helper routines run the gamut of supporting ftp transfers, getting aws secrets and a DataHub class that
can help users select and insert data into datahub control objects persisted in a sql server database.

## Data Hub
The DataHub class allows python packages to interact with the datahub database.
### Class: DataHub

### Methods:
    __init__ :: Takes the provided secret key and creates a mssql database connection to the database
                that hosts the ctl and pg schema.
    connect :: Private, establishes the database connection.
    get_secret :: Private, looks up the secret data from AWS.
    
    get_publication_list: Provide one of the following values to pull associated publication data:
        Publisher Code: Pulls a list of all publication associated with the publisher code.
        Publication File Path :: returns a single Pulication Record associated with the file path.
        Issue Id :: returns a single Publication Reocrds associated with the issue id.
        If and IssueId or PublicationFilePath are passed all publication and issue data will be returned for the single publication.
    * get_publication_record: <Depricated Use get_publication_list>. Provide a file path and it will return the single publication associated path
    * get_issue_details: <Depricated Use get_publication_list>. Provide an IssueId and the fruntion returns its details to the DataHub class properties.    
    
    get_publication_code: Returns the active publication code for the data hub object.
    set_publication_code: Allows the user to set / change the active publication Code.
    get_publication_idx: Returns the active publication index  for the data hub object.
    set_publication_idx: N/A set publication code now sets the index as well.
    insert_new_issue: Takes stored issue information and inserts it to the db. Returns IssueId
    update_issue: Takes stored issue information and updates it to the db based on stored IssueId
    is_issue_absent: Returns a true or false based on the file name's presence in data hub.
    get_issue_id: Gets the IssueId of the current publication -1 if the issue hasn't been inserted yet.
    *set_issue_values
    NotifySubscriberOfDistribution: Requires IssueId and kicks off down stream posting groups if all dependencies
        are met.

    T0D0: write_issue -- combine functionality of insert and update issue functions.
    T0D0: make get_publication_list part ofd the class __init__.
    TODO: make issue Id a property for the current publications issue id.

### Properties:

    publication_list = () :: Tuple of publications associated with the publisher.
    issue_list = [] :: An array of issues derived from the publication list. This is a list of the issues that we are
        trying to load. The first position in the list is a dictionary that points to the other dictionaries in the
        list that represent issues. Subsequent dictionaries in this list represent individual issues.
        The [0] position of the array equates later dictionaries in this array with their publication_code.
    *PublicationDictionary
    publication_idx = int :: Position of the active publication_code for the object.
    publication_code = str :: Currently active publication code for the object.

### An Example

    # Get the information needed to get the publication list. Puvlication Code and Next Execution Date
    pub_list_parms = {}
    pub_list_parms['PublisherCode'] = 'MyPublisherCode' # from ctl.Publication
    pub_list_parms['CurrentDate'] = '2099-Dec-31 23:59:59'  # datetime.today().strftime('%Y-%b-%d %H:%M:%S')
    
    # Create new object pass the secret key with the database credentials to log in.
    MyDataHub = DataHub('glue/database/adw')
    
    # Go get the publication list passing the parameters from above.
    MyDataHub.get_publication_list(pub_list_parms)
    
    # If several poublications are returned set the data hub object to deal with the publication you are currently interested in.
    MyDataHub.set_publication_code('8x8CRZ')
    
    # Determine if the file has already been processed. True if the file is absent from datahub.
    process = MyDataHub.is_issue_absent(file)
    
    # update Issue values in memory.
    issue_updates['DataLakePath'] = 's3://' + dl_bucket + s3_key
    issue_updates['SrcIssueName'] = file
    issue_updates['IssueName'] = file
    
    # Update the value stored in the class.
    MyDataHub.set_issue_val(issue_updates)
    
    # Write the issue with current in memory values to the database:
    MyDataHub.insert_new_issue()
    
    DO YOUR WORK HERE
    AND UPDATE INFOMRATION AS MUCH AS YOU WANT
    
    # Update values for an issue already written to the database.
    issue_updates['StatusCode'] = 'IL'
    MyDataHub.update_issue(issue_updates)

    # If you issue Failed ...
    issue_updates['StatusCode'] = 'IF'
    MyDataHub.update_issue(issue_updates)

## delogging
Several small helper functions for formatting logs. Right now its simple prints but it will extend to write to 
CloudWatch.
## ftp
The functions make use of paramiko to initiate sftp transfers.
## helper
The functions aggregate base functions into composite calls. For instance combining get_secret with connect_to_ftp. 
The new function get_ftp_connection_from_secret takes a secret as an input and returns a ftp connection to minimise
lines of code in the users call.
### deUtils
Normally when we make a request of AWS secrets it is to get credentials for connecting to a service. 
Two helper functions:

    get_db_connection_from_secret(secret_name)
    get_ftp_connection_from_secret(secret_name)
    secret_name: The string provided to AWS secrets that corresponds to the credentials we want to access.

Pass an aws secret ket to the function and it will return the specified connection.
### ftps3xfer.py
Standard parimiko libraries that support sftp transfers can be very slow. For a pipe that supports 5MBps
a transfer may reach only 250 KBps transfer speeds for large files. The functions in this package increase
throughput by transferring files in chunks and performing appropriate read ahead. Using these functions
allows the users to better utilize the network's bandwidth.

`def transfer_file_from_ftp_to_s3(s3_conn, ftp_conn, file_name, bucket_name, s3_key_val, chunk_size):`

    s3_conn: boto3 connection to s3
    ftp_conn: ftp connection to the file we want to transfer
    file_name: name of the file on the ftp site to transfer
    bucket_name: s3 bucket name where we will store the data
    s3_key_val: fully qualified key (directory and file name. e.g. Raw/FileType/YYYY/MM/DD/myfile.txt) 
    chunk_size: Size of the chunck you will be transferring.

When the function concludes the file should have transferred from fp site to s3 bucket/key.

## S3
Series of functions to interact with AWS s3 buckets.
## secrets
Series of functions to interact with AWS Secrets.
## test
Future space for unit testing these functions.

# Dependencies
pymssql
parimiko
pandas
boto3
io
math
time
datetime

### Change Log:
| User       | Date       | Comment                                                                     |
|------------|------------|-----------------------------------------------------------------------------|
| ffortunato | 04/22/2022 | Initial Iteration. Moved most class and function definitions to the readme. |
| ffortunato | 04/25/2022 | Adding additional details for several functions.                            |
| ffortunato | 08/11/2022 | Adding additional details for several functions. Unittest is now added.     |

[Github-flavored Markdown](https://guides.github.com/features/mastering-markdown/)
