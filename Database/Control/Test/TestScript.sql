USE Control
GO

CREATE OR ALTER PROCEDURE [ctl].[Test_DH_PG_MetadataSetup] (
	 @pVerbose					int = 1
	,@pETLExecutionId			int = -1
	,@pPathId					int	= -1
	,@pPassVerbose 				bit = 1)
AS
/******************************************************************************
File:           Metadata_setup_DH_PG.sql
Name:           Metdata setup for both Data Hub and Posting Group

Purpose:        There is an expectation for these test cases that reference data 
				for the following tables has already been created:
					RefStatus, Ref* ...
				This procedure does the Metadata setup for both Datahub and Posting Group

Parameters:     The parameters for this procedure are those from the posting 
				@Verbose,@PassVerbose 
				Verbose Helps determine how much output you want to see from the 
				test process.
				/*
				@pVerbose -- Parameter for local testing.
				0 - Nothing
				1 - Everything
				2 - All Print Statments
				3 - All Select Statments
				
				@pPassVerbose -- Parameter for testing procedures.
				0 - False
				1 - True
				*/
Execution:      EXEC [ctl].[Test_DH_PG_MetadataSetup]

Called By:      QA

Author:         ffortunato
Date:           20161206

*******************************************************************************
       Change History
*******************************************************************************
Date		Author			Description
--------	-------------	------------------------------------------------------
20161206	ffortunato	    initial iteration
20180731	ffortunato		we are back.
20180906	ffortunato		interface code
20201106	ochowkwale		Modifications to reflect current Datahub processes 
							and moving it to stored procedure
******************************************************************************/

-- Cleanup
delete ctl.[distribution] where IssueId IN (select IssueId from ctl.Issue where  publicationid in (select publicationid from ctl.publication where publicationcode in ('PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR')))
delete ctl.Issue where publicationid in (select publicationid from ctl.publication where publicationcode in ('PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR'))
delete ctl.MapContactToPublication where publicationid in (select publicationid from ctl.publication where publicationcode in ('PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR'))
delete ctl.MapContactToSubscription where SubscriptionId in (select SubscriptionId from ctl.Subscription where subscriptioncode in ('PUBR02-SUBR01-PUBN03-COUR','PUBR01-SUBR01-PUBN01-ACCT','PUBR01-SUBR01-PUBN02-ASSG','PUBR01-SUBR02-PUBN02-ASSG','PUBR02-SUBR02-PUBN03-COUR'))
delete ctl.Contact where [Name] IN ('TestContact01','TestContact02')
delete ctl.Subscription where subscriptioncode in ('PUBR02-SUBR01-PUBN03-COUR','PUBR01-SUBR01-PUBN01-ACCT','PUBR01-SUBR01-PUBN02-ASSG','PUBR01-SUBR02-PUBN02-ASSG','PUBR02-SUBR02-PUBN03-COUR')
delete ctl.Publication where PublicationCode in ('PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR')
delete ctl.Subscriber where subscribercode in ('SUBR01','SUBR02')
delete ctl.Publisher where publishercode in('PUBR01','PUBR02')

-------------------------------------------------------------------------------
-- Declaration and Initialization
-------------------------------------------------------------------------------

declare @Verbose       int
       ,@PassVerbose   bit
	   ,@Start         datetime
	   ,@End		   datetime
	   ,@IssueId	   int

select  @Verbose     = @pVerbose
       ,@PassVerbose = @pPassVerbose
	   ,@Start       = getdate()
	   ,@End         = getdate()
	   ,@IssueId     = -1

if not exists (select top 1 1 from ctl.Contact where name = 'BI-Development')
	insert into ctl.contact (name,[CreatedBy],[CreatedDtm])
	values ('BI-Development','ffortunato',getdate())

/******************************************************************************
Test Case: Create New Publisher
******************************************************************************/
if not exists (select top 1 1 from ctl.Publisher where PublisherCode	= 'PUBR01')
begin

