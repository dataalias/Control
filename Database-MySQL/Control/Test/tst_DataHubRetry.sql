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
USE BPI_DW_STAGE
GO

delete ctl.[distribution]			where IssueId			in (select IssueId from ctl.Issue where  publicationid in (select publicationid from ctl.publication where publicationcode in ('PUBN11-ACCT','PUBN12-ASSG','PUBN13-COUR')))
delete ctl.Issue					where publicationid		in (select publicationid from ctl.publication where publicationcode in ('PUBN11-ACCT','PUBN12-ASSG','PUBN13-COUR'))
delete ctl.MapContactToPublication	where publicationid		in (select publicationid from ctl.publication where publicationcode in ('PUBN11-ACCT','PUBN12-ASSG','PUBN13-COUR'))
delete ctl.MapContactToSubscription	where SubscriptionId	in (select SubscriptionId from ctl.Subscription where Subscriptioncode in ('PUBR12-SUBR11-PUBN13-COUR','PUBR11-SUBR11-PUBN11-ACCT','PUBR11-SUBR11-PUBN12-ASSG','PUBR11-SUBR12-PUBN12-ASSG','PUBR12-SUBR12-PUBN13-COUR'))
delete ctl.Subscription	 where subscriptioncode	in ('PUBR12-SUBR11-PUBN13-COUR','PUBR11-SUBR11-PUBN11-ACCT','PUBR11-SUBR11-PUBN12-ASSG','PUBR11-SUBR12-PUBN12-ASSG','PUBR12-SUBR12-PUBN13-COUR')
delete ctl.Publication	 where PublicationCode	in ('PUBN11-ACCT','PUBN12-ASSG','PUBN13-COUR')
delete ctl.Subscriber	 where subscribercode	in ('SUBR11' , 'SUBR12')
delete ctl.Publisher	 where publishercode	in('PUBR11','PUBR12')
delete ctl.Contact		 where [Name]			in ('PUB_Contact_Test11','PUB_Contact_Test12','SUB_Contact_Test11','SUB_Contact_Test12')




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
		,@CurrentUser  -- @CurrentUser
		,getdate())

if not exists (select top 1 1 from ctl.Contact where name = 'PUB_Contact_Test11')
EXEC [ctl].usp_InsertNewContact 
		 @pName						= 'PUB_Contact_Test11'
		,@pTier						= '1'
		,@pEmail					= 'omkar.chowkwale@zovio.com'
		,@pPhone					= '877.300.6069'
		,@pAddress01				= '10180 Telesis Ct'
		,@pAddress02				= '#400'
		,@pCity						= 'San Diego'
		,@pState					= 'CA'
		,@pZipCode					= '92121'

if not exists (select top 1 1 from ctl.Contact where name = 'PUB_Contact_Test12')
EXEC [ctl].usp_InsertNewContact 
		 @pName						= 'PUB_Contact_Test12'
		,@pTier						= '1'
		,@pEmail					= 'omkar.chowkwale@zovio.com'

if not exists (select top 1 1 from ctl.Contact where name = 'SUB_Contact_Test11')
EXEC [ctl].usp_InsertNewContact 
		 @pName						= 'SUB_Contact_Test11'
		,@pTier						= '1'
		,@pEmail					= 'omkar.chowkwale@zovio.com'

if not exists (select top 1 1 from ctl.Contact where name = 'SUB_Contact_Test12')
EXEC [ctl].usp_InsertNewContact 
		 @pName						= 'SUB_Contact_Test12'
		,@pTier						= '1'
		,@pEmail					= 'omkar.chowkwale@zovio.com'

--	select * from ctl.refstatus


/******************************************************************************
Test Case: Create New Publisher
******************************************************************************/
if not exists (select top 1 1 from ctl.Publisher where PublisherCode	= 'PUBR11')
begin

