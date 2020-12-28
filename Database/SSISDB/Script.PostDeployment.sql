/******************************************************************************
File:		ScriptPostDeployment.sql
Name:		SIS-CVue
Purpose:	Setting up the environment variables for the SISPackage
Author:		Jacquie Merrill	
Date:		20200423	
******************************************************************************/
USE [SSISDB]

DECLARE @hostname VARCHAR(1000) = 'Unknown';
DECLARE @SrcFilePath VARCHAR(1000);


SELECT @hostname = @@SERVERNAME;


PRINT 'Installing On: ' + @hostname;

DECLARE @vfolder_name NVARCHAR(15) = N'ETLFolder'
	,@venvironment_name NVARCHAR(128) = @@SERVERNAME
	,@vproject_name NVARCHAR(25) = N'Control'
	,@FALSE BIT = CAST(0 AS BIT)
	,@reference_id BIGINT
	,@AzureFunctionUrl  NVARCHAR(100)    = CASE WHEN @@SERVERNAME IN ('DME1EDLSQL01', 'DEDTEDLSQL01') THEN 'https://execdatafactorypipeline.azurewebsites.net/api/ExecutePipeline'
											  WHEN @@SERVERNAME IN ('QME1EDLSQL01', 'QME3EDLSQL01') THEN 'https://execdatafactorypipeline.azurewebsites.net/api/ExecutePipeline'
											  WHEN @@SERVERNAME = 'PRODEDLSQL01' THEN 'https://execdatafactorypipeline.azurewebsites.net/api/ExecutePipeline'
											  ELSE 'https://execdatafactorypipeline.azurewebsites.net/api/ExecutePipeline'
										 END
	,@subscriptionId  NVARCHAR(100)    = '3641d697-5ff2-4b72-9be2-c9ecbebd47c5'
	,@resourceGroup NVARCHAR(100)    = CASE WHEN @@SERVERNAME IN ('DME1EDLSQL01', 'DEDTEDLSQL01') THEN 'zvo-sbx-01-ds-dev-rg'
											  WHEN @@SERVERNAME IN ('QME1EDLSQL01', 'QME3EDLSQL01') THEN 'zvo-sbx-01-ds-qa-rg'
											  WHEN @@SERVERNAME = 'PRODEDLSQL01' THEN 'zvo-sbx-01-ds-rg'
											  ELSE 'zvo-sbx-01-ds-dev-rg'
										 END;

Declare @ERefID INT				= (SELECT TOP 1 reference_id
								  FROM SSISDB.catalog.environment_references R
								  INNER JOIN SSISDB.catalog.projects P
									  ON R.project_id = P.project_id
								  WHERE P.name = @vproject_name)	-- Project Name


IF (SELECT name FROM internal.environment_variables WHERE name = 'env_AzureFunctionUrl') IS NULL
EXECUTE SSISDB.[catalog].[create_environment_variable]
         @folder_name       = @vfolder_name
       , @environment_name  = @venvironment_name
       , @variable_name     = N'env_AzureFunctionUrl'
       , @data_type         = N'String'
       , @sensitive         = 0
       , @value             = @AzureFunctionUrl

IF (SELECT name FROM internal.environment_variables WHERE name = 'env_subscriptionId') IS NULL
EXECUTE SSISDB.[catalog].[create_environment_variable]
         @folder_name       = @vfolder_name
       , @environment_name  = @venvironment_name
       , @variable_name     = N'env_subscriptionId'
       , @data_type         = N'String'
       , @sensitive         = 0
       , @value             = @subscriptionId

IF (SELECT name FROM internal.environment_variables WHERE name = 'env_resourceGroup') IS NULL
EXECUTE SSISDB.[catalog].[create_environment_variable]
         @folder_name       = @vfolder_name
       , @environment_name  = @venvironment_name
       , @variable_name     = N'env_resourceGroup'
       , @data_type         = N'String'
       , @sensitive         = 0
       , @value             = @resourceGroup


IF (SELECT reference_id FROM internal.environment_references WHERE reference_id = @ERefID) IS NULL
EXEC [SSISDB].[catalog].[create_environment_reference] @environment_name = @venvironment_name
	,@reference_id = @reference_id OUTPUT
	,@project_name = @vproject_name
	,@folder_name = @vfolder_name
	,@reference_type = A
	,@environment_folder_name = @vfolder_name;

EXEC [SSISDB].[catalog].[set_object_parameter_value] @object_type = 20
	,@parameter_name = N'prj_server_EDL01'
	,@object_name = @vproject_name
	,@folder_name = @vfolder_name
	,@project_name = @vproject_name
	,@value_type = R
	,@parameter_value = N'env_server_EDL01';

EXEC [SSISDB].[catalog].[set_object_parameter_value] @object_type = 20
	,@parameter_name = N'prj_From_ErrorMail'
	,@object_name = @vproject_name
	,@folder_name = @vfolder_name
	,@project_name = @vproject_name
	,@value_type = R
	,@parameter_value = N'env_From_ErrorMail';

EXEC [SSISDB].[catalog].[set_object_parameter_value] @object_type = 20
	,@parameter_name = N'prj_To_ErrorMail'
	,@object_name = @vproject_name
	,@folder_name = @vfolder_name
	,@project_name = @vproject_name
	,@value_type = R
	,@parameter_value = N'env_To_ErrorMail';

EXEC [SSISDB].[catalog].[set_object_parameter_value] @object_type = 20
	,@parameter_name = N'prj_conn_SMTP'
	,@object_name = @vproject_name
	,@folder_name = @vfolder_name
	,@project_name = @vproject_name
	,@value_type = R
	,@parameter_value = N'env_conn_SMTP';

EXEC [SSISDB].[catalog].[set_object_parameter_value] @object_type = 20
	,@parameter_name = N'prj_server_c2000'
	,@object_name = @vproject_name
	,@folder_name = @vfolder_name
	,@project_name = @vproject_name
	,@value_type = R
	,@parameter_value = N'env_server_c2000';


	EXEC [SSISDB].[catalog].[set_object_parameter_value] @object_type = 20
	,@parameter_name = N'prj_AzureFunctionURL'
	,@object_name = @vproject_name
	,@folder_name = @vfolder_name
	,@project_name = @vproject_name
	,@value_type = R
	,@parameter_value = N'env_AzureFunctionUrl';


	EXEC [SSISDB].[catalog].[set_object_parameter_value] @object_type = 20
	,@parameter_name = N'prj_subscriptionId'
	,@object_name = @vproject_name
	,@folder_name = @vfolder_name
	,@project_name = @vproject_name
	,@value_type = R
	,@parameter_value = N'env_subscriptionId';


	EXEC [SSISDB].[catalog].[set_object_parameter_value] @object_type = 20
	,@parameter_name = N'prj_resourceGroup'
	,@object_name = @vproject_name
	,@folder_name = @vfolder_name
	,@project_name = @vproject_name
	,@value_type = R
	,@parameter_value = N'env_resourceGroup';


