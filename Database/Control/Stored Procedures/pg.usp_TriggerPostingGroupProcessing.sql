CREATE PROCEDURE [pg].[usp_TriggerPostingGroupProcessing] 
(	 @pETLExecutionId					int	= -1
	,@pPathId							int = -1
	,@pVerbose							bit	= 0
)

AS
/*****************************************************************************
File:		pg.usp_TriggerPostingGroupProcessing.sql
Name:		pg.usp_TriggerPostingGroupProcessing
Purpose:	
Example:	exec pg.usp_TriggerPostingGroupProcessing -1,-1,0
Parameters:    
Called by:	
Calls:          
Errors:		
Author:		Omkar Chowkwale
Date:		20200221
*******************************************************************************
							CHANGE HISTORY
*******************************************************************************
Date		Author				Description
--------	-------------		--------------------------------
20200221	Omkar Chowkwale		Initial Iteration
20201118	ffortunato			removing warnings, calling SSIS proc

******************************************************************************/

-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------
DECLARE	 @Rows					varchar(10)		= 0
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
		,@CurrentUser			varchar(256)	= CURRENT_USER
		,@ProcessType			varchar(10)		= 'Proc'
		,@StepName				varchar(256)	= 'Start'
		,@StepOperation			varchar(50)		= 'N/A' 
		,@MessageType			varchar(20)		= 'Info' -- ErrCust, ErrSQL, Info, Warn
		,@StepDesc				nvarchar(2048)	= 'Procedure started' 
		,@StepStatus			varchar(10)		= 'Supgess'
		,@StepNumber			varchar(10)		= 0
		,@Duration				varchar(10)		= 0
		,@JSONSnippet			nvarchar(max)	= 'N/A'
		,@ServerName			VARCHAR(100)	= @@SERVERNAME
		,@ReferenceId			int				= -1
		,@SSISProject			VARCHAR(100)	= 'N/A'		
		,@SSISFolder			VARCHAR(100)	= 'N/A'		
		,@SSISPackage			VARCHAR(100)	= 'N/A'		
		,@ExecutingPostingGroupId int			= -1
		,@NextPGPBatchSeq		int				= -1
		,@pPGBId				int				= -1
		,@ExecutionId			int				= -1
		,@DataFactoryName		varchar(100)	= 'N/A'
		,@DataFactoryPipeline   varchar(100)	= 'N/A'
		,@TriggerProcess		varchar(10)		= 'N/A'
		,@SSISParameters		udt_SSISPackageParameters
		,@ObjectType			int				= 30 -- package parameter
		,@LoopCount				int				= -1
		,@MaxCount				int				= -1


declare  @ProcessQueue table (
		 Id						int identity(1,1)
		,PostingGroupBatchId	int
		,PostingGroupId			int
		,PGPBatchSeq			int
		,SSISFolder				varchar(250)
		,SSISProject			varchar(250)
		,SSISPackage			varchar(250)
		,TriggerProcess			varchar(250)
		,DataFactoryName		varchar(250)
		,DataFactoryPipeline	varchar(250))

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------
SELECT	 @ParametersPassedChar	= 
			'exec pg.usp_TriggerPostingGroupProcessing' + @CRLF +
			'    ,@pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
			'    ,@pPathId = ' + isnull(cast(@pPathId as varchar(100)),'NULL') + @CRLF + 
			'    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL')

IF @pVerbose					= 1
BEGIN 
	PRINT @ParametersPassedChar
END

-------------------------------------------------------------------------------
--  Log Procedure Start
-------------------------------------------------------------------------------
EXEC [audit].[usp_InsertStepLog]
		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  Main Code Block
