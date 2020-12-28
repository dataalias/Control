CREATE TABLE [ctl].[Passphrase](
	[PassPhraseID]		 [int]			 IDENTITY(1,1) NOT NULL,
	[DatabaseName]		 [varchar](255)	 NOT NULL,
	[SchemaName]		 [varchar](255)	 NOT NULL,
	[TableName]			 [varchar](255)	 NOT NULL,
	[Passphrase]		 [varchar](100)	 NOT NULL,
	CreatedBy			 [varchar](100)	 NOT NULL,
	CreatedDtm			 datetime		 NOT NULL,
	ModifiedBy			 [varchar](100)	 NULL,
	ModifiedDtm			 datetime		 NULL,
 CONSTRAINT [PK_BIConfigPhrase_PhraseID] PRIMARY KEY CLUSTERED 
(
	[PassPhraseID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX [UNQ_PassPhrase__SchemaName_TableName_Passphrase]
    ON [ctl].[Passphrase]([SchemaName],[TableName],[Passphrase]) WITH (FILLFACTOR = 90);
GO

ALTER TABLE ctl.[Passphrase] ADD  CONSTRAINT [DF__Passphrase__CreatedBy__CurrentUser]  DEFAULT ((CURRENT_USER)) FOR [CreatedBy]
GO

ALTER TABLE ctl.[Passphrase] ADD  CONSTRAINT [DF__Passphrase__CreatedDtm__getdate]  DEFAULT ((getdate())) FOR [CreatedDtm]
GO