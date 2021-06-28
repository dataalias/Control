CREATE PROCEDURE [pg].[usp_ExecuteProcess] (
	 @pPostingGroupProcessingId			bigint			= -1
	,@pIssueId					int			= -1
	,@pAllowMultipleInstances			bit			= 0
	,@pExecuteProcessStatus				varchar(20)		output
	,@pETLExecutionId				int			= -1
	,@pPathId					int			= -1
	,@pVerbose					bit			= 0)
AS
/*****************************************************************************
File:		usp_ExecuteProcess.sql
Name:		[usp_ExecuteProcess]

Purpose:	Generic Kick Off for processes. This thing can call:
				SSIS
				DataFactory
				SQL Job
				...

Parameters:	

		,@pExecuteProcessStatus	'IAR' -- Instance already running.
								'INR' -- Instance not running.
								'ISS' -- Instance start succeeded.
								'ISF' -- Instance start failed.

Execution:	exec pg.usp_ExecuteProcess 


Called By:	The completion of any process or scheudled job at 
			30 min interval.

Calls:		Any process that is ready to run.

Author:		ffortunato
Date:		20210413

******************************************************************************/

-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------

DECLARE	 @Rows					int			= 0
        ,@ErrNum				int			= -1
		,@ErrMsg			nvarchar(2048)		= 'N/A'
		,@ParametersPassedChar	varchar(1000)   		= 'N/A'
		,@CRLF				varchar(10)		= char(13) + char(10)
		,@ProcName			varchar(256)		= OBJECT_NAME(@@PROCID) 
		,@ParentStepLogId       	int			= -1
		,@PrevStepLog			int			= -1
		,@ProcessStartDtm		datetime		= getdate()
		,@CurrentDtm			datetime		= getdate()
		,@PreviousDtm			datetime		= getdate()
		,@DbName			varchar(50)		= DB_NAME()
		,@ServerName			varchar(50)		= @@SERVERNAME
		,@CurrentUser			varchar(256)		= CURRENT_USER
		,@ProcessType			varchar(10)		= 'Proc'
		,@StepName			varchar(256)		= 'Start'
		,@StepOperation			varchar(50)		= 'N/A' 
		,@MessageType			varchar(20)		= 'Info' -- ErrCust, ErrSQL, Info, Warn
		,@StepDesc			nvarchar(2048)		= 'Procedure started' 
		,@StepStatus			varchar(10)		= 'Success'
		,@StepNumber			varchar(10)		= 0
		,@SubStepNumber			varchar(23)		= 0
		,@Duration			varchar(10)		= 0
		,@JSONSnippet			nvarchar(max)		= NULL

		-- Program Specific Parameters

		,@SSISParameters		udt_SSISPackageParameters
		,@ObjectType			int			= 30 -- package parameter
		,@JobReturnCode			int			= 1 -- 0 (success) or 1 (failure)
		,@ProcessingMethodCode		varchar(20)		= 'N/A'
		,@SSISFolder			varchar(255)		= 'N/A'
		,@SSISProject			varchar(255)		= 'N/A'
		,@SSISPackage			varchar(255)		= 'N/A'	
		,@DataFactoryName		varchar(255)		= 'N/A'
		,@DataFactoryPipeline		varchar(255)		= 'N/A'
		,@SQLJobName			varchar(255)		= 'N/A'
		,@SQLStoredProcedure		varchar(255)		= 'N/A'

		,@PostingGroupBatchId		int			= -1
		,@PostingGroupSequence		bigint			= -1
		,@PostingGroupId		int			= -1

exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar	,@ErrMsg output	,@ParentStepLogId	,@ProcName	,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus	,@DbName		,@Rows		,@pETLExecutionId	,@pPathId		,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

select	 @ParametersPassedChar	= 
            '***** Parameters Passed to exec pg.usp_ExecuteProcess' + @CRLF +
            '     @pPostingGroupProcessingId = ' + isnull(cast(@pPostingGroupProcessingId as varchar(100)),'NULL') + @CRLF + 
            '    ,@pIssueId = ' + isnull(cast(@pIssueId as varchar(100)),'NULL') + @CRLF + 
            '    ,@pProcessStatus = @pProcessStatus --output ' + @CRLF +
            '    ,@pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
            '    ,@pPathId = ' + isnull(cast(@pPathId as varchar(100)),'NULL') + @CRLF + 
            '    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL') + @CRLF + 
            '***** End of Parameters' + @CRLF 

-- REMOVE ME LATER
--print @ParametersPassedChar

select	  @pExecuteProcessStatus = 'ISF' -- Instance start failed.


if @pVerbose					= 1
	begin 
		print @ParametersPassedChar
	end

-------------------------------------------------------------------------------
--  Main
-------------------------------------------------------------------------------

If ((@pPostingGroupProcessingId > 0) and (@pIssueId <= 0))
begin
	select 
			 @ProcessingMethodCode				= pg.ProcessingMethodCode
			,@SSISFolder					= pg.SSISFolder
			,@SSISProject					= pg.SSISProject
			,@SSISPackage					= pg.SSISPackage
			,@PostingGroupBatchId				= pgp.PostingGroupBatchId
			,@PostingGroupSequence				= pgp.PGPBatchSeq
			,@PostingGroupId				= pgp.PostingGroupId
			,@DataFactoryName				= pg.DataFactoryName
			,@DataFactoryPipeline				= pg.DataFactoryPipeline
			,@SQLJobName					= pg.JobName
			,@SQLStoredProcedure				= pg.SQLStoredProcedure
	from	 pg.PostingGroupProcessing				  pgp
	join	 pg.PostingGroup					  pg
	on		 pgp.PostingGroupId				= pg.PostingGroupId
	where	 pgp.PostingGroupProcessingId				= @pPostingGroupProcessingId

	if @ProcessingMethodCode = 'SSIS'
	begin

		insert into	@SSISParameters values (@ObjectType,'pkg_PostingGroupId',		@PostingGroupId)
		insert into	@SSISParameters values (@ObjectType,'pkg_PostingGroupBatchSeq',	@PostingGroupSequence)
		insert into	@SSISParameters values (@ObjectType,'pkg_PostingGroupBatchId',	@PostingGroupBatchId)
	end
end

else If ((@pPostingGroupProcessingId <= 0) and (@pIssueId > 0))
begin
	select 
			 @ProcessingMethodCode				= pbn.ProcessingMethodCode
			,@SSISFolder					= pbn.SSISFolder
			,@SSISProject					= pbn.SSISProject
			,@SSISPackage					= pbn.SSISPackage
			,@DataFactoryName				= pbn.DataFactoryName
			,@DataFactoryPipeline				= pbn.DataFactoryPipeline
			,@SQLJobName					= pbn.StageJobName
	from	 ctl.Issue						  iss
	join	 ctl.Publication					  pbn
	on		 iss.PublicationId				= pbn.PublicationId
	where	 iss.IssueId						= @pIssueId

	if @ProcessingMethodCode = 'SSIS'
	begin
		insert into	@SSISParameters values (@ObjectType,'pkg_IssueId',	@pIssueId)
	end
end
else -- Error State
begin

	select 	 @PreviousDtm		= @CurrentDtm
			,@ErrNum	= 50010
			,@ErrMsg	= 'Cannot determine if Issue or Posting group should be run.'
			,@Rows		= 0
			,@MessageType	= 'ErrSQL'

	select	 @StepStatus		= 'Failure'
		,@CurrentDtm		= getdate()

	select	 @ErrMsg = @ErrMsg + @CRLF + 'ErrNum: ' +  cast(@ErrNum as varchar(20)) + @CRLF + ERROR_MESSAGE() + @CRLF + @ParametersPassedChar
			
	;throw	 @ErrNum, @ErrMsg, 1
end

