CREATE PROCEDURE [ctl].[usp_InsertNewSubscriber] (    
     @pSubscriberCode			varchar(20)
    ,@pContactName				varchar(100)
    ,@pSubscriberName			varchar(250)
	,@pSubscriberDesc			varchar(1000)
    ,@pInterfaceCode			varchar(20)
	,@pSiteURL					VARCHAR(256)	= NULL  
	,@pSiteUser					VARCHAR(256)	= NULL 
	,@pSitePassword				VARCHAR(256)    = NULL           
	,@pSiteHostKeyFingerprint	VARCHAR(256)	= NULL                         --FTPkey in dimvendor    
	,@pSitePort					VARCHAR(10)		= NULL
	,@pSiteProtocol				VARCHAR(100)	= NULL
	,@pPrivateKeyPassPhrase		VARCHAR(256)	= NULL 
	,@pPrivateKeyFile			VARCHAR(256)	= NULL 
	,@pNotificationHostName		varchar(255)
	,@pNotificationInstance		varchar(255)
	,@pNotificationDatabase		varchar(255)
	,@pNotificationSchema		varchar(255)
	,@pNotificationProcedure	varchar(255)
    ,@pCreatedBy				varchar(30)
	,@pETLExecutionId			int				= -1
	,@pPathId					int				= -1
	,@pVerbose					bit				= 0)

AS 
/*****************************************************************************
File:		[usp_InsertNewSubscriber].sql
Name:		[usp_InsertNewSubscriber]
Purpose:	

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

Parameters:    

Called by:	
Calls:          

Errors:		

Author:		ffortunato
Date:		20090220

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20170425	ffortunato		changing flowerbox. formatting variables. using
							standard logging.
20170711	ffortunato		formatting  updateing parms passed.
20180828	ffortunato		SubscriberType --> InterfaceCode
20190305	ochowkwale		Export to subscriber configurations
20201123	ffortunato		PassPhrase
20211007	ffortunato		Clearning up parms 
							+ Desc
							o Contact
							o Name varchar(250)
******************************************************************************/

-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------
SET NOCOUNT ON    SET QUOTED_IDENTIFIER OFF     SET ANSI_NULLS OFF

