/******************************************************************************
file:           Subscriber.sql
name:           Subscriber

purpose:        Provides a list of feeds a system will "get".

called by:      
calls:          

author:         ffortunato
date:           20181011

******************************************************************************/


-- ----------------------------------------------------------------------------
-- Table ctl.Subscriber
-- ----------------------------------------------------------------------------
-- ************************************** DATA_HUB.Subscriber
CREATE OR REPLACE TABLE ULTRA_@ENV@_RAW.DATA_HUB.Subscriber
(
 SubscriberId           integer NOT NULL AUTOINCREMENT START 1 INCREMENT 1 order,
 ContactName            varchar(255) NOT NULL,
 SubscriberCode         varchar(25) NOT NULL,
 SubscriberName         varchar(255) NOT NULL,
 SubscriberDesc         varchar(255),
 InterfaceCode          varchar(25) NOT NULL DEFAULT (('N/A')),
 SecretKey              varchar(255),
 /*
 SiteURL                varchar(255),
 SiteUser               varchar(255),
 SitePassword           binary(8388608),
 SiteHostKeyFingerprint binary(8388608),
 SitePort               varchar(255),
 SiteProtocol           varchar(255),
 PrivateKeyPassPhrase   binary(8388608),
 PrivateKeyFile         binary(8388608),
 */
 NotificationHostName   varchar(255) NOT NULL DEFAULT (('N/A')),
 NotificationInstance   varchar(255) NOT NULL DEFAULT (('N/A')),
 NotificationDatabase   varchar(255) NOT NULL DEFAULT (('N/A')),
 NotificationSchema     varchar(255) NOT NULL DEFAULT (('N/A')),
 NotificationProcedure  varchar(255) NOT NULL DEFAULT (('N/A')),
 NotificationURI        varchar(255) NOT NULL DEFAULT (('N/A')),
 NotificationTopic      varchar(255) NOT NULL DEFAULT (('N/A')),
 CreatedBy              varchar(255) NOT NULL,
 CreatedDtm             date,
 ModifiedBy             varchar(255),
 ModifiedDtm            date,

 CONSTRAINT PK_Subcriber__SubscriberId PRIMARY KEY ( SubscriberId ),
 CONSTRAINT UNQ_Subscriber__SubscriberCode UNIQUE ( SubscriberCode ),
 CONSTRAINT FK_Subscriber_RefInterface__InterfaceCode FOREIGN KEY ( InterfaceCode ) REFERENCES DATA_HUB.REF_Interface ( InterfaceCode )
);

/*
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
*/

/******************************************************************************
       change history
*******************************************************************************
date		author			description
--------	-------------	---------------------------------------------------
20181011	ffortunato		initial iteration
20201118	ffortunato		fixing some warnings etc.... 
							naming default constraints
******************************************************************************/