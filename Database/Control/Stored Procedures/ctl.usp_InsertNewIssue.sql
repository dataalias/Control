CREATE PROCEDURE [ctl].[usp_InsertNewIssue] (	
	 @pPublicationCode			varchar(50)
	,@pIssueName				varchar(255)	= null
	,@pStatusCode				varchar(20)		= null
	,@pSrcDFIssueId				varchar(100)	= null
	,@pSrcDFCreatedDate			datetime		= null
	,@pFirstRecordSeq			integer
	,@pLastRecordSeq			integer
	,@pFirstRecordChecksum		varchar(2048)
	,@pLastRecordChecksum		varchar(2048)
	,@pPeriodStartTime			datetime
	,@pPeriodEndTime			datetime
	,@pRecordCount				integer
	,@pETLExecutionId			int				= null
	,@pCreateBy					varchar(30)
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

declare @MyIssueId int 
exec ctl.[usp_InsertNewIssue] 
	@pPublicationCode= 'ACCOUNTDIM-AU'
	,@pIssueName= 'account_dim_20070112.txt'
	,@pStatusCode= 'IP'
	,@pSrcDFIssueId= '0'
	,@pSrcDFCreatedDate= '1/2/2017'
	,@pFirstRecordSeq= 1
	,@pLastRecordSeq= 100
	,@pFirstRecordChecksum= 'ABC'
	,@pLastRecordChecksum= 'DEF'
	,@pPeriodStartTime= '01/01/2017 00:00:00'
	,@pPeriodEndTime= '01/01/2017 00:00:00'
	,@pRecordCount= 100
	,@pETLExecutionId= 99
	,@pCreateBy= 'ffortunato'
	,@pIssueId = @MyIssueId output
	,@pVerbose= 0


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

*******************************************************************************
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

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------
SELECT	 @ROWS					= @@ROWCOUNT
		,@ERR					= @@ERROR
		,@ErrMsg				= 'N/A'
		,@FailedProcedure		= 'Stored Procedure : ' + OBJECT_NAME(@@PROCID) + ' failed.' + @CRLF
		,@CreatedDate			= GETDATE()
		,@PublicationId			= -1
		,@PublicationSeq		= -1
		,@DailyPublicationSeq	= -1
		,@StatusId				= -1
--		,@StatusCode			= 'IP'   -- Normal Starting Status (todo: allow this to be passed from calling application.)
		,@StatusType			= 'Issue'
		,@pCreateBy				= isnull(@pCreateBy,SYSTEM_USER)
		,@ParametersPassedChar	= @CRLF +
			'***** Parameters Passed to Control.ctl.usp_InsertNewIssue' + @CRLF +
			'@pPublicationCode = ''' + isnull(@pPublicationCode ,'NULL') + '''' + @CRLF + 
			'@pStatusCode = ''' + isnull(@pStatusCode ,'NULL') + '''' + @CRLF + 
			'@pIssueName = ''' + isnull(@pIssueName ,'NULL') + '''' + @CRLF + 
			'@pSrcDFIssueId = ''' + isnull(@pSrcDFIssueId ,'NULL') + '''' + @CRLF + 
			'@pSrcDFCreatedDate = ' + isnull(cast(@pSrcDFCreatedDate as varchar(100)),'NULL') + @CRLF + 
			'@pFirstRecordSeq = ' + isnull(cast(@pFirstRecordSeq as varchar(100)),'NULL') + @CRLF + 
			'@pLastRecordSeq = ' + isnull(cast(@pLastRecordSeq as varchar(100)),'NULL') + @CRLF + 
			'@pFirstRecordChecksum = ' + isnull(cast(@pFirstRecordChecksum as varchar(100)),'NULL') + @CRLF + 
			'@pLastRecordChecksum = ' + isnull(cast(@pLastRecordChecksum as varchar(100)),'NULL') + @CRLF + 
			'@pPeriodStartTime = ' + isnull(cast(@pPeriodStartTime as varchar(100)),'NULL') + @CRLF + 
			'@pPeriodEndTime = ' + isnull(cast(@pPeriodEndTime as varchar(100)),'NULL') + @CRLF + 
			'@pRecordCount = ' + isnull(cast(@pRecordCount as varchar(100)),'NULL') + @CRLF + 
			'@pCreateBy = ''' + isnull(@pCreateBy ,'NULL') + '''' + @CRLF + 
			'@pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
			'@pIssueId = ' + isnull(cast(@pIssueId as varchar(100)),'NULL') + @CRLF + 
			'@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL') + @CRLF + 
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

begin try

begin tran NEWISSUE

INSERT INTO ctl.Issue (
		 PublicationId
		,StatusId
		,ReportDate
		,SrcDFIssueId
		,SrcDFCreatedDate
		,IssueName
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
		,isnull(@pSrcDFCreatedDate,@CreatedDate) --Truncate to day with the line below.
		--,cast(convert(char(11), isnull(@pSrcDFCreatedDate,@CreatedDate), 113) as datetime)
		,@pSrcDFIssueId 
		,@pSrcDFCreatedDate
		,coalesce(@pIssueName,'Unknown')
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
IF (@pIssueName IS NULL or len(@pIssueName) < 1)
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

--added the select statement for azure data factory compatibility
--record set needs to be returned rather than using the parameter
select  @pIssueId as IssueId

return
