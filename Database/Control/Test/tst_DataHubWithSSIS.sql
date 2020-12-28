/******************************************************************************
File:           _DataHub.sql
Name:           _DataHub

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

20161206  ffortunato     initial iteration
20180731  ffortunato     we are back.
20180906	ffortunato		interface code

******************************************************************************/

-------------------------------------------------------------------------------
-- Declarations
-------------------------------------------------------------------------------
-- Verbose Helps dtermin how much output you want to see from the 
-- test process.

-- Cleanup
use Control


/*
select * from ctl.issue
*/


delete ctl.[distribution]
delete ctl.Issue where  publicationid in (select publicationid from ctl.publication where publicationcode in ('PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR'))
delete ctl.Subscription where subscriptioncode in ('PUBR02-SUBR01-PUBN03-COUR','PUBR01-SUBR01-PUBN01-ACCT','PUBR01-SUBR01-PUBN02-ASSG','PUBR01-SUBR02-PUBN02-ASSG','PUBR02-SUBR02-PUBN03-COUR')
delete ctl.Publication where PublicationCode in ('PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR')
delete ctl.Subscriber where subscribercode in ('SUBR01' , 'SUBR02')
delete ctl.Publisher where publishercode in('PUBR01','PUBR02')



-- Reset Key Values.
/*
DBCC CHECKIDENT ('ctl.[distribution]', RESEED, 0);
GO

DBCC CHECKIDENT ('ctl.[Issue]', RESEED, 0);
GO

DBCC CHECKIDENT ('ctl.[Subscription]', RESEED, 0);
GO

DBCC CHECKIDENT ('ctl.[Publication]', RESEED, 0);
GO

DBCC CHECKIDENT ('ctl.[Subscriber]', RESEED, 0);
GO

DBCC CHECKIDENT ('ctl.[Publisher]', RESEED, 0);
GO

DBCC CHECKIDENT ('ctl.[distribution]', RESEED, 0);
GO
*/
-------------------------------------------------------------------------------
-- Declaration and Initialization
-------------------------------------------------------------------------------

declare @Verbose       int
       ,@PassVerbose   bit
	   ,@Start         datetime
	   ,@End		   datetime
	   ,@IssueId	   int

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


/******************************************************************************
Test Case: Create New Publisher
******************************************************************************/
if not exists (select top 1 1 from ctl.Publisher where PublisherCode	= 'PUBR01')
begin

exec [ctl].usp_InsertNewPublisher 
		 @pPublisherCode		= 'PUBR01'
		,@pContactName			= 'BI-Development'
		,@pPublisherName		= '01 Test Publisher'
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

/******************************************************************************
Test Case: Create New Publication
******************************************************************************/

if not exists (select top 1 1 from ctl.Publication where PublicationCode	= 'PUBN01-ACCT')
begin

EXEC [ctl].[usp_InsertNewPublication] 
	 @pPublisherCode			= 'PUBR01' -- varchar(20) 
	,@pPublicationCode			= 'PUBN01-ACCT'-- varchar(50) 
	,@pPublicationName			= 'Test Account Dim Feed' -- varchar(50) 
	,@pSrcPublicationName		= 'PUBN01-ACCT'--_[1..9]{8}_[1..9]{8}\.csv$' -- varchar(255) 
	,@pPublicationFilePath		= '' -- '\PUBR01\inbound\'-- varchar(255) 
	,@pPublicationArchivePath	= '' -- '\PUBR01\archive\'-- varchar(255)
	,@pFeedFormat				= '' -- 'csv'
	,@pSrcFilePath				= '' -- '\\bpe-aesd-cifs\Share'
--	,@pInterfaceCode			= 'FILE' -- varchar(20) 
	,@pMethodCode				= 'DLT' -- varchar(20) 
	,@pIntervalCode				= 'HR' -- varchar(20) 
	,@pSLATime					= '01:00'
	,@pIntervalLength			= 1 -- int 
	--,@pRetryIntervalCode		= 'HR'	--	varchar(20)
	--,@pRetryIntervalLength	= 1	--	int
	--,@pRetryMax				= 3				--	int
	,@pPublicationEntity		= '' -- 'PUBN01-ACCT_[1..9]{8}_[1..9]{8}\.csv$' -- varchar(255) 
	,@pDestTableName			= '[Control].[schema].[TBL-ACCT]' -- varchar(255) 
	,@pIsActive					= 1  
	,@pIsDataHub				= 1
	,@pStageJobName				= ''
	,@pSSISProject				= 'PostingGroup'
	,@pSSISFolder				= 'ETLFolder'
	,@pSSISPackage				= 'TSTPUBN01-ACCT.dtsx'
	,@pCreatedBy				= 'ffortunato' -- varchar(50)


