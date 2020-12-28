CREATE TABLE [ctl].[Contact](
	[ContactId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](100) NOT NULL,
	[Tier] [varchar](20) NULL,
	[Email] [varchar](100) NULL,
	[Phone] [varchar](20) NULL,
	[Address01] [varchar](100) NULL,
	[Address02] [varchar](100) NULL,
	[City] [varchar](30) NULL,
	[State] [varchar](10) NULL,
	[ZipCode] [varchar](10) NULL,
	[CreatedBy] [varchar](50) NOT NULL,
	[CreatedDtm] [datetime] NOT NULL,
	[ModifiedBy] [varchar](50) NULL,
	[ModifiedDtm] [datetime] NULL,
 CONSTRAINT [PK_ContactContactId] PRIMARY KEY CLUSTERED 
(
	[ContactId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX [UNQ_Contact__Name] ON ctl.Contact([Name])
	WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
Go

ALTER TABLE [ctl].[Contact] ADD  CONSTRAINT [DF__Contact__Name__NA]  DEFAULT ('N/A') FOR [Name]
GO