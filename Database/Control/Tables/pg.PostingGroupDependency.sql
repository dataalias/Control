/******************************************************************************
file:           PostingGroupDependency.sql
name:           PostingGroupDependency

purpose:        Provides a list of dependencies between posting groups.

called by:      
calls:          

author:         ffortunato
date:           20181011

*******************************************************************************
       change history
*******************************************************************************
date		author			description
--------	-------------	---------------------------------------------------
20181011	ffortunato		initial iteration
20201118	ffortunato		fixing some warnings etc....

******************************************************************************/

CREATE TABLE [pg].[PostingGroupDependency](
	[PostingGroupDependencyId] [int] IDENTITY(1,1) NOT NULL,
	[ChildId] [int] NOT NULL,
	[ParentId] [int] NOT NULL,
	[DependencyCode] [varchar](100) NULL,
	[DependencyName] [varchar](250) NULL,
	[DependencyDesc] [varchar](max) NULL,
	[CreatedBy] [varchar](50) NOT NULL,
	[CreatedDtm] [datetime] NULL,
	[ModifiedBy] [varchar](50) NULL,
	[ModifiedDtm] [datetime] NULL,
 CONSTRAINT [PK_PGD__PostingGroupDependencyId] PRIMARY KEY CLUSTERED 
(
	[PostingGroupDependencyId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90)
)
GO

ALTER TABLE [pg].[PostingGroupDependency]  ADD  CONSTRAINT [FK_PGD_PG__ChildPostingGroupId] FOREIGN KEY([ChildId])
REFERENCES [pg].[PostingGroup] ([PostingGroupId])
GO

--ALTER TABLE [pg].[PostingGroupDependency] CHECK CONSTRAINT [FK_PGD_PG__ChildPostingGroupId]
--GO

ALTER TABLE [pg].[PostingGroupDependency]   ADD  CONSTRAINT [FK_PGD_PG__ParentPostingGroupId] FOREIGN KEY([ParentId])
REFERENCES [pg].[PostingGroup] ([PostingGroupId])
GO

--ALTER TABLE [pg].[PostingGroupDependency] CHECK CONSTRAINT [FK_PGD_PG__ParentPostingGroupId]
--GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_PGD__ChildId_ParentId]
    ON [pg].[PostingGroupDependency]([ChildId] ASC, [ParentId] ASC) WITH (FILLFACTOR = 90);
GO