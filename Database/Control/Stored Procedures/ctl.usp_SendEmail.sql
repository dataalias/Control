CREATE PROCEDURE ctl.usp_SendMail (
		 @pProject					varchar(250)	= 'N/A'
		,@pPackage					varchar(250)	= 'N/A'
		,@pDataFactoryName			varchar(250)	= 'N/A'
		,@pDataFactoryPipeline		varchar(250)	= 'N/A'
		,@pTo						varchar(250)	= 'N/A'
		,@pSeverity					int				= -1
		,@pPostingGroupProcessingId	int				= -1
		,@pETLExecutionId			int				= -1
		,@pPathId					int				= -1
		,@pVerbose					bit				= 0)
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

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20180101	ffortunato  Initial Iteration

******************************************************************************/

-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------

DECLARE	 @Rows					varchar(10)		= 0
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
		,@Subject				varchar(200)	= 'N/A'
		,@From				varchar(200)	= 'N/A'

exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

SELECT	 @ParametersPassedChar	= 
			'exec Control.ctl.usp_SendMail' + @CRLF +
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
	set @Subject =  (@ServerName + ' || ' + COALESCE(@pProject,@pDataFactoryName) + ' Posting Group Failure')

	set @From = CASE WHEN @ServerName IN ('DME1EDLSQL01','DEDTEDLSQL01') THEN 'DM-DEV-ETL@zovio.com'
					 WHEN @ServerName IN ('QME1EDLSQL01','QME3EDLSQL01') THEN 'DM-QA-ETL@zovio.com'
					 WHEN @ServerName IN ('PRODEDLSQL01') THEN 'DM-PROD-ETL@zovio.com'
				END

	set @pTo = CASE WHEN @pSeverity = 1 THEN @pTo 
						   ELSE 'DM-Development@bpiedu.com'
					  END

	set @Body = @CRLF
				+ 'SSISProject'+ @Tab				+ ': ' + @pProject+ @CRLF
				+ 'SSISPackage'+ @Tab				+ ': ' + CONVERT(varchar(10),@pPackage)+ @CRLF
				+ 'DataFactoryName'+ @Tab			+ ': ' + CONVERT(varchar(10),@pDataFactoryName)+ @CRLF
				+ 'DataFactoryPipeline'+ @Tab		+ ': ' + CONVERT(varchar(10),@pDataFactoryPipeline)+ @CRLF
				+ 'PostingGroupProcessinsId'+ @Tab	+ ': ' + CONVERT(varchar(10),@pPostingGroupProcessingId)+ @CRLF
				+ 'Date'+ @Tab						+ ': ' + CONVERT(varchar(20),@CurrentDtm, 120)+ @CRLF
				+ 'User'+ @Tab						+ ': ' + SYSTEM_USER + @CRLF
				+ 'Contact'+ @Tab					+ ': BI-Development@zovio.com' + @CRLF + @CRLF
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
