CREATE procedure [pg].[InsertPostingGroup] (	
		 @pCode					varchar(100)	= 'UNK'
		,@pName					varchar(250)	= 'Unknown'
		,@pDesc					varchar(1000)	= 'Description for this posting group is unknown.'
		,@pCategoryCode			varchar(20)		= 'UNK'
		,@pCategoryName			varchar(250)	= 'Unknown'
		,@pCategoryDesc			varchar(max)	= 'Category for this posting group is unknown.'
		,@pProcessingMethodCode	varchar(20)		= 'ADFP'
		,@pProcessingModeCode	varchar(20)		= 'NORM'
		,@pInterval				varchar(20)		= 'UNK'
		,@pLength				int				= 0
		,@pSSISFolder			varchar(255)	= 'N/A'
		,@pSSISProject			varchar(255)	= 'N/A'
		,@pSSISPackage			varchar(255)	= 'N/A'
		,@pDataFactoryName		varchar(255)	= 'N/A'
		,@pDataFactoryPipeline	varchar(255)	= 'N/A'
		,@pJobName				varchar(255)	= 'N/A'
		,@pRetryIntervalCode	varchar(20)		= 'MIN'
		,@pRetryIntervalLength	int				= 1
		,@pRetryMax				int				= 0
		,@pTriggerProcess		varchar(100)	= 'N/A'
		,@pIsActive				bit				= 0
		,@pIsRoot				bit				= 0
		,@pTriggerType			varchar(20)		= 'Immediate'
		,@pNextExecutionDtm		datetime		= NULL -- '1900-01-01 00:00:00.000'
		,@pCreatedBy			varchar(50)		= 'Unknown'
		,@pETLExecutionId		int				= -1
		,@pPathId				int				= -1
		,@pVerbose				bit				= 0
) AS 

/*****************************************************************************
File:           InsertPostingGroup.sql
Name:           InsertPostingGroup
Purpose:        Allows for the creation of new posting groups.

	EXEC pg.InsertPostingGroup 	
		 @pCode			= 'PUBR01-SUBR01-PUBN01-ACCT'		
		,@pName			= 'Test Publisher 01 Sending Data to Subscriber 01. Publication 01 Account'
		,@pDesc			= 'Regression testing the hand off from DataHub to PostingGroup'
		,@pCategory		= 'N/A'		
		--,@pProcessingMethodCode	= 'NORM'
		--,@pProcessingModeCode	= 'DFP'
		,@pInterval		= 'DLY'				
		,@pLength		= 1
		,@pSSISFolder	= 'RegressionTesting'	
		,@pSSISProject	= 'PostingGroup'	
		,@pSSISPackage	= 'TSTPUBN01-ACCT.dtsx'	
		,@pIsActive		= 1
		,@pTriggerType			= 'Immediate'
		,@pNextExecutionDtm		= '01-Jan-1900'
		,@pCreatedBy	= 'ffortunato'
		,@pETLExecutionId		= -1
		,@pPathId		= -1
		,@pVerbose		= 0

Parameters:     
	@pCode		-- Manually set a shortened code value to associate with this group
	@pName		-- Name of this group
	@pDesc		-- Description for this group
	@pCategory	-- Category
	@pInterval	-- Interval Code. See ctl.RefInterval for values 
	@pLength	-- Length of the interval 2 H = 2 hours.
	@pSSISFolder	-- ETL Folder
	@pSSISProject	-- ETL Project
	@pSSISPackage	-- ETL Package dtsx
	@pIsActive	-- IActive. 1=Yes, 0=No
	@pCreatedBy	-- Who created the posting group entry
	@pETLExecutionId
	@pPathId
	@pVerbose

Called By:   application
Calls:		exec ctl.[usp_InsertPostingGroup]

Examples:

Called By:      application
Calls:          

Author:         ffortunato
Date:           20091020

*******************************************************************************
      change history
*******************************************************************************
date		author			description
--------	-------------	---------------------------------------------------
20161020	ffortunato		adding process name to the postinggroup table.
20161122	jprom			updated parameter comments and added examples.
20180409	ffortunato		dusting off and preping for implementation.
20180906	ffortunato		code validation changes.
20200725	ochowkwale		parameters for NextExecutionDtm, TriggerType
20210217	ffortunato		Adding Job Name to fire SQL Server Jobs
20210327	ffortunato		Category stuff.
******************************************************************************/

DECLARE	 @Rows					int				= 0
        ,@ErrNum				int				= -1
		,@ErrMsg				nvarchar(2048)	= 'N/A'
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

