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
CREATE TABLE IF NOT EXISTS `ctl`.`Subscription` (
  `SubscriptionId` INT NOT NULL,
  `PublicationId` INT NOT NULL,
  `SubscriberId` INT NOT NULL,
  `SubscriptionCode` VARCHAR(100) NOT NULL,
  `SubscriptionName` VARCHAR(250) NOT NULL,
  `SubscriptionDesc` VARCHAR(1000) NULL,
  `InterfaceCode` VARCHAR(20) NOT NULL,
  `IsActive` INT NOT NULL DEFAULT 1,
  `SubscriptionFilePath` VARCHAR(255) NULL,
  `SubscriptionArchivePath` VARCHAR(255) NULL,
  `SrcFilePath` VARCHAR(256) NULL,
  `DestTableName` VARCHAR(255) NULL,
  `DestFileFormatCode` VARCHAR(20) NULL,
  `CreatedBy` VARCHAR(50) NOT NULL,
  `CreatedDtm` DATETIME(6) NOT NULL,
  `ModifiedBy` VARCHAR(50) NULL,
  `ModifiedDtm` DATETIME(6) NULL,
  PRIMARY KEY (`SubscriptionId`),
  UNIQUE INDEX `UNQ_Subscription__SubscriptionCode` (`SubscriptionCode` ASC) VISIBLE,
  CONSTRAINT `FK_FileFormat_Subscription__FileFormatCode`
    FOREIGN KEY (`DestFileFormatCode`)
    REFERENCES `ctl`.`RefFileFormat` (`FileFormatCode`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `FK_Subscriber_Subscription__SubscriberId`
    FOREIGN KEY (`SubscriberId`)
    REFERENCES `ctl`.`Subscriber` (`SubscriberId`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `FK_Interface_Subscription__InterfaceCode`
    FOREIGN KEY (`InterfaceCode`)
    REFERENCES `ctl`.`RefInterface` (`InterfaceCode`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);
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