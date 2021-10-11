print 'Start Live Person Domain Data Inserts'

declare	 @CurrentDtm	datetime		= getdate()
		,@CurrentUser	varchar(250)	= system_user
		,@Email			varchar(250)	= 'DE-Notify@ascentfunding.com'
		,@MyIssueId		int				= -1
		,@Verbose		int				= 0


-------------------------------------------------------------------------------
-- Contact, Live Person
-------------------------------------------------------------------------------


-- lets get some contacts.
if not exists (select top 1 1 from ctl.Contact where ContactName = 'Ascent Data Engineering')
EXEC [ctl].usp_InsertNewContact 
		 @pCompanyName				= 'Ascent Funding'
		,@pContactName				= 'Ascent Data Engineering'
		,@pTier						= '1'
		,@pEmail					= 'DataEngineering@ascentfunding.com'
		,@pPhone					= '877.300.6069'
		,@pAddress01				= '501 W. Broadway'
		,@pAddress02				= 'Ste A150'
		,@pCity						= 'San Diego'
		,@pState					= 'CA'
		,@pZipCode					= '92101'

if not exists (select top 1 1 from ctl.Contact where ContactName = 'Live Person Chat Support')
EXEC [ctl].usp_InsertNewContact 
		 @pCompanyName				= 'Live Person'
		,@pContactName				= 'Live Person Chat Support'
		,@pTier						= '1'
		,@pEmail					= ''
		,@pPhone					= ''
		,@pSupportURL				= 'https://z1.le.liveperson.net/a/55121139/#/camp/campaigns/web'
		,@pAddress01				= '475 10th Ave '
		,@pAddress02				= '5th Floor'
		,@pCity						= 'New York'
		,@pState					= 'NY'
		,@pZipCode					= '10018'


		

-------------------------------------------------------------------------------
-- Publisher, Live Person
-------------------------------------------------------------------------------

if not exists (select top 1 1 from ctl.Publisher where PublisherCode	= 'LVPRSN')
begin

exec [ctl].usp_InsertNewPublisher 
		 @pPublisherCode			= 'LVPRSN'
		,@pContactName				= 'Ascent Data Engineering'
		,@pPublisherName			= 'Live Person'
		,@pPublisherDesc			= 'Live Person provides chat functionality and make APIs available to dowlaod information.'
		,@pInterfaceCode			= 'API'
		,@pCreatedBy				= @CurrentUser
		,@pSiteURL					= 'http://api.liveperson.net/api/account/55121139'
		,@pSiteUser					= NULL
		,@pSitePassword				= NULL
		,@pSiteHostKeyFingerprint	= NULL
		,@pSitePort					= NULL
		,@pSiteProtocol				= NULL
		,@pPrivateKeyPassPhrase		= NULL
		,@pPrivateKeyFile			= NULL
		,@pETLExecutionId			= 0
		,@pPathId					= 0
		,@pVerbose					= @Verbose

end

-------------------------------------------------------------------------------
-- Subscriber, ODS Redshift
-------------------------------------------------------------------------------

if not exists (select top 1 1 from ctl.Subscriber where SubscriberCode	= 'ODSRS')
begin

exec [ctl].[usp_InsertNewSubscriber]   
     @pSubscriberCode				= 'ODSRS'
    ,@pContactName					= 'Ascent Data Engineering'
    ,@pSubscriberName				= 'Operational Data Store Red Shift'
	,@pSubscriberDesc				= 'Operational Data Store Red Shift this is the relational store in Red Shift that maintains raw infomration in a relational format.'
    ,@pInterfaceCode				= 'TBL'
	,@pSiteURL						= NULL  
	,@pSiteUser						= NULL 
	,@pSitePassword					= NULL           
	,@pSiteHostKeyFingerprint		= NULL                             
	,@pSitePort						= NULL
	,@pSiteProtocol					= NULL
	,@pPrivateKeyPassPhrase			= NULL 
	,@pPrivateKeyFile				= NULL 
	,@pNotificationHostName			= 'UNK'
	,@pNotificationInstance			= 'UNK'
	,@pNotificationDatabase			= 'UNK'
	,@pNotificationSchema			= 'UNK'
	,@pNotificationProcedure		= 'UNK'
    ,@pCreatedBy					= @CurrentUser
	,@pVerbose						= @Verbose

end

-------------------------------------------------------------------------------
-- Subscriber, ODS SQL Server
-------------------------------------------------------------------------------

if not exists (select top 1 1 from ctl.Subscriber where SubscriberCode	= 'ODSMSSQL')
begin

