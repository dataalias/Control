﻿CREATE PROCEDURE [ctl].[usp_GetPublicationList]
	 @pPublisherCode			varchar(50)		= 'UNK'	
	,@pNextExecutionDateTime	datetime		= NULL --'3001-Jan-01'
	,@pPublicationGroupSequence int				= 1
	,@pETLExecutionId			int				= -1
	,@pPathId					int				= -1
	,@pVerbose					bit				= 0
AS

/*****************************************************************************
 File:			usp_GetPublicationList.sql
 Name:			usp_GetPublicationList
 Purpose:		Returns all publications related to a particular publisher.
				Both Active and InActive publications are returned.
				It is the applications responsibility to decide what to do
				with active or inactive records.

	declare @MyDate datetime = getdatE()
	exec ctl.[usp_GetPublicationList] @pPublisherCode = '8x8CC', @pNextExecutionDateTime = @MyDate
	
 Parameters:    

 Called by:		Application
 Calls:          

 Author:		ffortunato
 Date:			20161114
******************************************************************************/

-------------------------------------------------------------------------------
--  Declarations and Initializations.
-------------------------------------------------------------------------------
SET NOCOUNT ON

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
		,@SLATimeChar			varchar(20)		= 'N/A'
		,@SLATime				datetime
		,@SchemaName			nvarchar(256)	= 'ctl'
		,@PassphraseTableName	nvarchar(256)	= 'Publisher'
		,@IssueRetry			varchar(2)		= 'IR'
		,@NextExecutionDateTime datetime		= cast('3002-Jan-10' as datetime)
		,@PublisherId			int				= -1
		--,@DummyFileDate			varchar(10)		= replace(convert(varchar(10),getdate(),121),'-','')

declare @RetryPublications table (
		 PublicationId			int
		,StatusCode				VARCHAR(20)
		,IssueId				int)

declare	@IssueDetail			table(
		 IssueDetailId			int identity(1,1)
		,PublicationId			int
		,PublicationSeq			int
		,IssueId				int
		,FirstRecordSeq			int
		,LastRecordSeq			int
		,FirstRecordChecksum	varchar(2048)
		,LastRecordChecksum 	varchar(2048)
		,PeriodStartTime		datetime
		,PeriodEndTime			datetime
		,PeriodStartTimeUTC		datetimeoffset
		,PeriodEndTimeUTC		datetimeoffset)