declare	 @Rows					int
        ,@ErrNum				int
		,@ErrMsg				nvarchar(2048)
		,@FailedProcedure		varchar(1000)
		,@ParametersPassedChar	varchar(1000)
		,@CRLF					varchar(10)		= char(13) + char(10)
		,@ContactId				int				= -1
		,@CreatedDate			datetime		= getdate()
		,@DbName				varchar(50)		= DB_NAME()
		,@SchemaName			nvarchar(256)	= 'ctl'
		,@PassphraseTableName	nvarchar(256)	= 'Subscriber'
		,@ProcessType			varchar(10)		= 'Proc'
		,@StepName				varchar(256)	= 'Start'
		,@StepOperation			varchar(50)		= 'N/A' 
		,@MessageType			varchar(20)		= 'Info' -- ErrCust, ErrSQL, Info, Warn
		,@StepDesc				nvarchar(2048)	= 'Procedure started' 
		,@StepStatus			varchar(10)		= 'Success'
		,@StepNumber			varchar(10)		= 0
		,@Duration				varchar(10)		= 0
		,@JSONSnippet			nvarchar(max)	= NULL
		,@SLATimeChar			varchar(20)		= 'N/A'
		,@SLATime				datetime
		,@Passphrase			varchar(100)	= ''
		,@PreviousDtm			datetime		= getdate()
		,@CurrentDtm			datetime		= getdate()
		,@ProcName				varchar(256)	= OBJECT_NAME(@@PROCID) 
		,@ParentStepLogId       int				= -1
		,@PrevStepLog			int				= -1
		,@ProcessStartDtm		datetime		= getdate()
		,@ServerName			varchar(256)	= @@SERVERNAME
		,@CurrentUser			varchar(256)	= CURRENT_USER

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------
select	 @ErrNum				= -1
		,@ErrMsg				= 'N/A'
		,@FailedProcedure		= 'Stored Procedure : ' + OBJECT_NAME(@@PROCID) 
								+ ' failed.' + @CRLF
		,@ParametersPassedChar	=       
      '***** Parameters Passed to exec <schema>.usp_InsertNewSubscriber' + @CRLF +
      '     @pSubscriberCode = ''' + isnull(@pSubscriberCode ,'NULL') + '''' + @CRLF + 
      '    ,@pContactName = ''' + isnull(@pContactName ,'NULL') + '''' + @CRLF + 
      '    ,@pSubscriberName = ''' + isnull(@pSubscriberName ,'NULL') + '''' + @CRLF + 
      '    ,@pInterfaceCode = ''' + isnull(@pInterfaceCode ,'NULL') + '''' + @CRLF + 
	  '	   ,@pSiteURL = ''' + isnull(@pSiteURL ,'NULL') + '''' + @CRLF + 
	  '	   ,@pSiteUser = ''' + isnull(@pSiteUser ,'NULL') + '''' + @CRLF + 
	  '	   ,@pSitePassword = ''' + isnull(@pSitePassword ,'NULL') + '''' + @CRLF + 
	  '	   ,@pSiteHostKeyFingerprint = ''' + isnull(@pSiteHostKeyFingerprint ,'NULL') + '''' + @CRLF + 
	  '	   ,@pSitePort = ''' + isnull(@pSitePort ,'NULL') + '''' + @CRLF + 
	  '	   ,@pSiteProtocol = ''' + isnull(@pSiteProtocol ,'NULL') + '''' + @CRLF + 
	  '	   ,@pPrivateKeyPassPhrase = ''' + isnull(@pPrivateKeyPassPhrase ,'NULL') + '''' + @CRLF + 
	  '	   ,@pPrivateKeyFile = ''' + isnull(@pPrivateKeyFile ,'NULL') + '''' + @CRLF + 
      '    ,@pNotificationHostName = ''' + isnull(@pNotificationHostName ,'NULL') + '''' + @CRLF + 
      '    ,@pNotificationInstance = ''' + isnull(@pNotificationInstance ,'NULL') + '''' + @CRLF + 
      '    ,@pNotificationDatabase = ''' + isnull(@pNotificationDatabase ,'NULL') + '''' + @CRLF + 
      '    ,@pNotificationSchema = ''' + isnull(@pNotificationSchema ,'NULL') + '''' + @CRLF + 
      '    ,@pNotificationProcedure = ''' + isnull(@pNotificationProcedure ,'NULL') + '''' + @CRLF + 
      '    ,@pCreatedBy = ''' + isnull(@pCreatedBy ,'NULL') + '''' + @CRLF + 
      '    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL') + @CRLF + 
      '***** End of Parameters' + @CRLF 

----------------------------------------------------------------------------------
--  Main
----------------------------------------------------------------------------------
begin try

	select	@ContactId				= ContactId
	from	ctl.Contact
	where	[ContactName]					= @pContactName


	SELECT	@Passphrase =
	(
		SELECT	 Passphrase
		FROM	 ctl.[Passphrase]
		WHERE	 DatabaseName	= @DbName
		AND		 SchemaName		= @SchemaName
		AND		 TableName		= @PassphraseTableName
	)


-------------------------------------------------------------------------------
--  Step comment. Custom Error Check
-------------------------------------------------------------------------------

	select	 @StepName			= 'Passphrase and Contact'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'validate'
			,@StepDesc			= 'Determine if we got good values for contact and passphrase'


	if (@Passphrase is null or @Passphrase = '' or @ContactId is null or @ContactId = -1)
	begin
		select   @ErrNum		= 50001
				,@MessageType	= 'ErrCust'
				,@ErrMsg		= 'CustomErrorMessage'
				,@JSONSnippet	= '{' + @CRLF +
							'		"Variables": {' + @CRLF +
							  '			"Contact":"' + cast(@ContactId as varchar(100)) + '",' + @CRLF +
							  '			"Passphrase":"' +@Passphrase + '"' + @CRLF +
							'		}'+ @CRLF +'	 }' + @CRLF

		; throw @ErrNum, @ErrMsg, 1  -- This is thrown to the catch block below.
	end

	else
		begin
			-- Log successful validation.
			select	 @PreviousDtm		= @CurrentDtm
			select	 @CurrentDtm		= getdate()

			exec [audit].usp_InsertStepLog
				 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
				,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
				,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
				,@pVerbose
		end


-------------------------------------------------------------------------------
--  Step comment
-------------------------------------------------------------------------------
	select	 @StepName			= 'Insert Subscriber'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Insert'
			,@StepDesc			= 'Adding a new Subscriber record.'

	insert into ctl.Subscriber (
			 ContactId
			,SubscriberCode
			,SubscriberName
			,SubscriberDesc
			,InterfaceCode
			,SiteURL
			,SiteUser
			,SitePassword
			,SiteHostKeyFingerprint
			,SitePort
			,SiteProtocol
			,PrivateKeyPassPhrase
			,PrivateKeyFile
			,NotificationHostName
			,NotificationInstance							
			,NotificationDatabase		
			,NotificationSchema				
			,NotificationProcedure
			,CreatedDtm
			,CreatedBy
			,ModifiedDtm
			,ModifiedBy
	) values (
			 @ContactId
			,@pSubscriberCode       
			,@pSubscriberName       
			,@pSubscriberDesc
			,@pInterfaceCode
			,@pSiteURL
			,@pSiteUser
			,ENCRYPTBYPASSPHRASE(@Passphrase, @pSitePassword)
			,ENCRYPTBYPASSPHRASE(@Passphrase, @pSiteHostKeyFingerprint)
			,@pSitePort
			,@pSiteProtocol
			,ENCRYPTBYPASSPHRASE(@Passphrase, @pPrivateKeyPassPhrase)
			,ENCRYPTBYPASSPHRASE(@Passphrase, @pPrivateKeyFile)
			,@pNotificationHostName				
			,@pNotificationInstance					
			,@pNotificationDatabase		
			,@pNotificationSchema				
			,@pNotificationProcedure
			,@CreatedDate
			,@pCreatedBy    
			,@CreatedDate
			,@pCreatedBy    
	)

	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			--,@JSONSnippet		= '{"":"' + @myvar + '"}' -- Only if needed.

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	select	 @JSONSnippet		= NULL


end try-- Main

begin catch

	select 	 @PreviousDtm		= @CurrentDtm
			,@ErrNum			= @@ERROR
			,@ErrMsg			= ERROR_MESSAGE()
			,@Rows				= 0

	select	 @StepStatus		= 'Failure'
			,@CurrentDtm		= getdate()

	if		 @MessageType		<> 'ErrCust'
		select   @MessageType	= 'ErrSQL'

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	if 	@ErrNum < 50000	
		select	 @ErrNum	= @ErrNum + 100000000 -- Need to increase number to throw message.

	;throw	 @ErrNum, @ErrMsg, 1

end catch


-------------------------------------------------------------------------------
--  Procedure End
-------------------------------------------------------------------------------

select 	 @PreviousDtm			= @CurrentDtm
select	 @CurrentDtm			= getdate()
		,@StepNumber			= @StepNumber + 1
		,@StepName				= 'End'
		,@StepDesc				= 'Procedure completed'
		,@Rows					= 0
		,@StepOperation			= 'N/A'

-- Passing @ProcessStartDtm so the total duration for the procedure is added.
-- @ProcessStartDtm (if you want total duration) 
-- @PreviousDtm (if you want 0)
exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm	,@ProcessStartDtm	,@StepNumber	,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
		,@pVerbose

