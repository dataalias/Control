DELIMITER //

CREATE PROCEDURE usp_NotifySubscriberOfDistribution (
    IN pIssueId INT DEFAULT -1,
    IN pStageStart DATETIME DEFAULT NULL,
    IN pStageEnd DATETIME DEFAULT NULL,
    IN pETLExecutionId INT DEFAULT -1,
    IN pPathId INT DEFAULT -1,
    IN pVerbose BOOLEAN DEFAULT 0
)
BEGIN
    DECLARE Rows INT DEFAULT 0;
    DECLARE ErrNum INT DEFAULT -1;
    DECLARE ErrMsg VARCHAR(65535) DEFAULT 'N/A';
    DECLARE ParametersPassedChar VARCHAR(1000) DEFAULT 'N/A';
    DECLARE CRLF VARCHAR(10) DEFAULT CHAR(13) + CHAR(10);
    DECLARE ProcName VARCHAR(256) DEFAULT 'usp_NotifySubscriberOfDistribution';
    DECLARE ParentStepLogId INT DEFAULT -1;
    DECLARE PrevStepLog INT DEFAULT -1;
    DECLARE ProcessStartDtm DATETIME DEFAULT NOW();
    DECLARE CurrentDtm DATETIME DEFAULT NOW();
    DECLARE PreviousDtm DATETIME DEFAULT NOW();
    DECLARE DbName VARCHAR(50) DEFAULT DATABASE();
    DECLARE CurrentUser VARCHAR(50) DEFAULT USER();
    DECLARE ProcessType VARCHAR(10) DEFAULT 'Proc';
    DECLARE StepName VARCHAR(256) DEFAULT 'Start';
    DECLARE StepOperation VARCHAR(50) DEFAULT 'N/A';
    DECLARE MessageType VARCHAR(20) DEFAULT 'Info';
    DECLARE StepDesc VARCHAR(2048) DEFAULT 'Procedure started';
    DECLARE StepStatus VARCHAR(10) DEFAULT 'Success';
    DECLARE StepNumber VARCHAR(10) DEFAULT '0';
    DECLARE SubStepNumber VARCHAR(23) DEFAULT '0';
    DECLARE Duration VARCHAR(10) DEFAULT '0';
    DECLARE JSONSnippet VARCHAR(65535) DEFAULT NULL;

    DECLARE SubscriptionCode VARCHAR(100) DEFAULT 'N/A';
    DECLARE PostingGroupBatchId INT DEFAULT -1;
    DECLARE PostingGroupId INT DEFAULT -1;
    DECLARE PostingGroupStatusId INT DEFAULT -1;
    DECLARE PostingGroupStatusCode VARCHAR(20) DEFAULT 'PC';
    DECLARE DistStatusId INT DEFAULT -1;
    DECLARE DistStatusCode VARCHAR(10) DEFAULT 'DN';
    DECLARE DateId INT DEFAULT -1;
    DECLARE ETLExecutionId INT DEFAULT -1;
    DECLARE DistributionId BIGINT DEFAULT -1;
    DECLARE Folder VARCHAR(100) DEFAULT 'N/A';
    DECLARE Project VARCHAR(100) DEFAULT 'N/A';
    DECLARE Package VARCHAR(100) DEFAULT 'N/A';
    DECLARE PGPSeq INT DEFAULT -1;
    DECLARE SubscriberCode VARCHAR(100) DEFAULT 'EDL';
    DECLARE IssueStatusCodeLoaded VARCHAR(100) DEFAULT 'IL';
    DECLARE DistributionStatusCodeAwait VARCHAR(100) DEFAULT 'DN';
    DECLARE DistributionStatusCodeNotify VARCHAR(100) DEFAULT 'DT';
    DECLARE LoopMax INT DEFAULT -1;
    DECLARE LoopCount INT DEFAULT 1;

    DECLARE NotificationList CURSOR FOR
        SELECT 
            IssueId,
            DistributionId,
            DistributionStatusCode,
            SubscriberCode,
            SubscriptionCode,
            DailyPublicationSeq
        FROM NotificationList;

    -- Insert initial log
    CALL usp_InsertStepLog(
        MessageType, CurrentDtm, PreviousDtm, StepNumber, StepOperation, JSONSnippet, ErrNum,
        ParametersPassedChar, ErrMsg, ParentStepLogId, ProcName
    );

		select	 @JSONSnippet		= NULL

		-------------------------------------------------------------------------------
		--  Check to see that we got a good set of values. Custom Error Check
		-------------------------------------------------------------------------------

		select	 @StepName			= 'Test Lookup Values'
				,@StepNumber		= @StepNumber + 0
				,@SubStepNumber		= @StepNumber + '.' + cast(@LoopCount as varchar(10)) + '.2'
				,@StepOperation		= 'validate'
				,@StepDesc			= 'Make sure each of the lookups above returned appropriate values.'

		if		 @SubscriptionCode	= 'N/A'	or 
				 @PostingGroupId	= -1	or 
				 @PostingGroupBatchId	 = -1		or 
				 @DateId			= -1	or 
				 @PGPSeq			= -1	or -- error test condition
				 exists (select top 1 1 
						from	 pg.[PostingGroupProcessing]
						where 	 PostingGroupBatchId	= @PostingGroupBatchId
						and		 PostingGroupId			= @PostingGroupId
						and		 PGPBatchSeq			= @PGPSeq)
		begin
			select   @ErrNum		= 50001
					,@MessageType	= 'ErrCust'
					,@ErrMsg		= 'Failure when lookup up supporting values. Review JSON for values of -1 or N/A.'
					,@JSONSnippet	= '{"@SubscriptionCode":"'	+      @SubscriptionCode +
									  '","@DistributionId":"'	+ cast(@DistributionId as varchar(20)) +
									  '","@IssueId":"'		+ cast(@pIssueId as varchar(20)) +
									  '","@PostingGroupId":"'	+ cast(@PostingGroupId as varchar(20)) +
									  '","@PostingGroupBatchId":"'	+ cast(@PostingGroupBatchId as varchar(20)) +
									  '","@PGPSeq":"'		+ cast(@PGPSeq as varchar(20)) +
									  '","@DateId":"'		+ cast(@DateId as varchar(20))+'"}'
				
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
					,@ParametersPassedChar	,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
					,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
					,@pVerbose

				select	 @JSONSnippet		= NULL
			end

		-------------------------------------------------------------------------------
		-- Gathers the information for each distribution assoicated with an Issue that 
		-- can be used to notify the subscribing system that processing can commense
		-------------------------------------------------------------------------------
		select	 @PostingGroupStatusId	= isnull(StatusId,-2)
		from	 pg.RefStatus			  rs
		where	 rs.StatusCode			= @PostingGroupStatusCode
		and		 rs.StatusType			= 'PostingGroup'

		select	 @StepName			= 'Insert Distribution Information'
				,@StepNumber		= @StepNumber + 0
				,@SubStepNumber		= @StepNumber + '.' + cast(@LoopCount as varchar(10)) + '.3'
				,@StepOperation		= 'insert'
				,@StepDesc			= 'Gathers the information for each distribution assoicated with an Issue that can be used to notify the subscribing system that processing can commense.'

		insert	 into pg.[PostingGroupProcessing](
				 [PostingGroupBatchId]		--[int] NOT NULL,
				,[PostingGroupId]		--[int] NOT NULL,
				,[PostingGroupStatusId]		--[int] NOT NULL,
				,[PGPBatchSeq]			--[int] NULL,
				,[SrcBatchSeq] 
				,[DateId]			--[int] NOT NULL,
				,[StartTime]			--[datetime] NULL,
				,[EndTime]			--[datetime] NULL,
				,[DurationChar]			--[varchar](20) NOT NULL,
				,[DurationSec]			--[int] NOT NULL,
				,[RecordCount]			--[int] NOT NULL,
				,[RetryCount]			--[int] NOT NULL,
				,IssueId			--[bigint]	null,
				,DistributionId			--[bigint]	null,
				,[ETLExecutionId]		--[int] NULL,
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
				,@Rows			= @@ROWCOUNT 
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
				,@ParametersPassedChar	,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
				,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
				,@pVerbose

		select	 @JSONSnippet		= NULL
				,@MessageType	= 'Info'
				,@StepStatus	= 'Success'

		-------------------------------------------------------------------------------
		-- Set the distribution to notified.
		-------------------------------------------------------------------------------
		select	 @StepName		= 'Update Distribution to Notified'
			,@StepNumber		= @StepNumber + 0
			,@SubStepNumber		= @StepNumber + '.' + cast(@LoopCount as varchar(10)) + '.4'
			,@StepOperation		= 'update'
			,@StepDesc			= 'Notification can be set to "sent".'
	
		update	 dist
		set		 StatusId	= (	select	 StatusId 
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
				,@ParametersPassedChar	,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
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
				,@StepDesc		= 'Execute downstream Posting Group processes by calling ExecutePostingGroupProcessing after sending notification.'
				-- Yes  this is here on purpose. All values are set. and incase of failure we want this here.
				,@JSONSnippet		= '{"ExecutePostingGroupProcessing":"' + 
									'exec pg.ExecutePostingGroupProcessing ' +
									' @pPGBId				=' + cast(@PostingGroupBatchId as varchar(20)) +
									',@pPGId				=' + cast(@PostingGroupId  as varchar(20)) +
									',@pPGBatchSeq				=' + cast(@PGPSeq  as varchar(20)) +
									',@pETLExecutionId			=' + cast(@pETLExecutionId  as varchar(20)) +
									',@pPathId				=' + cast(@pPathId  as varchar(20)) +
									',@pVerbose				=' + cast(@pVerbose  as varchar(20)) +
									+ '"}' 

		-- Upon completion of the step, log it!
		select	 @PreviousDtm		= @CurrentDtm
			,@Rows					= @@ROWCOUNT 
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
			-- Need to  get rid of this $$$$$
			--,@pIsDataHub			= @pIsDataHub
			,@pETLExecutionId		= @pETLExecutionId
			,@pPathId				= @pPathId
			,@pVerbose				= @pVerbose

		-- Upon completion of the step, log it!
		select	 @PreviousDtm		= @CurrentDtm
				,@Rows				= @@ROWCOUNT 
		select	 @CurrentDtm		= getdate()


		exec [audit].usp_InsertStepLog
				 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
				,@ParametersPassedChar	,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
				,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
				,@pVerbose

		select	 @JSONSnippet		= NULL
	
		-- Reset loop parameters
		select	 @DistributionId	= -1
			,@SubscriptionCode	= 'N/A'
			,@PostingGroupId	= -1
			,@Folder		= 'N/A'
			,@Project		= 'N/A'
			,@Package		= 'N/A'
			,@PGPSeq		= -1
			,@LoopCount		= @LoopCount + 1

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
			,@ParametersPassedChar	,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
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
	,@StepName			= 'End'
	,@StepDesc			= 'Procedure completed'
	,@Rows				= 0
	,@StepOperation			= 'N/A'

-- Passing @ProcessStartDtm so the total duration for the procedure is added.
-- @ProcessStartDtm (if you want total duration) 
-- @PreviousDtm (if you want 0)
exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm	,@ProcessStartDtm	,@StepNumber	,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar	,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
		,@pVerbose


/******************************************************************************
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

20220809	ffortunato		formatting

20230530	ffortunato		oETLExecutionId <-- *ID
******************************************************************************/