exec [ctl].usp_InsertNewPublisher 
		 @pPublisherCode		= 'PUBR11'
		,@pContactName			= 'BI-Development'
		,@pPublisherName		= '01 Test Publisher'
		,@pPublisherDesc		= 'First Test Publisher'
		,@pInterfaceCode		= 'TBL'
		,@pCreatedBy			= @CurrentUser  -- @CurrentUser -- @CurrentUser
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

if not exists (select top 1 1 from ctl.Publisher where PublisherCode	= 'PUBR12')
begin

exec [ctl].usp_InsertNewPublisher 
		 @pPublisherCode		= 'PUBR12'
		,@pContactName			= 'BI-Development'
		,@pPublisherName		= '02 Test Publisher'
		,@pPublisherDesc		= 'Second Test Publisher'
		,@pInterfaceCode		= 'TBL'
		,@pCreatedBy			= @CurrentUser  -- @CurrentUser -- @CurrentUser
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
	WHERE PublisherCode IN ('PUBR11','PUBR12')
/******************************************************************************
Test Case: Create New Subscriber
******************************************************************************/

if not exists (select top 1 1 from ctl.Subscriber where SubscriberCode	= 'SUBR11')
begin

exec [ctl].[usp_InsertNewSubscriber]   
     @pSubscriberCode			= 'SUBR11'
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
    ,@pCreatedBy				= @CurrentUser  -- @CurrentUser
	,@pVerbose					= 0

end

if not exists (select top 1 1 from ctl.Subscriber where SubscriberCode	= 'SUBR12')
begin

exec [ctl].[usp_InsertNewSubscriber]   
     @pSubscriberCode			= 'SUBR12'
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
    ,@pCreatedBy				= @CurrentUser  -- @CurrentUser
	,@pVerbose					= 0

end

if @Verbose in (1,3)
	select 'Initial State Subscriber' AS TestingStep, * 
	from ctl.Subscriber

/******************************************************************************
Test Case: Create New Publication
******************************************************************************/

if not exists (select top 1 1 from ctl.Publication where PublicationCode	= 'PUBN11-ACCT')
begin

EXEC [ctl].[usp_InsertNewPublication] 
	 @pPublisherCode			= 'PUBR11' -- varchar(20) 
	,@pPublicationCode			= 'PUBN11-ACCT'-- varchar(50) 
	,@pPublicationName			= 'Test Account Dim Feed' -- varchar(50) 
	,@pSrcPublicationName		= 'PUBN11-ACCT'--_[1..9]{8}_[1..9]{8}\.csv$ -- varchar(255) 
	,@pPublicationFilePath		= '' -- '\PUBR11\inbound\'-- varchar(255) 
	,@pPublicationArchivePath	= '' -- '\PUBR11\archive\'-- varchar(255)
	,@pSrcFileFormatCode				= '' -- 'csv'
	,@pStageJobName				= ''
	,@pSSISProject				= 'PostingGroup'
	,@pSSISFolder				= 'ETLFolder'
	,@pSSISPackage				= 'TSTPUBN11-ACCT.dtsx'
	,@pSrcFilePath				= '' -- '\\bpe-aesd-cifs\Share'
	,@pDataFactoryName			= 'N/A'
	,@pDataFactoryPipeline		= 'N/A'
--	,@pInterfaceCode			= 'FILE' -- varchar(20) 
	,@pMethodCode				= 'DLT' -- varchar(20) 
	,@pIntervalCode				= 'DLY' -- varchar(20) 
	,@pIntervalLength			= 1 -- int 
	,@pRetryIntervalCode		= 'HR'	--	varchar(20)
	,@pRetryIntervalLength		= 1	--	int
	,@pRetryMax					= 2	--	int
	,@pPublicationEntity		= '' -- 'PUBN11-ACCT_[1..9]{8}_[1..9]{8}\.csv$' -- varchar(255) 
	,@pDestTableName			= '[BPI_DW_STAGE].[schema].[TBL-ACCT]' -- varchar(255) 
	,@pSLATime					= '01:00'
	,@pSLAEndTimeInMinutes		= 10
	,@pNextExecutionDtm			= '1900-01-01 00:00:00.000'
	,@pIsActive					= 1  
	,@pIsDataHub				= 1
	,@pBound					= 'In'
	,@pCreatedBy				= @CurrentUser  -- @CurrentUser 
