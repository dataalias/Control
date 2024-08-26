-- ----------------------------------------------------------------------------
-- Table ctl.MapContactToSubscription
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ctl`.`MapContactToSubscription` (
  `ContactToSubscriptionId` INT NOT NULL,
  `ContactId` INT NOT NULL,
  `SubscriptionId` INT NOT NULL,
  `ContactToSubscriptionDesc` LONGTEXT NULL,
  `CreatedBy` VARCHAR(50) NOT NULL,
  `CreatedDtm` DATETIME(6) NOT NULL,
  `ModifiedBy` VARCHAR(50) NULL,
  `ModifiedDtm` DATETIME(6) NULL,
  PRIMARY KEY (`ContactToSubscriptionId`),
  UNIQUE INDEX `UQ_MapContactToSubscription__ContactId_SubscriptionId` (`ContactId` ASC, `SubscriptionId` ASC) VISIBLE,
  CONSTRAINT `FK_MapContactToSubscription_Subscription__SubscriptionId`
    FOREIGN KEY (`SubscriptionId`)
    REFERENCES `ctl`.`Subscription` (`SubscriptionId`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `FK_MapContactToSubscription_Contact__ContactId`
    FOREIGN KEY (`ContactId`)
    REFERENCES `ctl`.`Contact` (`ContactId`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);

/*
CREATE UNIQUE NONCLUSTERED INDEX [UQ_MapContactToSubscription__ContactId_SubscriptionId]
    ON [ctl].[MapContactToSubscription]([ContactId] ASC, [SubscriptionId] ASC) WITH (FILLFACTOR = 90);
GO

ALTER TABLE [ctl].[MapContactToSubscription]  ADD  CONSTRAINT [FK_MapContactToSubscription_Subscription__SubscriptionId] FOREIGN KEY([SubscriptionId])
REFERENCES [ctl].[Subscription] ([SubscriptionId])
GO

ALTER TABLE [ctl].[MapContactToSubscription] CHECK CONSTRAINT [FK_MapContactToSubscription_Subscription__SubscriptionId]
GO

ALTER TABLE [ctl].[MapContactToSubscription]  ADD  CONSTRAINT [FK_MapContactToSubscription_Contact__ContactId] FOREIGN KEY([ContactId])
REFERENCES [ctl].[Contact] ([ContactId])
GO
*/