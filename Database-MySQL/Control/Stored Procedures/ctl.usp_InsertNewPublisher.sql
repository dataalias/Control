CREATE PROCEDURE [ctl].[usp_InsertNewPublisher] (
		 @pPublisherCode			VARCHAR(10)
		,@pContactName				VARCHAR(30)
		,@pPublisherName			VARCHAR(50)
		,@pPublisherDesc			VARCHAR(1000)	= 'Unknown'
		,@pInterfaceCode			VARCHAR(20)
		,@pCreatedBy				VARCHAR(50)		= 'Unknown'
		,@pSiteURL					VARCHAR(256)	= NULL  
		,@pSiteUser					VARCHAR(256)	= NULL 
		,@pSitePassword				VARCHAR(256)    = NULL           
		,@pSiteHostKeyFingerprint	VARCHAR(256)	= NULL                         --FTPkey in dimvendor    
		,@pSitePort					VARCHAR(10)		= NULL
		,@pSiteProtocol				VARCHAR(100)	= NULL
		,@pPrivateKeyPassPhrase		VARCHAR(256)	= NULL 
		,@pPrivateKeyFile			VARCHAR(256)	= NULL 
		,@pETLExecutionId			INT				= -1
		,@pPathId					INT				= -1
		,@pVerbose					BIT				= 0)
AS
/*****************************************************************************
File:		usp_InsertNewPublisher.sql
Name:		usp_InsertNewPublisher
Purpose:	


EXEC [ctl].[usp_InsertNewPublisher] 
		 @pPublisherCode		= 'WzzD'
		,@pContactName			= 'BI-Development'
		,@pPublisherName		= 'Work Day sftp site'
		,@pPublisherDesc		= 'An even better description.'
		,@pInterfaceCode		= 'SFTP'
		,@pCreatedBy			= 'ffortunato'
		,@pSiteURL				= '@SiteURL'
		,@pSiteUser				= '@SiteUser'
		,@pSitePassword			= '@SitePassword'
		,@pSiteHostKeyFingerprint	= '@SiteKey'
		,@pSitePort				= '22'
		,@pSiteProtocol			= 'SFTP'
		,@pPrivateKeyPassPhrase = 'lala'
		,@pPrivateKeyFile		= 'c:\tmp\key.ppk'
		,@pETLExecutionId		= 0
		,@pPathId				= 0
		,@pVerbose				= 0

Parameters:    

Called by:	
Calls:          

Errors:		

Author:	ffortunato	
Date:		

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
1/11/2018	hbangad			1. Insert New fields- SiteUrl,SitePassword
								,SiteKey,SitePort,SiteProtocol.
							2. Add issue and step logging, error handling.
							3. Add PassPhrase for publisher.
20180222	ffortunato		Some formatting.
20180627	ffortunato		Whole new set of ftp values are needed.
								@pSiteHostKeyFingerprint <rename>
								@pSiteProtocol			
								@pPrivateKeyPassPhrase

20180827	ffortunato		PublisherType --> InterfaceCode
							naming parameters better.

20201124	ffortunato		Passphrase
******************************************************************************/

-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------

DECLARE  @Rows					int					= 0
		,@ErrNum				int					= -1
		,@ErrMsg				nvarchar(max)		= 'N/A'
		,@ParametersPassedChar	varchar(1000)		= 'N/A'
		,@CRLF					varchar(10)			= char(13) + char(10)
		,@ProcName				varchar(256)		= OBJECT_NAME(@@PROCID) 
		,@ParentStepLogId		int					= -1
		,@PrevStepLog			int					= -2
		,@ProcessStartDtm		datetime			= getdate()
		,@CurrentDtm			datetime			= getdate()
		,@PreviousDtm			datetime			= getdate()
		,@DbName				varchar(50)			= DB_NAME()
		,@CurrentUser			varchar(50)			= CURRENT_USER
		,@SchemaName			nvarchar(256)		= 'ctl'
		,@PassphraseTableName	nvarchar(256)		= 'Publisher'
		,@Passphrase			varchar(100)		= ''
		,@ProcessType			varchar(10)			= 'Proc'
		,@StepName				varchar(256)		= 'Start'
		,@StepOperation			varchar(50)			= 'N/A' 
		,@MessageType			varchar(20)			= 'Info' -- ErrCust, ErrSQL, Info, Warn
		,@StepDesc				nvarchar(2048)		= 'Procedure started' 
		,@StepStatus			varchar(10)			= 'Success'
		,@StepNumber			varchar(10)			= 0
		,@Duration				varchar(10)			= 0
		,@JSONSnippet			nvarchar(max)		= NULL
		,@ContactId				int					= -1
		,@CreateDate			datetime			= getdate()

exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

