CREATE PROCEDURE [ctl].[GetTablePublicationList] (
		 @pPublicationCode		varchar(50)		= 'N/A'
		,@pETLExecutionId		int				= -1
		,@pPathId				int				= -1
		,@pVerbose				bit				= 0)
AS
/*****************************************************************************
File:		GetTablePublicationList.sql
Name:		GetTablePublicationList

Purpose:	


Info   : 2018/05/29 12:19:44	Msg: Starting Invoke-dbIntervalCheckGet -dbServer .  -pubc OIE_BEHAVE -period 1 -interval DLY  -logFile C:\Users\ffortunato\Source\Workspaces\BIDW\PowerShell\DataHub\logs\Get-DataFeed_20180529_ITSME.log


exec ctl.GetTablePublicationList 'OIE_BEHAVE',  -1, -1, 1
exec ctl.GetTablePublicationList 'OIE_VIABLE',  -1, -1, 1

Parameters:    

Called by:	
Calls:          

Errors:		

Author:		ffortunato
Date:		20180518

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20180518	ffortunato		Initial Iteration

20180522	ffortunato		Code review changes. Fixed case statement. Looked up
							issue records directly in complete, failed, processing 
							series of insert updates.

20180712	ffortunato		Formatting.
20180906	ffortunato		Code validation changes, checking data types.
20180924	ffortunato		Adding IL to a success status to pull new data.
20190812	ochowkwale		Compatibility with azure data factory
20210121	ochowkwale		Making Issue Retry as a part of Processing IssueIds
20210413	ffortunato		IsDataHub is going back to a bit. 
							Correcting where clauses.
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
		,@CurrentUser			varchar(256)	= CURRENT_USER
		,@ProcessType			varchar(10)		= 'Proc'
		,@StepName				varchar(256)	= 'Start'
		,@StepOperation			varchar(50)		= 'N/A' 
		,@MessageType			varchar(20)		= 'Info' -- ErrCust, ErrSQL, Info, Warn
		,@StepDesc				nvarchar(2048)	= 'Procedure started' 
		,@StepStatus			varchar(10)		= 'Success'
		,@StepNumber			varchar(10)		= 0
		,@Duration				varchar(10)		= 0
		,@JSONSnippet			nvarchar(max)	= NULL
		,@MaxIssueId			bigint			= -1
		,@MidnightCurrentDay	datetime


declare @PublicationListComplete	table (
		 PublicationId			int
		,IssueId				bigint
		,PeriodEndTime			datetime
)
declare @PublicationListFailed		table (
		 PublicationId			int
		,IssueId				bigint
		,PeriodEndTime			datetime
)
declare @PublicationListProcessing	table (
		 PublicationId			int
		,IssueId				bigint
		,PeriodEndTime			datetime
)
declare @PublicationListPivot		table (
		 PublicationId			int
		,IntervalCode			varchar(20)
		,IntervalLength			int
		,SLATime				varchar(20)
		,SLAFormat				varchar(100)
		,SLARegEx				varchar(100)
		-- The last successfully completed Issue.
		,CompleteIssueId		bigint
		,CompletePeriodEndDtm	datetime
		-- The last failed Issue.
		,FailedIssueId			bigint
		,FailedPeriodEndDtm		datetime
		-- The last processing Issue.
		,ProcessingIssueId		bigint
		,ProcessingPeriodEndDtm	datetime
		-- Supporting information for the most current issue (regardless of state)
		,BaseLineIssueId		bigint
		,BaseLineStatus			varchar(20) not null default 'Processing'
		,NextRunTime			datetime	not null default '1/1/2099'
		,NextSLARunTime			datetime
		,IssueName				varchar(255)
		,FirstRecordSeq			int
		,PeriodStartTime		datetime	not null default '1/1/2100'
		,IsIntervalMet			bit
		,CurrentDtm				datetime
)

exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

select	 @ParametersPassedChar	= 
			'exec bpi_dw_stage.ctl.GetTablePublicationList' + @CRLF +
			'     @pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
			'    ,@pPathId = ' + isnull(cast(@pPathId as varchar(100)),'NULL') + @CRLF + 
			'    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL')

if @pVerbose					= 1
	begin 
		print @ParametersPassedChar
	end

-------------------------------------------------------------------------------
--  Main
-------------------------------------------------------------------------------

begin try

-------------------------------------------------------------------------------
--  Generate Publication List
-------------------------------------------------------------------------------
	select	 @StepName			= 'Gathering latest, Complete, Failed and Notified Issues.'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'insert'
			,@StepDesc			= 'Prepping Publication list tables, Complete, Failed, Processing.'

	-- Get all the latest completed table issue records.
	select	 @MaxIssueId		= max(iss.IssueId)
	from	 ctl.Issue			  iss
	join	 ctl.RefStatus		  rs
	on		 iss.StatusId		= rs.StatusId
	join	 ctl.Publication	  pbn
	on		 pbn.PublicationId	= iss.PublicationId
	join	 ctl.Publisher		  pbr
	on		 pbr.PublisherId	= pbn.PublisherId
	where	 rs.StatusCode		in ('IC','IA','IN','IL')
	and		 pbn.IsActive		= 1
	and		 pbn.IsDataHub		= 1	 -- IN (1,2)
	and		 pbn.PublicationCode  = @pPublicationCode
	group by iss.PublicationId

	insert into @PublicationListComplete
	select	 iss.PublicationId
			,iss.IssueId
--			,max(iss.CreatedDtm)
			,iss.PeriodEndTime
	from	 ctl.Issue			  iss
	where	 iss.IssueId		= @MaxIssueId

	select	 @MaxIssueId		= -1

	-- Get all the latest failed table issue records.
	select	 @MaxIssueId		= max(iss.IssueId)
	from	 ctl.Issue			  iss
	join	 ctl.RefStatus		  rs
	on		 iss.StatusId		= rs.StatusId
	join	 ctl.Publication	  pbn
	on		 pbn.PublicationId	= iss.PublicationId
	join	 ctl.Publisher		  pbr
	on		 pbr.PublisherId	= pbn.PublisherId
	where	 rs.StatusCode		in ('IF')
	and		 pbn.IsActive		= 1
	and		 pbn.IsDataHub		= 1 -- IN (1,2)
	and		 pbn.PublicationCode  = @pPublicationCode
	group by iss.PublicationId
	
	insert into @PublicationListFailed
	select	 iss.PublicationId
			,iss.IssueId
--			,max(iss.CreatedDtm)
			,iss.PeriodEndTime
	from	 ctl.Issue			  iss
	where	 iss.IssueId		= @MaxIssueId

	select	 @MaxIssueId		= -1

	-- Get all the latest processing table issue records.
	select	 @MaxIssueId		= max(iss.IssueId)
	from	 ctl.Issue			  iss
	join	 ctl.RefStatus		  rs
	on		 iss.StatusId		= rs.StatusId
	join	 ctl.Publication	  pbn
	on		 pbn.PublicationId	= iss.PublicationId
	join	 ctl.Publisher		  pbr
	on		 pbr.PublisherId	= pbn.PublisherId
	where	 rs.StatusCode		in ('IP','IS','IR')
	and		 pbn.IsActive		= 1
	and		 pbn.IsDataHub		= 1 -- IN (1,2)
	and		 pbn.PublicationCode  = @pPublicationCode
	group by iss.PublicationId

		
	insert into @PublicationListProcessing
	select	 iss.PublicationId
			,iss.IssueId
--			,max(iss.CreatedDtm)
			,iss.PeriodEndTime
	from	 ctl.Issue			  iss
	where	 iss.IssueId		= @MaxIssueId
	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			--,@JSONSnippet		= '{"":"' + @myvar + '"}' -- Only if needed.

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	select	 @JSONSnippet		= NULL

-------------------------------------------------------------------------------
--  Generate Publication List
-------------------------------------------------------------------------------
	select	 @StepName			= 'Pivoting Publication Data.'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'insert'
			,@StepDesc			= 'Consolidating data into a single table @PublicationListPivot.'


	-- Prime the pivot table with the publication code being interrogated.
	insert into @PublicationListPivot(
			  PublicationId	
			 ,IsIntervalMet
			 ,IntervalCode
			 ,IntervalLength
			 ,SLATime
			 ,SLAFormat
			 ,SLARegEx
			 ,CurrentDtm	
		)
	select	 PublicationId
			,0
			,pbn.IntervalCode
			,pbn.IntervalLength
			,pbn.SLATime
			,ri.SLAFormat
			,ri.SLARegEx
			,@CurrentDtm
	from	 ctl.Publication	  pbn
	join	 ctl.Publisher		  pbr
	on		 pbr.PublisherId	= pbn.PublisherId
	join	 ctl.RefInterval	  ri
	on		 pbn.IntervalCode	= ri.IntervalCode
	where	 pbn.IsDataHub = 1--IN (1,2)
	and		 pbn.IsActive = 1
	and		 pbn.PublicationCode = @pPublicationCode

	update	 plv
	set		 CompleteIssueId	= isnull(plf.IssueId,-1)
			,CompletePeriodEndDtm	= isnull(plf.PeriodEndTime, '1-1-1800')
	from	@PublicationListPivot plv
	left outer join @PublicationListComplete plf
	on		plv.PublicationId	= plf.PublicationId

	update	 plv
	set		 FailedIssueId		= isnull(plf.IssueId,-1)
			,FailedPeriodEndDtm = isnull(plf.PeriodEndTime, '1-1-1800')
	from	@PublicationListPivot plv
	left outer join @PublicationListFailed plf
	on		plv.PublicationId	= plf.PublicationId

	update	 plv
	set		 ProcessingIssueId	= isnull(plp.IssueId,-1)
			,ProcessingPeriodEndDtm = isnull(plp.PeriodEndTime, '1-1-1800')
	from	@PublicationListPivot plv
	left outer join @PublicationListProcessing plp
	on		plv.PublicationId	= plp.PublicationId

	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			--,@JSONSnippet		= '{"":"' + @myvar + '"}' -- Only if needed.

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	select	 @JSONSnippet		= NULL

-------------------------------------------------------------------------------
--  Generate Publication List
-------------------------------------------------------------------------------
	select	 @StepName			= 'Interval and next run logic.'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'update'
			,@StepDesc			= 'Determine last run and identify if new issue is required. Ensure things are not currently processing.'

	-- Determine if the last record is complete, failed or processing.
	update	 plp
	set		 --BaseLineIssueId = 
			 BaseLineStatus = CASE
								when CompleteIssueId   > FailedIssueId   and CompleteIssueId   > ProcessingIssueId then  'Complete'
								when FailedIssueId     > CompleteIssueId and FailedIssueId     > ProcessingIssueId then  'Failed'
								when ProcessingIssueId > FailedIssueId   and ProcessingIssueId > CompleteIssueId   then  'Processing'
								else 'N/A'
								end
	from	 @PublicationListPivot plp

	update	 plp
	set		 BaseLineIssueId = case BaseLineStatus
								when 'Complete'		then CompleteIssueId
								when 'Processing'	then -1
								when 'Failed'		then CompleteIssueId
								else -1
								end
	from	 @PublicationListPivot plp


	select	 @MidnightCurrentDay = convert(datetime,convert(varchar,@CurrentDtm,10))

	-- Set all the start times.
	update	 plp
	set		 PeriodStartTime	= iss.PeriodEndTime -- Last Issue End Time is becoming next issue start time.
			,NextRunTime		=  case IntervalCode
 								when 'MN'   then dateadd(mi,plp.IntervalLength,convert(datetime,substring(convert(varchar(112),iss.PeriodEndTime,126),1,17) + SLATime))
								when 'HR'    then dateadd(hh,plp.IntervalLength,convert(datetime,substring(convert(varchar(112),iss.PeriodEndTime,126),1,14) + SLATime))
								when 'DY'   then dateadd(dd,plp.IntervalLength,convert(datetime,substring(convert(varchar(112),iss.PeriodEndTime,126),1,11) + SLATime))
								when 'WK'  then convert(datetime,'2100-01-01')
								when 'MT' then dateadd(mm,plp.IntervalLength  ,convert(datetime,substring(convert(varchar(112),iss.PeriodEndTime,126),1,8) + SLATime))
								when 'YR'  then dateadd(yyyy,plp.IntervalLength,convert(datetime,substring(convert(varchar(112),iss.PeriodEndTime,126),1,5) + SLATime))
								else convert(datetime,'2100-01-01') end 
			,IssueName			= @pPublicationCode + '_'  + convert(varchar(20),@CurrentDtm, 112) + '_' + left(replace(convert(varchar(20),@CurrentDtm, 114),':',''),6)
			,FirstRecordSeq		= iss.LastRecordSeq + 1     -- Last Issue Rec Sequence becomes the first for the next run.
	from	 @PublicationListPivot plp
	join	 ctl.Issue			  iss
	on		 plp.BaseLineIssueId = iss.IssueId


	-- This is some tricky logic so going to explain the where clause line by line.
	--	PeriodStartTime	<  NextRunTime  :: PeriodStart is the last issue's PeriodEnd it must be less than the NextRunTime because the run time is calculated by taking the last issue's periodEnd and adding the interval length.
	--	NextRunTime		<= @CurrentDtm  :: We need to ensure that the NextRunTime (PeriodEnd for last issue + interval) has past @CurrentDtm to know its ready to run
	--	BaseLineStatus	<> 'Processing' :: If the issue is currently processing the system should not kick off a subsequent run.

	update	 plp
	set		 IsIntervalMet		= 1
	from	 @PublicationListPivot plp
	where	 PeriodStartTime	<  NextRunTime
	and		 NextRunTime		<= @CurrentDtm
	and		 BaseLineStatus		<> 'Processing'

	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			--,@JSONSnippet		= '{"":"' + @myvar + '"}' -- Only if needed.

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	select	 @JSONSnippet		= NULL

	select  
		 IssueName
		,FirstRecordSeq
		,PeriodStartTime
		,IsIntervalMet
--		,CurrentDtm				datetime
	from @PublicationListPivot

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
			 @MessageType		,@CurrentDtm	,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
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
/*
-- Passing @ProcessStartDtm so the total duration for the procedure is added.
-- @ProcessStartDtm (if you want total duration) 
-- @PreviousDtm (if you want 0)
exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm	,@ProcessStartDtm	,@StepNumber	,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar				,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus	,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
		,@pVerbose
*/

