/*

This is a template stored procedure that utilizes step logging for better
detail of what is going on within a stored procedure.

Add this to you SQL Server Templates directory:

C:\Users\<<USER>>\AppData\Roaming\Microsoft\SQL Server Management Studio\18.0\Templates\Sql\Stored Procedure\

*/


/******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20170831	ffortunato		making sure custom error and sql server error
							messages come across correctly in the thrown error
							to SSIS and the step log desctiption.

20170906	ffortunato		Adding StepNumber. Thinging about the future of
							error handling.

20170907	ffortunato		description JSON improvements and call to fomatting
							proc rather than doing it inline...

20170911	ffortunato		final changes. adding instructions.

20171115	ffortunato		Making sure we handle Snippets correctly.

20180221	ffortunato		Removing Database references to make dbProjects 
							work.

20180302	ffortunato		JSON example. More prep for DB projects. More 
							template parameters.

20211014	ffortunato		o Variable for logging database. 
							o Moving change history to end of procedure
*******************************************************************************
Instructions:

1) This section should be removed from the procedure.
2) Set the database, schema and procedure name using the 'Specify Values for Template Parameters' Ctl+Shift+M
3) After declaring parameters add them to the @ParametersPassedChar variable.
	a. This can be done by executing the procedure: DEDTEDLSQL01.BPI_DW_STAGE.[ctl].[usp_GetParameterListing]
4) Make sure all executions are inside of a TRY / CATCH block.
	a. This can be satisfied by a single block for the entire procedure or several individual blocks within the procedure.
5) Identify if any custom errors must be raised. 
	a. <error test condition> can be used to test variables and throw custom errors
6) Log to step log at the conclusion of each processing block in the procedure.

	a. @StepName = 'Step 1: <Step Name>'  -- <Step Name> should be replaced with a more appropriate descriptor. 
			This must come in front of the actual code so the failure can reference the correct step.
	b. @StepDesc = '<Description>' -- 
	c. @JSONSnippet <JSON Doc> should follow the format below. (CRLF can be excluded)

-- Snippet Start--
{
    "Counts": {
      "RecordCount": 0,
      "InsertCount": 0,
      "UpdateCount": 0,
      "DeleteCount": 0
    }
}
-- Snippet End --


	d. "OperationEnumeration": [ "merge", "select", "insert", "update", "create_index", "drop_index", "create_table", "drop_table", "DBCC", "exec","validate" ],
	e. "MessageTypeEnumeration": [ "Info", "Warn", "ErrCust", "ErrSQL" ],
	f. @JSONSnippet these are the items that are added under the Misc Heading. Only the snippet is needed. Misc is added by the usp_CreateStepLogDescription procedure.
		e.g. --
	g. NOTE!!! Once you use @JSONSnippet you must set it to null in your next step log ... SET @JSONSnippet	=NULL
	
7) <Add code block here>  remove this comment and add your code block in that area. It should be proceeded by the step name.
8) increment step number with each new step created. This way we get a counter that identifes how far along the code is.
9) The actual string that needs to be ;thrown cannot contain a % if one is needed escape it first with a second % (e.g.'%%')

******************************************************************************/

CREATE PROCEDURE <Schema_Name, sysname, SchemaName>.<Procedure_Name, sysname, ProcedureName> (
		 @pETLExecutionId		int				= -1
		,@pPathId				int				= -1
		,@pVerbose				bit				= 0)
AS
/*****************************************************************************
File:		<Procedure_Name, sysname, ProcedureName>.sql
Name:		<Procedure_Name, sysname, ProcedureName>

Purpose:	

exec <Schema_Name, sysname, SchemaName>.<Procedure_Name, sysname, ProcedureName> -1, -1, 1

Parameters:    

Called by:	
Calls:          

Errors:		

Author:		<Author,Varchar,Author Name>
Date:		<DateInt,Int,20180101>

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

exec [$(DataHub)].[audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

SELECT	 @ParametersPassedChar	= 
			'exec <Database_Name, sysname, DatabaseName>.<Schema_Name, sysname, SchemaName>.<Procedure_Name, sysname, ProcedureName>' + @CRLF +
			'     @pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
			'    ,@pPathId = ' + isnull(cast(@pPathId as varchar(100)),'NULL') + @CRLF + 
			'    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL')

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
	select 1

	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			--,@JSONSnippet		= '{"":"' + @myvar + '"}' -- Only if needed.

	exec [$(DataHub)].[audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	select	 @JSONSnippet		= NULL

/*
-------------------------------------------------------------------------------
--  Step comment. Custom Error Check
-------------------------------------------------------------------------------

	select	 @StepName			= 'ErrorTestCondition'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'validate'
			,@StepDesc			= 'StepDescription'


	if 1 <> 1 -- error test condition
	begin
		select   @ErrNum		= 50001
				,@MessageType	= 'ErrCust'
				,@ErrMsg		= 'CustomErrorMessage'
				,@JSONSnippet	= '{' + @CRLF +
							'		"Counts": {' + @CRLF +
							  '			"RecordCount":' + cast(varchar(100), @RecordCount) + ',' + @CRLF +
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

			exec [$(DataHub)].[audit].usp_InsertStepLog
				 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
				,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
				,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
				,@pVerbose
		end
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

	if		 @MessageType		<> 'ErrCust'
		select   @MessageType	= 'ErrSQL'

	exec [$(DataHub)].[audit].usp_InsertStepLog
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
exec [$(DataHub)].[audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm	,@ProcessStartDtm	,@StepNumber	,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
		,@pVerbose


/******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
<DateInt,,>	<Author,,Name>  Initial Iteration

******************************************************************************/