/*****************************************************************************
File:		RefTransferMethod.sql
Name:		RefTransferMethod

Purpose:	

			SCH: Scheduled
			S3 : s3 Bucket
            N/A
            UNK

Author:		ffortunato
Date:		20240520

******************************************************************************/

CREATE TABLE [ctl].[RefTriggerType](
    [TriggerTypeId]     int              IDENTITY(1,1),
	[TriggerTypeCode]   varchar(20)      NOT NULL,
    [TriggerTypeName]   varchar(250)     NOT NULL,
    [TriggerTypeDesc]   varchar(1000)    NOT NULL,
    [CreatedBy]    varchar(50)      NOT NULL,
    [CreatedDtm]   datetime         NOT NULL,
    [ModifiedBy]   varchar(50)      NULL,
    [ModifiedDtm]  datetime         NULL,
    CONSTRAINT [PK_RefTriggerType__TriggerTypeCode] PRIMARY KEY CLUSTERED ([TriggerTypeCode])
)
go


/******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20240520	ffortunato		Initial Iteration
******************************************************************************/