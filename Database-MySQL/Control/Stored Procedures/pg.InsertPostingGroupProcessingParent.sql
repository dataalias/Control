CREATE PROCEDURE [pg].[InsertPostingGroupProcessingParent] (
		 @pPGChildId			int				= -1
		,@pPGBatchId			int				= -1
		,@pPGBatchSeq			int				= -1
		,@pETLExecutionId		int				= -1
		,@pPathId				int				= -1
		,@pVerbose				bit				= 0)
AS
/******************************************************************************
File:		InsertPostingGroupProcessingParent.sql
Name:		InsertPostingGroupProcessingParent

Purpose:	

exec		pg.[InsertPostingGroupProcessingParent] 
		 @pPGChildId			= -1
		,@pPGBatchId			= -1
		,@pPGBatchSeq			= -1
		,@pETLExecutionId		= -1
		,@pPathId				= -1
		,@pVerbose				= 0

Parameters:     

Called By:	Job
Calls:		n/a

Author:		ffortunato
Date:		20180731

To Do:		Calculate thresholds.


*******************************************************************************
Change History
*******************************************************************************
date		author			description
--------	-------------	---------------------------------------------------
20180731	ffortunato		initial iteration

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
		,@ProcessType			varchar(10)		= 'Proc'
		,@StepName				varchar(256)	= 'Start'
		,@StepOperation			varchar(50)		= 'N/A' 
		,@MessageType			varchar(20)		= 'Info' -- ErrCust, ErrSQL, Info, Warn
		,@StepDesc				nvarchar(2048)	= 'Procedure started' 
		,@StepStatus			varchar(10)		= 'Success'
		,@StepNumber			varchar(10)		= 0
		,@Duration				varchar(10)		= 0
		,@JSONSnippet			nvarchar(max)	= NULL

		,@CreatedDate			datetime		= getdate()
		,@CreatedBy				varchar(50)		= cast(system_user as varchar(50))
		,@PGStatusCodeInitial	varchar(10)		= 'PI'
		,@PGStatusCodeQueued	varchar(10)		= 'PQ'
		,@PGStatusIdInitial		int				= -1
		,@PGStatusIdQueued		int				= -1
--		,@PGPSeq				
--		,@StatusId				int				= -1
		,@DateId				int				= -1
		,@CurrentBatchId		int				= -1
--		,@TotCnt				int				= -1
--		,@CompCnt				int				= -1
		,@PGParentId			int				= -1


declare  @PGParents				table(
		 PGParentsRowId			int identity (1,1)
		,PGChidId				int not null default -1
		,PGChildStatusId		int not null default -1
		,PGParentId				int not null default -1
		,PGParentStatusId		int not null default -1
		,PGParentSeq			int not null default -1
)

exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,-1	,-1				,@ParentStepLogId output	
		,0 --@pVerbose

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

SELECT	 @ParametersPassedChar	= 
			'exec ctl.usp_InsertPostingGroupProcessing' + @CRLF +
			'    @pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL')

if @pVerbose					= 1
begin
    print '**********'
    print 'Initialization' 
    print 'Executing Stored Procedure: ' + OBJECT_NAME(@@PROCID)
	print 'Parameters : ' + @ParametersPassedChar
	print 'Current Batch Id: ' + cast (@CurrentBatchId as varchar (200))
--	print 'Status Id: ' + cast (@StatusId as varchar (200)) + ' := '  + @StatusCode
	print '**********'
	print ''
end

-------------------------------------------------------------------------------
--  Main
-------------------------------------------------------------------------------

begin try

	select	 @StepName			= 'Initializations'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'select'
			,@StepDesc			= 'Priming variables.'


if @pPGBatchId = -1

	select   @CurrentBatchId         = isnull(max([PostingGroupBatchId]),-1)
	from     pg.PostingGroupBatch

else
	select	 @CurrentBatchId		 = isnull(max([PostingGroupBatchId]),-1)
	from     pg.PostingGroupBatch
	where	 PostingGroupBatchId	 = @pPGBatchId
         
select   @DateId                = cast(format(@CreatedDate,'yyyyMMdd') as int)

select	 @PGStatusIdInitial		= isnull(rs.StatusId,-1)
from	 pg.RefStatus			  rs
where	 StatusCode				= @PGStatusCodeInitial

select	 @PGStatusIdQueued	= isnull(rs.StatusId,-1)
from	 pg.RefStatus			  rs
where	 StatusCode				= @PGStatusCodeQueued

	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			--,@JSONSnippet		= '{"":"' + @myvar + '"}' -- Only if needed.

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	select	 @JSONSnippet		= NULL


if @pVerbose = 1
begin
    print '**********'
    print 'Initialization' 
    print 'Executing Stored Procedure: ' + OBJECT_NAME(@@PROCID)
	print 'Parameters : ' + @ParametersPassedChar
	print 'Current Batch Id: ' + cast (@CurrentBatchId as varchar (200))
--	print 'Status Id: ' + cast (@StatusId as varchar (200)) + ' := '  + @StatusCode
	print '**********'
	print ''
end

/******************************************************************************
If there are currently no records in the posting group go ahead and create the
initial entries to the table.
******************************************************************************/

