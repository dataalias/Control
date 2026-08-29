-- DROP PROCEDURE `audit`.`usp_CreateStepLogDescription`

DELIMITER //
CREATE PROCEDURE `audit`.`usp_CreateStepLogDescription` (
		 p_pMessageType			varchar(20)		/* = 'INFO' */
		,p_pStartDtm				datetime(3)		/* = NULL */
		,p_pEndDtm				datetime(3)		/* = NULL */
		,p_pStepNumber			varchar(23)		/* = '0' */
		,p_pOperation			varchar(50)	/* = 'Unknown' */
		,p_pStepDescription		longtext	/* = 'N/A' */
		,p_pJSONSnippet			longtext	/* = 'N/A' */
		,p_pErrNum				int				/* = 0 */
		,p_pErrMsg				longtext	/* = 'N/A' */
		,p_pParametersPassedChar longtext	/* = 'N/A' */
		,p_pStepLogId			int				/* = -1 */ 
		,out p_pJSONMsg				longtext	/* = '{}' */
		,out p_pFormatErrorMsg		longtext	/* = '{}' */
		,out p_pDuration				int				/* = -1 */		 
		,p_pETLExecutionId		int				/* = -1 */
		,p_pPathId				int				/* = -1 */
		,p_pVerbose				tinyint				/* = 0 */)
BEGIN
/***********************************************************************
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

--  SQLINES DEMO *** -----------------------------------------------------------
--  D... SQLINES DEMO ***
--  SQLINES DEMO *** -----------------------------------------------------------

DECLARE	 v_Rows					int				DEFAULT 0
        ; DECLARE v_ErrNum				int				DEFAULT -1
		; DECLARE v_ErrMsg				longtext	DEFAULT 'N/A'
		; DECLARE v_FailedProcedure		varchar(1000)	DEFAULT 'N/A'
		; DECLARE v_ParametersPassedChar	varchar(1000)	DEFAULT 'N/A'
		; DECLARE v_CRLF					varchar(10)		DEFAULT cast(char(13) as char) + cast(char(10) as char)
		; DECLARE v_Tab					varchar(10)		DEFAULT cast(char(9) as char)
		; DECLARE v_2Tab					varchar(10)		DEFAULT cast(char(9) as char) + cast(char(9) as char)
		; DECLARE v_ProcName				varchar(256)	DEFAULT 'StepLogDescription' 
		; DECLARE v_ParentStepLogId       int				DEFAULT -1
		; DECLARE v_PrevStepLog			int				DEFAULT -1
		; DECLARE v_CurrentDtm			datetime(3)		DEFAULT now(3)
		; DECLARE v_DbName				varchar(256)	DEFAULT DATABASE()
		; DECLARE v_ProcessType			varchar(10)		DEFAULT 'Proc'
		; DECLARE v_StepName				varchar(256)	DEFAULT 'Start'
		; DECLARE v_StepDesc				longtext	DEFAULT '{"Description":"Procedure started"}' 
		; DECLARE v_StepStatus			varchar(10)		DEFAULT 'Success'
		; DECLARE v_StepNumber			varchar(10)		DEFAULT 0;

--  SQLINES DEMO *** -----------------------------------------------------------
--  I... SQLINES DEMO ***
--  SQLINES DEMO *** -----------------------------------------------------------

SET	 v_FailedProcedure		= CONCAT('Stored Procedure : ' , v_ProcName , ' failed.')
		,v_ParametersPassedChar	= CONCAT(v_CRLF ,
      '***** Parameters Passed to exec <schema>.usp_CreateStepLogDescription' , v_CRLF ,
      '     @pMessageType = ''' , ifnull(p_pMessageType ,'NULL') , '''' , v_CRLF , 
      '    ,@pStartDtm = ''' , ifnull(date_format(p_pStartDtm ,'%d %b %Y %T.%f') ,'NULL') , '''' , v_CRLF , 
      '    ,@pEndDtm = ''' , ifnull(date_format(p_pEndDtm ,'%d %b %Y %T.%f') ,'NULL') , '''' , v_CRLF , 
      '    ,@pStepNumber = ''' , ifnull(p_pStepNumber ,'NULL') , '''' , v_CRLF , 
      '    ,@pOperation = ''' , ifnull(p_pOperation ,'NULL') , '''' , v_CRLF , 
      '    ,@pStepDescription = ''' , ifnull(p_pStepDescription ,'NULL') , '''' , v_CRLF , 
      '    ,@pJSONSnippet = ''' , ifnull(p_pJSONSnippet ,'NULL') , '''' , v_CRLF , 
      '    ,@pErrNum = ''' , ifnull(cast(p_pErrNum as char(100)) ,'NULL') , '''' , v_CRLF , 
      '    ,@pErrMsg = ''' , ifnull(p_pErrMsg ,'NULL') , '''' , v_CRLF , 
      '    ,@pParametersPassedChar = ''' , ifnull(p_pParametersPassedChar ,'NULL') , '''' , v_CRLF , 
      '    ,@pStepLogId = ' , ifnull(cast(p_pStepLogId as char(100)),'NULL') , v_CRLF , 
      '    ,@pJSONMsg = @pJSONMsg --output ' , v_CRLF ,
      '    ,@pFormatErrorMsg = @pFormatErrorMsg --output ' , v_CRLF ,
      '    ,@pDuration = @pDuration --output ' , v_CRLF ,
      '    ,@pETLExecutionId = ' , ifnull(cast(p_pETLExecutionId as char(100)),'NULL') , v_CRLF , 
      '    ,@pPathId = ' , ifnull(cast(p_pPathId as char(100)),'NULL') , v_CRLF , 
      '    ,@pVerbose = ' , ifnull(cast(p_pVerbose as char(100)),'NULL') , v_CRLF , 
      '***** End of Parameters' , v_CRLF); 


set	 p_pJSONMsg				= ifnull(p_pJSONMsg,'{}')
	,p_pFormatErrorMsg		= ifnull(p_pFormatErrorMsg,'{}')
	,p_pDuration			= ifnull(p_pDuration,-1); 

set	 p_pStartDtm	= ifnull(p_pStartDtm		,	cast( '1900-01-01' as datetime(3)));
set	 p_pEndDtm	= ifnull(p_pEndDtm		,	cast( '1900-01-01' as datetime(3)));
		

if p_pVerbose					= 1
	then 
		/* print v_ParametersPassedChar */
        select v_FailedProcedure;
