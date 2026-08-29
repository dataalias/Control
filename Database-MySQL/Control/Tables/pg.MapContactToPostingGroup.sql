CREATE TABLE [pg].[MapContactToPostingGroup](
	[ContactToPostingGroupId] [int] IDENTITY(1,1) NOT NULL,
	[ContactId] [int] NOT NULL,
	[PostingGroupId] [int] NOT NULL,
	[ContactToPostingGroupDesc] [varchar](max) NULL,
	[CreatedBy] [varchar](50) NOT NULL,
	[CreatedDtm] [datetime] NOT NULL,
	[ModifiedBy] [varchar](50) NULL,
	[ModifiedDtm] [datetime] NULL,
 CONSTRAINT [PK_ContactToPostingGroupId] PRIMARY KEY CLUSTERED 
(
	[ContactToPostingGroupId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_MapContactToPostingGroup__ContactId_PostingGroupId]
    ON [pg].[MapContactToPostingGroup]([ContactId] ASC, [PostingGroupId] ASC) WITH (FILLFACTOR = 90);
GO

ALTER TABLE [pg].[MapContactToPostingGroup]  ADD  CONSTRAINT [FK_MapContactToPostingGroup_PostingGroup__PostingGroupId] FOREIGN KEY([PostingGroupId])
REFERENCES [pg].[PostingGroup] ([PostingGroupId])
GO

ALTER TABLE [pg].[MapContactToPostingGroup] CHECK CONSTRAINT [FK_MapContactToPostingGroup_PostingGroup__PostingGroupId]
GO

ALTER TABLE [pg].[MapContactToPostingGroup]  ADD  CONSTRAINT [FK_MapContactToPostingGroup_Contact__ContactId] FOREIGN KEY([ContactId])
REFERENCES [ctl].[Contact] ([ContactId])
GO