exec [ctl].usp_InsertNewPublisher 
		 @pPublisherCode		= 'PUBR01'
		,@pContactName			= 'BI-Development'
		,@pPublisherName		= '01 Test Publisher'
		,@pPublisherDesc		= 'First Test Publisher'
		,@pInterfaceCode		= 'TBL'
		,@pCreatedBy			= 'ffortunato'
		,@pSiteURL				= NULL
		,@pSiteUser				= NULL
		,@pSitePassword			= NULL
		,@pSiteHostKeyFingerprint = NULL
		,@pSitePort				= NULL
		,@pSiteProtocol			= NULL
		,@pPrivateKeyPassPhrase = NULL
		,@pPrivateKeyFile		= NULL
		,@pETLExecutionId		= 0
		,@pPathId				= 0
		,@pVerbose				= 0

end

if not exists (select top 1 1 from ctl.Publisher where PublisherCode	= 'PUBR02')
begin

exec [ctl].usp_InsertNewPublisher 
		 @pPublisherCode		= 'PUBR02'
		,@pContactName			= 'BI-Development'
		,@pPublisherName		= '02 Test Publisher'
		,@pPublisherDesc		= 'Second Test Publisher'
		,@pInterfaceCode		= 'TBL'
		,@pCreatedBy			= 'ffortunato'
		,@pSiteURL				= NULL
		,@pSiteUser				= NULL
		,@pSitePassword			= NULL
		,@pSiteHostKeyFingerprint = NULL
		,@pSitePort				= NULL
		,@pSiteProtocol			= NULL
		,@pPrivateKeyPassPhrase = NULL
		,@pPrivateKeyFile		= NULL
		,@pETLExecutionId		= 0
		,@pPathId				= 0
		,@pVerbose				= 0

end

if @Verbose in (1,3)
	select 'Initial State Publisher' AS TestingStep, * 
	from ctl.Publisher
	WHERE PublisherCode IN ('PUBR01','PUBR02')
/******************************************************************************
Test Case: Create New Subscriber
******************************************************************************/

if not exists (select top 1 1 from ctl.Subscriber where SubscriberCode	= 'SUBR01')
begin

exec [ctl].[usp_InsertNewSubscriber]   
     @pSubscriberCode			= 'SUBR01'
    ,@pContactName				= 'BI-Development'
    ,@pSubscriberName			= '01 Test Subscriber'
    ,@pInterfaceCode			= 'TBL'
	,@pSiteURL					= NULL  
	,@pSiteUser					= NULL 
	,@pSitePassword				= NULL           
	,@pSiteHostKeyFingerprint	= NULL                             
	,@pSitePort					= NULL
	,@pSiteProtocol				= NULL
	,@pPrivateKeyPassPhrase		= NULL 
	,@pPrivateKeyFile			= NULL 
	,@pNotificationHostName		= 'SBXSRV01'
	,@pNotificationInstance		= 'SBXSRV01'
	,@pNotificationDatabase		= 'SBXSRV01'
	,@pNotificationSchema		= 'schema'
	,@pNotificationProcedure	= 'usp_NA'
    ,@pCreatedBy				= 'ffortunato'
	,@pVerbose					= 0

end

if not exists (select top 1 1 from ctl.Subscriber where SubscriberCode	= 'SUBR02')
begin

exec [ctl].[usp_InsertNewSubscriber]   
     @pSubscriberCode			= 'SUBR02'
    ,@pContactName				= 'BI-Development'
    ,@pSubscriberName			= '02 Test Subscriber'
    ,@pInterfaceCode			= 'TBL'
	,@pSiteURL					= NULL  
	,@pSiteUser					= NULL 
	,@pSitePassword				= NULL           
	,@pSiteHostKeyFingerprint	= NULL                             
	,@pSitePort					= NULL
	,@pSiteProtocol				= NULL
	,@pPrivateKeyPassPhrase		= NULL 
	,@pPrivateKeyFile			= NULL 
	,@pNotificationHostName		= 'SBXSRV02'
	,@pNotificationInstance		= 'SBXSRV02'
	,@pNotificationDatabase		= 'SBXSRV02'
	,@pNotificationSchema		= 'schema'
	,@pNotificationProcedure	= 'usp_NA'
    ,@pCreatedBy				= 'ffortunato'
	,@pVerbose					= 0

end

if @Verbose in (1,3)
	select 'Initial State Subscriber' AS TestingStep, * 
	from ctl.Subscriber
	WHERE SubscriberCode IN ('SUBR02','SUBR01')
/******************************************************************************
Test Case: Create New Publication
******************************************************************************/

if not exists (select top 1 1 from ctl.Publication where PublicationCode	= 'PUBN01-ACCT')
begin

