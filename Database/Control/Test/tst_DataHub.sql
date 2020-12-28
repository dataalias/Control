/******************************************************************************
File:           Metadata_setup_DH_PG.sql
Name:           Metdata setup for both Data Hub and Posting Group

Purpose:        Series of test cases for pub sub. There is an expectation
                for these test cases that reference data for the following
				tables has already been created:
					RefStatus, Ref* ...
				This procedure tests the creation of issues and distributions.

Parameters:     The parameters for this procedure are those from the posting 

  ,@Verbose     

  ,@PassVerbose 


Execution:      N/A

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
20201120	ffortunato		Mapping tables to contact need to be deleted.
							Adding test contacts to ensure mapping works.
20201130	ffortunato		Modifications to make posting group work.
******************************************************************************/

-------------------------------------------------------------------------------
-- Declarations
-------------------------------------------------------------------------------
-- Verbose Helps dtermin how much output you want to see from the 
-- test process.

-- Cleanup
USE Control
GO

delete ctl.[distribution]			where IssueId			in (select IssueId from ctl.Issue where  publicationid in (select publicationid from ctl.publication where publicationcode in ('PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR')))
delete ctl.Issue					where publicationid		in (select publicationid from ctl.publication where publicationcode in ('PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR'))
delete ctl.MapContactToPublication	where publicationid		in (select publicationid from ctl.publication where publicationcode in ('PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR'))
delete ctl.MapContactToSubscription	where SubscriptionId	in (select SubscriptionId from ctl.Subscription where Subscriptioncode in ('PUBR02-SUBR01-PUBN03-COUR','PUBR01-SUBR01-PUBN01-ACCT','PUBR01-SUBR01-PUBN02-ASSG','PUBR01-SUBR02-PUBN02-ASSG','PUBR02-SUBR02-PUBN03-COUR'))
delete ctl.Subscription	 where subscriptioncode	in ('PUBR02-SUBR01-PUBN03-COUR','PUBR01-SUBR01-PUBN01-ACCT','PUBR01-SUBR01-PUBN02-ASSG','PUBR01-SUBR02-PUBN02-ASSG','PUBR02-SUBR02-PUBN03-COUR')
delete ctl.Publication	 where PublicationCode	in ('PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR')
delete ctl.Subscriber	 where subscribercode	in ('SUBR01' , 'SUBR02')
delete ctl.Publisher	 where publishercode	in('PUBR01','PUBR02')
delete ctl.Contact		 where [Name]			in ('PUB_Contact_Test01','PUB_Contact_Test02','SUB_Contact_Test01','SUB_Contact_Test02')




-------------------------------------------------------------------------------
-- Declaration and Initialization
-------------------------------------------------------------------------------

declare @Verbose       int
       ,@PassVerbose   bit
	   ,@Start         datetime
	   ,@End		   datetime
	   ,@IssueId	   int
	   ,@CurrentUser   varchar(250)	= CURRENT_USER

	   
select  @Verbose     = 0
       ,@PassVerbose = 1
	   ,@Start       = getdate()
	   ,@End         = getdate()
	   ,@IssueId     = -1

/*
@Verbose -- Parameter for local testing.
0 - Nothing
1 - Everything
2 - All Print Statments
3 - All Select Statments

@PassVerbose -- Parameter for testing procedures.
0 - False
1 - True
*/

-- lets get some contacts.
if not exists (select top 1 1 from ctl.Contact where name = 'BI-Development')
	insert into ctl.contact (name,[CreatedBy],[CreatedDtm])
	values ('BI-Development'
		,'ffortunato'  -- @CurrentUser
		,getdate())

if not exists (select top 1 1 from ctl.Contact where name = 'PUB_Contact_Test01')
EXEC [ctl].usp_InsertNewContact 
		 @pName						= 'PUB_Contact_Test01'
		,@pTier						= '1'
		,@pEmail					= 'PUB_Contact_Test01@zovio.com'
		,@pPhone					= '877.300.6069'
		,@pAddress01				= '10180 Telesis Ct'
		,@pAddress02				= '#400'
		,@pCity						= 'San Diego'
		,@pState					= 'CA'
		,@pZipCode					= '92121'

