
-- ----------------------------------------------------------------------------
-- Table ctl.Contact
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ctl`.`Contact` (
  `ContactId` INT NOT NULL,
  `CompanyName` VARCHAR(250) NOT NULL,
  `ContactName` VARCHAR(250) NOT NULL DEFAULT 'N/A',
  `Tier` VARCHAR(20) NULL,
  `Email` VARCHAR(100) NULL,
  `Phone` VARCHAR(20) NULL,
  `SupportURL` VARCHAR(1000) NULL,
  `Address01` VARCHAR(100) NULL,
  `Address02` VARCHAR(100) NULL,
  `City` VARCHAR(30) NULL,
  `State` VARCHAR(10) NULL,
  `ZipCode` VARCHAR(10) NULL,
  `CreatedBy` VARCHAR(50) NOT NULL,
  `CreatedDtm` DATETIME(6) NOT NULL,
  `ModifiedBy` VARCHAR(50) NULL,
  `ModifiedDtm` DATETIME(6) NULL,
  PRIMARY KEY (`ContactId`),
  UNIQUE INDEX `UNQ_Contact__Name` (`ContactName` ASC) VISIBLE);
 

-- ALTER TABLE `dh`.`Contact` ADD  CONSTRAINT `DF__Contact__Name__NA`  DEFAULT ('N/A') FOR `ContactName`;