EXEC [ctl].[usp_InsertNewPublication] 
	 @pPublisherCode			= 'PUBR01' -- varchar(20) 
	,@pPublicationCode			= 'PUBN01-ACCT'-- varchar(50) 
	,@pPublicationName			= 'Test Account Dim Feed' -- varchar(50) 
	,@pSrcPublicationName		= 'PUBN01-ACCT'--_[1..9]{8}_[1..9]{8}\.csv$ -- varchar(255) 
	,@pPublicationFilePath		= '' -- '\PUBR01\inbound\'-- varchar(255) 
	,@pPublicationArchivePath	= '' -- '\PUBR01\archive\'-- varchar(255)
	,@pFeedFormat				= '' -- 'csv'
	,@pStageJobName				= ''
	,@pSSISProject				= 'PostingGroup'
	,@pSSISFolder				= 'ETLFolder'
	,@pSSISPackage				= 'TSTPUBN01-ACCT.dtsx'
	,@pSrcFilePath				= '' -- '\\bpe-aesd-cifs\Share'
	,@pDataFactoryName			= 'N/A'
	,@pDataFactoryPipeline		= 'N/A'
--	,@pInterfaceCode			= 'FILE' -- varchar(20) 
	,@pMethodCode				= 'DLT' -- varchar(20) 
	,@pIntervalCode				= 'DLY' -- varchar(20) 
	,@pIntervalLength			= 1 -- int 
	,@pRetryIntervalCode		= 'HRLY'	--	varchar(20)
	,@pRetryIntervalLength		= 1	--	int
	,@pRetryMax					= 0	--	int
	,@pPublicationEntity		= '' -- 'PUBN01-ACCT_[1..9]{8}_[1..9]{8}\.csv$' -- varchar(255) 
	,@pDestTableName			= '[Control].[schema].[TBL-ACCT]' -- varchar(255) 
	,@pSLATime					= '01:00'
	,@pSLAEndTime				= NULL
	,@pNextExecutionDtm			= '1900-01-01 00:00:00.000'
	,@pIsActive					= 1  
	,@pIsDataHub				= 1
	,@pBound					= 'In'
	,@pCreatedBy				= 'ffortunato' -- varchar(50)	
end

if not exists (select top 1 1 from ctl.Publication where PublicationCode	= 'PUBN02-ASSG')
begin


EXEC [ctl].[usp_InsertNewPublication] 
	 @pPublisherCode			= 'PUBR01' -- varchar(20) 
	,@pPublicationCode			= 'PUBN02-ASSG'-- varchar(50) 
	,@pPublicationName			= 'Test Assignment Dim Feed' -- varchar(50) 
	,@pSrcPublicationName		= 'PUBN02-ASSG'--_[1..9]{8}_[1..9]{8}\.csv$' -- varchar(255) 
	,@pPublicationFilePath		= '' -- '\PUBR01\inbound\'-- varchar(255) 
	,@pPublicationArchivePath	= '' -- '\PUBR01\archive\'-- varchar(255)
	,@pFeedFormat				= '' -- 'csv'
	,@pStageJobName				= ''
	,@pSSISProject				= 'PostingGroup'
	,@pSSISFolder				= 'ETLFolder'
	,@pSSISPackage				= 'TSTPUBN02-ASSG.dtsx'
	,@pSrcFilePath				= '' -- '\\bpe-aesd-cifs\Share'
	,@pDataFactoryName			= 'N/A'
	,@pDataFactoryPipeline		= 'N/A'
--	,@pInterfaceCode			= 'FILE' -- varchar(20) 
	,@pMethodCode				= 'DLT' -- varchar(20) 
	,@pIntervalCode				= 'DLY' -- varchar(20) 
	,@pIntervalLength			= 1 -- int 
	,@pRetryIntervalCode		= 'HRLY'	--	varchar(20)
	,@pRetryIntervalLength		= 1	--	int
	,@pRetryMax					= 0	--	int
	,@pPublicationEntity		= '' -- 'PUBN01-ACCT_[1..9]{8}_[1..9]{8}\.csv$' -- varchar(255) 
	,@pDestTableName			= '[Control].[schema].[TBL-ASSG]' -- varchar(255) 
	,@pSLATime					= '01:00'
	,@pSLAEndTime				= NULL
	,@pNextExecutionDtm			= '1900-01-01 00:00:00.000'
	,@pIsActive					= 1  
	,@pIsDataHub				= 1
	,@pBound					= 'In'
	,@pCreatedBy				= 'ffortunato' -- varchar(50)	
