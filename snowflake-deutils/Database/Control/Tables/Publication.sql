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
-- ----------------------------------------------------------------------------
-- Table ctl.Publication
-- ----------------------------------------------------------------------------

-- ************************************** DATA_HUB.Publication
CREATE OR REPLACE TABLE ULTRA_@ENV@_RAW.DATA_HUB.Publication
(
 PublicationId            integer NOT NULL AUTOINCREMENT START 1 INCREMENT 1 order,
 --PublisherId              integer NOT NULL,
 PublisherCode            varchar(25) NOT NULL,
 PublicationCode          varchar(25) NOT NULL,
 PublicationName          varchar(255) NOT NULL,
 PublicationDesc          varchar(255) NOT NULL,
 SrcPublicationCode       varchar(255) NOT NULL DEFAULT 'UNK',
 SrcPublicationName       varchar(255),
 PublicationEntity        varchar(255) NOT NULL,
 PublicationBucket        varchar(255) NOT NULL DEFAULT 'N/A',
 PublicationFilePath      varchar(255),
 PublicationArchivePath   varchar(255),
 SrcFilePath              varchar(255),
 SrcFileRegEx             varchar(255) NOT NULL DEFAULT 'N/A',
 SrcDeltaAttributes       varchar(255) NOT NULL DEFAULT 'N/A',
 -- DestFilePath             varchar(255) NOT NULL DEFAULT 'N/A',   -- No :: PublicationFilePath
 DestTableName            varchar(255) NOT NULL DEFAULT 'N/A',
 SrcFileFormatCode        varchar(255) NOT NULL DEFAULT 'UNK',
 StandardFileRegEx        varchar(255) NOT NULL DEFAULT 'UNK',
 StandardFileFormatCode   varchar(25) NOT NULL DEFAULT 'UNK',
 ProcessingMethodCode     varchar(25) NOT NULL DEFAULT 'UNK',
 TransferMethodCode       varchar(25) NOT NULL DEFAULT 'UNK',
 StorageMethodCode        varchar(25) NOT NULL DEFAULT 'UNK',
 IntervalCode             varchar(25) NOT NULL DEFAULT 'UNK',
 
 IntervalLength           integer NOT NULL DEFAULT 0,
 SLATime                  varchar(255),
 SLAEndTimeInMinutes      integer,
 NextExecutionDtm         TIMESTAMP_TZ NOT NULL DEFAULT CURRENT_DATE,
 TriggerTypeCode          varchar(255) NOT NULL DEFAULT 'N/A',
 IsActive                 boolean NOT NULL DEFAULT True,
 IsDataHub                boolean NOT NULL DEFAULT True,
 Bound                    varchar(255) NOT NULL DEFAULT 'In',
 RetryMax                 integer NOT NULL DEFAULT 0,
 RetryIntervalCode        varchar(255) NOT NULL DEFAULT 'UNK',
 RetryIntervalLength      integer NOT NULL DEFAULT 0,
 PublicationGroupSequence integer NOT NULL DEFAULT 1,
 PublicationGroupDesc     varchar(255) NOT NULL DEFAULT 'Default',
 KeyStoreName             varchar(255) NOT NULL DEFAULT 'N/A',
 GlueWorkflow             varchar(255) NOT NULL DEFAULT 'N/A',
 AirFlowDAG               varchar(255) NOT NULL DEFAULT 'N/A',
 CreatedBy                varchar(255) NOT NULL,
 CreatedDtm               date NOT NULL,
 ModifiedBy               varchar(255),
 ModifiedDtm              date,

 CONSTRAINT PK_PubnPublisherCode PRIMARY KEY ( PublicationCode )
 --CONSTRAINT UNQ_Publication__PublicationCode UNIQUE ( PublicationCode ),
 --CONSTRAINT FK_FeedFormat_Publication__FeedFormatCode FOREIGN KEY ( SrcFileFormatCode ) REFERENCES DATA_HUB.REF_FileFormat ( FileFormatCode ),
 --CONSTRAINT FK_Interval_Publication__IntervalCode FOREIGN KEY ( IntervalCode ) REFERENCES DATA_HUB.REF_Interval ( IntervalCode ),
 --CONSTRAINT FK_Interval_Publication__RetryIntervalCode FOREIGN KEY ( RetryIntervalCode ) REFERENCES DATA_HUB.REF_Interval ( IntervalCode ),
 --CONSTRAINT FK_Method_Publication__StorageMethodCode FOREIGN KEY ( StorageMethodCode ) REFERENCES DATA_HUB.REF_Storage_Method ( StorageMethodCode ),
 --CONSTRAINT FK_Method_Publication__TransferMethodCode FOREIGN KEY ( TransferMethodCode ) REFERENCES DATA_HUB.REF_Transfer_Method ( TransferMethodCode ),
 --CONSTRAINT FK_PubnPublisherId FOREIGN KEY ( PublisherCode ) REFERENCES DATA_HUB.Publisher ( PublisherCode ),
 --CONSTRAINT FK_StandardizedFileFormat_Publication__FeedFormatCode FOREIGN KEY ( StandardFileFormatCode ) REFERENCES DATA_HUB.REF_FileFormat ( FileFormatCode ),
 --CONSTRAINT FK_TriggerType_Publication__TriggerTypeCode FOREIGN KEY ( TriggerTypeCode ) REFERENCES DATA_HUB.REF_Trigger_Type ( TriggerTypeCode )
);
  
  /*VISIBLE,
  CONSTRAINT FK_Method_Publication__TransferMethodCode
    FOREIGN KEY (TransferMethodCode)
    REFERENCES ctl.RefTransferMethod (TransferMethodCode)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT FK_FeedFormat_Publication__FeedFormatCode
    FOREIGN KEY (SrcFileFormatCode)
    REFERENCES ctl.RefFileFormat (FileFormatCode)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT FK_Method_Publication__StorageMethodCode
    FOREIGN KEY (StorageMethodCode)
    REFERENCES ctl.RefStorageMethod (StorageMethodCode)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT FK_StandardizedFileFormat_Publication__FeedFormatCode
    FOREIGN KEY (StandardFileFormatCode)
    REFERENCES ctl.RefFileFormat (FileFormatCode)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT FK_RefProcessingMethod_Publication__ProcessingMethodCode
    FOREIGN KEY (ProcessingMethodCode)
    REFERENCES pg.RefProcessingMethod (ProcessingMethodCode)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT FK_Interval_Publication__RetryIntervalCode
    FOREIGN KEY (RetryIntervalCode)
    REFERENCES ctl.RefInterval (IntervalCode)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT FK_Interval_Publication__IntervalCode
    FOREIGN KEY (IntervalCode)
    REFERENCES ctl.RefInterval (IntervalCode)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT FK_PubnPublisherId
    FOREIGN KEY (PublisherId)
    REFERENCES ctl.Publisher (PublisherId)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT FK_TriggerType_Publication__TriggerTypeCode
    FOREIGN KEY (TriggerTypeCode)
    REFERENCES ctl.RefTriggerType (TriggerTypeCode)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);
*/
/*
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
*/

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
20210413	ffortunato		- PUBLISHERID (we have publication code we are good.)
******************************************************************************/