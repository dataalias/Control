from pathlib import Path

root = Path(r'c:\Users\DataA\source\repos\Control')
files_replacements = {
    root / 'AWS' / 'infra' / 'variables.tf': [
        ('arn:aws:events:us-east-1:582033825934:event-bus/default', 'arn:aws:events:us-east-1:<MY_ACCOUNT_ID>:event-bus/default'),
        ('transfer.ascentfunding.com', '<MY_FTP_DOMAIN>'),
    ],
    root / 'AWS' / 'pipeline' / 'buildspec_deploy.yml': [
        ('s3://$ENV-ascent-de-assets/deDataHub/dist/', 's3://$ENV-<MY_ORG>-de-assets/deDataHub/dist/'),
    ],
    root / 'AWS' / 'infra' / 'accounts' / 'prod' / 'terraform.tfvars': [
        ('account_id                  = "000000000000"', 'account_id                  = "<MY_ACCOUNT_ID>"'),
        ('datalake_bucket             = "datalake"', 'datalake_bucket             = "<MY_DATALAKE_BUCKET>"'),
        ('artifact_bucket             = "prod-de-assets"', 'artifact_bucket             = "<MY_ARTIFACT_BUCKET>"'),
        ('artifact_encryption_key     = "arn:aws:kms:us-east-1:000000000000:key/51981c0d-892e-4148-bf8f-3d52d6b09bae"', 'artifact_encryption_key     = "arn:aws:kms:us-east-1:<MY_ACCOUNT_ID>:key/<MY_KMS_KEY_ID>"'),
        ('dev_account_id              = "000000000000"', 'dev_account_id              = "<MY_ACCOUNT_ID>"'),
        ('code_commit_access_role_arn = "arn:aws:iam::00000000000000:role/ProdAcctCodePipelineCodeCommitRole"', 'code_commit_access_role_arn = "arn:aws:iam::<MY_ACCOUNT_ID>:role/ProdAcctCodePipelineCodeCommitRole"'),
        ('source_bucket_name          = "prod-ascent-datalake"', 'source_bucket_name          = "<MY_SOURCE_BUCKET_NAME>"'),
        ('mssql_layer                 = "arn:aws:lambda:us-east-1:000000000000:layer:pymssql39:1"', 'mssql_layer                 = "arn:aws:lambda:us-east-1:<MY_ACCOUNT_ID>:layer:pymssql39:1"'),
        ('boto_layer                  = "arn:aws:lambda:us-east-1:000000000000:layer:boto39:1"', 'boto_layer                  = "arn:aws:lambda:us-east-1:<MY_ACCOUNT_ID>:layer:boto39:1"'),
        ('datahub_layer               = "arn:aws:lambda:us-east-1:000000000000:layer:Python39-deDataHub:latest"', 'datahub_layer               = "arn:aws:lambda:us-east-1:<MY_ACCOUNT_ID>:layer:Python39-deDataHub:latest"'),
        ('subnet_ids = ["subnet-000000000"]', 'subnet_ids = ["<MY_SUBNET_ID>"]'),
        ('security_group_ids = ["sg-000000000","sg-000000000","sg-000000000"]', 'security_group_ids = ["<MY_SECURITY_GROUP_ID>","<MY_SECURITY_GROUP_ID>","<MY_SECURITY_GROUP_ID>"]'),
    ],
    root / 'AWS' / 'infra' / 'accounts' / 'dev' / 'terraform.tfvars': [
        ('account_id              = "000000000000"', 'account_id              = "<MY_ACCOUNT_ID>"'),
        ('datalake_bucket         = "datalake"', 'datalake_bucket         = "<MY_DATALAKE_BUCKET>"'),
        ('source_bucket_name      = "dev-datalake"', 'source_bucket_name      = "<MY_SOURCE_BUCKET_NAME>"'),
        ('artifact_bucket         = "dev-de-assets"', 'artifact_bucket         = "<MY_ARTIFACT_BUCKET>"'),
        ('artifact_encryption_key = "arn:aws:kms:us-east-1:000000000000:key/75367033-46ff-4c29-91b2-0df67b73637d"', 'artifact_encryption_key = "arn:aws:kms:us-east-1:<MY_ACCOUNT_ID>:key/<MY_KMS_KEY_ID>"'),
        ('mssql_layer             = "arn:aws:lambda:us-east-1:000000000000:layer:pymssql39:1"', 'mssql_layer             = "arn:aws:lambda:us-east-1:<MY_ACCOUNT_ID>:layer:pymssql39:1"'),
        ('boto_layer              = "arn:aws:lambda:us-east-1:000000000000:layer:boto3-layer:1"', 'boto_layer              = "arn:aws:lambda:us-east-1:<MY_ACCOUNT_ID>:layer:boto3-layer:1"'),
        ('datahub_layer           = "arn:aws:lambda:us-east-1:000000000000:layer:Python39-deDataHub:latest"', 'datahub_layer           = "arn:aws:lambda:us-east-1:<MY_ACCOUNT_ID>:layer:Python39-deDataHub:latest"'),
        ('subnet_ids = ["subnet-00000000"]', 'subnet_ids = ["<MY_SUBNET_ID>"]'),
        ('security_group_ids = ["sg-000000000","sg-000000000","sg-00000000"]', 'security_group_ids = ["<MY_SECURITY_GROUP_ID>","<MY_SECURITY_GROUP_ID>","<MY_SECURITY_GROUP_ID>"]'),
    ],
    root / 'AWS' / 'infra' / 'accounts' / 'stg' / 'terraform.tfvars': [
        ('account_id              = "000000000000"', 'account_id              = "<MY_ACCOUNT_ID>"'),
        ('datalake_bucket         = "datalake"', 'datalake_bucket         = "<MY_DATALAKE_BUCKET>"'),
        ('artifact_bucket         = "dev-de-assets"', 'artifact_bucket         = "<MY_ARTIFACT_BUCKET>"'),
        ('artifact_encryption_key = "arn:aws:kms:us-east-1:000000000000:key/75367033-46ff-4c29-91b2-0df67b73637d"', 'artifact_encryption_key = "arn:aws:kms:us-east-1:<MY_ACCOUNT_ID>:key/<MY_KMS_KEY_ID>"'),
        ('pandas_layer            = "arn:aws:lambda:us-east-1:000000000000:layer:pandas-layer:1"', 'pandas_layer            = "arn:aws:lambda:us-east-1:<MY_ACCOUNT_ID>:layer:pandas-layer:1"'),
        ('mssql_layer             = "arn:aws:lambda:us-east-1:000000000000:layer:pymssql-layer:4"', 'mssql_layer             = "arn:aws:lambda:us-east-1:<MY_ACCOUNT_ID>:layer:pymssql-layer:4"'),
        ('boto_layer              = "arn:aws:lambda:us-east-1:000000000000:layer:boto3-layer:1"', 'boto_layer              = "arn:aws:lambda:us-east-1:<MY_ACCOUNT_ID>:layer:boto3-layer:1"'),
        ('deutils_layer           = "arn:aws:lambda:us-east-1:000000000000:layer:deUtils3-2_py3-10_arm64:1"', 'deutils_layer           = "arn:aws:lambda:us-east-1:<MY_ACCOUNT_ID>:layer:deUtils3-2_py3-10_arm64:1"'),
        ('subnet_ids = ["subnet-000000000"]', 'subnet_ids = ["<MY_SUBNET_ID>"]'),
        ('security_group_ids = ["sg-000000000","sg-000000000","sg-000000000"]', 'security_group_ids = ["<MY_SECURITY_GROUP_ID>","<MY_SECURITY_GROUP_ID>","<MY_SECURITY_GROUP_ID>"]'),
    ],
    root / 'README.md': [
        ('https://github.com/Ascent-Funding/deControl', 'https://github.com/<MY_ORGANIZATION>/deControl'),
        ('Ascent-Funding', '<MY_ORGANIZATION>'),
    ],
    root / 'AWS' / 'DataHubS3Trigger' / 'app.py': [
        ("sys.path.insert(1,'D:\\Users\\MY_USERNAME\\source\\AscentRepo\\deDataHub\\src_dh_layer\\python')", "sys.path.insert(1, '<MY_LOCAL_REPO_PATH>/deDataHub/src_dh_layer/python')"),
    ],
    root / 'AWS' / 'PostingGroupTrigger' / 'app.py': [
        ("sys.path.insert(1,'D:\\Users\\MY_USERNAME\\source\\AscentRepo\\deDataHub\\src_dh_layer\\python')", "sys.path.insert(1, '<MY_LOCAL_REPO_PATH>/deDataHub/src_dh_layer/python')"),
    ],
    root / 'AWS' / 'DataHubScheduler' / 'app.py': [
        ("sys.path.insert(1,'D:\\Users\\MY_USERNAME\\source\\AscentRepo\\deDataHub\\src_dh_layer\\python')", "sys.path.insert(1, '<MY_LOCAL_REPO_PATH>/deDataHub/src_dh_layer/python')"),
    ],
    root / 'deUtils' / 'main.py': [
        ("sys.path.insert(1,'D:\\Users\\MY_USERNAME\\source\\AscentRepo\\deDataHub\\src_dh_layer\\python')", "sys.path.insert(1, '<MY_LOCAL_REPO_PATH>/deDataHub/src_dh_layer/python')"),
    ],
    root / 'deUtils' / 'python' / 'setup.py': [
        ('url=\'https://git-codecommit.us-east-1.amazonaws.com/v1/repos/deDataHub\'', 'url=\'<MY_REPOSITORY_URL>\''),
    ],
    root / 'src_dh_layer-bak' / 'setup.py': [
        ('url=\'https://git-codecommit.us-east-1.amazonaws.com/v1/repos/deDataHub\'', 'url=\'<MY_REPOSITORY_URL>\''),
    ],
    root / 'AzureFunctions' / 'ExecutePipeline' / 'Properties' / 'PublishProfiles' / 'ExecutePipeline20200807204635 - Zip Deploy.pubxml': [
        ('https://executepipeline20200807204635.azurewebsites.net', '<MY_AZURE_FUNCTION_APP_URL>'),
        ('/subscriptions/3641d697-5ff2-4b72-9be2-c9ecbebd47c5/resourcegroups/zvo-sbx-01-ds-qa-rg/providers/Microsoft.Web/sites/ExecutePipeline20200807204635', '<MY_RESOURCE_ID>'),
        ('https://executepipeline20200807204635.scm.azurewebsites.net/', '<MY_PUBLISH_URL>'),
        ('<UserName>$ExecutePipeline20200807204635</UserName>', '<UserName><MY_PUBLISH_USER></UserName>'),
    ],
    root / 'Database' / 'SSISDB' / 'Script.PostDeployment.sql': [
        ("'https://execdatafactorypipeline.azurewebsites.net/api/ExecutePipeline'", "'<MY_AZURE_FUNCTION_URL>'"),
        ('3641d697-5ff2-4b72-9be2-c9ecbebd47c5', '<MY_SUBSCRIPTION_ID>'),
        ('zvo-sbx-01-ds-dev-rg', '<MY_RESOURCE_GROUP_DEV>'),
        ('zvo-sbx-01-ds-qa-rg', '<MY_RESOURCE_GROUP_QA>'),
        ('zvo-sbx-01-ds-rg', '<MY_RESOURCE_GROUP_PROD>'),
        ('DME1EDLSQL01', '<MY_SQL_SERVER>'),
        ('MY_SQL_SERVER', '<MY_SQL_SERVER>'),
        ('QME1EDLSQL01', '<MY_SQL_SERVER>'),
        ('QME3EDLSQL01', '<MY_SQL_SERVER>'),
        ('PRODEDLSQL01', '<MY_SQL_SERVER>'),
    ],
    root / 'Database' / 'Control' / 'Stored Procedures' / 'pg.usp_ExecuteDataFactory.sql': [
        ("'https://execdatafactorypipeline-dev.azurewebsites.net/api/ExecutePipeline?'", "'<MY_AZURE_FUNCTION_URL_DEV>?'"),
        ("'https://execdatafactorypipeline-qa.azurewebsites.net/api/ExecutePipeline?'", "'<MY_AZURE_FUNCTION_URL_QA>?'"),
        ("'https://execdatafactorypipeline.azurewebsites.net/api/ExecutePipeline?'", "'<MY_AZURE_FUNCTION_URL_PROD>?'"),
    ],
    root / 'Database' / 'Control' / 'Stored Procedures' / 'ctl.usp_UpdatePublisherFTP.sql': [
        ("'MY_FTP_HOST'", "'<MY_FTP_HOST>'"),
    ],
    root / 'Database' / 'Control' / 'Stored Procedures' / 'ctl.usp_InsertNewContact.sql': [
        ("'MY_NOTIFICATION_EMAIL'", "'<MY_NOTIFICATION_EMAIL>'"),
    ],
}
additional_replacements = {
    root / 'Powershell-bak' / 'dmutils' / 'WinSCP' / 'WinSCP.psd1': [
        ("CompanyName = 'MY_ORGANIZATION'", "CompanyName = '<MY_ORGANIZATION>'"),
    ],
    root / 'Powershell-bak' / 'dmutils' / 'WinSCP' / 'WinSCP.ps1': [
        ('MY_FILE_TRANSFER_HOST', '<MY_FILE_TRANSFER_HOST>'),
        ('MY_EMAIL_ADDRESS', '<MY_EMAIL_ADDRESS>'),
        ('MY_FTP_HOST', '<MY_FILE_TRANSFER_HOST>'),
    ],
    root / 'Powershell-bak' / 'dmutils' / 'WinSCP' / 'ftpPut.ps1': [
        ('MY_HOST_NAME', '<MY_HOST_NAME>'),
        ('\\MY_FILE_SHARE_SERVER\\BI_Admin_dev\\DME3\\FileShare\\ChatTraffic\\outbound"', '\\<MY_FILE_SHARE_SERVER>\\BI_Admin_dev\\DME3\\FileShare\\ChatTraffic\\outbound"'),
        ('\\MY_FILE_SHARE_SERVER\\powershellrepo\\DM\\DME3\\DataHub\\logs\\ftplog.log"', '\\<MY_FILE_SHARE_SERVER>\\powershellrepo\\DM\\DME3\\DataHub\\logs\\ftplog.log"'),
    ],
    root / 'Powershell-bak' / 'dmutils' / 'WinSCP' / 'ftpListCheckGet.ps1': [
        ('MY_SFTP_HOST', '<MY_SFTP_HOST>'),
        ('MY_FILE_TRANSFER_HOST', '<MY_FILE_TRANSFER_HOST>'),
        ('MY_EMAIL_ADDRESS', '<MY_EMAIL_ADDRESS>'),
        ('\\\\MY_FILE_SHARE_SERVER\\powershellrepo\\DM\\QME3\\DataHub\\keys\\vendor_01_private_key.ppk', '\\\\<MY_FILE_SHARE_SERVER>\\powershellrepo\\DM\\QME3\\DataHub\\keys\\vendor_01_private_key.ppk'),
    ],
    root / 'Powershell-bak' / 'dmutils' / 'Send-eMail.ps1': [
        ('MY_SMTP_SERVER', '<MY_SMTP_SERVER>'),
        ('MY_EMAIL_ADDRESS', '<MY_EMAIL_ADDRESS>'),
        ('MY_NOTIFICATION_EMAIL', '<MY_NOTIFICATION_EMAIL>'),
    ],
    root / 'Powershell-bak' / 'dmutils' / 'Invoke-ErrorHandler.ps1': [
        ('MY_SMTP_SERVER', '<MY_SMTP_SERVER>'),
        ('MY_EMAIL_ADDRESS', '<MY_EMAIL_ADDRESS>'),
        ('MY_NOTIFICATION_EMAIL', '<MY_NOTIFICATION_EMAIL>'),
    ],
    root / 'Powershell-bak' / 'dmutils' / 'Put-DataFeed.ps1': [
        ('MY_NOTIFICATION_EMAIL', '<MY_NOTIFICATION_EMAIL>'),
    ],
    root / 'Powershell-bak' / 'dmutils' / 'RestAPI' / 'Get-QualtricsExport.ps1': [
        ('MY_QUALTRICS_API_URL', '<MY_QUALTRICS_API_URL>'),
    ],
    root / 'Powershell-bak' / 'dmutils' / 'FileShare' / 'Invoke-FileSharePut.ps1': [
        ('\\MY_FILE_SHARE_SERVER\\BI_Admin_dev\\FileShare\\OIE\\outbound"', '\\<MY_FILE_SHARE_SERVER>\\BI_Admin_dev\\FileShare\\OIE\\outbound"'),
        ('\\MY_FILE_SHARE_SERVER\\BI_Admin_dev\\FileShare\\OIE\\inbound"', '\\<MY_FILE_SHARE_SERVER>\\BI_Admin_dev\\FileShare\\OIE\\inbound"'),
    ],
    root / 'Powershell-bak' / 'dmutils' / 'FileShare' / 'FileShareListCheckGet.ps1': [
        ('MY_ISSUE_TRACKER_URL', '<MY_ISSUE_TRACKER_URL>'),
        ('\\MY_FILE_SHARE_SERVER\\BI_Admin_dev\\FileShare\\OIE\\outbound"', '\\<MY_FILE_SHARE_SERVER>\\BI_Admin_dev\\FileShare\\OIE\\outbound"'),
        ('\\MY_FILE_SHARE_SERVER\\BI_Admin_dev\\FileShare\\OIE\\inbound"', '\\<MY_FILE_SHARE_SERVER>\\BI_Admin_dev\\FileShare\\OIE\\inbound"'),
    ],
    root / 'Powershell-bak' / 'dmutils' / 'ctl' / 'Invoke-StagingPackage.ps1': [
        ('MY_SQL_SERVER', '<MY_SQL_SERVER>'),
    ],
    root / 'Powershell-bak' / 'dmutils' / 'ctl' / 'New-Issue.ps1': [
        ("$dbServer = 'MY_SQL_SERVER'", "$dbServer = '<MY_SQL_SERVER>'"),
        ("-dbsn 'MY_SQL_SERVER'", "-dbsn '<MY_SQL_SERVER>'"),
        ("-usr 'MY_USERNAME'", "-usr '<MY_USERNAME>'"),
    ],
    root / 'Powershell-bak' / 'dmutils' / 'ctl' / 'Get-IssueNamesToRetrieve.ps1': [
        ("#[string]$dbServer = 'MY_SQL_SERVER'", "#[string]$dbServer = '<MY_SQL_SERVER>'"),
    ],
    root / 'Powershell-bak' / 'dmutils' / 'ctl' / 'Edit-Issue.ps1': [
        (":> Edit-Issue  -dbsn 'MY_SQL_SERVER' -iss 1 -stat 'IF'", ":> Edit-Issue  -dbsn '<MY_SQL_SERVER>' -iss 1 -stat 'IF'"),
    ],
    root / 'Powershell-bak' / 'dmutils' / 'ctl' / 'Add-ControlFile.ps1': [
        ('\\MY_FILE_SHARE_SERVER\\bi_admin_qa\\FileShare\\Vendor_01\\inbound', '\\<MY_FILE_SHARE_SERVER>\\bi_admin_qa\\FileShare\\Vendor_01\\inbound'),
    ],
    root / 'Powershell-bak' / 'DataHub' / 'Get-Canvas.ps1': [
        ('\\MY_FILE_SHARE_SERVER\\powershellrepo\\DM\\DME1\\DataHub\\Get-Canvas.ps1', '\\<MY_FILE_SHARE_SERVER>\\powershellrepo\\DM\\DME1\\DataHub\\Get-Canvas.ps1'),
        ('\\MY_FILE_SHARE_SERVER\\canvassync\\dev\\Canvas\\InstCode\\Inbound\\"', '\\<MY_FILE_SHARE_SERVER>\\canvassync\\dev\\Canvas\\InstCode\\Inbound\\"'),
        ('\\MY_FILE_SHARE_SERVER\\canvassync\\dev\\Canvas\\InstCode\\Inbound\\Archive\\"', '\\<MY_FILE_SHARE_SERVER>\\canvassync\\dev\\Canvas\\InstCode\\Inbound\\Archive\\"'),
    ],
    root / 'Powershell-bak' / 'DataHub' / 'DH1.2_InterfaceCode_ReleaseNotes.txt': [
        ('PRODEDLSQL01', '<MY_SQL_SERVER>'),
        ('MY_ISSUE_TRACKER_URL', '<MY_ISSUE_TRACKER_URL>'),
        ('MY_SERVICE_NOW_URL', '<MY_SERVICE_NOW_URL>'),
        ('MY_TFS_SERVER', '<MY_TFS_SERVER>'),
        ('\\MY_FILE_SHARE_SERVER\\powershellrepo\\DM\\QME\\dmutils', '\\<MY_FILE_SHARE_SERVER>\\powershellrepo\\DM\\QME\\dmutils'),
    ],
    root / 'Integration' / 'DataFactoryCall' / 'conn_OLEDB_MY_DB_DW.conmgr': [
        ('Data Source=MY_SQL_SERVER;Initial Catalog=MY_DB_DW;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;', 'Data Source=<MY_SQL_SERVER>;Initial Catalog=MY_DB_DW;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    ],
    root / 'Integration' / 'DataFactoryCall' / 'AzureFunction_pg_CallDataFactory.dtsx': [
        ('SmtpServer=MY_SMTP_SERVER;UseWindowsAuthentication=False;EnableSsl=False;', 'SmtpServer=<MY_SMTP_SERVER>;UseWindowsAuthentication=False;EnableSsl=False;'),
        ('SendMailTask:From="MY_NOTIFICATION_EMAIL"', 'SendMailTask:From="<MY_NOTIFICATION_EMAIL>"'),
    ],
    root / 'Integration' / 'DataFactoryCall' / 'Project.params': [
        ('SSIS:Name="Value">MY_SQL_SERVER</SSIS:Property>', 'SSIS:Name="Value"><MY_SQL_SERVER></SSIS:Property>'),
        ('SSIS:Name="Value">SmtpServer=MY_SMTP_SERVER;UseWindowsAuthentication=False;EnableSsl=False;</SSIS:Property>', 'SSIS:Name="Value">SmtpServer=<MY_SMTP_SERVER>;UseWindowsAuthentication=False;EnableSsl=False;</SSIS:Property>'),
        ('SSIS:Name="Value">MY_NOTIFICATION_EMAIL</SSIS:Property>', 'SSIS:Name="Value"><MY_NOTIFICATION_EMAIL></SSIS:Property>'),
        ('SSIS:Name="Value">http://execdatafactorypipeline.azurewebsites.net/api/ExecutePipeline</SSIS:Property>', 'SSIS:Name="Value"><MY_AZURE_FUNCTION_URL></SSIS:Property>'),
    ],
    root / 'Integration' / 'DataFactoryCall' / 'DataFactoryCall.dtproj': [
        ('Data Source=MY_SQL_SERVER;Initial Catalog=Control;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;', 'Data Source=<MY_SQL_SERVER>;Initial Catalog=Control;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
        ('Data Source=MY_SQL_SERVER;Initial Catalog=MY_DB_DW;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;', 'Data Source=<MY_SQL_SERVER>;Initial Catalog=MY_DB_DW;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
        ('SSIS:Property SSIS:Name="Value">SmtpServer=MY_SMTP_SERVER;UseWindowsAuthentication=False;EnableSsl=False;</SSIS:Property>', 'SSIS:Property SSIS:Name="Value">SmtpServer=<MY_SMTP_SERVER>;UseWindowsAuthentication=False;EnableSsl=False;</SSIS:Property>'),
        ('SSIS:Property SSIS:Name="Value">MY_SMTP_SERVER</SSIS:Property>', 'SSIS:Property SSIS:Name="Value"><MY_SMTP_SERVER></SSIS:Property>'),
        ('Data Source=MY_SQL_SERVER;Initial Catalog=MY_DB_Reporting;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;', 'Data Source=<MY_SQL_SERVER>;Initial Catalog=MY_DB_Reporting;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    ],
    root / 'Integration' / 'DataFactoryCall' / 'conn_OLEDB_MY_DB_Reporting.conmgr': [
        ('Data Source=MY_SQL_SERVER;Initial Catalog=MY_DB_Reporting;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;', 'Data Source=<MY_SQL_SERVER>;Initial Catalog=MY_DB_Reporting;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    ],
    root / 'Integration' / 'DataFactoryCall' / 'conn_OLEDB_MY_DB_STAGE.conmgr': [
        ('Data Source=MY_SQL_SERVER;Initial Catalog=Control;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;', 'Data Source=<MY_SQL_SERVER>;Initial Catalog=Control;Provider=SQLNCLI11.1;Integrated Security=SSPI;Auto Translate=False;'),
    ],
    root / 'Database' / 'Control' / 'Test' / 'tst_DataHubWithSSIS.sql': [
        ('\\MY_FILE_SHARE_SERVER\\Share', '\\<MY_FILE_SHARE_SERVER>\\Share'),
    ],
    root / 'Database' / 'Control' / 'Test' / 'tst_DataHubWithPython.sql': [
        ('\\MY_FILE_SHARE_SERVER\\Share', '\\<MY_FILE_SHARE_SERVER>\\Share'),
    ],
    root / 'Database' / 'Control' / 'Test' / 'tst_DataHubRetry.sql': [
        ('\\MY_FILE_SHARE_SERVER\\Share', '\\<MY_FILE_SHARE_SERVER>\\Share'),
    ],
    root / 'Database' / 'Control' / 'Test' / 'tst_DataHub.sql': [
        ('\\MY_FILE_SHARE_SERVER\\Share', '\\<MY_FILE_SHARE_SERVER>\\Share'),
    ],
    root / 'Database' / 'Control' / 'Test' / 'TestScript.sql': [
        ('\\MY_FILE_SHARE_SERVER\\Share', '\\<MY_FILE_SHARE_SERVER>\\Share'),
    ],
    root / 'Database' / 'Control' / 'Stored Procedures' / 'pg.usp_ExecuteSSISPackage.sql': [
        ("@pServerName\t\t\t\t= 'MY_SQL_SERVER'", "@pServerName\t\t\t\t= '<MY_SQL_SERVER>'"),
    ],
    root / 'Interface' / 'connections' / 'connX.php': [
        ('//$serverName = "MY_SQL_SERVER";', '//$serverName = "<MY_SQL_SERVER>";'),
    ],
}
files_replacements.update(additional_replacements)
for fpath, replacements in files_replacements.items():
    if not fpath.exists():
        print('MISSING', fpath)
        continue
    text = fpath.read_text(encoding='utf-8', errors='ignore')
    original = text
    for old, new in replacements:
        text = text.replace(old, new)
    if text != original:
        fpath.write_text(text, encoding='utf-8')
        print('Updated', fpath)
