CREATE PROCEDURE ctl.usp_InsertNewContact (
		 @pName						[varchar](100)	= 'Unknown'
		,@pTier						[varchar](20)	= NULL
		,@pEmail					[varchar](100)	= NULL
		,@pPhone					[varchar](20)	= NULL
		,@pAddress01				[varchar](100)	= NULL
		,@pAddress02				[varchar](100)	= NULL
		,@pCity						[varchar](30)	= NULL
		,@pState					[varchar](10)	= NULL
		,@pZipCode					[varchar](10)	= NULL
		,@pETLExecutionId			INT				= -1
		,@pPathId					INT				= -1
		,@pVerbose					BIT				= 0)
AS
/*****************************************************************************
File:		ctl.usp_InsertNewContact.sql
Name:		ctl.usp_InsertNewContact
Purpose:	


EXEC [ctl].[usp_InsertNewContact] 
		 @pName						= 'Unit Test Name'
		,@pTier						= '1'
		,@pEmail					= 'DM-Development@bpiedu.com'
		,@pPhone					= '877.300.6069'
		,@pAddress01				= '10180 Telesis Ct'
		,@pAddress02				= '#400'
		,@pCity						= 'San Diego'
		,@pState					= 'CA'
		,@pZipCode					= '92121'


		

Parameters:    

Called by:	
Calls:          

Errors:		

Author:	ffortunato	
Date:	20201120	

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20201120	ffortunato		Initital Iteration

******************************************************************************/

-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------

DECLARE  @Rows				  int				= 0
		,@ErrNum			  int				= -1
		,@ErrMsg			  nvarchar(max)		= 'N/A'
		,@ParametersPassedChar  varchar(1000)	= 'N/A'
		,@CRLF				  varchar(10)		= char(13) + char(10)
		,@ProcName			  varchar(256)		= OBJECT_NAME(@@PROCID) 
		,@ParentStepLogId	  int				= -1
		,@PrevStepLog		  int				= -2
		,@ProcessStartDtm	  datetime			= getdate()
		,@CurrentDtm		  datetime			= getdate()
		,@PreviousDtm		  datetime			= getdate()
		,@DbName			  varchar(50)		= DB_NAME()
		,@CurrentUser		  varchar(50)		= CURRENT_USER
		,@ProcessType		  varchar(10)		= 'Proc'
		,@StepName			  varchar(256)		= 'Start'
		,@StepOperation		  varchar(50)		= 'N/A' 
		,@MessageType		  varchar(20)		= 'Info' -- ErrCust, ErrSQL, Info, Warn
		,@StepDesc			  nvarchar(2048)	= 'Procedure started' 
		,@StepStatus		  varchar(10)		= 'Success'
		,@StepNumber		  varchar(10)		= 0
		,@Duration			  varchar(10)		= 0
		,@JSONSnippet		  nvarchar(max)		= NULL
		,@ContactId			  int				= -1
		,@CreateDate		  datetime			= getdate()

exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

SELECT	 @ParametersPassedChar	= 
      '***** Parameters Passed to exec ctl.usp_insertnewcontact' + @CRLF +
      '     @pName = ''' + isnull(@pName ,'NULL') + '''' + @CRLF + 
      '    ,@pTier = ''' + isnull(@pTier ,'NULL') + '''' + @CRLF + 
      '    ,@pEmail = ''' + isnull(@pEmail ,'NULL') + '''' + @CRLF + 
      '    ,@pPhone = ''' + isnull(@pPhone ,'NULL') + '''' + @CRLF + 
      '    ,@pAddress01 = ''' + isnull(@pAddress01 ,'NULL') + '''' + @CRLF + 
      '    ,@pAddress02 = ''' + isnull(@pAddress02 ,'NULL') + '''' + @CRLF + 
      '    ,@pCity = ''' + isnull(@pCity ,'NULL') + '''' + @CRLF + 
      '    ,@pState = ''' + isnull(@pState ,'NULL') + '''' + @CRLF + 
      '    ,@pZipCode = ''' + isnull(@pZipCode ,'NULL') + '''' + @CRLF + 
      '    ,@pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pPathId = ' + isnull(cast(@pPathId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL') + @CRLF + 
      '***** End of Parameters' + @CRLF 

if @pVerbose					= 1
	begin 
		print @ParametersPassedChar
	end

-------------------------------------------------------------------------------
--  Main
-------------------------------------------------------------------------------

BEGIN TRY

	-------------------------------------------------------------------------------
	--  Step Comment - Start
	-------------------------------------------------------------------------------
	select	 @StepName			= 'Insert into contact values'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Insert'
			,@StepDesc			= 'Insert to ctl.contact'
	-------------------------------------------------------------------------------

	INSERT INTO ctl.Contact(
	   [Name]	
	  ,Tier		
	  ,Email	
	  ,Phone	
	  ,Address01
	  ,Address02
	  ,City		
	  ,[State]
	  ,ZipCode
	  ,CreatedBy
	  ,CreatedDtm
		)
	VALUES(
	   @pName		
	  ,@pTier		
	  ,@pEmail	
	  ,@pPhone	
	  ,@pAddress01
	  ,@pAddress02
	  ,@pCity		
	  ,@pState	
	  ,@pZipCode	
	  ,@CurrentUser
	  ,@CurrentDtm
	);

	-------------------------------------------------------------------------------
	--  Step Comment - End
	-------------------------------------------------------------------------------
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		
			,@JSONSnippet		,@ErrNum			,@ParametersPassedChar					
			,@ErrMsg output	,@ParentStepLogId		,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus		,@DbName		,@Rows				
			,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

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
