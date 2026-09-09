/******************************************************************************
file:           RefFileFormat.sql
name:           RefFileFormat

purpose:        Defines each of the processes that must be triggered 
				in the system.


called by:      
calls:          

author:         ffortunato
date:           20210312

******************************************************************************/

-- ----------------------------------------------------------------------------
-- Table ctl.RefFileFormat
-- ----------------------------------------------------------------------------
-- ************************************** DATA_HUB.REF_FileFormat
CREATE OR REPLACE TABLE DATA_HUB.REF_File_Format
(
 FileFormatCode   varchar(25) NOT NULL,
 FileFormatId     integer NOT NULL AUTOINCREMENT START 1 INCREMENT 1,
 FileFormatName   varchar(255) NOT NULL,
 FileFormatDesc   varchar(255) NOT NULL,
 FileExtension    varchar(255) NOT NULL,
 DotFileExtension varchar(255) NOT NULL,
 CreatedBy        varchar(255) NOT NULL,
 CreatedDtm       date NOT NULL,
 ModifiedBy       varchar(255),
 ModifiedDtm      date,

 CONSTRAINT PK_RefFileFormat_FileFormatCode PRIMARY KEY ( FileFormatCode )
);



/******************************************************************************
       change history
*******************************************************************************
date		author			description
--------	-------------	---------------------------------------------------
20210312	ffortunato		initial iteration
******************************************************************************/