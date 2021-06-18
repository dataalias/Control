CREATE PROCEDURE pg.usp_ExecuteStoredProcedure (
	 @pSQLStoredProcedure				varchar(255)	= 'N/A'
	,@pAllowMultipleInstances			bit				= 0
	,@pExecuteProcessStatus				varchar(20)		output
	,@pETLExecutionId					int				= -1
	,@pPathId							int				= -1
	,@pVerbose							bit				= 0)
AS
/*****************************************************************************
File:		pg.usp_ExecuteStoredProcedure.sql
Name:		usp_ExecuteStoredProcedure

Purpose:	The parameters for this procedure are used to create and run
			a nes SSIS execution. Identify server, pacgage and parameters.

Parameters:	
		 @p
		,@pAllowMultipleInstances Determines if several instances of the same SSIS package can run at once.
								1 - Yes : Allow new instance to invoke even if one is currently running.
								0 - No	: If an instance of the package is running do not allow another to run.


		,@pExecuteProcessStatus	'IAR' -- Instance already running.
								'INR' -- Instance not running.
								'ISS' -- Instance start succeeded.
								'ISF' -- Instance start failed.

		,@pETLExecutionId		= -1
		,@pPathId				= -1
		,@pVerbose				= 0


Execution

declare @MyResult varchar(200)
select @MyResult = 'NAH'
exec pg.usp_ExecuteStoredProcedure 

	 @pSQLStoredProcedure		= 'N/A'
	,@pAllowMultipleInstances	= 0
	,@pExecuteProcessStatus		=  @MyResult output
	,@pETLExecutionId		= -1
	,@pPathId				= -1
	,@pVerbose				= 0

print @MyResult
		 

Called By:	pg.usp_ExecuteProcess

Calls:		the named stored procedure passed in..

Author:		ffortunato
Date:		20210525

*******************************************************************************
       Change History
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------

20210525	ffortunato		Initial Iteration


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
		,@ExecutionId			int				= -1
		,@ReferenceId			int				= -1
		,@LoopMax				int				= -1
		,@LoopCount				int				= -1
		,@ObjectType			int				= -1
		,@ParameterName			nvarchar(128)	= 'N/A'
		,@ParameterValue		sql_variant		= 'N/A'		
		,@JSONAdd				nvarchar(400)	= NULL
		,@ReplaceJSONToken		nvarchar(10)	= ',"":""}'


exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

SELECT	 @ParametersPassedChar	= 
      '***** Parameters Passed to exec pg.usp_ExecuteSSISPackage' + @CRLF +
      '     @pServerName = ''' + isnull(@pSQLStoredProcedure ,'NULL') + '''' + @CRLF + 
	  '    ,@pAllowMultipleInstances = ''' + isnull(cast(@pAllowMultipleInstances as varchar(20)) ,'NULL') + '''' + @CRLF + 
	  '    ,@pExecuteProcessStatus = ''' + isnull(@pExecuteProcessStatus ,'NULL') + '''' + @CRLF + 
 --     '    ,@SSISParameters = ' + isnull(cast(@SSISParameters as varchar(100)),'NULL') + @CRLF + 
      '    ,@pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pPathId = ' + isnull(cast(@pPathId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL') + @CRLF + 
      '***** End of Parameters' + @CRLF 

select	  @pExecuteProcessStatus = 'ISF' -- Instnace start failed.

-------------------------------------------------------------------------------
--  Main
-------------------------------------------------------------------------------

begin try

-------------------------------------------------------------------------------
-- This section of code determines if any dependent jobs can be run based 
-- on other processes completeing.
-------------------------------------------------------------------------------

	select	 @StepName			= 'Is Instance Running'
			,@StepNumber		= @StepNumber + 0
			,@StepOperation		= 'select'
			,@StepDesc			= 'Going to determine if the instance is running.'
			,@JSONSnippet		= ' {"@pSQLStoredProcedure":"'	+ isnull(@pSQLStoredProcedure ,'NULL')+'",' + @ReplaceJSONToken

	-- See if the procedure is running?
	If exists (	select top 1 1 ) -- Status 2 = Executing)

		select	 @pExecuteProcessStatus = 'IAR' -- 'Instance Already Running'

	else
		select	 @pExecuteProcessStatus = 'INR' -- 'Instance not running'


	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			,@JSONSnippet		= '{"@pExecuteProcessStatus":"'  + isnull(@pExecuteProcessStatus, 'Bad Value') + '",' +
									'"@pAllowMultipleInstances":"' + isnull(cast(@pAllowMultipleInstances as varchar(2)),'Bad Value') + '"}' 
	
	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	-- Either serveral instances can be run at once or there is no instance of the job currently running.
	If ((@pAllowMultipleInstances = 1 ) or (@pAllowMultipleInstances = 0 and @pExecuteProcessStatus = 'INR'))
	begin

		-- Note when calling the next package Batch and Posting Group must be sent as well.
		select	 @StepName			= 'Execute Posting Group'
				,@StepNumber		= @StepNumber + 1
				,@StepOperation		= 'execute'
				,@StepDesc			= 'Execute Stored Procedure: ' + isnull(@pSQLStoredProcedure, 'Error')
				,@JSONSnippet		= ' {"@pSQLStoredProcedure":"'	+ isnull(@pSQLStoredProcedure ,'NULL')+'",' + @ReplaceJSONToken

		exec	 @pSQLStoredProcedure

		select	 @PreviousDtm		= @CurrentDtm
				,@Rows				= @@ROWCOUNT 
		select	 @CurrentDtm		= getdate()
	
		exec [audit].usp_InsertStepLog
				 @MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
				,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
				,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
				,@pVerbose
	end -- if
	else if ((@pAllowMultipleInstances = 0) and (@pExecuteProcessStatus = 'IAR'))
	begin
		-- There is nothing to do here. Only one instance can run at a time so send back IAR and let calling procedure figure out what to do.	
		select	 @JSONSnippet = '{"comment":"SQL Stored Procedure: '+isnull(@pSQLStoredProcedure,'No Procedure Name.')+ ' not run because another instance is already running."}'
		
	end -- if @pAllowMultipleInstances = 0
	else
	begin
			select	 @JSONSnippet = '{"comment":"SQL Stored Procedure: '+isnull(@pSQLStoredProcedure,'No Package Name.')+ ' not run because current status could not be established."}'
			;throw  50011, 'Could not establish if SQL Stored Procedure can run.', 1	-- Custom Error: 100001
	end

	select	 @JSONSnippet		= NULL
	select	 @pExecuteProcessStatus = 'ISS' -- Instance run succeded.

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

	select	 @pExecuteProcessStatus = 'ISF' -- Instance run failed.

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
		 @MessageType		,@CurrentDtm	,@ProcessStartDtm	,@StepNumber	,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
		,@pVerbose
