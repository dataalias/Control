CREATE TABLE [ctl].[RefMethod](
	[MethodCode] [varchar](20) NOT NULL,
	[MethodId] [int] IDENTITY(1,1) NOT NULL,
	[MethodName] [varchar](250) NULL,
	[MethodDesc] [varchar](1000) NULL,
	[CreatedBy] [varchar](50) NOT NULL,
	[CreatedDtm] [datetime] NOT NULL,
	[ModifiedBy] [varchar](50) NULL,
	[ModifiedDtm] [datetime] NULL,
 CONSTRAINT [PK_RefMethod_MethodCode] PRIMARY KEY CLUSTERED 
(
	[MethodCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO