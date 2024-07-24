CREATE FUNCTION [pg].[fn_GetPostingGroupProcessingDetails] (
		 @pPostingGroupBatchId		int				= -1
		,@pPostingGroupId			int				= -1
		,@pPostingGroupBatchSeq		int				= -1
		,@pChildPostingGroupCode	varchar(100)	= 'N/A'
		,@pETLExecutionId			int				= -1
		,@pPathId					int				= -1
		,@pVerbose					bit				= 0)

/*****************************************************************************
File:		fn_GetPostingGroupProcessingDetails.sql
Name:		fn_GetPostingGroupProcessingDetails
Purpose:    Allows for the retrieval of detailed Posting Group Processing
			information. This includes parent and child details. This 
			procedure does _not_ traverse the dependencies to the leaf level, 
			just next of kin.



select  * from pg.fn_GetPostingGroupProcessingDetails (
		  3
		, 109
		, 3
		,'PUBR01-SUBR01-PUBN01-ACCT'
		, -1
		, -1
		, 0)

Parameters:	@pIssueID - IssueID to retrieve details of

Called by: ETL
Calls:          

Errors:		

Author:		ffortunato
Date:		20181011

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20181011	ffortunato		Initial iteration.

******************************************************************************/

RETURNS @ReturnTable TABLE
(
	 ParentPostingGroupProcessingId	bigint
	,ParentPostingGroupBatchId		int
	,ParentPostingGroupId			int
	,ParentPostingGroupStatusId		int
	,ParentPGPBatchSeq				bigint
	,ChildPostingGroupProcessingId	bigint
	,ChildPostingGroupBatchId		int
	,ChildPostingGroupId			int
	,ChildPostingGroupStatusId		int
	,ChildPGPBatchSeq				bigint
		--,ChildRetryCount				int
	,ChildIssueId					bigint
	,ChildDistributionId			bigint
	,ChildPostingGroupCode			varchar(100)
)
AS
BEGIN
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
			insert into @ReturnTable
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
			insert into @ReturnTable
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
	return
end

