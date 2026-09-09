USE [DataHub]
GO
/****** Object:  StoredProcedure [pg].[usp_RetryPostingGroup]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [pg].[usp_RetryPostingGroup]
GO
/****** Object:  StoredProcedure [pg].[usp_GetPostingGroupParent]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [pg].[usp_GetPostingGroupParent]
GO
/****** Object:  StoredProcedure [pg].[usp_GetPostingGroupChild]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [pg].[usp_GetPostingGroupChild]
GO
/****** Object:  StoredProcedure [pg].[usp_ExecuteStoredProcedure]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [pg].[usp_ExecuteStoredProcedure]
GO
/****** Object:  StoredProcedure [pg].[usp_ExecuteSSISPackage]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [pg].[usp_ExecuteSSISPackage]
GO
/****** Object:  StoredProcedure [pg].[usp_ExecuteProcess]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [pg].[usp_ExecuteProcess]
GO
/****** Object:  StoredProcedure [pg].[usp_ExecuteDataFactory]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [pg].[usp_ExecuteDataFactory]
GO
/****** Object:  StoredProcedure [pg].[UpdatePostingGroupProcessingStatus]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [pg].[UpdatePostingGroupProcessingStatus]
GO
/****** Object:  StoredProcedure [pg].[InsertPostingGroupProcessingParent]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [pg].[InsertPostingGroupProcessingParent]
GO
/****** Object:  StoredProcedure [pg].[InsertPostingGroupDependency]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [pg].[InsertPostingGroupDependency]
GO
/****** Object:  StoredProcedure [pg].[InsertPostingGroup]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [pg].[InsertPostingGroup]
GO
/****** Object:  StoredProcedure [pg].[InsertMapContactToPostingGroup]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [pg].[InsertMapContactToPostingGroup]
GO
/****** Object:  StoredProcedure [pg].[GetPostingGroupProcessingDetails]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [pg].[GetPostingGroupProcessingDetails]
GO
/****** Object:  StoredProcedure [pg].[ExecutePostingGroupProcessing]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [pg].[ExecutePostingGroupProcessing]
GO
/****** Object:  StoredProcedure [ctl].[usp_UpdatePublisherFTP]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[usp_UpdatePublisherFTP]
GO
/****** Object:  StoredProcedure [ctl].[usp_UpdateIssue]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[usp_UpdateIssue]
GO
/****** Object:  StoredProcedure [ctl].[usp_UpdateDistributionStatus]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[usp_UpdateDistributionStatus]
GO
/****** Object:  StoredProcedure [ctl].[usp_SendMail]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[usp_SendMail]
GO
/****** Object:  StoredProcedure [ctl].[usp_RetryDatahub]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[usp_RetryDatahub]
GO
/****** Object:  StoredProcedure [ctl].[usp_PutSubscriptionList_Datahub]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[usp_PutSubscriptionList_Datahub]
GO
/****** Object:  StoredProcedure [ctl].[usp_NotifySubscriberOfDistribution]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[usp_NotifySubscriberOfDistribution]
GO
/****** Object:  StoredProcedure [ctl].[usp_InsertNewSubscription]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[usp_InsertNewSubscription]
GO
/****** Object:  StoredProcedure [ctl].[usp_InsertNewSubscriber]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[usp_InsertNewSubscriber]
GO
/****** Object:  StoredProcedure [ctl].[usp_InsertNewPublisher]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[usp_InsertNewPublisher]
GO
/****** Object:  StoredProcedure [ctl].[usp_InsertNewPublication]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[usp_InsertNewPublication]
GO
/****** Object:  StoredProcedure [ctl].[usp_InsertNewIssue]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[usp_InsertNewIssue]
GO
/****** Object:  StoredProcedure [ctl].[usp_InsertNewContact]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[usp_InsertNewContact]
GO
/****** Object:  StoredProcedure [ctl].[usp_GetStagedIssueList]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[usp_GetStagedIssueList]
GO
/****** Object:  StoredProcedure [ctl].[usp_GetPublicationList_DataHub]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[usp_GetPublicationList_DataHub]
GO
/****** Object:  StoredProcedure [ctl].[usp_GetPublicationList_DataFactory]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[usp_GetPublicationList_DataFactory]
GO
/****** Object:  StoredProcedure [ctl].[usp_GetPublicationList]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[usp_GetPublicationList]
GO
/****** Object:  StoredProcedure [ctl].[usp_GetParameterListing]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[usp_GetParameterListing]
GO
/****** Object:  StoredProcedure [ctl].[usp_GetOutboundPublication]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[usp_GetOutboundPublication]
GO
/****** Object:  StoredProcedure [ctl].[usp_GetLatestIssueRecordForPublication]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[usp_GetLatestIssueRecordForPublication]
GO
/****** Object:  StoredProcedure [ctl].[usp_GetIssueStatistics]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[usp_GetIssueStatistics]
GO
/****** Object:  StoredProcedure [ctl].[usp_GetIssueDetails]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[usp_GetIssueDetails]
GO
/****** Object:  StoredProcedure [ctl].[usp_CheckSubscriberNotification]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[usp_CheckSubscriberNotification]
GO
/****** Object:  StoredProcedure [ctl].[InsertMapContactToSubscription]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[InsertMapContactToSubscription]
GO
/****** Object:  StoredProcedure [ctl].[InsertMapContactToPublication]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[InsertMapContactToPublication]
GO
/****** Object:  StoredProcedure [ctl].[GetTablePublicationList]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[GetTablePublicationList]
GO
/****** Object:  StoredProcedure [ctl].[GetStagedIssueList]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[GetStagedIssueList]
GO
/****** Object:  StoredProcedure [ctl].[GetShareIssuesToArchive]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[GetShareIssuesToArchive]
GO
/****** Object:  StoredProcedure [ctl].[GetJobList_DataHub]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[GetJobList_DataHub]
GO
/****** Object:  StoredProcedure [ctl].[GetIssueNamesToRetrieve]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [ctl].[GetIssueNamesToRetrieve]
GO
/****** Object:  StoredProcedure [audit].[usp_InsertStepLog]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [audit].[usp_InsertStepLog]
GO
/****** Object:  StoredProcedure [audit].[usp_CreateStepLogDescription]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP PROCEDURE [audit].[usp_CreateStepLogDescription]
GO
ALTER TABLE [pg].[PostingGroupProcessing] DROP CONSTRAINT [FK_ProcessingMode_PostingGroupProcessing__ProcessingModeCode]
GO
ALTER TABLE [pg].[PostingGroupProcessing] DROP CONSTRAINT [FK_PGP_PostingGroupStatusId]
GO
ALTER TABLE [pg].[PostingGroupProcessing] DROP CONSTRAINT [FK_PGP_PostingGroupId]
GO
ALTER TABLE [pg].[PostingGroupProcessing] DROP CONSTRAINT [FK_PGP_PostingGroupBatchId]
GO
ALTER TABLE [pg].[PostingGroupDependency] DROP CONSTRAINT [FK_PGD_PG__ParentPostingGroupId]
GO
ALTER TABLE [pg].[PostingGroupDependency] DROP CONSTRAINT [FK_PGD_PG__ChildPostingGroupId]
GO
ALTER TABLE [pg].[PostingGroup] DROP CONSTRAINT [FK_ProcessingMode_PostingGroup__ProcessingModeCode]
GO
ALTER TABLE [pg].[PostingGroup] DROP CONSTRAINT [FK_ProcessingMethod_PostingGroup__ProcessingMethodCode]
GO
ALTER TABLE [pg].[PostingGroup] DROP CONSTRAINT [FK_Interval_PostingGroup__RetryIntervalCode]
GO
ALTER TABLE [pg].[PostingGroup] DROP CONSTRAINT [FK_Interval_PostingGroup__IntervalCode]
GO
ALTER TABLE [pg].[MapContactToPostingGroup] DROP CONSTRAINT [FK_MapContactToPostingGroup_PostingGroup__PostingGroupId]
GO
ALTER TABLE [pg].[MapContactToPostingGroup] DROP CONSTRAINT [FK_MapContactToPostingGroup_Contact__ContactId]
GO
ALTER TABLE [ctl].[Subscription] DROP CONSTRAINT [FK_Subscriber_Subscription__SubscriberId]
GO
ALTER TABLE [ctl].[Subscription] DROP CONSTRAINT [FK_Interface_Subscription__InterfaceCode]
GO
ALTER TABLE [ctl].[Subscription] DROP CONSTRAINT [FK_FileFormat_Subscription__FileFormatCode]
GO
ALTER TABLE [ctl].[Subscriber] DROP CONSTRAINT [FK_Subscriber_RefInterface__InterfaceCode]
GO
ALTER TABLE [ctl].[Publisher] DROP CONSTRAINT [FK_RefContact__ContactId]
GO
ALTER TABLE [ctl].[Publisher] DROP CONSTRAINT [FK_Publisher_RefInterface__InterfaceCode]
GO
ALTER TABLE [ctl].[Publication] DROP CONSTRAINT [FK_StandardizedFileFormat_Publication__FeedFormatCode]
GO
ALTER TABLE [ctl].[Publication] DROP CONSTRAINT [FK_RefProcessingMethod_Publication__ProcessingMethodCode]
GO
ALTER TABLE [ctl].[Publication] DROP CONSTRAINT [FK_PubnPublisherId]
GO
ALTER TABLE [ctl].[Publication] DROP CONSTRAINT [FK_Method_Publication__TransferMethodCode]
GO
ALTER TABLE [ctl].[Publication] DROP CONSTRAINT [FK_Method_Publication__StorageMethodCode]
GO
ALTER TABLE [ctl].[Publication] DROP CONSTRAINT [FK_Interval_Publication__RetryIntervalCode]
GO
ALTER TABLE [ctl].[Publication] DROP CONSTRAINT [FK_Interval_Publication__IntervalCode]
GO
ALTER TABLE [ctl].[Publication] DROP CONSTRAINT [FK_FeedFormat_Publication__FeedFormatCode]
GO
ALTER TABLE [ctl].[MapContactToSubscription] DROP CONSTRAINT [FK_MapContactToSubscription_Subscription__SubscriptionId]
GO
ALTER TABLE [ctl].[MapContactToSubscription] DROP CONSTRAINT [FK_MapContactToSubscription_Contact__ContactId]
GO
ALTER TABLE [ctl].[MapContactToPublication] DROP CONSTRAINT [FK_MapContactToPublication_Publication__PublicationId]
GO
ALTER TABLE [ctl].[MapContactToPublication] DROP CONSTRAINT [FK_MapContactToPublication_Contact__ContactId]
GO
ALTER TABLE [ctl].[Issue] DROP CONSTRAINT [FK_IssueStatusId]
GO
ALTER TABLE [ctl].[Issue] DROP CONSTRAINT [FK_IssuePublicationId]
GO
ALTER TABLE [ctl].[Distribution] DROP CONSTRAINT [FK_Dist__SubscriptionId]
GO
ALTER TABLE [ctl].[Distribution] DROP CONSTRAINT [FK_Dist__StatusId]
GO
ALTER TABLE [ctl].[Distribution] DROP CONSTRAINT [FK_Dist__IssueId]
GO
/****** Object:  Table [pg].[RefProcessingMode]    Script Date: 10/8/2021 8:32:07 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pg].[RefProcessingMode]') AND type in (N'U'))
DROP TABLE [pg].[RefProcessingMode]
GO
/****** Object:  Table [pg].[RefProcessingMethod]    Script Date: 10/8/2021 8:32:07 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pg].[RefProcessingMethod]') AND type in (N'U'))
DROP TABLE [pg].[RefProcessingMethod]
GO
/****** Object:  Table [pg].[PostingGroupBatch]    Script Date: 10/8/2021 8:32:07 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pg].[PostingGroupBatch]') AND type in (N'U'))
DROP TABLE [pg].[PostingGroupBatch]
GO
/****** Object:  Table [pg].[MapContactToPostingGroup]    Script Date: 10/8/2021 8:32:07 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pg].[MapContactToPostingGroup]') AND type in (N'U'))
DROP TABLE [pg].[MapContactToPostingGroup]
GO
/****** Object:  Table [ctl].[RefTransferMethod]    Script Date: 10/8/2021 8:32:07 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[ctl].[RefTransferMethod]') AND type in (N'U'))
DROP TABLE [ctl].[RefTransferMethod]
GO
/****** Object:  Table [ctl].[RefStorageMethod]    Script Date: 10/8/2021 8:32:07 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[ctl].[RefStorageMethod]') AND type in (N'U'))
DROP TABLE [ctl].[RefStorageMethod]
GO
/****** Object:  Table [ctl].[RefMethod]    Script Date: 10/8/2021 8:32:07 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[ctl].[RefMethod]') AND type in (N'U'))
DROP TABLE [ctl].[RefMethod]
GO
/****** Object:  Table [ctl].[RefInterval]    Script Date: 10/8/2021 8:32:07 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[ctl].[RefInterval]') AND type in (N'U'))
DROP TABLE [ctl].[RefInterval]
GO
/****** Object:  Table [ctl].[RefInterface]    Script Date: 10/8/2021 8:32:07 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[ctl].[RefInterface]') AND type in (N'U'))
DROP TABLE [ctl].[RefInterface]
GO
/****** Object:  Table [ctl].[RefFileFormat]    Script Date: 10/8/2021 8:32:07 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[ctl].[RefFileFormat]') AND type in (N'U'))
DROP TABLE [ctl].[RefFileFormat]
GO
/****** Object:  Table [ctl].[Passphrase]    Script Date: 10/8/2021 8:32:07 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[ctl].[Passphrase]') AND type in (N'U'))
DROP TABLE [ctl].[Passphrase]
GO
/****** Object:  Table [ctl].[MapContactToSubscription]    Script Date: 10/8/2021 8:32:07 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[ctl].[MapContactToSubscription]') AND type in (N'U'))
DROP TABLE [ctl].[MapContactToSubscription]
GO
/****** Object:  Table [ctl].[MapContactToPublication]    Script Date: 10/8/2021 8:32:07 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[ctl].[MapContactToPublication]') AND type in (N'U'))
DROP TABLE [ctl].[MapContactToPublication]
GO
/****** Object:  Table [ctl].[Contact]    Script Date: 10/8/2021 8:32:07 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[ctl].[Contact]') AND type in (N'U'))
DROP TABLE [ctl].[Contact]
GO
/****** Object:  Table [audit].[StepLog]    Script Date: 10/8/2021 8:32:07 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[audit].[StepLog]') AND type in (N'U'))
DROP TABLE [audit].[StepLog]
GO
/****** Object:  View [pg].[vw_PostingGroupProcessingStatus]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP VIEW [pg].[vw_PostingGroupProcessingStatus]
GO
/****** Object:  Table [pg].[PostingGroupProcessing]    Script Date: 10/8/2021 8:32:07 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pg].[PostingGroupProcessing]') AND type in (N'U'))
DROP TABLE [pg].[PostingGroupProcessing]
GO
/****** Object:  Table [pg].[RefStatus]    Script Date: 10/8/2021 8:32:07 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pg].[RefStatus]') AND type in (N'U'))
DROP TABLE [pg].[RefStatus]
GO
/****** Object:  View [pg].[vw_PostingGroupDependencyDetails]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP VIEW [pg].[vw_PostingGroupDependencyDetails]
GO
/****** Object:  Table [pg].[PostingGroup]    Script Date: 10/8/2021 8:32:07 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pg].[PostingGroup]') AND type in (N'U'))
DROP TABLE [pg].[PostingGroup]
GO
/****** Object:  Table [pg].[PostingGroupDependency]    Script Date: 10/8/2021 8:32:07 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[pg].[PostingGroupDependency]') AND type in (N'U'))
DROP TABLE [pg].[PostingGroupDependency]
GO
/****** Object:  View [ctl].[vw_DelayedPublicationsList]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP VIEW [ctl].[vw_DelayedPublicationsList]
GO
/****** Object:  View [ctl].[vw_DistributionStatus]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP VIEW [ctl].[vw_DistributionStatus]
GO
/****** Object:  View [ctl].[DistributionStatus]    Script Date: 10/8/2021 8:32:07 AM ******/
DROP VIEW [ctl].[DistributionStatus]
GO
/****** Object:  Table [ctl].[Distribution]    Script Date: 10/8/2021 8:32:08 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[ctl].[Distribution]') AND type in (N'U'))
DROP TABLE [ctl].[Distribution]
GO
/****** Object:  Table [ctl].[Issue]    Script Date: 10/8/2021 8:32:08 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[ctl].[Issue]') AND type in (N'U'))
DROP TABLE [ctl].[Issue]
GO
/****** Object:  Table [ctl].[RefStatus]    Script Date: 10/8/2021 8:32:08 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[ctl].[RefStatus]') AND type in (N'U'))
DROP TABLE [ctl].[RefStatus]
GO
/****** Object:  Table [ctl].[Subscriber]    Script Date: 10/8/2021 8:32:08 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[ctl].[Subscriber]') AND type in (N'U'))
DROP TABLE [ctl].[Subscriber]
GO
/****** Object:  Table [ctl].[Subscription]    Script Date: 10/8/2021 8:32:08 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[ctl].[Subscription]') AND type in (N'U'))
DROP TABLE [ctl].[Subscription]
GO
/****** Object:  Table [ctl].[Publisher]    Script Date: 10/8/2021 8:32:08 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[ctl].[Publisher]') AND type in (N'U'))
DROP TABLE [ctl].[Publisher]
GO
/****** Object:  Table [ctl].[Publication]    Script Date: 10/8/2021 8:32:08 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[ctl].[Publication]') AND type in (N'U'))
DROP TABLE [ctl].[Publication]
GO
/****** Object:  UserDefinedFunction [pg].[fn_GetPostingGroupProcessingStatus]    Script Date: 10/8/2021 8:32:08 AM ******/
DROP FUNCTION [pg].[fn_GetPostingGroupProcessingStatus]
GO
/****** Object:  UserDefinedFunction [pg].[fn_GetPostingGroupProcessingDetails]    Script Date: 10/8/2021 8:32:08 AM ******/
DROP FUNCTION [pg].[fn_GetPostingGroupProcessingDetails]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_CalculateNextExecutionDtm]    Script Date: 10/8/2021 8:32:08 AM ******/
DROP FUNCTION [dbo].[fn_CalculateNextExecutionDtm]
GO
/****** Object:  UserDefinedFunction [ctl].[fn_GetOutboundFileDate]    Script Date: 10/8/2021 8:32:08 AM ******/
DROP FUNCTION [ctl].[fn_GetOutboundFileDate]
GO
/****** Object:  UserDefinedFunction [ctl].[fn_GetLastSuccessfulIssuePeriodEndDtm]    Script Date: 10/8/2021 8:32:08 AM ******/
DROP FUNCTION [ctl].[fn_GetLastSuccessfulIssuePeriodEndDtm]
GO
/****** Object:  UserDefinedFunction [ctl].[fn_GetLastSuccessfulETLExecutionID]    Script Date: 10/8/2021 8:32:08 AM ******/
DROP FUNCTION [ctl].[fn_GetLastSuccessfulETLExecutionID]
GO
/****** Object:  UserDefinedFunction [ctl].[fn_GetIntervalInMinutes]    Script Date: 10/8/2021 8:32:08 AM ******/
DROP FUNCTION [ctl].[fn_GetIntervalInMinutes]
GO
/****** Object:  UserDefinedTableType [pg].[udt_SSISPackageParameters]    Script Date: 10/8/2021 8:32:08 AM ******/
DROP TYPE [pg].[udt_SSISPackageParameters]
GO
/****** Object:  UserDefinedTableType [pg].[udt_PostingGroupProcessingDetails]    Script Date: 10/8/2021 8:32:08 AM ******/
DROP TYPE [pg].[udt_PostingGroupProcessingDetails]
GO
/****** Object:  UserDefinedTableType [ctl].[udt_IssueNameLookup]    Script Date: 10/8/2021 8:32:08 AM ******/
DROP TYPE [ctl].[udt_IssueNameLookup]
GO
/****** Object:  UserDefinedTableType [ctl].[IssueNameLookup]    Script Date: 10/8/2021 8:32:08 AM ******/
DROP TYPE [ctl].[IssueNameLookup]
GO
/****** Object:  Schema [pg]    Script Date: 10/8/2021 8:32:08 AM ******/
DROP SCHEMA [pg]
GO
/****** Object:  Schema [ctl]    Script Date: 10/8/2021 8:32:08 AM ******/
DROP SCHEMA [ctl]
GO
/****** Object:  Schema [audit]    Script Date: 10/8/2021 8:32:08 AM ******/
DROP SCHEMA [audit]
GO
