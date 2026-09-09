/* SQLINES DEMO *** ***********************************************************
File:           tst_DataHub.sql
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
20210325	ffortunato		FeedFormat --> FileFormatCode
20211008	ffortunato		Cleanup based on code changes.
20220207	ffortunato		o Publication Names & Publisher Names.
20230615	ffortunato		+ triggertypecode on publication
******************************************************************************/

--  SQLINES DEMO *** -----------------------------------------------------------
-- De... SQLINES DEMO ***
--  SQLINES DEMO *** -----------------------------------------------------------
-- SQLINES DEMO *** rmin how much output you want to see from the 
-- te... SQLINES DEMO ***

-- Cl... SQLINES DEMO ***


delete from ctl.`distribution`			where IssueId			in (select IssueId from ctl.Issue where  publicationid in (select publicationid from ctl.publication where publicationcode in ('PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR')));
delete from ctl.Issue					where publicationid		in (select publicationid from ctl.publication where publicationcode in ('PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR'));
delete from ctl.MapContactToPublication	where publicationid		in (select publicationid from ctl.publication where publicationcode in ('PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR'));
delete from ctl.MapContactToSubscription	where SubscriptionId	in (select SubscriptionId from ctl.Subscription where Subscriptioncode in ('PUBR02-SUBR01-PUBN03-COUR','PUBR01-SUBR01-PUBN01-ACCT','PUBR01-SUBR01-PUBN02-ASSG','PUBR01-SUBR02-PUBN02-ASSG','PUBR02-SUBR02-PUBN03-COUR'));
delete from ctl.Subscription				where subscriptioncode	in ('PUBR02-SUBR01-PUBN03-COUR','PUBR01-SUBR01-PUBN01-ACCT','PUBR01-SUBR01-PUBN02-ASSG','PUBR01-SUBR02-PUBN02-ASSG','PUBR02-SUBR02-PUBN03-COUR');
delete from ctl.Publication				where PublicationCode	in ('PUBN01-ACCT','PUBN02-ASSG','PUBN03-COUR');
delete from ctl.Subscriber				where subscribercode	in ('SUBR01' , 'SUBR02');
delete from ctl.Publisher				where publishercode		in ('PUBR01','PUBR02');
delete from ctl.Contact					where `ContactName`		in ('PUB_Contact_Test01','PUB_Contact_Test02','SUB_Contact_Test01','SUB_Contact_Test02');


--  SQLINES DEMO *** -----------------------------------------------------------
-- SQLINES DEMO *** nitialization
--  SQLINES DEMO *** -----------------------------------------------------------

declare v_Verbose       int			default 0
       ; declare v_PassVerbose   tinyint			default 1
	   ; declare v_Start         datetime(3)		default now(3)
	   ; declare v_End		   datetime(3)		default now(3)
	   ; declare v_IssueId	   int			default -1
	   ; declare v_CurrentUser   varchar(250)	default CURRENT_USER

	   
/* SQLINES DEMO *** eter for local testing.
0 - Nothing
1 - Everything
2 - All Print Statments
3 - All Select Statments

@PassVerbose -- Parameter for testing procedures.
0 - False
1 - True
*/

-- SQLINES DEMO *** tacts.
if not exists (select 1 from ctl.Contact where ContactName = 'BI-Development'
limit 1) then

CALL `ctl`.usp_InsertNewContact(
		p_CompanyName				 = 'Unknown' 
		,p_pContactName				= 'BI-Development'
		,p_pTier						= '1'
		,p_pEmail					= 'PUB_Contact_Test01@myaddress.com'
		,p_pPhone					= '877.300.6069'
        ,p_pSupportURL				 = 'Unknown' 
		,p_pAddress01				= '10180 Telesis Ct'
		,p_pAddress02				= '#400'
		,p_pCity						= 'San Diego'
		,p_pState					= 'CA'
		,p_pZipCode					= '92121'
        ,p_pETLExecutionId			= -1 
		,p_pPathId					 = -1 
		,p_pVerbose					 = 0 );
        

        
end if;

if not exists (select 1 from ctl.Contact where Contactname = 'PUB_Contact_Test01'
limit 1) then
CALL `ctl`.usp_InsertNewContact(p_pContactName						= 'PUB_Contact_Test01'
		,p_pTier						= '1'
		,p_pEmail					= 'PUB_Contact_Test01@myaddress.com'
		,p_pPhone					= '877.300.6069'
		,p_pAddress01				= '10180 Telesis Ct'
		,p_pAddress02				= '#400'
		,p_pCity						= 'San Diego'
		,p_pState					= 'CA'
		,p_pZipCode					= '92121');
end if;

