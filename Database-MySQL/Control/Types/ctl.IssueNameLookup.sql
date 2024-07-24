CREATE TYPE [ctl].[IssueNameLookup] AS TABLE(
	[IssueName] [varchar](255) NULL,
	[FileAction] [varchar](255) NULL,
	[FileCreatedDtm] [datetime] NULL
)
GO