CREATE TABLE [ctl].[RefInterface](
	[InterfaceCode] [varchar](20) NOT NULL,
	[InterfaceId] [int] IDENTITY(1,1) NOT NULL,
	[InterfaceName] [varchar](250) NULL,
	[InterfaceDesc] [varchar](1000) NOT NULL,
	[CreatedBy] [varchar](50) NOT NULL,
	[CreatedDtm] [datetime] NOT NULL,
	[ModifiedBy] [varchar](50) NULL,
	[ModifiedDtm] [datetime] NULL,
 CONSTRAINT [PK_RefInterface__InterfaceCode] PRIMARY KEY CLUSTERED 
(
	[InterfaceCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO