CREATE PROCEDURE [ctl].[usp_GetOutboundPublication] (
	 @pPublicationCode			varchar(50)
	,@pETLExecutionId			int				= -1
	,@pPathId					int				= -1
	,@pVerbose					bit				= 0)
AS
/*****************************************************************************
File:			GetOutboundPublication.sql
Name:			usp_GetOutboundPublication
Purpose:		Gets the outbound publication details like source file path 
				where the data is going to be extracted

Parameters:	@pPublicationCode

EXEC [ctl].[usp_GetOutboundPublication] 
	 @pPublicationCode			= 'CHAT-TRFC-EXP'
	,@pETLExecutionId			= -1
	,@pPathId					= -1
	,@pVerbose					= 0

Called by:		Application
Calls:          

Author:		ochowkwale
Date:		03052019

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20190305	ochowkwale		Initial creation	
20191017	xli				Adding NextExecutionDtm as a return Parameter
20210415	ffortunato		feedformat --> SrcFileFormat TAXES!!!
20210415	ffortunato		Need some new parameters:
								
******************************************************************************/

-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------

DECLARE	 @Rows					int				= 0
		,@Err					int
		,@ErrNum				int				= -1
		,@ErrMsg				nvarchar(max)	= 'N/A'
		,@FailedProcedure		varchar(1000)
		,@ParametersPassedChar	varchar(1000)   = 'N/A'
		,@CRLF					varchar(10)		= char(13) + char(10)
		,@ProcName				varchar(256)	= OBJECT_NAME(@@PROCID) 
		,@ParentStepLogId		int				= -1
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
		,@CreatedDate			datetime		= getdate()
		,@PublisherId			int				= -1  -- Intentionally setting this to a bad value for the check later on.

exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@ParentStepLogId output	
		,@pVerbose

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

SELECT	 @ParametersPassedChar	= 
      '***** Parameters Passed to exec ctl.usp_GetOutboundPublication' + @CRLF +
      '    ,@pPublicationCode = ''' + isnull(@pPublicationCode ,'NULL') + '''' + @CRLF + 
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

begin try
	select	 @StepName			= 'Select Outbound Publication'
			,@StepNumber		= @StepNumber + 1
			,@StepOperation		= 'Select'
			,@StepDesc			= 'Select outbound Publication Details to be passed onto file creations'
			,@JSONSnippet		= NULL

	IF EXISTS (SELECT 1
		FROM ctl.Publication
		WHERE PublicationCode = @pPublicationCode
			AND Bound = 'Out')
	BEGIN
		SELECT SrcPublicationName
			,SrcFilePath
			,SrcFileFormatCode		As FeedFormat  -- This is being renamed for backward compatibility.
			,NextExecutionDtm
			,PublicationCode
			,PublicationName
			,SrcPublicationCode
			--,SrcPublicationName
			,PublicationEntity
			,PublicationFilePath
			,PublicationArchivePath
			--  ,SrcFilePath
			,SrcFileRegEx
			,SrcDeltaAttributes
			,DestTableName
			--   ,SrcFileFormatCode
			,StandardFileRegEx
			,StandardFileFormatCode
			,ProcessingMethodCode
--			,MethodCode
			,TransferMethodCode
			,StorageMethodCode
			,StageJobName
			,SSISFolder
			,SSISProject
			,SSISPackage
			,DataFactoryName
			,DataFactoryPipeline
			,IntervalCode
			,IntervalLength
			,SLATime
			,SLAEndTimeInMinutes
			--   ,NextExecutionDtm
			,IsActive
			,IsDataHub
			,Bound
			,RetryMax
			,RetryIntervalCode
			,RetryIntervalLength
			,PublicationGroupSequence
			,PublicationGroupDesc
			,CreatedBy
			,CreatedDtm
			,ModifiedBy
			,ModifiedDtm
		FROM ctl.Publication
		WHERE PublicationCode = @pPublicationCode
			AND Bound = 'Out'
	END
	ELSE
	BEGIN
		SELECT @Err = 50002
			,@ErrMsg = 'ErrorNumber: ' + CAST(@Err AS VARCHAR(50)) + @CRLF + 'Custom Error: Invalid PublicationCode. Insert New Issue transaction rolled back.' + @CRLF + isnull(@ParametersPassedChar, 'Parmeter was NULL');

		throw @Err,@ErrMsg,1
	END

	select	 @PreviousDtm		= @CurrentDtm
			,@Rows				= @@ROWCOUNT 
	select	 @CurrentDtm		= getdate()

	exec [audit].usp_InsertStepLog
			 @MessageType		,@CurrentDtm		,@PreviousDtm	,@StepNumber		,@StepOperation		
			,@JSONSnippet		,@ErrNum			,@ParametersPassedChar					
			,@ErrMsg output		,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
			,@StepDesc output	,@StepStatus		,@DbName		,@Rows				
			,@pETLExecutionId	,@pPathId			,@PrevStepLog output
			,@pVerbose

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

select 	 @PreviousDtm			= @CurrentDtm
select	 @CurrentDtm			= getdate()
		,@StepNumber			= @StepNumber + 1
		,@StepName				= 'End'
		,@StepDesc				= 'Procedure completed'
		,@Rows					= 0
		,@StepOperation			= 'N/A'

exec [audit].usp_InsertStepLog
		 @MessageType		,@CurrentDtm	,@ProcessStartDtm	,@StepNumber		,@StepOperation		,@JSONSnippet		,@ErrNum
		,@ParametersPassedChar					,@ErrMsg output	,@ParentStepLogId	,@ProcName			,@ProcessType		,@StepName
		,@StepDesc output	,@StepStatus		,@DbName		,@Rows				,@pETLExecutionId	,@pPathId			,@PrevStepLog output
		,@pVerbose