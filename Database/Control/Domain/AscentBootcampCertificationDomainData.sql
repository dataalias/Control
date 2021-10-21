print 'Start Live Person Domain Data Inserts'

-------------------------------------------------------------------------------
-- Cleanup
-------------------------------------------------------------------------------
/*
select * from  ctl.Publication	

delete ctl.[distribution]			where IssueId			in (select IssueId from ctl.Issue where  publicationid in (select publicationid from ctl.publication where publicationcode in ('ABPR','ABWR','FNACHAREF','FNACHAROST','LRCF','LOSCSF','DNACHAF','LRF','LONBF')))
delete ctl.Issue					where publicationid		in (select publicationid from ctl.publication where publicationcode in ('ABPR','ABWR','FNACHAREF','FNACHAROST','LRCF','LOSCSF','DNACHAF','LRF','LONBF'))
delete ctl.MapContactToPublication	where publicationid		in (select publicationid from ctl.publication where publicationcode in ('ABPR','ABWR','FNACHAREF','FNACHAROST','LRCF','LOSCSF','DNACHAF','LRF','LONBF'))
delete ctl.MapContactToSubscription	where SubscriptionId	in (select SubscriptionId from ctl.Subscription where Subscriptioncode in ('PUBR02-SUBR01-PUBN03-COUR','PUBR01-SUBR01-PUBN01-ACCT','PUBR01-SUBR01-PUBN02-ASSG','PUBR01-SUBR02-PUBN02-ASSG','PUBR02-SUBR02-PUBN03-COUR'))
delete ctl.Subscription				where subscriptioncode	in ('PUBR02-SUBR01-PUBN03-COUR','PUBR01-SUBR01-PUBN01-ACCT','PUBR01-SUBR01-PUBN02-ASSG','PUBR01-SUBR02-PUBN02-ASSG','PUBR02-SUBR02-PUBN03-COUR')
delete ctl.Publication				where PublicationCode	in ('ABPR','ABWR','FNACHAREF','FNACHAROST','LRCF','LOSCSF','DNACHAF','LRF','LONBF')
delete ctl.Subscriber				where subscribercode	in ('LAUNCH' , 'RSBSD')
*/


print 'Start declarations'

declare	 @CurrentDtm	datetime		= getdate()
		,@CurrentUser	varchar(250)	= system_user
		,@Email			varchar(250)	= 'DE-Notify@ascentfunding.com'
		,@MyIssueId		int				= -1
		,@Verbose		int				= 0


-------------------------------------------------------------------------------
-- Contact, Live Person
-------------------------------------------------------------------------------
print 'Start Insert contacts.'

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


-------------------------------------------------------------------------------
-- Publisher, Live Person
-------------------------------------------------------------------------------
print 'Start Insert Publisher ''Ascent Data Warehouse Microsoft SQL Server''.'

if not exists (select top 1 1 from ctl.Publisher where PublisherCode	= 'ADWMSSQL')
begin

exec [ctl].usp_InsertNewPublisher 
		 @pPublisherCode			= 'ADWMSSQL'
		,@pContactName				= 'Ascent Data Engineering'
		,@pPublisherName			= 'Ascent Data Warehouse Microsoft SQL Server'
		,@pPublisherDesc			= 'The Operational Data Store / Data Warehouse for Ascent funding hosted on Microsoft SQL Server.'
		,@pInterfaceCode			= 'SHARE'
		,@pCreatedBy				= @CurrentUser
		,@pSiteURL					= NULLL
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
-- Subscriber, Launch
-------------------------------------------------------------------------------
print 'Start Insert Subscriber ''Launch Loan Servicing''.'


if not exists (select top 1 1 from ctl.Subscriber where SubscriberCode	= 'LAUNCH')
begin

exec [ctl].[usp_InsertNewSubscriber]   
     @pSubscriberCode				= 'LAUNCH'
    ,@pContactName					= 'Ascent Data Engineering'
    ,@pSubscriberName				= 'Launch Loan Servicing'
	,@pSubscriberDesc				= 'The loan servicing platform hosted by Goal.'
    ,@pInterfaceCode				= 'SHARE'
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
-- Subscriber, Bank of Lake Mills
-------------------------------------------------------------------------------
/*
print 'Start Insert Subscriber ''Bank of Lake Mills''.'

if not exists (select top 1 1 from ctl.Subscriber where SubscriberCode	= 'BOLM')
begin

exec [ctl].[usp_InsertNewSubscriber]   
     @pSubscriberCode				= 'BOLM'
    ,@pContactName					= 'Ascent Data Engineering'
    ,@pSubscriberName				= 'Bank of Lake Mills'
	,@pSubscriberDesc				= 'The Bank of Lake Mills funds college loans generated by Ascent Funding.'
    ,@pInterfaceCode				= 'SHARE'
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
*/

