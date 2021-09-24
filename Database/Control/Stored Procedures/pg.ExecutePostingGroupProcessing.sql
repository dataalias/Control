CREATE PROCEDURE [pg].[ExecutePostingGroupProcessing] (
		 @pPGBId				int				= -1
		,@pPGId					int				= -1
		,@pPGBatchSeq			int				= -1
		--IsDataHub needs to be removed!!
		--,@pIsDataHub			int				= -1
		,@pETLExecutionId		int				= -1
		,@pPathId				int				= -1
		,@pVerbose				bit				= 0)
AS
/*****************************************************************************
File:		ExecutePostingGroupProcessing.sql
Name:		ExecutePostingGroupProcessing

Purpose:	Each time a posting groups status is updated to a complete 
			state the system must determine if a subssequent posting group
			can be fired off.

Parameters:	The parameters for this procedure are those from the posting 
			group that just completed. Otherwise null is passed and the 
			procedure can look for any process that need to execute
			for the current day.

   @pPGPBId     Posting Group Batch Id, NULL default value will 
				default to today's date if there is a batch entry, otherwise
				default to the max batch value in the table.

  ,@pPGId       Use this if you want to execute a particulare PGId
				Normally this is the posting group id of a processes that has
				just completed (the childId)

  ,@pPGBatchSeq

  ,@pIsDataHub	Pass for Datahub/Data Factory based execution

  ,@pVerbose    (Optional) Set to 1 if you want to get output to the screen.
				Useful for testing.

Execution:	exec pg.ExecutePostingGroupProcessing 
		 @pPGBId				= null
		,@pPGId					= null
		,@pPGBatchSeq			= -1
		,@pETLExecutionId		= -1
		,@pPathId				= -1
		,@pVerbose				= 0

Called By:	The completion of any process or scheudled job at 
			30 min interval.

Calls:		Any process that is ready to run.

Author:		ffortunato
Date:		20161018

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
		,@ServerName			varchar(50)		= @@SERVERNAME
		,@CurrentUser			varchar(256)	= CURRENT_USER
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

		-- Program Specific Parameters

		,@CreatedDtm			datetime		= getdate()
		,@CreatedBy				varchar(50)		= cast(system_user as varchar(50))
		,@PGStatusComplete		varchar(20)     = 'PC' -- Posting Group Complete.
		,@PGStatusReady			varchar(20)     = 'PI' -- Posting Group Ready.
		,@PGStatusReadyId		int				= -1
		,@PGStatusQueued		varchar(20)     = 'PQ' -- Posting Group Queued.
		,@PGCurrentStatus		varchar(20)     = 'PF' -- Posting Group Queued.
		,@LoopMax				int				= -1
		,@LoopCount				int				=  1
		,@TotalCount			int				= -1
		,@ReadyCount			int				= -2
		,@SSISFolder			varchar(255)	= 'N/A'     
		,@SSISProject			varchar(255)	= 'N/A'
		,@SSISPackage			varchar(255)	= 'N/A'
		,@DataFactoryName		varchar(255)	= 'N/A'
		,@DataFactoryPipeline	varchar(255)	= 'N/A'
		,@DataFactoryStatus		varchar(255)	= 'N/A'
		,@ExecutionString		varchar(2000)	= 'N/A'
		,@DateId				int				= -1
--		,@MaxPGPBatchSeq		int				= -1
		,@CurPGPBatchSeq		int				= -1
		,@NextPGPBatchSeq		int				= -1
		,@ExecutingPostingGroupId		int		= -1
		,@ExecutingChildPostingGroupId	int		= -1
		,@ExecutionId			int				= -1
		,@ReferenceId			int				= -1
		,@SSISParameters		udt_SSISPackageParameters
		,@ObjectType			int				= 30 -- package parameter
		,@CurrentNextExecutionDtm	datetime	= cast('1900-01-01 00:00:00.000' as datetime)
		,@NextExecutionDtm		datetime		= cast('1900-01-01 00:00:00.000' as datetime)
		,@IntervalCode			varchar(20)		= 'N/A'
		,@IntervalLength		int				= -1
		--,@TriggerType			varchar(20)		= 'Immediate'
		,@IntervalCodeImmediate	varchar(20)		= 'IMM'
		,@JobName				varchar(255)	= 'Unknown'
		,@JobReturnCode			int				= 1 -- 0 (success) or 1 (failure)
		,@ProcessStatus			varchar(255)	= 'N/A'
		,@ParentProcessingMethodCode		varchar(20)		= 'UNK'
		,@ParentProcessingModeCode			varchar(20)		= 'UNK'
		,@PostingGroupProcessingIdToExecute bigint			= -1
		,@PostingGroupCodeToExecute			varchar(100)	= 'UNK'
		,@ExecuteProcessStatus				varchar(20)		= 'ISF' -- Instant start failed
		,@AllowMultipleInstances			bit				= 0


declare @PostingGroupParents	table (
		 ParentStatusCode		varchar(20) not null default 'N/A'
		,ChildStatusCode		varchar(20)
		,PGId					int
		,ParentId				int			not null default -1
		,ChildId				int
		,ParentSeq				bigint		not null default -1
		,ChildSeq				bigint
		,PGPBatchSeq			int			not null default -1
--		,ParentProcessingMethodCode	varchar(20)		Not null default 'UNK'
--		,ParentProcessingModeCode	varchar(20)		not null default 'UNK'
)

declare @PostingGroupReady		table (
		PostingGroupReadyId		int			identity(1,1)
	   ,PostingGroupId			int
	   ,TotalCount				int			not null default -1
	   ,ReadyCount				int			not null default -2
	   ,ChildPostingGroupId		int			not null default -3
)  


exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

SELECT	 @ParametersPassedChar	= 
      '***** Parameters Passed to exec pg.ExecutePostingGroupProcessing' + @CRLF +
      '     @pPGBId = ' + isnull(cast(@pPGBId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pPGId = ' + isnull(cast(@pPGId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pPGBatchSeq = ' + isnull(cast(@pPGBatchSeq as varchar(100)),'NULL') + @CRLF + 
      '    ,@pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pPathId = ' + isnull(cast(@pPathId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL') + @CRLF + 
      '***** End of Parameters' + @CRLF 

select	 @PGStatusReadyId		= isnull(rs.StatusId, -1)
from	 pg.RefStatus			  rs
where	 rs.StatusCode			= @PGStatusReady

select	 @DateId				= isnull(pgb.DateId, -1)
from	 pg.PostingGroupBatch	  pgb
where	 pgb.PostingGroupBatchId = @pPGBId

if @pVerbose					= 1
	begin 
		print @ParametersPassedChar
	end

-------------------------------------------------------------------------------
--  Main
-------------------------------------------------------------------------------

begin try

-------------------------------------------------------------------------------
-- This section of code determines if any dependent jobs can be run based 
-- on other processes completeing.
-------------------------------------------------------------------------------

	select	 @StepName			= 'Identify Ready Parent Posting Groups'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'insert'
			,@StepDesc			= 'This section of code determines if any dependent jobs can be run based on other processes completeing.'

	insert   into @PostingGroupParents (
			 ParentStatusCode
			,ChildStatusCode
			,PGId
			,ParentId
			,ChildId
			,ParentSeq
			,ChildSeq
			,PGPBatchSeq
--			,ParentProcessingMethodCode	
--			,ParentProcessingModeCode	
			)
	select
			 'N/A' -- @PGStatusReady					as ParentStatusCode
			,RS.StatusCode					as ChildStatusCode
			,PGP.PostingGroupId
			,PGD.ParentId
			,PGD.ChildId
			,PGP.PGPBatchSeq				as ParentSeq
   			,PGP.PGPBatchSeq				as ChildSeq
			,@pPGBatchSeq
--			,pg.ProcessingMethodCode
--			,pg.ProcessingModeCode
	from     pg.PostingGroupProcessing		  PGP
	join     pg.RefStatus					  RS 
	on       RS.StatusId					= PGP.PostingGroupStatusId
	join     pg.PostingGroupDependency		  PGD
	on       PGP.PostingGroupId				= PGD.ChildId
	join	 pg.PostingGroup				  pg
	on		 pg.PostingGroupId				= PGD.ParentId
	where    RS.StatusCode					= @PGStatusComplete -- Child's PG Status
	and      PGP.PostingGroupId				= @pPGId  -- Child's posting group.
	and      PGP.PostingGroupBatchId		= @pPGBId -- Only get data from today's process.
	and		 PGP.PGPBatchSeq				= @pPGBatchSeq
	and		 pg.IsActive					= 1

	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			,@JSONSnippet		= '{"Comment":"If no parent rows are found procedure exits. ' +
									'","@Rows":"'				+ cast(isnull(@Rows,-1) as varchar(20)) +
									'","@PGStatusReady":"'		+ isnull(@PGStatusReady,'Unknown') +
									'","@PGStatusComplete":"'	+ isnull(@PGStatusComplete,'Unknown') +
									'","@pPGId":"'				+ cast(isnull(@pPGId,-1) as varchar(20)) +
									'","@pPGBId":"'				+ cast(isnull(@pPGBId,-1) as varchar(20)) +
									'","@pPGBatchSeq":"'		+ cast(isnull(@pPGBatchSeq,-1) as varchar(20)) +'"}'

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	select	 @JSONSnippet		= NULL

	if @pVerbose = 1
	begin
		print ' ********View Grid '
		print 'select * from @PostingGroupParents'
--		select 'PostingGroupParents' As TableName, * from @PostingGroupParents
	end 

	if @Rows = 0  and not exists (select top 1 1 from @PostingGroupReady)
	begin
		if @pVerbose = 1
		begin
			print ' **********'
			print ' No parent processes are ready to run'
			print ' **********'
		end 
		return  -- This is a big EXIT
	end

	select	 @StepName			= 'Child process completion check'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'insert'
			,@StepDesc			= 'find all the children of the parent and make sure their status is complete.'

	insert	 into @PostingGroupReady (
			 PostingGroupId
			,TotalCount
			,ReadyCount
			,ChildPostingGroupId) 
	select	 distinct
			 dep.ParentId  
			,count(1) over (partition by  dep.ParentId)  TotalCount
			,sum(case 
				when rs.StatusCode			= @PGStatusComplete then 1 
				else						  0 
				end) over (partition by		  dep.ParentId) ReadyCount
			,par.ChildId
	from		 @PostingGroupParents		  par
	join	  pg.PostingGroupDependency		  dep
	on		 par.ParentId					= dep.ParentId
	left join pg.PostingGroupProcessing		  pgp
	on		 dep.ChildId					= pgp.PostingGroupId
	and		 pgp.PostingGroupBatchId		= @pPGBId -- Only get data from today's process.
	and		 pgp.PGPBatchSeq				= @pPGBatchSeq
	left join pg.RefStatus					  rs            -- Child's Status
	on		  rs.StatusId					= pgp.PostingGroupStatusId

--select '@PostingGroupParents', * from 	@PostingGroupParents
--select '@PostingGroupReady  ' , * from @PostingGroupReady

	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			,@JSONSnippet		= '{"@PGStatusComplete":"'		+ cast(isnull(@PGStatusComplete,'-1') as varchar(20)) +
									'","@pPGId":"'				+ cast(isnull(@pPGId,-1) as varchar(20)) +
									'","@pPGBId":"'				+ cast(isnull(@pPGBId,-1) as varchar(20)) +
									'","@pPGBatchSeq":"'		+ cast(isnull(@pPGBatchSeq,-1) as varchar(20)) + 
									'","@ExecutingPostingGroupId":"'		+ cast(isnull(@ExecutingPostingGroupId,'-1') as varchar(20)) +
									'","@ExecutingChildPostingGroupId":"'	+ cast(isnull(@ExecutingChildPostingGroupId,'-1') as varchar(20)) + '"}'

	exec audit.usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	select	 @JSONSnippet		= NULL

	if @pVerbose = 1
	begin
		print ' ********View Grid '
		print 'select * from @PostingGroupReady'
		select '@PostingGroupReady' As TableName
			,PostingGroupReadyId
			,PostingGroupId
			,TotalCount
			,ReadyCount
			,ChildPostingGroupId	
	   from @PostingGroupReady
	end 

/******************************************************************************

We now have a complete list of processes that need to run. 
1) All Posting Groups that have no requirements.
2) All Posting Groups that have had their requirements met.
Loop through all the posting groups and set the status to Queued 'PQ'
so other instances of this stored procedure do not run the same processes.

******************************************************************************/

	select	 @StepName			= 'Execute Posting Groups'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'loop'
			,@StepDesc			= 'Loop though all posting groups and execute each one.'


	select   @LoopMax			= isnull(max(PostingGroupReadyId),-1)
	from     @PostingGroupReady

		-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			,@JSONSnippet		= '{"Loop Count":"' + cast(isnull(@LoopMax,-1) as varchar(10)) + '"}' -- Only if needed.

	exec audit.usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	select	 @JSONSnippet		= NULL


	-- priming the while loop to inspect all children.

	while	 @LoopCount			<= @LoopMax  
	begin

		select	 @StepName			= 'Priming parameters for the while loop.'
				,@StepNumber		= @StepNumber + 0
				,@SubStepNumber     = @StepNumber + '.' + cast(@LoopCount as varchar(10)) + '.1'
				,@StepOperation		= 'loop'
				,@StepDesc			= 'Gathering variable values. Check JSON for specifics.'

		select 
				 @SSISFolder					= PG.SSISFolder
				,@SSISProject					= PG.SSISProject
				,@SSISPackage					= PG.SSISPackage
				,@DataFactoryName				= PG.DataFactoryName
				,@DataFactoryPipeline			= PG.DataFactoryPipeline
				,@JobName						= PG.JobName
				,@TotalCount					= PGCR.TotalCount
				,@ReadyCount					= PGCR.ReadyCount
				,@ExecutingPostingGroupId		= PGCR.PostingGroupId
				,@ExecutingChildPostingGroupId	= PGCR.ChildPostingGroupId
				,@CurrentNextExecutionDtm		= PG.NextExecutionDtm
				--,@TriggerType					= PG.TriggerType
				,@IntervalCode					= PG.IntervalCode
				,@IntervalLength				= PG.IntervalLength
				,@ParentProcessingMethodCode	= PG.ProcessingMethodCode
				,@ParentProcessingModeCode		= PG.ProcessingModeCode
		from     @PostingGroupReady				  PGCR
		join     pg.PostingGroup				  PG
		on       pg.PostingGroupId				= PGCR.PostingGroupId
		where    PostingGroupReadyId			= @LoopCount
		and      TotalCount						= ReadyCount

			-- Upon completion of the step, log it!
		select	 @PreviousDtm		= @CurrentDtm
				,@Rows				= @@ROWCOUNT 
		select	 @CurrentDtm		= getdate()
				,@JSONSnippet		= '{"@SSISFolder":"'			+ isnull(@SSISFolder,'Unknown')  +
									'","@SSISProject":"'			+ isnull(@SSISProject,'Unknown') +
									'","@SSISPackage":"'			+ isnull(@SSISPackage,'Unknown') +
									'","@TotalCount":"'				+ cast(isnull(@TotalCount,-1) as varchar(20)) +
									'","@ReadyCount":"'				+ cast(isnull(@ReadyCount,-1) as varchar(20)) +
									'","@ExecutingPostingGroupId":"'+ cast(isnull(@ExecutingPostingGroupId,-1) as varchar(20)) +
									'","@ExecutingChildPostingGroupId":"'	+ cast(isnull(@ExecutingChildPostingGroupId,-1) as varchar(20)) +'"}'

		exec audit.usp_InsertStepLog
				 @MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
				,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
				,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
				,@pVerbose

		select	 @JSONSnippet		= NULL

		-- Only take action if all child commitments are met.
		if @TotalCount = @ReadyCount

		begin try
			-- Add the posting group processing record.
			select	 @CurPGPBatchSeq			= isnull(max(PGPBatchSeq),0)
			from	 pg.PostingGroupProcessing	  pgp
			where	 pgp.PostingGroupBatchId	= @pPGBId
			and		 pgp.PostingGroupId			= @ExecutingPostingGroupId

			select	 @NextPGPBatchSeq	= @CurPGPBatchSeq + 1

			select	 @StepName			= 'Insert Posting Group Processing records.'
					,@StepNumber		= @StepNumber + 0
					,@SubStepNumber     = @StepNumber + '.' + cast(@LoopCount as varchar(10)) + '.2'
					,@StepOperation		= 'insert'
					,@StepDesc			= 'If the posting group processing does not already exist add it.'

			insert into pg.PostingGroupProcessing (
					 [PostingGroupId]
					,[PostingGroupBatchId]
					,[PostingGroupStatusId]
					,[DateId]
					,PGPBatchSeq
					,SrcBatchSeq
					,ProcessingModeCode
					,[CreatedDtm]
					,[CreatedBy])
			select 
					 pg.PostingGroupId
					,@pPGBId
					,@PGStatusReadyId
					,@DateId
					,@NextPGPBatchSeq 
					,-1 --@pSrcBatchSeq
					,pg.ProcessingModeCode  --maybe use this :: @ParentProcessingMethodCode $$$$
					,@CreatedDtm
					,@CreatedBy
			from	pg.PostingGroup						  pg
			where	pg.IsActive							= 1
			and		pg.PostingGroupId					= @ExecutingPostingGroupId
			and exists (
				select	 top 1 1 
				from	 pg.PostingGroupProcessing		  pgp
				where	 pgp.PostingGroupBatchId		= @pPGBId
				and		 pgp.PostingGroupId				= @ExecutingChildPostingGroupId
				and		 pgp.PGPBatchSeq				= @NextPGPBatchSeq )

			select	 @Rows								= @@ROWCOUNT 

			select	 @PostingGroupProcessingIdToExecute = pgp.PostingGroupProcessingId
					,@PostingGroupCodeToExecute			= pg.PostingGroupCode
			from	 pg.PostingGroupProcessing			  pgp
			join	 pg.PostingGroup					  pg
			on		 pg.PostingGroupId					= pgp.PostingGroupId
			where	 pgp.PostingGroupId					= @ExecutingPostingGroupId
			and		 pgp.PostingGroupBatchId			= @pPGBId
			and		 pgp.PostingGroupStatusId			= @PGStatusReadyId
			and		 pgp. PGPBatchSeq					= @NextPGPBatchSeq

			-- Upon completion of the step, log it!
			select	 @PreviousDtm		= @CurrentDtm

			select	 @CurrentDtm		= getdate()
					,@JSONSnippet		= '{"@CurPGPBatchSeq":"'	+ cast(isnull(@CurPGPBatchSeq,-1) as varchar(20)) +
										'","@NextPGPBatchSeq":"'	+ cast(isnull(@NextPGPBatchSeq,-1)  as varchar(20))+
										'","@pPGBId":"'				+ cast(isnull(@pPGBId,-1) as varchar(20)) +
										'","@DateId":"'				+ cast(isnull(@DateId,-1) as varchar(20)) +
										'","@PostingGroupProcessingIdToExecute":"'	+ cast(isnull(@PostingGroupProcessingIdToExecute,-1) as varchar(20)) +
										'","@ProcessingMethodCode":"'				+ isnull(@ParentProcessingMethodCode,'Unknown') +
										'","@CreatedDtm":"'			+ cast(isnull(@CreatedDtm,'01-jan-1900') as varchar(20)) +
										'","@CreatedBy":"'			+ isnull(@CreatedBy,'Unknown') + '"}'

			exec audit.usp_InsertStepLog
					 @MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
					,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
					,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
					,@pVerbose

			select	 @JSONSnippet		= NULL

			-- Move to the next item in loop if it is not triggered immediately and NextExecutionDtm is greater than Current Date
			--IF (@TriggerType = 'Interval' AND @CurrentNextExecutionDtm > @CurrentDtm)
			IF (@IntervalCode <> @IntervalCodeImmediate AND @CurrentNextExecutionDtm > @CurrentDtm)
			BEGIN

				select	 @StepName			= 'Should Posting Group Run'
						,@StepNumber		= @StepNumber + 0
						,@SubStepNumber     = @StepNumber + '.' + cast(@LoopCount as varchar(10)) + '.3'
						,@StepOperation		= 'if'
						,@StepDesc			= 'Determine if the posting group should run or if it needs to wait for a bit.'

				select	 @LoopCount			= @LoopCount + 1
						,@SSISFolder		= 'N/A'
						,@SSISProject		= 'N/A'
						,@SSISPackage		= 'N/A'
						,@TotalCount		= -1
						,@ReadyCount		= -2
						,@ExecutingPostingGroupId		= -1
						,@ExecutingChildPostingGroupId	= -1
						,@CurPGPBatchSeq	= -1
						,@NextPGPBatchSeq	= -1

				select	 @PreviousDtm		= @CurrentDtm

				select	 @CurrentDtm		= getdate()
						,@JSONSnippet		= '{"@NextPGPBatchSeq":"'	+ cast(isnull(@NextPGPBatchSeq,-1) as varchar(20)) +
											'","@PGStatusReady":"'		+ cast(isnull(@PGStatusReady,-1)  as varchar(20))+
											'","@pPGBId":"'				+ cast(isnull(@pPGBId,-1) as varchar(20)) +
											'","@IntervalCode":"'		+ cast(isnull(@IntervalCode,-1)  as varchar(20))+
											'","@CurrentNextExecutionDtm":"'+ cast(isnull(@CurrentNextExecutionDtm,-1) as varchar(20)) +
											'","@CurrentDtm":"'				+ cast(isnull(@CurrentDtm,-1) as varchar(20)) +
											'","@ExecutingPostingGroupId":"'+ cast(isnull(@ExecutingPostingGroupId,-1) as varchar(20)) + '"}'
				exec audit.usp_InsertStepLog
						 @MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
						,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
						,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
						,@pVerbose

				select	 @JSONSnippet		= NULL
				
				CONTINUE -- This breaks us out of the while loop. But there is no way this will try again when the correct time passes.
			END
			
			--Calculate NextExecutionDtm
			select @NextExecutionDtm = (select [dbo].[fn_CalculateNextExecutionDtm](@CurrentDtm, @CurrentNextExecutionDtm, @IntervalCode, @IntervalLength))

			begin transaction PostingGroup
			-- Check to ensure the status has not change.

			select @PGCurrentStatus = [pg].[fn_GetPostingGroupProcessingStatus](@ExecutingPostingGroupId,@pPGBId,@NextPGPBatchSeq)

			if @pVerbose = 1
				begin
					print [pg].[fn_GetPostingGroupProcessingStatus](@ExecutingPostingGroupId,@pPGBId,@NextPGPBatchSeq)
				end

			if @PGCurrentStatus <> @PGStatusReady
				begin
					rollback transaction PostingGroup
				end
			else -- Status for record is set to ready.
				begin 						
					--Find out the Next Expected Execution Runtime for PostingGroup
					UPDATE	pg.PostingGroup
					SET		NextExecutionDtm	= @NextExecutionDtm
					WHERE	PostingGroupId		= @ExecutingPostingGroupId

					--If it needs to be fired immediately
					IF (@IntervalCode = @IntervalCodeImmediate)
					BEGIN
						select	 @StepName			= 'Queue Posting Group'
								,@StepNumber		= @StepNumber + 0
								,@SubStepNumber     = @StepNumber + '.' + cast(@LoopCount as varchar(10)) + '.3'
								,@StepOperation		= 'update'
								,@StepDesc			= 'Set the posting group to queued.'

						update	 pgp
						set		 pgp.PostingGroupStatusId = (	select	StatusId 
																from    pg.RefStatus
																where   StatusCode		= @PGStatusQueued)
								,StartTime					= @CreatedDtm
								,pgp.ModifiedBy				= @CreatedBy
								,pgp.ModifiedDtm			= @CurrentDtm
						from	 pg.PostingGroupProcessing	  pgp
						join	 pg.RefStatus				  rs
						on		 pgp.PostingGroupStatusId	= rs.StatusId
						where	 pgp.PostingGroupBatchId	= @pPGBId
						and		 pgp.PostingGroupId			= @ExecutingPostingGroupId
						and		 rs.StatusCode				= @PGStatusReady
						and		 pgp.PGPBatchSeq			= @NextPGPBatchSeq

						select	 @PreviousDtm		= @CurrentDtm

						select	 @CurrentDtm		= getdate()
								,@JSONSnippet		= '{"@NextPGPBatchSeq":"'	+ cast(isnull(@NextPGPBatchSeq,-1) as varchar(20)) +
													'","@PGStatusReady":"'		+ cast(isnull(@PGStatusReady,-1)  as varchar(20))+
													'","@pPGBId":"'				+ cast(isnull(@pPGBId,-1) as varchar(20)) +
													'","@ExecutingPostingGroupId":"'	+ cast(isnull(@ExecutingPostingGroupId,-1) as varchar(20)) + '"}'

						exec audit.usp_InsertStepLog
								 @MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
								,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
								,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
								,@pVerbose

						select	 @JSONSnippet		= NULL
					END -- IF (@IntervalCode = @IntervalCodeImmediate)

					--Update all the PostingGroup records in status PI for the PostingGroup which is not triggered 
					--immediately and NextExecutionDtm is in the past
					--IF (@TriggerType = 'Interval' AND @CurrentNextExecutionDtm <= @CurrentDtm)
					ELSE IF (@IntervalCode <> @IntervalCodeImmediate AND @CurrentNextExecutionDtm <= @CurrentDtm)
					BEGIN
						select	 @StepName			= 'Queue Posting Group'
								,@StepNumber		= @StepNumber + 0
								,@SubStepNumber     = @StepNumber + '.' + cast(@LoopCount as varchar(10)) + '.3'
								,@StepOperation		= 'update'
								,@StepDesc			= 'Set the posting group to queued.'

						update	 pgp
						set		 pgp.PostingGroupStatusId = (select   StatusId 
															 from     pg.RefStatus
															 where    StatusCode		= @PGStatusQueued)
								,StartTime					= @CreatedDtm
								,pgp.ModifiedBy				= @CreatedBy
								,pgp.ModifiedDtm			= @CurrentDtm
						from	 pg.PostingGroupProcessing	  pgp
						join	 pg.RefStatus				  rs
						on		 pgp.PostingGroupStatusId	= rs.StatusId
						where	 pgp.PostingGroupId			= @ExecutingPostingGroupId
						and		 rs.StatusCode				= @PGStatusReady
						and		 pgp.CreatedDtm				> DATEADD(mi,DATEDIFF(mi,@CurrentNextExecutionDtm,@NextExecutionDtm) * -1,@CurrentNextExecutionDtm)

						select	 @PreviousDtm		= @CurrentDtm

						select	 @CurrentDtm		= getdate()
								,@JSONSnippet		= '{"@NextPGPBatchSeq":"'	+ cast(isnull(@NextPGPBatchSeq,-1) as varchar(20)) +
													'","@PGStatusReady":"'		+ cast(isnull(@PGStatusReady,-1)  as varchar(20))+
													'","@pPGBId":"'				+ cast(isnull(@pPGBId,-1) as varchar(20)) +
													'","@ExecutingPostingGroupId":"'	+ cast(isnull(@ExecutingPostingGroupId,-1) as varchar(20)) + '"}'

						exec audit.usp_InsertStepLog
								 @MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
								,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
								,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
								,@pVerbose

						select	 @JSONSnippet		= NULL
					END  -- (@IntervalCode <> @IntervalCodeImmediate AND @CurrentNextExecutionDtm <= @CurrentDtm)
					ELSE 
					BEGIN -- Just logging the failure.
						/*
						print 'WE FAILED'
						print 'IntervalCode: ' +isnull(cast(@IntervalCode as varchar(200)),'NULL')
						print '@IntervalCodeImmediate: ' +isnull(cast(@IntervalCodeImmediate as varchar(200)),'NULL')
						print '@CurrentNextExecutionDtm: ' +isnull(cast(@CurrentNextExecutionDtm as varchar(200)),'NULL')
						print '@CurrentDtm: ' +isnull(cast(@CurrentDtm as varchar(200)),'NULL')
						*/

						select	 @StepName			= 'Queue Posting Group'
								,@StepNumber		= @StepNumber + 0
								,@SubStepNumber     = @StepNumber + '.' + cast(@LoopCount as varchar(10)) + '.3'
								,@StepOperation		= 'error'
								,@StepDesc			= 'Posting Group Failed to Queue.'

						-- Do nothing just log.
						-- Upon completion of the step, log it!
						select	 @PreviousDtm		= @CurrentDtm
								,@StepStatus		= 'failure'

						select	 @CurrentDtm		= getdate()
								,@JSONSnippet		= '{"IntervalCode: "' + isnull(cast(@IntervalCode as varchar(200)),'NULL') +
													'","@IntervalCodeImmediate":" ' + isnull(cast(@IntervalCodeImmediate as varchar(200)),'NULL') +
													'","@CurrentNextExecutionDtm":" ' + isnull(cast(@CurrentNextExecutionDtm as varchar(200)),'NULL') +
													'","@NextPGPBatchSeq":"'	+ cast(isnull(@NextPGPBatchSeq,-1) as varchar(20)) +
													'","@PGStatusReady":"'		+ cast(isnull(@PGStatusReady,-1)  as varchar(20))+
													'","@pPGBId":"'				+ cast(isnull(@pPGBId,-1) as varchar(20)) +
													'","@ExecutingPostingGroupId":"'	+ cast(isnull(@ExecutingPostingGroupId,-1) as varchar(20)) + 
													'","@CurrentDtm":" ' + isnull(cast(@CurrentDtm as varchar(200)),'NULL')+ '"}'

						exec audit.usp_InsertStepLog
								 @MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
								,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
								,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
								,@pVerbose

						select	 @JSONSnippet		= NULL
								,@StepStatus		= 'success'
					
					END -- ELSE
					commit transaction PostingGroup

					print 'exec [pg].[usp_ExecuteProcess]
						 @pPostingGroupProcessingId				= ' + isnull(cast(@PostingGroupProcessingIdToExecute as varchar(20)),'NULL') + @CRLF +
						',@pIssueId								= -1' + @CRLF +
						',@pProcessStatus						= ' + @ProcessStatus +' output' +  @CRLF 

					select	 @StepName			= 'Execute Process'
							,@StepNumber		= @StepNumber + 0
							,@SubStepNumber     = @StepNumber + '.' + cast(@LoopCount as varchar(10)) + '.3'
							,@StepOperation		= 'execute'
							,@StepDesc			= 'Execute Posting Group Processing Id:'  + cast(@PostingGroupProcessingIdToExecute as varchar(12))

					exec [pg].[usp_ExecuteProcess]
						 @pPostingGroupProcessingId				= @PostingGroupProcessingIdToExecute
						,@pIssueId								= -1 -- No issue date neeeds to be sent.
						/*
						,@pProcessingMethodCode					= @ParentProcessingMethodCode
						,@pSSISFolder							= @SSISFolder
						,@pSSISProject							= @SSISProject
						,@pSSISPackage							= @SSISPackage
						,@pSSISParameters						= @SSISParameters
						,@pDataFactoryName						= @DataFactoryName
						,@pDataFactoryPipeline					= @DataFactoryPipeline
						,@pSQLJobName							= @JobName
						*/
						,@pAllowMultipleInstances				= @AllowMultipleInstances
						,@pExecuteProcessStatus					= @ExecuteProcessStatus	output


					exec audit.usp_InsertStepLog
								@MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
							,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
							,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
							,@pVerbose

				end
		end try

		begin catch
			-- In this instance we want to log the error however we 
			-- still want to fire other parent jobs so allow the loop to continue.
			-- Note: the loop will continue even if 1 job fails to fire
			--       each job that could fire will be attempted.
			-- why is this a throw and not a continue...?? doesn't lign up with comment. ^
			select 	 @PreviousDtm		= @CurrentDtm
					,@ErrNum			= @@ERROR
					,@ErrMsg			= ERROR_MESSAGE()
					,@Rows				= 0
					,@MessageType		= 'ErrSQL'

			select	 @StepStatus		= 'Failure'
					,@CurrentDtm		= getdate()

			select	 @ErrMsg = @ErrMsg + @CRLF + 'ErrNum: ' +  cast(@ErrNum as varchar(20)) + @CRLF + ERROR_MESSAGE() + @CRLF + @SSISPackage + ' not able to fire. '+ @CRLF + @ParametersPassedChar
			
			if 	@ErrNum < 50000	
				select	 @ErrNum	= @ErrNum + 1000000 -- Need to increase number to throw message.

			;throw	 @ErrNum, @ErrMsg, 1
		end catch

		select	 @LoopCount							= @LoopCount + 1
				,@SSISFolder						= 'N/A'
				,@SSISProject						= 'N/A'
				,@SSISPackage						= 'N/A'
				,@DataFactoryName					= 'N/A'
				,@DataFactoryPipeline				= 'N/A'
				,@TotalCount						= -1
				,@ReadyCount						= -2
				,@ExecutingPostingGroupId			= -1
				,@ExecutingChildPostingGroupId		= -1
				,@CurPGPBatchSeq					= -1
				,@NextPGPBatchSeq					= -1
				,@PostingGroupProcessingIdToExecute	= -1
				,@PostingGroupCodeToExecute			= 'UNK'
	end -- while loop


	if @pVerbose = 1
	begin
		print ' ******** '
		print 'Completed sproc ' + OBJECT_NAME(@@PROCID)
		print 'Transaction Count: ' + isnull(cast(@@TranCount as varchar(200)),'NULL')
	end 