if not exists (select 1 from ctl.Contact where ContactName = 'PUB_Contact_Test02'
limit 1) then
CALL `ctl`.usp_InsertNewContact(p_pContactName						= 'PUB_Contact_Test02'
		,p_pTier						= '1'
		,p_pEmail					= 'PUB_Contact_Test02@myaddress.com');
end if;

if not exists (select 1 from ctl.Contact where ContactName = 'SUB_Contact_Test01'
limit 1) then
CALL `ctl`.usp_InsertNewContact(p_pContactName						= 'SUB_Contact_Test01'
		,p_pTier						= '1'
		,p_pEmail					= 'SUB_Contact_Test01@myaddress.com');
end if;

if not exists (select 1 from ctl.Contact where ContactName = 'SUB_Contact_Test02'
limit 1) then
CALL `ctl`.usp_InsertNewContact(p_pContactName						= 'SUB_Contact_Test02'
		,p_pTier						= '1'
		,p_pEmail					= 'SUB_Contact_Test02@myaddress.com');
end if;

-- SQLINES DEMO *** .refstatus


/* SQLINES DEMO *** ***********************************************************
Test Case: Create New Publisher
******************************************************************************/
if not exists (select 1 from ctl.Publisher where PublisherCode	= 'PUBR01'
limit 1)
then

call `ctl`.usp_InsertNewPublisher(p_pPublisherCode			= 'PUBR01'
		,p_pContactName				= 'BI-Development'
		,p_pPublisherName			= '01 Test Publisher'
		,p_pPublisherDesc			= 'First Test Publisher'
		,p_pInterfaceCode			= 'TBL'
		,p_pCreatedBy				= 'ffortunato'  -- SQLINES DEMO *** CurrentUser
		,p_pSiteURL					= NULL
		,p_pSiteUser					= NULL
		,p_pSitePassword				= NULL
		,p_pSiteHostKeyFingerprint	= NULL
		,p_pSitePort					= NULL
		,p_pSiteProtocol				= NULL
		,p_pPrivateKeyPassPhrase		= NULL
		,p_pPrivateKeyFile			= NULL
		,p_pETLExecutionId			= 0
		,p_pPathId					= 0
		,p_pVerbose					= v_Verbose);

end if;

if not exists (select 1 from ctl.Publisher where PublisherCode	= 'PUBR02'
limit 1)
then

call `ctl`.usp_InsertNewPublisher(p_pPublisherCode			= 'PUBR02'
		,p_pContactName				= 'BI-Development'
		,p_pPublisherName			= '02 Test Publisher'
		,p_pPublisherDesc			= 'Second Test Publisher'
		,p_pInterfaceCode			= 'TBL'
		,p_pCreatedBy				= 'ffortunato'  -- SQLINES DEMO *** CurrentUser
		,p_pSiteURL					= NULL
		,p_pSiteUser					= NULL
		,p_pSitePassword				= NULL
		,p_pSiteHostKeyFingerprint	= NULL
		,p_pSitePort					= NULL
		,p_pSiteProtocol				= NULL
		,p_pPrivateKeyPassPhrase		= NULL
		,p_pPrivateKeyFile			= NULL
		,p_pETLExecutionId			= 0
		,p_pPathId					= 0
		,p_pVerbose					= v_Verbose);

end if;

if v_Verbose in (1,3) then
	select 'Initial State Publisher' AS TestingStep, * 
	from ctl.Publisher
	WHERE PublisherCode IN ('PUBR01','PUBR02');
end if;
/* SQLINES DEMO *** ***********************************************************
Test Case: Create New Subscriber
******************************************************************************/

if not exists (select 1 from ctl.Subscriber where SubscriberCode	= 'SUBR01'
limit 1)
then

call `ctl`.`usp_InsertNewSubscriber`(p_pSubscriberCode				= 'SUBR01'
    ,p_pContactName					= 'BI-Development'
    ,p_pSubscriberName				= '01 Test Subscriber'
	,p_pSubscriberDesc				= '01 Test Subscriber'
    ,p_pInterfaceCode				= 'TBL'
	,p_pSiteURL						= NULL  
	,p_pSiteUser						= NULL 
	,p_pSitePassword					= NULL           
	,p_pSiteHostKeyFingerprint		= NULL                             
	,p_pSitePort						= NULL
	,p_pSiteProtocol					= NULL
	,p_pPrivateKeyPassPhrase			= NULL 
	,p_pPrivateKeyFile				= NULL 
	,p_pNotificationHostName			= 'SBXSRV01'
	,p_pNotificationInstance			= 'SBXSRV01'
	,p_pNotificationDatabase			= 'SBXSRV01'
	,p_pNotificationSchema			= 'schema'
	,p_pNotificationProcedure		= 'usp_NA'
    ,p_pCreatedBy					= 'ffortunato'  -- @C... SQLINES DEMO ***
	,p_pVerbose						= v_Verbose);

end if;

