/******************************************************************************
file:           PostingGroup.sql
name:           PostingGroup

purpose:        Defines each of the processes that must be triggered 
				in the system.


called by:      
calls:          

author:         ffortunato
date:           20181011

******************************************************************************/

CREATE TABLE [pg].[PostingGroup](
	[PostingGroupId] [int] IDENTITY(1,1) NOT NULL,
	[PostingGroupCode] [varchar](100) NOT NULL,
	[PostingGroupName] [varchar](250) NOT NULL,
	[PostingGroupDesc] [varchar](max) NOT NULL,
	[PostingGroupCategoryCode] [varchar](20) NOT NULL,
	-- Move this to a ref table.
	[PostingGroupCategoryName] [varchar](250) NOT NULL,
	[PostingGroupCategoryDesc] [varchar](max) NOT NULL,
	--end
	[ProcessingMethodCode] varchar(20) NOT NULL,
	[ProcessingModeCode] varchar(20) NOT NULL,
	[IntervalCode] [varchar](20) NOT NULL,
	[IntervalLength] [int] NOT NULL,
	[SSISFolder] [varchar](255) NOT NULL ,
	[SSISProject] [varchar](255) NOT NULL,
	[SSISPackage] [varchar](255) NOT NULL,
	[DataFactoryName] [varchar](255) NOT NULL,
	[DataFactoryPipeline] [varchar](255) NOT NULL,
	[GlueWorkflow] [varchar](255) NOT NULL,
	[JobName] varchar(255) NOT NULL,
	[SQLStoredProcedure] varchar(255) NOT NULL, -- Need to fully qualify Database.Schema.ProcedureName
	[IsActive] [bit] NOT NULL,
	[IsRoot] [bit] NOT NULL,
--	[TriggerType] [varchar](50) NOT NULL,
--	[TriggerProcess] [varchar](50) NULL,
	[NextExecutionDtm] [datetime] NOT NULL,
	[RetryMax] [int] NOT NULL,
	[RetryIntervalLength] [int] NOT NULL,
	[RetryIntervalCode] [varchar](20) NOT NULL,
	[SLAEndTimeInMinutes] [int] NOT NULL,
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

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__ProcessingMethodCode__ADFP]  DEFAULT 'ADFP' FOR [ProcessingMethodCode]
GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__ProcessingModeCode__NORM]  DEFAULT 'NORM' FOR [ProcessingModeCode]
GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__PostingGroupDesc__Unknown]  DEFAULT 'Unknown' FOR [PostingGroupDesc]
GO

-- Move this to a ref table.
ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__PostingGroupCategoryCode__UNK]  DEFAULT 'UNK' FOR [PostingGroupCategoryCode]
GO
ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__PostingGroupCategoryName__Unknown]  DEFAULT 'Unknown' FOR [PostingGroupCategoryName]
GO
ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__PostingGroupCategoryDesc__Unknown]  DEFAULT 'The category for this record is unknown.' FOR [PostingGroupCategoryDesc]
GO


ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__IsActive__1]  DEFAULT 1 FOR [IsActive]
GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__IsRoot__0]  DEFAULT 0 FOR [IsRoot]
GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__SLAEndTimeInMinutes__0]  DEFAULT 0 FOR [SLAEndTimeInMinutes]
GO

--ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__TriggerType__Immediate]  DEFAULT (('Immediate')) FOR [TriggerType]
--GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__InvervalCode__IMM]  DEFAULT 'IMM' FOR [IntervalCode]
GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__InvervalLength__1]  DEFAULT 1 FOR [IntervalLength]
GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__NextExecutionDtm]  DEFAULT '1900-01-01 00:00:00.000' FOR [NextExecutionDtm]
GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__RetryInvervalCode__NA]  DEFAULT 'N/A' FOR [RetryIntervalCode]
GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__RetryInvervalLength__0]  DEFAULT 0 FOR [RetryIntervalLength]
GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__SSISFolder__NA]  DEFAULT 'N/A' FOR [SSISFolder]
GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__SSISProject__NA]  DEFAULT 'N/A' FOR [SSISProject]
GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__SSISPackage__NA]  DEFAULT 'N/A' FOR [SSISPackage]
GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__DataFactoryName__NA]  DEFAULT 'N/A' FOR [DataFactoryName]
GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__DataFactoryPipeline__NA]  DEFAULT 'N/A' FOR [DataFactoryPipeline]
GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__JobName__NA]  DEFAULT 'N/A' FOR [JobName]
GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__SQLStoredProcedure__NA]  DEFAULT 'N/A' FOR [SQLStoredProcedure]
GO

ALTER TABLE [pg].[PostingGroup] ADD  CONSTRAINT [DF__PostingGroup__RetryMax__0]  DEFAULT 0 FOR [RetryMax]
GO

ALTER TABLE [pg].[PostingGroup] ADD CONSTRAINT CHK_PostingGroup_RetryInterval
CHECK (ctl.fn_GetIntervalInMinutes(RetryIntervalLength,RetryIntervalCode,-1,-1,0) <= ctl.fn_GetIntervalInMinutes(IntervalLength,IntervalCode,-1,-1,0))
GO

ALTER TABLE [pg].[PostingGroup]  ADD  CONSTRAINT [FK_Interval_PostingGroup__RetryIntervalCode] FOREIGN KEY([RetryIntervalCode])
REFERENCES [ctl].[RefInterval] ([IntervalCode])
GO

ALTER TABLE [pg].[PostingGroup]  ADD  CONSTRAINT [FK_Interval_PostingGroup__IntervalCode] FOREIGN KEY([IntervalCode])
REFERENCES [ctl].[RefInterval] ([IntervalCode])
GO

ALTER TABLE [pg].[PostingGroup] CHECK CONSTRAINT [FK_Interval_PostingGroup__RetryIntervalCode]
GO

ALTER TABLE [pg].[PostingGroup]   ADD  CONSTRAINT [FK_ProcessingMethod_PostingGroup__ProcessingMethodCode] FOREIGN KEY([ProcessingMethodCode])
REFERENCES [pg].[RefProcessingMethod] ([ProcessingMethodCode]) 
GO

ALTER TABLE [pg].[PostingGroup]   ADD  CONSTRAINT [FK_ProcessingMode_PostingGroup__ProcessingModeCode] FOREIGN KEY([ProcessingModeCode])
REFERENCES [pg].[RefProcessingMode] ([ProcessingModeCode]) 
GO

CREATE UNIQUE NONCLUSTERED INDEX [UQ_PostingGroup__PostingGroupCode]
    ON [pg].[PostingGroup]([PostingGroupCode] ASC) WITH (FILLFACTOR = 90);
GO

/******************************************************************************
       change history
*******************************************************************************
date		author			description
--------	-------------	---------------------------------------------------
20181011	ffortunato		initial iteration
20210212	ffortunato		Adding Job Name incase we want to kick off a sql 
							server job.... Adding processing type (Normal, Hist
							...
20210327	ffortunato		Lots of default / not null work.
******************************************************************************/