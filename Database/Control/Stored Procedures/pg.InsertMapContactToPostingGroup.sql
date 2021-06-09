CREATE procedure [pg].[InsertMapContactToPostingGroup] (	
		 @pPostingGroupCode			varchar(100)
		,@pContactName				varchar(100)
		,@pContactToPostingGroupDesc varchar(max)		= null
		,@pETLExecutionId			int					= -1
		,@pPathId					int					= -1
		,@pVerbose					bit					= 0
) as 

/******************************************************************************
File:		InsertMapContactToPostingGroup.sql
Name:		InsertMapContactToPostingGroup
Purpose:	Allows for the creation of mapping table for contact person for each posting group

exec pg.[InsertMapContactToPostingGroup] 
		 @pPostingGroupCode			= 'FMS1-EDL-COLLEGE-AU'
		,@pContactName				= 'BI-Development'
		,@ContactToPostingGroupDesc = 'Contact BI Development team in case of FMS failure'
			

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
20210413	ffortunato		Changing user to CurrentUser for consistency
							Adding modified date and user to insert.
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
		,@CurrentUser			varchar(50)		= SYSTEM_USER
		,@PostingGroupId		int				= -1
		,@ContactId				int				= -1

EXEC [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  initializations
-------------------------------------------------------------------------------
select	 @ParametersPassedChar   = char(13) + 'Parameters Passed: ' + char(13) +
		 '    @pPostingGroupCode = ' + isnull(@pPostingGroupCode,'NULL') + char(13) +
		 '    @pContactName  = ' + isnull(@pContactName, 'NULL') + char(13) +
		 '    @ContactToPostingGroupDesc = ' + isnull(@pContactToPostingGroupDesc,'NULL') + char(13)

begin try 

-------------------------------------------------------------------------------
--  Lookup Supporting Information
-------------------------------------------------------------------------------
	select	 @StepName			= 'Check parameters'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'select'
			,@StepDesc			= 'Check the parameters passed are correct'

	if @pPostingGroupCode  is not null
    
		select  @PostingGroupId			= isnull(pg.PostingGroupId,-1)
		from    pg.PostingGroup			  pg
		where   pg.PostingGroupCode		= @pPostingGroupCode

	if @pContactName  is not null
    
		select  @ContactId				= isnull(cnt.ContactId, -1)
		from    ctl.Contact				cnt
		where   cnt.[Name]				= @pContactName

	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			,@JSONSnippet		= '{"@pPostingGroupCode":"' + isnull(@pPostingGroupCode,'N/A')
								+ '","@PostingGroupId":"'+ isnull(cast(@PostingGroupId as varchar(10)),'N/A') + '"'
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
			,@StepDesc			= 'Test PostingGroup and Contact lookup.'

	if @PostingGroupId = -1 or @ContactId = -1 
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
	select	 @StepName			= 'Insert new record into PostingGroupDependency'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'insert'
			,@StepDesc			= 'Creating new dependency.'

	insert into pg.MapContactToPostingGroup(
		  ContactId
		 ,PostingGroupId
		 ,ContactToPostingGroupDesc		
		 ,CreatedBy
		 ,CreatedDtm
		 ,ModifiedBy
		 ,ModifiedDtm
	) values (
		  @ContactId
		 ,@PostingGroupId
		 ,@pContactToPostingGroupDesc		
		 ,@CurrentUser
		 ,@CurrentDtm
		 ,@CurrentUser
		 ,@CurrentDtm
	)

	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			,@JSONSnippet		= '{"@pPostingGroupCode":"' + isnull(@pPostingGroupCode,'N/A') + '","@pContactName":"'+ isnull(@pContactName,'N/A')+'"}'

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
