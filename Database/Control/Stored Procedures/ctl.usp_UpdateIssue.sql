﻿CREATE PROCEDURE [ctl].[usp_UpdateIssue] (	
		 @pIssueId				int				= -1
		,@pStatusCode			varchar(20)		= NULL
		,@pReportDate			datetime		= NULL
		,@pSrcDFPublisherId		varchar(40)		= NULL
		,@pSrcDFPublicationId	varchar(40)		= NULL
		,@pSrcDFIssueId			varchar(100)	= NULL
		,@pSrcDFCreatedDate		datetime		= NULL
		,@pDataLakePath			varchar(1000)	= NULL
		,@pIssueName			varchar(255)	= NULL
		,@pSrcIssueName			nvarchar(255)	= NULL
		,@pPublicationSeq		int				= NULL
		,@pFirstRecordSeq		int				= NULL
		,@pLastRecordSeq		int				= NULL
		,@pFirstRecordChecksum	varchar(2048)	= NULL
		,@pLastRecordChecksum	varchar(2048)	= NULL
		,@pPeriodStartTime		datetime		= NULL
		,@pPeriodEndTime		datetime		= NULL
		,@pIssueConsumedDate	datetime		= NULL
		,@pRecordCount			int				= NULL
		,@pModifiedBy			varchar(50)		= NULL
		,@pModifiedDtm			datetime		= NULL
		,@pVerbose				bit				= 0
		,@pETLExecutionId		int				= NULL)
AS 
/*****************************************************************************
File:			usp_UpdateIssue.sql
Name:			usp_UpdateIssue
Purpose:        Updates the issue table with any values the application
				wishes to add. If a value is null the value currently in the 
				table is retained.

exec ctl.usp_UpdateIssue 17, 'IC', 1

Parameters:

Called by:		Application
Calls:

Error:			50001 Unable to lookup Status.
				50002 Unable to lookup Issue

Author:			ffortunato
Date:			20170106
*******************************************************************************
CHANGE HISTORY
*******************************************************************************
Date		Author		Description
--------	-------------	---------------------------------------------------
20170106	ffortunato		Initial iteration
20170120	ffortunato		STatus code should be varchar(20)
			gopala			Made parameters default to null.
20170126	ffortunato		Throwing errors (replacing raiserror)
							replacing @ParametersPassedChar with latest format
							issueId cannot be null.
							subscriptionId no longer needed.
20180321	ffortunato		Had to rebaseline for error handling. Made some 
							changes to use case statements rather than just
							isnull
20180913	ffortunato		Add ETLExecutionId
20190603	ochowkwale		In case of failure, check for number of retries and 
							then set the issue to failed or to be retried. Send
							email in case of failure
20210316	ffortunato		Add SrcIssueName
20210412	ffortunato		@pDataLakePath	

******************************************************************************/
declare	 @Rows					integer
		,@Err					integer
		,@ErrMsg				nvarchar(3182)
		,@FailedProcedure		varchar(1000)
		,@CRLF					varchar(20)		= char(13) + char(10)
		,@ParametersPassedChar	nvarchar(2048)
		,@ModifiedDtm			datetime
		,@CurrentDtm			datetime
		,@ModifiedBy			varchar(50)
		,@StatusId				integer
		,@StatusType			varchar(30)
		,@IssueRetry			varchar(2)
		,@IssueFail				varchar(2)
		,@Severity				int
		,@Servername			varchar(20)
		,@From					varchar(50) 
		,@Recipients			varchar(1000)
		,@Project				varchar(255) 
		,@Package				varchar(255)
		,@DataFactoryPipeline	varchar(255)
		,@DataFactoryName		varchar(255)
		,@Subject				varchar(100)
		,@Body					nvarchar(max)
		,@Query					nvarchar(max)

