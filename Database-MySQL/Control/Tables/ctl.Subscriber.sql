/******************************************************************************
file:           Subscriber.sql
name:           Subscriber

purpose:        Provides a list of feeds a system will "get".

called by:      
calls:          

author:         ffortunato
date:           20181011

******************************************************************************/


CREATE TABLE [ctl].[Subscriber](
	[SubscriberId] [int] IDENTITY(1,1) NOT NULL,
	[ContactId] [int] NOT NULL,
	[SubscriberCode] [varchar](20) NOT NULL,
	[SubscriberName] [varchar](250) NOT NULL,
	[SubscriberDesc] [varchar](1000) NULL,
	[InterfaceCode] [varchar](20) NOT NULL,
	[SiteURL] [varchar](256) NULL,
	[SiteUser] [varchar](256) NULL,
	[SitePassword] [varbinary](8000) NULL,
	[SiteHostKeyFingerprint] [varbinary](8000) NULL,
	[SitePort] [varchar](10) NULL,
	[SiteProtocol] [varchar](100) NULL,
	[PrivateKeyPassPhrase] [varbinary](8000) NULL,
	[PrivateKeyFile] [varbinary](8000) NULL,
	[NotificationHostName] [varchar](255) NOT NULL,
	[NotificationInstance] [varchar](255) NOT NULL,
	[NotificationDatabase] [varchar](255) NOT NULL,
	[NotificationSchema] [varchar](255) NOT NULL,
	[NotificationProcedure] [varchar](255) NOT NULL,
	[NotificationURI] [varchar](255) NOT NULL,
	[NotificationTopic] [varchar](255) NOT NULL,
	[CreatedBy] [varchar](50) NOT NULL,
	[CreatedDtm] [datetime] NULL,
	[ModifiedBy] [varchar](50) NULL,
	[ModifiedDtm] [datetime] NULL,
 CONSTRAINT [PK_Subcriber__SubscriberId] PRIMARY KEY CLUSTERED 
(
	[SubscriberId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90)
)
GO

--ALTER TABLE [ctl].[Subscriber] ADD  DEFAULT ('N/A') FOR [InterfaceCode]
--GO

ALTER TABLE [ctl].[Subscriber] ADD  CONSTRAINT [DF__Subscriber__InterfaceCode__NA]  DEFAULT (('N/A')) FOR [InterfaceCode]
GO

--ALTER TABLE [ctl].[Subscriber] ADD  DEFAULT ('N/A') FOR [NotificationHostName]
--GO

ALTER TABLE [ctl].[Subscriber] ADD  CONSTRAINT [DF__Subscriber__NotificationHostName__NA]  DEFAULT (('N/A')) FOR [NotificationHostName]
GO

--ALTER TABLE [ctl].[Subscriber] ADD  DEFAULT ('N/A') FOR [NotificationInstance]
--GO

ALTER TABLE [ctl].[Subscriber] ADD  CONSTRAINT [DF__Subscriber__NotificationInstance__NA]  DEFAULT (('N/A')) FOR [NotificationInstance]
GO

--ALTER TABLE [ctl].[Subscriber] ADD  DEFAULT ('N/A') FOR [NotificationDatabase]
--GO

ALTER TABLE [ctl].[Subscriber] ADD  CONSTRAINT [DF__Subscriber__NotificationDatabase__NA]  DEFAULT (('N/A')) FOR [NotificationDatabase]
GO

--ALTER TABLE [ctl].[Subscriber] ADD  DEFAULT ('N/A') FOR [NotificationSchema]
--GO

ALTER TABLE [ctl].[Subscriber] ADD  CONSTRAINT [DF__Subscriber__NotificationSchema__NA]  DEFAULT (('N/A')) FOR [NotificationSchema]
GO

--ALTER TABLE [ctl].[Subscriber] ADD  DEFAULT ('N/A') FOR [NotificationProcedure]
--GO

ALTER TABLE [ctl].[Subscriber] ADD  CONSTRAINT [DF__Subscriber__NotificationProcedure__NA]  DEFAULT (('N/A')) FOR [NotificationProcedure]
GO

--ALTER TABLE [ctl].[Subscriber] ADD  DEFAULT ('N/A') FOR [NotificationURI]
--GO

ALTER TABLE [ctl].[Subscriber] ADD  CONSTRAINT [DF__Subscriber__NotificationURI__NA]  DEFAULT (('N/A')) FOR [NotificationURI]
GO

--ALTER TABLE [ctl].[Subscriber] ADD  DEFAULT ('N/A') FOR [NotificationTopic]
--GO

ALTER TABLE [ctl].[Subscriber] ADD  CONSTRAINT [DF__Subscriber__NotificationTopic__NA]  DEFAULT (('N/A')) FOR [NotificationTopic]
GO

ALTER TABLE [ctl].[Subscriber]   ADD  CONSTRAINT [FK_Subscriber_RefInterface__InterfaceCode] FOREIGN KEY([InterfaceCode])
REFERENCES [ctl].[RefInterface] ([InterfaceCode])
GO

--ALTER TABLE [ctl].[Subscriber] CHECK CONSTRAINT [FK_Subscriber_RefInterface__InterfaceCode]
--GO

CREATE UNIQUE NONCLUSTERED INDEX [UNQ_Subscriber__SubscriberCode]
    ON [ctl].[Subscriber]([SubscriberCode] ASC) WITH (FILLFACTOR = 90);
GO


/******************************************************************************
       change history
*******************************************************************************
date		author			description
--------	-------------	---------------------------------------------------
20181011	ffortunato		initial iteration
20201118	ffortunato		fixing some warnings etc.... 
							naming default constraints
******************************************************************************/