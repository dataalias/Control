CREATE PROCEDURE [pg].[usp_RetryPostingGroup] (
	@pETLExecutionId					int				= -1
	,@pPathId							int				= -1
	,@pVerbose							bit				= 0)
AS
/*****************************************************************************
File:		usp_RetryPostingGroup.sql
Name:		usp_RetryPostingGroup
Purpose:	Will do the retries for failed staging and failed Posting Group loads
Example:	exec pg.usp_RetryPostingGroup -1, -1, 0
Parameters: 
Called by:	
Calls:      
Errors:		
Author:		Omkar Chowkwale
Date:		2019-06-04
*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
----------	-------------	---------------------------------------------------
2020-10-22	Omkar Chowkwale	Initial Iteration
20201118	ffortunato		cleaning up warnings. calling SSIS exec proc.
20201119	ffortunato		cleaning up temp tables and making table variables.
20210415	ffortunato		Taxes
							cleaning up warnings
							cleaning up process calls to SSIS ADFP etc.
							fixing logging. youre welcome omkar.

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
		,@ProcessStartDtm		datetime		= getdate()
		,@CurrentDtm			datetime		= getdate()
		,@PreviousDtm			datetime		= getdate()
		,@DbName				varchar(50)		= DB_NAME()
		,@CurrentUser			varchar(50)		= CURRENT_USER
		,@ServerName			varchar(255)	= @@SERVERNAME
		,@ProcessType			varchar(10)		= 'Proc'
		,@StepName				varchar(256)	= 'Start'
		,@StepOperation			varchar(50)		= 'N/A' 
		,@MessageType			varchar(20)		= 'Info' -- ErrCust, ErrSQL, Info, Warn
		,@StepDesc				nvarchar(2048)	= 'Procedure started' 
		,@StepStatus			varchar(10)		= 'Success'
		,@StepNumber			varchar(10)		= '0'
		,@SubStepNumber			varchar(23)		= '0'
		,@Duration				varchar(10)		= '0'
		,@JSONSnippet			nvarchar(max)	= NULL
		,@PostingGroupProcessingId	bigint		=-1
		,@RetryFlag				int				=-1
		,@FailureFlag			int				=-1
		,@DestTblName			varchar(255)
		,@SSISFolder			varchar(255)
		,@SSISProject			varchar(255)
		,@SSISPackage			varchar(255)
		,@ReferenceId			int
		,@ExecutionId			int
		,@Running				int				= 2
--		,@TriggerProcess		varchar(50)
		,@DataFactoryName		varchar(255)
		,@DataFactoryPipeline	varchar(255)
		,@DataFactoryStatus		varchar(50)
		,@ExecutingPostingGroupId int
		,@ExecutingPostingGroupBatchSeq bigint
		,@ExecutingPostingGroupBatchId int
		,@SSISParameters		udt_SSISPackageParameters
		,@ObjectType			int				= 30 -- package parameter
		,@LoopCount				int				= -1
		,@MaxLoop				int				= -1
		,@PostingGroupFailed	varchar(10)		= 'PF'
		,@PostingGroupRetry		varchar(10)		= 'PR'
		,@PostingGroupQueued	varchar(10)		= 'PQ'
		,@PostingGroupProcessing varchar(10)	= 'PP'
		,@IsProcessed			bit				= 0
		,@ProcessingMethodCode	varchar(20)		= 'UNK'
		,@ProcessingModeCode	varchar(20)		= 'UNK'
		,@JobName				varchar(255)	= 'UNK'
		,@JobReturnCode			int				= -1
		,@ExecuteProcessStatus	varchar(20)		= 'ISF'

declare @PostingGroupProcessingRecords table (
		 PostingGroupProcessingRecordsId	int identity (1,1)
		,PostingGroupProcessingId	bigint			NOT NULL
		,PostingGroupBatchId		int				NOT NULL
		,PostingGroupId				int				NOT NULL
		,PGPBatchSeq				bigint		 	NOT NULL
		,ProcessingMethodCode		varchar(20)		NOT NULL
		,ProcessingModeCode			varchar(20)		NOT NULL
		,SSISFolder					varchar(255)	NOT NULL
		,SSISProject				varchar(255)	NOT NULL
		,SSISPackage				varchar(255)	NOT NULL
		,DataFactoryName			varchar(255)	NOT NULL
		,DataFactoryPipeline		varchar(255)	NOT NULL
		,JobName					varchar(255)	NOT NULL
		,RetryFlag					int				NOT NULL
		,FailureFlag				int				NOT NULL
--		,TriggerProcess				varchar(100)
		,IsProcessed				bit			 	NOT NULL)
	

-------------------------------------------------------------------------------
--  Display Verbose
-------------------------------------------------------------------------------
SELECT	 @ParametersPassedChar	= 
			'exec BPI_DW_STAGE.pg.usp_RetryPostingGroup' + @CRLF +
			'    ,@pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
			'    ,@pPathId = ' + isnull(cast(@pPathId as varchar(100)),'NULL') + @CRLF + 
			'    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL')

if @pVerbose					= 1
	begin 
		print @ParametersPassedChar
	end

-------------------------------------------------------------------------------
--  Log Procedure Start
-------------------------------------------------------------------------------
exec [audit].[usp_InsertStepLog]
		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  Main Code Block
-------------------------------------------------------------------------------
begin try
	---------------------------------------------------------------------------------
	----  Update Posting Group records in status of 'PQ' or 'PP' to 'PR'
	---------------------------------------------------------------------------------
	--select	 @StepName			= 'Update PostingGroupProcessingIds to status PR'
	--		,@StepNumber		= @StepNumber + 1
	--		,@StepOperation		= 'Update'
	--		,@StepDesc			= 'Update PostingGroupProcessing records to status of Retry'
	---------------------------------------------------------------------------------	
	--UPDATE pgp
	--SET pgp.PostingGroupStatusId	= rs.StatusId
	--	,pgp.ModifiedBy				= @CurrentUser
	--	,pgp.ModifiedDtm			= @CurrentDtm
	--FROM pg.PostingGroupProcessing as pgp
	--INNER JOIN (
	--	SELECT max(PostingGroupProcessingId) AS PostingGroupProcessingId
	--		,PostingGroupId
	--	FROM pg.PostingGroupProcessing
	--	GROUP BY PostingGroupId
	--	) AS m ON m.PostingGroupProcessingId = pgp.PostingGroupProcessingId
	--LEFT JOIN pg.RefStatus AS r ON pgp.PostingGroupStatusId = r.StatusId
	--LEFT JOIN pg.RefStatus AS rs on rs.StatusCode = @PostingGroupRetry
	--LEFT JOIN pg.PostingGroup AS p ON m.PostingGroupId = p.PostingGroupId
	--LEFT JOIN [$(SSISDB)].[catalog].executions AS e ON e.project_name = p.SSISProject
	--	AND e.package_name = p.SSISPackage
	--	AND e.folder_name = p.SSISFolder
	--	AND e.[status] = @running
	--WHERE r.StatusCode IN (@PostingGroupQueued,@PostingGroupProcessing)
	--	AND p.IsActive = 1
	--	AND p.TriggerProcess IN ('SSIS','ADF')
	--	AND p.RetryMax <> 0
	--	AND e.execution_id IS NULL
	--	AND DATEDIFF(mi, pgp.ModifiedDtm, @CurrentDtm) > ctl.fn_GetIntervalInMinutes(p.RetryIntervalLength, p.RetryIntervalCode, - 1, - 1, 0)

	---------------------------------------------------------------------------------
	----  Update PostingGroupProcessing records in status of 'IP' or 'IS' to 'PR' - End
	---------------------------------------------------------------------------------
	--select	 @PreviousDtm		= @CurrentDtm
	--		,@Rows				= @@ROWCOUNT 
	--select	 @CurrentDtm		= getdate()

	--exec [audit].usp_InsertStepLog
	--		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
	--		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
	--		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
	--		,@pVerbose
	---------------------------------------------------------------------------------

	-------------------------------------------------------------------------------
	--  Select PostingGroupProcessing Records in status of 'PR' and fire off staging for each
	-------------------------------------------------------------------------------
	select	 @StepName			= 'Select PR, checks for execution, Execute'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Select'
			,@StepDesc			= 'Select PR, checks for execution, Execute'
	-------------------------------------------------------------------------------
	--Find whether PostingGroupProcessing needs to be retried and whether it needs to be failed
	
	--DROP TABLE IF EXISTS #PostingGroupProcessingId

	
	INSERT	INTO @PostingGroupProcessingRecords(
		 PostingGroupProcessingId
		,PostingGroupBatchId
		,PostingGroupId	
		,PGPBatchSeq
		,ProcessingMethodCode
		,ProcessingModeCode
		,SSISFolder
		,SSISProject
		,SSISPackage
		,DataFactoryName
		,DataFactoryPipeline
		,JobName
		,RetryFlag
		,FailureFlag
--		,TriggerProcess
		,IsProcessed
	)
	SELECT pgp.PostingGroupProcessingId
		,pgp.PostingGroupBatchId
		,pgp.PostingGroupId
		,pgp.PGPBatchSeq
		,p.ProcessingMethodCode
		,pgp.ProcessingModeCode
		,p.SSISFolder
		,p.SSISProject
		,p.SSISPackage
		,p.DataFactoryName
		,p.DataFactoryPipeline
		,p.JobName
		,RetryFlag = CASE 
			WHEN DATEDIFF(mi, pgp.ModifiedDtm, @CurrentDtm) > ctl.fn_GetIntervalInMinutes(p.RetryIntervalLength, p.RetryIntervalCode, - 1, - 1, 0)
				THEN 1
			ELSE 0
			END
		,FailureFlag = CASE 
			WHEN (pgp.RetryCount >= p.RetryMax)	OR (DATEADD(mi,SLAEndTimeInMinutes,pgp.CreatedDtm) < @CurrentDtm)
				THEN 1
			ELSE 0
			END
--		,p.TriggerProcess
		,@IsProcessed
	FROM pg.PostingGroupProcessing AS pgp
	INNER JOIN pg.RefStatus AS rs 
	ON rs.StatusId = pgp.PostingGroupStatusId
	INNER JOIN pg.PostingGroup AS p 
	ON p.PostingGroupId = pgp.PostingGroupId
	WHERE rs.StatusCode = @PostingGroupRetry

	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()

	exec audit.usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	--Loop through individual PostingGroupProcessingID

	select	 @MaxLoop			= max(PostingGroupProcessingRecordsId) from @PostingGroupProcessingRecords
	select	 @LoopCount			= 1
			,@StepNumber		= @StepNumber + 1

	while @LoopCount <= @MaxLoop
	BEGIN

		select	 @StepName			= 'Priming parameters for the while loop.'
				,@StepNumber		= @StepNumber + 0
				,@SubStepNumber     = @StepNumber + '.' + cast(@LoopCount as varchar(10)) + '.1'
				,@StepOperation		= 'loop'
				,@StepDesc			= 'Gathering variable values. Check JSON for specifics.'

		SELECT	 @PostingGroupProcessingId		= PostingGroupProcessingId
				,@ExecutingPostingGroupId		= PostingGroupId
				,@ExecutingPostingGroupBatchSeq	= PGPBatchSeq
				,@ExecutingPostingGroupBatchId	= PostingGroupBatchId
				,@ProcessingMethodCode			= ProcessingMethodCode
				,@ProcessingModeCode			= ProcessingModeCode
				,@SSISFolder					= SSISFolder
				,@SSISProject					= SSISProject
				,@SSISPackage					= SSISPackage
				,@DataFactoryName				= DataFactoryName
				,@DataFactoryPipeline			= DataFactoryPipeline
				,@JobName						= JobName
				,@RetryFlag						= RetryFlag
				,@FailureFlag					= FailureFlag
				--,@TriggerProcess				= TriggerProcess
				,@IsProcessed					= IsProcessed
		FROM	 @PostingGroupProcessingRecords
		WHERE	 PostingGroupProcessingRecordsId = @LoopCount

					-- Upon completion of the step, log it!
		select	 @PreviousDtm		= @CurrentDtm
				,@Rows				= @@ROWCOUNT 
		select	 @CurrentDtm		= getdate()
				,@JSONSnippet		= '{"@SSISFolder":"'			+ isnull(@SSISFolder,'Unknown')  +
									'","@SSISProject":"'			+ isnull(@SSISProject,'Unknown') +
									'","@SSISPackage":"'			+ isnull(@SSISPackage,'Unknown') +
									'","@DataFactoryName":"'		+ isnull(@DataFactoryName,'Unknown') +
									'","@DataFactoryPipeline":"'	+ isnull(@DataFactoryPipeline,'Unknown') +
									'","@LoopCount":"'				+ cast(isnull(@LoopCount,-1) as varchar(20)) +'"}'

		exec audit.usp_InsertStepLog
				 @MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
				,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
				,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
				,@pVerbose

		select	 @JSONSnippet		= NULL

-- SOME OF THIS CODE LOOKS EXACTLY THE SAME AS WE HAVE ELSE WHERE. MAKE IT A SEPERATE CALL SO WE DONT MAANGE TO SEPERATE COPIES OF THE SAME CODE.
-- started the work with pg.usp_ExecuteProcess

		IF(@RetryFlag = 1 AND @FailureFlag = 0)
		BEGIN
/*
			insert into	@SSISParameters values (@ObjectType,'pkg_PostingGroupId',		@ExecutingPostingGroupId)
			insert into	@SSISParameters values (@ObjectType,'pkg_PostingGroupBatchSeq',	@ExecutingPostingGroupBatchSeq)
			insert into	@SSISParameters values (@ObjectType,'pkg_PostingGroupBatchId',	@ExecutingPostingGroupBatchId)
*/
			exec [pg].[usp_ExecuteProcess]
					 @pPostingGroupProcessingId				= @PostingGroupProcessingId
					,@pIssueId								= -1 -- IssueId Not Needed
					,@pAllowMultipleInstances				= 0
					 /*
					,@pProcessingMethodCode					= @ProcessingMethodCode
					,@pSSISFolder							= @SSISFolder
					,@pSSISProject							= @SSISProject
					,@pSSISPackage							= @SSISPackage
					,@pSSISParameters						= @SSISParameters
					,@pDataFactoryName						= @DataFactoryName
					,@pDataFactoryPipeline					= @DataFactoryPipeline
					,@pSQLJobName							= @JobName
					*/
					,@pExecuteProcessStatus					= @ExecuteProcessStatus output

			--If (@ExecuteProcessStatus <> 'ISS') -- We didn't kick off a new process because one was running so we need to manage the retry counter here. We increment then move on.
			--begin
			UPDATE	 pgp
			SET		 RetryCount				 = RetryCount + 1
					,ModifiedBy				 = @CurrentUser
					,ModifiedDtm			 = @CurrentDtm
			FROM	pg.PostingGroupProcessing  pgp
			WHERE	PostingGroupProcessingId = @PostingGroupProcessingId	
			--end
