CREATE PROCEDURE [pg].[usp_RetryPostingGroup] (
	@pETLExecutionId					int				= -1
	,@pPathId							int				= -1
	,@pVerbose							bit				= 0)
AS
/*****************************************************************************
File:		usp_RetryPostingGroup.sql
Name:		usp_RetryPostingGroup
Purpose:	Will do the retries for failed staging and failed Posting Group loads
Example:	exec pg.usp_RetryPostingGroup -1, -1, 0
Parameters: 
Called by:	
Calls:      
Errors:		
Author:		Omkar Chowkwale
Date:		2019-06-04
*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
----------	-------------	---------------------------------------------------
2020-10-22	Omkar Chowkwale	Initial Iteration
20201118	ffortunato		cleaning up warnings. calling SSIS exec proc.
20201119	ffortunato		cleaning up temp tables and making table variables.

******************************************************************************/

-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------
DECLARE	 @Rows					varchar(10)		= 0
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
		,@DbName				varchar(256)	= DB_NAME()
		,@CurrentUser			varchar(256)	= CURRENT_USER
		,@ServerName			varchar(256)	= @@SERVERNAME
		,@ProcessType			varchar(10)		= 'Proc'
		,@StepName				varchar(256)	= 'Start'
		,@StepOperation			varchar(50)		= 'N/A' 
		,@MessageType			varchar(50)		= 'Info' -- ErrCust, ErrSQL, Info, Warn
		,@StepDesc				nvarchar(max)	= 'Procedure started' 
		,@StepStatus			varchar(10)		= 'Success'
		,@StepNumber			varchar(10)		= 0
		,@Duration				varchar(10)		= 0
		,@JSONSnippet			nvarchar(max)	= NULL
		,@PostingGroupProcessingId				int
		,@RetryFlag				int
		,@FailureFlag			int
		,@destTblName			varchar(100)
		,@SSISFolder			varchar(100)
		,@SSISProject			varchar(50)
		,@SSISPackage			varchar(50)
		,@ReferenceId			int
		,@ExecutionId			int
		,@running				int				= 2
		,@TriggerProcess		varchar(50)
		,@DataFactoryName		varchar(50)
		,@DataFactoryPipeline	varchar(50)
		,@ExecutingPostingGroupId int
		,@ExecutingPostingGroupBatchSeq int
		,@ExecutingPostingGroupBatchId int
		,@SSISParameters		udt_SSISPackageParameters
		,@ObjectType			int				= 30 -- package parameter
		,@LoopCount				int				= -1
		,@MaxLoop				int				= -1
		,@PostingGroupFailed	varchar(10)		= 'PF'


declare @PostingGroupProcessing table (
		 Id							int identity (1,1)
		,PostingGroupProcessingId	bigint
		,PostingGroupBatchId		int 
		,PostingGroupId				int 
		,PGPBatchSeq				int 
		,SSISFolder					varchar(250)
		,SSISProject				varchar(250)
		,SSISPackage				varchar(250)
		,DataFactoryName			varchar(250)
		,DataFactoryPipeline		varchar(250)
		,RetryFlag					int
		,FailureFlag				int
		,TriggerProcess				varchar(100))
	

-------------------------------------------------------------------------------
--  Display Verbose
-------------------------------------------------------------------------------
SELECT	 @ParametersPassedChar	= 
			'exec Control.pg.usp_RetryPostingGroup' + @CRLF +
			'    ,@pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
			'    ,@pPathId = ' + isnull(cast(@pPathId as varchar(100)),'NULL') + @CRLF + 
			'    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL')

if @pVerbose					= 1
	begin 
		print @ParametersPassedChar
	end

-------------------------------------------------------------------------------
--  Log Procedure Start
-------------------------------------------------------------------------------
exec [audit].[usp_InsertStepLog]
		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  Main Code Block