/*
print 'Processing method	: ' +  isnull(@ProcessingMethodCode	,'NULL')
print 'SSISFolder			: ' +  isnull(@SSISFolder			,'NULL')
print 'SSISProject			: ' +  isnull(@SSISProject			,'NULL')
print 'SSISPackage			: ' +  isnull(@SSISPackage			,'NULL')
print 'DataFactoryName		: ' +  isnull(@DataFactoryName		,'NULL')
print 'DataFactoryPipeline	: ' +  isnull(@DataFactoryPipeline	,'NULL')
print 'SQLJobName			: ' +  isnull(@SQLJobName			,'NULL')
print 'SQLStoredProcedure	: ' +  isnull(@SQLStoredProcedure	,'NULL')
*/

begin try
	IF (@ProcessingMethodCode = 'SSIS')
	BEGIN
		-- Note when calling the next package Batch and Posting Group must be sent as well.
		select	 @StepName		= 'Execute Posting Group SSIS'
			,@StepNumber		= @StepNumber + 0
			,@StepOperation		= 'execute'
			,@StepDesc		= 'Execute SSIS Package: ' + @SSISPackage

	-- pretend execution   COMMENT THIS print OUT WHEN YOU WANT TO KICK THINGS OFF.
				
		print 'execute pg.usp_ExecuteSSISPackage'	+ isnull(@SSISPackage, 'BAD RESULT') 
						+ ' @SSISProject='	+ @SSISProject
						+ ' @ServerName='	+ @ServerName
						+ ' @SSISFolder='	+ @SSISFolder
						+ ' @SSISPackage='	+ @SSISPackage	+ @CRLF
						+  '@pPostingGroupProcesingId":"'	+ isnull(cast(@pPostingGroupProcessingId as varchar(10)),'NULL') + @CRLF
						+  '@pIssueId":"'					+ isnull(cast(@pIssueId					 as varchar(10)),'NULL') + @CRLF
