/*****************************************************************************
File:		RefStorageMethod.sql
Name:		RefStorageMethod

Purpose:	

			Data Factory: Standard Processing (ADFP)
			SSIS        : Recover from failure and reporocess (SSIS)
			SQL Job     : Initial load of data into new process (SQLJ)
            T-SQL Proc  : Stored Procedure (TSQL)

Author:		ffortunato
Date:		20181002

******************************************************************************/

-- ----------------------------------------------------------------------------
-- Table ctl.RefStorageMethod
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `ctl`.`RefStorageMethod` (
  `StorageMethodId` INT NOT NULL,
  `StorageMethodCode` VARCHAR(20) NOT NULL,
  `StorageMethodName` VARCHAR(250) NOT NULL,
  `StorageMethodDesc` VARCHAR(1000) NOT NULL,
  `CreatedBy` VARCHAR(50) NOT NULL,
  `CreatedDtm` DATETIME(6) NOT NULL,
  `ModifiedBy` VARCHAR(50) NULL,
  `ModifiedDtm` DATETIME(6) NULL,
  PRIMARY KEY (`StorageMethodCode`));



/******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20210429	ffortunato		Initial Iteration

******************************************************************************/