CREATE PROCEDURE [ctl].[usp_InsertNewIssue] (	
	 @pPublicationCode			varchar(50)
	,@pDataLakePath				varchar(1000)	= '/Raw Data Zone/...'
	,@pIssueName				varchar(255)	= 'Unknown'
	,@pSrcIssueName				nvarchar(255)	= 'Unknown'
	,@pStatusCode				varchar(20)		= null
	,@pSrcDFIssueId				varchar(100)	= 'UNK'
	,@pSrcDFCreatedDate			datetime		= null
	,@pFirstRecordSeq			integer			= null
	,@pLastRecordSeq			integer			= null
	,@pFirstRecordChecksum		varchar(2048)	= null
	,@pLastRecordChecksum		varchar(2048)	= null
	,@pPeriodStartTime			datetime		= null
	,@pPeriodEndTime			datetime		= null
	,@pRecordCount				integer			= null
	,@pETLExecutionId			int				= null
	,@pCreateBy					varchar(30)		= null
	,@pIssueId					int				output
	,@pVerbose					bit				= 0)

AS 
/*****************************************************************************
File:		InsertNewIssue.sql
Name:		usp_InsertNewIssue
Purpose:	Allows for the creation of new issues.

exec ctl.[usp_InsertNewIssue] 'TSTPUBN01-ACCT' ,NULL,1 ,getdate() ,1     
		,1000  ,3463466,4567745,getdate()-.02,getdate(),1000 ,'ffortunato'
		,@IssueId output,1 --@PassVerbose

declare @MyIssue int = -1

exec ctl.[usp_InsertNewIssue] 
	 @pPublicationCode	=	'PUBN01-ACCT' 
	,@pDataLakePath		=	'\PUBN01'
	,@pIssueName		=	NULL 
	,@pSrcIssueName		=	'1/1/2021'
	,@pStatusCode		=	'IS'     
	,@pSrcDFIssueId		=	1000  
	,@pSrcDFCreatedDate	=	'1/1/2021'
	,@pFirstRecordSeq	=	1
	,@pLastRecordSeq	=	1001
	,@pFirstRecordChecksum	=	3463466
	,@pLastRecordChecksum	=	4567745
	,@pPeriodStartTime	=	'1/1/2021'
	,@pPeriodEndTime	=	'1/2/2021'
	,@pRecordCount		=	1000
	,@pETLExecutionId	=	1
	,@pCreateBy			=	'ffortunato'
	,@pIssueId			=	@MyIssue output
	,@pVerbose			=	0	

print cast(@MyIssue as varchar(200))



Parameters:    
		@pPublicationCode
	,@pIssueName
	,@pSrcDFIssueId
	,@pSrcDFCreatedDate
	,@pFirstRecordSeq
	,@pLastRecordSeq
	,@pFirstRecordChecksum
	,@pLastRecordChecksum
	,@pPeriodStartTime
	,@pPeriodEndTime
	,@pRecordCount
	,@pETLExecutionId	
	,@pCreateBy
	,@pIssueId  OUTPUT
	,@pVerbose

Called by:	SSIS Staging Routines
Calls:          

Errors:		50001 'Custom Error: Unable to lookup Publication Id or Status Id.'
			50002 'Custom Error: Invalid @pIssued. Insert New Issue transaction rolled back.'	

Author:		ffortunato
Date:		20091020

******************************************************************************/

DECLARE	 @rows					int
		,@err					int
		,@ErrMsg				nvarchar(2048)
		,@FailedProcedure		varchar(1000)
		,@ParametersPassedChar	varchar(1000)
		,@CRLF					varchar(10) = char(13) + char(10)
		,@CreatedDate			datetime
		,@PublicationId			int
		,@PublicationSeq		int
		,@DailyPublicationSeq	int
		,@StatusId				integer
--		,@StatusCode			varchar(20)
		,@StatusType			varchar(20)
		,@testing				varchar(20)
		,@ReportDate			datetime
		,@NextExecutionDtm		datetime
		,@LastIssueId			int
		,@LastIssueStatus		varchar(2)

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------
SELECT	 @ROWS					= @@ROWCOUNT
		,@ERR					= @@ERROR
		,@ErrMsg				= 'N/A'
		,@FailedProcedure		= 'Stored Procedure : ' + OBJECT_NAME(@@PROCID) + ' failed.' + @CRLF
		,@CreatedDate			= GETDATE()
		,@LastIssueId			= -1
		,@LastIssueStatus		= 'IC'
		,@PublicationId			= -1
		,@PublicationSeq		= -1
		,@DailyPublicationSeq	= -1
		,@StatusId				= -1
