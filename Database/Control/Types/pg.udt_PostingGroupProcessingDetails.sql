CREATE TYPE [pg].[udt_PostingGroupProcessingDetails] AS TABLE(
	[ParentPostingGroupProcessingId] [bigint] NOT NULL,
	[ParentPostingGroupBatchId] [int] NOT NULL,
	[ParentPostingGroupId] [int] NOT NULL,
	[ParentPostingGroupStatusId] [int] NOT NULL,
	[ParentPGPBatchSeq] [int] NOT NULL,
	[ChildPostingGroupProcessingId] [bigint] NOT NULL,
	[ChildPostingGroupBatchId] [int] NOT NULL,
	[ChildPostingGroupId] [int] NOT NULL,
	[ChildPostingGroupStatusId] [int] NOT NULL,
	[ChildPGPBatchSeq] [int] NOT NULL,
	[ChildIssueId] [int] NOT NULL,
	[ChildDistributionId] [bigint] NOT NULL,
	[ChildPostingGroupCode] [varchar](100) NOT NULL
)
GO