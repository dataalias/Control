CREATE PROCEDURE ctl.usp_SendMail (
		 @pProject				varchar(255)	= 'N/A'
		,@pPackage				varchar(255)	= 'N/A'
		,@pDataFactoryName			varchar(255)	= 'N/A'
		,@pDataFactoryPipeline			varchar(255)	= 'N/A'
		,@pTo					varchar(1000)	= 'N/A'
		,@pSeverity				int		= -1
		,@pIssueId				int		= -1
		,@pPostingGroupProcessingId		bigint		= -1
		,@pETLExecutionId			int		= -1
		,@pPathId				int		= -1
		,@pVerbose				bit		= 0)
AS
/*****************************************************************************
File:		usp_SendMail.sql
Name:		usp_SendMail

Purpose:	

exec ctl.usp_SendMail -1, -1, 1

Parameters:    

Called by:	
Calls:          

Errors:		

Author:		ffortunato
Date:		20180101

******************************************************************************/

-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------

DECLARE	 @Rows					int				= 0
        ,@ErrNum				int				= -1
		,@ErrMsg				nvarchar(2048)	= 'N/A'
		,@ParametersPassedChar	varchar(1000)   = 'N/A'
		,@Tab					varchar(10)		= char(9)
		,@CRLF					varchar(10)		= char(13) + char(10)
		,@ProcName				varchar(256)	= OBJECT_NAME(@@PROCID) 
		,@ServerName			varchar(256)	= @@SERVERNAME
		,@ParentStepLogId       int				= -1
		,@PrevStepLog			int				= -1
		,@ProcessStartDtm		datetime		= getdate()
		,@CurrentDtm			datetime		= getdate()
		,@PreviousDtm			datetime		= getdate()
		,@DbName				varchar(50)		= DB_NAME()
		,@CurrentUser			varchar(256)	= CURRENT_USER
		,@ProcessType			varchar(10)		= 'Proc'
		,@StepName				varchar(256)	= 'Start'
		,@StepOperation			varchar(50)		= 'N/A' 
		,@MessageType			varchar(20)		= 'Info' -- ErrCust, ErrSQL, Info, Warn
		,@StepDesc				nvarchar(2048)	= 'Procedure started' 
		,@StepStatus			varchar(10)		= 'Success'
		,@StepNumber			varchar(10)		= 0
		,@Duration				varchar(10)		= 0
		,@JSONSnippet			nvarchar(max)	= NULL
		,@Body					varchar(2000)	= 'N/A'
		,@Subject				varchar(600)	= 'N/A'
		,@From					varchar(200)	= 'N/A'

exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

SELECT	 @ParametersPassedChar	= 
			'exec bpi_dw_stage.ctl.usp_SendMail' + @CRLF +
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
	select	 @StepName			= 'Send Mail'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'e-Mail'
			,@StepDesc			= 'Sending the notification email to users.'


	--Send Email
	if (@pProject = 'N/A')
		set @Subject =  (@ServerName + ' || Data Factory: ' + @pDataFactoryName + ' Failure')
	else if (@pDataFactoryName = 'N/A')
		set @Subject =  (@ServerName + ' || Integration Service: ' + @pProject + ' Failure')
	else 
		set @Subject =  (isnull(@ServerName, 'NULL') + ' || Shrug: ' + isnull(@pProject, 'NULL') + ' ' + isnull(@pDataFactoryName, 'NULL') + ' Failure')

	set @From = CASE WHEN @ServerName LIKE 'DME%'  THEN 'DM-DEV-ETL@myaddress.com'
					 WHEN @ServerName LIKE 'QME%'  THEN 'DM-QA-ETL@myaddress.com'
					 WHEN @ServerName LIKE 'PROD%' THEN 'DM-PROD-ETL@myaddress.com'
				END

	set @pTo = CASE WHEN @pSeverity = 1 THEN @pTo 
						   ELSE 'DM-Development@myaddress.com'
					  END

	set @Body = @CRLF
				+ 'SSISProject'+ @Tab				+ ': ' + CONVERT(varchar(50),COALESCE(@pProject,'N/A'))+ @CRLF
				+ 'SSISPackage'+ @Tab				+ ': ' + CONVERT(varchar(50),COALESCE(@pPackage,'N/A'))+ @CRLF
				+ 'DataFactoryName'+ @Tab			+ ': ' + CONVERT(varchar(50),COALESCE(@pDataFactoryName,'N/A'))+ @CRLF
				+ 'DataFactoryPipeline'+ @Tab		+ ': ' + CONVERT(varchar(50),COALESCE(@pDataFactoryPipeline,'N/A'))+ @CRLF
				+ 'IssueId'+ @Tab					+ ': ' + CONVERT(varchar(50),COALESCE(@pIssueId,-1))+ @CRLF
				+ 'PostingGroupProcessingId'+ @Tab	+ ': ' + CONVERT(varchar(50),COALESCE(@pPostingGroupProcessingId,-1))+ @CRLF
				+ 'Date'+ @Tab						+ ': ' + CONVERT(varchar(50),@CurrentDtm, 120)+ @CRLF
				+ 'User'+ @Tab						+ ': ' + SYSTEM_USER + @CRLF
				+ 'Contact'+ @Tab					+ ': DM-Development@myaddress.com' + @CRLF + @CRLF
				+ 'Error Messages'+ @CRLF
				+ '--------------------------------------------------------------------------------------------------'+ @CRLF + @CRLF + @CRLF

	exec msdb.dbo.sp_send_dbmail 
		 @from_address	 = @From
		,@recipients	 = @pTo
		,@importance	 = 'High'
		,@subject		 = @Subject
		,@body			 = @Body

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


/******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20180101	ffortunato		Initial Iteration
20210329	ffortunato		clearing warnings
20210329	ffortunato		history

******************************************************************************/

