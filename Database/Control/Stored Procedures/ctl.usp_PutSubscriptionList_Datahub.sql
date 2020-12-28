CREATE procedure [ctl].[usp_PutSubscriptionList_Datahub] (
		 @pIssueId				int				
		,@pETLExecutionId		int				= -1
		,@pPathId				int				= -1
		,@pVerbose				bit				= 0)
as
/*****************************************************************************
File:		usp_PutSubscriptionList.sql
Name:		usp_PutSubscriptionList
Purpose:	
			This procedure gathers all the relevant information required by
			DataHub to export files to FTP and SHARE locations of each subscriber
			with a subscription to given IssueId

exec ctl.usp_PutSubscriptionList_Datahub 463776,-1, -1, 1

Parameters:    

Called by:	
Calls:          

Errors:		

Author:	ochowkwale	
Date:	20190306

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20190306	ochowkwale		Initial Iteration.
20201118	ffortunato		clearing some warnings.
20201123	ffortunato		Passphrase.

******************************************************************************/

-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------

declare	 @Rows					int				= 0
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
		,@PassPhraseTableName	nvarchar(256)	= 'Subscriber'
		,@ProcessType			varchar(10)		= 'Proc'
		,@StepName				varchar(256)	= 'Start'
		,@StepOperation			varchar(50)		= 'N/A' 
		,@MessageType			varchar(20)		= 'Info' -- ErrCust, ErrSQL, Info, Warn
		,@StepDesc				nvarchar(2048)	= 'Procedure started' 
		,@StepStatus			varchar(10)		= 'Success'
		,@StepNumber			varchar(10)		= 0
		,@Duration				varchar(10)		= 0
		,@JSONSnippet			nvarchar(max)	= NULL
		,@PassPhrase			varchar(256)	= ''
		,@SLATimeChar			varchar(20)		= 'N/A'
		,@SLATime				datetime

/*
exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose
*/

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

select	 @ParametersPassedChar	= 
			'exec Control.ctl.usp_PutSubscriptionList' + @CRLF +
			'     @pIssueId = ' + ISNULL(CAST(@pIssueId AS VARCHAR(100)),'NULL') + @CRLF + 
			'     @pETLExecutionId = ' + ISNULL(CAST(@pETLExecutionId AS VARCHAR(100)),'NULL') + @CRLF + 
			'    ,@pPathId = ' + ISNULL(CAST(@pPathId AS VARCHAR(100)),'NULL') + @CRLF + 
			'    ,@pVerbose = ' + ISNULL(CAST(@pVerbose AS VARCHAR(100)),'NULL')

if @pVerbose					= 1
	begin 
		print @ParametersPassedChar
	end

-------------------------------------------------------------------------------
--  Main
-------------------------------------------------------------------------------

begin try

-------------------------------------------------------------------------------
--  Generate Publication List
-------------------------------------------------------------------------------
	select	 @StepName			= 'Generate Subscription List'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'select'
			,@StepDesc			= 'Generating the subscription list for IssueId'
				
	SELECT	@Passphrase =
	(
		SELECT	 Passphrase
		FROM	 ctl.[Passphrase]
		WHERE	 DatabaseName	= @DbName
		AND		 SchemaName		= @SchemaName
		AND		 TableName		= @PassPhraseTableName
	)

	IF EXISTS (	SELECT 1 FROM ctl.Issue	WHERE IssueId = @pIssueId)
	BEGIN
		SELECT d.IssueId
			,i.IssueName
			,sn.SubscriptionCode
			,sn.SubscriptionFilePath
			,sn.SubscriptionArchivePath
			,sn.SrcFilePath
			,sr.InterfaceCode
			,sr.SiteURL
			,sr.SiteUser
			,CONVERT(VARCHAR(256), DECRYPTBYPASSPHRASE(@PassPhrase, sr.[SitePassword])) AS SitePassword
			,CONVERT(VARCHAR(256), DECRYPTBYPASSPHRASE(@PassPhrase, sr.SiteHostKeyFingerprint)) AS SiteHostKeyFingerprint
			,sr.SitePort
			,sr.SiteProtocol
			,CONVERT(VARCHAR(256), DECRYPTBYPASSPHRASE(@PassPhrase, sr.PrivateKeyPassPhrase)) AS PrivateKeyPassPhrase
			,CONVERT(VARCHAR(256), DECRYPTBYPASSPHRASE(@PassPhrase, sr.PrivateKeyFile)) AS PrivateKeyFile
		FROM	  ctl.[Distribution]		  d
		LEFT JOIN ctl.[Issue]				  i 
		ON			i.IssueId				= d.IssueId
		LEFT JOIN ctl.Subscription			  sn 
		ON			d.SubscriptionId		= sn.SubscriptionId
		LEFT JOIN ctl.Subscriber			  sr 
		ON		   sr.SubscriberId			= sn.SubscriberId
		WHERE	   sn.IsActive				= 1 -- We only want active records
		AND			d.IssueId				= @pIssueId
	END
	ELSE
	BEGIN
		SELECT @ErrNum = 50002
			,@ErrMsg = 'ErrorNumber: ' + CAST(@ErrNum AS VARCHAR(50)) + @CRLF + 'Custom Error: Invalid IssueId passed to stored procdure' + @CRLF + isnull(@ParametersPassedChar, 'Parmeter was NULL');
		throw @ErrNum,@ErrMsg,1
	END


	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= GETDATE()
			--,@JSONSnippet		= '<JSON Snippet>' -- Only if needed.

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar					,@ErrMsg OUTPUT	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc OUTPUT	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog OUTPUT
			,@pVerbose

	select	 @JSONSnippet		= NULL

end try

-------------------------------------------------------------------------------
--  Error Handling
-------------------------------------------------------------------------------
begin catch

	select 	 @PreviousDtm		= @CurrentDtm
			,@ErrNum			= @@ERROR
			,@ErrMsg			= ERROR_MESSAGE()
			,@Rows				= 0

	select	 @StepStatus		= 'Failure'
			,@CurrentDtm		= GETDATE()

	if		 @MessageType		<> 'ErrCust'
		select   @MessageType	= 'ErrSQL'

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar					,@ErrMsg OUTPUT	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc OUTPUT	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog OUTPUT
			,@pVerbose

	if 	@ErrNum < 50000	
		select	 @ErrNum	= @ErrNum + 100000000 -- Need to increase number to throw message.

	;throw	 @ErrNum, @ErrMsg, 1
	
end catch