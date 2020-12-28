/******************************************************************************
file:           Publisher.sql
name:           Publisher

purpose:        Provider of publications (feeds).

called by:      
calls:          

author:         ffortunato
date:           20181011

******************************************************************************/

CREATE TABLE [ctl].[Publisher](
	[PublisherId] [int] IDENTITY(1,1) NOT NULL,
	[ContactId] [int] NOT NULL,
	[PublisherCode] [varchar](10) NOT NULL,
	[PublisherName] [varchar](50) NOT NULL,
	[PublisherDesc] [varchar](1000) NULL,
	[InterfaceCode] [varchar](20) NOT NULL,
	[SiteURL] [varchar](256) NULL,
	[SiteUser] [varchar](256) NULL,
	[SitePassword] [varbinary](8000) NULL,
	[SiteHostKeyFingerprint] [varbinary](8000) NULL,
	[SitePort] [varchar](10) NULL,
	[SiteProtocol] [varchar](100) NULL,
	[PrivateKeyPassPhrase] [varbinary](8000) NULL,
	[PrivateKeyFile] [varbinary](8000) NULL,
	[CreatedBy] [varchar](50) NOT NULL,
	[CreatedDtm] [datetime] NOT NULL,
	[ModifiedBy] [varchar](50) NULL,
	[ModifiedDtm] [datetime] NULL,
 CONSTRAINT [PK_PubrPublisherId] PRIMARY KEY CLUSTERED 
(
	[PublisherId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90),
 CONSTRAINT [UNQ_Publisher__PublisherCode] UNIQUE NONCLUSTERED 
(
	[PublisherCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90)
)
GO

--ALTER TABLE [ctl].[Publisher] ADD  DEFAULT ('N/A') FOR [InterfaceCode]
--GO

ALTER TABLE [ctl].[Publisher] ADD  CONSTRAINT [DF__Publisher__InterfaceCode__NA]  DEFAULT (('N/A')) FOR [InterfaceCode]
GO

ALTER TABLE [ctl].[Publisher]   ADD  CONSTRAINT [FK_Publisher_RefInterface__InterfaceCode] FOREIGN KEY([InterfaceCode])
REFERENCES [ctl].[RefInterface] ([InterfaceCode])
GO

--ALTER TABLE [ctl].[Publisher] CHECK CONSTRAINT [FK_Publisher_RefInterface__InterfaceCode]
--GO

ALTER TABLE [ctl].[Publisher]   ADD  CONSTRAINT [FK_RefContact__ContactId] FOREIGN KEY([ContactId])
REFERENCES [ctl].[Contact] ([ContactId])
GO

--ALTER TABLE [ctl].[Publisher] CHECK CONSTRAINT [FK_RefContact__ContactId]
--GO

CREATE NONCLUSTERED INDEX [IDX_Publisher__InterfaceCode]
    ON [ctl].[Publisher]([InterfaceCode] ASC) WITH (FILLFACTOR = 90);
GO

/******************************************************************************
       change history
*******************************************************************************
date		author			description
--------	-------------	---------------------------------------------------
20181011	ffortunato		initial iteration
20201118	ffortunato		fixing some warnings etc.... 

******************************************************************************/