if not exists (select 1 from ctl.Subscriber where SubscriberCode	= 'SUBR02'
limit 1)
then

call `ctl`.`usp_InsertNewSubscriber`(p_pSubscriberCode				= 'SUBR02'
    ,p_pContactName					= 'BI-Development'
    ,p_pSubscriberName				= '02 Test Subscriber'
	,p_pSubscriberDesc				= '01 Test Subscriber'
    ,p_pInterfaceCode				= 'TBL'
	,p_pSiteURL						= NULL  
	,p_pSiteUser						= NULL 
	,p_pSitePassword					= NULL           
	,p_pSiteHostKeyFingerprint		= NULL                             
	,p_pSitePort						= NULL
	,p_pSiteProtocol					= NULL
	,p_pPrivateKeyPassPhrase			= NULL 
	,p_pPrivateKeyFile				= NULL 
	,p_pNotificationHostName			= 'SBXSRV02'
	,p_pNotificationInstance			= 'SBXSRV02'
	,p_pNotificationDatabase			= 'SBXSRV02'
	,p_pNotificationSchema			= 'schema'
	,p_pNotificationProcedure		= 'usp_NA'
    ,p_pCreatedBy					= 'ffortunato'  -- @C... SQLINES DEMO ***
	,p_pVerbose						= v_Verbose);

end if;

if v_Verbose in (1,3) then
	select 'Initial State Subscriber' AS TestingStep, * 
	from ctl.Subscriber;
end if;

/* SQLINES DEMO *** ***********************************************************
Test Case: Create New Publication
******************************************************************************/

if not exists (select 1 from ctl.Publication where PublicationCode	= 'PUBN01-ACCT'
limit 1)
then

CALL `ctl`.`usp_InsertNewPublication`(p_pPublisherCode				= 'PUBR01' -- va... SQLINES DEMO ***
	,p_pPublicationCode				= 'PUBN01-ACCT'-- va... SQLINES DEMO ***
	,p_pPublicationName				= 'Test Account Dim Feed' -- va... SQLINES DEMO ***
	,p_pSrcPublicationName			= 'PUBN01-ACCT'--  SQLINES DEMO *** 8}.csv$ -- varchar(255) 
	,p_pPublicationFilePath			= '' -- SQLINES DEMO ***  varchar(255) 
	,p_pPublicationArchivePath		= '' -- SQLINES DEMO ***  varchar(255)
	,p_pSrcFileFormatCode			= 'UNK' -- 'c... SQLINES DEMO ***
	,p_pStageJobName					= ''
	,p_pSSISProject					= 'PostingGroup'
	,p_pSSISFolder					= 'ETLFolder'
	,p_pSSISPackage					= 'TSTPUBN01-ACCT.dtsx'
	,p_pSrcFilePath					= '' -- SQLINES DEMO *** are'
	,p_pDataFactoryName				= 'N/A'
	,p_pDataFactoryPipeline			= 'N/A'
-- SQLINES DEMO *** 			= 'FILE' -- varchar(20) 
-- SQLINES DEMO *** 	= 'DLT' -- varchar(20) 
	,p_pIntervalCode					= 'DY' -- va... SQLINES DEMO ***
	,p_pIntervalLength				= 1 -- in... SQLINES DEMO ***
	,p_pRetryIntervalCode			= 'HR'	--	va... SQLINES DEMO ***
	,p_pRetryIntervalLength			= 1	--	in... SQLINES DEMO ***
	,p_pRetryMax						= 0	--	in... SQLINES DEMO ***
	,p_pPublicationEntity			= '' -- SQLINES DEMO *** 9]{8}_[1..9]{8}.csv$' -- varchar(255) 
	,p_pDestTableName				= '[control].[schema].[TBL-ACCT]' -- va... SQLINES DEMO ***
	,p_pSLATime						= '01:00'
	,p_pSLAEndTimeInMinutes			= NULL
	,p_pNextExecutionDtm				= '1900-01-01 00:00:00.000'
	,p_pTriggerTypeCode				= 'SCH'
	,p_pIsActive						= 1  
	,p_pIsDataHub					= 1
	,p_pBound						= 'In'
	,p_pCreatedBy					= 'ffortunato'  -- @C... SQLINES DEMO ***
	,p_pVerbose						= v_Verbose);

end if;

if not exists (select 1 from ctl.Publication where PublicationCode	= 'PUBN02-ASSG'
limit 1)
then


