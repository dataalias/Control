/******************************************************************************
file:           RefTriggerType.sql
name:           RefTriggerType
purpose:        Defines each of the processes that must be triggered 
				in the system.


called by:      
calls:          

author:         ffortunato
date:           20230615

******************************************************************************/

-- ----------------------------------------------------------------------------
-- Table ctl.RefTriggerType
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ctl`.`RefTriggerType` (
  `TriggerTypeCode` VARCHAR(20) NOT NULL,
  `TriggerTypeId` INT NOT NULL,
  `TriggerTypeName` VARCHAR(250) NOT NULL,
  `TriggerTypeDesc` VARCHAR(1000) NOT NULL,
  `CreatedBy` VARCHAR(50) NOT NULL,
  `CreatedDtm` DATETIME(6) NOT NULL,
  `ModifiedBy` VARCHAR(50) NULL,
  `ModifiedDtm` DATETIME(6) NULL,
  PRIMARY KEY (`TriggerTypeCode`));


/******************************************************************************
       change history
*******************************************************************************
date		author			description
--------	-------------	---------------------------------------------------
20210312	ffortunato		initial iteration
******************************************************************************/