/*
		-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			--,@JSONSnippet		= '{"":"' + @myvar + '"}' -- Only if needed.

	exec audit.usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	select	 @JSONSnippet		= NULL
*/
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

	if		 @@trancount > 1
		rollback transaction

	if		 @MessageType		<> 'ErrCust'
		select   @MessageType	= 'ErrSQL'

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

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

20161021	ffortunato		Time for some legit error handling and making sure 
							parent is incomplete.

20161202	jprom			Added a verbose parameter
							Set @pPGBId as a nullable option
							Set @pPGId as a nullable option

20161205	ffortunato		allowing the processing to kick off process with 
							no dependencies.

20161205	ffortunato		new error handling.

20180731	ffortunato		new changes for adhoc processing inserts.
							this is a big gnraly change. 
							also removing non dependent section of code.

20180802	ffortunato		more PGP inserts bit o batch seq as well.

20180806	ffortunato		Check the child batch sequ3eence before you add 
							a parent with a subsequent batch sequence.

20180910	ffortunato		Lots more logging. Fixing status code logic.

20180918	ffortunato		updating start time
							removing old commented out code.

20180924	ffortunato		Getting procs together to fire SSIS.

20181002	ffortunato		Improving Logging.

20181004	ffortunato		fn_* now requires the sequence number as well.

