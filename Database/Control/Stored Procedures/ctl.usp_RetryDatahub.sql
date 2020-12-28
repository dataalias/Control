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
Errors:		
Author:		Omkar Chowkwale
Date:		2019-06-04
*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
----------	-------------	---------------------------------------------------
2020-10-22	Omkar Chowkwale	Initial Iteration
20201118	ffortunato		removing warnings
20201119	ffortunato		changing from temp table to table variable and
							and chinging looping strategy.

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
		,@IssueId				int
		,@RetryFlag				int
		,@FailureFlag			int
		,@destTblName			varchar(100)
		/*
		,@folder				varchar(100)
		,@project				varchar(50)
		,@package				varchar(50)
		,@ref_id				int				= -1
		,@execution_id			int				= -1	
		*/
		,@Running				int				= 2
		,@IsDataHub				int				= -1
		,@DataFactoryName		varchar(50)		= 'N/A'
		,@DataFactoryPipeline	varchar(50)		= 'N/A'
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

declare @Issue table (
		 Id						int identity(1,1)
		,IssueId				int
		,DestTableName			varchar(100)
		,SSISFolder				varchar(100)
		,SSISProject			varchar(100)
		,SSISPackage			varchar(100)
		,DataFactoryName		varchar(100)
		,DataFactoryPipeline	varchar(100)
		,RetryFlag				int
		,FailureFlag			int
		,IsDataHub				int )
-------------------------------------------------------------------------------
--  Display Verbose
-------------------------------------------------------------------------------
SELECT	 @ParametersPassedChar	= 
			'exec Control.ctl.usp_RetryDatahub' + @CRLF +
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
	-------------------------------------------------------------------------------
	--  Update Issue records in status of 'IP' or 'IS' to 'IR'
	-------------------------------------------------------------------------------
	select	 @StepName			= 'Update IssueIds to status IR'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Update'
			,@StepDesc			= 'Update Issue records to status of Retry'
	-------------------------------------------------------------------------------	
	UPDATE	 i
	SET		 i.StatusId		= rs.StatusId
			,i.ModifiedBy	= @CurrentUser
			,i.ModifiedDtm	= @CurrentDtm
	FROM	 ctl.Issue		  i
	INNER JOIN (
		SELECT max(IssueId) AS IssueId
			,PublicationId
		FROM ctl.Issue
		GROUP BY PublicationId
		) AS m 
	ON			m.IssueId		= i.IssueId
	LEFT JOIN	ctl.RefStatus	  r 
	ON			i.StatusId		= r.StatusId
	LEFT JOIN	ctl.RefStatus	  rs 
	ON			rs.StatusCode	= @IssueRetry
	LEFT JOIN	ctl.Publication   p 
	ON			m.PublicationId = p.PublicationId
	WHERE		r.StatusCode	IN (@IssuePrepared, @IssueStaged)
	AND			p.IsActive		= 1
	AND			p.IsDataHub		IN (1,2)
	AND			p.RetryMax		<> 0
	AND			DATEDIFF(mi, i.ModifiedDtm, @CurrentDtm) > ctl.fn_GetIntervalInMinutes(p.RetryIntervalLength, p.RetryIntervalCode, - 1, - 1, 0)

	-------------------------------------------------------------------------------
	--  Update Issue records in status of 'IP' or 'IS' to 'IR' - End
	-------------------------------------------------------------------------------
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()

	exec	[audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose
	-------------------------------------------------------------------------------

	-------------------------------------------------------------------------------
	--  Select Issue Records in status of 'IR' and fire off staging for each
	-------------------------------------------------------------------------------
	select	 @StepName			= 'Select IRs, checks for execution, Execute'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Select'
			,@StepDesc			= 'Select IRs, checks for execution, Execute'
	-------------------------------------------------------------------------------
	--Find whether Issue needs to be retried and whether it needs to be failed
--	DECLARE @CurrentDtm datetime = getdate()
	
--	DROP TABLE IF EXISTS #IssueId


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
		,IsDataHub			)
	SELECT i.IssueId
		,p.DestTableName
		,p.SSISFolder
		,p.SSISProject
		,p.SSISPackage
		,p.DataFactoryName
		,p.DataFactoryPipeline
		,/*RetryFlag =*/ CASE 
			WHEN DATEDIFF(mi, i.ModifiedDtm, @CurrentDtm) > ctl.fn_GetIntervalInMinutes(p.RetryIntervalLength, p.RetryIntervalCode, - 1, - 1, 0)
				THEN 1
			ELSE 0
			END
		,/*FailureFlag =*/ CASE 
			WHEN (i.RetryCount >= p.RetryMax)
				--CurrentDtm < SLAEndTime
				OR (STUFF(CONVERT(VARCHAR(50), @CurrentDtm, 20), LEN(CONVERT(VARCHAR(50), @CurrentDtm, 20)) - LEN(RTRIM(LTRIM(SLAEndTime))) + 1, LEN(RTRIM(LTRIM(SLAEndTime))), RTRIM(LTRIM(SLAEndTime))) < @CurrentDtm)
				THEN 1
			ELSE 0
			END
		,p.IsDataHub
