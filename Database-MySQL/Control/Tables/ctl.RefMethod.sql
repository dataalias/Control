-- ----------------------------------------------------------------------------
-- Table ctl.RefMethod
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ctl`.`RefMethod` (
  `MethodCode` VARCHAR(20) NOT NULL,
  `MethodId` INT NOT NULL,
  `MethodName` VARCHAR(250) NULL,
  `MethodDesc` VARCHAR(1000) NULL,
  `CreatedBy` VARCHAR(50) NOT NULL,
  `CreatedDtm` DATETIME(6) NOT NULL,
  `ModifiedBy` VARCHAR(50) NULL,
  `ModifiedDtm` DATETIME(6) NULL,
  PRIMARY KEY (`MethodCode`));