CREATE PROCEDURE [audit].[usp_InsertStepLog] (
		 @pMessageType			varchar(20)		= 'INFO'
		,@pCurrentDtm			datetime		= NULL
		,@pPreviousDtm			datetime		= NULL
		,@pStepNumber			varchar(23)		= '0'
		,@pStepOperation		nvarchar(50)	= 'Unknown'
		,@pJSONSnippet			nvarchar(max)	= 'N/A'
		,@pErrNum				int				= 0
		,@pParametersPassedChar nvarchar(max)	= 'N/A'
		,@pErrMsg				nvarchar(max)	= 'N/A' output
		,@pParentLogId			int				= -1
		,@pProcessName			varchar(256)	= 'N/A'
		,@pProcessType			varchar(256)	= 'N/A'
		,@pStepName				varchar(256)	= 'N/A'
		,@pStepDesc				nvarchar(2048)	= 'N/A' output
		,@pStepStatus			varchar(10)		= 'N/A'
		,@pDBName				varchar(50)		= 'N/A'
		,@pRecordCount			int				= -1
		,@pETLExecutionId		int				= -1
		,@pPathId				int				= -1
		,@pStepLogId			int				= -1 output
		,@pVerbose				bit				= 0)
AS
/*****************************************************************************
File:		usp_InsertStepLog.sql
Name:		usp_InsertStepLog
Purpose:	

Execute: 
	declare @LogId int, @Start datetime = getdate(),@End datetime = getdate() -.001,
	@StepDescription varchar(2048) = 'Adds some data to dis thing'

	exec [audit].[usp_InsertStepLog] 
			 @pMessageType			= 'INFO'
			,@pCurrentDtm			= @Start
			,@pPreviousDtm			= @End
			,@pStepNumber			= 1 
			,@pStepOperation		='select'
			,@pJSONSnippet			= '{"snip":"yup"}'
			,@pErrNum				= 344
			,@pParametersPassedChar = 'Parms...'
			,@pErrMsg				= 'I failed as a person...'
			,@pParentLogId			= -1
			,@pProcessName			= 'usp_SomeProcedure'
			,@pProcessType			= 'Proc'
			,@pStepName				= ' Insert some data...'
			,@pStepDesc				= @StepDescription output
			,@pStepStatus			= 'Success'
			,@pDBName				= 'BPI_DW_STAGE'
			,@pRecordCount			= 666
			,@pETLExecutionId		= 12345
			,@pPathId				= 99
			,@pStepLogId			= @LogId output
			,@pVerbose				= 1

	print 'LogId:     ' + cast(@LogId as varchar(20))
	print '@StepDesc: ' + @StepDescription

Parameters:    

Called by:	
Calls:          

Errors:		

Author:		ffortunato
Date:		20170802

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20170825	ffortunato		adding steplog status.

20170908	ffortunato		adding formatting proc call.

20170911	ffortunato		updated paramerter list.

******************************************************************************/

-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------

DECLARE	 @Rows					int				= 0
        ,@ErrNum				int				= -1
		,@ErrMsg				nvarchar(2048)	= 'N/A'
		,@FailedProcedure		varchar(1000)	= 'Stored Procedure : ' + OBJECT_NAME(@@PROCID) + ' failed.'
		,@ParametersPassedChar	varchar(1000)
		,@CRLF					varchar(10)		= char(13) + char(10)
		,@DurationInSeconds		int				= 0
		,@CurrentDtm			datetime		= getdate()
		,@MessageType			varchar(20)		= 'Info'
		--,@tstingLogId           varchar(20)     = '-1'
		,@SteplogId				int				= 0

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

