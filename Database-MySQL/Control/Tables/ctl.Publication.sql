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
CREATE TABLE IF NOT EXISTS `ctl`.`Publication` (
  `PublicationId` INT NOT NULL,
  `PublisherId` INT NOT NULL,
  `PublicationCode` VARCHAR(50) NOT NULL,
  `PublicationName` VARCHAR(255) NOT NULL,
  `PublicationDesc` VARCHAR(1000) NOT NULL,
  `SrcPublicationCode` VARCHAR(20) NOT NULL DEFAULT 'UNK',
  `SrcPublicationName` VARCHAR(255) NULL,
  `PublicationEntity` VARCHAR(255) NOT NULL,
  `PublicationFilePath` VARCHAR(255) NULL,
  `PublicationArchivePath` VARCHAR(255) NULL,
  `SrcFilePath` VARCHAR(255) NULL,
  `SrcFileRegEx` VARCHAR(255) NOT NULL DEFAULT 'N/A',
  `SrcDeltaAttributes` VARCHAR(2000) NOT NULL DEFAULT 'N/A',
  `DestTableName` VARCHAR(255) NULL,
  `SrcFileFormatCode` VARCHAR(20) NOT NULL DEFAULT 'UNK',
  `StandardFileRegEx` VARCHAR(255) NOT NULL DEFAULT 'UNK',
  `StandardFileFormatCode` VARCHAR(20) NOT NULL DEFAULT 'UNK',
  `ProcessingMethodCode` VARCHAR(20) NOT NULL DEFAULT 'UNK',
  `TransferMethodCode` VARCHAR(20) NOT NULL DEFAULT 'UNK',
  `StorageMethodCode` VARCHAR(20) NOT NULL DEFAULT 'UNK',
  `StageJobName` VARCHAR(255) NOT NULL DEFAULT 'N/A',
  `SSISFolder` VARCHAR(255) NOT NULL DEFAULT 'N/A',
  `SSISProject` VARCHAR(255) NOT NULL DEFAULT 'N/A',
  `SSISPackage` VARCHAR(255) NOT NULL DEFAULT 'N/A',
  `DataFactoryName` VARCHAR(255) NOT NULL DEFAULT 'N/A',
  `DataFactoryPipeline` VARCHAR(255) NOT NULL DEFAULT 'N/A',
  `GlueWorkflow` VARCHAR(255) NOT NULL DEFAULT 'N/A',
  `IntervalCode` VARCHAR(20) NOT NULL DEFAULT 'UNK',
  `IntervalLength` INT NOT NULL DEFAULT 0,
  `SLATime` VARCHAR(20) NULL,
  `SLAEndTimeInMinutes` INT NULL,
  `NextExecutionDtm` DATETIME(6) NOT NULL DEFAULT '1900-01-01',
  `TriggerTypeCode` VARCHAR(20) NOT NULL DEFAULT 'N/A',
  `IsActive` TINYINT(1) NOT NULL DEFAULT 1,
  `IsDataHub` TINYINT(1) NOT NULL DEFAULT 1,
  `Bound` VARCHAR(10) NOT NULL DEFAULT 'In',
  `RetryMax` INT NOT NULL DEFAULT 0,
  `RetryIntervalCode` VARCHAR(20) NOT NULL DEFAULT 'UNK',
  `RetryIntervalLength` INT NOT NULL DEFAULT 0,
  `PublicationGroupSequence` INT NOT NULL DEFAULT 1,
  `PublicationGroupDesc` VARCHAR(1000) NOT NULL DEFAULT 'Default',
  `KeyStoreName` VARCHAR(1000) NOT NULL DEFAULT 'N/A',
  `CreatedBy` VARCHAR(50) NOT NULL,
  `CreatedDtm` DATETIME(6) NOT NULL,
  `ModifiedBy` VARCHAR(50) NULL,
  `ModifiedDtm` DATETIME(6) NULL,
  PRIMARY KEY (`PublicationId`),
  UNIQUE INDEX `UNQ_Publication__PublicationCode` (`PublicationCode` ASC) VISIBLE,
  CONSTRAINT `FK_Method_Publication__TransferMethodCode`
    FOREIGN KEY (`TransferMethodCode`)
    REFERENCES `ctl`.`RefTransferMethod` (`TransferMethodCode`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `FK_FeedFormat_Publication__FeedFormatCode`
    FOREIGN KEY (`SrcFileFormatCode`)
    REFERENCES `ctl`.`RefFileFormat` (`FileFormatCode`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `FK_Method_Publication__StorageMethodCode`
    FOREIGN KEY (`StorageMethodCode`)
    REFERENCES `ctl`.`RefStorageMethod` (`StorageMethodCode`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `FK_StandardizedFileFormat_Publication__FeedFormatCode`
    FOREIGN KEY (`StandardFileFormatCode`)
    REFERENCES `ctl`.`RefFileFormat` (`FileFormatCode`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `FK_RefProcessingMethod_Publication__ProcessingMethodCode`
    FOREIGN KEY (`ProcessingMethodCode`)
    REFERENCES `pg`.`RefProcessingMethod` (`ProcessingMethodCode`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `FK_Interval_Publication__RetryIntervalCode`
    FOREIGN KEY (`RetryIntervalCode`)
    REFERENCES `ctl`.`RefInterval` (`IntervalCode`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `FK_Interval_Publication__IntervalCode`
    FOREIGN KEY (`IntervalCode`)
    REFERENCES `ctl`.`RefInterval` (`IntervalCode`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `FK_PubnPublisherId`
    FOREIGN KEY (`PublisherId`)
    REFERENCES `ctl`.`Publisher` (`PublisherId`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `FK_TriggerType_Publication__TriggerTypeCode`
    FOREIGN KEY (`TriggerTypeCode`)
    REFERENCES `ctl`.`RefTriggerType` (`TriggerTypeCode`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);

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
******************************************************************************/