end
if not exists (select top 1 1 from ctl.Publication where PublicationCode	= 'PUBN02-ASSG')
begin


EXEC [ctl].[usp_InsertNewPublication] 
	 @pPublisherCode			= 'PUBR01' -- varchar(20) 
	,@pPublicationCode			= 'PUBN02-ASSG'-- varchar(50) 
	,@pPublicationName			= 'Test Assignment Feed' -- varchar(50) 
	,@pSrcPublicationName		= 'PUBN02-ASSG'--_[1..9]{8}_[1..9]{8}\.csv$' -- varchar(255) 
	,@pPublicationFilePath		= ''--'\PUBR01\inbound\'-- varchar(255) 
	,@pPublicationArchivePath	= ''--'\PUBR01\archive\'-- varchar(255)
	,@pFeedFormat				= ''--'csv'
	,@pSrcFilePath				= ''--'\\bpe-aesd-cifs\Share'
--	,@pInterfaceCode			= 'FILE' -- varchar(20) 
	,@pMethodCode				= 'DLT' -- varchar(20) 
	,@pIntervalCode				= 'HR' -- varchar(20) 
	,@pSLATime					= '01:00'
	,@pIntervalLength			= 1 -- int 
	--,@pRetryIntervalCode		= 'HR'	--	varchar(20)
	--,@pRetryIntervalLength	= 1	--	int
	--,@pRetryMax				= 3				--	int
	,@pPublicationEntity		= ''--'PUBN02-ASSG_[1..9]{8}_[1..9]{8}\.csv$' -- varchar(255) 
	,@pDestTableName			= '[Control].[schema].[TBL-ASSG]' -- varchar(255) 
	,@pIsActive					= 1  
	,@pIsDataHub				= 1
	,@pStageJobName				= ''
	,@pSSISProject				= 'PostingGroup'
	,@pSSISFolder				= 'ETLFolder'
	,@pSSISPackage				= 'TSTPUBN02-ASSG.dtsx'
	,@pCreatedBy				= 'ffortunato' -- varchar(50)

end 

if not exists (select top 1 1 from ctl.Publication where PublicationCode	= 'PUBN03-COUR')
begin

EXEC [ctl].[usp_InsertNewPublication] 
	 @pPublisherCode			= 'PUBR02' -- varchar(20) 
	,@pPublicationCode			= 'PUBN03-COUR'-- varchar(50) 
	,@pPublicationName			= 'Test Course Feed' -- varchar(50) 
	,@pSrcPublicationName		= 'PUBN03-COUR'--_[1..9]{8}_[1..9]{8}\.csv$' -- varchar(255) 
	,@pPublicationFilePath		= ''--'\PUBR02\inbound\'-- varchar(255) 
	,@pPublicationArchivePath	= ''--'\PUBR02\archive\'-- varchar(255)
	,@pFeedFormat				= ''--'csv'
	,@pSrcFilePath				= ''--'\\bpe-aesd-cifs\Share'
--	,@pInterfaceCode			= 'FILE' -- varchar(20) 
	,@pMethodCode				= 'DLT' -- varchar(20) 
	,@pIntervalCode				= 'HR' -- varchar(20) 
	,@pIntervalLength			= 1 -- int 
	,@pSLATime					= '01:00'
	--,@pRetryIntervalCode		= 'HR'	--	varchar(20)
	--,@pRetryIntervalLength	= 1	--	int
	--,@pRetryMax				= 3				--	int
	,@pPublicationEntity		= ''--'PUBN03-COUR_[1..9]{8}_[1..9]{8}\.csv$' -- varchar(255) 
	,@pDestTableName			= '[Control].[schema].[TBL-COUR]' -- varchar(255) 
	,@pIsActive					= 1  
	,@pIsDataHub				= 1
	,@pStageJobName				= ''
	,@pSSISProject				= 'PostingGroup'
	,@pSSISFolder				= 'ETLFolder'
	,@pSSISPackage				= 'TSTPUBN03-COUR.dtsx'
	,@pCreatedBy				= 'ffortunato' -- varchar(50)

