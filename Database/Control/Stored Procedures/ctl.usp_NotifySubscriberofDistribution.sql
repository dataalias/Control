CREATE procedure [ctl].[usp_NotifySubscriberOfDistribution] (
		 @pIssueId				int				= -1
		,@pStageStart			datetime		= NULL
		,@pStageEnd				datetime		= NULL
		,@pIsDataHub			int				= -1
		,@pETLExecutionId		int				= -1
		,@pPathId				int				= -1
		,@pVerbose				bit				= 0)
AS
/*****************************************************************************
File:		usp_NotifySubscriberOfDistribution.sql
Name:		usp_NotifySubscriberOfDistribution

Purpose:	

exec ctl.usp_NotifySubscriberOfDistribution
		 @pIssueId								= 9532
		 ,@pIsDataHub							= -1
		,@pETLExecutionId						= -1
		,@pPathId								= -1
		,@pVerbose								= 0

Parameters:     

Called by:	
Calls:          

Errors:		

Author:		ffortunato
Date:		20180413

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20180413	ffortunato		Initial Iteration
20180801	ffortunato		Hax. Check the @SubscriberCode logic at top of 
							procedure.

20180806	ffortunato		Calling Execute as well. (inline)

20180907	ffortunato		Adding functionality for multiple internal 
							subscribers.

20190624	ochowkwale		Switching th logic for calculating BatchId from 
							CurrentDtm to ReportDate

20190812	ochowkwale		Compatibility with Azure Data Factory. 
							Passing the IsDataHub parameter further.

20200515	ffortunato		making sure txn for new batch doesnt fail.
							ISOLATION LEVEL SERIALIZABLE
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
		,@ProcessType			varchar(10)		= 'Proc'
		,@StepName				varchar(256)	= 'Start'
		,@StepOperation			varchar(50)		= 'N/A' 
		,@MessageType			varchar(20)		= 'Info' -- ErrCust, ErrSQL, Info, Warn
		,@StepDesc				nvarchar(2048)	= 'Procedure started' 
		,@StepStatus			varchar(10)		= 'Success'
		,@StepNumber			varchar(10)		= 0
		,@SubStepNumber			varchar(23)		= 0
		,@Duration				varchar(10)		= 0
		,@JSONSnippet			nvarchar(max)	= NULL

		,@SubscriptionCode		varchar(100)	= 'N/A'
		,@PostingGroupBatchId	int				= -1
		,@PostingGroupId		int				= -1
		,@PostingGroupStatusId	int				= -1
		,@PostingGroupStatusCode	varchar(20)	= 'PC' -- If we made it to this point the feed is staged.
		,@DistStatusId			int				= -1
		,@DistStatusCode		varchar(10)		= 'DN'
		,@DateId				int				= -1
		,@ETLExecutionId		int				= -1 --This is the SSIS that will be invoked.
		,@DistributionId		bigint			= -1
		,@Folder				varchar(100)	= 'N/A'
		,@Project				varchar(100)	= 'N/A'
		,@Package				varchar(100)	= 'N/A'
		,@PGPSeq				int				= -1
		,@SubscriberCode		varchar(100)	= 'EDL'
		,@IssueStatusCodeLoaded	varchar(100)	= 'IL'
		,@DistributionStatusCodeAwait	varchar(100)	= 'DN'
		,@DistributionStatusCodeNotify	varchar(100)	= 'DT'
		,@LoopMax				int				= -1
		,@LoopCount				int				=  1


declare	 @NotificationList table (
		 NotificationListId		int identity (1,1) not null
		,IssueId				int				not null
		,DistributionId			bigint			not null
		,DistributionStatusCode	varchar(20)		not null
		,SubscriberCode			varchar(20)		not null
		,SubscriptionCode		varchar(100)	not null
		,DailyPublicationSeq	int				not null
)

exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

select	 @ParametersPassedChar	= 
      '***** Parameters Passed to exec ctl.usp_NotifySubscriberOfDistribution' + @CRLF +
      '     @pIssueId = ' + isnull(cast(@pIssueId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pStageStart = ''' + isnull(convert(varchar(100),@pStageStart ,13) ,'NULL') + '''' + @CRLF + 
      '    ,@pStageEnd = ''' + isnull(convert(varchar(100),@pStageEnd ,13) ,'NULL') + '''' + @CRLF + 
      '    ,@pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pPathId = ' + isnull(cast(@pPathId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL') + @CRLF + 
      '***** End of Parameters' + @CRLF 

if @pVerbose					= 1
	begin 
		print @ParametersPassedChar
	end

SELECT @DateId = COALESCE(cast(convert(VARCHAR(20), ReportDate, 112) AS INT), cast(convert(VARCHAR(20), @CurrentDtm, 112) AS INT))
FROM ctl.Issue
WHERE IssueId = @pIssueId

-------------------------------------------------------------------------------
--  Main
-------------------------------------------------------------------------------

begin try

-------------------------------------------------------------------------------
-- Get the batch Id, The Distribution StatusId and posting group id.
---------------------------------------------------------------------------------
	select	 @StepName			= 'Get all associated distributions'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'insert'
			,@StepDesc			= 'Loading the primer table to prepare notifications.'


	insert into @NotificationList (
			 IssueId			
			,DistributionId
			,DistributionStatusCode
			,SubscriberCode		
			,SubscriptionCode
			,DailyPublicationSeq)
	select		 
			 IssueId			
			,DistributionId
			,DistributionStatusCode
			,SubscriberCode		
			,SubscriptionCode
			,DailyPublicationSeq
	from	 ctl.vw_DistributionStatus ds
	where	 ds.IssueId			= @pIssueId
	and		 ds.IssueStatusCode = @IssueStatusCodeLoaded
	and		 ds.DistributionStatusCode = @DistributionStatusCodeAwait


--	select * from @NotificationList

	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			,@JSONSnippet		= '{"@IssueStatusCodeLoaded":"'	+ @IssueStatusCodeLoaded +
									  '","@DistributionStatusCodeAwait":"'	+ cast(@DistributionStatusCodeAwait as varchar(20)) +
									  '","@pIssueId":"'	+ cast(@pIssueId as varchar(20)) + '"}'

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose


	select	 @StepName			= 'Loop through Distribution Records'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'loop'
			,@StepDesc			= 'Attempt to send notification to all subscribers of a specific publication.'

	select  @LoopMax			= isnull(max(NotificationListId),-1)
	from    @NotificationList

--select * from @NotificationList

		-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			,@JSONSnippet		= '{"Loop Count":"' + cast(@LoopMax as varchar(10)) + '"}'

	exec audit.usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	BEGIN TRY
		SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
		
		BEGIN TRANSACTION PostingGroupBatch

		IF NOT EXISTS (
				SELECT TOP 1 1
				FROM pg.PostingGroupBatch
				WHERE DateId = @DateId
				)
		BEGIN
			INSERT INTO pg.[PostingGroupBatch] (
				DateId
				,CreatedBy
				,CreatedDtm
				)
			VALUES (
				cast(convert(VARCHAR(20), @DateId, 112) AS INT)
				,@CurrentUser
				,@CurrentDtm
				)
		END

		COMMIT TRANSACTION PostingGroupBatch

		SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	END TRY

	BEGIN CATCH
		IF error_number() IN (2627,2601) -- (primalry key, unique index) violation
		BEGIN
			-- Just continue on.
			RETURN
		END

		ROLLBACK TRANSACTION

		SET TRANSACTION ISOLATION LEVEL READ COMMITTED

		IF @ErrNum < 50000
			SELECT @ErrNum = @ErrNum + 100000000 -- Need to increase number to throw message.
				;

		throw @ErrNum
			,@ErrMsg
			,1
	END CATCH


	SELECT @PostingGroupBatchId = isnull(PostingGroupBatchId, - 1)
		,@DateId = isnull(DateId, - 1)
	FROM pg.PostingGroupBatch
	WHERE DateId = @DateId


	------------------------------------------------------------------------------
	-- Loping through each of the distributions for the issue and 
	-- notifying accordingly.
	------------------------------------------------------------------------------
	while	 @LoopCount			<= @LoopMax  
	begin
		------------------------------------------------------------------------------
		-- Get the batch Id, The Distribution StatusId and posting group id.
		------------------------------------------------------------------------------
		select	 @StepName			= 'Lookup @NotificationList Information'
				,@StepNumber		= @StepNumber + 0
				,@SubStepNumber     = @StepNumber + '.' + cast(@LoopCount as varchar(10)) + '.1'
				,@StepOperation		= 'select'
				,@StepDesc			= 'Priming the data needed to send notification.'

		select	 @DistributionId	= isnull(nl.DistributionId,-1)
				,@SubscriptionCode	= isnull(nl.SubscriptionCode,'N/A')
		from	 @NotificationList	  nl
		where	 NotificationListId = @LoopCount

	-- Minor HAX. for the staged data subscription and posting group should be the same...
	-- Make this a trigger on the bpi_dw posting group table to kick off the package...
		select   @PostingGroupId	= isnull(pg.PostingGroupId,-1)
				,@Folder			= isnull(pg.SSISFolder, 'N/A')
				,@Project			= isnull(pg.SSISProject,'N/A')
				,@Package			= isnull(pg.SSISPackage,'N/A')
		from	 pg.PostingGroup	  pg
		where	 PostingGroupCode	= @SubscriptionCode

	-- Posting Group sequence is reset with each new batch id.
		select	 @PGPSeq				= isnull(max(PGPBatchSeq),0)+1
		from	 pg.PostingGroupProcessing
		where	 PostingGroupBatchId	= @PostingGroupBatchId
		and		 PostingGroupId			= @PostingGroupId

		-- Upon completion of the step, log it!
		select	 @PreviousDtm		= @CurrentDtm
				,@Rows				= @@ROWCOUNT 
		select	 @CurrentDtm		= getdate()
				,@JSONSnippet		= '{"@StatusId":"'			+ cast(@DistStatusId as varchar(20)) + 
									  '","@SubscriptionCode":"'	+      @SubscriptionCode +
									  '","@DistStatusId":"'		+ cast(@DistStatusId as varchar(20)) +
									  '","@DistributionId":"'	+ cast(@DistributionId as varchar(20)) +
									  '","@IssueId":"'			+ cast(@pIssueId as varchar(20)) +
									  '","@Folder":"'			+ cast(@Folder as varchar(20)) +
									  '","@Project":"'			+      @Project +
									  '","@Package":"'			+      @Package +
									  '","@PostingGroupId":"'	+ cast(@PostingGroupId as varchar(20)) +
									  '","@PostingGroupBatchId":"'+ cast(@PostingGroupBatchId as varchar(20)) +
									  '","@PGPSeq":"'			+ cast(@PGPSeq as varchar(20)) +
									  '","@DateId":"'			+ cast(@DateId as varchar(20))+'"}'

		exec [audit].usp_InsertStepLog
				 @MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
				,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
				,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
				,@pVerbose

		select	 @JSONSnippet		= NULL

		-------------------------------------------------------------------------------
		--  Check to see that we got a good set of values. Custom Error Check
		-------------------------------------------------------------------------------

		select	 @StepName			= 'Test Lookup Values'
				,@StepNumber		= @StepNumber + 0
				,@SubStepNumber		= @StepNumber + '.' + cast(@LoopCount as varchar(10)) + '.2'
				,@StepOperation		= 'validate'
				,@StepDesc			= 'Make sure each of the lookups above returned appropriate values.'

		if		 @SubscriptionCode	 = 'N/A' or 
				 @PostingGroupId	 = -1 or 
				 @PostingGroupBatchId = -1 or 
				 @DateId			 = -1 or 
				 @PGPSeq			 = -1 or -- error test condition
				 exists (select top 1 1 
						from	 pg.[PostingGroupProcessing]
						where 	 PostingGroupBatchId	 = @PostingGroupBatchId
						and		 PostingGroupId			 = @PostingGroupId
						and		 PGPBatchSeq			 = @PGPSeq)
		begin
			select   @ErrNum		= 50001
					,@MessageType	= 'ErrCust'
					,@ErrMsg		= 'Failure when lookup up supporting values. Review JSON for values of -1 or N/A.'
					,@JSONSnippet	= '{"@SubscriptionCode":"'	+      @SubscriptionCode +
									  '","@DistributionId":"'	+ cast(@DistributionId as varchar(20)) +
									  '","@IssueId":"'			+ cast(@pIssueId as varchar(20)) +
									  '","@PostingGroupId":"'	+ cast(@PostingGroupId as varchar(20)) +
									  '","@PostingGroupBatchId":"'+ cast(@PostingGroupBatchId as varchar(20)) +
									  '","@PGPSeq":"'			+ cast(@PGPSeq as varchar(20)) +
									  '","@DateId":"'			+ cast(@DateId as varchar(20))+'"}'
				
			; throw @ErrNum, @ErrMsg, 1  -- This is thrown to the catch block below.
		end

		else
			begin
				-- Log successful validation.
				select	 @PreviousDtm		= @CurrentDtm
				select	 @CurrentDtm		= getdate()
	-- remove later
				exec [audit].usp_InsertStepLog
					 @MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
					,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
					,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
					,@pVerbose

				select	 @JSONSnippet		= NULL
			end

		-------------------------------------------------------------------------------
		-- Gathers the information for each distribution assoicated with an Issue that 
		-- can be used to notify the subscribing system that processing can commense
		-------------------------------------------------------------------------------
		select	 @StepName			= 'Insert Distribution Information'
				,@StepNumber		= @StepNumber + 0
				,@SubStepNumber		= @StepNumber + '.' + cast(@LoopCount as varchar(10)) + '.3'
				,@StepOperation		= 'insert'
				,@StepDesc			= 'Gathers the information for each distribution assoicated with an Issue that can be used to notify the subscribing system that processing can commense.'

		select	 @PostingGroupStatusId	= isnull(StatusId,-2)
		from	 pg.RefStatus			  rs
		where	 rs.StatusCode			= @PostingGroupStatusCode
		and		 rs.StatusType			= 'PostingGroup'


		insert into pg.[PostingGroupProcessing](
				 [PostingGroupBatchId]	--[int] NOT NULL,
				,[PostingGroupId]		--[int] NOT NULL,
				,[PostingGroupStatusId]	--[int] NOT NULL,
				,[PGPBatchSeq]			--[int] NULL,
				,[SrcBatchSeq] 
				,[DateId]				--[int] NOT NULL,
				,[StartTime]			--[datetime] NULL,
				,[EndTime]				--[datetime] NULL,
				,[DurationChar]			--[varchar](20) NOT NULL,
				,[DurationSec]			--[int] NOT NULL,
				,[RecordCount]			--[int] NOT NULL,
				,[RetryCount]			--[int] NOT NULL,
				,IssueId				--[bigint]	null,
				,DistributionId			--[bigint]	null,
				,[ETLExecutionID]		--[int] NULL,
				,[CreatedBy]			--[varchar](50) NOT NULL,
				,[CreatedDtm]			--[datetime] NOT NULL,
		)
		select 
				 @PostingGroupBatchId
				,@PostingGroupId
				,@PostingGroupStatusId
				,@PGPSeq
				,DailyPublicationSeq
				,@DateId
				,isnull(@pStageStart,@CurrentDtm)
				,isnull(@pStageEnd,@CurrentDtm)
				,'00:00:00'
				,datediff(s,isnull(@pStageStart,@CurrentDtm),isnull(@pStageEnd,@CurrentDtm))
				,0
				,0
				,@pIssueId
				,@DistributionId
				,@pETLExecutionId
				,@CurrentUser
				,@CurrentDtm
		from	 @NotificationList
		where	 NotificationListId	= @LoopCount

		-- Upon completion of the step, log it!
		select	 @PreviousDtm		= @CurrentDtm
				,@Rows				= @@ROWCOUNT 
		select	 @CurrentDtm		= getdate()
				--,@JSONSnippet		= '{"":"' + @myvar + '"}' -- Only if needed.

		-- If no rows were added we should log a warning.
		if @Rows <= 0
		begin
			select	 @MessageType		= 'Warn'
					,@JSONSnippet		= '{"Warning":"No record notifications could be sent to DW PostingGroupProcessing."' +
											'","@SubscriptionCode":"'	+      @SubscriptionCode +
											'","@DistStatusId":"'		+ cast(@DistStatusId as varchar(20)) +
											'","@DistributionId":"'		+ cast(@DistributionId as varchar(20)) +
											'","@IssueId":"'			+ cast(@pIssueId as varchar(20)) +
											'","@Folder":"'				+ cast(@Folder as varchar(20)) +
											'","@Project":"'			+      @Project +
											'","@Package":"'			+      @Package +
											'","@PostingGroupId":"'		+ cast(@PostingGroupId as varchar(20)) +
											'","@PostingGroupBatchId":"'+ cast(@PostingGroupBatchId as varchar(20)) +
											'","@PGPSeq":"'				+ cast(@PGPSeq as varchar(20)) +
											'","@DateId":"'				+ cast(@DateId as varchar(20)) + 
											'","@CurrentUser":"'		+ cast(@CurrentUser as varchar(20)) + 
											'","@CurrentDtm":"'			+ cast(@CurrentDtm as varchar(20)) + '"}'
					,@StepStatus		= 'Warning'

		end

		exec [audit].usp_InsertStepLog
				 @MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
				,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
				,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
				,@pVerbose

		select	 @JSONSnippet		= NULL
				,@MessageType		= 'Info'
				,@StepStatus		= 'Success'

		-------------------------------------------------------------------------------
		-- Set the distribution to notified.
		-------------------------------------------------------------------------------
		select	 @StepName			= 'Update Distribution to Notified'
				,@StepNumber		= @StepNumber + 0
				,@SubStepNumber		= @StepNumber + '.' + cast(@LoopCount as varchar(10)) + '.4'
				,@StepOperation		= 'update'
				,@StepDesc			= 'Notification can be set to "sent".'
	
		update	 dist
		set		 StatusId				= ( select	 StatusId 
											from	 ctl.RefStatus 
											where	 StatusCode = @DistributionStatusCodeNotify) -- Notification Sent
		from	 ctl.Distribution		  dist
		where	 dist.DistributionId	= @DistributionId
	
		-- Upon completion of the step, log it!
		select	 @PreviousDtm		= @CurrentDtm
				,@Rows				= @@ROWCOUNT 
		select	 @CurrentDtm		= getdate()
				,@JSONSnippet		= '{"@DistributionId":"'     + cast(@DistributionId               as varchar(20)) + '"' +
									  ',"@DistributionStatus":"' + cast(@DistributionStatusCodeNotify as varchar(20)) + '"}' 

		exec [audit].usp_InsertStepLog
				 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
				,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
				,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
				,@pVerbose

		select	 @JSONSnippet		= NULL

		-------------------------------------------------------------------------------
		-- Execute the process??
		-------------------------------------------------------------------------------
	
		select	 @StepName			= 'execute ExecutePostingGroupProcessing'
				,@StepNumber		= @StepNumber + 0
				,@SubStepNumber		= @StepNumber + '.' + cast(@LoopCount as varchar(10)) + '.5'
				,@StepOperation		= 'exec'
				,@StepDesc			= 'Execute downstream Posting Group processes by calling ExecutePostingGroupProcessing after sending notification.'
				-- Yes  this is here on purpose. All values are set. and incase of failure we want this here.
				,@JSONSnippet		= '{"ExecutePostingGroupProcessing":"' + 
									'exec pg.ExecutePostingGroupProcessing ' +
									' @pPGBId				=' + cast(@PostingGroupBatchId as varchar(20)) +
									',@pPGId				=' + cast(@PostingGroupId  as varchar(20)) +
									',@pPGBatchSeq			=' + cast(@PGPSeq  as varchar(20)) +
									',@pETLExecutionId		=' + cast(@pETLExecutionId  as varchar(20)) +
									',@pPathId				=' + cast(@pPathId  as varchar(20)) +
									',@pVerbose				=' + cast(@pVerbose  as varchar(20)) +
									+ '"}' 

		-- Upon completion of the step, log it!
		select	 @PreviousDtm		= @CurrentDtm
				,@Rows				= @@ROWCOUNT 
		select	 @CurrentDtm		= getdate()

		exec [audit].usp_InsertStepLog
				 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
				,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
				,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
				,@pVerbose

		select	 @JSONSnippet		= NULL

		exec pg.ExecutePostingGroupProcessing 
			 @pPGBId				= @PostingGroupBatchId
			,@pPGId					= @PostingGroupId
			,@pPGBatchSeq			= @PGPSeq
			,@pIsDataHub			= @pIsDataHub
			,@pETLExecutionId		= @pETLExecutionId
			,@pPathId				= @pPathId
			,@pVerbose				= @pVerbose

		-- Upon completion of the step, log it!
		select	 @PreviousDtm		= @CurrentDtm
				,@Rows				= @@ROWCOUNT 
		select	 @CurrentDtm		= getdate()


		exec [audit].usp_InsertStepLog
				 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
				,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
				,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
				,@pVerbose

		select	 @JSONSnippet		= NULL
	
		-- Reset loop parameters
		select	 @DistributionId	= -1
				,@SubscriptionCode	= 'N/A'
				,@PostingGroupId	= -1
				,@Folder			= 'N/A'
				,@Project			= 'N/A'
				,@Package			= 'N/A'
				,@PGPSeq			= -1
				,@LoopCount			= @LoopCount + 1

	end --While loop
end try

-------------------------------------------------------------------------------
--  Error Handling
-------------------------------------------------------------------------------
begin catch

	select 	 @PreviousDtm		= @CurrentDtm
			,@ErrNum			= @@ERROR
			,@ErrMsg			= ERROR_MESSAGE()
			,@Rows				= 0

	select	 @StepStatus		= 'Failure'
			,@CurrentDtm		= getdate()

	if		 @MessageType		<> 'ErrCust'
		select   @MessageType	= 'ErrSQL'

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
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

-- Passing @ProcessStartDtm so the total duration for the procedure is added.
-- @ProcessStartDtm (if you want total duration) 
-- @PreviousDtm (if you want 0)
exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm	,@ProcessStartDtm	,@StepNumber	,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
		,@pVerbose