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
-- ************************************** DATA_HUB.REF_TransferMethod
CREATE OR REPLACE TABLE DATA_HUB.REF_Transfer_Method
(
 TransferMethodId   integer NOT NULL AUTOINCREMENT START 1 INCREMENT 1,
 TransferMethodCode varchar(25) NOT NULL,
 TransferMethodName varchar(255) NOT NULL,
 TransferMethodDesc varchar(255) NOT NULL,
 CreatedBy          varchar(255) NOT NULL,
 CreatedDtm         date NOT NULL,
 ModifiedBy         varchar(255),
 ModifiedDtm        date,

 CONSTRAINT PK_RefTransferMethod__MethodCode PRIMARY KEY ( TransferMethodCode )
);


/******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20210429	ffortunato		Initial Iteration
******************************************************************************/