exec [ctl].[usp_InsertNewSubscriber]   
     @pSubscriberCode				= 'ODSMSSQL'
    ,@pContactName					= 'Ascent Data Engineering'
    ,@pSubscriberName				= 'Operational Data Store Microsoft SQL Server'
	,@pSubscriberDesc				= 'Operational Data Store Microsoft SQL Server this is the relational store in Microsoft SQL Server that maintains raw information in a relational format.'
    ,@pInterfaceCode				= 'TBL'
	,@pSiteURL						= NULL  
	,@pSiteUser						= NULL 
	,@pSitePassword					= NULL           
	,@pSiteHostKeyFingerprint		= NULL                             
	,@pSitePort						= NULL
	,@pSiteProtocol					= NULL
	,@pPrivateKeyPassPhrase			= NULL 
	,@pPrivateKeyFile				= NULL 
	,@pNotificationHostName			= 'UNK'
	,@pNotificationInstance			= 'UNK'
	,@pNotificationDatabase			= 'UNK'
	,@pNotificationSchema			= 'UNK'
	,@pNotificationProcedure		= 'UNK'
    ,@pCreatedBy					= @CurrentUser
	,@pVerbose						= @Verbose

end


-------------------------------------------------------------------------------
-- Publication
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------
-- Publication -- Engagement History
-------------------------------------------------------------------------------


if not exists (select top 1 1 from ctl.Publication where PublicationCode	= 'ENGAGEHIST')
begin

EXEC [ctl].[usp_InsertNewPublication] 
	 @pPublisherCode			= 'LVPRSN' -- varchar(20) 
	,@pPublicationCode			= 'ENGAGEHIST'-- varchar(50) 
	,@pPublicationName			= 'Engagement History' -- varchar(50) 
	,@pPublicationDesc			= 'Engagement History provided a data set of all chat history interactions with ascent customers.' -- varchar(1000)  'UNK'
	,@pSrcPublicationName		= 'Engagment History'--_[1..9]{8}_[1..9]{8}\.csv$ -- varchar(255)  'UNK'
	,@pPublicationFilePath		= 'N/A'
	,@pPublicationArchivePath	= 'N/A'
	,@pSrcFileFormatCode		= 'JSON'
	,@pStageJobName				= 'N/A'
	,@pSSISFolder				= 'N/A'
	,@pSSISProject				= 'N/A'
	,@pSSISPackage				= 'N/A'
	,@pDataFactoryName			= 'N/A'
	,@pDataFactoryPipeline		= 'N/A'
	,@pSrcDeltaAttributes		= 'UNK'
	,@pSrcFilePath				= 'https://va.enghist.liveperson.net/interaction_history/api/account/55121139/interactions/'
	,@pSrcFileRegEx				= 'UNK'
	,@pStandardFileRegEx		= 'ENGAGEHIST_((19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01]))_([0-1]?\d|2[0-3]):([0-5]?\d):([0-5]?\d).JSON' -- 'ENGAGEHIST_YYYYMMDD_HHMMSS.JSON'
	,@pStandardFileFormatCode	= 'JSON'
	,@pProcessingMethodCode		= 'GLUE'
	,@pTransferMethodCode		= 'DLT'
	,@pStorageMethodCode		= 'TXN'
	,@pIntervalCode				= 'DY'
	,@pIntervalLength			= 1
	,@pRetryIntervalCode		= 'HR'
	,@pRetryIntervalLength		= 1
	,@pRetryMax					= 0
	,@pPublicationEntity		= 'UNK'
	,@pDestTableName			= 'UNK'
	,@pSLATime					= '00:00'
	,@pSLAEndTimeInMinutes		=  240
	,@pNextExecutionDtm			= NULL -- '1900-01-01 00:00:00.000'
	,@pIsActive					= 1  -- Why insert it if it isn't active...
	,@pIsDataHub				= 1  -- Maybe it isn't data hub, shouldn't be...
	,@pBound					= 'In'	 --Inbound or Outbound
	,@pCreatedBy				= @CurrentUser
	,@pETLExecutionId			= -1
	,@pPathId					= -1
	,@pVerbose					= 0
	
end

-------------------------------------------------------------------------------
-- Contact Mapping
-------------------------------------------------------------------------------

if not exists (select top 1 1 from ctl.Publication pr 
				join ctl.MapContactToPublication mp 
				on pr.PublicationId = mp.PublicationId where  pr.PublicationCode = 'ENGAGEHIST')
begin 
	exec [ctl].[usp_InsertMapContactToPublication] 	
			 @pPublicationCode			= 'ENGAGEHIST'
			,@pContactName				= 'Ascent Data Engineering'
			,@pContactToPublicationDesc = ''
end

if not exists (select top 1 1 from ctl.Publication pr 
				join ctl.MapContactToPublication mp 
				on pr.PublicationId = mp.PublicationId where  pr.PublicationCode = 'ENGAGEHIST')