end

if not exists (select top 1 1 from ctl.Publication where PublicationCode	= 'PUBN12-ASSG')
begin


EXEC [ctl].[usp_InsertNewPublication] 
	 @pPublisherCode			= 'PUBR11' -- varchar(20) 
	,@pPublicationCode			= 'PUBN12-ASSG'-- varchar(50) 
	,@pPublicationName			= 'Test Assignment Dim Feed' -- varchar(50) 
	,@pSrcPublicationName		= 'PUBN12-ASSG'--_[1..9]{8}_[1..9]{8}\.csv$' -- varchar(255) 
	,@pPublicationFilePath		= '' -- '\PUBR11\inbound\'-- varchar(255) 
	,@pPublicationArchivePath	= '' -- '\PUBR11\archive\'-- varchar(255)
	,@pSrcFileFormatCode				= '' -- 'csv'
	,@pStageJobName				= ''
	,@pSSISProject				= 'PostingGroup'
	,@pSSISFolder				= 'ETLFolder'
	,@pSSISPackage				= 'TSTPUBN12-ASSG.dtsx'
	,@pSrcFilePath				= '' -- '\\bpe-aesd-cifs\Share'
	,@pDataFactoryName			= 'N/A'
	,@pDataFactoryPipeline		= 'N/A'
--	,@pInterfaceCode			= 'FILE' -- varchar(20) 
	,@pMethodCode				= 'DLT' -- varchar(20) 
	,@pIntervalCode				= 'DLY' -- varchar(20) 
	,@pIntervalLength			= 1 -- int 
	,@pRetryIntervalCode		= 'MIN'	--	varchar(20)
	,@pRetryIntervalLength		= 1	--	int
	,@pRetryMax					= 1	--	int
	,@pPublicationEntity		= '' -- 'PUBN11-ACCT_[1..9]{8}_[1..9]{8}\.csv$' -- varchar(255) 
	,@pDestTableName			= '[BPI_DW_STAGE].[schema].[TBL-ASSG]' -- varchar(255) 
	,@pSLATime					= '01:00'
	,@pSLAEndTimeInMinutes		= NULL
	,@pNextExecutionDtm			= '1900-01-01 00:00:00.000'
	,@pIsActive					= 1  
	,@pIsDataHub				= 1
	,@pBound					= 'In'
	,@pCreatedBy				= @CurrentUser  -- @CurrentUser -- varchar(50)	
end

if not exists (select top 1 1 from ctl.Publication where PublicationCode	= 'PUBN13-COUR')
begin

EXEC [ctl].[usp_InsertNewPublication] 
	 @pPublisherCode			= 'PUBR12' -- varchar(20) 
	,@pPublicationCode			= 'PUBN13-COUR'-- varchar(50) 
	,@pPublicationName			= 'Test Course Feed' -- varchar(50) 
	,@pSrcPublicationName		= 'PUBN13-COUR'--_[1..9]{8}_[1..9]{8}\.csv$' -- varchar(255) 
	,@pPublicationFilePath		= '' -- '\PUBR11\inbound\'-- varchar(255) 
	,@pPublicationArchivePath	= '' -- '\PUBR11\archive\'-- varchar(255)
	,@pSrcFileFormatCode				= '' -- 'csv'
	,@pStageJobName				= ''
	,@pSSISProject				= 'PostingGroup'
	,@pSSISFolder				= 'ETLFolder'
	,@pSSISPackage				= 'TSTPUBN13-COUR.dtsx'
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
	,@pPublicationEntity		= '' -- 'PUBN11-ACCT_[1..9]{8}_[1..9]{8}\.csv$' -- varchar(255) 
	,@pDestTableName			= '[BPI_DW_STAGE].[schema].[TBL-COUR]' -- varchar(255) 
	,@pSLATime					= '01:00'
	,@pSLAEndTimeInMinutes		= NULL
	,@pNextExecutionDtm			= '1900-01-01 00:00:00.000'
	,@pIsActive					= 1  
	,@pIsDataHub				= 1
	,@pBound					= 'In'
	,@pCreatedBy				= @CurrentUser  -- @CurrentUser -- varchar(50)	