declare  @IssueComplete			table (
		 DistributionId			int
		,IssueId				int
		,DistStatusCode			varchar(20)
		,TotalCount				int
		,CompleteCount			int)

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------
SELECT	 @Rows					= -1
		,@Err					= -1
		,@ErrMsg				= 'N/A'
		,@FailedProcedure		= 'Stored Procedure : ' + OBJECT_NAME(@@PROCID) + ' failed.' + @CRLF
		,@ModifiedDtm			= GETDATE()
		,@CurrentDtm			= GETDATE()
		,@ModifiedBy			= SYSTEM_USER
		,@Servername			= @@SERVERNAME
		,@StatusId				= -1 -- NULL -- Chose null to make update clause easy
		,@StatusType			= 'Issue'
		,@IssueRetry			= 'IR'
		,@IssueFail				= 'IF'
		,@Recipients			= 'Bi-Notify@zovio.com'

select	 @ParametersPassedChar	=
      '***** Parameters Passed to exec ctl.usp_UpdateIssue' + @CRLF +
      '     @pIssueId = ' + isnull(cast(@pIssueId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pStatusCode = ''' + isnull(@pStatusCode ,'NULL') + '''' + @CRLF + 
      '    ,@pReportDate = ''' + isnull(convert(varchar(100),@pReportDate ,13) ,'NULL') + '''' + @CRLF + 
      '    ,@pSrcDFPublisherId = ''' + isnull(@pSrcDFPublisherId ,'NULL') + '''' + @CRLF + 
      '    ,@pSrcDFPublicationId = ''' + isnull(@pSrcDFPublicationId ,'NULL') + '''' + @CRLF + 
      '    ,@pSrcDFIssueId = ''' + isnull(@pSrcDFIssueId ,'NULL') + '''' + @CRLF + 
      '    ,@pSrcDFCreatedDate = ''' + isnull(convert(varchar(100),@pSrcDFCreatedDate ,13) ,'NULL') + '''' + @CRLF + 
      '    ,@pIssueName = ''' + isnull(@pIssueName ,'NULL') + '''' + @CRLF + 
      '    ,@pSrcIssueName = ''' + isnull(@pSrcIssueName ,'NULL') + '''' + @CRLF + 
      '    ,@pPublicationSeq = ' + isnull(cast(@pPublicationSeq as varchar(100)),'NULL') + @CRLF + 
      '    ,@pFirstRecordSeq = ' + isnull(cast(@pFirstRecordSeq as varchar(100)),'NULL') + @CRLF + 
      '    ,@pLastRecordSeq = ' + isnull(cast(@pLastRecordSeq as varchar(100)),'NULL') + @CRLF + 
      '    ,@pFirstRecordChecksum = ''' + isnull(@pFirstRecordChecksum ,'NULL') + '''' + @CRLF + 
      '    ,@pLastRecordChecksum = ''' + isnull(@pLastRecordChecksum ,'NULL') + '''' + @CRLF + 
      '    ,@pPeriodStartTime = ''' + isnull(convert(varchar(100),@pPeriodStartTime ,13) ,'NULL') + '''' + @CRLF + 
      '    ,@pPeriodEndTime = ''' + isnull(convert(varchar(100),@pPeriodEndTime ,13) ,'NULL') + '''' + @CRLF + 
      '    ,@pIssueConsumedDate = ''' + isnull(convert(varchar(100),@pIssueConsumedDate ,13) ,'NULL') + '''' + @CRLF + 
      '    ,@pRecordCount = ' + isnull(cast(@pRecordCount as varchar(100)),'NULL') + @CRLF + 
      '    ,@pModifiedBy = ''' + isnull(@pModifiedBy ,'NULL') + '''' + @CRLF + 
      '    ,@pModifiedDtm = ''' + isnull(convert(varchar(100),@pModifiedDtm ,13) ,'NULL') + '''' + @CRLF + 
      '    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL') + @CRLF + 
      '    ,@pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
      '***** End of Parameters' + @CRLF 

--	  raiserror ( @ParametersPassedChar, 16,1)

-------------------------------------------------------------------------------
--  Main
-------------------------------------------------------------------------------
--Switch the status to IR if MaxRetry limit has not reached
IF (@pStatusCode = @IssueFail)
BEGIN
	SELECT @pStatusCode				= CASE WHEN (i.RetryCount >= c.RetryMax) OR (DATEADD(mi,SLAEndTimeInMinutes,i.CreatedDtm) < @CurrentDtm) 
										THEN @IssueFail ELSE @IssueRetry END
		,@Severity					= CASE WHEN (c.RetryMax <= i.RetryCount) AND r.StatusCode <> @IssueFail 
										THEN 1 ELSE 0 END
		,@Project					= c.SSISProject
		,@Package					= c.SSISPackage
		,@DataFactoryName			= c.DataFactoryName
		,@DataFactoryPipeline		= c.DataFactoryPipeline
	FROM	 ctl.Publication		  c
	JOIN	 ctl.Issue				  i 
	ON		 i.PublicationId		= c.PublicationId
	JOIN	 ctl.RefStatus			  r 
	ON		 i.StatusId				= r.StatusId
	WHERE	 i.IssueId				= @pIssueId
	AND		 c.IsActive				= 1
	AND		 c.IsDataHub			= 1 -- IN (1,2)
	--AND		 c.ProcessingMethodCode in ('ADFP','SSIS')

	SELECT @Recipients = STRING_AGG(CONVERT(NVARCHAR(max), ISNULL(ct.Email, 'DM-Development@bpiedu.com')), ';')
	FROM ctl.Issue AS i
	LEFT JOIN ctl.MapContactToPublication AS mctp 
	ON mctp.PublicationId = i.PublicationId
	LEFT JOIN ctl.Contact AS ct 
	ON ct.ContactId = mctp.ContactId
	WHERE i.IssueId = @pIssueId

	--Send Email
	EXEC ctl.usp_SendMail 		 
		 @pProject				= @Project
		,@pPackage				= @Package
		,@pDataFactoryName		= @DataFactoryName
		,@pDataFactoryPipeline	= @DataFactoryPipeline
		,@pTo					= @Recipients
		,@pSeverity				= @Severity
		,@pIssueId				= @pIssueId

END

begin try

-- Check to see if a status change is being provided 
-- (wheter it is changing or not) Look up the associated statusid

if	@pStatusCode				is not null

	select	@StatusId			= isnull(StatusId,-1)
	from	ctl.RefStatus		  rst
	where	StatusCode			= @pStatusCode
	and		StatusType			= @StatusType

if @pVerbose					= 1 begin
	print ' @StatusId	 : '	+ cast(@StatusId as varchar(20))
	print ' @pStatusCode : '	+ cast(@pStatusCode as varchar(20))
end

end try

begin catch

	select	 @Err				= @@ERROR
			,@ErrMsg			= @FailedProcedure + @CRLF + ERROR_MESSAGE() 
								+ @CRLF + @ParametersPassedChar
	;throw	 @Err, @ErrMsg, 1

end catch

if @pVerbose = 1 begin
	print 'Issue Id: '			+ cast(@pIssueId as varchar(30))
	print 'Status Id: '			+ cast(@statusid as varchar(30))
	print @ParametersPassedChar
end

-- Could not look up apprporiate status code
if (@StatusId					= -1  
   and @pStatusCode				is not null) begin 
   	
	select @Err					= 50001
	select @ErrMsg				= @FailedProcedure 
								+ 'Lookup data not found. A bad '
								+ 'status code ' + @pStatusCode 
								+ ' was passed into the procedure. ' + @CRLF
								+ @ParametersPassedChar
	;throw	 @Err, @ErrMsg, 1

end

if not exists					(select	top 1 1 
								from	ctl.Issue 
								where	IssueId  = @pIssueId) begin
	
	select	@Err				= 50002
	select	@ErrMsg				= @FailedProcedure 
								+ 'ErrorNumber: ' + CAST (@Err as varchar(10)) + @CRLF
								+ 'Lookup data not found. A bad '
								+ 'issue id  was passed: ' 
								+ cast(@pIssueId as varchar(20)) + @CRLF
								+ @ParametersPassedChar
	;throw	 @Err, @ErrMsg, 1

end

begin try

update   ISS
set      StatusId				= case  @StatusId when -1 then StatusId -- Keep the value in the table.
								  else  @StatusId end -- Use the new value based on passed code.
		,ReportDate				= isnull(@pReportdate,ReportDate)
		,SrcDFPublisherId		= case
									when	((@pSrcDFPublisherId is null) or (len(@pSrcDFPublisherId) < 1)) then ISS.SrcDFPublisherId
									else    @pSrcDFPublisherId
								  end
		,SrcDFPublicationId		= case
									when	((@pSrcDFPublicationId is null) or (len(@pSrcDFPublicationId) < 1)) then ISS.SrcDFPublicationId
									else    @pSrcDFPublicationId
								  end
		,SrcDFIssueId			= case
									when	((@pSrcDFIssueId is null) or (len(@pSrcDFIssueId) < 1)) then ISS.SrcDFIssueId
									else    @pSrcDFIssueId
								  end
		,SrcDFCreatedDate		= isnull(@pSrcDFCreatedDate,	SrcDFCreatedDate)
		,DataLakePath			= case
									when	((@pDataLakePath is null) or (len(@pDataLakePath) < 1)) then ISS.DataLakePath
									else    @pDataLakePath
								  end
		,IssueName				= case
									when	((@pIssueName is null) or (len(@pIssueName) < 1)) then ISS.IssueName
									else    @pIssueName
								  end
		,SrcIssueName				= case
									when	((@pSrcIssueName is null) or (len(@pSrcIssueName) < 1)) then ISS.SrcIssueName
									else    @pSrcIssueName
								  end
		,PublicationSeq			= case
									when	((@pPublicationSeq is null) or 
											(isnumeric(@pPublicationSeq) = 0) 	or 
											(@pPublicationSeq = -1)) 
									then	ISS.PublicationSeq
									else    @pPublicationSeq
								  end
		,FirstRecordSeq			= isnull(@pFirstRecordSeq,FirstRecordSeq)
		,LastRecordSeq			= isnull(@pLastRecordSeq,LastRecordSeq)
		,FirstRecordChecksum	= isnull(@pFirstRecordChecksum,FirstRecordChecksum)
		,LastRecordChecksum		= isnull(@pLastRecordChecksum,LastRecordChecksum)
		,PeriodStartTime		= isnull(@pPeriodStartTime,PeriodStartTime)
		,PeriodEndTime			= isnull(@pPeriodEndTime,PeriodEndTime)
		,IssueConsumedDate		= isnull(@pIssueConsumedDate,IssueConsumedDate)
		,RecordCount			= isnull(@pRecordCount,RecordCount)
		,ETLExecutionID			= case
									when	((@pEtlExecutionId is null) or (@pEtlExecutionId < 1)) then ISS.ETLExecutionID
									else    @pEtlExecutionId
								  end
		,ModifiedBy				= isnull(@pModifiedBy,@ModifiedBy)
		,ModifiedDtm			= isnull(@pModifiedDtm,@ModifiedDtm)
from     ctl.[Issue]			  ISS
where    IssueId				= @pIssueId

end try-- main

begin catch
    select   @Err				= @@ERROR
            ,@ErrMsg			= 'ErrorNumber: ' + CAST (@Err as varchar(10)) + char(13)
								+ @ErrMsg + char(13) + ERROR_MESSAGE () + char(13)
								+ isnull(@ParametersPassedChar, 'Parm was NULL')

	if @Err < 50000  select @Err = @Err + 1000000
	;throw  @Err, @ErrMsg, 1

end catch

-------------------------------------------------------------------------------
-- End
-------------------------------------------------------------------------------