begin

	exec [ctl].[usp_InsertMapContactToPublication] 	
			 @pPublicationCode			= 'ENGAGEHIST'
			,@pContactName				= 'Live Person Chat Support'
			,@pContactToPublicationDesc = ''
end

-------------------------------------------------------------------------------
-- Subscription
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Subscription -- Engagement History to ODS RedShift
-------------------------------------------------------------------------------

if not exists (select top 1 1 from ctl.Subscription where SubscriptionCode	= 'LVPRSN-ODSRS-ENGAGEHIST')
begin

exec ctl.usp_InsertNewSubscription 
	 @pPublicationCode			= 'ENGAGEHIST'
	,@pSubscriberCode			= 'ODSRS'
	,@pSubscriptionName			= 'Live Person Engagement History to ODS Red Shift'
	,@pSubscriptionDesc			= 'Sending the Live Person Engagement History feed to ODS Red Shift'
	,@pInterfaceCode			= 'TBL'
	,@pIsActive					= 1
	,@pSubscriptionFilePath     = 'N/A'
	,@pSubscriptionArchivePath  = 'N/A'
	,@pSrcFilePath				= 'N/A'
	,@pDestTableName			= 'N/A'
	,@pDestFileFormatCode		= 'N/A'
	,@pCreatedBy				= @CurrentUser
	,@pVerbose					= 0

end 


-------------------------------------------------------------------------------
-- Posting Groups
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Posting Group -- Live Person Engagment History
-------------------------------------------------------------------------------

IF NOT EXISTS (SELECT TOP 1 1 FROM pg.PostingGroup WHERE PostingGroupCode = 'LVPRSN-ODSRS-ENGAGEHIST')
begin

	exec	[pg].[InsertPostingGroup]
		 @pPostingGroupCode			= 'LVPRSN-ODSRS-ENGAGEHIST'
		,@pPostingGroupName			= 'Live Person ODS Red Shift Engagement History' -- Test Publisher 01 Sending Data to Subscriber 02. Publication 02 Assignment
		,@pPostingGroupDesc			= 'Publisher Live Person Publication Engagement Hisorty sent to Subscriber ODS Red Shift.'
		,@pCategoryCode				= 'CHAT'
		,@pCategoryName				= 'Chat Data'
		,@pCategoryDesc				= 'Ascent chat interactions with borrowers.'
		,@pProcessingMethodCode		= 'GLUE'
		,@pProcessingModeCode		= 'NORM'
		,@pInterval					= 'DY'
		,@pLength					= 1
		,@pSSISFolder				= 'N/A'
		,@pSSISProject				= 'N/A'
		,@pSSISPackage				= 'N/A'
		,@pDataFactoryName			= 'N/A'
		,@pDataFactoryPipeline		= 'N/A'
		,@pJobName					= 'N/A'
		,@pRetryIntervalCode		= 'UNK'
		,@pRetryIntervalLength		= 1
		,@pRetryMax					= 0
		,@pIsActive					= 0
		,@pIsRoot					= 1
		,@pNextExecutionDtm			= NULL -- '1900-01-01 00:00:00.000'
		,@pCreatedBy				= @CurrentUser
		,@pETLExecutionId			= 0
		,@pPathId					= 0
		,@pVerbose					= 0
end

-------------------------------------------------------------------------------
-- Issue
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Issue -- Live Person Engagment History Initial Load
-------------------------------------------------------------------------------


if not exists (select top 1 1 from ctl.Issue where IssueName	like  'ENGAGEHIST_19000101_000000.txt')
begin

exec ctl.[usp_InsertNewIssue] 
	 @pPublicationCode		= 'ENGAGEHIST'
	,@pDataLakePath			= 'Unknown'
	,@pIssueName			= 'ENGAGEHIST_19000101_000000.txt'
	,@pStatusCode			= 'IP'
	,@pSrcPublisherId		= 'N/A'
	,@pSrcPublicationId		= 'N/A'
	,@pSrcDFIssueId			= 'N/A'
	,@pSrcDFCreatedDate		= '1900-01-01'
	,@pFirstRecordSeq		= 0
	,@pLastRecordSeq		= 0
	,@pFirstRecordChecksum	= 'N/A'
	,@pLastRecordChecksum	= 'N/A'
	,@pPeriodStartTime		= '1900-01-01'
	,@pPeriodEndTime		= '1900-01-01'
	,@pRecordCount			= 0
	,@pETLExecutionId		= 0
	,@pCreateBy				= @CurrentUser
	,@pIssueId				= @MyIssueId output
	,@pVerbose				= @Verbose

end 

print 'Returned Issue Id: ' + cast(@MyIssueId as varchar(200))




print 'Complete Live Person Domain Data Inserts'