-------------------------------------------------------------------------------
-- Subscriber, Richland State Bank South Dakota
-------------------------------------------------------------------------------
print 'Start Insert Subscriber ''Richland State Bank South Dakota''.'

if not exists (select top 1 1 from ctl.Subscriber where SubscriberCode	= 'RSBSD')
begin

exec [ctl].[usp_InsertNewSubscriber]   
     @pSubscriberCode				= 'RSBSD'
    ,@pContactName					= 'Ascent Data Engineering'
    ,@pSubscriberName				= 'Richland State Bank South Dakota'
	,@pSubscriberDesc				= 'Richland State Bank South Dakota funds bootcamp loans generated by Ascent Funding.'
    ,@pInterfaceCode				= 'SHARE'
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
-- Publication 1-- Ascent Bootcamp Predisbursment Roster
-------------------------------------------------------------------------------
print 'Start Insert Publication ''Ascent Bootcamp Predisbursment Roster''.'

if not exists (select top 1 1 from ctl.Publication where PublicationCode	= 'ABPR')
begin

EXEC [ctl].[usp_InsertNewPublication] 
	 @pPublisherCode			= 'ADWMSSQL' -- If its an e-mail who is the 
	,@pPublicationCode			= 'ABPR'-- varchar(50) 
	,@pPublicationName			= 'Ascent Bootcamp Predisbursment Roster' -- varchar(50) 
	,@pPublicationDesc			= 'This feed articulates the requested disbursment amounts from the bank. It is generated every Friday at 6:00 AM.' -- varchar(1000)  'UNK'
	,@pSrcPublicationName		= 'Engagment History'--_[1..9]{8}_[1..9]{8}\.csv$ -- varchar(255)  'UNK'
	,@pPublicationFilePath		= 'N/A'
	,@pPublicationArchivePath	= 'N/A'
	,@pSrcFileFormatCode		= 'CSV'
	,@pStageJobName				= 'N/A'
	,@pSSISFolder				= 'N/A'
	,@pSSISProject				= 'N/A'
	,@pSSISPackage				= 'N/A'
	,@pDataFactoryName			= 'N/A'
	,@pDataFactoryPipeline		= 'N/A'
	,@pSrcDeltaAttributes		= 'UNK'
	,@pSrcFilePath				= ''
	,@pSrcFileRegEx				= 'ABPR_((19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01]))_([0-1]?\d|2[0-3]):([0-5]?\d):([0-5]?\d).CSV'
	,@pStandardFileRegEx		= 'ABPR_((19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01]))_([0-1]?\d|2[0-3]):([0-5]?\d):([0-5]?\d).CSV' -- 'ENGAGEHIST_YYYYMMDD_HHMMSS.JSON'
	,@pStandardFileFormatCode	= 'JSON'
	,@pProcessingMethodCode		= 'SSIS'
	,@pTransferMethodCode		= 'DLT'
	,@pStorageMethodCode		= 'SS'
	,@pIntervalCode				= 'WK'
	,@pIntervalLength			= 1
	,@pRetryIntervalCode		= 'HR'
	,@pRetryIntervalLength		= 1
	,@pRetryMax					= 0
	,@pPublicationEntity		= 'UNK'
	,@pDestTableName			= 'UNK'
	,@pSLATime					= '06:00'
	,@pSLAEndTimeInMinutes		=  120
	,@pNextExecutionDtm			= NULL -- '1900-01-01 00:00:00.000'
	,@pIsActive					= 1  -- Why insert it if it isn't active...
	,@pIsDataHub				= 1  -- Maybe it isn't data hub, shouldn't be...
	,@pBound					= 'Out'	 --Inbound or Outbound
	,@pCreatedBy				= @CurrentUser
	,@pETLExecutionId			= -1
	,@pPathId					= -1
	,@pVerbose					= 0
	
end

-------------------------------------------------------------------------------
-- Contact Mapping
-------------------------------------------------------------------------------
print 'Start Insert Publication map to Contact ''Ascent Bootcamp Predisbursment Roster''.'

if not exists (select top 1 1 from ctl.Publication pr 
				join ctl.MapContactToPublication mp 
				on pr.PublicationId = mp.PublicationId where  pr.PublicationCode = 'ABPR')
begin 
	exec [ctl].[usp_InsertMapContactToPublication] 	
			 @pPublicationCode			= 'ABPR'
			,@pContactName				= 'Ascent Data Engineering'
			,@pContactToPublicationDesc = ''
