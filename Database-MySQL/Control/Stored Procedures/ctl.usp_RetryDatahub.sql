CREATE PROCEDURE [ctl].[usp_RetryDatahub] (
	 @pETLExecutionId					int				= -1
	,@pPathId							int				= -1
	,@pVerbose							bit				= 0)
AS
/*****************************************************************************
File:		usp_RetryDatahub.sql
Name:		usp_RetryDatahub
Purpose:	Will do the retries for failed staging and failed Posting Group loads
Example:	exec ctl.usp_RetryDatahub -1, -1, 0
Parameters: 
Called by:	
Calls:      
			pg.usp_ExecuteProcess	- To execute the process
			audit.usp_InsertStepLog - To log activity
Errors:		
Author:		Omkar Chowkwale
Date:		2019-06-04
******************************************************************************/


-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------
DECLARE	 @Rows					int		= 0
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
		,@CurrentUser			varchar(50)		= CURRENT_USER
		,@ServerName			varchar(255)	= @@SERVERNAME
		,@ProcessType			varchar(10)		= 'Proc'
		,@StepName				varchar(256)	= 'Start'
		,@StepOperation			varchar(50)		= 'N/A' 
		,@MessageType			varchar(20)		= 'Info' -- ErrCust, ErrSQL, Info, Warn
		,@StepDesc				nvarchar(2048)	= 'Procedure started' 
		,@StepStatus			varchar(10)		= 'Success'
		,@StepNumber			varchar(10)		= 0
		,@SubStepNumber			varchar(23)		= 0
		,@Duration				varchar(10)		= 0
		,@JSONSnippet			nvarchar(max)	= NULL
		,@IssueId				int				= -1
		,@RetryFlag				int				= -1
		,@IsFailure				int				= -1
		,@DestTblName			varchar(255)
		,@Running				int				= 2
		,@ProcessingMethodCode	varchar(20)		= 'UNK'
		,@IsDataHub				int				= -1
		,@DataFactoryName		varchar(255)	= 'N/A'
		,@DataFactoryPipeline	varchar(255)	= 'N/A'
		,@DataFactoryStatus		varchar(255)	= 'N/A'
		,@IssuePrepared			varchar(10)		= 'IP'
		,@IssueStaged			varchar(10)		= 'IS'
		,@IssueRetry			varchar(10)		= 'IR'
		,@IssueFailed			varchar(10)		= 'IF'
		,@SSISFolder			varchar(255)	= 'N/A'     
		,@SSISProject			varchar(255)	= 'N/A'
		,@SSISPackage			varchar(255)	= 'N/A'
		,@ExecutionId			int				= -1
		,@ReferenceId			int				= -1
		,@SSISParameters		pg.udt_SSISPackageParameters
		,@ObjectType			int				= 30 -- package parameter
		,@LoopCount				int				= -1
		,@MaxCount				int				= -1
		,@IsProcessed			bit				= 0
		,@ExecuteProcessStatus	varchar(20)		= 'IRF'
		,@AllowMultipleInstances bit			= 0 -- Do not allow multiple instances to run.

declare @Issue table (
		 Id						int identity(1,1)
		,IssueId				int					NOT NULL
		,DestTableName			varchar(255)		NOT NULL
		,SSISFolder				varchar(255)		NOT NULL
		,SSISProject			varchar(255)		NOT NULL
		,SSISPackage			varchar(255)		NOT NULL
		,DataFactoryName		varchar(255)		NOT NULL
		,DataFactoryPipeline	varchar(255)		NOT NULL
		,RetryFlag				int					NOT NULL
		,FailureFlag			int					NOT NULL
		,ProcessingMethodCode	varchar(20)			NOT NULL
		,IsDataHub				int					NOT NULL
		,IsProcessed			bit					NOT NULL)
-------------------------------------------------------------------------------
--  Display Verbose
-------------------------------------------------------------------------------
SELECT	 @ParametersPassedChar	= 
			'exec BPI_DW_STAGE.ctl.usp_RetryDatahub' + @CRLF +
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
exec	[audit].[usp_InsertStepLog]
		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  Main Code Block
