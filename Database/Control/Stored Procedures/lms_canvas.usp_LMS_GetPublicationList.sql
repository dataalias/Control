CREATE PROCEDURE [lms_canvas].[usp_LMS_GetPublicationList]
	@pPublisherCode			varchar(50) 
	,@pETLExecutionId		int				= -1
	,@pPathId				int				= -1
	,@pVerbose				bit				= 0
AS

/*****************************************************************************
 File:			usp_LMS_GetPublicationList.sql
 Name:			usp_LMS_GetPublicationList
 Purpose:		Returns all active publications related to a Canvas Publisher.
				
exec lms_canvas.[usp_LMS_GetPublicationList] NULL, 1
exec lms_canvas.[usp_LMS_GetPublicationList] 'CANVAS-AU', 1
exec lms_canvas.[usp_LMS_GetPublicationList] 'CANVAS-UoR' ,1 

 Parameters:    

 Called by:		Application
 Calls:          

 Author:		ochowkwale
 Date:			20190503
*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
 Date		Author			Description
 --------	-------------	-----------------------------------------------------
 20190503	ochowkwale		Original draft
 20210401	ffortunato		Geting feedofrmat out.
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

SELECT	 @Passphrase =
	(
		SELECT	 Passphrase
		FROM	 ctl.[Passphrase]
		WHERE	 DatabaseName	= @DbName
		AND		 SchemaName		= @SchemaName
		AND		 TableName		= @PassphraseTableName
	)

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

select	 @ParametersPassedChar	= 
			'exec bpi_dw_stage.ctl.usp_GetPublicationList_DataHub' + @CRLF +
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
	select	 @StepName			= 'Generate Publication List'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'select'
			,@StepDesc			= 'Generating the publication list for use by DataHub.'

--	insert	into @PublicationList
	select	 pn.PublicationId
			,pn.PublicationName
			,pn.PublicationCode
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
			,pn.SrcFileFormatCode  as FeedFormat
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
	where	pn.IsActive			= 1 
	and		pn.IsDataHub		= 1
	and		pn.Bound			= 'In'
	and		pn.NextExecutionDtm <= @CurrentDtm
	and		pr.PublisherCode	= @pPublisherCode

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