end

-------------------------------------------------------------------------------
-- Publication -- Ascent Bootcamp Weekly Refunds
-------------------------------------------------------------------------------
print 'Start Insert Publication ''Ascent Bootcamp Weekly Refunds''.'

if not exists (select top 1 1 from ctl.Publication where PublicationCode	= 'ABWR')
begin

EXEC [ctl].[usp_InsertNewPublication] 
	 @pPublisherCode			= 'ADWMSSQL' -- If its an e-mail who is the 
	,@pPublicationCode			= 'ABWR'-- varchar(50) 
	,@pPublicationName			= 'Ascent Bootcamp Weekly Refunds' -- varchar(50) 
	,@pPublicationDesc			= 'This feed articulates the requested refund amounts from the bank. It is generated every Friday at 6:00 AM.' -- varchar(1000)  'UNK'
	,@pSrcPublicationName		= 'ABWR_[1..9]{8}\.csv$' -- varchar(255)  'UNK'
	,@pPublicationFilePath		= 'N/A'
	,@pPublicationArchivePath	= 'N/A'
	,@pSrcFileFormatCode		= 'CSV'
	,@pStageJobName				= 'N/A'
	,@pSSISFolder				= 'UNK'
	,@pSSISProject				= 'UNK'
	,@pSSISPackage				= 'UNK'
	,@pDataFactoryName			= 'N/A'
	,@pDataFactoryPipeline		= 'N/A'
	,@pSrcDeltaAttributes		= 'UNK'
	,@pSrcFilePath				= ''
	,@pSrcFileRegEx				= 'ABWR_((19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01]))_([0-1]?\d|2[0-3]):([0-5]?\d):([0-5]?\d).CSV'
	,@pStandardFileRegEx		= 'ABWR_((19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01]))_([0-1]?\d|2[0-3]):([0-5]?\d):([0-5]?\d).CSV' -- 'ENGAGEHIST_YYYYMMDD_HHMMSS.JSON'
	,@pStandardFileFormatCode	= 'CSV'
	,@pProcessingMethodCode		= 'SSIS'
	,@pTransferMethodCode		= 'DLT'
	,@pStorageMethodCode		= 'SS'
	,@pIntervalCode				= 'WK'
	,@pIntervalLength			= 1
	,@pRetryIntervalCode		= 'HR'
	,@pRetryIntervalLength		= 1
	,@pRetryMax					= 0
	,@pPublicationEntity		= 'UNK'
	,@pDestTableName			= 'UNK'
	,@pSLATime					= '06:00'
	,@pSLAEndTimeInMinutes		=  120
	,@pNextExecutionDtm			= NULL -- '1900-01-01 00:00:00.000'
	,@pIsActive					= 1  -- Why insert it if it isn't active...
	,@pIsDataHub				= 1  -- Maybe it isn't data hub, shouldn't be...
	,@pBound					= 'Out'	 --Inbound or Outbound
	,@pCreatedBy				= @CurrentUser
	,@pETLExecutionId			= -1
	,@pPathId					= -1
	,@pVerbose					= 0
	
end

-------------------------------------------------------------------------------
-- Contact Mapping
-------------------------------------------------------------------------------
print 'Start Insert Contact ''Ascent Bootcamp Weekly Refunds''.'

if not exists (select top 1 1 from ctl.Publication pr 
				join ctl.MapContactToPublication mp 
				on pr.PublicationId = mp.PublicationId where  pr.PublicationCode = 'ABWR')
begin 
	exec [ctl].[usp_InsertMapContactToPublication] 	
			 @pPublicationCode			= 'ABWR'
			,@pContactName				= 'Ascent Data Engineering'
			,@pContactToPublicationDesc = ''
end

-------------------------------------------------------------------------------
-- Publication -- Final NACHA Ach Refund File <<<AND ROASTER FILE>>>
-------------------------------------------------------------------------------
print 'Start Insert Publication ''Final NACHA Ach Refund File''.'

if not exists (select top 1 1 from ctl.Publication where PublicationCode	= 'FNACHAREF')
begin

