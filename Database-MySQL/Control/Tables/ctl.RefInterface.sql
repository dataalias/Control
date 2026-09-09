-- ----------------------------------------------------------------------------
-- Table ctl.RefInterface
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ctl`.`RefInterface` (
  `InterfaceCode` VARCHAR(20) NOT NULL,
  `InterfaceId` INT NOT NULL,
  `InterfaceName` VARCHAR(250) NULL,
  `InterfaceDesc` VARCHAR(1000) NOT NULL,
  `CreatedBy` VARCHAR(50) NOT NULL,
  `CreatedDtm` DATETIME(6) NOT NULL,
  `ModifiedBy` VARCHAR(50) NULL,
  `ModifiedDtm` DATETIME(6) NULL,
  PRIMARY KEY (`InterfaceCode`));