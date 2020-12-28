CREATE procedure [pg].[InsertPostingGroupDependency] (	
		 @pParentCode				varchar(100)
		,@pChildCode				varchar(100)
		,@pDependencyCode			varchar(100)		= null
		,@pDependencyName			varchar(250)		= null
		,@pDependencyDesc			varchar(max)		= null
		,@pCreatedBy				varchar(50)
		,@pETLExecutionId			int					= -1
		,@pPathId					int					= -1
		,@pVerbose					bit					= 0
) as 

/******************************************************************************
File:		InsertPostingGroupDependency.sql
Name:		InsertPostingGroupDependency
Purpose:	Allows for the creation of new posting group dependencies.
			once the child is complete the parent can run.

exec pg.[InsertPostingGroupDependency] 
	 @pParentCode			= 'DimOIE'
	,@pChildCode			= 'OIE-EDL-OIE_BEHAVE'
	,@pDependencyCode		= ''
	,@pDependencyName		= ''
	,@pDependencyDesc		= ''
	,@pCreatedBy			= 'ffortunato'
	,@pETLExecutionId		= -1
	,@pPathId				= -1
	,@pVerbose				= 0

Parameters:     
	@pParentId	Parent is the process we are want to run next
	@pChildId	Child is the process we check for completion prior to 
				starting the parent process.
	@pCreatedBy	user inserting the new values.

Called By:	install script
Calls:		N/A

Author:		ffortunato
Date:		20161018

*******************************************************************************
       change history
*******************************************************************************
date		author			description
--------	-------------	---------------------------------------------------
20180410	ffortunato		getting ready with new errorhandling and logging.
20180730	ffortunato		Cleaning up the header.
20180803	ffortunato		changing code size to varchar(100).
20180906	ffortunato		code validation changes.
20180912	ffortunato		no more passing ID's.
20201130	ffortunato		Adding code and name values.
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

		,@ParentId				int				= -1
		,@ChildId				int				= -1

EXEC [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  initializations
-------------------------------------------------------------------------------
select	 @ParametersPassedChar   = char(13) + 'Parameters Passed: ' + char(13) +
		 '    @pParentCode = ' + isnull(@pParentCode,'NULL') + char(13) +
		 '    @pChildCode  = ' + isnull(@pChildCode, 'NULL') + char(13) +
		 '    @pDependencyCode = ' + isnull(@pDependencyCode,'NULL') + char(13) +
		 '    @pDependencyName  = ' + isnull(@pDependencyName, 'NULL') + char(13) +
		 '    @pDependencyDesc = ' + isnull(@pDependencyDesc,'NULL') + char(13) +
		 '    @pCreatedBy  = ' + isnull(@pCreatedBy, 'NULL') + char(13) 

begin try 

-------------------------------------------------------------------------------
--  Lookup Supporting Information
-------------------------------------------------------------------------------
	select	 @StepName			= 'Insert new record into Posting Group'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'insert'
			,@StepDesc			= 'Preparing a new record for posting group.'

	if @pParentCode  is not null
    
		select  @ParentId				= isnull(pg.PostingGroupId,-1)
		from    pg.PostingGroup			  pg
		where   pg.PostingGroupCode		= @pParentCode

	if @pChildCode  is not null
    
		select  @ChildId				= isnull(pg.PostingGroupId, -1)
		from    pg.PostingGroup			  pg
		where   pg.PostingGroupCode		= @pChildCode

	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			,@JSONSnippet		= '{"@pParentCode":"' + isnull(@pParentCode,'N/A')
								+ '","@ParentId":"'+ isnull(cast(@ParentId as varchar(10)),'N/A') + '"'
								+ '","@pChildCode":"'+ isnull(@pChildCode,'N/A') + '"'
								+ '","@ChildId":"'+ isnull(cast(@ChildId as varchar(10)),'N/A')+'"}'

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

-------------------------------------------------------------------------------
--  Checking for a good child / parent record.
-------------------------------------------------------------------------------

	select	 @StepName			= 'Test parent and child lookup.'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'validate'
			,@StepDesc			= 'Test parent and child lookup.'

	if @ParentId = -1 or @ChildId = -1 
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

	insert into pg.PostingGroupDependency(
		  ParentId
		 ,ChildId
		 ,DependencyCode		
		 ,DependencyName		
		 ,DependencyDesc
		 ,CreatedBy
		 ,CreatedDtm
	) values (
		  @ParentId
		 ,@ChildId
		 ,@pDependencyCode		
		 ,@pDependencyName		
		 ,@pDependencyDesc		
		 ,@pCreatedBy
		 ,@CurrentDtm
	)

	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			,@JSONSnippet		= '{"@pParentCode":"' + isnull(@pParentCode,'N/A') + '","@pChildCode":"'+ isnull(@pChildCode,'N/A')+'"}'

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose


	if 	@pDependencyCode		is null 
		or @pDependencyCode = ''

		update	 pgd
		set		 pgd.DependencyCode			= pgC.PostingGroupCode + ' --To-- ' + pgP.PostingGroupCode
		from	 pg.PostingGroupDependency	  pgd
		join	 pg.PostingGroup			  pgC
		on		 pgC.PostingGroupId			= pgd.ChildId
		join	 pg.PostingGroup			  pgP
		on		 pgP.PostingGroupId			= pgd.ParentId
		where	 pgd.ParentId				= @ParentId
		and		 pgd.ChildId				= @ChildId

	if	@pDependencyName		is null
		or @pDependencyName = ''

		update	 pgd
		set		 pgd.DependencyName			= pgC.PostingGroupName + '--To--' + pgP.PostingGroupName
		from	 pg.PostingGroupDependency	  pgd
		join	 pg.PostingGroup			  pgC
		on		 pgC.PostingGroupId			= pgd.ChildId
		join	 pg.PostingGroup			  pgP
		on		 pgP.PostingGroupId			= pgd.ParentId
		where	 pgd.ParentId				= @ParentId
		and		 pgd.ChildId				= @ChildId


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
