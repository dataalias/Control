-- ----------------------------------------------------------------------------
-- Table ctl.RefInterval
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ctl`.`RefInterval` (
  `IntervalCode` VARCHAR(20) NOT NULL,
  `IntervalId` INT NOT NULL,
  `IntervalName` VARCHAR(250) NULL,
  `IntervalDesc` VARCHAR(1000) NULL,
  `SLAFormat` VARCHAR(100) NULL,
  `SLARegEx` VARCHAR(100) NULL,
  `CreatedBy` VARCHAR(50) NOT NULL,
  `CreatedDtm` DATETIME(6) NOT NULL,
  `ModifiedBy` VARCHAR(50) NULL,
  `ModifiedDtm` DATETIME(6) NULL,
  PRIMARY KEY (`IntervalCode`));