EXEC [ctl].[usp_InsertNewPublication] 
	 @pPublisherCode			= 'ADWMSSQL' -- If its an e-mail who is the 
	,@pPublicationCode			= 'FNACHAREF'-- varchar(50) 
	,@pPublicationName			= 'Final NACHA Ach Refund File' -- varchar(50) 
	,@pPublicationDesc			= 'Final National Automated Clearning House Association (NACHA) Automated Clearing House (ACH) Refund File.  REfunds to be processed. The file is generated every Friday at 6:00 AM.' -- varchar(1000)  'UNK'
	,@pSrcPublicationName		= 'NACHA_ACHFile_SF_Refund_[1..9]{8}\.txt$' -- varchar(255)  'UNK'
	,@pPublicationFilePath		= '\\afshare\Data_Operations\Systems\CertificationFileTransfer\Bootcamp\NACHA\Outbound\'
	,@pPublicationArchivePath	= '\\afshare\Data_Operations\Systems\CertificationFileTransfer\Bootcamp\Archive\NACHA_Archive\Outbound\NACHA_ACH_Refund'
	,@pSrcFileFormatCode		= 'TXT'
	,@pStageJobName				= 'N/A'
	,@pSSISFolder				= 'UNK'
	,@pSSISProject				= 'UNK'
	,@pSSISPackage				= 'UNK'
	,@pDataFactoryName			= 'N/A'
	,@pDataFactoryPipeline		= 'N/A'
	,@pSrcDeltaAttributes		= 'UNK'
	,@pSrcFilePath				= 'UNK'
	,@pSrcFileRegEx				= 'NACHA_ACHFile_SF_Refund_' -- 'FNACHAREF_((19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01]))_([0-1]?\d|2[0-3]):([0-5]?\d):([0-5]?\d).CSV'
	,@pStandardFileRegEx		= 'FNACHAREF_((19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01]))_([0-1]?\d|2[0-3]):([0-5]?\d):([0-5]?\d).CSV' -- 'ENGAGEHIST_YYYYMMDD_HHMMSS.JSON'
	,@pStandardFileFormatCode	= 'CSV' -- ???
	,@pProcessingMethodCode		= 'SSIS'
	,@pTransferMethodCode		= 'DLT'
	,@pStorageMethodCode		= 'SS'
	,@pIntervalCode				= 'WK'
	,@pIntervalLength			= 1
	,@pRetryIntervalCode		= 'HR'
	,@pRetryIntervalLength		= 1
	,@pRetryMax					= 0
	,@pPublicationEntity		= 'UNK'
	,@pDestTableName			= 'UNK'
	,@pSLATime					= '06:00'
	,@pSLAEndTimeInMinutes		=  120
	,@pNextExecutionDtm			= NULL -- '1900-01-01 00:00:00.000'
	,@pIsActive					= 1  -- Why insert it if it isn't active...
	,@pIsDataHub				= 1  -- Maybe it isn't data hub, shouldn't be...
	,@pBound					= 'Out'	 --Inbound or Outbound
	,@pCreatedBy				= @CurrentUser
	,@pETLExecutionId			= -1
	,@pPathId					= -1
	,@pVerbose					= 0
	
end

-------------------------------------------------------------------------------
-- Contact Mapping
-------------------------------------------------------------------------------
print 'Start Insert Contact ''Final NACHA Ach Refund File''.'

if not exists (select top 1 1 from ctl.Publication pr 
				join ctl.MapContactToPublication mp 
				on pr.PublicationId = mp.PublicationId where  pr.PublicationCode = 'FNACHAREF')
begin 
	exec [ctl].[usp_InsertMapContactToPublication] 	
			 @pPublicationCode			= 'FNACHAREF'
			,@pContactName				= 'Ascent Data Engineering'
			,@pContactToPublicationDesc = ''
end

