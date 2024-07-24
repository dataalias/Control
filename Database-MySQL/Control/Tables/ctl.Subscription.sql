/******************************************************************************
file:           Subscription.sql
name:           Subscription

purpose:        Provides a list of system that will "get" data.

called by:      
calls:          

author:         ffortunato
date:           20181011

******************************************************************************/

CREATE TABLE [ctl].[Subscription](
	[SubscriptionId] [int] IDENTITY(1,1) NOT NULL,
	[PublicationId] [int] NOT NULL,
	[SubscriberId] [int] NOT NULL,
	[SubscriptionCode] [varchar](100) NOT NULL,
	[SubscriptionName] [varchar](250) NOT NULL,
	[SubscriptionDesc] [varchar](1000) NULL,
	[InterfaceCode] [varchar](20) NOT NULL,
	[IsActive] [int] NOT NULL,
	[SubscriptionFilePath] [varchar](255) NULL,
	[SubscriptionArchivePath] [varchar](255) NULL,
	[SrcFilePath] [varchar](256) NULL,
	[DestTableName] [varchar](255) NULL,
	[DestFileFormatCode] [varchar](20) NULL,
	[CreatedBy] [varchar](50) NOT NULL,
	[CreatedDtm] [datetime] NOT NULL,
	[ModifiedBy] [varchar](50) NULL,
	[ModifiedDtm] [datetime] NULL,
 CONSTRAINT [PK_Subscription__SubscriptionId] PRIMARY KEY CLUSTERED 
(
	[SubscriptionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY],
 CONSTRAINT [UNQ_Subscription__SubscriptionCode] UNIQUE NONCLUSTERED 
(
	[SubscriptionCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [ctl].[Subscription] ADD  CONSTRAINT [DF__Subscription__IsActive__1]  DEFAULT ((1)) FOR [IsActive]
GO

ALTER TABLE [ctl].[Subscription]  ADD  CONSTRAINT [FK_Interface_Subscription__InterfaceCode] FOREIGN KEY([InterfaceCode])
REFERENCES [ctl].[RefInterface] ([InterfaceCode])
GO

ALTER TABLE [ctl].[Subscription]  ADD  CONSTRAINT [FK_FileFormat_Subscription__FileFormatCode] FOREIGN KEY([DestFileFormatCode])
REFERENCES [ctl].[RefFileFormat] ([FileFormatCode])
GO

ALTER TABLE [ctl].[Subscription]  ADD  CONSTRAINT [FK_Subscriber_Subscription__SubscriberId] FOREIGN KEY([SubscriberId])
REFERENCES [ctl].[Subscriber] ([SubscriberId])
GO

/******************************************************************************
       change history
*******************************************************************************
date		author			description
--------	-------------	---------------------------------------------------
20181011	ffortunato		initial iteration
20201118	ffortunato		fixing some warnings etc....
20210325	ffortunato		Changing FeedFormat --> DestFileFormatCode

******************************************************************************/