CALL `ctl`.`usp_InsertNewPublication`(p_pPublisherCode			= 'PUBR01' -- va... SQLINES DEMO ***
	,p_pPublicationCode			= 'PUBN02-ASSG'-- va... SQLINES DEMO ***
	,p_pPublicationName			= 'Test Assignment Dim Feed' -- va... SQLINES DEMO ***
	,p_pSrcPublicationName		= 'PUBN02-ASSG'--  SQLINES DEMO *** 8}.csv$' -- varchar(255) 
	,p_pPublicationFilePath		= '' -- SQLINES DEMO ***  varchar(255) 
	,p_pPublicationArchivePath	= '' -- SQLINES DEMO ***  varchar(255)
	,p_pSrcFileFormatCode		= 'UNK' -- 'c... SQLINES DEMO ***
	,p_pStageJobName				= ''
	,p_pSSISProject				= 'PostingGroup'
	,p_pSSISFolder				= 'ETLFolder'
	,p_pSSISPackage				= 'TSTPUBN02-ASSG.dtsx'
	,p_pSrcFilePath				= '' -- SQLINES DEMO *** are'
	,p_pDataFactoryName			= 'N/A'
	,p_pDataFactoryPipeline		= 'N/A'
-- SQLINES DEMO *** 		= 'FILE' -- varchar(20) 
-- SQLINES DEMO *** = 'DLT' -- varchar(20) 
	,p_pIntervalCode				= 'DY' -- va... SQLINES DEMO ***
	,p_pIntervalLength			= 1 -- in... SQLINES DEMO ***
	,p_pRetryIntervalCode		= 'HR'	--	va... SQLINES DEMO ***
	,p_pRetryIntervalLength		= 1	--	in... SQLINES DEMO ***
	,p_pRetryMax					= 0	--	in... SQLINES DEMO ***
	,p_pPublicationEntity		= '' -- SQLINES DEMO *** 9]{8}_[1..9]{8}.csv$' -- varchar(255) 
	,p_pDestTableName			= '[control].[schema].[TBL-ASSG]' -- va... SQLINES DEMO ***
	,p_pSLATime					= '01:00'
	,p_pSLAEndTimeInMinutes				= NULL
	,p_pNextExecutionDtm			= '1900-01-01 00:00:00.000'
	,p_pIsActive					= 1  
	,p_pIsDataHub				= 1
	,p_pBound					= 'In'
	,p_pCreatedBy				= 'ffortunato'  -- SQLINES DEMO *** archar(50)	
	,p_pVerbose					= v_Verbose);
end if;

if not exists (select 1 from ctl.Publication where PublicationCode	= 'PUBN03-COUR'
limit 1)
then

CALL `ctl`.`usp_InsertNewPublication`(p_pPublisherCode			= 'PUBR02' -- va... SQLINES DEMO ***
	,p_pPublicationCode			= 'PUBN03-COUR'-- va... SQLINES DEMO ***
	,p_pPublicationName			= 'Test Course Feed' -- va... SQLINES DEMO ***
	,p_pSrcPublicationName		= 'PUBN03-COUR'--  SQLINES DEMO *** 8}.csv$' -- varchar(255) 
	,p_pPublicationFilePath		= '' -- SQLINES DEMO ***  varchar(255) 
	,p_pPublicationArchivePath	= '' -- SQLINES DEMO ***  varchar(255)
	,p_pSrcFileFormatCode		= 'UNK' -- 'c... SQLINES DEMO ***
	,p_pStageJobName				= ''
	,p_pSSISProject				= 'PostingGroup'
	,p_pSSISFolder				= 'ETLFolder'
	,p_pSSISPackage				= 'TSTPUBN03-COUR.dtsx'
	,p_pSrcFilePath				= '' -- SQLINES DEMO *** are'
	,p_pDataFactoryName			= 'N/A'
	,p_pDataFactoryPipeline		= 'N/A'
-- SQLINES DEMO *** 		= 'FILE' -- varchar(20) 
-- SQLINES DEMO *** = 'DLT' -- varchar(20) 
	,p_pIntervalCode				= 'DY' -- va... SQLINES DEMO ***
	,p_pIntervalLength			= 1 -- in... SQLINES DEMO ***
	,p_pRetryIntervalCode		= 'HR'	--	va... SQLINES DEMO ***
	,p_pRetryIntervalLength		= 1	--	in... SQLINES DEMO ***
	,p_pRetryMax					= 0	--	in... SQLINES DEMO ***
	,p_pPublicationEntity		= '' -- SQLINES DEMO *** 9]{8}_[1..9]{8}.csv$' -- varchar(255) 
	,p_pDestTableName			= '[control].[schema].[TBL-COUR]' -- va... SQLINES DEMO ***
	,p_pSLATime					= '01:00'
	,p_pSLAEndTimeInMinutes				= NULL
	,p_pNextExecutionDtm			= '1900-01-01 00:00:00.000'
	,p_pIsActive					= 1  
	,p_pIsDataHub				= 1
	,p_pBound					= 'In'
	,p_pCreatedBy				= 'ffortunato'  -- SQLINES DEMO *** archar(50)	
	,p_pVerbose				= v_Verbose);