/*
		exec pg.usp_ExecuteSSISPackage 
			 @pSSISProject			= @SSISProject	-- @pSSISProject
			,@pServerName			= @ServerName	-- @pServerName
			,@pSSISFolder			= @SSISFolder	-- @pSSISFolder
			,@pSSISPackage			= @SSISPackage	-- @pSSISPackage
			,@pSSISParameters		= @SSISParameters -- @pSSISParameters
			,@pETLExecutionId		= @pETLExecutionId
			,@pExecuteProcessStatus		= @pExecuteProcessStatus output
			,@pAllowMultipleInstances	= @pAllowMultipleInstances
			,@pPathId			= @pPathId
			,@pVerbose			= @pVerbose
*/
		select	 @PreviousDtm		= @CurrentDtm
				,@Rows				= @@ROWCOUNT 
		select	 @CurrentDtm		= getdate()
				,@JSONSnippet		= '{"@SSISFolder":"'	+ @SSISFolder  + '",'
									+  '"@SSISProject":"'	+ @SSISProject + '",'
									+  '"@SSISPackage":"'	+ @SSISPackage + '",'
									+  '"@pPostingGroupProcesingId":"'	+ isnull(cast(@pPostingGroupProcessingId as varchar(10)),'NULL') + '",'
									+  '"@pIssueId":"'					+ isnull(cast(@pIssueId					 as varchar(10)),'NULL') + '"}' 	

		exec audit.usp_InsertStepLog
				 @MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
				,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
				,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
				,@pVerbose

		select	 @JSONSnippet		= NULL
	END -- Call SSIS Package
	ELSE IF (@ProcessingMethodCode = 'ADFP')    --$$$$ Get me in coach.
	begin

		-- Note when calling the next package Batch and Posting Group must be sent as well.
		select	 @StepName			= 'Execute Posting Group ADFP'
				,@StepNumber		= @StepNumber + 0
				,@StepOperation		= 'execute'
				,@StepDesc			= 'Execute Azure Data Factory Pipeline: '

		print 'execute  [pg].[usp_ExecuteDataFactory]'										+ @CRLF
						+ ' @pDataFactoryName		= '''	+ @DataFactoryName		+ ''''	+ @CRLF
						+ ' @pDataFactoryPipeline	= '''	+ @DataFactoryPipeline	+ ''''	+ @CRLF
						+ ' @pStatus				= @DataFactoryStatus  output'			+ @CRLF
						+  '@pPostingGroupProcesingId":"'	+ isnull(cast(@pPostingGroupProcessingId as varchar(10)),'NULL') + @CRLF
						+  '@pIssueId":"'					+ isnull(cast(@pIssueId					 as varchar(10)),'NULL') + @CRLF
/*
		-- We are assuming that we can get the posting group processing id from within the job.
		-- Do we need to send a PorstingGroup processing id?
		EXEC	 [pg].[usp_ExecuteDataFactory] 
				 @pDataFactoryName			= @DataFactoryName				-- @DataFactoryName				
				,@pDataFactoryPipeline		= @DataFactoryPipeline			-- @DataFactoryPipeline			
				,@pExecuteProcessStatus		= @pExecuteProcessStatus output
				,@pAllowMultipleInstances	= @pAllowMultipleInstances	
				,@pETLExecutionId			= @pETLExecutionId
				,@pPathId					= @pPathId
				,@pVerbose					= @pVerbose
*/
		-- Upon completion of the step, log it!
		select	 @PreviousDtm		= @CurrentDtm
				,@Rows				= @@ROWCOUNT 
		select	 @CurrentDtm		= getdate()

		exec audit.usp_InsertStepLog
				 @MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
				,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
				,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
				,@pVerbose

	end -- Execute a SQL Job
	else if (@ProcessingMethodCode = 'SQLJ')    --$$$$ Get me in coach.
	begin

		-- Note when calling the next package Batch and Posting Group must be sent as well.
		select	 @StepName			= 'Execute Posting Group'
				,@StepNumber		= @StepNumber + 0
				,@StepOperation		= 'execute'
				,@StepDesc			= 'Execute SQL Server Job: ' + @SQLJobName

		-- We are assuming that we can get the posting group processing id from within the job.

		print 'EXEC	 @JobReturnCode	= msdb.dbo.sp_start_job @job_name = ''' + @SQLJobName + '''' +  @CRLF
					+  '@pPostingGroupProcesingId":"'	+ isnull(cast(@pPostingGroupProcessingId as varchar(10)),'NULL') + @CRLF
					+  '@pIssueId":"'					+ isnull(cast(@pIssueId					 as varchar(10)),'NULL') + @CRLF

		EXEC	 @JobReturnCode				= msdb.dbo.sp_start_job 
				 @job_name					= @SQLJobName

		if			 @JobReturnCode			= 1 -- fail return code
			select	 @pExecuteProcessStatus = 'ISF' -- Instance start failed.
		else if		 @JobReturnCode			= 0 -- succeed return code
			select	 @pExecuteProcessStatus = 'ISS' -- Instance start succeded.
		else
			select	 @pExecuteProcessStatus = 'ISF' -- Instance start failed.

		-- Upon completion of the step, log it!
		select	 @PreviousDtm		= @CurrentDtm
				,@Rows				= @@ROWCOUNT 
		select	 @CurrentDtm		= getdate()

		exec audit.usp_InsertStepLog
				 @MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
				,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
				,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
				,@pVerbose

	end -- Execute a SQL Job
	else if (@ProcessingMethodCode = 'SQLP')    --$$$$ Get me in coach.
	begin

		-- Note when calling the next package Batch and Posting Group must be sent as well.
		select	 @StepName			= 'Execute Posting Group'
				,@StepNumber		= @StepNumber + 0
				,@StepOperation		= 'execute'
				,@StepDesc			= 'Execute SQL Server Stored Procedure: ' + @SQLJobName

		-- We are assuming that we can get the posting group processing id from within the job.

		print 'EXEC	 ' + @SQLStoredProcedure + '''' +  @CRLF
					+  '@pPostingGroupProcesingId":"'	+ isnull(cast(@pPostingGroupProcessingId as varchar(10)),'NULL') + @CRLF
					+  '@pIssueId":"'					+ isnull(cast(@pIssueId					 as varchar(10)),'NULL') + @CRLF

		select	 @SQLStoredProcedure = @SQLStoredProcedure + ' @pPostingGroupProcessingId = ' + isnull(cast(@pPostingGroupProcessingId as varchar(10)),'NULL')

		select	 @JSONSnippet = '"@SQLStoredProcedure":"'+@SQLStoredProcedure+'"'

		exec	 (@SQLStoredProcedure)

		select	 @pExecuteProcessStatus = 'ISS' -- Instance start succeeded.

		-- Upon completion of the step, log it!
		select	 @PreviousDtm		= @CurrentDtm
				,@Rows				= @@ROWCOUNT 
		select	 @CurrentDtm		= getdate()

		exec audit.usp_InsertStepLog
				 @MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
				,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
				,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
				,@pVerbose

		select	 @JSONSnippet	 = NULL

	end -- Execute a SQL Procedure
	else -- Unable to find anything to run.
	begin
		select	 @StepName			= 'Unable to Execute Posting Group'
				,@StepNumber		= @StepNumber + 0
				,@StepOperation		= 'warning'
				,@StepDesc			= 'Unknown execution type' + isnull(@ProcessingMethodCode, 'Unknown')

		-- Upon completion of the step, log it!
		select	 @PreviousDtm		= @CurrentDtm
				,@Rows				= @@ROWCOUNT 
		select	 @CurrentDtm		= getdate()
				,@JSONSnippet		= '{"@ProcessingMethodCode":"'+isnull(@ProcessingMethodCode, 'Unknown')+'"}'

		exec audit.usp_InsertStepLog
				 @MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
				,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
				,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
				,@pVerbose

		select	 @ErrNum			= 60001
				,@ErrMsg			= @StepDesc

		;throw 	 @ErrNum, @ErrMsg, 1
	end -- Bad else