end

if not exists (select top 1 1 from ctl.Publication where PublicationCode	= 'PUBN03-COUR')
begin

EXEC [ctl].[usp_InsertNewPublication] 
	 @pPublisherCode			= 'PUBR02' -- varchar(20) 
	,@pPublicationCode			= 'PUBN03-COUR'-- varchar(50) 
	,@pPublicationName			= 'Test Course Feed' -- varchar(50) 
	,@pSrcPublicationName		= 'PUBN03-COUR'--_[1..9]{8}_[1..9]{8}\.csv$' -- varchar(255) 
	,@pPublicationFilePath		= '' -- '\PUBR01\inbound\'-- varchar(255) 
	,@pPublicationArchivePath	= '' -- '\PUBR01\archive\'-- varchar(255)
	,@pFeedFormat				= '' -- 'csv'
	,@pStageJobName				= ''
	,@pSSISProject				= 'PostingGroup'
	,@pSSISFolder				= 'ETLFolder'
	,@pSSISPackage				= 'TSTPUBN03-COUR.dtsx'
	,@pSrcFilePath				= '' -- '\\bpe-aesd-cifs\Share'
	,@pDataFactoryName			= 'N/A'
	,@pDataFactoryPipeline		= 'N/A'
--	,@pInterfaceCode			= 'FILE' -- varchar(20) 
	,@pMethodCode				= 'DLT' -- varchar(20) 
	,@pIntervalCode				= 'DLY' -- varchar(20) 
	,@pIntervalLength			= 1 -- int 
	,@pRetryIntervalCode		= 'HRLY'	--	varchar(20)
	,@pRetryIntervalLength		= 1	--	int
	,@pRetryMax					= 0	--	int
	,@pPublicationEntity		= '' -- 'PUBN01-ACCT_[1..9]{8}_[1..9]{8}\.csv$' -- varchar(255) 
	,@pDestTableName			= '[Control].[schema].[TBL-COUR]' -- varchar(255) 
	,@pSLATime					= '01:00'
	,@pSLAEndTime				= NULL
	,@pNextExecutionDtm			= '1900-01-01 00:00:00.000'
	,@pIsActive					= 1  
	,@pIsDataHub				= 1
	,@pBound					= 'In'
	,@pCreatedBy				= 'ffortunato' -- varchar(50)	
end

if @Verbose in (1,3)
	select 'Initial State Publication' AS TestingStep, * 
	from ctl.Publication
	WHERE PublicationCode IN ('PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR')

/******************************************************************************
Test Case: Create New Subscription
******************************************************************************/
-- declare @start datetime
SELECT  @START = GETDATE()

if not exists (select top 1 1 from ctl.Subscription where SubscriptionName	= 'SUB01 Account Data')
begin
exec ctl.usp_InsertNewSubscription 
	 @pPublicationCode			= 'PUBN01-ACCT'
	,@pSubscriberCode			= 'SUBR01'
	,@pSubscriptionName			= 'SUB01 Account Data'
	,@pSubscriptionDesc			= 'Sending the Account feed to subscriber 01'
	,@pInterfaceCode			= 'TBL'
	,@pIsActive					= 1
	,@pSubscriptionFilePath     = 'N/A'
	,@pSubscriptionArchivePath  = 'N/A'
	,@pSrcFilePath				= 'N/A'
	,@pDestTableName			= 'N/A'
	,@pFeedFormat				= 'N/A'
	,@pCreatedBy				= 'ffortunato'
	,@pVerbose					= 0
end 

if not exists (select top 1 1 from ctl.Subscription where SubscriptionName	= 'SUB01 Assignment Data')
begin
exec ctl.usp_InsertNewSubscription 
	 @pPublicationCode			= 'PUBN02-ASSG'
	,@pSubscriberCode			= 'SUBR01'
	,@pSubscriptionName			= 'SUB01 Assignment Data'
	,@pSubscriptionDesc			= 'Sending the Assignment feed to subscriber 01'
	,@pInterfaceCode			= 'TBL'
	,@pIsActive					= 1
	,@pSubscriptionFilePath     = 'N/A'
	,@pSubscriptionArchivePath  = 'N/A'
	,@pSrcFilePath				= 'N/A'
	,@pDestTableName			= 'N/A'
	,@pFeedFormat				= 'N/A'
	,@pCreatedBy				= 'ffortunato'
	,@pVerbose					= 0
