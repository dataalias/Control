-- ----------------------------------------------------------------------------
-- Table ctl.RefStatus
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ctl`.`RefStatus` (
  `StatusId` INT NOT NULL,
  `StatusCode` VARCHAR(20) NOT NULL,
  `StatusName` VARCHAR(100) NOT NULL,
  `StatusDesc` VARCHAR(255) NOT NULL,
  `StatusType` VARCHAR(100) NOT NULL,
  `CreatedBy` VARCHAR(50) NOT NULL,
  `CreatedDtm` DATETIME(6) NOT NULL,
  `ModifiedBy` VARCHAR(50) NULL,
  `ModifiedDtm` DATETIME(6) NULL,
  PRIMARY KEY (`StatusId`),
  UNIQUE INDEX `UNQ_RefStatus__StatusCode` (`StatusCode` ASC) VISIBLE);