/*
-------------------------------------------------------------------------------
-- Publication -- Final NACHA Ach ROASTER FILE
-------------------------------------------------------------------------------
print 'Start Insert Publication ''Final NACHA Ach Refund File''.' 

if not exists (select top 1 1 from ctl.Publication where PublicationCode	= 'FNACHAROST')
begin

EXEC [ctl].[usp_InsertNewPublication] 
	 @pPublisherCode			= 'ADWMSSQL' -- If its an e-mail who is the 
	,@pPublicationCode			= 'FNACHAROST'-- varchar(50) 
	,@pPublicationName			= 'Final NACHA Ach Roster File' -- varchar(50) 
	,@pPublicationDesc			= 'Final National Automated Clearning House Association (NACHA) Automated Clearing House (ACH) Refund File.  REfunds to be processed. The file is generated every Friday at 6:00 AM.' -- varchar(1000)  'UNK'
	,@pSrcPublicationName		= 'NACHA_ACHFile_SF_Roster_[1..9]{8}\.txt$' -- varchar(255)  'UNK'
	,@pPublicationFilePath		= '\\afshare\Data_Operations\Systems\CertificationFileTransfer\Bootcamp\NACHA\Outbound\'
	,@pPublicationArchivePath	= 'Y:\Data_Operations\Systems\CertificationFileTransfer\Bootcamp\Archive\????'
	,@pSrcFileFormatCode		= 'TXT'
	,@pStageJobName				= 'N/A'
	,@pSSISFolder				= 'UNK'
	,@pSSISProject				= 'UNK'
	,@pSSISPackage				= 'UNK'
	,@pDataFactoryName			= 'N/A'
	,@pDataFactoryPipeline		= 'N/A'
	,@pSrcDeltaAttributes		= 'UNK'
	,@pSrcFilePath				= 'UNK'
	,@pSrcFileRegEx				= 'NACHA_ACHFile_SF_Refund_' -- 'FNACHAREF_((19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01]))_([0-1]?\d|2[0-3]):([0-5]?\d):([0-5]?\d).CSV'
	,@pStandardFileRegEx		= 'FNACHAROST_((19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01]))_([0-1]?\d|2[0-3]):([0-5]?\d):([0-5]?\d).CSV' -- 'FNACHAROST_YYYYMMDD_HHMMSS.JSON'
	,@pStandardFileFormatCode	= 'CSV' -- ???
	,@pProcessingMethodCode		= 'SSIS'
	,@pTransferMethodCode		= 'DLT'
	,@pStorageMethodCode		= 'SS'
	,@pIntervalCode				= 'WK'
	,@pIntervalLength			= 1
	,@pRetryIntervalCode		= 'HR'
	,@pRetryIntervalLength		= 1
	,@pRetryMax					= 0
	,@pPublicationEntity		= 'UNK'
	,@pDestTableName			= 'UNK'
	,@pSLATime					= '06:00'
	,@pSLAEndTimeInMinutes		=  120
	,@pNextExecutionDtm			= NULL -- '1900-01-01 00:00:00.000'
	,@pIsActive					= 1  -- Why insert it if it isn't active...
	,@pIsDataHub				= 1  -- Maybe it isn't data hub, shouldn't be...
	,@pBound					= 'Out'	 --Inbound or Outbound
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
			 @pPublicationCode			= 'FNACHAREF'
			,@pContactName				= 'Ascent Data Engineering'
			,@pContactToPublicationDesc = ''
end
*/

-------------------------------------------------------------------------------
-- Publication -- Launch Refund Change File (LRCF)
-------------------------------------------------------------------------------
print 'Start Insert Publication ''Launch Refund Change File (LRCF)''.'

if not exists (select top 1 1 from ctl.Publication where PublicationCode	= 'LRCF')
begin

EXEC [ctl].[usp_InsertNewPublication] 
	 @pPublisherCode			= 'ADWMSSQL' -- If its an e-mail who is the 
	,@pPublicationCode			= 'LRCF'-- varchar(50) 
	,@pPublicationName			= 'Launch Refund Change File' -- varchar(50) 
	,@pPublicationDesc			= 'This file sends a refund changes to the Launch system. The file is generated every Friday at ??:?? AM.' -- varchar(1000)  'UNK'
	,@pSrcPublicationName		= 'NACHA_ACHFile_SF_Refund_[1..9]{8}\.txt$' -- varchar(255)  'UNK'
	,@pPublicationFilePath		= '\\afshare\Data_Operations\Systems\CertificationFileTransfer\Bootcamp\NACHA\Outbound\'
	,@pPublicationArchivePath	= '\\afshare\Data_Operations\Systems\CertificationFileTransfer\Bootcamp\Archive\????'
	,@pSrcFileFormatCode		= 'TXT'
	,@pStageJobName				= 'N/A'
	,@pSSISFolder				= 'UNK'
	,@pSSISProject				= 'UNK'
	,@pSSISPackage				= 'UNK'
	,@pDataFactoryName			= 'N/A'
	,@pDataFactoryPipeline		= 'N/A'
	,@pSrcDeltaAttributes		= 'UNK'
	,@pSrcFilePath				= 'UNK'
	,@pSrcFileRegEx				= 'Skills_Change_Refunds_((19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01]))' -- Skills_Change_Refunds_YYYYMMDD.txt
	,@pStandardFileRegEx		= 'LRCF_((19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01]))_([0-1]?\d|2[0-3]):([0-5]?\d):([0-5]?\d).CSV' -- 'ENGAGEHIST_YYYYMMDD_HHMMSS.JSON'
	,@pStandardFileFormatCode	= 'TXT' -- ???
	,@pProcessingMethodCode		= 'SSIS'
	,@pTransferMethodCode		= 'DLT'
	,@pStorageMethodCode		= 'SS'
	,@pIntervalCode				= 'DY'
	,@pIntervalLength			= 1
	,@pRetryIntervalCode		= 'HR'
	,@pRetryIntervalLength		= 1
	,@pRetryMax					= 0
	,@pPublicationEntity		= 'UNK'
	,@pDestTableName			= 'UNK'
	,@pSLATime					= '06:00'
	,@pSLAEndTimeInMinutes		=  120
	,@pNextExecutionDtm			= NULL -- '1900-01-01 00:00:00.000'
	,@pIsActive					= 1  -- Why insert it if it isn't active...
	,@pIsDataHub				= 1  -- Maybe it isn't data hub, shouldn't be...
	,@pBound					= 'Out'	 --Inbound or Outbound
	,@pCreatedBy				= @CurrentUser
	,@pETLExecutionId			= -1
	,@pPathId					= -1
	,@pVerbose					= 0
	