-------------------------------------------------------------------------------
begin try
	-------------------------------------------------------------------------------
	--  Update Posting Group records in status of 'PQ' or 'PP' to 'PR'
	-------------------------------------------------------------------------------
	select	 @StepName			= 'Update PostingGroupProcessingIds to status PR'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Update'
			,@StepDesc			= 'Update PostingGroupProcessing records to status of Retry'
	-------------------------------------------------------------------------------	
	UPDATE pgp
	SET pgp.PostingGroupStatusId	= rs.StatusId
		,pgp.ModifiedBy				= @CurrentUser
		,pgp.ModifiedDtm			= @CurrentDtm
	FROM pg.PostingGroupProcessing as pgp
	INNER JOIN (
		SELECT max(PostingGroupProcessingId) AS PostingGroupProcessingId
			,PostingGroupId
		FROM pg.PostingGroupProcessing
		GROUP BY PostingGroupId
		) AS m ON m.PostingGroupProcessingId = pgp.PostingGroupProcessingId
	LEFT JOIN pg.RefStatus AS r ON pgp.PostingGroupStatusId = r.StatusId
	LEFT JOIN pg.RefStatus AS rs on rs.StatusCode = 'PR'
	LEFT JOIN pg.PostingGroup AS p ON m.PostingGroupId = p.PostingGroupId
	WHERE r.StatusCode IN ('PQ','PP')
		AND p.IsActive = 1
		AND p.TriggerProcess IN ('SSIS','ADF')
		AND p.RetryMax <> 0
		AND DATEDIFF(mi, pgp.ModifiedDtm, @CurrentDtm) > ctl.fn_GetIntervalInMinutes(p.RetryIntervalLength, p.RetryIntervalCode, - 1, - 1, 0)

	-------------------------------------------------------------------------------
	--  Update PostingGroupProcessing records in status of 'IP' or 'IS' to 'PR' - End
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
	--  Select PostingGroupProcessing Records in status of 'PR' and fire off staging for each
	-------------------------------------------------------------------------------
	select	 @StepName			= 'Select PR, checks for execution, Execute'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Select'
			,@StepDesc			= 'Select PR, checks for execution, Execute'
	-------------------------------------------------------------------------------
	--Find whether PostingGroupProcessing needs to be retried and whether it needs to be failed
	
	--DROP TABLE IF EXISTS #PostingGroupProcessingId

	
	INSERT	INTO @PostingGroupProcessing(
		 PostingGroupProcessingId
		,PostingGroupBatchId
		,PostingGroupId	
		,PGPBatchSeq
		,SSISFolder
		,SSISProject
		,SSISPackage
		,DataFactoryName
		,DataFactoryPipeline
		,RetryFlag
		,FailureFlag
		,TriggerProcess
	)
	SELECT pgp.PostingGroupProcessingId
		,pgp.PostingGroupBatchId
		,pgp.PostingGroupId
		,pgp.PGPBatchSeq
		,p.SSISFolder
		,p.SSISProject
		,p.SSISPackage
		,p.DataFactoryName
		,p.DataFactoryPipeline
		,RetryFlag = CASE 
			WHEN DATEDIFF(mi, pgp.ModifiedDtm, @CurrentDtm) > ctl.fn_GetIntervalInMinutes(p.RetryIntervalLength, p.RetryIntervalCode, - 1, - 1, 0)
				THEN 1
			ELSE 0
			END
		,FailureFlag = CASE 
			WHEN (pgp.RetryCount >= p.RetryMax)
				OR (STUFF(CONVERT(VARCHAR(50), @CurrentDtm, 20), LEN(CONVERT(VARCHAR(50), @CurrentDtm, 20)) - LEN(RTRIM(LTRIM(SLAEndTime))) + 1, LEN(RTRIM(LTRIM(SLAEndTime))), RTRIM(LTRIM(SLAEndTime))) < @CurrentDtm)
				THEN 1
			ELSE 0
			END
		,p.TriggerProcess
	FROM pg.PostingGroupProcessing AS pgp
	INNER JOIN pg.RefStatus AS rs 
	ON rs.StatusId = pgp.PostingGroupStatusId
	INNER JOIN pg.PostingGroup AS p 
	ON p.PostingGroupId = pgp.PostingGroupId
	WHERE rs.StatusCode = 'PR'

	--Loop through individual PostingGroupProcessingID

	select @MaxLoop = max(Id) from @PostingGroupProcessing
	select @LoopCount = 1

	while @LoopCount <= @MaxLoop
	BEGIN
		SELECT 
				 @PostingGroupProcessingId		 = PostingGroupProcessingId
				,@ExecutingPostingGroupId		 = PostingGroupId
				,@ExecutingPostingGroupBatchSeq	 = PGPBatchSeq
				,@ExecutingPostingGroupBatchId	 = PostingGroupBatchId
				,@SSISFolder					 = SSISFolder
				,@SSISProject					 = SSISProject
				,@SSISPackage					 = SSISPackage
				,@DataFactoryName				 = DataFactoryName
				,@DataFactoryPipeline			 = DataFactoryPipeline
				,@RetryFlag						 = RetryFlag
				,@FailureFlag					 = FailureFlag
				,@TriggerProcess				 = TriggerProcess
		FROM	 @PostingGroupProcessing
		WHERE	 Id								 = @LoopCount

		IF(@RetryFlag = 1 AND @FailureFlag = 0)
		BEGIN
			
			IF(@TriggerProcess = 'SSIS')
			BEGIN

				IF NOT EXISTS(select 1 from [$(SSISDB)].catalog.executions where server_name = @ServerName AND folder_name = @SSISFolder AND project_name = @SSISProject AND package_name = @SSISPackage AND status = @running)
				BEGIN

					insert into	@SSISParameters values (@ObjectType,'pkg_PostingGroupId',		@ExecutingPostingGroupId)
					insert into	@SSISParameters values (@ObjectType,'pkg_PostingGroupBatchSeq',	@ExecutingPostingGroupBatchSeq)
					insert into	@SSISParameters values (@ObjectType,'pkg_PostingGroupBatchId',	@ExecutingPostingGroupBatchId)

					exec pg.usp_ExecuteSSISPackage 
							 @pSSISProject		= @SSISProject
							,@pServerName		= @ServerName
							,@pSSISFolder		= @SSISFolder
							,@pSSISPackage		= @SSISPackage
							,@pSSISParameters	= @SSISParameters
							,@pETLExecutionId	= @pETLExecutionId
							,@pPathId			= @pPathId
							,@pVerbose			= @pVerbose

					select	 @PreviousDtm		= @CurrentDtm
							,@Rows				= @@ROWCOUNT 
					select	 @CurrentDtm		= getdate()
							,@JSONSnippet		= '{"@SSISFolder":"'	+ @SSISFolder  + '",'
												+  '"@SSISProject":"'	+ @SSISProject + '",'
												+  '"@SSISPackage":"'	+ @SSISPackage + '",'
												+  '"@PostingGroupBatchId":"'	+ cast(@ExecutingPostingGroupBatchId as varchar(20)) + '",'
												+  '"@PGPBatchSeq":"'	+ cast(@ExecutingPostingGroupBatchSeq as varchar(20)) + '",'
												+  '"@ExecutingPostingGroupId Parent":"'+ cast(@ExecutingPostingGroupId as varchar(20))  + '",'
												+  '"@ExecutionId":"'	+ cast(@ExecutionId as varchar(20)) + '",'
												+  '"@ReferenceId":"'	+ cast(@ReferenceId as varchar(20))+ '"}' 	

				/*
					--FIRE ETL STEPS
					--1) Get the reference id
					SELECT TOP 1 @ref_id = reference_id
					FROM		 [$(SSISDB)].catalog.environment_references a
					INNER JOIN	 [$(SSISDB)].catalog.projects b 
					ON			 a.project_id			 = b.project_id
					WHERE		 [name]					 = @project
					AND			 environment_name		 = @@SERVERNAME
					AND			 environment_folder_name = @folder

					--2)Create the SSIS execution
					EXEC [$(SSISDB)].catalog.create_execution @folder, @project, @package, @ref_id, 0, NULL, 1, @execution_id OUTPUT
				
					--3) Set Execution parameter value
					EXEC [$(SSISDB)].[catalog].[set_execution_parameter_value] 
						 @execution_id				=  @execution_id
						,@object_type				= 30
						,@parameter_name			= 'pkg_PostingGroupId'
						,@parameter_value			= @ExecutingPostingGroupId

					--4) Set Execution parameter value
					EXEC [$(SSISDB)].[catalog].[set_execution_parameter_value] 
						 @execution_id				=  @execution_id
						,@object_type				= 30
						,@parameter_name			= 'pkg_PostingGroupBatchSeq'
						,@parameter_value			= @ExecutingPostingGroupBatchSeq

					--5) Set Execution parameter value
					EXEC [$(SSISDB)].[catalog].[set_execution_parameter_value] 
						 @execution_id				=  @execution_id
						,@object_type				= 30
						,@parameter_name			= 'pkg_PostingGroupBatchId'
						,@parameter_value			= @ExecutingPostingGroupBatchId

					--6) Start execution
					EXEC [$(SSISDB)].catalog.start_execution @execution_id
				*/
				END
			END

			IF(@TriggerProcess = 'ADF')
			BEGIN
				EXEC ctl.usp_TriggerDataFactory 
					 @pDataFactoryName		 = @DataFactoryName
					,@pDataFactoryPipeline	 = @DataFactoryPipeline
			END

			--Update the retry count for all PostingGroupProcessingIds that needs to be retried
			UPDATE pgp
			SET  RetryCount		 = RetryCount + 1
				,ModifiedBy		 = @CurrentUser
				,ModifiedDtm	 = @CurrentDtm
			FROM pg.PostingGroupProcessing AS pgp
			WHERE PostingGroupProcessingId = @PostingGroupProcessingId			
		END


		IF(@FailureFlag = 1)
		BEGIN
			--Update to IF

			EXEC pg.UpdatePostingGroupProcessingStatus 
				 @pPostingGroupBatchId		= @ExecutingPostingGroupBatchId
				,@pPostingGroupId			= @ExecutingPostingGroupId
				,@pPostingGroupBatchSeq		= @ExecutingPostingGroupBatchSeq
				,@pPostingGroupStatusCode	= @PostingGroupFailed
		END

		select @LoopCount					= @LoopCount + 1

	END -- WHILE

	-------------------------------------------------------------------------------
	--  Select PostingGroupProcessing Records in status of 'PR' and fire off staging for each - End
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
		
end try

-------------------------------------------------------------------------------
--  Error Handling
-------------------------------------------------------------------------------
begin catch

	select 	 @PreviousDtm		= @CurrentDtm
			,@ErrNum			= @@ERROR
			,@ErrMsg			= ERROR_MESSAGE()

	select	 @StepStatus		= 'Failure'
			,@Rows				= @@ROWCOUNT
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
		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
		,@pVerbose
-------------------------------------------------------------------------------