if not exists (select top 1 1 from ctl.Contact where name = 'PUB_Contact_Test02')
EXEC [ctl].usp_InsertNewContact 
		 @pName						= 'PUB_Contact_Test02'
		,@pTier						= '1'
		,@pEmail					= 'PUB_Contact_Test02@zovio.com'

if not exists (select top 1 1 from ctl.Contact where name = 'SUB_Contact_Test01')
EXEC [ctl].usp_InsertNewContact 
		 @pName						= 'SUB_Contact_Test01'
		,@pTier						= '1'
		,@pEmail					= 'SUB_Contact_Test01@zovio.com'

if not exists (select top 1 1 from ctl.Contact where name = 'SUB_Contact_Test02')
EXEC [ctl].usp_InsertNewContact 
		 @pName						= 'SUB_Contact_Test02'
		,@pTier						= '1'
		,@pEmail					= 'SUB_Contact_Test02@zovio.com'

--	select * from ctl.refstatus


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
		,@pCreatedBy			= 'ffortunato'  -- @CurrentUser -- @CurrentUser
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
		,@pVerbose				= 1

end

if not exists (select top 1 1 from ctl.Publisher where PublisherCode	= 'PUBR02')
begin

exec [ctl].usp_InsertNewPublisher 
		 @pPublisherCode		= 'PUBR02'
		,@pContactName			= 'BI-Development'
		,@pPublisherName		= '02 Test Publisher'
		,@pPublisherDesc		= 'Second Test Publisher'
		,@pInterfaceCode		= 'TBL'
		,@pCreatedBy			= 'ffortunato'  -- @CurrentUser -- @CurrentUser
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
    ,@pCreatedBy				= 'ffortunato'  -- @CurrentUser
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
    ,@pCreatedBy				= 'ffortunato'  -- @CurrentUser
	,@pVerbose					= 0

end

if @Verbose in (1,3)
	select 'Initial State Subscriber' AS TestingStep, * 
	from ctl.Subscriber

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
	,@pRetryIntervalCode		= 'HR'	--	varchar(20)
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
	,@pCreatedBy				= 'ffortunato'  -- @CurrentUser 
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
	,@pRetryIntervalCode		= 'HR'	--	varchar(20)
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
	,@pCreatedBy				= 'ffortunato'  -- @CurrentUser -- varchar(50)	
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
	,@pRetryIntervalCode		= 'HR'	--	varchar(20)
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
	,@pCreatedBy				= 'ffortunato'  -- @CurrentUser -- varchar(50)	
end

if @Verbose in (1,3)
	select 'Initial State Publication' AS TestingStep, * 
	from ctl.Publication

/******************************************************************************
Test Case: Map Contacts to New Publication
******************************************************************************/

exec [ctl].[InsertMapContactToPublication] 	
		 @pPublicationCode			= 'PUBN01-ACCT'
		,@pContactName				= 'PUB_Contact_Test01'
		,@pContactToPublicationDesc = ''

exec [ctl].[InsertMapContactToPublication] 	
		 @pPublicationCode			= 'PUBN02-ASSG'
		,@pContactName				= 'PUB_Contact_Test01'
		,@pContactToPublicationDesc = ''

exec [ctl].[InsertMapContactToPublication] 	
		 @pPublicationCode			= 'PUBN03-COUR'
		,@pContactName				= 'PUB_Contact_Test02'
		,@pContactToPublicationDesc = ''

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
	,@pCreatedBy				= 'ffortunato'  -- @CurrentUser
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
	,@pCreatedBy				= 'ffortunato'  -- @CurrentUser
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
	,@pCreatedBy				= 'ffortunato'  -- @CurrentUser
	,@pVerbose					= 0


end 
if not exists (select top 1 1 from ctl.Subscription where SubscriptionName	= 'SUB02 Course Data')
begin

