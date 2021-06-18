CREATE PROCEDURE [pg].[usp_ExecuteDataFactory] (	
	 @pDataFactoryName					varchar(255)	= 'Unknown'
	,@pDataFactoryPipeline				varchar(255)	= 'Unknown'
	,@pAllowMultipleInstances			bit				= 0
	,@pExecuteProcessStatus				varchar(20)		output
	,@pETLExecutionId					int				= -1
	,@pPathId							int				= -1
	,@pVerbose							bit				= 0)
AS
/*****************************************************************************
File:		pg.usp_ExecuteDataFactory.sql
Name:		pg.usp_ExecuteDataFactory
Purpose:	Trigger the Data Factory pipelines through SQL server
			This process can only be triggered individually at this point.

Example:	DECLARE @DataFactoryStatus VARCHAR(200)
			exec ctl.usp_ExecuteDataFactory @pDataFactoryName = 'zvo-sbx-01-ds-dev-ContactCenter-df',
											@pDataFactoryPipeline = 'ADFContactCenterStagingLoad',
											@pStatus = @DataFactoryStatus OUTPUT
			select @DataFactoryStatus

		,@pExecuteProcessStatus	'IAR' -- Instance already running.
								'INR' -- Instance not running.
								'ISS' -- Instance start suceeded.
								'ISF' -- Instance start failed.

Parameters:    
Called by:	
Calls:          
Errors:		
Author:		Omkar Chowkwale
Date:		20200221
*******************************************************************************
							CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	--------------------------------
20200221	Omkar Chowkwale	Initial Iteration
20201118	ffortunato		cleaning up warnings.
20210212	ffortunato		moving to pg
20210212	ffortunato		PARAMETER LIST ... come on omkar!


******************************************************************************/

-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------
DECLARE	 @Rows					int				= 0
        ,@ErrNum				int				= -1
		,@ErrMsg				nvarchar(2048)	= 'N/A'
		,@ParametersPassedChar	varchar(1000)   = 'N/A'
		,@CRLF					varchar(10)		= char(13) + char(10)
		,@ProcName				varchar(256)	= OBJECT_NAME(@@PROCID) 
		,@ParentStepLogId       int				= -1
		,@PrevStepLog			int				= -1
		,@ProcessStartDtm		datetime		= getdate()
		,@CurrentDtm			datetime		= getdate()
		,@PreviousDtm			datetime		= getdate()
		,@DbName				varchar(50)		= DB_NAME()
		,@CurrentUser			varchar(256)	= CURRENT_USER
		,@ProcessType			varchar(10)		= 'Proc'
		,@StepName				varchar(256)	= 'Start'
		,@StepOperation			varchar(50)		= 'N/A' 
		,@MessageType			varchar(20)		= 'Info' -- ErrCust, ErrSQL, Info, Warn
		,@StepDesc				nvarchar(2048)	= 'Procedure started' 
		,@StepStatus			varchar(10)		= 'Success'
		,@StepNumber			varchar(10)		= 0
		,@Duration				varchar(10)		= 0
		,@JSONSnippet			nvarchar(max)	= 'N/A'
		,@ServerName			VARCHAR(100)	= @@SERVERNAME
		/*
		,@ReferenceId			int				= -1
		,@SSISProject			VARCHAR(100)	= 'N/A'		
		,@SSISFolder			VARCHAR(100)	= 'N/A'		
		,@SSISPackage			VARCHAR(100)	= 'N/A'		
		*/
		,@ExecutingPostingGroupId int			= -1
		,@NextctlPBatchSeq		int				= -1
		,@pctlBId				int				= -1
		,@ExecutionId			int				= -1
		,@HTTPObject			int				= -1
		,@HTTPResponseText		varchar(8000)	= 'N/A'
		,@HTTPBody				varchar(8000)	= 'N/A'
		,@HTTPURL				varchar(8000)	
		,@DevHTTPURL			varchar(8000)	= 'https://execdatafactorypipeline-dev.azurewebsites.net/api/ExecutePipeline?'
		,@QAHTTPURL				varchar(8000)	= 'https://execdatafactorypipeline-qa.azurewebsites.net/api/ExecutePipeline?'
		,@PRODHTTPURL			varchar(8000)	= 'https://execdatafactorypipeline.azurewebsites.net/api/ExecutePipeline?'
		,@AzureSubscriptionId	varchar(200)	= '3641d697-5ff2-4b72-9be2-c9ecbebd47c5'
		,@DevResourceGroup		varchar(100)	= 'zvo-sbx-01-ds-dev-rg'
		,@QAResourceGroup		varchar(100)	= 'zvo-sbx-01-ds-qa-rg'
		,@PRODResourceGroup		varchar(100)	= 'zvo-sbx-01-ds-rg'
		,@ResourceGroup			varchar(100)	= 'N/A'
		,@APIResponse			varchar(20)		= 'Unknown'
-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------
SELECT	 @ParametersPassedChar	= 
			'exec ctl.usp_ExecuteDataFactory' + @CRLF +
			'     @pDataFactoryName = ' + isnull(cast(@pDataFactoryName as varchar(100)),'NULL') + @CRLF + 
			'    ,@pDataFactoryPipeline = ' + isnull(cast(@pDataFactoryPipeline as varchar(100)),'NULL') + ' output' + @CRLF + 
			'    ,@pStatus = ' + isnull(cast(@pPathId as varchar(100)),'NULL') + @CRLF + 
			'    ,@pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
			'    ,@pPathId = ' + isnull(cast(@pPathId as varchar(100)),'NULL') + @CRLF + 
			'    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL')

IF @pVerbose					= 1
BEGIN 
	PRINT @ParametersPassedChar
END