end 

if not exists (select top 1 1 from ctl.Subscription where SubscriptionName	= 'SUB02 Assignment Data')
begin
exec ctl.usp_InsertNewSubscription 
	 @pPublicationCode			= 'PUBN02-ASSG'
	,@pSubscriberCode			= 'SUBR02'
	,@pSubscriptionName			= 'SUB02 Assignment Data'
	,@pSubscriptionDesc			= 'Sending the Assignment feed to subscriber 02'
	,@pInterfaceCode			= 'TBL'
	,@pIsActive					= 1
	,@pSubscriptionFilePath     = 'N/A'
	,@pSubscriptionArchivePath  = 'N/A'
	,@pSrcFilePath				= 'N/A'
	,@pDestTableName			= 'N/A'
	,@pFeedFormat				= 'N/A'
	,@pCreatedBy				= 'ffortunato'
	,@pVerbose					= 0
end 

if not exists (select top 1 1 from ctl.Subscription where SubscriptionName	= 'SUB02 Course Data')
begin
exec ctl.usp_InsertNewSubscription 
	 @pPublicationCode			= 'PUBN03-COUR'
	,@pSubscriberCode			= 'SUBR01'
	,@pSubscriptionName			= 'SUB02 Course Data'
	,@pSubscriptionDesc			= 'Sending the Course feed to subscriber 02'
	,@pInterfaceCode			= 'TBL'
	,@pIsActive					= 1
	,@pSubscriptionFilePath     = 'N/A'
	,@pSubscriptionArchivePath  = 'N/A'
	,@pSrcFilePath				= 'N/A'
	,@pDestTableName			= 'N/A'
	,@pFeedFormat				= 'N/A'
	,@pCreatedBy				= 'ffortunato'
	,@pVerbose					= 0
end

if @Verbose in (1,3)
	select 'Initial State Subscription' AS TestingStep, * 
	from ctl.Subscription
	where SubscriptionName IN ('SUB01 Account Data','SUB01 Assignment Data','SUB02 Assignment Data','SUB02 Course Data')


--Insert Test Contacts
if not exists (select top 1 1 from ctl.Contact where name = 'TestContact01')
	insert into ctl.contact (name,[CreatedBy],[CreatedDtm])
	values ('TestContact01',SYSTEM_USER,getdate())

if not exists (select top 1 1 from ctl.Contact where name = 'TestContact02')
	insert into ctl.contact (name,[CreatedBy],[CreatedDtm])
	values ('TestContact02',SYSTEM_USER,getdate())

if @Verbose in (1,3)
	select 'Initial State Contacts' AS TestingStep, * 
	from ctl.Contact
	where [Name] IN ('TestContact01','TestContact02')


--Insert Test Mappings
exec ctl.[InsertMapContactToPublication] 
		 @pPublicationCode			= 'PUBN01-ACCT'
		,@pContactName				= 'TestContact01'
		,@pContactToPublicationDesc  = 'Contact BI Development team in case of test Publication Failure'

exec ctl.[InsertMapContactToPublication] 
		 @pPublicationCode			= 'PUBN01-ACCT'
		,@pContactName				= 'TestContact02'
		,@pContactToPublicationDesc  = 'Contact BI Development team in case of test Publication Failure'

exec ctl.[InsertMapContactToPublication] 
		 @pPublicationCode			= 'PUBN02-ASSG'
		,@pContactName				= 'TestContact01'
		,@pContactToPublicationDesc  = 'Contact BI Development team in case of test Publication Failure'

exec ctl.[InsertMapContactToPublication] 
		 @pPublicationCode			= 'PUBN03-COUR'
		,@pContactName				= 'TestContact02'
		,@pContactToPublicationDesc  = 'Contact BI Development team in case of test Publication Failure'

if @Verbose in (1,3)
	select 'Initial State Contact To Publication' AS TestingStep, * 
	from ctl.MapContactToPublication AS mctp
	INNER JOIN ctl.Contact as ct ON ct.ContactId = mctp.ContactId
	where [Name] IN ('TestContact01','TestContact02')