select	 @ParametersPassedChar	= 
      '***** Parameters Passed to exec ctl.usp_GetPublicationList' + @CRLF +
      '     @pPublisherCode = ''' + isnull(@pPublisherCode ,'NULL') + '''' + @CRLF + 
--      '    ,@pProcessingMethodCode = ''' + isnull(@pProcessingMethodCode ,'NULL') + '''' + @CRLF + 
--      '    ,@pStandardFileFormatCode = ''' + isnull(@pStandardFileFormatCode ,'NULL') + '''' + @CRLF + 
      '    ,@pNextExecutionDateTime = ''' + isnull(convert(varchar(100),@pNextExecutionDateTime ,13) ,'NULL') + '''' + @CRLF + 
	  '    ,@pPublicationGroupSequence = ' + isnull(cast(@pPublicationGroupSequence as varchar(100)),'NULL') + @CRLF + 
      '    ,@pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pPathId = ' + isnull(cast(@pPathId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL') + @CRLF + 
      '***** End of Parameters' + @CRLF 

if @pVerbose					= 1
	begin 
		print @ParametersPassedChar
	end

If @pNextExecutionDateTime is null
	select @pNextExecutionDateTime = cast('3001-Jan-01' as datetime)

-------------------------------------------------------------------------------
--  Main
-------------------------------------------------------------------------------
-- Figure out passphrase
begin try

-------------------------------------------------------------------------------
--  Generate Publication List
-------------------------------------------------------------------------------
/*
	select	 @StepName			= 'Getting Passphrase'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'select'
			,@StepDesc			= 'select Passphrase from Passphrase.'

	SELECT	@Passphrase =
	(
		SELECT	 Passphrase
		FROM	 ctl.[Passphrase]
		WHERE	 DatabaseName	= @DbName
		AND		 SchemaName		= @SchemaName
		AND		 TableName		= @PassphraseTableName
	)
*/
-------------------------------------------------------------------------------
--  Check Execution Date
-------------------------------------------------------------------------------
	select	 @StepName			= 'Check Execution Date'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'select'
			,@StepDesc			= 'select @pNextExecutionDateTime.'

-- Figure out Next Execution
if (@pNextExecutionDateTime			= cast('3001-Jan-01' as datetime))
-- No value was passed by the calling procedure so process normally.
	select @NextExecutionDateTime	= @CurrentDtm
else if (@pNextExecutionDateTime	= cast('1900-Jan-01' as datetime))
-- Calling procedure is not insterested in being constrained on next executation date time it wants to see all publication.
	select @NextExecutionDateTime	= cast('3001-Jan-01' as datetime)
else
-- Just let the ssytem check normally.
	select @NextExecutionDateTime	= @pNextExecutionDateTime

-------------------------------------------------------------------------------
--  Check if any publication issues are retrying
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  Check Execution Date
-------------------------------------------------------------------------------
	select	 @StepName			= 'Get Retry Publications'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'select'
			,@StepDesc			= 'select ctl.Publication.'

INSERT INTO @RetryPublications (
		 PublicationId
		,StatusCode
		,IssueId)
SELECT	 p.PublicationId
		,r.StatusCode
		,max(IssueId)		  IssueId
FROM	ctl.Publication		  p
JOIN	ctl.Publisher		  pu 
ON		p.PublisherId		= pu.PublisherId
JOIN	ctl.Issue			  i 
ON		i.PublicationId		= p.PublicationId
JOIN	ctl.RefStatus		  r 
ON		r.StatusId			= i.StatusId
WHERE	pu.PublisherCode	= @pPublisherCode
AND		r.StatusCode		= @IssueRetry
GROUP BY
		p.PublicationId
		,r.StatusCode

-------------------------------------------------------------------------------
--  Check if any publication issues are retrying
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--  Get Issue Details
-------------------------------------------------------------------------------
	select	 @StepName			= 'Get Issue Details'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'select'
			,@StepDesc			= 'select ctl.Issue, etc.'

select	 @PublisherId			= isnull(PublisherId,-1)
from	 ctl.Publisher			  pbr
where	 pbr.PublisherCode		= @pPublisherCode

Insert into @IssueDetail (
		 PublicationId
		,IssueId)
select	 pbn.PublicationId
		,max(IssueId)
from	 ctl.Issue				  iss
join	 ctl.Publication		  pbn
on		 iss.PublicationId		= pbn.PublicationId
join	 ctl.Publisher			  pbr
on		 pbn.PublisherId		= pbr.PublisherId
join	 ctl.RefStatus			  rs
on		 iss.StatusId			= rs.StatusId
where	 pbr.PublisherCode		= @pPublisherCode
and		 rs.StatusCode			in ('IC','IL','IC','IA') -- We dont want values from failed issues.
group by pbn.PublicationId



-------------------------------------------------------------------------------
--  Update Issue Details
-------------------------------------------------------------------------------
	select	 @StepName			= 'Update Issue Details'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'update'
			,@StepDesc			= 'update ctl.Issue, with new water mark values.'

--select * from @IssueDetail

update	 issd
set		 PeriodStartTime		= isnull(iss.PeriodStartTime   ,cast('1900-01-01' as datetime))
		,PeriodEndTime			= iss.PeriodEndTime
		,PeriodStartTimeUTC		= isnull(iss.PeriodStartTimeUTC,cast('1900-01-01' as datetime))
		,PeriodEndTimeUTC		= iss.PeriodEndTimeUTC
		,FirstRecordSeq			= iss.FirstRecordSeq
		,LastRecordSeq			= iss.LastRecordSeq
		,FirstRecordChecksum	= iss.FirstRecordChecksum
		,LastRecordChecksum 	= iss.LastRecordChecksum
		,PublicationSeq			= iss.PublicationSeq
from	 @IssueDetail			  issd
join	 ctl.Issue				  iss
on		 iss.IssueId			= issd.IssueId

-------------------------------------------------------------------------------
--  Generate Publication List
-------------------------------------------------------------------------------
	select	 @StepName			= 'Generate Publication List'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'select'
			,@StepDesc			= 'Generating the publication list for use by Data Factory.'

--	insert	into @PublicationList

	select	 pr.PublisherId
			,@pPublisherCode			PublisherCode
			,pr.PublisherName
			,pn.PublicationId
			,pn.PublicationName
			,pn.PublicationCode
			,pr.InterfaceCode

			,pn.SrcFileRegEx
			,pn.IntervalCode
			,pn.IntervalLength
			,pn.RetryIntervalCode
			,pn.RetryIntervalLength
			,pn.RetryMax
			,pn.ProcessingMethodCode
			,pn.TransferMethodCode
			,pn.NextExecutionDtm
			,pn.SLATime
			,ri.[SLAFormat]
			,ri.[SLARegEx]
			,pn.Bound
			,pn.SrcFileFormatCode  -- As FeedFormat
			,pn.StandardFileFormatCode
			,pn.SSISFolder
			,pn.SSISProject
			,pn.SSISPackage
			,pn.GlueWorkflow
			,pn.SrcPublicationName		
			,pn.SrcFilePath
			,pn.PublicationFilePath
			,pn.PublicationArchivePath
			,pn.PublicationGroupSequence
			,pn.KeyStoreName
			,id.IssueId						LastIssueId
			,'Unknown'						IssueName			-- Unk_' + pn.PublicationCode + '_00000_' + 	@DummyFileDate					IssueName
			,id.PeriodStartTime				LastHighWaterMarkDatetime
			,id.PeriodStartTimeUTC			LastHighWaterMarkDatetimeUTC
			,id.PeriodEndTime				HighWaterMarkDatetime
			,id.PeriodEndTimeUTC			HighWaterMarkDatetimeUTC
			/*
			,convert(varchar(40),isnull(iss.PeriodStartTime,cast('01-Jan-1900'as datetime)),121)		LastHighWaterMarkDatetime
			,convert(varchar(40),isnull(iss.PeriodStartTimeUTC,cast('01-Jan-1900'as datetime)),121 )	LastHighWaterMarkDatetimeUTC
			,convert(varchar(40),isnull(iss.PeriodEndTime,cast('01-Jan-1900'as datetime)),121)			HighWaterMarkDatetime
			,convert(varchar(40),isnull(iss.PeriodEndTimeUTC,cast('01-Jan-1900'as datetimeoffset)),121)	HighWaterMarkDatetimeUTC
			*/
			,LastRecordSeq					HighWaterMarkRecordSeq
			,id.PublicationSeq
	from 	ctl.Publication				  pn
--	left join @RetryPublications		  rpn
--	on		rpn.PublicationId			= pn.PublicationId
	left join @IssueDetail				  id
	on		id.PublicationId			= pn.PublicationId
	join	ctl.Publisher				  pr 
	on		pr.PublisherId				= pn.PublisherId
	join	ctl.RefInterval				  ri
	on		pn.IntervalCode				= ri.IntervalCode
	where	pn.IsActive					= 1 
--	and		pn.IsDataHub				= 1
	and		pn.Bound					= 'In'
--	and		(pn.NextExecutionDtm		<= @NextExecutionDateTime OR COALESCE(rpn.StatusCode,'Unknown') = @IssueRetry)
	and		pn.NextExecutionDtm			<= @NextExecutionDateTime
	and		pr.PublisherCode			= @pPublisherCode
--	and		pn.PublicationGroupSequence = @pPublicationGroupSequence
	

	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= GETDATE()
			--,@JSONSnippet		= '<JSON Snippet>' -- Only if needed.

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar					,@ErrMsg OUTPUT	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc OUTPUT	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog OUTPUT
			,@pVerbose

	select	 @JSONSnippet		= NULL

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
			,@CurrentDtm		= GETDATE()

	if		 @MessageType		<> 'ErrCust'
		select   @MessageType	= 'ErrSQL'

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar					,@ErrMsg OUTPUT	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc OUTPUT	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog OUTPUT
			,@pVerbose

	if 	@ErrNum < 50000	
		select	 @ErrNum	= @ErrNum + 100000000 -- Need to increase number to throw message.

	;throw	 @ErrNum, @ErrMsg, 1
	
end catch


/******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20161114	ffortunato		Initial Iteration
20170109	ffortunato		Adding parameters to allow for getting publication 
							list from based on a specific publisher code.
20170110	ffortunato		Error handling
20170120a	ffortunato		publication code should be varchar(50)
20170120b	ffortunato		returning 2 additional attributes
							PublicationFilePath
							PublicationArchivePath
20170126	ffortunato		adding IsActive indicator to result set.
20210312	ffortunato		modifying to be generic again.
20210524	ffortunato		adding @pPublicationGroupSequence. so different 
							pipelines can be called for a single publisher's 
							publication..
20211102	ffortunato		Preparing some changes in order to work with python.
20211104	ffortunato		Adding some content about the most recent issue.
20220125	ffortunato		+ SrcFileRegEx
20220207	ffortunato		+ SrcFileRegEx
20220210	ffortunato		o StartTime --> EndTime  
							highwater mark is the last end time not start time.
							+ high warter for recordSeq as well
20220405	ffortunato		o @IssueDetails is now updated correctly.
20220714	ffortunato		+ pn.GlueWorkflow
20230522	ffortunato		+ Start, Start UTC 
							This will make things closer to get Issue.
20230614	ffortunato		+ ,pn.KeyStoreName
******************************************************************************/