end if;

--  SQLINES DEMO *** -----------------------------------------------------------
--  M... SQLINES DEMO ***
--  SQLINES DEMO *** -----------------------------------------------------------

set	 p_pDuration				= TIMESTAMPDIFF(second, p_pStartDtm, p_pEndDtm);

if p_pMessageType				in ('ErrSQL','ErrCust')
then

	if	p_pJSONSnippet			= 'N/A'  or
		p_pJSONSnippet			  is null  or
		p_pJSONSnippet			= '' 
	then
		set   p_pFormatErrorMsg = Concat('{' , v_CRLF ,
								  v_Tab , '"MessageType":"' ,p_pMessageType, '",' , v_CRLF ,
								  v_Tab , '"Error" : {' , v_CRLF ,
								  v_2Tab , '"ErrorNumber":',cast(p_pErrNum as char(10)),',' , v_CRLF ,
								  v_2Tab , '"ErrorMessage":"', replace(p_pErrMsg,'"','''') ,'",' , v_CRLF ,
								  v_2Tab , '"ErrorTime":"', date_format(v_CurrentDtm ,120 ) ,'",' , v_CRLF ,
								  v_2Tab , '"StepLogId":', ifnull(cast(p_pStepLogId as char(10)),-1) ,',' , v_CRLF ,
								  v_2Tab , '"ParamentersPassed":"', p_pParametersPassedChar , '"' , v_CRLF ,
								  v_Tab , '},' , v_CRLF ,
								  v_Tab , '"ProcessStepNumber":', p_pStepNumber ,',' , v_CRLF ,
								  v_Tab , '"Description":"',ifnull(p_pStepDescription, CONCAT(p_pMessageType , ' thrown from process.')),'"' ,v_CRLF ,
								  '}');

		set	 p_pJSONMsg	= CONCAT('{"MessageType":"' ,p_pMessageType, '",' ,
								  '"Error" : {' ,
								  '"ErrorNumber":',cast(p_pErrNum as char(10)),',' ,
								  '"ErrorMessage":"', replace(p_pErrMsg,'"','''') ,'",' ,
								  '"ErrorTime":"', date_format(v_CurrentDtm ,120 ) ,'",' ,
								  '"StepLogId":', ifnull(cast(p_pStepLogId as char(10)),-1) ,',' ,
								  '"ParamentersPassed":"', replace(p_pParametersPassedChar,v_CRLF,''),'"},' ,
								  '"ProcessStepNumber":', p_pStepNumber ,',' ,
								  '"Description":"',ifnull(p_pStepDescription, CONCAT(p_pMessageType , ' thrown from process.')),'"}');
	else

		set   p_pFormatErrorMsg = Concat('{' , v_CRLF ,
								  v_Tab , '"MessageType":"' ,p_pMessageType, '",' , v_CRLF ,
								  v_Tab , '"Error" : {' , v_CRLF ,
								  v_2Tab , '"ErrorNumber":',cast(p_pErrNum as char(10)),',' , v_CRLF ,
								  v_2Tab , '"ErrorMessage":"', replace(p_pErrMsg,'"','''') ,'",' , v_CRLF ,
								  v_2Tab , '"ErrorTime":"', date_format(v_CurrentDtm ,120 ) ,'",' , v_CRLF ,
								  v_2Tab , '"StepLogId":', ifnull(cast(p_pStepLogId as char(10)),-1) ,',' , v_CRLF ,
								  v_2Tab , '"ParamentersPassed":"', p_pParametersPassedChar , '"' , v_CRLF ,
								  v_Tab , '},' , v_CRLF ,
								  v_Tab , '"ProcessStepNumber":', p_pStepNumber ,',' , v_CRLF ,
								  v_Tab , '"Description":"',ifnull(p_pStepDescription, CONCAT(p_pMessageType , ' thrown from process.')),
								  '}');

		set	 p_pJSONMsg	= CONCAT('{"MessageType":"' ,p_pMessageType, '",' ,
								  '"Error" : {' ,
								  '"ErrorNumber":',cast(p_pErrNum as char(10)),',' ,
								  '"ErrorMessage":"', replace(p_pErrMsg,'"','''') ,'",' ,
								  '"ErrorTime":"', date_format(v_CurrentDtm ,120 ) ,'",' ,
								  '"StepLogId":', ifnull(cast(p_pStepLogId as char(10)),-1) ,',' ,
								  '"ParamentersPassed":"',p_pParametersPassedChar,'"},' ,
								  '"ProcessStepNumber":', p_pStepNumber ,',' ,
								  '"Description":"',ifnull(p_pStepDescription, CONCAT(p_pMessageType , ' thrown from process.')),'",',
								  '"Custom":' , p_pJSONSnippet ,
								  '}');
	end if; -- Error Cust Err

elseif p_pMessageType			in ('Info','Warn')
then

	if	p_pJSONSnippet			= 'N/A'  or
		p_pJSONSnippet			  is null or
		p_pJSONSnippet			= '' 
	then 

		set	 p_pJSONMsg	= CONCAT('{"MessageType":"' ,p_pMessageType, '",' ,
									'"StepNumber":',p_pStepNumber,',' ,
									'"Operation":"',p_pOperation,'",',
									'"Description":"', ifnull(p_pStepDescription,'Step Completed'),'"}');

	else -- A snippet was provided.

		set	 p_pJSONMsg	= CONCAT('{"MessageType":"' ,p_pMessageType, '",' ,
									'"StepNumber":',p_pStepNumber,',' ,
									'"Operation":"',p_pOperation,'",',
									'"Description":"', ifnull(p_pStepDescription,'Step Completed'),'",',
									'"Custom":' , p_pJSONSnippet ,
									'}');
	end if;  -- Info and warn

else -- All other message types and try.
 
		set	 p_pJSONMsg	= CONCAT('{"MessageType":"' , ifnull(p_pMessageType,'Unknown') , '",' ,
									'"StepNumber":',ifnull(p_pStepNumber,-1),',' ,
									'"Operation":"',ifnull(p_pOperation,'Unknown'),'",',
									'"Description":"', ifnull(p_pStepDescription,'Unknown'),'"}');
end if;


if locate('%',p_pFormatErrorMsg,1)  > 0 then
	set p_pFormatErrorMsg = replace(p_pFormatErrorMsg,'%','%%');
end if;

if char_length(rtrim(p_pFormatErrorMsg)) > 2047 then
	set p_pFormatErrorMsg = concat(substring(p_pFormatErrorMsg,1,2030) , '<Truncated>');
end if;

end;
//