CREATE PROCEDURE [ctl].[GetJobList_DataHub] (
		 @pPublicationCode		varchar(50)		= 'N/A'
		,@pETLExecutionId		int				= -1
		,@pPathId				int				= -1
		,@pVerbose				bit				= 0)
AS
/*****************************************************************************
File:		GetJobList_DataHub.sql
Name:		GetJobList_DataHub
Purpose:	

exec ctl.GetJobList_DataHub 'OIE_BEHAVE', -1, -1, 1
exec ctl.GetJobList_DataHub 'OIE_VIABLE', -1, -1, 1
exec ctl.GetJobList_DataHub 'TUTOR_TR', -1, -1, 1
exec ctl.GetJobList_DataHub 'BAD_VALUE', -1, -1, 1

Parameters:    

Called by:	
Calls:          

Errors:		

Author:	ffortunato	
Date:	20180228

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20180228	ffortunato		SiteKey that is returned must be varchar (256)

******************************************************************************/

-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------

DECLARE	 @Rows					int				= 0
        ,@ErrNum				int				= -1
		,@ErrMsg				nvarchar(max)	= 'N/A'
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

		,@PassPhrase			varchar(256)	= 'N/A'
		,@StatusId				int				= -1
		,@LookBack				datetime		= dateadd(d,-3,GETDATE())
		,@PublicationId			int				= -1
		,@StatusCode			varchar(10)		= 'IP'




/*
exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose
*/

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

SELECT	 @ParametersPassedChar	= 
			'exec bpi_dw_stage.ctl.usp_GetPublicationList' + @CRLF +
			'     @pPublicationCode = ' + isnull(@pPublicationCode,'NULL') + @CRLF + 
			'    ,@pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
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
--  Step comment. Custom Error Check
-------------------------------------------------------------------------------

	select	 @StepName			= 'ErrorTestCondition'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'validate'
			,@StepDesc			= 'StepDescription'

	-- ADD A CHECK TO SEE IF A PARAMETER WAS PASSED!!!!

	select	 @StatusId			= ISNULL(StatusId,-1)
	from	 ctl.RefStatus		  rs
	where	 rs.StatusCode		= @StatusCode

	select	 @PublicationId		= ISNULL(pn.PublicationId,-1)
	from	 ctl.Publication	  pn
	where	 pn.PublicationCode	= @pPublicationCode

	select	 @JSONSnippet	= '{"StatusCode":"' + @StatusCode + '",' +
						'"StatusId":' + cast(@StatusId as varchar(10)) + ',' +
						'"PublicationCode":"' + @pPublicationCode + '", ' + 
						'"PublicationId":'+ cast(@PublicationId as varchar(10)) + '}' 


	if (@StatusId <= 0 or @PublicationId <= 0) -- error test condition
	begin
		select   @ErrNum		= 50001
				,@MessageType	= 'ErrCust'
				,@ErrMsg		= 'A bad status or publication provided to procedure.'


		; throw @ErrNum, @ErrMsg, 1  -- This is thrown to the catch block below.
	end

	else
		begin
			-- Log successful validation.
			select	 @PreviousDtm		= @CurrentDtm
			select	 @CurrentDtm		= getdate()

			exec [audit].usp_InsertStepLog
				 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
				,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
				,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
				,@pVerbose
			select	 @JSONSnippet		= NULL
		end




-------------------------------------------------------------------------------
--  Step comment
-------------------------------------------------------------------------------
	select	 @StepName			= 'Generate Publication List'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Operation'
			,@StepDesc			= 'Generating the publication list for use by DataHub.'


	SELECT	
			DISTINCT(pn.StageJobName) AS StageJobName
	FROM 	[ctl].[Publication]	  pn
	JOIN	ctl.Issue			  iss
	ON		iss.PublicationId	= pn.PublicationId
	WHERE	pn.IsActive			= 1 -- We only want active records.
	AND		iss.StatusId		= @StatusId
	AND		iss.CreatedDtm		> @LookBack
	--AND		COALESCE(iss.ModifiedDtm, iss.CreatedDtm)		> @LookBack
	AND		pn.PublicationCode  = @pPublicationCode
	AND		pn.StageJobName		IS NOT NULL

/*
	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			--,@JSONSnippet		= '<JSON Snippet>' -- Only if needed.

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
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

	if		 @MessageType		<> 'ErrCust'
		select   @MessageType	= 'ErrSQL'

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	if 	@ErrNum < 50000	
		select	 @ErrNum	= @ErrNum + 100000000 -- Need to increase number to throw message.

	;throw	 @ErrNum, @ErrMsg, 1
	
end catch

-------------------------------------------------------------------------------
--  Procedure End
-------------------------------------------------------------------------------
/*
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
		 @MessageType		,@CurrentDtm	,@ProcessStartDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
		,@pVerbose
*/
GO