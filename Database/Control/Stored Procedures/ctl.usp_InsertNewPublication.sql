CREATE PROCEDURE [ctl].[usp_InsertNewPublication] (
	 @pPublisherCode			varchar(20)
	,@pPublicationCode			varchar(50)
	,@pPublicationName			varchar(50)
	,@pSrcPublicationName		varchar(255)
	,@pPublicationFilePath		varchar(255)
	,@pPublicationArchivePath	varchar(255)
	,@pFeedFormat				varchar(10)
	,@pStageJobName				VARCHAR(255)	= 'N/A'
	,@pSSISFolder				VARCHAR(255)	= 'N/A'
	,@pSSISProject				VARCHAR(255)	= 'N/A'
	,@pSSISPackage				VARCHAR(255)	= 'N/A'
	,@pDataFactoryName			VARCHAR(255)	= 'N/A'
	,@pDataFactoryPipeline		VARCHAR(255)	= 'N/A'
	,@pSrcFilePath				varchar(255)
--	,@pInterfaceCode			varchar(20)
	,@pMethodCode				varchar(20)
	,@pIntervalCode				varchar(20)
	,@pIntervalLength			int
	,@pRetryIntervalCode		varchar(20)		= 'HR'
	,@pRetryIntervalLength		int				= 1
	,@pRetryMax					int				= 0
	,@pPublicationEntity		varchar(255)
	,@pDestTableName			varchar(255)
	,@pSLATime					varchar(20)		= NULL
	,@pSLAEndTime				varchar(20)		= NULL
	,@pNextExecutionDtm			datetime		= '1900-01-01 00:00:00.000'
	,@pIsActive					BIT				= 1  -- Why insert it if it isn't active...
	,@pIsDataHub				INT				= 0  -- Maybe it isn't data hub, shouldn't be...
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
	,@pFeedFormat				= 'csv'
	,@pSrcFilePath				= @SourceRosterFilePath
	,@pInterfaceCode			= 'FILE' -- varchar(20) 
	,@pMethodCode				= 'DLT' -- varchar(20) 
	,@pIntervalCode				= 'DLY' -- varchar(20) 
	,@pIntervalLength			= 1 -- int 
	,@pRetryIntervalCode		= 'HR'	--	varchar(20)
	,@pRetryIntervalLength	= 1	--	int
	,@pRetryMax				= 3				--	int
	,@pPublicationEntity		= 'WD_ROSTER_[1..9]{8}_[1..9]{8}\.csv$' -- varchar(255) 
	,@pDestTableName			= '[Control].[wd].[WorkdayRoster]' -- varchar(255) 
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
Date:			20091020

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

exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

SELECT	 @ParametersPassedChar	= 
      '***** Parameters Passed to exec ctl.usp_InsertNewPublication' + @CRLF +
      '     @pPublisherCode = ''' + isnull(@pPublisherCode ,'NULL') + '''' + @CRLF + 
      '    ,@pPublicationCode = ''' + isnull(@pPublicationCode ,'NULL') + '''' + @CRLF + 
      '    ,@pPublicationName = ''' + isnull(@pPublicationName ,'NULL') + '''' + @CRLF + 
      '    ,@pSrcPublicationName = ''' + isnull(@pSrcPublicationName ,'NULL') + '''' + @CRLF + 
      '    ,@pPublicationFilePath = ''' + isnull(@pPublicationFilePath ,'NULL') + '''' + @CRLF + 
      '    ,@pPublicationArchivePath = ''' + isnull(@pPublicationArchivePath ,'NULL') + '''' + @CRLF + 
      '    ,@pFeedFormat = ''' + isnull(@pFeedFormat ,'NULL') + '''' + @CRLF + 
      '    ,@pStageJobName = ''' + isnull(@pStageJobName ,'NULL') + '''' + @CRLF + 
      '    ,@pSSISFolder = ''' + isnull(@pSSISFolder ,'NULL') + '''' + @CRLF + 
      '    ,@pSSISProject = ''' + isnull(@pSSISProject ,'NULL') + '''' + @CRLF + 
      '    ,@pSSISPackage = ''' + isnull(@pSSISPackage ,'NULL') + '''' + @CRLF + 
	  '    ,@pDataFactoryName = ''' + isnull(@pDataFactoryName ,'NULL') + '''' + @CRLF + 
	  '    ,@pDataFactoryPipeline = ''' + isnull(@pDataFactoryPipeline ,'NULL') + '''' + @CRLF + 
      '    ,@pSrcFilePath = ''' + isnull(@pSrcFilePath ,'NULL') + '''' + @CRLF + 
--      '    ,@pInterfaceCode = ''' + isnull(@pInterfaceCode ,'NULL') + '''' + @CRLF + 
      '    ,@pMethodCode = ''' + isnull(@pMethodCode ,'NULL') + '''' + @CRLF + 
      '    ,@pIntervalCode = ''' + isnull(@pIntervalCode ,'NULL') + '''' + @CRLF + 
      '    ,@pIntervalLength = ' + isnull(cast(@pIntervalLength as varchar(100)),'NULL') + @CRLF + 
	  '    ,@pRetryIntervalCode = ''' + isnull(@pRetryIntervalCode ,'NULL') + '''' + @CRLF + 
	  '    ,@pRetryIntervalLength = ''' + isnull(cast(@pRetryIntervalLength as varchar(100)) ,'NULL') + '''' + @CRLF + 
	  '    ,@pRetryMax = ''' + isnull(cast(@pRetryMax as varchar(100)),'NULL') + '''' + @CRLF + 
      '    ,@pPublicationEntity = ''' + isnull(@pPublicationEntity ,'NULL') + '''' + @CRLF + 
      '    ,@pDestTableName = ''' + isnull(@pDestTableName ,'NULL') + '''' + @CRLF + 
      '    ,@pSLATime = ''' + isnull(@pSLATime ,'NULL') + '''' + @CRLF + 
	  '    ,@pSLAEndTime = ''' + isnull(@pSLAEndTime ,'NULL') + '''' + @CRLF + 
	  '    ,@pNextExecutionDtm = ' + isnull(cast(@pNextExecutionDtm as varchar(100)),'NULL') + @CRLF + 
      '    ,@pIsActive = ' + isnull(cast(@pIsActive as varchar(100)),'NULL') + @CRLF + 
      '    ,@pIsDataHub = ' + isnull(cast(@pIsDataHub as varchar(100)),'NULL') + @CRLF + 
	  '    ,@pBound = ' + isnull(cast(@pBound as varchar(5)),'NULL') + @CRLF + 
      '    ,@pCreatedBy = ''' + isnull(@pCreatedBy ,'NULL') + '''' + @CRLF + 
      '    ,@pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pPathId = ' + isnull(cast(@pPathId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL') + @CRLF + 
      '***** End of Parameters' + @CRLF 

if @pVerbose					= 1
	begin 
		print @ParametersPassedChar
	end

-------------------------------------------------------------------------------
--  Main
-------------------------------------------------------------------------------

begin try
-------------------------------------------------------------------------------
--  The first thing we are going to do is check ubput parameters and their 
--  associated lookups. We need to ensure we have quality data about a 
--  publisher before inserting a new puclication into the controls
-------------------------------------------------------------------------------

	select	 @StepName			= 'Check Publisher Id'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Select'
			,@StepDesc			= 'Gathering PublicationId based on PublicationCode: ' + @pPublisherCode

	select	 @PublisherId			= isnull(PublisherId, -1)
	from	 ctl.Publisher 
	where	 PublisherCode			= @pPublisherCode

	if @pVerbose					= 1
	begin 
		print '@PublisherId = ' + cast(@PublisherId as varchar(200))
	end

	if @PublisherId					= -1
	begin
		select   @ErrNum		= 50001
				,@MessageType	= 'ErrCust'
				,@ErrMsg		= 'A valid PublisherId could not be determined.'
				,@JSONSnippet	= '{' + @CRLF +
							'"PublisherId": "' + cast(@PublisherId as varchar(200)) + '"' + @CRLF +
							'"PublisherCode": "' + @pPublisherCode + '"' + @CRLF +
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

	select	 @StepName			= 'Insert New Publication'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Insert'
			,@StepDesc			= 'Entering a new record into the publication record.'
			,@JSONSnippet		= NULL

	insert into [ctl].[Publication](
			 [PublisherId]
			,[PublicationCode]
			,[PublicationName]
			,[SrcPublicationName]
--			,[InterfaceCode]
			,[MethodCode]
			,[IntervalCode]
			,[IntervalLength]
			,RetryIntervalCode
			,RetryIntervalLength
			,RetryMax
			,[PublicationEntity]
			,PublicationFilePath
			,PublicationArchivePath
			,FeedFormat
			,SrcFilePath
			,DestTableName
			,StageJobName
			,SLATime
			,SLAEndTime
			,NextExecutionDtm
			,IsActive
			,IsDataHub
			,Bound
			,SSISFolder
			,SSISProject
			,SSISPackage
			,DataFactoryName
			,DataFactoryPipeline
			,[CreatedBy]
			,[CreatedDtm]
	) values (
			 @PublisherId
			,@pPublicationCode
			,@pPublicationName
			,@pSrcPublicationName
--			,@pInterfaceCode
			,@pMethodCode
			,@pIntervalCode
			,@pIntervalLength
			,@pRetryIntervalCode
			,@pRetryIntervalLength
			,@pRetryMax
			,@pPublicationEntity
			,@pPublicationFilePath
			,@pPublicationArchivePath
			,@pFeedFormat
			,@pSrcFilePath
			,@pDestTableName
			,@pStageJobName
			,@pSLATime
			,@pSLAEndTime
			,@pNextExecutionDtm
			,@pIsActive
			,@pIsDataHub
			,@pBound
			,@pSSISFolder
			,@pSSISProject
			,@pSSISPackage
			,@pDataFactoryName
			,@pDataFactoryPipeline
			,@pCreatedBy
			,@CreatedDate)

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