exec ctl.usp_InsertNewSubscription 
	 @pPublicationCode			= 'PUBN03-COUR'
	,@pSubscriberCode			= 'SUBR01'
	,@pSubscriptionName			= 'SUB01 Course Data'
	,@pSubscriptionDesc			= 'Sending the Course feed to subscriber 02'
	,@pInterfaceCode			= 'TBL'
	,@pIsActive					= 1
	,@pSubscriptionFilePath     = 'N/A'
	,@pSubscriptionArchivePath  = 'N/A'
	,@pSrcFilePath				= 'N/A'
	,@pDestTableName			= 'N/A'
	,@pFeedFormat				= 'N/A'
	,@pCreatedBy				= 'ffortunato'  -- @CurrentUser
	,@pVerbose					= 0

end

if @Verbose in (1,3)
	select 'Initial State Subscription' AS TestingStep, * 
	from ctl.Subscription

/******************************************************************************
Test Case: Map Contacts to New Subscription
******************************************************************************/

/* Test Subscritpions created.
PUBR01-SUBR01-PUBN01-ACCT
PUBR01-SUBR01-PUBN02-ASSG
PUBR01-SUBR02-PUBN02-ASSG
PUBR02-SUBR01-PUBN03-COUR
*/

exec [ctl].InsertMapContactToSubscription 	
		 @pSubscriptionCode			= 'PUBR01-SUBR01-PUBN01-ACCT'
		,@pContactName				= 'SUB_Contact_Test01'
		,@pContactToSubscriptionDesc = ''

exec [ctl].InsertMapContactToSubscription 	
		 @pSubscriptionCode			= 'PUBR01-SUBR01-PUBN02-ASSG'
		,@pContactName				= 'SUB_Contact_Test01'
		,@pContactToSubscriptionDesc = ''

exec [ctl].InsertMapContactToSubscription 	
		 @pSubscriptionCode			= 'PUBR01-SUBR02-PUBN02-ASSG'
		,@pContactName				= 'SUB_Contact_Test02'
		,@pContactToSubscriptionDesc = ''

exec [ctl].InsertMapContactToSubscription 	
		 @pSubscriptionCode			= 'PUBR02-SUBR01-PUBN03-COUR'
		,@pContactName				= 'SUB_Contact_Test01'
		,@pContactToSubscriptionDesc = ''




/******************************************************************************

Test Case: Create New Issues

This test case represents the day to tday running of the pub sub model. 
As files / data move between publisher and subscriber issue and distribution
records are created. When a publisher creates an instance of a publication
and issue record is recorded. The issue is then distributed to each subscriber.
When an issue recored is created a distribution is created automaticaly based
on the subscriptions to a specific publication.

******************************************************************************/
go

declare @Verbose		int = 0
       ,@PassVerbose	bit = 0
	   ,@START			datetime
	   ,@End			datetime
	   ,@IssueId		int
	   ,@MyIssueId		int 
	  

SELECT @START = GETDATE()-.25
     , @END = GETDATE()
	 , @IssueId = -2
	 , @MyIssueId = -1

if not exists (select top 1 1 from ctl.Issue where IssueName	= 'PUBN01-ACCT_20070112_01.txt')
begin

exec ctl.[usp_InsertNewIssue] 
	@pPublicationCode= 'PUBN01-ACCT'
	,@pIssueName= 'PUBN01-ACCT_20070112_01.txt'
	,@pStatusCode= 'IP'
	,@pSrcDFIssueId= '0'
	,@pSrcDFCreatedDate= @Start --'1/2/2017'
	,@pFirstRecordSeq= 1
	,@pLastRecordSeq= 100
	,@pFirstRecordChecksum= 'ABC'
	,@pLastRecordChecksum= 'DEF'
	,@pPeriodStartTime= @START
	,@pPeriodEndTime= @END
	,@pRecordCount= 100
	,@pETLExecutionId= 99
	,@pCreateBy= 'ffortunato'  -- @CurrentUser
	,@pIssueId = @MyIssueId output
	,@pVerbose= 0

end 

print 'Returned Issue Id: ' + cast(@MyIssueId as varchar(200))

