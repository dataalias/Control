CREATE PROCEDURE [ctl].[usp_GetIssueDetails] (
		 @pIssueId		        INT
		,@pETLExecutionId		INT				= -1
		,@pPathId				INT				= -1
		,@pVerbose				BIT				= 0)
AS

/*****************************************************************************
File:		usp_GetIssueDetails.sql
Name:		usp_GetIssueDetails
Purpose:    Allows for the retrival of detailed Issue information.

exec ctl.usp_GetIssueDetails 212507, 1

Parameters:	@pIssueID - IssueID to retrieve details of

Called by: ETL
Calls:          

Errors:		

Author:		Gopi Kadambari
Date:		2018-03-13

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
2018-03-13	Gopi Kadambari	Original
2018-03-14	Gopi Kadambari	Adding new join to publication table to get publicationpath
2018-06-12	Jason Cabra	Add columns: PeriodStartTime (CharFull & CharTrim),
				PublicationSeq, PublicationCode
20201118	ffortunato		removing some warnings.
******************************************************************************/

-- TESTING --------------------------------------------------------------------
--declare @pIssueId	int				= 2185864
--declare @pVerbose	int				= 0
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------
DECLARE	 @Rows					varchar(10)		= 0
        ,@ErrNum				int				= -1
		,@ErrMsg				nvarchar(max)	= 'N/A'
		,@ParametersPassedChar	varchar(1000)   = 'N/A'
		,@CRLF					varchar(10)		= char(13) + char(10)
		,@ProcName				varchar(256)	= OBJECT_NAME(@@PROCID) 
		,@ParentStepLogId       int				= -1
		,@PrevStepLog			int				= -1
		,@CurrentDtm			datetime		= getdate()
		,@PreviousDtm			datetime		= getdate()
		,@DbName				varchar(256)	= DB_NAME()
		,@ProcessType			varchar(10)		= 'Proc'
		,@StepName				varchar(256)	= 'Start'
		,@StepOperation			varchar(50)		= 'N/A' 
		,@MessageType			varchar(50)		= 'Info' -- ErrCust, ErrSQL, Info, Warn
		,@StepDesc				nvarchar(max)	= 'Procedure started' 
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
			'exec Control.ctl.usp_GetIssueDetails' + @CRLF +
			'     @pIssueId = ' + isnull(cast(@pIssueId as varchar(100)),'NULL') + @CRLF + 
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

	IF EXISTS
	( 
		SELECT 1
		FROM ctl.Issue iss
		JOIN ctl.Publication pub
			ON iss.PublicationId = pub.PublicationId
		WHERE iss.IssueId = @pIssueId 
	)
	BEGIN
	
  		SELECT
			  iss.IssueId
			, iss.IssueName
			, pub.PublicationCode
			, pub.PublicationFilePath
			, CONVERT(VARCHAR(50), iss.PeriodStartTime, 121) AS PeriodStartTime
			, iss.PublicationSeq

		FROM ctl.Issue iss
		JOIN ctl.Publication pub
		on iss.PublicationId = pub.PublicationId 
		WHERE iss.IssueId = @pIssueId

	END
	ELSE
	BEGIN

		SELECT
			  0 AS IssueId
			, 'NA' AS IssueName
			, 'NA' AS PublicationCode
			, 'NA' AS PublicationFilePath
			, '1900-01-01 00:00:00.000' AS PeriodStartTime
			, 0 AS PublicationSeq

	END

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

/****** Object:  StoredProcedure [oie].[usp_OIE_stage_work_Cleanup_behave]    Script Date: 03/28/2018 1:07:24 PM ******/
SET ANSI_NULLS ON