-------------------------------------------------------------------------------
BEGIN TRY
	
	-------------------------------------------------------------------------------
	-- Create #ProcessQueue  - Start
	-------------------------------------------------------------------------------
	select	 @StepName			= 'Create #ProcessQueue'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Create Table'
			,@StepDesc			= 'Create #ProcessQueue'
	-------------------------------------------------------------------------------
	--DROP TABLE	IF EXISTS #ProcessQueue


	INSERT INTO @ProcessQueue(
		 PostingGroupBatchId
		,PostingGroupId
		,PGPBatchSeq
		,SSISFolder
		,SSISProject
		,SSISPackage
		,TriggerProcess
		,DataFactoryName
		,DataFactoryPipeline
	)
	SELECT pgp.PostingGroupBatchId
		,pgp.PostingGroupId
		,min(pgp.PGPBatchSeq) AS PGPBatchSeq
		,pgr.SSISFolder
		,pgr.SSISProject
		,pgr.SSISPackage
		,pgr.TriggerProcess
		,pgr.DataFactoryName
		,pgr.DataFactoryPipeline
--	INTO #ProcessQueue
	FROM pg.PostingGroupProcessing AS pgp
	INNER JOIN pg.RefStatus AS rs ON rs.StatusId = pgp.PostingGroupStatusId
	INNER JOIN pg.PostingGroup AS pgr ON pgr.PostingGroupId = pgp.PostingGroupId
	WHERE rs.StatusCode IN ('PQ')
	AND pgr.TriggerProcess IN ('SSIS','ADF')
	GROUP BY pgp.PostingGroupBatchId
		,pgp.PostingGroupId
		,pgr.SSISFolder
		,pgr.SSISProject
		,pgr.SSISPackage
		,pgr.TriggerProcess
		,pgr.DataFactoryName
		,pgr.DataFactoryPipeline
	-------------------------------------------------------------------------------
	--  Create #ProcessQueue - End
	-------------------------------------------------------------------------------
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose
	-------------------------------------------------------------------------------
	
	-------------------------------------------------------------------------------
	-- Execute SSIS  - Start
	-------------------------------------------------------------------------------
	select	 @StepName			= 'Execute SSIS'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Execute SSIS'
			,@StepDesc			= 'Execute SSIS'
	-------------------------------------------------------------------------------
	select @MaxCount = max(Id) from @ProcessQueue
	select @LoopCount = 1


	WHILE @LoopCount <= @MaxCount
	BEGIN
		SELECT	 @SSISProject				= SSISProject
				,@SSISPackage				= SSISPackage
				,@SSISFolder				= SSISFolder
				,@ExecutingPostingGroupId	= PostingGroupId
				,@NextPGPBatchSeq			= PGPBatchSeq
				,@pPGBId					= PostingGroupBatchId
				,@DataFactoryName			= DataFactoryName
				,@DataFactoryPipeline		= DataFactoryPipeline
				,@TriggerProcess			= TriggerProcess
		FROM	 @ProcessQueue
		where	 Id							= @LoopCount
/*
		DELETE
		FROM @ProcessQueue
		WHERE PostingGroupId = @ExecutingPostingGroupId
			AND PGPBatchSeq = @NextPGPBatchSeq
			AND PostingGroupBatchId = @pPGBId
*/
		IF (@TriggerProcess = 'SSIS')
		BEGIN TRY

			insert into	@SSISParameters values (@ObjectType,'pkg_PostingGroupId',		@ExecutingPostingGroupId)
			insert into	@SSISParameters values (@ObjectType,'pkg_PostingGroupBatchSeq',	@NextPGPBatchSeq)
			insert into	@SSISParameters values (@ObjectType,'pkg_PostingGroupBatchId',	@pPGBId)

			exec pg.usp_ExecuteSSISPackage 
					 @pSSISProject		= @SSISProject
					,@pServerName		= @ServerName
					,@pSSISFolder		= @SSISFolder
					,@pSSISPackage		= @SSISPackage
					,@pSSISParameters	= @SSISParameters
					,@pETLExecutionId	= @pETLExecutionId
					,@pPathId			= @pPathId
					,@pVerbose			= @pVerbose

