CREATE PROCEDURE [ctl].[usp_UpdatePublisherFTP] (
		 @pPublisherCode        varchar(10)
		,@pSiteURL				varchar(256)  
		,@pSiteUser				varchar(256) 
		,@pSitePassword			varchar(256)	= NULL	--only for aws
		,@pSiteKey				varchar(256)			--FTPkey in dimvendor    
		,@pSitePort				varchar(10)
		,@pSiteProtocol			varchar(100)
		,@pUser					varchar(50)
		,@pVerbose				bit				= 0
		,@pETLExecutionId		int				= -1
		,@pPathId				int				= 0
		    )
AS
/*****************************************************************************
File:		usp_UpdatePublisherFTP.sql
Name:		usp_UpdatePublisherFTP
Purpose:	

exec 		exec ctl.usp_UpdatePublisherFTP
				 @pPublisherCode ='SK',
                 @pSiteURL = 'vendorsftp.bridgepointeducation.com', --ftp
				 @pUserSite = 'chatstaff' ,
				 @pSitePassword = NULL,
				 @pSiteKey  = 'gKZu-Thd[oJqiH4Q',
				 @pSitePort  = '22' ,
				 @pSiteProtocol  = 'SFTP'


Parameters:    
	             @pPublisherCode 
                 @pSiteURL
				 @pUserSite 
				 @pSitePassword 
				 @pSiteKey
				 @pSitePort
				 @pSiteProtocol

Called by:	User 

Calls:          

Errors:		

Author:	jbonilla	
Date:	20180116 	

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20180111	jbonilla        Update FTP fields in existing data
20201118	ffortunato      cleaning up formatting and warnings
20201123	ffortunato      Cleaning up bi config
20210415	ffortunato      Cleaning warnings.

******************************************************************************/

-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------

DECLARE	 
         @Rows					int				= 0
        ,@ErrNum				int				= -1
		,@ErrMsg				nvarchar(max)	= 'N/A'
		,@ParametersPassedChar	varchar(1000)   = 'N/A'
		,@CRLF					varchar(10)		= char(13) + char(10)
		,@ProcName				varchar(256)	= OBJECT_NAME(@@PROCID) 
		,@ParentStepLogId       int				= -1
		,@PrevStepLog			int				= -1
		,@ProcessStartDtm		datetime		= getdate()
		,@CurrentDtm			datetime		= getdate()
		,@PreviousDtm			datetime		= getdate()
		,@DbName				varchar(50)		= DB_NAME()
		,@SchemaName			nvarchar(256)	= 'ctl'
		,@PassphraseTableName	nvarchar(256)	= 'Publisher'
		,@ProcessType			varchar(10)		= 'Proc'
		,@StepName				varchar(256)	= 'Start'
		,@StepOperation			varchar(50)		= 'N/A' 
		,@MessageType			varchar(20)		= 'Info' -- ErrCust, ErrSQL, Info, Warn
		,@StepDesc				nvarchar(2048)	= 'Procedure started' 
		,@StepStatus			varchar(10)		= 'Success'
		,@StepNumber			varchar(10)		= 0
		,@Duration				varchar(10)		= 0
		,@JSONSnippet			nvarchar(max)	= NULL
		--,@Contact_ID			INT				= -1
		--,@CREATE_DATE           DATETIME		= getdate()
		,@PassPhrase			VARCHAR(100)	= NULL

exec	[audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows	,@pETLExecutionId, @pPathId			,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

SELECT	 @ParametersPassedChar	= 
			'exec BPI_DW_Stage.ctl.usp_UpdatePublisherFTP' + @CRLF +
			'    ,@pPublisherCode	= ' + isnull(cast(@pPublisherCode as varchar(100)),'NULL') + @CRLF +
			'    ,@pSiteURL			= ' + isnull(cast(@pSiteURL as varchar(100)),'NULL') + @CRLF +
			'    ,@pSiteUser		= ' + isnull(cast(@pSiteUser as varchar(100)),'NULL') + @CRLF +
			'    ,@pSitePassword	= ' + isnull(cast(@pSitePassword as varchar(100)),'NULL') + @CRLF +
			'    ,@pSiteKey			= ' + isnull(cast(@pSiteKey as varchar(100)),'NULL') + @CRLF +
			'    ,@pSitePort		= ' + isnull(cast(@pSitePort as varchar(100)),'NULL') + @CRLF +
			'    ,@pSiteProtocol	= ' + isnull(cast(@pSiteProtocol as varchar(100)),'NULL') + @CRLF +
			'    ,@pUser			= ' + isnull(cast(@pUser as varchar(100)),'NULL') + @CRLF +
			'    ,@pVerbose			= ' + isnull(cast(@pVerbose as varchar(100)),'NULL')

if @pVerbose					= 1
	begin 
		print @ParametersPassedChar
	end

-------------------------------------------------------------------------------
--  Main
-------------------------------------------------------------------------------

begin try


	select	 @StepName			= 'StepName'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Select'
			,@StepDesc			= 'Select Passphrase'

	SELECT	 @Passphrase  =
	(
		SELECT	 Passphrase
		FROM	 ctl.[Passphrase]
		WHERE	 DatabaseName	= @DbName
		AND		 SchemaName		= @SchemaName
		AND		 TableName		= @PassphraseTableName
	)


	IF (NOT EXISTS(SELECT @Passphrase) OR @Passphrase IS NULL OR @Passphrase = '') -- <error test condition>
	begin
		select   @ErrNum		= 50001
				,@ErrMsg		= 'Error Number: ' + CAST (@ErrNum as varchar(10)) + @CRLF
								+ 'Custom Error: Passphrase for the DimVendor table does not exist in the BI_Config.DW.Phrase table.'  + @CRLF
								+ 'Phrase must be created for this table.'  + @CRLF
								+ isnull(@ParametersPassedChar, 'Parmeter input resulted in NULL or non-existing output')
		; throw @ErrNum, @ErrMsg, 1
	end

		-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			        ,@Rows				= @@ROWCOUNT 
                 	,@CurrentDtm		= getdate()

	exec	[audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

END TRY

begin catch
	select @ErrMsg = @ErrMsg + ERROR_MESSAGE()
	raiserror (@ErrMsg,-1,-1)
end catch


-------------------------------------------------------------------------------
--  Step comment
-------------------------------------------------------------------------------
Begin try
	select	 @StepName			= 'Update Publisher FTP'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Update'
			,@StepDesc			= 'Update Existing Publisher FTP Data'

	update	 p 				 
	SET		 ModifiedBy			= @pUser
			,ModifiedDtm		= getdate()
			,SiteURL			= @pSiteURL
			,SiteUser			= @pSiteUser
			,SitePassword		= ENCRYPTBYPASSPHRASE(@Passphrase, @pSitePassword)  --Only AWS@pSitePassword, 
			,SiteHostKeyFingerprint	= ENCRYPTBYPASSPHRASE(@Passphrase, @pSiteKey)   --FTP key in DimVendor
			,SitePort			= @pSitePort
			,SiteProtocol		= @pSiteProtocol
	FROM	 [ctl].[Publisher]   p
	where	 PublisherCode		= @pPublisherCode

	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
			,@CurrentDtm		= getdate()
			--,@JSONSnippet		= '<JSON Snippet>' -- Only if needed.

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,-1	,-1				,@PrevStepLog output
			,@pVerbose

	select	 @JSONSnippet		= NULL

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
			,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,-1	,-1			,@PrevStepLog output
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
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,-1	,-1			,@PrevStepLog output
		,@pVerbose