end

if @Verbose in (1,3)
	select 'Initial State Publication' AS TestingStep, * 
	from ctl.Publication

/******************************************************************************
Test Case: Map Contacts to New Publication
******************************************************************************/

exec [ctl].[InsertMapContactToPublication] 	
		 @pPublicationCode			= 'PUBN11-ACCT'
		,@pContactName				= 'PUB_Contact_Test11'
		,@pContactToPublicationDesc = ''

exec [ctl].[InsertMapContactToPublication] 	
		 @pPublicationCode			= 'PUBN12-ASSG'
		,@pContactName				= 'PUB_Contact_Test11'
		,@pContactToPublicationDesc = ''

exec [ctl].[InsertMapContactToPublication] 	
		 @pPublicationCode			= 'PUBN13-COUR'
		,@pContactName				= 'PUB_Contact_Test12'
		,@pContactToPublicationDesc = ''

/******************************************************************************
Test Case: Create New Subscription
******************************************************************************/

-- declare @start datetime

SELECT  @START = GETDATE()

if not exists (select top 1 1 from ctl.Subscription where SubscriptionName	= 'SUB11 Account Data')
begin

exec ctl.usp_InsertNewSubscription 
	 @pPublicationCode			= 'PUBN11-ACCT'
	,@pSubscriberCode			= 'SUBR11'
	,@pSubscriptionName			= 'SUB11 Account Data'
	,@pSubscriptionDesc			= 'Sending the Account feed to subscriber 01'
	,@pInterfaceCode			= 'TBL'
	,@pIsActive					= 1
	,@pSubscriptionFilePath     = 'N/A'
	,@pSubscriptionArchivePath  = 'N/A'
	,@pSrcFilePath				= 'N/A'
	,@pDestTableName			= 'N/A'
	,@pSrcFileFormatCode				= 'N/A'
	,@pCreatedBy				= @CurrentUser  -- @CurrentUser
	,@pVerbose					= 0

end 
if not exists (select top 1 1 from ctl.Subscription where SubscriptionName	= 'SUB11 Assignment Data')
begin


exec ctl.usp_InsertNewSubscription 
	 @pPublicationCode			= 'PUBN12-ASSG'
	,@pSubscriberCode			= 'SUBR11'
	,@pSubscriptionName			= 'SUB11 Assignment Data'
	,@pSubscriptionDesc			= 'Sending the Assignment feed to subscriber 01'
	,@pInterfaceCode			= 'TBL'
	,@pIsActive					= 1
	,@pSubscriptionFilePath     = 'N/A'
	,@pSubscriptionArchivePath  = 'N/A'
	,@pSrcFilePath				= 'N/A'
	,@pDestTableName			= 'N/A'
	,@pSrcFileFormatCode				= 'N/A'
	,@pCreatedBy				= @CurrentUser  -- @CurrentUser
	,@pVerbose					= 0

end 
if not exists (select top 1 1 from ctl.Subscription where SubscriptionName	= 'SUB12 Assignment Data')
begin

exec ctl.usp_InsertNewSubscription 
	 @pPublicationCode			= 'PUBN12-ASSG'
	,@pSubscriberCode			= 'SUBR12'
	,@pSubscriptionName			= 'SUB12 Assignment Data'
	,@pSubscriptionDesc			= 'Sending the Assignment feed to subscriber 02'
	,@pInterfaceCode			= 'TBL'
	,@pIsActive					= 1
	,@pSubscriptionFilePath     = 'N/A'
	,@pSubscriptionArchivePath  = 'N/A'
	,@pSrcFilePath				= 'N/A'
	,@pDestTableName			= 'N/A'
	,@pSrcFileFormatCode				= 'N/A'
	,@pCreatedBy				= @CurrentUser  -- @CurrentUser
	,@pVerbose					= 0


