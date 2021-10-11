CREATE PROCEDURE [ctl].[usp_InsertNewPublication] (
	 @pPublisherCode			varchar(20)
	,@pPublicationCode			varchar(50)
	,@pPublicationName			varchar(50)
	,@pPublicationDesc			varchar(1000)	= 'UNK'
	,@pSrcPublicationName		varchar(255)	= 'UNK'
	,@pPublicationFilePath		varchar(255)	= 'N/A'
	,@pPublicationArchivePath	varchar(255)	= 'N/A'
	,@pSrcFileFormatCode		varchar(20)		= 'N/A'
	,@pStageJobName				VARCHAR(255)	= 'N/A'
	,@pSSISFolder				VARCHAR(255)	= 'N/A'
	,@pSSISProject				VARCHAR(255)	= 'N/A'
	,@pSSISPackage				VARCHAR(255)	= 'N/A'
	,@pDataFactoryName			VARCHAR(255)	= 'N/A'
	,@pDataFactoryPipeline		VARCHAR(255)	= 'N/A'
	,@pSrcDeltaAttributes		varchar(2000)	= 'UNK'
	,@pSrcFilePath				varchar(255)	= 'N/A'
	,@pSrcFileRegEx				varchar(255)	= 'UNK'
	,@pStandardFileRegEx		varchar(255)	= 'UNK'
	,@pStandardFileFormatCode	varchar(20)		= 'UNK'
--	,@pInterfaceCode			varchar(20)
--	,@pMethodCode				varchar(20)		= 'UNK'
	,@pProcessingMethodCode		varchar(20)		= 'UNK'
	,@pTransferMethodCode		varchar(20)		= 'UNK'
	,@pStorageMethodCode		varchar(20)		= 'UNK'
	,@pIntervalCode				varchar(20)		= 'UNK'
	,@pIntervalLength			int				= 0
	,@pRetryIntervalCode		varchar(20)		= 'UNK'
	,@pRetryIntervalLength		int				= 1
	,@pRetryMax					int				= 0
	,@pPublicationEntity		varchar(255)	= 'UNK'
	,@pDestTableName			varchar(255)	= 'UNK'
	,@pSLATime					varchar(20)		= NULL
	,@pSLAEndTimeInMinutes		int				= -1
	,@pNextExecutionDtm			datetime		= NULL -- '1900-01-01 00:00:00.000'
	,@pIsActive					BIT				= 1  -- Why insert it if it isn't active...
	,@pIsDataHub				bit				= 0  -- Maybe it isn't data hub, shouldn't be...
	,@pBound					varchar(5)		= 'In'	 --Inbound or Outbound
	,@pCreatedBy				varchar(50)
	,@pETLExecutionId			int				= -1
	,@pPathId					int				= -1
	,@pVerbose					bit				= 0)
