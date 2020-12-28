CREATE PROCEDURE [ctl].[usp_GetStagedIssueList]
	 @pPublicationCode			varchar(50) 
	,@pStatusCode				varchar(10)			= 'IS'
	,@pVerbose					int = 0
AS

/*****************************************************************************
 File:			GetStagedIssueList.sql
 Name:			GetStagedIssueList
 Purpose:		Returns all publications related to a particular publisher.
				Both Active and InActive publications are returned.
				It is the applications responsibility to decide what to do
				with active or inactive records.

	exec ctl.[GetStagedIssueList] NULL,'IS', 1
	exec ctl.[GetStagedIssueList] 'CNVSRTSQS','IS', 1
	exec ctl.[GetStagedIssueList] 'CNVSRTSQS' ,'IG',1 
	exec ctl.[GetStagedIssueList] 'CANVAS-AB' ,'IG',1 
    exec ctl.usp_GetStagedIssueList 'CNVSRTSQS','IS', 1 


 Parameters:    

 Called by:		Application
 Calls:          

 Author:		ffortunato
 Date:			20170602
*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
 Date		Author			Description
 --------	-------------	-----------------------------------------------------

20170602	ffortunato		adding IsActive indicator to result set.
20171205	jbonilla        adding logic for processing only prior day RT records
20201118	ffortunato		cleaning up warnings, formatting and case. It's my birthday.
******************************************************************************/

DECLARE	 @Rows					int
		,@Err					int
		,@ErrMsg				nvarchar(2000)
		,@FailedProcedure		varchar(1000)
		,@ParametersPassedChar	varchar(1000)
		,@CRLF					varchar(20)


-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------
SELECT	 @Rows					= @@ROWCOUNT
        ,@Err					= 50000
		,@ErrMsg				= 'N/A'
		,@FailedProcedure		= 'Stored Procedure : ' + OBJECT_NAME(@@PROCID) + ' failed.' + Char(13) + Char(10)
		,@CRLF =  char(13) + char(10) -- CR + LF
		,@ParametersPassedChar	=       
			'***** Parameters Passed to exec <schema>.GetStagedIssueList' + @CRLF +
			'     @pPublicationCode = ''' + isnull(@pPublicationCode ,'NULL') + '''' + @CRLF + 
			'    ,@pStatusCode = ''' + isnull(@pStatusCode ,'NULL') + '''' + @CRLF + 
			'    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL') + @CRLF + 
			'***** End of Parameters' + @CRLF 


if		@pVerbose				= 1
begin
		print @ParametersPassedChar
end

-- If not PublisherCode is provided error out.
-- If PublisherCode can't be looked up error out.

begin try

IF @pPublicationCode IS NULL 
or not exists (
SELECT	top 1 1 
	FROM	[ctl].[Publication]	  pn
	WHERE	pn.PublicationCode	= @pPublicationCode)
or not exists (
	SELECT	top 1 1 
	FROM	[ctl].RefStatus	  rs
	WHERE	rs.StatusCode	= @pStatusCode)

begin

	select @ErrMsg				=  'Custom Error: PublicationCode or StatusCode not found. Issue list cannot be created.'

	if		@pVerbose			= 1
	begin
			print				'Message Output: ' + @ErrMsg
	end

	;throw  100001, @ErrMsg, 103
	
end

end try

begin catch

	select	 @Err				= isnull(@@ERROR,@Err)  --@@Error will be zero so make sure to get the right error number with an if.
			,@ErrMsg			= 'ErrorNumber: ' + CAST (@Err as varchar(10)) + char(13)
								+ @FailedProcedure + char(13)
								+ ERROR_MESSAGE () + char(13)
								+ isnull(@ParametersPassedChar, 'Parmeter was NULL')
	;throw  @Err, @ErrMsg, 1

end catch

	-- Return the list of publications.

begin try

if @pPublicationCode = 'CNVSRTSQS' 
BEGIN
	select	 iss.IssueId
			,iss.RecordCount
	from	 ctl.Publication	  pn
	join	 ctl.Issue			  iss
	on		 pn.PublicationId	= iss.PublicationId
	join	 ctl.RefStatus		  stat
	on		 iss.StatusId		= stat.StatusId
	where 	 pn.PublicationCode	= @pPublicationCode
	and      stat.StatusCode	= @pStatusCode
	and		 ReportDate			< cast(getdate()  as date)
END
ELSE 
BEGIN
	select	 iss.IssueId
			,iss.RecordCount
	from	ctl.Publication		  pn
	join	ctl.Issue			  iss
	on		pn.PublicationId	= iss.PublicationId
	join	ctl.RefStatus		  stat
	on		iss.StatusId		= stat.StatusId
	where 	pn.PublicationCode	= @pPublicationCode
	and     stat.StatusCode		= @pStatusCode
END 		
	
end	try

begin catch

	select   @Err				= @@ERROR
			,@ErrMsg			= 'ErrorNumber: ' + CAST (@Err as varchar(10)) + char(13)
								+ @FailedProcedure + char(13) + 'Publication list cannot be created'
								+ ERROR_MESSAGE () + char(13)
								+ isnull(@ParametersPassedChar, 'Parmeter list was NULL')
	;throw  @Err, @ErrMsg, 1

end catch


