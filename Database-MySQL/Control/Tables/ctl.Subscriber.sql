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
CREATE TABLE IF NOT EXISTS `ctl`.`Subscriber` (
  `SubscriberId` INT NOT NULL,
  `ContactId` INT NOT NULL,
  `SubscriberCode` VARCHAR(20) NOT NULL,
  `SubscriberName` VARCHAR(250) NOT NULL,
  `SubscriberDesc` VARCHAR(1000) NULL,
  `InterfaceCode` VARCHAR(20) NOT NULL DEFAULT 'N/A',
  `SiteURL` VARCHAR(256) NULL,
  `SiteUser` VARCHAR(256) NULL,
  `SitePassword` VARBINARY(8000) NULL,
  `SiteHostKeyFingerprint` VARBINARY(8000) NULL,
  `SitePort` VARCHAR(10) NULL,
  `SiteProtocol` VARCHAR(100) NULL,
  `PrivateKeyPassPhrase` VARBINARY(8000) NULL,
  `PrivateKeyFile` VARBINARY(8000) NULL,
  `NotificationHostName` VARCHAR(255) NOT NULL DEFAULT 'N/A',
  `NotificationInstance` VARCHAR(255) NOT NULL DEFAULT 'N/A',
  `NotificationDatabase` VARCHAR(255) NOT NULL DEFAULT 'N/A',
  `NotificationSchema` VARCHAR(255) NOT NULL DEFAULT 'N/A',
  `NotificationProcedure` VARCHAR(255) NOT NULL DEFAULT 'N/A',
  `NotificationURI` VARCHAR(255) NOT NULL DEFAULT 'N/A',
  `NotificationTopic` VARCHAR(255) NOT NULL DEFAULT 'N/A',
  `CreatedBy` VARCHAR(50) NOT NULL,
  `CreatedDtm` DATETIME(6) NULL,
  `ModifiedBy` VARCHAR(50) NULL,
  `ModifiedDtm` DATETIME(6) NULL,
  PRIMARY KEY (`SubscriberId`),
  UNIQUE INDEX `UNQ_Subscriber__SubscriberCode` (`SubscriberCode` ASC) VISIBLE,
  CONSTRAINT `FK_Subscriber_RefInterface__InterfaceCode`
    FOREIGN KEY (`InterfaceCode`)
    REFERENCES `ctl`.`RefInterface` (`InterfaceCode`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);

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