end if;

if v_Verbose in (1,3) then
	select 'Initial State Publication' AS TestingStep, * 
	from ctl.Publication;
end if;

/* SQLINES DEMO *** ***********************************************************
Test Case: Map Contacts to New Publication
******************************************************************************/
! echo 'Start Mpaaing Contacts.'

call `ctl`.`usp_InsertMapContactToPublication`(p_pPublicationCode			= 'PUBN01-ACCT'
		,p_pContactName				= 'PUB_Contact_Test01'
		,p_pContactToPublicationDesc = '')

call `ctl`.`usp_InsertMapContactToPublication`(p_pPublicationCode			= 'PUBN02-ASSG'
		,p_pContactName				= 'PUB_Contact_Test01'
		,p_pContactToPublicationDesc = '')

call `ctl`.`usp_InsertMapContactToPublication`(p_pPublicationCode			= 'PUBN03-COUR'
		,p_pContactName				= 'PUB_Contact_Test02'
		,p_pContactToPublicationDesc = '')

! echo 'Complete Mapping Contacts.'
/* SQLINES DEMO *** ***********************************************************
Test Case: Create New Subscription
******************************************************************************/

-- SQLINES DEMO *** tetime

-- SQLINES LICENSE FOR EVALUATION USE ONLY
SET  v_Start = NOW(3)

if not exists (select 1 from ctl.Subscription where SubscriptionName	= 'SUB01 Account Data'
limit 1)
then

call ctl.usp_InsertNewSubscription(p_pPublicationCode			= 'PUBN01-ACCT'
	,p_pSubscriberCode			= 'SUBR01'
	,p_pSubscriptionName			= 'SUB01 Account Data'
	,p_pSubscriptionDesc			= 'Sending the Account feed to subscriber 01'
	,p_pInterfaceCode			= 'TBL'
	,p_pIsActive					= 1
	,p_pSubscriptionFilePath     = 'N/A'
	,p_pSubscriptionArchivePath  = 'N/A'
	,p_pSrcFilePath				= 'N/A'
	,p_pDestTableName			= 'N/A'
	,p_pDestFileFormatCode		= 'N/A'
	,p_pCreatedBy				= 'ffortunato'  -- @C... SQLINES DEMO ***
	,p_pVerbose					= 0);

end if; 
if not exists (select 1 from ctl.Subscription where SubscriptionName	= 'SUB01 Assignment Data'
limit 1)
then


call ctl.usp_InsertNewSubscription(p_pPublicationCode			= 'PUBN02-ASSG'
	,p_pSubscriberCode			= 'SUBR01'
	,p_pSubscriptionName			= 'SUB01 Assignment Data'
	,p_pSubscriptionDesc			= 'Sending the Assignment feed to subscriber 01'
	,p_pInterfaceCode			= 'TBL'
	,p_pIsActive					= 1
	,p_pSubscriptionFilePath     = 'N/A'
	,p_pSubscriptionArchivePath  = 'N/A'
	,p_pSrcFilePath				= 'N/A'
	,p_pDestTableName			= 'N/A'
	,p_pDestFileFormatCode		= 'N/A'
	,p_pCreatedBy				= 'ffortunato'  -- @C... SQLINES DEMO ***
	,p_pVerbose					= v_Verbose);

end if; 
if not exists (select 1 from ctl.Subscription where SubscriptionName	= 'SUB02 Assignment Data'
limit 1)
then

call ctl.usp_InsertNewSubscription(p_pPublicationCode			= 'PUBN02-ASSG'
	,p_pSubscriberCode			= 'SUBR02'
	,p_pSubscriptionName			= 'SUB02 Assignment Data'
	,p_pSubscriptionDesc			= 'Sending the Assignment feed to subscriber 02'
	,p_pInterfaceCode			= 'TBL'
	,p_pIsActive					= 1
	,p_pSubscriptionFilePath     = 'N/A'
	,p_pSubscriptionArchivePath  = 'N/A'
	,p_pSrcFilePath				= 'N/A'
	,p_pDestTableName			= 'N/A'
	,p_pDestFileFormatCode		= 'N/A'
	,p_pCreatedBy				= 'ffortunato'  -- @C... SQLINES DEMO ***
	,p_pVerbose					= v_Verbose);


end if; 
if not exists (select 1 from ctl.Subscription where SubscriptionName	= 'SUB02 Course Data'
limit 1)
then

