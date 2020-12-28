CREATE TABLE [ctl].[RefInterval](
	[IntervalCode] [varchar](20) NOT NULL,
	[IntervalId] [int] IDENTITY(1,1) NOT NULL,
	[IntervalName] [varchar](250) NULL,
	[IntervalDesc] [varchar](1000) NULL,
	[SLAFormat] [varchar](100) NULL,
	[SLARegEx] [varchar](100) NULL,
	[CreatedBy] [varchar](50) NOT NULL,
	[CreatedDtm] [datetime] NOT NULL,
	[ModifiedBy] [varchar](50) NULL,
	[ModifiedDtm] [datetime] NULL,
 CONSTRAINT [PK_RefInterval_IntervalCode] PRIMARY KEY CLUSTERED 
(
	[IntervalCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO