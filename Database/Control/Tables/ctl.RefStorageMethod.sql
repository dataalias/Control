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

CREATE TABLE [ctl].RefStorageMethod(
    [StorageMethodId]     int              IDENTITY(1,1),
	[StorageMethodCode]   varchar(20)      NOT NULL,
    [StorageMethodName]   varchar(250)     NOT NULL,
    [StorageMethodDesc]   varchar(1000)    NOT NULL,
    [CreatedBy]           varchar(50)      NOT NULL,
    [CreatedDtm]          datetime         NOT NULL,
    [ModifiedBy]          varchar(50)      NULL,
    [ModifiedDtm]         datetime         NULL,
    CONSTRAINT [PK_RefStorageMethod__MethodCode] PRIMARY KEY CLUSTERED ([StorageMethodCode])
)
go


/******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20210429	ffortunato		Initial Iteration

******************************************************************************/