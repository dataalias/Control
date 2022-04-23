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
    get_publication_list: Returns a list of publications associated with the provided publisher_code
    get_publication_code: Returns the active publication code for the data hub object.
    set_publication_code: Allows the user to set / change the active publication Code.
    get_publication_idx: Returns the active publication index  for the data hub object.
    set_publication_idx: N/A set publication code now sets the index as well.
    insert_new_issue: Takes stored issue information and inserts it to the db. Returns IssueId
    update_issue: Takes stored issue information and updates it to the db based on stored IssueId
    is_issue_absent: Returns a true or false based on the file name's presence in data hub.
    
    T0D0: write_issue -- combine functionality of insert and update issue functions.
    T0D0: make get_publication_list part ofd the class __init__.

### Properties:

    publication_list = () :: Tuple of publications associated with the publisher.
    issue_list = [] :: An array of issues derived from the publication list. This is a list of the issues that we are
        trying to load. The first position in the list is a dictionary that points to the other dictionaries in the
        list that represent issues. Subsequent dictionaries in this list represent individual issues.
        The [0] position of the array equates later dictionaries in this array with their publication_code.
    publication_idx = int :: Position of the active publication_code for the object.
    publication_code = str :: Currently active publication code for the object.

## delogging
Several small helper functions for formatting logs. Right now its simple prints but it will extend to write to 
CloudWatch.
## ftp
The functions make use of paramiko to initiate sftp transfers.
## helper
The functions aggregate base functions into composite calls. For instance combining get_secret with connect_to_ftp. 
The new function get_ftp_connection_from_secret takes a secret as an input and returns a ftp connection to minimise
lines of code in the users call.
## S3
Series of functions to interact with AWS s3 buckets.
## secrets
Series of functions to interact with AWS Secrets.
## test
Future space for unit testing these functions.


### Change Log:
| User       | Date       | Comment                                                                     |
|------------|------------|-----------------------------------------------------------------------------|
| ffortunato | 04/22/2022 | Initial Iteration. Moved most class and function definitions to the readme. |

[Github-flavored Markdown](https://guides.github.com/features/mastering-markdown/)
