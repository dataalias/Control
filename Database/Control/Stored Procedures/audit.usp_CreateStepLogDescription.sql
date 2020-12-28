CREATE PROCEDURE [audit].[usp_CreateStepLogDescription] (
		 @pMessageType			varchar(20)		= 'INFO'
		,@pStartDtm				datetime		= NULL
		,@pEndDtm				datetime		= NULL
		,@pStepNumber			varchar(23)		= '0'
		,@pOperation			nvarchar(50)	= 'Unknown'
		,@pStepDescription		nvarchar(max)	= 'N/A'
		,@pJSONSnippet			nvarchar(max)	= 'N/A'
		,@pErrNum				int				= 0
		,@pErrMsg				nvarchar(max)	= 'N/A'
		,@pParametersPassedChar nvarchar(max)	= 'N/A'
		,@pStepLogId			int				= -1 
		,@pJSONMsg				nvarchar(max)	= '{}'	output
		,@pFormatErrorMsg		nvarchar(max)	= '{}'	output
		,@pDuration				int				= -1	output	 
		,@pETLExecutionId		int				= -1
		,@pPathId				int				= -1
		,@pVerbose				bit				= 0)
AS
/*****************************************************************************
File:		usp_CreateStepLogDescription.sql
Name:		usp_CreateStepLogDescription
Purpose:	


	declare	 @StartDtm				datetime		= getdate()
			,@EndDtm				datetime		= getdate() + .013
			,@ErrMsgFormatted		nvarchar(max)
			,@ErrorJSON				nvarchar(max)
			,@duration				int				= 0
			,@JsonMessage			varchar(1000)	= '{"animal":"moose"}'

	exec [audit].[usp_CreateStepLogDescription] 
			 @pMessageType				= 'INFO' -- 'ErrCust'
			,@pStartDtm					= @StartDtm
			,@pEndDtm					= @EndDtm
			,@pStepNumber				= 5
			,@pOperation				= 'Insert'
			,@pStepDescription			= 'Neat Description'
			,@pJSONSnippet				= '{"hi":"bye"}'
			,@pErrNum					= 0
			,@pErrMsg					= 'I failed as a person'
			,@pParametersPassedChar 	= 'Parameters ...'
			,@pStepLogId				= -1 
			,@pJSONMsg					= @JsonMessage	output
			,@pFormatErrorMsg			= @ErrMsgFormatted	output
			,@pDuration					= @duration	output	 
			,@pETLExecutionId			= -1
			,@pPathId					= -1
			,@pVerbose					= 0

	print '@ErrMsgFormatted: ' + isnull(@ErrMsgFormatted,'null')
	print '@ErrorJSON:       ' + isnull(@ErrorJSON,'null')
	print '@JsonMessage:     ' + isnull(@JsonMessage,'null')
	print '@duration:        ' + isnull(cast(@duration as varchar(100)),'null')

Parameters:    

Called by:	
Calls:          

Errors:		

Author:		ffortunato
Date:		9/7/2017

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20170908	ffortunato		Getting Snippets. Adding Duration to steplog.

20170911	ffortunato		Consolidated formatting to reduce code. added 
							message type.

20170913	ffortunato		Errors cannot exceed 2048 characters
							Errors cannot have a % symbol in them w/o escaping 
							it first. (e.g. %% )

20171116	ffortunato		Adding Operation into one of the messages. 
							Updating test execution to work with ne parameters.
							Ignoring JSON parameter if its NULL, 'N/A' or ''
							Renaming snippet area from "Misc" to "Custom"

20180404	ffortunato		Missed a snippet area from "Misc" to "Custom" 

20180906	ffortunato		Cleaning up issues with Code analysis.
							@pErrNum varchar(10) --> int
							header / execute updates. better unit testing.
******************************************************************************/

-------------------------------------------------------------------------------
--  Declarations
-------------------------------------------------------------------------------