end 
/*
if not exists (select top 1 1 from ctl.Publication where PublicationCode	= 'PUBN04-GRADE')
begin

EXEC [ctl].[usp_InsertNewPublication] 
	 @pPublisherCode			= 'PUBR02' -- varchar(20) 
	,@pPublicationCode			= 'PUBN04-GRADE'-- varchar(50) 
	,@pPublicationName			= 'Test Grade Feed' -- varchar(50) 
	,@pSrcPublicationName		= 'PUBN04-GRADE'--_[1..9]{8}_[1..9]{8}\.csv$' -- varchar(255) 
	,@pPublicationFilePath		= ''--'\PUBR02\inbound\'-- varchar(255) 
	,@pPublicationArchivePath	= ''--'\PUBR02\archive\'-- varchar(255)
	,@pFeedFormat				= ''--'csv'
	,@pSrcFilePath				= ''--'\\bpe-aesd-cifs\Share'
--	,@pInterfaceCode			= 'FILE' -- varchar(20) 
	,@pMethodCode				= 'DLT' -- varchar(20) 
	,@pIntervalCode				= 'HR' -- varchar(20) 
	,@pIntervalLength			= 1 -- int 
	,@pSLATime					= '01:00'
	--,@pRetryIntervalCode		= 'HR'	--	varchar(20)
	--,@pRetryIntervalLength	= 1	--	int
	--,@pRetryMax				= 3				--	int
	,@pPublicationEntity		= ''--'PUBN03-COUR_[1..9]{8}_[1..9]{8}\.csv$' -- varchar(255) 
	,@pDestTableName			= '[Control].[schema].[TBL-COUR]' -- varchar(255) 
	,@pIsActive					= 1  
	,@pIsDataHub				= 1
	,@pStageJobName				= ''
	,@pSSISProject				= 'PostingGroup'
	,@pSSISFolder				= 'ETLFolder'
	,@pSSISPackage				= 'TSTPUBN04-GRADE.dtsx'
	,@pCreatedBy				= 'ffortunato' -- varchar(50)

end 
*/
if @Verbose in (1,3)
	select 'Initial State Publication' AS TestingStep, * 
	from ctl.Publication


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
	,@pCreatedBy				= 'ffortunato'
	,@pVerbose					= 0


end 
if not exists (select top 1 1 from ctl.Subscription where SubscriptionName	= 'SUB02 Course Data')
begin

exec ctl.usp_InsertNewSubscription 
	 @pPublicationCode			= 'PUBN03-COUR'
	,@pSubscriberCode			= 'SUBR01'
	,@pSubscriptionName			= 'SUB01 Course Data'
	,@pSubscriptionDesc			= 'Sending the Course feed to subscriber 01'
	,@pInterfaceCode			= 'TBL'
	,@pIsActive					= 1
	,@pCreatedBy				= 'ffortunato'
	,@pVerbose					= 0

end

if @Verbose in (1,3)
	select 'Initial State Subscription' AS TestingStep, * 
	from ctl.Subscription
/*
if not exists (select top 1 1 from ctl.Subscription where SubscriptionName	= 'SUB02 Course Data')
begin

exec ctl.usp_InsertNewSubscription 
	 @pPublicationCode			= 'PUBN04-GRADE'
	,@pSubscriberCode			= 'SUBR02'
	,@pSubscriptionName			= 'SUB02 Grade Data'
	,@pSubscriptionDesc			= 'Sending the Grade feed to subscriber 02'
	,@pInterfaceCode			= 'TBL'
	,@pIsActive					= 1
	,@pCreatedBy				= 'ffortunato'
	,@pVerbose					= 0

end

if @Verbose in (1,3)
	select 'Initial State Subscription' AS TestingStep, * 
	from ctl.Subscription
*/
	
/******************************************************************************

Test Case: Dummy out Initial Issues

This test case represents the day to tday running of the pub sub model. 
As files / data move between publisher and subscriber issue and distribution
records are created. When a publisher creates an instance of a publication
and issue record is recorded. The issue is then distributed to each subscriber.
When an issue recored is created a distribution is created automaticaly based
on the subscriptions to a specific publication.

******************************************************************************/
go

declare @Verbose       int
       ,@PassVerbose   bit
	   ,@START         datetime
	   ,@End		   datetime
	   ,@IssueId	   int
	   ,@MyIssueId		int 
	  

SELECT @START = GETDATE()-.083333333
     , @END = GETDATE()-.0416666666
	 , @IssueId = -2
	 , @MyIssueId = -1