end

-------------------------------------------------------------------------------
-- Contact Mapping
-------------------------------------------------------------------------------
print 'Start Insert Contact ''Launch Refund Change File (LRCF)''.'
if not exists (select top 1 1 from ctl.Publication pr 
				join ctl.MapContactToPublication mp 
				on pr.PublicationId = mp.PublicationId where  pr.PublicationCode = 'LRCF')
begin 
	exec [ctl].[usp_InsertMapContactToPublication] 	
			 @pPublicationCode			= 'LRCF'
			,@pContactName				= 'Ascent Data Engineering'
			,@pContactToPublicationDesc = ''
end

-------------------------------------------------------------------------------
-- Publication -- LOS Cert Sys File
-------------------------------------------------------------------------------
print 'Start Insert Publication ''Loan Origination System Certification System File (LOSCSF)''.'

if not exists (select top 1 1 from ctl.Publication where PublicationCode	= 'LOSCSF')
begin

EXEC [ctl].[usp_InsertNewPublication] 
	 @pPublisherCode			= 'ADWMSSQL' -- If its an e-mail who is the 
	,@pPublicationCode			= 'LOSCSF'-- varchar(50) 
	,@pPublicationName			= 'Loan Origination System Certification System File' -- varchar(50) 
	,@pPublicationDesc			= '. The file is generated every day at ??:?? AM.' -- varchar(1000)  'UNK'
	,@pSrcPublicationName		= 'SF_CertSys_[1..9]{8}\.txt$' -- SF_CertSys_YYYYMMDDhhmmss.csv
	,@pPublicationFilePath		= '\\asfileshare\Data_Operations\Systems\CertificationFileTransfer\Bootcamp\LOS\Outbound\'
	,@pPublicationArchivePath	= 'Y:\Data_Operations\Systems\CertificationFileTransfer\Bootcamp\Archive\????'
	,@pSrcFileFormatCode		= 'TXT'
	,@pStageJobName				= 'N/A'
	,@pSSISFolder				= 'UNK'
	,@pSSISProject				= 'UNK'
	,@pSSISPackage				= 'UNK'
	,@pDataFactoryName			= 'N/A'
	,@pDataFactoryPipeline		= 'N/A'
	,@pSrcDeltaAttributes		= 'UNK'
	,@pSrcFilePath				= 'UNK'
	,@pSrcFileRegEx				= 'NACHA_ACHFile_SF_Refund_' -- 'FNACHAREF_((19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01]))_([0-1]?\d|2[0-3]):([0-5]?\d):([0-5]?\d).CSV'
	,@pStandardFileRegEx		= 'FNACHAREF_((19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01]))_([0-1]?\d|2[0-3]):([0-5]?\d):([0-5]?\d).CSV' -- 'ENGAGEHIST_YYYYMMDD_HHMMSS.JSON'
	,@pStandardFileFormatCode	= 'CSV' -- ???
	,@pProcessingMethodCode		= 'SSIS'
	,@pTransferMethodCode		= 'DLT'
	,@pStorageMethodCode		= 'SS'
	,@pIntervalCode				= 'WK'
	,@pIntervalLength			= 1
	,@pRetryIntervalCode		= 'HR'
	,@pRetryIntervalLength		= 1
	,@pRetryMax					= 0
	,@pPublicationEntity		= 'UNK'
	,@pDestTableName			= 'UNK'
	,@pSLATime					= '06:00'
	,@pSLAEndTimeInMinutes		=  120
	,@pNextExecutionDtm			= NULL -- '1900-01-01 00:00:00.000'
	,@pIsActive					= 1  -- Why insert it if it isn't active...
	,@pIsDataHub				= 1  -- Maybe it isn't data hub, shouldn't be...
	,@pBound					= 'Out'	 --Inbound or Outbound
	,@pCreatedBy				= @CurrentUser
	,@pETLExecutionId			= -1
	,@pPathId					= -1
	,@pVerbose					= 0
	