end try

begin catch
	-- In this instance we want to log the error however we 
	-- still want to fire other parent jobs so allow the loop to continue.
	-- Note: the loop will continue even if 1 job fails to fire
	--       each job that could fire will be attempted.
	select 	 @PreviousDtm		= @CurrentDtm
			,@ErrNum			= @@ERROR
			,@ErrMsg			= ERROR_MESSAGE()
			,@Rows				= 0
			,@MessageType		= 'ErrSQL'

	select	 @StepStatus		= 'Failure'
			,@CurrentDtm		= getdate()

	select	 @ErrMsg = @ErrMsg + @CRLF + 'ErrNum: ' +  cast(@ErrNum as varchar(20)) + @CRLF + ERROR_MESSAGE() + @CRLF + @StepDesc + ' not able to fire. '+ @CRLF + @ParametersPassedChar

	select	 @pExecuteProcessStatus = 'ISF' -- Instance start failed.
			
	if 	@ErrNum < 50000	
		select	 @ErrNum	= @ErrNum + 1000000 -- Need to increase number to throw message.

	;throw	 @ErrNum, @ErrMsg, 1
end catch

-------------------------------------------------------------------------------
--  Procedure End
-------------------------------------------------------------------------------

select 	 @PreviousDtm			= @CurrentDtm
select	 @CurrentDtm			= getdate()
		,@StepNumber			= @StepNumber + 1
		,@StepName				= 'End'
		,@StepDesc				= 'Procedure completed'
		,@Rows					= 0
		,@StepOperation			= 'N/A'

-- Passing @ProcessStartDtm so the total duration for the procedure is added.
-- @ProcessStartDtm (if you want total duration) 
-- @PreviousDtm (if you want 0)
exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm	,@ProcessStartDtm	,@StepNumber	,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
		,@pVerbose

/******************************************************************************
       Change History
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------

20210413	ffortunato		Initital Iteration
20210415	ffortunato		Why can i not make it to the pull?

******************************************************************************/