-------------------------------------------------------------------------------
begin try
	---------------------------------------------------------------------------------
	----  Update Issue records in status of 'IP' or 'IS' to 'IR'
	---------------------------------------------------------------------------------
	--select	 @StepName			= 'Update IssueIds to status IR'
	--		,@StepNumber		= @StepNumber + 1
	--		,@StepOperation		= 'Update'
	--		,@StepDesc			= 'Update Issue records to status of Retry'
	---------------------------------------------------------------------------------	
	--UPDATE	 i
	--SET		 i.StatusId		= rs.StatusId
	--		,i.ModifiedBy	= @CurrentUser
	--		,i.ModifiedDtm	= @CurrentDtm
	--FROM ctl.Issue i
	--INNER JOIN (
	--	SELECT max(IssueId) AS IssueId
	--		,PublicationId
	--	FROM ctl.Issue
	--	GROUP BY PublicationId
	--	) AS m ON m.IssueId = i.IssueId
	--LEFT JOIN ctl.RefStatus r ON i.StatusId = r.StatusId
	--LEFT JOIN ctl.RefStatus rs ON rs.StatusCode = @IssueRetry
	--LEFT JOIN ctl.Publication p ON m.PublicationId = p.PublicationId
	--LEFT JOIN [$(SSISDB)].[catalog].executions AS e ON e.project_name = p.SSISProject
	--	AND e.package_name = p.SSISPackage
	--	AND e.folder_name = p.SSISFolder
	--	AND e.[status] = @Running
	--WHERE r.StatusCode IN (	@IssuePrepared,@IssueStaged)
	--	AND p.IsActive = 1
	--	AND p.IsDataHub IN (1,2)
	--	AND p.RetryMax <> 0
	--	AND e.execution_id IS NULL
	--	AND DATEDIFF(mi, i.ModifiedDtm, GETDATE()) > ctl.fn_GetIntervalInMinutes(p.RetryIntervalLength, p.RetryIntervalCode, - 1, - 1, 0)

	---------------------------------------------------------------------------------
	----  Update Issue records in status of 'IP' or 'IS' to 'IR' - End
	---------------------------------------------------------------------------------
	--select	 @PreviousDtm		= @CurrentDtm
	--		,@Rows				= @@ROWCOUNT 
	--select	 @CurrentDtm		= getdate()

	--exec	[audit].usp_InsertStepLog
	--		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
	--		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
	--		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
	--		,@pVerbose
	---------------------------------------------------------------------------------

	-------------------------------------------------------------------------------
	--  Select Issue Records in status of 'IR' and fire off staging for each
	-------------------------------------------------------------------------------
	select	 @StepName			= 'Insert IRs, checks for execution, Execute'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'insert'
			,@StepDesc			= 'Insert IRs, checks for execution, Execute'
	-------------------------------------------------------------------------------
	--Find whether Issue needs to be retried and whether it needs to be failed
	insert into @Issue(
		IssueId
		,DestTableName	
		,SSISFolder		
		,SSISProject	
		,SSISPackage	
		,DataFactoryName	
		,DataFactoryPipeline
		,RetryFlag			
		,FailureFlag	
		,ProcessingMethodCode
		,IsDataHub
		,IsProcessed			)

	SELECT i.IssueId
		,p.DestTableName
		,p.SSISFolder
		,p.SSISProject
		,p.SSISPackage
		,p.DataFactoryName
		,p.DataFactoryPipeline
		,RetryFlag = CASE 
			WHEN DATEDIFF(mi, i.ModifiedDtm, @CurrentDtm) > ctl.fn_GetIntervalInMinutes(p.RetryIntervalLength, p.RetryIntervalCode, - 1, - 1, 0)
				THEN 1
			ELSE 0
			END
		,FailureFlag = CASE 
			WHEN (i.RetryCount >= p.RetryMax) OR (DATEADD(mi,SLAEndTimeInMinutes,i.CreatedDtm) < @CurrentDtm)
				THEN 1
			ELSE 0
			END
		,p.ProcessingMethodCode
		,p.IsDataHub
		,@IsProcessed
	FROM	 ctl.Issue			   i
	JOIN	 ctl.RefStatus		   rs 
	ON		 rs.StatusId		 = i.StatusId
	JOIN	 ctl.Publication	   p 
	ON		 p.PublicationId	 = i.PublicationId
	WHERE	 rs.StatusCode		 = @IssueRetry

	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			,@JSONSnippet		= ''	

	exec audit.usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	select	 @LoopCount			 = 1
	select	 @MaxCount			 = count(*) FROM @Issue

	--Loop through individual IssueID
	while	 @LoopCount <= @MaxCount
	BEGIN
		SELECT	 @IssueId			 = IssueId
				,@DestTblName		 = DestTableName
				,@SSISFolder		 = SSISFolder
				,@SSISProject		 = SSISProject
				,@SSISPackage		 = SSISPackage
				,@DataFactoryName	 = DataFactoryName
				,@DataFactoryPipeline = DataFactoryPipeline
				,@RetryFlag			 = RetryFlag
				,@IsFailure			 = FailureFlag
				,@ProcessingMethodCode = ProcessingMethodCode
				,@IsDataHub			 = IsDataHub
				,@IsProcessed		 = IsProcessed
		FROM	 @Issue --#IssueId
		WHERE	 Id = @LoopCount

		IF(@RetryFlag = 1 AND @IsFailure = 0)
		BEGIN
			select	 @StepName			= 'Executing Process.'
					,@StepNumber		= @StepNumber + 0
					,@SubStepNumber     = @StepNumber + '.' + cast(@LoopCount as varchar(10)) + '.1'
					,@StepOperation		= 'execute'
					,@StepDesc			= 'Execute the process associated with the IssueId: ' + isnull(cast(@IssueId as varchar(10)),'NULL')+ '.'

			exec	[pg].[usp_ExecuteProcess]
					 @pPostingGroupProcessingId				= -1 -- No posting group processing record needed.
					,@pIssueId								= @IssueId
					,@pAllowMultipleInstances				= @AllowMultipleInstances
					,@pExecuteProcessStatus					= @ExecuteProcessStatus output

			select	 @PreviousDtm		= @CurrentDtm
					,@Rows				= @@ROWCOUNT 
			select	 @CurrentDtm		= getdate()
					,@JSONSnippet		= '{"@pPostingGroupProcessingId":"'+ cast(-1 as varchar(20))  + '",'
										+  '"@pIssueId":"'+ cast(@IssueId as varchar(20))  + '"}' 	

			exec audit.usp_InsertStepLog
					 @MessageType		,@CurrentDtm	,@PreviousDtm	,@SubStepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
					,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
					,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
					,@pVerbose

			select	 @JSONSnippet		= ''

			IF(@ExecuteProcessStatus <> 'ISS') -- If the run did not succeed log a retry. Instance Start Success
			BEGIN
				--Update the retry count for all IssueIds that needs to be retried
				UPDATE	 i
				SET		 RetryCount		= RetryCount + 1
						,ModifiedBy		= @CurrentUser
						,ModifiedDtm	= @CurrentDtm
				FROM	 ctl.Issue		  i
				WHERE	 IssueId		= @IssueId		
			END -- IF(@ExecuteProcessStatus <> 'ISS') 
		END--(@RetryFlag = 1 AND @IsFailure = 0)


		IF(@IsFailure = 1)
		BEGIN
			--Update to IF
			EXEC ctl.usp_UpdateIssue @IssueId,@IssueFailed
		END

		UPDATE	 @Issue
		SET		 IsProcessed	= 1
		WHERE	 IssueId		= @IssueId

		select	 @LoopCount		= @LoopCount + 1
	END 	-- while
	
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

	exec	[audit].usp_InsertStepLog
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

exec	[audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
		,@pVerbose
-------------------------------------------------------------------------------

/******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20201022	Omkar Chowkwale	Initial Iteration
20201118	ffortunato		removing warnings
20201119	ffortunato		changing from temp table to table variable and
							and chinging looping strategy.
20210413	ffortunato		Replacing IsDataHub with ProcessingMethod.
20210416	ffortunato		Moved Is Process Running checks to 
							usp_ExecuteProces --> Usp_ExecuteSSIS 
							and usp_ExecuteDataFacotry
******************************************************************************/

