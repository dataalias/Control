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
CREATE OR REPLACE TABLE DATA_HUB.REF_Trigger_Type
(
 TriggerTypeCode varchar(25) NOT NULL,
 TriggerTypeId   integer NOT NULL AUTOINCREMENT START 1 INCREMENT 1,
 TriggerTypeName varchar(255) NOT NULL,
 TriggerTypeDesc varchar(255) NOT NULL,
 CreatedBy       varchar(255) NOT NULL,
 CreatedDtm      date NOT NULL,
 ModifiedBy      varchar(255),
 ModifiedDtm     date,

 CONSTRAINT PK_RefTriggerType_TriggerTypeCode PRIMARY KEY ( TriggerTypeCode )
);


/******************************************************************************
       change history
*******************************************************************************
date		author			description
--------	-------------	---------------------------------------------------
20210312	ffortunato		initial iteration
******************************************************************************/