SELECT	 @ParametersPassedChar	= @CRLF +
      '***** Parameters Passed to exec audit.usp_InsertStepLog' + @CRLF +
      '     @pMessageType = ''' + isnull(@pMessageType ,'NULL') + '''' + @CRLF + 
      '    ,@pCurrentDtm = ''' + isnull(convert(varchar(100),@pCurrentDtm ,13) ,'NULL') + '''' + @CRLF + 
      '    ,@pPreviousDtm = ''' + isnull(convert(varchar(100),@pPreviousDtm ,13) ,'NULL') + '''' + @CRLF + 
      '    ,@pStepNumber = ''' + isnull(@pStepNumber ,'NULL') + '''' + @CRLF + 
      '    ,@pStepOperation = ''' + isnull(@pStepOperation ,'NULL') + '''' + @CRLF + 
      '    ,@pJSONSnippet = ''' + isnull(@pJSONSnippet ,'NULL') + '''' + @CRLF + 
      '    ,@pErrNum = ' + isnull(cast(@pErrNum as varchar(100)),'NULL') + @CRLF + 
      '    ,@pParametersPassedChar = ''' + isnull(@pParametersPassedChar ,'NULL') + '''' + @CRLF + 
      '    ,@pErrMsg = @pErrMsg --output ' + @CRLF +
      '    ,@pParentLogId = ' + isnull(cast(@pParentLogId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pProcessName = ''' + isnull(@pProcessName ,'NULL') + '''' + @CRLF + 
      '    ,@pProcessType = ''' + isnull(@pProcessType ,'NULL') + '''' + @CRLF + 
      '    ,@pStepName = ''' + isnull(@pStepName ,'NULL') + '''' + @CRLF + 
      '    ,@pStepDesc = @pStepDesc --output ' + @CRLF +
      '    ,@pStepStatus = ''' + isnull(@pStepStatus ,'NULL') + '''' + @CRLF + 
      '    ,@pDBName = ''' + isnull(@pDBName ,'NULL') + '''' + @CRLF + 
      '    ,@pRecordCount = ' + isnull(cast(@pRecordCount as varchar(100)),'NULL') + @CRLF + 
      '    ,@pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pPathId = ' + isnull(cast(@pPathId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pStepLogId = @pStepLogId --output ' + @CRLF +
      '    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL') + @CRLF + 
      '***** End of Parameters' + @CRLF 

select	 @pStepDesc				= isnull(@pStepDesc,'No Step Description Provided...')
select	 @pStepLogId			= isnull(@pStepLogId,-1)

select	 @pCurrentDtm			= isnull(@pCurrentDtm,cast('1900-01-01' as datetime))
select	 @pPreviousDtm			= isnull(@pPreviousDtm,cast('1900-01-01' as datetime))

if @pVerbose					= 1
	begin 
		print @ParametersPassedChar
	end

-------------------------------------------------------------------------------
--  Main
-------------------------------------------------------------------------------
begin try

-- Starting transaction to ensure Id's remain consistent.

BEGIN TRANSACTION StepLogInsert

select	@SteplogId			= isnull(max(StepLogId) + 1 ,1)
	from	[audit].StepLog

	exec	[audit].[usp_CreateStepLogDescription] 
			 @pMessageType			= @pMessageType
			,@pStartDtm				= @pPreviousDtm
			,@pEndDtm				= @pCurrentDtm
			,@pStepNumber			= @pStepNumber
			,@pOperation			= @pStepOperation
			,@pStepDescription		= @pStepDesc
			,@pJSONSnippet			= @pJSONSnippet
			,@pErrNum				= @pErrNum
			,@pErrMsg				= @pErrMsg
			,@pParametersPassedChar = @pParametersPassedChar
			,@pStepLogId			= @StepLogId
			,@pJSONMsg				= @pStepDesc			output
			,@pFormatErrorMsg		= @pErrMsg				output
			,@pDuration				= @DurationInSeconds	output	 
			,@pETLExecutionId		= @pETLExecutionId
			,@pPathId				= @pPathId
			,@pVerbose				= @pVerbose

-- If a parent Id wasn't passed the next insert will be the parent.

if  @pParentLogId				= -1
	select	@pParentLogId		= @SteplogId	
	

insert into [audit].StepLog (
		ParentLogId
		,ProcessName
		,ProcessType
		,StepName
		,StepDesc
		,StepStatus	
		,StartDtm
		,DurationInSeconds
		,DbName
		,RecordCount
		,ETLExecutionId
		,PathId
) values (
		 @pParentLogId
		,@pProcessName
		,@pProcessType
		,@pStepName
		,@pStepDesc
		,@pStepStatus
		,@pPreviousDtm -- Yes this should be previous! It has to do with the timing of exec in the calling procedure.
		,@DurationInSeconds
		,@pDBName
		,@pRecordCount
		,@pETLExecutionId
		,@pPathId
)

-- Sending back the Id just inserted. 

select  @pStepLogId				= isnull(SCOPE_IDENTITY(),-1)

COMMIT TRANSACTION StepLogInsert

/*
if @pVerbose					= 1
	begin 
		print '@pStepLogId        : ' + cast(@pStepLogId as varchar(100))
		print 'SCOPE_IDENTITY     : ' + cast(SCOPE_IDENTITY() as varchar(100))
		print '@@Identity         : ' + cast(@@Identity as varchar(100))
		select @tstingLogId		= cast(max(StepLogId) as varchar(20)) from [audit].StepLog
		print 'max(StepLogId)     : ' + @tstingLogId
	end
*/

-- If for some reason @pStepLogId is -1 we have a problem.

if @pStepLogId					= -1
begin
    select   @ErrNum			= 50001
			,@ErrMsg			= 'ErrorNumber: ' + CAST (@ErrNum as varchar(10)) + @CRLF
								+ 'Custom Error: Invalid @pStepLogId. Insert New Step Log transaction rolled back.'  + @CRLF
								+ isnull(@ParametersPassedChar, 'Parmeter was NULL')
			,@MessageType		= 'ErrCust'
	; throw @ErrNum, @ErrMsg, 1

end

end try

begin catch

	select	 @ErrNum			= @@ERROR
			,@ErrMsg			= ERROR_MESSAGE()

	if @@TRANCOUNT				> 1
		ROLLBACK TRANSACTION StepLogInsert

	if		 @MessageType		<> 'ErrCust'
		select   @MessageType	=  'ErrSQL'

	exec	[audit].[usp_CreateStepLogDescription] 
			 @pMessageType			= @MessageType
			,@pStartDtm				= @CurrentDtm
			,@pEndDtm				= @CurrentDtm
			,@pStepNumber			= 0
			,@pOperation			= 'Insert'
			,@pStepDescription		= 'Failed to insert into audit.StepLog'
			,@pJSONSnippet			= NULL
			,@pErrNum				= @ErrNum
			,@pErrMsg				= @ErrMsg
			,@pParametersPassedChar = @ParametersPassedChar
			,@pStepLogId			= @StepLogId
			,@pJSONMsg				= @pStepDesc
			,@pFormatErrorMsg		= @pErrMsg	output
			,@pDuration				= @DurationInSeconds output	 
			,@pETLExecutionId		= @pETLExecutionId
			,@pPathId				= @pPathId
			,@pVerbose				= @pVerbose

	select	 @ErrNum			= @@ERROR
			,@ErrMsg			= @pStepDesc

	if @ErrNum < 50000  select @ErrNum = @ErrNum + 100000000

	;throw	 @ErrNum, @ErrMsg, 1	-- Sql Server Error

end catch