end 
if not exists (select top 1 1 from ctl.Subscription where SubscriptionName	= 'SUB12 Course Data')
begin

exec ctl.usp_InsertNewSubscription 
	 @pPublicationCode			= 'PUBN13-COUR'
	,@pSubscriberCode			= 'SUBR11'
	,@pSubscriptionName			= 'SUB11 Course Data'
	,@pSubscriptionDesc			= 'Sending the Course feed to subscriber 02'
	,@pInterfaceCode			= 'TBL'
	,@pIsActive					= 1
	,@pSubscriptionFilePath     = 'N/A'
	,@pSubscriptionArchivePath  = 'N/A'
	,@pSrcFilePath				= 'N/A'
	,@pDestTableName			= 'N/A'
	,@pSrcFileFormatCode				= 'N/A'
	,@pCreatedBy				= @CurrentUser  -- @CurrentUser
	,@pVerbose					= 0

end

if @Verbose in (1,3)
	select 'Initial State Subscription' AS TestingStep, * 
	from ctl.Subscription

/******************************************************************************
Test Case: Map Contacts to New Subscription
******************************************************************************/

/* Test Subscritpions created.
PUBR11-SUBR11-PUBN11-ACCT
PUBR11-SUBR11-PUBN12-ASSG
PUBR11-SUBR12-PUBN12-ASSG
PUBR12-SUBR11-PUBN13-COUR
*/

exec [ctl].InsertMapContactToSubscription 	
		 @pSubscriptionCode			= 'PUBR11-SUBR11-PUBN11-ACCT'
		,@pContactName				= 'SUB_Contact_Test11'
		,@pContactToSubscriptionDesc = ''

exec [ctl].InsertMapContactToSubscription 	
		 @pSubscriptionCode			= 'PUBR11-SUBR11-PUBN12-ASSG'
		,@pContactName				= 'SUB_Contact_Test11'
		,@pContactToSubscriptionDesc = ''

exec [ctl].InsertMapContactToSubscription 	
		 @pSubscriptionCode			= 'PUBR11-SUBR12-PUBN12-ASSG'
		,@pContactName				= 'SUB_Contact_Test12'
		,@pContactToSubscriptionDesc = ''

exec [ctl].InsertMapContactToSubscription 	
		 @pSubscriptionCode			= 'PUBR12-SUBR11-PUBN13-COUR'
		,@pContactName				= 'SUB_Contact_Test11'
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

declare @Verbose		int
       ,@PassVerbose	bit
	   ,@START			datetime
	   ,@End			datetime
	   ,@IssueId		int
	   ,@MyIssueId		int 
	   ,@CurrentUser	VARCHAR(50) = SYSTEM_USER
	   ,@RetryCount		int
	   ,@IssueStatus	varchar(50)

SELECT @START = GETDATE()-.25
     , @END = GETDATE()
	 , @IssueId = -2
	 , @MyIssueId = -1

if not exists (select top 1 1 from ctl.Issue where IssueName	= 'PUBN11-ACCT_20070112_01.txt')
begin

exec ctl.[usp_InsertNewIssue] 
	@pPublicationCode= 'PUBN11-ACCT'
	,@pIssueName= 'PUBN11-ACCT_20070112_01.txt'
	,@pStatusCode= 'IP'
	,@pSrcDFIssueId= '0'
	,@pSrcDFCreatedDate= '1/2/2017'
	,@pFirstRecordSeq= 1
	,@pLastRecordSeq= 100
	,@pFirstRecordChecksum= 'ABC'
	,@pLastRecordChecksum= 'DEF'
	,@pPeriodStartTime= @START
	,@pPeriodEndTime= @END
	,@pRecordCount= 100
	,@pETLExecutionId= 99
	,@pCreateBy= @CurrentUser  -- @CurrentUser
	,@pIssueId = @MyIssueId output
	,@pVerbose= 0