--		,@StatusCode			= 'IP'   -- Normal Starting Status (todo: allow this to be passed from calling application.)
		,@StatusType			= 'Issue'
		,@pCreateBy				= isnull(@pCreateBy,SYSTEM_USER)
		,@ParametersPassedChar	= @CRLF +
      '***** Parameters Passed to exec ctl.usp_InsertNewIssue' + @CRLF +
      '     @pPublicationCode = ''' + isnull(@pPublicationCode ,'NULL') + '''' + @CRLF + 
      '    ,@pIssueName = ''' + isnull(@pIssueName ,'NULL') + '''' + @CRLF + 
      '    ,@pSrcIssueName = ''' + isnull(@pSrcIssueName ,'NULL') + '''' + @CRLF + 
      '    ,@pStatusCode = ''' + isnull(@pStatusCode ,'NULL') + '''' + @CRLF + 
      '    ,@pSrcDFIssueId = ''' + isnull(@pSrcDFIssueId ,'NULL') + '''' + @CRLF + 
      '    ,@pSrcDFCreatedDate = ''' + isnull(convert(varchar(100),@pSrcDFCreatedDate ,13) ,'NULL') + '''' + @CRLF + 
      '    ,@pFirstRecordSeq = ' + isnull(cast(@pFirstRecordSeq as varchar(100)),'NULL') + @CRLF + 
      '    ,@pLastRecordSeq = ' + isnull(cast(@pLastRecordSeq as varchar(100)),'NULL') + @CRLF + 
      '    ,@pFirstRecordChecksum = ''' + isnull(@pFirstRecordChecksum ,'NULL') + '''' + @CRLF + 
      '    ,@pLastRecordChecksum = ''' + isnull(@pLastRecordChecksum ,'NULL') + '''' + @CRLF + 
      '    ,@pPeriodStartTime = ''' + isnull(convert(varchar(100),@pPeriodStartTime ,13) ,'NULL') + '''' + @CRLF + 
      '    ,@pPeriodEndTime = ''' + isnull(convert(varchar(100),@pPeriodEndTime ,13) ,'NULL') + '''' + @CRLF + 
      '    ,@pRecordCount = ' + isnull(cast(@pRecordCount as varchar(100)),'NULL') + @CRLF + 
      '    ,@pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pCreateBy = ''' + isnull(@pCreateBy ,'NULL') + '''' + @CRLF + 
      '    ,@pIssueId = @pIssueId --output ' + @CRLF +
      '    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL') + @CRLF + 
      '***** End of Parameters' + @CRLF 

		,@pIssueId				= -1

if @pVerbose					= 1
	begin 
		print @ParametersPassedChar
	end
 
-------------------------------------------------------------------------------
--  Main
-------------------------------------------------------------------------------
begin try

select	 @PublicationId			= isnull(PublicationId ,-1)
from	 ctl.Publication		  pubr
where	 PublicationCode		= @pPublicationCode

select	 @PublicationSeq		= isnull(max(iss.PublicationSeq),0) + 1
from	 ctl.Issue				  iss
where	 PublicationId			= @PublicationId 


select	 @ReportDate			= isnull(@pSrcDFCreatedDate,@CreatedDate)

select	 @DailyPublicationSeq	= isnull(max(iss.DailyPublicationSeq),0) + 1
from	 ctl.Issue				  iss
where	 PublicationId			= @PublicationId 
and		 ReportDate				= @ReportDate

select	 @StatusId				= isnull(StatusId  , -1)
from	 ctl.RefStatus			  rstat
where	 StatusCode				= @pStatusCode
and		 StatusType				= @StatusType

--Find out the Next Expected Execution Runtime for Publication
SELECT @NextExecutionDtm = (select [dbo].[fn_CalculateNextExecutionDtm](@CreatedDate, NextExecutionDtm, IntervalCode, IntervalLength))
FROM ctl.Publication
WHERE PublicationCode = @pPublicationCode

--Find out if the last issue is in retry status for that Publication
SELECT @LastIssueId = COALESCE(i.IssueId, @LastIssueId)
	,@LastIssueStatus = COALESCE(r.StatusCode, @LastIssueStatus)
FROM ctl.Issue as i
INNER JOIN ctl.Publication as p ON p.PublicationId = i.PublicationId
INNER JOIN ctl.RefStatus as r ON r.StatusId = i.StatusId
WHERE p.PublicationCode = @pPublicationCode
GROUP BY i.IssueId, r.StatusCode
HAVING i.IssueId = max(IssueId)


if @pVerbose					= 1
	begin 
		print ' ***** Lookup Parameters ***** '
		print '@publicationid = ' + cast(@publicationId as varchar(200))
		print '@publicationseq = ' + cast(@PublicationSeq as varchar(200))
		print '@statusid = '+ cast(@StatusId as varchar(200))
		print ' ***************************** '
		print ''
	end

--Testing
--select @publicationid = -1

-- Ensure we got good lookups.
if	@PublicationId				= -1 or
	@StatusId					= -1 or
	@DailyPublicationSeq		= -1

begin

	select	 @Err				= 50001
			,@ErrMsg			= 'ErrorNumber: ' + CAST (@Err as varchar(10)) + @CRLF
								+ @FailedProcedure + 'Custom Error: Unable to lookup Publication Id or Status Id.' + @CRLF

								+ '@publicationid = ' + cast(@publicationId as varchar(200)) + @CRLF
								+ '@publicationseq = ' + cast(@PublicationSeq as varchar(200)) + @CRLF
								+ '@Dailypublicationseq = ' + cast(@DailyPublicationSeq as varchar(200)) + @CRLF
								+ '@statusid = '+ cast(@StatusId as varchar(200)) + @CRLF


								+ isnull(@ParametersPassedChar, 'Parm was NULL')
	;throw  @Err, @ErrMsg, 1

end

end try

begin catch

if	@PublicationId				= -1 or
	@StatusId					= -1 begin

	;throw  @Err, @ErrMsg, 1	-- Custom Error: 50001

end else begin

	select	 @Err				= @@ERROR
			,@ErrMsg			= 'ErrorNumber: ' + CAST (@Err as varchar(10)) + @CRLF
								+ @FailedProcedure + @CRLF + 'SQL Server Error: ' + @CRLF
								+ ERROR_MESSAGE () + @CRLF
								+ isnull(@ParametersPassedChar, 'Parmeter was NULL')

	if @Err < 50000  select @Err = @Err + 1000000
	;throw	 @Err, @ErrMsg, 1	-- Sql Server Error

end

end catch

IF(@LastIssueStatus <> 'IR')
BEGIN

begin try

begin tran NEWISSUE

INSERT INTO ctl.Issue (
		 PublicationId
		,StatusId
		,DataLakePath
		,ReportDate
		,SrcDFIssueId
		,SrcDFCreatedDate
		,IssueName
		,SrcIssueName
		,PublicationSeq
		,DailyPublicationSeq
		,FirstRecordSeq
		,LastRecordSeq
		,FirstRecordChecksum
		,LastRecordChecksum
		,PeriodStartTime
		,PeriodEndTime
		,RecordCount
		,ETLExecutionID
		,CreatedDtm
		,CreatedBy
) VALUES (
		 @PublicationId
		,@StatusId 
		,@pDataLakePath
		,isnull(@pSrcDFCreatedDate,@CreatedDate) --Truncate to day with the line below.
		--,cast(convert(char(11), isnull(@pSrcDFCreatedDate,@CreatedDate), 113) as datetime)
		,@pSrcDFIssueId 
		,@pSrcDFCreatedDate
		,coalesce(@pIssueName,'Unknown')
		,coalesce(@pSrcIssueName,'Unknown')
		,@PublicationSeq
		,@DailyPublicationSeq
		,@pFirstRecordSeq
		,@pLastRecordSeq 
		,@pFirstRecordChecksum 
		,@pLastRecordChecksum    
		,@pPeriodStartTime 
		,@pPeriodEndTime
		,@pRecordCount 
		,@pETLExecutionID
		,@CreatedDate
		,@pCreateBy
)

select  @pIssueId				= isnull(SCOPE_IDENTITY(),-1)

if @pVerbose					= 1
	begin 
		print '@pIssueId          : ' + cast(@pIssueId as varchar(100))
		print 'SCOPE_IDENTITY     : ' + cast(SCOPE_IDENTITY() as varchar(100))
--		print '@@Identity         : ' + cast(@@Identity as varchar(100))
		select @testing = cast(max(IssueId) as varchar(20)) from ctl.Issue where PublicationId = @PublicationId
		print 'max(publicationid) : ' + @testing
	end

if @pIssueId					= -1
begin
	select   @Err				= 50002
			,@ErrMsg			= 'ErrorNumber: ' + CAST (@Err as varchar(10)) + @CRLF
								+ 'Custom Error: Invalid @pIssued. Insert New Issue transaction rolled back.'  + @CRLF
								+ isnull(@ParametersPassedChar, 'Parmeter was NULL')
	; throw @Err, @ErrMsg, 1

end

	update	 ctl.Publication
	set		 NextExecutionDtm	= @NextExecutionDtm
	where	 PublicationCode	= @pPublicationCode

commit tran NEWISSUE

end try

begin catch
	select   @Err				= @@ERROR
			,@ErrMsg			= 'ErrorNumber: ' + CAST (@Err as varchar(10)) + @CRLF
								+ @FailedProcedure + @CRLF
								+ ERROR_MESSAGE () + @CRLF
								+ isnull(@ParametersPassedChar, 'Parmeter was NULL')
	if @@trancount > 1
		rollback tran
	select	@pIssueId			= -1

	if @Err < 50000  select @Err = @Err + 1000000
	;throw  @Err, @ErrMsg, 1

end catch

begin try
-- Lets create a name for the issue if we weren't provided one.
IF (@pIssueName IS NULL or len(@pIssueName) < 1 or @pIssueName = 'Unknown')
	begin
		update	iss
		set		issuename			= pub.PublicationCode + '-'
					--Doing some fancy padding to get decent sequence numbers.
					+ REPLICATE('0',5-len(right(cast(iss.PublicationSeq as varchar(100)),5))) 
					+ right(cast(iss.PublicationSeq as varchar(100)),5)    + '-'
					-- end of fancy padding
					+ left(convert(varchar(20), isnull(@pSrcDFCreatedDate,iss.CreatedDtm),112),8)
		from	ctl.Issue			  iss
		join	ctl.Publication		  pub
		on		iss.PublicationId	= pub.PublicationId
		where	iss.PublicationId	= @PublicationId
		and		iss.PublicationSeq	= @PublicationSeq
		and		iss.IssueId			= @pIssueId

	end -- Fix Null Issue Names

end try

begin catch
	select   @Err				= @@ERROR
			,@ErrMsg			= 'ErrorNumber: ' + CAST (@Err as varchar(10)) + @CRLF
								+ @FailedProcedure + 'Unable to update custom issue name.' 
								+ @CRLF + ERROR_MESSAGE ()  + @CRLF
								+ isnull(@ParametersPassedChar, 'Parm was NULL')

	if @@trancount > 1
		rollback tran

	if @Err < 50000  select @Err = @Err + 1000000
	;throw  @Err, @ErrMsg, 1

end catch

END

--added the select statement for azure data factory compatibility
--record set needs to be returned rather than using the parameter
select  IssueId = CASE WHEN @LastIssueStatus = 'IR' THEN @LastIssueId ELSE @pIssueId END

return

/******************************************************************************
		CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20161215	ffortunato		Added Verbose and Errorhandling.
20161220	ffortunato		Sending the IssueId back to the calling procedure.
20170107	ffortunato		Making sure I get the right IssueId
20170112	ffortunato		actually throwing the error messages now. 
							formatting. app errors vs sql errors.
20170120	ffortunato		publication code is 50. status code 20
20170123	ffortunato		change to parameter list syntax so exe can be 
							generated.
20170131	ffortunato		minor change to error handling and parameter list.
20170222    ffortunato		adding @pStatus Code specifically for LMS. Calling
							system needs to be able to provide a status.
							Replaced +char (13) + Char (10) with @CRLF for 
							readability.
20170315	ffortunato		adding @pETLExecutionId.
							more @CRLF
20171012	ffortunato		cleaning up parameter data types.
20180316	ffortunato		no change. just proving build catches it.
20180802	ffortunato		Need to get some logic for the daily sequence.
20180906	ffortunato		Addressing some warning / validation comments.
20180920	jsardina		Changed from @@Identity to SCOPE_IDENTITY() when
							fetching new issue id after insert.
20181029	ffortunato		figure out the next run time as well...
20181031	ochowkwale		Find the Next Expected Execution Runtime for 
							Publication
20190812	ochowkwale		Added the select for compatibility with Azure Data Factory
20201130	ffortunato		Moving the select of issue id to the endo of the procedure.
20212101	ochowkwale		New issue must not be created if the previous issue is retrying
20210413	ffortunato		Adding SrcIssueName incase vendor cannot meet our naming standards.
							Adding DataLakePath so we can find the feed in the lake.
20210525	ffortunato		Proc should calc the issue name if it is unknown.
******************************************************************************/