AS
/*****************************************************************************
File:			InsertNewPublication.sql
Name:			usp_InsertNewPublication
Purpose:		Allows for the creation of new publishers.

Parameters:	@p_Publisher_Name

EXEC [ctl].[usp_InsertNewPublication] 
	 @pPublisherCode			= 'WD' -- varchar(20) 
	,@pPublicationCode			= 'WD_ROSTER'-- varchar(50) 
	,@pPublicationName			= 'Workday Roster Data Feed' -- varchar(50) 
	,@pSrcPublicationName		= 'WD_ROSTER_[1..9]{8}_[1..9]{8}\.csv$' -- varchar(255) 
	,@pPublicationFilePath		= 'Workday\inbound\'-- varchar(255) 
	,@pPublicationArchivePath	= 'Workday\archive\'-- varchar(255)
	,@pSrcFileFormatCode				= 'csv'
	,@pSrcFilePath				= @SourceRosterFilePath
	,@pInterfaceCode			= 'FILE' -- varchar(20) 
	,@pMethodCode				= 'DLT' -- varchar(20) 
	,@pIntervalCode				= 'DLY' -- varchar(20) 
	,@pIntervalLength			= 1 -- int 
	,@pRetryIntervalCode		= 'HRLY'	--	varchar(20)
	,@pRetryIntervalLength	= 1	--	int
	,@pRetryMax				= 3				--	int
	,@pPublicationEntity		= 'WD_ROSTER_[1..9]{8}_[1..9]{8}\.csv$' -- varchar(255) 
	,@pDestTableName			= '[BPI_DW_STAGE].[wd].[WorkdayRoster]' -- varchar(255) 
	,@pIsActive					= 1  
	,@pIsDataHub				= 1
	,@pBound					= 'In'
	,@pStageJobName				= ''
	,@pSSISProject				= 'Workday'
	,@pSSISFolder				= 'ETLFolder'
	,@pSSISPackage				= 'Roster_Main_Workday.dtsx'
	,@pCreatedBy				= 'ffortunato' -- varchar(50)

Called by:		Application
Calls:          

Error(s):		50001 - Publisher Code could not be looked up.

Author:		ffortunato
Date:		20091020

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20161205	ffortunato		removing some additional print statements.
20161206	ffortunato		@pPublicationCode should be varchar 20.
20170111	ffortunato		@pPublicationCode should be varchar 50.
							@pSrcPublicationName should be 255
20170120	ffortunato		Adding path variables. changing to alter
20170126	ffortunato		Fixing issues when throwing errors.
							redoing the parameter listing as well.
							formatting.
20170606	fforutnato		Adding destination table.	
20180112	hbangad			Adding new fields-
							1)FeedFormat
							2)SrcFilePath
							Added Insert Step Log and error handling
20180228	fforutnato		Adding SLA and SQLJobName so we can kick off 
							packages.
20180611	fforutnato		SLA needs to be varchar (20) 
20180705	fforutnato		Working on Adding retry logic.
20190305	ochowkwale		Data is inbound or outbound	
20190926	ochowkwale		Change IsDataHub to INT from BIT
20201022	ochowkwale		Parameters for Retrys
20210325	ffortunato		RegEx and FileFormat
******************************************************************************/

-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------

DECLARE	 @Rows					int				= 0
		,@Err					int
		,@ErrNum				int				= -1
		,@ErrMsg				nvarchar(max)	= 'N/A'
		,@FailedProcedure		varchar(1000)
		,@ParametersPassedChar	varchar(1000)   = 'N/A'
		,@CRLF					varchar(10)		= char(13) + char(10)
		,@ProcName				varchar(256)	= OBJECT_NAME(@@PROCID) 
		,@ParentStepLogId		int				= -1
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
		,@CreatedDate			datetime		= getdate()
		,@PublisherId			int				= -1  -- Intentionally setting this to a bad value for the check later on.
		,@StandardFileRegEx		varchar(255)	= 'UNK'
		,@SrcFileRegEx			varchar(255)	= 'UNK'
		,@StandardFileFormatCode varchar(20)	= 'UNK'
		,@SrcFormatCode			varchar(20)		= 'UNK'
		,@SrcFileFormatId		int				= -1
		,@StandardFeedFormatId	int				= -1

exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

