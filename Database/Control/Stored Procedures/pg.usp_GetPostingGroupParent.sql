CREATE procedure [pg].[usp_GetPostingGroupParent] (
		 @pPostingGroupCode			varchar(100)	= NULL
		,@pPostingGroupStatusCode	varchar(20)		= NULL
		,@pETLExecutionId			int				= -1
		,@pPathId					int				= -1
		,@pVerbose					bit				= 0)
as

/*****************************************************************************
File:		GetQueuedPostingGroupParent.sql
Name:		GetQueuedPostingGroups_DataFactory
Purpose:    Gets Posting Group Parent by posting group code and status

exec pg.GetPostingGroupParent
		 @pPostingGroupCode			='SF-EDL-DATAMART'
		,@pPostingGroupStatusCode	= 'PQ'
		,@pETLExecutionId			= -1
		,@pPathId					= -1
		,@pVerbose					= 0

Parameters:	
Called by: Data Factory Pipeline
Calls:          
Errors:		
Author:		jsardina
Date:		20190624

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20190624	jsardina		Initial iteration.
20191031	jsardina		Making it PostingGroup specific
20200309	ochowkwale		Adding PostingGroupProcessingId field in the 
							returned list
20201118	ffortunato		removing warnings.	
20210415	ffortunato		cleaning up warnings. explicit select of columns.
******************************************************************************/

-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------
declare	 @Rows					int				= 0
        ,@ErrNum				int				= -1
		,@ErrMsg				nvarchar(2048)	= 'N/A'
		,@ParametersPassedChar	varchar(1000)   = 'N/A'
		,@CRLF					varchar(10)		= char(13) + char(10)
		,@Tab					varchar(10)		= char(11)
		,@ProcName				varchar(256)	= OBJECT_NAME(@@PROCID) 
		,@ParentStepLogId       int				= -1
		,@PrevStepLog			int				= -1
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
		,@PostingGroupRetry		varchar(2)		= 'PR'

exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------
select	 @ParametersPassedChar	= 
      '***** Parameters Passed to exec pg.GetPostingGroups_DataFactory' + @CRLF +     
	  '     @pPostingGroupCode = ' + isnull(cast(@pPostingGroupCode as varchar(100)),'NULL') + @CRLF + 
      '    ,@pPostingGroupStatusCode = ' + isnull(cast(@pPostingGroupStatusCode as varchar(100)),'NULL') + @CRLF + 
      '    ,@pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
     '     ,@pPathId = ' + isnull(cast(@pPathId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL') + @CRLF + 
      '***** End of Parameters' + @CRLF 

if @pVerbose					= 1
	begin 
		print @ParametersPassedChar
	end

begin try
	-- Set Log Values
	select	 @StepName			= 'Select Queued Posting Group Parent'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Select'
			,@StepDesc			= 'Select the first queued record from Posting Group Processing table for the given Posting Group Code and Status'
			,@JSONSnippet		= '{' + @CRLF +
										@Tab + @Tab + '"@pPostingGroupStatusCode": "' + cast(@pPostingGroupStatusCode as varchar(200)) + '"' + @CRLF +
										@Tab + '}'+ @CRLF 
	-- Select Records
	SELECT 
			 p.ParentPostingGroupProcessingId
			,p.ParentPostingGroupId
			,p.ParentPostingGroupBatchId
			,p.ParentPostingGroupBatchSeq
			,p.ParentPostingGroupPipeline
			,p.ParentPostingGroupRank
	FROM (
		SELECT 
			 pgpP.PostingGroupProcessingId	 ParentPostingGroupProcessingId
			,pgpP.PostingGroupId			 ParentPostingGroupId
			,pgpP.PostingGroupBatchId		 ParentPostingGroupBatchId
			,pgpP.PGPBatchSeq				 ParentPostingGroupBatchSeq

			-- you either need them all or none.
			, pgP.SSISPackage				 ParentPostingGroupPipeline
			/*
			, pgP.MethodCode				PartentPostingGroupMethodCode
			, pgP.ModeCode					PartentPostingGroupModeCode
			*/
			,RANK() OVER (
				PARTITION BY pgpP.PostingGroupId 
				ORDER BY PostingGroupBatchId	ASC
						,pgpP.PGPBatchSeq		ASC
				) ParentPostingGroupRank
		FROM	pg.PostingGroupProcessing pgpP
		JOIN	pg.PostingGroup			  pgP 
		ON		pgpP.PostingGroupId		= pgP.PostingGroupId
		JOIN	pg.RefStatus			  pgr 
		ON		pgr.StatusId			= pgpP.PostingGroupStatusId
		WHERE	pgr.StatusCode			  IN (@pPostingGroupStatusCode,@PostingGroupRetry)
		AND		pgP.PostingGroupCode	= @pPostingGroupCode
		) p
	WHERE p.ParentPostingGroupRank = 1

	-- Insert Log Record
	select	 @PreviousDtm		= @CurrentDtm, @Rows = @@ROWCOUNT 
	select	 @CurrentDtm		= GETDATE()

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
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

	if		 @@trancount > 1
		rollback transaction

	if		 @MessageType		<> 'ErrCust'
		select   @MessageType	= 'ErrSQL'

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	if 	@ErrNum < 50000	
		select	 @ErrNum	= @ErrNum + 1000000 -- Need to increase number to throw message.

	;throw	 @ErrNum, @ErrMsg, 1
	
end catch


-------------------------------------------------------------------------------
--  Procedure End
-------------------------------------------------------------------------------

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