call ctl.usp_InsertNewSubscription(p_pPublicationCode			= 'PUBN03-COUR'
	,p_pSubscriberCode			= 'SUBR01'
	,p_pSubscriptionName			= 'SUB01 Course Data'
	,p_pSubscriptionDesc			= 'Sending the Course feed to subscriber 02'
	,p_pInterfaceCode			= 'TBL'
	,p_pIsActive					= 1
	,p_pSubscriptionFilePath     = 'N/A'
	,p_pSubscriptionArchivePath  = 'N/A'
	,p_pSrcFilePath				= 'N/A'
	,p_pDestTableName			= 'N/A'
	,p_pDestFileFormatCode		= 'N/A'
	,p_pCreatedBy				= 'ffortunato'  -- @C... SQLINES DEMO ***
	,p_pVerbose					= 0);

end if;

if v_Verbose in (1,3) then
	select 'Initial State Subscription' AS TestingStep, * 
	from ctl.Subscription;
end if;

/* SQLINES DEMO *** ***********************************************************
Test Case: Map Contacts to New Subscription
******************************************************************************/

/* SQLINES DEMO *** s created.
PUBR01-SUBR01-PUBN01-ACCT
PUBR01-SUBR01-PUBN02-ASSG
PUBR01-SUBR02-PUBN02-ASSG
PUBR02-SUBR01-PUBN03-COUR
*/

call `ctl`.usp_InsertMapContactToSubscription(p_pSubscriptionCode			= 'PUBR01-SUBR01-PUBN01-ACCT'
		,p_pContactName				= 'SUB_Contact_Test01'
		,p_pContactToSubscriptionDesc = '')

call `ctl`.usp_InsertMapContactToSubscription(p_pSubscriptionCode			= 'PUBR01-SUBR01-PUBN02-ASSG'
		,p_pContactName				= 'SUB_Contact_Test01'
		,p_pContactToSubscriptionDesc = '')

call `ctl`.usp_InsertMapContactToSubscription(p_pSubscriptionCode			= 'PUBR01-SUBR02-PUBN02-ASSG'
		,p_pContactName				= 'SUB_Contact_Test02'
		,p_pContactToSubscriptionDesc = '')

call `ctl`.usp_InsertMapContactToSubscription(p_pSubscriptionCode			= 'PUBR02-SUBR01-PUBN03-COUR'
		,p_pContactName				= 'SUB_Contact_Test01'
		,p_pContactToSubscriptionDesc = '');




/* SQLINES DEMO *** ***********************************************************

Test Case: Create New Issues

This test case represents the day to tday running of the pub sub model. 
As files / data move between publisher and subscriber issue and distribution
records are created. When a publisher creates an instance of a publication
and issue record is recorded. The issue is then distributed to each subscriber.
When an issue recored is created a distribution is created automaticaly based
on the subscriptions to a specific publication.

******************************************************************************/
 

declare v_Verbose		int default 0
       ; declare v_PassVerbose	tinyint default 0
	   ; declare v_Start			datetime(3)
	   ; declare v_End			datetime(3)
	   ; declare v_IssueId		int
	   ; declare v_MyIssueId		int 
	  

-- SQLINES LICENSE FOR EVALUATION USE ONLY
SET v_Start = DATE_SUB(NOW(3), INTERVAL 360 MINUTE)
     , v_End = NOW(3)
	 , v_IssueId = -2
	 , v_MyIssueId = -1

if not exists (select 1 from ctl.Issue where IssueName	= 'PUBN01-ACCT_20070112_01.txt'
limit 1)
then

call ctl.`usp_InsertNewIssue`(p_pPublicationCode= 'PUBN01-ACCT'
	,p_pIssueName= 'PUBN01-ACCT_20070112_01.txt'
	,p_pStatusCode= 'IP'
	,p_pSrcDFIssueId= '0'
	,p_pSrcDFCreatedDate= v_Start -- '1/... SQLINES DEMO ***
	,p_pFirstRecordSeq= 1
	,p_pLastRecordSeq= 100
	,p_pFirstRecordChecksum= 'ABC'
	,p_pLastRecordChecksum= 'DEF'
	,p_pPeriodStartTime= v_Start
	,p_pPeriodEndTime= v_End
	,p_pRecordCount= 100
	,p_pETLExecutionId= 99
	,p_pCreateBy= 'ffortunato'  -- @C... SQLINES DEMO ***
	,p_pIssueId = v_MyIssueId
	,p_pVerbose					= v_Verbose);

end if; 

select CONCAT('Returned Issue Id: ' , cast(v_MyIssueId as char(200))) as ''

call ctl.`usp_InsertNewIssue`(p_pPublicationCode= 'PUBN02-ASSG'
	,p_pIssueName= 'PUBN02-ASSG_20070112_01.txt'
	,p_pStatusCode= 'IP'
	,p_pSrcDFIssueId= '0'
	,p_pSrcDFCreatedDate= v_Start -- '1/... SQLINES DEMO ***
	,p_pFirstRecordSeq= 1
	,p_pLastRecordSeq= 100
	,p_pFirstRecordChecksum= 'ABC'
	,p_pLastRecordChecksum= 'DEF'
	,p_pPeriodStartTime= v_Start
	,p_pPeriodEndTime= v_End
	,p_pRecordCount= 100
	,p_pETLExecutionId= 99
	,p_pCreateBy= 'ffortunato'  -- @C... SQLINES DEMO ***
	,p_pIssueId = v_MyIssueId
	,p_pVerbose					= v_Verbose)

