CREATE procedure [ctl].[InsertMapContactToSubscription] (	
		 @pSubscriptionCode			varchar(100)
		,@pContactName				varchar(100)
		,@pContactToSubscriptionDesc varchar(max)		= null
		,@pETLExecutionId			int					= -1
		,@pPathId					int					= -1
		,@pVerbose					bit					= 0
) as 

/******************************************************************************
File:		InsertMapContactToSubscription.sql
Name:		InsertMapContactToSubscription
Purpose:	Allows for the creation of mapping table for contact person for each Subscription

exec ctl.[InsertMapContactToSubscription] 
		 @pSubscriptionCode			= 'FMS1-EDL-COLLEGE-AU'
		,@pContactName				= 'BI-Development'
		,@ContactToSubscriptionDesc = 'Contact BI Development team in case of FMS failure'
			

Parameters:     
	@pParentId	Parent is the process we are want to run next
	@pChildId	Child is the process we check for completion prior to 
				starting the parent process.
	@pCreatedBy	user inserting the new values.

Called By:	install script
Calls:		N/A

Author:		ochowkwale
Date:		20200511

*******************************************************************************
       change history
*******************************************************************************
date		author			description
--------	-------------	---------------------------------------------------

******************************************************************************/

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
		,@ProcessType			varchar(10)		= 'Proc'
		,@StepName				varchar(256)	= 'Start'
		,@StepOperation			varchar(50)		= 'N/A' 
		,@MessageType			varchar(20)		= 'Info' -- ErrCust, ErrSQL, Info, Warn
		,@StepDesc				nvarchar(2048)	= 'Procedure started' 
		,@StepStatus			varchar(10)		= 'Success'
		,@StepNumber			varchar(10)		= 0
		,@Duration				varchar(10)		= 0
		,@JSONSnippet			nvarchar(max)	= NULL
		,@PassPhrase			varchar(256)	= ''
		,@CurrentUser			varchar(100)	= SYSTEM_USER
		,@SubscriptionId		int				= -1
		,@ContactId				int				= -1

EXEC [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  initializations
-------------------------------------------------------------------------------
select	 @ParametersPassedChar   = 
      '***** Parameters Passed to exec ctl.InsertMapContactToSubscription' + @CRLF +
      '     @pSubscriptionCode = ''' + isnull(@pSubscriptionCode ,'NULL') + '''' + @CRLF + 
      '    ,@pContactName = ''' + isnull(@pContactName ,'NULL') + '''' + @CRLF + 
      '    ,@pContactToSubscriptionDesc = ''' + isnull(@pContactToSubscriptionDesc ,'NULL') + '''' + @CRLF + 
      '    ,@pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pPathId = ' + isnull(cast(@pPathId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL') + @CRLF + 
      '***** End of Parameters' + @CRLF 

begin try 

-------------------------------------------------------------------------------
--  Lookup Supporting Information
-------------------------------------------------------------------------------
	select	 @StepName			= 'Check parameters'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'select'
			,@StepDesc			= 'Check the parameters passed are correct'

	if @pSubscriptionCode  is not null
    
		select  @SubscriptionId			= isnull(ctl.SubscriptionId,-1)
		from    ctl.Subscription		ctl
		where   ctl.SubscriptionCode	= @pSubscriptionCode

	if @pContactName  is not null
    
		select  @ContactId				= isnull(cnt.ContactId, -1)
		from    ctl.Contact				cnt
		where   cnt.[Name]				= @pContactName

	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			,@JSONSnippet		= '{"@pSubscriptionCode":"' + isnull(@pSubscriptionCode,'N/A')
								+ '","@SubscriptionId":"'+ isnull(cast(@SubscriptionId as varchar(10)),'N/A') + '"'
								+ '","@pContactName":"'+ isnull(@pContactName,'N/A') + '"'
								+ '","@ContactId":"'+ isnull(cast(@ContactId as varchar(10)),'N/A')+'"}'

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

-------------------------------------------------------------------------------
--  Checking for a good child / parent record.
-------------------------------------------------------------------------------

	select	 @StepName			= 'Test lookups'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'validate'
			,@StepDesc			= 'Test Subscription and Contact lookup.'

	if @SubscriptionId = -1 or @ContactId = -1 
	begin
		select   @ErrNum		= 50001
				,@MessageType	= 'ErrCust'
				,@ErrMsg		= 'Lookup for Child / Parent Id values failed.'

		; throw @ErrNum, @ErrMsg, 1  -- This is thrown to the catch block below.
	end

	else
		begin
			-- Log successful validation.
			select	 @PreviousDtm		= @CurrentDtm
			select	 @CurrentDtm		= getdate()

			exec [audit].usp_InsertStepLog
				 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
				,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
				,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
				,@pVerbose
		end

-------------------------------------------------------------------------------
--  Lookup Supporting Information
-------------------------------------------------------------------------------
	select	 @StepName			= 'Insert new record into SubscriptionDependency'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'insert'
			,@StepDesc			= 'Creating new dependency.'

	if	@pContactToSubscriptionDesc is null  or @pSubscriptionCode = ''
	begin
		select @pContactToSubscriptionDesc = isnull(@pSubscriptionCode,'Unknown') + '__' + isnull(@pContactName,'Unknown')
	end

	insert into ctl.MapContactToSubscription(
		  ContactId
		 ,SubscriptionId
		 ,ContactToSubscriptionDesc		
		 ,CreatedBy
		 ,CreatedDtm
	) values (
		  @ContactId
		 ,@SubscriptionId
		 ,@pContactToSubscriptionDesc		
		 ,@CurrentUser
		 ,@CurrentDtm
	)

	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			,@JSONSnippet		= '{"@pSubscriptionCode":"' + isnull(@pSubscriptionCode,'N/A') + '","@pContactName":"'+ isnull(@pContactName,'N/A')+'"}'

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

end try -- main

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

exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm	,@ProcessStartDtm	,@StepNumber	,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
		,@pVerbose
