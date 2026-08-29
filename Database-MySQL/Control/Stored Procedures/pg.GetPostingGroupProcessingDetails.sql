CREATE procedure [pg].[GetPostingGroupProcessingDetails] (
		 @pPostingGroupBatchId		int				= -1
		,@pPostingGroupId			int				= -1
		,@pPostingGroupBatchSeq		int				= -1
--		,@pParentPostingGroupCode	varchar(100)	= 'N/A' 
		,@pChildPostingGroupCode	varchar(100)	= 'N/A'
		,@pETLExecutionId			int				= -1
		,@pPathId					int				= -1
		,@pVerbose					bit				= 0)
as

/*****************************************************************************
File:		GetPostingGroupProcessingDetails.sql
Name:		GetPostingGroupProcessingDetails
Purpose:    Allows for the retrieval of detailed Posting Group Processing
			information. This includes parent and child details. This 
			procedure does _not_ traverse the dependencies to the leaf level, 
			just next of kin.

exec pg.GetPostingGroupProcessingDetails
		 @pPostingGroupBatchId		= 3
		,@pPostingGroupId			= 109
		,@pPostingGroupBatchSeq		= 3
		,@pChildPostingGroupCode    = 'PUBR01-SUBR01-PUBN01-ACCT'
		,@pETLExecutionId			= -1
		,@pPathId					= -1
		,@pVerbose					= 0

Parameters:	@pIssueID - IssueID to retrieve details of

Called by: ETL
Calls:          

Errors:		

Author:		ffortunato
Date:		20180803

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20180803	ffortunato		Initial iteration.
20180918	ffortunato		More data returned.
20180925	ffortunato		ADded ChildCostingGroupCode as a parameter.

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

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------
select	 @ParametersPassedChar	= 
      '***** Parameters Passed to exec pg.GetPostingGroupProcessingDetails' + @CRLF +
      '     @pPGBId = ' + isnull(cast(@pPostingGroupBatchId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pPGId = ' + isnull(cast(@pPostingGroupId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pPGBatchSeq = ' + isnull(cast(@pPostingGroupBatchSeq as varchar(100)),'NULL') + @CRLF + 
	  '    ,@pChildPostingGroupCode = ' + isnull(@pChildPostingGroupCode,'NULL') + @CRLF + 
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
	select	 @StepName			= 'Select Issue Records'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Select'
			,@StepDesc			= 'SelectiNg records from Issue table for the given IssueId'
			,@JSONSnippet		= '{' + @CRLF +
										@Tab + @Tab + '"@pPostingGroupBatchId": "' + cast(@pPostingGroupBatchId as varchar(200)) + '"' + @CRLF +
										@Tab + @Tab + '"@pPostingGroupId": "' + cast(@pPostingGroupId as varchar(200)) + '"' + @CRLF +
										@Tab + @Tab + '"@pPostingGroupBatchSeq": "' + cast(@pPostingGroupBatchSeq as varchar(200)) + '"' + @CRLF +
										@Tab + @Tab + '"@pChildPostingGroupCode": "' + @pChildPostingGroupCode + '"' + @CRLF +
										@Tab + '}'+ @CRLF 



	if exists
	( 
		select	 top 1 1
		from	 pg.PostingGroupProcessing	  pgp
		where	 pgp.PostingGroupBatchId	= @pPostingGroupBatchId
		and		 pgp.PostingGroupId			= @pPostingGroupId
		and		 pgp.PGPBatchSeq			= @pPostingGroupBatchSeq
	)
	begin
		if (@pChildPostingGroupCode <> 'N/A')
		begin	
	
  			select	 pgpP.PostingGroupProcessingId	ParentPostingGroupProcessingId
					,pgpP.PostingGroupBatchId		ParentPostingGroupBatchId
					,pgpP.PostingGroupId			ParentPostingGroupId
					,pgpP.PostingGroupStatusId		ParentPostingGroupStatusId
					,pgpP.PGPBatchSeq				ParentPGPBatchSeq
	--				,pgpP.RetryCount				ParentRetryCount
	--				,pgpP.IssueId					ParentIssueId
	--				,pgpP.DistributionId			ParentDistributionId
	--				, pgP.PostingGroupCode			ParentPostingGroupCode
					,pgpC.PostingGroupProcessingId	ChildPostingGroupProcessingId
					,pgpC.PostingGroupBatchId		ChildPostingGroupBatchId
					,pgpC.PostingGroupId			ChildPostingGroupId
					,pgpC.PostingGroupStatusId		ChildPostingGroupStatusId
					,pgpC.PGPBatchSeq				ChildPGPBatchSeq
	--				,pgpC.RetryCount				ChildRetryCount
					,isnull(pgpC.IssueId,-1)		ChildIssueId
					,isnull(pgpC.DistributionId,-1)	ChildDistributionId
					, pgC.PostingGroupCode			ChildPostingGroupCode
			from	   pg.PostingGroupProcessing	  pgpP
			join	   pg.PostingGroupDependency	  pgd
			on		 pgpP.PostingGroupId			= pgd.ParentId
	--		join	   pg.PostingGroup				  pgP
	--		on		  pgP.PostingGroupId			= pgd.ParentId
			join	   pg.PostingGroupProcessing	  pgpC
			on		 pgpC.PostingGroupId			= pgd.ChildId
			join	   pg.PostingGroup				  pgC
			on		  pgC.PostingGroupId			= pgd.ChildId
			where	 pgpP.PostingGroupBatchId		= @pPostingGroupBatchId
			and		 pgpP.PostingGroupId			= @pPostingGroupId
			and		 pgpP.PGPBatchSeq				= @pPostingGroupBatchSeq
			and		 pgpC.PostingGroupBatchId		= @pPostingGroupBatchId
			and		 pgpC.PGPBatchSeq				= @pPostingGroupBatchSeq
			and		  pgC.PostingGroupCode			= @pChildPostingGroupCode
		end --ChildPostingGroupProvided
		else
		begin
			
  			select	 pgpP.PostingGroupProcessingId	ParentPostingGroupProcessingId
					,pgpP.PostingGroupBatchId		ParentPostingGroupBatchId
					,pgpP.PostingGroupId			ParentPostingGroupId
					,pgpP.PostingGroupStatusId		ParentPostingGroupStatusId
					,pgpP.PGPBatchSeq				ParentPGPBatchSeq
	--				,pgpP.RetryCount				ParentRetryCount
	--				,pgpP.IssueId					ParentIssueId
	--				,pgpP.DistributionId			ParentDistributionId
	--				, pgP.PostingGroupCode			ParentPostingGroupCode
					,pgpC.PostingGroupProcessingId	ChildPostingGroupProcessingId
					,pgpC.PostingGroupBatchId		ChildPostingGroupBatchId
					,pgpC.PostingGroupId			ChildPostingGroupId
					,pgpC.PostingGroupStatusId		ChildPostingGroupStatusId
					,pgpC.PGPBatchSeq				ChildPGPBatchSeq
	--				,pgpC.RetryCount				ChildRetryCount
					,isnull(pgpC.IssueId,-1)		ChildIssueId
					,isnull(pgpC.DistributionId,-1)	ChildDistributionId
					, pgC.PostingGroupCode			ChildPostingGroupCode
			from	   pg.PostingGroupProcessing	  pgpP
			join	   pg.PostingGroupDependency	  pgd
			on		 pgpP.PostingGroupId			= pgd.ParentId
	--		join	   pg.PostingGroup				  pgP
	--		on		  pgP.PostingGroupId			= pgd.ParentId
			join	   pg.PostingGroupProcessing	  pgpC
			on		 pgpC.PostingGroupId			= pgd.ChildId
			join	   pg.PostingGroup				  pgC
			on		  pgC.PostingGroupId			= pgd.ChildId
			where	 pgpP.PostingGroupBatchId		= @pPostingGroupBatchId
			and		 pgpP.PostingGroupId			= @pPostingGroupId
			and		 pgpP.PGPBatchSeq				= @pPostingGroupBatchSeq
			and		 pgpC.PostingGroupBatchId		= @pPostingGroupBatchId
			and		 pgpC.PGPBatchSeq				= @pPostingGroupBatchSeq
		end -- Not child posting ggroup code provided.
	end
	else
	begin

		select   @ErrNum		= 50001
				,@MessageType	= 'ErrCust'
				,@ErrMsg		= 'Unable to look up Processing record.'

		; throw @ErrNum, @ErrMsg, 1  -- This is thrown to the catch block below.

	end

	-- Insert Log Record
	select	 @PreviousDtm		= @CurrentDtm, @Rows = @@ROWCOUNT 
	select	 @CurrentDtm		= GETDATE()
	exec	 [audit].usp_InsertStepLog @MessageType, @CurrentDtm, @PreviousDtm, @StepNumber, @StepOperation, @JSONSnippet, @ErrNum, @ParametersPassedChar, @ErrMsg OUTPUT, @ParentStepLogId, @ProcName, @ProcessType, @StepName, @StepDesc OUTPUT, @StepStatus, @DbName, @Rows, @pETLExecutionId, @pPathId, @PrevStepLog OUTPUT, @pVerbose

end try

-------------------------------------------------------------------------------
--  Error Handling
-------------------------------------------------------------------------------
begin catch
	select 	 @PreviousDtm		= @CurrentDtm
			,@ErrNum			= @@ERROR
			,@ErrMsg			= ERROR_MESSAGE()

	select	 @StepStatus		= 'Failure'
			,@Rows				= @@ROWCOUNT
			,@CurrentDtm		= GETDATE()

	if		 @MessageType		<> 'ErrCust'
		select   @MessageType	= 'ErrSQL'

	exec	 [audit].usp_InsertStepLog @MessageType, @CurrentDtm, @PreviousDtm, @StepNumber, @StepOperation, @JSONSnippet, @ErrNum, @ParametersPassedChar, @ErrMsg OUTPUT, @ParentStepLogId, @ProcName, @ProcessType, @StepName, @StepDesc OUTPUT, @StepStatus, @DbName, @Rows, @pETLExecutionId, @pPathId, @PrevStepLog OUTPUT, @pVerbose

	if 	@ErrNum < 50000	
		select	 @ErrNum	= @ErrNum + 100000000 -- Need to increase number to throw message.

	;throw	 @ErrNum, @ErrMsg, 1
end catch

-------------------------------------------------------------------------------
--  Procedure End
-------------------------------------------------------------------------------
-- removed end log
-------------------------------------------------------------------------------