exec ctl.[usp_InsertNewIssue] 
	@pPublicationCode= 'PUBN02-ASSG'
	,@pIssueName= 'PUBN02-ASSG_20070112_01.txt'
	,@pStatusCode= 'IP'
	,@pSrcDFIssueId= '0'
	,@pSrcDFCreatedDate= @Start --'1/2/2017'
	,@pFirstRecordSeq= 1
	,@pLastRecordSeq= 100
	,@pFirstRecordChecksum= 'ABC'
	,@pLastRecordChecksum= 'DEF'
	,@pPeriodStartTime= @START
	,@pPeriodEndTime= @END
	,@pRecordCount= 100
	,@pETLExecutionId= 99
	,@pCreateBy= 'ffortunato'  -- @CurrentUser
	,@pIssueId = @MyIssueId output
	,@pVerbose= 0

print 'Returned Issue Id: ' + cast(@MyIssueId as varchar(200))

exec ctl.[usp_InsertNewIssue] 
	@pPublicationCode= 'PUBN03-COUR'
	,@pIssueName= 'PUBN03-COUR_20070112_01.txt'
	,@pStatusCode= 'IP'
	,@pSrcDFIssueId= '0'
	,@pSrcDFCreatedDate= @Start --'1/2/2017'  THIS IS A PROBLEM WITH CURRENT CHANGES TO THE CODE
	,@pFirstRecordSeq= 1
	,@pLastRecordSeq= 100
	,@pFirstRecordChecksum= 'ABC'
	,@pLastRecordChecksum= 'DEF'
	,@pPeriodStartTime= @START
	,@pPeriodEndTime= @END
	,@pRecordCount= 100
	,@pETLExecutionId= 99
	,@pCreateBy= 'ffortunato'  -- @CurrentUser
	,@pIssueId = @MyIssueId output
	,@pVerbose= 0

print 'Returned Issue Id: ' + cast(@MyIssueId as varchar(200))

SELECT @START = GETDATE()+.26
     , @END = GETDATE() + .26

exec ctl.[usp_InsertNewIssue] 
	@pPublicationCode= 'PUBN01-ACCT'
	,@pIssueName= 'PUBN01-ACCT_20070112_02.txt'
	,@pStatusCode= 'IP'
	,@pSrcDFIssueId= '0'
	,@pSrcDFCreatedDate= @Start -- '1/2/2017'
	,@pFirstRecordSeq= 1
	,@pLastRecordSeq= 100
	,@pFirstRecordChecksum= 'ABC'
	,@pLastRecordChecksum= 'DEF'
	,@pPeriodStartTime= @START
	,@pPeriodEndTime= @END
	,@pRecordCount= 100
	,@pETLExecutionId= 99
	,@pCreateBy= 'ffortunato'  -- @CurrentUser
	,@pIssueId = @MyIssueId output
	,@pVerbose= 0

print 'Returned Issue Id: ' + cast(@MyIssueId as varchar(200))

exec ctl.[usp_InsertNewIssue] 
	@pPublicationCode= 'PUBN02-ASSG'
	,@pIssueName= 'PUBN02-ASSG_20070112_02.txt'
	,@pStatusCode= 'IP'
	,@pSrcDFIssueId= '0'
	,@pSrcDFCreatedDate= @Start --'1/2/2017'
	,@pFirstRecordSeq= 1
	,@pLastRecordSeq= 100
	,@pFirstRecordChecksum= 'ABC'
	,@pLastRecordChecksum= 'DEF'
	,@pPeriodStartTime= @START
	,@pPeriodEndTime= @END
	,@pRecordCount= 100
	,@pETLExecutionId= 99
	,@pCreateBy= 'ffortunato'  -- @CurrentUser
	,@pIssueId = @MyIssueId output
	,@pVerbose= 0

print 'Returned Issue Id: ' + cast(@MyIssueId as varchar(200))

exec ctl.[usp_InsertNewIssue] 
	@pPublicationCode= 'PUBN03-COUR'
	,@pIssueName= 'PUBN03-COUR_20070112_02.txt'
	,@pStatusCode= 'IP'
	,@pSrcDFIssueId= '0'
	,@pSrcDFCreatedDate= @Start --'1/2/2017'
	,@pFirstRecordSeq= 1
	,@pLastRecordSeq= 100
	,@pFirstRecordChecksum= 'ABC'
	,@pLastRecordChecksum= 'DEF'
	,@pPeriodStartTime= @START
	,@pPeriodEndTime= @END
	,@pRecordCount= 100
	,@pETLExecutionId= 99
	,@pCreateBy= 'ffortunato'  -- @CurrentUser
	,@pIssueId = @MyIssueId output
	,@pVerbose= 0

	print 'Returned Issue Id: ' + cast(@MyIssueId as varchar(200))


