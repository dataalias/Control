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

CREATE TABLE [ctl].[RefFileFormat](
	[FileFormatCode] [varchar](20) NOT NULL,
	[FileFormatId] [int] IDENTITY(1,1) NOT NULL,
	[FileFormatName] [varchar](250) NOT NULL,
	[FileFormatDesc] [varchar](1000) NOT NULL,
	[FileExtension] varchar(20) NOT NULL,
	[DotFileExtension] varchar(20) NOT NULL,
	[CreatedBy] [varchar](50) NOT NULL,
	[CreatedDtm] [datetime] NOT NULL,
	[ModifiedBy] [varchar](50) NULL,
	[ModifiedDtm] [datetime] NULL,
 CONSTRAINT [PK_RefFileFormat_FileFormatCode] PRIMARY KEY CLUSTERED 
(
	[FileFormatCode] ASC
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