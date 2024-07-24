/*****************************************************************************
File:		RefProcessingMode.sql
Name:		RefProcessingMode

Purpose:	Defines what Mode a posting group should executed with. See List:

			Normal      : Typical processing of the code (NORM)
			Retry       : Clean up then rerun (RTRY)
			Historical  : Building the history for a data set normally 
                            performed on the initial load. (HIST)
			Restatement : (REST) future...
            Unknown     : Record should never be unknown
            Not Applicable : Record should never be N/A

Author:		ffortunato
Date:		20210211

******************************************************************************/

CREATE TABLE [pg].RefProcessingMode(
    [ProcessingModeId]     int              IDENTITY(1,1),
	[ProcessingModeCode]   varchar(20)      NOT NULL,
    [ProcessingModeName]   varchar(250)     NOT NULL,
    [ProcessingModeDesc]   varchar(1000)    NOT NULL,
    [CreatedBy]    varchar(50)      NOT NULL,
    [CreatedDtm]   datetime         NOT NULL,
    [ModifiedBy]   varchar(50)      NULL,
    [ModifiedDtm]  datetime         NULL,
    CONSTRAINT [PK_RefProcessingMode__ModeCode] PRIMARY KEY CLUSTERED ([ProcessingModeCode])
)
go




/******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20210211	ffortunato		Initial Iteration


******************************************************************************/