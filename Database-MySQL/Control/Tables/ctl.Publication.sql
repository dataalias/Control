/******************************************************************************
file:           Publication.sql
name:           Publication

purpose:        Defines each feed sent by publishers.
				in the system.


called by:      
calls:          

author:         ffortunato
date:           20181011

******************************************************************************/

CREATE TABLE [ctl].[Publication](
	[PublicationId] [int] IDENTITY(1,1) NOT NULL,
	[PublisherId] [int] NOT NULL,
	[PublicationCode] [varchar](50) NOT NULL,
	[PublicationName] [varchar](255) NOT NULL,
	[PublicationDesc] [varchar](1000) NOT NULL,
	[SrcPublicationCode] [varchar](20) NOT NULL,
	[SrcPublicationName] [varchar](255) NULL,
	[PublicationEntity] [varchar](255) NOT NULL,
	[PublicationFilePath] [varchar](255) NULL,
	[PublicationArchivePath] [varchar](255) NULL,
	[SrcFilePath] [varchar](255) NULL,
	[SrcFileRegEx] [varchar](255)  NOT NULL,
	[SrcDeltaAttributes] varchar(2000) not null, -- Pipe delimited list of attributes that can be used in the merge.
	[DestTableName] [varchar](255) NULL,
	[SrcFileFormatCode] [varchar](20) NOT NULL,
	[StandardFileRegEx] varchar(255) NOT NULL,
	[StandardFileFormatCode] varchar(20) NOT NULL,
	[ProcessingMethodCode] [varchar](20) NOT NULL, -- Talks about the system that will run the code :Data Factory, Integration Services ... FK to pg.RefProcessingMethod
--	[MethodCode]	[varchar](20),  -- This field is deprecated in its place will be Transfer and Storage Method Code.
	[TransferMethodCode] [varchar](20) NOT NULL,
	[StorageMethodCode] [varchar](20) NOT NULL,
	[StageJobName] [varchar](255) NOT NULL,
	[SSISFolder] [varchar](255) NOT NULL,
	[SSISProject] [varchar](255) NOT NULL,
	[SSISPackage] [varchar](255) NOT NULL,
	[DataFactoryName] [varchar](255) NOT NULL,
	[DataFactoryPipeline] [varchar](255) NOT NULL,
	[GlueWorkflow] [varchar](255) NOT NULL,
	[IntervalCode] [varchar](20) NOT NULL,
	[IntervalLength] [int] NOT NULL,
	[SLATime] [varchar](20) NULL,
	[SLAEndTimeInMinutes] [int] NULL,
	[NextExecutionDtm] [datetime] NOT NULL,
	TriggerTypeCode varchar(20) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDataHub] BIT NOT NULL, -- this needs to be changed to a bit. I'm mad at you omkar.
	[Bound] [varchar](10) NOT NULL,
	[RetryMax] [int] NOT NULL,
	[RetryIntervalCode] [varchar](20) NOT NULL,
	[RetryIntervalLength] [int] NOT NULL,
	--[SLAIntervalCode] [varchar](20) NULL,
	--[SLAIntervalLength] [int] NULL,
	[PublicationGroupSequence] int not null, -- This atribute allows us to group publication pulls for publishers that have lots of publications. It also allows us to enforce and order to publication loads or use different pipelines.
	[PublicationGroupDesc] varchar(1000) not null,
	[KeyStoreName] varchar(1000) not null,
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

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__SrcPublicationCode__UNK]  DEFAULT 'UNK' FOR [SrcPublicationCode]
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__SrcFileRegEx__NA]  DEFAULT 'N/A' FOR [SrcFileRegEx]
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__SrcDeltaAttributes__NA]  DEFAULT 'N/A' FOR [SrcDeltaAttributes]
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__ProcessingMethodCode__UNK]  DEFAULT 'UNK' FOR [ProcessingMethodCode]
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__TransferMethodCode__UNK]  DEFAULT 'UNK' FOR [TransferMethodCode]
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__StorageMethodCode__UNK]  DEFAULT 'UNK' FOR [StorageMethodCode]
GO



ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__NextExecutionDtm__19000101]  DEFAULT '1900-01-01' FOR [NextExecutionDtm]
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__IsActive__1]  DEFAULT 1 FOR [IsActive]
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__IsDataHub__1]  DEFAULT 1 FOR [IsDataHub]
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__Bound__In]  DEFAULT 'In' FOR [Bound]
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__IntervalCode__UNK]  DEFAULT 'UNK' FOR [IntervalCode]
GO
ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__IntervalLength__0]  DEFAULT 0 FOR [IntervalLength]
GO
ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__PublicationGroupSequence__1]  DEFAULT 1 FOR [PublicationGroupSequence]
GO
ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__PublicationGroupDesc__Default]  DEFAULT 'Default' FOR [PublicationGroupDesc]
GO
ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__RetryIntervalCode__UNK]  DEFAULT 'UNK' FOR [RetryIntervalCode]
GO
ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__RetryIntervalLength__0]  DEFAULT 0 FOR [RetryIntervalLength]
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__SrcFileFormatCode__UNK]  DEFAULT 'UNK' FOR [SrcFileFormatCode]
GO
ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__StandardFileRegEx__UNK]  DEFAULT 'UNK' FOR [StandardFileRegEx]
GO
ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__StandardFormatCode__UNK]  DEFAULT 'UNK' FOR [StandardFileFormatCode]
GO
ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__RetryMax__0]  DEFAULT 0 FOR [RetryMax]
GO
ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__TriggerTypeCode__NA]  DEFAULT 'N/A' FOR [TriggerTypeCode]
GO
ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__StageJobName__NA]  DEFAULT 'N/A' FOR [StageJobName]
GO
ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__SSISFolder__NA]  DEFAULT 'N/A' FOR [SSISFolder]
GO
ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__SSISProject__NA]  DEFAULT 'N/A' FOR [SSISProject]
GO
ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__SSISPackage__NA]  DEFAULT 'N/A' FOR [SSISPackage]
GO
ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__DataFactoryName__NA]  DEFAULT 'N/A' FOR [DataFactoryName]
GO
ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__DataFactoryPipeline__NA]  DEFAULT 'N/A' FOR [DataFactoryPipeline]
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__GlueWorkflow__NA]  DEFAULT 'N/A' FOR [GlueWorkflow]
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [DF__Publication__KeyStoreName__NA]  DEFAULT 'N/A' FOR [KeyStoreName]
GO

