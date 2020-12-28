CREATE TABLE [pg].[PostingGroup](
	[PostingGroupId] [int] IDENTITY(1,1) NOT NULL,
	[PostingGroupCode] [varchar](100) NOT NULL,
	[PostingGroupName] [varchar](250) NOT NULL,
	[PostingGroupDesc] [varchar](max) NULL,
	[PostingGroupCategory] [varchar](50) NULL,
	[PostingGroupCategoryDesc] [varchar](max) NULL,
	[IntervalCode] [varchar](20) NOT NULL,
	[IntervalLength] [int] NOT NULL,
	[SSISFolder] [varchar](255) NOT NULL ,
	[SSISProject] [varchar](255) NOT NULL,
	[SSISPackage] [varchar](255) NOT NULL,
	[DataFactoryName] [varchar](255) NOT NULL,
	[DataFactoryPipeline] [varchar](255) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsRoot] [bit] NOT NULL,
	[TriggerType] [varchar](50) NOT NULL,
	[TriggerProcess] [varchar](50) NULL,
	[NextExecutionDtm] [datetime] NOT NULL,
	[RetryMax] [int] NOT NULL,
	[RetryIntervalLength] [int] NULL,
	[RetryIntervalCode] [varchar](20) NULL,
	[SLAEndTime] [varchar](20) NULL,
	[CreatedBy] [varchar](50) NOT NULL,
	[CreatedDtm] [datetime] NOT NULL,
	[ModifiedBy] [varchar](50) NULL,
	[ModifiedDtm] [datetime] NULL,
 CONSTRAINT [PK_PostingGroup__PostingGroupId] PRIMARY KEY CLUSTERED 
(
	[PostingGroupId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90)
)
GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__IsRoot__0]  DEFAULT ((0)) FOR [IsRoot]
GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__TriggerType__Immediate]  DEFAULT (('Immediate')) FOR [TriggerType]
GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__NextExecutionDtm]  DEFAULT (('1900-01-01 00:00:00.000')) FOR [NextExecutionDtm]
GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__SSISFolder__NA]  DEFAULT (('NA')) FOR [SSISFolder]
GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__SSISProject__NA]  DEFAULT (('NA')) FOR [SSISProject]
GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__SSISPackage__NA]  DEFAULT (('NA')) FOR [SSISPackage]
GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__DataFactoryName__NA]  DEFAULT (('NA')) FOR [DataFactoryName]
GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__DataFactoryPipeline__NA]  DEFAULT (('NA')) FOR [DataFactoryPipeline]
GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__RetryMax__0]  DEFAULT (0) FOR [RetryMax]
GO

ALTER TABLE [pg].[PostingGroup] ADD CONSTRAINT CHK_PostingGroup_RetryInterval
CHECK ((ctl.fn_GetIntervalInMinutes(RetryIntervalLength,RetryIntervalCode,-1,-1,0)) < (ctl.fn_GetIntervalInMinutes(IntervalLength,IntervalCode,-1,-1,0)))
GO

ALTER TABLE [pg].[PostingGroup]  ADD  CONSTRAINT [FK_Interval_PostingGroup__RetryIntervalCode] FOREIGN KEY([RetryIntervalCode])
REFERENCES [ctl].[RefInterval] ([IntervalCode])
GO

ALTER TABLE [pg].[PostingGroup] CHECK CONSTRAINT [FK_Interval_PostingGroup__RetryIntervalCode]
GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_PostingGroup__PostingGroupCode]
    ON [pg].[PostingGroup]([PostingGroupCode] ASC) WITH (FILLFACTOR = 90);
GO