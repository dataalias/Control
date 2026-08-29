-- DROP PROCEDURE `audit`.`usp_InsertStepLog`
DELIMITER //

CREATE PROCEDURE `audit`.`usp_InsertStepLog` (
		 p_MessageType			varchar(20)		/* = 'INFO' */
		,p_CurrentDtm			datetime(3)		/* = NULL */
		,p_PreviousDtm			datetime(3)		/* = NULL */
		,p_StepNumber			varchar(23)		/* = '0' */
		,p_StepOperation		varchar(50)	/* = 'Unknown' */
		,p_JSONSnippet			longtext	/* = 'N/A' */
		,p_ErrNum				int				/* = 0 */
		,p_ParametersPassedChar longtext	/* = 'N/A' */
		,out p_ErrMsg			longtext	/* = 'N/A' */
		,p_ParentLogId			int				/* = -1 */
		,p_ProcessName			varchar(256)	/* = 'N/A' */
		,p_ProcessType			varchar(256)	/* = 'N/A' */
		,p_StepName			varchar(256)	/* = 'N/A' */
		,out p_StepDesc		varchar(2048)	/* = 'N/A' */
		,p_StepStatus			varchar(10)		/* = 'N/A' */
		,p_DBName				varchar(50)		/* = 'N/A' */
		,p_RecordCount			int				/* = -1 */
		,p_ETLExecutionId		int				/* = -1 */
		,p_PathId				int				/* = -1 */
		,out p_StepLogId		int				/* = -1 */
		,p_Verbose				tinyint				/* = 0 */)
BEGIN
/**********************************************************************************************************************
File:		usp_InsertStepLog.sql
Name:		usp_InsertStepLog
Purpose:	

Execute: 
	declare @LogId int, @Start datetime = getdate(),@End datetime = getdate() -.001,
	@StepDescription varchar(2048) = 'Adds some data to dis thing'

	exec [audit].[usp_InsertStepLog] 
			 @pMessageType			= 'INFO'
			,@pCurrentDtm			= @Start
			,@pPreviousDtm			= @End
			,@pStepNumber			= 1 
			,@pStepOperation		='select'
			,@pJSONSnippet			= '{"snip":"yup"}'
			,@pErrNum				= 344
			,@pParametersPassedChar = 'Parms...'
			,@pErrMsg				= 'I failed as a person...'
			,@pParentLogId			= -1
			,@pProcessName			= 'usp_SomeProcedure'
			,@pProcessType			= 'Proc'
			,@pStepName				= ' Insert some data...'
			,@pStepDesc				= @StepDescription output
			,@pStepStatus			= 'Success'
			,@pDBName				= 'BPI_DW_STAGE'
			,@pRecordCount			= 666
			,@pETLExecutionId		= 12345
			,@pPathId				= 99
			,@pStepLogId			= @LogId output
			,@pVerbose				= 1

	print 'LogId:     ' + cast(@LogId as varchar(20))
	print '@StepDesc: ' + @StepDescription

Parameters:    

Called by:	
Calls:          

Errors:		

Author:		ffortunato
Date:		20170802

*******************************************************************************
       CHANGE HISTORY
*******************************************************************************
Date		Author			Description
--------	-------------	---------------------------------------------------
20170825	ffortunato		adding steplog status.

20170908	ffortunato		adding formatting proc call.

20170911	ffortunato		updated paramerter list.

20230528	ffortunato		Removing Transaction and @Steplog = query :(

20240725	ffortunato		o Convert to MySQL
							- Remove error handling
******************************************************************************/

--  SQLINES DEMO *** -----------------------------------------------------------
--  D... SQLINES DEMO ***
--  SQLINES DEMO *** -----------------------------------------------------------

