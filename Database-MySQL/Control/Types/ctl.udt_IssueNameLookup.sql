CREATE TYPE [ctl].[udt_IssueNameLookup] AS TABLE(
	[IssueName] [varchar](255) NOT NULL,
	[FileAction] [varchar](255) NOT NULL,
	[FileCreatedDtm] [datetime] NULL
)
GO