SELECT	 @ParametersPassedChar	= 
			'EXEC BPI_DW_Stage.ctl.usp_InsertNewPublisher' + @CRLF +
			'    ,@p_PUBLISHER_CODE		= ' + isnull(cast(@pPublisherCode as varchar(100)),'NULL') + @CRLF +
			'    ,@p_CONTACT_NAME		= ' + isnull(cast(@pContactName as varchar(100)),'NULL') + @CRLF +
			'    ,@pPublisherName		= ' + isnull(cast(@pPublisherName as varchar(100)),'NULL') + @CRLF +
			'    ,@pPublisherDesc		= ' + isnull(cast(@pPublisherDesc as varchar(100)),'NULL') + @CRLF +
			'    ,@pInterfaceCode 		= ' + isnull(cast(@pInterfaceCode  as varchar(100)),'NULL') + @CRLF +
			'    ,@p_CREATED_BY		    = ' + isnull(cast(@pCreatedBy as varchar(100)),'NULL') + @CRLF +
			'    ,@pSiteURL			    = ' + isnull(cast(@pSiteURL as varchar(100)),'NULL') + @CRLF +
			'    ,@pSiteUser		    = ' + isnull(cast(@pSiteUser as varchar(100)),'NULL') + @CRLF +
			'    ,@pSitePassword		= ' + isnull(cast(@pSitePassword as varchar(100)),'NULL') + @CRLF +
			'    ,@pSiteKey				= ' + isnull(cast(@pSiteHostKeyFingerprint as varchar(100)),'NULL') + @CRLF +
			'    ,@pSitePort          	= ' + isnull(cast(@pSitePort as varchar(100)),'NULL') + @CRLF +
			'    ,@pSiteProtocol		= ' + isnull(cast(@pSiteProtocol as varchar(100)),'NULL') + @CRLF +
			'     @pETLExecutionId		= ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
			'    ,@pPathId				= ' + isnull(cast(@pPathId as varchar(100)),'NULL') + @CRLF + 
			'    ,@pVerbose				= ' + isnull(cast(@pVerbose as varchar(100)),'NULL')

if @pVerbose					= 1
	begin 
		print @ParametersPassedChar
	end

-------------------------------------------------------------------------------
--  Main
-------------------------------------------------------------------------------

BEGIN TRY

	-------------------------------------------------------------------------------
	--  Step Comment - Start
	-------------------------------------------------------------------------------
	select	 @StepName			= 'Insert into publisher values'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Insert'
			,@StepDesc			= 'Insert to ctl.publisher'
	-------------------------------------------------------------------------------

	SELECT	@Passphrase =
	(
		SELECT	 Passphrase
		FROM	 ctl.[Passphrase]
		WHERE	 DatabaseName	= @DbName
		AND		 SchemaName		= @SchemaName
		AND		 TableName		= @PassphraseTableName
	)

    IF(NOT EXISTS (SELECT @Passphrase ) OR @Passphrase IS NULL OR @Passphrase = '') -- <error test condition>
	   
	   BEGIN

		  SELECT @ErrNum = 50001,
			    @ErrMsg = 'Error Number: '+CAST(@ErrNum AS VARCHAR(10))+@CRLF+
			    'Custom Error: Passphrase for the Publisher table does not exist in the BPI_DW_STAGE.ctl.Passshrase table.'+@CRLF+
			    'Phrase must be created for this table.'+@CRLF+
			    isnull(@ParametersPassedChar, 'Parmeter input resulted in NULL or non-existing output');

		  THROW @ErrNum, @ErrMsg, 1;
	   END;

	SELECT	 @ContactId			= ContactId
	FROM	 ctl.Contact
	WHERE	 [ContactName]		= @pContactName;

    IF(NOT EXISTS(SELECT @ContactId) OR @ContactId IS NULL) -- <error test condition>

	  BEGIN

		  SELECT @ErrNum = 50001,
			    @ErrMsg = 'Error Number: '+CAST(@ErrNum AS VARCHAR(10))+@CRLF+
			    'Custom Error: Contact ID does not exist in the contact table.'+@CRLF+
			    'Contact must be created for this table.'+@CRLF+
			    isnull(@ParametersPassedChar, 'Parmeter input resulted in NULL or non-existing output');

		  THROW @ErrNum, @ErrMsg, 1;
	   END;

-- If the caller provides a User name us it...
	If  @pCreatedBy <> 'Unknown'
		select @CurrentUser = @pCreatedBy
-- Implied Else select @CurrentUser	= CURRENT_USER
	


 INSERT INTO ctl.Publisher
    ([ContactId],
	[PublisherCode],
	[PublisherName],
	[PublisherDesc],
	InterfaceCode,
	[SiteURL],
	[SiteUser],
	[SitePassword],
	[SiteHostKeyFingerprint],
	[SitePort],
	[SiteProtocol]
	,PrivateKeyPassPhrase
	,PrivateKeyFile
	,CreatedDtm
	,CreatedBy
	,ModifiedDtm
	,ModifiedBy
    )
  VALUES
    (@ContactId
	,@pPublisherCode
	,@pPublisherName
	,@pPublisherDesc
	,@pInterfaceCode
	,@pSiteURL
	,@pSiteUser
	,ENCRYPTBYPASSPHRASE(@Passphrase, @pSitePassword)
	,ENCRYPTBYPASSPHRASE(@Passphrase, @pSiteHostKeyFingerprint)   --FTP key in DimVendor  
	,@pSitePort
	,@pSiteProtocol
	,ENCRYPTBYPASSPHRASE(@Passphrase, @pPrivateKeyPassPhrase)
	,ENCRYPTBYPASSPHRASE(@Passphrase, @pPrivateKeyFile) 
	,@CurrentDtm
	,@CurrentUser
	,@CurrentDtm
	,@CurrentUser
    );

	-------------------------------------------------------------------------------
	--  Step Comment - End
	-------------------------------------------------------------------------------
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows			= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		
			,@JSONSnippet		,@ErrNum			,@ParametersPassedChar					
			,@ErrMsg output	,@ParentStepLogId		,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus		,@DbName		,@Rows				
			,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

END try


-------------------------------------------------------------------------------
--  Error Handling
-------------------------------------------------------------------------------
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
			 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
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
		 @MessageType		,@CurrentDtm	,@ProcessStartDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
		,@pVerbose