end 

print 'Returned Issue Id: ' + cast(@MyIssueId as varchar(200))

exec ctl.[usp_InsertNewIssue] 
	@pPublicationCode= 'PUBN12-ASSG'
	,@pIssueName= 'PUBN12-ASSG_20070112_01.txt'
	,@pStatusCode= 'IP'
	,@pSrcDFIssueId= '0'
	,@pSrcDFCreatedDate= '1/2/2017'
	,@pFirstRecordSeq= 1
	,@pLastRecordSeq= 100
	,@pFirstRecordChecksum= 'ABC'
	,@pLastRecordChecksum= 'DEF'
	,@pPeriodStartTime= @START
	,@pPeriodEndTime= @END
	,@pRecordCount= 100
	,@pETLExecutionId= 99
	,@pCreateBy= @CurrentUser  -- @CurrentUser
	,@pIssueId = @MyIssueId output
	,@pVerbose= 0

print 'Returned Issue Id: ' + cast(@MyIssueId as varchar(200))

exec ctl.[usp_InsertNewIssue] 
	@pPublicationCode= 'PUBN13-COUR'
	,@pIssueName= 'PUBN13-COUR_20070112_01.txt'
	,@pStatusCode= 'IP'
	,@pSrcDFIssueId= '0'
	,@pSrcDFCreatedDate= '1/2/2017'
	,@pFirstRecordSeq= 1
	,@pLastRecordSeq= 100
	,@pFirstRecordChecksum= 'ABC'
	,@pLastRecordChecksum= 'DEF'
	,@pPeriodStartTime= @START
	,@pPeriodEndTime= @END
	,@pRecordCount= 100
	,@pETLExecutionId= 99
	,@pCreateBy= @CurrentUser  -- @CurrentUser
	,@pIssueId = @MyIssueId output
	,@pVerbose= 0

print 'Returned Issue Id: ' + cast(@MyIssueId as varchar(200))

SELECT @START = GETDATE()+.76
     , @END = GETDATE() + 1.01

exec ctl.[usp_InsertNewIssue] 
	@pPublicationCode= 'PUBN11-ACCT'
	,@pIssueName= 'PUBN11-ACCT_20070112_02.txt'
	,@pStatusCode= 'IP'
	,@pSrcDFIssueId= '0'
	,@pSrcDFCreatedDate= '1/2/2017'
	,@pFirstRecordSeq= 1
	,@pLastRecordSeq= 100
	,@pFirstRecordChecksum= 'ABC'
	,@pLastRecordChecksum= 'DEF'
	,@pPeriodStartTime= @START
	,@pPeriodEndTime= @END
	,@pRecordCount= 100
	,@pETLExecutionId= 99
	,@pCreateBy= @CurrentUser  -- @CurrentUser
	,@pIssueId = @MyIssueId output
	,@pVerbose= 0

print 'Returned Issue Id: ' + cast(@MyIssueId as varchar(200))

exec ctl.[usp_InsertNewIssue] 
	@pPublicationCode= 'PUBN12-ASSG'
	,@pIssueName= 'PUBN12-ASSG_20070112_02.txt'
	,@pStatusCode= 'IP'
	,@pSrcDFIssueId= '0'
	,@pSrcDFCreatedDate= '1/2/2017'
	,@pFirstRecordSeq= 1
	,@pLastRecordSeq= 100
	,@pFirstRecordChecksum= 'ABC'
	,@pLastRecordChecksum= 'DEF'
	,@pPeriodStartTime= @START
	,@pPeriodEndTime= @END
	,@pRecordCount= 100
	,@pETLExecutionId= 99
	,@pCreateBy= @CurrentUser  -- @CurrentUser
	,@pIssueId = @MyIssueId output
	,@pVerbose= 0

print 'Returned Issue Id: ' + cast(@MyIssueId as varchar(200))

