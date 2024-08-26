-- ----------------------------------------------------------------------------
-- Table ctl.MapContactToPublication
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ctl`.`MapContactToPublication` (
  `ContactToPublicationId` INT NOT NULL,
  `ContactId` INT NOT NULL,
  `PublicationId` INT NOT NULL,
  `ContactToPublicationDesc` LONGTEXT NULL,
  `CreatedBy` VARCHAR(50) NOT NULL,
  `CreatedDtm` DATETIME(6) NOT NULL,
  `ModifiedBy` VARCHAR(50) NULL,
  `ModifiedDtm` DATETIME(6) NULL,
  PRIMARY KEY (`ContactToPublicationId`),
  UNIQUE INDEX `UQ_MapContactToPublication__ContactId_PublicationId` (`ContactId` ASC, `PublicationId` ASC) VISIBLE,
  CONSTRAINT `FK_MapContactToPublication_Publication__PublicationId`
    FOREIGN KEY (`PublicationId`)
    REFERENCES `ctl`.`Publication` (`PublicationId`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `FK_MapContactToPublication_Contact__ContactId`
    FOREIGN KEY (`ContactId`)
    REFERENCES `ctl`.`Contact` (`ContactId`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);

/*
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
*/