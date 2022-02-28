CREATE PROCEDURE audit.tst_StepLog(
		 @pETLExecutionId		int				= -1
		,@pPathId				int				= -1
		,@pVerbose				bit				= 0)
AS
/*****************************************************************************
File:		tst_StepLog.sql
Name:		tst_StepLog

Purpose:	

exec audit.tst_StepLog -1, -1, 0

Parameters:    

Called by:	
Calls:          

Errors:		

Author:		ffortunato
Date:		20211115

******************************************************************************/

-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------

DECLARE	 @Rows					varchar(10)		= 0
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
		,@ServerName			varchar(256)	= @@SERVERNAME
		,@DBName				varchar(50)		= DB_NAME()
		,@CurrentUser			varchar(256)	= SYSTEM_USER
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

exec DataHub.[audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

SELECT	 @ParametersPassedChar	= 
			'exec DataHub.audit.tst_StepLog' + @CRLF +
			'     @pETLExecutionId = '	+ isnull(cast(@pETLExecutionId	as varchar(12)),'NULL') + @CRLF + 
			'    ,@pPathId = '			+ isnull(cast(@pPathId			as varchar(10)),'NULL') + @CRLF + 
			'    ,@pVerbose = '			+ isnull(cast(@pVerbose			as varchar(10)),'NULL')

if @pVerbose					= 1
	begin 
		print @ParametersPassedChar
	end

-------------------------------------------------------------------------------
--  Main
-------------------------------------------------------------------------------

begin try

-------------------------------------------------------------------------------
--  Step comment
-------------------------------------------------------------------------------
	select	 @StepName			= 'StepName'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Operation'
			,@StepDesc			= 'StepDescription'

/*
	<Add code block here>  --Remove select 1 and add your specific code.
	eg. select 1
*/

--	select 1/0

	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			--,@JSONSnippet		= '{"":"' + @myvar + '"}' -- Only if needed.

	exec DataHub.[audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	select	 @JSONSnippet		= NULL


-------------------------------------------------------------------------------
--  Step comment. Custom Error Check
-------------------------------------------------------------------------------

	select	 @StepName			= 'ErrorTestCondition'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'validate'
			,@StepDesc			= 'StepDescription'

declare @var int  = 1
	if @var = 1 -- error test condition


	begin
		select   @ErrNum		= 50001
				,@MessageType	= 'ErrCust'
				,@ErrMsg		= 'CustomErrorMessage <e.g. Validation failed>'
				,@JSONSnippet	= '{' + @CRLF +
							'		"Counts": {' + @CRLF +
							  '			"RecordCount":' + cast(@Rows as varchar(20)) + ',' + @CRLF +
							  '			"InsertCount": 2, ' + @CRLF +
							  '			"UpdateCount": 3, ' + @CRLF +
							  '			"DeleteCount": 4  ' + @CRLF +
							'		}'+ @CRLF +'	 }' + @CRLF

		; throw @ErrNum, @ErrMsg, 1  -- This is thrown to the catch block below.
	end

	else
		begin
			-- Log successful validation.
			select	 @PreviousDtm		= @CurrentDtm
			select	 @CurrentDtm		= getdate()

			exec DataHub.[audit].usp_InsertStepLog
				 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
				,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
				,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
				,@pVerbose
		end

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

	exec DataHub.[audit].usp_InsertStepLog
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
exec DataHub.[audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm	,@ProcessStartDtm	,@StepNumber	,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
		,@pVerbose


/******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20211115	ffortunato  Initial Iteration

******************************************************************************/