select CONCAT('Returned Issue Id: ' , cast(v_MyIssueId as char(200))) as ''

call ctl.`usp_InsertNewIssue`(p_pPublicationCode= 'PUBN03-COUR'
	,p_pIssueName= 'PUBN03-COUR_20070112_01.txt'
	,p_pStatusCode= 'IP'
	,p_pSrcDFIssueId= '0'
	,p_pSrcDFCreatedDate= v_Start --  SQLINES DEMO *** S A PROBLEM WITH CURRENT CHANGES TO THE CODE
	,p_pFirstRecordSeq= 1
	,p_pLastRecordSeq= 100
	,p_pFirstRecordChecksum= 'ABC'
	,p_pLastRecordChecksum= 'DEF'
	,p_pPeriodStartTime= v_Start
	,p_pPeriodEndTime= v_End
	,p_pRecordCount= 100
	,p_pETLExecutionId= 99
	,p_pCreateBy= 'ffortunato'  -- @C... SQLINES DEMO ***
	,p_pIssueId = v_MyIssueId
	,p_pVerbose= 0)

select CONCAT('Returned Issue Id: ' , cast(v_MyIssueId as char(200))) as ''

-- SQLINES LICENSE FOR EVALUATION USE ONLY
SET v_Start = DATE_ADD(NOW(3), INTERVAL 374 MINUTE)
     , v_End = DATE_ADD(NOW(3), INTERVAL 374 MINUTE)

call ctl.`usp_InsertNewIssue`(p_pPublicationCode= 'PUBN01-ACCT'
	,p_pIssueName= 'PUBN01-ACCT_20070112_02.txt'
	,p_pStatusCode= 'IP'
	,p_pSrcDFIssueId= '0'
	,p_pSrcDFCreatedDate= v_Start -- '1... SQLINES DEMO ***
	,p_pFirstRecordSeq= 1
	,p_pLastRecordSeq= 100
	,p_pFirstRecordChecksum= 'ABC'
	,p_pLastRecordChecksum= 'DEF'
	,p_pPeriodStartTime= v_Start
	,p_pPeriodEndTime= v_End
	,p_pRecordCount= 100
	,p_pETLExecutionId= 99
	,p_pCreateBy= 'ffortunato'  -- @C... SQLINES DEMO ***
	,p_pIssueId = v_MyIssueId
	,p_pVerbose					= v_Verbose)

select CONCAT('Returned Issue Id: ' , cast(v_MyIssueId as char(200))) as ''

call ctl.`usp_InsertNewIssue`(p_pPublicationCode= 'PUBN02-ASSG'
	,p_pIssueName= 'PUBN02-ASSG_20070112_02.txt'
	,p_pStatusCode= 'IP'
	,p_pSrcDFIssueId= '0'
	,p_pSrcDFCreatedDate= v_Start -- '1/... SQLINES DEMO ***
	,p_pFirstRecordSeq= 1
	,p_pLastRecordSeq= 100
	,p_pFirstRecordChecksum= 'ABC'
	,p_pLastRecordChecksum= 'DEF'
	,p_pPeriodStartTime= v_Start
	,p_pPeriodEndTime= v_End
	,p_pRecordCount= 100
	,p_pETLExecutionId= 99
	,p_pCreateBy= 'ffortunato'  -- @C... SQLINES DEMO ***
	,p_pIssueId = v_MyIssueId
	,p_pVerbose= 0)

select CONCAT('Returned Issue Id: ' , cast(v_MyIssueId as char(200))) as ''

call ctl.`usp_InsertNewIssue`(p_pPublicationCode= 'PUBN03-COUR'
	,p_pIssueName= 'PUBN03-COUR_20070112_02.txt'
	,p_pStatusCode= 'IP'
	,p_pSrcDFIssueId= '0'
	,p_pSrcDFCreatedDate= v_Start -- '1/... SQLINES DEMO ***
	,p_pFirstRecordSeq= 1
	,p_pLastRecordSeq= 100
	,p_pFirstRecordChecksum= 'ABC'
	,p_pLastRecordChecksum= 'DEF'
	,p_pPeriodStartTime= v_Start
	,p_pPeriodEndTime= v_End
	,p_pRecordCount= 100
	,p_pETLExecutionId= 99
	,p_pCreateBy= 'ffortunato'  -- @C... SQLINES DEMO ***
	,p_pIssueId = v_MyIssueId
	,p_pVerbose					= v_Verbose)

	select CONCAT('Returned Issue Id: ' , cast(v_MyIssueId as char(200))) as ''


