CREATE PROCEDURE [ctl].[usp_GetLoadedIssueDetails] (
		 @pIssueId		        INT				= -1
		,@pTableName			varchar(255)	= 'N/A'
		,@pSeqAttribute			varchar(255)	= 'N/A'
		,@pHighWaterAttribute	varchar(255)	= 'N/A'
		/*
		,@pFirstRecordChecksum		varchar(255)			output
		,@pLastRecordChecksum		varchar(255)			output
		*/
		,@pFirstRecordSeq		bigint			output
		,@pLastRecordSeq		bigint			output
		,@pEndPeriodDateTime	datetime		output
		,@pETLExecutionId		INT				= -1
		,@pPathId				INT				= -1
		,@pVerbose				BIT				= 0)
AS

/*****************************************************************************
File:		usp_GetLoadedIssueDetails.sql
Name:		usp_GetLoadedIssueDetails
Purpose:    Allows for the retrival of detailed Issue information.

exec ctl.usp_GetLoadedIssueDetails 
@pIssueId = -1
,@pTableName = 'MyTable'

Parameters:	@pIssueID - IssueID to retrieve details of

Called by: ETL
Calls:          

Errors:		

Author:		ffortunato
Date:		20220210

******************************************************************************/



-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------
DECLARE	 @Rows					int				= 0
        ,@ErrNum				int				= -1
		,@ErrMsg				nvarchar(max)	= 'N/A'
		,@ParametersPassedChar	varchar(1000)   = 'N/A'
		,@CRLF					varchar(10)		= char(13) + char(10)
		,@ProcName				varchar(256)	= OBJECT_NAME(@@PROCID) 
		,@ParentStepLogId       int				= -1
		,@PrevStepLog			int				= -1
		,@CurrentDtm			datetime		= getdate()
		,@PreviousDtm			datetime		= getdate()
		,@DbName				varchar(50)		= DB_NAME()
		,@ProcessType			varchar(10)		= 'Proc'
		,@StepName				varchar(256)	= 'Start'
		,@StepOperation			varchar(50)		= 'N/A' 
		,@MessageType			varchar(20)		= 'Info' -- ErrCust, ErrSQL, Info, Warn
		,@StepDesc				nvarchar(2048)	= 'Procedure started' 
		,@StepStatus			varchar(10)		= 'Success'
		,@StepNumber			varchar(10)		= 0
		,@Duration				varchar(10)		= 0
		,@JSONSnippet			nvarchar(max)	= NULL



exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------
SELECT	 @ParametersPassedChar	= 
			'exec BPI_DW_Stage.ctl.usp_GetIssueDetails' + @CRLF +
			'     @pIssueId = ' + isnull(cast(@pIssueId as varchar(100)),'NULL') + @CRLF + 
			'     @pTableName = ' + isnull(cast(@pTableName as varchar(100)),'NULL') + @CRLF + 
			'    ,@pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
			'    ,@pPathId = ' + isnull(cast(@pPathId as varchar(100)),'NULL') + @CRLF + 
			'    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL')

if @pVerbose					= 1
	begin 
		print @ParametersPassedChar
	end


BEGIN TRY
	-- Set Log Values
	select	 @StepName			= 'Select Issue Records'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Select'
			,@StepDesc			= 'SelectiNg records from Issue table for the given IssueId'


	-- Insert Log Record
	SELECT	 @PreviousDtm = @CurrentDtm, @Rows = @@ROWCOUNT 
	SELECT	 @CurrentDtm = GETDATE()
	EXEC [audit].usp_InsertStepLog @MessageType, @CurrentDtm, @PreviousDtm, @StepNumber, @StepOperation, @JSONSnippet, @ErrNum, @ParametersPassedChar, @ErrMsg OUTPUT, @ParentStepLogId, @ProcName, @ProcessType, @StepName, @StepDesc OUTPUT, @StepStatus, @DbName, @Rows, @pETLExecutionId, @pPathId, @PrevStepLog OUTPUT, @pVerbose

	
END TRY

-------------------------------------------------------------------------------
--  Error Handling
-------------------------------------------------------------------------------
BEGIN CATCH
	SELECT 	 @PreviousDtm		= @CurrentDtm
			,@ErrNum			= @@ERROR
			,@ErrMsg			= ERROR_MESSAGE()

	SELECT	 @StepStatus		= 'Failure'
			,@Rows				= @@ROWCOUNT
			,@CurrentDtm		= GETDATE()

	IF		 @MessageType		<> 'ErrCust'
		SELECT   @MessageType	= 'ErrSQL'

	EXEC [audit].usp_InsertStepLog @MessageType, @CurrentDtm, @PreviousDtm, @StepNumber, @StepOperation, @JSONSnippet, @ErrNum, @ParametersPassedChar, @ErrMsg OUTPUT, @ParentStepLogId, @ProcName, @ProcessType, @StepName, @StepDesc OUTPUT, @StepStatus, @DbName, @Rows, @pETLExecutionId, @pPathId, @PrevStepLog OUTPUT, @pVerbose

	IF 	@ErrNum < 50000	
		SELECT	 @ErrNum	= @ErrNum + 100000000 -- Need to increase number to throw message.

	;THROW	 @ErrNum, @ErrMsg, 1
END CATCH

-------------------------------------------------------------------------------
--  Procedure End
-------------------------------------------------------------------------------
SELECT	 @CurrentDtm			= GETDATE()
		,@StepNumber			= @StepNumber + 1
		,@StepName				= 'End'
		,@StepDesc				= 'Procedure completed'
		,@Rows					= 0
		,@StepOperation			= 'N/A'

EXEC [audit].usp_InsertStepLog @MessageType, @CurrentDtm, @PreviousDtm, @StepNumber, @StepOperation, @JSONSnippet, @ErrNum, @ParametersPassedChar, @ErrMsg OUTPUT, @ParentStepLogId, @ProcName, @ProcessType, @StepName, @StepDesc OUTPUT, @StepStatus, @DbName, @Rows, @pETLExecutionId, @pPathId, @PrevStepLog OUTPUT, @pVerbose
-------------------------------------------------------------------------------



/******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20220210	ffortunato		Initial Iteration

******************************************************************************/