CREATE PROCEDURE [ctl].[usp_GetIssueStatistics] (
		 @pPublisherCode			varchar(50)
		,@pStatusCode				varchar(20)
		,@pPeriodStart				datetime		= NULL
		,@pPeriodEnd				datetime		= NULL
		,@pTotalCount				int				output
		,@pIssuePending				int				output
		,@pIssueStaged				int				output
		,@pIssueComplete			int				output
		,@pIssueFailed				int				output
		,@pIsComplete				bit				output
		,@pVerbose					bit				= 0)
AS
/*****************************************************************************
File:		GetIssueStatistics.sql
Name:		GetIssueStatistics
Purpose:	

declare  @pTotalCount				int = -1
		,@pIssuePending				int = -1
		,@pIssueStaged				int = -1
		,@pIssueComplete			int = -1
		,@pIssueFailed				int = -1
		,@pIsComplete				int = -1
		,@RC int = -1

exec @RC = ctl.usp_GetIssueStatistics
	 @pPublisherCode = 'CANVAS-AU'
	,@pStatusCode = 'IP'
	,@pPeriodStart = '01 Jan 2014 21:21:21:213'
	,@pPeriodEnd = '01 Jan 2300 00:00:00:000'
	,@pTotalCount = @pTotalCount output 
	,@pIssuePending = @pIssuePending output 
	,@pIssueStaged = @pIssueStaged output 
	,@pIssueComplete = @pIssueComplete output 
	,@pIssueFailed = @pIssueFailed output 
	,@pIsComplete = @pIsComplete output 
	,@pVerbose = 1

		print '@pTotalCount: ' + cast(			@pTotalCount			as varchar(100))
		print '@pIssuePending: ' + cast(		@pIssuePending			as varchar(100))
		print '@pIssueStaged: ' + cast(			@pIssueStaged			as varchar(100))
		print '@pIssueComplete: ' + cast(		@pIssueComplete			as varchar(100))
		print '@pIssueFailed: ' + cast(			@pIssueFailed			as varchar(100))
		print '@pIsComplete: ' + cast(			@pIsComplete			as varchar(100))
		print '@RC: ' + cast(			@RC			as varchar(100))

Parameters:    

Called by:	
Calls:          

Errors:		

Author:		
Date:		

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20210329	ffortunato		clearing out warnings.

******************************************************************************/

-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------

DECLARE	 @Rows						int
        ,@ErrNum					int
		,@ErrMsg					nvarchar(2048)
		,@FailedProcedure			varchar(1000)
		,@ParametersPassedChar		varchar(1000)
		,@CRLF						varchar(10)		= char(13) + char(10)


declare  @GetIssueStatistics		table(
		 TotalCount					int
		,IssuePending				int
		,IssueStaged				int
		,IssueComplete				int
		,IssueFailed				int
		,IsComplete					bit)

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------
SELECT	 @ErrNum					= -1
		,@ErrMsg					= 'N/A'
		,@FailedProcedure			= 'Stored Procedure : ' + OBJECT_NAME(@@PROCID) 
									  + ' failed.' + @CRLF
		,@pTotalCount				= -1
		,@pIssuePending				= -1
		,@pIssueStaged				= -1
		,@pIssueComplete			= -1
		,@pIssueFailed				= -1
		,@pIsComplete				= 0
		,@ParametersPassedChar	= @CRLF +
			'***** Parameters Passed to usp_GetIssueStatistics' + @CRLF +
			'	 @pPublisherCode = ''' + isnull(@pPublisherCode ,'NULL') + '''' + @CRLF + 
			'	,@pStatusCode = ''' + isnull(@pStatusCode ,'NULL') + '''' + @CRLF + 
			'	,@pPeriodStart = ''' + isnull(convert(varchar(100),@pPeriodStart ,13) ,'NULL') + '''' + @CRLF + 
			'	,@pPeriodEnd = ''' + isnull(convert(varchar(100),@pPeriodEnd ,13) ,'NULL') + '''' + @CRLF + 
			'	,@pTotalCount = @pTotalCount output ' + @CRLF +
			'	,@pIssuePending = @pIssuePending output ' + @CRLF +
			'	,@pIssueStaged = @pIssueStaged output ' + @CRLF +
			'	,@pIssueComplete = @pIssueComplete output ' + @CRLF +
			'	,@pIssueFailed = @pIssueFailed output ' + @CRLF +
			'	,@pIsComplete = @pIsComplete output ' + @CRLF +
			'	,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL') + @CRLF + 
			'***** End of Parameters' + @CRLF 


if @pVerbose					= 1
	begin 
		print @ParametersPassedChar
	end

-------------------------------------------------------------------------------
--  Main
-------------------------------------------------------------------------------
begin try

	insert into @GetIssueStatistics (
			 TotalCount
			,IssuePending
			,IssueStaged
			,IssueComplete
			,IssueFailed
			,IsComplete)
	select	 TotalCount				= count(1)
			,IssuePending			= sum(case when rs.StatusCode = 'IP'
		                                      then 1 else 0 
											  end) 
			,IssueStaged			= sum(case when rs.StatusCode = 'IP'
		                                      then 1 else 0 
											  end) 
			,IssueComplete			= sum(case when rs.StatusCode = 'IC'
		                                      then 1 else 0 
											  end) 
			,IssueFailed			= sum(case when rs.StatusCode = 'IF'
		                                      then 1 else 0 
											  end)
			,IsComplete				= 0 			
	from	ctl.Issue				  iss
	join	ctl.RefStatus			  rs
	on		iss.StatusId			= rs.StatusId
	join	ctl.Publication			  pubn
	on		iss.PublicationId		= pubn.PublicationId
	join	ctl.Publisher			  pubr
	on		pubr.PublisherId		= pubn.PublisherId
	where	pubr.PublisherCode		= @pPublisherCode
	and		iss.CreatedDtm			  between @pPeriodStart and @pPeriodEnd


	update	@GetIssueStatistics
	set		IsComplete				= case when	TotalCount = IssueComplete then 1
									  else 0 end

	select 	 @pTotalCount			= TotalCount
			,@pIssuePending			= IssuePending	
			,@pIssueStaged			= IssueStaged
			,@pIssueComplete		= IssueComplete
			,@pIssueFailed			= IssueFailed
			,@pIsComplete			= IsComplete
	from	@GetIssueStatistics

end try

begin catch

	select	 @ErrNum			= @@ERROR
			,@ErrMsg			= 'ErrorNumber: ' 
								+ CAST (@ErrNum as varchar(10)) + @CRLF
								+ @FailedProcedure + @CRLF 
								+ 'SQL Server Error: ' + @CRLF
								+ ERROR_MESSAGE () + @CRLF
								+ isnull(@ParametersPassedChar, 'Parmeter was NULL')

	if @ErrNum < 50000  select @ErrNum = @ErrNum + 1000000
	;throw	 @ErrNum, @ErrMsg, 1	-- Sql Server Error

end catch


