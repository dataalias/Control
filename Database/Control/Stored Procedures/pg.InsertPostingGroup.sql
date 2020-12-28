CREATE procedure [pg].[InsertPostingGroup] (	
		 @pCode					VARCHAR(100)
		,@pName					VARCHAR(250)
		,@pDesc					VARCHAR(1000)
		,@pCategory				VARCHAR(50)
		,@pInterval				VARCHAR(20)
		,@pLength				INT
		,@pSSISFolder			VARCHAR(255)
		,@pSSISProject			VARCHAR(255)
		,@pSSISPackage			VARCHAR(255)
		,@pIsActive				BIT
		,@pTriggerType			VARCHAR(20)			= 'Immediate'
		,@pNextExecutionDtm		datetime			= '01-Jan-1900'
		,@pCreatedBy			VARCHAR(50)
		,@pETLExecutionId		INT					= -1
		,@pPathId				INT					= -1
		,@pVerbose				BIT					= 0
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
date      author         description
--------	-------------	---------------------------------------------------
20161020	ffortunato		adding process name to the postinggroup table.
20161122	jprom			updated parameter comments and added examples.
20180409	ffortunato		dusting off and preping for implementation.
20180906	ffortunato		code validation changes.
20200725	ochowkwale		parameters for NextExecutionDtm, TriggerType
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
		'***** Parameters Passed to exec pg.usp_InsertPostingGroup' + @CRLF +
		'     @pCode = '''			+ ISNULL(@pCode ,'NULL') + '''' + @CRLF + 
		'    ,@pName = '''			+ ISNULL(@pName ,'NULL') + '''' + @CRLF + 
		'    ,@pDesc = '''			+ ISNULL(@pDesc ,'NULL') + '''' + @CRLF + 
		'    ,@pCategory = '''		+ ISNULL(@pCategory ,'NULL') + '''' + @CRLF + 
		'    ,@pInterval = '''		+ ISNULL(@pInterval ,'NULL') + '''' + @CRLF + 
		'    ,@pLength = '			+ ISNULL(CAST(@pLength as varchar(100)),'NULL') + @CRLF + 
		'    ,@pSSISFolder = '''	+ ISNULL(@pSSISFolder ,'NULL') + '''' + @CRLF + 
		'    ,@pSSISProject = '''	+ ISNULL(@pSSISProject ,'NULL') + '''' + @CRLF + 
		'    ,@pSSISPackage = '''	+ ISNULL(@pSSISPackage ,'NULL') + '''' + @CRLF + 
		'    ,@pIsActive = '		+ ISNULL(CAST(@pIsActive as varchar(100)),'NULL') + @CRLF + 
		'    ,@pCreatedBy = '''		+ ISNULL(@pCreatedBy ,'NULL') + '''' + @CRLF + 
		'    ,@pETLExecutionId = '	+ ISNULL(CAST(@pETLExecutionId AS varchar(100)),'NULL') + @CRLF + 
		'    ,@pPathId = '			+ ISNULL(CAST(@pPathId as varchar(100)),'NULL') + @CRLF + 
		'    ,@pVerbose = '			+ ISNULL(CAST(@pVerbose as varchar(100)),'NULL') + @CRLF + 
		'***** End of Parameters' + @CRLF  

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
		,[PostingGroupCategory]
		,[IntervalCode]
		,[IntervalLength]
		,SSISFolder
		,SSISProject
		,SSISPackage
		,[IsActive]
		,[TriggerType]
		,[NextExecutionDtm]
		,[CreatedDtm]
		,CreatedBy
	) values (
		 @pCode
		,@pName
		,@pDesc
		,@pCategory
		,@pInterval
		,@pLength
		,@pSSISFolder	
		,@pSSISProject	
		,@pSSISPackage	
		,@pIsActive
		,@pTriggerType
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