exec ctl.[usp_InsertNewIssue] 
	@pPublicationCode= 'PUBN13-COUR'
	,@pIssueName= 'PUBN13-COUR_20070112_02.txt'
	,@pStatusCode= 'IP'
	,@pSrcDFIssueId= '0'
	,@pSrcDFCreatedDate= '1/2/2017'
	,@pFirstRecordSeq= 1
	,@pLastRecordSeq= 100
	,@pFirstRecordChecksum= 'ABC'
	,@pLastRecordChecksum= 'DEF'
	,@pPeriodStartTime= @START
	,@pPeriodEndTime= @END
	,@pRecordCount= 100
	,@pETLExecutionId= 99
	,@pCreateBy= @CurrentUser  -- @CurrentUser
	,@pIssueId = @MyIssueId output
	,@pVerbose= 0

	print 'Returned Issue Id: ' + cast(@MyIssueId as varchar(200))


/******************************************************************************

Test Case: Update Issue Status - Staging

This test case represents the execution of staging packages.

******************************************************************************/

-- select * from ctl.refstatus


select  @IssueId = isnull(IssueId,-1) from ctl.Issue where IssueName = 'PUBN11-ACCT_20070112_01.txt'
print 'IssueId:   ' + cast(@IssueId as varchar(100)) 
print 'IssueName: PUBN11-ACCT_20070112_01.txt'

exec [ctl].usp_UpdateIssue
		 @pIssueId				= @IssueId
		,@pStatusCode			= 'IS'


select  @IssueId = isnull(IssueId,-1) from ctl.Issue where IssueName = 'PUBN12-ASSG_20070112_01.txt'
print 'IssueId:   ' + cast(@IssueId as varchar(100)) 
print 'IssueName: PUBN12-ASSG_20070112_01.txt'

exec [ctl].usp_UpdateIssue
		 @pIssueId				= @IssueId
		,@pStatusCode			= 'IS'

select  @IssueId = isnull(IssueId,-1) from ctl.Issue where IssueName = 'PUBN13-COUR_20070112_01.txt'
print 'IssueId:   ' + cast(@IssueId as varchar(100)) 
print 'IssueName: PUBN13-COUR_20070112_01.txt'


exec [ctl].usp_UpdateIssue
		 @pIssueId				= @IssueId
		,@pStatusCode			= 'IS'


/******************************************************************************

Test Case: Update Issue Status - Complete

This test case represents the execution of staging packages.

******************************************************************************/

-- select * from ctl.refstatus


select  @IssueId = isnull(IssueId,-1) from ctl.Issue where IssueName = 'PUBN11-ACCT_20070112_01.txt'
print 'IssueId:   ' + cast(@IssueId as varchar(100)) 
print 'IssueName: PUBN11-ACCT_20070112_01.txt'

exec [ctl].usp_UpdateIssue
		 @pIssueId				= @IssueId
		,@pStatusCode			= 'IL'


select  @IssueId = isnull(IssueId,-1) from ctl.Issue where IssueName = 'PUBN12-ASSG_20070112_01.txt'
print 'IssueId:   ' + cast(@IssueId as varchar(100)) 
print 'IssueName: PUBN12-ASSG_20070112_01.txt'

exec [ctl].usp_UpdateIssue
		 @pIssueId				= @IssueId
		,@pStatusCode			= 'IL'

select  @IssueId = isnull(IssueId,-1) from ctl.Issue where IssueName = 'PUBN13-COUR_20070112_01.txt'
print 'IssueId:   ' + cast(@IssueId as varchar(100)) 
print 'IssueName: PUBN13-COUR_20070112_01.txt'


exec [ctl].usp_UpdateIssue
		 @pIssueId				= @IssueId
		,@pStatusCode			= 'IL'


/******************************************************************************

Test Case: Update Issue Status- Failed

This test case represents the execution of staging packages.

*** Testing this failure condition will cause issues with posting group
*** processing tests.

******************************************************************************/
select  @IssueId = isnull(IssueId,-1) from ctl.Issue where IssueName = 'PUBN11-ACCT_20070112_02.txt'
print 'IssueId:   ' + cast(@IssueId as varchar(100)) 
print 'IssueName: PUBN11-ACCT_20070112_02.txt'

