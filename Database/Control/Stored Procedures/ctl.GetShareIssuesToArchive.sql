CREATE PROCEDURE [ctl].[GetShareIssuesToArchive] (
		 @pETLExecutionId		int				= -1
		,@pPathId				int				= -1
		,@pVerbose				bit				= 0)
AS
/*****************************************************************************
File:		GetShareIssuesToArchive.sql
Name:		GetShareIssuesToArchive
Purpose:	

exec [ctl].[GetShareIssuesToArchive] -1, -1, 1

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
20180312	ffortunato		Adding the status of ILDW as files to archive.
20180320	ffortunato		Removing testing code.
20180717	ffortunato		Adding some new statuses. removing some logging.
20180905	ffortunato		PublisherType --> InterfaceCode.

******************************************************************************/

-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------

DECLARE	 @Rows					int				= 0
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
		,@LookBack				datetime		= dateadd(d,-1,getdate()) -- Look back one day.

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

SELECT	 @ParametersPassedChar	= 
			'exec Control.ctl.GetIssuesToArchive' + @CRLF +
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
--  Identifies files that are potentially in inbound directories and moves 
--  them to archive.
-------------------------------------------------------------------------------
	select	 @StepName			= 'Get Issue List to Archive'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Select'
			,@StepDesc			= 'Identifies files that are potentially in inbound directories and moves them to archive.'

	select	 iss.IssueId
			,iss.IssueName
			,pn.PublicationEntity
			,pn.PublicationFilePath
			,pn.PublicationArchivePath
	from	 ctl.Issue			  iss
	join	 ctl.Publication	  pn
	on		 iss.PublicationId	= pn.PublicationId
	join	 ctl.RefStatus		  rs
	on		 rs.StatusId		= iss.StatusId
	join	 ctl.Publisher		  pr
	on		 pr.PublisherId		= pn.PublisherId
	where	 rs.StatusCode		  in ('IC','IA','IN') 
	and		 pr.InterfaceCode	  in ('SHARE','FTP','SFTP')
	and		 iss.CreatedDtm		> @Lookback

	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			--,@JSONSnippet		= '{"":""}'

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
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
			,@CurrentDtm		= getdate()

	if		 @MessageType		<> 'ErrCust'
		select   @MessageType	= 'ErrSQL'

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
			,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

	if 	@ErrNum < 50000	
		select	 @ErrNum	= @ErrNum + 100000000 -- Need to increase number to throw message.

	;throw	 @ErrNum, @ErrMsg, 1
	
end catch

-------------------------------------------------------------------------------
--  Procedure End
-------------------------------------------------------------------------------
