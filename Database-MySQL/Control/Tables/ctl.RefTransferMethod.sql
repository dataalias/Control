/*****************************************************************************
File:		RefTransferMethod.sql
Name:		RefTransferMethod

Purpose:	

			DLT: Delta Processing (DLT) - Only the changes siunce the last pull are derived from the source.
			SS : Snap Shot (SS) - The entire entity is pulled from the source.

Author:		ffortunato
Date:		20181002

******************************************************************************/

CREATE TABLE [ctl].[RefTransferMethod](
    [TransferMethodId]     int              IDENTITY(1,1),
	[TransferMethodCode]   varchar(20)      NOT NULL,
    [TransferMethodName]   varchar(250)     NOT NULL,
    [TransferMethodDesc]   varchar(1000)    NOT NULL,
    [CreatedBy]    varchar(50)      NOT NULL,
    [CreatedDtm]   datetime         NOT NULL,
    [ModifiedBy]   varchar(50)      NULL,
    [ModifiedDtm]  datetime         NULL,
    CONSTRAINT [PK_RefTransferMethod__MethodCode] PRIMARY KEY CLUSTERED ([TransferMethodCode])
)
go


/******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20210429	ffortunato		Initial Iteration
******************************************************************************/