20181016	jsardina		added @ServerName variable to be used in SSISDB Catalog setup

20190812	ochowkwale		Compatibility with Azure Data Factory.
							Must not execute SSIS package.

20200725	ochowkwale		NextExecutionDtm functionality for Posting Group process

20201022	ochowkwale		Adding the check for IsActive field

202011118	ffortunato		cleaning up warnings. Its my birthday. Move SSIS
							calls to another proc

202011118	ffortunato		small fix to step logging.

20210212	ffortunato		Ability to call SQL Server agent job.
							Adding Mode Code so we know if running NORM, HIST.

20210407	ffortunato		This thing should be able to call data factory too.

20210413	ffortunato		Generic call to processes.

20215026	ffortunato		BIG ELSE.
******************************************************************************/



--leaving this here for postarity for a bit.
/*

					insert into	@SSISParameters values (@ObjectType,'pkg_PostingGroupId',		@ExecutingPostingGroupId)
					insert into	@SSISParameters values (@ObjectType,'pkg_PostingGroupBatchSeq',	@NextPGPBatchSeq)
					insert into	@SSISParameters values (@ObjectType,'pkg_PostingGroupBatchId',	@pPGBId)

					IF (@ParentProcessingMethodCode = 'SSIS')
					BEGIN
						-- Note when calling the next package Batch and Posting Group must be sent as well.
						select	 @StepName			= 'Execute Posting Group'
								,@StepNumber		= @StepNumber + 0
								,@SubStepNumber		= @StepNumber + '.' + cast(@LoopCount as varchar(10)) + '.3'
								,@StepOperation		= 'execute'
								,@StepDesc			= 'Execute SSIS Package: ' + @SSISPackage

					-- pretend execution   COMMENT THIS print OUT WHEN YOU WANT TO KICK THINGS OFF.
					
					print 'execute '	+ isnull(@SSISPackage, 'BAD RESULT') 
										+ ' PostingGroupBatchId:='	+ cast(@pPGBId as varchar) 
										+ ' ParentPostingGroupId='	+ cast(@ExecutingPostingGroupId as varchar(20))
										+ ' ChildPostingGroupId='	+ cast(@pPGId as varchar(20))
										+ ' Cur Sequence Number='	+ cast(@CurPGPBatchSeq as varchar(20))
										+ ' Next Sequence Number='	+ cast(@NextPGPBatchSeq as varchar(20))
										+ ' @SSISProject='	+ @SSISProject
										+ ' @ServerName='	+ @ServerName
										+ ' @SSISFolder='	+ @SSISFolder
										+ ' @SSISPackage='	+ @SSISPackage
					

						insert into	@SSISParameters values (@ObjectType,'pkg_PostingGroupId',		@ExecutingPostingGroupId)
						insert into	@SSISParameters values (@ObjectType,'pkg_PostingGroupBatchSeq',	@NextPGPBatchSeq)
						insert into	@SSISParameters values (@ObjectType,'pkg_PostingGroupBatchId',	@pPGBId)
						
						--insert into	@SSISParameters values (@ObjectType,'pkg_PostingGroupMethod',	@PostingGroupMethod)    $$$$ NEver pass method becuase it know what was called
						--insert into	@SSISParameters values (@ObjectType,'pkg_PostingGroupMode',		@PostingGroupMode)  -- Passing mode to determin how I should run. This can be picked up by the ETL instead.
/*
						exec pg.usp_ExecuteSSISPackage 
								 @pSSISProject		= @SSISProject
								,@pServerName		= @ServerName
								,@pSSISFolder		= @SSISFolder
								,@pSSISPackage		= @SSISPackage
								,@pSSISParameters	= @SSISParameters
								,@pETLExecutionId	= @pETLExecutionId
								,@pPathId			= @pPathId
								,@pVerbose			= @pVerbose
*/
						select	 @PreviousDtm		= @CurrentDtm
								,@Rows				= @@ROWCOUNT 
						select	 @CurrentDtm		= getdate()
								,@JSONSnippet		= '{"@SSISFolder":"'	+ @SSISFolder  + '",'
													+  '"@SSISProject":"'	+ @SSISProject + '",'
													+  '"@SSISPackage":"'	+ @SSISPackage + '",'
													+  '"@TotalCount":"'	+ cast(@TotalCount as varchar(20)) + '",'
													+  '"@ReadyCount":"'	+ cast(@ReadyCount as varchar(20)) + '",'
													+  '"@PostingGroupBatchId":"'	+ cast(@pPGBId as varchar(20)) + '",'
													+  '"@PGPBatchSeq":"'	+ cast(@CurPGPBatchSeq as varchar(20)) + '",'
													+  '"@ExecutingPostingGroupId Parent":"'+ cast(@ExecutingPostingGroupId as varchar(20))  + '",'
													+  '"@ChildPostingGroupId Child":"'+ cast(@pPGId as varchar(20))  + '",'
													+  '"@CurPGPBatchSeq Parent":"'+ cast(@CurPGPBatchSeq as varchar(20))  + '",'
													+  '"@NextPGPBatchSeq Child":"'+ cast(@NextPGPBatchSeq as varchar(20))  + '",'
													+  '"@ExecutionId":"'	+ cast(@ExecutionId as varchar(20)) + '",'
													+  '"@ReferenceId":"'	+ cast(@ReferenceId as varchar(20))+ '"}' 	

						exec audit.usp_InsertStepLog
								 @MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
								,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
								,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
								,@pVerbose

						select	 @JSONSnippet		= NULL
					END -- Call SSIS Package
					ELSE IF (@ParentProcessingMethodCode = 'ADFP')    --$$$$ Get me in coach.
					begin

						-- Note when calling the next package Batch and Posting Group must be sent as well.
						select	 @StepName			= 'Execute Posting Group ADFP'
								,@StepNumber		= @StepNumber + 0
								,@SubStepNumber		= @StepNumber + '.' + cast(@LoopCount as varchar(10)) + '.3'
								,@StepOperation		= 'execute'
								,@StepDesc			= 'Execute Azure Data Factory Pipeline: '

						print 'execute  [pg].[usp_ExecuteDataFactory]'										+ @CRLF
										+ ' @pDataFactoryName		= '''	+ @DataFactoryName		+ ''''	+ @CRLF
										+ ' @pDataFactoryPipeline	= '''	+ @DataFactoryPipeline	+ ''''	+ @CRLF
										+ ' @pStatus				= @DataFactoryStatus  output'			+ @CRLF
										+ ' PostingGroupBatchId:'	+ cast(@pPGBId as varchar) 
										+ ' ParentPostingGroupId:'	+ cast(@ExecutingPostingGroupId as varchar(20))
										+ ' ChildPostingGroupId:'	+ cast(@pPGId as varchar(20))
										+ ' Cur Sequence Number:'	+ cast(@CurPGPBatchSeq as varchar(20))
										+ ' Next Sequence Number:'	+ cast(@NextPGPBatchSeq as varchar(20))
/*
						-- We are assuming that we can get the posting group processing id from within the job.
						EXEC	 [pg].[usp_ExecuteDataFactory] 
								 @pDataFactoryName		= @DataFactoryName
								,@pDataFactoryPipeline	= @DataFactoryPipeline
								,@pStatus				= @DataFactoryStatus output
								,@pETLExecutionId		= -1
								,@pPathId				= -1
								,@pVerbose				= 0
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
					ELSE IF (@ParentProcessingMethodCode = 'SQLJ')    --$$$$ Get me in coach.
					begin

						-- Note when calling the next package Batch and Posting Group must be sent as well.
						select	 @StepName			= 'Execute Posting Group'
								,@StepNumber		= @StepNumber + 0
								,@SubStepNumber		= @StepNumber + '.' + cast(@LoopCount as varchar(10)) + '.3'
								,@StepOperation		= 'execute'
								,@StepDesc			= 'Execute SQL Server Job: ' + @JobName

						-- We are assuming that we can get the posting group processing id from within the job.
						EXEC	 @JobReturnCode		= msdb.dbo.sp_start_job 
									@job_name		= @JobName

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
					else -- Unable to find anything to run.
					begin
						select	 @StepName			= 'Unable to Execute Posting Group'
								,@StepNumber		= @StepNumber + 0
								,@SubStepNumber		= @StepNumber + '.' + cast(@LoopCount as varchar(10)) + '.3'
								,@StepOperation		= 'warning'
								,@StepDesc			= 'Unknown execution type' + @JobName

						-- Upon completion of the step, log it!
						select	 @PreviousDtm		= @CurrentDtm
								,@Rows				= @@ROWCOUNT 
						select	 @CurrentDtm		= getdate()

						exec audit.usp_InsertStepLog
								 @MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
								,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
								,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
								,@pVerbose
					end -- Bad else
*/