/* SQLINES DEMO *** ***********************************************************

Test Case: Update Issue Status - Staging

This test case represents the execution of staging packages.

******************************************************************************/

-- SQLINES DEMO *** .refstatus


-- SQLINES LICENSE FOR EVALUATION USE ONLY
select ifnull(IssueId,-1) into v_IssueId from ctl.Issue where IssueName = 'PUBN01-ACCT_20070112_01.txt'
select CONCAT('IssueId:   ' , cast(v_IssueId as char(100))) as '' 
! echo 'IssueName: PUBN01-ACCT_20070112_01.txt'

call `ctl`.usp_UpdateIssue(p_pIssueId				= v_IssueId
		,p_pStatusCode			= 'IS')


-- SQLINES LICENSE FOR EVALUATION USE ONLY
select ifnull(IssueId,-1) into v_IssueId from ctl.Issue where IssueName = 'PUBN02-ASSG_20070112_01.txt'
select CONCAT('IssueId:   ' , cast(v_IssueId as char(100))) as '' 
! echo 'IssueName: PUBN02-ASSG_20070112_01.txt'

call `ctl`.usp_UpdateIssue(p_pIssueId				= v_IssueId
		,p_pStatusCode			= 'IS')

-- SQLINES LICENSE FOR EVALUATION USE ONLY
select ifnull(IssueId,-1) into v_IssueId from ctl.Issue where IssueName = 'PUBN03-COUR_20070112_01.txt'
select CONCAT('IssueId:   ' , cast(v_IssueId as char(100))) as '' 
! echo 'IssueName: PUBN03-COUR_20070112_01.txt'


call `ctl`.usp_UpdateIssue(p_pIssueId				= v_IssueId
		,p_pStatusCode			= 'IS')


/* SQLINES DEMO *** ***********************************************************

Test Case: Update Issue Status - Complete

This test case represents the execution of staging packages.

******************************************************************************/

-- SQLINES DEMO *** .refstatus


-- SQLINES LICENSE FOR EVALUATION USE ONLY
select ifnull(IssueId,-1) into v_IssueId from ctl.Issue where IssueName = 'PUBN01-ACCT_20070112_01.txt'
select CONCAT('IssueId:   ' , cast(v_IssueId as char(100))) as '' 
! echo 'IssueName: PUBN01-ACCT_20070112_01.txt'

call `ctl`.usp_UpdateIssue(p_pIssueId				= v_IssueId
		,p_pStatusCode			= 'IL')


-- SQLINES LICENSE FOR EVALUATION USE ONLY
select ifnull(IssueId,-1) into v_IssueId from ctl.Issue where IssueName = 'PUBN02-ASSG_20070112_01.txt'
select CONCAT('IssueId:   ' , cast(v_IssueId as char(100))) as '' 
! echo 'IssueName: PUBN02-ASSG_20070112_01.txt'

call `ctl`.usp_UpdateIssue(p_pIssueId				= v_IssueId
		,p_pStatusCode			= 'IL')

-- SQLINES LICENSE FOR EVALUATION USE ONLY
select ifnull(IssueId,-1) into v_IssueId from ctl.Issue where IssueName = 'PUBN03-COUR_20070112_01.txt'
select CONCAT('IssueId:   ' , cast(v_IssueId as char(100))) as '' 
! echo 'IssueName: PUBN03-COUR_20070112_01.txt'


call `ctl`.usp_UpdateIssue(p_pIssueId				= v_IssueId
		,p_pStatusCode			= 'IL')


/* SQLINES DEMO *** ***********************************************************

Test Case: Update Issue Status- Failed

This test case represents the execution of staging packages.

*** Testing this failure condition will cause issues with posting group
*** processing tests.

******************************************************************************/

-- SQLINES DEMO *** .refstatus

-- SQLINES LICENSE FOR EVALUATION USE ONLY
select ifnull(IssueId,-1) into v_IssueId from ctl.Issue where IssueName = 'PUBN03-COUR_20070112_01.txt'
select CONCAT('IssueId:   ' , cast(v_IssueId as char(100))) as '' 
! echo 'IssueName: PUBN03-COUR_20070112_01.txt'
/* SQLINES DEMO *** dateIssue
		 @pIssueId				= @IssueId
		,@pStatusCode			= 'IF'
*/

if v_Verbose in (1,3) then
	select 'Initial State Issue' AS TestingStep, * 
	from ctl.Issue
	limit 100;

	select 'Initial State Distribution' AS TestingStep, * 
	from `ctl`.`vw_DistributionStatus`
	limit 100;

	select * from ctl.RefStatus where StatusType = 'Distribution';

end if;

	
	! echo 'Dunzo'


	
