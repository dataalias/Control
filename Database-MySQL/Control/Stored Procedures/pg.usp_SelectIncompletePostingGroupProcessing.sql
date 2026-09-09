CREATE Procedure [pg].usp_SelectIncompletePostingGroupProcessing(
		 @pStartDtm						datetime		= NULL --'3001-JAN-01'
		,@pEndDtm						datetime		= NULL --'3001-JAN-02'
		,@pETLExecutionId				int				= -1
		,@pPathId						int				= -1
		,@pVerbose						bit				= 0
)as

/*****************************************************************************
file:           pg.usp_SelectIncompletePostingGroupProcessing.sql
name:           pg.usp_SelectIncompletePostingGroupProcessing
purpose:        Set status to appropriate value for the posting group.
				Note: Due to frequency of calls, this procedure is not logged
				in steplog.

exec pg.usp_SelectIncompletePostingGroupProcessing
		 @pStartDtm		= '3/10/2021'
		,@pEndDtm		= '3/19/2021'


parameters:   @pPostingGroupProcessing



called by:      php UpdatePosting Group Processing Page
calls:          

author:         ffortunato
date:           20210312


*******************************************************************************
      change history
*******************************************************************************
date      author         description
--------  -------------  ------------------------------------------------------

20210312  ffortunato     Initial Iteration
20210319  jprom			 Added ProcessingModeName and CreatedDtm
20210322  jprom			 Removed one of the step logs for now. This is breaking the PHP

******************************************************************************/

-------------------------------------------------------------------------------
--  declarations
-------------------------------------------------------------------------------
declare	 @Rows					int				= 0
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
		,@Duration				int				= 0
		,@JSONSnippet			nvarchar(max)	= NULL 
		,@PostingGoupFailure	varchar(5)		= 'PF'
		,@PostingGroupRetry		varchar(5)		= 'PR'
		,@Severity				int				= 0
		,@Project				varchar(50)		= 'N/A'
		,@Package				varchar(50)		= 'N/A'
		,@DataFactoryName		varchar(50)		= 'N/A'
		,@DataFactoryPipeline	varchar(50)		= 'N/A'
		,@Subject				varchar(255)	= 'N/A'
		,@From					varchar(255)	= 'N/A'
		,@Recipients			varchar(1000)	= 'N/A'
		,@Body					varchar(255)	= 'N/A'
		,@Servername			varchar(100)	= @@SERVERNAME
		,@PostingGroupProcessingId int			= 0
-- Procedure Specific Parameters     
		,@ModifiedDtm			datetime		= getdate()
		,@ModifiedBy			varchar(30)		= cast(system_user as varchar(30))
		,@StatusId				int				= -2
		,@StartDtm				datetime		= dateadd(d,-1,getdate())
		,@EndDtm				datetime		= getdate()

  
-------------------------------------------------------------------------------
--  initializations
-------------------------------------------------------------------------------
select	 @ParametersPassedChar   	  = 
      '***** Parameters Passed to exec pg.usp_SelectPostingGroupProcessing' + @CRLF +
      '     @pStartDtm = ''' + isnull(convert(varchar(100),@pStartDtm ,13) ,'NULL') + '''' + @CRLF + 
      '    ,@pEndDtm = ''' + isnull(convert(varchar(100),@pEndDtm ,13) ,'NULL') + '''' + @CRLF + 
      '    ,@pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pPathId = ' + isnull(cast(@pPathId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL') + @CRLF + 
      '***** End of Parameters' + @CRLF 
      
-------------------------------------------------------------------------------
--  main
-------------------------------------------------------------------------------

begin try

-------------------------------------------------------------------------------
--  If no records were updated we will throw an error to the calling proc.
-------------------------------------------------------------------------------

select	 @StepName				= 'Set variables.'
		,@StepNumber			= @StepNumber + 1
		,@StepOperation			= 'select'
		,@StepDesc				= 'Make sure all the date parameters are good.'




	if @pStartDtm	is null
		select	@StartDtm = dateadd(dd,-1,getdate())
	else
		select	@StartDtm = @pStartDtm

	if @pEndDtm		is null
		select	@EndDtm = getdate() 
	else
		select	@EndDtm = @pEndDtm

	if @EndDtm <= @StartDtm
	begin
		select   @ErrNum			= 50001
				,@MessageType		= 'ErrCust'
				,@ErrMsg			= 'EndDtm cannot be less than or equal StartDtm: '
								  
		; throw @ErrNum, @ErrMsg, 1  -- This is thrown to the catch block below.
	end

	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= GETDATE()
			,@JSONSnippet		= '{"StartDtm":"'+ isnull(cast(@StartDtm as varchar(20)),'<NULL>')+'","EndDtm":"'+ isnull(cast(@EndDtm as varchar(20)),'NULL')+'"}' -- Only if needed.

	------------------------------------------------------
	-- This breaks the PHP page for some reason
	------------------------------------------------------
	--exec [audit].usp_InsertStepLog
	--		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
	--		,@ParametersPassedChar					,@ErrMsg OUTPUT	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
	--		,@StepDesc OUTPUT	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog OUTPUT
	--		,@pVerbose;
	------------------------------------------------------

	select	 @JSONSnippet		= NULL

	select	 @StepName				= 'Select Incomplete Posting Group Processing'
			,@StepNumber			= @StepNumber + 1
			,@StepOperation			= 'select'
			,@StepDesc				= 'Return posting groups in date range'

	select	 pgp.PostingGroupProcessingId
			,pg.PostingGroupCode
			,pg.PostingGroupName
			,rs.StatusCode
			,rs.StatusName
			,pgp.ProcessingModeCode
			,pgm.ProcessingModeName
			,pgp.CreatedDtm
	from	 pg.PostingGroupProcessing	  pgp
	join	 pg.PostingGroup			  pg
	on		 pgp.PostingGroupId			= pg.PostingGroupId
	join	 pg.RefStatus				  rs
	on		 pgp.PostingGroupStatusId	= rs.StatusId
	join	 pg.RefProcessingMode		  pgm
	on		 pgp.ProcessingModeCode		= pgm.ProcessingModeCode
	where	 coalesce (pgp.ModifiedDtm,pgp.CreatedDtm) between @StartDtm and @EndDtm
	and		 rs.StatusCode not in ('PC','PQ')


	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= GETDATE()
			--,@JSONSnippet		= '<JSON Snippet>' -- Only if needed.

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar					,@ErrMsg OUTPUT	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc OUTPUT	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog OUTPUT
			,@pVerbose

	select	 @JSONSnippet		= NULL

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

	exec [audit].usp_CreateStepLogDescription 
			 @MessageType	,@CurrentDtm		,@CurrentDtm	,0		,@StepOperation		,@StepDesc		,@JSONSnippet		,@ErrNum
			,@ErrMsg		,@ParametersPassedChar				,0		,@StepDesc output	,@ErrMsg output	,@Duration output		
			,0	,0	,0

	if 	@ErrNum < 50000	
		select	 @ErrNum	= @ErrNum + 100000000 -- Need to increase number to throw message.

	;throw	 @ErrNum, @ErrMsg, 1
	
end catch
