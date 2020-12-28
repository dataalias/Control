CREATE TABLE [ctl].[Publication](
	[PublicationId] [int] IDENTITY(1,1) NOT NULL,
	[PublisherId] [int] NOT NULL,
	[PublicationCode] [varchar](50) NOT NULL,
	[PublicationName] [varchar](255) NOT NULL,
	[SrcPublicationName] [varchar](255) NULL,
	[PublicationEntity] [varchar](255) NOT NULL,
	[PublicationFilePath] [varchar](255) NULL,
	[PublicationArchivePath] [varchar](255) NULL,
	[SrcFilePath] [varchar](256) NULL,
	[DestTableName] [varchar](255) NULL,
	[FeedFormat] [varchar](100) NULL,
	[StageJobName] [varchar](255) NULL,
	[SSISFolder] [varchar](255) NULL,
	[SSISProject] [varchar](255) NULL,
	[SSISPackage] [varchar](255) NULL,
	[DataFactoryName] [varchar](255) NULL,
	[DataFactoryPipeline] [varchar](255) NULL,
	[MethodCode] [varchar](20) NOT NULL,
	[IntervalCode] [varchar](20) NOT NULL,
	[IntervalLength] [int] NOT NULL,
	[SLATime] [varchar](20) NULL,
	[SLAEndTime] [varchar](20) NULL,
	[NextExecutionDtm] [datetime] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDataHub] [int] NULL,
	[Bound] [varchar](10) NOT NULL,
	[RetryMax] [int] NULL,
	[RetryIntervalLength] [int] NULL,
	[RetryIntervalCode] [varchar](20) NULL,
	[CreatedBy] [varchar](50) NOT NULL,
	[CreatedDtm] [datetime] NOT NULL,
	[ModifiedBy] [varchar](50) NULL,
	[ModifiedDtm] [datetime] NULL,
 CONSTRAINT [PK_PubnPublisherId] PRIMARY KEY CLUSTERED 
(
	[PublicationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
)
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__NextExecutionDtm__19000101]  DEFAULT ('1900-01-01') FOR [NextExecutionDtm]
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__IsActive__1]  DEFAULT ((1)) FOR [IsActive]
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__IsDataHub__0]  DEFAULT ((0)) FOR [IsDataHub]
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__Bound__In]  DEFAULT ('In') FOR [Bound]
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__RetryMax__0]  DEFAULT (0) FOR [RetryMax]
GO

ALTER TABLE ctl.Publication ADD CONSTRAINT CHK_Publication_RetryInterval
CHECK ((ctl.fn_GetIntervalInMinutes(RetryIntervalLength,RetryIntervalCode,-1,-1,0)) < (ctl.fn_GetIntervalInMinutes(IntervalLength,IntervalCode,-1,-1,0)))
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [FK_Interval_Publication__RetryIntervalCode] FOREIGN KEY([RetryIntervalCode])
REFERENCES [ctl].[RefInterval] ([IntervalCode])
GO

ALTER TABLE [ctl].[Publication] CHECK CONSTRAINT [FK_Interval_Publication__RetryIntervalCode]
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [FK_Interval_Publication__IntervalCode] FOREIGN KEY([IntervalCode])
REFERENCES [ctl].[RefInterval] ([IntervalCode])
GO

ALTER TABLE [ctl].[Publication] CHECK CONSTRAINT [FK_Interval_Publication__IntervalCode]
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [FK_Method_Publication__MethodCode] FOREIGN KEY([MethodCode])
REFERENCES [ctl].[RefMethod] ([MethodCode])
GO

ALTER TABLE [ctl].[Publication] CHECK CONSTRAINT [FK_Method_Publication__MethodCode]
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [FK_PubnPublisherId] FOREIGN KEY([PublisherId])
REFERENCES [ctl].[Publisher] ([PublisherId])
GO

ALTER TABLE [ctl].[Publication] CHECK CONSTRAINT [FK_PubnPublisherId]
GO

CREATE UNIQUE NONCLUSTERED INDEX [UNQ_Publication__PublicationCode]
    ON [ctl].[Publication]([PublicationCode] ASC) WITH (FILLFACTOR = 90);
GO