exec [ctl].usp_UpdateIssue
		 @pIssueId				= @IssueId
		,@pStatusCode			= 'IF'

select  @IssueId = isnull(IssueId,-1) from ctl.Issue where IssueName = 'PUBN12-ASSG_20070112_02.txt'
print 'IssueId:   ' + cast(@IssueId as varchar(100)) 
print 'IssueName: PUBN12-ASSG_20070112_02.txt'

exec [ctl].usp_UpdateIssue
		 @pIssueId				= @IssueId
		,@pStatusCode			= 'IF'

select  @IssueId = isnull(IssueId,-1) from ctl.Issue where IssueName = 'PUBN13-COUR_20070112_02.txt'
print 'IssueId:   ' + cast(@IssueId as varchar(100)) 
print 'IssueName: PUBN13-COUR_20070112_02.txt'


exec [ctl].usp_UpdateIssue
		 @pIssueId				= @IssueId
		,@pStatusCode			= 'IF'

/******************************************************************************

Test Case: Retry failed Issue Records when 1) Retry Interval is NOT met
2) Retry Interval is met

This test case represents the re execution of staging packages.

*** Testing this failure condition will cause issues with posting group
*** processing tests.

******************************************************************************/
WAITFOR DELAY '00:02:00';
EXEC	[ctl].[usp_RetryDatahub]

SELECT @IssueId = isnull(IssueId, - 1)
	,@RetryCount = RetryCount
	,@IssueStatus = s.StatusCode
FROM ctl.Issue AS i
LEFT JOIN ctl.RefStatus AS s ON s.StatusId = i.StatusId
WHERE IssueName = 'PUBN11-ACCT_20070112_02.txt'

print 'IssueId:   ' + cast(@IssueId as varchar(100)) 
print 'IssueStatus:   ' + cast(@IssueStatus as varchar(100)) 
print 'RetryCount:   ' + cast(@RetryCount as varchar(100)) 
print 'Issue - PUBN11-ACCT_20070112_02.txt was not retried as SLAEndTime is not met'

SELECT @IssueId = isnull(IssueId, - 1)
	,@RetryCount = RetryCount
	,@IssueStatus = s.StatusCode
FROM ctl.Issue AS i
LEFT JOIN ctl.RefStatus AS s ON s.StatusId = i.StatusId
WHERE IssueName = 'PUBN12-ASSG_20070112_02.txt'

print 'IssueId:   ' + cast(@IssueId as varchar(100)) 
print 'IssueStatus:   ' + cast(@IssueStatus as varchar(100))
print 'RetryCount:   ' + cast(@RetryCount as varchar(100)) 
print 'Issue - PUBN12-ASSG_20070112_02.txt was retried as RetryInterval is met'

/******************************************************************************
Test Case: Issue Update to Fail in case RetryMax reached

This test case represents the re execution of staging packages.

*** Testing this failure condition will cause issues with posting group
*** processing tests.

******************************************************************************/
WAITFOR DELAY '00:02:00';
EXEC	[ctl].[usp_RetryDatahub]

SELECT @IssueId = isnull(IssueId, - 1)
	,@RetryCount = RetryCount
	,@IssueStatus = s.StatusCode
FROM ctl.Issue AS i
LEFT JOIN ctl.RefStatus AS s ON s.StatusId = i.StatusId
WHERE IssueName LIKE '%PUBN12-ASSG_20070112_02.txt'

print 'IssueId:   ' + cast(@IssueId as varchar(100)) 
print 'IssueStatus:   ' + cast(@IssueStatus as varchar(100))
print 'RetryCount:   ' + cast(@RetryCount as varchar(100)) 
print 'Issue - PUBN12-ASSG_20070112_02.txt status changed to failed as retry max reached'

