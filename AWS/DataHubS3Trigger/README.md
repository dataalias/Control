MOVED TO MAIN PROJECT README.md

# deDataHub
## Overview
This AWS lambda function will insert or update issues in the database based on the request made.

## Functions

### DataHubS3Trigger
When a file falls on S3 bucket, this lambda function kicks off and checks for two possibilities.

1.  If the Lambda Function is schedule driven then, the issue already exist in database. So issue is fetched directly.
2.  If the Lambda Function is s3 driven then, the issue does not already exist in database. So issue is created.

### Modules used 
1.  boto3
2.  pymssql
3.  datahub.py 


### Change Log:
| User          | Date       | Comment                                                                     |
|---------------|------------|-----------------------------------------------------------------------------|
| schandramouly | 04/16/2023 | Initial Iteration.        |

[Github-flavored Markdown](https://guides.github.com/features/mastering-markdown/)
