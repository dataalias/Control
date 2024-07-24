CREATE Procedure [pg].usp_UpdatePostingGroupProcessing(
		 @pPostingGroupProcessingId		bigint			= -1
		,@pPostingGroupProcessingStatusCode	varchar(20)	= 'PR'
		,@pPostingGroupProcessingModeCode	varchar(20)	= 'RTRY'
		,@pETLExecutionId				int				= -1
		,@pPathId						int				= -1
		,@pVerbose						bit				= 0
)as

/*****************************************************************************
file:           pg.usp_UpdatePostingGroupProcessing.sql
name:           pg.usp_UpdatePostingGroupProcessing
purpose:        Set status to appropriate value for the posting group.
				Note: Due to frequency of calls this procedure is no logged in
				steplog.

exec pg.usp_UpdatePostingGroupProcessing
		 @pPostingGroupProcessingId				= 100001
		,@pPostingGroupProcessingStatusCode		= 'IF'
		,@pPostingGroupProcessingModeCode		= 'RTRY'


parameters:   @pPostingGroupProcessing



called by:      php UpdatePosting Group Processing Page
calls:          

author:         ffortunato
date:           2021182012


*******************************************************************************
      change history
*******************************************************************************
date      author         description
--------  -------------  ------------------------------------------------------

2021182012  ffortunato     Initial Iteration
20210327	ffortunato     Cleanup modified by / not dtm.

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

  
-------------------------------------------------------------------------------
--  initializations
-------------------------------------------------------------------------------
select	 @ParametersPassedChar   	  = @CRLF + '    Parameters Passed: ' + @CRLF +
						'@pPostingGroupProcessingId = '   + cast (@pPostingGroupProcessingId as varchar (20)) + ''''
      
-------------------------------------------------------------------------------
--  main
-------------------------------------------------------------------------------

begin try

-------------------------------------------------------------------------------
--  If no records were updated we will throw an error to the calling proc.
-------------------------------------------------------------------------------

select	 @StepName				= 'Validate variables.'
		,@StepNumber			= @StepNumber + 1
		,@StepOperation			= 'validate'
		,@StepDesc				= 'Determine if rows are returned for Id'


	if not exists (	select	top 1 1
				from	pg.PostingGroupProcessing
				where	PostingGroupProcessingId	= @pPostingGroupProcessingId)

	begin
		select   @ErrNum			= 50001
				,@MessageType		= 'ErrCust'
				,@ErrMsg			= 'Associated ctl.PostingGroupProcessing record could not be found.'
									  + ' @pPostingGroupId='  + cast(@pPostingGroupProcessingId as varchar(10)) 
								  
		; throw @ErrNum, @ErrMsg, 1  -- This is thrown to the catch block below.
	end

	if not exists (	select	top 1 1
				from	pg.RefProcessingMode
				where	ProcessingModeCode	= @pPostingGroupProcessingModeCode)

	begin
		select   @ErrNum			= 50002
				,@MessageType		= 'ErrCust'
				,@ErrMsg			= 'Unable to find Processing Mode: '
									  + ' @pPostingGroupProcessingModeCode='  + @pPostingGroupProcessingModeCode
								  
		; throw @ErrNum, @ErrMsg, 1  -- This is thrown to the catch block below.
	end


	select	 @StatusId		 = isnull(StatusId,-2)
	from	 pg.RefStatus
	where	 StatusCode		 = @pPostingGroupProcessingStatusCode

	if @StatusId = -2
	begin
		select   @ErrNum			= 50003
				,@MessageType		= 'ErrCust'
				,@ErrMsg			= 'Status code could not be looked up:'
									  + ' @pPostingGroupProcessingStatusCode='  + @pPostingGroupProcessingStatusCode
								  
		; throw @ErrNum, @ErrMsg, 1  -- This is thrown to the catch block below.
	end


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

select	 @StepName				= 'TestForRows'
		,@StepNumber			= @StepNumber + 1
		,@StepOperation			= 'validate'
		,@StepDesc				= 'Determine if rows are returned for Id'

	update	 pgp
	set		 PostingGroupStatusId			= @StatusId
			,ProcessingModeCode				= @pPostingGroupProcessingModeCode
			,ModifiedBy						= @ModifiedBy
			,ModifiedDtm					= @ModifiedDtm
	from	 pg.PostingGroupProcessing		  pgp
	where	 pgp.PostingGroupProcessingId	= @pPostingGroupProcessingId


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