/*		
			IF(@ProcessingMethodCode = 'SSIS')
			BEGIN

				select	 @StepName			= 'Processing SSIS.'
						,@StepNumber		= @StepNumber + 0
						,@SubStepNumber     = @StepNumber + '.' + cast(@LoopCount as varchar(10)) + '.2'
						,@StepOperation		= 'loop'
						,@StepDesc			= 'Gathering variable values. Check JSON for specifics.'

				IF NOT EXISTS(select 1 from [$(SSISDB)].catalog.executions where server_name = @ServerName AND folder_name = @SSISFolder AND project_name = @SSISProject AND package_name = @SSISPackage 
				AND status = @running)
				BEGIN

					insert into	@SSISParameters values (@ObjectType,'pkg_PostingGroupId',		@ExecutingPostingGroupId)
					insert into	@SSISParameters values (@ObjectType,'pkg_PostingGroupBatchSeq',	@ExecutingPostingGroupBatchSeq)
					insert into	@SSISParameters values (@ObjectType,'pkg_PostingGroupBatchId',	@ExecutingPostingGroupBatchId)

					exec pg.usp_ExecuteSSISPackage 
							 @pSSISProject		= @SSISProject
							,@pServerName		= @ServerName
							,@pSSISFolder		= @SSISFolder
							,@pSSISPackage		= @SSISPackage
							,@pSSISParameters	= @SSISParameters
							,@pETLExecutionId	= @pETLExecutionId
							,@pPathId			= @pPathId
							,@pVerbose			= @pVerbose	

					--Update the retry count for all PostingGroupProcessingIds that needs to be retried
					UPDATE pgp
					SET  RetryCount		 = RetryCount + 1
						,ModifiedBy		 = @CurrentUser
						,ModifiedDtm	 = @CurrentDtm
					FROM pg.PostingGroupProcessing AS pgp
					WHERE PostingGroupProcessingId = @PostingGroupProcessingId	
				END  -- SSIS package isn't running

				select	 @PreviousDtm		= @CurrentDtm
						,@Rows				= @@ROWCOUNT 
				select	 @CurrentDtm		= getdate()
						,@JSONSnippet		= '{"@SSISFolder":"'	+ @SSISFolder  + '",'
											+  '"@SSISProject":"'	+ @SSISProject + '",'
											+  '"@SSISPackage":"'	+ @SSISPackage + '",'
											+  '"@PostingGroupBatchId":"'	+ cast(@ExecutingPostingGroupBatchId as varchar(20)) + '",'
											+  '"@PGPBatchSeq":"'	+ cast(@ExecutingPostingGroupBatchSeq as varchar(20)) + '",'
											+  '"@ExecutingPostingGroupId Parent":"'+ cast(@ExecutingPostingGroupId as varchar(20))  + '",'
											+  '"@ExecutionId":"'	+ cast(@ExecutionId as varchar(20)) + '",'
											+  '"@ReferenceId":"'	+ cast(@ReferenceId as varchar(20))+ '"}' 

				exec audit.usp_InsertStepLog
						 @MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
						,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
						,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
						,@pVerbose
			END

			ELSE IF(@ProcessingMethodCode = 'ADFP')
			BEGIN

				select	 @StepName			= 'Processing ADFP.'
						,@StepNumber		= @StepNumber + 0
						,@SubStepNumber     = @StepNumber + '.' + cast(@LoopCount as varchar(10)) + '.2'
						,@StepOperation		= 'loop'
						,@StepDesc			= 'Processing Data Factory Pipeline Check JSON for specifics.'

				IF NOT EXISTS(select TOP 1 1 from @PostingGroupProcessingRecords WHERE IsProcessed = 1 AND DataFactoryName = @DataFactoryName AND DataFactoryPipeline = @DataFactoryPipeline)
				BEGIN

					EXEC pg.usp_ExecuteDataFactory @pDataFactoryName = @DataFactoryName, @pDataFactoryPipeline = @DataFactoryPipeline, @pStatus = @DataFactoryStatus OUTPUT

					IF(@DataFactoryStatus <> 'PipelineIsRunning')
					BEGIN
						--Update the retry count for all PostingGroupProcessingIds that needs to be retried
						UPDATE pgp
						SET  RetryCount		 = RetryCount + 1
							,ModifiedBy		 = @CurrentUser
							,ModifiedDtm	 = @CurrentDtm
						FROM pg.PostingGroupProcessing AS pgp
						WHERE PostingGroupProcessingId = @PostingGroupProcessingId		
					END
				END

				select	 @PreviousDtm		= @CurrentDtm
						,@Rows				= @@ROWCOUNT 
				select	 @CurrentDtm		= getdate()
						,@JSONSnippet		= '{"@DataFactoryName":"'		+ @DataFactoryName  + '",'
											+  '"@DataFactoryPipeline":"'	+ @DataFactoryPipeline + '",'
											+  '"@PostingGroupBatchId":"'	+ cast(@ExecutingPostingGroupBatchId as varchar(20)) + '",'
											+  '"@PGPBatchSeq":"'			+ cast(@ExecutingPostingGroupBatchSeq as varchar(20)) + '",'
											+  '"@ExecutingPostingGroupId Parent":"'+ cast(@ExecutingPostingGroupId as varchar(20))  + '",'
											+  '"@ExecutionId":"'			+ cast(@ExecutionId as varchar(20)) + '",'
											+  '"@ReferenceId":"'			+ cast(@ReferenceId as varchar(20))+ '"}' 

				exec audit.usp_InsertStepLog
						 @MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
						,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
						,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
						,@pVerbose
			END		-- IF(@ProcessingMethodCode = 'ADFP')
			ELSE IF (@ProcessingMethodCode = 'SQLJ')    --$$$$ Get me in coach.
			begin

				-- Note when calling the next package Batch and Posting Group must be sent as well.
				select	 @StepName			= 'Execute Posting Group SQL Job'
						,@StepNumber		= @StepNumber + 0
						,@SubStepNumber     = @StepNumber + '.' + cast(@LoopCount as varchar(10)) + '.2'
						,@StepOperation		= 'execute'
						,@StepDesc			= 'Execute SQL Server Job: ' + @JobName

				-- We are assuming that we can get the posting group processing id from within the job.
				EXEC	 @JobReturnCode		= msdb.dbo.sp_start_job 
							@job_name		= @JobName

				UPDATE pgp
				SET  RetryCount		 = RetryCount + 1
					,ModifiedBy		 = @CurrentUser
					,ModifiedDtm	 = @CurrentDtm
				FROM pg.PostingGroupProcessing AS pgp
				WHERE PostingGroupProcessingId = @PostingGroupProcessingId	

				-- Upon completion of the step, log it!
				select	 @PreviousDtm		= @CurrentDtm
						,@Rows				= @@ROWCOUNT 
				select	 @CurrentDtm		= getdate()

				exec audit.usp_InsertStepLog
						 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
						,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
						,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
						,@pVerbose

			end -- Execute a SQL Job
			else -- Unable to find anything to run.
				begin
					select	 @StepName			= 'Unable to Retry Posting Group'
							,@StepNumber		= @StepNumber + 0
							,@StepOperation		= 'warning'
							,@StepDesc			= 'Unknown execution type' + @ProcessingMethodCode

					-- Upon completion of the step, log it!
					select	 @PreviousDtm		= @CurrentDtm
							,@Rows				= @@ROWCOUNT 
					select	 @CurrentDtm		= getdate()

					exec audit.usp_InsertStepLog
							 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
							,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
							,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
							,@pVerbose
				end -- Bad else
*/
		END -- IF(@RetryFlag = 1 AND @FailureFlag = 0)

		IF(@FailureFlag = 1)
		BEGIN
			--Update to IF

			EXEC pg.UpdatePostingGroupProcessingStatus 
				 @pPostingGroupBatchId		= @ExecutingPostingGroupBatchId
				,@pPostingGroupId			= @ExecutingPostingGroupId
				,@pPostingGroupBatchSeq		= @ExecutingPostingGroupBatchSeq
				,@pPostingGroupStatusCode	= @PostingGroupFailed
		END  -- (@FailureFlag = 1)

		UPDATE	 @PostingGroupProcessingRecords
		SET		 IsProcessed				= 1
		WHERE	 PostingGroupProcessingId	= @PostingGroupProcessingId

		select	 @LoopCount						= @LoopCount + 1
				,@PostingGroupProcessingId		= -1
				,@ExecutingPostingGroupId		= -1
				,@ExecutingPostingGroupBatchSeq	= -1
				,@ExecutingPostingGroupBatchId	= -1
				,@ProcessingMethodCode			= 'UNK'
				,@ProcessingModeCode			= 'UNK'
				,@SSISFolder					= 'UNK'
				,@SSISProject					= 'UNK'
				,@SSISPackage					= 'UNK'
				,@DataFactoryName				= 'UNK'
				,@DataFactoryPipeline			= 'UNK'
				,@JobName						= 'UNK'
				,@RetryFlag						= 0
				,@FailureFlag					= 0     -- Why the flag convention when we always use IS?
				--,@TriggerProcess				= TriggerProcess
				,@IsProcessed					= 0


	END --while @LoopCount <= @MaxLoop

	-------------------------------------------------------------------------------
	--  Select PostingGroupProcessing Records in status of 'PR' and fire off staging for each - End
	-------------------------------------------------------------------------------
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose
	-------------------------------------------------------------------------------
		
end try

-------------------------------------------------------------------------------
--  Error Handling
-------------------------------------------------------------------------------
begin catch

	select 	 @PreviousDtm		= @CurrentDtm
			,@ErrNum			= @@ERROR
			,@ErrMsg			= ERROR_MESSAGE()

	select	 @StepStatus		= 'Failure'
			,@Rows				= @@ROWCOUNT
			,@CurrentDtm		= getdate()

	if		 @MessageType		<> 'ErrCust'
		select   @MessageType	= 'ErrSQL'

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	if 	@ErrNum < 50000	
		select	 @ErrNum	= @ErrNum + 100000000 -- Need to increase number to throw message.

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

exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
		,@pVerbose
-------------------------------------------------------------------------------