----------------------------------------------------------------------------------
--  initializations
----------------------------------------------------------------------------------
select	 @ParametersPassedChar   =       
      '***** Parameters Passed to exec pg.InsertPostingGroup' + @CRLF +
      '     @pCode = ''' + isnull(@pCode ,'NULL') + '''' + @CRLF + 
      '    ,@pName = ''' + isnull(@pName ,'NULL') + '''' + @CRLF + 
      '    ,@pDesc = ''' + isnull(@pDesc ,'NULL') + '''' + @CRLF + 
      '    ,@pCategoryCode = ''' + isnull(@pCategoryCode ,'NULL') + '''' + @CRLF + 
	  '    ,@pCategoryName = ''' + isnull(@pCategoryName ,'NULL') + '''' + @CRLF + 
	  '    ,@pCategoryDesc = ''' + isnull(@pCategoryDesc ,'NULL') + '''' + @CRLF + 
      '    ,@pProcessingMethodCode = ''' + isnull(@pProcessingMethodCode ,'NULL') + '''' + @CRLF + 
      '    ,@pProcessingModeCode = ''' + isnull(@pProcessingModeCode ,'NULL') + '''' + @CRLF + 
      '    ,@pInterval = ''' + isnull(@pInterval ,'NULL') + '''' + @CRLF + 
      '    ,@pLength = ' + isnull(cast(@pLength as varchar(100)),'NULL') + @CRLF + 
      '    ,@pSSISFolder = ''' + isnull(@pSSISFolder ,'NULL') + '''' + @CRLF + 
      '    ,@pSSISProject = ''' + isnull(@pSSISProject ,'NULL') + '''' + @CRLF + 
      '    ,@pSSISPackage = ''' + isnull(@pSSISPackage ,'NULL') + '''' + @CRLF + 
      '    ,@pDataFactoryName = ''' + isnull(@pDataFactoryName ,'NULL') + '''' + @CRLF + 
      '    ,@pDataFactoryPipeline = ''' + isnull(@pDataFactoryPipeline ,'NULL') + '''' + @CRLF + 
      '    ,@pJobName = ''' + isnull(@pJobName ,'NULL') + '''' + @CRLF + 
      '    ,@pRetryIntervalCode = ''' + isnull(@pRetryIntervalCode ,'NULL') + '''' + @CRLF + 
      '    ,@pRetryIntervalLength = ' + isnull(cast(@pRetryIntervalLength as varchar(100)),'NULL') + @CRLF + 
      '    ,@pRetryMax = ' + isnull(cast(@pRetryMax as varchar(100)),'NULL') + @CRLF + 
      '    ,@pTriggerProcess = ''' + isnull(@pTriggerProcess ,'NULL') + '''' + @CRLF + 
      '    ,@pIsActive = ' + isnull(cast(@pIsActive as varchar(100)),'NULL') + @CRLF + 
      '    ,@pTriggerType = ''' + isnull(@pTriggerType ,'NULL') + '''' + @CRLF + 
      '    ,@pNextExecutionDtm = ''' + isnull(convert(varchar(100),@pNextExecutionDtm ,13) ,'NULL') + '''' + @CRLF + 
      '    ,@pCreatedBy = ''' + isnull(@pCreatedBy ,'NULL') + '''' + @CRLF + 
      '    ,@pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pPathId = ' + isnull(cast(@pPathId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL') + @CRLF + 
      '***** End of Parameters' + @CRLF 

if @pNextExecutionDtm is null
	  select @pNextExecutionDtm		= cast('1900-01-01 00:00:00.000' as datetime)

----------------------------------------------------------------------------------
--  main
----------------------------------------------------------------------------------
begin try


	exec audit.usp_InsertStepLog
		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose


-------------------------------------------------------------------------------
--  Generate Publication List
-------------------------------------------------------------------------------
	select	 @StepName			= 'Insert new record into Posting Group'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'insert'
			,@StepDesc			= 'Preparing a new record for posting group.'

	insert into pg.PostingGroup(
		 [PostingGroupCode]
		,[PostingGroupName]
		,[PostingGroupDesc]
		,[ProcessingMethodCode]
		,[ProcessingModeCode]
		,[PostingGroupCategoryCode]
		,[PostingGroupCategoryName]
		,[PostingGroupCategoryDesc]
		,[IntervalCode]
		,[IntervalLength]
		,SSISFolder
		,SSISProject
		,SSISPackage		
		,DataFactoryName		
		,DataFactoryPipeline	
		,JobName
		,RetryIntervalCode	
		,RetryIntervalLength	
		,RetryMax				
--		,TriggerProcess		
		,[IsActive]
		,IsRoot
--		,[TriggerType]
		,[NextExecutionDtm]
		,[CreatedDtm]
		,CreatedBy
	) values (
		 @pCode
		,@pName
		,@pDesc
		,@pProcessingMethodCode
		,@pProcessingModeCode
		,@pCategoryCode
		,@pCategoryName
		,@pCategoryDesc
		,@pInterval
		,@pLength
		,@pSSISFolder	
		,@pSSISProject	
		,@pSSISPackage	
		,@pDataFactoryName		
		,@pDataFactoryPipeline	
		,@pJobName
		,@pRetryIntervalCode	
		,@pRetryIntervalLength	
		,@pRetryMax				
--		,@pTriggerProcess		
		,@pIsActive
		,@pIsRoot
--		,@pTriggerType
		,@pNextExecutionDtm
		,@CurrentDtm
		,@pCreatedBy
	)

	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			,@JSONSnippet		= '{"PostingGroupCode":"'+@pCode+'"}'

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	select	 @JSONSnippet		= NULL

end try-- main

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
		,@ParametersPassedChar				,@ErrMsg output		,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus	,@DbName			,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
		,@pVerbose