if not exists (select top 1 1 from ctl.Issue where IssueName	= 'PUBN01-ACCT_20070112_01.txt')
begin

exec ctl.[usp_InsertNewIssue] 
	@pPublicationCode= 'PUBN01-ACCT'
	,@pIssueName= 'PUBN01-ACCT_20070112_01.txt'
	,@pStatusCode= 'IC'
	,@pSrcDFIssueId= '0'
	,@pSrcDFCreatedDate= '1/2/2017'
	,@pFirstRecordSeq= 1
	,@pLastRecordSeq= 100
	,@pFirstRecordChecksum= ''
	,@pLastRecordChecksum= ''
	,@pPeriodStartTime= @START
	,@pPeriodEndTime= @END
	,@pRecordCount= 100
	,@pETLExecutionId= 99
	,@pCreateBy= 'ffortunato'
	,@pIssueId = @MyIssueId output
	,@pVerbose= 0

end 

print 'Returned Issue Id: ' + cast(@MyIssueId as varchar(200))

exec ctl.[usp_InsertNewIssue] 
	@pPublicationCode= 'PUBN02-ASSG'
	,@pIssueName= 'PUBN02-ASSG_20070112_01.txt'
	,@pStatusCode= 'IC'
	,@pSrcDFIssueId= '0'
	,@pSrcDFCreatedDate= '1/2/2017'
	,@pFirstRecordSeq= 1
	,@pLastRecordSeq= 100
	,@pFirstRecordChecksum= ''
	,@pLastRecordChecksum= ''
	,@pPeriodStartTime= @START
	,@pPeriodEndTime= @END
	,@pRecordCount= 100
	,@pETLExecutionId= 99
	,@pCreateBy= 'ffortunato'
	,@pIssueId = @MyIssueId output
	,@pVerbose= 0

print 'Returned Issue Id: ' + cast(@MyIssueId as varchar(200))

exec ctl.[usp_InsertNewIssue] 
	@pPublicationCode= 'PUBN03-COUR'
	,@pIssueName= 'PUBN03-COUR_20070112_01.txt'
	,@pStatusCode= 'IC'
	,@pSrcDFIssueId= '0'
	,@pSrcDFCreatedDate= '1/2/2017'
	,@pFirstRecordSeq= 1
	,@pLastRecordSeq= 100
	,@pFirstRecordChecksum= ''
	,@pLastRecordChecksum= ''
	,@pPeriodStartTime= @START
	,@pPeriodEndTime= @END
	,@pRecordCount= 100
	,@pETLExecutionId= 99
	,@pCreateBy= 'ffortunato'
	,@pIssueId = @MyIssueId output
	,@pVerbose= 0

print 'Returned Issue Id: ' + cast(@MyIssueId as varchar(200))
/*
exec ctl.[usp_InsertNewIssue] 
	@pPublicationCode= 'PUBN04-GRADE'
	,@pIssueName= 'PUBN04-GRADE_20070112_01.txt'
	,@pStatusCode= 'IC'
	,@pSrcDFIssueId= '0'
	,@pSrcDFCreatedDate= '1/2/2017'
	,@pFirstRecordSeq= 1
	,@pLastRecordSeq= 100
	,@pFirstRecordChecksum= ''
	,@pLastRecordChecksum= ''
	,@pPeriodStartTime= @START
	,@pPeriodEndTime= @END
	,@pRecordCount= 100
	,@pETLExecutionId= 99
	,@pCreateBy= 'ffortunato'
	,@pIssueId = @MyIssueId output
	,@pVerbose= 0

print 'Returned Issue Id: ' + cast(@MyIssueId as varchar(200))
*/
/******************************************************************************

Test Case: Create New Issues

This test case represents the hourly run of the TST feeds through datahub.
With the dh control strucutres populated data hub will create new issues
for the test publications. The TST SSIS packages will then be run to move
the issue status codes through their paces.

******************************************************************************/

if @Verbose in (1,3) begin
	select  top 100 'Initial State Issue' AS TestingStep, * 
	from ctl.Issue

	select  top 100 'Initial State Distribution' AS TestingStep, * 
	from [ctl].[DistributionStatus]

	select * from ctl.RefStatus where StatusType = 'Distribution'

end

/*
	select top 100 'Initial State Issue' AS TestingStep, * 
	from ctl.Issue order by IssueId desc
*/


/*
select * from ctl.issue order by 1 desc
	select * from ctl.Publisher
	select * from ctl.Publication
*/
	