DECLARE	 v_Rows					int				DEFAULT 0
        ; DECLARE v_ErrNum				int				DEFAULT -1
		; DECLARE v_ErrMsg				varchar(2048)	DEFAULT 'N/A'
		; DECLARE v_FailedProcedure		varchar(1000)	DEFAULT CONCAT('Stored Procedure : ' , 'usp_InsertStepLog' , ' failed.')
		; DECLARE v_ParametersPassedChar	varchar(1000)
		; DECLARE v_CRLF					varchar(10)		DEFAULT cast(char(13) as char) + cast(char(10) as char)
		; DECLARE v_DurationInSeconds		int				DEFAULT 0
		; DECLARE v_CurrentDtm			datetime(3)		DEFAULT now(3)
		; DECLARE v_MessageType			varchar(20)		DEFAULT 'Info'
		--  SQLINES DEMO ***       varchar(20)     = '-1'
		; DECLARE v_SteplogId				int				DEFAULT 0;

--  SQLINES DEMO *** -----------------------------------------------------------
--  I... SQLINES DEMO ***
--  SQLINES DEMO *** -----------------------------------------------------------

SET	 v_ParametersPassedChar	= CONCAT(v_CRLF ,
      '***** Parameters Passed to exec audit.usp_InsertStepLog' , v_CRLF ,
      '     @pMessageType = ''' , ifnull(p_MessageType ,'NULL') , '''' , v_CRLF , 
      '    ,@pCurrentDtm = ''' , ifnull(date_format(p_CurrentDtm ,'%d %b %Y %T.%f') ,'NULL') , '''' , v_CRLF , 
      '    ,@pPreviousDtm = ''' , ifnull(date_format(p_PreviousDtm ,'%d %b %Y %T.%f') ,'NULL') , '''' , v_CRLF , 
      '    ,@pStepNumber = ''' , ifnull(p_StepNumber ,'NULL') , '''' , v_CRLF , 
      '    ,@pStepOperation = ''' , ifnull(p_StepOperation ,'NULL') , '''' , v_CRLF , 
      '    ,@pJSONSnippet = ''' , ifnull(p_JSONSnippet ,'NULL') , '''' , v_CRLF , 
      '    ,@pErrNum = ' , ifnull(cast(p_ErrNum as char(100)),'NULL') , v_CRLF , 
      '    ,@pParametersPassedChar = ''' , ifnull(p_ParametersPassedChar ,'NULL') , '''' , v_CRLF , 
      '    ,@pErrMsg = @pErrMsg --output ' , v_CRLF ,
      '    ,@pParentLogId = ' , ifnull(cast(p_ParentLogId as char(100)),'NULL') , v_CRLF , 
      '    ,@pProcessName = ''' , ifnull(p_ProcessName ,'NULL') , '''' , v_CRLF , 
      '    ,@pProcessType = ''' , ifnull(p_ProcessType ,'NULL') , '''' , v_CRLF , 
      '    ,@pStepName = ''' , ifnull(p_StepName ,'NULL') , '''' , v_CRLF , 
      '    ,@pStepDesc = @pStepDesc --output ' , v_CRLF ,
      '    ,@pStepStatus = ''' , ifnull(p_StepStatus ,'NULL') , '''' , v_CRLF , 
      '    ,@pDBName = ''' , ifnull(p_DBName ,'NULL') , '''' , v_CRLF , 
      '    ,@pRecordCount = ' , ifnull(cast(p_RecordCount as char(100)),'NULL') , v_CRLF , 
      '    ,@pETLExecutionId = ' , ifnull(cast(p_ETLExecutionId as char(100)),'NULL') , v_CRLF , 
      '    ,@pPathId = ' , ifnull(cast(p_PathId as char(100)),'NULL') , v_CRLF , 
      '    ,@pStepLogId = @pStepLogId --output ' , v_CRLF ,
      '    ,@pVerbose = ' , ifnull(cast(p_Verbose as char(100)),'NULL') , v_CRLF , 
      '***** End of Parameters' , v_CRLF); 

set	 p_StepDesc				= ifnull(p_StepDesc,'No Step Description Provided...');
set	 p_StepLogId			= ifnull(p_StepLogId,-1);

set	 p_CurrentDtm			= ifnull(p_CurrentDtm,cast('1900-01-01' as datetime(3)));
set	 p_PreviousDtm			= ifnull(p_PreviousDtm,cast('1900-01-01' as datetime(3)));

if p_Verbose					= 1
	then 
		/* print v_ParametersPassedChar */
        select 1 from dual;
	end if;

--  SQLINES DEMO *** -----------------------------------------------------------
--  M... SQLINES DEMO ***
--  SQLINES DEMO *** -----------------------------------------------------------


-- SQLINES DEMO *** ion to ensure Id's remain consistent.

--  SQLINES DEMO *** StepLogInsert

select ifnull(max(StepLogId) + 1 ,1) into v_SteplogId
	from	`audit`.StepLog;

	call	`audit`.`usp_CreateStepLogDescription`(p_MessageType			= v_pMessageType
			,p_StartDtm				= v_pPreviousDtm
			,p_EndDtm				= v_pCurrentDtm
			,p_StepNumber			= v_pStepNumber
			,p_Operation			= v_pStepOperation
			,p_StepDescription		= v_pStepDesc
			,p_JSONSnippet			= v_pJSONSnippet
			,p_ErrNum				= v_pErrNum
			,p_ErrMsg				= v_pErrMsg
			,p_ParametersPassedChar = v_pParametersPassedChar
			,p_StepLogId			= v_SteplogId
			,p_JSONMsg				= v_pStepDesc		
			,p_FormatErrorMsg		= v_pErrMsg			
			,p_Duration				= v_DurationInSeconds		 
			,p_ETLExecutionId		= v_pETLExecutionId
			,p_PathId				= v_pPathId
			,p_Verbose				= v_pVerbose);

-- SQLINES DEMO *** sn't passed the next insert will be the parent.

if  p_ParentLogId				= -1 then
	set	p_ParentLogId		= v_SteplogId;
end if;	
	

-- SQLINES LICENSE FOR EVALUATION USE ONLY
insert into `audit`.StepLog (
		ParentLogId
		,ProcessName
		,ProcessType
		,StepName
		,StepDesc
		,StepStatus	
		,StartDtm
		,DurationInSeconds
		,DbName
		,RecordCount
		,ETLExecutionId
		,PathId
) values (
		 p_ParentLogId
		,p_ProcessName
		,p_ProcessType
		,p_StepName
		,p_StepDesc
		,p_StepStatus
		,p_PreviousDtm -- SQLINES DEMO *** e previous! It has to do with the timing of exec in the calling procedure.
		,v_DurationInSeconds
		,p_DBName
		,p_RecordCount
		,p_ETLExecutionId
		,p_PathId
);

-- SQLINES DEMO *** Id just inserted. 

set  p_StepLogId				= ifnull(LAST_INSERT_ID(),-1);

--  SQLINES DEMO ***  StepLogInsert

/* SQLINES DEMO *** = 1
	begin 
		print '@pStepLogId        : ' + cast(@pStepLogId as varchar(100))
		print 'SCOPE_IDENTITY     : ' + cast(SCOPE_IDENTITY() as varchar(100))
		print '@@Identity         : ' + cast(@@Identity as varchar(100))
		select @tstingLogId		= cast(max(StepLogId) as varchar(20)) from [audit].StepLog
		print 'max(StepLogId)     : ' + @tstingLogId
	end
*/

-- SQLINES DEMO *** n @pStepLogId is -1 we have a problem.

if p_StepLogId					= -1
then
    set   v_ErrNum			= 50001
			,v_ErrMsg			= CONCAT('ErrorNumber: ' , CAST(v_ErrNum as char(10)) + v_CRLF
								, 'Custom Error: Invalid @pStepLogId. Insert New Step Log transaction rolled back.'  , v_CRLF
								, ifnull(v_ParametersPassedChar, 'Parmeter was NULL'))
			,v_MessageType		= 'ErrCust';
	select 'Failure',v_ErrMsg from dual;

end if;

end;
//


