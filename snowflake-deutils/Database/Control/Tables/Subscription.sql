/******************************************************************************
file:           Subscription.sql
name:           Subscription

purpose:        Provides a list of system that will "get" data.

called by:      
calls:          

author:         ffortunato
date:           20181011

******************************************************************************/

-- ----------------------------------------------------------------------------
-- Table ctl.Subscription
-- ----------------------------------------------------------------------------
-- ************************************** DATA_HUB.Subscription
CREATE OR REPLACE TABLE DATA_HUB.Subscription
(
 SubscriptionId          integer NOT NULL AUTOINCREMENT START 1 INCREMENT 1 order,
 PublicationCode         varchar(25) NOT NULL,
 SubscriberCode          varchar(25) NOT NULL,
 SubscriptionCode        varchar(25) NOT NULL,
 SubscriptionName        varchar(255) NOT NULL,
 SubscriptionDesc        varchar(255),
 InterfaceCode           varchar(25) NOT NULL,
 IsActive                integer NOT NULL DEFAULT ((1)),
 SubscriptionFilePath    varchar(255),
 SubscriptionArchivePath varchar(255),
 SrcFilePath             varchar(255),
 DestTableName           varchar(255),
 DestFileFormatCode      varchar(25),
 CreatedBy               varchar(255) NOT NULL,
 CreatedDtm              date NOT NULL,
 ModifiedBy              varchar(255),
 ModifiedDtm             date,

 CONSTRAINT PK_Subscription__SubscriptionId PRIMARY KEY ( SubscriptionId ),
 CONSTRAINT UNQ_Subscription__SubscriptionCode UNIQUE ( SubscriptionCode ),
 CONSTRAINT FK_FileFormat_Subscription__FileFormatCode FOREIGN KEY ( DestFileFormatCode ) REFERENCES DATA_HUB.REF_File_Format ( FileFormatCode ),
 CONSTRAINT FK_Interface_Subscription__InterfaceCode FOREIGN KEY ( InterfaceCode ) REFERENCES DATA_HUB.REF_Interface ( InterfaceCode ),
 CONSTRAINT FK_Subscriber_Subscription__SubscriberId FOREIGN KEY ( SubscriberCode ) REFERENCES DATA_HUB.Subscriber ( SubscriberCode )
);
/*
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
*/
/******************************************************************************
       change history
*******************************************************************************
date		author			description
--------	-------------	---------------------------------------------------
20181011	ffortunato		initial iteration
20201118	ffortunato		fixing some warnings etc....
20210325	ffortunato		Changing FeedFormat --> DestFileFormatCode

******************************************************************************/