/****************************************************************************
file:           Publisher.sql
name:           Publisher

purpose:        Provider of publications (feeds).

called by:      
calls:          

author:         ffortunato
date:           20181011

******************************************************************************/

-- ----------------------------------------------------------------------------
-- Table ctl.Publisher
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ctl`.`Publisher` (
  `PublisherId` INT NOT NULL,
  `ContactId` INT NOT NULL,
  `PublisherCode` VARCHAR(20) NOT NULL,
  `PublisherName` VARCHAR(50) NOT NULL,
  `PublisherDesc` VARCHAR(1000) NULL,
  `InterfaceCode` VARCHAR(20) NOT NULL DEFAULT 'N/A',
  /*
  `SiteURL` VARCHAR(256) NULL,
  `SiteUser` VARCHAR(256) NULL,
  `SitePassword` VARBINARY(8000) NULL,
  `SiteHostKeyFingerprint` VARBINARY(8000) NULL,
  `SitePort` VARCHAR(10) NULL,
  `SiteProtocol` VARCHAR(100) NULL,
  `PrivateKeyPassPhrase` VARBINARY(8000) NULL,
  `PrivateKeyFile` VARBINARY(8000) NULL,
  */
  `CreatedBy` VARCHAR(50) NOT NULL,
  `CreatedDtm` DATETIME(6) NOT NULL,
  `ModifiedBy` VARCHAR(50) NULL,
  `ModifiedDtm` DATETIME(6) NULL,
  PRIMARY KEY (`PublisherId`),
  UNIQUE INDEX `UNQ_Publisher__PublisherCode` (`PublisherCode` ASC) VISIBLE,
  INDEX `IDX_Publisher__InterfaceCode` (`InterfaceCode` ASC) VISIBLE,
  CONSTRAINT `FK_Publisher_RefInterface__InterfaceCode`
    FOREIGN KEY (`InterfaceCode`)
    REFERENCES `ctl`.`RefInterface` (`InterfaceCode`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `FK_RefContact__ContactId`
    FOREIGN KEY (`ContactId`)
    REFERENCES `ctl`.`Contact` (`ContactId`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);
/*
-- ALTER TABLE `ctl`.`Publisher` ADD  CONSTRAINT `DF__Publisher__InterfaceCode__NA`  SET DEFAULT (('N/A')) FOR `InterfaceCode`;
ALTER TABLE `ctl`.`Publisher`  ALTER COLUMN  InterfaceCode SET DEFAULT 'N/A';

ALTER TABLE `ctl`.`Publisher`   ADD  CONSTRAINT `FK_RefContact__ContactId` FOREIGN KEY(`ContactId`)
REFERENCES `ctl`.`Contact` (`ContactId`);
 
CREATE INDEX `IDX_Publisher__InterfaceCode`
    ON `ctl`.`Publisher`(`InterfaceCode` ASC) ;
 */

/******************************************************************************
       change history
*******************************************************************************
date		author			description
--------	-------------	---------------------------------------------------
20181011	ffortunato		initial iteration
20201118	ffortunato		fixing some warnings etc.... 
20211007	ffortunato		o PublisherCode 10 --> 20
							+ PublicationDesc
							o DataHube int --> bit
							- MethodCode
20240724	ffortunato		o Convert to MySQL
******************************************************************************/