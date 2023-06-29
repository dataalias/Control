CREATE PROCEDURE ctl.usp_GetPublicationRecord
	 @pPublicationFilePath		varchar(255)	= 'UNK'	
	,@pETLExecutionId			int				= -1
	,@pPathId					int				= -1
	,@pVerbose					bit				= 0
AS

/*****************************************************************************
 File:			ctl.usp_GetPublicationRecord.sql
 Name:			ctl.usp_GetPublicationRecord
 Purpose:		Returns a single publication related to a particular folder
				path.
				Only Active publications are returned.
				Note: NextExecutionDate is not considered in this procedure 
				because the proc is invoked by a trigger meaning a file is 
				available.
				

	exec ctl.usp_GetPublicationRecord @pPublicationFilePath = '/one/two'
										

 Parameters:    

 Called by:		SSIS
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
		,@PublicationCode		varchar(50)		= 'N/A'
		
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
		,PeriodStartTime		datetime
		,PeriodEndTime			datetime
		,PeriodStartTimeUTC		datetimeoffset
		,PeriodEndTimeUTC		datetimeoffset)

select	 @ParametersPassedChar	= 
      '***** Parameters Passed to exec ctl.usp_GetPublicationRecord' + @CRLF +
      '     @pPublicationFilePath = ''' + isnull(@pPublicationFilePath ,'NULL') + '''' + @CRLF + 
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
-- Figure out passphrase
begin try

	SELECT	@Passphrase =
	(
		SELECT	 Passphrase
		FROM	 ctl.[Passphrase]
		WHERE	 DatabaseName	= @DbName
		AND		 SchemaName		= @SchemaName
		AND		 TableName		= @PassphraseTableName
	)

-------------------------------------------------------------------------------
--  Check if any publication issues are retrying
-------------------------------------------------------------------------------
/*
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
*/
-------------------------------------------------------------------------------
--  Check if any publication issues are retrying
-------------------------------------------------------------------------------
select  @PublicationCode =  PublicationCode
from ctl.Publication
where  PublicationFilePath = @pPublicationFilePath


-------------------------------------------------------------------------------
--  Generate Publication List
-------------------------------------------------------------------------------
	select	 @StepName			= 'Get Max IssueID Details'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'select'
			,@StepDesc			= 'Getting the latest information for the last issue ofr the publication.'

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
where	 pbn.PublicationCode	= @PublicationCode
and		 rs.StatusCode			in ('IC','IL','IC','IA','IN') -- We dont want values from failed issues.
group by pbn.PublicationId

update	 issd
set		 PeriodStartTime		= iss.PeriodStartTime
		,PeriodEndTime			= iss.PeriodEndTime
		,PeriodStartTimeUTC		= iss.PeriodStartTimeUTC
		,PeriodEndTimeUTC		= iss.PeriodEndTimeUTC
		,FirstRecordSeq			= iss.FirstRecordSeq
		,LastRecordSeq			= iss.LastRecordSeq
		,PublicationSeq			= iss.PublicationSeq
from	 @IssueDetail			  issd
join	 ctl.Issue	iss
on		 iss.IssueId			= issd.IssueId

/* testing
select * 
from	@IssueDetail
*/
-------------------------------------------------------------------------------
--  Generate Publication List
-------------------------------------------------------------------------------
	select	 @StepName			= 'Generate Publication List'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'select'
			,@StepDesc			= 'Generating the publication list for use by Data Factory.'


if exists (select top 1 1 
			from 	ctl.Publication				  pn
			left join @IssueDetail				  id
			on		id.PublicationId			= pn.PublicationId
			join	ctl.Publisher				  pr 
			on		pr.PublisherId				= pn.PublisherId
			join	ctl.RefInterval				  ri
			on		pn.IntervalCode				= ri.IntervalCode
			where	pn.IsActive					= 1 
			and		pn.Bound					= 'In'
			and		pn.NextExecutionDtm			<= @NextExecutionDateTime
			and		pn.PublicationCode			= @PublicationCode
		)
begin

--	insert	into @PublicationList
	select	 pr.PublisherId
			,pr.PublisherCode
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
			,isnull(id.IssueId,-1)						LastIssueId
			,'Unknown'									IssueName
			,convert(varchar(40),isnull(id.PeriodStartTime,cast('01-Jan-1900'as datetime)),121)		LastHighWaterMarkDatetime
			,convert(varchar(40),isnull(id.PeriodStartTimeUTC,cast('01-Jan-1900'as datetime)),121 )	LastHighWaterMarkDatetimeUTC
			,convert(varchar(40),isnull(id.PeriodEndTime,cast('01-Jan-1900'as datetime)),121)			HighWaterMarkDatetime
			,convert(varchar(40),isnull(id.PeriodEndTimeUTC,cast('01-Jan-1900'as datetimeoffset)),121)	HighWaterMarkDatetimeUTC
			,isnull(id.LastRecordSeq,1)					HighWaterMarkRecordSeq
			,isnull(id.PublicationSeq,0)				PublicationSeq
	from 	ctl.Publication				  pn
	left join @IssueDetail				  id
	on		id.PublicationId			= pn.PublicationId
	join	ctl.Publisher				  pr 
	on		pr.PublisherId				= pn.PublisherId
	join	ctl.RefInterval				  ri
	on		pn.IntervalCode				= ri.IntervalCode
	where	pn.IsActive					= 1 
	and		pn.Bound					= 'In'
	and		pn.PublicationCode			= @PublicationCode
	order by pn.PublicationId  -- This should be a processing order but that is only to meet a special case so....
	
end 
/*
else
begin
	select 	 -1 PublisherId
			,'N/A' PublisherName
			,-1		PublicationId
			,'N/A'	PublicationName
			,'N/A'	PublicationCode
			,'N/A'	SrcFileRegEx
			,'N/A'	ProcessingMethodCode
			,'N/A'	TransferMethodCode
			,'N/A'	SSISFolder
			,'N/A'	SSISProject
			,'N/A'	SSISPackage
			,'N/A'	PublicationFilePath
			,'N/A'	PublicationArchivePath
			,-1		LastIssueId
			,cast('1900-01-01' as datetime)		HighWaterMarkDatetime
			,cast('1900-01-01' as datetimeoffset(7))	HighWaterMarkDatetimeUTC
			,-1		HighWaterMarkRecordSeq 
end
*/
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
20220712	ffortunato		Initial Iteration
							Needed something for triggered events to get
							datahub information.
20220714	ffortunato		+ pn.GlueWorkflow
20230602	ffortunato		- URL / User Password data.
							+ pr.PublisherCode
20230614	ffortunato		+ KeyStoreName
******************************************************************************/