SELECT	 @ParametersPassedChar	= 
		'***** Parameters Passed to exec ctl.usp_insertnewpublication' + @CRLF +
		'     @pPublisherCode = '''		 + isnull(@pPublisherCode ,'NULL') + '''' + @CRLF + 
		'    ,@pPublicationCode = '''	 + isnull(@pPublicationCode ,'NULL') + '''' + @CRLF + 
		'    ,@pPublicationName = '''	 + isnull(@pPublicationName ,'NULL') + '''' + @CRLF + 	
		'    ,@@pPublicationDesc = '''	 + isnull(@pPublicationDesc ,'NULL') + '''' + @CRLF + 
		'    ,@pSrcPublicationName = ''' + isnull(@pSrcPublicationName ,'NULL') + '''' + @CRLF + 
		'    ,@pPublicationFilePath = ''' + isnull(@pPublicationFilePath ,'NULL') + '''' + @CRLF + 
		'    ,@pPublicationArchivePath = ''' + isnull(@pPublicationArchivePath ,'NULL') + '''' + @CRLF + 
		'    ,@pSrcFileFormatCode = '''		 + isnull(@pSrcFileFormatCode ,'NULL') + '''' + @CRLF + 
		'    ,@pStageJobName = '''		 + isnull(@pStageJobName ,'NULL') + '''' + @CRLF + 
		'    ,@pSSISFolder = '''		 + isnull(@pSSISFolder ,'NULL') + '''' + @CRLF + 
		'    ,@pSSISProject = '''		 + isnull(@pSSISProject ,'NULL') + '''' + @CRLF + 
		'    ,@pSSISPackage = '''		 + isnull(@pSSISPackage ,'NULL') + '''' + @CRLF + 
		'    ,@pDataFactoryName = '''	 + isnull(@pDataFactoryName ,'NULL') + '''' + @CRLF + 
		'    ,@pDataFactoryPipeline = ''' + isnull(@pDataFactoryPipeline ,'NULL') + '''' + @CRLF + 
		'    ,@pSrcFilePath = '''		 + isnull(@pSrcFilePath ,'NULL') + '''' + @CRLF + 
		'    ,@pSrcFileRegEx = '''		 + isnull(@pSrcFileRegEx ,'NULL') + '''' + @CRLF + 
		'    ,@pStandardFileRegEx = '''	 + isnull(@pStandardFileRegEx ,'NULL') + '''' + @CRLF + 
		'    ,@pStandardFileFormatCode = ''' + isnull(@pStandardFileFormatCode ,'NULL') + '''' + @CRLF + 
		'    ,@pProcessingMethodCode = ''' + isnull(@pProcessingMethodCode ,'NULL') + '''' + @CRLF + 
--		'    ,@pMethodCode = '''		 + isnull(@pMethodCode ,'NULL') + '''' + @CRLF + 
		'    ,@pTransferMethodCode = ''' + isnull(@pTransferMethodCode ,'NULL') + '''' + @CRLF + 
		'    ,@pStageMethodCode = '''	 + isnull(@pStorageMethodCode ,'NULL') + '''' + @CRLF + 
		'    ,@pIntervalCode = '''		 + isnull(@pIntervalCode ,'NULL') + '''' + @CRLF + 
		'    ,@pIntervalLength = '		 + isnull(cast(@pIntervalLength as varchar(100)),'NULL') + @CRLF + 
		'    ,@pRetryIntervalCode = '''	 + isnull(@pRetryIntervalCode ,'NULL') + '''' + @CRLF + 
		'    ,@pRetryIntervalLength = '	 + isnull(cast(@pRetryIntervalLength as varchar(100)),'NULL') + @CRLF + 
		'    ,@pRetryMax = '			 + isnull(cast(@pRetryMax as varchar(100)),'NULL') + @CRLF + 
		'    ,@pPublicationEntity = '''	 + isnull(@pPublicationEntity ,'NULL') + '''' + @CRLF + 
		'    ,@pDestTableName = '''		 + isnull(@pDestTableName ,'NULL') + '''' + @CRLF + 
		'    ,@pSLATime = '''			 + isnull(@pSLATime ,'NULL') + '''' + @CRLF + 
		'    ,@pSLAEndTimeInMinutes = ''' + isnull(cast(@pSLAEndTimeInMinutes as varchar(20)) ,'NULL') + '''' + @CRLF + 
		'    ,@pNextExecutionDtm = '''	 + isnull(convert(varchar(100),@pNextExecutionDtm ,13) ,'NULL') + '''' + @CRLF + 
		'    ,@pIsActive = '			 + isnull(cast(@pIsActive as varchar(100)),'NULL') + @CRLF + 
		'    ,@pIsDataHub = '			 + isnull(cast(@pIsDataHub as varchar(100)),'NULL') + @CRLF + 
		'    ,@pBound = '''				 + isnull(@pBound ,'NULL') + '''' + @CRLF + 
		'    ,@pCreatedBy = '''			 + isnull(@pCreatedBy ,'NULL') + '''' + @CRLF + 
		'    ,@pETLExecutionId = '		 + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
		'    ,@pPathId = '				 + isnull(cast(@pPathId as varchar(100)),'NULL') + @CRLF + 
		'    ,@pVerbose = '				 + isnull(cast(@pVerbose as varchar(100)),'NULL') + @CRLF + 
		'***** End of Parameters' + @CRLF 

if @pVerbose					= 1
	begin 
		print @ParametersPassedChar
	end

if @pNextExecutionDtm is null
	select @pNextExecutionDtm			=  cast('1900-01-01 00:00:00.000' as datetime)

-------------------------------------------------------------------------------
--  Main
-------------------------------------------------------------------------------

begin try
-------------------------------------------------------------------------------
--  The first thing we are going to do is check ubput parameters and their 
--  associated lookups. We need to ensure we have quality data about a 
--  publisher before inserting a new puclication into the controls
-------------------------------------------------------------------------------

	select	 @StepName			= 'Id Lookups'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Select'
			,@StepDesc			= 'Gathering PublicationId based on PublicationCode: ' + @pPublisherCode + ' and FeedFormatId based on FeedFormatCode: ' + @pSrcFileFormatCode

	select	 @PublisherId			= isnull(PublisherId, -1)
	from	 ctl.Publisher			  pbr
	where	 PublisherCode			= @pPublisherCode

	select	 @SrcFileFormatId		= isnull(FileFormatId, -1)
	from	 ctl.RefFileFormat		  ff 
	where	 FileFormatCode			= @pSrcFileFormatCode

	select	 @StandardFeedFormatId	= isnull(FileFormatId, -1)
	from	 ctl.RefFileFormat		  ff 
	where	 FileFormatCode			= @pStandardFileFormatCode


	if @pVerbose					= 1
	begin 
		print '@PublisherId = ' + cast(@PublisherId as varchar(200))
	end

	if ((@PublisherId				= -1) or (@SrcFileFormatId = -1) or (@StandardFeedFormatId = -1))
	begin
		select   @ErrNum		= 50001
				,@MessageType	= 'ErrCust'
				,@ErrMsg		= 'A valid PublisherId or FileFormatId could not be determined.'
				,@JSONSnippet	= '{' + @CRLF +
							'"PublisherId": "'	 + cast(@PublisherId as varchar(200)) + '"' + @CRLF +
							'"PublisherCode": "' + @pPublisherCode + '"' + @CRLF +
							'"FeedFileId": "'	 + cast(@SrcFileFormatId as varchar(200)) + '"' + @CRLF +
							'"FeedFileCode": "'	 + @pSrcFileFormatCode + '"' + @CRLF +
							'"StandardFileFormatId": "'		 + cast(@StandardFeedFormatId as varchar(200)) + '"' + @CRLF +
							'"StandardFileFormatCode": "'	 + @pStandardFileFormatCode + '"' + @CRLF +
							'}'+ @CRLF 

		; throw @ErrNum, @ErrMsg, 1  -- This is thrown to the catch block below.
	end

	else
		begin
			-- Log successful validation.
			select	 @PreviousDtm		= @CurrentDtm
			select	 @CurrentDtm		= getdate()

			exec [audit].usp_InsertStepLog
				 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
				,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
				,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
				,@pVerbose
		end


	-- Prep some variables that can be standard.

	select	 @StepName			= 'Derive Reg Ex'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Select'
			,@StepDesc			= 'Derive a regular expression for the various file names.'

-- Source File
	if (	(@pSrcFileRegEx			= 'UNK') or 
			(@pSrcFileRegEx			= '')	 or 
			(@pSrcFileRegEx			is null))
	begin
		select @SrcFileRegEx		= @pPublicationCode + '_[1-2][0-9][0-9][0-9]([0][1-9]|[1][0-2])([0-2][0-9]|[3][0-1])([0-1][0-9]|[2][0-4])[0-5][0-9][0-5][0-9]\.' + @pSrcFileFormatCode + '$'
	end
	else
	begin
		select @SrcFileRegEx		= @pSrcFileRegEx
	end
-- Data Lake File
	if (	(@pStandardFileRegEx	= 'UNK') or 
			(@pStandardFileRegEx	= '')	 or 
			(@pStandardFileRegEx	is null))
	begin
		select @StandardFileRegEx 	= @pPublicationCode + '_[1-2][0-9][0-9][0-9]([0][1-9]|[1][0-2])([0-2][0-9]|[3][0-1])([0-1][0-9]|[2][0-4])[0-5][0-9][0-5][0-9]\.' + @pSrcFileFormatCode + '$'
	end
	else
	begin
		select @StandardFileRegEx	= @pStandardFileRegEx
	end

	-- Log successful validation.
	select	 @PreviousDtm		= @CurrentDtm
	select	 @CurrentDtm		= getdate()

	exec [audit].usp_InsertStepLog
			@MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
		,@pVerbose

	select	 @StepName			= 'Insert New Publication'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Insert'
			,@StepDesc			= 'Entering a new record into the publication record.'
			,@JSONSnippet		= NULL

	insert into [ctl].[Publication](
			 [PublisherId]
			,[PublicationCode]
			,[PublicationName]
			,PublicationDesc	
			,[SrcPublicationName]
--			,[InterfaceCode]
--			,[MethodCode]
			,ProcessingMethodCode
			,TransferMethodCode
			,StorageMethodCode
			,[IntervalCode]
			,[IntervalLength]
			,RetryIntervalCode
			,RetryIntervalLength
			,RetryMax
			,[PublicationEntity]
			,PublicationFilePath
			,PublicationArchivePath
			,SrcFileFormatCode
			,SrcFilePath
			,SrcFileRegEx			
			,StandardFileRegEx	
			,StandardFileFormatCode
			,DestTableName
			,StageJobName
			,SLATime
			,SLAEndTimeInMinutes
			,NextExecutionDtm
			,IsActive
			,IsDataHub
			,Bound
			,SSISFolder
			,SSISProject
			,SSISPackage
			,DataFactoryName
			,DataFactoryPipeline
			,SrcDeltaAttributes
			,CreatedBy
			,CreatedDtm
			,ModifiedBy
			,ModifiedDtm
	) values (
			 @PublisherId
			,@pPublicationCode
			,@pPublicationName
			,@pPublicationDesc	
			,@pSrcPublicationName
--			,@pInterfaceCode
--			,@pMethodCode
			,@pProcessingMethodCode
			,@pTransferMethodCode
			,@pStorageMethodCode
			,@pIntervalCode
			,@pIntervalLength
			,@pRetryIntervalCode
			,@pRetryIntervalLength
			,@pRetryMax
			,@pPublicationEntity
			,@pPublicationFilePath
			,@pPublicationArchivePath
			,@pSrcFileFormatCode
			,@pSrcFilePath
			,@pSrcFileRegEx			
			,@pStandardFileRegEx	
			,@pStandardFileFormatCode
			,@pDestTableName
			,@pStageJobName
			,@pSLATime
			,@pSLAEndTimeInMinutes
			,@pNextExecutionDtm
			,@pIsActive
			,@pIsDataHub
			,@pBound
			,@pSSISFolder
			,@pSSISProject
			,@pSSISPackage
			,@pDataFactoryName
			,@pDataFactoryPipeline
			,@pSrcDeltaAttributes
			,@pCreatedBy
			,@CreatedDate
			,@pCreatedBy -- Ya ya its modified
			,@CreatedDate) -- Ya ya its modified

	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		
			,@JSONSnippet		,@ErrNum			,@ParametersPassedChar					
			,@ErrMsg output		,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus		,@DbName		,@Rows				
			,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

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

exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm	,@ProcessStartDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
		,@pVerbose
