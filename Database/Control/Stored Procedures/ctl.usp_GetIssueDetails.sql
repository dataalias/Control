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
		FROM ctl.Issue id
		JOIN ctl.Publication pub
			ON iss.PublicationId = pub.PublicationId
		WHERE iss.IssueId = @pIssueId 
	)
	BEGIN
	
		select	 pr.PublisherId
				,pr.PublisherCode
				,pr.PublisherName
				,pn.PublicationId
				,pn.PublicationName
				,pn.PublicationCode
				,pr.InterfaceCode
				-- URL and Login info should come from the Secret / Vault
				,pn.SrcFileRegEx
				,pn.IntervalCode
				,pn.IntervalLength
				,pn.RetryIntervalCode
				,pn.RetryIntervalLength
				,pn.RetryMax
				,pn.ProcessingMethodCode
				,pn.TransferMethodCode
				,pn.NextExecutionDtm
				,pn.SLATime
				,ri.[SLAFormat]
				,ri.[SLARegEx]
				,pn.Bound
				,pn.SrcFileFormatCode  -- As FeedFormat
				,pn.StandardFileFormatCode
				,pn.SSISFolder
				,pn.SSISProject
				,pn.SSISPackage
				,pn.GlueWorkflow
				,pn.SrcPublicationName		
				,pn.SrcFilePath
				,pn.PublicationFilePath
				,pn.PublicationArchivePath
				,pn.PublicationGroupSequence
				,iss.IssueId					IssueId
				,iss.IssueName					IssueName
				,iss.PeriodStartTime			LastHighWaterMarkDatetime
				,iss.PeriodStartTimeUTC			LastHighWaterMarkDatetimeUTC
				,iss.PeriodEndTime				HighWaterMarkDatetime
				,iss.PeriodEndTimeUTC			HighWaterMarkDatetimeUTC
				,iss.LastRecordSeq				HighWaterMarkRecordSeq
				,rs.StatusCode					IssueStatusCode
				,iss.RecordCount				RecordCount
				,iss.ETLExecutionID				ETLExecutionID
				,iss.ReportDate					ReportDate

		from 	ctl.Publication				  pn
		join	ctl.Issue					  iss
		on		iss.PublicationId			= pn.PublicationId
		join	ctl.Publisher				  pr 
		on		pr.PublisherId				= pn.PublisherId
		join	ctl.RefInterval				  ri
		on		pn.IntervalCode				= ri.IntervalCode
		join	ctl.RefStatus				  rs
		on		iss.StatusId				= rs.StatusId
		where	pn.IsActive					= 1 
		and		iss.IssueId					= @pIssueId

	END
	ELSE
	BEGIN

		SELECT
			  -1	AS IssueId
			, 'NA'	AS IssueName
			, 'NA'	AS PublicationCode
			, 'NA'	AS PublicationFilePath
			, '1900-01-01 00:00:00.000' AS PeriodStartTime
			, -1	AS PublicationSeq

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



/******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
2018-03-13	Gopi Kadambari	Original
2018-03-14	Gopi Kadambari	Adding new join to publication table to get publicationpath
2018-06-12	Jason Cabra	Add columns: PeriodStartTime (CharFull & CharTrim),
				PublicationSeq, PublicationCode
20201118	ffortunato		removing some warnings.
20220726	ffortunato		Adding new attributes and new logic to supprt dh
							processing within the new class.
20230527	ffortunato		getting consistency with Get Publication List and
							Record. Gateway API
******************************************************************************/