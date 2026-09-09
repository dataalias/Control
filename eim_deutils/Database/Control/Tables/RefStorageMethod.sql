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
-- ************************************** DATA_HUB.REF_StorageMethod
CREATE OR REPLACE TABLE DATA_HUB.REF_Storage_Method
(
 StorageMethodId   integer NOT NULL AUTOINCREMENT START 1 INCREMENT 1,
 StorageMethodCode varchar(25) NOT NULL,
 StorageMethodName varchar(255) NOT NULL,
 StorageMethodDesc varchar(255) NOT NULL,
 CreatedBy         varchar(255) NOT NULL,
 CreatedDtm        date NOT NULL,
 ModifiedBy        varchar(255),
 ModifiedDtm       date,

 CONSTRAINT PK_RefStorageMethod__MethodCode PRIMARY KEY ( StorageMethodCode )
);



/******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20210429	ffortunato		Initial Iteration

******************************************************************************/