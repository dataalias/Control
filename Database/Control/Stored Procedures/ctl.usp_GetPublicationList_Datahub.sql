CREATE procedure [ctl].[usp_GetPublicationList_DataHub] (
		 @pETLExecutionId		int				= -1
		,@pPathId				int				= -1
		,@pVerbose				bit				= 0)
as
/*****************************************************************************
File:		usp_GetPublicationList_DataHub.sql
Name:		usp_GetPublicationList_DataHub
Purpose:	

			This procedure gathers all the relevant information required by
			DataHub to process new data into the staging system. FTP and SHARE
			locations are returned for file based connectors. TBL connectors
			are automatically entered when the interval is met.

exec ctl.usp_GetPublicationList_DataHub -1, -1, 0

Parameters:    

Called by:	
Calls:          

Errors:		

Author:		
Date:		

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20180226	ffortunato		SiteKey that is returned must be varchar (256)
20180307	ffortunato		Adding SSIS parameters for kicking off packages.
20180604	ffortunato		Adding SLATime and format to return set.
20180703	ffortunato		formatting only. testing .editorconfig
20180710	ffortunato		Prepping for some new retry attributes.
							Removing status check for "last" update. 
							Retry neeeds to retry any issue status.
20180822	ffortunato		Adding Bound (In or Out).
							PublisherType --> InterfaceCode
							Rows char --> int
20180925	ffortunato		Cleaning up some validations.
20181018	ffortunato		SLA and Interval Check added.
20181029	ffortunato		Updating interval logic. Cleaning out old code.
20190530	ochowkwale		No Interface code - CANVAS

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
		,@SchemaName			nvarchar(256)	= 'ctl'
		,@PassphraseTableName	nvarchar(256)	= 'Publisher'


exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose


-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

select	 @ParametersPassedChar	= 
			'exec Control.ctl.usp_GetPublicationList_DataHub' + @CRLF +
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

	SELECT	@Passphrase =
	(
		SELECT	 Passphrase
		FROM	 ctl.[Passphrase]
		WHERE	 DatabaseName	= @DbName
		AND		 SchemaName		= @SchemaName
		AND		 TableName		= @PassphraseTableName
	)

-------------------------------------------------------------------------------
--  Generate Publication List
-------------------------------------------------------------------------------
	select	 @StepName			= 'Generate Publication List'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'select'
			,@StepDesc			= 'Generating the publication list for use by DataHub.'

--	insert	into @PublicationList
	select	 pn.PublicationId
			,pn.PublicationName
			,pn.PublicationCode
--			,pr.PublisherType
			,pr.InterfaceCode
			,pr.SiteURL
			,pr.SiteUser
			,CONVERT(varchar(256), DECRYPTBYPASSPHRASE(@PassPhrase, pr.[SitePassword]))				as SitePassword
			,CONVERT(varchar(256), DECRYPTBYPASSPHRASE(@PassPhrase, pr.SiteHostKeyFingerprint))		as SiteHostKeyFingerprint
			,pr.SitePort
			,pr.SiteProtocol
			,CONVERT(varchar(256), DECRYPTBYPASSPHRASE(@PassPhrase, pr.PrivateKeyPassPhrase))		as PrivateKeyPassPhrase
			,CONVERT(varchar(256), DECRYPTBYPASSPHRASE(@PassPhrase, pr.PrivateKeyFile))				as PrivateKeyFile
			,pn.IntervalCode
			,pn.IntervalLength
			--,pn.RetryIntervalCode
			--,pn.RetryIntervalLength
			--,pn.RetryMax
			,pn.NextExecutionDtm
			,pn.SLATime
			,ri.[SLAFormat]
			,ri.[SLARegEx]
			,pn.FeedFormat
			,pn.SSISFolder
			,pn.SSISProject
			,pn.SSISPackage
			,pn.SrcPublicationName		
			,pn.SrcFilePath
			,pn.PublicationFilePath
			,pn.PublicationArchivePath

	from 	[ctl].[Publication]	  pn
	join	[ctl].[Publisher]	  pr 
	on		pr.PublisherId		= pn.PublisherId
	join	ctl.RefInterval		  ri
	on		pn.IntervalCode		= ri.IntervalCode
	where	pn.IsActive			= 1 -- We only want active records.
	and		pn.IsDataHub		= 1
 	and		pr.InterfaceCode	!= 'CANVAS'
	and		pn.Bound			= 'In'
	and		pn.NextExecutionDtm <= @CurrentDtm

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

-------------------------------------------------------------------------------
--  Procedure End
-------------------------------------------------------------------------------
/*
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
*/