--	INTO #IssueId
	FROM	 ctl.Issue			   i
	JOIN	 ctl.RefStatus		   rs 
	ON		 rs.StatusId		 = i.StatusId
	JOIN	 ctl.Publication	   p 
	ON		 p.PublicationId	 = i.PublicationId
	WHERE	 rs.StatusCode		 = @IssueRetry

	select	 @LoopCount			 = 1
	select	 @MaxCount			 = count(*) FROM @Issue

	--Loop through individual IssueID
	while	 @LoopCount <= @MaxCount
	BEGIN
		SELECT	 @IssueId			 = IssueId
				,@destTblName		 = DestTableName
				,@SSISFolder		 = SSISFolder
				,@SSISProject		 = SSISProject
				,@SSISPackage		 = SSISPackage
				,@DataFactoryName	 = DataFactoryName
				,@DataFactoryPipeline = DataFactoryPipeline
				,@RetryFlag			 = RetryFlag
				,@FailureFlag		 = FailureFlag
				,@IsDataHub			 = IsDataHub
		FROM	 @Issue --#IssueId
		WHERE	 Id = @LoopCount

		IF(@RetryFlag = 1 AND @FailureFlag = 0)
		BEGIN
			
			IF(@IsDataHub = 1)
			BEGIN
				IF NOT EXISTS(select 1 from [$(SSISDB)].catalog.executions where server_name = @ServerName AND folder_name = @SSISFolder AND project_name = @SSISProject AND package_name = @SSISPackage AND status = @Running)
				BEGIN

					insert into	@SSISParameters values (@ObjectType,'pkg_IssueId',	@IssueId)

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
												+  '"@IssueId":"'	+ cast(@IssueId as varchar(20)) + '"}' 

/*
					--FIRE ETL STEPS
					--1) Get the reference id
					SELECT TOP 1 @ref_id = reference_id
					FROM		 [$(SSISDB)].catalog.environment_references a
					INNER JOIN	 [$(SSISDB)].catalog.projects b
					ON			 a.project_id		 = b.project_id
					WHERE		 [name]				 = @project
					AND			 environment_name	 = @ServerName
					AND			 environment_folder_name = @folder

					--2)Create the SSIS execution
					EXEC [$(SSISDB)].catalog.create_execution @folder, @project, @package, @ref_id, 0, NULL, 1, @execution_id OUTPUT
				
					--3) Set Execution parameter value
					EXEC [$(SSISDB)].catalog.set_execution_parameter_value @execution_id, 30, "pkg_IssueId", @IssueId

					--4) Start execution
					EXEC [$(SSISDB)].catalog.start_execution @execution_id
*/
				END
			END

			IF(@IsDataHub = 2)
			BEGIN
				EXEC ctl.usp_TriggerDataFactory @pDataFactoryName = @DataFactoryName, @pDataFactoryPipeline = @DataFactoryPipeline
			END

			--Update the retry count for all IssueIds that needs to be retried
			UPDATE	 i
			SET		 RetryCount		= RetryCount + 1
					,ModifiedBy		= @CurrentUser
					,ModifiedDtm	= @CurrentDtm
			FROM	 ctl.Issue		  i
			WHERE	 IssueId		= @IssueId			
		END


		IF(@FailureFlag = 1)
		BEGIN
			--Update to IF
			EXEC ctl.usp_UpdateIssue @IssueId,@IssueFailed
		END

		select	 @LoopCount			= @LoopCount + 1
		--DELETE FROM @Issue WHERE IssueId = @Issue
	END

	-------------------------------------------------------------------------------
	--  Select Issue Records in status of 'IR' and fire off staging for each - End
	-------------------------------------------------------------------------------
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()

	exec	[audit].usp_InsertStepLog
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