end

-------------------------------------------------------------------------------
-- Contact Mapping
-------------------------------------------------------------------------------
print 'Start Insert Contact ''Loan Origination System Certification System File (LOSCSF)''.'
if not exists (select top 1 1 from ctl.Publication pr 
				join ctl.MapContactToPublication mp 
				on pr.PublicationId = mp.PublicationId where  pr.PublicationCode = 'LOSCSF')
begin 
	exec [ctl].[usp_InsertMapContactToPublication] 	
			 @pPublicationCode			= 'LOSCSF'
			,@pContactName				= 'Ascent Data Engineering'
			,@pContactToPublicationDesc = ''
end

-------------------------------------------------------------------------------
-- Publication -- Disbursement NACHA ACH File
-------------------------------------------------------------------------------
print 'Start Insert Publication ''Disbursement NACHA ACH File (DNACHAF)''.'

if not exists (select top 1 1 from ctl.Publication where PublicationCode	= 'DNACHAF')
begin

EXEC [ctl].[usp_InsertNewPublication] 
	 @pPublisherCode			= 'ADWMSSQL' -- If its an e-mail who is the 
	,@pPublicationCode			= 'DNACHAF'-- varchar(50) 
	,@pPublicationName			= 'Disbursement NACHA ACH File' -- varchar(50) 
	,@pPublicationDesc			= '. The file is generated every Tuesday at ??:?? AM.' -- varchar(1000)  'UNK'
	,@pSrcPublicationName		= 'NACHA_ACHFile_SF_[1..9]{8}\.txt$' -- NACHA_ACHFile_SF_YYYYMMDD.txt
	,@pPublicationFilePath		= '\Data_Operations\Systems\CertificationFileTransfer\Bootcamp\NACHA\Outbound\NACHA_ACH\'
	,@pPublicationArchivePath	= '\Data_Operations\Systems\CertificationFileTransfer\Bootcamp\Archive\NACHA_Archive\Outbound\NACHA_ACH\'
	,@pSrcFileFormatCode		= 'TXT'
	,@pStageJobName				= 'N/A'
	,@pSSISFolder				= 'Certification'
	,@pSSISProject				= 'Certification'
	,@pSSISPackage				= 'Parent_DisbursmentRoster.dtsx'
	,@pDataFactoryName			= 'N/A'
	,@pDataFactoryPipeline		= 'N/A'
	,@pSrcDeltaAttributes		= 'UNK'
	,@pSrcFilePath				= 'UNK'
	,@pSrcFileRegEx				= 'NACHA_ACHFile_SF_Refund_' -- 'FNACHAREF_((19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01]))_([0-1]?\d|2[0-3]):([0-5]?\d):([0-5]?\d).CSV'
	,@pStandardFileRegEx		= 'FNACHAREF_((19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01]))_([0-1]?\d|2[0-3]):([0-5]?\d):([0-5]?\d).CSV' -- 'ENGAGEHIST_YYYYMMDD_HHMMSS.JSON'
	,@pStandardFileFormatCode	= 'CSV' -- ???
	,@pProcessingMethodCode		= 'SSIS'
	,@pTransferMethodCode		= 'DLT'
	,@pStorageMethodCode		= 'SS'
	,@pIntervalCode				= 'WK'
	,@pIntervalLength			= 1
	,@pRetryIntervalCode		= 'HR'
	,@pRetryIntervalLength		= 1
	,@pRetryMax					= 0
	,@pPublicationEntity		= 'UNK'
	,@pDestTableName			= 'UNK'
	,@pSLATime					= '09:00'
	,@pSLAEndTimeInMinutes		=  240
	,@pNextExecutionDtm			= NULL -- '1900-01-01 00:00:00.000'
	,@pIsActive					= 1  -- Why insert it if it isn't active...
	,@pIsDataHub				= 1  -- Maybe it isn't data hub, shouldn't be...
	,@pBound					= 'Out'	 --Inbound or Outbound
	,@pCreatedBy				= @CurrentUser
	,@pETLExecutionId			= -1
	,@pPathId					= -1
	,@pVerbose					= 0
	
end

-------------------------------------------------------------------------------
-- Contact Mapping
-------------------------------------------------------------------------------
print 'Start Insert Contact ''Disbursement NACHA ACH File (DNACHAF)''.'
if not exists (select top 1 1 from ctl.Publication pr 
				join ctl.MapContactToPublication mp 
				on pr.PublicationId = mp.PublicationId where  pr.PublicationCode = 'DNACHAF')
begin 
	exec [ctl].[usp_InsertMapContactToPublication] 	
			 @pPublicationCode			= 'DNACHAF'
			,@pContactName				= 'Ascent Data Engineering'
			,@pContactToPublicationDesc = ''