ALTER TABLE ctl.Publication ADD CONSTRAINT CHK_Publication_RetryInterval
CHECK ((ctl.fn_GetIntervalInMinutes(RetryIntervalLength,RetryIntervalCode,-1,-1,0)) < (ctl.fn_GetIntervalInMinutes(IntervalLength,IntervalCode,-1,-1,0)))
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [FK_RefProcessingMethod_Publication__ProcessingMethodCode] FOREIGN KEY([ProcessingMethodCode])
REFERENCES [pg].[RefProcessingMethod] ([ProcessingMethodCode])
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [FK_Interval_Publication__RetryIntervalCode] FOREIGN KEY([RetryIntervalCode])
REFERENCES [ctl].[RefInterval] ([IntervalCode])
GO

ALTER TABLE [ctl].[Publication] CHECK CONSTRAINT [FK_Interval_Publication__RetryIntervalCode]
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [FK_StandardizedFileFormat_Publication__FeedFormatCode] FOREIGN KEY([StandardFileFormatCode])
REFERENCES [ctl].[RefFileFormat] ([FileFormatCode])
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [FK_FeedFormat_Publication__FeedFormatCode] FOREIGN KEY([SrcFileFormatCode])
REFERENCES [ctl].[RefFileFormat] ([FileFormatCode])
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [FK_Interval_Publication__IntervalCode] FOREIGN KEY([IntervalCode])
REFERENCES [ctl].[RefInterval] ([IntervalCode])
GO

ALTER TABLE [ctl].[Publication] CHECK CONSTRAINT [FK_Interval_Publication__IntervalCode]
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [FK_Method_Publication__StorageMethodCode] FOREIGN KEY([StorageMethodCode])
REFERENCES [ctl].[RefStorageMethod] ([StorageMethodCode])
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [FK_Method_Publication__TransferMethodCode] FOREIGN KEY([TransferMethodCode])
REFERENCES [ctl].[RefTransferMethod] ([TransferMethodCode])
GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [FK_TriggerType_Publication__TriggerTypeCode] FOREIGN KEY([TriggerTypeCode])
REFERENCES [ctl].[RefTriggerType] ([TriggerTypeCode])
GO

--ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [FK_Method_Publication__MethodCode] FOREIGN KEY([MethodCode])
--REFERENCES [ctl].[RefMethod] ([MethodCode])
--GO

--ALTER TABLE [ctl].[Publication] CHECK CONSTRAINT [FK_Method_Publication__MethodCode]
--GO

ALTER TABLE [ctl].[Publication] ADD  CONSTRAINT [FK_PubnPublisherId] FOREIGN KEY([PublisherId])
REFERENCES [ctl].[Publisher] ([PublisherId])
GO

ALTER TABLE [ctl].[Publication] CHECK CONSTRAINT [FK_PubnPublisherId]
GO

CREATE UNIQUE NONCLUSTERED INDEX [UNQ_Publication__PublicationCode]
	ON [ctl].[Publication]([PublicationCode] ASC) WITH (FILLFACTOR = 90);
GO

/******************************************************************************
	   change history
*******************************************************************************
date		author			description
--------	-------------	---------------------------------------------------
20181011	ffortunato		initial iteration
20210212	ffortunato		Removing lots of null attributes
							Adding lots of default constraints
							Adding Processing Method Code (ADPF, SSIS, ...)
							Existing method code defines snapshot, transaction, etc..)
20210413	ffortunato		Fixing flower box.
20210413	ffortunato		+ GlueWorkflow 
							Time to start kicking off Glue jobs ...
******************************************************************************/