-------------------------------------------------------------------------------
--  Log Procedure Start
-------------------------------------------------------------------------------
EXEC [audit].[usp_InsertStepLog]
		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose

select	@pExecuteProcessStatus		= 'ISF'
-------------------------------------------------------------------------------
--  Main Code Block
-------------------------------------------------------------------------------
BEGIN TRY
	
	-------------------------------------------------------------------------------
	-- Trigger Data Factory  - Start
	-------------------------------------------------------------------------------
	select	 @StepName			= 'Trigger Data Factory'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'API Call'
			,@StepDesc			= 'Trigger Data Factory using API Call'
	-------------------------------------------------------------------------------


	select @ResourceGroup = CASE WHEN @ServerName IN ('DME1EDLSQL01','DEDTEDLSQL01') THEN @DevResourceGroup
								 WHEN @ServerName IN ('QME1EDLSQL01','QME3EDLSQL01') THEN @QAResourceGroup
								 WHEN @ServerName IN ('PRODEDLSQL01') THEN @PRODResourceGroup
							END

	select @HTTPURL = CASE WHEN @ServerName IN ('DME1EDLSQL01','DEDTEDLSQL01') THEN @DevHTTPURL
								 WHEN @ServerName IN ('QME1EDLSQL01','QME3EDLSQL01') THEN @QAHTTPURL
								 WHEN @ServerName IN ('PRODEDLSQL01') THEN @PRODHTTPURL
							END

	select @HTTPBody = '{
		"subscriptionId": "'+ @AzureSubscriptionId	+ '",
		"resourceGroup": "'	+ @ResourceGroup		+ '",
		"factoryName": "'	+ @pDataFactoryName		+ '",
		"pipelineName": "'	+ @pDataFactoryPipeline	+ '"}'

-- Doing some testing
--print 'Assuming process clear to run'
select	@pExecuteProcessStatus		= 'ISS' -- Instance Start successful
--GOTO EndProcessTest

	EXEC sp_OACreate 
		'MSXML2.ServerXMLHTTP'--Programatic identifier of the OLE object to create
		,@HTTPObject OUTPUT;--returned Object token

	EXEC sp_OAMethod @HTTPObject, 'open', NULL, 'post', @HTTPURL, 'false'

	EXEC sp_OAMethod @HTTPObject, 'setRequestHeader', NULL, 'Content-Type', 'application/json; charset=utf-8'

	EXEC sp_OAMethod @HTTPObject,'send', NULL, @HTTPBody

	EXEC sp_OAMethod @HTTPObject,'responseText',@HTTPResponseText OUTPUT

	SELECT @APIResponse = (select [Status] from OPENJSON(@HTTPResponseText) WITH (PipelineName VARCHAR(200) '$.PipelineName', [Status] VARCHAR(200) '$.Status'));

	if		 @APIResponse in ('Queued', 'In Progress', 'Succeeded', 'Canceled', 'Canceling')
		select 	  @pExecuteProcessStatus = 'ISS' -- Instance start successful.
	else if  @APIResponse in ('Failed', 'PipelineTriggerFailed')
		select 	  @pExecuteProcessStatus = 'ISF' -- Instance start failed.
	else if  @APIResponse = 'PipelineIsRunning'
		select 	  @pExecuteProcessStatus = 'IAR' -- Instance already running.
	else
		select 	  @pExecuteProcessStatus = 'ISF' -- Instance run failed.

	EXEC sp_OADestroy @HTTPObject

	-------------------------------------------------------------------------------
	-- Trigger Data Factory  - End
	-------------------------------------------------------------------------------
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			,@JSONSnippet		= replace(@HTTPBody,'}',',"@pExecuteProcessStatus":"'  + isnull(@pExecuteProcessStatus, 'Bad Value') + '",' +
								  '"@pAllowMultipleInstances":"' + isnull(cast(@pAllowMultipleInstances as varchar(2)),'Bad Value') + '"}')

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose
	-------------------------------------------------------------------------------
		
END TRY

-------------------------------------------------------------------------------
--  Error Handling
-------------------------------------------------------------------------------
BEGIN CATCH

	SELECT 	 @PreviousDtm		= @CurrentDtm
			,@ErrNum			= @@ERROR
			,@ErrMsg			= ERROR_MESSAGE()
			,@Rows				= 0

	select	 @StepStatus		= 'Failure'
			,@CurrentDtm		= getdate()

	IF		 @MessageType		<> 'ErrCust'
		SELECT   @MessageType	= 'ErrSQL'

	EXEC [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	IF 	@ErrNum < 50000	
		SELECT	 @ErrNum	= @ErrNum + 100000000 -- Need to increase number to throw message.

	;THROW	 @ErrNum, @ErrMsg, 1
	
END CATCH

-------------------------------------------------------------------------------
--  Log Procedure End
-------------------------------------------------------------------------------
SELECT 	 @PreviousDtm			= @CurrentDtm
		,@CurrentDtm			= getdate()
		,@StepNumber			= @StepNumber + 1
		,@StepName				= 'End'
		,@StepDesc				= 'Procedure completed'
		,@Rows					= 0
		,@StepOperation			= 'N/A'

-- Passing @ProcessStartDtm so the total duration for the procedure is added.
-- @ProcessStartDtm (if you want total duration) 
-- @PreviousDtm (if you want 0)
EXEC [audit].usp_InsertStepLog
		 @MessageType ,@CurrentDtm ,@ProcessStartDtm ,@StepNumber ,@StepOperation ,@JSONSnippet ,@ErrNum
		,@ParametersPassedChar, @ErrMsg OUTPUT, @ParentStepLogId ,@ProcName, @ProcessType ,@StepName
		,@StepDesc OUTPUT, @StepStatus, @DbName, @Rows, @pETLExecutionId ,@pPathId, @PrevStepLog output
		,@pVerbose