/******************************************************************************

Test Case: Update Issue Status - Staging

This test case represents the execution of staging packages.

******************************************************************************/

-- select * from ctl.refstatus


select  @IssueId = isnull(IssueId,-1) from ctl.Issue where IssueName = 'PUBN01-ACCT_20070112_01.txt'
print 'IssueId:   ' + cast(@IssueId as varchar(100)) 
print 'IssueName: PUBN01-ACCT_20070112_01.txt'

exec [ctl].usp_UpdateIssue
		 @pIssueId				= @IssueId
		,@pStatusCode			= 'IS'


select  @IssueId = isnull(IssueId,-1) from ctl.Issue where IssueName = 'PUBN02-ASSG_20070112_01.txt'
print 'IssueId:   ' + cast(@IssueId as varchar(100)) 
print 'IssueName: PUBN02-ASSG_20070112_01.txt'

exec [ctl].usp_UpdateIssue
		 @pIssueId				= @IssueId
		,@pStatusCode			= 'IS'

select  @IssueId = isnull(IssueId,-1) from ctl.Issue where IssueName = 'PUBN03-COUR_20070112_01.txt'
print 'IssueId:   ' + cast(@IssueId as varchar(100)) 
print 'IssueName: PUBN03-COUR_20070112_01.txt'


exec [ctl].usp_UpdateIssue
		 @pIssueId				= @IssueId
		,@pStatusCode			= 'IS'


/******************************************************************************

Test Case: Update Issue Status - Complete

This test case represents the execution of staging packages.

******************************************************************************/

-- select * from ctl.refstatus


select  @IssueId = isnull(IssueId,-1) from ctl.Issue where IssueName = 'PUBN01-ACCT_20070112_01.txt'
print 'IssueId:   ' + cast(@IssueId as varchar(100)) 
print 'IssueName: PUBN01-ACCT_20070112_01.txt'

exec [ctl].usp_UpdateIssue
		 @pIssueId				= @IssueId
		,@pStatusCode			= 'IL'


select  @IssueId = isnull(IssueId,-1) from ctl.Issue where IssueName = 'PUBN02-ASSG_20070112_01.txt'
print 'IssueId:   ' + cast(@IssueId as varchar(100)) 
print 'IssueName: PUBN02-ASSG_20070112_01.txt'

exec [ctl].usp_UpdateIssue
		 @pIssueId				= @IssueId
		,@pStatusCode			= 'IL'

select  @IssueId = isnull(IssueId,-1) from ctl.Issue where IssueName = 'PUBN03-COUR_20070112_01.txt'
print 'IssueId:   ' + cast(@IssueId as varchar(100)) 
print 'IssueName: PUBN03-COUR_20070112_01.txt'


exec [ctl].usp_UpdateIssue
		 @pIssueId				= @IssueId
		,@pStatusCode			= 'IL'


/******************************************************************************

Test Case: Update Issue Status- Failed

This test case represents the execution of staging packages.

*** Testing this failure condition will cause issues with posting group
*** processing tests.

******************************************************************************/

-- select * from ctl.refstatus

select  @IssueId = isnull(IssueId,-1) from ctl.Issue where IssueName = 'PUBN03-COUR_20070112_01.txt'
print 'IssueId:   ' + cast(@IssueId as varchar(100)) 
print 'IssueName: PUBN03-COUR_20070112_01.txt'
/*
exec [ctl].usp_UpdateIssue
		 @pIssueId				= @IssueId
		,@pStatusCode			= 'IF'
*/

if @Verbose in (1,3) begin
	select  top 100 'Initial State Issue' AS TestingStep, * 
	from ctl.Issue

	select  top 100 'Initial State Distribution' AS TestingStep, * 
	from [ctl].[vw_DistributionStatus]

	select * from ctl.RefStatus where StatusType = 'Distribution'

end

	
	print 'Dunzo'


	
