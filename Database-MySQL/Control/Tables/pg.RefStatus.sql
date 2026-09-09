CREATE TABLE [pg].[RefStatus](
	[StatusId] [int] IDENTITY(1,1) NOT NULL,
	[StatusCode] [varchar](20) NOT NULL,
	[StatusName] [varchar](250) NOT NULL,
	[StatusDesc] [varchar](1000) NOT NULL,
	[StatusType] [varchar](100) NOT NULL,
	[CreatedBy] [varchar](50) NOT NULL,
	[CreatedDtm] [datetime] NOT NULL,
	[ModifiedBy] [varchar](50) NULL,
	[ModifiedDtm] [datetime] NULL,
 CONSTRAINT [PK_RefStatusStatusId] PRIMARY KEY CLUSTERED 
(
	[StatusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90)
)
GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_RefStatus__StatusCode]
    ON [pg].[RefStatus]([StatusCode] ASC) WITH (FILLFACTOR = 90);
GO