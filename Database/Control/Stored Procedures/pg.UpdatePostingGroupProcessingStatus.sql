CREATE Procedure [pg].[UpdatePostingGroupProcessingStatus](
		 @pPostingGroupBatchId		int				= -1
		,@pPostingGroupId			int				= -1
		,@pPostingGroupBatchSeq		int				= -1
		,@pPostingGroupStatusCode	varchar(20)		='PF'
-- Think about adding 
-- @pStartDate				datetime		= NULL
-- @pEndDate                     datetime = NULL
-- as parameters rather than deriving them in the proc.

)as

/*****************************************************************************
file:           UpdatePostingGroupProcessingStatus.sql
name:           UpdatePostingGroupProcessingStatus
purpose:        Set status to appropriate value for the posting group.
				Note: Due to frequency of calls this procedure is no logged in
				steplog.

exec pg.UpdatePostingGroupProcessingStatus(
		 @pPGBId				= -1
		,@pPGId					= -1
		,@pPGBatchSeq			= -1
		,@pPostingGroupStatusCode			='PF'

parameters:   @pPostingGroupStatusCode
    PC    Posting Group Complete
    PF    Posting Group Failed
    PP    Posting Group Processing


called by:      insert on publication
calls:          

author:         ffortunato
date:           20161018


*******************************************************************************
      change history
*******************************************************************************
date      author         description
--------  -------------  ---------------------------------------------------

20170927  ffortunato     new error handling and template.
20180802  ffortunato     messing with status codes/
20180920  ffortunato     quick logging change.
20180921  ffortunato     Need patch sequence too!
20201022  ochowkwale	 Adding the retry logic
******************************************************************************/

-------------------------------------------------------------------------------
--  declarations
-------------------------------------------------------------------------------
declare	 @Rows					int				= 0
        ,@ErrNum				int				= -1
		,@ErrMsg				nvarchar(2048)	= 'N/A'
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
		,@Duration				int				= 0
		,@JSONSnippet			nvarchar(max)	= NULL 
		,@PostingGoupFailure	varchar(5)		= 'PF'
		,@PostingGroupRetry		varchar(5)		= 'PR'
		,@EmailFlag				bit				= 0
		,@Project				varchar(50)		= 'N/A'
		,@Package				varchar(50)		= 'N/A'
		,@DataFactoryName		varchar(50)		= 'N/A'
		,@DataFactoryPipeline	varchar(50)		= 'N/A'
		,@Subject				varchar(255)	= 'N/A'
		,@From					varchar(255)	= 'N/A'
		,@Recipients			varchar(255)	= 'N/A'
		,@Body					varchar(255)	= 'N/A'
		,@Servername			varchar(100)	= @@SERVERNAME
		,@PostingGroupProcessingId int			= 0
-- Procedure Specific Parameters     
		,@ModifiedDtm			datetime		= getdate()
		,@ModifiedBy			varchar(30)		= cast(system_user as varchar(30))
		,@StatusId				int
  
