/*****************************************************************************
File:		RefTransferMethod.sql
Name:		RefTransferMethod

Purpose:	

			DLT: Delta Processing (DLT) - Only the changes siunce the last pull are derived from the source.
			SS : Snap Shot (SS) - The entire entity is pulled from the source.

Author:		ffortunato
Date:		20181002

******************************************************************************/

-- ----------------------------------------------------------------------------
-- Table ctl.RefTransferMethod
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ctl`.`RefTransferMethod` (
  `TransferMethodId` INT NOT NULL,
  `TransferMethodCode` VARCHAR(20) NOT NULL,
  `TransferMethodName` VARCHAR(250) NOT NULL,
  `TransferMethodDesc` VARCHAR(1000) NOT NULL,
  `CreatedBy` VARCHAR(50) NOT NULL,
  `CreatedDtm` DATETIME(6) NOT NULL,
  `ModifiedBy` VARCHAR(50) NULL,
  `ModifiedDtm` DATETIME(6) NULL,
  PRIMARY KEY (`TransferMethodCode`));


/******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20210429	ffortunato		Initial Iteration
******************************************************************************/