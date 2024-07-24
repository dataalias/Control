/*****************************************************************************
File:		RefProcessingMethod.sql
Name:		RefProcessingMethod

Purpose:	

			Data Factory: Standard Processing (ADFP)
			SSIS        : Recover from failure and reporocess (SSIS)
			SQL Job     : Initial load of data into new process (SQLJ)
            T-SQL Proc  : Stored Procedure (TSQL)

Author:		ffortunato
Date:		20181002

******************************************************************************/

CREATE TABLE [pg].[RefProcessingMethod](
    [ProcessingMethodId]     int              IDENTITY(1,1),
	[ProcessingMethodCode]   varchar(20)      NOT NULL,
    [ProcessingMethodName]   varchar(250)     NOT NULL,
    [ProcessingMethodDesc]   varchar(1000)    NOT NULL,
    [CreatedBy]    varchar(50)      NOT NULL,
    [CreatedDtm]   datetime         NOT NULL,
    [ModifiedBy]   varchar(50)      NULL,
    [ModifiedDtm]  datetime         NULL,
    CONSTRAINT [PK_RefProcessingMethod__MethodCode] PRIMARY KEY CLUSTERED ([ProcessingMethodCode])
)
go


/******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20181002	ffortunato		Initial Iteration
20181011	ffortunato		Defines the type of run posting group will have.
20190208	ffortunato		Normalizing Constraint / Index Names
20210105	ffortunato		Ressurecting this table.

******************************************************************************/