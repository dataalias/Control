CREATE PROCEDURE [ctl].[usp_GetPublicationList_DataFactory]
	 @pPublisherCode		varchar(50)		
	,@pETLExecutionId		int				= -1
	,@pPathId				int				= -1
	,@pVerbose				bit				= 0
AS

/*****************************************************************************
 File:			usp_GetPublicationList_DataFactory.sql
 Name:			usp_GetPublicationList_DataFactory
 Purpose:		Returns all active data factory publications related to a publisher.
				exec ctl.usp_GetPublicationList_DataFactory NULL,-1,-1,0	-returns all data factory publications
				exec ctl.usp_GetPublicationList_DataFactory 'SF',-1,-1,0	-returns Salesforce data factory publications
 Parameters:    
 Called by:		Data Factory
 Calls:          
 Author:		jsardina
 Date:			20190812
*******************************************************************************
 CHANGE HISTORY
*******************************************************************************
 Date		Author			Description
 --------	-------------	-----------------------------------------------------
 20190812	jsardina		Original draft
 20210121	ochowkwale		Get Retry Publications without looking at NextExecutionDtm
 20210312	ffortunato		IsDataHub back to a bit.
							Adding ProcessingMEthodCode to replace the functionality.
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
		,@IssueRetry			varchar(2)		= 'IR'

declare @RetryPublications table (
		 PublicationId			int				NOT NULL
		,StatusCode				VARCHAR(20)		NOT NULL
		,IssueId				int				NOT NULL)
-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

select	 @ParametersPassedChar	= 
			'exec bpi_dw_stage.ctl.usp_GetPublicationList_DataFactory' + @CRLF +
			'     @pPublisherCode = ' + ISNULL(CAST(@pETLExecutionId AS VARCHAR(100)),'NULL') + @CRLF + 
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
--  Check if any publication issues are retrying
-------------------------------------------------------------------------------
INSERT INTO @RetryPublications (
	PublicationId
	,StatusCode
	,IssueId)
SELECT p.PublicationId
	,r.StatusCode
	,max(IssueId) AS IssueId
FROM ctl.Publication AS p
INNER JOIN ctl.Publisher AS pu ON p.PublisherId = pu.PublisherId
INNER JOIN ctl.Issue AS i ON i.PublicationId = p.PublicationId
INNER JOIN ctl.RefStatus AS r ON r.StatusId = i.StatusId
WHERE pu.PublisherCode = @pPublisherCode
	AND r.StatusCode = @IssueRetry
GROUP BY p.PublicationId
	,r.StatusCode

-------------------------------------------------------------------------------
--  Generate Publication List
-------------------------------------------------------------------------------
	select	 @StepName			= 'Generate Publication List'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'select'
			,@StepDesc			= 'Generating the publication list for use by Data Factory.'

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
			,pn.RetryIntervalCode
			,pn.RetryIntervalLength
			,pn.RetryMax
			--,pn.MethodCode
			,pn.NextExecutionDtm
			,pn.SLATime
			,ri.[SLAFormat]
			,ri.[SLARegEx]
			--,pn.SrcFileFormatCode AS FeedFormat -- If powershell breaks use this ::AS FeedFormat
			,rff.FileExtension AS FeedFormat -- If powershell breaks use this ::AS FeedFormat
			,pn.SSISFolder
			,pn.SSISProject
			,pn.SSISPackage
			,pn.SrcPublicationName		
			,pn.SrcFilePath
			,pn.PublicationFilePath
			,pn.PublicationArchivePath
	from 	[ctl].[Publication]	  pn
	left join @RetryPublications  rpn
	on		rpn.PublicationId = pn.PublicationId
	join	[ctl].[Publisher]	  pr 
	on		pr.PublisherId		= pn.PublisherId
	join	ctl.RefInterval		  ri
	on		pn.IntervalCode		= ri.IntervalCode
	join	ctl.RefFileFormat	  rff
	on		rff.FileFormatCode	= pn.SrcFileFormatCode
	where	pn.IsActive			= 1 
	and		pn.ProcessingMethodCode = 'ADFP'  -- Azure Data Factory Pipeline
	and		pn.IsDataHub		= 1
	and		pn.Bound			= 'In'
	and		(pn.NextExecutionDtm <= @CurrentDtm OR COALESCE(rpn.StatusCode,'Unknown') = @IssueRetry)
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