DECLARE	 @Rows					int				= 0
        ,@ErrNum				int				= -1
		,@ErrMsg				nvarchar(max)	= 'N/A'
		,@FailedProcedure		varchar(1000)	= 'N/A'
		,@ParametersPassedChar	varchar(1000)	= 'N/A'
		,@CRLF					varchar(10)		= char(13) + char(10)
		,@Tab					varchar(10)		= char(9)
		,@2Tab					varchar(10)		= char(9) + char(9)
		,@ProcName				varchar(256)	= OBJECT_NAME(@@PROCID) 
		,@ParentStepLogId       int				= -1
		,@PrevStepLog			int				= -1
		,@CurrentDtm			datetime		= getdate()
		,@DbName				varchar(256)	= DB_NAME()
		,@ProcessType			varchar(10)		= 'Proc'
		,@StepName				varchar(256)	= 'Start'
		,@StepDesc				nvarchar(max)	= '{"Description":"Procedure started"}' 
		,@StepStatus			varchar(10)		= 'Success'
		,@StepNumber			varchar(10)		= 0

-------------------------------------------------------------------------------
--  Initializations
-------------------------------------------------------------------------------

SELECT	 @FailedProcedure		= 'Stored Procedure : ' + @ProcName + ' failed.'
		,@ParametersPassedChar	= @CRLF +
      '***** Parameters Passed to exec <schema>.usp_CreateStepLogDescription' + @CRLF +
      '     @pMessageType = ''' + isnull(@pMessageType ,'NULL') + '''' + @CRLF + 
      '    ,@pStartDtm = ''' + isnull(convert(varchar(100),@pStartDtm ,13) ,'NULL') + '''' + @CRLF + 
      '    ,@pEndDtm = ''' + isnull(convert(varchar(100),@pEndDtm ,13) ,'NULL') + '''' + @CRLF + 
      '    ,@pStepNumber = ''' + isnull(@pStepNumber ,'NULL') + '''' + @CRLF + 
      '    ,@pOperation = ''' + isnull(@pOperation ,'NULL') + '''' + @CRLF + 
      '    ,@pStepDescription = ''' + isnull(@pStepDescription ,'NULL') + '''' + @CRLF + 
      '    ,@pJSONSnippet = ''' + isnull(@pJSONSnippet ,'NULL') + '''' + @CRLF + 
      '    ,@pErrNum = ''' + isnull(cast(@pErrNum as varchar(100)) ,'NULL') + '''' + @CRLF + 
      '    ,@pErrMsg = ''' + isnull(@pErrMsg ,'NULL') + '''' + @CRLF + 
      '    ,@pParametersPassedChar = ''' + isnull(@pParametersPassedChar ,'NULL') + '''' + @CRLF + 
      '    ,@pStepLogId = ' + isnull(cast(@pStepLogId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pJSONMsg = @pJSONMsg --output ' + @CRLF +
      '    ,@pFormatErrorMsg = @pFormatErrorMsg --output ' + @CRLF +
      '    ,@pDuration = @pDuration --output ' + @CRLF +
      '    ,@pETLExecutionId = ' + isnull(cast(@pETLExecutionId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pPathId = ' + isnull(cast(@pPathId as varchar(100)),'NULL') + @CRLF + 
      '    ,@pVerbose = ' + isnull(cast(@pVerbose as varchar(100)),'NULL') + @CRLF + 
      '***** End of Parameters' + @CRLF 


select	 @pJSONMsg				= isnull(@pJSONMsg,'{}')
		,@pFormatErrorMsg		= isnull(@pFormatErrorMsg,'{}')
		,@pDuration				= isnull(@pDuration,-1) 

select	 @pStartDtm	= isnull(@pStartDtm		,	cast( '1900-01-01' as datetime))
select	 @pEndDtm	= isnull(@pEndDtm		,	cast( '1900-01-01' as datetime))
		

if @pVerbose					= 1
	begin 
		print @ParametersPassedChar
	end

-------------------------------------------------------------------------------
--  Main
-------------------------------------------------------------------------------

begin try

select	 @pDuration				= DATEDIFF(second, @pStartDtm, @pEndDtm)

if @pMessageType				in ('ErrSQL','ErrCust')
begin

	if	@pJSONSnippet			= 'N/A'  or
		@pJSONSnippet			  is null  or
		@pJSONSnippet			= '' 
begin
		select   @pFormatErrorMsg = '{' + @CRLF +
								  @Tab + '"MessageType":"' +@pMessageType+ '",' + @CRLF +
								  @Tab + '"Error" : {' + @CRLF +
								  @2Tab + '"ErrorNumber":'+cast(@pErrNum as varchar(10))+',' + @CRLF +
								  @2Tab + '"ErrorMessage":"'+ replace(@pErrMsg,'"','''') +'",' + @CRLF +
								  @2Tab + '"ErrorTime":"'+ convert(varchar(30),@CurrentDtm ,120 ) +'",' + @CRLF +
								  @2Tab + '"StepLogId":'+ isnull(cast(@pStepLogId as varchar(10)),-1) +',' + @CRLF +
								  @2Tab + '"ParamentersPassed":"'+ @pParametersPassedChar + '"' + @CRLF +
								  @Tab + '},' + @CRLF +
								  @Tab + '"ProcessStepNumber":'+ @pStepNumber +',' + @CRLF +
								  @Tab + '"Description":"'+isnull(@pStepDescription, @pMessageType + ' thrown from process.')+'"' +@CRLF +
								  '}'

		select	 @pJSONMsg	= '{"MessageType":"' +@pMessageType+ '",' +
								  '"Error" : {' +
								  '"ErrorNumber":'+cast(@pErrNum as varchar(10))+',' +
								  '"ErrorMessage":"'+ replace(@pErrMsg,'"','''') +'",' +
								  '"ErrorTime":"'+ convert(varchar(30),@CurrentDtm ,120 ) +'",' +
								  '"StepLogId":'+ isnull(cast(@pStepLogId as varchar(10)),-1) +',' +
								  '"ParamentersPassed":"'+ replace(@pParametersPassedChar,@CRLF,'')+'"},' +
								  '"ProcessStepNumber":'+ @pStepNumber +',' +
								  '"Description":"'+isnull(@pStepDescription, @pMessageType + ' thrown from process.')+'"}'
end
else
	begin

		select   @pFormatErrorMsg = '{' + @CRLF +
								  @Tab + '"MessageType":"' +@pMessageType+ '",' + @CRLF +
								  @Tab + '"Error" : {' + @CRLF +
								  @2Tab + '"ErrorNumber":'+cast(@pErrNum as varchar(10))+',' + @CRLF +
								  @2Tab + '"ErrorMessage":"'+ replace(@pErrMsg,'"','''') +'",' + @CRLF +
								  @2Tab + '"ErrorTime":"'+ convert(varchar(30),@CurrentDtm ,120 ) +'",' + @CRLF +
								  @2Tab + '"StepLogId":'+ isnull(cast(@pStepLogId as varchar(10)),-1) +',' + @CRLF +
								  @2Tab + '"ParamentersPassed":"'+ @pParametersPassedChar + '"' + @CRLF +
								  @Tab + '},' + @CRLF +
								  @Tab + '"ProcessStepNumber":'+ @pStepNumber +',' + @CRLF +
								  @Tab + '"Description":"'+isnull(@pStepDescription, @pMessageType + ' thrown from process.')++'",'+@CRLF +
								  @Tab + '"Custom":' + @pJSONSnippet + @CRLF +
								  '}'

		select	 @pJSONMsg	= '{"MessageType":"' +@pMessageType+ '",' +
								  '"Error" : {' +
								  '"ErrorNumber":'+cast(@pErrNum as varchar(10))+',' +
								  '"ErrorMessage":"'+ replace(@pErrMsg,'"','''') +'",' +
								  '"ErrorTime":"'+ convert(varchar(30),@CurrentDtm ,120 ) +'",' +
								  '"StepLogId":'+ isnull(cast(@pStepLogId as varchar(10)),-1) +',' +
								  '"ParamentersPassed":"'+@pParametersPassedChar+'"},' +
								  '"ProcessStepNumber":'+ @pStepNumber +',' +
								  '"Description":"'+isnull(@pStepDescription, @pMessageType + ' thrown from process.')+'",'+
								  '"Custom":' + @pJSONSnippet +
								  '}'
	end
end -- ErrCust, ErrSQL

else if @pMessageType			in ('Info','Warn')
begin

	if	@pJSONSnippet			= 'N/A'  or
		@pJSONSnippet			  is null or
		@pJSONSnippet			= '' 

		select	 @pJSONMsg	= '{"MessageType":"' +@pMessageType+ '",' +
									'"StepNumber":'+@pStepNumber+',' +
									'"Operation":"'+@pOperation+'",'+
									'"Description":"'+ isnull(@pStepDescription,'Step Completed')+'"}'

	else -- A Snippet was provided.

		select	 @pJSONMsg	= '{"MessageType":"' +@pMessageType+ '",' +
									'"StepNumber":'+@pStepNumber+',' +
									'"Operation":"'+@pOperation+'",'+
									'"Description":"'+ isnull(@pStepDescription,'Step Completed')+'",'+
									'"Custom":' + @pJSONSnippet +
									'}'

end -- Info / Warn

else -- Take all other message types and try.
 
begin
		select	 @pJSONMsg	= '{"MessageType":"' + isnull(@pMessageType,'Unknown') + '",' +
									'"StepNumber":'+isnull(@pStepNumber,-1)+',' +
									'"Operation":"'+isnull(@pOperation,'Unknown')+'",'+
									'"Description":"'+ isnull(@pStepDescription,'Unknown')+'"}'
end


if charindex('%',@pFormatErrorMsg,1)  > 0
	select @pFormatErrorMsg = replace(@pFormatErrorMsg,'%','%%')

if len(@pFormatErrorMsg) > 2047
	select @pFormatErrorMsg = substring(@pFormatErrorMsg,1,2030) + '<Truncated>'

end try

-------------------------------------------------------------------------------
--  Error Handling
-------------------------------------------------------------------------------
begin catch

	select	 @ErrNum			= @@ERROR
			,@StepStatus		= 'Failure'
			,@ErrMsg			= 'Error Number: ' 
								+ CAST (@ErrNum as varchar(10)) + @CRLF
								+ @FailedProcedure				+ @CRLF 
								+ 'Step Name: ' + @StepName     + @CRLF
								+ 'SQL Server Error: '			+ @CRLF
								+ ERROR_MESSAGE ()				+ @CRLF
								+ isnull(@ParametersPassedChar, 'Parmeter was NULL')
			,@CurrentDtm		= getdate()
			,@Rows				= @@ROWCOUNT

	if @ErrNum < 50000  
		begin	-- SQL Server Error do no need to add all of the extra information...
			select	  @StepDesc	= '{"Error" : {	' +
								  '"ErrorNumber":'+cast(@ErrNum as varchar(10))+',' +
								  '"ErrorType":"SQL Server Error",' +
								  '"ErrorMessage":"'+ replace(ERROR_MESSAGE(),'"','''') +'",' +
								  '"ParamentersPassed":"'+@ParametersPassedChar+'"},' +
								  '"StepNumber":'+ @StepNumber +',' +
								  '"Description":"Failure in stored procedure"}'
			select	 @ErrNum	= @ErrNum + 100000000 -- Need to increase number to throw message.
		end

	;throw	 @ErrNum, @ErrMsg, 1	-- Sql Server Error
	
end catch

-------------------------------------------------------------------------------
--  Procedure End
-------------------------------------------------------------------------------