end

-------------------------------------------------------------------------------
-- Publication -- Launch Disbursment Roster File 
-------------------------------------------------------------------------------
print 'Start Insert Publication ''Launch Disbursment Roster File'' (LDRF).'

if not exists (select top 1 1 from ctl.Publication where PublicationCode	= 'LDRF')
begin

EXEC [ctl].[usp_InsertNewPublication] 
	 @pPublisherCode			= 'ADWMSSQL' -- If its an e-mail who is the 
	,@pPublicationCode			= 'LDRF'-- varchar(50) 
	,@pPublicationName			= 'Launch Disbursment Roster File' -- varchar(50) 
	,@pPublicationDesc			= 'Launch Disbursment Roster File. The file is generated every Wednesday at 11:00 AM.' -- varchar(1000)  'UNK'
	,@pSrcPublicationName		= 'Skills_RosterFile_[1..9]{8}\.txt$' -- NACHA_ACHFile_SF_YYYYMMDD.txt
	,@pPublicationFilePath		= '\Data_Operations\Systems\CertificationFileTransfer\Bootcamp\Launch\Outbound\Roster\'
	,@pPublicationArchivePath	= '\Data_Operations\Systems\CertificationFileTransfer\Bootcamp\Archive\Launch_Archive\Outbound\Roster\'
	,@pSrcFileFormatCode		= 'TXT'
	,@pStageJobName				= 'N/A'
	,@pSSISFolder				= 'Certification'
	,@pSSISProject				= 'Certification'
	,@pSSISPackage				= 'Parent Servicer Onboarding.dtsx'
	,@pDataFactoryName			= 'N/A'
	,@pDataFactoryPipeline		= 'N/A'
	,@pSrcDeltaAttributes		= 'UNK'
	,@pSrcFilePath				= 'UNK'
	,@pSrcFileRegEx				= 'Skills_RosterFile_[1..9]{8}\.txt$' 
	,@pStandardFileRegEx		= 'LDRF_((19|20)\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01]))_([0-1]?\d|2[0-3]):([0-5]?\d):([0-5]?\d).CSV' -- 'ENGAGEHIST_YYYYMMDD_HHMMSS.JSON'
	,@pStandardFileFormatCode	= 'TXT' -- ???
	,@pProcessingMethodCode		= 'SSIS'
	,@pTransferMethodCode		= 'DLT'
	,@pStorageMethodCode		= 'SS'
	,@pIntervalCode				= 'WK'
	,@pIntervalLength			= 1
	,@pRetryIntervalCode		= 'HR'
	,@pRetryIntervalLength		= 1
	,@pRetryMax					= 0
	,@pPublicationEntity		= 'UNK'
	,@pDestTableName			= 'UNK'
	,@pSLATime					= '11:00'
	,@pSLAEndTimeInMinutes		=  120
	,@pNextExecutionDtm			= NULL -- '1900-01-01 00:00:00.000'
	,@pIsActive					= 1  -- Why insert it if it isn't active...
	,@pIsDataHub				= 1  -- Maybe it isn't data hub, shouldn't be...
	,@pBound					= 'Out'	 --Inbound or Outbound
	,@pCreatedBy				= @CurrentUser
	,@pETLExecutionId			= -1
	,@pPathId					= -1
	,@pVerbose					= 0
	
end

-------------------------------------------------------------------------------
-- Contact Mapping
-------------------------------------------------------------------------------
print 'Start Insert Contact ''Disbursement NACHA ACH File (DNACHAF)''.'
if not exists (select top 1 1 from ctl.Publication pr 
				join ctl.MapContactToPublication mp 
				on pr.PublicationId = mp.PublicationId where  pr.PublicationCode = 'DNACHAF')
begin 
	exec [ctl].[usp_InsertMapContactToPublication] 	
			 @pPublicationCode			= 'DNACHAF'
			,@pContactName				= 'Ascent Data Engineering'
			,@pContactToPublicationDesc = ''
end

-------------------------------------------------------------------------------
-- Subscription
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Subscription -- Engagement History to ODS RedShift
-------------------------------------------------------------------------------
print 'Start Insert Subscription ''Loan Origination System Certification System File (LOSCSF)''.'
if not exists (select top 1 1 from ctl.Subscription where SubscriptionCode	= 'LVPRSN-ODSRS-ENGAGEHIST')
begin

exec ctl.usp_InsertNewSubscription 
	 @pPublicationCode			= 'ENGAGEHIST'
	,@pSubscriberCode			= 'ADWMSSQL'
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