-------------------------------------------------------------------------------
--  initializations
-------------------------------------------------------------------------------
select	 @ParametersPassedChar   	  = @CRLF + '    Parameters Passed: ' + @CRLF +
						'@pPostingGroupId = '   + cast (@pPostingGroupId as varchar (20)) + ' ' + @CRLF +
						'@pPostingGroupBatchId = '  + cast (@pPostingGroupBatchId as varchar (20)) + ' ' + @CRLF +
						'@pPostingGroupBatchSeq = '  + cast (@pPostingGroupBatchSeq as varchar (20)) + ' ' + @CRLF +
						'@pPostingGroupStatusCode = ''' + @pPostingGroupStatusCode + ''''
      
-------------------------------------------------------------------------------
--  main
-------------------------------------------------------------------------------

begin try

select  @StatusId				= StatusId
from    pg.RefStatus			  rs
where   rs.StatusCode			= @pPostingGroupStatusCode

--debug
--print @pStatusCode
IF (@pPostingGroupStatusCode = @PostingGoupFailure)
BEGIN
	SELECT @PostingGroupProcessingId = pr.PostingGroupProcessingId
		,@pPostingGroupStatusCode = CASE WHEN p.RetryMax > pr.RetryCount THEN @PostingGroupRetry	ELSE @PostingGoupFailure END
		,@EmailFlag = CASE WHEN (p.RetryMax <= pr.RetryCount) AND r.StatusCode <> @PostingGoupFailure THEN 1 ELSE 0 END
		,@Project = p.SSISProject
		,@Package = p.SSISPackage
		,@DataFactoryName = p.DataFactoryName
		,@DataFactoryPipeline = p.DataFactoryPipeline
	FROM pg.PostingGroup AS p
	INNER JOIN pg.PostingGroupProcessing AS pr ON pr.PostingGroupId = p.PostingGroupId
	INNER JOIN pg.RefStatus AS r ON r.StatusId = pr.PostingGroupStatusId
	WHERE pr.PostingGroupBatchId = @pPostingGroupBatchId
		AND pr.PostingGroupId = @pPostingGroupId
		AND pr.PGPBatchSeq = @pPostingGroupBatchSeq
		AND p.IsActive = 1
	
	SELECT STRING_AGG(CONVERT(NVARCHAR(max), ISNULL(ct.Email, 'DM-Development@bpiedu.com')), ';')
	FROM pg.PostingGroupProcessing AS pgp
	INNER JOIN pg.MapContactToPostingGroup AS mctp ON mctp.PostingGroupId = pgp.PostingGroupId
	INNER JOIN ctl.Contact AS ct ON ct.ContactId = mctp.ContactId
	WHERE pgp.PostingGroupBatchId = @pPostingGroupBatchId
		AND pgp.PostingGroupId = @pPostingGroupId
		AND pgp.PGPBatchSeq = @pPostingGroupBatchSeq

	--Send Email
	set @Subject =  (@Servername + ' || ' + COALESCE(@Project,@DataFactoryName) + ' Posting Group Failure')

	set @From = CASE WHEN @Servername IN ('DME1EDLSQL01','DEDTEDLSQL01') THEN 'DM-DEV-ETL@zovio.com'
					 WHEN @Servername IN ('QME1EDLSQL01','QME3EDLSQL01') THEN 'DM-QA-ETL@zovio.com'
					 WHEN @Servername IN ('PRODEDLSQL01') THEN 'DM-PROD-ETL@zovio.com'
				END

	set @Recipients = CASE WHEN @EmailFlag = 1 THEN @Recipients 
						   ELSE 'DM-Development@bpiedu.com'
					  END

	set @Body = CHAR(13) + 'SSISProject: ' + @Project + CHAR(13)
			   +'SSISPackage'+Char(9)+': '+ CONVERT(varchar(10),@Package)+CHAR(13)	
			   +'DataFactoryName'+Char(9)+': '+ CONVERT(varchar(10),@DataFactoryName)+CHAR(13)
			   +'DataFactoryPipeline'+Char(9)+': '+ CONVERT(varchar(10),@DataFactoryPipeline)+CHAR(13)
			   +'PostingGroupProcessinsId'+Char(9)+': '+ CONVERT(varchar(10),@PostingGroupProcessingId)+CHAR(13)
			   +'Date'+Char(9)+': '+ CONVERT(varchar(20),@modifiedDtm, 120)+CHAR(13)
			   +'User'+Char(9)+': '+ SYSTEM_USER+CHAR(13)
			   +'Contact'+Char(9)+': BI-Development@zovio.com' +CHAR(13) +CHAR(13)
			   +'Error Messages'+CHAR(13)
			   +'--------------------------------------------------------------------------------------------------'+CHAR(13) +CHAR(13) +CHAR(13)

	exec msdb.dbo.sp_send_dbmail @from_address = @from
		,@recipients = @Recipients
		,@importance = 'High'
		,@subject = @Subject
		,@body = @Body
END

update  PGP
set     PostingGroupStatusId	= @StatusId
       ,StartTime				= Case @pPostingGroupStatusCode when 'PI' then @ModifiedDtm 
													else StartTime end
	   ,EndTime					= Case @pPostingGroupStatusCode when 'PF' then @ModifiedDtm
													when 'PC' then @ModifiedDtm
													else EndTime end
	   ,DurationChar			= 
			case when isnull(StartTime,0) <> 0 then
				isnull(replicate ('0' , 2 - len(cast ((datediff (second, StartTime, @ModifiedDtm) / 3600) as varchar(20)))),'XX') +
				cast ((datediff (second, StartTime, @ModifiedDtm) / 3600) as varchar(20)) + ':' +
				replicate ('0' , 2 - len(cast ((datediff (second, StartTime, @ModifiedDtm) % 3600) / 60 as varchar(20)))) +
				cast ((datediff (second, StartTime, @ModifiedDtm) % 3600) / 60 as varchar(20)) + ':' +
				replicate ('0' , 2 - len(cast ((datediff (second, StartTime, @ModifiedDtm) % 3600) % 60 as varchar(20)))) +
				cast ((datediff (second, StartTime, @ModifiedDtm) % 3600) % 60 as varchar(20))
			else '00:00:00' end
	   ,DurationSec				 = 
			case when isnull(StartTime,0) <> 0 then
				datediff (second, StartTime, @ModifiedDtm )
			else 0 end
       ,ModifiedDtm              = isnull(@ModifiedDtm, getdate())
       ,ModifiedBy               = isnull(@ModifiedBy,cast(system_user as varchar(30)))
from    pg.[PostingGroupProcessing] PGP
where   PGP.PostingGroupId       = @pPostingGroupId
and     PGP.PostingGroupBatchId  = @pPostingGroupBatchId
and		PGP.PGPBatchSeq			 = @pPostingGroupBatchSeq

-------------------------------------------------------------------------------
-- We will check later to see if anything was updated.
-------------------------------------------------------------------------------
select   @Rows                   = @@ROWCOUNT

-------------------------------------------------------------------------------
--  If no records were updated we will throw an error to the calling proc.
-------------------------------------------------------------------------------

select	 @StepName				= 'ErrorTestCondition'
		,@StepNumber			= @StepNumber + 1
		,@StepOperation			= 'validate'
		,@StepDesc				= 'StepDescription'

if @Rows						<= 0 

begin
	select   @ErrNum			= 50001
			,@MessageType		= 'ErrCust'
			,@ErrMsg			= 'Zero records were update in the table ctl.PostingGroupProcessing.'
								  + ' @pPostingGroupId='  + cast(@pPostingGroupId as varchar(10)) 
								  + ' @pPostingGroupBatchId=' + cast(@pPostingGroupBatchId as varchar(10)) 
								  + ' @pPostingGroupBatchSeq=' + cast(@pPostingGroupBatchSeq as varchar(10)) 
								  
	; throw @ErrNum, @ErrMsg, 1  -- This is thrown to the catch block below.
end

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

	exec [audit].usp_CreateStepLogDescription 
			 @MessageType	,@CurrentDtm		,@CurrentDtm	,0		,@StepOperation		,@StepDesc		,@JSONSnippet		,@ErrNum
			,@ErrMsg		,@ParametersPassedChar				,0		,@StepDesc output	,@ErrMsg output	,@Duration output		
			,0	,0	,0

	if 	@ErrNum < 50000	
		select	 @ErrNum	= @ErrNum + 100000000 -- Need to increase number to throw message.

	;throw	 @ErrNum, @ErrMsg, 1
	
end catch
