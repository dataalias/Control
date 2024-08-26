/******************************************************************************
file:           RefFileFormat.sql
name:           RefFileFormat

purpose:        Defines each of the processes that must be triggered 
				in the system.


called by:      
calls:          

author:         ffortunato
date:           20210312

******************************************************************************/

-- ----------------------------------------------------------------------------
-- Table ctl.RefFileFormat
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ctl`.`RefFileFormat` (
  `FileFormatCode` VARCHAR(20) NOT NULL,
  `FileFormatId` INT NOT NULL,
  `FileFormatName` VARCHAR(250) NOT NULL,
  `FileFormatDesc` VARCHAR(1000) NOT NULL,
  `FileExtension` VARCHAR(20) NOT NULL,
  `DotFileExtension` VARCHAR(20) NOT NULL,
  `CreatedBy` VARCHAR(50) NOT NULL,
  `CreatedDtm` DATETIME(6) NOT NULL,
  `ModifiedBy` VARCHAR(50) NULL,
  `ModifiedDtm` DATETIME(6) NULL,
  PRIMARY KEY (`FileFormatCode`));



/******************************************************************************
       change history
*******************************************************************************
date		author			description
--------	-------------	---------------------------------------------------
20210312	ffortunato		initial iteration
******************************************************************************/