CREATE procedure [pg].[usp_GetPostingGroupChild] (
		 @pPostingGroupBatchId		int				= -1
		,@pPostingGroupId			int				= -1
		,@pPostingGroupBatchSeq		int				= -1
		,@pChildPostingGroupCode	varchar(50)		= 'N/A'
		,@pETLExecutionId			int				= -1
		,@pPathId					int				= -1
		,@pVerbose					bit				= 0)
as

/*****************************************************************************
File:		GetPostingGroupChildren.sql
Name:		GetPostingGroupChildren
Purpose:    Allows for the retrieval of detailed Posting Group Processing
			information. This includes parent and child details. 

exec pg.GetPostingGroupChild 
		 @pPostingGroupBatchId		= 3
		,@pPostingGroupId			= 109
		,@pPostingGroupBatchSeq		= 3
		,@pChildPostingGroupCode	= 'FB_MCA-EDL-ADCOMP'
		,@pETLExecutionId			= -1
		,@pPathId					= -1
		,@pVerbose					= 0

Parameters:	@pIssueID - IssueID to retrieve details of

Called by: Data Factory
Calls:          
Errors:		
Author:		jsardina
Date:		20190624

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20201118	ffortunato		cleaning up warnings.
20210415	ffortunato		formatting.
******************************************************************************/

-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------
declare	 @Rows					int				= 0
        ,@ErrNum				int				= -1
		,@ErrMsg				nvarchar(2048)	= 'N/A'
		,@ParametersPassedChar	varchar(1000)   = 'N/A'
		,@CRLF					varchar(10)		= char(13) + char(10)
		,@Tab					varchar(10)		= char(11)
		,@ProcName				varchar(256)	= OBJECT_NAME(@@PROCID) 
		,@ParentStepLogId       int				= -1
		,@PrevStepLog			int				= -1
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

exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------
select	 @ParametersPassedChar	= 
      '***** Parameters Passed to exec pg.usp_GetPostingGroupChild' + @CRLF +
      '     @pPGBId = ' + isnull(cast(@pPostingGroupBatchId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pPGId = ' + isnull(cast(@pPostingGroupId as varchar(100)),'NULL') + @CRLF + 	  
	  '    ,@pChildPostingGroupCode = ' + isnull(cast(@pChildPostingGroupCode as varchar(100)),'NULL') + @CRLF + 
      '    ,@pPGBatchSeq = ' + isnull(cast(@pPostingGroupBatchSeq as varchar(100)),'NULL') + @CRLF + 
      '    ,@pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pPathId = ' + isnull(cast(@pPathId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL') + @CRLF + 
      '***** End of Parameters' + @CRLF 

if @pVerbose					= 1
	begin 
		print @ParametersPassedChar
	end


begin try
	-- Set Log Values
	select	 @StepName			= 'Select Posting Group Records'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Select'
			,@StepDesc			= 'SelectiNg records from Posting Group table for the given ChildPostingGroupCode'
			,@JSONSnippet		= '{' + @CRLF +
										@Tab + @Tab + '"@pPostingGroupBatchId": "' + cast(@pPostingGroupBatchId as varchar(200)) + '"' + @CRLF +
										@Tab + @Tab + '"@pPostingGroupId": "' + cast(@pPostingGroupId as varchar(200)) + '"' + @CRLF +
										@Tab + @Tab + '"@pPostingGroupBatchSeq": "' + cast(@pPostingGroupBatchSeq as varchar(200)) + '"' + @CRLF +
										@Tab + '}'+ @CRLF 
			
  		select	 pgpP.PostingGroupProcessingId	ParentPostingGroupProcessingId
				,pgpP.PostingGroupBatchId		ParentPostingGroupBatchId
				,pgpP.PostingGroupId			ParentPostingGroupId
				,pgpP.PostingGroupStatusId		ParentPostingGroupStatusId
				,pgpP.PGPBatchSeq				ParentPGPBatchSeq
				,pgpC.PostingGroupProcessingId	ChildPostingGroupProcessingId
				,pgpC.PostingGroupBatchId		ChildPostingGroupBatchId
				,pgpC.PostingGroupId			ChildPostingGroupId
				,pgpC.PostingGroupStatusId		ChildPostingGroupStatusId
				,pgpC.PGPBatchSeq				ChildPGPBatchSeq
				,isnull(pgpC.IssueId,-1)		ChildIssueId
				,isnull(pgpC.DistributionId,-1)	ChildDistributionId
				,pgC.PostingGroupCode			ChildPostingGroupCode
				/*
				, pgC.MethodCode				ChildPostingGroupMethodCode
				, pgC.ModeCode					ChildPostingGroupModeCode
				*/
				,ctlI.IssueId					IssueId
				,ctlI.IssueName					IssueName
				,ctlP.PublicationName			PublicationName
				,ctlP.SrcPublicationName		SrcPublicationName
		from	 pg.PostingGroupProcessing		  pgpP
		join	 pg.PostingGroupDependency		  pgd
		on		 pgpP.PostingGroupId			= pgd.ParentId
		join	 pg.PostingGroupProcessing		  pgpC
		on		 pgpC.PostingGroupId			= pgd.ChildId
		join	 pg.PostingGroup				  pgC
		on		 pgC.PostingGroupId				= pgd.ChildId
		join	 ctl.Issue						  ctlI
		on		 pgpC.IssueId					= ctlI.IssueId
		join	 ctl.Publication				  ctlP
		on		 ctlI.PublicationId				= ctlP.PublicationId
		where	 pgpP.PostingGroupBatchId		= @pPostingGroupBatchId
		and		 pgpP.PostingGroupId			= @pPostingGroupId
		and		 pgpP.PGPBatchSeq				= @pPostingGroupBatchSeq
		and		 pgpC.PostingGroupBatchId		= @pPostingGroupBatchId
		and		 pgpC.PGPBatchSeq				= @pPostingGroupBatchSeq
		and		 pgC.PostingGroupCode			= @pChildPostingGroupCode

	-- Insert Log Record
	select	 @PreviousDtm		= @CurrentDtm, @Rows = @@ROWCOUNT 
	select	 @CurrentDtm		= GETDATE()

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
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

	;throw	 @ErrNum, @ErrMsg, 1
	
end catch


-------------------------------------------------------------------------------
--  Procedure End
-------------------------------------------------------------------------------

select	 @CurrentDtm			= getdate()
		,@StepNumber			= @StepNumber + 1
		,@StepName				= 'End'
		,@StepDesc				= 'Procedure completed'
		,@Rows					= 0
		,@StepOperation			= 'N/A'


exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
		,@pVerbose