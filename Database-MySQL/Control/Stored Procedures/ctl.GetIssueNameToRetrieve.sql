CREATE PROCEDURE [ctl].[GetIssueNamesToRetrieve] (
		 @pIssueNameLookup		ctl.udt_IssueNameLookup READONLY
		,@pPublicationCode      varchar(50)     = 'N/A'
		,@pLookBack				datetime		= Null
		,@pETLExecutionId		int				= -1
		,@pPathId				int				= -1
		,@pVerbose				bit				= 0)
AS
/*****************************************************************************
File:		GetIssueNamesToRetrieve.sql
Name:		GetIssueNamesToRetrieve

Purpose:	This procedure accpets a list of files that datahub has found on a 
			publisher file share (noramlly ftp / sftp site). The procedure 
			returns a subset list of those files that have not been processed.
			This list will be used by powersehll to inititate a file transfer.

exec:

	declare @MyTable [ctl].[udt_IssueNameLookup]

	insert into @MyTable
	select 'Frank','Open',getdate()

	select * from @MyTable

	exec ctl.GetIssueNamesToRetrieve
			 @pIssueNameLookup		= @MyTable
			,@pPublicationCode      = 'N/A'
			,@pLookBack				= Null
			,@pETLExecutionId		= -1
			,@pPathId				= -1
			,@pVerbose				= 0

Parameters:   
			 @pIssueNameLookup		Table of vaules to be processed
			,@pPublicationCode      Publication Codes to be evaulated
			,@pLookBack				Determines how far back you want to search for a file.
			,@pETLExecutionId		 
			,@pPathId				 
			,@pVerbose				 

Called by:	DataHub powershell scripts
Calls:          

Errors:		

Author:		
Date:		

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20180222	ffortunato		getting ready for build. 23
20180705	ffortunato		Need to preserver the order the fils came in.
							Modifying the input table to include LastWriteTime
20180906	ffortunato		code validation changes dbnam varchar(20) 
							message (20).
20181004	ffortunato		changing in clause to where exists. Improving join.
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

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

SELECT	 @ParametersPassedChar	= 
			'exec bpi_dw_stage.ctl.GetIssueNamesToRetrieve' + @CRLF +
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

	if @pLookBack is null
		set @pLookBack = dateadd (d,-180,getdate())

-------------------------------------------------------------------------------
--  Step comment
-------------------------------------------------------------------------------
	select	 @StepName			= 'Select files to download'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Operation'
			,@StepDesc			= 'Compares input list to ctl.issue and outputs any files not already staged.'

	select	 IssueName			as IssueName
			,'Get'				as FileAction
			,FileCreatedDtm		as FileCreatedDtm
	from	 @pIssueNameLookup	  inl
	where	 not exists (
		select	 top 1 1 
		from	 ctl.Issue			  i
		join	 ctl.Publication	  pn
		on		 i.PublicationId	= pn.PublicationId
		where	 pn.PublicationCode = @pPublicationCode
		and		 i.CreatedDtm		> @pLookBack
		and		 inl.IssueName      = i.IssueName)
/*
	where	 inl.IssueName		  not in (
		select	 i.IssueName
		from	 ctl.Issue			  i
		join	 ctl.Publication	  pn
		on		 pn.PublicationCode = @pPublicationCode
		where	 i.CreatedDtm		> @pLookBack)
*/
	-- Upon completion of the step, log it!
	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()
			--,@JSONSnippet		= '<JSON Snippet>' -- Only if needed.
/*
			-- TESTING
			declare @x varchar(299)
			select top 1 @x= 'Issue: ' + IssueName from @pIssueNameLookup 
			select @x=@x + ' Rows: ' + CAST(@Rows AS VARCHAR(10))
			select @JSONSnippet	 = '{"Dump":"'+@x+'"}'
*/

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
