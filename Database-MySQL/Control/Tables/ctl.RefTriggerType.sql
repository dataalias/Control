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

CREATE TABLE [ctl].[RefTriggerType](
	[TriggerTypeCode] [varchar](20) NOT NULL,
	[TriggerTypeId] [int] IDENTITY(1,1) NOT NULL,
	[TriggerTypeName] [varchar](250) NOT NULL,
	[TriggerTypeDesc] [varchar](1000) NOT NULL,
	[CreatedBy] [varchar](50) NOT NULL,
	[CreatedDtm] [datetime] NOT NULL,
	[ModifiedBy] [varchar](50) NULL,
	[ModifiedDtm] [datetime] NULL,
 CONSTRAINT [PK_RefTriggerType_TriggerTypeCode] PRIMARY KEY CLUSTERED 
(
	[TriggerTypeCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO



/******************************************************************************
       change history
*******************************************************************************
date		author			description
--------	-------------	---------------------------------------------------
20210312	ffortunato		initial iteration
******************************************************************************/