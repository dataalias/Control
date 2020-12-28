CREATE TABLE [ctl].[MapContactToPublication](
	[ContactToPublicationId] [int] IDENTITY(1,1) NOT NULL,
	[ContactId] [int] NOT NULL,
	[PublicationId] [int] NOT NULL,
	[ContactToPublicationDesc] [varchar](max) NULL,
	[CreatedBy] [varchar](50) NOT NULL,
	[CreatedDtm] [datetime] NOT NULL,
	[ModifiedBy] [varchar](50) NULL,
	[ModifiedDtm] [datetime] NULL,
 CONSTRAINT [PK_ContactToPublicationId] PRIMARY KEY CLUSTERED 
(
	[ContactToPublicationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_MapContactToPublication__ContactId_PublicationId]
    ON [ctl].[MapContactToPublication]([ContactId] ASC, [PublicationId] ASC) WITH (FILLFACTOR = 90);
GO

ALTER TABLE [ctl].[MapContactToPublication]  ADD  CONSTRAINT [FK_MapContactToPublication_Publication__PublicationId] FOREIGN KEY([PublicationId])
REFERENCES [ctl].[Publication] ([PublicationId])
GO

ALTER TABLE [ctl].[MapContactToPublication] CHECK CONSTRAINT [FK_MapContactToPublication_Publication__PublicationId]
GO

ALTER TABLE [ctl].[MapContactToPublication]  ADD  CONSTRAINT [FK_MapContactToPublication_Contact__ContactId] FOREIGN KEY([ContactId])
REFERENCES [ctl].[Contact] ([ContactId])
GO