if @CurrentBatchId				= -1
begin

	INSERT INTO pg.[PostingGroupBatch]
		([DateId]
		,[CreatedBy]
		,[CreatedDtm])
	VALUES
		(@DateId
		,@createdBy
		,@CreatedDate)

	select   @CurrentBatchId	= isnull(max([PostingGroupBatchId]),-1)
	from     pg.PostingGroupBatch

end

-------------------------------------------------------------------------------
-- Check to see if the child record has a parent.
-------------------------------------------------------------------------------

	select	 @StepName			= 'Check for Child''s Parent'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'insert'
			,@StepDesc			= 'Check to see if the child record has a parent.'

	insert into @PGParents (
			  PGChidId
			 ,PGChildStatusId
			 ,PGParentId
			 ,PGParentStatusId
			 ,PGParentSeq)
	select
			 pgd.ChildId
			,-1 -- Don't think you need the child status yet we will get it when we look for all parent dependencies...
			,pgd.ParentId
			,-1 -- Assuming i dont care     isnull(pgp.PostingGroupStatusId,-1)
			,@pPGBatchSeq
	from		 pg.PostingGroupDependency	  pgd
--	left join	 pg.PostingGroupProcessing	  pgp
--	on		 pgd.ParentId					= pgp.PostingGroupId
	where	 pgd.ChildId					= @pPGChildId
--	and		 pgp.PostingGroupBatchId		= @CurrentBatchId


	if @pPGBatchSeq <= 0

		update	 par
		set		 par.PGParentSeq			= isnull(pro.PGPBatchSeq,0)+1
		from	 @PGParents par
		join	 pg.PostingGroupProcessing	  pro
		on		 par.PGParentId				= pro.PostingGroupId
		where	 pro.PostingGroupId			= par.PGParentId
		and		 pro.PostingGroupBatchId	= @CurrentBatchId

	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			,@JSONSnippet		= '{"pPGBatchSeq":"' + cast(@pPGBatchSeq as varchar(10)) + '"}' -- Only if needed.

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	select	 @JSONSnippet		= NULL


-------------------------------------------------------------------------------
-- Check to see if all child conditions are met.
-------------------------------------------------------------------------------

	select	 @StepName			= 'Insert parent records into PostingGroupProcessing'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'insert'
			,@StepDesc			= 'All parent records of the child posting group provided are added to the processing table.'


	if	exists (select top 1 1 from @PGParents)
	begin
		insert into pg.PostingGroupProcessing (
				 [PostingGroupId]
				,[PostingGroupBatchId]
				,[PostingGroupStatusId]
				,PGPBatchSeq
				,[DateId]
				,[CreatedDtm]
				,[CreatedBy])
		select 
				 PostingGroupId
				,@CurrentBatchId
				,@PGStatusIdInitial
				,PGParentSeq
				,@DateId
				,@CreatedDate
				,@CreatedBy
		from	 pg.PostingGroup		  pg
		join	 @PGParents				  pgp
		on		 pg.PostingGroupId		= pgp.PGParentId
		where	 pg.IsActive			= 1
		and not exists ( select top 1 1 
				 from	 pg.PostingGroupProcessing	  pgp2
				 where	 pgp2.PostingGroupId		= pgp.PGParentId
				 and	 pgp2.PostingGroupBatchId	= @CurrentBatchId 
				 and	 pgp2.PGPBatchSeq			= PGParentSeq )

		if @pVerbose				= 1
			begin
				print '**********'
				print 'Created initial entries for PostingGroupProcessing table.'
				print '**********'
			end
	end 

	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			--,@JSONSnippet		= '{"":"' + @myvar + '"}' -- Only if needed.

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	select	 @JSONSnippet		= NULL

	exec pg.ExecutePostingGroupProcessing 
			 @pPGBId				= @pPGBatchId
			,@pPGId					= null
			,@pETLExecutionId		= -1
			,@pPathId				= -1
			,@pVerbose				= 1


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
			,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,-1	,-1			,@PrevStepLog output
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
		 @MessageType		,@ProcessStartDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,-1	,-1			,@PrevStepLog output
		,0 --@pVerbose