/*
			SELECT @ReferenceId = isnull(er.reference_id, - 1)
			FROM [$(SSISDB)].catalog.environment_references er
			INNER JOIN [$(SSISDB)].catalog.projects prj ON er.project_id = prj.project_id
			WHERE prj.[name] = @SSISProject
				AND er.environment_name = @ServerName
				AND er.environment_folder_name = @SSISFolder
			
			EXEC [$(SSISDB)].catalog.create_execution @folder_name = @SSISFolder
				,@project_name = @SSISProject
				,@package_name = @SSISPackage
				,@reference_id = @ReferenceId
				,@execution_id = @ExecutionId OUTPUT

			EXEC [$(SSISDB)].[catalog].[set_execution_parameter_value] @execution_id = @ExecutionId
				,@object_type = 30
				,@parameter_name = 'pkg_PostingGroupId'
				,@parameter_value = @ExecutingPostingGroupId

			EXEC [$(SSISDB)].[catalog].[set_execution_parameter_value] @execution_id = @ExecutionId
				,@object_type = 30
				,@parameter_name = 'pkg_PostingGroupBatchSeq'
				,@parameter_value = @NextPGPBatchSeq --@CurPGPBatchSeq

			EXEC [$(SSISDB)].[catalog].[set_execution_parameter_value] @execution_id = @ExecutionId
				,@object_type = 30
				,@parameter_name = 'pkg_PostingGroupBatchId'
				,@parameter_value = @pPGBId

			EXEC [$(SSISDB)].[catalog].[start_execution] @execution_id = @ExecutionId
*/
		END TRY

		BEGIN CATCH
			SELECT 	 @PreviousDtm		= @CurrentDtm
					,@ErrNum			= @@ERROR
					,@ErrMsg			= ERROR_MESSAGE()
					,@Rows				= 0

			select	 @StepStatus		= 'Failure'
					,@CurrentDtm		= getdate()

			IF		 @MessageType		<> 'ErrCust'
				SELECT   @MessageType	= 'ErrSQL'

			EXEC [audit].usp_InsertStepLog
					 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
					,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
					,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
					,@pVerbose
			CONTINUE
		END CATCH

		IF(@TriggerProcess = 'ADF')
		BEGIN
			EXEC ctl.usp_TriggerDataFactory
					 @pDataFactoryName		 = @DataFactoryName
					,@pDataFactoryPipeline	 = @DataFactoryPipeline
		END

		select @LoopCount					 = @LoopCount + 1

	END -- While Loop

	-------------------------------------------------------------------------------
	--  Execute SSIS - End
	-------------------------------------------------------------------------------
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose
	-------------------------------------------------------------------------------
		
END TRY

-------------------------------------------------------------------------------
--  Error Handling
-------------------------------------------------------------------------------
BEGIN CATCH

	SELECT 	 @PreviousDtm		= @CurrentDtm
			,@ErrNum			= @@ERROR
			,@ErrMsg			= ERROR_MESSAGE()
			,@Rows				= 0

	select	 @StepStatus		= 'Failure'
			,@CurrentDtm		= getdate()

	IF		 @MessageType		<> 'ErrCust'
		SELECT   @MessageType	= 'ErrSQL'

	EXEC [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	IF 	@ErrNum < 50000	
		SELECT	 @ErrNum	= @ErrNum + 100000000 -- Need to increase number to throw message.

	;THROW	 @ErrNum, @ErrMsg, 1
	
END CATCH

-------------------------------------------------------------------------------
--  Log Procedure End
-------------------------------------------------------------------------------
SELECT 	 @PreviousDtm			= @CurrentDtm
		,@CurrentDtm			= getdate()
		,@StepNumber			= @StepNumber + 1
		,@StepName				= 'End'
		,@StepDesc				= 'Procedure completed'
		,@Rows					= 0
		,@StepOperation			= 'N/A'

-- Passing @ProcessStartDtm so the total duration for the procedure is added.
-- @ProcessStartDtm (if you want total duration) 
-- @PreviousDtm (if you want 0)
EXEC	[audit].usp_InsertStepLog
		 @MessageType ,@CurrentDtm ,@ProcessStartDtm ,@StepNumber ,@StepOperation ,@JSONSnippet ,@ErrNum
		,@ParametersPassedChar, @ErrMsg OUTPUT, @ParentStepLogId ,@ProcName, @ProcessType ,@StepName
		,@StepDesc OUTPUT, @StepStatus, @DbName, @Rows, @pETLExecutionId ,@pPathId, @PrevStepLog output
		,@pVerbose
------------------------------------------------------