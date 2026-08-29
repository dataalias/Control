-- ----------------------------------------------------------------------------
-- Table ctl.Passphrase
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ctl`.`Passphrase` (
  `PassPhraseID` INT NOT NULL,
  `DatabaseName` VARCHAR(255) NOT NULL,
  `SchemaName` VARCHAR(255) NOT NULL,
  `TableName` VARCHAR(255) NOT NULL,
  `Passphrase` VARCHAR(100) NOT NULL,
  `CreatedBy` VARCHAR(100) NOT NULL,
  `CreatedDtm` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ModifiedBy` VARCHAR(100) NULL,
  `ModifiedDtm` DATETIME(6) NULL,
  PRIMARY KEY (`PassPhraseID`),
  UNIQUE INDEX `UNQ_PassPhrase__SchemaName_TableName_Passphrase` (`SchemaName` ASC, `TableName` ASC, `Passphrase` ASC) VISIBLE);
/*
CREATE UNIQUE NONCLUSTERED INDEX [UNQ_PassPhrase__SchemaName_TableName_Passphrase]
    ON [ctl].[Passphrase]([SchemaName],[TableName],[Passphrase]) WITH (FILLFACTOR = 90);
GO

ALTER TABLE ctl.[Passphrase] ADD  CONSTRAINT [DF__Passphrase__CreatedBy__CurrentUser]  DEFAULT ((CURRENT_USER)) FOR [CreatedBy]
GO

ALTER TABLE ctl.[Passphrase] ADD  CONSTRAINT [DF__Passphrase__CreatedDtm__getdate]  DEFAULT ((getdate())) FOR [CreatedDtm]
GO
*/